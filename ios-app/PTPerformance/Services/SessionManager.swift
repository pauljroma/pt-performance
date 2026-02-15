//
//  SessionManager.swift
//  PTPerformance
//
//  Purpose: Automatic session timeout (15 minutes) - HIPAA Technical Safeguard requirement
//  ACP-1040: Session security hardening — token refresh, fingerprinting, compromise detection
//

import SwiftUI
import Combine

/// Manages user session timeout, token refresh, and security monitoring
/// HIPAA Technical Safeguard: Automatic Logoff (§164.312(a)(2)(iii))
/// ACP-1040: Session security hardening

final class SessionManager: ObservableObject {

    // MARK: - Properties

    /// Session timeout duration (15 minutes)
    static let sessionTimeout: TimeInterval = 15 * 60 // 900 seconds

    /// Token refresh threshold — refresh when less than 5 minutes remain on the token
    static let tokenRefreshThreshold: TimeInterval = 5 * 60 // 300 seconds

    /// Singleton instance
    static let shared = SessionManager()

    /// Published property to trigger logout
    @Published var shouldLogout = false

    /// Reason for the most recent logout trigger (for UI messaging)
    @Published var logoutReason: LogoutReason?

    /// Timer for session timeout
    private var timeoutTimer: Timer?

    /// Timer for periodic token refresh checks
    private var tokenRefreshTimer: Timer?

    /// Last activity timestamp
    private var lastActivityTime: Date = Date()

    /// Session start time for duration tracking
    private var sessionStartTime: Date?

    /// Whether session monitoring is active
    private var isMonitoring = false

    /// Notification observers
    private var cancellables = Set<AnyCancellable>()

    /// Logger for session events
    private let debugLogger = DebugLogger.shared

    /// Secure store for session fingerprint
    private let secureStore = SecureStore.shared

    // MARK: - Logout Reasons

    /// Describes why a session was terminated
    enum LogoutReason: Equatable {
        case inactivityTimeout
        case tokenRefreshFailed
        case compromisedSession
        case passwordChanged
        case userInitiated
        case forceLogout

        var displayMessage: String {
            switch self {
            case .inactivityTimeout:
                return "Your session expired due to inactivity."
            case .tokenRefreshFailed:
                return "Your session could not be refreshed. Please sign in again."
            case .compromisedSession:
                return "A security issue was detected with your session. Please sign in again."
            case .passwordChanged:
                return "Your password was changed. Please sign in with your new password."
            case .userInitiated:
                return "You have been signed out."
            case .forceLogout:
                return "You have been signed out for security reasons."
            }
        }
    }

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Public Methods

    /// Start monitoring user activity and session timeout
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        sessionStartTime = Date()
        resetActivity()
        startTimer()
        startTokenRefreshTimer()
        storeSessionFingerprint()

