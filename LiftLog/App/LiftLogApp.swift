//
//  LiftLogApp.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData

@main
struct LiftLogApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(for: [
            Workout.self,
            Exercise.self,
            WorkoutSet.self,
            ExerciseTemplate.self
        ])
    }
}
