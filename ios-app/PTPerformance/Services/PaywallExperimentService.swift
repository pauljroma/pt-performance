//
//  PaywallExperimentService.swift
//  PTPerformance
//
//  ACP-973: Paywall Experimentation Service
//  Manages paywall experiment lifecycle: variant assignment, interaction tracking,
//  performance metrics collection, and experiment reporting.
//
//  Integrates with PaywallService for presentation, ConversionFunnelTracker for
//  funnel attribution, and AnalyticsSDK/AnalyticsTracker for event dispatch.
//

import Foundation
import Combine

// MARK: - Paywall Experiment Service

/// Singleton service that manages paywall experimentation: variant assignment,
/// interaction event recording, session metrics aggregation, and performance reporting.
///
/// ## Architecture
/// - Variant assignments are persisted in UserDefaults for consistent user experience
/// - Interaction events are accumulated per paywall session and flushed on dismiss/convert
/// - Session metrics are persisted to disk for cross-session analysis
/// - All events are dispatched to AnalyticsTracker and ConversionFunnelTracker
///
/// ## Usage
/// ```swift
/// // Get the assigned variant for a trigger
/// let variant = PaywallExperimentService.shared.assignedVariant(for: .featureGate)
///
/// // Record interactions during paywall session
/// PaywallExperimentService.shared.recordImpression(trigger: .featureGate)
/// PaywallExperimentService.shared.recordCTATap()
/// PaywallExperimentService.shared.recordScrollDepth(0.75)
/// PaywallExperimentService.shared.recordDismissal(reason: .closeTapped)
///
/// // Get performance summary
/// let summaries = PaywallExperimentService.shared.getPerformanceSummaries(for: "paywall_layout_2026_q1")
/// ```
@MainActor
class PaywallExperimentService: ObservableObject {

    // MARK: - Singleton

    static let shared = PaywallExperimentService()

    // MARK: - Published State

    /// The currently active experiment (nil if no experiment applies)
    @Published private(set) var activeExperiment: PaywallExperiment?

    /// The currently assigned variant for the active paywall session
    @Published private(set) var activeVariant: PaywallExperimentVariant?

    /// Whether an experiment paywall session is currently in progress
    @Published private(set) var isSessionActive: Bool = false

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    /// All registered experiments
    private var experiments: [PaywallExperiment] = []

    /// Persisted variant assignments keyed by experiment key
    private var assignments: [String: VariantAssignment] = [:]

    /// Interaction events for the current paywall session
    private var currentSessionEvents: [PaywallInteractionEvent] = []

    /// Timestamp of the current session's impression
    private var currentSessionImpressionTime: Date?

    /// The trigger for the current session
    private var currentSessionTrigger: PaywallTrigger?

    /// Maximum scroll depth tracked during the current session
    private var currentSessionMaxScrollDepth: Double = 0

    /// Whether the user tapped the CTA during the current session
    private var currentSessionDidTapCTA: Bool = false

    /// Whether the user toggled pricing during the current session
    private var currentSessionDidTogglePricing: Bool = false

    /// Number of feature expands during the current session
    private var currentSessionFeatureExpandCount: Int = 0

    /// All persisted session metrics for reporting
    private var sessionMetrics: [PaywallSessionMetrics] = []

    // MARK: - Persistence

    private enum UDKeys {
        static let assignmentPrefix = "paywall_experiment_assignment_"
        static let experimentsRegistered = "paywall_experiments_registered"
    }

    private let metricsFileURL: URL = {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("paywall_experiment_metrics.json")
        }
        let appDirectory = directory.appendingPathComponent("PTPerformance", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.appendingPathComponent("paywall_experiment_metrics.json")
    }()

    private nonisolated static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private nonisolated static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {
        logger.info("PaywallExperiment", "PaywallExperimentService initialized")
        loadPersistedAssignments()
        loadPersistedMetrics()
        registerDefaultExperiments()
    }

    // MARK: - Experiment Registration

    /// Registers an experiment for evaluation. Experiments are checked in order;
    /// the first active experiment matching the trigger is used.
    ///
    /// - Parameter experiment: The experiment to register
    func registerExperiment(_ experiment: PaywallExperiment) {
        // Replace existing experiment with the same key
        experiments.removeAll { $0.key == experiment.key }
        experiments.append(experiment)
        logger.info("PaywallExperiment", "Registered experiment '\(experiment.key)' with \(experiment.variants.count) variants")
    }

