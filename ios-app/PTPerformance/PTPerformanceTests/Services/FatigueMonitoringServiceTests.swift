//
//  FatigueMonitoringServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for fatigue monitoring functionality
//  Tests fatigue score calculation, deload recommendation logic, and historical data analysis
//

import XCTest
@testable import PTPerformance

// MARK: - Fatigue Score Calculation Tests

final class FatigueScoreCalculationTests: XCTestCase {

    // MARK: - Basic Calculation Tests

    func testFatigueScore_LowFatigue() {
        // Low fatigue scenario: good readiness, low ACR, no consecutive low days
        let score = calculateFatigueScore(
            avgReadiness7d: 82.0,
            acuteChronicRatio: 1.0,
            consecutiveLowDays: 0,
            missedReps: 0,
            highRPE: 0,
            painReports: 0
        )

        XCTAssertLessThan(score, 40.0, "Low fatigue should score below 40")
    }

    func testFatigueScore_ModerateFatigue() {
        // Moderate fatigue scenario
        let score = calculateFatigueScore(
            avgReadiness7d: 65.0,
            acuteChronicRatio: 1.2,
            consecutiveLowDays: 2,
            missedReps: 3,
            highRPE: 2,
            painReports: 0
        )

        XCTAssertGreaterThanOrEqual(score, 40.0)
        XCTAssertLessThan(score, 60.0, "Moderate fatigue should score 40-60")
    }

    func testFatigueScore_HighFatigue() {
        // High fatigue scenario
        let score = calculateFatigueScore(
            avgReadiness7d: 52.0,
            acuteChronicRatio: 1.4,
            consecutiveLowDays: 4,
            missedReps: 6,
            highRPE: 5,
            painReports: 2
        )

        XCTAssertGreaterThanOrEqual(score, 60.0)
        XCTAssertLessThan(score, 80.0, "High fatigue should score 60-80")
    }

    func testFatigueScore_CriticalFatigue() {
        // Critical fatigue scenario
        let score = calculateFatigueScore(
            avgReadiness7d: 40.0,
            acuteChronicRatio: 1.7,
            consecutiveLowDays: 6,
            missedReps: 12,
            highRPE: 8,
            painReports: 4
        )

        XCTAssertGreaterThanOrEqual(score, 80.0, "Critical fatigue should score 80+")
    }

    // MARK: - Component Weight Tests

    func testFatigueScore_ReadinessWeight() {
        // Lower readiness should increase fatigue score
        let highReadiness = calculateFatigueScore(avgReadiness7d: 85.0, acuteChronicRatio: 1.0, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)
        let lowReadiness = calculateFatigueScore(avgReadiness7d: 45.0, acuteChronicRatio: 1.0, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)

        XCTAssertLessThan(highReadiness, lowReadiness, "Lower readiness should increase fatigue score")
    }

