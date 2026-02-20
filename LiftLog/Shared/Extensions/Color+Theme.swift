//
//  Color+Theme.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import SwiftUI

extension Color {
    // Primary accent - Red
    static let accent = Color.red
    static let accentLight = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let accentDark = Color(red: 0.8, green: 0.1, blue: 0.1)
    
    // Background colors
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    // Card backgrounds
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let cardBackgroundDark = Color(red: 0.12, green: 0.12, blue: 0.14)
    
    // Text colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // Muscle group colors
    static let muscleChest = Color.red
    static let muscleBack = Color.blue
    static let muscleShoulders = Color.orange
    static let muscleArms = Color.purple
    static let muscleLegs = Color.green
    static let muscleCore = Color.yellow
}

extension ShapeStyle where Self == Color {
    static var accent: Color { .red }
}
