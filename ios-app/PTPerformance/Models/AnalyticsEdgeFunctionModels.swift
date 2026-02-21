//
//  AnalyticsEdgeFunctionModels.swift
//  PTPerformance
//
//  Codable response models for analytics edge functions.
//  Each struct mirrors the JSON shape returned by the corresponding
//  Supabase edge function / RPC.
//

import Foundation

// MARK: - Revenue Analytics (revenue-analytics EF)

struct RevenueAnalyticsResponse: Codable {
    let success: Bool?
    let generatedAt: String?
    let periodDays: Int?
    let sectionsIncluded: [String]?
    let metrics: RevenueMetrics?
    let cohortAnalysis: [RevenueCohortData]?
    let ltvEstimates: [RevenueLTVData]?
    let forecasting: RevenueForecastingInputs?

    enum CodingKeys: String, CodingKey {
        case success
        case generatedAt = "generated_at"
        case periodDays = "period_days"
        case sectionsIncluded = "sections_included"
        case metrics
        case cohortAnalysis = "cohort_analysis"
        case ltvEstimates = "ltv_estimates"
        case forecasting
    }
}

struct RevenueMetrics: Codable {
    let mrr: Double?
    let arr: Double?
    let mrrBreakdown: MRRBreakdown?
    let activeSubscribers: ActiveSubscribers?
    let churnRate: Double?
    let churnDetails: ChurnDetails?
    let expansionRevenue: Double?
    let revenueByTier: [TierRevenue]?
    let subscribersByTier: [TierSubscribers]?

    enum CodingKeys: String, CodingKey {
        case mrr, arr
        case mrrBreakdown = "mrr_breakdown"
        case activeSubscribers = "active_subscribers"
        case churnRate = "churn_rate"
        case churnDetails = "churn_details"
        case expansionRevenue = "expansion_revenue"
        case revenueByTier = "revenue_by_tier"
        case subscribersByTier = "subscribers_by_tier"
    }
}

struct MRRBreakdown: Codable {
    let appStore: Double?
    let packSubscriptions: Double?

    enum CodingKeys: String, CodingKey {
        case appStore = "app_store"
        case packSubscriptions = "pack_subscriptions"
    }
}

struct ActiveSubscribers: Codable {
    let total: Int?
    let appStore: Int?
    let packSubscriptions: Int?
    let trials: Int?

    enum CodingKeys: String, CodingKey {
        case total
        case appStore = "app_store"
        case packSubscriptions = "pack_subscriptions"
        case trials
    }
}

struct ChurnDetails: Codable {
    let ratePercent: Double?
    let churnedInPeriod: Int?
    let activeAtPeriodStart: Int?

    enum CodingKeys: String, CodingKey {
        case ratePercent = "rate_percent"
        case churnedInPeriod = "churned_in_period"
        case activeAtPeriodStart = "active_at_period_start"
    }
}

struct TierRevenue: Codable {
    let tier: String?
    let tierName: String?
    let activeSubscribers: Int?
    let priceMonthly: Double?
    let monthlyRevenue: Double?

    enum CodingKeys: String, CodingKey {
        case tier
        case tierName = "tier_name"
        case activeSubscribers = "active_subscribers"
        case priceMonthly = "price_monthly"
        case monthlyRevenue = "monthly_revenue"
    }
}

struct TierSubscribers: Codable {
    let tier: String?
    let tierName: String?
    let active: Int?
    let trial: Int?
    let cancelled: Int?

    enum CodingKeys: String, CodingKey {
        case tier
        case tierName = "tier_name"
        case active, trial, cancelled
    }
}

struct RevenueCohortData: Codable {
    let cohort: String?
    let totalUsers: Int?
    let retainedUsers: Int?
    let retentionRatePercent: Double?
    let totalSubscriptions: Int?
    let activeSubscriptions: Int?
    let churnedSubscriptions: Int?
    let currentMrrContribution: Double?
    let avgMonthsRetained: Double?
    let avgRevenuePerUser: Double?