    func testFatigueScore_ACRWeight() {
        // Higher ACR should increase fatigue score
        let normalACR = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.0, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)
        let highACR = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.6, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)

        XCTAssertLessThan(normalACR, highACR, "Higher ACR should increase fatigue score")
    }

    func testFatigueScore_ConsecutiveDaysWeight() {
        // More consecutive low days should increase fatigue score
        let zeroDays = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)
        let fiveDays = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 5, missedReps: 0, highRPE: 0, painReports: 0)

        XCTAssertLessThan(zeroDays, fiveDays, "More consecutive low days should increase fatigue score")
    }

    func testFatigueScore_MissedRepsWeight() {
        let noMissed = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)
        let manyMissed = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 0, missedReps: 10, highRPE: 0, painReports: 0)

        XCTAssertLessThan(noMissed, manyMissed, "Missed reps should increase fatigue score")
    }

    func testFatigueScore_PainReportsWeight() {
        let noPain = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 0)
        let withPain = calculateFatigueScore(avgReadiness7d: 70.0, acuteChronicRatio: 1.1, consecutiveLowDays: 0, missedReps: 0, highRPE: 0, painReports: 5)

        XCTAssertLessThan(noPain, withPain, "Pain reports should increase fatigue score")
    }

    // MARK: - Boundary Tests

    func testFatigueScore_NeverNegative() {
        let score = calculateFatigueScore(
            avgReadiness7d: 100.0,
            acuteChronicRatio: 0.5,
            consecutiveLowDays: 0,
            missedReps: 0,
            highRPE: 0,
            painReports: 0
        )

        XCTAssertGreaterThanOrEqual(score, 0.0, "Fatigue score should never be negative")
    }

    func testFatigueScore_NeverExceeds100() {
        let score = calculateFatigueScore(
            avgReadiness7d: 0.0,
            acuteChronicRatio: 3.0,
            consecutiveLowDays: 14,
            missedReps: 100,
            highRPE: 50,
            painReports: 20
        )

        XCTAssertLessThanOrEqual(score, 100.0, "Fatigue score should not exceed 100")
    }

    // MARK: - Edge Cases

    func testFatigueScore_AllZeros() {
        let score = calculateFatigueScore(
            avgReadiness7d: 0.0,
            acuteChronicRatio: 0.0,
            consecutiveLowDays: 0,
            missedReps: 0,
            highRPE: 0,
            painReports: 0
        )

        XCTAssertGreaterThanOrEqual(score, 0.0)
    }

    func testFatigueScore_PerfectCondition() {
        let score = calculateFatigueScore(
            avgReadiness7d: 100.0,
            acuteChronicRatio: 1.0,
            consecutiveLowDays: 0,
            missedReps: 0,
            highRPE: 0,
            painReports: 0
        )

        XCTAssertLessThan(score, 20.0, "Perfect condition should have very low fatigue")
    }

    // MARK: - Helper Methods

    /// Simulates fatigue score calculation
    private func calculateFatigueScore(
        avgReadiness7d: Double,
        acuteChronicRatio: Double,
        consecutiveLowDays: Int,
        missedReps: Int,
        highRPE: Int,
        painReports: Int
    ) -> Double {
        // Weight factors
        let readinessWeight = 0.25
        let acrWeight = 0.25
        let consecutiveDaysWeight = 0.20
        let performanceWeight = 0.15
        let painWeight = 0.15

        // Readiness contribution (inverted: lower readiness = higher fatigue)
        let readinessContribution = (100.0 - avgReadiness7d) * readinessWeight

        // ACR contribution (scaled: 1.0 is baseline, higher = more fatigue)
        let acrContribution = max(0, (acuteChronicRatio - 0.8) * 50) * acrWeight

        // Consecutive low days contribution
        let daysContribution = min(Double(consecutiveLowDays) * 10.0, 100.0) * consecutiveDaysWeight

        // Performance degradation contribution
        let perfContribution = min(Double(missedReps + highRPE) * 3.0, 100.0) * performanceWeight

        // Pain contribution
        let painContribution = min(Double(painReports) * 15.0, 100.0) * painWeight

        let score = readinessContribution + acrContribution + daysContribution + perfContribution + painContribution

        return min(max(score, 0), 100)
    }
}

// MARK: - Deload Recommendation Logic Tests

final class DeloadRecommendationLogicTests: XCTestCase {

    // MARK: - Recommendation Trigger Tests

    func testDeloadRecommendation_NotTriggered_LowFatigue() {
        let recommendation = shouldRecommendDeload(
            fatigueScore: 35.0,
            fatigueBand: .low,
            consecutiveLowDays: 0,
            acr: 1.0
        )

        XCTAssertFalse(recommendation.recommended)
        XCTAssertEqual(recommendation.urgency, .none)
    }

    func testDeloadRecommendation_Suggested_ModerateFatigue() {
        let recommendation = shouldRecommendDeload(
            fatigueScore: 52.0,
            fatigueBand: .moderate,
            consecutiveLowDays: 2,
            acr: 1.2
        )

        XCTAssertFalse(recommendation.recommended)
        XCTAssertEqual(recommendation.urgency, .suggested)
    }

    func testDeloadRecommendation_Recommended_HighFatigue() {
        let recommendation = shouldRecommendDeload(
            fatigueScore: 72.0,
            fatigueBand: .high,
            consecutiveLowDays: 4,
            acr: 1.4
        )

        XCTAssertTrue(recommendation.recommended)
        XCTAssertEqual(recommendation.urgency, .recommended)
    }

