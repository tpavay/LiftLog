//
//  Exercise.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import SwiftData

/// Muscle groups for categorizing exercises
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.strengthtraining.functional"
        case .triceps: return "figure.boxing"
        case .forearms: return "hand.raised"
        case .quadriceps: return "figure.walk"
        case .hamstrings: return "figure.run"
        case .glutes: return "figure.hiking"
        case .calves: return "shoeprints.fill"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.cross.training"
        case .cardio: return "heart.fill"
        case .other: return "dumbbell"
        }
    }
}

/// Equipment type for exercises
enum EquipmentType: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case resistanceBand = "Resistance Band"
    case smithMachine = "Smith Machine"
    case ezBar = "EZ Bar"
    case trapBar = "Trap Bar"
    case other = "Other"
}

/// Template for exercises (the exercise catalog)
@Model
final class ExerciseTemplate {
    var id: UUID
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: EquipmentType
    var instructions: String?
    var isCustom: Bool
    var createdAt: Date
    
    init(
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentType,
        instructions: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
        self.createdAt = Date()
    }
}

/// An exercise performed in a workout (instance of a template)
@Model
final class Exercise {
    var id: UUID
    var templateId: UUID
    var name: String
    var primaryMuscle: MuscleGroup
    var equipment: EquipmentType
    var notes: String?
    var order: Int
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet]?
    
    var workout: Workout?
    
    init(
        template: ExerciseTemplate,
        order: Int = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.templateId = template.id
        self.name = template.name
        self.primaryMuscle = template.primaryMuscle
        self.equipment = template.equipment
        self.order = order
        self.notes = notes
        self.sets = []
    }
    
    init(
        name: String,
        primaryMuscle: MuscleGroup,
        equipment: EquipmentType,
        order: Int = 0
    ) {
        self.id = UUID()
        self.templateId = UUID()
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.equipment = equipment
        self.order = order
        self.sets = []
    }
    
    var sortedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.order < $1.order }
    }
    
    var totalVolume: Double {
        sortedSets.reduce(0) { $0 + $1.volume }
    }
}