    /// Removes a registered experiment by key.
    ///
    /// - Parameter key: The experiment key to remove
    func removeExperiment(key: String) {
        experiments.removeAll { $0.key == key }
        logger.info("PaywallExperiment", "Removed experiment '\(key)'")
    }

    /// Returns all currently registered experiments.
    func registeredExperiments() -> [PaywallExperiment] {
        return experiments
    }

    // MARK: - Variant Assignment

    /// Returns the assigned experiment variant for a given trigger, creating
    /// a new assignment if one does not already exist.
    ///
    /// The first active experiment matching the trigger is selected. If no experiment
    /// is active, returns nil and the caller should fall back to default PaywallService behavior.
    ///
    /// - Parameter trigger: The paywall trigger context
    /// - Returns: The assigned experiment variant, or nil if no experiment applies
    func assignedVariant(for trigger: PaywallTrigger) -> PaywallExperimentVariant? {
        // Find the first active experiment that applies to this trigger
        guard let experiment = experiments.first(where: { $0.isActive && $0.appliesTo(trigger: trigger) }) else {
            logger.diagnostic("PaywallExperiment: No active experiment for trigger '\(trigger.analyticsName)'")
            return nil
        }

        activeExperiment = experiment

        // Check for existing persisted assignment
        if let existing = assignments[experiment.key],
           let variant = experiment.variants.first(where: { $0.variantName == existing.variantName }) {
            logger.diagnostic("PaywallExperiment: Using persisted assignment '\(existing.variantName)' for experiment '\(experiment.key)'")
            activeVariant = variant
            return variant
        }

        // Create new weighted random assignment
        let variant = weightedRandomVariant(from: experiment.variants)
        let assignment = VariantAssignment(
            experimentKey: experiment.key,
            variantName: variant.variantName,
            assignedAt: Date(),
            trigger: trigger
        )

        assignments[experiment.key] = assignment
        persistAssignment(assignment)

        activeVariant = variant
        logger.info("PaywallExperiment", "Assigned variant '\(variant.variantName)' for experiment '\(experiment.key)' (trigger: \(trigger.analyticsName))")

        return variant
    }

    /// Returns the current variant assignment for an experiment without creating a new one.
    ///
    /// - Parameter experimentKey: The experiment key to look up
    /// - Returns: The persisted assignment, or nil if the user has not been assigned
    func currentAssignment(for experimentKey: String) -> VariantAssignment? {
        return assignments[experimentKey]
    }

    // MARK: - Session Lifecycle

    /// Starts a new paywall experiment session and records the impression.
    ///
    /// Call this when the paywall is displayed. If no experiment is active for the
    /// trigger, the session is tracked without experiment attribution.
    ///
    /// - Parameter trigger: The trigger that caused the paywall presentation
    func recordImpression(trigger: PaywallTrigger) {
        // Reset session state
        currentSessionEvents.removeAll()
        currentSessionImpressionTime = Date()
        currentSessionTrigger = trigger
        currentSessionMaxScrollDepth = 0
        currentSessionDidTapCTA = false
        currentSessionDidTogglePricing = false
        currentSessionFeatureExpandCount = 0
        isSessionActive = true

        let variant = activeVariant
        let experiment = activeExperiment

        let event = PaywallInteractionEvent(
            experimentKey: experiment?.key,
            variantName: variant?.variantName ?? "no_experiment",
            experimentLayout: variant?.experimentLayout,
            pricingOrder: variant?.pricingOrder,
            trigger: trigger,
            interactionType: .impression,
            timeOnPaywall: 0
        )

        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        logger.info("PaywallExperiment", "Session started — experiment: \(experiment?.key ?? "none"), variant: \(variant?.variantName ?? "none"), trigger: \(trigger.analyticsName)")
    }

    /// Records that the user tapped the primary CTA button.
    func recordCTATap() {
        guard isSessionActive else { return }
        currentSessionDidTapCTA = true

        let event = makeEvent(interactionType: .ctaTap)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        logger.info("PaywallExperiment", "CTA tap recorded — variant: \(activeVariant?.variantName ?? "none")")
    }