    func testDeloadRecommendation_Required_CriticalFatigue() {
        let recommendation = shouldRecommendDeload(
            fatigueScore: 88.0,
            fatigueBand: .critical,
            consecutiveLowDays: 6,
            acr: 1.7
        )

        XCTAssertTrue(recommendation.recommended)
        XCTAssertEqual(recommendation.urgency, .required)
    }

    // MARK: - Override Trigger Tests

    func testDeloadRecommendation_ACROverride() {
        // High ACR should trigger deload even with moderate fatigue score
        let recommendation = shouldRecommendDeload(
            fatigueScore: 55.0,
            fatigueBand: .moderate,
            consecutiveLowDays: 1,
            acr: 1.6
        )

        XCTAssertTrue(recommendation.recommended, "High ACR should trigger deload")
        XCTAssertEqual(recommendation.urgency, .required)
    }

    func testDeloadRecommendation_ConsecutiveDaysOverride() {
        // Many consecutive low days should trigger deload
        let recommendation = shouldRecommendDeload(
            fatigueScore: 50.0,
            fatigueBand: .moderate,
            consecutiveLowDays: 6,
            acr: 1.1
        )

        XCTAssertTrue(recommendation.recommended, "6+ consecutive low days should trigger deload")
        XCTAssertEqual(recommendation.urgency, .required)
    }

    // MARK: - Threshold Tests

    func testDeloadRecommendation_FatigueScoreThresholds() {
        // Test boundary values
        let below40 = shouldRecommendDeload(fatigueScore: 39.9, fatigueBand: .low, consecutiveLowDays: 0, acr: 1.0)
        XCTAssertEqual(below40.urgency, .none)

        let at40 = shouldRecommendDeload(fatigueScore: 40.0, fatigueBand: .moderate, consecutiveLowDays: 1, acr: 1.1)
        XCTAssertEqual(at40.urgency, .suggested)

        let at60 = shouldRecommendDeload(fatigueScore: 60.0, fatigueBand: .high, consecutiveLowDays: 3, acr: 1.3)
        XCTAssertEqual(at60.urgency, .recommended)

        let at80 = shouldRecommendDeload(fatigueScore: 80.0, fatigueBand: .critical, consecutiveLowDays: 5, acr: 1.5)
        XCTAssertEqual(at80.urgency, .required)
    }

    func testDeloadRecommendation_ACRThresholds() {
        // Normal ACR (0.8-1.3) - no override
        let normalACR = shouldRecommendDeload(fatigueScore: 50.0, fatigueBand: .moderate, consecutiveLowDays: 0, acr: 1.1)
        XCTAssertEqual(normalACR.urgency, .suggested)

        // Elevated ACR (1.3-1.5) - increases urgency
        let elevatedACR = shouldRecommendDeload(fatigueScore: 50.0, fatigueBand: .moderate, consecutiveLowDays: 0, acr: 1.4)
        XCTAssertEqual(elevatedACR.urgency, .recommended)

        // High ACR (>1.5) - requires deload
        let highACR = shouldRecommendDeload(fatigueScore: 50.0, fatigueBand: .moderate, consecutiveLowDays: 0, acr: 1.6)
        XCTAssertEqual(highACR.urgency, .required)
    }

    // MARK: - Prescription Generation Tests

    func testDeloadPrescription_ModerateUrgency() {
        let prescription = generatePrescription(urgency: .suggested)

        XCTAssertEqual(prescription.durationDays, 5)
        XCTAssertEqual(prescription.loadReductionPct, 0.20, accuracy: 0.01)
        XCTAssertEqual(prescription.volumeReductionPct, 0.25, accuracy: 0.01)
    }

    func testDeloadPrescription_RecommendedUrgency() {
        let prescription = generatePrescription(urgency: .recommended)

        XCTAssertEqual(prescription.durationDays, 7)
        XCTAssertEqual(prescription.loadReductionPct, 0.30, accuracy: 0.01)
        XCTAssertEqual(prescription.volumeReductionPct, 0.40, accuracy: 0.01)
    }

