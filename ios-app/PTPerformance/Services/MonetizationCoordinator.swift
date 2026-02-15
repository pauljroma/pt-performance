//
//  MonetizationCoordinator.swift
//  PTPerformance
//
//  ACP-993 / ACP-1006 / ACP-1007 / ACP-1010
//  Orchestrates all monetization surfaces — winback, upsell, annual
//  conversion, and upgrade prompts — ensuring only one monetization
//  prompt is active at a time and respecting priority ordering.
//

import Foundation
import Combine

// MARK: - Monetization Event

/// Events that the coordinator uses to decide when to evaluate monetization opportunities.
enum MonetizationEvent: String, Sendable {
    case appLaunch = "app_launch"
    case workoutCompleted = "workout_completed"
    case personalRecord = "personal_record"
    case streakMilestone = "streak_milestone"
    case featureLimitHit = "feature_limit_hit"
    case aiUsageLimitHit = "ai_usage_limit_hit"
    case analyticsViewed = "analytics_viewed"
    case exportAttempted = "export_attempted"
    case subscriptionExpiring = "subscription_expiring"
    case sessionStart = "session_start"
}

// MARK: - Active Prompt Type

/// The type of monetization prompt currently being shown.
enum MonetizationPromptType: String, Comparable, Sendable {
    case winback = "winback"
    case trialExpiring = "trial_expiring"
    case annualConversion = "annual_conversion"
    case upgradeToElite = "upgrade_to_elite"
    case upsell = "upsell"

    /// Priority ordering (lower number = higher priority).
    var priority: Int {
        switch self {
        case .winback: return 0
        case .trialExpiring: return 1
        case .annualConversion: return 2
        case .upgradeToElite: return 3
        case .upsell: return 4
        }
    }

    static func < (lhs: MonetizationPromptType, rhs: MonetizationPromptType) -> Bool {
        lhs.priority < rhs.priority
    }
}

// MARK: - Monetization Coordinator

/// Singleton coordinator that prevents conflicting monetization prompts
/// and evaluates the highest-priority monetization opportunity.
///
/// ## Priority Order
/// 1. Winback (churned user recovery)
/// 2. Trial expiring soon
/// 3. Annual plan conversion
/// 4. Pro to Elite upgrade path
/// 5. Contextual upsell banners
///
/// ## Usage
/// ```swift
/// await MonetizationCoordinator.shared.handleEvent(.workoutCompleted)
/// ```
@MainActor
class MonetizationCoordinator: ObservableObject {

    // MARK: - Singleton

    static let shared = MonetizationCoordinator()

    // MARK: - Published Properties

    /// The type of monetization prompt currently active, if any.
    @Published var activePromptType: MonetizationPromptType?

    /// Whether the annual plan prompt should be shown.
    @Published var showAnnualPrompt: Bool = false

    /// Whether the Pro-to-Elite upgrade view should be shown.
    @Published var showUpgradePath: Bool = false

    /// Whether the winback offer view should be shown.
    @Published var showWinbackOffer: Bool = false

    /// Whether a trial-expiring banner should be shown.
    @Published var showTrialExpiring: Bool = false

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let storeKit = StoreKitService.shared
    private let winbackService = WinbackService.shared
    private let upsellService = UpsellService.shared

    /// Debounce guard to prevent rapid re-evaluation.
    private var lastEvaluationDate: Date?
    private let evaluationCooldown: TimeInterval = 5.0

    /// UserDefaults keys
    private enum Keys {
        static let monthlySubscriptionStartDate = "monetization_monthly_start_date"
        static let annualPromptLastShown = "monetization_annual_prompt_last_shown"
        static let annualPromptDismissCount = "monetization_annual_prompt_dismiss_count"
        static let upgradePathLastShown = "monetization_upgrade_path_last_shown"
    }

    // MARK: - Init

    private init() {
        logger.info("MonetizationCoordinator", "Initialized")
    }

    // MARK: - Event Handling

