//
//  ApprovalRequestViewModel.swift
//  PTPerformance
//
//  ViewModel for the Therapist Approval Gate system.
//  Manages fetching, approving, and rejecting AI-generated modification requests.
//

import SwiftUI

@MainActor
class ApprovalRequestViewModel: ObservableObject {

    // MARK: - Published State

    /// All approval requests loaded for the current context
    @Published var approvalRequests: [ApprovalRequest] = []

    /// Pending requests that need therapist attention
    @Published var pendingRequests: [ApprovalRequest] = []

    /// Count of pending requests (for badge display)
    @Published var pendingCount: Int = 0

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Whether an approve/reject operation is in progress
    @Published var isProcessing: Bool = false

    /// Success message after an action
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared

    // MARK: - Therapist: Fetch Pending Approvals

    /// Load all pending approval requests for a therapist's patients.
    /// Used on the therapist dashboard to show items requiring review.
    /// - Parameter therapistId: The therapist's ID (from the therapists table)
    func fetchPendingApprovals(therapistId: String) async {
        isLoading = true
        errorMessage = nil

        let logger = DebugLogger.shared
        logger.log("Loading pending approval requests for therapist \(therapistId)")

        do {
            let response = try await supabase.client
                .from("approval_requests")
                .select()
                .eq("therapist_id", value: therapistId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let jsonString = String(data: response.data, encoding: .utf8),
               jsonString != "[]" && !jsonString.isEmpty {
                let decoded = try decoder.decode([ApprovalRequest].self, from: response.data)
                pendingRequests = decoded
                pendingCount = decoded.count
                logger.log("Loaded \(decoded.count) pending approval requests", level: .success)
            } else {
                pendingRequests = []
                pendingCount = 0
                logger.log("No pending approval requests found", level: .diagnostic)
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "ApprovalRequestViewModel.fetchPendingApprovals")
            logger.log("Error loading pending approvals: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load pending approvals. Please try again."
            pendingRequests = []
            pendingCount = 0
        }

        isLoading = false
    }

    // MARK: - Therapist: Fetch All Approvals (with optional filters)

    /// Load all approval requests for a therapist, optionally filtered by status.
    /// - Parameters:
    ///   - therapistId: The therapist's ID
    ///   - statusFilter: Optional status to filter by (nil = all statuses)
    ///   - limit: Maximum number of records to fetch
    func fetchApprovals(therapistId: String, statusFilter: ApprovalStatus? = nil, limit: Int = 50) async {
        isLoading = true
        errorMessage = nil

        let logger = DebugLogger.shared

        do {
            // Apply all filters before transforms (order/limit)
            var filterQuery = supabase.client
                .from("approval_requests")
                .select()
                .eq("therapist_id", value: therapistId)

            if let statusFilter = statusFilter {
                filterQuery = filterQuery.eq("status", value: statusFilter.rawValue)
            }

            let response = try await filterQuery
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let jsonString = String(data: response.data, encoding: .utf8),
               jsonString != "[]" && !jsonString.isEmpty {
                approvalRequests = try decoder.decode([ApprovalRequest].self, from: response.data)
                logger.log("Loaded \(approvalRequests.count) approval requests", level: .success)
            } else {
                approvalRequests = []
            }

            // Update pending count
            pendingCount = approvalRequests.filter { $0.status.isPending }.count
        } catch {
            ErrorLogger.shared.logError(error, context: "ApprovalRequestViewModel.fetchApprovals")
            logger.log("Error loading approvals: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load approval history. Please try again."
            approvalRequests = []
        }

        isLoading = false
    }

    // MARK: - Patient: Fetch Approval Status

    /// Load approval requests for a specific patient (patient-facing view).
    /// - Parameter patientId: The patient's UUID
    func fetchApprovalStatus(patientId: String) async {
        isLoading = true
        errorMessage = nil

        let logger = DebugLogger.shared
        logger.log("Loading approval status for patient \(patientId)")

        do {
            let response = try await supabase.client
                .from("approval_requests")
                .select()
                .eq("patient_id", value: patientId)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let jsonString = String(data: response.data, encoding: .utf8),
               jsonString != "[]" && !jsonString.isEmpty {
                approvalRequests = try decoder.decode([ApprovalRequest].self, from: response.data)
                pendingCount = approvalRequests.filter { $0.status.isPending }.count
                logger.log("Loaded \(approvalRequests.count) approval requests for patient", level: .success)
            } else {
                approvalRequests = []
                pendingCount = 0
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "ApprovalRequestViewModel.fetchApprovalStatus")
            logger.log("Error loading patient approval status: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load modification status. Please try again."
            approvalRequests = []
            pendingCount = 0
        }

        isLoading = false
    }

    // MARK: - Therapist: Approve Request

    /// Approve an approval request with optional therapist notes.
    /// - Parameters:
    ///   - requestId: The approval request UUID
    ///   - therapistUserId: The therapist's auth.users UUID (for reviewed_by)
    ///   - notes: Optional therapist notes explaining the approval
    /// - Returns: Whether the operation succeeded
    @discardableResult
    func approveRequest(requestId: UUID, therapistUserId: String, notes: String? = nil) async -> Bool {
        isProcessing = true
        errorMessage = nil
        successMessage = nil

        let logger = DebugLogger.shared
        logger.log("Approving request \(requestId)")

        do {
            let reviewData = ApprovalReviewRequest(
                status: "approved",
                therapistNotes: notes,
                reviewedAt: ISO8601DateFormatter().string(from: Date()),
                reviewedBy: therapistUserId
            )

            try await supabase.client
                .from("approval_requests")
                .update(reviewData)
                .eq("id", value: requestId.uuidString)
                .execute()

            // Remove from pending list
            pendingRequests.removeAll { $0.id == requestId }
            pendingCount = pendingRequests.count

            // Update in full list if loaded
            if let index = approvalRequests.firstIndex(where: { $0.id == requestId }) {
                // Re-fetch the updated record
                approvalRequests.remove(at: index)
            }

            successMessage = "Modification approved successfully."
            logger.log("Request \(requestId) approved", level: .success)
            isProcessing = false
            return true
        } catch {
            ErrorLogger.shared.logError(error, context: "ApprovalRequestViewModel.approveRequest")
            logger.log("Error approving request: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to approve. Please try again."
            isProcessing = false
            return false
        }
    }

    // MARK: - Therapist: Reject Request

    /// Reject an approval request with required therapist notes.
    /// - Parameters:
    ///   - requestId: The approval request UUID
    ///   - therapistUserId: The therapist's auth.users UUID
    ///   - notes: Therapist notes explaining why the change was rejected
    /// - Returns: Whether the operation succeeded
    @discardableResult
    func rejectRequest(requestId: UUID, therapistUserId: String, notes: String) async -> Bool {
        isProcessing = true
        errorMessage = nil
        successMessage = nil

        let logger = DebugLogger.shared
        logger.log("Rejecting request \(requestId)")

        do {
            let reviewData = ApprovalReviewRequest(
                status: "rejected",
                therapistNotes: notes,
                reviewedAt: ISO8601DateFormatter().string(from: Date()),
                reviewedBy: therapistUserId
            )

            try await supabase.client
                .from("approval_requests")
                .update(reviewData)
                .eq("id", value: requestId.uuidString)
                .execute()

            // Remove from pending list
            pendingRequests.removeAll { $0.id == requestId }
            pendingCount = pendingRequests.count

            // Update in full list if loaded
            if let index = approvalRequests.firstIndex(where: { $0.id == requestId }) {
                approvalRequests.remove(at: index)
            }

            successMessage = "Modification rejected."
            logger.log("Request \(requestId) rejected", level: .success)
            isProcessing = false
            return true
        } catch {
            ErrorLogger.shared.logError(error, context: "ApprovalRequestViewModel.rejectRequest")
            logger.log("Error rejecting request: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to reject. Please try again."
            isProcessing = false
            return false
        }
    }

    // MARK: - Fetch Single Request

    /// Fetch a single approval request by ID (for detail view or status check).
    /// - Parameter requestId: The approval request UUID
    /// - Returns: The approval request, or nil if not found
    func fetchRequest(requestId: UUID) async -> ApprovalRequest? {
        let logger = DebugLogger.shared

        do {
            let response = try await supabase.client
                .from("approval_requests")
                .select()
                .eq("id", value: requestId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let request = try decoder.decode(ApprovalRequest.self, from: response.data)
            return request
        } catch {
            logger.log("Error fetching request \(requestId): \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    // MARK: - Refresh

    /// Refresh pending approvals (for pull-to-refresh)
    /// - Parameter therapistId: The therapist's ID
    func refreshPending(therapistId: String) async {
        await fetchPendingApprovals(therapistId: therapistId)
    }

    // MARK: - Helpers

    /// Clear any displayed error
    func clearError() {
        errorMessage = nil
    }

    /// Clear any displayed success message
    func clearSuccess() {
        successMessage = nil
    }

    /// Get requests filtered by severity
    func requests(bySeverity severity: ApprovalSeverity) -> [ApprovalRequest] {
        pendingRequests.filter { $0.severity == severity }
    }

    /// Get requests filtered by type
    func requests(byType type: ApprovalRequestType) -> [ApprovalRequest] {
        pendingRequests.filter { $0.requestType == type }
    }

    /// Whether there are critical pending requests that need immediate attention
    var hasCriticalPending: Bool {
        pendingRequests.contains { $0.severity == .critical }
    }

    /// Number of critical pending requests
    var criticalPendingCount: Int {
        pendingRequests.filter { $0.severity == .critical }.count
    }
}

// MARK: - Preview Support

extension ApprovalRequestViewModel {
    /// Preview instance with mock pending requests
    static var preview: ApprovalRequestViewModel {
        let vm = ApprovalRequestViewModel()
        vm.pendingRequests = ApprovalRequest.mockPendingRequests
        vm.pendingCount = ApprovalRequest.mockPendingRequests.count
        vm.approvalRequests = ApprovalRequest.mockPendingRequests
        return vm
    }

    /// Preview instance with empty state
    static var emptyPreview: ApprovalRequestViewModel {
        let vm = ApprovalRequestViewModel()
        vm.pendingRequests = []
        vm.pendingCount = 0
        return vm
    }

    /// Preview instance in loading state
    static var loadingPreview: ApprovalRequestViewModel {
        let vm = ApprovalRequestViewModel()
        vm.isLoading = true
        return vm
    }
}
