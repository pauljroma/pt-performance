//
//  ProgramReviewService.swift
//  PTPerformance
//
//  ACP-395: PT Review and Approval Workflow
//  Service for managing the program review lifecycle where therapists
//  review AI-generated programs, track edits, add evidence citations,
//  and approve or reject programs before patient deployment.
//

import Foundation
import Supabase

// MARK: - Encodable Structs for Supabase Operations

/// Input for creating a new program review
private struct ProgramReviewInsert: Encodable {
    let programId: UUID
    let reviewerId: UUID
    let status: String
    let aiGenerated: Bool
    let aiModel: String?
    let aiConfidenceScore: Double?
    let evidenceCitations: [ReviewEvidenceCitation]
    let contraindications: [ReviewContraindication]

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case reviewerId = "reviewer_id"
        case status
        case aiGenerated = "ai_generated"
        case aiModel = "ai_model"
        case aiConfidenceScore = "ai_confidence_score"
        case evidenceCitations = "evidence_citations"
        case contraindications
    }
}

/// Update for review status transitions
private struct ReviewStatusUpdate: Encodable {
    let status: String

    enum CodingKeys: String, CodingKey {
        case status
    }
}

/// Update for program review_status column
private struct ProgramReviewStatusUpdate: Encodable {
    let reviewStatus: String

    enum CodingKeys: String, CodingKey {
        case reviewStatus = "review_status"
    }
}

/// Update for adding review notes
private struct ReviewNotesUpdate: Encodable {
    let reviewNotes: String

    enum CodingKeys: String, CodingKey {
        case reviewNotes = "review_notes"
    }
}

/// Update for adding edits to a review
private struct ReviewEditsUpdate: Encodable {
    let editsMade: [ProgramEdit]

    enum CodingKeys: String, CodingKey {
        case editsMade = "edits_made"
    }
}

/// Update for approving a program
private struct ReviewApprovalUpdate: Encodable {
    let status: String
    let reviewNotes: String?
    let approvedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case reviewNotes = "review_notes"
        case approvedAt = "approved_at"
    }
}

/// Update for rejecting a program
private struct ReviewRejectionUpdate: Encodable {
    let status: String
    let rejectionReason: String

    enum CodingKeys: String, CodingKey {
        case status
        case rejectionReason = "rejection_reason"
    }
}

/// Update for requesting revision
private struct ReviewRevisionUpdate: Encodable {
    let status: String
    let reviewNotes: String

    enum CodingKeys: String, CodingKey {
        case status
        case reviewNotes = "review_notes"
    }
}

// MARK: - Errors

/// Errors specific to program review service operations
enum ProgramReviewServiceError: LocalizedError {
    case reviewNotFound
    case programNotFound
    case invalidStatusTransition(from: String, to: String)
    case createFailed(Error)
    case updateFailed(Error)
    case fetchFailed(Error)
    case approvalFailed(Error)
    case rejectionFailed(Error)
    case alreadyApproved
    case alreadyRejected

    var errorDescription: String? {
        switch self {
        case .reviewNotFound:
            return "Review not found"
        case .programNotFound:
            return "Program not found"
        case .invalidStatusTransition(let from, let to):
            return "Cannot transition review from '\(from)' to '\(to)'"
        case .createFailed(let error):
            return "Failed to create review: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update review: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch reviews: \(error.localizedDescription)"
        case .approvalFailed(let error):
            return "Failed to approve program: \(error.localizedDescription)"
        case .rejectionFailed(let error):
            return "Failed to reject program: \(error.localizedDescription)"
        case .alreadyApproved:
            return "This program has already been approved"
        case .alreadyRejected:
            return "This program has already been rejected"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .reviewNotFound:
            return "This review may have been deleted. Return to the review queue and refresh."
        case .programNotFound:
            return "This program may have been deleted. Return to the program list."
        case .invalidStatusTransition:
            return "Refresh the review to see its current status and try again."
        case .createFailed, .updateFailed, .fetchFailed, .approvalFailed, .rejectionFailed:
            return "Please check your connection and try again."
        case .alreadyApproved:
            return "This program is already approved and deployed. No further action needed."
        case .alreadyRejected:
            return "This program has been rejected. Create a new review to reconsider."
        }
    }
}

// MARK: - Service

/// Service for therapists to review and approve AI-generated programs
@MainActor
class ProgramReviewService: ObservableObject {
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Published State

    @Published private(set) var reviewQueue: [ProgramReview] = []
    @Published private(set) var currentReview: ProgramReview?
    @Published private(set) var isLoading = false
    @Published private(set) var error: ProgramReviewServiceError?

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Submit for Review