    /// Records that the user tapped a secondary CTA.
    func recordSecondaryCtaTap() {
        guard isSessionActive else { return }

        let event = makeEvent(interactionType: .secondaryCtaTap)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)
    }

    /// Records a scroll depth update during the paywall session.
    ///
    /// - Parameter depth: The current scroll depth as a percentage (0.0 to 1.0)
    func recordScrollDepth(_ depth: Double) {
        guard isSessionActive else { return }
        let clampedDepth = min(max(depth, 0.0), 1.0)
        currentSessionMaxScrollDepth = max(currentSessionMaxScrollDepth, clampedDepth)

        let event = makeEvent(interactionType: .scroll, scrollDepth: clampedDepth)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)
    }

    /// Records that the user toggled the pricing period (monthly/annual).
    ///
    /// - Parameter selectedPeriod: The pricing period the user selected (e.g. "monthly", "annual")
    func recordPricingToggle(selectedPeriod: String) {
        guard isSessionActive else { return }
        currentSessionDidTogglePricing = true

        let event = makeEvent(interactionType: .pricingToggle, selectedPricingPeriod: selectedPeriod)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        logger.info("PaywallExperiment", "Pricing toggle — selected: \(selectedPeriod)")
    }

    /// Records that the user expanded a feature detail.
    func recordFeatureExpand() {
        guard isSessionActive else { return }
        currentSessionFeatureExpandCount += 1

        let event = makeEvent(interactionType: .featureExpand)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)
    }

    /// Records that the user tapped "Restore Purchases".
    func recordRestoreTap() {
        guard isSessionActive else { return }

        let event = makeEvent(interactionType: .restoreTap)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)
    }

    /// Records that the user tapped a legal link (terms/privacy).
    func recordLegalTap() {
        guard isSessionActive else { return }

        let event = makeEvent(interactionType: .legalTap)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)
    }

    /// Records that a purchase flow was initiated (StoreKit dialog shown).
    ///
    /// - Parameters:
    ///   - tier: The subscription tier being purchased
    ///   - period: The billing period selected (e.g. "monthly", "annual")
    func recordPurchaseInitiated(tier: String, period: String) {
        guard isSessionActive else { return }

        let event = makeEvent(
            interactionType: .purchaseInitiated,
            selectedPricingPeriod: period,
            selectedTier: tier
        )
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        // Forward to conversion funnel
        let triggerSource = currentSessionTrigger?.analyticsName ?? "unknown"
        let variantName = activeVariant?.variantName ?? "no_experiment"
        Task {
            await ConversionFunnelTracker.shared.recordStage(
                .purchaseInitiated,
                source: triggerSource,
                tier: tier,
                revenue: nil,
                paywallVariant: variantName
            )
        }

        logger.info("PaywallExperiment", "Purchase initiated — tier: \(tier), period: \(period)")
    }

    /// Records a completed purchase and finalizes the session metrics.
    ///
    /// - Parameters:
    ///   - tier: The subscription tier purchased
    ///   - period: The billing period purchased
    ///   - revenue: The revenue amount in dollars
    func recordPurchaseCompleted(tier: String, period: String, revenue: Double) {
        guard isSessionActive else { return }

        let event = makeEvent(
            interactionType: .purchaseCompleted,
            selectedPricingPeriod: period,
            selectedTier: tier
        )
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        // Finalize session with conversion
        finalizeSession(didConvert: true, dismissReason: nil, revenue: revenue, purchasedTier: tier)

        logger.success("PaywallExperiment", "Purchase completed — tier: \(tier), period: \(period), revenue: $\(String(format: "%.2f", revenue))")
    }

    /// Records a failed or cancelled purchase.
    ///
    /// - Parameter reason: Description of the failure (e.g. "user_cancelled", "payment_failed")
    func recordPurchaseFailed(reason: String) {
        guard isSessionActive else { return }

        let event = makeEvent(interactionType: .purchaseFailed)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        logger.info("PaywallExperiment", "Purchase failed — reason: \(reason)")
    }

    /// Records that the user dismissed the paywall and finalizes the session.
    ///
    /// - Parameter reason: Why the user dismissed the paywall
    func recordDismissal(reason: PaywallDismissReason) {
        guard isSessionActive else { return }

        let event = makeEvent(interactionType: .dismissal, dismissReason: reason)
        currentSessionEvents.append(event)
        dispatchInteractionEvent(event)

        // Finalize session without conversion
        finalizeSession(didConvert: false, dismissReason: reason, revenue: nil, purchasedTier: nil)

        logger.info("PaywallExperiment", "Dismissal recorded — reason: \(reason.rawValue), scrollDepth: \(String(format: "%.0f%%", currentSessionMaxScrollDepth * 100))")
    }

    // MARK: - Performance Reporting

    /// Returns performance summaries for all variants in the specified experiment.
    ///
    /// Aggregates session metrics into per-variant summaries including conversion rates,
    /// average view durations, scroll depths, and revenue metrics.
    ///
    /// - Parameter experimentKey: The experiment to generate summaries for
    /// - Returns: Array of performance summaries, one per variant
    func getPerformanceSummaries(for experimentKey: String) -> [ExperimentPerformanceSummary] {
        guard let experiment = experiments.first(where: { $0.key == experimentKey }) else {
            logger.warning("PaywallExperiment", "Experiment '\(experimentKey)' not found for reporting")
            return []
        }

        var summaries: [ExperimentPerformanceSummary] = []

        for variant in experiment.variants {
            let variantMetrics = sessionMetrics.filter {
                $0.experimentKey == experimentKey && $0.variantName == variant.variantName
            }

            let impressionCount = variantMetrics.count
            let ctaTapCount = variantMetrics.filter { $0.didTapCTA }.count
            let conversionCount = variantMetrics.filter { $0.didConvert }.count
            let pricingToggleCount = variantMetrics.filter { $0.didTogglePricing }.count

            let totalRevenue = variantMetrics.compactMap { $0.revenue }.reduce(0, +)
            let avgDuration = impressionCount > 0
                ? variantMetrics.map { $0.totalViewDuration }.reduce(0, +) / Double(impressionCount)
                : 0
            let avgScrollDepth = impressionCount > 0
                ? variantMetrics.map { $0.maxScrollDepth }.reduce(0, +) / Double(impressionCount)
                : 0

            // Dismiss reason breakdown
            var dismissBreakdown: [PaywallDismissReason: Int] = [:]
            for metric in variantMetrics {
                if let reason = metric.dismissReason {
                    dismissBreakdown[reason, default: 0] += 1
                }
            }

            let summary = ExperimentPerformanceSummary(
                experimentKey: experimentKey,
                variantName: variant.variantName,
                isControl: variant.isControl,
                impressionCount: impressionCount,
                ctaTapCount: ctaTapCount,
                conversionCount: conversionCount,
                ctaTapRate: impressionCount > 0 ? Double(ctaTapCount) / Double(impressionCount) : 0,
                conversionRate: impressionCount > 0 ? Double(conversionCount) / Double(impressionCount) : 0,
                ctaToConversionRate: ctaTapCount > 0 ? Double(conversionCount) / Double(ctaTapCount) : 0,
                averageViewDuration: avgDuration,
                averageScrollDepth: avgScrollDepth,
                totalRevenue: totalRevenue,
                revenuePerImpression: impressionCount > 0 ? totalRevenue / Double(impressionCount) : 0,
                dismissReasonBreakdown: dismissBreakdown,
                pricingToggleRate: impressionCount > 0 ? Double(pricingToggleCount) / Double(impressionCount) : 0
            )

            summaries.append(summary)
        }

        logger.info("PaywallExperiment", "Generated \(summaries.count) performance summaries for experiment '\(experimentKey)'")
        return summaries
    }

    /// Generates a formatted text report for an experiment.
    ///
    /// - Parameter experimentKey: The experiment to report on
    /// - Returns: A multi-line formatted string with variant performance data
    func getExperimentReport(for experimentKey: String) -> String {
        let summaries = getPerformanceSummaries(for: experimentKey)
        guard let experiment = experiments.first(where: { $0.key == experimentKey }) else {
            return "Experiment '\(experimentKey)' not found."
        }

        var lines: [String] = []
        lines.append("=== Paywall Experiment Report ===")
        lines.append("Experiment: \(experiment.name)")
        lines.append("Key: \(experiment.key)")
        lines.append("Hypothesis: \(experiment.hypothesis)")
        lines.append("Status: \(experiment.isActive ? "Active" : "Inactive")")
        lines.append("Period: \(Self.reportDateFormatter.string(from: experiment.startDate)) - \(Self.reportDateFormatter.string(from: experiment.endDate))")
        lines.append("")

        for summary in summaries {
            let controlLabel = summary.isControl ? " (CONTROL)" : ""
            lines.append("--- Variant: \(summary.variantName)\(controlLabel) ---")
            lines.append("  Impressions: \(summary.impressionCount)")
            lines.append("  CTA Taps: \(summary.ctaTapCount) (\(String(format: "%.1f%%", summary.ctaTapRate * 100)))")
            lines.append("  Conversions: \(summary.conversionCount) (\(String(format: "%.1f%%", summary.conversionRate * 100)))")
            lines.append("  CTA->Convert: \(String(format: "%.1f%%", summary.ctaToConversionRate * 100))")
            lines.append("  Avg View Duration: \(String(format: "%.1fs", summary.averageViewDuration))")
            lines.append("  Avg Scroll Depth: \(String(format: "%.0f%%", summary.averageScrollDepth * 100))")
            lines.append("  Total Revenue: \(String(format: "$%.2f", summary.totalRevenue))")
            lines.append("  Revenue/Impression: \(String(format: "$%.4f", summary.revenuePerImpression))")
            lines.append("  Pricing Toggle Rate: \(String(format: "%.1f%%", summary.pricingToggleRate * 100))")

            if !summary.dismissReasonBreakdown.isEmpty {
                lines.append("  Dismiss Reasons:")
                let sorted = summary.dismissReasonBreakdown.sorted { $0.value > $1.value }
                for (reason, count) in sorted {
                    lines.append("    \(reason.rawValue): \(count)")
                }
            }
            lines.append("")
        }

        // Winner determination (highest conversion rate with at least 30 impressions)
        let qualifiedSummaries = summaries.filter { $0.impressionCount >= 30 }
        if let winner = qualifiedSummaries.max(by: { $0.conversionRate < $1.conversionRate }),
           let control = qualifiedSummaries.first(where: { $0.isControl }) {
            let lift = control.conversionRate > 0
                ? ((winner.conversionRate - control.conversionRate) / control.conversionRate) * 100
                : 0
            lines.append("--- Winner (by conversion rate, min 30 impressions) ---")
            lines.append("  \(winner.variantName): \(String(format: "%.1f%%", winner.conversionRate * 100)) conversion rate")
            if !winner.isControl {
                lines.append("  Lift over control: \(String(format: "%+.1f%%", lift))")
            } else {
                lines.append("  Control is currently winning")
            }
        } else {
            lines.append("--- Winner: Insufficient data (need 30+ impressions per variant) ---")
        }

        lines.append("================================")
        return lines.joined(separator: "\n")
    }

    /// Resets all experiment data. Use with caution (intended for debug/testing).
    func resetAllExperimentData() {
        assignments.removeAll()
        sessionMetrics.removeAll()
        currentSessionEvents.removeAll()
        isSessionActive = false
        activeExperiment = nil
        activeVariant = nil

        // Clear persisted assignments
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix(UDKeys.assignmentPrefix) {
            defaults.removeObject(forKey: key)
        }

        // Clear persisted metrics
        try? FileManager.default.removeItem(at: metricsFileURL)

        logger.warning("PaywallExperiment", "All experiment data reset")
    }

    // MARK: - Private Helpers

    /// Selects a variant using weighted random assignment.
    private func weightedRandomVariant(from variants: [PaywallExperimentVariant]) -> PaywallExperimentVariant {
        let totalWeight = variants.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return variants.first ?? PaywallExperimentVariant.controlStandard
        }

        var randomValue = Int.random(in: 0..<totalWeight)
        for variant in variants {
            randomValue -= variant.weight
            if randomValue < 0 {
                return variant
            }
        }

        return variants.last ?? PaywallExperimentVariant.controlStandard
    }

    /// Creates a PaywallInteractionEvent with current session context.
    private func makeEvent(
        interactionType: PaywallInteractionEvent.InteractionType,
        scrollDepth: Double? = nil,
        dismissReason: PaywallDismissReason? = nil,
        selectedPricingPeriod: String? = nil,
        selectedTier: String? = nil
    ) -> PaywallInteractionEvent {
        let timeOnPaywall: TimeInterval
        if let start = currentSessionImpressionTime {
            timeOnPaywall = Date().timeIntervalSince(start)
        } else {
            timeOnPaywall = 0
        }

        return PaywallInteractionEvent(
            experimentKey: activeExperiment?.key,
            variantName: activeVariant?.variantName ?? "no_experiment",
            experimentLayout: activeVariant?.experimentLayout,
            pricingOrder: activeVariant?.pricingOrder,
            trigger: currentSessionTrigger ?? .featureGate,
            interactionType: interactionType,
            timeOnPaywall: timeOnPaywall,
            scrollDepth: scrollDepth,
            dismissReason: dismissReason,
            selectedPricingPeriod: selectedPricingPeriod,
            selectedTier: selectedTier
        )
    }

    /// Finalizes the current session by computing aggregated metrics and persisting them.
    private func finalizeSession(
        didConvert: Bool,
        dismissReason: PaywallDismissReason?,
        revenue: Double?,
        purchasedTier: String?
    ) {
        let viewDuration: TimeInterval
        if let start = currentSessionImpressionTime {
            viewDuration = Date().timeIntervalSince(start)
        } else {
            viewDuration = 0
        }

        let metrics = PaywallSessionMetrics(
            experimentKey: activeExperiment?.key,
            variantName: activeVariant?.variantName ?? "no_experiment",
            experimentLayout: activeVariant?.experimentLayout,
            pricingOrder: activeVariant?.pricingOrder,
            trigger: currentSessionTrigger ?? .featureGate,
            impressionTimestamp: currentSessionImpressionTime ?? Date(),
            totalViewDuration: viewDuration,
            maxScrollDepth: currentSessionMaxScrollDepth,
            didTapCTA: currentSessionDidTapCTA,
            didConvert: didConvert,
            didTogglePricing: currentSessionDidTogglePricing,
            featureExpandCount: currentSessionFeatureExpandCount,
            dismissReason: dismissReason,
            revenue: revenue,
            purchasedTier: purchasedTier
        )

        sessionMetrics.append(metrics)
        persistMetrics()

        // Dispatch aggregated session event to analytics
        dispatchSessionMetrics(metrics)

        // Clear session state
        isSessionActive = false
        currentSessionEvents.removeAll()
        currentSessionImpressionTime = nil
        currentSessionTrigger = nil
        currentSessionMaxScrollDepth = 0
        currentSessionDidTapCTA = false
        currentSessionDidTogglePricing = false
        currentSessionFeatureExpandCount = 0

        logger.info("PaywallExperiment", "Session finalized — converted: \(didConvert), duration: \(String(format: "%.1fs", viewDuration)), scrollDepth: \(String(format: "%.0f%%", metrics.maxScrollDepth * 100))")
    }

    // MARK: - Analytics Dispatch

    /// Dispatches an individual interaction event to the analytics pipeline.
    private func dispatchInteractionEvent(_ event: PaywallInteractionEvent) {
        var properties: [String: Any] = [
            "interaction_type": event.interactionType.rawValue,
            "variant_name": event.variantName,
            "trigger": event.trigger.analyticsName,
            "time_on_paywall": String(format: "%.1f", event.timeOnPaywall)
        ]

        if let experimentKey = event.experimentKey {
            properties["experiment_key"] = experimentKey
        }
        if let layout = event.experimentLayout {
            properties["experiment_layout"] = layout.rawValue
        }
        if let pricingOrder = event.pricingOrder {
            properties["pricing_order"] = pricingOrder.rawValue
        }
        if let scrollDepth = event.scrollDepth {
            properties["scroll_depth"] = String(format: "%.2f", scrollDepth)
        }
        if let dismissReason = event.dismissReason {
            properties["dismiss_reason"] = dismissReason.rawValue
        }
        if let period = event.selectedPricingPeriod {
            properties["selected_pricing_period"] = period
        }
        if let tier = event.selectedTier {
            properties["selected_tier"] = tier
        }

        analyticsTracker.track(event: "paywall_experiment_interaction", properties: properties)
    }

    /// Dispatches aggregated session metrics to analytics and conversion funnel.
    private func dispatchSessionMetrics(_ metrics: PaywallSessionMetrics) {
        var properties: [String: Any] = [
            "session_id": metrics.sessionId,
            "variant_name": metrics.variantName,
            "trigger": metrics.trigger.analyticsName,
            "total_view_duration": String(format: "%.1f", metrics.totalViewDuration),
            "max_scroll_depth": String(format: "%.2f", metrics.maxScrollDepth),
            "did_tap_cta": metrics.didTapCTA,
            "did_convert": metrics.didConvert,
            "did_toggle_pricing": metrics.didTogglePricing,
            "feature_expand_count": metrics.featureExpandCount
        ]

        if let experimentKey = metrics.experimentKey {
            properties["experiment_key"] = experimentKey
        }
        if let layout = metrics.experimentLayout {
            properties["experiment_layout"] = layout.rawValue
        }
        if let pricingOrder = metrics.pricingOrder {
            properties["pricing_order"] = pricingOrder.rawValue
        }
        if let dismissReason = metrics.dismissReason {
            properties["dismiss_reason"] = dismissReason.rawValue
        }
        if let revenue = metrics.revenue {
            properties["revenue"] = String(format: "%.2f", revenue)
        }
        if let tier = metrics.purchasedTier {
            properties["purchased_tier"] = tier
        }

        analyticsTracker.track(event: "paywall_experiment_session", properties: properties)

        // Forward session outcome to ConversionFunnelTracker
        let source = metrics.trigger.analyticsName
        let variantName = metrics.variantName
        let revenue = metrics.revenue
        let tier = metrics.purchasedTier

        if metrics.didConvert {
            Task {
                await ConversionFunnelTracker.shared.recordStage(
                    .purchaseCompleted,
                    source: source,
                    tier: tier,
                    revenue: revenue,
                    paywallVariant: variantName
                )
            }
        } else if metrics.didTapCTA {
            Task {
                await ConversionFunnelTracker.shared.recordStage(
                    .paywallEngaged,
                    source: source,
                    tier: nil,
                    revenue: nil,
                    paywallVariant: variantName
                )
            }
        }
    }

    // MARK: - Persistence: Assignments

    /// Loads all persisted variant assignments from UserDefaults.
    private func loadPersistedAssignments() {
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()
        let prefix = UDKeys.assignmentPrefix

        for (key, value) in dict where key.hasPrefix(prefix) {
            guard let data = (value as? String)?.data(using: .utf8) else { continue }
            if let assignment = try? Self.jsonDecoder.decode(VariantAssignment.self, from: data) {
                assignments[assignment.experimentKey] = assignment
            }
        }

        logger.diagnostic("PaywallExperiment: Loaded \(assignments.count) persisted assignments")
    }

    /// Persists a variant assignment to UserDefaults.
    private func persistAssignment(_ assignment: VariantAssignment) {
        guard let data = try? Self.jsonEncoder.encode(assignment),
              let jsonString = String(data: data, encoding: .utf8) else {
            logger.warning("PaywallExperiment", "Failed to encode assignment for '\(assignment.experimentKey)'")
            return
        }

        UserDefaults.standard.set(jsonString, forKey: UDKeys.assignmentPrefix + assignment.experimentKey)
    }

    // MARK: - Persistence: Metrics

    /// Persists session metrics to disk.
    private func persistMetrics() {
        do {
            let data = try Self.jsonEncoder.encode(sessionMetrics)
            try data.write(to: metricsFileURL, options: .atomic)
            logger.diagnostic("PaywallExperiment: Persisted \(sessionMetrics.count) session metrics to disk")
        } catch {
            logger.warning("PaywallExperiment", "Failed to persist session metrics: \(error.localizedDescription)")
        }
    }

    /// Loads previously persisted session metrics from disk.
    private func loadPersistedMetrics() {
        guard FileManager.default.fileExists(atPath: metricsFileURL.path) else {
            logger.diagnostic("PaywallExperiment: No persisted metrics file found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: metricsFileURL)
            let loaded = try Self.jsonDecoder.decode([PaywallSessionMetrics].self, from: data)
            sessionMetrics = loaded
            logger.info("PaywallExperiment", "Loaded \(loaded.count) persisted session metrics")
        } catch {
            logger.warning("PaywallExperiment", "Failed to load persisted metrics: \(error.localizedDescription)")
        }
    }

    // MARK: - Default Experiments

    /// Registers the default built-in experiments.
    private func registerDefaultExperiments() {
        registerExperiment(PaywallExperiment.layoutExperiment)
        registerExperiment(PaywallExperiment.pricingOrderExperiment)
        logger.info("PaywallExperiment", "Registered \(experiments.count) default experiments")
    }

    // MARK: - Formatters

    private nonisolated static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