    /// Handles a monetization-relevant event and evaluates which prompt (if any) should be shown.
    ///
    /// - Parameter event: The event that occurred.
    func handleEvent(_ event: MonetizationEvent) async {
        logger.info("MonetizationCoordinator", "Handling event: \(event.rawValue)")

        // Map events to upsell triggers for the UpsellService.
        switch event {
        case .featureLimitHit:
            upsellService.checkUpsellOpportunity(trigger: .featureLimitReached)
        case .aiUsageLimitHit:
            upsellService.checkUpsellOpportunity(trigger: .aiUsageLimit)
        case .analyticsViewed:
            upsellService.checkUpsellOpportunity(trigger: .analyticsPreview)
        case .exportAttempted:
            upsellService.checkUpsellOpportunity(trigger: .exportAttempt)
        case .personalRecord, .streakMilestone:
            upsellService.checkUpsellOpportunity(trigger: .workoutMilestone)
        default:
            break
        }

        // Full evaluation on app launch and session start.
        if event == .appLaunch || event == .sessionStart {
            await evaluateMonetizationOpportunity()
        }

        // Annual prompt on positive moments.
        if event == .personalRecord || event == .streakMilestone || event == .workoutCompleted {
            evaluateAnnualPrompt()
        }
    }

    // MARK: - Full Evaluation

    /// Evaluates all monetization opportunities in priority order and activates
    /// the highest-priority prompt that applies.
    func evaluateMonetizationOpportunity() async {
        // Debounce rapid calls.
        if let last = lastEvaluationDate, Date().timeIntervalSince(last) < evaluationCooldown {
            logger.diagnostic("MonetizationCoordinator: Evaluation debounced")
            return
        }
        lastEvaluationDate = Date()

        logger.info("MonetizationCoordinator", "Evaluating monetization opportunities")

        // Priority 1: Winback
        if await evaluateWinback() {
            return
        }

        // Priority 2: Trial expiring
        if evaluateTrialExpiring() {
            return
        }

        // Priority 3: Annual conversion
        if evaluateAnnualConversion() {
            return
        }

        // Priority 4: Pro to Elite upgrade
        if evaluateUpgradeToElite() {
            return
        }

        // Priority 5: Contextual upsells are handled event-by-event in handleEvent(_:)

        logger.info("MonetizationCoordinator", "No monetization prompt needed at this time")
    }

    // MARK: - Individual Evaluations

    /// Checks winback eligibility for churned users.
    private func evaluateWinback() async -> Bool {
        await winbackService.checkWinbackEligibility()

        if winbackService.winbackOffer != nil {
            setActivePrompt(.winback)
            showWinbackOffer = true
            logger.success("MonetizationCoordinator", "Winback offer activated")
            return true
        }
        return false
    }

    /// Checks if the user's trial is expiring within 48 hours.
    private func evaluateTrialExpiring() -> Bool {
        guard storeKit.isInTrialPeriod,
              let expiration = storeKit.subscriptionExpirationDate else {
            return false
        }

        let hoursUntilExpiry = expiration.timeIntervalSince(Date()) / 3600
        if hoursUntilExpiry > 0 && hoursUntilExpiry <= 48 {
            setActivePrompt(.trialExpiring)
            showTrialExpiring = true
            logger.info("MonetizationCoordinator", "Trial expiring in \(Int(hoursUntilExpiry))h — prompt activated")
            return true
        }
        return false
    }

    /// Checks if a monthly subscriber should be prompted to switch to annual.
    private func evaluateAnnualConversion() -> Bool {
        guard storeKit.currentTier != .free else { return false }

        // Only for monthly subscribers.
        let isMonthly = storeKit.purchasedProductIDs.contains(Config.Subscription.monthlyProductID)
            || storeKit.purchasedProductIDs.contains(SubscriptionTier.elite.monthlyProductId ?? "")
        guard isMonthly else { return false }

        // Must have been subscribed monthly for 2+ months.
        if let startDate = UserDefaults.standard.object(forKey: Keys.monthlySubscriptionStartDate) as? Date {
            let monthsSubscribed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0
            guard monthsSubscribed >= 2 else { return false }
        } else {
            // First time we see a monthly subscriber — record now, don't prompt yet.
            UserDefaults.standard.set(Date(), forKey: Keys.monthlySubscriptionStartDate)
            return false
        }

        // Throttle: max once per 14 days.
        if let lastShown = UserDefaults.standard.object(forKey: Keys.annualPromptLastShown) as? Date,
           Date().timeIntervalSince(lastShown) < 14 * 24 * 60 * 60 {
            return false
        }

        // Max 5 total dismissals.
        let dismissCount = UserDefaults.standard.integer(forKey: Keys.annualPromptDismissCount)
        if dismissCount >= 5 {
            return false
        }

        return false // Do not auto-show; wait for a positive moment.
    }

