//
//  ProgramReview.swift
//  PTPerformance
//
//  ACP-395: PT Review and Approval Workflow
//  Models for the program review/approval process where therapists review
//  AI-generated programs, add evidence citations, and approve for deployment.
//

import Foundation

// MARK: - Review Status

/// Status of a program review in the approval workflow
enum ReviewStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case pendingReview = "pending_review"
    case inReview = "in_review"
    case approved
    case rejected
    case revisionRequested = "revision_requested"

    /// Human-readable display name for UI
    var displayName: String {
        switch self {
        case .pendingReview: return "Pending Review"
        case .inReview: return "In Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .revisionRequested: return "Revision Requested"
        }
    }

    /// SF Symbol name for status indicator
    var iconName: String {
        switch self {
        case .pendingReview: return "clock.badge.questionmark"
        case .inReview: return "eye"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        case .revisionRequested: return "arrow.uturn.backward.circle"
        }
    }

    /// Whether the review is in an active/editable state
    var isEditable: Bool {
        switch self {
        case .pendingReview, .inReview, .revisionRequested: return true
        case .approved, .rejected: return false
        }
    }
}

// MARK: - Program Review Status (for programs table)

/// Review status for the programs table `review_status` column
enum ProgramReviewStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case draft
    case pendingReview = "pending_review"
    case inReview = "in_review"
    case approved
    case rejected

    /// Human-readable display name for UI
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pendingReview: return "Pending Review"
        case .inReview: return "In Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Evidence Level

/// Hierarchy of evidence levels for clinical citations in program reviews
enum ReviewEvidenceLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case systematicReview = "systematic_review"
    case rct
    case cohortStudy = "cohort_study"
    case caseStudy = "case_study"
    case expertOpinion = "expert_opinion"
    case clinicalGuideline = "clinical_guideline"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .systematicReview: return "Systematic Review"
        case .rct: return "Randomized Controlled Trial"
        case .cohortStudy: return "Cohort Study"
        case .caseStudy: return "Case Study"
        case .expertOpinion: return "Expert Opinion"
        case .clinicalGuideline: return "Clinical Guideline"
        }
    }

    /// Numeric rank for sorting (lower = stronger evidence)
    var rank: Int {
        switch self {
        case .systematicReview: return 1
        case .rct: return 2
        case .cohortStudy: return 3
        case .clinicalGuideline: return 4
        case .caseStudy: return 5
        case .expertOpinion: return 6
        }
    }
}

// MARK: - Contraindication Severity

/// Severity level for contraindication flags
enum ContraindicationSeverity: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case critical
    case warning
    case info

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .warning: return "Warning"
        case .info: return "Info"
        }
    }

    /// SF Symbol name for severity indicator
    var iconName: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Program Edit

/// Tracks a single edit made by the PT to the AI-generated program
struct ProgramEdit: Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for this edit (client-generated)
    let id: UUID
    let exerciseId: UUID
    let fieldChanged: String
    let oldValue: String
    let newValue: String

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case fieldChanged = "field_changed"
        case oldValue = "old_value"
        case newValue = "new_value"
    }

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        fieldChanged: String,
        oldValue: String,
        newValue: String
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.fieldChanged = fieldChanged
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - Review Evidence Citation

/// Research citation supporting a program's exercise selection or progression
struct ReviewEvidenceCitation: Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for this citation (client-generated)
    let id: UUID
    let title: String
    let authors: [String]
    let journal: String?
    let year: Int?
    let doi: String?
    let relevanceNote: String?
    let evidenceLevel: ReviewEvidenceLevel

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authors
        case journal
        case year
        case doi
        case relevanceNote = "relevance_note"
        case evidenceLevel = "evidence_level"
    }

    init(
        id: UUID = UUID(),
        title: String,
        authors: [String],
        journal: String? = nil,
        year: Int? = nil,
        doi: String? = nil,
        relevanceNote: String? = nil,
        evidenceLevel: ReviewEvidenceLevel = .expertOpinion
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.journal = journal
        self.year = year
        self.doi = doi
        self.relevanceNote = relevanceNote
        self.evidenceLevel = evidenceLevel
    }

    /// Formatted author string for display (e.g., "Smith et al., 2024")
    var formattedAuthors: String {
        guard !authors.isEmpty else { return "Unknown Authors" }
        if authors.count == 1 {
            return authors[0]
        } else if authors.count == 2 {
            return "\(authors[0]) & \(authors[1])"
        } else {
            return "\(authors[0]) et al."
        }
    }

    /// Short citation for inline display (e.g., "Smith et al., 2024")
    var shortCitation: String {
        if let year = year {
            return "\(formattedAuthors), \(year)"
        }
        return formattedAuthors
    }
}

// MARK: - Review Contraindication

/// Safety concern or contraindication flagged for a program
struct ReviewContraindication: Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for this contraindication (client-generated)
    let id: UUID
    let type: String
    let description: String
    let severity: ContraindicationSeverity
    let affectedExercises: [UUID]

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case description
        case severity
        case affectedExercises = "affected_exercises"
    }

    init(
        id: UUID = UUID(),
        type: String,
        description: String,
        severity: ContraindicationSeverity,
        affectedExercises: [UUID] = []
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.severity = severity
        self.affectedExercises = affectedExercises
    }
}

