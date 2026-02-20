//
//  ProgressView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Workout.date, order: .reverse)
    private var workouts: [Workout]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats overview
                statsOverview
                
                // Volume chart
                volumeChart
                
                // Workout frequency
                frequencyChart
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Progress")
    }
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "This Week",
                value: "\(workoutsThisWeek)",
                subtitle: "workouts",
                icon: "flame.fill",
                color: .red
            )
            
            StatCard(
                title: "Volume",
                value: formattedWeeklyVolume,
                subtitle: "this week",
                icon: "scalemass.fill",
                color: .blue
            )
            
            StatCard(
                title: "Streak",
                value: "\(currentStreak)",
                subtitle: "days",
                icon: "bolt.fill",
                color: .orange
            )
        }
    }
    
    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Volume")
                .font(.system(size: 16, weight: .semibold))
            
            if weeklyVolumeData.isEmpty {
                Text("Log workouts to see volume trends")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(weeklyVolumeData, id: \.week) { data in
                    BarMark(
                        x: .value("Week", data.week),
                        y: .value("Volume", data.volume)
                    )
                    .foregroundStyle(.red.gradient)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }
    
    private var frequencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Frequency")
                .font(.system(size: 16, weight: .semibold))
            
            // Muscle group breakdown
            if muscleGroupBreakdown.isEmpty {
                Text("Log workouts to see muscle group breakdown")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(muscleGroupBreakdown.prefix(5), id: \.group) { item in
                        HStack {
                            Text(item.group.rawValue)
                                .font(.system(size: 14))
                            
                            Spacer()
                            
                            Text("\(item.count) sets")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - Computed Stats
    
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return workouts.filter { $0.date >= weekAgo }.count
    }
    
    private var formattedWeeklyVolume: String {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let volume = workouts
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.totalVolume }
        
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
    
    private var currentStreak: Int {
        // Simplified streak calculation
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for _ in 0..<30 {
            if workouts.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var weeklyVolumeData: [(week: String, volume: Double)] {
        let calendar = Calendar.current
        var data: [(week: String, volume: Double)] = []
        
        for weeksAgo in (0..<4).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let volume = workouts
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0) { $0 + $1.totalVolume }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            data.append((week: formatter.string(from: weekStart), volume: volume))
        }
        
        return data
    }
    
    private var muscleGroupBreakdown: [(group: MuscleGroup, count: Int)] {
        var counts: [MuscleGroup: Int] = [:]
        
        for workout in workouts {
            for exercise in workout.sortedExercises {
                counts[exercise.primaryMuscle, default: 0] += exercise.sets?.count ?? 0
            }
        }
        
        return counts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    NavigationStack {
        ProgressView()
    }
}
