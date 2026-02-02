import SwiftUI

/// Color definitions for widgets
enum WidgetColors {
    // MARK: - Readiness Band Colors

    static let readinessGreen = Color.green
    static let readinessYellow = Color.yellow
    static let readinessOrange = Color.orange
    static let readinessRed = Color.red

    static func colorForBand(_ band: String) -> Color {
        switch band.lowercased() {
        case "green": return readinessGreen
        case "yellow": return readinessYellow
        case "orange": return readinessOrange
        case "red": return readinessRed
        default: return .gray
        }
    }

    static func colorForScore(_ score: Int) -> Color {
        switch score {
        case 80...100: return readinessGreen
        case 60..<80: return readinessYellow
        case 40..<60: return readinessOrange
        default: return readinessRed
        }
    }

    // MARK: - Fatigue Band Colors

    static let fatigueLow = Color.green
    static let fatigueModerate = Color.yellow
    static let fatigueHigh = Color.orange
    static let fatigueCritical = Color.red

    static func colorForFatigueBand(_ band: String) -> Color {
        switch band.lowercased() {
        case "low": return fatigueLow
        case "moderate": return fatigueModerate
        case "high": return fatigueHigh
        case "critical": return fatigueCritical
        default: return .gray
        }
    }

    // MARK: - Workout Status Colors

    static let statusScheduled = Color.blue
    static let statusInProgress = Color.orange
    static let statusCompleted = Color.green
    static let statusSkipped = Color.red
    static let statusRestDay = Color.purple

    // MARK: - Adherence Colors

    static let adherenceCompleted = Color.green
    static let adherenceScheduled = Color.blue.opacity(0.3)
    static let adherenceSkipped = Color.red.opacity(0.5)
    static let adherenceRestDay = Color.gray.opacity(0.3)
    static let adherenceFuture = Color.gray.opacity(0.2)

    // MARK: - Streak Colors

    static let streakFlameGradient = LinearGradient(
        colors: [.orange, .red],
        startPoint: .bottom,
        endPoint: .top
    )

    // MARK: - Chart Colors

    static let chartLine = Color.blue
    static let chartFill = Color.blue.opacity(0.2)
    static let chartGrid = Color.gray.opacity(0.2)
}
