//
//  CoachingAlertService.swift
//  PTPerformance
//
//  Service for Exception-Based Coaching system
//  Manages patient alerts, safety rules, and therapist preferences
//

import Foundation
import Supabase

// MARK: - Supporting Data Models

/// Summary of exceptions for a single patient (Service response model)
struct ServicePatientException: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let patientId: UUID
    let firstName: String
    let lastName: String
    let alertCount: Int
    let criticalCount: Int
    let highCount: Int
    let oldestAlertDate: Date?
    let latestAlertDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case alertCount = "alert_count"
        case criticalCount = "critical_count"
        case highCount = "high_count"
        case oldestAlertDate = "oldest_alert_date"
        case latestAlertDate = "latest_alert_date"
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var hasCriticalAlerts: Bool {
        criticalCount > 0
    }
}

/// Summary of exception counts for a therapist's caseload (Service response model)
struct ServiceExceptionSummary: Codable, Equatable, Sendable {
    let totalActiveAlerts: Int
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let patientsNeedingAttention: Int
    let oldestUnresolvedDate: Date?

    enum CodingKeys: String, CodingKey {
        case totalActiveAlerts = "total_active_alerts"
        case criticalCount = "critical_count"
        case highCount = "high_count"
        case mediumCount = "medium_count"
        case lowCount = "low_count"
        case patientsNeedingAttention = "patients_needing_attention"
        case oldestUnresolvedDate = "oldest_unresolved_date"
    }

    /// Returns true if there are any alerts requiring attention
    var hasAlerts: Bool {
        totalActiveAlerts > 0
    }

    /// Returns true if there are critical or high priority alerts
    var hasUrgentAlerts: Bool {
        criticalCount > 0 || highCount > 0
    }

    /// Empty summary with all counts at zero
    static let empty = ServiceExceptionSummary(
        totalActiveAlerts: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        patientsNeedingAttention: 0,
        oldestUnresolvedDate: nil
    )
}

/// A safety rule that triggers alerts when conditions are met (Service response model)
struct ServiceSafetyRule: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let ruleType: String
    let priority: String
    let threshold: Double
    let comparisonOperator: String
    let timeWindowDays: Int?
    let isActive: Bool
    let isSystemRule: Bool
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case ruleType = "rule_type"
        case priority
        case threshold
        case comparisonOperator = "comparison_operator"
        case timeWindowDays = "time_window_days"
        case isActive = "is_active"
        case isSystemRule = "is_system_rule"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Therapist preferences for coaching alerts and notifications (Service response model)
struct ServiceCoachingPreferences: Codable, Equatable, Sendable {
    let id: UUID
    let therapistId: UUID
    let emailNotifications: Bool
    let pushNotifications: Bool
    let criticalAlertSound: Bool
    let dailyDigestEnabled: Bool
    let dailyDigestTime: String?
    let alertPrioritiesEnabled: [String]
    let alertTypesEnabled: [String]
    let autoAcknowledgeHours: Int?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case emailNotifications = "email_notifications"
        case pushNotifications = "push_notifications"
        case criticalAlertSound = "critical_alert_sound"
        case dailyDigestEnabled = "daily_digest_enabled"
        case dailyDigestTime = "daily_digest_time"
        case alertPrioritiesEnabled = "alert_priorities_enabled"
        case alertTypesEnabled = "alert_types_enabled"
        case autoAcknowledgeHours = "auto_acknowledge_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Update Payloads

/// Payload for acknowledging an alert
private struct AcknowledgeAlertPayload: Encodable {
    let acknowledgedAt: String

    enum CodingKeys: String, CodingKey {
        case acknowledgedAt = "acknowledged_at"
    }
}

/// Payload for resolving an alert
private struct ResolveAlertPayload: Encodable {
    let resolvedAt: String
    let resolutionNotes: String?

    enum CodingKeys: String, CodingKey {
        case resolvedAt = "resolved_at"
        case resolutionNotes = "resolution_notes"
    }
}

/// Payload for dismissing an alert
private struct DismissAlertPayload: Encodable {
    let resolvedAt: String
    let dismissedAt: String
    let resolutionNotes: String

