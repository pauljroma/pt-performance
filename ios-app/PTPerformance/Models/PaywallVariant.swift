//
//  PaywallVariant.swift
//  PTPerformance
//
//  ACP-990 / ACP-991: Paywall configuration model for context-aware triggers and A/B testable designs.
//

import Foundation
import SwiftUI

// MARK: - Paywall Trigger

/// Context in which a paywall is presented to the user.
/// Each trigger maps to a unique entry point in the app flow, enabling
/// per-trigger analytics, variant selection, and cooldown logic.
enum PaywallTrigger: String, Codable, CaseIterable, Sendable {
    /// Shown during post-signup onboarding flow
    case onboarding
    /// Shown when user taps a premium-gated feature
    case featureGate
    /// Shown after N free sessions to encourage conversion
    case sessionLimit
    /// Shown when the user's trial is about to expire
    case trialExpiring
    /// Shown to lapsed subscribers as a re-engagement prompt
    case winback
    /// Shown to monthly subscribers to encourage annual upgrade
    case upgrade

    /// Human-readable title used in analytics dashboards
    var analyticsName: String {
        switch self {
        case .onboarding:    return "onboarding"
        case .featureGate:   return "feature_gate"
        case .sessionLimit:  return "session_limit"
        case .trialExpiring: return "trial_expiring"
        case .winback:       return "winback"
        case .upgrade:       return "upgrade"
        }
    }
}

// MARK: - Paywall Layout

/// Visual layout template for paywall rendering.
/// Each layout has a dedicated SwiftUI view that interprets the PaywallVariant data.
enum PaywallLayout: String, Codable, CaseIterable, Sendable {
    /// Default vertical layout with feature list and pricing cards
    case standard
    /// Side-by-side tier comparison table (Free / Pro / Elite)
    case comparison
    /// Trial-focused layout with timeline and single CTA
    case trial
    /// Minimal layout for quick upsell prompts
    case minimal
}

// MARK: - Paywall Variant

/// Complete configuration for a single paywall presentation.
/// Supports A/B testing by varying copy, layout, and CTA styling per variant.
struct PaywallVariant: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let features: [PaywallFeature]
    let ctaText: String
    let ctaColorHex: String
    let layout: PaywallLayout
    let showTrial: Bool
    let variantName: String

    /// Resolved CTA color from the hex string (non-codable convenience)
    var ctaColor: Color {
        Color(hex: ctaColorHex) ?? .modusCyan
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        features: [PaywallFeature],
        ctaText: String,
        ctaColorHex: String = "0891B2",
        layout: PaywallLayout = .standard,
        showTrial: Bool = false,
        variantName: String = "control"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.ctaText = ctaText
        self.ctaColorHex = ctaColorHex
        self.layout = layout
        self.showTrial = showTrial
        self.variantName = variantName
    }
}

// MARK: - Paywall Feature

