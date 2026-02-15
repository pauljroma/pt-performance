//
//  AccessControlService.swift
//  PTPerformance
//
//  ACP-1059: Client-side Role-Based Access Control (RBAC)
//  Provides permission checks based on user role (patient, therapist, admin)
//

import Foundation

// MARK: - App Role

/// Extended role type that includes admin for future use.
/// Maps from the existing UserRole enum used in authentication.
enum AppRole: String {
    case patient
    case therapist
    case admin
}

// MARK: - Access Control Error

enum AccessControlError: LocalizedError {
    case unauthorized(String)
    case roleNotSet
    case patientIdMismatch(requested: String, actual: String)

    var errorDescription: String? {
        switch self {
        case .unauthorized(let reason):
            return "Access denied: \(reason)"
        case .roleNotSet:
            return "User role has not been determined. Please sign in again."
        case .patientIdMismatch(let requested, let actual):
            return "Cannot access data for patient \(requested). Your patient ID is \(actual)."
        }
    }
}

// MARK: - Access Control Service

/// Singleton service for client-side role-based access control.
///
/// Checks the current user's role and permissions before allowing access
/// to sensitive data or features. This is a client-side enforcement layer;
/// the server-side Supabase RLS policies provide the authoritative control.
///
/// ## Usage
/// ```swift
/// let acl = AccessControlService.shared
///
/// if acl.canModifyExercise() {
///     // Allow exercise modification
/// }
///
/// // Throws if unauthorized
/// try acl.requireAccess(toPatientData: somePatientId)
/// ```
final class AccessControlService {

    // MARK: - Singleton

    static let shared = AccessControlService()

    // MARK: - Dependencies

    private let logger = DebugLogger.shared
    private let supabaseClient = PTSupabaseClient.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Current User Info

    /// The current user's app role, derived from the existing UserRole.
    var currentRole: AppRole? {
        guard let userRole = supabaseClient.userRole else { return nil }
        switch userRole {
        case .patient: return .patient
        case .therapist: return .therapist
        }
    }

    /// The current user's ID from the Supabase client.
    var currentUserId: String? {
        return supabaseClient.userId
    }

    // MARK: - Permission Checks

    /// Check if the current user can access a specific patient's data.
    ///
    /// - Patients can only access their own data.
    /// - Therapists can access data for patients linked to them (server enforces the link).
    /// - Admins can access any patient data.
    ///
    /// - Parameter patientId: The patient ID whose data is being accessed.
    /// - Returns: `true` if access is allowed.
    func canAccessPatientData(patientId: String) -> Bool {
        guard let role = currentRole else {
            logger.log("[AccessControl] Role not set, denying patient data access", level: .warning)
            return false
        }

        switch role {
        case .patient:
            // Patients can only access their own data
            let allowed = currentUserId == patientId
            if !allowed {
                logger.log("[AccessControl] Patient \(currentUserId ?? "nil") attempted to access data for patient \(patientId)", level: .warning)
            }
            return allowed

        case .therapist:
            // Therapists can access linked patients' data
            // The actual link validation is enforced server-side by RLS
            // Client-side, we permit the request and let the server decide
            logger.log("[AccessControl] Therapist \(currentUserId ?? "nil") accessing patient \(patientId) data", level: .diagnostic)
            return true

        case .admin:
            logger.log("[AccessControl] Admin accessing patient \(patientId) data", level: .diagnostic)
            return true
        }
    }

    /// Check if the current user can modify exercises (create, edit, delete).
    ///
    /// - Therapists and admins can modify exercises.
    /// - Patients cannot modify exercise definitions (they can only log performance).
    ///
    /// - Returns: `true` if the user can modify exercises.
    func canModifyExercise() -> Bool {
        guard let role = currentRole else {
            logger.log("[AccessControl] Role not set, denying exercise modification", level: .warning)
            return false
        }

        switch role {
        case .therapist, .admin:
            return true
        case .patient:
            return false
        }
    }

    /// Check if the current user can view analytics dashboards.
    ///
    /// - Therapists and admins can view aggregate analytics.
    /// - Patients can view their own analytics only.
    ///
    /// - Returns: `true` if the user can view analytics.
    func canViewAnalytics() -> Bool {
        guard let role = currentRole else {
            logger.log("[AccessControl] Role not set, denying analytics access", level: .warning)
            return false
        }

        // All authenticated roles can view analytics (scoped by role server-side)
        switch role {
        case .patient, .therapist, .admin:
            return true
        }
    }

    /// Check if the current user can manage other users (therapist-patient linking, etc.).
    ///
    /// - Returns: `true` if the user has management permissions.
    func canManageUsers() -> Bool {
        guard let role = currentRole else { return false }

        switch role {
        case .therapist, .admin:
            return true
        case .patient:
            return false
        }
    }

    // MARK: - Throwing Accessors

    /// Require that the current user can access a specific patient's data.
    /// Throws `AccessControlError` if unauthorized.
    ///
    /// - Parameter patientId: The patient ID whose data is being accessed.
    /// - Throws: `AccessControlError.unauthorized` or `.roleNotSet`
    func requireAccess(toPatientData patientId: String) throws {
        guard currentRole != nil else {
            throw AccessControlError.roleNotSet
        }

        guard canAccessPatientData(patientId: patientId) else {
            let errorMsg = "User \(currentUserId ?? "unknown") (role: \(currentRole?.rawValue ?? "none")) cannot access patient \(patientId)"
            logger.log("[AccessControl] \(errorMsg)", level: .error)
            throw AccessControlError.unauthorized(errorMsg)
        }
    }

    /// Require that the current user can modify exercises.
    /// Throws `AccessControlError` if unauthorized.
    ///
    /// - Throws: `AccessControlError.unauthorized` or `.roleNotSet`
    func requireExerciseModification() throws {
        guard currentRole != nil else {
            throw AccessControlError.roleNotSet
        }

        guard canModifyExercise() else {
            let errorMsg = "User role \(currentRole?.rawValue ?? "none") cannot modify exercises"
            logger.log("[AccessControl] \(errorMsg)", level: .warning)
            throw AccessControlError.unauthorized(errorMsg)
        }
    }

    /// Validates that the given patient ID matches the current user's patient ID.
    /// Used to ensure patient data compartmentalization on the client side.
    ///
    /// - Parameter patientId: The patient ID to validate.
    /// - Returns: `true` if the ID matches or user is therapist/admin.
    func validatePatientIdMatchesCurrentUser(patientId: String) -> Bool {
        guard let role = currentRole else { return false }

        switch role {
        case .patient:
            let matches = currentUserId == patientId
            if !matches {
                logger.log("[AccessControl] Patient ID mismatch: requested=\(patientId) actual=\(currentUserId ?? "nil")", level: .error)
            }
            return matches

        case .therapist, .admin:
            // Non-patients can access other patients' data (server-side RLS enforces linking)
            return true
        }
    }
}