    enum CodingKeys: String, CodingKey {
        case cohort
        case totalUsers = "total_users"
        case retainedUsers = "retained_users"
        case retentionRatePercent = "retention_rate_percent"
        case totalSubscriptions = "total_subscriptions"
        case activeSubscriptions = "active_subscriptions"
        case churnedSubscriptions = "churned_subscriptions"
        case currentMrrContribution = "current_mrr_contribution"
        case avgMonthsRetained = "avg_months_retained"
        case avgRevenuePerUser = "avg_revenue_per_user"
    }
}

struct RevenueLTVData: Codable {
    let tier: String?
    let tierName: String?
    let monthlyPrice: Double?
    let totalSubscriptions: Int?
    let activeSubscriptions: Int?
    let churnedSubscriptions: Int?
    let avgLifespanMonths: Double?
    let medianLifespanMonths: Double?
    let monthlyChurnRatePercent: Double?
    let estimatedLtv: Double?
    let estimatedLtvChurnMethod: Double?
    let conversionRatePercent: Double?

    enum CodingKeys: String, CodingKey {
        case tier
        case tierName = "tier_name"
        case monthlyPrice = "monthly_price"
        case totalSubscriptions = "total_subscriptions"
        case activeSubscriptions = "active_subscriptions"
        case churnedSubscriptions = "churned_subscriptions"
        case avgLifespanMonths = "avg_lifespan_months"
        case medianLifespanMonths = "median_lifespan_months"
        case monthlyChurnRatePercent = "monthly_churn_rate_percent"
        case estimatedLtv = "estimated_ltv"
        case estimatedLtvChurnMethod = "estimated_ltv_churn_method"
        case conversionRatePercent = "conversion_rate_percent"
    }
}

struct RevenueForecastingInputs: Codable {
    let currentMrr: Double?
    let currentArr: Double?
    let monthlyChurnRate: Double?
    let avgRevenuePerAccount: Double?
    let activeSubscriberCount: Int?
    let trialCount: Int?
    let expansionRevenueMonthly: Double?
    let netRevenueRetention: Double?
    let projectedArr12m: Double?
    let projectedMrrNextMonth: Double?
    let runwayMonthsAtCurrentChurn: Double?

    enum CodingKeys: String, CodingKey {
        case currentMrr = "current_mrr"
        case currentArr = "current_arr"
        case monthlyChurnRate = "monthly_churn_rate"
        case avgRevenuePerAccount = "avg_revenue_per_account"
        case activeSubscriberCount = "active_subscriber_count"
        case trialCount = "trial_count"
        case expansionRevenueMonthly = "expansion_revenue_monthly"
        case netRevenueRetention = "net_revenue_retention"
        case projectedArr12m = "projected_arr_12m"
        case projectedMrrNextMonth = "projected_mrr_next_month"
        case runwayMonthsAtCurrentChurn = "runway_months_at_current_churn"
    }
}

// MARK: - Retention Analytics (retention-analytics EF)

struct RetentionAnalyticsResponse: Codable {
    let analysisId: String?
    let generatedAt: String?
    let monthsAnalyzed: Int?
    let cohorts: [RetentionCohortRow]?
    let drivers: [RetentionDriver]?
    let resurrectedUsers: [ResurrectedUser]?
    let churnPredictionInputs: ChurnPredictionInputs?
    let summary: RetentionSummary?

    enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case generatedAt = "generated_at"
        case monthsAnalyzed = "months_analyzed"
        case cohorts, drivers
        case resurrectedUsers = "resurrected_users"
        case churnPredictionInputs = "churn_prediction_inputs"
        case summary
    }
}

struct RetentionCohortRow: Codable, Identifiable {
    var id: String { cohortMonth ?? UUID().uuidString }

    let cohortMonth: String?
    let cohortSize: Int?
    let d1RetentionPct: Double?
    let d1Retained: Int?
    let d7RetentionPct: Double?
    let d7Retained: Int?
    let d30RetentionPct: Double?
    let d30Retained: Int?
    let d90RetentionPct: Double?
    let d90Retained: Int?

