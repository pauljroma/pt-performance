//
//  WorkoutModification.swift
//  PTPerformance
//
//  Adaptive Training Engine - Workout modification types and models
//  Generated workout adjustments based on health/readiness data
//

import Foundation

// MARK: - Modification Types

/// Types of workout modifications the system can suggest
enum WorkoutModificationType: String, Codable, CaseIterable {
    case loadAdjustment = "load_adjustment"
    case volumeReduction = "volume_reduction"
    case exerciseSwap = "exercise_swap"
    case workoutDelay = "workout_delay"
    case insertRecoveryDay = "insert_recovery_day"
    case triggerDeload = "trigger_deload"
    case intensityZoneChange = "intensity_zone_change"
    case skipWorkout = "skip_workout"

    var displayName: String {
        switch self {
        case .loadAdjustment: return "Adjust Load"
        case .volumeReduction: return "Reduce Volume"
        case .exerciseSwap: return "Swap Exercise"
        case .workoutDelay: return "Delay Workout"
        case .insertRecoveryDay: return "Recovery Day"
        case .triggerDeload: return "Deload Week"
        case .intensityZoneChange: return "Change Intensity"
        case .skipWorkout: return "Skip Workout"
        }
    }

    var icon: String {
        switch self {
        case .loadAdjustment: return "scalemass"
        case .volumeReduction: return "minus.circle"
        case .exerciseSwap: return "arrow.triangle.2.circlepath"
        case .workoutDelay: return "calendar.badge.clock"
        case .insertRecoveryDay: return "bed.double"
        case .triggerDeload: return "arrow.down.right.circle"
        case .intensityZoneChange: return "gauge.with.needle"
        case .skipWorkout: return "xmark.circle"
        }
    }
}

// MARK: - Modification Status

/// Status of a pending workout modification
enum ModificationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case modified = "modified"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .modified: return "Modified"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Modification Trigger

/// What triggered the modification suggestion
enum ModificationTrigger: String, Codable {
    case lowReadiness = "low_readiness"
    case highReadiness = "high_readiness"
    case consecutiveLowDays = "consecutive_low_days"
    case highACWR = "high_acwr"
    case lowHRV = "low_hrv"
    case poorSleep = "poor_sleep"
    case painReported = "pain_reported"
    case highFatigue = "high_fatigue"
    case manualRequest = "manual_request"
    case aiCoachSuggestion = "ai_coach_suggestion"

    var displayName: String {
        switch self {
        case .lowReadiness: return "Low Readiness"
        case .highReadiness: return "High Readiness"
        case .consecutiveLowDays: return "Extended Fatigue"
        case .highACWR: return "High Training Load"
        case .lowHRV: return "Low HRV"
        case .poorSleep: return "Poor Sleep"
        case .painReported: return "Pain Reported"
        case .highFatigue: return "High Fatigue"
        case .manualRequest: return "Manual Request"
        case .aiCoachSuggestion: return "AI Coach"
        }
    }

    var description: String {
        switch self {
        case .lowReadiness: return "Your readiness score indicates you may benefit from reduced intensity."
        case .highReadiness: return "Your readiness is excellent - consider pushing harder today."
        case .consecutiveLowDays: return "Multiple days of low readiness suggest accumulated fatigue."
        case .highACWR: return "Your acute training load is high relative to your chronic load."
        case .lowHRV: return "Your HRV is significantly below your baseline."
        case .poorSleep: return "Poor sleep quality may affect your performance today."
        case .painReported: return "Pain in affected areas may require exercise modifications."
        case .highFatigue: return "Your fatigue accumulation indicates need for recovery."
        case .manualRequest: return "Modification requested by you or your coach."
        case .aiCoachSuggestion: return "Your AI coach analyzed your data and suggests this change."
        }
    }
}

// MARK: - Exercise Modification Detail

/// Details for modifying a specific exercise
struct ExerciseModificationDetail: Codable, Identifiable {
    var id: UUID = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let originalLoad: Double?
    let suggestedLoad: Double?
    let originalSets: Int?
    let suggestedSets: Int?
    let originalReps: Int?
    let suggestedReps: Int?
    let swapExerciseId: UUID?
    let swapExerciseName: String?
    let reason: String?

