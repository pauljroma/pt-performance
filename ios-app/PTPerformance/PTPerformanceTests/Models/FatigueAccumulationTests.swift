//
//  FatigueAccumulationTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueAccumulation model
//  Tests ACR calculations, training load calculations, and consecutive low readiness tracking
//

import XCTest
@testable import PTPerformance

final class FatigueAccumulationModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testFatigueAccumulation_MemberwiseInit_AllFields() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let fatigue = FatigueAccumulation(
            id: id,
            patientId: patientId,
            calculationDate: date,
            avgReadiness7d: 65.0,
            avgReadiness14d: 70.0,
            trainingLoad7d: 1200.0,
            trainingLoad14d: 2200.0,
            acuteChronicRatio: 1.1,
            consecutiveLowReadiness: 2,
            missedRepsCount7d: 3,
            highRpeCount7d: 4,
            painReports7d: 1,
            fatigueScore: 55.0,
            fatigueBand: .moderate,
            deloadRecommended: false,
            deloadUrgency: .suggested,
            createdAt: date,
            updatedAt: date
        )

        XCTAssertEqual(fatigue.id, id)
        XCTAssertEqual(fatigue.patientId, patientId)
        XCTAssertEqual(fatigue.calculationDate, date)
        XCTAssertEqual(fatigue.avgReadiness7d, 65.0)
        XCTAssertEqual(fatigue.avgReadiness14d, 70.0)
        XCTAssertEqual(fatigue.trainingLoad7d, 1200.0)
        XCTAssertEqual(fatigue.trainingLoad14d, 2200.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 1.1)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 2)
        XCTAssertEqual(fatigue.missedRepsCount7d, 3)
        XCTAssertEqual(fatigue.highRpeCount7d, 4)
        XCTAssertEqual(fatigue.painReports7d, 1)
        XCTAssertEqual(fatigue.fatigueScore, 55.0)
        XCTAssertEqual(fatigue.fatigueBand, .moderate)
        XCTAssertFalse(fatigue.deloadRecommended)
        XCTAssertEqual(fatigue.deloadUrgency, .suggested)
    }

    func testFatigueAccumulation_DefaultValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date()
        )

        XCTAssertNil(fatigue.avgReadiness7d)
        XCTAssertNil(fatigue.avgReadiness14d)
        XCTAssertNil(fatigue.trainingLoad7d)
        XCTAssertNil(fatigue.trainingLoad14d)
        XCTAssertNil(fatigue.acuteChronicRatio)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 0)
        XCTAssertEqual(fatigue.missedRepsCount7d, 0)
        XCTAssertEqual(fatigue.highRpeCount7d, 0)
        XCTAssertEqual(fatigue.painReports7d, 0)
        XCTAssertEqual(fatigue.fatigueScore, 0.0)
        XCTAssertEqual(fatigue.fatigueBand, .low)
        XCTAssertFalse(fatigue.deloadRecommended)
        XCTAssertEqual(fatigue.deloadUrgency, .none)
        XCTAssertNil(fatigue.createdAt)
        XCTAssertNil(fatigue.updatedAt)
    }

    func testFatigueAccumulation_Identifiable() {
        let id = UUID()
        let fatigue = FatigueAccumulation(
            id: id,
            patientId: UUID(),
            calculationDate: Date()
        )

        XCTAssertEqual(fatigue.id, id)
    }

    // MARK: - ACR (Acute:Chronic Ratio) Tests

    func testACR_OptimalRange() {
        // Optimal ACR is typically between 0.8 and 1.3
        let optimalACR = 1.1
        let fatigue = createFatigueWithACR(optimalACR)

        XCTAssertEqual(fatigue.acuteChronicRatio, optimalACR)
        XCTAssertTrue(isACROptimal(optimalACR))
    }

    func testACR_HighRiskRange() {
        // ACR > 1.5 indicates high injury/overtraining risk
        let highRiskACR = 1.6
        let fatigue = createFatigueWithACR(highRiskACR)

        XCTAssertEqual(fatigue.acuteChronicRatio, highRiskACR)
        XCTAssertTrue(isACRHighRisk(highRiskACR))
    }

    func testACR_LowRange() {
        // ACR < 0.8 indicates potential detraining
        let lowACR = 0.6
        let fatigue = createFatigueWithACR(lowACR)

        XCTAssertEqual(fatigue.acuteChronicRatio, lowACR)
        XCTAssertTrue(isACRLow(lowACR))
    }

    func testACR_BoundaryValues() {
        // Test boundary values
        XCTAssertTrue(isACROptimal(0.8))
        XCTAssertTrue(isACROptimal(1.3))
        XCTAssertFalse(isACROptimal(0.79))
        XCTAssertFalse(isACROptimal(1.31))
    }

    func testACR_Calculation_FromLoads() {
        // ACR = Acute Load (7d) / Chronic Load (14d average per week)
        let trainingLoad7d = 1400.0
        let trainingLoad14d = 2400.0

        // Chronic load per week = trainingLoad14d / 2
        let chronicLoadPerWeek = trainingLoad14d / 2.0
        let expectedACR = trainingLoad7d / chronicLoadPerWeek

        XCTAssertEqual(expectedACR, 1.1667, accuracy: 0.01)
    }

    func testACR_WithZeroChronicLoad() {
        // Edge case: zero chronic load should handle gracefully
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: 1200.0,
            trainingLoad14d: 0.0,
            acuteChronicRatio: nil
        )

        XCTAssertNil(fatigue.acuteChronicRatio)
    }

    func testACR_ExtremeValues() {
        // Very high ACR (overreaching)
        let extremeHighACR = 2.5
        XCTAssertTrue(isACRHighRisk(extremeHighACR))

        // Very low ACR (significant detraining)
        let extremeLowACR = 0.3
        XCTAssertTrue(isACRLow(extremeLowACR))
    }

    // MARK: - Training Load Calculation Tests

    func testTrainingLoad_7DayWindow() {
        let load7d = 1500.0
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: load7d
        )

        XCTAssertEqual(fatigue.trainingLoad7d, load7d)
    }

    func testTrainingLoad_14DayWindow() {
        let load14d = 2800.0
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad14d: load14d
        )

        XCTAssertEqual(fatigue.trainingLoad14d, load14d)
    }

    func testTrainingLoad_Relationship() {
        // Typically 7d load should be about half of 14d load (or less if ramping up)
        let load7d = 1400.0
        let load14d = 2800.0

        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: load7d,
            trainingLoad14d: load14d
        )

        // 7d load should be <= 14d load (unless there's an error)
        XCTAssertLessThanOrEqual(fatigue.trainingLoad7d ?? 0, fatigue.trainingLoad14d ?? 0)
    }

    func testTrainingLoad_HighVolume() {
        // Test high training load scenario
        let highLoad7d = 3000.0
        let highLoad14d = 5500.0

        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: highLoad7d,
            trainingLoad14d: highLoad14d
        )

        XCTAssertEqual(fatigue.trainingLoad7d, highLoad7d)
        XCTAssertEqual(fatigue.trainingLoad14d, highLoad14d)
    }

    func testTrainingLoad_LowVolume() {
        // Test low training load (deload or recovery week)
        let lowLoad7d = 400.0
        let lowLoad14d = 1200.0

        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: lowLoad7d,
            trainingLoad14d: lowLoad14d
        )

        XCTAssertEqual(fatigue.trainingLoad7d, lowLoad7d)
        XCTAssertEqual(fatigue.trainingLoad14d, lowLoad14d)
    }

    func testTrainingLoad_ZeroLoad() {
        // Test zero load (complete rest)
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: 0.0,
            trainingLoad14d: 500.0
        )

        XCTAssertEqual(fatigue.trainingLoad7d, 0.0)
    }

    // MARK: - Consecutive Low Readiness Tracking Tests

    func testConsecutiveLowReadiness_Zero() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            consecutiveLowReadiness: 0
        )

        XCTAssertEqual(fatigue.consecutiveLowReadiness, 0)
        XCTAssertFalse(shouldRecommendDeload(consecutiveDays: 0))
    }

    func testConsecutiveLowReadiness_OneTwodays() {
        // 1-2 consecutive low days = warning but not critical
        for days in 1...2 {
            let fatigue = FatigueAccumulation(
                id: UUID(),
                patientId: UUID(),
                calculationDate: Date(),
                consecutiveLowReadiness: days
            )

            XCTAssertEqual(fatigue.consecutiveLowReadiness, days)
            XCTAssertFalse(shouldRecommendDeload(consecutiveDays: days))
        }
    }

    func testConsecutiveLowReadiness_ThreeToFourDays() {
        // 3-4 consecutive low days = consider deload
        for days in 3...4 {
            let fatigue = FatigueAccumulation(
                id: UUID(),
                patientId: UUID(),
                calculationDate: Date(),
                consecutiveLowReadiness: days
            )

            XCTAssertEqual(fatigue.consecutiveLowReadiness, days)
            XCTAssertTrue(shouldConsiderDeload(consecutiveDays: days))
        }
    }

    func testConsecutiveLowReadiness_FivePlusDays() {
        // 5+ consecutive low days = deload required
        for days in 5...7 {
            let fatigue = FatigueAccumulation(
                id: UUID(),
                patientId: UUID(),
                calculationDate: Date(),
                consecutiveLowReadiness: days
            )

            XCTAssertEqual(fatigue.consecutiveLowReadiness, days)
            XCTAssertTrue(shouldRequireDeload(consecutiveDays: days))
        }
    }

    func testConsecutiveLowReadiness_ExtendedPeriod() {
        // Extended low readiness (7+ days)
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            consecutiveLowReadiness: 10
        )

        XCTAssertEqual(fatigue.consecutiveLowReadiness, 10)
        XCTAssertTrue(shouldRequireDeload(consecutiveDays: 10))
    }

    // MARK: - Average Readiness Tests

    func testAvgReadiness_7Day() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 72.5
        )

        XCTAssertEqual(fatigue.avgReadiness7d, 72.5)
    }

    func testAvgReadiness_14Day() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness14d: 68.0
        )

        XCTAssertEqual(fatigue.avgReadiness14d, 68.0)
    }

    func testAvgReadiness_Comparison() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 65.0,
            avgReadiness14d: 72.0
        )

        // If 7d readiness is lower than 14d, fatigue is accumulating
        let fatigueAccumulating = (fatigue.avgReadiness7d ?? 0) < (fatigue.avgReadiness14d ?? 0)
        XCTAssertTrue(fatigueAccumulating)
    }

    func testAvgReadiness_HighReadiness() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 85.0,
            avgReadiness14d: 82.0
        )

        // High readiness indicates good recovery
        XCTAssertGreaterThan(fatigue.avgReadiness7d ?? 0, 80.0)
        XCTAssertGreaterThan(fatigue.avgReadiness14d ?? 0, 80.0)
    }

    func testAvgReadiness_LowReadiness() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 45.0,
            avgReadiness14d: 50.0
        )

        // Low readiness indicates fatigue
        XCTAssertLessThan(fatigue.avgReadiness7d ?? 100, 60.0)
    }

    // MARK: - Fatigue Indicators Tests

    func testMissedRepsCount() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            missedRepsCount7d: 8
        )

        XCTAssertEqual(fatigue.missedRepsCount7d, 8)
    }

    func testHighRPECount() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            highRpeCount7d: 6
        )

        XCTAssertEqual(fatigue.highRpeCount7d, 6)
    }

    func testPainReportsCount() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            painReports7d: 3
        )

        XCTAssertEqual(fatigue.painReports7d, 3)
    }

    func testMultipleFatigueIndicators() {
        // High counts across multiple indicators = high fatigue
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            missedRepsCount7d: 10,
            highRpeCount7d: 8,
            painReports7d: 4
        )

        let totalIndicators = fatigue.missedRepsCount7d + fatigue.highRpeCount7d + fatigue.painReports7d
        XCTAssertEqual(totalIndicators, 22)
        XCTAssertTrue(totalIndicators > 15, "Multiple high indicators suggest fatigue")
    }

    // MARK: - Fatigue Score Tests

    func testFatigueScore_Low() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 25.0,
            fatigueBand: .low
        )

        XCTAssertEqual(fatigue.fatigueScore, 25.0)
        XCTAssertEqual(fatigue.fatigueBand, .low)
    }

    func testFatigueScore_Moderate() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 55.0,
            fatigueBand: .moderate
        )

        XCTAssertEqual(fatigue.fatigueScore, 55.0)
        XCTAssertEqual(fatigue.fatigueBand, .moderate)
    }

    func testFatigueScore_High() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 72.0,
            fatigueBand: .high
        )

        XCTAssertEqual(fatigue.fatigueScore, 72.0)
        XCTAssertEqual(fatigue.fatigueBand, .high)
    }

    func testFatigueScore_Critical() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 88.0,
            fatigueBand: .critical
        )

        XCTAssertEqual(fatigue.fatigueScore, 88.0)
        XCTAssertEqual(fatigue.fatigueBand, .critical)
    }

    func testFatigueScore_Boundary() {
        // Test boundary values
        let boundary40 = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 40.0,
            fatigueBand: .moderate
        )
        XCTAssertEqual(boundary40.fatigueBand, .moderate)

        let boundary60 = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 60.0,
            fatigueBand: .high
        )
        XCTAssertEqual(boundary60.fatigueBand, .high)

        let boundary80 = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 80.0,
            fatigueBand: .critical
        )
        XCTAssertEqual(boundary80.fatigueBand, .critical)
    }

    // MARK: - Deload Recommendation Tests

    func testDeloadRecommended_True() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            deloadRecommended: true,
            deloadUrgency: .required
        )

        XCTAssertTrue(fatigue.deloadRecommended)
        XCTAssertEqual(fatigue.deloadUrgency, .required)
    }

    func testDeloadRecommended_False() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            deloadRecommended: false,
            deloadUrgency: .none
        )

        XCTAssertFalse(fatigue.deloadRecommended)
        XCTAssertEqual(fatigue.deloadUrgency, .none)
    }

    func testDeloadRecommended_WithSuggestedUrgency() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            deloadRecommended: false,
            deloadUrgency: .suggested
        )

        // Suggested doesn't mean recommended yet
        XCTAssertFalse(fatigue.deloadRecommended)
        XCTAssertEqual(fatigue.deloadUrgency, .suggested)
    }

    // MARK: - Sample Data Tests

    func testSample_ModerateFatigue() {
        let sample = FatigueAccumulation.sample

        XCTAssertEqual(sample.avgReadiness7d, 65.0)
        XCTAssertEqual(sample.avgReadiness14d, 70.0)
        XCTAssertEqual(sample.trainingLoad7d, 1200.0)
        XCTAssertEqual(sample.trainingLoad14d, 2200.0)
        XCTAssertEqual(sample.acuteChronicRatio, 1.1)
        XCTAssertEqual(sample.consecutiveLowReadiness, 2)
        XCTAssertEqual(sample.fatigueScore, 55.0)
        XCTAssertEqual(sample.fatigueBand, .moderate)
        XCTAssertFalse(sample.deloadRecommended)
    }

    func testSample_HighFatigue() {
        let sample = FatigueAccumulation.highFatigueSample

        XCTAssertEqual(sample.avgReadiness7d, 45.0)
        XCTAssertEqual(sample.avgReadiness14d, 55.0)
        XCTAssertEqual(sample.acuteChronicRatio, 1.5)
        XCTAssertEqual(sample.consecutiveLowReadiness, 4)
        XCTAssertEqual(sample.fatigueScore, 78.0)
        XCTAssertEqual(sample.fatigueBand, .critical)
        XCTAssertTrue(sample.deloadRecommended)
        XCTAssertEqual(sample.deloadUrgency, .required)
    }

    // MARK: - Edge Cases Tests

    func testEdgeCase_AllNilOptionals() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date()
        )

        XCTAssertNil(fatigue.avgReadiness7d)
        XCTAssertNil(fatigue.avgReadiness14d)
        XCTAssertNil(fatigue.trainingLoad7d)
        XCTAssertNil(fatigue.trainingLoad14d)
        XCTAssertNil(fatigue.acuteChronicRatio)
        XCTAssertNil(fatigue.createdAt)
        XCTAssertNil(fatigue.updatedAt)
    }

    func testEdgeCase_ExtremeValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 0.0,
            avgReadiness14d: 100.0,
            trainingLoad7d: 10000.0,
            trainingLoad14d: 20000.0,
            acuteChronicRatio: 3.0,
            consecutiveLowReadiness: 14,
            missedRepsCount7d: 100,
            highRpeCount7d: 50,
            painReports7d: 10,
            fatigueScore: 100.0,
            fatigueBand: .critical
        )

        XCTAssertEqual(fatigue.fatigueScore, 100.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 3.0)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 14)
    }

    func testEdgeCase_ZeroValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 0.0,
            avgReadiness14d: 0.0,
            trainingLoad7d: 0.0,
            trainingLoad14d: 0.0,
            acuteChronicRatio: 0.0,
            fatigueScore: 0.0
        )

        XCTAssertEqual(fatigue.avgReadiness7d, 0.0)
        XCTAssertEqual(fatigue.trainingLoad7d, 0.0)
        XCTAssertEqual(fatigue.fatigueScore, 0.0)
    }

    // MARK: - Helper Methods

    private func createFatigueWithACR(_ acr: Double) -> FatigueAccumulation {
        return FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            trainingLoad7d: 1200.0,
            trainingLoad14d: 2400.0,
            acuteChronicRatio: acr
        )
    }

    private func isACROptimal(_ acr: Double) -> Bool {
        return acr >= 0.8 && acr <= 1.3
    }

    private func isACRHighRisk(_ acr: Double) -> Bool {
        return acr > 1.5
    }

    private func isACRLow(_ acr: Double) -> Bool {
        return acr < 0.8
    }

    private func shouldRecommendDeload(consecutiveDays: Int) -> Bool {
        return consecutiveDays >= 3
    }

    private func shouldConsiderDeload(consecutiveDays: Int) -> Bool {
        return consecutiveDays >= 3 && consecutiveDays < 5
    }

    private func shouldRequireDeload(consecutiveDays: Int) -> Bool {
        return consecutiveDays >= 5
    }
}

