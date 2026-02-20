//
//  OnboardingView.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "bubble.left.and.text.bubble.right.fill",
            title: "Chat to Log",
            description: "Just describe your workout naturally. Type \"Bench 135x10, 185x8, 205x6\" and we'll parse it for you.",
            color: .red
        ),
        OnboardingPage(
            icon: "mic.fill",
            title: "Voice Input",
            description: "Tap the mic and speak your workout. Perfect for logging between sets without typing.",
            color: .orange
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "Quick Start",
            description: "Use templates like Push Day, Pull Day, or Leg Day to quickly populate common exercises.",
            color: .yellow
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Progress",
            description: "See your volume over time, track PRs, and visualize your gains across muscle groups.",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundStyle(.secondary)
                .padding()
            }
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 32)
            
            // Continue/Get Started button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.backgroundPrimary)
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.color)
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
