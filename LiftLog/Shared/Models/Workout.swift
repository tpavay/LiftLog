//
//  Workout.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import SwiftData

/// A complete workout session
@Model
final class Workout {
    var id: UUID
    var name: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var notes: String?
    var isTemplate: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]?
    
    init(
        name: String = "",
        date: Date = Date(),
        notes: String? = nil,
        isTemplate: Bool = false
    ) {
        self.id = UUID()
        self.name = name.isEmpty ? Workout.generateDefaultName(for: date) : name
        self.date = date
        self.notes = notes
        self.isTemplate = isTemplate
        self.exercises = []
    }
    
    // MARK: - Computed Properties
    
    var sortedExercises: [Exercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }
    
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "--" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
    
    var totalVolume: Double {
        sortedExercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: totalVolume)) ?? "0") + " lbs"
    }
    
    var totalSets: Int {
        sortedExercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }
    }
    
    var muscleGroupsWorked: [MuscleGroup] {
        let groups = sortedExercises.map { $0.primaryMuscle }
        return Array(Set(groups))
    }
    
    // MARK: - Methods
    
    func start() {
        startTime = Date()
    }
    
    func finish() {
        endTime = Date()
    }
    
    func addExercise(_ exercise: Exercise) {
        exercise.order = (exercises?.count ?? 0)
        exercises?.append(exercise)
    }
    
    // MARK: - Static Methods
    
    static func generateDefaultName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date)
        
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "Morning"
        case 12..<17: timeOfDay = "Afternoon"
        case 17..<21: timeOfDay = "Evening"
        default: timeOfDay = "Night"
        }
        
        return "\(timeOfDay) Workout"
    }
}
