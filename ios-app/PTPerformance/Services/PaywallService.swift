//
//  PaywallService.swift
//  PTPerformance
//
//  ACP-990: Smart Paywall System — context-aware paywall triggers with A/B variant selection,
//  cooldown management, and analytics hooks.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Paywall Service

/// Singleton service that manages paywall triggering, variant selection,
/// analytics recording, and cooldown enforcement.
///
/// ## Usage
/// ```swift
/// PaywallService.shared.triggerPaywall(.featureGate)
/// ```
///
/// ## Architecture
/// - Observes feature usage to trigger session-limit paywalls automatically
/// - Persists A/B assignment in UserDefaults for consistent variant exposure
/// - Enforces per-trigger cooldowns to avoid spamming the user
/// - Records impression / conversion / dismissal events for analytics
@MainActor
class PaywallService: ObservableObject {

    // MARK: - Singleton

    static let shared = PaywallService()

    // MARK: - Published State

    /// Whether the paywall sheet should be presented
    @Published var shouldShowPaywall: Bool = false

    /// The currently selected variant to display
    @Published var currentVariant: PaywallVariant = .featureGateDefault

    /// The trigger that caused the current paywall presentation
    @Published var currentTrigger: PaywallTrigger = .featureGate

    // MARK: - Private Properties

    private let logger = DebugLogger.shared

    /// Tracks how many times each feature gate has been accessed in the current session
    private var featureUsageCounts: [String: Int] = [:]

    /// Set of triggers that have already been shown in this session (cooldown)
    private var triggersShownThisSession: Set<PaywallTrigger> = []

    /// Timestamps of the last paywall show per trigger for time-based cooldown
    private var lastShownTimestamps: [PaywallTrigger: Date] = [:]

    /// The impression currently being tracked (set on show, cleared on dismiss/convert)
    private var currentImpressionStart: Date?

    /// Number of free uses allowed before showing a session-limit paywall
    private let freeUsageThreshold: Int = 3

    /// Minimum seconds between showing the same trigger paywall
    private let cooldownInterval: TimeInterval = 300 // 5 minutes

    // MARK: - UserDefaults Keys

    private enum UDKeys {
        static let variantAssignmentPrefix = "paywall_variant_"
        static let totalImpressions = "paywall_total_impressions"
        static let totalConversions = "paywall_total_conversions"
        static let featureUsagePrefix = "paywall_feature_usage_"
    }

    // MARK: - Init

    private init() {
        logger.info("Paywall", "PaywallService initialized")
        loadPersistedUsageCounts()
    }

    // MARK: - Trigger Paywall

    /// Triggers the paywall with a specific context.
    ///
    /// - Parameter trigger: The context in which the paywall should appear
    ///
    /// Respects cooldown rules:
    /// 1. Same trigger is not shown more than once per session
    /// 2. A minimum interval must pass between same-trigger impressions
    /// 3. Paywall is never shown if user is already premium
    func triggerPaywall(_ trigger: PaywallTrigger) {
        logger.info("Paywall", "Trigger requested: \(trigger.analyticsName)")

        // Guard: do not show if user is premium
        guard !StoreKitService.shared.isPremium else {
            logger.diagnostic("Paywall: Skipping trigger — user is premium")
            return
        }

        // Guard: do not show if already showing a paywall
        guard !shouldShowPaywall else {
            logger.diagnostic("Paywall: Skipping trigger — paywall already visible")
            return
        }

        // Guard: cooldown — same trigger not shown more than once per session
        guard !triggersShownThisSession.contains(trigger) else {
            logger.info("Paywall", "Cooldown active (session) for trigger: \(trigger.analyticsName)")
            return
        }

        // Guard: cooldown — minimum time between same-trigger impressions
        if let lastShown = lastShownTimestamps[trigger],
           Date().timeIntervalSince(lastShown) < cooldownInterval {
            logger.info("Paywall", "Cooldown active (time) for trigger: \(trigger.analyticsName)")
            return
        }

        // Select variant (A/B logic)
        let variant = selectVariant(for: trigger)
        currentVariant = variant
        currentTrigger = trigger

        // Present
        shouldShowPaywall = true
        currentImpressionStart = Date()

        // Track cooldown
        triggersShownThisSession.insert(trigger)
        lastShownTimestamps[trigger] = Date()

        // Record impression
        recordImpression()

        logger.success("Paywall", "Showing paywall — trigger: \(trigger.analyticsName), variant: \(variant.variantName), layout: \(variant.layout.rawValue)")
        HapticFeedback.sheetPresented()
    }

