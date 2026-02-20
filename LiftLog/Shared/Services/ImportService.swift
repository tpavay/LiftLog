//
//  ImportService.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import SwiftData
import HealthKit

// MARK: - Import Result

struct ImportResult: Sendable {
    let workoutsImported: Int
    let exercisesImported: Int
    let errors: [String]
    
    var isSuccess: Bool { errors.isEmpty }
}

// MARK: - Hevy Import Service

actor HevyImportService {
    private let baseURL = "https://api.hevyapp.com/v1"
    
    func importWorkouts(apiKey: String, modelContext: ModelContext) async throws -> ImportResult {
        var allWorkouts: [HevyWorkout] = []
        var page = 1
        var hasMore = true
        
        // Fetch all pages
        while hasMore {
            let pageData = try await fetchPage(page: page, apiKey: apiKey)
            allWorkouts.append(contentsOf: pageData.workouts)
            hasMore = page < pageData.pageCount
            page += 1
            
            // Rate limiting - be nice to the API
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Convert and save
        var exerciseCount = 0
        var errors: [String] = []
        
        for hevyWorkout in allWorkouts {
            do {
                let workout = try convertHevyWorkout(hevyWorkout)
                exerciseCount += workout.exercises?.count ?? 0
                await MainActor.run {
                    modelContext.insert(workout)
                }
            } catch {
                errors.append("Failed to import workout: \(hevyWorkout.title)")
            }
        }
        
        await MainActor.run {
            try? modelContext.save()
        }
        
        return ImportResult(
            workoutsImported: allWorkouts.count,
            exercisesImported: exerciseCount,
            errors: errors
        )
    }
    
    private func fetchPage(page: Int, apiKey: String) async throws -> HevyPageResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/workouts?page=\(page)&pageSize=10")!)
        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ImportError.apiError
        }
        
        return try JSONDecoder().decode(HevyPageResponse.self, from: data)
    }
    
    private func convertHevyWorkout(_ hevy: HevyWorkout) throws -> Workout {
        let workout = Workout(
            name: hevy.title,
            date: ISO8601DateFormatter().date(from: hevy.startTime) ?? Date(),
            notes: hevy.description
        )
        
        // Parse start/end times
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let start = formatter.date(from: hevy.startTime) {
            workout.startTime = start
        }
        if let end = formatter.date(from: hevy.endTime) {
            workout.endTime = end
        }
        
        // Convert exercises
        var exercises: [Exercise] = []
        for (index, hevyExercise) in hevy.exercises.enumerated() {
            let exercise = Exercise(
                name: hevyExercise.title,
                primaryMuscle: guessMuscleGroup(from: hevyExercise.title),
                equipment: .barbell,
                order: index
            )
            exercise.notes = hevyExercise.notes
            
            // Convert sets
            var sets: [WorkoutSet] = []
            for (setIndex, hevySet) in hevyExercise.sets.enumerated() {
                let workoutSet = WorkoutSet(
                    order: setIndex,
                    weight: (hevySet.weightKg ?? 0) * 2.20462, // Convert kg to lbs
                    reps: hevySet.reps ?? 0,
                    setType: hevySet.type == "warmup" ? .warmup : .working,
                    isCompleted: true
                )
                // Store duration/distance for cardio exercises
                if let duration = hevySet.durationSeconds {
                    workoutSet.duration = TimeInterval(duration)
                }
                if let distance = hevySet.distanceMeters {
                    workoutSet.distance = Double(distance)
                }
                sets.append(workoutSet)
            }
            exercise.sets = sets
            exercises.append(exercise)
        }
        
        workout.exercises = exercises
        return workout
    }
    
    private func guessMuscleGroup(from name: String) -> MuscleGroup {
        let lowercased = name.lowercased()
        
        if lowercased.contains("bench") || lowercased.contains("chest") || lowercased.contains("fly") || lowercased.contains("push") {
            return .chest
        }
        if lowercased.contains("row") || lowercased.contains("pull") || lowercased.contains("lat") || lowercased.contains("back") {
            return .back
        }
        if lowercased.contains("shoulder") || lowercased.contains("press") || lowercased.contains("lateral") || lowercased.contains("delt") {
            return .shoulders
        }
        if lowercased.contains("bicep") || lowercased.contains("curl") {
            return .biceps
        }
        if lowercased.contains("tricep") || lowercased.contains("pushdown") || lowercased.contains("skull") {
            return .triceps
        }
        if lowercased.contains("squat") || lowercased.contains("leg press") || lowercased.contains("quad") || lowercased.contains("lunge") {
            return .quadriceps
        }
        if lowercased.contains("deadlift") || lowercased.contains("hamstring") || lowercased.contains("rdl") {
            return .hamstrings
        }
        if lowercased.contains("calf") || lowercased.contains("calves") {
            return .calves
        }
        if lowercased.contains("glute") || lowercased.contains("hip thrust") {
            return .glutes
        }
        if lowercased.contains("ab") || lowercased.contains("crunch") || lowercased.contains("plank") || lowercased.contains("core") {
            return .core
        }
        if lowercased.contains("run") || lowercased.contains("bike") || lowercased.contains("cardio") || lowercased.contains("stair") || lowercased.contains("treadmill") {
            return .cardio
        }
        
        return .other
    }
}

