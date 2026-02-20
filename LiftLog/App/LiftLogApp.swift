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
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            Workout.self,
            Exercise.self,
            WorkoutSet.self,
            ExerciseTemplate.self
        ])
    }
}
