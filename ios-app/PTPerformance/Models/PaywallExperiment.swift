//
//  PaywallExperiment.swift
//  PTPerformance
//
//  ACP-973: Paywall Experimentation Models
//  Defines experiment configurations, variant definitions, performance metrics,
//  and conversion data structures for paywall A/B testing.
//

import Foundation

// MARK: - Paywall Experiment Layout

/// Extended layout variants for paywall experimentation.
/// These supplement the existing `PaywallLayout` with experiment-specific layouts
/// that test different persuasion strategies.
enum PaywallExperimentLayout: String, Codable, CaseIterable, Sendable {
    /// Condensed layout with pricing up front, minimal scrolling required
    case compact
    /// Full-detail layout with feature explanations, testimonials, and FAQ
    case detailed
    /// Layout emphasising social proof: user counts, ratings, testimonials
    case socialProof = "social_proof"
    /// Scarcity/urgency layout with countdown timers and limited-time offers
    case urgency
}

// MARK: - Pricing Display Order

/// Controls which billing period is presented first/prominently on the paywall.
/// Used for pricing display experiments to measure which ordering drives higher LTV.
enum PricingDisplayOrder: String, Codable, CaseIterable, Sendable {
    /// Monthly plan shown first / highlighted (lower commitment)
    case monthlyFirst = "monthly_first"
    /// Annual plan shown first / highlighted (higher LTV)
    case annualFirst = "annual_first"
}

// MARK: - Paywall Dismiss Reason

/// Captures why the user dismissed the paywall without converting.
/// Enables analysis of drop-off reasons per variant and trigger.
enum PaywallDismissReason: String, Codable, CaseIterable, Sendable {
    /// User tapped the X / close button
    case closeTapped = "close_tapped"
    /// User swiped down to dismiss the sheet
    case swipedDown = "swiped_down"
    /// User tapped outside the paywall (background dismiss)
    case backgroundTap = "background_tap"
    /// User pressed the hardware back button
    case backButton = "back_button"
    /// User navigated away (app backgrounded, deep link, etc.)
    case navigatedAway = "navigated_away"
    /// Paywall was programmatically dismissed (timeout, state change, etc.)
    case programmatic
    /// Dismiss reason could not be determined
    case unknown
}

// MARK: - Paywall Experiment Definition

/// Defines a complete paywall experiment with control and treatment variants.
///
/// An experiment represents a single A/B (or A/B/C/D) test that runs for a defined
/// period. Each experiment has a unique key used for assignment persistence and
/// analytics attribution.
///
/// ## Example
/// ```swift
/// let experiment = PaywallExperiment(
///     key: "q1_2026_layout_test",
///     name: "Q1 2026 Layout Test",
///     variants: [layoutControlVariant, compactVariant, socialProofVariant],
///     triggers: [.featureGate, .sessionLimit],
///     startDate: Date(),
///     endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!
/// )
/// ```
struct PaywallExperiment: Identifiable, Codable, Sendable {
    /// Unique identifier for the experiment
    let id: String
    /// Machine-readable key used for UserDefaults persistence and analytics (e.g. "q1_2026_layout_test")
    let key: String
    /// Human-readable name for dashboards
    let name: String
    /// Description of the hypothesis being tested
    let hypothesis: String
    /// The experiment variants including the control
    let variants: [PaywallExperimentVariant]
    /// Which triggers this experiment applies to (empty = all triggers)
    let triggers: [PaywallTrigger]
    /// When the experiment starts accepting new assignments
    let startDate: Date
    /// When the experiment stops accepting new assignments (existing assignments persist)
    let endDate: Date
    /// Whether the experiment is currently active (manual kill switch)
    let isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        key: String,
        name: String,
        hypothesis: String = "",
        variants: [PaywallExperimentVariant],
        triggers: [PaywallTrigger] = [],
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.hypothesis = hypothesis
        self.variants = variants
        self.triggers = triggers
        self.startDate = startDate
        self.endDate = endDate
        self.isEnabled = isEnabled
    }

    /// Whether this experiment is currently running (enabled, within date range)
    var isActive: Bool {
        let now = Date()
        return isEnabled && now >= startDate && now <= endDate
    }

    /// Whether this experiment applies to a given trigger
    func appliesTo(trigger: PaywallTrigger) -> Bool {
        triggers.isEmpty || triggers.contains(trigger)
    }
}

// MARK: - Experiment Variant

