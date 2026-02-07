//
//  RecoveryImpactAnalysisTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoveryImpactAnalysis and related models
//

import XCTest
@testable import PTPerformance

// MARK: - RecoveryImpactAnalysis Tests

final class RecoveryImpactAnalysisTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRecoveryImpactAnalysis_Initialization() {
        let analysis = createMockAnalysis()

        XCTAssertEqual(analysis.insights.count, 3)
        XCTAssertEqual(analysis.correlations.count, 2)
        XCTAssertEqual(analysis.personalizedRecommendations.count, 2)
        XCTAssertEqual(analysis.dataPointsAnalyzed, 25)
    }

    // MARK: - Computed Properties Tests

    func testRecoveryImpactAnalysis_HasSufficientData() {
        var analysis = createMockAnalysis(dataPoints: 5)
        XCTAssertTrue(analysis.hasSufficientData)

        analysis = createMockAnalysis(dataPoints: 4)
        XCTAssertFalse(analysis.hasSufficientData)

        analysis = createMockAnalysis(dataPoints: 10)
        XCTAssertTrue(analysis.hasSufficientData)
    }

    func testRecoveryImpactAnalysis_TopInsight() {
        let analysis = createMockAnalysis()
        let topInsight = analysis.topInsight

        XCTAssertNotNil(topInsight)
        // Should return the insight with highest confidence
        XCTAssertTrue(analysis.insights.allSatisfy { $0.confidence <= topInsight!.confidence })
    }

    func testRecoveryImpactAnalysis_PositiveInsights() {
        let analysis = createMockAnalysis()
        let positive = analysis.positiveInsights

        XCTAssertTrue(positive.allSatisfy { $0.impactPercentage > 0 })
    }

    func testRecoveryImpactAnalysis_NegativeInsights() {
        let analysis = createMockAnalysis()
        let negative = analysis.negativeInsights

        XCTAssertTrue(negative.allSatisfy { $0.impactPercentage < 0 })
    }

    func testRecoveryImpactAnalysis_EmptyInsights() {
        let analysis = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 0
        )

        XCTAssertNil(analysis.topInsight)
        XCTAssertTrue(analysis.positiveInsights.isEmpty)
        XCTAssertTrue(analysis.negativeInsights.isEmpty)
        XCTAssertFalse(analysis.hasSufficientData)
    }

    // MARK: - Codable Tests

    func testRecoveryImpactAnalysis_Codable() throws {
        let original = createMockAnalysis()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecoveryImpactAnalysis.self, from: data)

        XCTAssertEqual(original.dataPointsAnalyzed, decoded.dataPointsAnalyzed)
        XCTAssertEqual(original.insights.count, decoded.insights.count)
        XCTAssertEqual(original.correlations.count, decoded.correlations.count)
        XCTAssertEqual(original.personalizedRecommendations.count, decoded.personalizedRecommendations.count)
    }

    // MARK: - Helper Methods

    private func createMockAnalysis(dataPoints: Int = 25) -> RecoveryImpactAnalysis {
        let insights = [
            RecoveryInsight(
                type: .hrvImprovement,
                metric: .hrv,
                protocolType: .saunaTraditional,
                impactPercentage: 15.0,
                confidence: 0.85,
                description: "HRV improved after sauna",
                dataPoints: 12
            ),
            RecoveryInsight(
                type: .sleepQualityBoost,
                metric: .deepSleep,
                protocolType: .coldPlunge,
                impactPercentage: 22.0,
                confidence: 0.78,
                description: "Deep sleep increased after cold plunge",
                dataPoints: 8
            ),
            RecoveryInsight(
                type: .recoveryEffectiveness,
                metric: .restingHeartRate,
                protocolType: .contrast,
                impactPercentage: -4.5,
                confidence: 0.72,
                description: "RHR dropped with contrast therapy",
                dataPoints: 6
            )
        ]

        let correlations = [
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

        let recommendations = [
            PersonalizedRecoveryRecommendation(
                protocolType: .saunaTraditional,
                title: "Continue Sauna Sessions",
                reason: "Consistent HRV improvement",
                expectedBenefit: "+12-15% HRV",
                suggestedFrequency: "3-4x per week",
                suggestedDuration: 20,
                suggestedTimeOfDay: .evening,
                priority: .high
            ),
            PersonalizedRecoveryRecommendation(
                protocolType: .coldPlunge,
                title: "Try Cold Plunge",
                reason: "Similar profiles see improved sleep",
                expectedBenefit: "+20% deep sleep",
                priority: .medium
            )
        ]

        return RecoveryImpactAnalysis(
            insights: insights,
            correlations: correlations,
            personalizedRecommendations: recommendations,
            analysisDate: Date(),
            dataPointsAnalyzed: dataPoints
        )
    }
}

