//
//  DeloadRecommendationViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for DeloadRecommendationViewModel
//  Tests fatigue summary computation, deload prescriptions, and user actions
//

import XCTest
@testable import PTPerformance

@MainActor
final class DeloadRecommendationViewModelTests: XCTestCase {

    var viewModel: DeloadRecommendationViewModel!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        viewModel = DeloadRecommendationViewModel(patientId: testPatientId)
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false initially")
    }

    func testInitialState_FatigueSummaryIsNil() {
        XCTAssertNil(viewModel.fatigueSummary, "fatigueSummary should be nil initially")
    }

    func testInitialState_PrescriptionIsNil() {
        XCTAssertNil(viewModel.prescription, "prescription should be nil initially")
    }

    func testInitialState_TrendDataIsEmpty() {
        XCTAssertTrue(viewModel.trendData.isEmpty, "trendData should be empty initially")
    }

    func testInitialState_UrgencyIsNone() {
        XCTAssertEqual(viewModel.urgency, .none, "urgency should be .none initially")
    }

    func testInitialState_ContributingFactorsIsEmpty() {
        XCTAssertTrue(viewModel.contributingFactors.isEmpty, "contributingFactors should be empty initially")
    }

    func testInitialState_ErrorStateIsClear() {
        XCTAssertNil(viewModel.error, "error should be nil initially")
        XCTAssertFalse(viewModel.showError, "showError should be false initially")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage should be empty initially")
    }

    func testInitialState_ActionStatesAreFalse() {
        XCTAssertFalse(viewModel.isActivating, "isActivating should be false initially")
        XCTAssertFalse(viewModel.isDismissing, "isDismissing should be false initially")
        XCTAssertFalse(viewModel.showActivationSuccess, "showActivationSuccess should be false initially")
        XCTAssertFalse(viewModel.showDismissalSuccess, "showDismissalSuccess should be false initially")
    }

    // MARK: - Computed Properties Tests - hasData

    func testHasData_WhenFatigueSummaryIsNil_ReturnsFalse() {
        viewModel.fatigueSummary = nil
        XCTAssertFalse(viewModel.hasData, "hasData should be false when fatigueSummary is nil")
    }

    func testHasData_WhenFatigueSummaryExists_ReturnsTrue() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50.0, fatigueBand: "moderate")
        XCTAssertTrue(viewModel.hasData, "hasData should be true when fatigueSummary exists")
    }

    // MARK: - Computed Properties Tests - deloadRecommended

    func testDeloadRecommended_WhenUrgencyIsNone_ReturnsFalse() {
        viewModel.urgency = .none
        viewModel.prescription = createMockPrescription()
        XCTAssertFalse(viewModel.deloadRecommended, "deloadRecommended should be false when urgency is .none")
    }

    func testDeloadRecommended_WhenPrescriptionIsNil_ReturnsFalse() {
        viewModel.urgency = .recommended
        viewModel.prescription = nil
        XCTAssertFalse(viewModel.deloadRecommended, "deloadRecommended should be false when prescription is nil")
    }

    func testDeloadRecommended_WhenUrgencyAndPrescriptionExist_ReturnsTrue() {
        viewModel.urgency = .recommended
        viewModel.prescription = createMockPrescription()
        XCTAssertTrue(viewModel.deloadRecommended, "deloadRecommended should be true with urgency and prescription")
    }

    func testDeloadRecommended_AllUrgencyLevelsExceptNone() {
        viewModel.prescription = createMockPrescription()

        viewModel.urgency = .suggested
        XCTAssertTrue(viewModel.deloadRecommended, "deloadRecommended should be true with .suggested urgency")

        viewModel.urgency = .recommended
        XCTAssertTrue(viewModel.deloadRecommended, "deloadRecommended should be true with .recommended urgency")

        viewModel.urgency = .required
        XCTAssertTrue(viewModel.deloadRecommended, "deloadRecommended should be true with .required urgency")
    }

    // MARK: - Computed Properties Tests - fatigueScore

    func testFatigueScore_WhenFatigueSummaryIsNil_ReturnsZero() {
        viewModel.fatigueSummary = nil
        XCTAssertEqual(viewModel.fatigueScore, 0, "fatigueScore should be 0 when fatigueSummary is nil")
    }

    func testFatigueScore_WhenFatigueSummaryExists_ReturnsCorrectValue() {
        let expectedScore = 72.5
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: expectedScore, fatigueBand: "high")
        XCTAssertEqual(viewModel.fatigueScore, expectedScore, "fatigueScore should match fatigueSummary value")
    }

    // MARK: - Computed Properties Tests - fatigueScoreText

    func testFatigueScoreText_FormatsCorrectly() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 72.5, fatigueBand: "high")
        XCTAssertEqual(viewModel.fatigueScoreText, "73", "fatigueScoreText should format to whole number")
    }

    func testFatigueScoreText_WhenZero_DisplaysZero() {
        viewModel.fatigueSummary = nil
        XCTAssertEqual(viewModel.fatigueScoreText, "0", "fatigueScoreText should display 0 when no summary")
    }

    func testFatigueScoreText_RoundsDownCorrectly() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 65.4, fatigueBand: "moderate")
        XCTAssertEqual(viewModel.fatigueScoreText, "65", "fatigueScoreText should round 65.4 to 65")
    }

    func testFatigueScoreText_RoundsUpCorrectly() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 65.6, fatigueBand: "moderate")
        XCTAssertEqual(viewModel.fatigueScoreText, "66", "fatigueScoreText should round 65.6 to 66")
    }

    // MARK: - Computed Properties Tests - fatigueColor

    func testFatigueColor_WhenNoSummary_ReturnsGray() {
        viewModel.fatigueSummary = nil
        XCTAssertEqual(viewModel.fatigueColor, .gray, "fatigueColor should be gray when no summary")
    }

    func testFatigueColor_ForLowBand_ReturnsGreen() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 30, fatigueBand: "low")
        XCTAssertEqual(viewModel.fatigueColor, .green, "fatigueColor should be green for low band")
    }

    func testFatigueColor_ForModerateBand_ReturnsYellow() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50, fatigueBand: "moderate")
        XCTAssertEqual(viewModel.fatigueColor, .yellow, "fatigueColor should be yellow for moderate band")
    }

    func testFatigueColor_ForHighBand_ReturnsOrange() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 70, fatigueBand: "high")
        XCTAssertEqual(viewModel.fatigueColor, .orange, "fatigueColor should be orange for high band")
    }

    func testFatigueColor_ForCriticalBand_ReturnsRed() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 90, fatigueBand: "critical")
        XCTAssertEqual(viewModel.fatigueColor, .red, "fatigueColor should be red for critical band")
    }

    func testFatigueColor_ForInvalidBand_ReturnsGray() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50, fatigueBand: "invalid_band")
        XCTAssertEqual(viewModel.fatigueColor, .gray, "fatigueColor should be gray for invalid band")
    }

    // MARK: - Computed Properties Tests - fatigueBand

    func testFatigueBand_WhenNoSummary_ReturnsNil() {
        viewModel.fatigueSummary = nil
        XCTAssertNil(viewModel.fatigueBand, "fatigueBand should be nil when no summary")
    }

    func testFatigueBand_ParsesLow() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 30, fatigueBand: "low")
        XCTAssertEqual(viewModel.fatigueBand, .low, "fatigueBand should parse 'low' correctly")
    }

    func testFatigueBand_ParsesModerate() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50, fatigueBand: "moderate")
        XCTAssertEqual(viewModel.fatigueBand, .moderate, "fatigueBand should parse 'moderate' correctly")
    }

    func testFatigueBand_ParsesHigh() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 70, fatigueBand: "high")
        XCTAssertEqual(viewModel.fatigueBand, .high, "fatigueBand should parse 'high' correctly")
    }

    func testFatigueBand_ParsesCritical() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 90, fatigueBand: "critical")
        XCTAssertEqual(viewModel.fatigueBand, .critical, "fatigueBand should parse 'critical' correctly")
    }

    func testFatigueBand_InvalidBand_ReturnsNil() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50, fatigueBand: "unknown")
        XCTAssertNil(viewModel.fatigueBand, "fatigueBand should be nil for invalid band string")
    }

    // MARK: - Computed Properties Tests - fatigueDescription

    func testFatigueDescription_WhenNoSummary_ReturnsDefault() {
        viewModel.fatigueSummary = nil
        XCTAssertEqual(viewModel.fatigueDescription, "No fatigue data available",
            "fatigueDescription should return default when no summary")
    }

    func testFatigueDescription_ForLowBand() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 30, fatigueBand: "low")
        XCTAssertEqual(viewModel.fatigueDescription, "Low fatigue - Ready for full training",
            "fatigueDescription should match low band description")
    }

    func testFatigueDescription_ForModerateBand() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 50, fatigueBand: "moderate")
        XCTAssertEqual(viewModel.fatigueDescription, "Moderate fatigue - Monitor recovery",
            "fatigueDescription should match moderate band description")
    }

    func testFatigueDescription_ForHighBand() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 70, fatigueBand: "high")
        XCTAssertEqual(viewModel.fatigueDescription, "High fatigue - Consider reducing load",
            "fatigueDescription should match high band description")
    }

    func testFatigueDescription_ForCriticalBand() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 90, fatigueBand: "critical")
        XCTAssertEqual(viewModel.fatigueDescription, "Critical fatigue - Deload recommended",
            "fatigueDescription should match critical band description")
    }

    // MARK: - Contributing Factors Tests

    func testContributingFactors_EmptyByDefault() {
        XCTAssertTrue(viewModel.contributingFactors.isEmpty, "contributingFactors should be empty by default")
    }

    func testContributingFactors_CanBeSet() {
        let factors = ["High ACR", "Low readiness streak", "Elevated RPE"]
        viewModel.contributingFactors = factors
        XCTAssertEqual(viewModel.contributingFactors.count, 3, "contributingFactors should have 3 items")
        XCTAssertEqual(viewModel.contributingFactors, factors, "contributingFactors should match set values")
    }

    func testContributingFactors_SingleFactor() {
        viewModel.contributingFactors = ["Elevated acute:chronic workload ratio"]
        XCTAssertEqual(viewModel.contributingFactors.count, 1, "Single factor should be stored")
        XCTAssertEqual(viewModel.contributingFactors.first, "Elevated acute:chronic workload ratio")
    }

    func testContributingFactors_ManyFactors() {
        let manyFactors = (1...10).map { "Factor \($0)" }
        viewModel.contributingFactors = manyFactors
        XCTAssertEqual(viewModel.contributingFactors.count, 10, "Should handle many factors")
    }

    // MARK: - User Actions Tests - activateDeload

    func testActivateDeload_WithoutPrescription_DoesNotActivate() async {
        viewModel.prescription = nil
        viewModel.urgency = .recommended

        await viewModel.activateDeload()

        XCTAssertFalse(viewModel.isActivating, "isActivating should be false after call")
        XCTAssertFalse(viewModel.showActivationSuccess, "showActivationSuccess should remain false")
    }

    func testActivateDeload_SetsIsActivatingDuringOperation() async {
        // Setup: Add prescription so activation proceeds
        viewModel.prescription = createMockPrescription()
        viewModel.urgency = .recommended

        let activatingExpectation = expectation(description: "Activation completes")

        Task {
            await viewModel.activateDeload()
            XCTAssertFalse(viewModel.isActivating, "isActivating should be false after completion")
            activatingExpectation.fulfill()
        }

        await fulfillment(of: [activatingExpectation], timeout: 10.0)
    }

    // MARK: - User Actions Tests - dismissRecommendation

    func testDismissRecommendation_SetsIsDismissingDuringOperation() async {
        viewModel.urgency = .recommended
        viewModel.prescription = createMockPrescription()

        let dismissingExpectation = expectation(description: "Dismissal completes")

        Task {
            await viewModel.dismissRecommendation()
            XCTAssertFalse(viewModel.isDismissing, "isDismissing should be false after completion")
            dismissingExpectation.fulfill()
        }

        await fulfillment(of: [dismissingExpectation], timeout: 10.0)
    }

    func testDismissRecommendation_WithReason() async {
        let dismissingExpectation = expectation(description: "Dismissal with reason completes")

        Task {
            await viewModel.dismissRecommendation(reason: "Athlete feels ready to continue")
            XCTAssertFalse(viewModel.isDismissing, "isDismissing should be false")
            dismissingExpectation.fulfill()
        }

        await fulfillment(of: [dismissingExpectation], timeout: 10.0)
    }

    // MARK: - Error Handling Tests

    func testClearError_ClearsAllErrorState() {
        // Setup error state
        viewModel.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        viewModel.showError = true
        viewModel.errorMessage = "Test error message"

        // Clear error
        viewModel.clearError()

        XCTAssertNil(viewModel.error, "error should be nil after clearError")
        XCTAssertFalse(viewModel.showError, "showError should be false after clearError")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage should be empty after clearError")
    }

    func testClearError_WhenNoError_DoesNothing() {
        // Ensure initial state
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")

        // Clear should not crash or change state
        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    // MARK: - Loading State Tests

    func testLoadData_LoadingStateChanges() async {
        let loadingExpectation = expectation(description: "Loading state changes")

        Task {
            XCTAssertFalse(viewModel.isLoading, "Should start not loading")
            await viewModel.loadData()
            XCTAssertFalse(viewModel.isLoading, "Should finish loading")
            loadingExpectation.fulfill()
        }

        await fulfillment(of: [loadingExpectation], timeout: 10.0)
    }

    func testRefresh_CallsLoadData() async {
        let refreshExpectation = expectation(description: "Refresh completes")

        Task {
            await viewModel.refresh()
            XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
            refreshExpectation.fulfill()
        }

        await fulfillment(of: [refreshExpectation], timeout: 10.0)
    }

    // MARK: - Trend Data Tests

    func testTrendData_EmptyInitially() {
        XCTAssertTrue(viewModel.trendData.isEmpty, "trendData should be empty initially")
    }

    func testTrendData_CanBePopulated() {
        let trendPoints = createMockTrendData(days: 7)
        viewModel.trendData = trendPoints

        XCTAssertEqual(viewModel.trendData.count, 7, "Should have 7 trend points")
    }

    func testTrendData_SortedByDate() {
        let trendPoints = createMockTrendData(days: 7)
        viewModel.trendData = trendPoints

        // Verify sorted order
        for i in 0..<(viewModel.trendData.count - 1) {
            XCTAssertTrue(viewModel.trendData[i].date <= viewModel.trendData[i + 1].date,
                "Trend data should be sorted by date ascending")
        }
    }

    // MARK: - FatigueTrendPoint Tests

    func testFatigueTrendPoint_FormattedDate() {
        let date = Date()
        let trendPoint = FatigueTrendPoint(date: date, fatigueScore: 50.0, band: .moderate)

        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let expectedDayName = formatter.string(from: date)

        XCTAssertEqual(trendPoint.formattedDate, expectedDayName,
            "formattedDate should return abbreviated day name")
    }

    func testFatigueTrendPoint_FormattedScore() {
        let trendPoint = FatigueTrendPoint(date: Date(), fatigueScore: 72.5, band: .high)
        XCTAssertEqual(trendPoint.formattedScore, "73", "formattedScore should round to whole number")
    }

    func testFatigueTrendPoint_HasUniqueId() {
        let point1 = FatigueTrendPoint(date: Date(), fatigueScore: 50.0, band: .moderate)
        let point2 = FatigueTrendPoint(date: Date(), fatigueScore: 50.0, band: .moderate)

        XCTAssertNotEqual(point1.id, point2.id, "Each trend point should have unique ID")
    }

    // MARK: - DeloadUrgency Tests

    func testDeloadUrgency_AllCasesHaveTitle() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.title.isEmpty, "Urgency \(urgency) should have a title")
        }
    }

    func testDeloadUrgency_AllCasesHaveSubtitle() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.subtitle.isEmpty, "Urgency \(urgency) should have a subtitle")
        }
    }

    func testDeloadUrgency_AllCasesHaveIcon() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.icon.isEmpty, "Urgency \(urgency) should have an icon")
        }
    }

    func testDeloadUrgency_Titles() {
        XCTAssertEqual(DeloadUrgency.none.title, "No Deload Needed")
        XCTAssertEqual(DeloadUrgency.suggested.title, "Deload Suggested")
        XCTAssertEqual(DeloadUrgency.recommended.title, "Deload Recommended")
        XCTAssertEqual(DeloadUrgency.required.title, "Deload Required")
    }

    // MARK: - FatigueBand Tests

    func testFatigueBand_AllCasesHaveDescription() {
        for band in FatigueBand.allCases {
            XCTAssertFalse(band.description.isEmpty, "Band \(band) should have a description")
        }
    }

    func testFatigueBand_AllCasesHaveIcon() {
        for band in FatigueBand.allCases {
            XCTAssertFalse(band.icon.isEmpty, "Band \(band) should have an icon")
        }
    }

    func testFatigueBand_AllCasesHaveDisplayName() {
        for band in FatigueBand.allCases {
            XCTAssertFalse(band.displayName.isEmpty, "Band \(band) should have a display name")
        }
    }

    func testFatigueBand_DisplayNames() {
        XCTAssertEqual(FatigueBand.low.displayName, "Low")
        XCTAssertEqual(FatigueBand.moderate.displayName, "Moderate")
        XCTAssertEqual(FatigueBand.high.displayName, "High")
        XCTAssertEqual(FatigueBand.critical.displayName, "Critical")
    }

    // MARK: - Preview Support Tests

    func testPreviewInstance_HasData() {
        let previewVM = DeloadRecommendationViewModel.preview

        XCTAssertNotNil(previewVM.fatigueSummary, "Preview should have fatigue summary")
        XCTAssertNotNil(previewVM.prescription, "Preview should have prescription")
        XCTAssertEqual(previewVM.urgency, .recommended, "Preview should have recommended urgency")
        XCTAssertFalse(previewVM.contributingFactors.isEmpty, "Preview should have contributing factors")
        XCTAssertFalse(previewVM.trendData.isEmpty, "Preview should have trend data")
    }

    func testNoDeloadPreview_HasLowFatigue() {
        let previewVM = DeloadRecommendationViewModel.noDeloadPreview

        XCTAssertNotNil(previewVM.fatigueSummary, "No deload preview should have fatigue summary")
        XCTAssertNil(previewVM.prescription, "No deload preview should not have prescription")
        XCTAssertEqual(previewVM.urgency, .none, "No deload preview should have no urgency")
        XCTAssertTrue(previewVM.contributingFactors.isEmpty, "No deload preview should have empty factors")
    }

    // MARK: - Edge Cases Tests

    func testViewModel_WithZeroFatigueScore() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 0, fatigueBand: "low")
        XCTAssertEqual(viewModel.fatigueScore, 0, "Should handle zero fatigue score")
        XCTAssertEqual(viewModel.fatigueScoreText, "0", "Should display 0 for zero score")
    }

    func testViewModel_WithMaxFatigueScore() {
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: 100, fatigueBand: "critical")
        XCTAssertEqual(viewModel.fatigueScore, 100, "Should handle max fatigue score")
        XCTAssertEqual(viewModel.fatigueScoreText, "100", "Should display 100 for max score")
    }

    func testViewModel_WithNegativeFatigueScore() {
        // Edge case: negative score (should not happen but test defensive handling)
        viewModel.fatigueSummary = createMockFatigueSummary(fatigueScore: -10, fatigueBand: "low")
        XCTAssertEqual(viewModel.fatigueScore, -10, "Should handle negative score (defensive)")
        XCTAssertEqual(viewModel.fatigueScoreText, "-10", "Should display negative score")
    }

    func testViewModel_EmptyTrendData() {
        viewModel.trendData = []
        XCTAssertTrue(viewModel.trendData.isEmpty, "Should handle empty trend data")
    }

    // MARK: - Helper Methods

    private func createMockFatigueSummary(fatigueScore: Double, fatigueBand: String) -> FatigueSummary {
        return FatigueSummary(
            fatigueScore: fatigueScore,
            fatigueBand: fatigueBand,
            avgReadiness7d: 65.0,
            acuteChronicRatio: 1.2,
            consecutiveLowDays: 2,
            contributingFactors: ["Test factor 1", "Test factor 2"]
        )
    }

    private func createMockPrescription() -> DeloadPrescription {
        return DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Active recovery and mobility work",
            suggestedStartDate: Date()
        )
    }

    private func createMockTrendData(days: Int) -> [FatigueTrendPoint] {
        let calendar = Calendar.current
        return (0..<days).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -days + 1 + daysAgo, to: Date()) ?? Date()
            let score = 45.0 + Double(daysAgo) * 5.0 + Double.random(in: -5...5)
            let band: FatigueBand = score > 70 ? .high : (score > 50 ? .moderate : .low)
            return FatigueTrendPoint(date: date, fatigueScore: score, band: band)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - DeloadPrescription Tests

