//
//  UpsellService.swift
//  PTPerformance
//
//  ACP-1006: In-App Upsell Prompts — Contextual upgrade nudges.
//  Surfaces upgrade prompts at high-value moments with smart
//  frequency capping to avoid being pushy.
//

import Foundation
import Combine

// MARK: - Upsell Trigger

/// Contextual triggers that may surface an upsell prompt.
enum UpsellTrigger: String, Codable, CaseIterable, Sendable {
    /// User hit a feature limit (e.g., max free workouts)
    case featureLimitReached = "feature_limit_reached"
    /// User achieved a workout milestone (PR, streak)
    case workoutMilestone = "workout_milestone"
    /// User exhausted free AI coaching quota
    case aiUsageLimit = "ai_usage_limit"
    /// User previewed a Pro/Elite analytics screen
    case analyticsPreview = "analytics_preview"
    /// User attempted to export data (Elite-only)
    case exportAttempt = "export_attempt"

    /// Human-readable name for analytics
    var displayName: String {
        switch self {
        case .featureLimitReached: return "Feature Limit"
        case .workoutMilestone: return "Workout Milestone"
        case .aiUsageLimit: return "AI Usage Limit"
        case .analyticsPreview: return "Analytics Preview"
        case .exportAttempt: return "Export Attempt"
        }
    }

    /// The SF Symbol icon displayed alongside the upsell banner
    var icon: String {
        switch self {
        case .featureLimitReached: return "lock.fill"
        case .workoutMilestone: return "trophy.fill"
        case .aiUsageLimit: return "brain.head.profile"
        case .analyticsPreview: return "chart.bar.fill"
        case .exportAttempt: return "square.and.arrow.up.fill"
        }
    }

    /// Accent color for the banner icon tint
    var accentColorName: String {
        switch self {
        case .featureLimitReached: return "orange"
        case .workoutMilestone: return "modusCyan"
        case .aiUsageLimit: return "purple"
        case .analyticsPreview: return "modusCyan"
        case .exportAttempt: return "purple"
        }
    }
}

// MARK: - Upsell Prompt

/// A contextual upgrade prompt displayed inline as a banner.
struct UpsellPrompt: Identifiable, Sendable {
    let id: String
    let trigger: UpsellTrigger
    let title: String
    let message: String
    let feature: SubscriptionTier.Feature?
    let targetTier: SubscriptionTier
    let dismissCount: Int
    let createdAt: Date

    init(
        trigger: UpsellTrigger,
        title: String,
        message: String,
        feature: SubscriptionTier.Feature? = nil,
        targetTier: SubscriptionTier = .pro,
        dismissCount: Int = 0
    ) {
        self.id = UUID().uuidString
        self.trigger = trigger
        self.title = title
        self.message = message
        self.feature = feature
        self.targetTier = targetTier
        self.dismissCount = dismissCount
        self.createdAt = Date()
    }
}

// MARK: - Upsell Service

/// Contextual upsell engine with smart frequency capping.
///
/// ## Frequency Rules
/// - Maximum 1 upsell per session
/// - Maximum 3 upsells per rolling 7-day window
/// - A trigger is suppressed if dismissed 3+ times for the same trigger type
///
/// ## Usage
/// ```swift
/// UpsellService.shared.checkUpsellOpportunity(trigger: .workoutMilestone)
/// ```
@MainActor
class UpsellService: ObservableObject {

    // MARK: - Singleton

    static let shared = UpsellService()

    // MARK: - Published Properties

    /// The currently active upsell prompt, if any. Only one at a time.
    @Published var activeUpsell: UpsellPrompt?

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let storeKit = StoreKitService.shared

    /// Tracks how many upsells were shown in this app session.
    private var sessionImpressionCount: Int = 0

    /// Maximum upsell impressions per app session.
    private let maxSessionImpressions: Int = 1

    /// Maximum upsell impressions per 7-day window.
    private let maxWeeklyImpressions: Int = 3

    /// Maximum times a single trigger can be dismissed before suppression.
    private let maxDismissPerTrigger: Int = 3

    /// UserDefaults keys
    private enum Keys {
        static let weeklyImpressions = "upsell_weekly_impressions"
        static let triggerDismissals = "upsell_trigger_dismissals"
        static let triggerImpressions = "upsell_trigger_impressions"
        static let triggerConversions = "upsell_trigger_conversions"
    }

    // MARK: - Init

    private init() {
        logger.info("Upsell", "UpsellService initialized")
        cleanupStaleImpressions()
    }

    // MARK: - Check Opportunity

    /// Evaluates whether an upsell prompt should be shown for the given trigger.
    ///
    /// The prompt is only surfaced if all frequency caps pass and the user's
    /// current tier does not already include the feature associated with the trigger.
    ///
    /// - Parameter trigger: The contextual event that may warrant an upsell.
    func checkUpsellOpportunity(trigger: UpsellTrigger) {
        logger.info("Upsell", "Evaluating upsell opportunity for trigger: \(trigger.displayName)")

        // User already has a high enough tier? No upsell needed.
        let currentTier = storeKit.currentTier
        let targetTier = targetTierForTrigger(trigger)

        if currentTier.isAtLeast(targetTier) {
            logger.diagnostic("Upsell: User tier \(currentTier.displayName) already covers \(trigger.displayName)")
            return
        }

        // Frequency cap: session limit
        if sessionImpressionCount >= maxSessionImpressions {
            logger.info("Upsell", "Session impression cap reached (\(maxSessionImpressions))")
            return
        }

        // Frequency cap: weekly limit
        let weeklyCount = getWeeklyImpressionCount()
        if weeklyCount >= maxWeeklyImpressions {
            logger.info("Upsell", "Weekly impression cap reached (\(maxWeeklyImpressions))")
            return
        }

        // Frequency cap: per-trigger dismissal limit
        let dismissals = getDismissCount(for: trigger)
        if dismissals >= maxDismissPerTrigger {
            logger.info("Upsell", "Trigger \(trigger.displayName) dismissed \(dismissals) times — suppressed")
            return
        }

        // Already showing a prompt? Don't replace it.
        if activeUpsell != nil {
            logger.info("Upsell", "An upsell is already active — skipping")
            return
        }

        // Build and present the prompt.
        let prompt = buildPrompt(for: trigger, targetTier: targetTier, dismissCount: dismissals)
        activeUpsell = prompt
        sessionImpressionCount += 1
        recordImpression(for: trigger)

        HapticFeedback.light()
        logger.success("Upsell", "Presenting upsell: \(prompt.title) (trigger: \(trigger.displayName))")
    }

