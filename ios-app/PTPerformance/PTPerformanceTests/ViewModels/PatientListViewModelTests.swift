//
//  PatientListViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for PatientListViewModel
//  Tests initial state, computed properties, search/filtering, multi-select operations,
//  bulk summary generation, selection mode toggling, and edge cases.
//

import XCTest
@testable import PTPerformance

@MainActor
final class PatientListViewModelTests: XCTestCase {

    var sut: PatientListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = PatientListViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_PatientsIsEmpty() {
        XCTAssertTrue(sut.patients.isEmpty, "patients should be empty initially")
    }

    func testInitialState_ActiveFlagsIsEmpty() {
        XCTAssertTrue(sut.activeFlags.isEmpty, "activeFlags should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "", "searchText should be empty initially")
    }

    func testInitialState_SelectedFlagFilterIsAll() {
        XCTAssertEqual(sut.selectedFlagFilter, .all, "selectedFlagFilter should be .all initially")
    }

    func testInitialState_SelectedSportIsNil() {
        XCTAssertNil(sut.selectedSport, "selectedSport should be nil initially")
    }

    func testInitialState_IsSelectionModeActiveIsFalse() {
        XCTAssertFalse(sut.isSelectionModeActive, "isSelectionModeActive should be false initially")
    }

    func testInitialState_SelectedPatientIdsIsEmpty() {
        XCTAssertTrue(sut.selectedPatientIds.isEmpty, "selectedPatientIds should be empty initially")
    }

    func testInitialState_AvailableProgramsIsEmpty() {
        XCTAssertTrue(sut.availablePrograms.isEmpty, "availablePrograms should be empty initially")
    }

    func testInitialState_IsBulkOperationInProgressIsFalse() {
        XCTAssertFalse(sut.isBulkOperationInProgress, "isBulkOperationInProgress should be false initially")
    }

    func testInitialState_BulkOperationErrorIsNil() {
        XCTAssertNil(sut.bulkOperationError, "bulkOperationError should be nil initially")
    }

    // MARK: - isEmpty Computed Property

    func testIsEmpty_WhenNotLoadingAndNoPatientsReturnsTrue() {
        sut.isLoading = false
        sut.patients = []
        XCTAssertTrue(sut.isEmpty, "isEmpty should be true when not loading and no patients")
    }

    func testIsEmpty_WhenLoadingReturnsFalse() {
        sut.isLoading = true
        sut.patients = []
        XCTAssertFalse(sut.isEmpty, "isEmpty should be false when loading")
    }

    func testIsEmpty_WhenHasPatientsReturnsFalse() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.isLoading = false
        XCTAssertFalse(sut.isEmpty, "isEmpty should be false when patients exist")
    }

    // MARK: - isSearchEmpty Computed Property

    func testIsSearchEmpty_WhenSearchTextEmptyReturnsFalse() {
        sut.searchText = ""
        XCTAssertFalse(sut.isSearchEmpty, "isSearchEmpty should be false when no search text")
    }

