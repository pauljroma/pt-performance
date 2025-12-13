import Foundation
import SwiftUI

/// Represents a daily readiness check-in for a patient
/// Part of the Auto-Regulation System (Build 39 - Phase 3)
struct DailyReadiness: Codable, Identifiable {
    let id: String
    let patientId: String
    let checkInDate: Date

    // Readiness inputs
    let sleepHours: Double?
    let sleepQuality: Int?  // 1-5
    let hrvValue: Double?
    let hrvDeltaFromBaseline: Double?
    let whoopRecoveryPct: Int?  // 0-100
    let subjectiveReadiness: Int?  // 1-5

    // Soreness/pain
    let armSoreness: Bool
    let armSorenessSeverity: Int?  // 1-3
    let shoulderPain: Bool
    let elbowPain: Bool
    let hipPain: Bool
    let kneePain: Bool
    let backPain: Bool
    let jointPainNotes: String?

    // CNS fatigue
    let barSpeedAvg: Double?
    let barSpeedBaseline: Double?

    // Calculated
    let readinessBand: ReadinessBand
    let readinessScore: Double?

    // Override
    let overrideBand: ReadinessBand?
    let overrideReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case checkInDate = "check_in_date"
        case sleepHours = "sleep_hours"
        case sleepQuality = "sleep_quality"
        case hrvValue = "hrv_value"
        case hrvDeltaFromBaseline = "hrv_delta_from_baseline"
        case whoopRecoveryPct = "whoop_recovery_pct"
        case subjectiveReadiness = "subjective_readiness"
        case armSoreness = "arm_soreness"
        case armSorenessSeverity = "arm_soreness_severity"
        case shoulderPain = "shoulder_pain"
        case elbowPain = "elbow_pain"
        case hipPain = "hip_pain"
        case kneePain = "knee_pain"
        case backPain = "back_pain"
        case jointPainNotes = "joint_pain_notes"
        case barSpeedAvg = "bar_speed_avg"
        case barSpeedBaseline = "bar_speed_baseline"
        case readinessBand = "readiness_band"
        case readinessScore = "readiness_score"
        case overrideBand = "override_band"
        case overrideReason = "override_reason"
    }
}

/// Readiness band classification with workout modifications
enum ReadinessBand: String, Codable, CaseIterable {
    case green
    case yellow
    case orange
    case red

    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .green: return "Full prescription"
        case .yellow: return "Reduce top set load 5-8%"
        case .orange: return "Skip top set, back-off work only"
        case .red: return "Technique + arm care only"
        }
    }

    var loadAdjustment: Double {
        switch self {
        case .green: return 0
        case .yellow: return -0.07      // -7%
        case .orange: return -0.12      // -12%
        case .red: return -1.0          // No loading
        }
    }

    var volumeAdjustment: Double {
        switch self {
        case .green: return 0
        case .yellow: return -0.20      // -20%
        case .orange: return -0.35      // -35%
        case .red: return -1.0          // No volume
        }
    }
}

/// Input model for creating a daily readiness check-in
struct ReadinessInput: Codable {
    var sleepHours: Double?
    var sleepQuality: Int?
    var hrvValue: Double?
    var whoopRecoveryPct: Int?
    var subjectiveReadiness: Int?
    var armSoreness: Bool = false
    var armSorenessSeverity: Int?
    var jointPain: [JointPainLocation] = []
    var jointPainNotes: String?

    init(
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        hrvValue: Double? = nil,
        whoopRecoveryPct: Int? = nil,
        subjectiveReadiness: Int? = nil,
        armSoreness: Bool = false,
        armSorenessSeverity: Int? = nil,
        jointPain: [JointPainLocation] = [],
        jointPainNotes: String? = nil
    ) {
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.hrvValue = hrvValue
        self.whoopRecoveryPct = whoopRecoveryPct
        self.subjectiveReadiness = subjectiveReadiness
        self.armSoreness = armSoreness
        self.armSorenessSeverity = armSorenessSeverity
        self.jointPain = jointPain
        self.jointPainNotes = jointPainNotes
    }
}

/// Joint pain location classification
enum JointPainLocation: String, Codable, CaseIterable {
    case shoulder
    case elbow
    case hip
    case knee
    case back

    var displayName: String {
        rawValue.capitalized
    }
}

/// Preview model for real-time band calculation
struct ReadinessPreview {
    let band: ReadinessBand
    let score: Double?
}

/// Readiness modification record applied to a session
struct ReadinessModification: Codable, Identifiable {
    let id: String
    let patientId: String
    let sessionId: String
    let dailyReadinessId: String?

    // Applied band
    let readinessBand: String

    // Modifications
    let loadAdjustmentPct: Double?
    let volumeAdjustmentPct: Double?
    let skipTopSet: Bool
    let techniqueOnly: Bool

    // Exercise-level modifications (stored as JSONB)
    let modifiedExercises: [ModifiedExercise]?

    let appliedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case dailyReadinessId = "daily_readiness_id"
        case readinessBand = "readiness_band"
        case loadAdjustmentPct = "load_adjustment_pct"
        case volumeAdjustmentPct = "volume_adjustment_pct"
        case skipTopSet = "skip_top_set"
        case techniqueOnly = "technique_only"
        case modifiedExercises = "modified_exercises"
        case appliedAt = "applied_at"
    }

    struct ModifiedExercise: Codable {
        let exerciseId: String
        let originalLoad: Double
        let modifiedLoad: Double
        let loadAdjustmentPct: Double

        enum CodingKeys: String, CodingKey {
            case exerciseId = "exercise_id"
            case originalLoad = "original_load"
            case modifiedLoad = "modified_load"
            case loadAdjustmentPct = "load_adjustment_pct"
        }
    }
}

/// HRV baseline tracking (7-day rolling average)
struct HRVBaseline: Codable, Identifiable {
    let id: String
    let patientId: String
    let calculatedDate: Date

    // Baseline calculation
    let baselineValue: Double
    let calculationWindowDays: Int
    let dataPointsUsed: Int?

    // Rolling window data
    let windowStart: Date?
    let windowEnd: Date?

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case calculatedDate = "calculated_date"
        case baselineValue = "baseline_value"
        case calculationWindowDays = "calculation_window_days"
        case dataPointsUsed = "data_points_used"
        case windowStart = "window_start"
        case windowEnd = "window_end"
        case createdAt = "created_at"
    }
}
