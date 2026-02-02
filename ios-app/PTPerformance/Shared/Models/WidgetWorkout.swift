import Foundation

/// Lightweight workout data for widget display
public struct WidgetWorkout: Codable {
    public let sessionId: UUID?
    public let name: String
    public let sessionType: String     // "strength", "mobility", "arm_care", etc.
    public let scheduledTime: Date?
    public let status: WorkoutStatus
    public let estimatedMinutes: Int?
    public let exerciseCount: Int?
    public let lastUpdated: Date

    public enum WorkoutStatus: String, Codable {
        case scheduled
        case inProgress
        case completed
        case skipped
        case restDay

        public var displayText: String {
            switch self {
            case .scheduled: return "Scheduled"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .skipped: return "Skipped"
            case .restDay: return "Rest Day"
            }
        }

        public var iconName: String {
            switch self {
            case .scheduled: return "calendar"
            case .inProgress: return "figure.run"
            case .completed: return "checkmark.circle.fill"
            case .skipped: return "xmark.circle"
            case .restDay: return "bed.double.fill"
            }
        }
    }

    public init(sessionId: UUID? = nil, name: String, sessionType: String, scheduledTime: Date? = nil, status: WorkoutStatus, estimatedMinutes: Int? = nil, exerciseCount: Int? = nil, lastUpdated: Date = Date()) {
        self.sessionId = sessionId
        self.name = name
        self.sessionType = sessionType
        self.scheduledTime = scheduledTime
        self.status = status
        self.estimatedMinutes = estimatedMinutes
        self.exerciseCount = exerciseCount
        self.lastUpdated = lastUpdated
    }

    /// Formatted scheduled time
    public var formattedTime: String? {
        guard let time = scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Rest day placeholder
    public static var restDay: WidgetWorkout {
        WidgetWorkout(name: "Rest Day", sessionType: "recovery", status: .restDay)
    }

    /// Placeholder for widget previews
    public static var placeholder: WidgetWorkout {
        WidgetWorkout(sessionId: UUID(), name: "Upper Body Strength", sessionType: "strength", scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()), status: .scheduled, estimatedMinutes: 45, exerciseCount: 8)
    }
}
