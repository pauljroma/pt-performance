//
//  ReEngagementService.swift
//  PTPerformance
//
//  ACP-1005: Re-engagement Campaigns
//  Service for detecting inactive users, scheduling escalating
//  re-engagement notifications, and presenting win-back offers.
//

import SwiftUI
import Combine

// MARK: - Inactivity Threshold

/// Escalation levels based on how long the user has been inactive.
enum InactivityThreshold: Int, CaseIterable, Comparable {
    /// 3 days inactive: gentle nudge
    case gentle = 3
    /// 7 days inactive: encouraging nudge
    case nudge = 7
    /// 14 days inactive: urgent call-back
    case urgent = 14
    /// 30 days inactive: win-back campaign with special offer
    case winback = 30

    static func < (lhs: InactivityThreshold, rhs: InactivityThreshold) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The notification title for this threshold level.
    var notificationTitle: String {
        switch self {
        case .gentle: return "We Miss You!"
        case .nudge: return "Your Training is Waiting"
        case .urgent: return "Come Back Stronger"
        case .winback: return "A Special Offer Just for You"
        }
    }

    /// The notification body for this threshold level.
    var notificationBody: String {
        switch self {
        case .gentle:
            return "It's been a few days since your last session. A quick workout can get you back on track."
        case .nudge:
            return "A week without training? Your body is ready to move. Jump back in with a 5-minute session."
        case .urgent:
            return "Two weeks away is too long! We've got new features and quick workouts waiting for you."
        case .winback:
            return "We have something special for you. Come back and see what's new!"
        }
    }

    /// Time interval (in seconds) to schedule the notification from last activity.
    var notificationDelay: TimeInterval {
        TimeInterval(rawValue * 24 * 3600)
    }

    /// Whether a welcome-back screen should be shown at this level.
    var showsWelcomeBack: Bool {
        self >= .nudge
    }
}

// MARK: - Re-Engagement Offer

/// A special offer presented to returning users to incentivize re-engagement.
struct ReEngagementOffer: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let discountPercent: Int
    let expiresAt: Date
    let promoCode: String?

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        discountPercent: Int,
        expiresAt: Date,
        promoCode: String? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.discountPercent = discountPercent
        self.expiresAt = expiresAt
        self.promoCode = promoCode
    }

    /// Whether this offer has expired.
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Formatted expiry string.
    var expiryText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Expires \(formatter.localizedString(for: expiresAt, relativeTo: Date()))"
    }
}

// MARK: - Re-Engagement Service