// MARK: - Program Review

/// Represents a PT's review of an AI-generated (or manually created) program.
/// Maps to the `program_reviews` database table.
struct ProgramReview: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let programId: UUID
    let reviewerId: UUID
    let status: ReviewStatus
    let aiGenerated: Bool
    let aiModel: String?
    let aiConfidenceScore: Double?
    let reviewNotes: String?
    let rejectionReason: String?
    let editsMade: [ProgramEdit]
    let evidenceCitations: [ReviewEvidenceCitation]
    let contraindications: [ReviewContraindication]
    let approvedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case reviewerId = "reviewer_id"
        case status
        case aiGenerated = "ai_generated"
        case aiModel = "ai_model"
        case aiConfidenceScore = "ai_confidence_score"
        case reviewNotes = "review_notes"
        case rejectionReason = "rejection_reason"
        case editsMade = "edits_made"
        case evidenceCitations = "evidence_citations"
        case contraindications
        case approvedAt = "approved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        programId: UUID,
        reviewerId: UUID,
        status: ReviewStatus = .pendingReview,
        aiGenerated: Bool = true,
        aiModel: String? = nil,
        aiConfidenceScore: Double? = nil,
        reviewNotes: String? = nil,
        rejectionReason: String? = nil,
        editsMade: [ProgramEdit] = [],
        evidenceCitations: [ReviewEvidenceCitation] = [],
        contraindications: [ReviewContraindication] = [],
        approvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.programId = programId
        self.reviewerId = reviewerId
        self.status = status
        self.aiGenerated = aiGenerated
        self.aiModel = aiModel
        self.aiConfidenceScore = aiConfidenceScore
        self.reviewNotes = reviewNotes
        self.rejectionReason = rejectionReason
        self.editsMade = editsMade
        self.evidenceCitations = evidenceCitations
        self.contraindications = contraindications
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        programId = container.safeUUID(forKey: .programId)
        reviewerId = container.safeUUID(forKey: .reviewerId)

        // Status with fallback
        status = container.safeOptionalEnum(ReviewStatus.self, forKey: .status) ?? .pendingReview

        // Booleans with fallback
        if container.contains(.aiGenerated) {
            aiGenerated = container.safeBool(forKey: .aiGenerated, default: true)
        } else {
            aiGenerated = true
        }

        // Optional strings
        aiModel = container.safeOptionalString(forKey: .aiModel)
        reviewNotes = container.safeOptionalString(forKey: .reviewNotes)
        rejectionReason = container.safeOptionalString(forKey: .rejectionReason)

        // Optional double
        aiConfidenceScore = container.safeOptionalDouble(forKey: .aiConfidenceScore)

        // JSONB arrays with fallback to empty
        editsMade = (try? container.decodeIfPresent([ProgramEdit].self, forKey: .editsMade)) ?? []
        evidenceCitations = (try? container.decodeIfPresent([ReviewEvidenceCitation].self, forKey: .evidenceCitations)) ?? []
        contraindications = (try? container.decodeIfPresent([ReviewContraindication].self, forKey: .contraindications)) ?? []

        // Dates with fallback
        approvedAt = container.safeOptionalDate(forKey: .approvedAt)
        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)
    }

    // MARK: - Computed Properties

    /// Whether the review has any critical contraindications
    var hasCriticalContraindications: Bool {
        contraindications.contains { $0.severity == .critical }
    }

    /// Total number of edits made by the PT
    var editCount: Int {
        editsMade.count
    }

    /// Whether the AI confidence is below a threshold that warrants careful review
    var needsCarefulReview: Bool {
        guard let score = aiConfidenceScore else { return true }
        return score < 70.0
    }

    /// Formatted confidence score for display (e.g., "85%")
    var formattedConfidence: String? {
        guard let score = aiConfidenceScore else { return nil }
        return "\(Int(score))%"
    }
}

// MARK: - Preview Support

#if DEBUG
extension ProgramReview {
    /// Sample pending review for previews
    static var samplePending: ProgramReview {
        ProgramReview(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            programId: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            reviewerId: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            status: .pendingReview,
            aiGenerated: true,
            aiModel: "claude",
            aiConfidenceScore: 87.5,
            reviewNotes: nil,
            rejectionReason: nil,
            editsMade: [],
            evidenceCitations: [.sampleRCT, .sampleSystematicReview],
            contraindications: [.sampleWarning],
            approvedAt: nil,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        )
    }

