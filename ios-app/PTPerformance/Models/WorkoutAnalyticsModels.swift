//
//  WorkoutAnalyticsModels.swift
//  PTPerformance
//
//  ACP-965: Workout Session Analytics
//  Data models for workout session metrics, quality scores, personal records,
//  exercise completion tracking, and workout type distribution analytics.
//
//  These models are consumed by ``WorkoutSessionAnalytics`` and forwarded
//  to ``AnalyticsSDK`` for backend ingestion.
//

import Foundation

// MARK: - Workout Type

/// Classification of workout types for distribution analytics.
///
/// Maps to the existing ``WorkoutTemplate.TemplateCategory`` where applicable
/// and extends it with additional granularity for analytics purposes.
enum WorkoutType: String, CaseIterable, Codable, Sendable {
    case strength = "strength"
    case mobility = "mobility"
    case recovery = "recovery"
    case cardio = "cardio"
    case rehab = "rehab"
    case hybrid = "hybrid"
    case prehab = "prehab"
    case unknown = "unknown"

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .mobility: return "Mobility"
        case .recovery: return "Recovery"
        case .cardio:   return "Cardio"
        case .rehab:    return "Rehabilitation"
        case .hybrid:   return "Hybrid"
        case .prehab:   return "Prehab"
        case .unknown:  return "Unknown"
        }
    }

    /// Infer workout type from a template category string.
    static func from(templateCategory: String?) -> WorkoutType {
        guard let category = templateCategory?.lowercased() else { return .unknown }
        switch category {
        case "strength":             return .strength
        case "mobility":             return .mobility
        case "recovery":             return .recovery
        case "cardio":               return .cardio
        case "rehab":                return .rehab
        case "hybrid":               return .hybrid
        case "prehab":               return .prehab
        default:                     return .unknown
        }
    }

    /// Infer workout type from a ``WorkoutBlockType``.
    static func from(blockType: WorkoutBlockType) -> WorkoutType {
        switch blockType {
        case .cardio:                return .cardio
        case .dynamicStretch:        return .mobility
        case .prehab:                return .prehab
        case .push, .pull, .hinge, .lungeSquat: return .strength
        case .functional:            return .hybrid
        case .recovery:              return .recovery
        }
    }
}

// MARK: - Session State

/// The lifecycle state of a tracked workout session.
enum WorkoutSessionState: String, Codable, Sendable {
    /// Session has been started but no exercises completed yet.
    case active = "active"
    /// Session is temporarily paused (e.g. user took a break).
    case paused = "paused"
    /// Session was completed normally.
    case completed = "completed"
    /// Session was abandoned before all exercises were finished.
    case abandoned = "abandoned"
}

// MARK: - Exercise Completion Record

/// Tracks how much of a single exercise was completed versus what was prescribed.
///
/// Used to compute per-exercise and per-session completion rates.
struct ExerciseCompletionRecord: Codable, Sendable {
    /// The exercise identifier (maps to `Exercise.id` or `ManualSessionExercise.id`).
    let exerciseId: UUID
    /// Human-readable exercise name for reporting.
    let exerciseName: String
    /// Number of sets prescribed / planned.
    let plannedSets: Int
    /// Number of sets actually completed.
    let completedSets: Int
    /// Prescribed reps per set (parsed from string like "8-10" to use the lower bound).
    let plannedRepsPerSet: Int?
    /// Actual reps completed per set.
    let completedReps: [Int]
    /// Prescribed load in the exercise's load unit.
    let plannedLoad: Double?
    /// Actual load used.
    let actualLoad: Double?
    /// Load unit (e.g. "lbs", "kg").
    let loadUnit: String?
    /// When this exercise was completed.
    let completedAt: Date

    /// Completion rate as a fraction (0.0 ... 1.0) based on sets.
    var setCompletionRate: Double {
        guard plannedSets > 0 else { return completedSets > 0 ? 1.0 : 0.0 }
        return min(Double(completedSets) / Double(plannedSets), 1.0)
    }

    /// Whether the exercise was fully completed (all planned sets done).
    var isFullyCompleted: Bool {
        completedSets >= plannedSets
    }

    /// Computed volume: actual load * total reps completed.
    var volume: Double {
        let totalReps = completedReps.reduce(0, +)
        let load = actualLoad ?? plannedLoad ?? 0
        return load * Double(totalReps)
    }
}

// MARK: - Rest Timer Record

/// Captures a single rest timer usage event during a workout session.
struct RestTimerRecord: Codable, Sendable {
    /// The prescribed rest duration in seconds (nil if user chose their own).
    let prescribedDuration: Int?
    /// The actual rest duration in seconds.
    let actualDuration: Int
    /// Whether the user skipped (ended early) the rest timer.
    let wasSkipped: Bool
    /// When the rest period started.
    let startedAt: Date
    /// The exercise the rest followed.
    let afterExerciseId: UUID?

