//
//  ApprovalRequest.swift
//  PTPerformance
//
//  Therapist Approval Gate model for human-in-the-loop AI modification review.
//  AI-generated workout modifications require therapist approval before being applied.
//

import Foundation

// MARK: - Request Type

/// Types of changes that require therapist approval
enum ApprovalRequestType: String, Codable, CaseIterable {
    case workoutModification = "workout_modification"
    case intensityIncrease = "intensity_increase"
    case exerciseSubstitution = "exercise_substitution"
    case programChange = "program_change"
    case returnToActivity = "return_to_activity"

    var displayName: String {
        switch self {
        case .workoutModification: return "Workout Modification"
        case .intensityIncrease: return "Intensity Increase"
        case .exerciseSubstitution: return "Exercise Substitution"
        case .programChange: return "Program Change"
        case .returnToActivity: return "Return to Activity"
        }
    }

    var icon: String {
        switch self {
        case .workoutModification: return "pencil.circle"
        case .intensityIncrease: return "arrow.up.circle"
        case .exerciseSubstitution: return "arrow.triangle.2.circlepath"
        case .programChange: return "doc.badge.gearshape"
        case .returnToActivity: return "figure.run"
        }
    }
}

// MARK: - Severity

/// Risk level of the proposed change
enum ApprovalSeverity: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var colorName: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }

    /// Whether this severity level requires manual therapist review
    var requiresManualReview: Bool {
        switch self {
        case .low: return false
        case .medium, .high, .critical: return true
        }
    }
}

// MARK: - Status

/// Current status of the approval request
enum ApprovalStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case rejected
    case expired
    case autoApproved = "auto_approved"

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        case .autoApproved: return "Auto-Approved"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .expired: return "clock.badge.exclamationmark"
        case .autoApproved: return "checkmark.seal.fill"
        }
    }

    /// Whether the modification can be applied
    var isApproved: Bool {
        self == .approved || self == .autoApproved
    }

    /// Whether the request is still awaiting a decision
    var isPending: Bool {
        self == .pending
    }
}

// MARK: - Approval Request Model

