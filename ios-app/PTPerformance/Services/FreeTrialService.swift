//
//  FreeTrialService.swift
//  PTPerformance
//
//  ACP-992: Free Trial Optimization — manages trial state, conversion nudges,
//  and scheduled notifications for trial expiry.
//

import Foundation
import UserNotifications
import Combine

// MARK: - Free Trial Service

/// Manages the free trial lifecycle: activation, status tracking, expiry notifications,
/// and backend persistence.
///
/// ## Trial Flow
/// 1. User starts trial via paywall CTA -> `startTrial()`
/// 2. Service persists trial start date to UserDefaults + Supabase
/// 3. Schedules local notifications at 3 days, 1 day, and expiry
/// 4. `checkTrialStatus()` is called on every app launch to update state
/// 5. When trial expires, `PaywallService` is triggered with `.trialExpiring`
///
/// ## Persistence
/// Trial state is dual-persisted:
/// - **UserDefaults**: Immediate offline access for UI state
/// - **Supabase**: Server-side truth for cross-device sync and analytics
@MainActor
class FreeTrialService: ObservableObject {

    // MARK: - Singleton

    static let shared = FreeTrialService()

    // MARK: - Published State

    /// Whether the user is currently in an active free trial
    @Published var isInTrial: Bool = false

    /// Number of full days remaining in the trial (0 when expired)
    @Published var trialDaysRemaining: Int = 0

    /// The date the trial was started (nil if never started)
    @Published var trialStartDate: Date?

    /// Whether the trial has ever been started by this user
    @Published var hasStartedTrial: Bool = false

    /// Whether the trial has expired (started but no longer active)
    @Published var hasTrialExpired: Bool = false

    // MARK: - Private Properties

    private let logger = DebugLogger.shared

    /// Trial duration in days
    private let trialDurationDays: Int = 7

    /// Calendar for date calculations
    private let calendar = Calendar.current

    // MARK: - UserDefaults Keys

    private enum UDKeys {
        static let trialStartDate = "freetrial_start_date"
        static let hasStartedTrial = "freetrial_has_started"
        static let trialNotificationsScheduled = "freetrial_notifications_scheduled"
    }

    // MARK: - Notification IDs

    private enum NotificationIDs {
        static let threeDayWarning = "trial_expiry_3day"
        static let oneDayWarning = "trial_expiry_1day"
        static let expired = "trial_expired"
    }

    // MARK: - Init

    private init() {
        logger.info("FreeTrial", "FreeTrialService initialized")
        loadPersistedState()
        checkTrialStatus()
    }

    // MARK: - Start Trial

    /// Activates the free trial for the current user.
    ///
    /// - Sets the trial start date to now
    /// - Persists to UserDefaults and Supabase
    /// - Schedules expiry notification reminders
    /// - Updates all published state
    func startTrial() async {
        logger.info("FreeTrial", "Starting free trial")

        let startDate = Date()
        trialStartDate = startDate
        hasStartedTrial = true
        isInTrial = true
        trialDaysRemaining = trialDurationDays

        // Persist locally
        persistTrialStart(startDate)

        // Schedule notifications
        await scheduleTrialNotifications(from: startDate)

        // Persist to backend
        await syncTrialToBackend(startDate: startDate, isActive: true)

        logger.success("FreeTrial", "Free trial started — expires in \(trialDurationDays) days")
        HapticFeedback.success()
    }

    // MARK: - Check Trial Status

