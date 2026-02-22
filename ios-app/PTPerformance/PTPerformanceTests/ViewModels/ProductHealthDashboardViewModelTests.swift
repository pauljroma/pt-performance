//
//  ProductHealthDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProductHealthDashboardViewModel
//  Tests initial state, periodLabel, sortedFeatureAdoption,
//  totalRatings, and ratingDistributionData computed properties
//

import XCTest
@testable import PTPerformance

// MARK: - Product Health Dashboard ViewModel Tests

@MainActor
final class ProductHealthDashboardViewModelTests: XCTestCase {

    var sut: ProductHealthDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = ProductHealthDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_HealthIsNil() {
        XCTAssertNil(sut.health, "health should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SelectedPeriodIs30() {
        XCTAssertEqual(sut.selectedPeriod, 30, "selectedPeriod should default to 30")
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")
    }

    func testPublishedProperties_ErrorMessageCanBeSet() {
        sut.errorMessage = "Failed to load"
        XCTAssertEqual(sut.errorMessage, "Failed to load")
    }

    func testPublishedProperties_SelectedPeriodCanBeSet() {
        sut.selectedPeriod = 7
        XCTAssertEqual(sut.selectedPeriod, 7)

        sut.selectedPeriod = 90
        XCTAssertEqual(sut.selectedPeriod, 90)
    }

    // MARK: - periodLabel Tests

    func testPeriodLabel_7Days() {
        sut.selectedPeriod = 7
        XCTAssertEqual(sut.periodLabel, "7 Days", "Period 7 should display '7 Days'")
    }

    func testPeriodLabel_30Days() {
        sut.selectedPeriod = 30
        XCTAssertEqual(sut.periodLabel, "30 Days", "Period 30 should display '30 Days'")
    }

    func testPeriodLabel_90Days() {
        sut.selectedPeriod = 90
        XCTAssertEqual(sut.periodLabel, "90 Days", "Period 90 should display '90 Days'")
    }

    func testPeriodLabel_DefaultCase() {
        sut.selectedPeriod = 14
        XCTAssertEqual(sut.periodLabel, "14 Days", "Period 14 should display '14 Days'")
    }

    func testPeriodLabel_AnotherDefaultCase() {
        sut.selectedPeriod = 60
        XCTAssertEqual(sut.periodLabel, "60 Days", "Period 60 should display '60 Days'")
    }

    func testPeriodLabel_AllStandardPeriods() {
        let testCases: [(period: Int, expected: String)] = [
            (7, "7 Days"),
            (30, "30 Days"),
            (90, "90 Days"),
            (1, "1 Days"),
            (365, "365 Days")
        ]

        for (period, expected) in testCases {
            sut.selectedPeriod = period
            XCTAssertEqual(sut.periodLabel, expected,
                           "Period \(period) should display '\(expected)'")
        }
    }

    // MARK: - sortedFeatureAdoption Tests

    func testSortedFeatureAdoption_WhenHealthIsNil_ReturnsEmpty() {
        sut.health = nil
        XCTAssertTrue(sut.sortedFeatureAdoption.isEmpty,
                      "sortedFeatureAdoption should be empty when health is nil")
    }

    func testSortedFeatureAdoption_WhenFeatureAdoptionIsNil_ReturnsEmpty() {
        sut.health = makeHealthResponse(featureAdoption: nil)
        XCTAssertTrue(sut.sortedFeatureAdoption.isEmpty,
                      "sortedFeatureAdoption should be empty when featureAdoption is nil")
    }

    func testSortedFeatureAdoption_WhenFeatureAdoptionIsEmpty_ReturnsEmpty() {
        sut.health = makeHealthResponse(featureAdoption: [:])
        XCTAssertTrue(sut.sortedFeatureAdoption.isEmpty,
                      "sortedFeatureAdoption should be empty when featureAdoption dict is empty")
    }

    func testSortedFeatureAdoption_SortedByAdoptionPctDescending() {
        let features: [String: FeatureAdoptionMetric] = [
            "workout_logging": FeatureAdoptionMetric(users: 80, adoptionPct: 80.0),
            "streak_tracking": FeatureAdoptionMetric(users: 45, adoptionPct: 45.0),
            "ai_coaching": FeatureAdoptionMetric(users: 25, adoptionPct: 25.0),
            "recovery_tracking": FeatureAdoptionMetric(users: 60, adoptionPct: 60.0)
        ]

        sut.health = makeHealthResponse(featureAdoption: features)

        let sorted = sut.sortedFeatureAdoption

        XCTAssertEqual(sorted.count, 4, "Should have 4 sorted feature entries")
        XCTAssertEqual(sorted[0].key, "workout_logging", "workout_logging (80%) should be first")
        XCTAssertEqual(sorted[1].key, "recovery_tracking", "recovery_tracking (60%) should be second")
        XCTAssertEqual(sorted[2].key, "streak_tracking", "streak_tracking (45%) should be third")
        XCTAssertEqual(sorted[3].key, "ai_coaching", "ai_coaching (25%) should be fourth")
    }

    func testSortedFeatureAdoption_HandlesNilAdoptionPct() {
        let features: [String: FeatureAdoptionMetric] = [
            "workout_logging": FeatureAdoptionMetric(users: 80, adoptionPct: 80.0),
            "unknown_feature": FeatureAdoptionMetric(users: nil, adoptionPct: nil),
            "ai_coaching": FeatureAdoptionMetric(users: 25, adoptionPct: 25.0)
        ]

        sut.health = makeHealthResponse(featureAdoption: features)

        let sorted = sut.sortedFeatureAdoption

        XCTAssertEqual(sorted.count, 3, "Should have 3 sorted feature entries")
        XCTAssertEqual(sorted[0].key, "workout_logging", "workout_logging (80%) should be first")
        XCTAssertEqual(sorted[1].key, "ai_coaching", "ai_coaching (25%) should be second")
        XCTAssertEqual(sorted[2].key, "unknown_feature", "unknown_feature (nil -> 0) should be last")
    }

    func testSortedFeatureAdoption_SingleFeature() {
        let features: [String: FeatureAdoptionMetric] = [
            "workout_logging": FeatureAdoptionMetric(users: 80, adoptionPct: 80.0)
        ]

        sut.health = makeHealthResponse(featureAdoption: features)

        let sorted = sut.sortedFeatureAdoption

        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted[0].key, "workout_logging")
        XCTAssertEqual(sorted[0].value.adoptionPct, 80.0)
    }