/// A therapist approval request for an AI-generated workout modification
struct ApprovalRequest: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID?
    let requestType: ApprovalRequestType
    let severity: ApprovalSeverity
    let status: ApprovalStatus

    // What's being requested
    let title: String
    let description: String
    let suggestedChange: SuggestedChangeData
    let aiRationale: String?
    let aiConfidence: Double?

    // Therapist response
    let therapistNotes: String?
    let reviewedAt: Date?
    let reviewedBy: UUID?

    // Auto-approval rules
    let autoApproveIfLowSeverity: Bool
    let expiresAt: Date?

    // Timestamps
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    /// Whether the request is still actionable (pending and not expired)
    var isActionable: Bool {
        status.isPending && !isExpired
    }

    /// Whether the request has expired based on the expiration date
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }

    /// Time remaining until expiration, formatted for display
    var timeRemainingText: String? {
        guard let expiresAt = expiresAt, status.isPending else { return nil }
        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining / 3600)
        if hours > 24 {
            let days = hours / 24
            return "\(days)d remaining"
        }
        return "\(hours)h remaining"
    }

    /// Formatted AI confidence as a percentage string
    var confidenceText: String? {
        guard let confidence = aiConfidence else { return nil }
        return "\(Int(confidence * 100))% confidence"
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case requestType = "request_type"
        case severity
        case status
        case title
        case description
        case suggestedChange = "suggested_change"
        case aiRationale = "ai_rationale"
        case aiConfidence = "ai_confidence"
        case therapistNotes = "therapist_notes"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case autoApproveIfLowSeverity = "auto_approve_if_low_severity"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Defensive Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        therapistId = container.safeOptionalUUID(forKey: .therapistId)
        requestType = container.safeEnum(ApprovalRequestType.self, forKey: .requestType, default: .workoutModification)
        severity = container.safeEnum(ApprovalSeverity.self, forKey: .severity, default: .medium)
        status = container.safeEnum(ApprovalStatus.self, forKey: .status, default: .pending)

        title = container.safeString(forKey: .title, default: "Modification Request")
        description = container.safeString(forKey: .description, default: "")
        suggestedChange = (try? container.decode(SuggestedChangeData.self, forKey: .suggestedChange)) ?? SuggestedChangeData.empty
        aiRationale = container.safeOptionalString(forKey: .aiRationale)
        aiConfidence = container.safeOptionalDouble(forKey: .aiConfidence)

        therapistNotes = container.safeOptionalString(forKey: .therapistNotes)
        reviewedAt = container.safeOptionalDate(forKey: .reviewedAt)
        reviewedBy = container.safeOptionalUUID(forKey: .reviewedBy)

        autoApproveIfLowSeverity = container.safeBool(forKey: .autoApproveIfLowSeverity, default: true)
        expiresAt = container.safeOptionalDate(forKey: .expiresAt)

        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID? = nil,
        requestType: ApprovalRequestType,
        severity: ApprovalSeverity,
        status: ApprovalStatus = .pending,
        title: String,
        description: String,
        suggestedChange: SuggestedChangeData = .empty,
        aiRationale: String? = nil,
        aiConfidence: Double? = nil,
        therapistNotes: String? = nil,
        reviewedAt: Date? = nil,
        reviewedBy: UUID? = nil,
        autoApproveIfLowSeverity: Bool = true,
        expiresAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.requestType = requestType
        self.severity = severity
        self.status = status
        self.title = title
        self.description = description
        self.suggestedChange = suggestedChange
        self.aiRationale = aiRationale
        self.aiConfidence = aiConfidence
        self.therapistNotes = therapistNotes
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.autoApproveIfLowSeverity = autoApproveIfLowSeverity
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Suggested Change Data

/// Container for the JSONB suggested_change column.
/// Wraps arbitrary change data with typed accessors for common fields.
/// Uses AnyCodable from ProgramBuilderService for JSON type erasure.
struct SuggestedChangeData: Codable {
    let rawData: [String: AnyCodable]

    /// Empty change data
    static let empty = SuggestedChangeData(rawData: [:])

    /// Modification type (e.g., "load_reduction", "exercise_swap")
    var modificationType: String? {
        rawData["modification_type"]?.value as? String
    }

    /// Percentage change (positive for increases, negative for reductions)
    var changePercentage: Double? {
        (rawData["increase_percentage"]?.value as? Double) ?? (rawData["reduction_percentage"]?.value as? Double)
    }

    /// Whether the substitution targets the same muscle group
    var sameMusclGroup: Bool? {
        rawData["same_muscle_group"]?.value as? Bool
    }

    /// Whether the change is pain-related
    var painRelated: Bool? {
        rawData["pain_related"]?.value as? Bool
    }

    init(rawData: [String: AnyCodable]) {
        self.rawData = rawData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawData = (try? container.decode([String: AnyCodable].self)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawData)
    }
}

// MARK: - Approval Review Request

/// Data structure for submitting a therapist review (approve/reject)
struct ApprovalReviewRequest: Codable {
    let status: String
    let therapistNotes: String?
    let reviewedAt: String
    let reviewedBy: String

    enum CodingKeys: String, CodingKey {
        case status
        case therapistNotes = "therapist_notes"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
    }
}

// MARK: - Mock Data

extension ApprovalRequest {
    static let mockPendingRequests: [ApprovalRequest] = [
        ApprovalRequest(
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100") ?? UUID(),
            requestType: .intensityIncrease,
            severity: .high,
            status: .pending,
            title: "Increase squat load by 15%",
            description: "Based on consistent readiness scores above 85 for 5 consecutive days and successful completion of current load without pain, the AI recommends increasing squat load from 185 lbs to 213 lbs.",
            aiRationale: "Patient has shown consistent high readiness (avg 88/100) over the past week with zero pain reports during squats. Current RPE is 6/10, indicating room for progression.",
            aiConfidence: 0.82,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 48, to: Date())
        ),
        ApprovalRequest(
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100") ?? UUID(),
            requestType: .exerciseSubstitution,
            severity: .medium,
            status: .pending,
            title: "Substitute barbell row with cable row",
            description: "Patient reported mild lower back discomfort (3/10). AI suggests substituting barbell rows with seated cable rows to reduce spinal loading while maintaining similar training stimulus.",
            aiRationale: "Pain reported in lumbar region during bent-over movements. Cable row provides equivalent lat/rhomboid activation with reduced spinal compression.",
            aiConfidence: 0.91,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 60, to: Date())
        ),
        ApprovalRequest(
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100") ?? UUID(),
            requestType: .returnToActivity,
            severity: .critical,
            status: .pending,
            title: "Return to throwing program - Phase 2",
            description: "Patient has completed Phase 1 interval throwing program with no pain. AI recommends progressing to Phase 2 (increased distance and intensity).",
            aiRationale: "All Phase 1 checkpoints met: zero pain during and after throwing, full ROM restored, adequate arm care compliance (95%). Ready for Phase 2 based on protocol criteria.",
            aiConfidence: 0.75,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 72, to: Date())
        ),
    ]
}
