//
//  SubscriptionTier.swift
//  PTPerformance
//
//  ACP-986: Subscription Tier Architecture
//  Defines Free/Pro/Elite tiers with feature gating for the Modus app.
//

import Foundation

// MARK: - Subscription Tier

/// The three subscription tiers available in the Modus app.
///
/// Each tier unlocks progressively more features. The tier hierarchy is:
/// `.free` < `.pro` < `.elite`
///
/// ## Product IDs
/// Product IDs are derived from `Config.Subscription` to ensure consistency
/// with App Store Connect configuration. Pro maps to the existing monthly/annual
/// premium subscription; Elite adds a new tier above Pro.
///
/// ## Feature Gating
/// Use `hasAccess(to:)` to check whether a tier grants access to a specific feature.
/// The `SubscriptionManager` provides a convenient `canAccess(_:)` that checks
/// against the user's current tier.
///
/// ## Usage
/// ```swift
/// let tier = SubscriptionTier.pro
/// if tier.hasAccess(to: .advancedAnalytics) {
///     // Show analytics
/// }
/// ```
enum SubscriptionTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case free = "free"
    case pro = "pro"
    case elite = "elite"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable name for the tier
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .elite: return "Elite"
        }
    }

    /// Short description of the tier
    var tierDescription: String {
        switch self {
        case .free:
            return "Basic workout tracking and exercise library"
        case .pro:
            return "Full access to analytics, AI coaching, and nutrition"
        case .elite:
            return "Everything in Pro plus telehealth, custom programs, and priority support"
        }
    }

    /// SF Symbol icon for the tier
    var icon: String {
        switch self {
        case .free: return "person.fill"
        case .pro: return "star.fill"
        case .elite: return "crown.fill"
        }
    }

    /// Tier badge color name for UI rendering
    var badgeColorName: String {
        switch self {
        case .free: return "gray"
        case .pro: return "modusCyan"
        case .elite: return "purple"
        }
    }

    // MARK: - Product IDs

    /// The monthly subscription product ID for this tier, if applicable.
    /// Free tier returns nil since no purchase is required.
    var monthlyProductId: String? {
        switch self {
        case .free: return nil
        case .pro: return Config.Subscription.monthlyProductID
        case .elite: return "com.getmodus.app.elite.monthly"
        }
    }

    /// The annual subscription product ID for this tier, if applicable.
    /// Free tier returns nil since no purchase is required.
    var annualProductId: String? {
        switch self {
        case .free: return nil
        case .pro: return Config.Subscription.annualProductID
        case .elite: return "com.getmodus.app.elite.annual"
        }
    }

    /// All product IDs associated with this tier
    var productIds: [String] {
        [monthlyProductId, annualProductId].compactMap { $0 }
    }

    /// All product IDs across all paid tiers
    static var allPaidProductIds: Set<String> {
        var ids = Set<String>()
        for tier in Self.allCases where tier != .free {
            ids.formUnion(tier.productIds)
        }
        return ids
    }

    // MARK: - Price Display

    /// Display price string for monthly billing
    var monthlyPriceDisplay: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$9.99/mo"
        case .elite: return "$24.99/mo"
        }
    }

    /// Display price string for annual billing
    var annualPriceDisplay: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$59.99/yr"
        case .elite: return "$199.99/yr"
        }
    }

    /// Savings description for annual billing compared to monthly
    var annualSavingsDisplay: String? {
        switch self {
        case .free: return nil
        case .pro: return "Save 50%"
        case .elite: return "Save 33%"
        }
    }

    // MARK: - Tier Hierarchy

    /// Numeric level for tier comparison (higher is better)
    var level: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .elite: return 2
        }
    }

    /// Returns true if this tier is at least as high as the specified tier
    func isAtLeast(_ tier: SubscriptionTier) -> Bool {
        self.level >= tier.level
    }

    // MARK: - Feature Access

    /// The set of features available at this tier
    var features: Set<Feature> {
        switch self {
        case .free:
            return [
                .basicWorkouts,
                .exerciseLibrary,
                .limitedHistory
            ]
        case .pro:
            return [
                .basicWorkouts,
                .exerciseLibrary,
                .limitedHistory,
                .unlimitedWorkouts,
                .advancedAnalytics,
                .aiCoaching,
                .nutritionTracking,
                .readinessScoring,
                .learnContent,
                .workoutHistory
            ]
        case .elite:
            return [
                .basicWorkouts,
                .exerciseLibrary,
                .limitedHistory,
                .unlimitedWorkouts,
                .advancedAnalytics,
                .aiCoaching,
                .nutritionTracking,
                .readinessScoring,
                .learnContent,
                .workoutHistory,
                .customPrograms,
                .telehealth,
                .prioritySupport,
                .exportData,
                .wearableIntegration
            ]
        }
    }

    /// Check if this tier grants access to a specific feature
    ///
    /// - Parameter feature: The feature to check
    /// - Returns: True if this tier includes the specified feature
    func hasAccess(to feature: Feature) -> Bool {
        features.contains(feature)
    }

    /// Returns the minimum tier required to access a given feature
    static func minimumTier(for feature: Feature) -> SubscriptionTier {
        for tier in [SubscriptionTier.free, .pro, .elite] {
            if tier.hasAccess(to: feature) {
                return tier
            }
        }
        return .elite
    }

    /// Determine tier from a set of purchased product IDs
    static func from(purchasedProductIDs: Set<String>) -> SubscriptionTier {
        // Check Elite first (highest tier)
        let eliteTier = SubscriptionTier.elite
        if !eliteTier.productIds.filter({ purchasedProductIDs.contains($0) }).isEmpty {
            return .elite
        }

        // Check Pro
        let proTier = SubscriptionTier.pro
        if !proTier.productIds.filter({ purchasedProductIDs.contains($0) }).isEmpty {
            return .pro
        }

        return .free
    }
}