    enum CodingKeys: String, CodingKey {
        case cohortMonth = "cohort_month"
        case cohortSize = "cohort_size"
        case d1RetentionPct = "d1_retention_pct"
        case d1Retained = "d1_retained"
        case d7RetentionPct = "d7_retention_pct"
        case d7Retained = "d7_retained"
        case d30RetentionPct = "d30_retention_pct"
        case d30Retained = "d30_retained"
        case d90RetentionPct = "d90_retention_pct"
        case d90Retained = "d90_retained"
    }
}

struct RetentionDriver: Codable, Identifiable {
    var id: String { feature ?? UUID().uuidString }

    let feature: String?
    let totalUsers: Int?
    let usersWithFeature: Int?
    let usersWithoutFeature: Int?
    let retainedWithFeature: Int?
    let retainedWithoutFeature: Int?
    let retentionRateWithPct: Double?
    let retentionRateWithoutPct: Double?
    let liftPct: Double?

    enum CodingKeys: String, CodingKey {
        case feature
        case totalUsers = "total_users"
        case usersWithFeature = "users_with_feature"
        case usersWithoutFeature = "users_without_feature"
        case retainedWithFeature = "retained_with_feature"
        case retainedWithoutFeature = "retained_without_feature"
        case retentionRateWithPct = "retention_rate_with_pct"
        case retentionRateWithoutPct = "retention_rate_without_pct"
        case liftPct = "lift_pct"
    }
}

struct ResurrectedUser: Codable, Identifiable {
    var id: String { patientId ?? UUID().uuidString }

    let patientId: String?
    let resurrectedAt: String?
    let lastActiveAt: String?
    let inactiveDays: Int?
    let returnSessionType: String?
    let signupDate: String?
    let daysSinceSignup: Int?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case resurrectedAt = "resurrected_at"
        case lastActiveAt = "last_active_at"
        case inactiveDays = "inactive_days"
        case returnSessionType = "return_session_type"
        case signupDate = "signup_date"
        case daysSinceSignup = "days_since_signup"
    }
}

struct ChurnPredictionInputs: Codable {
    let totalUsersAnalyzed: Int?
    let overallD30RetentionPct: Double?
    let highestImpactFeature: String?
    let highestImpactLiftPct: Double?
    let avgInactiveDaysBeforeResurrection: Double?
    let resurrectionCount: Int?
    let cohortTrend: String?

    enum CodingKeys: String, CodingKey {
        case totalUsersAnalyzed = "total_users_analyzed"
        case overallD30RetentionPct = "overall_d30_retention_pct"
        case highestImpactFeature = "highest_impact_feature"
        case highestImpactLiftPct = "highest_impact_lift_pct"
        case avgInactiveDaysBeforeResurrection = "avg_inactive_days_before_resurrection"
        case resurrectionCount = "resurrection_count"
        case cohortTrend = "cohort_trend"
    }
}

struct RetentionSummary: Codable {
    let totalCohortUsers: Int?
    let latestCohortD1Pct: Double?
    let latestCohortD7Pct: Double?
    let bestRetentionMonth: String?
    let topRetentionDriver: String?
    let totalResurrections: Int?

    enum CodingKeys: String, CodingKey {
        case totalCohortUsers = "total_cohort_users"
        case latestCohortD1Pct = "latest_cohort_d1_pct"
        case latestCohortD7Pct = "latest_cohort_d7_pct"
        case bestRetentionMonth = "best_retention_month"
        case topRetentionDriver = "top_retention_driver"
        case totalResurrections = "total_resurrections"
    }
}

// MARK: - Engagement Scoring (engagement-scoring EF)

struct EngagementScoresResponse: Codable {
    let success: Bool?
    let summary: EngagementSummary?
    let data: [EngagementScoreRow]?
    let executionTimeMs: Int?

    enum CodingKeys: String, CodingKey {
        case success, summary, data
        case executionTimeMs = "execution_time_ms"
    }
}

struct EngagementSummary: Codable {
    let totalPatients: Int?
    let highlyEngaged: Int?
    let engaged: Int?
    let moderate: Int?
    let atRisk: Int?
    let highRisk: Int?
    let avgScore: Double?

