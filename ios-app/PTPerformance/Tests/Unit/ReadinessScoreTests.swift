//
//  ReadinessScoreTests.swift
//  PTPerformanceTests
//
//  Unit tests for ReadinessScoreHelper and ReadinessCategory
//  Tests score categorization, computed properties, and training adjustments
//

import XCTest
@testable import PTPerformance

final class ReadinessScoreTests: XCTestCase {

    // MARK: - Score Categorization Tests

    func testEliteCategoryForScores90To100() {
        // Test boundary and middle values
        XCTAssertEqual(ReadinessCategory.category(for: 90), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 95), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 100), .elite)
    }

    func testHighCategoryForScores75To89() {
        XCTAssertEqual(ReadinessCategory.category(for: 75), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 82), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 89.9), .high)
    }

    func testModerateCategoryForScores60To74() {
        XCTAssertEqual(ReadinessCategory.category(for: 60), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 67), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 74.9), .moderate)
    }

    func testLowCategoryForScores45To59() {
        XCTAssertEqual(ReadinessCategory.category(for: 45), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 52), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 59.9), .low)
    }

    func testPoorCategoryForScoresBelow45() {
        XCTAssertEqual(ReadinessCategory.category(for: 44), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 25), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 0), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: -10), .poor) // Edge case: negative
    }

    // MARK: - ReadinessScoreHelper Tests

    func testScoreHelperCategoryMapping() {
        let eliteHelper = ReadinessScoreHelper(score: 95)
        XCTAssertEqual(eliteHelper.category, .elite)

        let highHelper = ReadinessScoreHelper(score: 80)
        XCTAssertEqual(highHelper.category, .high)

        let moderateHelper = ReadinessScoreHelper(score: 65)
        XCTAssertEqual(moderateHelper.category, .moderate)

        let lowHelper = ReadinessScoreHelper(score: 50)
        XCTAssertEqual(lowHelper.category, .low)

        let poorHelper = ReadinessScoreHelper(score: 35)
        XCTAssertEqual(poorHelper.category, .poor)
    }

    func testScoreText() {
        let helper = ReadinessScoreHelper(score: 85.7)
        XCTAssertEqual(helper.scoreText, "85.7")

        let wholeNumber = ReadinessScoreHelper(score: 90.0)
        XCTAssertEqual(wholeNumber.scoreText, "90.0")
    }

    func testRecommendationFromHelper() {
        let eliteHelper = ReadinessScoreHelper(score: 95)
        XCTAssertEqual(eliteHelper.recommendation, "Ready for high intensity training")

        let poorHelper = ReadinessScoreHelper(score: 30)
        XCTAssertEqual(poorHelper.recommendation, "Rest recommended, avoid intense training")
    }

    // MARK: - Category Display Property Tests

    func testCategoryDisplayName() {
        XCTAssertEqual(ReadinessCategory.elite.displayName, "Elite")
        XCTAssertEqual(ReadinessCategory.high.displayName, "High")
        XCTAssertEqual(ReadinessCategory.moderate.displayName, "Moderate")
        XCTAssertEqual(ReadinessCategory.low.displayName, "Low")
        XCTAssertEqual(ReadinessCategory.poor.displayName, "Poor")
    }

    func testCategoryScoreRange() {
        XCTAssertEqual(ReadinessCategory.elite.scoreRange, "90-100")
        XCTAssertEqual(ReadinessCategory.high.scoreRange, "75-89")
        XCTAssertEqual(ReadinessCategory.moderate.scoreRange, "60-74")
        XCTAssertEqual(ReadinessCategory.low.scoreRange, "45-59")
        XCTAssertEqual(ReadinessCategory.poor.scoreRange, "0-44")
    }

    func testCategoryRecommendations() {
        XCTAssertEqual(ReadinessCategory.elite.recommendation, "Ready for high intensity training")
        XCTAssertEqual(ReadinessCategory.high.recommendation, "Ready for normal training load")
        XCTAssertEqual(ReadinessCategory.moderate.recommendation, "Proceed with caution, consider lighter work")
        XCTAssertEqual(ReadinessCategory.low.recommendation, "Consider light work or active recovery")
        XCTAssertEqual(ReadinessCategory.poor.recommendation, "Rest recommended, avoid intense training")
    }

    func testFullDescription() {
        let eliteDescription = ReadinessCategory.elite.fullDescription
        XCTAssertTrue(eliteDescription.contains("Elite"))
        XCTAssertTrue(eliteDescription.contains("90-100"))
        XCTAssertTrue(eliteDescription.contains("high intensity"))
    }

    // MARK: - Training Modification Tests

    func testVolumeAdjustment() {
        // Elite and High should have no adjustment
        XCTAssertEqual(ReadinessCategory.elite.volumeAdjustment, 0.0)
        XCTAssertEqual(ReadinessCategory.high.volumeAdjustment, 0.0)

        // Moderate should reduce by 15%
        XCTAssertEqual(ReadinessCategory.moderate.volumeAdjustment, -0.15)

        // Low should reduce by 30%
        XCTAssertEqual(ReadinessCategory.low.volumeAdjustment, -0.30)

        // Poor should reduce by 50%
        XCTAssertEqual(ReadinessCategory.poor.volumeAdjustment, -0.50)
    }

    func testIntensityAdjustment() {
        // Elite and High should have no adjustment
        XCTAssertEqual(ReadinessCategory.elite.intensityAdjustment, 0.0)
        XCTAssertEqual(ReadinessCategory.high.intensityAdjustment, 0.0)

        // Moderate should reduce by 10%
        XCTAssertEqual(ReadinessCategory.moderate.intensityAdjustment, -0.10)

        // Low should reduce by 20%
        XCTAssertEqual(ReadinessCategory.low.intensityAdjustment, -0.20)

        // Poor should reduce by 40%
        XCTAssertEqual(ReadinessCategory.poor.intensityAdjustment, -0.40)
    }

    func testShouldModifyTraining() {
        XCTAssertFalse(ReadinessCategory.elite.shouldModifyTraining)
        XCTAssertFalse(ReadinessCategory.high.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.moderate.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.low.shouldModifyTraining)
        XCTAssertTrue(ReadinessCategory.poor.shouldModifyTraining)
    }

    func testRecommendsRest() {
        XCTAssertFalse(ReadinessCategory.elite.recommendsRest)
        XCTAssertFalse(ReadinessCategory.high.recommendsRest)
        XCTAssertFalse(ReadinessCategory.moderate.recommendsRest)
        XCTAssertFalse(ReadinessCategory.low.recommendsRest)
        XCTAssertTrue(ReadinessCategory.poor.recommendsRest)
    }

    // MARK: - Sample Data Tests

    func testAllOrderedCategories() {
        let ordered = ReadinessCategory.allOrdered
        XCTAssertEqual(ordered.count, 5)
        XCTAssertEqual(ordered.first, .elite)
        XCTAssertEqual(ordered.last, .poor)
    }

    func testSampleCategory() {
        XCTAssertEqual(ReadinessCategory.sample, .high)
    }

    func testSampleScoreHelpers() {
        let samples = ReadinessScoreHelper.samples
        XCTAssertEqual(samples.count, 5)

        // Verify each sample maps to correct category
        XCTAssertEqual(samples[0].category, .elite)
        XCTAssertEqual(samples[1].category, .high)
        XCTAssertEqual(samples[2].category, .moderate)
        XCTAssertEqual(samples[3].category, .low)
        XCTAssertEqual(samples[4].category, .poor)
    }

    // MARK: - Codable Tests

    func testReadinessCategoryCodable() throws {
        // Test encoding
        let category = ReadinessCategory.high
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ReadinessCategory.self, from: data)
        XCTAssertEqual(decoded, category)
    }

    func testAllCategoriesCodable() throws {
        for category in ReadinessCategory.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(category)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ReadinessCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - Boundary Condition Tests

    func testBoundaryBetweenCategories() {
        // Test exact boundaries
        XCTAssertEqual(ReadinessCategory.category(for: 89.9999), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 90.0), .elite)

        XCTAssertEqual(ReadinessCategory.category(for: 74.9999), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 75.0), .high)

        XCTAssertEqual(ReadinessCategory.category(for: 59.9999), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 60.0), .moderate)

        XCTAssertEqual(ReadinessCategory.category(for: 44.9999), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 45.0), .low)
    }
}