    func testSortedFeatureAdoption_ReturnsTuples() {
        let features: [String: FeatureAdoptionMetric] = [
            "feature_a": FeatureAdoptionMetric(users: 50, adoptionPct: 50.0),
            "feature_b": FeatureAdoptionMetric(users: 75, adoptionPct: 75.0)
        ]

        sut.health = makeHealthResponse(featureAdoption: features)

        let sorted = sut.sortedFeatureAdoption

        XCTAssertEqual(sorted[0].key, "feature_b")
        XCTAssertEqual(sorted[0].value.users, 75)
        XCTAssertEqual(sorted[0].value.adoptionPct, 75.0)
        XCTAssertEqual(sorted[1].key, "feature_a")
        XCTAssertEqual(sorted[1].value.users, 50)
    }

    // MARK: - totalRatings Tests

    func testTotalRatings_WhenHealthIsNil_ReturnsZero() {
        sut.health = nil
        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0 when health is nil")
    }

    func testTotalRatings_WhenSatisfactionIsNil_ReturnsZero() {
        sut.health = makeHealthResponse(satisfaction: nil)
        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0 when satisfaction is nil")
    }

    func testTotalRatings_WhenRatingDistributionIsNil_ReturnsZero() {
        let satisfaction = ProductSatisfaction(
            avgRating: 4.2,
            totalReviews: 100,
            ratingDistribution: nil,
            npsProxy: 45.0,
            recentLowRatings: nil
        )
        sut.health = makeHealthResponse(satisfaction: satisfaction)
        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0 when ratingDistribution is nil")
    }