    func testDeloadPrescription_RequiredUrgency() {
        let prescription = generatePrescription(urgency: .required)

        XCTAssertEqual(prescription.durationDays, 7)
        XCTAssertEqual(prescription.loadReductionPct, 0.50, accuracy: 0.01)
        XCTAssertEqual(prescription.volumeReductionPct, 0.50, accuracy: 0.01)
    }

    // MARK: - Helper Methods

    private func shouldRecommendDeload(
        fatigueScore: Double,
        fatigueBand: FatigueBand,
        consecutiveLowDays: Int,
        acr: Double
    ) -> (recommended: Bool, urgency: DeloadUrgency) {
        // ACR override
        if acr >= 1.5 {
            return (true, .required)
        }

        // Consecutive days override
        if consecutiveLowDays >= 5 {
            return (true, .required)
        }

        // Score-based determination
        switch fatigueBand {
        case .low:
            return (false, .none)
        case .moderate:
            let urgency: DeloadUrgency = acr >= 1.3 ? .recommended : .suggested
            return (urgency == .recommended, urgency)
        case .high:
            return (true, .recommended)
        case .critical:
            return (true, .required)
        }
    }

    private func generatePrescription(urgency: DeloadUrgency) -> (durationDays: Int, loadReductionPct: Double, volumeReductionPct: Double) {
        switch urgency {
        case .none:
            return (0, 0.0, 0.0)
        case .suggested:
            return (5, 0.20, 0.25)
        case .recommended:
            return (7, 0.30, 0.40)
        case .required:
            return (7, 0.50, 0.50)
        }
    }
}

// MARK: - Historical Data Analysis Tests

final class HistoricalDataAnalysisTests: XCTestCase {

    // MARK: - Trend Analysis Tests

    func testTrendAnalysis_IncreasingFatigue() {
        let trendData = createTrendData(
            startScore: 40.0,
            endScore: 75.0,
            days: 7
        )

        let trend = analyzeTrend(trendData)

        XCTAssertEqual(trend.direction, .increasing)
        XCTAssertGreaterThan(trend.averageChange, 0)
    }

    func testTrendAnalysis_DecreasingFatigue() {
        let trendData = createTrendData(
            startScore: 70.0,
            endScore: 35.0,
            days: 7
        )

        let trend = analyzeTrend(trendData)

        XCTAssertEqual(trend.direction, .decreasing)
        XCTAssertLessThan(trend.averageChange, 0)
    }

    func testTrendAnalysis_StableFatigue() {
        let trendData = createTrendData(
            startScore: 50.0,
            endScore: 52.0,
            days: 7
        )

        let trend = analyzeTrend(trendData)

        XCTAssertEqual(trend.direction, .stable)
        XCTAssertLessThan(abs(trend.averageChange), 2.0)
    }

    // MARK: - No Historical Data Tests

    func testHistoricalAnalysis_NoData() {
        let trendData: [FatigueDataPoint] = []

        let analysis = analyzeHistoricalData(trendData)

        XCTAssertNil(analysis.trend)
        XCTAssertNil(analysis.averageScore)
        XCTAssertNil(analysis.peakScore)
        XCTAssertTrue(analysis.hasInsufficientData)
    }

    func testHistoricalAnalysis_SingleDataPoint() {
        let trendData = [FatigueDataPoint(date: Date(), score: 55.0)]

        let analysis = analyzeHistoricalData(trendData)

        XCTAssertNil(analysis.trend)
        XCTAssertEqual(analysis.averageScore, 55.0)
        XCTAssertEqual(analysis.peakScore, 55.0)
        XCTAssertTrue(analysis.hasInsufficientData)
    }

    func testHistoricalAnalysis_MinimumDataForTrend() {
        let trendData = createTrendData(startScore: 50.0, endScore: 60.0, days: 3)

        let analysis = analyzeHistoricalData(trendData)

        XCTAssertNotNil(analysis.trend)
        XCTAssertFalse(analysis.hasInsufficientData)
    }

    // MARK: - Incomplete Readiness Entries Tests

