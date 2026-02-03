import Foundation

/// Timer runtime state enum
/// Used by UI to track and display current timer state
enum TimerState: String, Codable, CaseIterable, Sendable {
    case idle       // Timer not started
    case running    // Timer actively running
    case paused     // Timer temporarily paused
    case completed  // Timer finished

    var displayName: String {
        switch self {
        case .idle:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        }
    }

    var description: String {
        switch self {
        case .idle:
            return "Timer is ready to start"
        case .running:
            return "Timer is actively running"
        case .paused:
            return "Timer is temporarily paused"
        case .completed:
            return "Timer has completed all rounds"
        }
    }

    /// Icon name for SwiftUI SF Symbols
    var iconName: String {
        switch self {
        case .idle:
            return "play.circle.fill"
        case .running:
            return "pause.circle.fill"
        case .paused:
            return "play.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    /// Whether the timer can be started/resumed
    var canStart: Bool {
        switch self {
        case .idle, .paused:
            return true
        case .running, .completed:
            return false
        }
    }

    /// Whether the timer can be paused
    var canPause: Bool {
        switch self {
        case .running:
            return true
        case .idle, .paused, .completed:
            return false
        }
    }

    /// Whether the timer can be reset
    var canReset: Bool {
        switch self {
        case .paused, .completed:
            return true
        case .idle, .running:
            return false
        }
    }
}
