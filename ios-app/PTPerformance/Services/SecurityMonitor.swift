//
//  SecurityMonitor.swift
//  PTPerformance
//
//  Purpose: Failed login tracking, security alerts, and real-time anomaly detection
//  ACP-1056: Security Event Monitoring
//

import SwiftUI
#if canImport(Sentry)
import Sentry
#endif

// MARK: - Security Alert Model

/// A security alert raised by the monitoring system
struct SecurityAlert: Identifiable {
    let id: UUID
    let severity: SecurityAlertSeverity
    let message: String
    let timestamp: Date
    var acknowledged: Bool

    init(severity: SecurityAlertSeverity, message: String) {
        self.id = UUID()
        self.severity = severity
        self.message = message
        self.timestamp = Date()
        self.acknowledged = false
    }
}

/// Severity levels for security alerts
enum SecurityAlertSeverity: String, CaseIterable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    private var order: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    static func < (lhs: SecurityAlertSeverity, rhs: SecurityAlertSeverity) -> Bool {
        lhs.order < rhs.order
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    var icon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

// MARK: - SecurityMonitor

/// Monitors security events, failed login attempts, API rate limiting,
/// and unusual data access patterns in real time.
///
/// ACP-1056: Provides real-time security monitoring with anomaly detection
/// and integration with Sentry for incident response.
@MainActor
final class SecurityMonitor: ObservableObject {

    // MARK: - Static Formatters

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    // MARK: - Properties

    static let shared = SecurityMonitor()

    /// Active security alerts (newest first)
    @Published var securityAlerts: [SecurityAlert] = []

    /// Whether anomaly checking is active
    @Published var isMonitoring: Bool = false

    /// Maximum failed login attempts before lockout
    private let maxFailedAttempts = 5

    /// Window for counting failed login attempts (15 minutes)
    private let failedLoginWindow: TimeInterval = 15 * 60

    /// Lockout duration in seconds
    private let lockoutDuration: TimeInterval = 30 * 60 // 30 minutes

    /// API rate limit: max calls per minute per endpoint
    private let apiRateLimitPerMinute = 60

    /// Threshold for bulk data access detection (records in 5 minutes)
    private let bulkAccessThreshold = 100

    /// Failed login attempts cache (email -> [timestamps])
    private var failedAttempts: [String: [Date]] = [:]

    /// Account lockouts cache (email -> lockout expiry)
    private var accountLockouts: [String: Date] = [:]

    /// API call tracking (endpoint -> [timestamps])
    private var apiCallLog: [String: [Date]] = [:]

    /// Data access tracking for anomaly detection (resource -> [timestamps])
    private var dataAccessLog: [String: [Date]] = [:]

    /// Typical access hours for the current user (hour of day -> access count)
    private var accessHourProfile: [Int: Int] = [:]

    /// Maximum alerts to retain in memory
    private let maxAlerts = 200

    // MARK: - Public Methods

    /// Start real-time security monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Run periodic anomaly checks
        Task {
            while isMonitoring && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Every 60 seconds
                checkAnomalies()
                cleanupExpiredData()
            }
        }

        DebugLogger.shared.info("SecurityMonitor", "Real-time security monitoring started")

