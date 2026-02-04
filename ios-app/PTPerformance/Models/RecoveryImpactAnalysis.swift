import Foundation

// MARK: - Recovery Impact Analysis Models

/// Complete recovery impact analysis with insights, correlations, and recommendations
struct RecoveryImpactAnalysis: Codable, Equatable {
    let insights: [RecoveryInsight]
    let correlations: [RecoveryCorrelation]
    let personalizedRecommendations: [PersonalizedRecoveryRecommendation]
    let analysisDate: Date
    let dataPointsAnalyzed: Int

    /// Check if we have sufficient data for meaningful analysis
    var hasSufficientData: Bool {
        dataPointsAnalyzed >= 5
    }

    /// Top insight by confidence
    var topInsight: RecoveryInsight? {
        insights.sorted { $0.confidence > $1.confidence }.first
    }

    /// Positive impact insights
    var positiveInsights: [RecoveryInsight] {
        insights.filter { $0.impactPercentage > 0 }
    }

    /// Negative impact insights
    var negativeInsights: [RecoveryInsight] {
        insights.filter { $0.impactPercentage < 0 }
    }
}

/// Individual recovery insight derived from data correlation
struct RecoveryInsight: Identifiable, Codable, Equatable {
    let id: UUID
    let type: RecoveryInsightType
    let metric: HealthMetricType
    let protocolType: RecoveryProtocolType
    let impactPercentage: Double
    let confidence: Double // 0.0 to 1.0
    let description: String
    let dataPoints: Int
    let averageValue: Double?
    let baselineValue: Double?

    init(
        id: UUID = UUID(),
        type: RecoveryInsightType,
        metric: HealthMetricType,
        protocolType: RecoveryProtocolType,
        impactPercentage: Double,
        confidence: Double,
        description: String,
        dataPoints: Int,
        averageValue: Double? = nil,
        baselineValue: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.metric = metric
        self.protocolType = protocolType
        self.impactPercentage = impactPercentage
        self.confidence = confidence
        self.description = description
        self.dataPoints = dataPoints
        self.averageValue = averageValue
        self.baselineValue = baselineValue
    }

    /// Formatted impact string for display
    var formattedImpact: String {
        let sign = impactPercentage >= 0 ? "+" : ""
        return "\(sign)\(Int(impactPercentage))%"
    }

    /// Impact category for styling
    var impactCategory: ImpactCategory {
        if impactPercentage >= 10 {
            return .strongPositive
        } else if impactPercentage >= 3 {
            return .positive
        } else if impactPercentage <= -10 {
            return .strongNegative
        } else if impactPercentage <= -3 {
            return .negative
        } else {
            return .neutral
        }
    }

    /// Confidence level description
    var confidenceLevel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5..<0.8: return "Moderate"
        default: return "Low"
        }
    }
}

/// Type of insight derived from analysis
enum RecoveryInsightType: String, Codable, CaseIterable {
    case hrvImprovement = "hrv_improvement"
    case hrvDecline = "hrv_decline"
    case sleepImprovement = "sleep_improvement"
    case sleepDecline = "sleep_decline"
    case sleepQualityBoost = "sleep_quality_boost"
    case recoveryEffectiveness = "recovery_effectiveness"
    case optimalTiming = "optimal_timing"
    case frequencyRecommendation = "frequency_recommendation"

    var displayName: String {
        switch self {
        case .hrvImprovement: return "HRV Improvement"
        case .hrvDecline: return "HRV Decline"
        case .sleepImprovement: return "Sleep Duration Improvement"
        case .sleepDecline: return "Sleep Duration Decline"
        case .sleepQualityBoost: return "Sleep Quality Boost"
        case .recoveryEffectiveness: return "Recovery Effectiveness"
        case .optimalTiming: return "Optimal Timing"
        case .frequencyRecommendation: return "Frequency Insight"
        }
    }

    var icon: String {
        switch self {
        case .hrvImprovement: return "heart.fill"
        case .hrvDecline: return "heart"
        case .sleepImprovement: return "moon.fill"
        case .sleepDecline: return "moon"
        case .sleepQualityBoost: return "bed.double.fill"
        case .recoveryEffectiveness: return "chart.line.uptrend.xyaxis"
        case .optimalTiming: return "clock.fill"
        case .frequencyRecommendation: return "calendar"
        }
    }
}

/// Health metric types for correlation analysis
enum HealthMetricType: String, Codable, CaseIterable {
    case hrv = "hrv"
    case sleepDuration = "sleep_duration"
    case sleepQuality = "sleep_quality"
    case deepSleep = "deep_sleep"
    case remSleep = "rem_sleep"
    case restingHeartRate = "resting_heart_rate"

    var displayName: String {
        switch self {
        case .hrv: return "HRV"
        case .sleepDuration: return "Sleep Duration"
        case .sleepQuality: return "Sleep Quality"
        case .deepSleep: return "Deep Sleep"
        case .remSleep: return "REM Sleep"
        case .restingHeartRate: return "Resting Heart Rate"
        }
    }

    var unit: String {
        switch self {
        case .hrv: return "ms"
        case .sleepDuration: return "hours"
        case .sleepQuality: return "%"
        case .deepSleep: return "min"
        case .remSleep: return "min"
        case .restingHeartRate: return "bpm"
        }
    }
}

/// Impact category for UI styling
enum ImpactCategory: String, Codable {
    case strongPositive
    case positive
    case neutral
    case negative
    case strongNegative
}

/// Correlation between recovery protocol and health metric
struct RecoveryCorrelation: Identifiable, Codable, Equatable {
    let id: UUID
    let protocolType: RecoveryProtocolType
    let metric: HealthMetricType
    let correlationCoefficient: Double // -1.0 to 1.0
    let pValue: Double // Statistical significance
    let sampleSize: Int
    let averageImpact: Double

