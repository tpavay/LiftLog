//
//  WorkoutConfirmationView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI

/// Confirmation view for reviewing parsed workout before saving
struct WorkoutConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let parsedData: ParsedWorkoutData
    let onConfirm: (ParsedWorkoutData) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Workout name
                    if let name = parsedData.workoutName {
                        workoutNameCard(name)
                    }
                    
                    // Exercises
                    ForEach(Array(parsedData.exercises.enumerated()), id: \.offset) { index, exercise in
                        exerciseCard(exercise, index: index + 1)
                    }
                    
                    // Notes
                    if let notes = parsedData.notes {
                        notesCard(notes)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Confirm Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onConfirm(parsedData)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                }
            }
        }
    }
    
    private func workoutNameCard(_ name: String) -> some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(.red)
            
            Text(name)
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private func exerciseCard(_ exercise: ParsedWorkoutData.ParsedExercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Text("\(index). \(exercise.name)")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("\(exercise.sets.count) sets")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            // Sets
            VStack(spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack {
                        // Set number
                        Text("Set \(setIndex + 1)")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                        
                        Spacer()
                        
                        // Weight
                        if let weight = set.weight {
                            Text("\(Int(weight)) lbs")
                                .font(.system(size: 15, weight: .medium))
                        } else {
                            Text("BW")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("×")
                            .foregroundStyle(.secondary)
                        
                        // Reps
                        Text("\(set.reps)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                        
                        // Set type badge
                        if let type = set.setType, type != "working" {
                            Text(type.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(colorForSetType(type))
                                )
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if setIndex < exercise.sets.count - 1 {
                        Divider()
                    }
                }
            }
            
            // Exercise notes
            if let notes = exercise.notes {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text(notes)
                .font(.system(size: 15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private func colorForSetType(_ type: String) -> Color {
        switch type.lowercased() {
        case "warmup": return .orange
        case "dropset": return .purple
        case "failure": return .red
        case "amrap": return .green
        default: return .gray
        }
    }
}

#Preview {
    WorkoutConfirmationView(
        parsedData: ParsedWorkoutData(
            exercises: [
                .init(name: "Bench Press", sets: [
                    .init(weight: 135, reps: 10, setType: "warmup"),
                    .init(weight: 185, reps: 8, setType: "working"),
                    .init(weight: 205, reps: 6, setType: "working"),
                    .init(weight: 225, reps: 4, setType: "working")
                ], notes: nil),
                .init(name: "Incline Dumbbell Press", sets: [
                    .init(weight: 60, reps: 10, setType: "working"),
                    .init(weight: 60, reps: 10, setType: "working"),
                    .init(weight: 60, reps: 8, setType: "working")
                ], notes: "Focus on stretch at bottom")
            ],
            workoutName: "Push Day",
            notes: "Felt strong today"
        ),
        onConfirm: { _ in },
        onCancel: { }
    )
}