        // Log to audit trail
        Task {
            await AuditLogger.shared.logSecurityEvent(
                event: "monitoring_started",
                details: "Real-time security monitoring activated"
            )
        }
    }

    /// Stop real-time security monitoring
    func stopMonitoring() {
        isMonitoring = false
        DebugLogger.shared.info("SecurityMonitor", "Real-time security monitoring stopped")
    }

    /// Check if account is currently locked
    func isAccountLocked(email: String) -> Bool {
        guard let lockoutExpiry = accountLockouts[email] else {
            return false
        }

        // Check if lockout has expired
        if Date() > lockoutExpiry {
            // Lockout expired, remove from cache
            accountLockouts.removeValue(forKey: email)
            failedAttempts.removeValue(forKey: email)
            return false
        }

        return true
    }

    /// Get remaining lockout time in seconds
    func getRemainingLockoutTime(email: String) -> TimeInterval {
        guard let lockoutExpiry = accountLockouts[email] else {
            return 0
        }

        let remaining = lockoutExpiry.timeIntervalSinceNow
        return max(0, remaining)
    }

    /// Record failed login attempt
    func recordFailedLogin(email: String) async {
        let now = Date()

        // Add failed attempt
        if failedAttempts[email] == nil {
            failedAttempts[email] = []
        }
        failedAttempts[email]?.append(now)

        // Clean up old attempts
        cleanupOldAttempts(email: email)

        // Check if should lock account (5 attempts in 15 minutes)
        let recentAttempts = failedAttempts[email]?.filter { attempt in
            now.timeIntervalSince(attempt) < failedLoginWindow
        } ?? []

        if recentAttempts.count >= maxFailedAttempts {
            await lockAccount(email: email, reason: "Too many failed login attempts (\(recentAttempts.count) in \(Int(failedLoginWindow / 60)) minutes)")
        } else if recentAttempts.count >= 3 {
            // Warn at 3 attempts
            addAlert(SecurityAlert(
                severity: .medium,
                message: "Multiple failed login attempts for account (\(recentAttempts.count)/\(maxFailedAttempts))"
            ))
        }

        // Log to audit trail
        await AuditLogger.shared.logSecurityEvent(
            event: "failed_login",
            details: "attempt_count=\(recentAttempts.count)"
        )

        // Log to database
        await logFailedAttempt(email: email)
    }

    /// Record successful login (clears failed attempts)
    func recordSuccessfulLogin(email: String) {
        failedAttempts.removeValue(forKey: email)
        accountLockouts.removeValue(forKey: email)

        // Update access hour profile
        let hour = Calendar.current.component(.hour, from: Date())
        accessHourProfile[hour, default: 0] += 1

        // Log to audit trail
        Task {
            await AuditLogger.shared.logAuthentication(
                action: "login",
                success: true,
                details: "email_auth"
            )
        }
    }

    /// Manually unlock account (admin function)
    func unlockAccount(email: String) {
        accountLockouts.removeValue(forKey: email)
        failedAttempts.removeValue(forKey: email)
        DebugLogger.shared.info("SecurityMonitor", "Account unlocked: \(email)")

        Task {
            await AuditLogger.shared.logSecurityEvent(
                event: "account_unlocked",
                details: "manual_unlock"
            )
        }
    }

    // MARK: - API Rate Limiting (ACP-1056)

    /// Record an API call for rate limiting detection.
    ///
    /// - Parameter endpoint: The API endpoint being called
    /// - Returns: True if the call is allowed, false if rate limited
    @discardableResult
    func recordAPICall(endpoint: String) -> Bool {
        let now = Date()

        if apiCallLog[endpoint] == nil {
            apiCallLog[endpoint] = []
        }
        apiCallLog[endpoint]?.append(now)

        // Count calls in the last minute
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let recentCalls = apiCallLog[endpoint]?.filter { $0 > oneMinuteAgo } ?? []

        if recentCalls.count > apiRateLimitPerMinute {
            addAlert(SecurityAlert(
                severity: .high,
                message: "API rate limit exceeded for endpoint: \(endpoint) (\(recentCalls.count) calls/min)"
            ))

            Task {
                await AuditLogger.shared.logSecurityEvent(
                    event: "rate_limit_exceeded",
                    details: "endpoint=\(endpoint); calls=\(recentCalls.count)"
                )
            }

            return false
        }

        return true
    }

    // MARK: - Data Access Tracking (ACP-1056)

    /// Record a data access event for anomaly detection.
    ///
    /// - Parameter resource: The type of data accessed
    func recordDataAccess(resource: String) {
        let now = Date()

        if dataAccessLog[resource] == nil {
            dataAccessLog[resource] = []
        }
        dataAccessLog[resource]?.append(now)

        // Update access hour profile
        let hour = Calendar.current.component(.hour, from: now)
        accessHourProfile[hour, default: 0] += 1

        // Check for bulk access (many records in a short window)
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let recentAccesses = dataAccessLog[resource]?.filter { $0 > fiveMinutesAgo } ?? []

        if recentAccesses.count > bulkAccessThreshold {
            addAlert(SecurityAlert(
                severity: .high,
                message: "Bulk data access detected: \(resource) (\(recentAccesses.count) accesses in 5 minutes)"
            ))

            Task {
                await AuditLogger.shared.logSecurityEvent(
                    event: "bulk_access_detected",
                    details: "resource=\(resource); count=\(recentAccesses.count)"
                )
            }
        }
    }

    // MARK: - Anomaly Detection (ACP-1056)

    /// Check for anomalous patterns in security data.
    /// Called periodically by the monitoring loop.
    func checkAnomalies() {
        checkUnusualAccessTime()
        checkRapidAPIUsage()
    }

    /// Acknowledge a security alert (mark as reviewed).
    func acknowledgeAlert(_ alertId: UUID) {
        if let index = securityAlerts.firstIndex(where: { $0.id == alertId }) {
            securityAlerts[index].acknowledged = true
        }
    }

    /// Dismiss all acknowledged alerts.
    func dismissAcknowledgedAlerts() {
        securityAlerts.removeAll { $0.acknowledged }
    }

    /// Count of unacknowledged alerts.
    var unacknowledgedAlertCount: Int {
        securityAlerts.filter { !$0.acknowledged }.count
    }

    /// Highest severity among unacknowledged alerts.
    var highestAlertSeverity: SecurityAlertSeverity? {
        securityAlerts
            .filter { !$0.acknowledged }
            .map { $0.severity }
            .max()
    }

    // MARK: - Private Methods

    private func lockAccount(email: String, reason: String) async {
        let lockoutExpiry = Date().addingTimeInterval(lockoutDuration)
        accountLockouts[email] = lockoutExpiry

        let remainingMinutes = Int(lockoutDuration / 60)

        DebugLogger.shared.warning("SecurityMonitor", "Account locked: \(email) - Reason: \(reason)")
        DebugLogger.shared.warning("SecurityMonitor", "Lockout expires in \(remainingMinutes) minutes")

        addAlert(SecurityAlert(
            severity: .critical,
            message: "Account locked due to: \(reason). Lockout duration: \(remainingMinutes) minutes."
        ))

        // Log to audit trail
        await AuditLogger.shared.logSecurityEvent(
            event: "account_locked",
            details: "reason=\(reason); duration_min=\(remainingMinutes)"
        )

        // Send alert to Sentry
        await sendSecurityAlert(
            email: email,
            event: "ACCOUNT_LOCKED",
            details: [
                "reason": reason,
                "lockout_duration_minutes": remainingMinutes,
                "failed_attempts": failedAttempts[email]?.count ?? 0
            ]
        )
    }

    private func cleanupOldAttempts(email: String) {
        let cutoff = Date().addingTimeInterval(-3600)

        failedAttempts[email] = failedAttempts[email]?.filter { attempt in
            attempt > cutoff
        }

        // Remove empty entries
        if failedAttempts[email]?.isEmpty == true {
            failedAttempts.removeValue(forKey: email)
        }
    }

    /// Clean up expired data from all tracking dictionaries.
    private func cleanupExpiredData() {
        let oneHourAgo = Date().addingTimeInterval(-3600)

        // Clean API call log (keep last hour)
        for (endpoint, timestamps) in apiCallLog {
            apiCallLog[endpoint] = timestamps.filter { $0 > oneHourAgo }
            if apiCallLog[endpoint]?.isEmpty == true {
                apiCallLog.removeValue(forKey: endpoint)
            }
        }

        // Clean data access log (keep last hour)
        for (resource, timestamps) in dataAccessLog {
            dataAccessLog[resource] = timestamps.filter { $0 > oneHourAgo }
            if dataAccessLog[resource]?.isEmpty == true {
                dataAccessLog.removeValue(forKey: resource)
            }
        }

        // Trim alerts to max
        if securityAlerts.count > maxAlerts {
            securityAlerts = Array(securityAlerts.prefix(maxAlerts))
        }
    }

    /// Check if data is being accessed at an unusual time.
    private func checkUnusualAccessTime() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let totalAccesses = accessHourProfile.values.reduce(0, +)

        // Need enough historical data to make a judgment
        guard totalAccesses > 50 else { return }

        let currentHourCount = accessHourProfile[currentHour, default: 0]
        let averagePerHour = Double(totalAccesses) / 24.0

        // If this hour has less than 10% of average and we have recent activity, flag it
        let recentActivityCount = dataAccessLog.values.flatMap { $0 }.filter {
            Date().timeIntervalSince($0) < 300 // Last 5 minutes
        }.count

        if Double(currentHourCount) < averagePerHour * 0.1 && recentActivityCount > 5 {
            addAlert(SecurityAlert(
                severity: .medium,
                message: "Data access at unusual time (hour \(currentHour):00). This time has historically low activity."
            ))

            Task {
                await AuditLogger.shared.logSecurityEvent(
                    event: "unusual_access_time",
                    details: "hour=\(currentHour); recent_accesses=\(recentActivityCount)"
                )
            }
        }
    }

    /// Check for rapid API usage across all endpoints.
    private func checkRapidAPIUsage() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let totalRecentCalls = apiCallLog.values.flatMap { $0 }.filter { $0 > oneMinuteAgo }.count

        // Warn if total API calls across all endpoints exceed 2x the per-endpoint limit
        if totalRecentCalls > apiRateLimitPerMinute * 2 {
            addAlert(SecurityAlert(
                severity: .medium,
                message: "High API activity detected: \(totalRecentCalls) total calls in the last minute across all endpoints."
            ))
        }
    }

    /// Add a security alert to the published list.
    private func addAlert(_ alert: SecurityAlert) {
        securityAlerts.insert(alert, at: 0)

        // Keep within limit
        if securityAlerts.count > maxAlerts {
            securityAlerts.removeLast()
        }

        DebugLogger.shared.warning("SecurityMonitor", "[\(alert.severity.rawValue)] \(alert.message)")
    }

    private func logFailedAttempt(email: String) async {
        // Log to database for audit trail
        let client = PTSupabaseClient.shared.client

        let input = FailedLoginAttemptInsert(
            userEmail: email,
            attemptedAt: Self.iso8601Formatter.string(from: Date())
        )

        do {
            try await client.from("failed_login_attempts")
                .insert(input)
                .execute()
        } catch {
            DebugLogger.shared.error("SecurityMonitor", "Failed to log failed attempt: \(error.localizedDescription)")
        }
    }

    // MARK: - Encodable Structs for Supabase

    private struct FailedLoginAttemptInsert: Encodable {
        let userEmail: String
        let attemptedAt: String

        enum CodingKeys: String, CodingKey {
            case userEmail = "user_email"
            case attemptedAt = "attempted_at"
        }
    }

    private func sendSecurityAlert(email: String, event: String, details: [String: Any]) async {
        DebugLogger.shared.warning("SecurityMonitor", "SECURITY ALERT: \(event)")
        DebugLogger.shared.warning("SecurityMonitor", "Email: \(email)")
        DebugLogger.shared.warning("SecurityMonitor", "Details: \(details)")

        #if canImport(Sentry)
        SentrySDK.capture(message: "Security Alert: \(event)") { scope in
            scope.setLevel(.warning)
            scope.setContext(value: details, key: "security_event")
            scope.setTag(value: event, key: "security_event_type")
        }
        #endif
    }

    // MARK: - Public Helpers

    /// Get failed attempts count for email
    func getFailedAttemptsCount(email: String) -> Int {
        let cutoff = Date().addingTimeInterval(-failedLoginWindow)
        return failedAttempts[email]?.filter { $0 > cutoff }.count ?? 0
    }

    /// Get remaining attempts before lockout
    func getRemainingAttempts(email: String) -> Int {
        let failed = getFailedAttemptsCount(email: email)
        return max(0, maxFailedAttempts - failed)
    }
}
