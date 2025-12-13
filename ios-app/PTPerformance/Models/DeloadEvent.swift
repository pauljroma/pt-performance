import Foundation

/// Represents a deload event triggered by accumulated fatigue markers
struct DeloadEvent: Codable, Identifiable {
    let id: String
    let patientId: String
    let programId: String?
    let phaseId: String?

    // Trigger information
    let triggerDate: Date
    let triggersMet: [String]
    let triggerWindowStart: Date?
    let triggerWindowEnd: Date?

    // Deload prescription
    let loadReductionPct: Double
    let volumeReductionPct: Double
    let durationDays: Int

    // Status
    let status: DeloadStatus
    let startedAt: Date?
    let completedAt: Date?

    // Outcome
    let recoveryNotes: String?
    let effectivenessRating: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programId = "program_id"
        case phaseId = "phase_id"
        case triggerDate = "trigger_date"
        case triggersMet = "triggers_met"
        case triggerWindowStart = "trigger_window_start"
        case triggerWindowEnd = "trigger_window_end"
        case loadReductionPct = "load_reduction_pct"
        case volumeReductionPct = "volume_reduction_pct"
        case durationDays = "duration_days"
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case recoveryNotes = "recovery_notes"
        case effectivenessRating = "effectiveness_rating"
    }
}

/// Deload status tracking
enum DeloadStatus: String, Codable {
    case scheduled
    case active
    case completed
    case cancelled

    var description: String {
        switch self {
        case .scheduled:
            return "Scheduled"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

/// Individual deload trigger occurrence within rolling window
struct DeloadTrigger: Codable, Identifiable {
    let id: String
    let patientId: String
    let triggerType: DeloadTriggerType
    let occurredAt: Date
    let severity: Int  // 1-3
    let details: [String: String]?
    let evaluationWindowStart: Date?
    let evaluationWindowEnd: Date?
    let resolved: Bool
    let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case triggerType = "trigger_type"
        case occurredAt = "occurred_at"
        case severity
        case details
        case evaluationWindowStart = "evaluation_window_start"
        case evaluationWindowEnd = "evaluation_window_end"
        case resolved
        case resolvedAt = "resolved_at"
    }
}

/// Types of deload triggers
enum DeloadTriggerType: String, Codable {
    case missedRepsPrimary = "missed_reps_primary"
    case rpeOvershoot = "rpe_overshoot"
    case jointPain = "joint_pain"
    case readinessLow = "readiness_low"

    var description: String {
        switch self {
        case .missedRepsPrimary:
            return "Missed reps on primary lift"
        case .rpeOvershoot:
            return "RPE overshoot"
        case .jointPain:
            return "Joint pain reported"
        case .readinessLow:
            return "Low readiness score"
        }
    }

    var severityThreshold: Int {
        switch self {
        case .missedRepsPrimary:
            return 2  // Missing reps 2+ times in window
        case .rpeOvershoot:
            return 2  // RPE overshoot 2+ times in window
        case .jointPain:
            return 1  // Any joint pain is serious
        case .readinessLow:
            return 3  // Low readiness 3+ times in window
        }
    }
}

/// Input model for creating a deload event
struct CreateDeloadEventInput: Codable {
    let patientId: String
    let programId: String?
    let phaseId: String?
    let triggerDate: Date
    let triggersMet: [String]
    let triggerWindowStart: Date?
    let triggerWindowEnd: Date?
    let loadReductionPct: Double
    let volumeReductionPct: Double
    let durationDays: Int
    let status: DeloadStatus

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case programId = "program_id"
        case phaseId = "phase_id"
        case triggerDate = "trigger_date"
        case triggersMet = "triggers_met"
        case triggerWindowStart = "trigger_window_start"
        case triggerWindowEnd = "trigger_window_end"
        case loadReductionPct = "load_reduction_pct"
        case volumeReductionPct = "volume_reduction_pct"
        case durationDays = "duration_days"
        case status
    }
}

/// Input model for creating a deload trigger
struct CreateDeloadTriggerInput: Codable {
    let patientId: String
    let triggerType: DeloadTriggerType
    let occurredAt: Date
    let severity: Int
    let details: [String: String]?
    let evaluationWindowStart: Date?
    let evaluationWindowEnd: Date?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case triggerType = "trigger_type"
        case occurredAt = "occurred_at"
        case severity
        case details
        case evaluationWindowStart = "evaluation_window_start"
        case evaluationWindowEnd = "evaluation_window_end"
    }
}

/// Deload evaluation result from 7-day rolling window
struct DeloadEvaluation {
    let shouldTriggerDeload: Bool
    let triggerCount: Int
    let uniqueTriggerTypes: Set<DeloadTriggerType>
    let triggers: [DeloadTrigger]
    let windowStart: Date
    let windowEnd: Date

    var reason: String {
        if shouldTriggerDeload {
            let triggerNames = uniqueTriggerTypes.map { $0.description }.joined(separator: ", ")
            return "Deload triggered by \(uniqueTriggerTypes.count) different trigger types: \(triggerNames)"
        } else {
            return "Insufficient triggers for deload (need ≥2 unique types)"
        }
    }
}
