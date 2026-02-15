//
//  EmailLifecycleService.swift
//  PTPerformance
//
//  ACP-1003: Email Lifecycle Campaigns — In-app triggers for email flows
//  Fires event hooks that queue emails via Supabase edge functions.
//

import Foundation

// MARK: - Email Trigger

/// Lifecycle events that trigger automated email campaigns.
///
/// Each trigger maps to a specific email template on the backend.
/// The edge function handles template selection, personalization, and delivery.
enum EmailTrigger: String, CaseIterable, Identifiable {
    case welcome = "welcome"
    case onboardingComplete = "onboarding_complete"
    case firstWorkout = "first_workout"
    case streakMilestone = "streak_milestone"
    case trialExpiring = "trial_expiring"
    case subscriptionRenewal = "subscription_renewal"
    case inactive3Days = "inactive_3_days"
    case inactive7Days = "inactive_7_days"
    case cancellation = "cancellation"

    var id: String { rawValue }

    /// Human-readable name for logging
    var displayName: String {
        switch self {
        case .welcome: return "Welcome"
        case .onboardingComplete: return "Onboarding Complete"
        case .firstWorkout: return "First Workout"
        case .streakMilestone: return "Streak Milestone"
        case .trialExpiring: return "Trial Expiring"
        case .subscriptionRenewal: return "Subscription Renewal"
        case .inactive3Days: return "Inactive 3 Days"
        case .inactive7Days: return "Inactive 7 Days"
        case .cancellation: return "Cancellation"
        }
    }

    /// Cooldown period in seconds before this trigger can fire again for the same user.
    /// Prevents duplicate emails from rapid event firing.
    var cooldownSeconds: TimeInterval {
        switch self {
        case .welcome: return 86400 * 365           // Once ever
        case .onboardingComplete: return 86400 * 365 // Once ever
        case .firstWorkout: return 86400 * 365       // Once ever
        case .streakMilestone: return 86400 * 7      // Once per week
        case .trialExpiring: return 86400 * 3        // Once per 3 days
        case .subscriptionRenewal: return 86400 * 30 // Once per month
        case .inactive3Days: return 86400 * 7        // Once per week
        case .inactive7Days: return 86400 * 14       // Once per 2 weeks
        case .cancellation: return 86400 * 30        // Once per month
        }
    }
}

// MARK: - Email Lifecycle Service

/// Manages in-app triggers for automated email lifecycle campaigns.
///
/// When a lifecycle event occurs (e.g., first workout completed, streak milestone),
/// this service fires a trigger that calls a Supabase edge function to queue
/// the appropriate email. Includes deduplication, cooldown enforcement, and
/// opt-out checking.
///
/// ## Architecture
/// 1. App event occurs -> `triggerEmail(.firstWorkout, metadata: [...])`
/// 2. Service checks cooldown and opt-out status
/// 3. Edge function `queue-lifecycle-email` is called with trigger + metadata
/// 4. Backend handles template selection, personalization, and delivery via SendGrid/Resend
///
/// ## Usage
/// ```swift
/// // After user completes their first workout
/// await EmailLifecycleService.shared.triggerEmail(
///     .firstWorkout,
///     metadata: ["workout_name": "Full Body A", "duration_minutes": "45"]
/// )
///
/// // After a streak milestone
/// await EmailLifecycleService.shared.triggerEmail(
///     .streakMilestone,
///     metadata: ["streak_count": "7", "streak_type": "workout"]
/// )
/// ```
@MainActor
class EmailLifecycleService: ObservableObject {

    // MARK: - Singleton

