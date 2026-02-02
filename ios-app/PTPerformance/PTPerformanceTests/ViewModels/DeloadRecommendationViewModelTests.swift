//
//  DeloadRecommendationViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for DeloadRecommendationViewModel
//  Tests data loading, activate/dismiss actions, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Services

/// Mock FatigueTrackingService for testing
class MockFatigueTrackingService: FatigueTrackingService {

    var shouldFail = false
    var mockFatigueAccumulations: [FatigueAccumulation] = []

    override func getFatigueTrend(patientId: UUID, days: Int) async throws -> [FatigueAccumulation] {
        if shouldFail {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock fatigue trend error"])
        }
        return mockFatigueAccumulations
    }
}

/// Mock DeloadRecommendationService for testing
class MockDeloadRecommendationService: DeloadRecommendationService {

    var shouldFailFetch = false
    var shouldFailActivate = false
    var shouldFailDismiss = false
    var mockRecommendation: DeloadRecommendation?
    var activatedPrescription: DeloadPrescription?
    var dismissedReason: String?

    override func fetchRecommendation(patientId: UUID) async throws {
        if shouldFailFetch {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock fetch error"])
        }
        // Set the recommendation property that the service normally sets
        self.recommendation = mockRecommendation
    }

    override func activateDeload(patientId: UUID, prescription: DeloadPrescription) async throws {
        if shouldFailActivate {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock activation error"])
        }
        activatedPrescription = prescription
    }

    override func dismissRecommendation(patientId: UUID, reason: String?) async throws {
        if shouldFailDismiss {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock dismissal error"])
        }
        dismissedReason = reason
    }
}

// MARK: - Tests

@MainActor
final class DeloadRecommendationViewModelTests: XCTestCase {

    var viewModel: DeloadRecommendationViewModel!
    var mockFatigueService: MockFatigueTrackingService!
    var mockDeloadService: MockDeloadRecommendationService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockFatigueService = MockFatigueTrackingService()
        mockDeloadService = MockDeloadRecommendationService()
        viewModel = DeloadRecommendationViewModel(
            patientId: testPatientId,
            fatigueTrackingService: mockFatigueService,
            deloadRecommendationService: mockDeloadService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockFatigueService = nil
        mockDeloadService = nil
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

    // MARK: - Data Loading Tests

    func testLoadData_Success_PopulatesFatigueSummary() async {
        // Setup mock recommendation
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()

        await viewModel.loadData()

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after loading")
        XCTAssertNotNil(viewModel.fatigueSummary, "fatigueSummary should be populated")
        XCTAssertFalse(viewModel.showError, "showError should be false on success")
    }

    func testLoadData_Success_PopulatesPrescription() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()

        await viewModel.loadData()

        XCTAssertNotNil(viewModel.prescription, "prescription should be populated")
    }

    func testLoadData_Success_PopulatesUrgency() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()

        await viewModel.loadData()