    /// Evaluates the current trial state based on the persisted start date.
    /// Call this on every app launch and when returning from background.
    func checkTrialStatus() {
        guard let startDate = trialStartDate else {
            // No trial has been started
            isInTrial = false
            trialDaysRemaining = 0
            hasTrialExpired = false
            logger.diagnostic("FreeTrial: No trial start date found")
            return
        }

        let expiryDate = calendar.date(byAdding: .day, value: trialDurationDays, to: startDate) ?? startDate
        let now = Date()

        if now < expiryDate {
            // Trial is active
            let components = calendar.dateComponents([.day], from: now, to: expiryDate)
            let remaining = max(0, components.day ?? 0)

            isInTrial = true
            trialDaysRemaining = remaining
            hasTrialExpired = false

            logger.info("FreeTrial", "Trial active — \(remaining) days remaining (expires: \(expiryDate))")

            // If 1 day or less remaining, trigger the trial-expiring paywall
            if remaining <= 1 && !StoreKitService.shared.isPremium {
                PaywallService.shared.triggerPaywall(.trialExpiring)
            }
        } else {
            // Trial has expired
            isInTrial = false
            trialDaysRemaining = 0
            hasTrialExpired = true

            logger.warning("FreeTrial", "Trial expired on \(expiryDate)")

            // Trigger winback paywall for expired trials
            if !StoreKitService.shared.isPremium {
                PaywallService.shared.triggerPaywall(.trialExpiring)
            }
        }
    }

    /// Returns the trial expiry date, or nil if no trial has been started.
    var trialExpiryDate: Date? {
        guard let startDate = trialStartDate else { return nil }
        return calendar.date(byAdding: .day, value: trialDurationDays, to: startDate)
    }

    /// Returns a human-readable string for the trial status.
    var trialStatusDescription: String {
        if isInTrial {
            if trialDaysRemaining == 0 {
                return "Trial expires today"
            } else if trialDaysRemaining == 1 {
                return "1 day left in trial"
            } else {
                return "\(trialDaysRemaining) days left in trial"
            }
        } else if hasTrialExpired {
            return "Trial expired"
        } else {
            return "No active trial"
        }
    }

    // MARK: - Notification Scheduling

