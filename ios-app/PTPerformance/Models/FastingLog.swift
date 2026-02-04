import Foundation

/// Fasting log entry (matches fasting_logs table in Supabase)
struct FastingLog: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let fastingType: FastingType
    let startedAt: Date
    let endedAt: Date?
    let plannedEndAt: Date?
    let targetHours: Int
    let actualHours: Double?
    let wasBrokenEarly: Bool?
    let breakReason: String?
    let moodStart: Int? // 1-10
    let moodEnd: Int? // 1-10
    let hungerLevel: Int? // 1-10
    let energyLevel: Int? // 1-10
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case fastingType = "fasting_type"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case plannedEndAt = "planned_end_at"
        case targetHours = "target_hours"
        case actualHours = "actual_hours"
        case wasBrokenEarly = "was_broken_early"
        case breakReason = "break_reason"
        case moodStart = "mood_start"
        case moodEnd = "mood_end"
        case hungerLevel = "hunger_level"
        case energyLevel = "energy_level"
        case notes
        case createdAt = "created_at"
    }

    var isActive: Bool {
        endedAt == nil
    }

    var progressPercent: Double {
        guard let end = endedAt else {
            let elapsed = Date().timeIntervalSince(startedAt) / 3600
            return min(elapsed / Double(targetHours), 1.0)
        }
        let actual = end.timeIntervalSince(startedAt) / 3600
        return min(actual / Double(targetHours), 1.0)
    }

    // MARK: - Backward Compatibility

    /// Backward-compatible property for code using startTime
    var startTime: Date { startedAt }

    /// Backward-compatible property for code using endTime
    var endTime: Date? { endedAt }
}

/// Fasting type enum matching Supabase database values
/// Database expects: intermittent, extended, water_only, modified, custom
enum FastingType: String, Codable, CaseIterable {
    case intermittent = "intermittent"
    case extended = "extended"
    case waterOnly = "water_only"
    case modified = "modified"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .intermittent: return "Intermittent"
        case .extended: return "Extended"
        case .waterOnly: return "Water Only"
        case .modified: return "Modified"
        case .custom: return "Custom"
        }
    }

    var targetHours: Int {
        switch self {
        case .intermittent: return 16
        case .extended: return 24
        case .waterOnly: return 24
        case .modified: return 18
        case .custom: return 16
        }
    }

    var description: String {
        switch self {
        case .intermittent: return "Daily time-restricted eating (e.g., 16:8, 18:6)"
        case .extended: return "Extended fasting period (24+ hours)"
        case .waterOnly: return "Water-only fast with no caloric intake"
        case .modified: return "Modified fast allowing limited calories"
        case .custom: return "Custom fasting schedule"
        }
    }
}

/// Eating window recommendation based on training schedule
struct EatingWindowRecommendation: Identifiable, Codable {
    let id: UUID
    let suggestedStart: Date
    let suggestedEnd: Date
    let reason: String
    let trainingTime: Date?
    let confidence: Double
}

/// Fasting statistics
struct FastingStats: Codable {
    let totalFasts: Int
    let completedFasts: Int
    let averageHours: Double
    let longestFast: Double
    let currentStreak: Int
    let bestStreak: Int

    enum CodingKeys: String, CodingKey {
        case totalFasts = "total_fasts"
        case completedFasts = "completed_fasts"
        case averageHours = "average_hours"
        case longestFast = "longest_fast"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
    }
}