// MARK: - RecoveryInsight Tests

final class RecoveryInsightTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRecoveryInsight_Initialization() {
        let insight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.85,
            description: "HRV improved 15% after sauna sessions",
            dataPoints: 12,
            averageValue: 72.5,
            baselineValue: 63.0
        )

        XCTAssertNotNil(insight.id)
        XCTAssertEqual(insight.type, .hrvImprovement)
        XCTAssertEqual(insight.metric, .hrv)
        XCTAssertEqual(insight.protocolType, .saunaTraditional)
        XCTAssertEqual(insight.impactPercentage, 15.0)
        XCTAssertEqual(insight.confidence, 0.85)
        XCTAssertEqual(insight.dataPoints, 12)
        XCTAssertEqual(insight.averageValue, 72.5)
        XCTAssertEqual(insight.baselineValue, 63.0)
    }

    // MARK: - Computed Properties Tests

    func testRecoveryInsight_FormattedImpact_Positive() {
        let insight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.7,
            confidence: 0.85,
            description: "Test",
            dataPoints: 10
        )

        XCTAssertEqual(insight.formattedImpact, "+15%")
    }

    func testRecoveryInsight_FormattedImpact_Negative() {
        let insight = RecoveryInsight(
            type: .hrvDecline,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: -8.3,
            confidence: 0.70,
            description: "Test",
            dataPoints: 5
        )

        XCTAssertEqual(insight.formattedImpact, "-8%")
    }

    func testRecoveryInsight_FormattedImpact_Zero() {
        let insight = RecoveryInsight(
            type: .recoveryEffectiveness,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 0.4,
            confidence: 0.50,
            description: "Test",
            dataPoints: 5
        )

        XCTAssertEqual(insight.formattedImpact, "+0%")
    }

    func testRecoveryInsight_ImpactCategory_StrongPositive() {
        let insight = createInsightWithImpact(12.0)
        XCTAssertEqual(insight.impactCategory, .strongPositive)
    }

    func testRecoveryInsight_ImpactCategory_Positive() {
        let insight = createInsightWithImpact(5.0)
        XCTAssertEqual(insight.impactCategory, .positive)
    }

    func testRecoveryInsight_ImpactCategory_Neutral() {
        let insight = createInsightWithImpact(1.0)
        XCTAssertEqual(insight.impactCategory, .neutral)
    }

    func testRecoveryInsight_ImpactCategory_Negative() {
        let insight = createInsightWithImpact(-5.0)
        XCTAssertEqual(insight.impactCategory, .negative)
    }

    func testRecoveryInsight_ImpactCategory_StrongNegative() {
        let insight = createInsightWithImpact(-15.0)
        XCTAssertEqual(insight.impactCategory, .strongNegative)
    }

    func testRecoveryInsight_ConfidenceLevel() {
        let highConfidence = createInsightWithConfidence(0.85)
        XCTAssertEqual(highConfidence.confidenceLevel, "High")

        let moderateConfidence = createInsightWithConfidence(0.65)
        XCTAssertEqual(moderateConfidence.confidenceLevel, "Moderate")

        let lowConfidence = createInsightWithConfidence(0.40)
        XCTAssertEqual(lowConfidence.confidenceLevel, "Low")
    }

    // MARK: - Codable Tests

    func testRecoveryInsight_Codable() throws {
        let original = RecoveryInsight(
            type: .sleepImprovement,
            metric: .sleepDuration,
            protocolType: .contrast,
            impactPercentage: 10.0,
            confidence: 0.75,
            description: "Sleep improved",
            dataPoints: 8
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecoveryInsight.self, from: data)

        XCTAssertEqual(original.type, decoded.type)
        XCTAssertEqual(original.metric, decoded.metric)
        XCTAssertEqual(original.protocolType, decoded.protocolType)
        XCTAssertEqual(original.impactPercentage, decoded.impactPercentage)
    }

    // MARK: - Helper Methods

    private func createInsightWithImpact(_ impact: Double) -> RecoveryInsight {
        RecoveryInsight(
            type: .recoveryEffectiveness,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: impact,
            confidence: 0.75,
            description: "Test",
            dataPoints: 10
        )
    }

    private func createInsightWithConfidence(_ confidence: Double) -> RecoveryInsight {
        RecoveryInsight(
            type: .recoveryEffectiveness,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 10.0,
            confidence: confidence,
            description: "Test",
            dataPoints: 10
        )
    }
}

// MARK: - RecoveryInsightType Tests

final class RecoveryInsightTypeTests: XCTestCase {