    init(
        id: UUID = UUID(),
        protocolType: RecoveryProtocolType,
        metric: HealthMetricType,
        correlationCoefficient: Double,
        pValue: Double,
        sampleSize: Int,
        averageImpact: Double
    ) {
        self.id = id
        self.protocolType = protocolType
        self.metric = metric
        self.correlationCoefficient = correlationCoefficient
        self.pValue = pValue
        self.sampleSize = sampleSize
        self.averageImpact = averageImpact
    }

    /// Correlation strength description
    var strength: String {
        let abs = abs(correlationCoefficient)
        switch abs {
        case 0.7...: return "Strong"
        case 0.4..<0.7: return "Moderate"
        case 0.2..<0.4: return "Weak"
        default: return "Negligible"
        }
    }

    /// Whether correlation is statistically significant
    var isSignificant: Bool {
        pValue < 0.05 && sampleSize >= 5
    }
}

/// Personalized recommendation based on user's data
struct PersonalizedRecoveryRecommendation: Identifiable, Codable, Equatable {
    let id: UUID
    let protocolType: RecoveryProtocolType
    let title: String
    let reason: String
    let expectedBenefit: String
    let suggestedFrequency: String?
    let suggestedDuration: Int? // minutes
    let suggestedTimeOfDay: TimeOfDay?
    let priority: RecoveryPriority
    let basedOnInsights: [UUID] // IDs of supporting insights

    init(
        id: UUID = UUID(),
        protocolType: RecoveryProtocolType,
        title: String,
        reason: String,
        expectedBenefit: String,
        suggestedFrequency: String? = nil,
        suggestedDuration: Int? = nil,
        suggestedTimeOfDay: TimeOfDay? = nil,
        priority: RecoveryPriority,
        basedOnInsights: [UUID] = []
    ) {
        self.id = id
        self.protocolType = protocolType
        self.title = title
        self.reason = reason
        self.expectedBenefit = expectedBenefit
        self.suggestedFrequency = suggestedFrequency
        self.suggestedDuration = suggestedDuration
        self.suggestedTimeOfDay = suggestedTimeOfDay
        self.priority = priority
        self.basedOnInsights = basedOnInsights
    }
}

// TimeOfDay is defined in Supplement.swift

// MARK: - Preview Support

#if DEBUG
extension RecoveryImpactAnalysis {
    static var sample: RecoveryImpactAnalysis {
        RecoveryImpactAnalysis(
            insights: RecoveryInsight.sampleInsights,
            correlations: RecoveryCorrelation.sampleCorrelations,
            personalizedRecommendations: PersonalizedRecoveryRecommendation.sampleRecommendations,
            analysisDate: Date(),
            dataPointsAnalyzed: 25
        )
    }

    static var empty: RecoveryImpactAnalysis {
        RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 2
        )
    }
}

extension RecoveryInsight {
    static var sampleInsights: [RecoveryInsight] {
        [
            RecoveryInsight(
                type: .hrvImprovement,
                metric: .hrv,
                protocolType: .saunaTraditional,
                impactPercentage: 15.2,
                confidence: 0.85,
                description: "Your HRV improved 15% after sauna sessions",
                dataPoints: 12,
                averageValue: 72.5,
                baselineValue: 63.0
            ),
            RecoveryInsight(
                type: .sleepQualityBoost,
                metric: .deepSleep,
                protocolType: .coldPlunge,
                impactPercentage: 22.0,
                confidence: 0.78,
                description: "Deep sleep increased 22% after cold plunge",
                dataPoints: 8,
                averageValue: 95.0,
                baselineValue: 78.0
            ),
            RecoveryInsight(
                type: .recoveryEffectiveness,
                metric: .restingHeartRate,
                protocolType: .contrast,
                impactPercentage: -4.5,
                confidence: 0.72,
                description: "Resting heart rate dropped 4.5% with contrast therapy",
                dataPoints: 6,
                averageValue: 54.0,
                baselineValue: 56.5
            )
        ]
    }
}

extension RecoveryCorrelation {
    static var sampleCorrelations: [RecoveryCorrelation] {
        [
            RecoveryCorrelation(
                protocolType: .saunaTraditional,
                metric: .hrv,
                correlationCoefficient: 0.68,
                pValue: 0.02,
                sampleSize: 15,
                averageImpact: 12.5
            ),
            RecoveryCorrelation(
                protocolType: .coldPlunge,
                metric: .deepSleep,
                correlationCoefficient: 0.55,
                pValue: 0.04,
                sampleSize: 10,
                averageImpact: 18.0
            )
        ]
    }
}

extension PersonalizedRecoveryRecommendation {
    static var sampleRecommendations: [PersonalizedRecoveryRecommendation] {
        [
            PersonalizedRecoveryRecommendation(
                protocolType: .saunaTraditional,
                title: "Continue Sauna Sessions",
                reason: "Your data shows consistent HRV improvement after sauna use",
                expectedBenefit: "+12-15% HRV improvement",
                suggestedFrequency: "3-4x per week",
                suggestedDuration: 20,
                suggestedTimeOfDay: .evening,
                priority: .high
            ),
            PersonalizedRecoveryRecommendation(
                protocolType: .coldPlunge,
                title: "Try Cold Plunge After Workouts",
                reason: "Athletes with similar profiles see improved deep sleep",
                expectedBenefit: "+20% deep sleep duration",
                suggestedFrequency: "2-3x per week",
                suggestedDuration: 3,
                suggestedTimeOfDay: .afternoon,
                priority: .medium
            )
        ]
    }
}
#endif
