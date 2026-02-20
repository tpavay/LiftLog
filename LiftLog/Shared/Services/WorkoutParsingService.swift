//
//  WorkoutParsingService.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation

/// Parsed workout data from natural language input
struct ParsedWorkoutData: Codable {
    var exercises: [ParsedExercise]
    var workoutName: String?
    var notes: String?
    
    struct ParsedExercise: Codable {
        var name: String
        var sets: [ParsedSet]
        var notes: String?
        
        struct ParsedSet: Codable {
            var weight: Double? // nil = bodyweight
            var reps: Int
            var setType: String? // "warmup", "working", "dropset", etc.
        }
    }
}

/// Service for parsing natural language workout descriptions using LLM
actor WorkoutParsingService {
    
    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ??
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }
    
    // MARK: - Parse Workout
    
    func parseWorkoutDescription(_ text: String) async throws -> ParsedWorkoutData {
        guard let apiKey = apiKey else {
            // Try regex fallback
            return FallbackWorkoutParser.parse(text)
        }
        
        let prompt = buildPrompt(for: text)
        let response = try await callAPI(prompt: prompt, apiKey: apiKey)
        return try parseResponse(response)
    }
    
    private func buildPrompt(for input: String) -> String {
        """
        Parse this gym workout description into structured data. Return ONLY valid JSON.
        
        Output format:
        {
          "exercises": [
            {
              "name": "Exercise Name",
              "sets": [
                {"weight": 135, "reps": 10, "setType": "warmup"},
                {"weight": 185, "reps": 8, "setType": "working"}
              ],
              "notes": "optional notes"
            }
          ],
          "workoutName": "optional workout name",
          "notes": "optional overall notes"
        }
        
        Rules:
        - weight is in lbs, null for bodyweight exercises
        - setType can be: "warmup", "working", "dropset", "failure", "amrap"
        - Recognize common exercise names and normalize them
        - "3x10" means 3 sets of 10 reps at same weight
        - "135x10" or "135 for 10" means 135 lbs for 10 reps
        - "BW" or "bodyweight" means weight is null
        
        Examples:
        
        Input: "bench press 135x10, 185x8, 205x6"
        Output: {"exercises":[{"name":"Bench Press","sets":[{"weight":135,"reps":10,"setType":"working"},{"weight":185,"reps":8,"setType":"working"},{"weight":205,"reps":6,"setType":"working"}]}]}
        
        Input: "squats: warmup 135x10, then 225 for 5x3"
        Output: {"exercises":[{"name":"Barbell Squat","sets":[{"weight":135,"reps":10,"setType":"warmup"},{"weight":225,"reps":5,"setType":"working"},{"weight":225,"reps":5,"setType":"working"},{"weight":225,"reps":5,"setType":"working"}]}]}
        
        Input: "pull-ups 3x8, dips 3x10 bodyweight"
        Output: {"exercises":[{"name":"Pull-ups","sets":[{"weight":null,"reps":8,"setType":"working"},{"weight":null,"reps":8,"setType":"working"},{"weight":null,"reps":8,"setType":"working"}]},{"name":"Dips","sets":[{"weight":null,"reps":10,"setType":"working"},{"weight":null,"reps":10,"setType":"working"},{"weight":null,"reps":10,"setType":"working"}]}]}
        
        Now parse:
        \(input)
        """
    }
    
    private func callAPI(prompt: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1000,
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ParsingError.apiError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ParsingError.invalidResponse
        }
        
        return text
    }
    
    private func parseResponse(_ response: String) throws -> ParsedWorkoutData {
        var cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        return try JSONDecoder().decode(ParsedWorkoutData.self, from: data)
    }
}

// MARK: - Fallback Parser

struct FallbackWorkoutParser {
    static func parse(_ text: String) -> ParsedWorkoutData {
        var exercises: [ParsedWorkoutData.ParsedExercise] = []
        
        // Split by common delimiters
        let parts = text.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed.isEmpty { continue }
            
            // Try to extract exercise name and sets
            // Pattern: "exercise name weightxreps" or "exercise name weight for reps"
            if let exercise = parseExercisePart(trimmed) {
                exercises.append(exercise)
            }
        }
        
        return ParsedWorkoutData(exercises: exercises, workoutName: nil, notes: nil)
    }
    
    private static func parseExercisePart(_ text: String) -> ParsedWorkoutData.ParsedExercise? {
        // Simple regex patterns
        let patterns = [
            // "bench 135x10"
            #"^(.+?)\s+(\d+)\s*x\s*(\d+)$"#,
            // "bench 135 for 10"
            #"^(.+?)\s+(\d+)\s+for\s+(\d+)$"#,
            // "bench 3x10 at 135"
            #"^(.+?)\s+(\d+)\s*x\s*(\d+)\s+at\s+(\d+)$"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // Extract groups
                    if let nameRange = Range(match.range(at: 1), in: text) {
                        let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
                        // Simplified - just return with one set for now
                        return ParsedWorkoutData.ParsedExercise(
                            name: name.capitalized,
                            sets: [ParsedWorkoutData.ParsedExercise.ParsedSet(weight: nil, reps: 10, setType: "working")],
                            notes: nil
                        )
                    }
                }
            }
        }
        
        // If no pattern matches, just use the whole thing as exercise name
        return ParsedWorkoutData.ParsedExercise(
            name: text.capitalized,
            sets: [],
            notes: nil
        )
    }
}

// MARK: - Errors

enum ParsingError: LocalizedError {
    case noApiKey
    case apiError
    case invalidResponse
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .noApiKey: return "No API key configured"
        case .apiError: return "API request failed"
        case .invalidResponse: return "Invalid response from server"
        case .invalidJSON: return "Could not parse workout data"
        }
    }
}
