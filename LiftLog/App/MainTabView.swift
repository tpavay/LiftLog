//
//  MainTabView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Chat-first logging
            NavigationStack {
                ChatHomeView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Log")
            }
            .tag(0)
            
            // History
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("History")
            }
            .tag(1)
            
            // Exercises library
            NavigationStack {
                ExercisesView()
            }
            .tabItem {
                Image(systemName: "dumbbell.fill")
                Text("Exercises")
            }
            .tag(2)
            
            // Progress/Stats
            NavigationStack {
                ProgressView()
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Progress")
            }
            .tag(3)
            
            // Profile
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(4)
        }
        .tint(.red)
    }
}

#Preview {
    MainTabView()
}
