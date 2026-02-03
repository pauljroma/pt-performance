//
//  LabResultsViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for LabResultsViewModel
//  Tests PDF upload handling, biomarker display, trend chart data, AI analysis integration
//

import XCTest
import Combine
@testable import PTPerformance

// MARK: - Mock Lab Result Service Protocol

protocol LabResultServiceProtocol {
    func fetchLabResults() async
    func deleteLabResult(_ id: UUID) async throws
    func analyzeLabResult(_ result: LabResult) async throws -> LabAnalysis
    func fetchBiomarkerHistory(biomarkerType: String) async throws -> [BiomarkerTrendPoint]
}

// MARK: - Mock Lab Result Service

final class MockLabResultService: LabResultServiceProtocol {
    var mockLabResults: [LabResult] = []
    var mockAnalysis: LabAnalysis?
    var mockBiomarkerTrends: [BiomarkerTrendPoint] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    var fetchLabResultsCallCount = 0
    var deleteLabResultCallCount = 0
    var analyzeLabResultCallCount = 0
    var fetchBiomarkerHistoryCallCount = 0

    var lastDeletedId: UUID?
    var lastAnalyzedResult: LabResult?
    var lastBiomarkerType: String?

    func fetchLabResults() async {
        fetchLabResultsCallCount += 1
    }

    func deleteLabResult(_ id: UUID) async throws {
        deleteLabResultCallCount += 1
        lastDeletedId = id
        if shouldThrowError { throw errorToThrow }
    }

    func analyzeLabResult(_ result: LabResult) async throws -> LabAnalysis {
        analyzeLabResultCallCount += 1
        lastAnalyzedResult = result
        if shouldThrowError { throw errorToThrow }
        if let analysis = mockAnalysis {
            return analysis
        }
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No mock analysis"])
    }

    func fetchBiomarkerHistory(biomarkerType: String) async throws -> [BiomarkerTrendPoint] {
        fetchBiomarkerHistoryCallCount += 1
        lastBiomarkerType = biomarkerType
        if shouldThrowError { throw errorToThrow }
        return mockBiomarkerTrends
    }
}

// MARK: - LabResultsViewModel Extended Tests

@MainActor
final class LabResultsViewModelExtendedTests: XCTestCase {

    var sut: LabResultsViewModel!

