import Foundation

/// Interval template model - maps to database interval_templates table
/// Represents a reusable timer configuration that can be saved and shared
struct IntervalTemplate: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let type: TimerType
    let workSeconds: Int
    let restSeconds: Int
    let rounds: Int
    let cycles: Int
    let createdBy: UUID?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case rounds
        case cycles
        case workSeconds = "work_seconds"
        case restSeconds = "rest_seconds"
        case createdBy = "created_by"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Total duration in seconds for one cycle
    var cycleDuration: Int {
        return (workSeconds + restSeconds) * rounds
    }

    /// Total duration in seconds for all cycles
    var totalDuration: Int {
        return cycleDuration * cycles
    }

    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted cycle duration string (MM:SS)
    var formattedCycleDuration: String {
        let minutes = cycleDuration / 60
        let seconds = cycleDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Human-readable duration (e.g., "5 min" or "1 hr 15 min")
    var readableDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        let seconds = totalDuration % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours) hr \(minutes) min"
            }
            return "\(hours) hr"
        } else if minutes > 0 {
            if seconds > 0 {
                return "\(minutes) min \(seconds) sec"
            }
            return "\(minutes) min"
        } else {
            return "\(seconds) sec"
        }
    }

    /// Work/rest ratio as a string (e.g., "2:1")
    var workRestRatio: String {
        if restSeconds == 0 {
            return "Continuous"
        }
        let gcd = greatestCommonDivisor(workSeconds, restSeconds)
        let workRatio = workSeconds / gcd
        let restRatio = restSeconds / gcd
        return "\(workRatio):\(restRatio)"
    }

    // MARK: - Validation

    /// Validates the template configuration
    /// Returns nil if valid, error message if invalid
    func validate() -> String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Name cannot be empty"
        }

        if workSeconds <= 0 {
            return "Work duration must be greater than 0"
        }

        if restSeconds < 0 {
            return "Rest duration cannot be negative"
        }

        if rounds <= 0 {
            return "Rounds must be greater than 0"
        }

        if cycles <= 0 {
            return "Cycles must be greater than 0"
        }

        // Check for reasonable maximum values
        if totalDuration > 7200 {  // 2 hours
            return "Total duration cannot exceed 2 hours"
        }

        if rounds > 100 {
            return "Rounds cannot exceed 100"
        }

        if cycles > 10 {
            return "Cycles cannot exceed 10"
        }

        return nil
    }

    /// Whether this template is valid
    var isValid: Bool {
        return validate() == nil
    }

    // MARK: - Helper Methods

    /// Calculate greatest common divisor for work/rest ratio
    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }

    // MARK: - Sample Data

    static let sample = IntervalTemplate(
        id: UUID(),
        name: "Standard Tabata",
        type: .tabata,
        workSeconds: 20,
        restSeconds: 10,
        rounds: 8,
        cycles: 1,
        createdBy: nil,
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let samples: [IntervalTemplate] = [
        IntervalTemplate(
            id: UUID(),
            name: "Standard Tabata",
            type: .tabata,
            workSeconds: 20,
            restSeconds: 10,
            rounds: 8,
            cycles: 1,
            createdBy: nil,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        IntervalTemplate(
            id: UUID(),
            name: "EMOM 10",
            type: .emom,
            workSeconds: 40,
            restSeconds: 20,
            rounds: 10,
            cycles: 1,
            createdBy: nil,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        IntervalTemplate(
            id: UUID(),
            name: "5 Min AMRAP",
            type: .amrap,
            workSeconds: 300,
            restSeconds: 0,
            rounds: 1,
            cycles: 1,
            createdBy: nil,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