    /// Schedules local notifications for trial expiry reminders.
    ///
    /// Notifications:
    /// - 3 days before expiry: Gentle reminder
    /// - 1 day before expiry: Urgent reminder
    /// - On expiry: Trial ended notification
    private func scheduleTrialNotifications(from startDate: Date) async {
        // Don't re-schedule if already done
        guard !UserDefaults.standard.bool(forKey: UDKeys.trialNotificationsScheduled) else {
            logger.diagnostic("FreeTrial: Notifications already scheduled")
            return
        }

        let center = UNUserNotificationCenter.current()

        // Request notification permission if needed
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                logger.warning("FreeTrial", "Notification permission not granted")
                return
            }
        } catch {
            logger.error("FreeTrial", "Failed to request notification permission: \(error.localizedDescription)")
            return
        }

        let expiryDate = calendar.date(byAdding: .day, value: trialDurationDays, to: startDate) ?? startDate

        // 3-day warning (4 days after start)
        if let threeDayDate = calendar.date(byAdding: .day, value: trialDurationDays - 3, to: startDate),
           threeDayDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Your Trial Ends in 3 Days"
            content.body = "Subscribe now to keep unlimited access to all Modus features."
            content.sound = .default
            content.categoryIdentifier = "TRIAL_REMINDER"

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: threeDayDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: NotificationIDs.threeDayWarning, content: content, trigger: trigger)

            do {
                try await center.add(request)
                logger.diagnostic("FreeTrial: Scheduled 3-day warning notification for \(threeDayDate)")
            } catch {
                logger.error("FreeTrial", "Failed to schedule 3-day notification: \(error.localizedDescription)")
            }
        }

        // 1-day warning
        if let oneDayDate = calendar.date(byAdding: .day, value: trialDurationDays - 1, to: startDate),
           oneDayDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Last Day of Your Free Trial"
            content.body = "Your trial ends tomorrow. Subscribe to continue your progress."
            content.sound = .default
            content.categoryIdentifier = "TRIAL_REMINDER"

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: NotificationIDs.oneDayWarning, content: content, trigger: trigger)

            do {
                try await center.add(request)
                logger.diagnostic("FreeTrial: Scheduled 1-day warning notification for \(oneDayDate)")
            } catch {
                logger.error("FreeTrial", "Failed to schedule 1-day notification: \(error.localizedDescription)")
            }
        }

        // Expiry notification
        if expiryDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Your Free Trial Has Ended"
            content.body = "Subscribe to Modus Premium to continue accessing all features."
            content.sound = .default
            content.categoryIdentifier = "TRIAL_EXPIRED"

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: expiryDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: NotificationIDs.expired, content: content, trigger: trigger)

            do {
                try await center.add(request)
                logger.diagnostic("FreeTrial: Scheduled expiry notification for \(expiryDate)")
            } catch {
                logger.error("FreeTrial", "Failed to schedule expiry notification: \(error.localizedDescription)")
            }
        }

        UserDefaults.standard.set(true, forKey: UDKeys.trialNotificationsScheduled)
        logger.success("FreeTrial", "Trial notifications scheduled successfully")
    }

    /// Cancels all pending trial notifications (e.g., when user converts to premium).
    func cancelTrialNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            NotificationIDs.threeDayWarning,
            NotificationIDs.oneDayWarning,
            NotificationIDs.expired
        ])
        logger.info("FreeTrial", "Trial notifications cancelled")
    }

    // MARK: - Persistence

    /// Loads the persisted trial state from UserDefaults
    private func loadPersistedState() {
        let defaults = UserDefaults.standard

        hasStartedTrial = defaults.bool(forKey: UDKeys.hasStartedTrial)

        if let startDateInterval = defaults.object(forKey: UDKeys.trialStartDate) as? TimeInterval {
            trialStartDate = Date(timeIntervalSince1970: startDateInterval)
            logger.diagnostic("FreeTrial: Loaded persisted trial start date: \(trialStartDate?.description ?? "nil")")
        }
    }

    /// Persists the trial start date to UserDefaults
    private func persistTrialStart(_ date: Date) {
        let defaults = UserDefaults.standard
        defaults.set(date.timeIntervalSince1970, forKey: UDKeys.trialStartDate)
        defaults.set(true, forKey: UDKeys.hasStartedTrial)
        // Reset notification flag so they can be re-scheduled if needed
        defaults.set(false, forKey: UDKeys.trialNotificationsScheduled)
    }

    // MARK: - Backend Sync

    /// Syncs trial state to Supabase for cross-device consistency and analytics.
    private func syncTrialToBackend(startDate: Date, isActive: Bool) async {
        guard PTSupabaseClient.shared.userId != nil else {
            logger.diagnostic("FreeTrial: No user logged in, skipping backend sync")
            return
        }

        logger.info("FreeTrial", "Syncing trial state to backend")

        do {
            let expiryDate = calendar.date(byAdding: .day, value: trialDurationDays, to: startDate) ?? startDate
            let formatter = ISO8601DateFormatter()

            let payload: [String: String] = [
                "trial_start": formatter.string(from: startDate),
                "trial_expiry": formatter.string(from: expiryDate),
                "trial_active": isActive ? "true" : "false",
                "trial_duration_days": "\(trialDurationDays)"
            ]

            _ = try await PTSupabaseClient.shared.client.functions
                .invoke("sync-trial-status", options: .init(body: payload))

            logger.success("FreeTrial", "Trial state synced to backend")
        } catch {
            // Non-fatal: trial still works locally
            logger.warning("FreeTrial", "Failed to sync trial to backend: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset (for testing / account deletion)

    /// Resets all trial state. Used for testing and account deletion flows.
    func resetTrial() {
        isInTrial = false
        trialDaysRemaining = 0
        trialStartDate = nil
        hasStartedTrial = false
        hasTrialExpired = false

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UDKeys.trialStartDate)
        defaults.removeObject(forKey: UDKeys.hasStartedTrial)
        defaults.removeObject(forKey: UDKeys.trialNotificationsScheduled)

        cancelTrialNotifications()

        logger.info("FreeTrial", "Trial state reset")
    }
}