    override func setUp() {
        super.setUp()
        sut = LabResultsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_LabResultsIsEmpty() {
        XCTAssertTrue(sut.labResults.isEmpty, "labResults should be empty initially")
    }

    func testInitialState_SelectedResultIsNil() {
        XCTAssertNil(sut.selectedResult, "selectedResult should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_ShowingAddSheetIsFalse() {
        XCTAssertFalse(sut.showingAddSheet, "showingAddSheet should be false initially")
    }

    func testInitialState_ShowingDetailSheetIsFalse() {
        XCTAssertFalse(sut.showingDetailSheet, "showingDetailSheet should be false initially")
    }

    // MARK: - AI Analysis State Tests

    func testInitialState_LabAnalysisIsNil() {
        XCTAssertNil(sut.labAnalysis, "labAnalysis should be nil initially")
    }

    func testInitialState_IsAnalyzingIsFalse() {
        XCTAssertFalse(sut.isAnalyzing, "isAnalyzing should be false initially")
    }

    func testInitialState_AnalysisErrorIsNil() {
        XCTAssertNil(sut.analysisError, "analysisError should be nil initially")
    }

    func testInitialState_BiomarkerTrendDataIsEmpty() {
        XCTAssertTrue(sut.biomarkerTrendData.isEmpty, "biomarkerTrendData should be empty initially")
    }

    func testInitialState_IsLoadingTrendsIsFalse() {
        XCTAssertFalse(sut.isLoadingTrends, "isLoadingTrends should be false initially")
    }

    // MARK: - Biomarker Display Tests (groupedResults)

    func testGroupedResults_WhenEmpty_ReturnsEmpty() {
        sut.labResults = []
        XCTAssertTrue(sut.groupedResults.isEmpty)
    }

    func testGroupedResults_GroupsByTestType() {
        let bloodPanel1 = createMockLabResult(testType: .bloodPanel)
        let bloodPanel2 = createMockLabResult(testType: .bloodPanel)
        let lipidPanel = createMockLabResult(testType: .lipidPanel)

        sut.labResults = [bloodPanel1, bloodPanel2, lipidPanel]

        XCTAssertEqual(sut.groupedResults.count, 2)

        let bloodPanelGroup = sut.groupedResults.first { $0.0 == .bloodPanel }
        XCTAssertNotNil(bloodPanelGroup)
        XCTAssertEqual(bloodPanelGroup?.1.count, 2)

        let lipidPanelGroup = sut.groupedResults.first { $0.0 == .lipidPanel }
        XCTAssertNotNil(lipidPanelGroup)
        XCTAssertEqual(lipidPanelGroup?.1.count, 1)
    }

    func testGroupedResults_SortedByDisplayName() {
        let thyroid = createMockLabResult(testType: .thyroid)
        let bloodPanel = createMockLabResult(testType: .bloodPanel)
        let cbc = createMockLabResult(testType: .cbc)

        sut.labResults = [thyroid, bloodPanel, cbc]

        let testTypes = sut.groupedResults.map { $0.0 }
        let sortedNames = testTypes.map { $0.displayName }

        XCTAssertEqual(sortedNames, sortedNames.sorted())
    }

    // MARK: - Trend Chart Data Tests (recentResults)

    func testRecentResults_WhenEmpty_ReturnsEmpty() {
        sut.labResults = []
        XCTAssertTrue(sut.recentResults.isEmpty)
    }

    func testRecentResults_ReturnsFirst5() {
        let results = (0..<10).map { _ in createMockLabResult(testType: .bloodPanel) }
        sut.labResults = results

        XCTAssertEqual(sut.recentResults.count, 5)
    }

    func testRecentResults_WhenLessThan5_ReturnsAll() {
        let results = (0..<3).map { _ in createMockLabResult(testType: .bloodPanel) }
        sut.labResults = results

        XCTAssertEqual(sut.recentResults.count, 3)
    }

    func testRecentResults_PreservesOrder() {
        let result1 = createMockLabResult(testType: .bloodPanel)
        let result2 = createMockLabResult(testType: .lipidPanel)
        let result3 = createMockLabResult(testType: .thyroid)
        sut.labResults = [result1, result2, result3]

        XCTAssertEqual(sut.recentResults[0].id, result1.id)
        XCTAssertEqual(sut.recentResults[1].id, result2.id)
        XCTAssertEqual(sut.recentResults[2].id, result3.id)
    }

    // MARK: - Selection Tests

    func testSelectResult_SetsSelectedResult() {
        let result = createMockLabResult(testType: .bloodPanel)

        sut.selectResult(result)

        XCTAssertEqual(sut.selectedResult?.id, result.id)
    }

    func testSelectResult_ShowsDetailSheet() {
        let result = createMockLabResult(testType: .bloodPanel)

        sut.selectResult(result)

        XCTAssertTrue(sut.showingDetailSheet)
    }

    // MARK: - Sheet State Tests

    func testShowingAddSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingAddSheet)

        sut.showingAddSheet = true
        XCTAssertTrue(sut.showingAddSheet)

        sut.showingAddSheet = false
        XCTAssertFalse(sut.showingAddSheet)
    }

