//
//  ImportView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isImporting = false
    @State private var importSource: ImportSource?
    @State private var showingFilePicker = false
    @State private var showingHevySetup = false
    @State private var showingResult = false
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?
    
    @AppStorage("hevy_api_key") private var hevyApiKey = ""
    
    enum ImportSource: Identifiable {
        case hevy, appleHealth, csv
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        
                        Text("Import Workouts")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Bring in your workout history from other apps")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Import options
                    VStack(spacing: 12) {
                        ImportOptionCard(
                            icon: "dumbbell.fill",
                            title: "Hevy",
                            description: "Import all workouts with full exercise details",
                            color: .orange,
                            isLoading: isImporting && importSource == .hevy
                        ) {
                            if hevyApiKey.isEmpty {
                                showingHevySetup = true
                            } else {
                                startHevyImport()
                            }
                        }
                        
                        ImportOptionCard(
                            icon: "heart.fill",
                            title: "Apple Health",
                            description: "Import workout summaries from Health app",
                            color: .red,
                            isLoading: isImporting && importSource == .appleHealth
                        ) {
                            startHealthKitImport()
                        }
                        
                        ImportOptionCard(
                            icon: "doc.text.fill",
                            title: "CSV File",
                            description: "Import from Strong, Hevy export, or generic CSV",
                            color: .blue,
                            isLoading: isImporting && importSource == .csv
                        ) {
                            showingFilePicker = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Info section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Import Tips", systemImage: "lightbulb.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            tipRow("Hevy gives you the most detail — all exercises, sets, and weights")
                            tipRow("Apple Health imports workout summaries (duration, calories)")
                            tipRow("CSV works with exports from Strong, Hevy, and similar apps")
                            tipRow("Duplicate workouts are not automatically filtered")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHevySetup) {
                HevySetupSheet(apiKey: $hevyApiKey) {
                    startHevyImport()
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Complete", isPresented: $showingResult) {
                Button("OK") {
                    if importResult?.isSuccess == true {
                        dismiss()
                    }
                }
            } message: {
                if let result = importResult {
                    Text("Imported \(result.workoutsImported) workouts and \(result.exercisesImported) exercises.")
                }
            }
            .alert("Import Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Import Actions
    
    private func startHevyImport() {
        guard !hevyApiKey.isEmpty else { return }
        
        isImporting = true
        importSource = .hevy
        
        Task {
            do {
                let service = HevyImportService()
                let result = try await service.importWorkouts(apiKey: hevyApiKey, modelContext: modelContext)
                
                await MainActor.run {
                    isImporting = false
                    importResult = result
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func startHealthKitImport() {
        let service = HealthKitImportService()
        
        guard service.isAvailable else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        isImporting = true
        importSource = .appleHealth
        
        Task {
            do {
                try await service.requestAuthorization()
                let result = try await service.importWorkouts(modelContext: modelContext)
                
                await MainActor.run {
                    isImporting = false
                    importResult = result
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isImporting = true
            importSource = .csv
            
            // Need to start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the file"
                isImporting = false
                return
            }
            
            Task {
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let service = CSVImportService()
                    let result = try await service.importFromCSV(url: url, modelContext: modelContext)
                    
                    await MainActor.run {
                        isImporting = false
                        importResult = result
                        showingResult = true
                    }
                } catch {
                    await MainActor.run {
                        isImporting = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Import Option Card

struct ImportOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundStyle(color)
                    }
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackground)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Hevy Setup Sheet

struct HevySetupSheet: View {
    @Binding var apiKey: String
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var inputKey = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                }
                .padding(.top, 40)
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Connect to Hevy")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("To import your Hevy workouts, you'll need your API key.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    stepRow(1, "Open hevy.com/settings?developer")
                    stepRow(2, "Generate or copy your API key")
                    stepRow(3, "Paste it below")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .padding(.horizontal, 20)
                
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    SecureField("Paste your Hevy API key", text: $inputKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Connect button
                Button {
                    apiKey = inputKey
                    dismiss()
                    onComplete()
                } label: {
                    Text("Connect & Import")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(inputKey.isEmpty ? Color.gray : Color.orange)
                        )
                }
                .disabled(inputKey.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Hevy Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.orange))
            
            Text(text)
                .font(.system(size: 15))
        }
    }
}

// MARK: - Preview

#Preview {
    ImportView()
}