// MARK: - Hevy API Models

struct HevyPageResponse: Codable {
    let page: Int
    let pageCount: Int
    let workouts: [HevyWorkout]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pageCount = "page_count"
        case workouts
    }
}

struct HevyWorkout: Codable {
    let id: String
    let title: String
    let description: String?
    let startTime: String
    let endTime: String
    let exercises: [HevyExercise]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, exercises
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct HevyExercise: Codable {
    let index: Int
    let title: String
    let notes: String?
    let sets: [HevySet]
}

struct HevySet: Codable {
    let index: Int
    let type: String
    let weightKg: Double?
    let reps: Int?
    let distanceMeters: Int?
    let durationSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case index, type, reps
        case weightKg = "weight_kg"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
    }
}

// MARK: - Apple Health Import Service

class HealthKitImportService {
    private let healthStore = HKHealthStore()
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned)
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func importWorkouts(modelContext: ModelContext, since: Date? = nil) async throws -> ImportResult {
        let workoutType = HKObjectType.workoutType()
        
        var predicate: NSPredicate? = nil
        if let since = since {
            predicate = HKQuery.predicateForSamples(withStart: since, end: Date(), options: .strictStartDate)
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: ImportResult(workoutsImported: 0, exercisesImported: 0, errors: ["No workouts found"]))
                    return
                }
                
                Task { @MainActor in
                    var importedCount = 0
                    var errors: [String] = []
                    
                    for hkWorkout in workouts {
                        let workout = self?.convertHealthKitWorkout(hkWorkout)
                        if let workout = workout {
                            modelContext.insert(workout)
                            importedCount += 1
                        }
                    }
                    
                    try? modelContext.save()
                    
                    continuation.resume(returning: ImportResult(
                        workoutsImported: importedCount,
                        exercisesImported: 0, // HealthKit doesn't have exercise-level detail
                        errors: errors
                    ))
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func convertHealthKitWorkout(_ hkWorkout: HKWorkout) -> Workout {
        let name = workoutName(for: hkWorkout.workoutActivityType)
        
        let workout = Workout(
            name: name,
            date: hkWorkout.startDate,
            notes: "Imported from Apple Health"
        )
        
        workout.startTime = hkWorkout.startDate
        workout.endTime = hkWorkout.endDate
        
        // Create a single "exercise" representing the workout
        let exercise = Exercise(
            name: name,
            primaryMuscle: muscleGroup(for: hkWorkout.workoutActivityType),
            equipment: .other,
            order: 0
        )
        
        // Store duration and calories as a single "set"
        let workoutSet = WorkoutSet(
            order: 0,
            weight: 0,
            reps: 0,
            setType: .working,
            isCompleted: true
        )
        workoutSet.duration = hkWorkout.duration
        
        if let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
            workoutSet.calories = calories
        }
        
        if let distance = hkWorkout.totalDistance?.doubleValue(for: .meter()) {
            workoutSet.distance = distance
        }
        
        exercise.sets = [workoutSet]
        workout.exercises = [exercise]
        
        return workout
    }
    
    private func workoutName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .mixedCardio: return "Cardio"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .elliptical: return "Elliptical"
        default: return "Workout"
        }
    }
    
    private func muscleGroup(for type: HKWorkoutActivityType) -> MuscleGroup {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .fullBody
        case .running, .cycling, .rowing, .stairClimbing, .swimming, .elliptical, .mixedCardio:
            return .cardio
        case .yoga, .pilates:
            return .core
        default:
            return .other
        }
    }
}

// MARK: - CSV Import Service

