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
    
    @State private var showingImport = false
    
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
            
            // Import section
            Section("Import Data") {
                Button {
                    showingImport = true
                } label: {
                    Label("Import Workouts", systemImage: "square.and.arrow.down")
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
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
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
    @State private var apiKey: String = ""
    @State private var showingSaveConfirmation = false
    @State private var hasChanges = false
    
    private var isValidKey: Bool {
        apiKey.isEmpty || KeychainService.isValidAnthropicKey(apiKey)
    }
    
    var body: some View {
        Form {
            Section {
                SecureField("Anthropic API Key", text: $apiKey)
                    .onChange(of: apiKey) { _, _ in
                        hasChanges = true
                    }
                
                // Validation feedback
                if !apiKey.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: isValidKey ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(isValidKey ? .green : .orange)
                        Text(isValidKey ? "Valid format" : "Should start with sk-ant-")
                            .font(.system(size: 12))
                            .foregroundStyle(isValidKey ? .green : .orange)
                    }
                }
            } header: {
                Text("API Key")
            } footer: {
                Text("Used for AI-powered workout parsing. Get your key from console.anthropic.com")
            }
            
            Section {
                Button {
                    saveApiKey()
                } label: {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Save to Keychain")
                    }
                }
                .disabled(!hasChanges || (!apiKey.isEmpty && !isValidKey))
                
                if KeychainService.exists(key: .anthropicApiKey) {
                    Button(role: .destructive) {
                        deleteApiKey()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove API Key")
                        }
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it works")
                        .font(.headline)
                    
                    Text("When you describe a workout in natural language, LiftLog uses Claude AI to parse it into structured data. This costs about $0.002 per workout logged.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text("Security")
                            .font(.headline)
                    }
                    
                    Text("Your API key is stored in the iOS Keychain, encrypted and protected by your device passcode.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("AI Settings")
        .onAppear {
            // Load existing key (masked)
            if let existingKey = KeychainService.get(key: .anthropicApiKey) {
                // Show masked version
                apiKey = existingKey
            }
            hasChanges = false
        }
        .alert("Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("API key saved securely to Keychain")
        }
    }
    
    private func saveApiKey() {
        do {
            if apiKey.isEmpty {
                try KeychainService.delete(key: .anthropicApiKey)
            } else {
                try KeychainService.save(key: .anthropicApiKey, value: apiKey)
            }
            hasChanges = false
            showingSaveConfirmation = true
        } catch {
            // Handle error
        }
    }
    
    private func deleteApiKey() {
        try? KeychainService.delete(key: .anthropicApiKey)
        apiKey = ""
        hasChanges = false
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
