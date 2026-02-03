import Foundation

/// Fasting log entry
struct FastingLog: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let fastingType: FastingType
    let startTime: Date
    let endTime: Date?
    let targetHours: Int
    let actualHours: Double?
    let breakfastFood: String?
    let energyLevel: Int? // 1-10
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case fastingType = "fasting_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case targetHours = "target_hours"
        case actualHours = "actual_hours"
        case breakfastFood = "breakfast_food"
        case energyLevel = "energy_level"
        case notes
        case createdAt = "created_at"
    }

    var isActive: Bool {
        endTime == nil
    }

    var progressPercent: Double {
        guard let end = endTime else {
            let elapsed = Date().timeIntervalSince(startTime) / 3600
            return min(elapsed / Double(targetHours), 1.0)
        }
        let actual = end.timeIntervalSince(startTime) / 3600
        return min(actual / Double(targetHours), 1.0)
    }
}

enum FastingType: String, Codable, CaseIterable {
    case intermittent16_8 = "16_8"
    case intermittent18_6 = "18_6"
    case intermittent20_4 = "20_4"
    case omad = "omad"
    case extended24 = "24"
    case extended36 = "36"
    case extended48 = "48"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .intermittent16_8: return "16:8"
        case .intermittent18_6: return "18:6"
        case .intermittent20_4: return "20:4"
        case .omad: return "OMAD (23:1)"
        case .extended24: return "24 Hour"
        case .extended36: return "36 Hour"
        case .extended48: return "48 Hour"
        case .custom: return "Custom"
        }
    }

    var targetHours: Int {
        switch self {
        case .intermittent16_8: return 16
        case .intermittent18_6: return 18
        case .intermittent20_4: return 20
        case .omad: return 23
        case .extended24: return 24
        case .extended36: return 36
        case .extended48: return 48
        case .custom: return 16
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
