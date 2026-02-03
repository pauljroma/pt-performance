import SwiftUI

/// Timer category enum - maps to database timer_category enum
/// Used for organizing and filtering timer presets
enum TimerCategory: String, Codable, CaseIterable, Sendable {
    case cardio
    case strength
    case warmup
    case cooldown
    case recovery

    var displayName: String {
        switch self {
        case .cardio:
            return "Cardio"
        case .strength:
            return "Strength"
        case .warmup:
            return "Warm-up"
        case .cooldown:
            return "Cool-down"
        case .recovery:
            return "Recovery"
        }
    }

    var description: String {
        switch self {
        case .cardio:
            return "Cardiovascular conditioning and endurance training"
        case .strength:
            return "Resistance training and power development"
        case .warmup:
            return "Pre-workout activation and mobility"
        case .cooldown:
            return "Post-workout recovery and stretching"
        case .recovery:
            return "Active recovery and regeneration"
        }
    }

    /// Category color for UI display
    var color: Color {
        switch self {
        case .cardio:
            return .red
        case .strength:
            return .blue
        case .warmup:
            return .orange
        case .cooldown:
            return .purple
        case .recovery:
            return .green
        }
    }

    /// Icon name for SwiftUI SF Symbols
    var iconName: String {
        switch self {
        case .cardio:
            return "heart.fill"
        case .strength:
            return "dumbbell.fill"
        case .warmup:
            return "figure.run"
        case .cooldown:
            return "figure.cooldown"
        case .recovery:
            return "leaf.fill"
        }
    }

    /// Typical intensity level for this category
    var typicalIntensity: String {
        switch self {
        case .cardio:
            return "Moderate to High"
        case .strength:
            return "High"
        case .warmup:
            return "Low to Moderate"
        case .cooldown:
            return "Low"
        case .recovery:
            return "Low to Moderate"
        }
    }
}