/// A single variant within an experiment, carrying its own layout config,
/// pricing order, and traffic weight.
///
/// The `weight` field controls traffic allocation. For example, three variants
/// with weights [50, 25, 25] allocate 50% to the first and 25% each to the others.
struct PaywallExperimentVariant: Identifiable, Codable, Sendable {
    /// Unique identifier
    let id: String
    /// Machine-readable variant name (e.g. "control", "compact_annual_first")
    let variantName: String
    /// Human-readable label for dashboards
    let displayName: String
    /// Whether this is the control (baseline) variant
    let isControl: Bool
    /// The experiment layout to use
    let experimentLayout: PaywallExperimentLayout
    /// Pricing display order for this variant
    let pricingOrder: PricingDisplayOrder
    /// Traffic allocation weight (relative to other variants in the experiment)
    let weight: Int
    /// The underlying PaywallVariant configuration to render
    let paywallVariant: PaywallVariant

    init(
        id: String = UUID().uuidString,
        variantName: String,
        displayName: String = "",
        isControl: Bool = false,
        experimentLayout: PaywallExperimentLayout = .compact,
        pricingOrder: PricingDisplayOrder = .annualFirst,
        weight: Int = 1,
        paywallVariant: PaywallVariant
    ) {
        self.id = id
        self.variantName = variantName
        self.displayName = displayName.isEmpty ? variantName : displayName
        self.isControl = isControl
        self.experimentLayout = experimentLayout
        self.pricingOrder = pricingOrder
        self.weight = weight
        self.paywallVariant = paywallVariant
    }
}

// MARK: - Variant Assignment

/// Records which variant a user was assigned for a given experiment.
/// Persisted to ensure the user always sees the same variant.
struct VariantAssignment: Codable, Sendable {
    /// The experiment key this assignment belongs to
    let experimentKey: String
    /// The assigned variant name
    let variantName: String
    /// When the assignment was made
    let assignedAt: Date
    /// The trigger context at the time of assignment
    let trigger: PaywallTrigger
}

// MARK: - Paywall Interaction Event

/// A detailed interaction event recorded during a paywall session.
/// Captures the full context needed for experiment performance analysis.
struct PaywallInteractionEvent: Codable, Sendable {

    /// The type of interaction
    enum InteractionType: String, Codable, Sendable {
        /// Paywall was displayed to the user
        case impression
        /// User tapped the primary CTA button
        case ctaTap = "cta_tap"
        /// User tapped a secondary CTA (e.g. "See all plans")
        case secondaryCtaTap = "secondary_cta_tap"
        /// User toggled between monthly/annual pricing
        case pricingToggle = "pricing_toggle"
        /// User scrolled the paywall content
        case scroll
        /// User tapped to expand a feature detail
        case featureExpand = "feature_expand"
        /// User tapped "Restore Purchases"
        case restoreTap = "restore_tap"
        /// User tapped terms/privacy links
        case legalTap = "legal_tap"
        /// Purchase flow was initiated (StoreKit dialog shown)
        case purchaseInitiated = "purchase_initiated"
        /// Purchase completed successfully
        case purchaseCompleted = "purchase_completed"
        /// Purchase failed or was cancelled
        case purchaseFailed = "purchase_failed"
        /// User dismissed the paywall
        case dismissal
    }

    /// Unique event ID
    let id: String
    /// Experiment key (nil if no experiment is active)
    let experimentKey: String?
    /// The variant name shown to the user
    let variantName: String
    /// The experiment layout used
    let experimentLayout: PaywallExperimentLayout?
    /// The pricing display order used
    let pricingOrder: PricingDisplayOrder?
    /// The trigger that caused the paywall
    let trigger: PaywallTrigger
    /// The type of interaction
    let interactionType: InteractionType
    /// When the event occurred
    let timestamp: Date
    /// Time elapsed since the paywall impression (seconds)
    let timeOnPaywall: TimeInterval
    /// Scroll depth as a percentage (0.0 to 1.0), nil for non-scroll events
    let scrollDepth: Double?
    /// The dismiss reason, populated only for dismissal events
    let dismissReason: PaywallDismissReason?
    /// The selected pricing period at the time of the event (nil if not applicable)
    let selectedPricingPeriod: String?
    /// The subscription tier involved (nil if not applicable)
    let selectedTier: String?

