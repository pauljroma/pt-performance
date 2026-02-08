//
//  SecurityMonitor.swift
//  PTPerformance
//
//  Purpose: Failed login tracking and security alerts
//

import SwiftUI
#if canImport(Sentry)
import Sentry
#endif

/// Monitors security events and failed login attempts
final class SecurityMonitor: ObservableObject {

    // MARK: - Properties

    static let shared = SecurityMonitor()

    /// Maximum failed login attempts before lockout
    private let maxFailedAttempts = 5

    /// Lockout duration in seconds
    private let lockoutDuration: TimeInterval = 30 * 60 // 30 minutes

    /// Failed login attempts cache (email -> [timestamps])
    private var failedAttempts: [String: [Date]] = [:]

    /// Account lockouts cache (email -> lockout expiry)
    private var accountLockouts: [String: Date] = [:]

    // MARK: - Public Methods

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

        // Clean up old attempts (older than 1 hour)
        cleanupOldAttempts(email: email)

        // Check if should lock account
        let recentAttempts = failedAttempts[email]?.filter { attempt in
            now.timeIntervalSince(attempt) < 3600 // Last hour
        } ?? []

        if recentAttempts.count >= maxFailedAttempts {
            await lockAccount(email: email, reason: "Too many failed login attempts")
        }

        // Log to database
        await logFailedAttempt(email: email)
    }

    /// Record successful login (clears failed attempts)
    func recordSuccessfulLogin(email: String) {
        failedAttempts.removeValue(forKey: email)
        accountLockouts.removeValue(forKey: email)
    }

    /// Manually unlock account (admin function)
    func unlockAccount(email: String) {
        accountLockouts.removeValue(forKey: email)
        failedAttempts.removeValue(forKey: email)
        DebugLogger.shared.info("SecurityMonitor", "Account unlocked: \(email)")
    }

    // MARK: - Private Methods

    private func lockAccount(email: String, reason: String) async {
        let lockoutExpiry = Date().addingTimeInterval(lockoutDuration)
        accountLockouts[email] = lockoutExpiry

        let remainingMinutes = Int(lockoutDuration / 60)

        DebugLogger.shared.warning("SecurityMonitor", "Account locked: \(email) - Reason: \(reason)")
        DebugLogger.shared.warning("SecurityMonitor", "Lockout expires in \(remainingMinutes) minutes")

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
        let oneHourAgo = Date().addingTimeInterval(-3600)

        failedAttempts[email] = failedAttempts[email]?.filter { attempt in
            attempt > oneHourAgo
        }

        // Remove empty entries
        if failedAttempts[email]?.isEmpty == true {
            failedAttempts.removeValue(forKey: email)
        }
    }

    private func logFailedAttempt(email: String) async {
        // Log to database for audit trail
        let client = PTSupabaseClient.shared.client

        let input = FailedLoginAttemptInsert(
            userEmail: email,
            attemptedAt: ISO8601DateFormatter().string(from: Date())
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
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return failedAttempts[email]?.filter { $0 > oneHourAgo }.count ?? 0
    }

    /// Get remaining attempts before lockout
    func getRemainingAttempts(email: String) -> Int {
        let failed = getFailedAttemptsCount(email: email)
        return max(0, maxFailedAttempts - failed)
    }
}