        debugLogger.log("[SessionManager] Session monitoring started (timeout: \(Int(Self.sessionTimeout / 60)) minutes)", level: .success)
    }

    /// Stop monitoring (e.g., when user logs out)
    func stopMonitoring() {
        isMonitoring = false
        stopTimer()
        stopTokenRefreshTimer()
        logSessionDuration()

        debugLogger.log("[SessionManager] Session monitoring stopped", level: .diagnostic)
    }

    /// Record user activity (call on any user interaction)
    func recordActivity() {
        guard isMonitoring else { return }

        lastActivityTime = Date()
        // Timer will check this on next fire
    }

    /// Reset session (e.g., after successful re-authentication)
    func resetSession() {
        resetActivity()
        shouldLogout = false
        logoutReason = nil
    }

    /// Force logout: clears all credentials and triggers navigation to login.
    /// Use for security events like password change, compromised session, or admin action.
    ///
    /// - Parameter reason: The reason for the forced logout
    func forceLogout(reason: LogoutReason) {
        debugLogger.log("[SessionManager] Force logout triggered: \(reason.displayMessage)", level: .warning)

        // Clear auth credentials only (preserve encryption keys)
        secureStore.clearAuthCredentials()

        // Clear the hasActiveSession flag
        UserDefaults.standard.set(false, forKey: "hasActiveSession")

        stopMonitoring()

        // Trigger logout on main thread
        Task { @MainActor [weak self] in
            self?.logoutReason = reason
            self?.shouldLogout = true
        }
    }

    /// Called when the user's password is changed to force re-authentication.
    /// Clears all tokens and navigates to login.
    func handlePasswordChanged() {
        debugLogger.log("[SessionManager] Password change detected, forcing re-authentication", level: .warning)
        forceLogout(reason: .passwordChanged)
    }

    /// Detects whether the current session may be compromised by comparing
    /// the stored session fingerprint with the current device fingerprint.
    ///
    /// A mismatch indicates the token may have been used on a different device
    /// or the app was reinstalled.
    ///
    /// - Returns: `true` if the session appears compromised (fingerprint mismatch)
    func detectCompromisedSession() -> Bool {
        let currentFingerprint = generateSessionFingerprint()

        guard let storedFingerprint = try? secureStore.getString(forKey: SecureStore.Keys.sessionFingerprint) else {
            // No stored fingerprint — first session or keychain was cleared
            debugLogger.log("[SessionManager] No stored fingerprint found — new session", level: .diagnostic)
            return false
        }

        if storedFingerprint != currentFingerprint {
            debugLogger.log("[SessionManager] Session fingerprint mismatch detected", level: .warning)
            debugLogger.log("[SessionManager] Stored: \(storedFingerprint.prefix(20))..., Current: \(currentFingerprint.prefix(20))...", level: .diagnostic)
            return true
        }

        debugLogger.log("[SessionManager] Session fingerprint verified", level: .diagnostic)
        return false
    }

    /// Attempts to refresh the Supabase auth token proactively.
    /// Called periodically to ensure the token doesn't expire during active use.
    func refreshTokenIfNeeded() async {
        guard isMonitoring else { return }

        do {
            // Supabase SDK handles token refresh internally via autoRefreshToken,
            // but we explicitly call session refresh to ensure it happens proactively
            let session = try await PTSupabaseClient.shared.client.auth.session
            let expiresAt = Date(timeIntervalSince1970: TimeInterval(session.expiresAt))
            let timeUntilExpiry = expiresAt.timeIntervalSinceNow

            if timeUntilExpiry < Self.tokenRefreshThreshold {
                debugLogger.log("[SessionManager] Token expiring in \(Int(timeUntilExpiry))s, refreshing...", level: .info)

                let refreshedSession = try await PTSupabaseClient.shared.client.auth.refreshSession()

                await MainActor.run {
                    PTSupabaseClient.shared.currentSession = refreshedSession
                    PTSupabaseClient.shared.currentUser = refreshedSession.user
                }

                let newExpiresAt = Date(timeIntervalSince1970: TimeInterval(refreshedSession.expiresAt))
                debugLogger.log("[SessionManager] Token refreshed successfully, new expiry: \(newExpiresAt)", level: .success)
            } else {
                debugLogger.log("[SessionManager] Token valid for \(Int(timeUntilExpiry / 60)) more minutes", level: .diagnostic)
            }
        } catch {
            debugLogger.error("SessionManager", "Token refresh failed: \(error.localizedDescription)")

            // If token refresh fails and we can't recover, force logout
            forceLogout(reason: .tokenRefreshFailed)
        }
    }

    /// Performs a comprehensive session security check on app foreground.
    /// Validates fingerprint, checks token freshness, and verifies session integrity.
    func performSecurityCheck() async {
        guard isMonitoring else { return }

        // Check session fingerprint
        if detectCompromisedSession() {
            forceLogout(reason: .compromisedSession)
            return
        }

        // Proactively refresh token if needed
        await refreshTokenIfNeeded()
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        // Monitor app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleForeground()
            }
            .store(in: &cancellables)

        // Monitor app entering background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleBackgrounding()
            }
            .store(in: &cancellables)
    }

    private func startTimer() {
        stopTimer() // Clear any existing timer

        // Check every 60 seconds
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkSessionTimeout()
        }
    }

    private func stopTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    private func startTokenRefreshTimer() {
        stopTokenRefreshTimer()

        // Check token freshness every 2 minutes
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { [weak self] in
                await self?.refreshTokenIfNeeded()
            }
        }
    }

    private func stopTokenRefreshTimer() {
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
    }

    private func resetActivity() {
        lastActivityTime = Date()
    }

    private func checkSessionTimeout() {
        guard isMonitoring else { return }

        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastActivityTime)

        if elapsedTime >= Self.sessionTimeout {
            // Session expired
            forceLogout(reason: .inactivityTimeout)
        } else {
            let remainingTime = Self.sessionTimeout - elapsedTime
            debugLogger.log("[SessionManager] Session valid - \(Int(remainingTime / 60)) minutes remaining", level: .diagnostic)
        }
    }

    private func handleForeground() {
        // When app returns to foreground, check session validity and security
        checkSessionTimeout()

        // Run async security check (fingerprint + token refresh)
        Task { [weak self] in
            await self?.performSecurityCheck()
        }
    }

    private func handleBackgrounding() {
        // Record when app went to background
        // Session continues counting even in background
        debugLogger.log("[SessionManager] App backgrounded - session timeout continues", level: .diagnostic)
    }

    // MARK: - Session Fingerprinting (ACP-1040)

    /// Generates a fingerprint for the current device and app configuration.
    /// Used to detect if a session token is being used on a different device.
    ///
    /// Fingerprint components:
    /// - Vendor device ID (unique per device per vendor)
    /// - App version + build number
    /// - Bundle identifier
    private func generateSessionFingerprint() -> String {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"

        return "\(deviceId):\(bundleId):\(appVersion).\(buildNumber)"
    }

    /// Stores the current session fingerprint in the keychain.
    /// Called when session monitoring starts.
    private func storeSessionFingerprint() {
        let fingerprint = generateSessionFingerprint()
        do {
            try secureStore.set(fingerprint, forKey: SecureStore.Keys.sessionFingerprint)
            debugLogger.log("[SessionManager] Session fingerprint stored", level: .diagnostic)
        } catch {
            debugLogger.error("SessionManager", "Failed to store session fingerprint: \(error.localizedDescription)")
        }
    }

    // MARK: - Session Duration Tracking

    /// Logs the duration of the current session when monitoring stops.
    private func logSessionDuration() {
        guard let startTime = sessionStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        debugLogger.log("[SessionManager] Session duration: \(minutes)m \(seconds)s", level: .info)

        // Log to error tracking for analytics
        ErrorLogger.shared.logUserAction(
            action: "session_ended",
            properties: [
                "duration_seconds": Int(duration),
                "duration_minutes": minutes,
                "reason": logoutReason?.displayMessage ?? "unknown"
            ]
        )

        sessionStartTime = nil
    }

    // MARK: - Public Helpers

    /// Get remaining session time in seconds
    func getRemainingSessionTime() -> TimeInterval {
        guard isMonitoring else { return 0 }

        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastActivityTime)
        let remainingTime = max(0, Self.sessionTimeout - elapsedTime)

        return remainingTime
    }

    /// Check if session is about to expire (within 2 minutes)
    func isSessionExpiringSoon() -> Bool {
        let remaining = getRemainingSessionTime()
        return remaining > 0 && remaining <= 120 // 2 minutes
    }

    /// Whether a session is currently active and being monitored
    var isSessionActive: Bool {
        return isMonitoring
    }
}

// MARK: - View Extension for Activity Tracking

extension View {
    /// Track user activity on this view
    func trackActivity() -> some View {
        self.onAppear {
            SessionManager.shared.recordActivity()
        }
        .onTapGesture {
            SessionManager.shared.recordActivity()
        }
    }
}
