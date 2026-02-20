//
//  WorkoutDetailView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header stats
                headerStats
                
                // Exercises
                exercisesList
                
                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // Edit workout
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        // Share workout
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(workout)
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStats: some View {
        HStack(spacing: 16) {
            StatPill(
                icon: "clock",
                value: workout.formattedDuration,
                label: "Duration"
            )
            
            StatPill(
                icon: "scalemass",
                value: workout.formattedVolume,
                label: "Volume"
            )
            
            StatPill(
                icon: "number",
                value: "\(workout.totalSets)",
                label: "Sets"
            )
        }
    }
    
    // MARK: - Exercises List
    
    private var exercisesList: some View {
        VStack(spacing: 16) {
            ForEach(Array(workout.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseCard(exercise, index: index + 1)
            }
        }
    }
    
    private func exerciseCard(_ exercise: Exercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Text("\(index). \(exercise.name)")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Text(exercise.primaryMuscle.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.15))
                    )
            }
            
            // Sets table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Spacer()
                    Text("WEIGHT")
                        .frame(width: 80)
                    Text("REPS")
                        .frame(width: 50)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
                
                // Rows
                ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { setIndex, set in
                    HStack {
                        // Set number with type indicator
                        HStack(spacing: 4) {
                            Text("\(setIndex + 1)")
                                .font(.system(size: 14, weight: .medium))
                            
                            if set.setType != .working {
                                Text(set.setType.rawValue.prefix(1))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(colorForSetType(set.setType)))
                            }
                        }
                        .frame(width: 40, alignment: .leading)
                        
                        Spacer()
                        
                        // Weight
                        Text(set.formattedWeight)
                            .font(.system(size: 15))
                            .frame(width: 80)
                        
                        // Reps
                        Text("\(set.reps)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(width: 50)
                    }
                    .padding(.vertical, 8)
                    
                    if setIndex < exercise.sortedSets.count - 1 {
                        Divider()
                    }
                }
            }
            
            // Exercise notes
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private func notesSection(_ notes: String) -> some View {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private func colorForSetType(_ type: SetType) -> Color {
        switch type {
        case .working: return .gray
        case .warmup: return .orange
        case .dropset: return .purple
        case .failure: return .red
        case .amrap: return .green
        }
    }
}

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    let workout = Workout(name: "Push Day")
    workout.start()
    
    let bench = Exercise(name: "Bench Press", primaryMuscle: .chest, equipment: .barbell, order: 0)
    bench.sets = [
        WorkoutSet(order: 0, weight: 135, reps: 10, setType: .warmup, isCompleted: true),
        WorkoutSet(order: 1, weight: 185, reps: 8, setType: .working, isCompleted: true),
        WorkoutSet(order: 2, weight: 205, reps: 6, setType: .working, isCompleted: true),
        WorkoutSet(order: 3, weight: 225, reps: 4, setType: .working, isCompleted: true)
    ]
    workout.exercises = [bench]
    
    return NavigationStack {
        WorkoutDetailView(workout: workout)
    }
}
