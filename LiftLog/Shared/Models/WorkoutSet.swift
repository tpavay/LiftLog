//
//  WorkoutSet.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import SwiftData

/// Type of set
enum SetType: String, Codable, CaseIterable {
    case working = "Working"
    case warmup = "Warmup"
    case dropset = "Dropset"
    case failure = "To Failure"
    case amrap = "AMRAP"
    
    var color: String {
        switch self {
        case .working: return "primary"
        case .warmup: return "orange"
        case .dropset: return "purple"
        case .failure: return "red"
        case .amrap: return "green"
        }
    }
}

/// A single set within an exercise
@Model
final class WorkoutSet {
    var id: UUID
    var order: Int
    var weight: Double // in lbs
    var reps: Int
    var setType: SetType
    var isCompleted: Bool
    var rpe: Double? // Rate of perceived exertion (1-10)
    var notes: String?
    var completedAt: Date?
    
    var exercise: Exercise?
    
    init(
        order: Int,
        weight: Double = 0,
        reps: Int = 0,
        setType: SetType = .working,
        isCompleted: Bool = false,
        rpe: Double? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.order = order
        self.weight = weight
        self.reps = reps
        self.setType = setType
        self.isCompleted = isCompleted
        self.rpe = rpe
        self.notes = notes
    }
    
    /// Volume = weight × reps
    var volume: Double {
        weight * Double(reps)
    }
    
    /// Format weight for display
    var formattedWeight: String {
        if weight == 0 { return "BW" } // Bodyweight
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) lbs"
        }
        return String(format: "%.1f lbs", weight)
    }
    
    /// Format set for display (e.g., "135 × 10")
    var formattedSet: String {
        let weightStr = weight == 0 ? "BW" : "\(Int(weight))"
        return "\(weightStr) × \(reps)"
    }
    
    /// Mark this set as completed
    func complete() {
        isCompleted = true
        completedAt = Date()
    }
}
