//
//  ProfileView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Query private var workouts: [Workout]
    
    @AppStorage("userName") private var userName = ""
    @AppStorage("userWeight") private var userWeight = ""
    @AppStorage("anthropic_api_key") private var apiKey = ""
    
    var body: some View {
        List {
            // Profile section
            Section {
                HStack(spacing: 16) {
                    // Avatar
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(userName.prefix(1).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.red)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Your Name", text: $userName)
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("\(workouts.count) workouts logged")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Stats section
            Section("Lifetime Stats") {
                StatRow(label: "Total Workouts", value: "\(workouts.count)")
                StatRow(label: "Total Volume", value: formattedTotalVolume)
                StatRow(label: "Total Sets", value: "\(totalSets)")
                StatRow(label: "Exercises Used", value: "\(uniqueExercises)")
            }
            
            // Settings section
            Section("Settings") {
                HStack {
                    Label("Body Weight", systemImage: "scalemass")
                    Spacer()
                    TextField("lbs", text: $userWeight)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                NavigationLink {
                    APIKeySettingsView()
                } label: {
                    Label("AI Settings", systemImage: "brain")
                }
            }
            
            // App section
            Section("App") {
                NavigationLink {
                    // About view
                } label: {
                    Label("About LiftLog", systemImage: "info.circle")
                }
                
                Link(destination: URL(string: "https://github.com")!) {
                    Label("Rate on App Store", systemImage: "star")
                }
                
                Link(destination: URL(string: "mailto:support@liftlog.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }
            
            // Danger zone
            Section {
                Button(role: .destructive) {
                    // Export data
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    // Delete all data
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Profile")
    }
    
    private var formattedTotalVolume: String {
        let volume = workouts.reduce(0) { $0 + $1.totalVolume }
        if volume >= 1_000_000 {
            return String(format: "%.1fM lbs", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
    
    private var totalSets: Int {
        workouts.reduce(0) { $0 + $1.totalSets }
    }
    
    private var uniqueExercises: Int {
        let names = workouts.flatMap { $0.sortedExercises.map { $0.name } }
        return Set(names).count
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct APIKeySettingsView: View {
    @AppStorage("anthropic_api_key") private var apiKey = ""
    
    var body: some View {
        Form {
            Section {
                SecureField("Anthropic API Key", text: $apiKey)
            } header: {
                Text("API Key")
            } footer: {
                Text("Used for AI-powered workout parsing. Get your key from console.anthropic.com")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it works")
                        .font(.headline)
                    
                    Text("When you describe a workout in natural language, LiftLog uses Claude AI to parse it into structured data. This costs about $0.002 per workout logged.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("AI Settings")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
