import Foundation
import SwiftUI

// MARK: - RTSClearance Model
// Formal clearance documents with signing workflow for Return-to-Sport

/// Represents a formal clearance document for RTS progression
struct RTSClearance: Identifiable, Codable, Hashable {
    let id: UUID
    let protocolId: UUID
    let clearanceType: RTSClearanceType
    var clearanceLevel: RTSTrafficLight
    var status: RTSClearanceStatus
    var assessmentSummary: String
    var recommendations: String
    var restrictions: String?
    let requiresPhysicianSignature: Bool
    var signedBy: UUID?
    var signedAt: Date?
    var coSignedBy: UUID?
    var coSignedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case clearanceType = "clearance_type"
        case clearanceLevel = "clearance_level"
        case status
        case assessmentSummary = "assessment_summary"
        case recommendations
        case restrictions
        case requiresPhysicianSignature = "requires_physician_signature"
        case signedBy = "signed_by"
        case signedAt = "signed_at"
        case coSignedBy = "co_signed_by"
        case coSignedAt = "co_signed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Whether the clearance can be edited
    var canEdit: Bool {
        status == .draft
    }

    /// Whether the clearance can be signed
    var canSign: Bool {
        status == .complete
    }

    /// Whether the clearance can be co-signed
    var canCoSign: Bool {
        status == .signed && requiresPhysicianSignature && coSignedBy == nil
    }

    /// Whether the clearance has been signed
    var isSigned: Bool {
        signedAt != nil
    }

    /// Whether the clearance is fully signed (including co-signature if required)
    var isFullySigned: Bool {
        guard isSigned else { return false }
        if requiresPhysicianSignature {
            return coSignedAt != nil
        }
        return true
    }

    /// Whether the clearance grants full activity clearance
    var isFullyCleared: Bool {
        clearanceLevel == .green && isFullySigned
    }

    /// Formatted signed date string
    var formattedSignedDate: String? {
        guard let date = signedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formatted co-signed date string
    var formattedCoSignedDate: String? {
        guard let date = coSignedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Summary of signature status
    var signatureStatusText: String {
        if isFullySigned {
            return "Fully Signed"
        } else if isSigned && requiresPhysicianSignature {
            return "Awaiting Co-Signature"
        } else if isSigned {
            return "Signed"
        } else if canSign {
            return "Ready for Signature"
        } else {
            return "Draft"
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        protocolId: UUID,
        clearanceType: RTSClearanceType,
        clearanceLevel: RTSTrafficLight,
        status: RTSClearanceStatus = .draft,
        assessmentSummary: String,
        recommendations: String,
        restrictions: String? = nil,
        requiresPhysicianSignature: Bool = false,
        signedBy: UUID? = nil,
        signedAt: Date? = nil,
        coSignedBy: UUID? = nil,
        coSignedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.protocolId = protocolId
        self.clearanceType = clearanceType
        self.clearanceLevel = clearanceLevel
        self.status = status
        self.assessmentSummary = assessmentSummary
        self.recommendations = recommendations
        self.restrictions = restrictions
        self.requiresPhysicianSignature = requiresPhysicianSignature
        self.signedBy = signedBy
        self.signedAt = signedAt
        self.coSignedBy = coSignedBy
        self.coSignedAt = coSignedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Clearance Type

/// Types of RTS clearance documents
enum RTSClearanceType: String, Codable, CaseIterable, Identifiable, Hashable {
    case phaseClearance = "phase_clearance"
    case finalClearance = "final_clearance"
    case conditionalClearance = "conditional_clearance"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .phaseClearance: return "Phase Clearance"
        case .finalClearance: return "Final Clearance"
        case .conditionalClearance: return "Conditional Clearance"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .phaseClearance: return "arrow.right.circle.fill"
        case .finalClearance: return "checkmark.seal.fill"
        case .conditionalClearance: return "exclamationmark.shield.fill"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .phaseClearance: return .blue
        case .finalClearance: return .green
        case .conditionalClearance: return .orange
        }
    }

    /// Description of the clearance type
    var description: String {
        switch self {
        case .phaseClearance:
            return "Clearance to progress to the next phase of rehabilitation"
        case .finalClearance:
            return "Full clearance to return to sport without restrictions"
        case .conditionalClearance:
            return "Limited clearance with specific restrictions and monitoring"
        }
    }
}

// MARK: - Clearance Status

/// Status of an RTS clearance document
enum RTSClearanceStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case draft
    case complete
    case signed
    case coSigned = "co_signed"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .complete: return "Complete"
        case .signed: return "Signed"
        case .coSigned: return "Co-Signed"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .draft: return .gray
        case .complete: return .orange
        case .signed: return .blue
        case .coSigned: return .green
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .complete: return "doc.badge.checkmark"
        case .signed: return "signature"
        case .coSigned: return "checkmark.seal"
        }
    }