    func testRecoveryInsightType_RawValues() {
        XCTAssertEqual(RecoveryInsightType.hrvImprovement.rawValue, "hrv_improvement")
        XCTAssertEqual(RecoveryInsightType.hrvDecline.rawValue, "hrv_decline")
        XCTAssertEqual(RecoveryInsightType.sleepImprovement.rawValue, "sleep_improvement")
        XCTAssertEqual(RecoveryInsightType.sleepDecline.rawValue, "sleep_decline")
        XCTAssertEqual(RecoveryInsightType.sleepQualityBoost.rawValue, "sleep_quality_boost")
        XCTAssertEqual(RecoveryInsightType.recoveryEffectiveness.rawValue, "recovery_effectiveness")
        XCTAssertEqual(RecoveryInsightType.optimalTiming.rawValue, "optimal_timing")
        XCTAssertEqual(RecoveryInsightType.frequencyRecommendation.rawValue, "frequency_recommendation")
    }

    func testRecoveryInsightType_DisplayNames() {
        XCTAssertEqual(RecoveryInsightType.hrvImprovement.displayName, "HRV Improvement")
        XCTAssertEqual(RecoveryInsightType.hrvDecline.displayName, "HRV Decline")
        XCTAssertEqual(RecoveryInsightType.sleepImprovement.displayName, "Sleep Duration Improvement")
        XCTAssertEqual(RecoveryInsightType.sleepDecline.displayName, "Sleep Duration Decline")
    }

    func testRecoveryInsightType_Icons() {
        for type in RecoveryInsightType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "Type \(type) should have an icon")
        }
    }
}

// MARK: - HealthMetricType Tests

final class HealthMetricTypeTests: XCTestCase {

    func testHealthMetricType_RawValues() {
        XCTAssertEqual(HealthMetricType.hrv.rawValue, "hrv")
        XCTAssertEqual(HealthMetricType.sleepDuration.rawValue, "sleep_duration")
        XCTAssertEqual(HealthMetricType.sleepQuality.rawValue, "sleep_quality")
        XCTAssertEqual(HealthMetricType.deepSleep.rawValue, "deep_sleep")
        XCTAssertEqual(HealthMetricType.remSleep.rawValue, "rem_sleep")
        XCTAssertEqual(HealthMetricType.restingHeartRate.rawValue, "resting_heart_rate")
    }

    func testHealthMetricType_DisplayNames() {
        XCTAssertEqual(HealthMetricType.hrv.displayName, "HRV")
        XCTAssertEqual(HealthMetricType.sleepDuration.displayName, "Sleep Duration")
        XCTAssertEqual(HealthMetricType.sleepQuality.displayName, "Sleep Quality")
        XCTAssertEqual(HealthMetricType.deepSleep.displayName, "Deep Sleep")
        XCTAssertEqual(HealthMetricType.remSleep.displayName, "REM Sleep")
        XCTAssertEqual(HealthMetricType.restingHeartRate.displayName, "Resting Heart Rate")
    }

    func testHealthMetricType_Units() {
        XCTAssertEqual(HealthMetricType.hrv.unit, "ms")
        XCTAssertEqual(HealthMetricType.sleepDuration.unit, "hours")
        XCTAssertEqual(HealthMetricType.sleepQuality.unit, "%")
        XCTAssertEqual(HealthMetricType.deepSleep.unit, "min")
        XCTAssertEqual(HealthMetricType.remSleep.unit, "min")
        XCTAssertEqual(HealthMetricType.restingHeartRate.unit, "bpm")
    }

    func testHealthMetricType_AllCases() {
        let allCases = HealthMetricType.allCases
        XCTAssertEqual(allCases.count, 6)
    }
}

// MARK: - RecoveryCorrelation Tests

final class RecoveryCorrelationTests: XCTestCase {

