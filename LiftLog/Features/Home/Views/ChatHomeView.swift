//
//  ChatHomeView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData

/// Chat-first home screen for logging workouts conversationally
struct ChatHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort: \Workout.date, order: .reverse)
    private var recentWorkouts: [Workout]
    
    @State private var userInput = ""
    @State private var isProcessing = false
    @State private var parsedWorkout: ParsedWorkoutData?
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let examplePhrases = [
        "Bench press 135x10, 185x8, 205x6...",
        "Squats: warmup 135, then 225 for 5x3...",
        "Push day - bench, incline, flyes...",
        "Pull-ups 3x10, rows 135x12...",
        "Deadlift 315x5, 365x3, 405x1..."
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Chat input card
                inputCard
                
                // Quick actions
                quickActions
                
                // Recent workouts
                if !recentWorkouts.isEmpty {
                    recentSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("")
        .sheet(isPresented: $showConfirmation) {
            if let workout = parsedWorkout {
                WorkoutConfirmationView(
                    parsedData: workout,
                    onConfirm: { saveWorkout($0) },
                    onCancel: { showConfirmation = false }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Log Workout")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)
            
            Text("Describe your workout naturally")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    // MARK: - Input Card
    
    private var inputCard: some View {
        VStack(spacing: 16) {
            // Animated placeholder or input
            if userInput.isEmpty {
                TypewriterText(phrases: examplePhrases)
                    .frame(minHeight: 60)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            } else {
                TextField("Describe your workout...", text: $userInput, axis: .vertical)
                    .font(.system(size: 17))
                    .lineLimit(3...6)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Action buttons
            HStack(spacing: 12) {
                // Voice button
                Button {
                    // TODO: Voice input
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18))
                        Text("Voice")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.15))
                    )
                }
                
                // Log button
                Button {
                    processInput()
                } label: {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(isProcessing ? "Processing" : "Log")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(userInput.isEmpty ? Color.gray : Color.red)
                    )
                }
                .disabled(userInput.isEmpty || isProcessing)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(title: "Empty Workout", icon: "plus") {
                        // Start empty workout
                    }
                    
                    QuickActionButton(title: "Push Day", icon: "figure.strengthtraining.traditional") {
                        userInput = "Push day: bench press, incline dumbbell press, cable flyes, tricep pushdowns"
                    }
                    
                    QuickActionButton(title: "Pull Day", icon: "figure.rowing") {
                        userInput = "Pull day: pull-ups, barbell rows, lat pulldowns, bicep curls"
                    }
                    
                    QuickActionButton(title: "Leg Day", icon: "figure.walk") {
                        userInput = "Leg day: squats, romanian deadlifts, leg press, calf raises"
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Workouts
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink("See All") {
                    HistoryView()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
            }
            
            ForEach(recentWorkouts.prefix(3)) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    RecentWorkoutRow(workout: workout)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    
    private func processInput() {
        guard !userInput.isEmpty else { return }
        isProcessing = true
        
        Task {
            do {
                let service = WorkoutParsingService()
                let parsed = try await service.parseWorkoutDescription(userInput)
                
                await MainActor.run {
                    parsedWorkout = parsed
                    showConfirmation = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func saveWorkout(_ data: ParsedWorkoutData) {
        let workout = Workout(name: data.workoutName ?? "Workout", notes: data.notes)
        workout.start()
        
        for (index, parsedExercise) in data.exercises.enumerated() {
            let exercise = Exercise(
                name: parsedExercise.name,
                primaryMuscle: .other, // Would need exercise matching
                equipment: .barbell,
                order: index
            )
            exercise.notes = parsedExercise.notes
            
            for (setIndex, parsedSet) in parsedExercise.sets.enumerated() {
                let workoutSet = WorkoutSet(
                    order: setIndex,
                    weight: parsedSet.weight ?? 0,
                    reps: parsedSet.reps,
                    setType: SetType(rawValue: parsedSet.setType?.capitalized ?? "Working") ?? .working,
                    isCompleted: true
                )
                workoutSet.complete()
                exercise.sets?.append(workoutSet)
            }
            
            workout.addExercise(exercise)
        }
        
        workout.finish()
        modelContext.insert(workout)
        
        showConfirmation = false
        userInput = ""
    }
}

// MARK: - Supporting Views

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.red)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(width: 90, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
}

private struct RecentWorkoutRow: View {
    let workout: Workout
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.sortedExercises.count) exercises")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
                
                Text(workout.formattedVolume)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(workout.date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDateInYesterday(workout.date) {
            formatter.dateFormat = "'Yesterday'"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: workout.date)
    }
}

// MARK: - Typewriter Text

struct TypewriterText: View {
    let phrases: [String]
    
    @State private var displayedText = ""
    @State private var currentPhraseIndex = 0
    @State private var charIndex = 0
    
    var body: some View {
        Text(displayedText)
            .font(.system(size: 17))
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { startTyping() }
    }
    
    private func startTyping() {
        guard !phrases.isEmpty else { return }
        typeNextChar()
    }
    
    private func typeNextChar() {
        let phrase = phrases[currentPhraseIndex]
        
        if charIndex < phrase.count {
            let idx = phrase.index(phrase.startIndex, offsetBy: charIndex)
            displayedText = String(phrase[...idx])
            charIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { typeNextChar() }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { eraseText() }
        }
    }
    
    private func eraseText() {
        if !displayedText.isEmpty {
            displayedText = String(displayedText.dropLast())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { eraseText() }
        } else {
            currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
            charIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { typeNextChar() }
        }
    }
}

#Preview {
    NavigationStack {
        ChatHomeView()
    }
}
