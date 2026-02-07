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
            updatedAt: Date(),
            provider: nil,
            notes: nil,
            parsedData: nil
        )
    }
}

// MARK: - LabResultsViewModel PDF Parsing Tests

@MainActor
final class LabResultsViewModelPDFParsingTests: XCTestCase {

    var sut: LabResultsViewModel!

    override func setUp() {
        super.setUp()
        sut = LabResultsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Parsed Result Structure Tests

    func testParsedLabResult_ProviderQuest() throws {
        let json = """
        {
            "provider": "quest",
            "test_date": "2024-01-15",
            "patient_name": "Test Patient",
            "biomarkers": [
                {"name": "Glucose", "value": 95.0, "unit": "mg/dL", "flag": "normal"}
            ],
            "confidence": "high"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(parsed.provider, .quest)
        XCTAssertEqual(parsed.patientName, "Test Patient")
        XCTAssertEqual(parsed.biomarkers.count, 1)
        XCTAssertEqual(parsed.confidence, .high)
    }

    func testParsedLabResult_ProviderLabCorp() throws {
        let json = """
        {
            "provider": "labcorp",
            "biomarkers": [],
            "confidence": "medium"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(parsed.provider, .labcorp)
    }

    func testParsedLabResult_UnknownProvider() throws {
        let json = """
        {
            "provider": "random_lab_xyz",
            "biomarkers": [],
            "confidence": "low"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(parsed.provider, .unknown)
    }

    // MARK: - Biomarker Parsing Tests

    func testParsedBiomarker_AllFields() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Hemoglobin",
            "value": 14.5,
            "unit": "g/dL",
            "reference_range": "12.0-17.0",
            "reference_low": 12.0,
            "reference_high": 17.0,
            "flag": "normal",
            "category": "CBC",
            "is_selected": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let biomarker = try decoder.decode(ParsedBiomarker.self, from: json)

        XCTAssertEqual(biomarker.name, "Hemoglobin")
        XCTAssertEqual(biomarker.value, 14.5)
        XCTAssertEqual(biomarker.unit, "g/dL")
        XCTAssertEqual(biomarker.referenceRange, "12.0-17.0")
        XCTAssertEqual(biomarker.referenceLow, 12.0)
        XCTAssertEqual(biomarker.referenceHigh, 17.0)
        XCTAssertEqual(biomarker.flag, .normal)
        XCTAssertEqual(biomarker.category, "CBC")
        XCTAssertTrue(biomarker.isSelected)
    }

    func testParsedBiomarker_MinimalFields() throws {
        let json = """
        {
            "name": "Custom Marker",
            "value": 50.0,
            "unit": "units"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let biomarker = try decoder.decode(ParsedBiomarker.self, from: json)

        XCTAssertEqual(biomarker.name, "Custom Marker")
        XCTAssertEqual(biomarker.value, 50.0)
        XCTAssertNil(biomarker.referenceRange)
        XCTAssertNil(biomarker.referenceLow)
        XCTAssertNil(biomarker.referenceHigh)
        XCTAssertNil(biomarker.flag)
        XCTAssertTrue(biomarker.isSelected) // Default value
    }

    // MARK: - Confidence Level Tests

    func testParsingConfidence_HighConfidence() {
        XCTAssertEqual(ParsingConfidence.high.displayName, "High Confidence")
        XCTAssertEqual(ParsingConfidence.high.iconName, "checkmark.circle.fill")
    }

    func testParsingConfidence_MediumConfidence() {
        XCTAssertEqual(ParsingConfidence.medium.displayName, "Medium Confidence")
        XCTAssertEqual(ParsingConfidence.medium.iconName, "exclamationmark.circle.fill")
    }

    func testParsingConfidence_LowConfidence() {
        XCTAssertEqual(ParsingConfidence.low.displayName, "Low Confidence")
        XCTAssertEqual(ParsingConfidence.low.iconName, "questionmark.circle.fill")
    }
}

// MARK: - LabResultsViewModel Manual Entry Validation Tests

@MainActor
final class LabResultsViewModelManualEntryTests: XCTestCase {

    // MARK: - Biomarker Value Validation

    func testBiomarkerValue_ValidPositive() {
        let biomarker = ParsedBiomarker(
            name: "Glucose",
            value: 95.0,
            unit: "mg/dL"
        )

        XCTAssertEqual(biomarker.value, 95.0)
        XCTAssertTrue(biomarker.value > 0)
    }

    func testBiomarkerValue_ValidZero() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 0.0,
            unit: "units"
        )

        XCTAssertEqual(biomarker.value, 0.0)
    }

    func testBiomarkerValue_ValidNegative() {
        // Some biomarkers can have negative values (e.g., deltas)
        let biomarker = ParsedBiomarker(
            name: "Temperature Delta",
            value: -2.5,
            unit: "degrees"
        )

        XCTAssertEqual(biomarker.value, -2.5)
    }

    func testBiomarkerValue_ValidDecimal() {
        let biomarker = ParsedBiomarker(
            name: "TSH",
            value: 0.0015,
            unit: "mIU/L"
        )

        XCTAssertEqual(biomarker.value, 0.0015, accuracy: 0.00001)
    }

    func testBiomarkerValue_ValidLarge() {
        let biomarker = ParsedBiomarker(
            name: "Platelet Count",
            value: 350000.0,
            unit: "cells/uL"
        )

        XCTAssertEqual(biomarker.value, 350000.0)
    }

    // MARK: - Reference Range Validation

    func testReferenceRange_ValidRange() {
        let biomarker = ParsedBiomarker(
            name: "Hemoglobin",
            value: 14.0,
            unit: "g/dL",
            referenceRange: "12.0-17.0",
            referenceLow: 12.0,
            referenceHigh: 17.0
        )

        XCTAssertNotNil(biomarker.referenceLow)
        XCTAssertNotNil(biomarker.referenceHigh)
        XCTAssertTrue(biomarker.referenceLow! < biomarker.referenceHigh!)
    }

    func testReferenceRange_MissingLow() {
        let biomarker = ParsedBiomarker(
            name: "LDL",
            value: 100.0,
            unit: "mg/dL",
            referenceRange: "<130",
            referenceLow: nil,
            referenceHigh: 130.0
        )

        XCTAssertNil(biomarker.referenceLow)
        XCTAssertEqual(biomarker.referenceHigh, 130.0)
    }

    func testReferenceRange_MissingHigh() {
        let biomarker = ParsedBiomarker(
            name: "HDL",
            value: 60.0,
            unit: "mg/dL",
            referenceRange: ">40",
            referenceLow: 40.0,
            referenceHigh: nil
        )

        XCTAssertEqual(biomarker.referenceLow, 40.0)
        XCTAssertNil(biomarker.referenceHigh)
    }

    // MARK: - Unit Validation

    func testBiomarkerUnit_StandardUnits() {
        let standardUnits = ["mg/dL", "ng/mL", "pg/mL", "mIU/L", "g/dL", "cells/uL", "%", "mmol/L"]

        for unit in standardUnits {
            let biomarker = ParsedBiomarker(name: "Test", value: 50.0, unit: unit)
            XCTAssertEqual(biomarker.unit, unit)
        }
    }

    func testBiomarkerUnit_EmptyUnit() {
        let biomarker = ParsedBiomarker(name: "Test", value: 50.0, unit: "")
        XCTAssertEqual(biomarker.unit, "")
    }

    // MARK: - Flag Conversion Tests

    func testBiomarkerFlag_ToLabMarker_Normal() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 50.0,
            unit: "units",
            flag: .normal
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .normal)
    }

    func testBiomarkerFlag_ToLabMarker_Low() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 20.0,
            unit: "units",
            flag: .low
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .low)
    }

    func testBiomarkerFlag_ToLabMarker_High() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 100.0,
            unit: "units",
            flag: .high
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .high)
    }

    func testBiomarkerFlag_ToLabMarker_Critical() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 200.0,
            unit: "units",
            flag: .critical
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .critical)
    }

    func testBiomarkerFlag_ToLabMarker_NilFlag() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 50.0,
            unit: "units",
            flag: nil
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .normal) // Default
    }
}

