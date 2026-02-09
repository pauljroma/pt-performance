import SwiftUI

/// Color definitions for widgets
/// Uses adaptive colors for proper dark mode support
enum WidgetColors {
    // MARK: - Readiness Band Colors (Dark Mode Optimized)

    static var readinessGreen: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)  // Brighter green
                : UIColor.systemGreen
        })
    }

    static var readinessYellow: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)  // Brighter yellow
                : UIColor.systemYellow
        })
    }

    static var readinessOrange: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)  // Brighter orange
                : UIColor.systemOrange
        })
    }

    static var readinessRed: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)  // Brighter red
                : UIColor.systemRed
        })
    }

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

    static var fatigueLow: Color { readinessGreen }
    static var fatigueModerate: Color { readinessYellow }
    static var fatigueHigh: Color { readinessOrange }
    static var fatigueCritical: Color { readinessRed }

    static func colorForFatigueBand(_ band: String) -> Color {
        switch band.lowercased() {
        case "low": return fatigueLow
        case "moderate": return fatigueModerate
        case "high": return fatigueHigh
        case "critical": return fatigueCritical
        default: return .gray
        }
    }

    // MARK: - Workout Status Colors (Dark Mode Optimized)

    static var statusScheduled: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0)  // Brighter blue
                : UIColor.systemBlue
        })
    }

    static var statusInProgress: Color { readinessOrange }
    static var statusCompleted: Color { readinessGreen }
    static var statusSkipped: Color { readinessRed }

    static var statusRestDay: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.7, green: 0.45, blue: 0.9, alpha: 1.0)  // Brighter purple
                : UIColor.systemPurple
        })
    }

    // MARK: - Adherence Colors (Dark Mode Optimized)

    static var adherenceCompleted: Color { readinessGreen }

    static var adherenceScheduled: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemBlue.withAlphaComponent(0.4)
                : UIColor.systemBlue.withAlphaComponent(0.3)
        })
    }

    static var adherenceSkipped: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemRed.withAlphaComponent(0.6)
                : UIColor.systemRed.withAlphaComponent(0.5)
        })
    }

    static var adherenceRestDay: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray.withAlphaComponent(0.4)
                : UIColor.systemGray.withAlphaComponent(0.3)
        })
    }

    static var adherenceFuture: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray.withAlphaComponent(0.3)
                : UIColor.systemGray.withAlphaComponent(0.2)
        })
    }

    // MARK: - Streak Colors

    static let streakFlameGradient = LinearGradient(
        colors: [.orange, .red],
        startPoint: .bottom,
        endPoint: .top
    )

    // MARK: - Chart Colors (Dark Mode Optimized)

    static var chartLine: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0)  // Brighter blue
                : UIColor.systemBlue
        })
    }

    static var chartFill: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemBlue.withAlphaComponent(0.3)  // More visible in dark
                : UIColor.systemBlue.withAlphaComponent(0.2)
        })
    }

    static var chartGrid: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.15)  // Lighter grid on dark
                : UIColor.gray.withAlphaComponent(0.2)
        })
    }

    // MARK: - Widget Background Colors

    static var widgetBackground: Color {
        Color(UIColor.systemBackground)
    }

    static var widgetSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
}
