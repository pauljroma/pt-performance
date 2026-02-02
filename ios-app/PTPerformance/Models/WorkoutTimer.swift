import Foundation

/// Workout timer model - maps to database workout_timers table
/// Represents an active or completed timer session
struct WorkoutTimer: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let templateId: UUID?  // Optional - NULL when started from preset
    let startedAt: Date
    let completedAt: Date?
    let roundsCompleted: Int
    let pausedSeconds: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case templateId = "template_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Whether this timer session is completed
    var isCompleted: Bool {
        return completedAt != nil
    }

    /// Duration from start to completion (or current time if not completed)
    var duration: TimeInterval {
        let endTime = completedAt ?? Date()
        return endTime.timeIntervalSince(startedAt)
    }

    /// Effective duration excluding paused time
    var effectiveDuration: TimeInterval {
        return duration - Double(pausedSeconds)
    }

    /// Formatted duration string (HH:MM:SS or MM:SS)
    var formattedDuration: String {
        return formatDuration(duration)
    }

    /// Formatted effective duration string (HH:MM:SS or MM:SS)
    var formattedEffectiveDuration: String {
        return formatDuration(effectiveDuration)
    }

    /// Formatted paused time string (MM:SS)
    var formattedPausedTime: String {
        let minutes = pausedSeconds / 60
        let seconds = pausedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Completion status text
    var statusText: String {
        if isCompleted {
            return "Completed"
        } else {
            return "In Progress"
        }
    }

    /// Progress percentage (0-100) based on rounds completed
    /// Requires template to calculate accurate percentage
    func progress(totalRounds: Int) -> Double {
        guard totalRounds > 0 else { return 0 }
        return min(Double(roundsCompleted) / Double(totalRounds) * 100, 100)
    }

    // MARK: - Validation

    /// Validates the timer session
    /// Returns nil if valid, error message if invalid
    func validate() -> String? {
        if roundsCompleted < 0 {
            return "Rounds completed cannot be negative"
        }

        if pausedSeconds < 0 {
            return "Paused time cannot be negative"
        }

        if let completed = completedAt, completed < startedAt {
            return "Completion time cannot be before start time"
        }

        if duration < 0 {
            return "Duration cannot be negative"
        }

        if effectiveDuration < 0 {
            return "Effective duration cannot be negative"
        }

        return nil
    }

    /// Whether this timer session is valid
    var isValid: Bool {
        return validate() == nil
    }

    // MARK: - Helper Methods

    /// Format duration in seconds to HH:MM:SS or MM:SS
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Sample Data

    static let sample = WorkoutTimer(
        id: UUID(),
        patientId: UUID(),
        templateId: nil,  // No template - started from preset
        startedAt: Date().addingTimeInterval(-300),  // 5 minutes ago
        completedAt: Date(),
        roundsCompleted: 8,
        pausedSeconds: 15,
        createdAt: Date().addingTimeInterval(-300),
        updatedAt: Date()
    )

    static let sampleInProgress = WorkoutTimer(
        id: UUID(),
        patientId: UUID(),
        templateId: nil,  // No template - started from preset
        startedAt: Date().addingTimeInterval(-120),  // 2 minutes ago
        completedAt: nil,
        roundsCompleted: 4,
        pausedSeconds: 5,
        createdAt: Date().addingTimeInterval(-120),
        updatedAt: Date()
    )

    static let samples: [WorkoutTimer] = [
        WorkoutTimer(
            id: UUID(),
            patientId: UUID(),
            templateId: nil,  // No template - started from preset
            startedAt: Date().addingTimeInterval(-86400),  // Yesterday
            completedAt: Date().addingTimeInterval(-86100),
            roundsCompleted: 8,
            pausedSeconds: 0,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86100)
        ),
        WorkoutTimer(
            id: UUID(),
            patientId: UUID(),
            templateId: nil,  // No template - started from preset
            startedAt: Date().addingTimeInterval(-172800),  // 2 days ago
            completedAt: Date().addingTimeInterval(-172500),
            roundsCompleted: 10,
            pausedSeconds: 20,
            createdAt: Date().addingTimeInterval(-172800),
            updatedAt: Date().addingTimeInterval(-172500)
        ),
        sampleInProgress
    ]
}