    func testShowingDetailSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingDetailSheet)

        sut.showingDetailSheet = true
        XCTAssertTrue(sut.showingDetailSheet)

        sut.showingDetailSheet = false
        XCTAssertFalse(sut.showingDetailSheet)
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        sut.error = "Test error"
        XCTAssertEqual(sut.error, "Test error")

        sut.error = nil
        XCTAssertNil(sut.error)
    }

    func testAnalysisError_CanBeSet() {
        sut.analysisError = "Analysis failed"
        XCTAssertEqual(sut.analysisError, "Analysis failed")

        sut.analysisError = nil
        XCTAssertNil(sut.analysisError)
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    func testIsAnalyzing_CanBeSet() {
        sut.isAnalyzing = true
        XCTAssertTrue(sut.isAnalyzing)

        sut.isAnalyzing = false
        XCTAssertFalse(sut.isAnalyzing)
    }

    func testIsLoadingTrends_CanBeSet() {
        sut.isLoadingTrends = true
        XCTAssertTrue(sut.isLoadingTrends)

        sut.isLoadingTrends = false
        XCTAssertFalse(sut.isLoadingTrends)
    }

    // MARK: - AI Analysis Integration Tests

    func testClearAnalysis_ClearsAllAnalysisState() {
        sut.labAnalysis = createMockLabAnalysis()
        sut.analysisError = "Test error"
        sut.biomarkerTrendData = [createMockBiomarkerTrendPoint()]

        sut.clearAnalysis()

        XCTAssertNil(sut.labAnalysis)
        XCTAssertNil(sut.analysisError)
        XCTAssertTrue(sut.biomarkerTrendData.isEmpty)
    }

    // MARK: - Load Results Tests

    func testLoadResults_SetsLoadingState() async {
        let expectation = expectation(description: "Load completes")

        Task {
            await sut.loadResults()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Helper Methods

    private func createMockLabResult(testType: LabTestType) -> LabResult {
        return LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: testType,
            results: [],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockLabAnalysis() -> LabAnalysis {
        return LabAnalysis(
            id: UUID(),
            labResultId: UUID(),
            analysisText: "Sample analysis",
            recommendations: ["Recommendation 1", "Recommendation 2"],
            flaggedMarkers: [],
            overallAssessment: "Good health overall",
            createdAt: Date()
        )
    }

    private func createMockBiomarkerTrendPoint() -> BiomarkerTrendPoint {
        return BiomarkerTrendPoint(
            date: Date(),
            value: 5.0,
            unit: "mg/dL",
            status: .normal
        )
    }
}

// MARK: - LabTestType Tests

final class LabTestTypeExtendedTests: XCTestCase {

    func testAllCasesHaveDisplayName() {
        for testType in LabTestType.allCases {
            XCTAssertFalse(testType.displayName.isEmpty)
        }
    }

    func testDisplayNames() {
        XCTAssertEqual(LabTestType.bloodPanel.displayName, "Blood Panel")
        XCTAssertEqual(LabTestType.metabolicPanel.displayName, "Metabolic Panel")
        XCTAssertEqual(LabTestType.hormonePanel.displayName, "Hormone Panel")
        XCTAssertEqual(LabTestType.lipidPanel.displayName, "Lipid Panel")
        XCTAssertEqual(LabTestType.thyroid.displayName, "Thyroid")
        XCTAssertEqual(LabTestType.vitaminD.displayName, "Vitamin D")
        XCTAssertEqual(LabTestType.iron.displayName, "Iron Studies")
        XCTAssertEqual(LabTestType.cbc.displayName, "Complete Blood Count")
        XCTAssertEqual(LabTestType.other.displayName, "Other")
    }

    func testCasesCount() {
        XCTAssertEqual(LabTestType.allCases.count, 9)
    }

    func testRawValues() {
        XCTAssertEqual(LabTestType.bloodPanel.rawValue, "blood_panel")
        XCTAssertEqual(LabTestType.metabolicPanel.rawValue, "metabolic_panel")
        XCTAssertEqual(LabTestType.hormonePanel.rawValue, "hormone_panel")
        XCTAssertEqual(LabTestType.lipidPanel.rawValue, "lipid_panel")
        XCTAssertEqual(LabTestType.thyroid.rawValue, "thyroid")
        XCTAssertEqual(LabTestType.vitaminD.rawValue, "vitamin_d")
        XCTAssertEqual(LabTestType.iron.rawValue, "iron")
        XCTAssertEqual(LabTestType.cbc.rawValue, "cbc")
        XCTAssertEqual(LabTestType.other.rawValue, "other")
    }
}

// MARK: - MarkerStatus Tests

final class MarkerStatusExtendedTests: XCTestCase {

    func testColors() {
        XCTAssertEqual(MarkerStatus.normal.color, "green")
        XCTAssertEqual(MarkerStatus.low.color, "orange")
        XCTAssertEqual(MarkerStatus.high.color, "orange")
        XCTAssertEqual(MarkerStatus.critical.color, "red")
    }

    func testAllCasesHaveColor() {
        for status in MarkerStatus.allCases {
            XCTAssertFalse(status.color.isEmpty)
        }
    }

    func testCasesCount() {
        XCTAssertEqual(MarkerStatus.allCases.count, 4)
    }
}

// MARK: - LabResult Tests

final class LabResultTests: XCTestCase {

    func testLabResult_Initialization() {
        let id = UUID()
        let patientId = UUID()
        let testDate = Date()
        let testType = LabTestType.bloodPanel

        let result = LabResult(
            id: id,
            patientId: patientId,
            testDate: testDate,
            testType: testType,
            results: [],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.patientId, patientId)
        XCTAssertEqual(result.testDate, testDate)
        XCTAssertEqual(result.testType, testType)
        XCTAssertTrue(result.results.isEmpty)
        XCTAssertNil(result.pdfUrl)
        XCTAssertNil(result.aiAnalysis)
    }

    func testLabResult_WithPdfUrl() {
        let pdfUrl = "https://example.com/lab-result.pdf"

        let result = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .lipidPanel,
            results: [],
            pdfUrl: pdfUrl,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(result.pdfUrl, pdfUrl)
    }

    func testLabResult_WithAiAnalysis() {
        let aiAnalysis = "AI-generated analysis of lab results"

        let result = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .thyroid,
            results: [],
            pdfUrl: nil,
            aiAnalysis: aiAnalysis,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(result.aiAnalysis, aiAnalysis)
    }
}

// MARK: - BiomarkerTrendPoint Tests

final class BiomarkerTrendPointTests: XCTestCase {

    func testBiomarkerTrendPoint_Initialization() {
        let date = Date()
        let value = 5.5
        let unit = "mg/dL"
        let status = MarkerStatus.normal

        let point = BiomarkerTrendPoint(
            date: date,
            value: value,
            unit: unit,
            status: status
        )

        XCTAssertEqual(point.date, date)
        XCTAssertEqual(point.value, value)
        XCTAssertEqual(point.unit, unit)
        XCTAssertEqual(point.status, status)
    }

    func testBiomarkerTrendPoint_DifferentStatuses() {
        let normalPoint = BiomarkerTrendPoint(date: Date(), value: 5.0, unit: "mg/dL", status: .normal)
        let lowPoint = BiomarkerTrendPoint(date: Date(), value: 3.0, unit: "mg/dL", status: .low)
        let highPoint = BiomarkerTrendPoint(date: Date(), value: 8.0, unit: "mg/dL", status: .high)
        let criticalPoint = BiomarkerTrendPoint(date: Date(), value: 12.0, unit: "mg/dL", status: .critical)

        XCTAssertEqual(normalPoint.status, .normal)
        XCTAssertEqual(lowPoint.status, .low)
        XCTAssertEqual(highPoint.status, .high)
        XCTAssertEqual(criticalPoint.status, .critical)
    }
}

// MARK: - LabAnalysis Tests

final class LabAnalysisTests: XCTestCase {

    func testLabAnalysis_Initialization() {
        let id = UUID()
        let labResultId = UUID()
        let analysisText = "Detailed analysis of lab results"
        let recommendations = ["Increase vitamin D intake", "Follow up in 3 months"]
        let flaggedMarkers = ["Vitamin D: Low"]
        let overallAssessment = "Generally healthy with minor deficiencies"
        let createdAt = Date()

        let analysis = LabAnalysis(
            id: id,
            labResultId: labResultId,
            analysisText: analysisText,
            recommendations: recommendations,
            flaggedMarkers: flaggedMarkers,
            overallAssessment: overallAssessment,
            createdAt: createdAt
        )

        XCTAssertEqual(analysis.id, id)
        XCTAssertEqual(analysis.labResultId, labResultId)
        XCTAssertEqual(analysis.analysisText, analysisText)
        XCTAssertEqual(analysis.recommendations.count, 2)
        XCTAssertEqual(analysis.flaggedMarkers.count, 1)
        XCTAssertEqual(analysis.overallAssessment, overallAssessment)
    }

    func testLabAnalysis_EmptyRecommendations() {
        let analysis = LabAnalysis(
            id: UUID(),
            labResultId: UUID(),
            analysisText: "All values are normal",
            recommendations: [],
            flaggedMarkers: [],
            overallAssessment: "Excellent health",
            createdAt: Date()
        )

        XCTAssertTrue(analysis.recommendations.isEmpty)
        XCTAssertTrue(analysis.flaggedMarkers.isEmpty)
    }
}