    init(
        id: String = UUID().uuidString,
        experimentKey: String? = nil,
        variantName: String,
        experimentLayout: PaywallExperimentLayout? = nil,
        pricingOrder: PricingDisplayOrder? = nil,
        trigger: PaywallTrigger,
        interactionType: InteractionType,
        timestamp: Date = Date(),
        timeOnPaywall: TimeInterval = 0,
        scrollDepth: Double? = nil,
        dismissReason: PaywallDismissReason? = nil,
        selectedPricingPeriod: String? = nil,
        selectedTier: String? = nil
    ) {
        self.id = id
        self.experimentKey = experimentKey
        self.variantName = variantName
        self.experimentLayout = experimentLayout
        self.pricingOrder = pricingOrder
        self.trigger = trigger
        self.interactionType = interactionType
        self.timestamp = timestamp
        self.timeOnPaywall = timeOnPaywall
        self.scrollDepth = scrollDepth
        self.dismissReason = dismissReason
        self.selectedPricingPeriod = selectedPricingPeriod
        self.selectedTier = selectedTier
    }
}

// MARK: - Paywall Session Metrics

/// Aggregated metrics for a single paywall session (from impression to dismiss/convert).
/// Created when the paywall is dismissed or a purchase completes.
struct PaywallSessionMetrics: Codable, Sendable {
    /// Unique session ID
    let sessionId: String
    /// Experiment key (nil if no experiment active)
    let experimentKey: String?
    /// Variant shown
    let variantName: String
    /// Experiment layout used
    let experimentLayout: PaywallExperimentLayout?
    /// Pricing order used
    let pricingOrder: PricingDisplayOrder?
    /// Trigger context
    let trigger: PaywallTrigger
    /// When the paywall was shown
    let impressionTimestamp: Date
    /// Total time the paywall was visible (seconds)
    let totalViewDuration: TimeInterval
    /// Maximum scroll depth reached (0.0 to 1.0)
    let maxScrollDepth: Double
    /// Whether the user tapped the CTA
    let didTapCTA: Bool
    /// Whether the user completed a purchase
    let didConvert: Bool
    /// Whether the user toggled pricing period
    let didTogglePricing: Bool
    /// Number of feature expands
    let featureExpandCount: Int
    /// Dismiss reason (nil if converted)
    let dismissReason: PaywallDismissReason?
    /// Revenue from this session (nil if no purchase)
    let revenue: Double?
    /// The tier purchased (nil if no purchase)
    let purchasedTier: String?

    init(
        sessionId: String = UUID().uuidString,
        experimentKey: String? = nil,
        variantName: String,
        experimentLayout: PaywallExperimentLayout? = nil,
        pricingOrder: PricingDisplayOrder? = nil,
        trigger: PaywallTrigger,
        impressionTimestamp: Date = Date(),
        totalViewDuration: TimeInterval = 0,
        maxScrollDepth: Double = 0,
        didTapCTA: Bool = false,
        didConvert: Bool = false,
        didTogglePricing: Bool = false,
        featureExpandCount: Int = 0,
        dismissReason: PaywallDismissReason? = nil,
        revenue: Double? = nil,
        purchasedTier: String? = nil
    ) {
        self.sessionId = sessionId
        self.experimentKey = experimentKey
        self.variantName = variantName
        self.experimentLayout = experimentLayout
        self.pricingOrder = pricingOrder
        self.trigger = trigger
        self.impressionTimestamp = impressionTimestamp
        self.totalViewDuration = totalViewDuration
        self.maxScrollDepth = maxScrollDepth
        self.didTapCTA = didTapCTA
        self.didConvert = didConvert
        self.didTogglePricing = didTogglePricing
        self.featureExpandCount = featureExpandCount
        self.dismissReason = dismissReason
        self.revenue = revenue
        self.purchasedTier = purchasedTier
    }
}

// MARK: - Experiment Performance Summary

/// Aggregated performance summary for an experiment variant, computed from
/// accumulated session metrics. Used for reporting and winner determination.
struct ExperimentPerformanceSummary: Sendable {
    /// Experiment key
    let experimentKey: String
    /// Variant name
    let variantName: String
    /// Whether this is the control variant
    let isControl: Bool
    /// Total number of impressions
    let impressionCount: Int
    /// Number of CTA taps
    let ctaTapCount: Int
    /// Number of completed purchases
    let conversionCount: Int
    /// Impression-to-CTA-tap rate (0.0 to 1.0)
    let ctaTapRate: Double
    /// Impression-to-purchase conversion rate (0.0 to 1.0)
    let conversionRate: Double
    /// CTA-tap-to-purchase rate (0.0 to 1.0)
    let ctaToConversionRate: Double
    /// Average time on paywall across all sessions (seconds)
    let averageViewDuration: TimeInterval
    /// Average max scroll depth across all sessions (0.0 to 1.0)
    let averageScrollDepth: Double
    /// Total revenue generated by this variant
    let totalRevenue: Double
    /// Average revenue per impression (totalRevenue / impressionCount)
    let revenuePerImpression: Double
    /// Breakdown of dismiss reasons with counts
    let dismissReasonBreakdown: [PaywallDismissReason: Int]
    /// Pricing toggle rate (how many users toggled pricing period)
    let pricingToggleRate: Double
}