    /// Percentage change in load
    var loadChangePercentage: Double? {
        guard let original = originalLoad, let suggested = suggestedLoad, original > 0 else {
            return nil
        }
        return ((suggested - original) / original) * 100
    }

    /// Human-readable summary of the change
    var changeSummary: String {
        var parts: [String] = []

        if let original = originalLoad, let suggested = suggestedLoad {
            let change = Int(((suggested - original) / original) * 100)
            let changeStr = change >= 0 ? "+\(change)%" : "\(change)%"
            parts.append("\(Int(original)) → \(Int(suggested)) lbs (\(changeStr))")
        }

        if let original = originalSets, let suggested = suggestedSets, original != suggested {
            parts.append("\(original) → \(suggested) sets")
        }

        if let swapName = swapExerciseName {
            parts.append("→ \(swapName)")
        }

        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
}

// MARK: - Workout Modification

/// A suggested modification to a scheduled workout
struct WorkoutModification: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let scheduledSessionId: UUID?
    let sessionName: String?
    let scheduledDate: Date
    let modificationType: WorkoutModificationType
    let trigger: ModificationTrigger
    let status: ModificationStatus
    let readinessScore: Double?
    let fatigueScore: Double?

    // Modification details
    let loadAdjustmentPercentage: Double?
    let volumeReductionSets: Int?
    let delayDays: Int?
    let deloadDurationDays: Int?
    let exerciseModifications: [ExerciseModificationDetail]?

    // User interaction
    let reason: String
    let detailedExplanation: String?
    let createdAt: Date
    let resolvedAt: Date?
    let athleteFeedback: String?

    // MARK: - Computed Properties

    /// Whether the modification is still actionable
    var isActionable: Bool {
        status == .pending && scheduledDate >= Calendar.current.startOfDay(for: Date())
    }

    /// Primary display text for the modification
    var primaryDisplayText: String {
        switch modificationType {
        case .loadAdjustment:
            if let percentage = loadAdjustmentPercentage {
                let sign = percentage >= 0 ? "+" : ""
                return "\(sign)\(Int(percentage))% load adjustment"
            }
            return "Load adjustment"

        case .volumeReduction:
            if let sets = volumeReductionSets {
                return "Remove \(sets) set\(sets == 1 ? "" : "s")"
            }
            return "Reduce volume"

        case .workoutDelay:
            if let days = delayDays {
                return "Move to \(days == 1 ? "tomorrow" : "in \(days) days")"
            }
            return "Delay workout"

        case .insertRecoveryDay:
            return "Add recovery day"

        case .triggerDeload:
            if let days = deloadDurationDays {
                return "\(days)-day deload"
            }
            return "Start deload week"

        case .exerciseSwap:
            return "Swap exercises"

        case .intensityZoneChange:
            return "Adjust intensity zone"

        case .skipWorkout:
            return "Skip today's workout"
        }
    }

    /// Secondary description text
    var secondaryDisplayText: String {
        if let explanation = detailedExplanation {
            return explanation
        }
        return trigger.description
    }