    enum CodingKeys: String, CodingKey {
        case totalPatients = "total_patients"
        case highlyEngaged = "highly_engaged"
        case engaged, moderate
        case atRisk = "at_risk"
        case highRisk = "high_risk"
        case avgScore = "avg_score"
    }
}

struct EngagementScoreRow: Codable, Identifiable {
    var id: String { patientId ?? UUID().uuidString }

    let patientId: String?
    let score: Double?
    let riskLevel: String?
    let components: EngagementComponents?
    let calculatedAt: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case score
        case riskLevel = "risk_level"
        case components
        case calculatedAt = "calculated_at"
    }
}

struct EngagementComponents: Codable {
    let workoutFrequency: EngagementComponent?
    let streakConsistency: EngagementComponent?
    let featureBreadth: EngagementComponent?
    let recency: EngagementComponent?

    enum CodingKeys: String, CodingKey {
        case workoutFrequency = "workout_frequency"
        case streakConsistency = "streak_consistency"
        case featureBreadth = "feature_breadth"
        case recency
    }
}

struct EngagementComponent: Codable {
    let rawValue: Double?
    let weight: Double?
    let weightedValue: Double?
    // Optional detail fields (vary by component)
    let sessionsCompleted: Int?
    let expectedSessions: Int?
    let currentStreak: Int?
    let featuresUsed: Int?
    let featuresTotal: Int?
    let daysSinceLastActivity: Int?

    enum CodingKeys: String, CodingKey {
        case rawValue = "raw_value"
        case weight
        case weightedValue = "weighted_value"
        case sessionsCompleted = "sessions_completed"
        case expectedSessions = "expected_sessions"
        case currentStreak = "current_streak"
        case featuresUsed = "features_used"
        case featuresTotal = "features_total"
        case daysSinceLastActivity = "days_since_last_activity"
    }
}

// MARK: - Training Outcomes (training-outcomes EF)

struct TrainingOutcomesResponse: Codable {
    let success: Bool?
    let type: String?
    let summary: TrainingOutcomeSummary?
    let data: TrainingOutcomeData?
}

struct TrainingOutcomeData: Codable {
    let volumeProgression: [WeeklyVolume]?
    let strengthGains: [StrengthGain]?
    let painTrend: [WeeklyPain]?
    let adherence: [EFWeeklyAdherence]?
    let recoveryCorrelation: [String: EFAnyCodable]?

    enum CodingKeys: String, CodingKey {
        case volumeProgression = "volume_progression"
        case strengthGains = "strength_gains"
        case painTrend = "pain_trend"
        case adherence
        case recoveryCorrelation = "recovery_correlation"
    }
}

struct StrengthGain: Codable, Identifiable {
    var id: String { exerciseName ?? UUID().uuidString }

    let exerciseName: String?
    let startLoad: Double?
    let currentLoad: Double?
    let pctChange: Double?
    let dataPoints: Int?

    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
        case startLoad = "start_load"
        case currentLoad = "current_load"
        case pctChange = "pct_change"
        case dataPoints = "data_points"
    }
}

struct WeeklyVolume: Codable, Identifiable {
    var id: String { weekStart ?? UUID().uuidString }

    let weekStart: String?
    let totalVolume: Double?
    let logCount: Int?

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case totalVolume = "total_volume"
        case logCount = "log_count"
    }
}

struct WeeklyPain: Codable, Identifiable {
    var id: String { weekStart ?? UUID().uuidString }

    let weekStart: String?
    let avgPain: Double?
    let sampleCount: Int?

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case avgPain = "avg_pain"
        case sampleCount = "sample_count"
    }
}

struct EFWeeklyAdherence: Codable, Identifiable {
    var id: String { weekStart ?? UUID().uuidString }

    let weekStart: String?
    let sessionsCompleted: Int?
    let sessionsScheduled: Int?
    let adherencePct: Double?

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case sessionsCompleted = "sessions_completed"
        case sessionsScheduled = "sessions_scheduled"
        case adherencePct = "adherence_pct"
    }
}