/// A single feature bullet point displayed in the paywall feature list.
struct PaywallFeature: Identifiable, Codable, Sendable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String?

    init(id: String = UUID().uuidString, icon: String, title: String, subtitle: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Paywall Impression Record

/// Analytics record for a single paywall impression / interaction.
struct PaywallImpression: Codable, Sendable {
    let trigger: PaywallTrigger
    let variantId: String
    let variantName: String
    let layout: PaywallLayout
    let timestamp: Date
    let action: PaywallAction

    enum PaywallAction: String, Codable, Sendable {
        case impression
        case conversion
        case dismissal
    }
}

// MARK: - Comparison Tier

/// A tier displayed in the comparison paywall layout (Free / Pro / Elite).
struct ComparisonTier: Identifiable, Sendable {
    let id: String
    let name: String
    let price: String
    let badge: String?
    let features: [ComparisonFeatureRow]
    let isHighlighted: Bool
    let ctaText: String

    init(
        id: String = UUID().uuidString,
        name: String,
        price: String,
        badge: String? = nil,
        features: [ComparisonFeatureRow],
        isHighlighted: Bool = false,
        ctaText: String
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.badge = badge
        self.features = features
        self.isHighlighted = isHighlighted
        self.ctaText = ctaText
    }
}

/// A single row in the comparison table showing feature availability across tiers.
struct ComparisonFeatureRow: Identifiable, Sendable {
    let id: String
    let featureName: String
    let freeIncluded: Bool
    let proIncluded: Bool
    let eliteIncluded: Bool

    init(
        id: String = UUID().uuidString,
        featureName: String,
        freeIncluded: Bool,
        proIncluded: Bool,
        eliteIncluded: Bool
    ) {
        self.id = id
        self.featureName = featureName
        self.freeIncluded = freeIncluded
        self.proIncluded = proIncluded
        self.eliteIncluded = eliteIncluded
    }
}

// MARK: - Default Variants

extension PaywallVariant {

    /// Default premium features list shared across variants
    static let defaultFeatures: [PaywallFeature] = [
        PaywallFeature(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", subtitle: "Track progress with detailed charts and trends"),
        PaywallFeature(icon: "brain.head.profile", title: "AI Coach", subtitle: "Personalized training recommendations powered by AI"),
        PaywallFeature(icon: "fork.knife", title: "Nutrition Tracking", subtitle: "Log meals, track macros, and get meal plans"),
        PaywallFeature(icon: "heart.text.square", title: "Readiness Scores", subtitle: "Daily readiness checks with HRV and recovery data"),
        PaywallFeature(icon: "clock.arrow.circlepath", title: "Workout History", subtitle: "Complete session history with performance insights"),
        PaywallFeature(icon: "graduationcap", title: "Learn Library", subtitle: "Evidence-based educational content")
    ]

    /// Default variant for the onboarding trigger
    static let onboardingDefault = PaywallVariant(
        title: "Welcome to Korza",
        subtitle: "Start your free trial and unlock your full potential",
        features: defaultFeatures,
        ctaText: "Start Free Trial",
        layout: .trial,
        showTrial: true,
        variantName: "onboarding_trial"
    )

    /// Default variant for feature gate triggers
    static let featureGateDefault = PaywallVariant(
        title: "Unlock This Feature",
        subtitle: "Upgrade to Premium to access advanced tools and insights",
        features: defaultFeatures,
        ctaText: "Upgrade to Premium",
        layout: .standard,
        showTrial: false,
        variantName: "feature_gate_standard"
    )

    /// Default variant for session limit triggers
    static let sessionLimitDefault = PaywallVariant(
        title: "You've Used Your Free Sessions",
        subtitle: "Upgrade for unlimited sessions and full access to all features",
        features: defaultFeatures,
        ctaText: "Continue with Premium",
        layout: .comparison,
        showTrial: true,
        variantName: "session_limit_comparison"
    )

    /// Default variant for trial expiring triggers
    static let trialExpiringDefault = PaywallVariant(
        title: "Your Trial Ends Soon",
        subtitle: "Subscribe now to keep your streak and all your data",
        features: defaultFeatures,
        ctaText: "Subscribe Now",
        ctaColorHex: "E65100",
        layout: .standard,
        showTrial: false,
        variantName: "trial_expiring_urgent"
    )

    /// Default variant for winback triggers
    static let winbackDefault = PaywallVariant(
        title: "We Miss You!",
        subtitle: "Come back and pick up where you left off with Premium",
        features: defaultFeatures,
        ctaText: "Reactivate Premium",
        layout: .standard,
        showTrial: true,
        variantName: "winback_standard"
    )

    /// Default variant for upgrade triggers (monthly -> annual)
    static let upgradeDefault = PaywallVariant(
        title: "Save with Annual",
        subtitle: "Switch to annual billing and save over 40% per year",
        features: defaultFeatures,
        ctaText: "Switch to Annual",
        layout: .standard,
        showTrial: false,
        variantName: "upgrade_annual"
    )

    /// Returns the default variant for a given trigger type
    static func defaultVariant(for trigger: PaywallTrigger) -> PaywallVariant {
        switch trigger {
        case .onboarding:    return onboardingDefault
        case .featureGate:   return featureGateDefault
        case .sessionLimit:  return sessionLimitDefault
        case .trialExpiring: return trialExpiringDefault
        case .winback:       return winbackDefault
        case .upgrade:       return upgradeDefault
        }
    }
}

// MARK: - Default Comparison Data

extension ComparisonTier {

    static let defaultTiers: [ComparisonTier] = [
        ComparisonTier(
            name: "Free",
            price: "$0",
            features: ComparisonFeatureRow.defaultRows,
            ctaText: "Current Plan"
        ),
        ComparisonTier(
            name: "Pro",
            price: "$9.99/mo",
            badge: "Most Popular",
            features: ComparisonFeatureRow.defaultRows,
            isHighlighted: true,
            ctaText: "Start Free Trial"
        ),
        ComparisonTier(
            name: "Elite",
            price: "$59.99/yr",
            badge: "Best Value",
            features: ComparisonFeatureRow.defaultRows,
            ctaText: "Save 50%"
        )
    ]
}

extension ComparisonFeatureRow {

    static let defaultRows: [ComparisonFeatureRow] = [
        ComparisonFeatureRow(featureName: "Workout Logging", freeIncluded: true, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Basic Programs", freeIncluded: true, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Workout History", freeIncluded: false, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Advanced Analytics", freeIncluded: false, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "AI Coach", freeIncluded: false, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Nutrition Tracking", freeIncluded: false, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Readiness Scores", freeIncluded: false, proIncluded: true, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Priority Support", freeIncluded: false, proIncluded: false, eliteIncluded: true),
        ComparisonFeatureRow(featureName: "Early Access Features", freeIncluded: false, proIncluded: false, eliteIncluded: true)
    ]
}