    func testIncompleteEntries_SomeNilScores() {
        let trendData: [FatigueDataPoint] = [
            FatigueDataPoint(date: Date().addingTimeInterval(-6 * 86400), score: 50.0),
            FatigueDataPoint(date: Date().addingTimeInterval(-5 * 86400), score: nil),
            FatigueDataPoint(date: Date().addingTimeInterval(-4 * 86400), score: 55.0),
            FatigueDataPoint(date: Date().addingTimeInterval(-3 * 86400), score: nil),
            FatigueDataPoint(date: Date().addingTimeInterval(-2 * 86400), score: 60.0),
            FatigueDataPoint(date: Date().addingTimeInterval(-1 * 86400), score: nil),
            FatigueDataPoint(date: Date(), score: 65.0)
        ]

        let analysis = analyzeHistoricalData(trendData)

        // Should use available data points only
        XCTAssertEqual(analysis.validDataPoints, 4)
        XCTAssertNotNil(analysis.averageScore)
        XCTAssertEqual(analysis.averageScore!, 57.5, accuracy: 0.1)
    }

    func testIncompleteEntries_AllNilScores() {
        let trendData: [FatigueDataPoint] = [
            FatigueDataPoint(date: Date().addingTimeInterval(-2 * 86400), score: nil),
            FatigueDataPoint(date: Date().addingTimeInterval(-1 * 86400), score: nil),
            FatigueDataPoint(date: Date(), score: nil)
        ]

        let analysis = analyzeHistoricalData(trendData)

        XCTAssertTrue(analysis.hasInsufficientData)
        XCTAssertEqual(analysis.validDataPoints, 0)
        XCTAssertNil(analysis.averageScore)
    }

    func testIncompleteEntries_GapsInData() {
        // Data with gaps (missing days)
        let trendData: [FatigueDataPoint] = [
            FatigueDataPoint(date: Date().addingTimeInterval(-10 * 86400), score: 40.0),
            FatigueDataPoint(date: Date().addingTimeInterval(-5 * 86400), score: 55.0),
            FatigueDataPoint(date: Date(), score: 70.0)
        ]

        let analysis = analyzeHistoricalData(trendData)

        XCTAssertNotNil(analysis.trend)
        // Should still detect increasing trend despite gaps
        XCTAssertEqual(analysis.trend, .increasing)
    }

    // MARK: - Extreme ACR Values Tests

    func testExtremeACR_VeryHigh() {
        let analysis = analyzeACR(2.5)

        XCTAssertEqual(analysis.risk, .critical)
        XCTAssertTrue(analysis.requiresImmediateAction)
    }

    func testExtremeACR_VeryLow() {
        let analysis = analyzeACR(0.4)

        XCTAssertEqual(analysis.risk, .detraining)
        XCTAssertTrue(analysis.requiresAttention)
    }

    func testExtremeACR_Optimal() {
        let analysis = analyzeACR(1.1)

        XCTAssertEqual(analysis.risk, .optimal)
        XCTAssertFalse(analysis.requiresImmediateAction)
        XCTAssertFalse(analysis.requiresAttention)
    }

    func testExtremeACR_ZeroValue() {
        let analysis = analyzeACR(0.0)

        XCTAssertEqual(analysis.risk, .noData)
        XCTAssertTrue(analysis.requiresAttention)
    }

    // MARK: - Recovery from Deload Tests

    func testRecoveryFromDeload_Successful() {
        // Before deload: high fatigue
        let beforeDeload = createTrendData(startScore: 75.0, endScore: 78.0, days: 3)

        // After deload: decreasing fatigue
        let afterDeload = createTrendData(startScore: 60.0, endScore: 40.0, days: 7)

        let recovery = analyzeDeloadRecovery(beforeDeload: beforeDeload, afterDeload: afterDeload)

        XCTAssertTrue(recovery.isSuccessful)
        XCTAssertGreaterThan(recovery.percentImprovement, 30.0)
    }

    func testRecoveryFromDeload_Partial() {
        let beforeDeload = createTrendData(startScore: 75.0, endScore: 78.0, days: 3)
        let afterDeload = createTrendData(startScore: 70.0, endScore: 55.0, days: 7)

        let recovery = analyzeDeloadRecovery(beforeDeload: beforeDeload, afterDeload: afterDeload)

        XCTAssertTrue(recovery.isSuccessful)
        XCTAssertGreaterThan(recovery.percentImprovement, 10.0)
        XCTAssertLessThan(recovery.percentImprovement, 40.0)
    }