    func testTotalRatings_SumsAllStars() {
        let distribution = RatingDistribution(
            oneStar: 5,
            twoStar: 10,
            threeStar: 20,
            fourStar: 35,
            fiveStar: 30
        )
        let satisfaction = ProductSatisfaction(
            avgRating: 3.75,
            totalReviews: 100,
            ratingDistribution: distribution,
            npsProxy: 40.0,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        XCTAssertEqual(sut.totalRatings, 100, "totalRatings should sum all star counts (5+10+20+35+30=100)")
    }

    func testTotalRatings_HandlesNilStarValues() {
        let distribution = RatingDistribution(
            oneStar: 5,
            twoStar: nil,
            threeStar: 20,
            fourStar: nil,
            fiveStar: 30
        )
        let satisfaction = ProductSatisfaction(
            avgRating: nil,
            totalReviews: nil,
            ratingDistribution: distribution,
            npsProxy: nil,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        XCTAssertEqual(sut.totalRatings, 55, "totalRatings should treat nil as 0 (5+0+20+0+30=55)")
    }

    func testTotalRatings_AllZeros() {
        let distribution = RatingDistribution(
            oneStar: 0,
            twoStar: 0,
            threeStar: 0,
            fourStar: 0,
            fiveStar: 0
        )
        let satisfaction = ProductSatisfaction(
            avgRating: 0,
            totalReviews: 0,
            ratingDistribution: distribution,
            npsProxy: 0,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0 when all star counts are 0")
    }

    func testTotalRatings_AllNil() {
        let distribution = RatingDistribution(
            oneStar: nil,
            twoStar: nil,
            threeStar: nil,
            fourStar: nil,
            fiveStar: nil
        )
        let satisfaction = ProductSatisfaction(
            avgRating: nil,
            totalReviews: nil,
            ratingDistribution: distribution,
            npsProxy: nil,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0 when all star counts are nil")
    }

    // MARK: - ratingDistributionData Tests

    func testRatingDistributionData_WhenHealthIsNil_ReturnsEmpty() {
        sut.health = nil
        XCTAssertTrue(sut.ratingDistributionData.isEmpty,
                      "ratingDistributionData should be empty when health is nil")
    }

    func testRatingDistributionData_WhenSatisfactionIsNil_ReturnsEmpty() {
        sut.health = makeHealthResponse(satisfaction: nil)
        XCTAssertTrue(sut.ratingDistributionData.isEmpty,
                      "ratingDistributionData should be empty when satisfaction is nil")
    }

    func testRatingDistributionData_WhenRatingDistributionIsNil_ReturnsEmpty() {
        let satisfaction = ProductSatisfaction(
            avgRating: 4.0,
            totalReviews: 50,
            ratingDistribution: nil,
            npsProxy: 40.0,
            recentLowRatings: nil
        )
        sut.health = makeHealthResponse(satisfaction: satisfaction)
        XCTAssertTrue(sut.ratingDistributionData.isEmpty,
                      "ratingDistributionData should be empty when ratingDistribution is nil")
    }

    func testRatingDistributionData_CorrectStarCountMapping() {
        let distribution = RatingDistribution(
            oneStar: 3,
            twoStar: 7,
            threeStar: 15,
            fourStar: 40,
            fiveStar: 35
        )
        let satisfaction = ProductSatisfaction(
            avgRating: 3.97,
            totalReviews: 100,
            ratingDistribution: distribution,
            npsProxy: 50.0,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        let data = sut.ratingDistributionData

        XCTAssertEqual(data.count, 5, "Should have 5 entries (one per star)")

        XCTAssertEqual(data[0].stars, 1, "First entry should be 1 star")
        XCTAssertEqual(data[0].count, 3, "1-star count should be 3")

        XCTAssertEqual(data[1].stars, 2, "Second entry should be 2 stars")
        XCTAssertEqual(data[1].count, 7, "2-star count should be 7")

        XCTAssertEqual(data[2].stars, 3, "Third entry should be 3 stars")
        XCTAssertEqual(data[2].count, 15, "3-star count should be 15")

        XCTAssertEqual(data[3].stars, 4, "Fourth entry should be 4 stars")
        XCTAssertEqual(data[3].count, 40, "4-star count should be 40")

        XCTAssertEqual(data[4].stars, 5, "Fifth entry should be 5 stars")
        XCTAssertEqual(data[4].count, 35, "5-star count should be 35")
    }

    func testRatingDistributionData_HandlesNilStarValues() {
        let distribution = RatingDistribution(
            oneStar: nil,
            twoStar: 10,
            threeStar: nil,
            fourStar: 25,
            fiveStar: nil
        )
        let satisfaction = ProductSatisfaction(
            avgRating: nil,
            totalReviews: nil,
            ratingDistribution: distribution,
            npsProxy: nil,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        let data = sut.ratingDistributionData

        XCTAssertEqual(data.count, 5, "Should still have 5 entries")
        XCTAssertEqual(data[0].count, 0, "nil 1-star count should default to 0")
        XCTAssertEqual(data[1].count, 10, "2-star count should be 10")
        XCTAssertEqual(data[2].count, 0, "nil 3-star count should default to 0")
        XCTAssertEqual(data[3].count, 25, "4-star count should be 25")
        XCTAssertEqual(data[4].count, 0, "nil 5-star count should default to 0")
    }

    func testRatingDistributionData_StarsInAscendingOrder() {
        let distribution = RatingDistribution(
            oneStar: 1,
            twoStar: 2,
            threeStar: 3,
            fourStar: 4,
            fiveStar: 5
        )
        let satisfaction = ProductSatisfaction(
            avgRating: 3.67,
            totalReviews: 15,
            ratingDistribution: distribution,
            npsProxy: nil,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        let data = sut.ratingDistributionData

        for i in 0..<data.count {
            XCTAssertEqual(data[i].stars, i + 1,
                           "Star value at index \(i) should be \(i + 1)")
        }
    }

    func testRatingDistributionData_ConsistencyWithTotalRatings() {
        let distribution = RatingDistribution(
            oneStar: 2,
            twoStar: 5,
            threeStar: 18,
            fourStar: 42,
            fiveStar: 33
        )
        let satisfaction = ProductSatisfaction(
            avgRating: 3.99,
            totalReviews: 100,
            ratingDistribution: distribution,
            npsProxy: 50.0,
            recentLowRatings: nil
        )

        sut.health = makeHealthResponse(satisfaction: satisfaction)

        let distributionSum = sut.ratingDistributionData.reduce(0) { $0 + $1.count }

        XCTAssertEqual(distributionSum, sut.totalRatings,
                       "Sum of ratingDistributionData counts should equal totalRatings")
    }

    // MARK: - Computed Properties With Nil Health Tests

    func testAllComputedProperties_WhenHealthIsNil() {
        sut.health = nil

        XCTAssertTrue(sut.sortedFeatureAdoption.isEmpty, "sortedFeatureAdoption should be empty")
        XCTAssertEqual(sut.totalRatings, 0, "totalRatings should be 0")
        XCTAssertTrue(sut.ratingDistributionData.isEmpty, "ratingDistributionData should be empty")
        // periodLabel is independent of health
        XCTAssertEqual(sut.periodLabel, "30 Days", "periodLabel should still work")
    }

    // MARK: - Health Response Full Data Tests

    func testHealth_CanBeSetWithFullResponse() {
        let health = ProductHealthResponse(
            periodStart: "2026-01-22",
            periodEnd: "2026-02-21",
            periodDays: 30,
            engagement: ProductEngagement(
                dau: 150,
                wau: 450,
                mau: 1200,
                totalPatients: 2000,
                dauTrend: 5.0,
                wauTrend: 3.0,
                mauTrend: 2.0,
                dauWauRatio: 0.33,
                wauMauRatio: 0.375
            ),
            featureAdoption: [
                "workout_logging": FeatureAdoptionMetric(users: 900, adoptionPct: 75.0),
                "streak_tracking": FeatureAdoptionMetric(users: 600, adoptionPct: 50.0)
            ],
            satisfaction: ProductSatisfaction(
                avgRating: 4.3,
                totalReviews: 250,
                ratingDistribution: RatingDistribution(
                    oneStar: 5,
                    twoStar: 10,
                    threeStar: 30,
                    fourStar: 80,
                    fiveStar: 125
                ),
                npsProxy: 60.0,
                recentLowRatings: nil
            ),
            safety: nil,
            subscriptionHealth: nil,
            generatedAt: "2026-02-21T10:00:00Z"
        )

        sut.health = health

        XCTAssertNotNil(sut.health)
        XCTAssertEqual(sut.health?.periodDays, 30)
        XCTAssertEqual(sut.health?.engagement?.dau, 150)
        XCTAssertEqual(sut.sortedFeatureAdoption.count, 2)
        XCTAssertEqual(sut.totalRatings, 250)
        XCTAssertEqual(sut.ratingDistributionData.count, 5)
    }

    // MARK: - Helper Methods

    /// Creates a minimal ProductHealthResponse with optional overrides for specific fields
    private func makeHealthResponse(
        featureAdoption: [String: FeatureAdoptionMetric]? = nil,
        satisfaction: ProductSatisfaction? = nil
    ) -> ProductHealthResponse {
        return ProductHealthResponse(
            periodStart: "2026-01-22",
            periodEnd: "2026-02-21",
            periodDays: 30,
            engagement: nil,
            featureAdoption: featureAdoption,
            satisfaction: satisfaction,
            safety: nil,
            subscriptionHealth: nil,
            generatedAt: "2026-02-21T10:00:00Z"
        )
    }
}