    // MARK: - Feature Gate Helper

    /// Checks whether a premium feature should be gated and triggers the paywall if needed.
    ///
    /// - Parameters:
    ///   - featureKey: A unique key identifying the feature (e.g. "ai_coach", "nutrition")
    ///   - threshold: Number of free uses before gating (defaults to `freeUsageThreshold`)
    ///
    /// - Returns: `true` if the feature is accessible (user is premium or under threshold),
    ///            `false` if the paywall was triggered and the feature should not proceed.
    @discardableResult
    func checkFeatureAccess(_ featureKey: String, threshold: Int? = nil) -> Bool {
        let limit = threshold ?? freeUsageThreshold

        // Premium users always have access
        guard !StoreKitService.shared.isPremium else { return true }

        // Increment usage
        let currentCount = featureUsageCounts[featureKey, default: 0] + 1
        featureUsageCounts[featureKey] = currentCount
        persistUsageCount(featureKey, count: currentCount)

        logger.diagnostic("Paywall: Feature '\(featureKey)' usage count: \(currentCount)/\(limit)")

        if currentCount > limit {
            triggerPaywall(.featureGate)
            return false
        }

        return true
    }

    /// Records usage of a feature without triggering the gate check.
    /// Useful for tracking usage of features that you want to monitor but not gate immediately.
    func recordFeatureUsage(_ featureKey: String) {
        let currentCount = featureUsageCounts[featureKey, default: 0] + 1
        featureUsageCounts[featureKey] = currentCount
        persistUsageCount(featureKey, count: currentCount)
    }

    // MARK: - Analytics Hooks

    /// Records that the paywall was shown to the user.
    func recordImpression() {
        let impression = PaywallImpression(
            trigger: currentTrigger,
            variantId: currentVariant.id,
            variantName: currentVariant.variantName,
            layout: currentVariant.layout,
            timestamp: Date(),
            action: .impression
        )

        let total = UserDefaults.standard.integer(forKey: UDKeys.totalImpressions) + 1
        UserDefaults.standard.set(total, forKey: UDKeys.totalImpressions)

        logger.info("Paywall", "Impression #\(total) recorded — variant: \(impression.variantName), trigger: \(impression.trigger.analyticsName)")

        sendAnalyticsEvent(impression)
    }

    /// Records that the user purchased/subscribed from the paywall.
    func recordConversion() {
        let impression = PaywallImpression(
            trigger: currentTrigger,
            variantId: currentVariant.id,
            variantName: currentVariant.variantName,
            layout: currentVariant.layout,
            timestamp: Date(),
            action: .conversion
        )

        let total = UserDefaults.standard.integer(forKey: UDKeys.totalConversions) + 1
        UserDefaults.standard.set(total, forKey: UDKeys.totalConversions)

        logger.success("Paywall", "Conversion #\(total) recorded — variant: \(impression.variantName), trigger: \(impression.trigger.analyticsName)")

        sendAnalyticsEvent(impression)

        // Dismiss paywall on conversion
        dismissPaywall()
    }

    /// Records that the user dismissed the paywall without converting.
    func recordDismissal() {
        let viewDuration: TimeInterval
        if let start = currentImpressionStart {
            viewDuration = Date().timeIntervalSince(start)
        } else {
            viewDuration = 0
        }

        let impression = PaywallImpression(
            trigger: currentTrigger,
            variantId: currentVariant.id,
            variantName: currentVariant.variantName,
            layout: currentVariant.layout,
            timestamp: Date(),
            action: .dismissal
        )

        logger.info("Paywall", "Dismissal recorded — variant: \(impression.variantName), trigger: \(impression.trigger.analyticsName), viewDuration: \(String(format: "%.1f", viewDuration))s")

        sendAnalyticsEvent(impression)
    }

    /// Dismisses the paywall and clears the impression tracking state.
    func dismissPaywall() {
        shouldShowPaywall = false
        currentImpressionStart = nil
        logger.diagnostic("Paywall: Paywall dismissed")
    }

