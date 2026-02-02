//
//  ReadinessServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ReadinessService
//  Tests band calculations, category classification, score interpretation,
//  input validation, and display properties
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - ReadinessCategory Tests

final class ReadinessCategoryTests: XCTestCase {

    // MARK: - Score Classification Tests

    func testCategory_Elite_Score90To100() {
        XCTAssertEqual(ReadinessCategory.category(for: 90.0), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 95.0), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 100.0), .elite)
    }

    func testCategory_High_Score75To89() {
        XCTAssertEqual(ReadinessCategory.category(for: 75.0), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 80.0), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 89.9), .high)
    }

    func testCategory_Moderate_Score60To74() {
        XCTAssertEqual(ReadinessCategory.category(for: 60.0), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 67.0), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 74.9), .moderate)
    }

    func testCategory_Low_Score45To59() {
        XCTAssertEqual(ReadinessCategory.category(for: 45.0), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 52.0), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 59.9), .low)
    }

    func testCategory_Poor_ScoreBelow45() {
        XCTAssertEqual(ReadinessCategory.category(for: 0.0), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 30.0), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 44.9), .poor)
    }

    func testCategory_BoundaryValues() {
        // Test exact boundaries
        XCTAssertEqual(ReadinessCategory.category(for: 44.9999), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 45.0), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 59.9999), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 60.0), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 74.9999), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 75.0), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 89.9999), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 90.0), .elite)
    }

    // MARK: - Raw Value Tests

    func testCategory_RawValues() {
        XCTAssertEqual(ReadinessCategory.elite.rawValue, "Elite")
        XCTAssertEqual(ReadinessCategory.high.rawValue, "High")
        XCTAssertEqual(ReadinessCategory.moderate.rawValue, "Moderate")
        XCTAssertEqual(ReadinessCategory.low.rawValue, "Low")
        XCTAssertEqual(ReadinessCategory.poor.rawValue, "Poor")
    }

    // MARK: - Display Properties Tests

    func testCategory_DisplayNames() {
        XCTAssertEqual(ReadinessCategory.elite.displayName, "Elite")
        XCTAssertEqual(ReadinessCategory.high.displayName, "High")
        XCTAssertEqual(ReadinessCategory.moderate.displayName, "Moderate")
        XCTAssertEqual(ReadinessCategory.low.displayName, "Low")
        XCTAssertEqual(ReadinessCategory.poor.displayName, "Poor")
    }

    func testCategory_Colors() {
        XCTAssertEqual(ReadinessCategory.elite.color, .green)
        XCTAssertEqual(ReadinessCategory.high.color, .blue)
        XCTAssertEqual(ReadinessCategory.moderate.color, .yellow)
        XCTAssertEqual(ReadinessCategory.low.color, .orange)
        XCTAssertEqual(ReadinessCategory.poor.color, .red)
    }

    func testCategory_ScoreRanges() {
        XCTAssertEqual(ReadinessCategory.elite.scoreRange, "90-100")
        XCTAssertEqual(ReadinessCategory.high.scoreRange, "75-89")
        XCTAssertEqual(ReadinessCategory.moderate.scoreRange, "60-74")
        XCTAssertEqual(ReadinessCategory.low.scoreRange, "45-59")
        XCTAssertEqual(ReadinessCategory.poor.scoreRange, "0-44")
    }

    // MARK: - Recommendation Tests

    func testCategory_Recommendations() {
        XCTAssertEqual(ReadinessCategory.elite.recommendation, "Ready for high intensity training")
        XCTAssertEqual(ReadinessCategory.high.recommendation, "Ready for normal training load")
        XCTAssertEqual(ReadinessCategory.moderate.recommendation, "Proceed with caution, consider lighter work")
        XCTAssertEqual(ReadinessCategory.low.recommendation, "Consider light work or active recovery")
        XCTAssertEqual(ReadinessCategory.poor.recommendation, "Rest recommended, avoid intense training")
    }

    // MARK: - Training Modification Tests

    func testCategory_VolumeAdjustment() {
        XCTAssertEqual(ReadinessCategory.elite.volumeAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.high.volumeAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.moderate.volumeAdjustment, -0.15, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.low.volumeAdjustment, -0.30, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.poor.volumeAdjustment, -0.50, accuracy: 0.001)
    }

    func testCategory_IntensityAdjustment() {
        XCTAssertEqual(ReadinessCategory.elite.intensityAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.high.intensityAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.moderate.intensityAdjustment, -0.10, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.low.intensityAdjustment, -0.20, accuracy: 0.001)
        XCTAssertEqual(ReadinessCategory.poor.intensityAdjustment, -0.40, accuracy: 0.001)
    }

    func testCategory_ShouldModifyTraining() {
        XCTAssertFalse(ReadinessCategory.elite.shouldModifyTraining)
        XCTAssertFalse(ReadinessCategory.high.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.moderate.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.low.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.poor.shouldModifyTraining)
    }

    func testCategory_RecommendsRest() {
        XCTAssertFalse(ReadinessCategory.elite.recommendsRest)
        XCTAssertFalse(ReadinessCategory.high.recommendsRest)
        XCTAssertFalse(ReadinessCategory.moderate.recommendsRest)
        XCTAssertFalse(ReadinessCategory.low.recommendsRest)
        XCTAssertTrue(ReadinessCategory.poor.recommendsRest)
    }

    func testCategory_AllOrdered() {
        let expected: [ReadinessCategory] = [.elite, .high, .moderate, .low, .poor]
        XCTAssertEqual(ReadinessCategory.allOrdered, expected)
    }
}

