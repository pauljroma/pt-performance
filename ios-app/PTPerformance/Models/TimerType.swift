import Foundation

/// Timer type enum - maps to database timer_type enum
/// Represents different interval training protocols
enum TimerType: String, Codable, CaseIterable, Sendable {
    case tabata
    case emom
    case amrap
    case intervals
    case custom

    var displayName: String {
        switch self {
        case .tabata:
            return "Tabata"
        case .emom:
            return "EMOM"
        case .amrap:
            return "AMRAP"
        case .intervals:
            return "Intervals"
        case .custom:
            return "Custom"
        }
    }

    var description: String {
        switch self {
        case .tabata:
            return "High-intensity interval training (20s work, 10s rest)"
        case .emom:
            return "Every Minute On the Minute - complete work within each minute"
        case .amrap:
            return "As Many Rounds As Possible - maximize rounds in time limit"
        case .intervals:
            return "Work/Rest intervals - customizable work and rest periods"
        case .custom:
            return "Custom timer configuration with flexible parameters"
        }
    }

    /// Default configuration for each timer type
    var defaultWorkSeconds: Int {
        switch self {
        case .tabata:
            return 20
        case .emom:
            return 40  // 40s work, 20s rest per minute
        case .amrap:
            return 300  // 5 minute default
        case .intervals:
            return 30
        case .custom:
            return 30
        }
    }

    var defaultRestSeconds: Int {
        switch self {
        case .tabata:
            return 10
        case .emom:
            return 20
        case .amrap:
            return 0  // No rest in AMRAP
        case .intervals:
            return 30
        case .custom:
            return 30
        }
    }

    var defaultRounds: Int {
        switch self {
        case .tabata:
            return 8
        case .emom:
            return 10
        case .amrap:
            return 1  // Single continuous round
        case .intervals:
            return 5
        case .custom:
            return 5
        }
    }

    /// Icon name for SwiftUI SF Symbols
    var iconName: String {
        switch self {
        case .tabata:
            return "flame.fill"
        case .emom:
            return "clock.fill"
        case .amrap:
            return "repeat.circle.fill"
        case .intervals:
            return "waveform.path.ecg"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}
