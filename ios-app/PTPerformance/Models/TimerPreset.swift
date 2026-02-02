import Foundation

/// Timer preset model - maps to database timer_presets table
/// Represents curated timer configurations with metadata
struct TimerPreset: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let templateJson: TemplateJSON
    let category: TimerCategory
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case templateJson = "template_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Template JSON Structure

    /// JSONB structure for template configuration
    struct TemplateJSON: Codable, Hashable, Equatable {
        let type: TimerType
        let workSeconds: Int
        let restSeconds: Int
        let rounds: Int
        let cycles: Int
        let totalDuration: Int?  // BUILD 136: Optional - some presets missing this field
        let difficulty: Difficulty?  // BUILD 136: Optional - not always in database
        let equipment: String?  // BUILD 136: Optional - not always specified

        enum CodingKeys: String, CodingKey {
            case type
            case workSeconds = "work_seconds"
            case restSeconds = "rest_seconds"
            case rounds
            case cycles
            case totalDuration = "total_duration"
            case difficulty
            case equipment
        }

        /// Difficulty levels for presets
        enum Difficulty: String, Codable, CaseIterable, Hashable {
            case easy
            case moderate
            case hard
            case veryHard = "very_hard"

            var displayName: String {
                switch self {
                case .easy:
                    return "Easy"
                case .moderate:
                    return "Moderate"
                case .hard:
                    return "Hard"
                case .veryHard:
                    return "Very Hard"
                }
            }

            var color: String {
                switch self {
                case .easy:
                    return "green"
                case .moderate:
                    return "yellow"
                case .hard:
                    return "orange"
                case .veryHard:
                    return "red"
                }
            }

            var iconName: String {
                switch self {
                case .easy:
                    return "figure.walk"
                case .moderate:
                    return "figure.run"
                case .hard:
                    return "figure.strengthtraining.traditional"
                case .veryHard:
                    return "flame.fill"
                }
            }
        }

        // MARK: - Computed Properties

        /// Calculated total duration from work/rest/rounds if not provided
        var calculatedDuration: Int {
            if let total = totalDuration {
                return total
            }
            // Calculate from work + rest * rounds * cycles
            return (workSeconds + restSeconds) * rounds * cycles
        }

        /// Formatted duration string (MM:SS)
        var formattedDuration: String {
            let duration = calculatedDuration
            let minutes = duration / 60
            let seconds = duration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        /// Human-readable duration (e.g., "5 min" or "1 hr 15 min")
        var readableDuration: String {
            let duration = calculatedDuration
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60

            if hours > 0 {
                if minutes > 0 {
                    return "\(hours) hr \(minutes) min"
                }
                return "\(hours) hr"
            } else if minutes > 0 {
                return "\(minutes) min"
            } else {
                return "\(duration) sec"
            }
        }
    }

    // MARK: - Computed Properties

    /// Formatted duration from template
    var formattedDuration: String {
        return templateJson.formattedDuration
    }

    /// Readable duration from template
    var readableDuration: String {
        return templateJson.readableDuration
    }

    /// Difficulty display name
    var difficultyName: String {
        return templateJson.difficulty?.displayName ?? "Moderate"
    }

    /// Create an IntervalTemplate from this preset
    func toIntervalTemplate(createdBy: UUID? = nil) -> IntervalTemplate {
        return IntervalTemplate(
            id: UUID(),  // Generate new ID
            name: name,
            type: templateJson.type,
            workSeconds: templateJson.workSeconds,
            restSeconds: templateJson.restSeconds,
            rounds: templateJson.rounds,
            cycles: templateJson.cycles,
            createdBy: createdBy,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Sample Data

    static let sample = TimerPreset(
        id: UUID(),
        name: "Classic Tabata",
        description: "The original Tabata protocol - 4 minutes of high-intensity interval training",
        templateJson: TemplateJSON(
            type: .tabata,
            workSeconds: 20,
            restSeconds: 10,
            rounds: 8,
            cycles: 1,
            totalDuration: 240,
            difficulty: .hard,
            equipment: "Bodyweight"
        ),
        category: .cardio,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let samples: [TimerPreset] = [
        TimerPreset(
            id: UUID(),
            name: "Classic Tabata",
            description: "The original Tabata protocol - 4 minutes of high-intensity interval training",
            templateJson: TemplateJSON(
                type: .tabata,
                workSeconds: 20,
                restSeconds: 10,
                rounds: 8,
                cycles: 1,
                totalDuration: 240,
                difficulty: .hard,
                equipment: "Bodyweight"
            ),
            category: .cardio,
            createdAt: Date(),
            updatedAt: Date()
        ),
        TimerPreset(
            id: UUID(),
            name: "EMOM Strength",
            description: "10 rounds of strength work with built-in rest",
            templateJson: TemplateJSON(
                type: .emom,
                workSeconds: 40,
                restSeconds: 20,
                rounds: 10,
                cycles: 1,
                totalDuration: 600,
                difficulty: .moderate,
                equipment: "Dumbbells"
            ),
            category: .strength,
            createdAt: Date(),
            updatedAt: Date()
        ),
        TimerPreset(
            id: UUID(),
            name: "5 Minute AMRAP",
            description: "As many rounds as possible in 5 minutes",
            templateJson: TemplateJSON(
                type: .amrap,
                workSeconds: 300,
                restSeconds: 0,
                rounds: 1,
                cycles: 1,
                totalDuration: 300,
                difficulty: .hard,
                equipment: "Bodyweight"
            ),
            category: .cardio,
            createdAt: Date(),
            updatedAt: Date()
        ),
        TimerPreset(
            id: UUID(),
            name: "Warm-up Intervals",
            description: "Light intervals to prepare for training",
            templateJson: TemplateJSON(
                type: .intervals,
                workSeconds: 30,
                restSeconds: 30,
                rounds: 5,
                cycles: 1,
                totalDuration: 300,
                difficulty: .easy,
                equipment: "None"
            ),
            category: .warmup,
            createdAt: Date(),
            updatedAt: Date()
        ),
        TimerPreset(
            id: UUID(),
            name: "Recovery Stretching",
            description: "Guided recovery with timed holds",
            templateJson: TemplateJSON(
                type: .custom,
                workSeconds: 45,
                restSeconds: 15,
                rounds: 6,
                cycles: 1,
                totalDuration: 360,
                difficulty: .easy,
                equipment: "Mat"
            ),
            category: .recovery,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