// MARK: - ReadinessScoreHelper Tests

final class ReadinessScoreHelperTests: XCTestCase {

    func testScoreHelper_Category() {
        let eliteHelper = ReadinessScoreHelper(score: 95.0)
        XCTAssertEqual(eliteHelper.category, .elite)

        let poorHelper = ReadinessScoreHelper(score: 30.0)
        XCTAssertEqual(poorHelper.category, .poor)
    }

    func testScoreHelper_Color() {
        let helper = ReadinessScoreHelper(score: 85.0)
        XCTAssertEqual(helper.color, .blue) // High category
    }

    func testScoreHelper_Recommendation() {
        let helper = ReadinessScoreHelper(score: 50.0)
        XCTAssertEqual(helper.recommendation, "Consider light work or active recovery")
    }

    func testScoreHelper_ScoreText() {
        let helper = ReadinessScoreHelper(score: 78.5)
        XCTAssertEqual(helper.scoreText, "78.5")

        let roundHelper = ReadinessScoreHelper(score: 80.0)
        XCTAssertEqual(roundHelper.scoreText, "80.0")
    }

    func testScoreHelper_Samples() {
        let samples = ReadinessScoreHelper.samples
        XCTAssertEqual(samples.count, 5)

        XCTAssertEqual(samples[0].category, .elite)
        XCTAssertEqual(samples[1].category, .high)
        XCTAssertEqual(samples[2].category, .moderate)
        XCTAssertEqual(samples[3].category, .low)
        XCTAssertEqual(samples[4].category, .poor)
    }
}

// MARK: - ReadinessBand Tests

final class ReadinessBandTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testReadinessBand_RawValues() {
        XCTAssertEqual(ReadinessBand.green.rawValue, "green")
        XCTAssertEqual(ReadinessBand.yellow.rawValue, "yellow")
        XCTAssertEqual(ReadinessBand.orange.rawValue, "orange")
        XCTAssertEqual(ReadinessBand.red.rawValue, "red")
    }

    // MARK: - Display Properties Tests

    func testReadinessBand_DisplayNames() {
        XCTAssertEqual(ReadinessBand.green.displayName, "Ready to Train")
        XCTAssertEqual(ReadinessBand.yellow.displayName, "Train with Caution")
        XCTAssertEqual(ReadinessBand.orange.displayName, "Reduced Intensity")
        XCTAssertEqual(ReadinessBand.red.displayName, "Recovery Day")
    }

    func testReadinessBand_Descriptions() {
        XCTAssertTrue(ReadinessBand.green.description.contains("recovered"))
        XCTAssertTrue(ReadinessBand.yellow.description.contains("Minor fatigue"))
        XCTAssertTrue(ReadinessBand.orange.description.contains("Elevated fatigue"))
        XCTAssertTrue(ReadinessBand.red.description.contains("High fatigue"))
    }

    func testReadinessBand_Colors() {
        XCTAssertEqual(ReadinessBand.green.color, .green)
        XCTAssertEqual(ReadinessBand.yellow.color, .yellow)
        XCTAssertEqual(ReadinessBand.orange.color, .orange)
        XCTAssertEqual(ReadinessBand.red.color, .red)
    }

    // MARK: - Load Adjustment Tests

    func testReadinessBand_LoadAdjustment() {
        XCTAssertEqual(ReadinessBand.green.loadAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.yellow.loadAdjustment, -0.10, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.orange.loadAdjustment, -0.25, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.red.loadAdjustment, -0.50, accuracy: 0.001)
    }

    // MARK: - Volume Adjustment Tests

    func testReadinessBand_VolumeAdjustment() {
        XCTAssertEqual(ReadinessBand.green.volumeAdjustment, 0.0, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.yellow.volumeAdjustment, -0.10, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.orange.volumeAdjustment, -0.30, accuracy: 0.001)
        XCTAssertEqual(ReadinessBand.red.volumeAdjustment, -0.50, accuracy: 0.001)
    }
}