    // MARK: - Dismiss

    /// Dismisses the current upsell prompt and records the dismissal.
    func dismissUpsell() {
        guard let upsell = activeUpsell else { return }
        logger.info("Upsell", "User dismissed upsell for trigger: \(upsell.trigger.displayName)")

        recordDismissal(for: upsell.trigger)
        activeUpsell = nil
        HapticFeedback.light()
    }

    // MARK: - Conversion

    /// Records that the user tapped the upgrade CTA on an upsell prompt.
    func recordConversion() {
        guard let upsell = activeUpsell else { return }
        logger.success("Upsell", "Upsell conversion for trigger: \(upsell.trigger.displayName)")

        recordConversionEvent(for: upsell.trigger)
        activeUpsell = nil
        HapticFeedback.medium()
    }

    // MARK: - Reset (for session boundaries)

    /// Resets session-scoped counters. Call on app foreground if desired.
    func resetSessionCounters() {
        sessionImpressionCount = 0
        logger.diagnostic("Upsell: Session counters reset")
    }

    // MARK: - Prompt Building

    private func buildPrompt(for trigger: UpsellTrigger, targetTier: SubscriptionTier, dismissCount: Int) -> UpsellPrompt {
        let title: String
        let message: String
        let feature: SubscriptionTier.Feature?

        switch trigger {
        case .featureLimitReached:
            title = "Go Unlimited"
            message = "Unlock unlimited workouts and remove all limits with \(targetTier.displayName)."
            feature = .unlimitedWorkouts

        case .workoutMilestone:
            title = "You are on Fire"
            message = "Keep the momentum going with advanced analytics and AI coaching."
            feature = .advancedAnalytics

        case .aiUsageLimit:
            title = "Unlock AI Coaching"
            message = "Get unlimited personalized AI coaching recommendations."
            feature = .aiCoaching

        case .analyticsPreview:
            title = "See the Full Picture"
            message = "Unlock advanced charts, trends, and performance insights."
            feature = .advancedAnalytics

        case .exportAttempt:
            title = "Export Your Data"
            message = "Elite members can export all training data in multiple formats."
            feature = .exportData
        }

        return UpsellPrompt(
            trigger: trigger,
            title: title,
            message: message,
            feature: feature,
            targetTier: targetTier,
            dismissCount: dismissCount
        )
    }

    private func targetTierForTrigger(_ trigger: UpsellTrigger) -> SubscriptionTier {
        switch trigger {
        case .featureLimitReached, .workoutMilestone, .aiUsageLimit, .analyticsPreview:
            return .pro
        case .exportAttempt:
            return .elite
        }
    }

    // MARK: - Persistence Helpers

    private func getWeeklyImpressionCount() -> Int {
        let impressions = getWeeklyImpressions()
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return impressions.filter { $0 > oneWeekAgo }.count
    }

    private func getWeeklyImpressions() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: Keys.weeklyImpressions),
              let dates = try? SafeJSON.decoder().decode([Date].self, from: data) else {
            return []
        }
        return dates
    }

    private func recordImpression(for trigger: UpsellTrigger) {
        // Weekly timestamps
        var impressions = getWeeklyImpressions()
        impressions.append(Date())
        if let data = try? SafeJSON.encoder().encode(impressions) {
            UserDefaults.standard.set(data, forKey: Keys.weeklyImpressions)
        }

        // Per-trigger impression count
        var counts = getTriggerCounts(key: Keys.triggerImpressions)
        counts[trigger.rawValue, default: 0] += 1
        saveTriggerCounts(counts, key: Keys.triggerImpressions)
    }

    private func getDismissCount(for trigger: UpsellTrigger) -> Int {
        let counts = getTriggerCounts(key: Keys.triggerDismissals)
        return counts[trigger.rawValue] ?? 0
    }

    private func recordDismissal(for trigger: UpsellTrigger) {
        var counts = getTriggerCounts(key: Keys.triggerDismissals)
        counts[trigger.rawValue, default: 0] += 1
        saveTriggerCounts(counts, key: Keys.triggerDismissals)
    }

    private func recordConversionEvent(for trigger: UpsellTrigger) {
        var counts = getTriggerCounts(key: Keys.triggerConversions)
        counts[trigger.rawValue, default: 0] += 1
        saveTriggerCounts(counts, key: Keys.triggerConversions)
    }

    private func getTriggerCounts(key: String) -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return counts
    }

    private func saveTriggerCounts(_ counts: [String: Int], key: String) {
        if let data = try? JSONEncoder().encode(counts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Removes impressions older than 7 days to keep storage lean.
    private func cleanupStaleImpressions() {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let impressions = getWeeklyImpressions().filter { $0 > oneWeekAgo }
        if let data = try? SafeJSON.encoder().encode(impressions) {
            UserDefaults.standard.set(data, forKey: Keys.weeklyImpressions)
        }
    }
}
