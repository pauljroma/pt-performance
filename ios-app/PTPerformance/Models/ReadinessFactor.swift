import Foundation

/// Represents a configurable readiness factor used in score calculation
/// BUILD 116 - Agent 6: Daily Readiness Models
///
/// Maps to the `readiness_factors` table in Supabase
struct ReadinessFactor: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let weight: Double
    let description: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case weight
        case description
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Weight as a percentage (0-100)
    var weightPercentage: Double {
        return weight * 100
    }

    /// Formatted weight display (e.g., "25.0%")
    var weightDisplay: String {
        return String(format: "%.1f%%", weightPercentage)
    }

    /// Display name with weight (e.g., "Sleep Quality (30%)")
    var displayNameWithWeight: String {
        return "\(name) (\(weightDisplay))"
    }

    // MARK: - Factory Methods

    /// Standard readiness factors based on Agent 3 specifications
    static func defaultFactors() -> [ReadinessFactor] {
        return [
            sleepFactor(),
            sorenessFactor(),
            energyFactor(),
            stressFactor()
        ]
    }

    /// Sleep hours factor (30% weight)
    static func sleepFactor() -> ReadinessFactor {
        return ReadinessFactor(
            id: UUID(),
            name: "Sleep Hours",
            weight: 0.30,
            description: "Hours of sleep in the past 24 hours. Optimal: 7-9 hours.",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Soreness level factor (25% weight)
    static func sorenessFactor() -> ReadinessFactor {
        return ReadinessFactor(
            id: UUID(),
            name: "Soreness Level",
            weight: 0.25,
            description: "Muscle soreness rating on a 1-10 scale. Lower is better.",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Energy level factor (25% weight)
    static func energyFactor() -> ReadinessFactor {
        return ReadinessFactor(
            id: UUID(),
            name: "Energy Level",
            weight: 0.25,
            description: "Perceived energy level on a 1-10 scale. Higher is better.",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Stress level factor (20% weight)
    static func stressFactor() -> ReadinessFactor {
        return ReadinessFactor(
            id: UUID(),
            name: "Stress Level",
            weight: 0.20,
            description: "Perceived stress level on a 1-10 scale. Lower is better.",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Validation

    /// Validates that weight is between 0 and 1
    func isValid() -> Bool {
        return weight >= 0 && weight <= 1
    }

    /// Validates a set of factors to ensure weights sum to 1.0
    static func validateFactors(_ factors: [ReadinessFactor]) -> Bool {
        let activeFactors = factors.filter { $0.isActive }
        let totalWeight = activeFactors.reduce(0.0) { $0 + $1.weight }
        // Allow small floating-point tolerance
        return abs(totalWeight - 1.0) < 0.001
    }
}

// MARK: - Sample Data

extension ReadinessFactor {
    /// Sample factors for previews and testing
    static let sampleFactors: [ReadinessFactor] = defaultFactors()

    /// Single sample factor
    static var sample: ReadinessFactor {
        sleepFactor()
    }
}