struct TrainingOutcomeSummary: Codable {
    let totalExercisesTracked: Int?
    let exercisesWithGains: Int?
    let avgStrengthGainPct: Double?
    let bestStrengthGain: StrengthGain?
    let volumeTrend: String?
    let painTrend: String?
    let overallAdherencePct: Double?
    let weeksOfData: Int?

    enum CodingKeys: String, CodingKey {
        case totalExercisesTracked = "total_exercises_tracked"
        case exercisesWithGains = "exercises_with_gains"
        case avgStrengthGainPct = "avg_strength_gain_pct"
        case bestStrengthGain = "best_strength_gain"
        case volumeTrend = "volume_trend"
        case painTrend = "pain_trend"
        case overallAdherencePct = "overall_adherence_pct"
        case weeksOfData = "weeks_of_data"
    }
}

// MARK: - Executive Dashboard (executive-dashboard EF → get_executive_dashboard RPC)

struct ExecutiveDashboardResponse: Codable {
    let generatedAt: String?
    let overview: ExecOverview?
    let revenue: ExecRevenue?
    let engagement: ExecEngagement?
    let satisfaction: ExecSatisfaction?
    let safety: ExecSafety?
    let trends: ExecTrends?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case overview, revenue, engagement, satisfaction, safety, trends
    }
}

struct ExecOverview: Codable {
    let totalUsers: Int?
    let dau: Int?
    let wau: Int?
    let mau: Int?
    let dauMauRatio: Double?

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case dau, wau, mau
        case dauMauRatio = "dau_mau_ratio"
    }
}

struct ExecRevenue: Codable {
    let subscriberCount: Int?
    let trialCount: Int?
    let mrrEstimate: Double?
    let totalActive: Int?
    let churnCount: Int?

    enum CodingKeys: String, CodingKey {
        case subscriberCount = "subscriber_count"
        case trialCount = "trial_count"
        case mrrEstimate = "mrr_estimate"
        case totalActive = "total_active"
        case churnCount = "churn_count"
    }
}

struct ExecEngagement: Codable {
    let avgSessionsPerUserPerWeek: Double?
    let totalSessionsThisWeek: Int?
    let activeUsersWithSessions: Int?
    let avgStreakLength: Double?

    enum CodingKeys: String, CodingKey {
        case avgSessionsPerUserPerWeek = "avg_sessions_per_user_per_week"
        case totalSessionsThisWeek = "total_sessions_this_week"
        case activeUsersWithSessions = "active_users_with_sessions"
        case avgStreakLength = "avg_streak_length"
    }
}

struct ExecSatisfaction: Codable {
    let avgRating: Double?
    let feedbackCount: Int?
    let feedbackLast30d: Int?
    let avgRatingLast30d: Double?
    let ratingDistribution: RatingDistribution?

    enum CodingKeys: String, CodingKey {
        case avgRating = "avg_rating"
        case feedbackCount = "feedback_count"
        case feedbackLast30d = "feedback_last_30d"
        case avgRatingLast30d = "avg_rating_last_30d"
        case ratingDistribution = "rating_distribution"
    }
}

struct RatingDistribution: Codable {
    let oneStar: Int?
    let twoStar: Int?
    let threeStar: Int?
    let fourStar: Int?
    let fiveStar: Int?

    enum CodingKeys: String, CodingKey {
        case oneStar = "1_star"
        case twoStar = "2_star"
        case threeStar = "3_star"
        case fourStar = "4_star"
        case fiveStar = "5_star"
    }
}

struct ExecSafety: Codable {
    let openIncidents: SafetyIncidentCounts?
    let totalOpen: Int?
    let resolvedThisWeek: Int?
    let totalThisMonth: Int?

    enum CodingKeys: String, CodingKey {
        case openIncidents = "open_incidents"
        case totalOpen = "total_open"
        case resolvedThisWeek = "resolved_this_week"
        case totalThisMonth = "total_this_month"
    }
}

struct SafetyIncidentCounts: Codable {
    let critical: Int?
    let high: Int?
    let medium: Int?
    let low: Int?
}

struct ExecTrends: Codable {
    let dau: EFTrendMetric?
    let sessions: EFTrendMetric?
    let newSignups: EFTrendMetric?