    /// How much of the prescribed rest was actually taken (0.0 ... 1.0+).
    /// Returns nil if no prescribed duration was set.
    var restComplianceRate: Double? {
        guard let prescribed = prescribedDuration, prescribed > 0 else { return nil }
        return Double(actualDuration) / Double(prescribed)
    }
}

// MARK: - Workout Personal Record

/// Represents a personal record (PR) detected during a workout session.
///
/// PRs are detected by comparing the current exercise performance against
/// historical bests stored in the analytics history.
///
/// Named `WorkoutPersonalRecord` to distinguish from the chart-layer
/// `PersonalRecord` in `ChartData.swift`.
struct WorkoutPersonalRecord: Codable, Sendable {
    /// Unique identifier for this PR record.
    let id: String
    /// The exercise template identifier for cross-session comparison.
    let exerciseTemplateId: UUID
    /// Human-readable exercise name.
    let exerciseName: String
    /// The type of PR achieved.
    let recordType: RecordType
    /// The previous best value.
    let previousValue: Double
    /// The new record value.
    let newValue: Double
    /// The unit for display (e.g. "lbs", "kg", "reps").
    let unit: String
    /// When the PR was achieved.
    let achievedAt: Date
    /// The session in which the PR was achieved.
    let sessionId: UUID

    /// Types of personal records that can be detected.
    enum RecordType: String, Codable, Sendable, CaseIterable {
        /// Heaviest weight used for the exercise.
        case maxWeight = "max_weight"
        /// Most reps completed in a single set at a given weight.
        case maxReps = "max_reps"
        /// Highest single-set volume (weight * reps).
        case maxVolume = "max_volume"
        /// Highest total session volume for the exercise (all sets).
        case maxTotalVolume = "max_total_volume"

        var displayName: String {
            switch self {
            case .maxWeight:      return "Max Weight"
            case .maxReps:        return "Max Reps"
            case .maxVolume:      return "Max Set Volume"
            case .maxTotalVolume: return "Max Total Volume"
            }
        }
    }

    /// The percentage improvement over the previous record.
    var improvementPercentage: Double {
        guard previousValue > 0 else { return 0 }
        return ((newValue - previousValue) / previousValue) * 100
    }
}

// MARK: - Session Quality Score

/// A composite quality score for a completed workout session.
///
/// The score is derived from three weighted components:
/// - **Completion** (40%): How many prescribed exercises/sets were completed.
/// - **Consistency** (30%): How closely actual rest times matched prescribed times.
/// - **Effort** (30%): Average RPE relative to target intensity.
///
/// Each component is scored 0-100. The final score is a weighted average.
struct SessionQualityScore: Codable, Sendable {
    /// Overall quality score (0-100).
    let overallScore: Int
    /// Completion component score (0-100).
    let completionScore: Int
    /// Consistency component score (0-100).
    let consistencyScore: Int
    /// Effort component score (0-100).
    let effortScore: Int
    /// Qualitative rating derived from the overall score.
    let rating: QualityRating
    /// When the score was calculated.
    let calculatedAt: Date

    /// Qualitative rating tiers.
    enum QualityRating: String, Codable, Sendable, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case needsImprovement = "needs_improvement"

        var displayName: String {
            switch self {
            case .excellent:         return "Excellent"
            case .good:              return "Good"
            case .fair:              return "Fair"
            case .needsImprovement:  return "Needs Improvement"
            }
        }

        /// Derive a rating from a numeric score (0-100).
        static func from(score: Int) -> QualityRating {
            switch score {
            case 85...100: return .excellent
            case 70..<85:  return .good
            case 50..<70:  return .fair
            default:       return .needsImprovement
            }
        }
    }

    /// Weight applied to each component in the final score.
    enum ComponentWeight {
        static let completion: Double = 0.40
        static let consistency: Double = 0.30
        static let effort: Double = 0.30
    }
}

// MARK: - Workout Session Metrics

/// Comprehensive metrics captured for a single workout session.
///
/// Aggregates exercise completion data, rest timer usage, personal records,
/// timing information, and the quality score into a single reportable snapshot.
struct WorkoutSessionMetrics: Codable, Sendable {
    /// Unique identifier for this metrics record.
    let id: String
    /// The session this metrics record belongs to.
    let sessionId: UUID
    /// The workout type classification.
    let workoutType: WorkoutType
    /// The session source (prescribed, manual, etc.).
    let sessionSource: String?

    // MARK: Timing