    func testRecoveryCorrelation_Initialization() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.68,
            pValue: 0.02,
            sampleSize: 15,
            averageImpact: 12.5
        )

        XCTAssertNotNil(correlation.id)
        XCTAssertEqual(correlation.protocolType, .saunaTraditional)
        XCTAssertEqual(correlation.metric, .hrv)
        XCTAssertEqual(correlation.correlationCoefficient, 0.68)
        XCTAssertEqual(correlation.pValue, 0.02)
        XCTAssertEqual(correlation.sampleSize, 15)
        XCTAssertEqual(correlation.averageImpact, 12.5)
    }

    func testRecoveryCorrelation_Strength_Strong() {
        let correlation = createCorrelationWithCoefficient(0.75)
        XCTAssertEqual(correlation.strength, "Strong")
    }

    func testRecoveryCorrelation_Strength_Moderate() {
        let correlation = createCorrelationWithCoefficient(0.55)
        XCTAssertEqual(correlation.strength, "Moderate")
    }

    func testRecoveryCorrelation_Strength_Weak() {
        let correlation = createCorrelationWithCoefficient(0.30)
        XCTAssertEqual(correlation.strength, "Weak")
    }

    func testRecoveryCorrelation_Strength_Negligible() {
        let correlation = createCorrelationWithCoefficient(0.15)
        XCTAssertEqual(correlation.strength, "Negligible")
    }

    func testRecoveryCorrelation_Strength_Negative() {
        let correlation = createCorrelationWithCoefficient(-0.72)
        XCTAssertEqual(correlation.strength, "Strong") // Uses absolute value
    }

    func testRecoveryCorrelation_IsSignificant_True() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.68,
            pValue: 0.02, // < 0.05
            sampleSize: 10, // >= 5
            averageImpact: 12.5
        )

        XCTAssertTrue(correlation.isSignificant)
    }

    func testRecoveryCorrelation_IsSignificant_False_HighPValue() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.68,
            pValue: 0.10, // >= 0.05
            sampleSize: 10,
            averageImpact: 12.5
        )

        XCTAssertFalse(correlation.isSignificant)
    }

    func testRecoveryCorrelation_IsSignificant_False_SmallSample() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.68,
            pValue: 0.02,
            sampleSize: 3, // < 5
            averageImpact: 12.5
        )

        XCTAssertFalse(correlation.isSignificant)
    }

    // MARK: - Helper Methods

    private func createCorrelationWithCoefficient(_ coefficient: Double) -> RecoveryCorrelation {
        RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: coefficient,
            pValue: 0.02,
            sampleSize: 15,
            averageImpact: 10.0
        )
    }
}

// MARK: - PersonalizedRecoveryRecommendation Tests

final class PersonalizedRecoveryRecommendationTests: XCTestCase {

    func testPersonalizedRecoveryRecommendation_Initialization() {
        let id = UUID()
        let recommendation = PersonalizedRecoveryRecommendation(
            id: id,
            protocolType: .saunaTraditional,
            title: "Continue Sauna Sessions",
            reason: "Your data shows consistent HRV improvement",
            expectedBenefit: "+12-15% HRV improvement",
            suggestedFrequency: "3-4x per week",
            suggestedDuration: 20,
            suggestedTimeOfDay: .evening,
            priority: .high,
            basedOnInsights: [UUID(), UUID()]
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.protocolType, .saunaTraditional)
        XCTAssertEqual(recommendation.title, "Continue Sauna Sessions")
        XCTAssertEqual(recommendation.reason, "Your data shows consistent HRV improvement")
        XCTAssertEqual(recommendation.expectedBenefit, "+12-15% HRV improvement")
        XCTAssertEqual(recommendation.suggestedFrequency, "3-4x per week")
        XCTAssertEqual(recommendation.suggestedDuration, 20)
        XCTAssertEqual(recommendation.suggestedTimeOfDay, .evening)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.basedOnInsights.count, 2)
    }

    func testPersonalizedRecoveryRecommendation_OptionalFields() {
        let recommendation = PersonalizedRecoveryRecommendation(
            protocolType: .coldPlunge,
            title: "Try Cold Plunge",
            reason: "May improve recovery",
            expectedBenefit: "Unknown",
            priority: .low
        )

        XCTAssertNil(recommendation.suggestedFrequency)
        XCTAssertNil(recommendation.suggestedDuration)
        XCTAssertNil(recommendation.suggestedTimeOfDay)
        XCTAssertTrue(recommendation.basedOnInsights.isEmpty)
    }

    func testPersonalizedRecoveryRecommendation_Codable() throws {
        let original = PersonalizedRecoveryRecommendation(
            protocolType: .contrast,
            title: "Add Meditation",
            reason: "Stress reduction",
            expectedBenefit: "Better HRV",
            suggestedDuration: 15,
            priority: .medium
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonalizedRecoveryRecommendation.self, from: data)

        XCTAssertEqual(original.protocolType, decoded.protocolType)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.suggestedDuration, decoded.suggestedDuration)
        XCTAssertEqual(original.priority, decoded.priority)
    }
}

// MARK: - ImpactCategory Tests

final class ImpactCategoryTests: XCTestCase {

    func testImpactCategory_RawValues() {
        XCTAssertEqual(ImpactCategory.strongPositive.rawValue, "strongPositive")
        XCTAssertEqual(ImpactCategory.positive.rawValue, "positive")
        XCTAssertEqual(ImpactCategory.neutral.rawValue, "neutral")
        XCTAssertEqual(ImpactCategory.negative.rawValue, "negative")
        XCTAssertEqual(ImpactCategory.strongNegative.rawValue, "strongNegative")
    }
}
