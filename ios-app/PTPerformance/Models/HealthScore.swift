import Foundation

/// Overall health score combining multiple metrics
struct HealthScore: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let date: Date
    let overallScore: Int // 0-100
    let sleepScore: Int
    let recoveryScore: Int
    let nutritionScore: Int
    let activityScore: Int
    let stressScore: Int
    let breakdown: [HealthScoreComponent]
    let insights: [HealthInsight]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case date
        case overallScore = "overall_score"
        case sleepScore = "sleep_score"
        case recoveryScore = "recovery_score"
        case nutritionScore = "nutrition_score"
        case activityScore = "activity_score"
        case stressScore = "stress_score"
        case breakdown, insights
        case createdAt = "created_at"
    }
}

struct HealthScoreComponent: Identifiable, Codable, Hashable {
    let id: UUID
    let category: String
    let score: Int
    let weight: Double
    let trend: ScoreTrend
}

enum ScoreTrend: String, Codable {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "yellow"
        case .declining: return "red"
        }
    }
}

struct HealthInsight: Identifiable, Codable, Hashable {
    let id: UUID
    let category: InsightCategory
    let title: String
    let description: String
    let actionable: Bool
    let action: String?
    let priority: InsightPriority
}

enum InsightCategory: String, Codable, CaseIterable {
    case sleep = "sleep"
    case recovery = "recovery"
    case nutrition = "nutrition"
    case training = "training"
    case stress = "stress"
    case supplements = "supplements"
    case labs = "labs"
    case general = "general"

    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .recovery: return "Recovery"
        case .nutrition: return "Nutrition"
        case .training: return "Training"
        case .stress: return "Stress"
        case .supplements: return "Supplements"
        case .labs: return "Lab Results"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .recovery: return "heart.fill"
        case .nutrition: return "leaf.fill"
        case .training: return "figure.run"
        case .stress: return "brain.head.profile"
        case .supplements: return "pill.fill"
        case .labs: return "cross.case.fill"
        case .general: return "lightbulb.fill"
        }
    }
}

enum InsightPriority: String, Codable {
    case high
    case medium
    case low
}

/// AI Coach chat message
struct HealthCoachMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let category: InsightCategory?
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