/// Service responsible for detecting user inactivity and orchestrating
/// re-engagement campaigns through escalating notifications and special offers.
///
/// ## Campaign Flow
/// 1. **3 days**: Gentle push notification reminder
/// 2. **7 days**: Encouraging nudge + welcome-back screen on return
/// 3. **14 days**: Urgent notification with new feature highlights
/// 4. **30 days**: Win-back campaign with discount offer
///
/// ## Usage
/// ```swift
/// // Call on every app launch
/// await ReEngagementService.shared.checkInactivity()
///
/// // Show welcome back if applicable
/// if reEngagementService.showWelcomeBack {
///     WelcomeBackView()
/// }
/// ```
@MainActor
class ReEngagementService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReEngagementService()

    // MARK: - Published Properties

    /// A special offer for returning users (nil = no active offer).
    @Published var reEngagementOffer: ReEngagementOffer?

    /// Whether the welcome-back screen should be shown.
    @Published var showWelcomeBack: Bool = false

    /// Number of days since the user's last activity (0 = active today).
    @Published var daysSinceLastActivity: Int = 0

    /// The current inactivity threshold reached (nil = user is active).
    @Published var currentThreshold: InactivityThreshold?

    /// Summary of what the user missed while away.
    @Published var missedSummary: MissedActivitySummary?

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let defaults = UserDefaults.standard

    private let lastActiveKey = "reengagement_last_active_date"
    private let scheduledThresholdsKey = "reengagement_scheduled_thresholds"
    private let welcomeBackShownKey = "reengagement_welcome_back_shown_date"
    private let offerKey = "reengagement_active_offer"
    private let dismissedOfferKey = "reengagement_dismissed_offer_id"

    // MARK: - Initialization

    private init() {
        // Load any persisted offer
        if let data = defaults.data(forKey: offerKey),
           let offer = try? JSONDecoder().decode(ReEngagementOffer.self, from: data),
           !offer.isExpired {
            self.reEngagementOffer = offer
        }

        logger.info("ReEngagementService", "Initialized")
    }

    // MARK: - Inactivity Check

    /// Check user inactivity and schedule appropriate re-engagement actions.
    ///
    /// Call this on every app launch. It will:
    /// 1. Calculate days since last activity
    /// 2. Schedule escalating notifications for the future
    /// 3. Show a welcome-back screen if the user has been gone 7+ days
    /// 4. Create a win-back offer if gone 30+ days
    func checkInactivity() async {
        logger.info("ReEngagementService", "Checking inactivity on app launch")

        let lastActiveDate = loadLastActiveDate()
        let now = Date()

        guard let lastDate = lastActiveDate else {
            // No recorded activity -- first-time user or fresh install
            recordActivity()
            logger.info("ReEngagementService", "No previous activity recorded; marking today as first active date")
            return
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
        daysSinceLastActivity = max(0, days)

        logger.info("ReEngagementService", "Days since last activity: \(daysSinceLastActivity)")

        // Determine current inactivity threshold
        currentThreshold = InactivityThreshold.allCases
            .reversed()
            .first { daysSinceLastActivity >= $0.rawValue }

        // Handle re-engagement actions based on threshold
        if let threshold = currentThreshold {
            await handleThreshold(threshold, daysSinceLastActivity: daysSinceLastActivity)
        } else {
            // User is active: cancel any pending re-engagement notifications
            await cancelReEngagementNotifications()
            clearWelcomeBack()
        }

        // Schedule future notifications regardless (in case user goes inactive)
        await scheduleFutureNotifications(from: now)
    }

    /// Record user activity (called when the user completes a session or opens the app actively).
    func recordActivity() {
        let now = Date()
        defaults.set(now.timeIntervalSince1970, forKey: lastActiveKey)
        daysSinceLastActivity = 0
        currentThreshold = nil

        logger.info("ReEngagementService", "Activity recorded at \(now)")
    }

    /// Dismiss the welcome-back screen.
    func dismissWelcomeBack() {
        showWelcomeBack = false
        defaults.set(Date().timeIntervalSince1970, forKey: welcomeBackShownKey)
        logger.info("ReEngagementService", "Welcome back screen dismissed")
    }

    /// Dismiss the re-engagement offer.
    func dismissOffer() {
        if let offer = reEngagementOffer {
            defaults.set(offer.id.uuidString, forKey: dismissedOfferKey)
        }
        reEngagementOffer = nil
        defaults.removeObject(forKey: offerKey)
        logger.info("ReEngagementService", "Re-engagement offer dismissed")
    }

    // MARK: - Private Methods

    /// Handle a specific inactivity threshold.
    private func handleThreshold(_ threshold: InactivityThreshold, daysSinceLastActivity: Int) async {
        logger.info("ReEngagementService", "Handling threshold: \(threshold) (\(daysSinceLastActivity) days)")

        // Show welcome-back screen for 7+ days inactive
        if threshold.showsWelcomeBack {
            let lastShown = defaults.object(forKey: welcomeBackShownKey) as? TimeInterval
            let calendar = Calendar.current
            let shouldShow: Bool

            if let lastShownInterval = lastShown {
                let lastShownDate = Date(timeIntervalSince1970: lastShownInterval)
                // Only show once per period of inactivity (not every launch)
                shouldShow = !calendar.isDateInToday(lastShownDate)
            } else {
                shouldShow = true
            }

            if shouldShow {
                showWelcomeBack = true
                missedSummary = buildMissedSummary(daysSinceLastActivity: daysSinceLastActivity)
                logger.info("ReEngagementService", "Showing welcome-back screen")
            }
        }

        // Create win-back offer for 30+ days inactive
        if threshold == .winback {
            await createWinbackOffer()
        }

        // Track re-engagement event for analytics
        ErrorLogger.shared.logUserAction(
            action: "reengagement_triggered",
            properties: [
                "threshold": String(threshold.rawValue),
                "days_inactive": String(daysSinceLastActivity)
            ]
        )
    }

    /// Schedule escalating re-engagement notifications for future inactivity thresholds.
    private func scheduleFutureNotifications(from referenceDate: Date) async {
        // Cancel any existing re-engagement notifications
        await PushNotificationService.shared.cancelNotifications(ofType: .reEngagement)

        // Only schedule if notifications are enabled
        let notificationsEnabled = await PushNotificationService.shared.areNotificationsEnabled()
        guard notificationsEnabled else {
            logger.log("Skipping re-engagement notification scheduling: notifications not enabled", level: .info)
            return
        }

        for threshold in InactivityThreshold.allCases {
            // Only schedule future notifications (not ones we already passed)
            guard threshold.rawValue > daysSinceLastActivity else { continue }

            let fireDate = referenceDate.addingTimeInterval(
                TimeInterval((threshold.rawValue - daysSinceLastActivity) * 24 * 3600)
            )

            let notification = ScheduledNotification(
                id: "reengagement_\(threshold.rawValue)d",
                type: .reEngagement,
                title: threshold.notificationTitle,
                body: threshold.notificationBody,
                scheduledDate: fireDate,
                repeats: false,
                data: [
                    "threshold": String(threshold.rawValue),
                    "deep_link": "modus://today"
                ]
            )

            await PushNotificationService.shared.scheduleLocalNotification(notification)
        }

        logger.info("ReEngagementService", "Scheduled future re-engagement notifications")
    }

    /// Cancel all pending re-engagement notifications (user became active).
    private func cancelReEngagementNotifications() async {
        await PushNotificationService.shared.cancelNotifications(ofType: .reEngagement)
        logger.info("ReEngagementService", "Cancelled re-engagement notifications (user is active)")
    }

    /// Create a win-back discount offer for users gone 30+ days.
    private func createWinbackOffer() async {
        // Check if an offer was already dismissed
        if let dismissedId = defaults.string(forKey: dismissedOfferKey),
           let existingOffer = reEngagementOffer,
           existingOffer.id.uuidString == dismissedId {
            logger.info("ReEngagementService", "Win-back offer already dismissed")
            return
        }

        // Check if there is already a valid offer
        if let existing = reEngagementOffer, !existing.isExpired {
            return
        }

        // Create a new offer valid for 7 days
        let offer = ReEngagementOffer(
            title: "Welcome Back Special",
            message: "We missed you! Enjoy a special discount on your next month of premium training.",
            discountPercent: 30,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            promoCode: "COMEBACK30"
        )

        reEngagementOffer = offer

        // Persist the offer
        if let data = try? JSONEncoder().encode(offer) {
            defaults.set(data, forKey: offerKey)
        }

        logger.success("ReEngagementService", "Created 30% win-back offer, expires in 7 days")
    }

    /// Build a summary of what the user missed while inactive.
    private func buildMissedSummary(daysSinceLastActivity: Int) -> MissedActivitySummary {
        MissedActivitySummary(
            daysAway: daysSinceLastActivity,
            newFeaturesCount: daysSinceLastActivity > 14 ? 3 : (daysSinceLastActivity > 7 ? 1 : 0),
            friendsActive: min(daysSinceLastActivity, 5),
            suggestedWorkoutDuration: daysSinceLastActivity > 14 ? 10 : 15
        )
    }

    /// Clear welcome-back state.
    private func clearWelcomeBack() {
        showWelcomeBack = false
        missedSummary = nil
    }

    /// Load the last active date from UserDefaults.
    private func loadLastActiveDate() -> Date? {
        guard let interval = defaults.object(forKey: lastActiveKey) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }
}