    /// Submit a program for PT review. Creates a review record and updates the program's review status.
    /// - Parameters:
    ///   - programId: The program to submit for review
    ///   - reviewerId: The therapist who will review the program
    ///   - aiGenerated: Whether the program was AI-generated
    ///   - aiModel: Which AI model generated it (e.g., "claude", "gpt-4")
    ///   - aiConfidenceScore: AI confidence score (0-100)
    ///   - citations: Evidence citations supporting the program
    ///   - contraindications: Safety concerns flagged during generation
    /// - Returns: The created ProgramReview
    func submitForReview(
        programId: UUID,
        reviewerId: UUID,
        aiGenerated: Bool = true,
        aiModel: String? = nil,
        aiConfidenceScore: Double? = nil,
        citations: [ReviewEvidenceCitation] = [],
        contraindications: [ReviewContraindication] = []
    ) async throws -> ProgramReview {
        logger.log("Submitting program \(programId) for review by \(reviewerId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        let insert = ProgramReviewInsert(
            programId: programId,
            reviewerId: reviewerId,
            status: ReviewStatus.pendingReview.rawValue,
            aiGenerated: aiGenerated,
            aiModel: aiModel,
            aiConfidenceScore: aiConfidenceScore,
            evidenceCitations: citations,
            contraindications: contraindications
        )

        do {
            // Create the review record
            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value

            // Update program's review_status
            try await supabase.client
                .from("programs")
                .update(ProgramReviewStatusUpdate(reviewStatus: ProgramReviewStatus.pendingReview.rawValue))
                .eq("id", value: programId.uuidString)
                .execute()

            logger.log("Created review \(review.id) for program \(programId)", level: .success)
            currentReview = review
            return review
        } catch {
            let serviceError = ProgramReviewServiceError.createFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.submitForReview")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Fetch Review Queue

    /// Fetch the review queue for a therapist (pending and in-review items).
    /// - Parameter therapistId: The therapist whose queue to fetch
    /// - Returns: Array of ProgramReviews sorted by creation date (newest first)
    func fetchReviewQueue(therapistId: UUID) async throws -> [ProgramReview] {
        logger.log("Fetching review queue for therapist \(therapistId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let reviews: [ProgramReview] = try await supabase.client
                .from("program_reviews")
                .select()
                .eq("reviewer_id", value: therapistId.uuidString)
                .in("status", values: [
                    ReviewStatus.pendingReview.rawValue,
                    ReviewStatus.inReview.rawValue,
                    ReviewStatus.revisionRequested.rawValue
                ])
                .order("created_at", ascending: false)
                .execute()
                .value

            logger.log("Fetched \(reviews.count) reviews in queue", level: .success)
            reviewQueue = reviews
            return reviews
        } catch {
            let serviceError = ProgramReviewServiceError.fetchFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.fetchReviewQueue")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Start Review

    /// Mark a review as in-progress. Transitions from pending_review to in_review.
    /// - Parameter reviewId: The review to start
    func startReview(reviewId: UUID) async throws {
        logger.log("Starting review \(reviewId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let update = ReviewStatusUpdate(status: ReviewStatus.inReview.rawValue)

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            // Also update the program's review_status
            try await supabase.client
                .from("programs")
                .update(ProgramReviewStatusUpdate(reviewStatus: ProgramReviewStatus.inReview.rawValue))
                .eq("id", value: review.programId.uuidString)
                .execute()

            logger.log("Started review \(reviewId)", level: .success)
            currentReview = review

            // Update the queue to reflect the status change
            if let index = reviewQueue.firstIndex(where: { $0.id == reviewId }) {
                reviewQueue[index] = review
            }
        } catch {
            let serviceError = ProgramReviewServiceError.updateFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.startReview")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Add Edit

    /// Track a PT edit to the program under review.
    /// Appends the edit to the review's edits_made JSONB array.
    /// - Parameters:
    ///   - reviewId: The review being edited
    ///   - edit: The edit to record
    func addEdit(reviewId: UUID, edit: ProgramEdit) async throws {
        logger.log("Adding edit to review \(reviewId): \(edit.fieldChanged)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Fetch current edits
            let current: ProgramReview = try await supabase.client
                .from("program_reviews")
                .select()
                .eq("id", value: reviewId.uuidString)
                .single()
                .execute()
                .value

            // Append the new edit
            var updatedEdits = current.editsMade
            updatedEdits.append(edit)

            let update = ReviewEditsUpdate(editsMade: updatedEdits)

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            logger.log("Added edit to review \(reviewId), total edits: \(review.editCount)", level: .success)
            currentReview = review
        } catch {
            let serviceError = ProgramReviewServiceError.updateFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.addEdit")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Add Note

    /// Add or update review notes for a review.
    /// - Parameters:
    ///   - reviewId: The review to annotate
    ///   - note: The review notes text
    func addNote(reviewId: UUID, note: String) async throws {
        logger.log("Adding note to review \(reviewId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let update = ReviewNotesUpdate(reviewNotes: note)

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            logger.log("Added note to review \(reviewId)", level: .success)
            currentReview = review
        } catch {
            let serviceError = ProgramReviewServiceError.updateFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.addNote")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Approve Program

    /// Approve a program and mark it for deployment. Sets approved_at timestamp
    /// and updates both the review and program statuses.
    /// - Parameters:
    ///   - reviewId: The review to approve
    ///   - notes: Optional approval notes from the PT
    func approveProgram(reviewId: UUID, notes: String? = nil) async throws {
        logger.log("Approving review \(reviewId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let update = ReviewApprovalUpdate(
                status: ReviewStatus.approved.rawValue,
                reviewNotes: notes,
                approvedAt: formatter.string(from: Date())
            )

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            // Update program review_status to approved
            try await supabase.client
                .from("programs")
                .update(ProgramReviewStatusUpdate(reviewStatus: ProgramReviewStatus.approved.rawValue))
                .eq("id", value: review.programId.uuidString)
                .execute()

            logger.log("Approved review \(reviewId) for program \(review.programId)", level: .success)
            currentReview = review

            // Remove from queue
            reviewQueue.removeAll { $0.id == reviewId }
        } catch {
            let serviceError = ProgramReviewServiceError.approvalFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.approveProgram")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Reject Program

    /// Reject a program with a reason. The program will not be deployed.
    /// - Parameters:
    ///   - reviewId: The review to reject
    ///   - reason: Required reason for rejection
    func rejectProgram(reviewId: UUID, reason: String) async throws {
        logger.log("Rejecting review \(reviewId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let update = ReviewRejectionUpdate(
                status: ReviewStatus.rejected.rawValue,
                rejectionReason: reason
            )

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            // Update program review_status to rejected
            try await supabase.client
                .from("programs")
                .update(ProgramReviewStatusUpdate(reviewStatus: ProgramReviewStatus.rejected.rawValue))
                .eq("id", value: review.programId.uuidString)
                .execute()

            logger.log("Rejected review \(reviewId) for program \(review.programId)", level: .success)
            currentReview = review

            // Remove from queue
            reviewQueue.removeAll { $0.id == reviewId }
        } catch {
            let serviceError = ProgramReviewServiceError.rejectionFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.rejectProgram")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Request Revision

    /// Request revision of a program. The program stays in review but is flagged
    /// for changes. Useful when the PT wants AI to regenerate certain parts.
    /// - Parameters:
    ///   - reviewId: The review to request revision on
    ///   - notes: Notes describing what revisions are needed
    func requestRevision(reviewId: UUID, notes: String) async throws {
        logger.log("Requesting revision for review \(reviewId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let update = ReviewRevisionUpdate(
                status: ReviewStatus.revisionRequested.rawValue,
                reviewNotes: notes
            )

            let review: ProgramReview = try await supabase.client
                .from("program_reviews")
                .update(update)
                .eq("id", value: reviewId.uuidString)
                .select()
                .single()
                .execute()
                .value

            logger.log("Requested revision for review \(reviewId)", level: .success)
            currentReview = review

            // Update in queue
            if let index = reviewQueue.firstIndex(where: { $0.id == reviewId }) {
                reviewQueue[index] = review
            }
        } catch {
            let serviceError = ProgramReviewServiceError.updateFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.requestRevision")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Fetch Review History

    /// Fetch the full review history for a program (audit trail).
    /// Returns all reviews regardless of status, ordered by creation date.
    /// - Parameter programId: The program to fetch history for
    /// - Returns: Array of all ProgramReviews for this program
    func fetchReviewHistory(programId: UUID) async throws -> [ProgramReview] {
        logger.log("Fetching review history for program \(programId)", level: .diagnostic)
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let reviews: [ProgramReview] = try await supabase.client
                .from("program_reviews")
                .select()
                .eq("program_id", value: programId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            logger.log("Fetched \(reviews.count) reviews for program \(programId)", level: .success)
            return reviews
        } catch {
            let serviceError = ProgramReviewServiceError.fetchFailed(error)
            errorLogger.logError(error, context: "ProgramReviewService.fetchReviewHistory")
            self.error = serviceError
            throw serviceError
        }
    }

    // MARK: - Helpers

    /// Clear the current error state
    func clearError() {
        error = nil
    }

    /// Set the current review being viewed/edited
    func setCurrentReview(_ review: ProgramReview?) {
        currentReview = review
    }
}
