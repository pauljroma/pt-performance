//
//  SubscriptionAnalytics.swift
//  PTPerformance
//
//  ACP-989: Subscription Analytics Dashboard
//  ACP-988: Pricing Experimentation
//  Data models for subscription metrics, revenue tracking, churn, and conversion analytics
//

import Foundation

// MARK: - Subscription Metrics

/// Aggregate subscription metrics for the analytics dashboard
struct SubscriptionMetrics: Codable, Equatable {
    /// Monthly Recurring Revenue in dollars
    let mrr: Double

    /// Annual Recurring Revenue in dollars
    let arr: Double

    /// Total number of active subscribers
    let totalSubscribers: Int

    /// Number of users currently in a trial period
    let activeTrials: Int

    /// Monthly churn rate as a percentage (0-100)
    let churnRate: Double

    /// Trial-to-paid conversion rate as a percentage (0-100)
    let conversionRate: Double

    /// Average Revenue Per User per month
    let avgRevenuePerUser: Double

    /// Estimated Lifetime Value per subscriber
    let ltv: Double

    // MARK: - Computed Properties

    var formattedMRR: String {
        formatCurrency(mrr)
    }

    var formattedARR: String {
        formatCurrency(arr)
    }

    var formattedARPU: String {
        formatCurrency(avgRevenuePerUser)
    }

    var formattedLTV: String {
        formatCurrency(ltv)
    }

    var formattedChurnRate: String {
        String(format: "%.1f%%", churnRate)
    }

    var formattedConversionRate: String {
        String(format: "%.1f%%", conversionRate)
    }

    /// MRR trend direction based on churn vs conversion health
    var mrrTrend: MetricTrend {
        if churnRate < 3.0 && conversionRate > 50.0 {
            return .up
        } else if churnRate > 8.0 || conversionRate < 20.0 {
            return .down
        }
        return .flat
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case mrr
        case arr
        case totalSubscribers = "total_subscribers"
        case activeTrials = "active_trials"
        case churnRate = "churn_rate"
        case conversionRate = "conversion_rate"
        case avgRevenuePerUser = "avg_revenue_per_user"
        case ltv
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Metric Trend

/// Direction indicator for metric trends
enum MetricTrend: String, Codable {
    case up
    case down
    case flat

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    var isPositive: Bool {
        self == .up
    }
}

// MARK: - Revenue Data Point

/// A single data point for revenue charting over time
struct RevenueDataPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let revenue: Double
    let subscribers: Int

    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: revenue)) ?? "$\(Int(revenue))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case revenue
        case subscribers
    }
}

// MARK: - Churn Event

/// Records a subscriber cancellation or churn event
struct ChurnEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: String
    let date: Date
    let reason: ChurnReason
    let tier: SubscriptionTier
    let duration: Int // days subscribed before churning

    /// Formatted duration as a human-readable string
    var formattedDuration: String {
        if duration < 30 {
            return "\(duration)d"
        } else if duration < 365 {
            let months = duration / 30
            return "\(months)mo"
        } else {
            let years = duration / 365
            let remainingMonths = (duration % 365) / 30
            return remainingMonths > 0 ? "\(years)y \(remainingMonths)mo" : "\(years)y"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case reason
        case tier
        case duration
    }
}

// MARK: - Churn Reason

/// Categorized reasons why a subscriber churned
enum ChurnReason: String, Codable, CaseIterable {
    case tooExpensive = "too_expensive"
    case notUsing = "not_using"
    case missingFeatures = "missing_features"
    case switchedCompetitor = "switched_competitor"
    case technicalIssues = "technical_issues"
    case trialExpired = "trial_expired"
    case involuntary = "involuntary" // payment failure
    case other = "other"

    var displayName: String {
        switch self {
        case .tooExpensive: return "Too Expensive"
        case .notUsing: return "Not Using"
        case .missingFeatures: return "Missing Features"
        case .switchedCompetitor: return "Switched Competitor"
        case .technicalIssues: return "Technical Issues"
        case .trialExpired: return "Trial Expired"
        case .involuntary: return "Payment Failed"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .tooExpensive: return "dollarsign.circle"
        case .notUsing: return "moon.zzz"
        case .missingFeatures: return "puzzlepiece"
        case .switchedCompetitor: return "arrow.left.arrow.right"
        case .technicalIssues: return "exclamationmark.triangle"
        case .trialExpired: return "clock.badge.xmark"
        case .involuntary: return "creditcard.trianglebadge.exclamationmark"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Conversion Event

/// Records a subscription tier change (upgrade, downgrade, or trial conversion)
struct ConversionEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: String
    let date: Date
    let fromTier: SubscriptionTier
    let toTier: SubscriptionTier
    let trigger: ConversionTrigger
    let variant: String? // pricing experiment variant ID, if applicable

    /// Whether this event represents an upgrade
    var isUpgrade: Bool {
        toTier.level > fromTier.level
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case fromTier = "from_tier"
        case toTier = "to_tier"
        case trigger
        case variant
    }
}

// MARK: - Conversion Trigger

/// What triggered a tier conversion
enum ConversionTrigger: String, Codable, CaseIterable {
    case organicUpgrade = "organic_upgrade"
    case trialConversion = "trial_conversion"
    case promotionalOffer = "promotional_offer"
    case featureGate = "feature_gate"
    case paywallPresentation = "paywall_presentation"
    case pushNotification = "push_notification"
    case inAppMessage = "in_app_message"

    var displayName: String {
        switch self {
        case .organicUpgrade: return "Organic"
        case .trialConversion: return "Trial Conversion"
        case .promotionalOffer: return "Promo Offer"
        case .featureGate: return "Feature Gate"
        case .paywallPresentation: return "Paywall"
        case .pushNotification: return "Push"
        case .inAppMessage: return "In-App Message"
        }
    }
}

// MARK: - Subscription Event

/// Types of subscription lifecycle events for tracking
enum SubscriptionEventType: String, Codable, CaseIterable {
    case purchase = "purchase"
    case renewal = "renewal"
    case cancellation = "cancellation"
    case trialStart = "trial_start"
    case trialConvert = "trial_convert"
    case trialExpire = "trial_expire"

    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .renewal: return "Renewal"
        case .cancellation: return "Cancellation"
        case .trialStart: return "Trial Started"
        case .trialConvert: return "Trial Converted"
        case .trialExpire: return "Trial Expired"
        }
    }
}