// MARK: - Feature Enum

extension SubscriptionTier {

    /// Individual features that can be gated by subscription tier.
    ///
    /// Each feature maps to a specific capability in the app. Use
    /// `SubscriptionTier.hasAccess(to:)` or `SubscriptionManager.canAccess(_:)`
    /// to check access at runtime.
    enum Feature: String, Codable, CaseIterable, Identifiable, Sendable {
        // Free tier features
        case basicWorkouts = "basic_workouts"
        case exerciseLibrary = "exercise_library"
        case limitedHistory = "limited_history"

        // Pro tier features
        case unlimitedWorkouts = "unlimited_workouts"
        case advancedAnalytics = "advanced_analytics"
        case aiCoaching = "ai_coaching"
        case nutritionTracking = "nutrition_tracking"
        case readinessScoring = "readiness_scoring"
        case learnContent = "learn_content"
        case workoutHistory = "workout_history"

        // Elite tier features
        case customPrograms = "custom_programs"
        case telehealth = "telehealth"
        case prioritySupport = "priority_support"
        case exportData = "export_data"
        case wearableIntegration = "wearable_integration"

        var id: String { rawValue }

        /// Human-readable feature name
        var displayName: String {
            switch self {
            case .basicWorkouts: return "Basic Workouts"
            case .exerciseLibrary: return "Exercise Library"
            case .limitedHistory: return "Limited History"
            case .unlimitedWorkouts: return "Unlimited Workouts"
            case .advancedAnalytics: return "Advanced Analytics"
            case .aiCoaching: return "AI Coaching"
            case .nutritionTracking: return "Nutrition Tracking"
            case .readinessScoring: return "Readiness Scoring"
            case .learnContent: return "Learn Content"
            case .workoutHistory: return "Full Workout History"
            case .customPrograms: return "Custom Programs"
            case .telehealth: return "Telehealth"
            case .prioritySupport: return "Priority Support"
            case .exportData: return "Data Export"
            case .wearableIntegration: return "Wearable Integration"
            }
        }

        /// Short description of the feature
        var featureDescription: String {
            switch self {
            case .basicWorkouts: return "Follow guided workout sessions"
            case .exerciseLibrary: return "Browse the full exercise database"
            case .limitedHistory: return "View your last 7 days of workouts"
            case .unlimitedWorkouts: return "Create and track unlimited workout sessions"
            case .advancedAnalytics: return "Detailed performance trends and insights"
            case .aiCoaching: return "Personalized AI-powered coaching and recommendations"
            case .nutritionTracking: return "Meal plans, food logging, and nutrition guidance"
            case .readinessScoring: return "Daily readiness check-ins and recovery scoring"
            case .learnContent: return "Educational guides and technique tutorials"
            case .workoutHistory: return "Complete workout history with no time limit"
            case .customPrograms: return "Build and share custom training programs"
            case .telehealth: return "Video consultations with your therapist"
            case .prioritySupport: return "Priority customer support and faster response times"
            case .exportData: return "Export all your data in multiple formats"
            case .wearableIntegration: return "Connect and sync with fitness wearables"
            }
        }

        /// SF Symbol icon for the feature
        var icon: String {
            switch self {
            case .basicWorkouts: return "figure.strengthtraining.traditional"
            case .exerciseLibrary: return "books.vertical.fill"
            case .limitedHistory: return "clock.fill"
            case .unlimitedWorkouts: return "infinity"
            case .advancedAnalytics: return "chart.bar.fill"
            case .aiCoaching: return "brain.head.profile"
            case .nutritionTracking: return "fork.knife"
            case .readinessScoring: return "battery.100"
            case .learnContent: return "book.fill"
            case .workoutHistory: return "clock.arrow.circlepath"
            case .customPrograms: return "doc.badge.plus"
            case .telehealth: return "video.fill"
            case .prioritySupport: return "headphones"
            case .exportData: return "square.and.arrow.up.fill"
            case .wearableIntegration: return "applewatch"
            }
        }
    }
}

// MARK: - Comparable

extension SubscriptionTier: Comparable {
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.level < rhs.level
    }
}
