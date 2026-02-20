//
//  HistoryView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort: \Workout.date, order: .reverse)
    private var workouts: [Workout]
    
    var body: some View {
        Group {
            if workouts.isEmpty {
                emptyState
            } else {
                workoutList
            }
        }
        .navigationTitle("History")
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Workouts Yet")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Your workout history will appear here")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var workoutList: some View {
        List {
            ForEach(groupedWorkouts, id: \.key) { month, monthWorkouts in
                Section(header: Text(month)) {
                    ForEach(monthWorkouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutHistoryRow(workout: workout)
                        }
                    }
                    .onDelete { indexSet in
                        deleteWorkouts(at: indexSet, from: monthWorkouts)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var groupedWorkouts: [(key: String, value: [Workout])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: workouts) { workout in
            formatter.string(from: workout.date)
        }
        
        return grouped.sorted { $0.value.first?.date ?? Date() > $1.value.first?.date ?? Date() }
    }
    
    private func deleteWorkouts(at offsets: IndexSet, from workouts: [Workout]) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
    }
}

private struct WorkoutHistoryRow: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.sortedExercises.count) exercises")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
                
                if let duration = workout.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: workout.date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