/// A subscription lifecycle event for recording and analytics
struct SubscriptionEvent: Codable, Identifiable {
    let id: UUID
    let userId: String
    let type: SubscriptionEventType
    let tier: SubscriptionTier
    let revenue: Double
    let timestamp: Date
    let metadata: [String: String]?

    init(
        id: UUID = UUID(),
        userId: String,
        type: SubscriptionEventType,
        tier: SubscriptionTier,
        revenue: Double = 0,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.tier = tier
        self.revenue = revenue
        self.timestamp = timestamp
        self.metadata = metadata
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case tier
        case revenue
        case timestamp
        case metadata
    }
}

// MARK: - Date Range

/// Predefined date ranges for analytics queries
enum AnalyticsDateRange: String, CaseIterable, Identifiable {
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case ninetyDays = "90d"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .ninetyDays: return "90 Days"
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension SubscriptionMetrics {
    static var sample: SubscriptionMetrics {
        SubscriptionMetrics(
            mrr: 24_850.00,
            arr: 298_200.00,
            totalSubscribers: 312,
            activeTrials: 47,
            churnRate: 4.2,
            conversionRate: 62.5,
            avgRevenuePerUser: 79.65,
            ltv: 1_135.00
        )
    }

    static var empty: SubscriptionMetrics {
        SubscriptionMetrics(
            mrr: 0,
            arr: 0,
            totalSubscribers: 0,
            activeTrials: 0,
            churnRate: 0,
            conversionRate: 0,
            avgRevenuePerUser: 0,
            ltv: 0
        )
    }
}

extension RevenueDataPoint {
    static var sampleHistory: [RevenueDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let baseRevenue = 800.0
            let trend = Double(30 - daysAgo) * 5.0
            let noise = Double.random(in: -50...50)
            return RevenueDataPoint(
                id: UUID(),
                date: date,
                revenue: baseRevenue + trend + noise,
                subscribers: 280 + (30 - daysAgo)
            )
        }
    }
}

extension ChurnEvent {
    static var sampleList: [ChurnEvent] {
        let calendar = Calendar.current
        let today = Date()
        return [
            ChurnEvent(
                id: UUID(),
                userId: "user-001",
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                reason: .tooExpensive,
                tier: .pro,
                duration: 92
            ),
            ChurnEvent(
                id: UUID(),
                userId: "user-002",
                date: calendar.date(byAdding: .day, value: -2, to: today)!,
                reason: .notUsing,
                tier: .pro,
                duration: 35
            ),
            ChurnEvent(
                id: UUID(),
                userId: "user-003",
                date: calendar.date(byAdding: .day, value: -3, to: today)!,
                reason: .trialExpired,
                tier: .free,
                duration: 7
            ),
            ChurnEvent(
                id: UUID(),
                userId: "user-004",
                date: calendar.date(byAdding: .day, value: -4, to: today)!,
                reason: .switchedCompetitor,
                tier: .elite,
                duration: 180
            ),
            ChurnEvent(
                id: UUID(),
                userId: "user-005",
                date: calendar.date(byAdding: .day, value: -5, to: today)!,
                reason: .involuntary,
                tier: .pro,
                duration: 120
            )
        ]
    }
}

extension ConversionEvent {
    static var sampleList: [ConversionEvent] {
        let calendar = Calendar.current
        let today = Date()
        return [
            ConversionEvent(
                id: UUID(),
                userId: "user-010",
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                fromTier: .free,
                toTier: .pro,
                trigger: .trialConversion,
                variant: "variant-A"
            ),
            ConversionEvent(
                id: UUID(),
                userId: "user-011",
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                fromTier: .pro,
                toTier: .pro,
                trigger: .featureGate,
                variant: nil
            ),
            ConversionEvent(
                id: UUID(),
                userId: "user-012",
                date: calendar.date(byAdding: .day, value: -2, to: today)!,
                fromTier: .free,
                toTier: .pro,
                trigger: .paywallPresentation,
                variant: "variant-B"
            )
        ]
    }
}
#endif
