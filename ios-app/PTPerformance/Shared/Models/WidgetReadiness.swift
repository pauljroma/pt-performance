import Foundation

/// Lightweight readiness data for widget display
public struct WidgetReadiness: Codable {
    public let score: Int              // 0-100
    public let band: String            // "green", "yellow", "orange", "red"
    public let hrv: Double?            // HRV in ms
    public let sleepHours: Double?     // Sleep duration
    public let restingHR: Int?         // Resting heart rate
    public let date: Date              // Date of readiness
    public let lastUpdated: Date       // When data was last synced

    public init(score: Int, band: String, hrv: Double? = nil, sleepHours: Double? = nil, restingHR: Int? = nil, date: Date, lastUpdated: Date = Date()) {
        self.score = score
        self.band = band
        self.hrv = hrv
        self.sleepHours = sleepHours
        self.restingHR = restingHR
        self.date = date
        self.lastUpdated = lastUpdated
    }

    /// Band display color name for SwiftUI
    public var bandColorName: String {
        switch band.lowercased() {
        case "green": return "systemGreen"
        case "yellow": return "systemYellow"
        case "orange": return "systemOrange"
        case "red": return "systemRed"
        default: return "systemGray"
        }
    }

    /// Human-readable band label
    public var bandLabel: String {
        switch band.lowercased() {
        case "green": return "Ready to Train"
        case "yellow": return "Train with Caution"
        case "orange": return "Reduced Intensity"
        case "red": return "Recovery Day"
        default: return "Unknown"
        }
    }

    /// Check if data is stale (older than 1 hour)
    public var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 3600
    }

    /// Placeholder for widget previews
    public static var placeholder: WidgetReadiness {
        WidgetReadiness(score: 75, band: "green", hrv: 65, sleepHours: 7.5, restingHR: 52, date: Date())
    }
}
