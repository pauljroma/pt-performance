//
//  SessionManager.swift
//  PTPerformance
//
//  Purpose: Automatic session timeout (15 minutes) - HIPAA Technical Safeguard requirement
//

import Foundation
import SwiftUI
import Combine

/// Manages user session timeout and auto-logout
/// HIPAA Technical Safeguard: Automatic Logoff (§164.312(a)(2)(iii))
final class SessionManager: ObservableObject {

    // MARK: - Properties

    /// Session timeout duration (15 minutes)
    static let sessionTimeout: TimeInterval = 15 * 60 // 900 seconds

    /// Singleton instance
    static let shared = SessionManager()

    /// Published property to trigger logout
    @Published var shouldLogout = false

    /// Timer for session timeout
    private var timeoutTimer: Timer?

    /// Last activity timestamp
    private var lastActivityTime: Date = Date()

    /// Whether session monitoring is active
    private var isMonitoring = false

    /// Notification observers
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Start monitoring user activity and session timeout
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        resetActivity()
        startTimer()

        #if DEBUG
        print("[SessionManager] Session monitoring started (timeout: \(Self.sessionTimeout / 60) minutes)")
        #endif
    }

    /// Stop monitoring (e.g., when user logs out)
    func stopMonitoring() {
        isMonitoring = false
        stopTimer()

        #if DEBUG
        print("[SessionManager] Session monitoring stopped")
        #endif
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
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        // Monitor app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkSessionOnForeground()
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

    private func resetActivity() {
        lastActivityTime = Date()
    }

    private func checkSessionTimeout() {
        guard isMonitoring else { return }

        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastActivityTime)

        if elapsedTime >= Self.sessionTimeout {
            // Session expired
            triggerLogout(reason: "Session expired after \(Int(Self.sessionTimeout / 60)) minutes of inactivity")
        } else {
            #if DEBUG
            let remainingTime = Self.sessionTimeout - elapsedTime
            print("[SessionManager] Session valid - \(Int(remainingTime / 60)) minutes remaining")
            #endif
        }
    }

    private func checkSessionOnForeground() {
        // When app returns to foreground, check if session is still valid
        checkSessionTimeout()
    }

    private func handleBackgrounding() {
        // Record when app went to background
        // Session continues counting even in background
        #if DEBUG
        print("[SessionManager] App backgrounded - session timeout continues")
        #endif
    }

    private func triggerLogout(reason: String) {
        #if DEBUG
        print("[SessionManager] ⚠️ Triggering logout: \(reason)")
        #endif

        stopMonitoring()

        // Trigger logout on main thread
        Task { @MainActor [weak self] in
            self?.shouldLogout = true
        }
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