    func testRecoveryFromDeload_Unsuccessful() {
        let beforeDeload = createTrendData(startScore: 75.0, endScore: 78.0, days: 3)
        let afterDeload = createTrendData(startScore: 75.0, endScore: 80.0, days: 7)

        let recovery = analyzeDeloadRecovery(beforeDeload: beforeDeload, afterDeload: afterDeload)

        XCTAssertFalse(recovery.isSuccessful)
        XCTAssertLessThanOrEqual(recovery.percentImprovement, 0.0)
    }

    func testRecoveryFromDeload_NoAfterData() {
        let beforeDeload = createTrendData(startScore: 75.0, endScore: 78.0, days: 3)
        let afterDeload: [FatigueDataPoint] = []

        let recovery = analyzeDeloadRecovery(beforeDeload: beforeDeload, afterDeload: afterDeload)

        XCTAssertFalse(recovery.isSuccessful)
        XCTAssertTrue(recovery.insufficientData)
    }

    // MARK: - Helper Types and Methods

    struct FatigueDataPoint {
        let date: Date
        let score: Double?
    }

    enum TrendDirection {
        case increasing
        case decreasing
        case stable
    }

    enum ACRRisk {
        case optimal
        case elevated
        case critical
        case detraining
        case noData
    }

    struct TrendAnalysis {
        let direction: TrendDirection
        let averageChange: Double
    }

    struct HistoricalAnalysis {
        let trend: TrendDirection?
        let averageScore: Double?
        let peakScore: Double?
        let validDataPoints: Int
        var hasInsufficientData: Bool { validDataPoints < 3 }
    }

    struct ACRAnalysis {
        let risk: ACRRisk
        let requiresImmediateAction: Bool
        let requiresAttention: Bool
    }

    struct DeloadRecoveryAnalysis {
        let isSuccessful: Bool
        let percentImprovement: Double
        let insufficientData: Bool
    }

    private func createTrendData(startScore: Double, endScore: Double, days: Int) -> [FatigueDataPoint] {
        guard days > 0 else { return [] }

        let increment = (endScore - startScore) / Double(days - 1)

        return (0..<days).map { dayOffset in
            let date = Date().addingTimeInterval(Double(-days + 1 + dayOffset) * 86400)
            let score = startScore + (increment * Double(dayOffset))
            return FatigueDataPoint(date: date, score: score)
        }
    }

    private func analyzeTrend(_ data: [FatigueDataPoint]) -> TrendAnalysis {
        let validScores = data.compactMap { $0.score }
        guard validScores.count >= 2 else {
            return TrendAnalysis(direction: .stable, averageChange: 0)
        }

        let changes = zip(validScores, validScores.dropFirst()).map { $1 - $0 }
        let avgChange = changes.reduce(0, +) / Double(changes.count)

        let direction: TrendDirection
        if avgChange > 2.0 {
            direction = .increasing
        } else if avgChange < -2.0 {
            direction = .decreasing
        } else {
            direction = .stable
        }

        return TrendAnalysis(direction: direction, averageChange: avgChange)
    }

    private func analyzeHistoricalData(_ data: [FatigueDataPoint]) -> HistoricalAnalysis {
        let validScores = data.compactMap { $0.score }

        guard !validScores.isEmpty else {
            return HistoricalAnalysis(
                trend: nil,
                averageScore: nil,
                peakScore: nil,
                validDataPoints: 0
            )
        }

        let avgScore = validScores.reduce(0, +) / Double(validScores.count)
        let peakScore = validScores.max()

        let trend: TrendDirection?
        if validScores.count >= 3 {
            let trendAnalysis = analyzeTrend(data)
            trend = trendAnalysis.direction
        } else {
            trend = nil
        }

        return HistoricalAnalysis(
            trend: trend,
            averageScore: avgScore,
            peakScore: peakScore,
            validDataPoints: validScores.count
        )
    }