    /// Sample approved review for previews
    static var sampleApproved: ProgramReview {
        ProgramReview(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEFA-234567890123")!,
            programId: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            reviewerId: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            status: .approved,
            aiGenerated: true,
            aiModel: "gpt-4",
            aiConfidenceScore: 92.0,
            reviewNotes: "Program looks excellent. Evidence-based progression aligns with patient's recovery timeline.",
            rejectionReason: nil,
            editsMade: [.sampleEdit],
            evidenceCitations: [.sampleRCT, .sampleSystematicReview, .sampleGuideline],
            contraindications: [],
            approvedAt: Date().addingTimeInterval(-1800),
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-1800)
        )
    }

    /// Sample rejected review for previews
    static var sampleRejected: ProgramReview {
        ProgramReview(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EFAB-345678901234")!,
            programId: UUID(uuidString: "F6A7B8C9-D0E1-2345-FABC-456789012345")!,
            reviewerId: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            status: .rejected,
            aiGenerated: true,
            aiModel: "claude",
            aiConfidenceScore: 45.0,
            reviewNotes: nil,
            rejectionReason: "Progression too aggressive for post-surgical week 4. Need to reduce load parameters.",
            editsMade: [],
            evidenceCitations: [.sampleRCT],
            contraindications: [.sampleCritical, .sampleWarning],
            approvedAt: nil,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-82800)
        )
    }

    /// Sample review queue for previews
    static var sampleQueue: [ProgramReview] {
        [.samplePending, .sampleApproved, .sampleRejected]
    }
}

extension ProgramEdit {
    /// Sample edit for previews
    static var sampleEdit: ProgramEdit {
        ProgramEdit(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            exerciseId: UUID(uuidString: "22222222-3333-4444-5555-666666666666")!,
            fieldChanged: "prescribed_sets",
            oldValue: "4",
            newValue: "3"
        )
    }

    /// Sample reps edit for previews
    static var sampleRepsEdit: ProgramEdit {
        ProgramEdit(
            id: UUID(uuidString: "33333333-4444-5555-6666-777777777777")!,
            exerciseId: UUID(uuidString: "22222222-3333-4444-5555-666666666666")!,
            fieldChanged: "prescribed_reps",
            oldValue: "12",
            newValue: "8"
        )
    }
}

extension ReviewEvidenceCitation {
    /// Sample RCT citation for previews
    static var sampleRCT: ReviewEvidenceCitation {
        ReviewEvidenceCitation(
            id: UUID(uuidString: "AAAA1111-BBBB-CCCC-DDDD-EEEE11111111")!,
            title: "Progressive Resistance Training in Post-ACL Reconstruction: A Randomized Controlled Trial",
            authors: ["Johnson", "Smith", "Williams", "Brown"],
            journal: "Journal of Orthopaedic & Sports Physical Therapy",
            year: 2024,
            doi: "10.2519/jospt.2024.12345",
            relevanceNote: "Supports the progressive loading protocol used in weeks 8-12",
            evidenceLevel: .rct
        )
    }

    /// Sample systematic review citation for previews
    static var sampleSystematicReview: ReviewEvidenceCitation {
        ReviewEvidenceCitation(
            id: UUID(uuidString: "AAAA2222-BBBB-CCCC-DDDD-EEEE22222222")!,
            title: "Eccentric Exercise for Tendinopathy: A Systematic Review and Meta-Analysis",
            authors: ["Garcia", "Chen"],
            journal: "British Journal of Sports Medicine",
            year: 2023,
            doi: "10.1136/bjsports-2023-107890",
            relevanceNote: "Supports eccentric loading approach for patellar tendinopathy rehabilitation",
            evidenceLevel: .systematicReview
        )
    }

    /// Sample clinical guideline citation for previews
    static var sampleGuideline: ReviewEvidenceCitation {
        ReviewEvidenceCitation(
            id: UUID(uuidString: "AAAA3333-BBBB-CCCC-DDDD-EEEE33333333")!,
            title: "APTA Clinical Practice Guideline: Knee Stability and Movement Coordination",
            authors: ["American Physical Therapy Association"],
            journal: nil,
            year: 2025,
            doi: nil,
            relevanceNote: "Guideline-concordant exercise selection for stability training phase",
            evidenceLevel: .clinicalGuideline
        )
    }
}

extension ReviewContraindication {
    /// Sample critical contraindication for previews
    static var sampleCritical: ReviewContraindication {
        ReviewContraindication(
            id: UUID(uuidString: "CCCC1111-DDDD-EEEE-FFFF-000011111111")!,
            type: "Post-Surgical Precaution",
            description: "Patient is 4 weeks post-ACL reconstruction. High-impact plyometrics are contraindicated before week 16.",
            severity: .critical,
            affectedExercises: [UUID(uuidString: "22222222-3333-4444-5555-666666666666")!]
        )
    }

    /// Sample warning contraindication for previews
    static var sampleWarning: ReviewContraindication {
        ReviewContraindication(
            id: UUID(uuidString: "CCCC2222-DDDD-EEEE-FFFF-000022222222")!,
            type: "Load Progression Rate",
            description: "Weekly load increase exceeds 10% recommendation for early-stage rehab patients.",
            severity: .warning,
            affectedExercises: []
        )
    }

    /// Sample info contraindication for previews
    static var sampleInfo: ReviewContraindication {
        ReviewContraindication(
            id: UUID(uuidString: "CCCC3333-DDDD-EEEE-FFFF-000033333333")!,
            type: "Equipment Availability",
            description: "Isokinetic dynamometer exercises may not be available in home setting.",
            severity: .info,
            affectedExercises: []
        )
    }
}
#endif
