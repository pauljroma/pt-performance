//
//  LabResultsViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for LabResultsViewModel
//  Tests initial state, computed properties, and form state management
//

import XCTest
@testable import PTPerformance

@MainActor
final class LabResultsViewModelTests: XCTestCase {

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

    // MARK: - Computed Properties Tests - groupedResults

    func testGroupedResults_WhenEmpty_ReturnsEmpty() {
        sut.labResults = []
        XCTAssertTrue(sut.groupedResults.isEmpty, "groupedResults should be empty when labResults is empty")
    }

    func testGroupedResults_GroupsByTestType() {
        let bloodPanel1 = createMockLabResult(testType: .bloodPanel, id: UUID())
        let bloodPanel2 = createMockLabResult(testType: .bloodPanel, id: UUID())
        let lipidPanel = createMockLabResult(testType: .lipidPanel, id: UUID())

        sut.labResults = [bloodPanel1, bloodPanel2, lipidPanel]

        XCTAssertEqual(sut.groupedResults.count, 2, "Should have 2 groups")

        // Find blood panel group
        let bloodPanelGroup = sut.groupedResults.first { $0.0 == .bloodPanel }
        XCTAssertNotNil(bloodPanelGroup, "Should have blood panel group")
        XCTAssertEqual(bloodPanelGroup?.1.count, 2, "Blood panel group should have 2 results")

        // Find lipid panel group
        let lipidPanelGroup = sut.groupedResults.first { $0.0 == .lipidPanel }
        XCTAssertNotNil(lipidPanelGroup, "Should have lipid panel group")
        XCTAssertEqual(lipidPanelGroup?.1.count, 1, "Lipid panel group should have 1 result")
    }

    func testGroupedResults_SortedByDisplayName() {
        let thyroid = createMockLabResult(testType: .thyroid, id: UUID())
        let bloodPanel = createMockLabResult(testType: .bloodPanel, id: UUID())
        let cbc = createMockLabResult(testType: .cbc, id: UUID())

        sut.labResults = [thyroid, bloodPanel, cbc]

        let testTypes = sut.groupedResults.map { $0.0 }
        let sortedNames = testTypes.map { $0.displayName }

        // Verify sorted alphabetically
        XCTAssertEqual(sortedNames, sortedNames.sorted(), "Groups should be sorted by display name")
    }

    // MARK: - Computed Properties Tests - recentResults

    func testRecentResults_WhenEmpty_ReturnsEmpty() {
        sut.labResults = []
        XCTAssertTrue(sut.recentResults.isEmpty, "recentResults should be empty when labResults is empty")
    }

    func testRecentResults_ReturnsFirst5() {
        let results = (0..<10).map { createMockLabResult(testType: .bloodPanel, id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\($0)")!) }
        sut.labResults = results

        XCTAssertEqual(sut.recentResults.count, 5, "recentResults should return maximum 5 results")
    }

    func testRecentResults_WhenLessThan5_ReturnsAll() {
        let results = (0..<3).map { createMockLabResult(testType: .bloodPanel, id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\($0)")!) }
        sut.labResults = results

        XCTAssertEqual(sut.recentResults.count, 3, "recentResults should return all results when less than 5")
    }

    func testRecentResults_PreservesOrder() {
        let result1 = createMockLabResult(testType: .bloodPanel, id: UUID())
        let result2 = createMockLabResult(testType: .lipidPanel, id: UUID())
        let result3 = createMockLabResult(testType: .thyroid, id: UUID())
        sut.labResults = [result1, result2, result3]

        XCTAssertEqual(sut.recentResults[0].id, result1.id, "First recent result should match first in labResults")
        XCTAssertEqual(sut.recentResults[1].id, result2.id, "Second recent result should match second in labResults")
        XCTAssertEqual(sut.recentResults[2].id, result3.id, "Third recent result should match third in labResults")
    }

    // MARK: - Selection Tests

    func testSelectResult_SetsSelectedResult() {
        let result = createMockLabResult(testType: .bloodPanel, id: UUID())

        sut.selectResult(result)

        XCTAssertEqual(sut.selectedResult?.id, result.id, "selectedResult should be set to the selected result")
    }

    func testSelectResult_ShowsDetailSheet() {
        let result = createMockLabResult(testType: .bloodPanel, id: UUID())

        sut.selectResult(result)

        XCTAssertTrue(sut.showingDetailSheet, "showingDetailSheet should be true after selecting a result")
    }

    // MARK: - Sheet State Tests

    func testShowingAddSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingAddSheet)

        sut.showingAddSheet = true
        XCTAssertTrue(sut.showingAddSheet, "showingAddSheet should be togglable to true")

        sut.showingAddSheet = false
        XCTAssertFalse(sut.showingAddSheet, "showingAddSheet should be togglable to false")
    }

    func testShowingDetailSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingDetailSheet)

        sut.showingDetailSheet = true
        XCTAssertTrue(sut.showingDetailSheet, "showingDetailSheet should be togglable to true")

        sut.showingDetailSheet = false
        XCTAssertFalse(sut.showingDetailSheet, "showingDetailSheet should be togglable to false")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Test error message"
        XCTAssertEqual(sut.error, "Test error message", "error should be settable")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading, "isLoading should be settable to false")
    }

    // MARK: - LabTestType Tests

    func testLabTestType_AllCasesHaveDisplayName() {
        for testType in LabTestType.allCases {
            XCTAssertFalse(testType.displayName.isEmpty, "TestType \(testType) should have a display name")
        }
    }

    func testLabTestType_DisplayNames() {
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

    // MARK: - MarkerStatus Tests

    func testMarkerStatus_Colors() {
        XCTAssertEqual(MarkerStatus.normal.color, "green")
        XCTAssertEqual(MarkerStatus.low.color, "orange")
        XCTAssertEqual(MarkerStatus.high.color, "orange")
        XCTAssertEqual(MarkerStatus.critical.color, "red")
    }

    // MARK: - Helper Methods

    private func createMockLabResult(testType: LabTestType, id: UUID) -> LabResult {
        return LabResult(
            id: id,
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
}
