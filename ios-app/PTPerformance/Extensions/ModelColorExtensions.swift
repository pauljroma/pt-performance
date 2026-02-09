//
//  ModelColorExtensions.swift
//  PTPerformance
//
//  Provides SwiftUI Color computed properties for model types.
//  Models store colorName as String, these extensions convert to Color.
//  This keeps Models as pure Swift (no SwiftUI import required).
//

import SwiftUI

// MARK: - Color Name Conversion

/// Converts a color name string to a SwiftUI Color
/// Supports standard SwiftUI colors and custom Modus brand colors
func colorFromName(_ name: String) -> Color {
    switch name.lowercased() {
    // Standard SwiftUI Colors
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "mint": return .mint
    case "teal": return .teal
    case "cyan": return .cyan
    case "blue": return .blue
    case "indigo": return .indigo
    case "purple": return .purple
    case "pink": return .pink
    case "brown": return .brown
    case "gray", "grey": return .gray
    case "black": return .black
    case "white": return .white
    case "clear": return .clear
    case "primary": return .primary
    case "secondary": return .secondary

    // Modus Brand Colors
    case "modustealaccent", "modus_teal_accent": return .modusTealAccent
    case "modusdeepteal", "modus_deep_teal": return .modusDeepTeal
    case "moducyan", "moduscyan", "modus_cyan": return .modusCyan
    case "moduslightteal", "modus_light_teal": return .modusLightTeal
    case "modusprimary", "modus_primary": return .modusPrimary
    case "modustint", "modus_tint": return .modusTint
    case "modussuccess", "modus_success": return .modusSuccess
    case "modusbackground", "modus_background": return .modusBackground

    // Achievement Tier Colors (custom RGB)
    case "bronze": return Color(red: 0.8, green: 0.5, blue: 0.2)
    case "silver": return Color(red: 0.75, green: 0.75, blue: 0.8)
    case "gold": return .yellow
    case "platinum": return Color(red: 0.9, green: 0.9, blue: 1.0)
    case "diamond": return .cyan

    // Default fallback
    default: return .gray
    }
}

// MARK: - Model Color Extensions
// Each extension provides only `var color: Color` using the model's `colorName` property

extension TimerCategory {
    var color: Color { colorFromName(colorName) }
}

extension ProgramType {
    var color: Color { colorFromName(colorName) }
}

extension ReadinessBand {
    var color: Color { colorFromName(colorName) }
}

extension ReadinessCategory {
    var color: Color { colorFromName(colorName) }
}

extension ReadinessScoreHelper {
    var color: Color { category.color }
}

extension AchievementType {
    var color: Color { colorFromName(colorName) }
}

extension AchievementTier {
    var color: Color { colorFromName(colorName) }
    var glowColor: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.5)
        case .silver: return Color.gray.opacity(0.5)
        case .gold: return Color.yellow.opacity(0.6)
        case .platinum: return Color.white.opacity(0.7)
        case .diamond: return Color.cyan.opacity(0.8)
        }
    }
}

extension PRCelebrationType {
    var color: Color { colorFromName(colorName) }
}

extension AlertType {
    var color: Color { colorFromName(colorName) }
}

extension CoachingAlertSeverity {
    var color: Color { colorFromName(colorName) }
}

extension AlertStatus {
    var color: Color { colorFromName(colorName) }
}

extension PatientAlert {
    var color: Color { colorFromName(colorName) }
}

extension WorkloadFlag.Severity {
    var color: Color { colorFromName(colorName) }
}

extension WorkloadFlag {
    var color: Color { severity.color }
}

extension StreakType {
    var color: Color { colorFromName(colorName) }
}

extension StreakBadge {
    var color: Color { colorFromName(colorName) }
}

extension GoalCategory {
    var color: Color { colorFromName(colorName) }
}

extension EnrollmentStatus {
    var color: Color { colorFromName(colorName) }
}

// MARK: - DailyReadiness Extension

extension DailyReadiness {
    var scoreColor: Color { colorFromName(scoreColorName) }
}

// MARK: - Protocol for Dynamic Color Names

protocol ColorNameProviding {
    var colorName: String { get }
}

extension ColorNameProviding {
    var color: Color { colorFromName(colorName) }
}