        XCTAssertEqual(viewModel.urgency, .recommended, "urgency should match recommendation")
    }

    func testLoadData_Success_PopulatesContributingFactors() async {
        let mockRec = createMockDeloadRecommendation()
        mockDeloadService.mockRecommendation = mockRec

        await viewModel.loadData()

        XCTAssertEqual(viewModel.contributingFactors.count,
            mockRec.fatigueSummary.contributingFactors.count,
            "contributingFactors should be populated from recommendation")
    }

    func testLoadData_SetsIsLoadingDuringOperation() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()

        XCTAssertFalse(viewModel.isLoading, "Should start not loading")

        await viewModel.loadData()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
    }

    func testLoadData_Failure_SetsErrorState() async {
        mockDeloadService.shouldFailFetch = true

        await viewModel.loadData()

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after failed load")
        XCTAssertTrue(viewModel.showError, "showError should be true after failure")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "errorMessage should be set")
        XCTAssertNotNil(viewModel.error, "error should be set")
    }

    func testLoadData_FatigueTrendFailure_SetsErrorState() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()
        mockFatigueService.shouldFail = true

        await viewModel.loadData()

        // Recommendation loaded but trend failed - should still show error
        XCTAssertTrue(viewModel.showError, "showError should be true when trend fails")
    }

    func testLoadData_PopulatesTrendData() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()
        mockFatigueService.mockFatigueAccumulations = createMockFatigueAccumulations(days: 7)

        await viewModel.loadData()

        XCTAssertEqual(viewModel.trendData.count, 7, "trendData should have 7 points")
    }

    func testLoadData_TrendDataSortedByDate() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()
        mockFatigueService.mockFatigueAccumulations = createMockFatigueAccumulations(days: 7)

        await viewModel.loadData()

        for i in 0..<(viewModel.trendData.count - 1) {
            XCTAssertTrue(viewModel.trendData[i].date <= viewModel.trendData[i + 1].date,
                "Trend data should be sorted by date ascending")
        }
    }

    // MARK: - Refresh Tests

    func testRefresh_CallsLoadData() async {
        mockDeloadService.mockRecommendation = createMockDeloadRecommendation()

        await viewModel.refresh()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    // MARK: - Activate Deload Tests

    func testActivateDeload_WithoutPrescription_DoesNotActivate() async {
        viewModel.prescription = nil
        viewModel.urgency = .recommended

        await viewModel.activateDeload()

        XCTAssertFalse(viewModel.isActivating, "isActivating should be false after call")
        XCTAssertFalse(viewModel.showActivationSuccess, "showActivationSuccess should remain false")
        XCTAssertNil(mockDeloadService.activatedPrescription, "Should not call activate service")
    }

    func testActivateDeload_Success() async {
        let prescription = createMockPrescription()
        viewModel.prescription = prescription
        viewModel.urgency = .recommended

        await viewModel.activateDeload()

        XCTAssertFalse(viewModel.isActivating, "isActivating should be false after completion")
        XCTAssertTrue(viewModel.showActivationSuccess, "showActivationSuccess should be true")
        XCTAssertEqual(viewModel.urgency, .none, "urgency should be cleared after activation")
        XCTAssertNotNil(mockDeloadService.activatedPrescription, "Service should receive prescription")
    }

    func testActivateDeload_Failure() async {
        viewModel.prescription = createMockPrescription()
        viewModel.urgency = .recommended
        mockDeloadService.shouldFailActivate = true

        await viewModel.activateDeload()

        XCTAssertFalse(viewModel.isActivating, "isActivating should be false after failure")
        XCTAssertFalse(viewModel.showActivationSuccess, "showActivationSuccess should be false on failure")
        XCTAssertTrue(viewModel.showError, "showError should be true on failure")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "errorMessage should be set")
    }

    func testActivateDeload_SetsIsActivatingDuringOperation() async {
        viewModel.prescription = createMockPrescription()
        viewModel.urgency = .recommended

        XCTAssertFalse(viewModel.isActivating, "Should start not activating")

        await viewModel.activateDeload()

        XCTAssertFalse(viewModel.isActivating, "Should finish activating")
    }

    // MARK: - Dismiss Recommendation Tests

    func testDismissRecommendation_Success() async {
        viewModel.urgency = .recommended
        viewModel.prescription = createMockPrescription()

        await viewModel.dismissRecommendation()

        XCTAssertFalse(viewModel.isDismissing, "isDismissing should be false after completion")
        XCTAssertTrue(viewModel.showDismissalSuccess, "showDismissalSuccess should be true")
        XCTAssertEqual(viewModel.urgency, .none, "urgency should be cleared after dismissal")
        XCTAssertNil(viewModel.prescription, "prescription should be cleared after dismissal")
    }

    func testDismissRecommendation_WithReason() async {
        let reason = "Athlete feels ready to continue"

        await viewModel.dismissRecommendation(reason: reason)

        XCTAssertEqual(mockDeloadService.dismissedReason, reason, "Service should receive reason")
    }

    func testDismissRecommendation_WithoutReason() async {
        await viewModel.dismissRecommendation(reason: nil)

        XCTAssertNil(mockDeloadService.dismissedReason, "Service should receive nil reason")
    }

    func testDismissRecommendation_Failure() async {
        mockDeloadService.shouldFailDismiss = true

        await viewModel.dismissRecommendation()

        XCTAssertFalse(viewModel.isDismissing, "isDismissing should be false after failure")
        XCTAssertFalse(viewModel.showDismissalSuccess, "showDismissalSuccess should be false on failure")
        XCTAssertTrue(viewModel.showError, "showError should be true on failure")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "errorMessage should be set")
    }

    func testDismissRecommendation_SetsIsDismissingDuringOperation() async {
        XCTAssertFalse(viewModel.isDismissing, "Should start not dismissing")

        await viewModel.dismissRecommendation()

        XCTAssertFalse(viewModel.isDismissing, "Should finish dismissing")
    }

    // MARK: - Error Handling Tests

    func testClearError_ClearsAllErrorState() {
        viewModel.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        viewModel.showError = true
        viewModel.errorMessage = "Test error message"

        viewModel.clearError()

        XCTAssertNil(viewModel.error, "error should be nil after clearError")
        XCTAssertFalse(viewModel.showError, "showError should be false after clearError")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage should be empty after clearError")
    }

    func testClearError_WhenNoError_DoesNothing() {
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")
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

    // MARK: - DeloadPrescription Tests

    func testDeloadPrescription_FormattedLoadReduction() {
        let prescription = createMockPrescription(loadReduction: 0.30, volumeReduction: 0.40)
        XCTAssertEqual(prescription.formattedLoadReduction, "30%", "Should format 0.30 as 30%")
    }

    func testDeloadPrescription_FormattedVolumeReduction() {
        let prescription = createMockPrescription(loadReduction: 0.30, volumeReduction: 0.40)
        XCTAssertEqual(prescription.formattedVolumeReduction, "40%", "Should format 0.40 as 40%")
    }

    func testDeloadPrescription_DateRangeText() {
        let prescription = createMockPrescription()
        let dateRangeText = prescription.dateRangeText

        XCTAssertTrue(dateRangeText.contains(" - "), "Date range should contain separator")
        XCTAssertFalse(dateRangeText.isEmpty, "Date range text should not be empty")
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

    func testViewModel_EmptyTrendData() {
        viewModel.trendData = []
        XCTAssertTrue(viewModel.trendData.isEmpty, "Should handle empty trend data")
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

    private func createMockPrescription(
        loadReduction: Double = 0.30,
        volumeReduction: Double = 0.40
    ) -> DeloadPrescription {
        return DeloadPrescription(
            durationDays: 7,
            loadReductionPct: loadReduction,
            volumeReductionPct: volumeReduction,
            focus: "Active recovery and mobility work",
            suggestedStartDate: Date()
        )
    }

    private func createMockDeloadRecommendation() -> DeloadRecommendation {
        return DeloadRecommendation(
            id: UUID(),
            patientId: testPatientId,
            fatigueSummary: createMockFatigueSummary(fatigueScore: 72.0, fatigueBand: "high"),
            deloadPrescription: createMockPrescription(),
            urgency: .recommended,
            createdAt: Date()
        )
    }

    private func createMockFatigueAccumulations(days: Int) -> [FatigueAccumulation] {
        let calendar = Calendar.current
        return (0..<days).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -days + 1 + daysAgo, to: Date()) ?? Date()
            let score = 45.0 + Double(daysAgo) * 5.0 + Double.random(in: -5...5)
            let band: FatigueBand = score > 70 ? .high : (score > 50 ? .moderate : .low)
            return FatigueAccumulation(
                id: UUID(),
                patientId: testPatientId,
                calculationDate: date,
                avgReadiness7d: 65.0,
                avgReadiness14d: 68.0,
                trainingLoad7d: 1200,
                trainingLoad14d: 2400,
                acuteChronicRatio: 1.2,
                consecutiveLowReadiness: 0,
                missedRepsCount7d: 0,
                highRpeCount7d: 1,
                painReports7d: 0,
                fatigueScore: score,
                fatigueBand: band,
                deloadRecommended: false,
                deloadUrgency: .none,
                createdAt: date,
                updatedAt: date
            )
        }
    }
}