actor CSVImportService {
    
    enum CSVFormat {
        case hevy
        case strong
        case generic
        
        static func detect(from headers: [String]) -> CSVFormat {
            let lowercased = headers.map { $0.lowercased() }
            
            if lowercased.contains("exercise_template_id") || lowercased.contains("superset_id") {
                return .hevy
            }
            if lowercased.contains("workout name") && lowercased.contains("set order") {
                return .strong
            }
            return .generic
        }
    }
    
    func importFromCSV(url: URL, modelContext: ModelContext) async throws -> ImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(content)
        
        guard rows.count > 1 else {
            throw ImportError.emptyFile
        }
        
        let headers = rows[0]
        let format = CSVFormat.detect(from: headers)
        
        switch format {
        case .hevy:
            return try await importHevyCSV(rows: rows, headers: headers, modelContext: modelContext)
        case .strong:
            return try await importStrongCSV(rows: rows, headers: headers, modelContext: modelContext)
        case .generic:
            return try await importGenericCSV(rows: rows, headers: headers, modelContext: modelContext)
        }
    }
    
    private func parseCSV(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in content {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else if char == "\n" && !inQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Don't forget the last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        
        return rows
    }
    
    private func importHevyCSV(rows: [[String]], headers: [String], modelContext: ModelContext) async throws -> ImportResult {
        // Hevy CSV format parsing
        // Headers: title, start_time, end_time, description, exercise_title, set_index, weight_kg, reps, etc.
        
        var workouts: [String: Workout] = [:]
        var exerciseCount = 0
        
        let titleIdx = headers.firstIndex(of: "title") ?? 0
        let startIdx = headers.firstIndex(of: "start_time") ?? 1
        let exerciseIdx = headers.firstIndex(of: "exercise_title") ?? headers.firstIndex(of: "Exercise Name") ?? 4
        let weightIdx = headers.firstIndex(of: "weight_kg") ?? headers.firstIndex(of: "Weight") ?? 6
        let repsIdx = headers.firstIndex(of: "reps") ?? headers.firstIndex(of: "Reps") ?? 7
        
        for row in rows.dropFirst() {
            guard row.count > max(titleIdx, startIdx, exerciseIdx, weightIdx, repsIdx) else { continue }
            
            let workoutTitle = row[titleIdx]
            let workoutKey = "\(workoutTitle)_\(row[startIdx])"
            
            if workouts[workoutKey] == nil {
                let dateFormatter = ISO8601DateFormatter()
                let date = dateFormatter.date(from: row[startIdx]) ?? Date()
                
                let workout = Workout(name: workoutTitle, date: date)
                workout.exercises = []
                workouts[workoutKey] = workout
            }
            
            // Add exercise/set
            if let workout = workouts[workoutKey] {
                let exerciseName = row[exerciseIdx]
                let weight = Double(row[weightIdx]) ?? 0
                let reps = Int(row[repsIdx]) ?? 0
                
                // Find or create exercise
                if let existingExercise = workout.exercises?.first(where: { $0.name == exerciseName }) {
                    let set = WorkoutSet(
                        order: existingExercise.sets?.count ?? 0,
                        weight: weight * 2.20462,
                        reps: reps,
                        setType: .working,
                        isCompleted: true
                    )
                    existingExercise.sets?.append(set)
                } else {
                    let exercise = Exercise(
                        name: exerciseName,
                        primaryMuscle: .other,
                        equipment: .barbell,
                        order: workout.exercises?.count ?? 0
                    )
                    let set = WorkoutSet(order: 0, weight: weight * 2.20462, reps: reps, setType: .working, isCompleted: true)
                    exercise.sets = [set]
                    workout.exercises?.append(exercise)
                    exerciseCount += 1
                }
            }
        }
        
        // Save all workouts
        await MainActor.run {
            for workout in workouts.values {
                modelContext.insert(workout)
            }
            try? modelContext.save()
        }
        
        return ImportResult(
            workoutsImported: workouts.count,
            exercisesImported: exerciseCount,
            errors: []
        )
    }
    
    private func importStrongCSV(rows: [[String]], headers: [String], modelContext: ModelContext) async throws -> ImportResult {
        // Strong app CSV format
        // Headers: Date, Workout Name, Exercise Name, Set Order, Weight, Reps, etc.
        
        var workouts: [String: Workout] = [:]
        var exerciseCount = 0
        
        let dateIdx = headers.firstIndex(where: { $0.lowercased() == "date" }) ?? 0
        let workoutNameIdx = headers.firstIndex(where: { $0.lowercased() == "workout name" }) ?? 1
        let exerciseIdx = headers.firstIndex(where: { $0.lowercased() == "exercise name" }) ?? 2
        let weightIdx = headers.firstIndex(where: { $0.lowercased() == "weight" }) ?? 4
        let repsIdx = headers.firstIndex(where: { $0.lowercased() == "reps" }) ?? 5
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows.dropFirst() {
            guard row.count > max(dateIdx, workoutNameIdx, exerciseIdx, weightIdx, repsIdx) else { continue }
            
            let dateStr = row[dateIdx]
            let workoutName = row[workoutNameIdx]
            let workoutKey = "\(workoutName)_\(dateStr)"
            
            if workouts[workoutKey] == nil {
                let date = dateFormatter.date(from: dateStr) ?? Date()
                let workout = Workout(name: workoutName, date: date)
                workout.exercises = []
                workouts[workoutKey] = workout
            }
            
            if let workout = workouts[workoutKey] {
                let exerciseName = row[exerciseIdx]
                let weight = Double(row[weightIdx]) ?? 0
                let reps = Int(row[repsIdx]) ?? 0
                
                if let existingExercise = workout.exercises?.first(where: { $0.name == exerciseName }) {
                    let set = WorkoutSet(
                        order: existingExercise.sets?.count ?? 0,
                        weight: weight,
                        reps: reps,
                        setType: .working,
                        isCompleted: true
                    )
                    existingExercise.sets?.append(set)
                } else {
                    let exercise = Exercise(
                        name: exerciseName,
                        primaryMuscle: .other,
                        equipment: .barbell,
                        order: workout.exercises?.count ?? 0
                    )
                    let set = WorkoutSet(order: 0, weight: weight, reps: reps, setType: .working, isCompleted: true)
                    exercise.sets = [set]
                    workout.exercises?.append(exercise)
                    exerciseCount += 1
                }
            }
        }
        
        await MainActor.run {
            for workout in workouts.values {
                modelContext.insert(workout)
            }
            try? modelContext.save()
        }
        
        return ImportResult(
            workoutsImported: workouts.count,
            exercisesImported: exerciseCount,
            errors: []
        )
    }
    
    private func importGenericCSV(rows: [[String]], headers: [String], modelContext: ModelContext) async throws -> ImportResult {
        // Generic CSV - try to find common column names
        let lowercased = headers.map { $0.lowercased() }
        
        let dateIdx = lowercased.firstIndex(where: { $0.contains("date") }) ?? 0
        let exerciseIdx = lowercased.firstIndex(where: { $0.contains("exercise") }) ?? 1
        let weightIdx = lowercased.firstIndex(where: { $0.contains("weight") }) ?? 2
        let repsIdx = lowercased.firstIndex(where: { $0.contains("rep") }) ?? 3
        
        var workouts: [String: Workout] = [:]
        var exerciseCount = 0
        
        for row in rows.dropFirst() {
            guard row.count > max(dateIdx, exerciseIdx, weightIdx, repsIdx) else { continue }
            
            let dateStr = row[dateIdx]
            let workoutKey = dateStr
            
            if workouts[workoutKey] == nil {
                let workout = Workout(name: "Imported Workout", date: Date())
                workout.exercises = []
                workouts[workoutKey] = workout
            }
            
            if let workout = workouts[workoutKey] {
                let exerciseName = row[exerciseIdx]
                let weight = Double(row[weightIdx]) ?? 0
                let reps = Int(row[repsIdx]) ?? 0
                
                if let existingExercise = workout.exercises?.first(where: { $0.name == exerciseName }) {
                    let set = WorkoutSet(
                        order: existingExercise.sets?.count ?? 0,
                        weight: weight,
                        reps: reps,
                        setType: .working,
                        isCompleted: true
                    )
                    existingExercise.sets?.append(set)
                } else {
                    let exercise = Exercise(
                        name: exerciseName,
                        primaryMuscle: .other,
                        equipment: .barbell,
                        order: workout.exercises?.count ?? 0
                    )
                    let set = WorkoutSet(order: 0, weight: weight, reps: reps, setType: .working, isCompleted: true)
                    exercise.sets = [set]
                    workout.exercises?.append(exercise)
                    exerciseCount += 1
                }
            }
        }
        
        await MainActor.run {
            for workout in workouts.values {
                modelContext.insert(workout)
            }
            try? modelContext.save()
        }
        
        return ImportResult(
            workoutsImported: workouts.count,
            exercisesImported: exerciseCount,
            errors: []
        )
    }
}

// MARK: - Errors

enum ImportError: LocalizedError {
    case apiError
    case emptyFile
    case invalidFormat
    case healthKitNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .apiError: return "Failed to connect to API"
        case .emptyFile: return "The file is empty"
        case .invalidFormat: return "Invalid file format"
        case .healthKitNotAvailable: return "HealthKit is not available on this device"
        }
    }
}