    static let shared = EmailLifecycleService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let edgeFunctionName = "queue-lifecycle-email"
        static let lastTriggerPrefix = "email_trigger_last_"
        static let emailOptOutKey = "email_lifecycle_opt_out"
        static let triggerHistoryTable = "email_trigger_history"
    }

    // MARK: - Published Properties

    /// Whether the user has opted out of lifecycle emails
    @Published var isOptedOut: Bool

    /// Number of emails triggered this session (for diagnostics)
    @Published private(set) var sessionTriggerCount: Int = 0

    /// Last trigger error, if any
    @Published var lastError: String?

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.logger = logger
        self.isOptedOut = UserDefaults.standard.bool(forKey: Constants.emailOptOutKey)
        logger.info("EmailLifecycleService", "Initializing email lifecycle service (opted out: \(self.isOptedOut))")
    }

    // MARK: - Trigger Email

    /// Fires an email lifecycle trigger, queuing the email via a Supabase edge function.
    ///
    /// Performs the following checks before triggering:
    /// 1. User is authenticated
    /// 2. User has not opted out of lifecycle emails
    /// 3. Cooldown period has not been violated (deduplication)
    ///
    /// - Parameters:
    ///   - trigger: The lifecycle event that occurred
    ///   - metadata: Additional context for email personalization (e.g., streak count, workout name)
    func triggerEmail(_ trigger: EmailTrigger, metadata: [String: Any] = [:]) async {
        logger.info("EmailLifecycleService", "Attempting to trigger email: \(trigger.displayName)")

        // Check opt-out
        guard !isOptedOut else {
            logger.info("EmailLifecycleService", "User opted out of lifecycle emails. Skipping: \(trigger.displayName)")
            return
        }

        // Check authentication
        guard let userId = supabase.userId else {
            logger.warning("EmailLifecycleService", "No authenticated user. Cannot trigger: \(trigger.displayName)")
            return
        }

        // Check cooldown (deduplication)
        guard !isInCooldown(trigger) else {
            logger.info("EmailLifecycleService", "Trigger \(trigger.displayName) is in cooldown. Skipping.")
            return
        }

        // Build payload
        var payload: [String: String] = [
            "user_id": userId,
            "trigger": trigger.rawValue,
            "triggered_at": ISO8601DateFormatter().string(from: Date())
        ]

        // Flatten metadata to string values
        for (key, value) in metadata {
            payload["meta_\(key)"] = String(describing: value)
        }

        // Call edge function
        do {
            try await supabase.client.functions
                .invoke(Constants.edgeFunctionName, options: .init(body: payload))

            // Record cooldown
            recordTriggerTime(trigger)
            sessionTriggerCount += 1
            lastError = nil

            logger.success("EmailLifecycleService", "Successfully triggered email: \(trigger.displayName)")
        } catch {
            if error.isCancellation {
                logger.diagnostic("EmailLifecycleService: Trigger cancelled for \(trigger.displayName)")
                return
            }

            let message = "Failed to trigger email \(trigger.displayName): \(error.localizedDescription)"
            logger.error("EmailLifecycleService", message)
            lastError = message

            // Store failed trigger for retry
            await storePendingTrigger(trigger: trigger, metadata: payload)
        }
    }

    // MARK: - Opt-Out Management

    /// Sets the user's email lifecycle opt-out preference.
    ///
    /// - Parameter optOut: `true` to opt out of all lifecycle emails
    func setOptOut(_ optOut: Bool) {
        isOptedOut = optOut
        UserDefaults.standard.set(optOut, forKey: Constants.emailOptOutKey)
        logger.info("EmailLifecycleService", "Email opt-out set to: \(optOut)")

        // Sync preference to backend
        Task {
            await syncOptOutPreference(optOut)
        }
    }

    // MARK: - Retry Pending Triggers

    /// Retries any pending triggers that failed due to network issues.
    func retryPendingTriggers() async {
        logger.diagnostic("EmailLifecycleService: Checking for pending email triggers to retry")

        guard let pendingData = UserDefaults.standard.data(forKey: "pending_email_triggers"),
              let pending = try? JSONDecoder().decode([[String: String]].self, from: pendingData),
              !pending.isEmpty else {
            return
        }

        logger.info("EmailLifecycleService", "Found \(pending.count) pending triggers to retry")

        var remaining: [[String: String]] = []

        for payload in pending {
            do {
                try await supabase.client.functions
                    .invoke(Constants.edgeFunctionName, options: .init(body: payload))

                logger.success("EmailLifecycleService", "Retried trigger: \(payload["trigger"] ?? "unknown")")
            } catch {
                remaining.append(payload)
                logger.warning("EmailLifecycleService", "Retry still failed for: \(payload["trigger"] ?? "unknown")")
            }
        }

        // Update pending list
        if remaining.isEmpty {
            UserDefaults.standard.removeObject(forKey: "pending_email_triggers")
        } else {
            if let data = try? JSONEncoder().encode(remaining) {
                UserDefaults.standard.set(data, forKey: "pending_email_triggers")
            }
        }
    }

    // MARK: - Private: Cooldown Management

    /// Checks whether a trigger is currently in its cooldown period.
    private func isInCooldown(_ trigger: EmailTrigger) -> Bool {
        let key = Constants.lastTriggerPrefix + trigger.rawValue
        guard let lastTriggered = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastTriggered) < trigger.cooldownSeconds
    }

    /// Records the current time as the last trigger time for cooldown tracking.
    private func recordTriggerTime(_ trigger: EmailTrigger) {
        let key = Constants.lastTriggerPrefix + trigger.rawValue
        UserDefaults.standard.set(Date(), forKey: key)
    }

    // MARK: - Private: Persistence

    /// Stores a failed trigger for later retry.
    private func storePendingTrigger(trigger: EmailTrigger, metadata: [String: String]) async {
        var pending: [[String: String]] = []
        if let data = UserDefaults.standard.data(forKey: "pending_email_triggers"),
           let existing = try? JSONDecoder().decode([[String: String]].self, from: data) {
            pending = existing
        }

        // Limit pending queue size
        guard pending.count < 50 else {
            logger.warning("EmailLifecycleService", "Pending trigger queue full. Dropping: \(trigger.displayName)")
            return
        }

        pending.append(metadata)
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: "pending_email_triggers")
        }

        logger.info("EmailLifecycleService", "Stored pending trigger: \(trigger.displayName)")
    }

    /// Syncs the opt-out preference to the backend.
    private func syncOptOutPreference(_ optOut: Bool) async {
        guard let userId = supabase.userId else { return }

        do {
            try await supabase.client
                .from("user_preferences")
                .upsert([
                    "user_id": userId,
                    "email_lifecycle_opt_out": optOut ? "true" : "false",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()

            logger.success("EmailLifecycleService", "Synced opt-out preference to backend")
        } catch {
            logger.warning("EmailLifecycleService", "Failed to sync opt-out preference: \(error.localizedDescription)")
        }
    }
}
