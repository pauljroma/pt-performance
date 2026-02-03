import Foundation

// MARK: - Supplement Recommendation Models

/// Response from AI supplement recommendation endpoint
struct SupplementRecommendationResponse: Codable {
    let recommendationId: String
    let recommendations: [AISupplementRecommendation]
    let stackSummary: String
    let totalDailyCostEstimate: String
    let goalCoverage: [String: [String]]
    let interactionWarnings: [String]
    let timingSchedule: SupplementTimingSchedule
    let disclaimer: String
    let cached: Bool

    enum CodingKeys: String, CodingKey {
        case recommendationId = "recommendation_id"
        case recommendations
        case stackSummary = "stack_summary"
        case totalDailyCostEstimate = "total_daily_cost_estimate"
        case goalCoverage = "goal_coverage"
        case interactionWarnings = "interaction_warnings"
        case timingSchedule = "timing_schedule"
        case disclaimer
        case cached
    }
}

/// Individual supplement recommendation from AI
struct AISupplementRecommendation: Identifiable, Codable, Hashable {
    var id: String { supplementId ?? UUID().uuidString }
    let supplementId: String?
    let name: String
    let brand: String
    let category: String
    let dosage: String
    let timing: String
    let evidenceRating: Int
    let rationale: String
    let goalAlignment: [String]
    let purchaseUrl: String?
    let priority: SupplementPriority
    let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case supplementId = "supplement_id"
        case name, brand, category, dosage, timing
        case evidenceRating = "evidence_rating"
        case rationale
        case goalAlignment = "goal_alignment"
        case purchaseUrl = "purchase_url"
        case priority, warnings
    }
}

/// Priority level for supplement recommendations
enum SupplementPriority: String, Codable, CaseIterable {
    case essential
    case recommended
    case optional

    var displayName: String {
        switch self {
        case .essential: return "Essential"
        case .recommended: return "Recommended"
        case .optional: return "Optional"
        }
    }

    var color: String {
        switch self {
        case .essential: return "red"
        case .recommended: return "orange"
        case .optional: return "blue"
        }
    }

    var sortOrder: Int {
        switch self {
        case .essential: return 0
        case .recommended: return 1
        case .optional: return 2
        }
    }
}

/// Timing schedule for supplements
struct SupplementTimingSchedule: Codable, Hashable {
    let morning: [SupplementTimingItem]
    let preWorkout: [SupplementTimingItem]
    let postWorkout: [SupplementTimingItem]
    let evening: [SupplementTimingItem]
    let withMeals: [SupplementTimingItem]

    enum CodingKeys: String, CodingKey {
        case morning
        case preWorkout = "pre_workout"
        case postWorkout = "post_workout"
        case evening
        case withMeals = "with_meals"
    }

    var allTimings: [(String, [SupplementTimingItem])] {
        [
            ("Morning", morning),
            ("Pre-Workout", preWorkout),
            ("Post-Workout", postWorkout),
            ("Evening", evening),
            ("With Meals", withMeals)
        ].filter { !$0.1.isEmpty }
    }
}

/// Individual timing item
struct SupplementTimingItem: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let dosage: String
    let notes: String
}

// MARK: - Supplement Goal Selection

/// Goals for supplement recommendation
enum SupplementGoal: String, CaseIterable, Identifiable {
    case muscleBuilding = "muscle_building"
    case fatLoss = "fat_loss"
    case sleep = "sleep"
    case cognitive = "cognitive"
    case recovery = "recovery"
    case testosterone = "testosterone"
    case energy = "energy"
    case longevity = "longevity"
    case general = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muscleBuilding: return "Muscle Building"
        case .fatLoss: return "Fat Loss"
        case .sleep: return "Sleep Quality"
        case .cognitive: return "Cognitive Performance"
        case .recovery: return "Recovery"
        case .testosterone: return "Hormone Optimization"
        case .energy: return "Energy & Endurance"
        case .longevity: return "Longevity"
        case .general: return "General Health"
        }
    }

    var icon: String {
        switch self {
        case .muscleBuilding: return "figure.strengthtraining.traditional"
        case .fatLoss: return "flame.fill"
        case .sleep: return "moon.fill"
        case .cognitive: return "brain.head.profile"
        case .recovery: return "heart.fill"
        case .testosterone: return "bolt.fill"
        case .energy: return "battery.100.bolt"
        case .longevity: return "hourglass"
        case .general: return "cross.case.fill"
        }
    }

    var description: String {
        switch self {
        case .muscleBuilding: return "Optimize muscle protein synthesis and strength gains"
        case .fatLoss: return "Support metabolism and body composition"
        case .sleep: return "Improve sleep quality and recovery"
        case .cognitive: return "Enhance focus, memory, and mental clarity"
        case .recovery: return "Speed up recovery between training sessions"
        case .testosterone: return "Support healthy hormone levels naturally"
        case .energy: return "Boost energy and endurance for training"
        case .longevity: return "Promote long-term health and vitality"
        case .general: return "Foundation supplements for overall wellness"
        }
    }
}