// MARK: - ReadinessInput Validation Tests

final class ReadinessInputValidationTests: XCTestCase {

    // MARK: - Valid Input Tests

    func testValidate_AllMetrics_DoesNotThrow() throws {
        let input = ReadinessInput(
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            notes: "Feeling good",
            patientId: UUID().uuidString,
            date: "2024-01-15"
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_OnlyOneMetic_DoesNotThrow() throws {
        let sleepOnlyInput = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil
        )
        XCTAssertNoThrow(try sleepOnlyInput.validate())

        let energyOnlyInput = ReadinessInput(
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: 7,
            stressLevel: nil
        )
        XCTAssertNoThrow(try energyOnlyInput.validate())
    }

    func testValidate_BoundaryValues_DoesNotThrow() throws {
        // Minimum valid values
        let minInput = ReadinessInput(
            sleepHours: 0,
            sorenessLevel: 1,
            energyLevel: 1,
            stressLevel: 1
        )
        XCTAssertNoThrow(try minInput.validate())

        // Maximum valid values
        let maxInput = ReadinessInput(
            sleepHours: 24,
            sorenessLevel: 10,
            energyLevel: 10,
            stressLevel: 10
        )
        XCTAssertNoThrow(try maxInput.validate())
    }

    // MARK: - Invalid Input Tests

    func testValidate_NoMetrics_Throws() {
        let input = ReadinessInput(
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .noMetricsProvided)
        }
    }

    func testValidate_InvalidSleepHours_Negative_Throws() {
        let input = ReadinessInput(
            sleepHours: -1,
            sorenessLevel: 5,
            energyLevel: 5,
            stressLevel: 5
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSleepHours)
        }
    }

    func testValidate_InvalidSleepHours_Over24_Throws() {
        let input = ReadinessInput(
            sleepHours: 25,
            sorenessLevel: 5,
            energyLevel: 5,
            stressLevel: 5
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSleepHours)
        }
    }

    func testValidate_InvalidSorenessLevel_Zero_Throws() {
        let input = ReadinessInput(
            sleepHours: 7,
            sorenessLevel: 0, // Invalid - must be 1-10
            energyLevel: 5,
            stressLevel: 5
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSorenessLevel)
        }
    }

    func testValidate_InvalidSorenessLevel_Over10_Throws() {
        let input = ReadinessInput(
            sleepHours: 7,
            sorenessLevel: 11, // Invalid
            energyLevel: 5,
            stressLevel: 5
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSorenessLevel)
        }
    }

    func testValidate_InvalidEnergyLevel_Throws() {
        let input = ReadinessInput(
            sleepHours: 7,
            sorenessLevel: 5,
            energyLevel: 0, // Invalid - must be 1-10
            stressLevel: 5
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidEnergyLevel)
        }
    }

    func testValidate_InvalidStressLevel_Throws() {
        let input = ReadinessInput(
            sleepHours: 7,
            sorenessLevel: 5,
            energyLevel: 5,
            stressLevel: 15 // Invalid
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidStressLevel)
        }
    }
}

// MARK: - DailyReadiness Tests

final class DailyReadinessTests: XCTestCase {

    // MARK: - Readiness Band Tests