    /// Resets session cooldowns (call on app foreground or new session start).
    func resetSessionCooldowns() {
        triggersShownThisSession.removeAll()
        logger.diagnostic("Paywall: Session cooldowns reset")
    }

    // MARK: - A/B Variant Selection

    /// Selects a variant for the given trigger, using persisted assignment for consistency.
    ///
    /// Variant assignment is persisted in UserDefaults so a user always sees the same variant
    /// for a given trigger throughout their lifecycle (until the experiment is rotated).
    private func selectVariant(for trigger: PaywallTrigger) -> PaywallVariant {
        let key = UDKeys.variantAssignmentPrefix + trigger.rawValue

        // Check for persisted assignment
        if let persistedVariantName = UserDefaults.standard.string(forKey: key),
           let variant = variantPool(for: trigger).first(where: { $0.variantName == persistedVariantName }) {
            logger.diagnostic("Paywall: Using persisted variant '\(persistedVariantName)' for trigger \(trigger.analyticsName)")
            return variant
        }

        // Random assignment from the pool
        let pool = variantPool(for: trigger)
        let selected = pool.randomElement() ?? PaywallVariant.defaultVariant(for: trigger)

        // Persist assignment
        UserDefaults.standard.set(selected.variantName, forKey: key)
        logger.info("Paywall", "Assigned variant '\(selected.variantName)' for trigger \(trigger.analyticsName)")

        return selected
    }

    /// Returns the pool of available variants for a given trigger.
    /// Extend this method to add A/B variants per trigger.
    private func variantPool(for trigger: PaywallTrigger) -> [PaywallVariant] {
        switch trigger {
        case .onboarding:
            return [
                PaywallVariant.onboardingDefault,
                PaywallVariant(
                    title: "Train Smarter, Not Harder",
                    subtitle: "7 days free, then unlock your full training potential",
                    features: PaywallVariant.defaultFeatures,
                    ctaText: "Try It Free",
                    layout: .trial,
                    showTrial: true,
                    variantName: "onboarding_trial_b"
                )
            ]

        case .featureGate:
            return [
                PaywallVariant.featureGateDefault,
                PaywallVariant(
                    title: "Go Premium",
                    subtitle: "This feature is available to Premium members",
                    features: PaywallVariant.defaultFeatures,
                    ctaText: "Unlock Now",
                    layout: .minimal,
                    showTrial: true,
                    variantName: "feature_gate_minimal"
                )
            ]

        case .sessionLimit:
            return [
                PaywallVariant.sessionLimitDefault
            ]

        case .trialExpiring:
            return [
                PaywallVariant.trialExpiringDefault
            ]

        case .winback:
            return [
                PaywallVariant.winbackDefault
            ]

        case .upgrade:
            return [
                PaywallVariant.upgradeDefault
            ]
        }
    }

    // MARK: - Persistence

    /// Loads persisted feature usage counts from UserDefaults
    private func loadPersistedUsageCounts() {
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()
        let prefix = UDKeys.featureUsagePrefix

        for (key, value) in dict where key.hasPrefix(prefix) {
            let featureKey = String(key.dropFirst(prefix.count))
            if let count = value as? Int {
                featureUsageCounts[featureKey] = count
            }
        }

        logger.diagnostic("Paywall: Loaded \(featureUsageCounts.count) persisted usage counts")
    }

    /// Persists a single feature usage count
    private func persistUsageCount(_ featureKey: String, count: Int) {
        UserDefaults.standard.set(count, forKey: UDKeys.featureUsagePrefix + featureKey)
    }

    // MARK: - Analytics Dispatch

    private static let isoFormatter = ISO8601DateFormatter()

    /// Sends an analytics event to the backend (stub — wire to your analytics pipeline).
    private func sendAnalyticsEvent(_ impression: PaywallImpression) {
        // Encode to dictionary for analytics dispatch
        let payload: [String: Any] = [
            "trigger": impression.trigger.analyticsName,
            "variant_id": impression.variantId,
            "variant_name": impression.variantName,
            "layout": impression.layout.rawValue,
            "action": impression.action.rawValue,
            "timestamp": Self.isoFormatter.string(from: impression.timestamp)
        ]

        logger.diagnostic("Paywall: Analytics event dispatched — \(payload)")

        // TODO: Wire to AnalyticsTracker.shared.track("paywall_event", properties: payload)
    }
}
