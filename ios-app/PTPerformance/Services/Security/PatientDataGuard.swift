//
//  PatientDataGuard.swift
//  PTPerformance
//
//  ACP-1060: Patient Data Compartmentalization - Client-side enforcement
//  Ensures API queries always include the patient ID filter and validates
//  that the current user's patient ID matches the data being requested.
//

import Foundation

// MARK: - Patient Data Guard

/// Client-side helper for patient data compartmentalization.
///
/// Validates that all data access is properly scoped to the current user's patient ID.
/// This complements the server-side Supabase RLS (Row Level Security) policies by
/// providing an early check before network requests are made.
///
/// ## Usage
/// ```swift
/// // Before making a Supabase query:
/// let patientId = try PatientDataGuard.shared.validatedPatientId()
///
/// // Or validate an incoming patient ID:
/// try PatientDataGuard.shared.validateAccess(toPatientId: someId)
/// ```
final class PatientDataGuard {

    // MARK: - Singleton

    static let shared = PatientDataGuard()

    // MARK: - Dependencies

    private let logger = DebugLogger.shared
    private let accessControl = AccessControlService.shared

    /// Cached ISO8601 formatter to avoid repeated allocation in security logging
    private static let iso8601Formatter = ISO8601DateFormatter()

    // MARK: - Initialization

    private init() {}

    // MARK: - Validation Methods

    /// Returns the current user's validated patient ID for use in API queries.
    ///
    /// This method ensures that every query includes a proper patient_id filter.
    /// Call this before constructing Supabase queries to guarantee the filter is present.
    ///
    /// - Returns: The current user's patient ID string.
    /// - Throws: `PatientDataError.noPatientId` if user is not authenticated or has no ID.
    func validatedPatientId() throws -> String {
        guard let patientId = PTSupabaseClient.shared.userId else {
            logger.log("[PatientDataGuard] No patient ID available - user may not be authenticated", level: .error)
            throw PatientDataError.noPatientId
        }
        return patientId
    }

    /// Validates that the current user is allowed to access data for the given patient ID.
    ///
    /// For patients: checks that the requested ID matches their own ID.
    /// For therapists/admins: permits access (server-side RLS enforces linking).
    /// Logs any unauthorized access attempts for security auditing.
    ///
    /// - Parameter patientId: The patient ID being accessed.
    /// - Throws: `PatientDataError.accessDenied` if the user cannot access this patient's data.
    func validateAccess(toPatientId patientId: String) throws {
        guard accessControl.validatePatientIdMatchesCurrentUser(patientId: patientId) else {
            let currentId = PTSupabaseClient.shared.userId ?? "unknown"
            let role = accessControl.currentRole?.rawValue ?? "unknown"

            // Log the unauthorized access attempt
            logUnauthorizedAccessAttempt(
                requestedPatientId: patientId,
                currentUserId: currentId,
                userRole: role
            )

            throw PatientDataError.accessDenied(
                requestedPatientId: patientId,
                currentUserId: currentId
            )
        }
    }

    /// Validates a patient ID and returns it if access is allowed.
    /// Convenience method that combines ID extraction and validation.
    ///
    /// - Parameter requestedPatientId: The patient ID to validate. If nil, uses the current user's ID.
    /// - Returns: The validated patient ID.
    /// - Throws: `PatientDataError` if validation fails.
    func validatedId(for requestedPatientId: String? = nil) throws -> String {
        if let requestedId = requestedPatientId {
            try validateAccess(toPatientId: requestedId)
            return requestedId
        } else {
            return try validatedPatientId()
        }
    }

    // MARK: - Audit Logging

    /// Logs an unauthorized access attempt for security auditing.
    ///
    /// These logs are important for detecting potential data access violations.
    /// In production, these would also be sent to the server for review.
    private func logUnauthorizedAccessAttempt(
        requestedPatientId: String,
        currentUserId: String,
        userRole: String
    ) {
        let message = "[PatientDataGuard] SECURITY: Unauthorized data access attempt - " +
            "requested_patient_id=\(requestedPatientId), " +
            "current_user_id=\(currentUserId), " +
            "user_role=\(userRole), " +
            "timestamp=\(Self.iso8601Formatter.string(from: Date()))"

        logger.log(message, level: .error)

        // Also log to ErrorLogger for production monitoring
        ErrorLogger.shared.logError(
            PatientDataError.accessDenied(
                requestedPatientId: requestedPatientId,
                currentUserId: currentUserId
            ),
            context: "PatientDataGuard.unauthorizedAccess",
            metadata: [
                "requested_patient_id": requestedPatientId,
                "current_user_id": currentUserId,
                "user_role": userRole
            ]
        )
    }
}

// MARK: - Patient Data Errors

enum PatientDataError: LocalizedError {
    case noPatientId
    case accessDenied(requestedPatientId: String, currentUserId: String)
    case invalidPatientId

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "No patient ID available. Please sign in to access your data."
        case .accessDenied(let requested, let current):
            return "Access denied: Cannot access data for patient \(requested). Your user ID is \(current)."
        case .invalidPatientId:
            return "The patient ID provided is not valid."
        }
    }
}