    func testIsSearchEmpty_WhenSearchHasResultsReturnsFalse() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.searchText = "John"
        XCTAssertFalse(sut.isSearchEmpty, "isSearchEmpty should be false when search has results")
    }

    func testIsSearchEmpty_WhenSearchHasNoResultsReturnsTrue() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.searchText = "Zzzzzz"
        XCTAssertTrue(sut.isSearchEmpty, "isSearchEmpty should be true when search has no results")
    }

    // MARK: - emptyStateMessage Computed Property

    func testEmptyStateMessage_WhenErrorExists() {
        sut.errorMessage = "Network error occurred"
        let message = sut.emptyStateMessage
        XCTAssertEqual(message, "Network error occurred")
    }

    func testEmptyStateMessage_WhenSearchEmpty() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.searchText = "NoMatch"
        let message = sut.emptyStateMessage
        XCTAssertTrue(message.contains("NoMatch"), "Message should include the search term")
        XCTAssertTrue(message.contains("No patients match"), "Message should explain no results found")
    }

    func testEmptyStateMessage_WhenListEmpty() {
        sut.patients = []
        sut.isLoading = false
        sut.searchText = ""
        sut.errorMessage = nil
        let message = sut.emptyStateMessage
        XCTAssertTrue(message.contains("don't have any patients"), "Message should explain no patients exist")
    }

    func testEmptyStateMessage_WhenHasPatients() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.searchText = ""
        sut.errorMessage = nil
        let message = sut.emptyStateMessage
        XCTAssertEqual(message, "", "Message should be empty when patients exist and no search")
    }

    func testEmptyStateMessage_ErrorTakesPrecedenceOverSearchEmpty() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        sut.searchText = "NoMatch"
        sut.errorMessage = "Something went wrong"
        let message = sut.emptyStateMessage
        XCTAssertEqual(message, "Something went wrong", "Error message should take precedence")
    }

    // MARK: - filteredPatients Computed Property

    func testFilteredPatients_WhenSearchEmpty_ReturnsAll() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = ""

        XCTAssertEqual(sut.filteredPatients.count, 2, "Should return all patients when search is empty")
    }

    func testFilteredPatients_FiltersByFirstName() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = "John"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.firstName, "John")
    }

    func testFilteredPatients_FiltersByLastName() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = "Smith"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.lastName, "Smith")
    }

    func testFilteredPatients_FiltersByFullName() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = "John Doe"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.fullName, "John Doe")
    }

    func testFilteredPatients_FiltersByEmail() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe", email: "john@test.com")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith", email: "jane@test.com")
        sut.patients = [patient1, patient2]
        sut.searchText = "john@test"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.email, "john@test.com")
    }

    func testFilteredPatients_FiltersBySport() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe", sport: "Baseball")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith", sport: "Basketball")
        sut.patients = [patient1, patient2]
        sut.searchText = "Baseball"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.sport, "Baseball")
    }

    func testFilteredPatients_CaseInsensitive() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]
        sut.searchText = "john"

        XCTAssertEqual(sut.filteredPatients.count, 1, "Search should be case insensitive")
    }

    func testFilteredPatients_NoResults() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]
        sut.searchText = "Xyz"

        XCTAssertTrue(sut.filteredPatients.isEmpty, "Should return empty when no match")
    }

    func testFilteredPatients_PartialMatch() {
        let patient = createMockPatient(firstName: "Jonathan", lastName: "Doe")
        sut.patients = [patient]
        sut.searchText = "Jon"

        XCTAssertEqual(sut.filteredPatients.count, 1, "Should match partial strings")
    }

    func testFilteredPatients_NilSportDoesNotCrash() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", sport: nil)
        sut.patients = [patient]
        sut.searchText = "Baseball"

        XCTAssertTrue(sut.filteredPatients.isEmpty, "Should not crash when patient sport is nil")
    }

    // MARK: - availableSports Computed Property

    func testAvailableSports_WhenEmpty() {
        sut.patients = []
        XCTAssertTrue(sut.availableSports.isEmpty, "Should be empty when no patients")
    }

    func testAvailableSports_DeduplicatesAndSorts() {
        sut.patients = [
            createMockPatient(firstName: "John", lastName: "Doe", sport: "Baseball"),
            createMockPatient(firstName: "Jane", lastName: "Smith", sport: "Basketball"),
            createMockPatient(firstName: "Mike", lastName: "Brown", sport: "Baseball"),
            createMockPatient(firstName: "Sarah", lastName: "Lee", sport: "Football")
        ]
        let sports = sut.availableSports
        XCTAssertEqual(sports, ["Baseball", "Basketball", "Football"], "Should deduplicate and sort alphabetically")
    }

    func testAvailableSports_ExcludesNilSports() {
        sut.patients = [
            createMockPatient(firstName: "John", lastName: "Doe", sport: "Baseball"),
            createMockPatient(firstName: "Jane", lastName: "Smith", sport: nil)
        ]
        let sports = sut.availableSports
        XCTAssertEqual(sports, ["Baseball"], "Should exclude patients with nil sport")
    }

    // MARK: - patient(for:) Method

    func testPatientForId_ReturnsCorrectPatient() {
        let id = UUID()
        let patient = createMockPatient(id: id, firstName: "John", lastName: "Doe")
        sut.patients = [patient]

        let result = sut.patient(for: id)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fullName, "John Doe")
    }

    func testPatientForId_ReturnsNilWhenNotFound() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]

        let result = sut.patient(for: UUID())
        XCTAssertNil(result, "Should return nil when patient ID not found")
    }

    func testPatientForId_EmptyList() {
        let result = sut.patient(for: UUID())
        XCTAssertNil(result, "Should return nil from empty list")
    }

    // MARK: - Multi-Select: toggleSelectionMode

    func testToggleSelectionMode_ActivatesMode() {
        XCTAssertFalse(sut.isSelectionModeActive)

        sut.toggleSelectionMode()

        XCTAssertTrue(sut.isSelectionModeActive)
    }

    func testToggleSelectionMode_DeactivatesModeClearsSelections() {
        let id = UUID()
        sut.isSelectionModeActive = true
        sut.selectedPatientIds = [id]

        sut.toggleSelectionMode()

        XCTAssertFalse(sut.isSelectionModeActive)
        XCTAssertTrue(sut.selectedPatientIds.isEmpty, "Selections should be cleared when exiting selection mode")
    }

    func testToggleSelectionMode_DoubleToggle() {
        sut.toggleSelectionMode()
        XCTAssertTrue(sut.isSelectionModeActive)

        sut.toggleSelectionMode()
        XCTAssertFalse(sut.isSelectionModeActive)
    }

    // MARK: - Multi-Select: toggleSelection

    func testToggleSelection_AddsPatientId() {
        let id = UUID()
        sut.toggleSelection(patientId: id)

        XCTAssertTrue(sut.selectedPatientIds.contains(id))
    }

    func testToggleSelection_RemovesPatientId() {
        let id = UUID()
        sut.selectedPatientIds = [id]

        sut.toggleSelection(patientId: id)

        XCTAssertFalse(sut.selectedPatientIds.contains(id))
    }

    func testToggleSelection_MultiplePatients() {
        let id1 = UUID()
        let id2 = UUID()

        sut.toggleSelection(patientId: id1)
        sut.toggleSelection(patientId: id2)

        XCTAssertEqual(sut.selectedPatientIds.count, 2)
        XCTAssertTrue(sut.selectedPatientIds.contains(id1))
        XCTAssertTrue(sut.selectedPatientIds.contains(id2))
    }

    // MARK: - Multi-Select: isSelected

    func testIsSelected_WhenSelectedReturnsTrue() {
        let id = UUID()
        sut.selectedPatientIds = [id]
        XCTAssertTrue(sut.isSelected(patientId: id))
    }

    func testIsSelected_WhenNotSelectedReturnsFalse() {
        let id = UUID()
        XCTAssertFalse(sut.isSelected(patientId: id))
    }

    // MARK: - Multi-Select: selectAll / deselectAll

    func testSelectAll_SelectsAllFilteredPatients() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = ""

        sut.selectAll()

        XCTAssertEqual(sut.selectedPatientIds.count, 2)
        XCTAssertTrue(sut.selectedPatientIds.contains(patient1.id))
        XCTAssertTrue(sut.selectedPatientIds.contains(patient2.id))
    }

    func testSelectAll_RespectsSearchFilter() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = "John"

        sut.selectAll()

        XCTAssertEqual(sut.selectedPatientIds.count, 1, "Should only select filtered patients")
        XCTAssertTrue(sut.selectedPatientIds.contains(patient1.id))
    }

    func testDeselectAll_ClearsAllSelections() {
        let id1 = UUID()
        let id2 = UUID()
        sut.selectedPatientIds = [id1, id2]

        sut.deselectAll()

        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
    }

    // MARK: - Multi-Select: selectedPatients

    func testSelectedPatients_ReturnsCorrectPatients() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        let patient3 = createMockPatient(firstName: "Mike", lastName: "Brown")
        sut.patients = [patient1, patient2, patient3]
        sut.selectedPatientIds = [patient1.id, patient3.id]

        let selected = sut.selectedPatients
        XCTAssertEqual(selected.count, 2)
        XCTAssertTrue(selected.contains(where: { $0.id == patient1.id }))
        XCTAssertTrue(selected.contains(where: { $0.id == patient3.id }))
    }

    func testSelectedPatients_EmptyWhenNoneSelected() {
        sut.patients = [createMockPatient(firstName: "John", lastName: "Doe")]
        XCTAssertTrue(sut.selectedPatients.isEmpty)
    }

    // MARK: - Multi-Select: selectedCount

    func testSelectedCount_ReturnsCorrectCount() {
        sut.selectedPatientIds = [UUID(), UUID(), UUID()]
        XCTAssertEqual(sut.selectedCount, 3)
    }

    func testSelectedCount_ZeroWhenEmpty() {
        XCTAssertEqual(sut.selectedCount, 0)
    }

    // MARK: - Multi-Select: allFilteredPatientsSelected

    func testAllFilteredPatientsSelected_WhenAllSelected() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.selectedPatientIds = [patient1.id, patient2.id]
        sut.searchText = ""

        XCTAssertTrue(sut.allFilteredPatientsSelected)
    }

    func testAllFilteredPatientsSelected_WhenNotAllSelected() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.selectedPatientIds = [patient1.id]
        sut.searchText = ""

        XCTAssertFalse(sut.allFilteredPatientsSelected)
    }

    func testAllFilteredPatientsSelected_WhenNoPatients() {
        sut.patients = []
        XCTAssertFalse(sut.allFilteredPatientsSelected, "Should be false when no filtered patients")
    }

    func testAllFilteredPatientsSelected_RespectsSearchFilter() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        sut.patients = [patient1, patient2]
        sut.searchText = "John"
        sut.selectedPatientIds = [patient1.id]

        XCTAssertTrue(sut.allFilteredPatientsSelected, "Should be true when all filtered patients are selected")
    }

    // MARK: - clearSelectionAndExit

    func testClearSelectionAndExit_ClearsSelectionsAndExitsMode() {
        sut.isSelectionModeActive = true
        sut.selectedPatientIds = [UUID(), UUID()]

        sut.clearSelectionAndExit()

        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
        XCTAssertFalse(sut.isSelectionModeActive)
    }

    func testClearSelectionAndExit_WhenAlreadyInactive() {
        sut.isSelectionModeActive = false
        sut.selectedPatientIds = []

        sut.clearSelectionAndExit()

        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
        XCTAssertFalse(sut.isSelectionModeActive)
    }

    // MARK: - generateBulkSummary Method

    func testGenerateBulkSummary_EmptySelection() {
        let summary = sut.generateBulkSummary(patientIds: [])
        XCTAssertEqual(summary, "No patients selected.")
    }

    func testGenerateBulkSummary_ContainsHeader() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("Modus - Patient Summary"))
        XCTAssertTrue(summary.contains("Total Patients: 1"))
    }

    func testGenerateBulkSummary_ContainsPatientName() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("John Doe"))
    }

    func testGenerateBulkSummary_GroupsBySport() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe", sport: "Baseball")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith", sport: "Basketball")
        sut.patients = [patient1, patient2]

        let summary = sut.generateBulkSummary(patientIds: [patient1.id, patient2.id])
        XCTAssertTrue(summary.contains("[Baseball]"))
        XCTAssertTrue(summary.contains("[Basketball]"))
    }

    func testGenerateBulkSummary_IncludesPosition() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", position: "Pitcher")
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("(Pitcher)"))
    }

    func testGenerateBulkSummary_IncludesAdherence() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", adherencePercentage: 92.5)
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("Adherence: 92%"))
    }

    func testGenerateBulkSummary_IncludesFlagCount() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", flagCount: 3, highSeverityFlagCount: 1)
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("Flags: 3"))
        XCTAssertTrue(summary.contains("(HIGH)"))
    }

    func testGenerateBulkSummary_NoPerPatientFlagsWhenZero() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", flagCount: 0)
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        // The per-patient line should NOT include "| Flags:" when flagCount is 0
        // But the statistics section always includes "Total Flags:"
        let patientLine = summary.components(separatedBy: "\n").first { $0.contains("John Doe") } ?? ""
        XCTAssertFalse(patientLine.contains("Flags:"), "Per-patient line should not include flags when count is 0")
    }

    func testGenerateBulkSummary_NoSportGrouping() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", sport: nil)
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("[No Sport]"))
    }

    func testGenerateBulkSummary_ContainsStatisticsSection() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", adherencePercentage: 85.0)
        sut.patients = [patient]

        let summary = sut.generateBulkSummary(patientIds: [patient.id])
        XCTAssertTrue(summary.contains("Statistics:"))
        XCTAssertTrue(summary.contains("Average Adherence:"))
    }

    func testGenerateBulkSummary_ContainsTotalFlagsInStatistics() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe", flagCount: 2, highSeverityFlagCount: 1)
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith", flagCount: 3, highSeverityFlagCount: 2)
        sut.patients = [patient1, patient2]

        let summary = sut.generateBulkSummary(patientIds: [patient1.id, patient2.id])
        XCTAssertTrue(summary.contains("Total Flags: 5 (3 high severity)"))
    }

    func testGenerateBulkSummary_MultiplePatients() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Doe")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Smith")
        let patient3 = createMockPatient(firstName: "Mike", lastName: "Brown")
        sut.patients = [patient1, patient2, patient3]

        let summary = sut.generateBulkSummary(patientIds: [patient1.id, patient2.id, patient3.id])
        XCTAssertTrue(summary.contains("Total Patients: 3"))
    }

    func testGenerateBulkSummary_SortsByLastNameWithinSport() {
        let patient1 = createMockPatient(firstName: "John", lastName: "Zebra", sport: "Baseball")
        let patient2 = createMockPatient(firstName: "Jane", lastName: "Apple", sport: "Baseball")
        sut.patients = [patient1, patient2]

        let summary = sut.generateBulkSummary(patientIds: [patient1.id, patient2.id])
        // Apple should come before Zebra
        let appleRange = summary.range(of: "Jane Apple")
        let zebraRange = summary.range(of: "John Zebra")
        XCTAssertNotNil(appleRange)
        XCTAssertNotNil(zebraRange)
        if let appleStart = appleRange?.lowerBound, let zebraStart = zebraRange?.lowerBound {
            XCTAssertTrue(appleStart < zebraStart, "Patients should be sorted by last name within sport group")
        }
    }

    // MARK: - FlagFilter Enum Tests

    func testFlagFilter_AllCases() {
        let allCases = PatientListViewModel.FlagFilter.allCases
        XCTAssertEqual(allCases.count, 4, "FlagFilter should have 4 cases")
    }

    func testFlagFilter_RawValues() {
        XCTAssertEqual(PatientListViewModel.FlagFilter.all.rawValue, "All")
        XCTAssertEqual(PatientListViewModel.FlagFilter.high.rawValue, "High Risk")
        XCTAssertEqual(PatientListViewModel.FlagFilter.medium.rawValue, "Medium Risk")
        XCTAssertEqual(PatientListViewModel.FlagFilter.low.rawValue, "Low Risk")
    }

    // MARK: - Patient Model Computed Properties

    func testPatient_FullName() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        XCTAssertEqual(patient.fullName, "John Doe")
    }

    func testPatient_Initials() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        XCTAssertEqual(patient.initials, "JD")
    }

    func testPatient_InitialsLowercase() {
        let patient = createMockPatient(firstName: "john", lastName: "doe")
        XCTAssertEqual(patient.initials, "JD", "Initials should be uppercased")
    }

    func testPatient_HasHighSeverityFlags_True() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", highSeverityFlagCount: 2)
        XCTAssertTrue(patient.hasHighSeverityFlags)
    }

    func testPatient_HasHighSeverityFlags_False() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", highSeverityFlagCount: 0)
        XCTAssertFalse(patient.hasHighSeverityFlags)
    }

    func testPatient_HasHighSeverityFlags_Nil() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe", highSeverityFlagCount: nil)
        XCTAssertFalse(patient.hasHighSeverityFlags)
    }

    // MARK: - State Mutation Tests

    func testErrorMessage_CanBeSetAndCleared() {
        XCTAssertNil(sut.errorMessage)

        sut.errorMessage = "An error occurred"
        XCTAssertEqual(sut.errorMessage, "An error occurred")

        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    func testSearchText_CanBeSet() {
        sut.searchText = "test query"
        XCTAssertEqual(sut.searchText, "test query")
    }

    func testPatients_CanBeSetAndCleared() {
        let patient = createMockPatient(firstName: "John", lastName: "Doe")
        sut.patients = [patient]
        XCTAssertEqual(sut.patients.count, 1)

        sut.patients = []
        XCTAssertTrue(sut.patients.isEmpty)
    }

    // MARK: - Helper Methods

    private func createMockPatient(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String = "test@example.com",
        sport: String? = nil,
        position: String? = nil,
        flagCount: Int? = nil,
        highSeverityFlagCount: Int? = nil,
        adherencePercentage: Double? = nil
    ) -> Patient {
        Patient(
            id: id,
            therapistId: UUID(),
            firstName: firstName,
            lastName: lastName,
            email: email,
            sport: sport,
            position: position,
            injuryType: nil,
            targetLevel: nil,
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: flagCount,
            highSeverityFlagCount: highSeverityFlagCount,
            adherencePercentage: adherencePercentage,
            lastSessionDate: nil
        )
    }
}
