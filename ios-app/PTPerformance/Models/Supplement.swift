import Foundation
import SwiftUI

/// Evidence level for supplement research
enum EvidenceLevel: String, Codable, CaseIterable, Identifiable {
    case high
    case moderate
    case low
    case emerging

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: return "Strong Evidence"
        case .moderate: return "Moderate Evidence"
        case .low: return "Limited Evidence"
        case .emerging: return "Emerging Research"
        }
    }

    var shortName: String {
        switch self {
        case .high: return "Strong"
        case .moderate: return "Moderate"
        case .low: return "Limited"
        case .emerging: return "Emerging"
        }
    }

    var color: Color {
        switch self {
        case .high: return .modusTealAccent
        case .moderate: return .modusCyan
        case .low: return .orange
        case .emerging: return .gray
        }
    }

    var icon: String {
        switch self {
        case .high: return "checkmark.seal.fill"
        case .moderate: return "checkmark.seal"
        case .low: return "questionmark.circle"
        case .emerging: return "sparkle"
        }
    }
}

/// Supplement in user's stack
struct Supplement: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let name: String
    let brand: String?
    let category: SupplementCategory
    let dosage: String
    let frequency: SupplementFrequency
    let timeOfDay: [TimeOfDay]
    let withFood: Bool
    let notes: String?
    let momentousProductId: String?
    let isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name, brand, category, dosage, frequency
        case timeOfDay = "time_of_day"
        case withFood = "with_food"
        case notes
        case momentousProductId = "momentous_product_id"
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    // Computed properties for view compatibility
    var recommendedDosage: String { dosage }
    var shouldTakeWithFood: Bool { withFood }
    var evidenceLevel: EvidenceLevel { .moderate }
}

enum SupplementCategory: String, Codable, CaseIterable {
    case protein = "protein"
    case creatine = "creatine"
    case vitamins = "vitamins"
    case minerals = "minerals"
    case omega3 = "omega3"
    case preworkout = "preworkout"
    case recovery = "recovery"
    case sleep = "sleep"
    case adaptogens = "adaptogens"
    case other = "other"

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .creatine: return "Creatine"
        case .vitamins: return "Vitamins"
        case .minerals: return "Minerals"
        case .omega3: return "Omega-3"
        case .preworkout: return "Pre-Workout"
        case .recovery: return "Recovery"
        case .sleep: return "Sleep"
        case .adaptogens: return "Adaptogens"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .protein: return "figure.strengthtraining.traditional"
        case .creatine: return "bolt.fill"
        case .vitamins: return "pill.fill"
        case .minerals: return "leaf.fill"
        case .omega3: return "drop.fill"
        case .preworkout: return "flame.fill"
        case .recovery: return "heart.fill"
        case .sleep: return "moon.fill"
        case .adaptogens: return "brain.head.profile"
        case .other: return "pills.fill"
        }
    }
}

enum SupplementFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case twiceDaily = "twice_daily"
    case threeTimesDaily = "three_times_daily"
    case weekly = "weekly"
    case asNeeded = "as_needed"
    case trainingDaysOnly = "training_days_only"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .twiceDaily: return "Twice Daily"
        case .threeTimesDaily: return "Three Times Daily"
        case .weekly: return "Weekly"
        case .asNeeded: return "As Needed"
        case .trainingDaysOnly: return "Training Days Only"
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable, Equatable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    case beforeBed = "before_bed"
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"
    case withMeals = "with_meals"

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        case .beforeBed: return "Before Bed"
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        case .withMeals: return "With Meals"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        case .beforeBed: return "moon.fill"
        case .preWorkout: return "figure.run"
        case .postWorkout: return "figure.cooldown"
        case .withMeals: return "fork.knife"
        }
    }
}

/// Scheduled supplement dose
struct ScheduledSupplement: Identifiable, Codable {
    let id: UUID
    let supplement: Supplement
    let scheduledTime: Date
    let taken: Bool
    let takenAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, supplement
        case scheduledTime = "scheduled_time"
        case taken
        case takenAt = "taken_at"
    }
}

/// Supplement log entry
struct SupplementLog: Identifiable, Codable {
    let id: UUID
    let supplementId: UUID
    let patientId: UUID
    let takenAt: Date
    let dosage: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case patientId = "patient_id"
        case takenAt = "taken_at"
        case dosage, notes
    }
}
