//
//  EngagementScoreDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for EngagementScoreDashboardViewModel
//  Tests initial state, scoreColor static method, and published properties
//

import XCTest
@testable import PTPerformance

// MARK: - Engagement Score Dashboard ViewModel Tests

@MainActor
final class EngagementScoreDashboardViewModelTests: XCTestCase {

    var sut: EngagementScoreDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = EngagementScoreDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_ScoresIsEmpty() {
        XCTAssertTrue(sut.scores.isEmpty, "scores should be empty initially")
    }

    func testInitialState_SummaryIsNil() {
        XCTAssertNil(sut.summary, "summary should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_IsRecalculatingIsFalse() {
        XCTAssertFalse(sut.isRecalculating, "isRecalculating should be false initially")
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_ScoresCanBeSet() {
        let mockScores = [
            EngagementScoreRow(
                patientId: "patient-1",
                score: 85.0,
                riskLevel: "highly_engaged",
                components: nil,
                calculatedAt: "2026-02-01"
            ),
            EngagementScoreRow(
                patientId: "patient-2",
                score: 42.0,
                riskLevel: "moderate",
                components: nil,
                calculatedAt: "2026-02-01"
            )
        ]

        sut.scores = mockScores

        XCTAssertEqual(sut.scores.count, 2, "scores should have 2 rows after setting")
        XCTAssertEqual(sut.scores[0].patientId, "patient-1")
        XCTAssertEqual(sut.scores[1].score, 42.0)
    }

    func testPublishedProperties_SummaryCanBeSet() {
        let mockSummary = EngagementSummary(
            totalPatients: 100,
            highlyEngaged: 25,
            engaged: 30,
            moderate: 20,
            atRisk: 15,
            highRisk: 10,
            avgScore: 62.5
        )

        sut.summary = mockSummary

        XCTAssertNotNil(sut.summary, "summary should not be nil after setting")
        XCTAssertEqual(sut.summary?.totalPatients, 100)
        XCTAssertEqual(sut.summary?.avgScore, 62.5)
    }

    func testPublishedProperties_ErrorMessageCanBeSet() {
        sut.errorMessage = "Network error"

        XCTAssertEqual(sut.errorMessage, "Network error", "errorMessage should be settable")
    }

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true

        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")
    }

    func testPublishedProperties_IsRecalculatingCanBeSet() {
        sut.isRecalculating = true

        XCTAssertTrue(sut.isRecalculating, "isRecalculating should be settable to true")
    }

    // MARK: - scoreColor Static Method Tests

    func testScoreColor_HighlyEngaged_Score100() {
        let result = EngagementScoreDashboardViewModel.scoreColor(100)
        XCTAssertEqual(result, "highly_engaged", "Score 100 should return highly_engaged")
    }

    func testScoreColor_HighlyEngaged_Score80() {
        let result = EngagementScoreDashboardViewModel.scoreColor(80)
        XCTAssertEqual(result, "highly_engaged", "Score 80 should return highly_engaged")
    }

    func testScoreColor_HighlyEngaged_Score90() {
        let result = EngagementScoreDashboardViewModel.scoreColor(90)
        XCTAssertEqual(result, "highly_engaged", "Score 90 should return highly_engaged")
    }

    func testScoreColor_Engaged_Score79() {
        let result = EngagementScoreDashboardViewModel.scoreColor(79)
        XCTAssertEqual(result, "engaged", "Score 79 should return engaged")
    }

    func testScoreColor_Engaged_Score60() {
        let result = EngagementScoreDashboardViewModel.scoreColor(60)
        XCTAssertEqual(result, "engaged", "Score 60 should return engaged")
    }

    func testScoreColor_Engaged_Score70() {
        let result = EngagementScoreDashboardViewModel.scoreColor(70)
        XCTAssertEqual(result, "engaged", "Score 70 should return engaged")
    }

    func testScoreColor_Moderate_Score59() {
        let result = EngagementScoreDashboardViewModel.scoreColor(59)
        XCTAssertEqual(result, "moderate", "Score 59 should return moderate")
    }

    func testScoreColor_Moderate_Score40() {
        let result = EngagementScoreDashboardViewModel.scoreColor(40)
        XCTAssertEqual(result, "moderate", "Score 40 should return moderate")
    }

    func testScoreColor_Moderate_Score50() {
        let result = EngagementScoreDashboardViewModel.scoreColor(50)
        XCTAssertEqual(result, "moderate", "Score 50 should return moderate")
    }

    func testScoreColor_AtRisk_Score39() {
        let result = EngagementScoreDashboardViewModel.scoreColor(39)
        XCTAssertEqual(result, "at_risk", "Score 39 should return at_risk")
    }

    func testScoreColor_AtRisk_Score20() {
        let result = EngagementScoreDashboardViewModel.scoreColor(20)
        XCTAssertEqual(result, "at_risk", "Score 20 should return at_risk")
    }

    func testScoreColor_AtRisk_Score30() {
        let result = EngagementScoreDashboardViewModel.scoreColor(30)
        XCTAssertEqual(result, "at_risk", "Score 30 should return at_risk")
    }

    func testScoreColor_HighRisk_Score19() {
        let result = EngagementScoreDashboardViewModel.scoreColor(19)
        XCTAssertEqual(result, "high_risk", "Score 19 should return high_risk")
    }

    func testScoreColor_HighRisk_Score0() {
        let result = EngagementScoreDashboardViewModel.scoreColor(0)
        XCTAssertEqual(result, "high_risk", "Score 0 should return high_risk")
    }

    func testScoreColor_HighRisk_Score10() {
        let result = EngagementScoreDashboardViewModel.scoreColor(10)
        XCTAssertEqual(result, "high_risk", "Score 10 should return high_risk")
    }

    func testScoreColor_HighRisk_NegativeScore() {
        let result = EngagementScoreDashboardViewModel.scoreColor(-5)
        XCTAssertEqual(result, "high_risk", "Negative score should return high_risk")
    }

    // MARK: - scoreColor Boundary Tests

    func testScoreColor_BoundaryAt80() {
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(80),
            "highly_engaged",
            "Score exactly 80 should be highly_engaged"
        )
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(79.99),
            "engaged",
            "Score 79.99 should be engaged"
        )
    }

    func testScoreColor_BoundaryAt60() {
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(60),
            "engaged",
            "Score exactly 60 should be engaged"
        )
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(59.99),
            "moderate",
            "Score 59.99 should be moderate"
        )
    }

    func testScoreColor_BoundaryAt40() {
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(40),
            "moderate",
            "Score exactly 40 should be moderate"
        )
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(39.99),
            "at_risk",
            "Score 39.99 should be at_risk"
        )
    }

    func testScoreColor_BoundaryAt20() {
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(20),
            "at_risk",
            "Score exactly 20 should be at_risk"
        )
        XCTAssertEqual(
            EngagementScoreDashboardViewModel.scoreColor(19.99),
            "high_risk",
            "Score 19.99 should be high_risk"
        )
    }

    // MARK: - scoreColor Comprehensive Range Tests

    func testScoreColor_AllRanges() {
        let testCases: [(score: Double, expected: String)] = [
            (-10, "high_risk"),
            (0, "high_risk"),
            (10, "high_risk"),
            (19.99, "high_risk"),
            (20, "at_risk"),
            (30, "at_risk"),
            (39.99, "at_risk"),
            (40, "moderate"),
            (50, "moderate"),
            (59.99, "moderate"),
            (60, "engaged"),
            (70, "engaged"),
            (79.99, "engaged"),
            (80, "highly_engaged"),
            (90, "highly_engaged"),
            (100, "highly_engaged")
        ]

        for (score, expected) in testCases {
            XCTAssertEqual(
                EngagementScoreDashboardViewModel.scoreColor(score),
                expected,
                "Score \(score) should return \(expected)"
            )
        }
    }

    // MARK: - Summary Properties Tests

    func testSummary_AllFieldsAccessible() {
        let mockSummary = EngagementSummary(
            totalPatients: 50,
            highlyEngaged: 10,
            engaged: 15,
            moderate: 12,
            atRisk: 8,
            highRisk: 5,
            avgScore: 58.3
        )

        sut.summary = mockSummary

        XCTAssertEqual(sut.summary?.totalPatients, 50)
        XCTAssertEqual(sut.summary?.highlyEngaged, 10)
        XCTAssertEqual(sut.summary?.engaged, 15)
        XCTAssertEqual(sut.summary?.moderate, 12)
        XCTAssertEqual(sut.summary?.atRisk, 8)
        XCTAssertEqual(sut.summary?.highRisk, 5)
        XCTAssertEqual(sut.summary?.avgScore ?? 0, 58.3, accuracy: 0.01)
    }

    // MARK: - Scores Array Tests

    func testScores_RowIdentifiableByPatientId() {
        let row = EngagementScoreRow(
            patientId: "test-patient-123",
            score: 75.0,
            riskLevel: "engaged",
            components: nil,
            calculatedAt: nil
        )

        XCTAssertEqual(row.id, "test-patient-123", "id should equal patientId")
    }

    func testScores_RowWithNilPatientIdGeneratesId() {
        let row = EngagementScoreRow(
            patientId: nil,
            score: 75.0,
            riskLevel: "engaged",
            components: nil,
            calculatedAt: nil
        )

        XCTAssertFalse(row.id.isEmpty, "id should not be empty even when patientId is nil")
    }

    func testScores_MultipleRowsCanBeStored() {
        let rows = (1...5).map { index in
            EngagementScoreRow(
                patientId: "patient-\(index)",
                score: Double(index * 20),
                riskLevel: nil,
                components: nil,
                calculatedAt: nil
            )
        }

        sut.scores = rows

        XCTAssertEqual(sut.scores.count, 5, "Should store 5 score rows")
        XCTAssertEqual(sut.scores[0].score, 20.0)
        XCTAssertEqual(sut.scores[4].score, 100.0)
    }
}