    enum CodingKeys: String, CodingKey {
        case resolvedAt = "resolved_at"
        case dismissedAt = "dismissed_at"
        case resolutionNotes = "resolution_notes"
    }
}

/// Payload for updating coaching preferences
private struct UpdatePreferencesPayload: Encodable {
    let emailNotifications: Bool
    let pushNotifications: Bool
    let criticalAlertSound: Bool
    let dailyDigestEnabled: Bool
    let dailyDigestTime: String?
    let alertPrioritiesEnabled: [String]
    let alertTypesEnabled: [String]
    let autoAcknowledgeHours: Int?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case emailNotifications = "email_notifications"
        case pushNotifications = "push_notifications"
        case criticalAlertSound = "critical_alert_sound"
        case dailyDigestEnabled = "daily_digest_enabled"
        case dailyDigestTime = "daily_digest_time"
        case alertPrioritiesEnabled = "alert_priorities_enabled"
        case alertTypesEnabled = "alert_types_enabled"
        case autoAcknowledgeHours = "auto_acknowledge_hours"
        case updatedAt = "updated_at"
    }
}

// MARK: - Coaching Alert Service

/// Service for Exception-Based Coaching alert management.
///
/// Thread-safe actor that handles:
/// - Fetching and filtering coaching alerts
/// - Acknowledging, resolving, and dismissing alerts
/// - Managing safety rules and thresholds
/// - Therapist notification preferences
///
/// ## Usage
/// ```swift
/// // Fetch active alerts for a therapist's patients
/// let alerts = try await CoachingAlertService.shared.fetchActiveAlerts(therapistId: therapistId)
///
/// // Acknowledge an alert
/// let alert = try await CoachingAlertService.shared.acknowledgeAlert(alertId: alertId)
///
/// // Get exception summary counts
/// let summary = try await CoachingAlertService.shared.fetchExceptionSummary(therapistId: therapistId)
/// ```
actor CoachingAlertService {

    // MARK: - Singleton

    static let shared = CoachingAlertService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger: ErrorLogger
    private let debugLogger: DebugLogger

    // MARK: - Constants

    private enum Tables {
        static let coachingAlerts = "coaching_alerts"
        static let safetyRules = "safety_rules"
        static let coachingPreferences = "coaching_preferences"
        static let patientExceptionsView = "vw_patient_exceptions"
        static let exceptionSummaryView = "vw_exception_summary"
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        errorLogger: ErrorLogger = .shared,
        debugLogger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.errorLogger = errorLogger
        self.debugLogger = debugLogger
    }

    // MARK: - Fetch Active Alerts

    /// Fetch all active alerts for a therapist's patients.
    ///
    /// Returns alerts that have not been resolved, sorted by severity
    /// (critical first) then by creation date (newest first).
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of active coaching alerts
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchActiveAlerts(therapistId: UUID) async throws -> [CoachingAlert] {
        debugLogger.log("[CoachingAlertService] Fetching active alerts for therapist: \(therapistId)")

        do {
            let alerts: [CoachingAlert] = try await supabase.client
                .from(Tables.coachingAlerts)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .is("resolved_at", value: nil)
                .order("severity", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Found \(alerts.count) active alerts", level: .success)
            return alerts
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchActiveAlerts(therapist=\(therapistId))")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Patient Alerts

    /// Fetch alerts for a specific patient.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - includeResolved: Whether to include resolved alerts
    /// - Returns: Array of coaching alerts for the patient
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchPatientAlerts(patientId: UUID, includeResolved: Bool = false) async throws -> [CoachingAlert] {
        debugLogger.log("[CoachingAlertService] Fetching alerts for patient: \(patientId), includeResolved: \(includeResolved)")

        do {
            var query = supabase.client
                .from(Tables.coachingAlerts)
                .select()
                .eq("patient_id", value: patientId.uuidString)

            if !includeResolved {
                query = query.is("resolved_at", value: nil)
            }

            let alerts: [CoachingAlert] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Found \(alerts.count) alerts for patient", level: .success)
            return alerts
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchPatientAlerts(patient=\(patientId))")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Acknowledge Alert

    /// Mark an alert as acknowledged.
    ///
    /// Updates the alert with an acknowledged timestamp.
    ///
    /// - Parameter alertId: The alert UUID to acknowledge
    /// - Returns: The updated coaching alert
    /// - Throws: `CoachingAlertError.acknowledgeFailed` if the update fails
    func acknowledgeAlert(alertId: UUID) async throws -> CoachingAlert {
        debugLogger.log("[CoachingAlertService] Acknowledging alert: \(alertId)")

        do {
            let payload = AcknowledgeAlertPayload(
                acknowledgedAt: dateFormatter.string(from: Date())
            )

            let alert: CoachingAlert = try await supabase.client
                .from(Tables.coachingAlerts)
                .update(payload)
                .eq("id", value: alertId.uuidString)
                .select()
                .single()
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Alert acknowledged successfully", level: .success)
            return alert
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.acknowledgeAlert(id=\(alertId))")
            throw CoachingAlertError.acknowledgeFailed(error)
        }
    }

    // MARK: - Resolve Alert

    /// Resolve an alert with optional notes.
    ///
    /// Updates the alert with a resolved timestamp and any resolution notes.
    ///
    /// - Parameters:
    ///   - alertId: The alert UUID to resolve
    ///   - notes: Optional notes about the resolution
    /// - Returns: The updated coaching alert
    /// - Throws: `CoachingAlertError.resolveFailed` if the update fails
    func resolveAlert(alertId: UUID, notes: String? = nil) async throws -> CoachingAlert {
        debugLogger.log("[CoachingAlertService] Resolving alert: \(alertId)")

        do {
            let payload = ResolveAlertPayload(
                resolvedAt: dateFormatter.string(from: Date()),
                resolutionNotes: notes
            )

            let alert: CoachingAlert = try await supabase.client
                .from(Tables.coachingAlerts)
                .update(payload)
                .eq("id", value: alertId.uuidString)
                .select()
                .single()
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Alert resolved successfully", level: .success)
            return alert
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.resolveAlert(id=\(alertId))")
            throw CoachingAlertError.resolveFailed(error)
        }
    }

    // MARK: - Dismiss Alert

    /// Dismiss an alert as a false positive.
    ///
    /// Marks the alert as both resolved and dismissed for future rule tuning.
    ///
    /// - Parameter alertId: The alert UUID to dismiss
    /// - Returns: The updated coaching alert
    /// - Throws: `CoachingAlertError.dismissFailed` if the update fails
    func dismissAlert(alertId: UUID) async throws -> CoachingAlert {
        debugLogger.log("[CoachingAlertService] Dismissing alert: \(alertId)")

        do {
            let now = dateFormatter.string(from: Date())
            let payload = DismissAlertPayload(
                resolvedAt: now,
                dismissedAt: now,
                resolutionNotes: "Dismissed as false positive"
            )

            let alert: CoachingAlert = try await supabase.client
                .from(Tables.coachingAlerts)
                .update(payload)
                .eq("id", value: alertId.uuidString)
                .select()
                .single()
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Alert dismissed successfully", level: .success)
            return alert
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.dismissAlert(id=\(alertId))")
            throw CoachingAlertError.dismissFailed(error)
        }
    }

    // MARK: - Fetch Patient Exceptions

    /// Fetch patients with active exceptions requiring attention.
    ///
    /// Returns patients who have one or more active alerts, sorted by
    /// critical count (highest first) then by alert count.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of patients with active exceptions
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchPatientExceptions(therapistId: UUID) async throws -> [ServicePatientException] {
        debugLogger.log("[CoachingAlertService] Fetching patient exceptions for therapist: \(therapistId)")

        do {
            let exceptions: [ServicePatientException] = try await supabase.client
                .from(Tables.patientExceptionsView)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .gt("alert_count", value: 0)
                .order("critical_count", ascending: false)
                .order("alert_count", ascending: false)
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Found \(exceptions.count) patients with exceptions", level: .success)
            return exceptions
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchPatientExceptions(therapist=\(therapistId))")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Exception Summary

    /// Fetch summary counts of exceptions for a therapist's caseload.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Summary of exception counts by priority
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchExceptionSummary(therapistId: UUID) async throws -> ServiceExceptionSummary {
        debugLogger.log("[CoachingAlertService] Fetching exception summary for therapist: \(therapistId)")

        do {
            let summaries: [ServiceExceptionSummary] = try await supabase.client
                .from(Tables.exceptionSummaryView)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .limit(1)
                .execute()
                .value

            let summary = summaries.first ?? ServiceExceptionSummary.empty

            debugLogger.log("[CoachingAlertService] Exception summary: \(summary.totalActiveAlerts) total, \(summary.criticalCount) critical", level: .success)
            return summary
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchExceptionSummary(therapist=\(therapistId))")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Safety Rules

    /// Fetch active safety rules.
    ///
    /// Returns all active safety rules that can trigger alerts,
    /// including both system-defined and custom rules.
    ///
    /// - Returns: Array of active safety rules
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchSafetyRules() async throws -> [ServiceSafetyRule] {
        debugLogger.log("[CoachingAlertService] Fetching safety rules")

        do {
            let rules: [ServiceSafetyRule] = try await supabase.client
                .from(Tables.safetyRules)
                .select()
                .eq("is_active", value: true)
                .order("is_system_rule", ascending: false)
                .order("priority", ascending: true)
                .order("name", ascending: true)
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Found \(rules.count) active safety rules", level: .success)
            return rules
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchSafetyRules")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Preferences

    /// Fetch coaching alert preferences for a therapist.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: The therapist's coaching preferences, or nil if not configured
    /// - Throws: `CoachingAlertError.fetchFailed` if the database query fails
    func fetchPreferences(therapistId: UUID) async throws -> ServiceCoachingPreferences? {
        debugLogger.log("[CoachingAlertService] Fetching preferences for therapist: \(therapistId)")

        do {
            let preferences: [ServiceCoachingPreferences] = try await supabase.client
                .from(Tables.coachingPreferences)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .limit(1)
                .execute()
                .value

            if preferences.first != nil {
                debugLogger.log("[CoachingAlertService] Preferences loaded successfully", level: .success)
            } else {
                debugLogger.log("[CoachingAlertService] No preferences found, using defaults", level: .info)
            }

            return preferences.first
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.fetchPreferences(therapist=\(therapistId))")
            throw CoachingAlertError.fetchFailed(error)
        }
    }

    // MARK: - Update Preferences

    /// Update coaching alert preferences for a therapist.
    ///
    /// - Parameter preferences: The updated preferences to save
    /// - Returns: The updated coaching preferences
    /// - Throws: `CoachingAlertError.updateFailed` if the update fails
    func updatePreferences(_ preferences: ServiceCoachingPreferences) async throws -> ServiceCoachingPreferences {
        debugLogger.log("[CoachingAlertService] Updating preferences for therapist: \(preferences.therapistId)")

        do {
            let payload = UpdatePreferencesPayload(
                emailNotifications: preferences.emailNotifications,
                pushNotifications: preferences.pushNotifications,
                criticalAlertSound: preferences.criticalAlertSound,
                dailyDigestEnabled: preferences.dailyDigestEnabled,
                dailyDigestTime: preferences.dailyDigestTime,
                alertPrioritiesEnabled: preferences.alertPrioritiesEnabled,
                alertTypesEnabled: preferences.alertTypesEnabled,
                autoAcknowledgeHours: preferences.autoAcknowledgeHours,
                updatedAt: dateFormatter.string(from: Date())
            )

            let updated: ServiceCoachingPreferences = try await supabase.client
                .from(Tables.coachingPreferences)
                .update(payload)
                .eq("id", value: preferences.id.uuidString)
                .select()
                .single()
                .execute()
                .value

            debugLogger.log("[CoachingAlertService] Preferences updated successfully", level: .success)
            return updated
        } catch {
            errorLogger.logError(error, context: "CoachingAlertService.updatePreferences(id=\(preferences.id))")
            throw CoachingAlertError.updateFailed(error)
        }
    }
}

// MARK: - String Convenience Methods

extension CoachingAlertService {
    /// Fetch active alerts for a therapist (String version).
    func fetchActiveAlerts(therapistId: String) async throws -> [CoachingAlert] {
        guard let uuid = UUID(uuidString: therapistId) else {
            throw CoachingAlertError.invalidUUID(therapistId)
        }
        return try await fetchActiveAlerts(therapistId: uuid)
    }

    /// Fetch patient alerts (String version).
    func fetchPatientAlerts(patientId: String, includeResolved: Bool = false) async throws -> [CoachingAlert] {
        guard let uuid = UUID(uuidString: patientId) else {
            throw CoachingAlertError.invalidUUID(patientId)
        }
        return try await fetchPatientAlerts(patientId: uuid, includeResolved: includeResolved)
    }

    /// Acknowledge alert (String version).
    func acknowledgeAlert(alertId: String) async throws -> CoachingAlert {
        guard let uuid = UUID(uuidString: alertId) else {
            throw CoachingAlertError.invalidUUID(alertId)
        }
        return try await acknowledgeAlert(alertId: uuid)
    }

    /// Resolve alert (String version).
    func resolveAlert(alertId: String, notes: String? = nil) async throws -> CoachingAlert {
        guard let uuid = UUID(uuidString: alertId) else {
            throw CoachingAlertError.invalidUUID(alertId)
        }
        return try await resolveAlert(alertId: uuid, notes: notes)
    }

    /// Dismiss alert (String version).
    func dismissAlert(alertId: String) async throws -> CoachingAlert {
        guard let uuid = UUID(uuidString: alertId) else {
            throw CoachingAlertError.invalidUUID(alertId)
        }
        return try await dismissAlert(alertId: uuid)
    }

    /// Fetch patient exceptions (String version).
    func fetchPatientExceptions(therapistId: String) async throws -> [ServicePatientException] {
        guard let uuid = UUID(uuidString: therapistId) else {
            throw CoachingAlertError.invalidUUID(therapistId)
        }
        return try await fetchPatientExceptions(therapistId: uuid)
    }

    /// Fetch exception summary (String version).
    func fetchExceptionSummary(therapistId: String) async throws -> ServiceExceptionSummary {
        guard let uuid = UUID(uuidString: therapistId) else {
            throw CoachingAlertError.invalidUUID(therapistId)
        }
        return try await fetchExceptionSummary(therapistId: uuid)
    }

    /// Fetch preferences (String version).
    func fetchPreferences(therapistId: String) async throws -> ServiceCoachingPreferences? {
        guard let uuid = UUID(uuidString: therapistId) else {
            throw CoachingAlertError.invalidUUID(therapistId)
        }
        return try await fetchPreferences(therapistId: uuid)
    }
}

// MARK: - Coaching Alert Errors

/// Errors specific to coaching alert operations.
/// User-friendly messages that avoid technical jargon.
enum CoachingAlertError: LocalizedError {
    /// Failed to fetch alerts or related data from the database.
    case fetchFailed(Error)
    /// Failed to acknowledge an alert.
    case acknowledgeFailed(Error)
    /// Failed to resolve an alert.
    case resolveFailed(Error)
    /// Failed to dismiss an alert.
    case dismissFailed(Error)
    /// Failed to update preferences.
    case updateFailed(Error)
    /// The requested alert was not found.
    case alertNotFound
    /// User is not authenticated.
    case notAuthenticated
    /// Invalid UUID string provided.
    case invalidUUID(String)

    // MARK: - User-Friendly Error Titles

    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "Couldn't Load Alerts"
        case .acknowledgeFailed: return "Couldn't Acknowledge Alert"
        case .resolveFailed: return "Couldn't Resolve Alert"
        case .dismissFailed: return "Couldn't Dismiss Alert"
        case .updateFailed: return "Couldn't Update Settings"
        case .alertNotFound: return "Alert Not Found"
        case .notAuthenticated: return "Not Signed In"
        case .invalidUUID: return "Invalid Identifier"
        }
    }

    // MARK: - User-Friendly Recovery Suggestions

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "We couldn't load your alerts. Please check your connection and try again."
        case .acknowledgeFailed:
            return "We couldn't mark this alert as acknowledged. Please try again."
        case .resolveFailed:
            return "We couldn't resolve this alert. Please try again."
        case .dismissFailed:
            return "We couldn't dismiss this alert. Please try again."
        case .updateFailed:
            return "We couldn't save your settings. Please try again."
        case .alertNotFound:
            return "This alert may have been removed. Please refresh your alerts."
        case .notAuthenticated:
            return "Please sign in to manage alerts."
        case .invalidUUID:
            return "An internal error occurred. Please try again."
        }
    }

    // MARK: - Retry Logic

    /// Whether the user should be offered a retry option.
    var shouldRetry: Bool {
        switch self {
        case .fetchFailed, .acknowledgeFailed, .resolveFailed, .dismissFailed, .updateFailed:
            return true
        case .alertNotFound, .notAuthenticated, .invalidUUID:
            return false
        }
    }

    /// The underlying error, if any.
    var underlyingError: Error? {
        switch self {
        case .fetchFailed(let error),
             .acknowledgeFailed(let error),
             .resolveFailed(let error),
             .dismissFailed(let error),
             .updateFailed(let error):
            return error
        case .alertNotFound, .notAuthenticated, .invalidUUID:
            return nil
        }
    }
}