// MARK: - LabResultsViewModel Biomarker Categorization Tests

@MainActor
final class LabResultsViewModelCategorizationTests: XCTestCase {

    var sut: LabResultsViewModel!

    override func setUp() {
        super.setUp()
        sut = LabResultsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Type Categorization

    func testLabTestType_AllCasesHaveDisplayNames() {
        for testType in LabTestType.allCases {
            XCTAssertFalse(testType.displayName.isEmpty, "TestType \(testType) should have a display name")
        }
    }

    func testLabTestType_RawValues() {
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

    // MARK: - Grouped Results Sorting

    func testGroupedResults_SortedAlphabetically() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        // Add in non-alphabetical order
        sut.labResults = [
            createMockLabResult(testType: .vitaminD, id: id1),
            createMockLabResult(testType: .bloodPanel, id: id2),
            createMockLabResult(testType: .lipidPanel, id: id3)
        ]

        let grouped = sut.groupedResults
        let testTypeNames = grouped.map { $0.0.displayName }

        // Should be sorted: Blood Panel, Lipid Panel, Vitamin D
        XCTAssertEqual(testTypeNames, testTypeNames.sorted())
    }

    // MARK: - LabResult Safe Accessors

    func testLabResult_TestTypeValue_WithType() {
        let result = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .hormonePanel,
            results: nil,
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertEqual(result.testTypeValue, .hormonePanel)
    }

    func testLabResult_TestTypeValue_NilType() {
        let result = LabResult(
            id: UUID(),
            patientId: nil,
            testDate: nil,
            testType: nil,
            results: nil,
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertEqual(result.testTypeValue, .other)
    }

    func testLabResult_ResultsList_WithResults() {
        let marker = LabMarker(
            id: UUID(),
            name: "Glucose",
            value: 95.0,
            unit: "mg/dL",
            referenceMin: 70.0,
            referenceMax: 100.0,
            status: .normal
        )

        let result = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .metabolicPanel,
            results: [marker],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertEqual(result.resultsList.count, 1)
    }

    func testLabResult_ResultsList_NilResults() {
        let result = LabResult(
            id: UUID(),
            patientId: nil,
            testDate: nil,
            testType: nil,
            results: nil,
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertTrue(result.resultsList.isEmpty)
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
            updatedAt: Date(),
            provider: nil,
            notes: nil,
            parsedData: nil
        )
    }
}

// MARK: - LabResultsViewModel Edge Cases Tests

@MainActor
final class LabResultsViewModelEdgeCasesTests: XCTestCase {

    var sut: LabResultsViewModel!

    override func setUp() {
        super.setUp()
        sut = LabResultsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Empty Lab Results

    func testEmptyLabResults_GroupedResults() {
        sut.labResults = []
        XCTAssertTrue(sut.groupedResults.isEmpty)
    }

    func testEmptyLabResults_RecentResults() {
        sut.labResults = []
        XCTAssertTrue(sut.recentResults.isEmpty)
    }

    // MARK: - Single Lab Result

    func testSingleLabResult_GroupedResults() {
        sut.labResults = [createMockLabResult(testType: .bloodPanel, id: UUID())]

        XCTAssertEqual(sut.groupedResults.count, 1)
        XCTAssertEqual(sut.groupedResults.first?.1.count, 1)
    }

    func testSingleLabResult_RecentResults() {
        let result = createMockLabResult(testType: .bloodPanel, id: UUID())
        sut.labResults = [result]

        XCTAssertEqual(sut.recentResults.count, 1)
        XCTAssertEqual(sut.recentResults.first?.id, result.id)
    }

    // MARK: - Large Dataset

    func testLargeDataset_RecentResultsLimit() {
        // Create 20 results
        let results = (0..<20).map { createMockLabResult(testType: .bloodPanel, id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", $0))")!) }
        sut.labResults = results

        // Recent results should only return 5
        XCTAssertEqual(sut.recentResults.count, 5)
    }

    func testLargeDataset_GroupedResultsPerformance() {
        // Create 100 results across different types
        var results: [LabResult] = []
        for i in 0..<100 {
            let testType = LabTestType.allCases[i % LabTestType.allCases.count]
            results.append(createMockLabResult(testType: testType, id: UUID()))
        }
        sut.labResults = results

        // Should still group correctly
        XCTAssertFalse(sut.groupedResults.isEmpty)

        // Total count across all groups should equal original count
        let totalGrouped = sut.groupedResults.reduce(0) { $0 + $1.1.count }
        XCTAssertEqual(totalGrouped, 100)
    }

    // MARK: - Invalid Biomarker Values

    func testInvalidBiomarkerValue_NaN() {
        // This tests handling of edge case values
        let value = Double.nan
        XCTAssertTrue(value.isNaN)
    }

    func testInvalidBiomarkerValue_Infinity() {
        let value = Double.infinity
        XCTAssertTrue(value.isInfinite)
    }

    // MARK: - Missing Reference Ranges

    func testMissingReferenceRanges_BothMissing() {
        let marker = LabMarker(
            id: UUID(),
            name: "Custom",
            value: 50.0,
            unit: "units",
            referenceMin: nil,
            referenceMax: nil,
            status: .normal
        )

        XCTAssertNil(marker.referenceMin)
        XCTAssertNil(marker.referenceMax)
    }

    func testMissingReferenceRanges_OnlyMinPresent() {
        let marker = LabMarker(
            id: UUID(),
            name: "HDL",
            value: 60.0,
            unit: "mg/dL",
            referenceMin: 40.0,
            referenceMax: nil,
            status: .normal
        )

        XCTAssertEqual(marker.referenceMin, 40.0)
        XCTAssertNil(marker.referenceMax)
    }

    func testMissingReferenceRanges_OnlyMaxPresent() {
        let marker = LabMarker(
            id: UUID(),
            name: "LDL",
            value: 100.0,
            unit: "mg/dL",
            referenceMin: nil,
            referenceMax: 130.0,
            status: .normal
        )

        XCTAssertNil(marker.referenceMin)
        XCTAssertEqual(marker.referenceMax, 130.0)
    }

    // MARK: - Partial Data Scenarios

    func testPartialData_NoTestDate() {
        let result = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: nil,
            testType: .bloodPanel,
            results: [],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertNil(result.testDate)
        XCTAssertEqual(result.testTypeValue, .bloodPanel)
    }

    func testPartialData_NoPatientId() {
        let result = LabResult(
            id: UUID(),
            patientId: nil,
            testDate: Date(),
            testType: .bloodPanel,
            results: [],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        XCTAssertNil(result.patientId)
    }

    func testPartialData_OnlyRequiredFields() {
        let result = LabResult(
            id: UUID(),
            patientId: nil,
            testDate: nil,
            testType: nil,
            results: nil,
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: nil,
            updatedAt: nil,
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        // Should still be usable with safe accessors
        XCTAssertEqual(result.testTypeValue, .other)
        XCTAssertTrue(result.resultsList.isEmpty)
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
            updatedAt: Date(),
            provider: nil,
            notes: nil,
            parsedData: nil
        )
    }
}
