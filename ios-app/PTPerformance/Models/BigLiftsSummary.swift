import Foundation

// MARK: - Big Lifts Summary Model
// Model for the get_big_lifts_summary RPC function response
// Displays key strength metrics for major compound lifts

/// Summary data for a single big lift exercise
/// Populated from the get_big_lifts_summary Supabase RPC function
struct BigLiftSummary: Codable, Identifiable {
    let exerciseName: String
    let currentMaxWeight: Double
    let estimated1rm: Double
    let lastPrDate: Date?
    let prCount: Int
    let lastPerformed: Date?
    let improvementPct30d: Double?
    let totalVolume: Double
    let loadUnit: String

    var id: String { exerciseName }

    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
        case currentMaxWeight = "current_max_weight"
        case estimated1rm = "estimated_1rm"
        case lastPrDate = "last_pr_date"
        case prCount = "pr_count"
        case lastPerformed = "last_performed"
        case improvementPct30d = "improvement_pct_30d"
        case totalVolume = "total_volume"
        case loadUnit = "load_unit"
    }

    // MARK: - Computed Properties

    /// Formatted weight with unit
    var formattedMaxWeight: String {
        String(format: "%.0f %@", currentMaxWeight, loadUnit)
    }

    /// Formatted estimated 1RM with unit
    var formattedEstimated1rm: String {
        String(format: "%.0f %@", estimated1rm, loadUnit)
    }

    /// Formatted improvement percentage with sign
    var formattedImprovement: String? {
        guard let improvement = improvementPct30d else { return nil }
        let sign = improvement >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, improvement)
    }

    /// Whether this lift has improved in the last 30 days
    var isImproving: Bool {
        (improvementPct30d ?? 0) > 0
    }

    /// Whether this lift has declined in the last 30 days
    var isDeclining: Bool {
        (improvementPct30d ?? 0) < 0
    }

    /// Whether the last PR was within the last 30 days
    var hasRecentPR: Bool {
        guard let prDate = lastPrDate else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return prDate > thirtyDaysAgo
    }

    /// Days since last PR
    var daysSinceLastPR: Int? {
        guard let prDate = lastPrDate else { return nil }
        return Calendar.current.dateComponents([.day], from: prDate, to: Date()).day
    }

    /// Days since last performed
    var daysSinceLastPerformed: Int? {
        guard let lastDate = lastPerformed else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}

// MARK: - Big Lifts Constants

/// Standard big lifts for strength training scorecards
enum BigLift: String, CaseIterable {
    case benchPress = "Bench Press"
    case squat = "Squat"
    case deadlift = "Deadlift"
    case overheadPress = "Overhead Press"
    case barbellRow = "Barbell Row"

    /// SF Symbol icon name for each lift
    var iconName: String {
        switch self {
        case .benchPress:
            return "figure.strengthtraining.traditional"
        case .squat:
            return "figure.strengthtraining.functional"
        case .deadlift:
            return "figure.cross.training"
        case .overheadPress:
            return "figure.arms.open"
        case .barbellRow:
            return "figure.rowing"
        }
    }

    /// Whether this is a core big lift (SBD)
    var isCoreLift: Bool {
        switch self {
        case .benchPress, .squat, .deadlift:
            return true
        case .overheadPress, .barbellRow:
            return false
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension BigLiftSummary {
    /// Sample data for previews
    static let sample = BigLiftSummary(
        exerciseName: "Bench Press",
        currentMaxWeight: 225.0,
        estimated1rm: 245.0,
        lastPrDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
        prCount: 3,
        lastPerformed: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        improvementPct30d: 8.5,
        totalVolume: 45000.0,
        loadUnit: "lbs"
    )

    /// Sample array for previews
    static let sampleArray: [BigLiftSummary] = [
        BigLiftSummary(
            exerciseName: "Bench Press",
            currentMaxWeight: 225.0,
            estimated1rm: 245.0,
            lastPrDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            prCount: 3,
            lastPerformed: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            improvementPct30d: 8.5,
            totalVolume: 45000.0,
            loadUnit: "lbs"
        ),
        BigLiftSummary(
            exerciseName: "Squat",
            currentMaxWeight: 315.0,
            estimated1rm: 345.0,
            lastPrDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            prCount: 5,
            lastPerformed: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            improvementPct30d: 5.2,
            totalVolume: 68000.0,
            loadUnit: "lbs"
        ),
        BigLiftSummary(
            exerciseName: "Deadlift",
            currentMaxWeight: 405.0,
            estimated1rm: 445.0,
            lastPrDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
            prCount: 4,
            lastPerformed: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            improvementPct30d: -2.1,
            totalVolume: 52000.0,
            loadUnit: "lbs"
        ),
        BigLiftSummary(
            exerciseName: "Overhead Press",
            currentMaxWeight: 135.0,
            estimated1rm: 150.0,
            lastPrDate: nil,
            prCount: 0,
            lastPerformed: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            improvementPct30d: nil,
            totalVolume: 18000.0,
            loadUnit: "lbs"
        )
    ]
}
#endif