    enum CodingKeys: String, CodingKey {
        case dau, sessions
        case newSignups = "new_signups"
    }
}

struct EFTrendMetric: Codable {
    let current: Int?
    let previous: Int?
    let changePct: Double?

    enum CodingKeys: String, CodingKey {
        case current, previous
        case changePct = "change_pct"
    }
}

// MARK: - Product Health (product-health EF → get_product_health RPC)

struct ProductHealthResponse: Codable {
    let periodStart: String?
    let periodEnd: String?
    let periodDays: Int?
    let engagement: ProductEngagement?
    let featureAdoption: [String: FeatureAdoptionMetric]?
    let satisfaction: ProductSatisfaction?
    let safety: ProductSafety?
    let subscriptionHealth: ProductSubscriptionHealth?
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case periodDays = "period_days"
        case engagement
        case featureAdoption = "feature_adoption"
        case satisfaction, safety
        case subscriptionHealth = "subscription_health"
        case generatedAt = "generated_at"
    }
}

struct ProductEngagement: Codable {
    let dau: Int?
    let wau: Int?
    let mau: Int?
    let totalPatients: Int?
    let dauTrend: Double?
    let wauTrend: Double?
    let mauTrend: Double?
    let dauWauRatio: Double?
    let wauMauRatio: Double?

    enum CodingKeys: String, CodingKey {
        case dau, wau, mau
        case totalPatients = "total_patients"
        case dauTrend = "dau_trend"
        case wauTrend = "wau_trend"
        case mauTrend = "mau_trend"
        case dauWauRatio = "dau_wau_ratio"
        case wauMauRatio = "wau_mau_ratio"
    }
}

struct FeatureAdoptionMetric: Codable {
    let users: Int?
    let adoptionPct: Double?

    enum CodingKeys: String, CodingKey {
        case users
        case adoptionPct = "adoption_pct"
    }
}

struct ProductSatisfaction: Codable {
    let avgRating: Double?
    let totalReviews: Int?
    let ratingDistribution: RatingDistribution?
    let npsProxy: Double?
    let recentLowRatings: [LowRatingEntry]?

    enum CodingKeys: String, CodingKey {
        case avgRating = "avg_rating"
        case totalReviews = "total_reviews"
        case ratingDistribution = "rating_distribution"
        case npsProxy = "nps_proxy"
        case recentLowRatings = "recent_low_ratings"
    }
}

struct LowRatingEntry: Codable, Identifiable {
    var id: String { timestamp ?? UUID().uuidString }

    let rating: Int?
    let feedback: String?
    let timestamp: String?
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case rating, feedback, timestamp
        case appVersion = "app_version"
    }
}

struct ProductSafety: Codable {
    let openIncidents: SafetyIncidentCounts?
    let totalOpen: Int?
    let incidentsInPeriod: Int?
    let resolvedInPeriod: Int?
    let avgResolutionHours: Double?

    enum CodingKeys: String, CodingKey {
        case openIncidents = "open_incidents"
        case totalOpen = "total_open"
        case incidentsInPeriod = "incidents_in_period"
        case resolvedInPeriod = "resolved_in_period"
        case avgResolutionHours = "avg_resolution_hours"
    }
}

struct ProductSubscriptionHealth: Codable {
    let newTrials: Int?
    let activeSubscriptions: Int?
    let conversions: Int?
    let cancellations: Int?
    let expired: Int?
    let trialConversionRate: Double?
    let churnRate: Double?

    enum CodingKeys: String, CodingKey {
        case newTrials = "new_trials"
        case activeSubscriptions = "active_subscriptions"
        case conversions, cancellations, expired
        case trialConversionRate = "trial_conversion_rate"
        case churnRate = "churn_rate"
    }
}

// MARK: - AnyCodable Helper (for untyped JSON fields)

struct EFAnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int { try container.encode(int) }
        else if let double = value as? Double { try container.encode(double) }
        else if let string = value as? String { try container.encode(string) }
        else if let bool = value as? Bool { try container.encode(bool) }
        else { try container.encodeNil() }
    }
}