    func testReadinessBand_GreenFor80Plus() {
        let readiness = createReadiness(score: 85.0)
        XCTAssertEqual(readiness.readinessBand, .green)

        let readiness80 = createReadiness(score: 80.0)
        XCTAssertEqual(readiness80.readinessBand, .green)
    }

    func testReadinessBand_YellowFor60To79() {
        let readiness = createReadiness(score: 70.0)
        XCTAssertEqual(readiness.readinessBand, .yellow)

        let readiness60 = createReadiness(score: 60.0)
        XCTAssertEqual(readiness60.readinessBand, .yellow)
    }

    func testReadinessBand_OrangeFor40To59() {
        let readiness = createReadiness(score: 50.0)
        XCTAssertEqual(readiness.readinessBand, .orange)

        let readiness40 = createReadiness(score: 40.0)
        XCTAssertEqual(readiness40.readinessBand, .orange)
    }

    func testReadinessBand_RedForBelow40() {
        let readiness = createReadiness(score: 30.0)
        XCTAssertEqual(readiness.readinessBand, .red)

        let readiness0 = createReadiness(score: 0.0)
        XCTAssertEqual(readiness0.readinessBand, .red)
    }

    func testReadinessBand_NilScore_DefaultsToYellow() {
        let readiness = createReadiness(score: nil)
        XCTAssertEqual(readiness.readinessBand, .yellow)
    }

    // MARK: - Category Tests

    func testCategory_ReturnsCorrectCategory() {
        let eliteReadiness = createReadiness(score: 95.0)
        XCTAssertEqual(eliteReadiness.category, .elite)

        let moderateReadiness = createReadiness(score: 65.0)
        XCTAssertEqual(moderateReadiness.category, .moderate)
    }

    func testCategory_NilScore_ReturnsNil() {
        let readiness = createReadiness(score: nil)
        XCTAssertNil(readiness.category)
    }

    // MARK: - Score Color Tests

    func testScoreColor_MatchesCategory() {
        let eliteReadiness = createReadiness(score: 95.0)
        XCTAssertEqual(eliteReadiness.scoreColor, .green)

        let poorReadiness = createReadiness(score: 30.0)
        XCTAssertEqual(poorReadiness.scoreColor, .red)
    }

    func testScoreColor_NilScore_ReturnsGray() {
        let readiness = createReadiness(score: nil)
        XCTAssertEqual(readiness.scoreColor, .gray)
    }

    // MARK: - Score Text Tests

    func testScoreText_FormatsCorrectly() {
        let readiness = createReadiness(score: 75.5)
        XCTAssertEqual(readiness.scoreText, "76") // Rounded

        let roundScore = createReadiness(score: 80.0)
        XCTAssertEqual(roundScore.scoreText, "80")
    }

    func testScoreText_NilScore_ReturnsDashes() {
        let readiness = createReadiness(score: nil)
        XCTAssertEqual(readiness.scoreText, "--")
    }

    // MARK: - Helper Methods