    /// When the session was started.
    let startedAt: Date
    /// When the session ended (nil if still active).
    let endedAt: Date?
    /// Total wall-clock duration in seconds (including pauses).
    let totalDurationSeconds: Int
    /// Time spent actively working out (excluding pauses) in seconds.
    let activeDurationSeconds: Int
    /// Total time spent paused in seconds.
    let pausedDurationSeconds: Int
    /// Number of times the session was paused.
    let pauseCount: Int

    // MARK: Exercise Completion

    /// Total number of exercises in the session.
    let totalExercises: Int
    /// Number of exercises completed (at least one set done).
    let completedExercises: Int
    /// Total planned sets across all exercises.
    let totalPlannedSets: Int
    /// Total sets actually completed.
    let totalCompletedSets: Int
    /// Per-exercise completion breakdown.
    let exerciseCompletions: [ExerciseCompletionRecord]

    // MARK: Rest Timer

    /// All rest timer records for the session.
    let restTimerRecords: [RestTimerRecord]
    /// Average rest duration in seconds (nil if no rest timers were used).
    let averageRestSeconds: Int?
    /// Number of rest timers that were skipped.
    let restTimersSkipped: Int

    // MARK: Weight & Volume

    /// Total session volume (sum of weight * reps across all sets).
    let totalVolume: Double
    /// Average RPE across all logged exercises (nil if none reported).
    let averageRPE: Double?
    /// Average pain score across all logged exercises (nil if none reported).
    let averagePainScore: Double?

    // MARK: Personal Records

    /// Any personal records achieved during this session.
    let personalRecords: [WorkoutPersonalRecord]

    // MARK: Quality

    /// Session quality score (nil if score could not be computed).
    let qualityScore: SessionQualityScore?

    /// Overall exercise completion rate (0.0 ... 1.0).
    var exerciseCompletionRate: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercises) / Double(totalExercises)
    }

    /// Overall set completion rate (0.0 ... 1.0).
    var setCompletionRate: Double {
        guard totalPlannedSets > 0 else { return totalCompletedSets > 0 ? 1.0 : 0.0 }
        return min(Double(totalCompletedSets) / Double(totalPlannedSets), 1.0)
    }

    /// Whether any personal records were set during this session.
    var hasPRs: Bool {
        !personalRecords.isEmpty
    }
}

// MARK: - Weight History Entry

/// A historical weight entry for a specific exercise, used for PR detection.
struct WeightHistoryEntry: Codable, Sendable {
    /// The exercise template identifier.
    let exerciseTemplateId: UUID
    /// The maximum weight recorded for this exercise.
    let maxWeight: Double
    /// The maximum reps at the max weight.
    let maxRepsAtMaxWeight: Int
    /// The maximum single-set volume (weight * reps).
    let maxSetVolume: Double
    /// The maximum total volume across all sets in a single session.
    let maxTotalVolume: Double
    /// When this record was last updated.
    let lastUpdatedAt: Date
}

// MARK: - Workout Type Distribution

/// Aggregated distribution of workout types over a time period.
struct WorkoutTypeDistribution: Codable, Sendable {
    /// The time period start date.
    let periodStart: Date
    /// The time period end date.
    let periodEnd: Date
    /// Number of sessions per workout type.
    let sessionCounts: [WorkoutType: Int]
    /// Total sessions in the period.
    let totalSessions: Int

    /// Returns the percentage for a given workout type (0.0 ... 100.0).
    func percentage(for type: WorkoutType) -> Double {
        guard totalSessions > 0 else { return 0 }
        let count = sessionCounts[type] ?? 0
        return (Double(count) / Double(totalSessions)) * 100
    }

    /// Returns the most frequent workout type, or nil if no sessions exist.
    var dominantType: WorkoutType? {
        sessionCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Session Analytics Summary

/// A high-level summary of workout analytics over a configurable time window.
///
/// Used for dashboard displays and trend reporting.
struct SessionAnalyticsSummary: Codable, Sendable {
    /// When this summary was generated.
    let generatedAt: Date
    /// Total sessions tracked.
    let totalSessions: Int
    /// Total sessions completed (not abandoned).
    let completedSessions: Int
    /// Total sessions abandoned.
    let abandonedSessions: Int
    /// Average session duration in seconds.
    let averageDurationSeconds: Int
    /// Average exercise completion rate (0.0 ... 1.0).
    let averageCompletionRate: Double
    /// Average quality score across all completed sessions.
    let averageQualityScore: Int?
    /// Total personal records achieved.
    let totalPRs: Int
    /// Workout type distribution.
    let typeDistribution: WorkoutTypeDistribution
    /// Average rest time in seconds across all sessions.
    let averageRestSeconds: Int?
    /// Total volume lifted across all sessions.
    let totalVolume: Double
}