    private func analyzeACR(_ acr: Double) -> ACRAnalysis {
        if acr == 0 {
            return ACRAnalysis(risk: .noData, requiresImmediateAction: false, requiresAttention: true)
        } else if acr < 0.6 {
            return ACRAnalysis(risk: .detraining, requiresImmediateAction: false, requiresAttention: true)
        } else if acr >= 0.8 && acr <= 1.3 {
            return ACRAnalysis(risk: .optimal, requiresImmediateAction: false, requiresAttention: false)
        } else if acr > 1.3 && acr <= 1.5 {
            return ACRAnalysis(risk: .elevated, requiresImmediateAction: false, requiresAttention: true)
        } else {
            return ACRAnalysis(risk: .critical, requiresImmediateAction: true, requiresAttention: true)
        }
    }

    private func analyzeDeloadRecovery(beforeDeload: [FatigueDataPoint], afterDeload: [FatigueDataPoint]) -> DeloadRecoveryAnalysis {
        let beforeScores = beforeDeload.compactMap { $0.score }
        let afterScores = afterDeload.compactMap { $0.score }

        guard !beforeScores.isEmpty, !afterScores.isEmpty else {
            return DeloadRecoveryAnalysis(isSuccessful: false, percentImprovement: 0, insufficientData: true)
        }

        let avgBefore = beforeScores.reduce(0, +) / Double(beforeScores.count)
        let avgAfter = afterScores.reduce(0, +) / Double(afterScores.count)

        let improvement = avgBefore - avgAfter
        let percentImprovement = (improvement / avgBefore) * 100

        return DeloadRecoveryAnalysis(
            isSuccessful: percentImprovement > 10,
            percentImprovement: percentImprovement,
            insufficientData: false
        )
    }
}

// MARK: - FatigueTrackingService Tests

@MainActor
final class FatigueMonitoringServiceTests: XCTestCase {

    var service: FatigueTrackingService!

    override func setUp() async throws {
        try await super.setUp()
        service = FatigueTrackingService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testService_Initialization() {
        XCTAssertNotNil(service)
        XCTAssertNil(service.currentFatigue)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    // MARK: - Fatigue Summary Tests

    func testGetFatigueSummary_WithCurrentFatigue() {
        service.currentFatigue = FatigueAccumulation.sample

        let summary = service.getFatigueSummary()

        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.band, .moderate)
        XCTAssertEqual(summary?.score, 55.0)
        XCTAssertEqual(summary?.urgency, .suggested)
    }

    func testGetFatigueSummary_WithoutCurrentFatigue() {
        service.currentFatigue = nil

        let summary = service.getFatigueSummary()

        XCTAssertNil(summary)
    }

    func testGetFatigueSummary_HighFatigue() {
        service.currentFatigue = FatigueAccumulation.highFatigueSample

        let summary = service.getFatigueSummary()

        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.band, .critical)
        XCTAssertEqual(summary?.score, 78.0)
        XCTAssertEqual(summary?.urgency, .required)
    }

    // MARK: - Clear Error Tests

    func testClearError() {
        service.error = "Test error message"

        service.clearError()

        XCTAssertNil(service.error)
    }

    // MARK: - High Fatigue Detection Tests

    func testHighFatigueDetection_WithHighBand() {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 75.0,
            fatigueBand: .high
        )

        let isHighFatigue = service.currentFatigue?.fatigueBand == .high ||
                           service.currentFatigue?.fatigueBand == .critical
        XCTAssertTrue(isHighFatigue)
    }

    func testHighFatigueDetection_WithCriticalBand() {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 88.0,
            fatigueBand: .critical
        )

        let isHighFatigue = service.currentFatigue?.fatigueBand == .high ||
                           service.currentFatigue?.fatigueBand == .critical
        XCTAssertTrue(isHighFatigue)
    }

    func testHighFatigueDetection_WithLowBand() {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 30.0,
            fatigueBand: .low
        )

        let isHighFatigue = service.currentFatigue?.fatigueBand == .high ||
                           service.currentFatigue?.fatigueBand == .critical
        XCTAssertFalse(isHighFatigue)
    }

    func testHighFatigueDetection_WithNilFatigue() {
        service.currentFatigue = nil

        let hasHighFatigue = service.currentFatigue?.fatigueBand == .high ||
                            service.currentFatigue?.fatigueBand == .critical
        XCTAssertFalse(hasHighFatigue)
    }
}