    private func createReadiness(score: Double?) -> DailyReadiness {
        return DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: score,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - ReadinessError Tests

final class ReadinessErrorTests: XCTestCase {

    func testError_InvalidSleepHours() {
        let error = ReadinessError.invalidSleepHours
        XCTAssertEqual(error.errorDescription, "Sleep hours must be between 0 and 24")
    }

    func testError_InvalidSorenessLevel() {
        let error = ReadinessError.invalidSorenessLevel
        XCTAssertEqual(error.errorDescription, "Soreness level must be between 1 and 10")
    }

    func testError_InvalidEnergyLevel() {
        let error = ReadinessError.invalidEnergyLevel
        XCTAssertEqual(error.errorDescription, "Energy level must be between 1 and 10")
    }

    func testError_InvalidStressLevel() {
        let error = ReadinessError.invalidStressLevel
        XCTAssertEqual(error.errorDescription, "Stress level must be between 1 and 10")
    }

    func testError_NoMetricsProvided() {
        let error = ReadinessError.noMetricsProvided
        XCTAssertEqual(error.errorDescription, "At least one metric must be provided")
    }

    func testError_ScoreCalculationFailed() {
        let error = ReadinessError.scoreCalculationFailed
        XCTAssertEqual(error.errorDescription, "Failed to calculate readiness score")
    }

    func testError_NoDataFound() {
        let error = ReadinessError.noDataFound
        XCTAssertEqual(error.errorDescription, "No readiness data found")
    }

    func testError_TrendCalculationFailed() {
        let error = ReadinessError.trendCalculationFailed
        XCTAssertEqual(error.errorDescription, "Failed to calculate readiness trend")
    }
}

// MARK: - JointPainLocation Tests

final class JointPainLocationTests: XCTestCase {

    func testJointPainLocation_RawValues() {
        XCTAssertEqual(JointPainLocation.shoulder.rawValue, "shoulder")
        XCTAssertEqual(JointPainLocation.elbow.rawValue, "elbow")
        XCTAssertEqual(JointPainLocation.hip.rawValue, "hip")
        XCTAssertEqual(JointPainLocation.knee.rawValue, "knee")
        XCTAssertEqual(JointPainLocation.back.rawValue, "back")
    }

    func testJointPainLocation_DisplayNames() {
        XCTAssertEqual(JointPainLocation.shoulder.displayName, "Shoulder")
        XCTAssertEqual(JointPainLocation.elbow.displayName, "Elbow")
        XCTAssertEqual(JointPainLocation.hip.displayName, "Hip")
        XCTAssertEqual(JointPainLocation.knee.displayName, "Knee")
        XCTAssertEqual(JointPainLocation.back.displayName, "Back")
    }

    func testJointPainLocation_AllCases() {
        let allCases = JointPainLocation.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.shoulder))
        XCTAssertTrue(allCases.contains(.elbow))
        XCTAssertTrue(allCases.contains(.hip))
        XCTAssertTrue(allCases.contains(.knee))
        XCTAssertTrue(allCases.contains(.back))
    }
}

// MARK: - ReadinessSummary Tests

final class ReadinessSummaryTests: XCTestCase {

    func testHasLoggedToday_WithTodayEntry() {
        let today = createReadiness(score: 75.0)
        let trend = createTrend(avgReadiness: 70.0)
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertTrue(summary.hasLoggedToday)
    }

    func testHasLoggedToday_WithoutTodayEntry() {
        let trend = createTrend(avgReadiness: 70.0)
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertFalse(summary.hasLoggedToday)
    }

    func testCurrentScore_ReturnsToday() {
        let today = createReadiness(score: 82.0)
        let trend = createTrend(avgReadiness: 70.0)
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertEqual(summary.currentScore, 82.0)
    }

    func testCurrentScore_NilWithoutToday() {
        let trend = createTrend(avgReadiness: 70.0)
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertNil(summary.currentScore)
    }

    func testAverageScore_ReturnsTrendAverage() {
        let trend = createTrend(avgReadiness: 75.5)
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertEqual(summary.averageScore, 75.5)
    }

    func testScoreChange_CalculatesDifference() {
        let today = createReadiness(score: 80.0)
        let trend = createTrend(avgReadiness: 70.0)
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertEqual(summary.scoreChange, 10.0, accuracy: 0.001)
    }

    func testScoreChange_NilWhenMissingData() {
        let trend = createTrend(avgReadiness: 70.0)
        let summaryNoToday = ReadinessSummary(today: nil, recent: [], trend: trend)
        XCTAssertNil(summaryNoToday.scoreChange)

        let trendNoAvg = createTrend(avgReadiness: nil)
        let today = createReadiness(score: 75.0)
        let summaryNoAvg = ReadinessSummary(today: today, recent: [today], trend: trendNoAvg)
        XCTAssertNil(summaryNoAvg.scoreChange)
    }

    // MARK: - Helper Methods

    private func createReadiness(score: Double?) -> DailyReadiness {
        return DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: score,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createTrend(avgReadiness: Double?) -> ReadinessTrend {
        return ReadinessTrend(
            patientId: UUID(),
            daysAnalyzed: 7,
            currentDate: Date(),
            trendData: [],
            statistics: ReadinessTrend.TrendStatistics(
                avgReadiness: avgReadiness,
                minReadiness: nil,
                maxReadiness: nil,
                avgSleep: nil,
                avgSoreness: nil,
                avgEnergy: nil,
                avgStress: nil,
                totalEntries: 0
            )
        )
    }
}
