import Foundation

/// Streak data for widget display
public struct WidgetStreak: Codable {
    public let currentStreak: Int          // Days in current streak
    public let longestStreak: Int          // All-time longest
    public let streakType: StreakType
    public let lastActivityDate: Date?
    public let lastUpdated: Date

    public enum StreakType: String, Codable {
        case workout           // Consecutive workout days
        case armCare           // Consecutive arm care days
        case combined          // Any training activity

        public var displayName: String {
            switch self {
            case .workout: return "Workout"
            case .armCare: return "Arm Care"
            case .combined: return "Training"
            }
        }

        public var iconName: String {
            switch self {
            case .workout: return "figure.strengthtraining.traditional"
            case .armCare: return "arm.flexed.fill"
            case .combined: return "flame.fill"
            }
        }
    }

    public init(currentStreak: Int, longestStreak: Int, streakType: StreakType = .combined, lastActivityDate: Date? = nil, lastUpdated: Date = Date()) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakType = streakType
        self.lastActivityDate = lastActivityDate
        self.lastUpdated = lastUpdated
    }

    /// Motivational message based on streak
    public var motivationalMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks! Amazing!"
        case 30...59: return "One month! Incredible!"
        case 60...89: return "Two months! Unstoppable!"
        default: return "Legendary consistency!"
        }
    }

    /// Check if streak is at risk (no activity today)
    public var isAtRisk: Bool {
        guard let lastDate = lastActivityDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Placeholder for widget previews
    public static var placeholder: WidgetStreak {
        WidgetStreak(currentStreak: 12, longestStreak: 21, lastActivityDate: Date())
    }
}
