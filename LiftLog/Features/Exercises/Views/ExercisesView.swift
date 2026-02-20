//
//  ExercisesView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    
    @Query(sort: \ExerciseTemplate.name)
    private var exercises: [ExerciseTemplate]
    
    private var filteredExercises: [ExerciseTemplate] {
        var result = exercises.isEmpty ? defaultExercises : exercises
        
        if let muscle = selectedMuscle {
            result = result.filter { $0.primaryMuscle == muscle }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Muscle group filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedMuscle == nil) {
                        selectedMuscle = nil
                    }
                    
                    ForEach(MuscleGroup.allCases.filter { $0 != .other }, id: \.self) { muscle in
                        FilterChip(title: muscle.rawValue, isSelected: selectedMuscle == muscle) {
                            selectedMuscle = muscle
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Exercise list
            List {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            }
            .listStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Add custom exercise
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    // Default exercise library
    private var defaultExercises: [ExerciseTemplate] {
        [
            // Chest
            ExerciseTemplate(name: "Bench Press", primaryMuscle: .chest, equipment: .barbell),
            ExerciseTemplate(name: "Incline Bench Press", primaryMuscle: .chest, equipment: .barbell),
            ExerciseTemplate(name: "Dumbbell Bench Press", primaryMuscle: .chest, equipment: .dumbbell),
            ExerciseTemplate(name: "Incline Dumbbell Press", primaryMuscle: .chest, equipment: .dumbbell),
            ExerciseTemplate(name: "Cable Flyes", primaryMuscle: .chest, equipment: .cable),
            ExerciseTemplate(name: "Push-ups", primaryMuscle: .chest, equipment: .bodyweight),
            ExerciseTemplate(name: "Dips", primaryMuscle: .chest, secondaryMuscles: [.triceps], equipment: .bodyweight),
            
            // Back
            ExerciseTemplate(name: "Barbell Row", primaryMuscle: .back, equipment: .barbell),
            ExerciseTemplate(name: "Deadlift", primaryMuscle: .back, secondaryMuscles: [.hamstrings, .glutes], equipment: .barbell),
            ExerciseTemplate(name: "Pull-ups", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .bodyweight),
            ExerciseTemplate(name: "Lat Pulldown", primaryMuscle: .back, equipment: .cable),
            ExerciseTemplate(name: "Seated Cable Row", primaryMuscle: .back, equipment: .cable),
            ExerciseTemplate(name: "Dumbbell Row", primaryMuscle: .back, equipment: .dumbbell),
            
            // Shoulders
            ExerciseTemplate(name: "Overhead Press", primaryMuscle: .shoulders, equipment: .barbell),
            ExerciseTemplate(name: "Dumbbell Shoulder Press", primaryMuscle: .shoulders, equipment: .dumbbell),
            ExerciseTemplate(name: "Lateral Raises", primaryMuscle: .shoulders, equipment: .dumbbell),
            ExerciseTemplate(name: "Face Pulls", primaryMuscle: .shoulders, equipment: .cable),
            
            // Arms
            ExerciseTemplate(name: "Barbell Curl", primaryMuscle: .biceps, equipment: .barbell),
            ExerciseTemplate(name: "Dumbbell Curl", primaryMuscle: .biceps, equipment: .dumbbell),
            ExerciseTemplate(name: "Hammer Curl", primaryMuscle: .biceps, equipment: .dumbbell),
            ExerciseTemplate(name: "Tricep Pushdown", primaryMuscle: .triceps, equipment: .cable),
            ExerciseTemplate(name: "Skull Crushers", primaryMuscle: .triceps, equipment: .ezBar),
            ExerciseTemplate(name: "Overhead Tricep Extension", primaryMuscle: .triceps, equipment: .dumbbell),
            
            // Legs
            ExerciseTemplate(name: "Barbell Squat", primaryMuscle: .quadriceps, secondaryMuscles: [.glutes], equipment: .barbell),
            ExerciseTemplate(name: "Leg Press", primaryMuscle: .quadriceps, equipment: .machine),
            ExerciseTemplate(name: "Romanian Deadlift", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes], equipment: .barbell),
            ExerciseTemplate(name: "Leg Curl", primaryMuscle: .hamstrings, equipment: .machine),
            ExerciseTemplate(name: "Leg Extension", primaryMuscle: .quadriceps, equipment: .machine),
            ExerciseTemplate(name: "Calf Raises", primaryMuscle: .calves, equipment: .machine),
            ExerciseTemplate(name: "Hip Thrust", primaryMuscle: .glutes, equipment: .barbell),
            ExerciseTemplate(name: "Lunges", primaryMuscle: .quadriceps, secondaryMuscles: [.glutes], equipment: .dumbbell),
            
            // Core
            ExerciseTemplate(name: "Plank", primaryMuscle: .core, equipment: .bodyweight),
            ExerciseTemplate(name: "Cable Crunch", primaryMuscle: .core, equipment: .cable),
            ExerciseTemplate(name: "Hanging Leg Raise", primaryMuscle: .core, equipment: .bodyweight)
        ]
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.red : Color.gray.opacity(0.15))
                )
        }
    }
}

private struct ExerciseRow: View {
    let exercise: ExerciseTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            // Muscle icon
            Image(systemName: exercise.primaryMuscle.icon)
                .font(.system(size: 20))
                .foregroundStyle(.red)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(exercise.primaryMuscle.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(exercise.equipment.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ExercisesView()
    }
}