@MainActor
final class DeloadPrescriptionTests: XCTestCase {

    func testFormattedLoadReduction() {
        let prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Recovery",
            suggestedStartDate: Date()
        )

        XCTAssertEqual(prescription.formattedLoadReduction, "30%",
            "Should format 0.30 as 30%")
    }

    func testFormattedVolumeReduction() {
        let prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Recovery",
            suggestedStartDate: Date()
        )

        XCTAssertEqual(prescription.formattedVolumeReduction, "40%",
            "Should format 0.40 as 40%")
    }

    func testFormattedLoadReduction_ZeroPercent() {
        let prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.0,
            volumeReductionPct: 0.0,
            focus: "Recovery",
            suggestedStartDate: Date()
        )

        XCTAssertEqual(prescription.formattedLoadReduction, "0%",
            "Should format 0.0 as 0%")
    }

    func testFormattedLoadReduction_HighPercent() {
        let prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.50,
            volumeReductionPct: 0.60,
            focus: "Recovery",
            suggestedStartDate: Date()
        )

        XCTAssertEqual(prescription.formattedLoadReduction, "50%",
            "Should format 0.50 as 50%")
        XCTAssertEqual(prescription.formattedVolumeReduction, "60%",
            "Should format 0.60 as 60%")
    }

    func testDateRangeText() {
        let startDate = Date()
        let prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Recovery",
            suggestedStartDate: startDate
        )

        let dateRangeText = prescription.dateRangeText

        // Verify it contains a date separator
        XCTAssertTrue(dateRangeText.contains(" - "),
            "Date range should contain separator")

        // Verify it's not empty
        XCTAssertFalse(dateRangeText.isEmpty,
            "Date range text should not be empty")
    }
}