    /// Checks if a Pro subscriber should see the Elite upgrade path.
    private func evaluateUpgradeToElite() -> Bool {
        guard storeKit.currentTier == .pro else { return false }

        // Throttle: max once per 30 days.
        if let lastShown = UserDefaults.standard.object(forKey: Keys.upgradePathLastShown) as? Date,
           Date().timeIntervalSince(lastShown) < 30 * 24 * 60 * 60 {
            return false
        }

        // Don't auto-trigger on launch; this is presented via menu or positive moment.
        return false
    }

    // MARK: - Annual Prompt (Positive Moment)

    /// Evaluates whether an annual conversion prompt should be shown
    /// after a positive moment (workout completed, PR achieved, streak milestone).
    func evaluateAnnualPrompt() {
        guard activePromptType == nil else { return }

        let isMonthly = storeKit.purchasedProductIDs.contains(Config.Subscription.monthlyProductID)
            || storeKit.purchasedProductIDs.contains(SubscriptionTier.elite.monthlyProductId ?? "")
        guard isMonthly else { return }

        // Must have been subscribed 2+ months.
        if let startDate = UserDefaults.standard.object(forKey: Keys.monthlySubscriptionStartDate) as? Date {
            let monthsSubscribed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0
            guard monthsSubscribed >= 2 else { return }
        } else {
            UserDefaults.standard.set(Date(), forKey: Keys.monthlySubscriptionStartDate)
            return
        }

        // Throttle.
        if let lastShown = UserDefaults.standard.object(forKey: Keys.annualPromptLastShown) as? Date,
           Date().timeIntervalSince(lastShown) < 14 * 24 * 60 * 60 {
            return
        }

        let dismissCount = UserDefaults.standard.integer(forKey: Keys.annualPromptDismissCount)
        if dismissCount >= 5 { return }

        setActivePrompt(.annualConversion)
        showAnnualPrompt = true
        UserDefaults.standard.set(Date(), forKey: Keys.annualPromptLastShown)
        logger.success("MonetizationCoordinator", "Annual conversion prompt shown after positive moment")
    }

    // MARK: - Manual Triggers

    /// Manually presents the Pro-to-Elite upgrade path (e.g., from a settings button).
    func presentUpgradePath() {
        guard storeKit.currentTier == .pro else {
            logger.info("MonetizationCoordinator", "Upgrade path only available for Pro users")
            return
        }

        setActivePrompt(.upgradeToElite)
        showUpgradePath = true
        UserDefaults.standard.set(Date(), forKey: Keys.upgradePathLastShown)
        logger.info("MonetizationCoordinator", "Upgrade path presented")
    }

    // MARK: - Dismissals

    /// Dismisses the current monetization prompt.
    func dismissActivePrompt() {
        guard let promptType = activePromptType else { return }
        logger.info("MonetizationCoordinator", "Dismissing prompt: \(promptType.rawValue)")

        switch promptType {
        case .winback:
            showWinbackOffer = false
            winbackService.dismissOffer()
        case .trialExpiring:
            showTrialExpiring = false
        case .annualConversion:
            showAnnualPrompt = false
            let count = UserDefaults.standard.integer(forKey: Keys.annualPromptDismissCount)
            UserDefaults.standard.set(count + 1, forKey: Keys.annualPromptDismissCount)
        case .upgradeToElite:
            showUpgradePath = false
        case .upsell:
            upsellService.dismissUpsell()
        }

        activePromptType = nil
    }

    // MARK: - Helpers

    /// Sets the active prompt type, blocking lower-priority prompts.
    private func setActivePrompt(_ type: MonetizationPromptType) {
        // If a higher-priority prompt is already active, don't override.
        if let current = activePromptType, current < type {
            logger.info("MonetizationCoordinator", "Skipping \(type.rawValue) — \(current.rawValue) already active")
            return
        }
        activePromptType = type
    }

    /// Records the monthly subscription start date when the user first subscribes monthly.
    func recordMonthlySubscriptionStart() {
        if UserDefaults.standard.object(forKey: Keys.monthlySubscriptionStartDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.monthlySubscriptionStartDate)
            logger.info("MonetizationCoordinator", "Monthly subscription start date recorded")
        }
    }
}