    /// Color for the modification card
    var displayColor: String {
        switch modificationType {
        case .loadAdjustment where (loadAdjustmentPercentage ?? 0) > 0:
            return "green"
        case .triggerDeload, .skipWorkout:
            return "red"
        case .insertRecoveryDay:
            return "blue"
        default:
            return "orange"
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case scheduledSessionId = "scheduled_session_id"
        case sessionName = "session_name"
        case scheduledDate = "scheduled_date"
        case modificationType = "modification_type"
        case trigger
        case status
        case readinessScore = "readiness_score"
        case fatigueScore = "fatigue_score"
        case loadAdjustmentPercentage = "load_adjustment_percentage"
        case volumeReductionSets = "volume_reduction_sets"
        case delayDays = "delay_days"
        case deloadDurationDays = "deload_duration_days"
        case exerciseModifications = "exercise_modifications"
        case reason
        case detailedExplanation = "detailed_explanation"
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
        case athleteFeedback = "athlete_feedback"
    }
}

// MARK: - Modification Request

/// Request to create a new workout modification
struct WorkoutModificationRequest: Codable {
    let patientId: UUID
    let scheduledSessionId: UUID?
    let scheduledDate: Date
    let modificationType: WorkoutModificationType
    let trigger: ModificationTrigger
    let readinessScore: Double?
    let fatigueScore: Double?
    let loadAdjustmentPercentage: Double?
    let volumeReductionSets: Int?
    let delayDays: Int?
    let deloadDurationDays: Int?
    let exerciseModifications: [ExerciseModificationDetail]?
    let reason: String
    let detailedExplanation: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case scheduledSessionId = "scheduled_session_id"
        case scheduledDate = "scheduled_date"
        case modificationType = "modification_type"
        case trigger
        case readinessScore = "readiness_score"
        case fatigueScore = "fatigue_score"
        case loadAdjustmentPercentage = "load_adjustment_percentage"
        case volumeReductionSets = "volume_reduction_sets"
        case delayDays = "delay_days"
        case deloadDurationDays = "deload_duration_days"
        case exerciseModifications = "exercise_modifications"
        case reason
        case detailedExplanation = "detailed_explanation"
    }
}

// MARK: - Modification Response

/// Response when accepting/declining a modification
struct ModificationResolution: Codable {
    let modificationId: UUID
    let status: ModificationStatus
    let athleteFeedback: String?
    let customAdjustments: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case modificationId = "modification_id"
        case status
        case athleteFeedback = "athlete_feedback"
        case customAdjustments = "custom_adjustments"
    }

    // Custom encoding for the Any type
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modificationId, forKey: .modificationId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(athleteFeedback, forKey: .athleteFeedback)
        // Note: customAdjustments would need special handling for Supabase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modificationId = try container.decode(UUID.self, forKey: .modificationId)
        status = try container.decode(ModificationStatus.self, forKey: .status)
        athleteFeedback = try container.decodeIfPresent(String.self, forKey: .athleteFeedback)
        customAdjustments = nil // Would need special handling
    }

    init(modificationId: UUID, status: ModificationStatus, athleteFeedback: String? = nil, customAdjustments: [String: Any]? = nil) {
        self.modificationId = modificationId
        self.status = status
        self.athleteFeedback = athleteFeedback
        self.customAdjustments = customAdjustments
    }
}

// MARK: - Readiness Thresholds

/// Configuration for when to trigger modifications
struct ReadinessThresholds {
    /// Score below which to suggest load reduction
    static let lowReadiness: Double = 60

    /// Score below which to suggest skip/recovery
    static let veryLowReadiness: Double = 40

    /// Score above which to suggest intensity increase
    static let highReadiness: Double = 90

    /// Number of consecutive low days to trigger deload
    static let consecutiveLowDaysForDeload: Int = 3

    /// ACWR threshold for volume reduction
    static let highACWR: Double = 1.5

    /// HRV percentage below baseline to trigger modification
    static let hrvDeviationThreshold: Double = -20.0

    /// Minimum sleep hours before suggesting modification
    static let poorSleepThreshold: Double = 5.0

    /// Load reduction percentages by readiness band
    static func loadReductionPercentage(forReadiness score: Double) -> Double {
        switch score {
        case 0..<40: return -50.0
        case 40..<50: return -30.0
        case 50..<60: return -25.0
        case 60..<70: return -20.0
        case 70..<80: return -10.0
        case 90...: return 10.0  // Increase for high readiness
        default: return 0.0
        }
    }

    /// Suggested modification type based on readiness
    static func suggestedModificationType(forReadiness score: Double) -> WorkoutModificationType {
        switch score {
        case 0..<40: return .skipWorkout
        case 40..<50: return .insertRecoveryDay
        case 50..<70: return .loadAdjustment
        case 90...: return .loadAdjustment  // Increase
        default: return .loadAdjustment
        }
    }
}