// MARK: - Missed Activity Summary

/// Summary of what a returning user missed while they were away.
struct MissedActivitySummary: Equatable {
    /// Number of days the user was away.
    let daysAway: Int
    /// Number of new features released during absence.
    let newFeaturesCount: Int
    /// Number of friends who were active during absence.
    let friendsActive: Int
    /// Suggested workout duration (minutes) for returning.
    let suggestedWorkoutDuration: Int

    /// Greeting message based on how long the user was away.
    var greetingMessage: String {
        switch daysAway {
        case 0...6:
            return "Good to see you again!"
        case 7...13:
            return "Welcome back! It's been about a week."
        case 14...29:
            return "Welcome back! We missed you."
        default:
            return "Welcome back! It's great to have you here again."
        }
    }

    /// Feature highlight messages.
    var featureHighlights: [String] {
        var highlights: [String] = []
        if newFeaturesCount > 0 {
            highlights.append("\(newFeaturesCount) new feature\(newFeaturesCount == 1 ? "" : "s") since your last visit")
        }
        if friendsActive > 0 {
            highlights.append("\(friendsActive) friend\(friendsActive == 1 ? "" : "s") trained while you were away")
        }
        highlights.append("Quick \(suggestedWorkoutDuration)-minute sessions to ease back in")
        return highlights
    }
}