// MARK: - Default Experiment Variants

extension PaywallExperimentVariant {

    /// Control variant: standard layout with annual-first pricing
    static let controlStandard = PaywallExperimentVariant(
        variantName: "control_standard",
        displayName: "Control (Standard)",
        isControl: true,
        experimentLayout: .compact,
        pricingOrder: .annualFirst,
        weight: 25,
        paywallVariant: PaywallVariant.featureGateDefault
    )

    /// Treatment A: compact layout with monthly-first pricing
    static let compactMonthlyFirst = PaywallExperimentVariant(
        variantName: "compact_monthly_first",
        displayName: "Compact + Monthly First",
        experimentLayout: .compact,
        pricingOrder: .monthlyFirst,
        weight: 25,
        paywallVariant: PaywallVariant(
            title: "Go Premium",
            subtitle: "Unlock everything starting at $9.99/month",
            features: PaywallVariant.defaultFeatures,
            ctaText: "Start Now",
            layout: .minimal,
            showTrial: true,
            variantName: "compact_monthly_first"
        )
    )

    /// Treatment B: detailed layout with social proof
    static let detailedSocialProof = PaywallExperimentVariant(
        variantName: "detailed_social_proof",
        displayName: "Detailed + Social Proof",
        experimentLayout: .socialProof,
        pricingOrder: .annualFirst,
        weight: 25,
        paywallVariant: PaywallVariant(
            title: "Join 50,000+ Athletes",
            subtitle: "See why top performers choose Korza",
            features: PaywallVariant.defaultFeatures,
            ctaText: "Join Premium",
            layout: .standard,
            showTrial: true,
            variantName: "detailed_social_proof"
        )
    )

    /// Treatment C: urgency layout with scarcity messaging
    static let urgencyScarcity = PaywallExperimentVariant(
        variantName: "urgency_scarcity",
        displayName: "Urgency + Scarcity",
        experimentLayout: .urgency,
        pricingOrder: .annualFirst,
        weight: 25,
        paywallVariant: PaywallVariant(
            title: "Limited Time Offer",
            subtitle: "Save 50% on your first year - offer ends soon",
            features: PaywallVariant.defaultFeatures,
            ctaText: "Claim Offer",
            ctaColorHex: "E65100",
            layout: .standard,
            showTrial: false,
            variantName: "urgency_scarcity"
        )
    )
}

// MARK: - Default Experiments

extension PaywallExperiment {

    /// Default layout experiment comparing compact, social-proof, and urgency layouts
    /// against the standard control.
    static let layoutExperiment = PaywallExperiment(
        key: "paywall_layout_2026_q1",
        name: "Q1 2026 Paywall Layout Test",
        hypothesis: "Social proof and urgency layouts will outperform the standard layout in conversion rate",
        variants: [
            .controlStandard,
            .compactMonthlyFirst,
            .detailedSocialProof,
            .urgencyScarcity
        ],
        triggers: [.featureGate, .sessionLimit],
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date().addingTimeInterval(30 * 24 * 60 * 60)
    )

    /// Pricing order experiment: monthly-first vs annual-first across all triggers
    static let pricingOrderExperiment = PaywallExperiment(
        key: "pricing_order_2026_q1",
        name: "Q1 2026 Pricing Order Test",
        hypothesis: "Annual-first pricing will produce higher LTV despite potentially lower initial conversion",
        variants: [
            PaywallExperimentVariant(
                variantName: "pricing_annual_first",
                displayName: "Annual First (Control)",
                isControl: true,
                experimentLayout: .compact,
                pricingOrder: .annualFirst,
                weight: 50,
                paywallVariant: PaywallVariant.featureGateDefault
            ),
            PaywallExperimentVariant(
                variantName: "pricing_monthly_first",
                displayName: "Monthly First",
                experimentLayout: .compact,
                pricingOrder: .monthlyFirst,
                weight: 50,
                paywallVariant: PaywallVariant(
                    title: "Unlock This Feature",
                    subtitle: "Start with a flexible monthly plan",
                    features: PaywallVariant.defaultFeatures,
                    ctaText: "Start Monthly",
                    layout: .standard,
                    showTrial: true,
                    variantName: "pricing_monthly_first"
                )
            )
        ],
        triggers: []
    )
}