    /// Whether the clearance document is locked from editing
    var isLocked: Bool {
        self == .signed || self == .coSigned
    }
}

// MARK: - Input Model

/// Input model for creating/updating RTS clearances
struct RTSClearanceInput: Codable {
    var protocolId: String?
    var clearanceType: String?
    var clearanceLevel: String?
    var status: String?
    var assessmentSummary: String?
    var recommendations: String?
    var restrictions: String?
    var requiresPhysicianSignature: Bool?
    var signedBy: String?
    var signedAt: String?
    var coSignedBy: String?
    var coSignedAt: String?

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case clearanceType = "clearance_type"
        case clearanceLevel = "clearance_level"
        case status
        case assessmentSummary = "assessment_summary"
        case recommendations
        case restrictions
        case requiresPhysicianSignature = "requires_physician_signature"
        case signedBy = "signed_by"
        case signedAt = "signed_at"
        case coSignedBy = "co_signed_by"
        case coSignedAt = "co_signed_at"
    }

    /// Validate input before submission
    func validate() throws {
        guard protocolId != nil else {
            throw RTSClearanceError.invalidInput("Protocol ID is required")
        }
        guard clearanceType != nil else {
            throw RTSClearanceError.invalidInput("Clearance type is required")
        }
        guard clearanceLevel != nil else {
            throw RTSClearanceError.invalidInput("Clearance level is required")
        }
        guard let assessmentSummary = assessmentSummary, !assessmentSummary.isEmpty else {
            throw RTSClearanceError.invalidInput("Assessment summary is required")
        }
        guard let recommendations = recommendations, !recommendations.isEmpty else {
            throw RTSClearanceError.invalidInput("Recommendations are required")
        }
    }
}

// MARK: - Errors

enum RTSClearanceError: LocalizedError {
    case invalidInput(String)
    case clearanceNotFound
    case saveFailed
    case fetchFailed
    case cannotSign
    case cannotCoSign
    case cannotEditSigned
    case missingSignature

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .clearanceNotFound:
            return "RTS clearance not found"
        case .saveFailed:
            return "Failed to save RTS clearance"
        case .fetchFailed:
            return "Failed to fetch RTS clearance"
        case .cannotSign:
            return "Cannot sign this clearance document"
        case .cannotCoSign:
            return "Cannot co-sign this clearance document"
        case .cannotEditSigned:
            return "Cannot edit a signed clearance document"
        case .missingSignature:
            return "This clearance requires a signature before proceeding"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSClearance {
    static let draftSample = RTSClearance(
        protocolId: UUID(),
        clearanceType: .phaseClearance,
        clearanceLevel: .yellow,
        status: .draft,
        assessmentSummary: "Patient has met all Phase 2 criteria. Strength LSI at 85%, functional tests within acceptable limits.",
        recommendations: "Progress to Phase 3 with continued monitoring. Maintain 2x weekly PT sessions.",
        restrictions: "No full-speed cutting or pivoting for 2 more weeks."
    )

    static let signedSample = RTSClearance(
        protocolId: UUID(),
        clearanceType: .finalClearance,
        clearanceLevel: .green,
        status: .signed,
        assessmentSummary: "Patient has successfully completed all RTS criteria. Strength, functional, and psychological assessments all within normal limits.",
        recommendations: "Full return to sport activities. Continue home exercise program for maintenance.",
        restrictions: nil,
        requiresPhysicianSignature: true,
        signedBy: UUID(),
        signedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())
    )

    static let coSignedSample = RTSClearance(
        protocolId: UUID(),
        clearanceType: .finalClearance,
        clearanceLevel: .green,
        status: .coSigned,
        assessmentSummary: "Complete resolution of ACL reconstruction. All objective criteria met.",
        recommendations: "Return to full competitive sport. Follow up in 3 months for re-assessment.",
        restrictions: nil,
        requiresPhysicianSignature: true,
        signedBy: UUID(),
        signedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        coSignedBy: UUID(),
        coSignedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())
    )

    static let conditionalSample = RTSClearance(
        protocolId: UUID(),
        clearanceType: .conditionalClearance,
        clearanceLevel: .yellow,
        status: .signed,
        assessmentSummary: "Patient meets minimum criteria but psychological readiness below optimal. ACL-RSI score 65%.",
        recommendations: "Limited return to non-contact practice. Continue psychological support and confidence building.",
        restrictions: "No game play. Practice only with 75% intensity limits. Weekly reassessment required.",
        requiresPhysicianSignature: false,
        signedBy: UUID(),
        signedAt: Date()
    )
}
#endif