// MARK: - Codable Tests

final class FatigueAccumulationCodableTests: XCTestCase {

    func testDecoding_WithStringNumericValues() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": "72.5",
            "avg_readiness_14d": "75.0",
            "training_load_7d": "1500.0",
            "training_load_14d": "2800.0",
            "acute_chronic_ratio": "1.25",
            "consecutive_low_readiness": 1,
            "missed_reps_count_7d": 2,
            "high_rpe_count_7d": 3,
            "pain_reports_7d": 0,
            "fatigue_score": "45.5",
            "fatigue_band": "moderate",
            "deload_recommended": false,
            "deload_urgency": "none"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertEqual(fatigue.avgReadiness7d, 72.5)
        XCTAssertEqual(fatigue.avgReadiness14d, 75.0)
        XCTAssertEqual(fatigue.trainingLoad7d, 1500.0)
        XCTAssertEqual(fatigue.trainingLoad14d, 2800.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 1.25)
        XCTAssertEqual(fatigue.fatigueScore, 45.5)
    }

    func testDecoding_WithDoubleNumericValues() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": 72.5,
            "avg_readiness_14d": 75.0,
            "training_load_7d": 1500.0,
            "training_load_14d": 2800.0,
            "acute_chronic_ratio": 1.25,
            "fatigue_score": 45.5,
            "fatigue_band": "low",
            "deload_urgency": "suggested"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertEqual(fatigue.avgReadiness7d, 72.5)
        XCTAssertEqual(fatigue.fatigueScore, 45.5)
        XCTAssertEqual(fatigue.fatigueBand, .low)
    }

    func testDecoding_WithNullOptionalValues() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": null,
            "avg_readiness_14d": null,
            "training_load_7d": null,
            "training_load_14d": null,
            "acute_chronic_ratio": null,
            "fatigue_score": 0,
            "fatigue_band": "low",
            "deload_urgency": "none"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertNil(fatigue.avgReadiness7d)
        XCTAssertNil(fatigue.avgReadiness14d)
        XCTAssertNil(fatigue.trainingLoad7d)
        XCTAssertNil(fatigue.trainingLoad14d)
        XCTAssertNil(fatigue.acuteChronicRatio)
    }

    func testDecoding_AllFatigueBands() throws {
        let bands = ["low", "moderate", "high", "critical"]

        for band in bands {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "calculation_date": "2024-01-15",
                "fatigue_score": 50.0,
                "fatigue_band": "\(band)",
                "deload_urgency": "none"
            }
            """.data(using: .utf8)!

            let decoder = PTSupabaseClient.flexibleDecoder
            let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

            XCTAssertEqual(fatigue.fatigueBand.rawValue, band)
        }
    }

    func testDecoding_AllDeloadUrgencies() throws {
        let urgencies = ["none", "suggested", "recommended", "required"]

        for urgency in urgencies {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "calculation_date": "2024-01-15",
                "fatigue_score": 50.0,
                "fatigue_band": "moderate",
                "deload_urgency": "\(urgency)"
            }
            """.data(using: .utf8)!

            let decoder = PTSupabaseClient.flexibleDecoder
            let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

            XCTAssertEqual(fatigue.deloadUrgency.rawValue, urgency)
        }
    }
}
