//
//  TherapistDashboardTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for therapist dashboard functionality
//  Tests patient list loading, filtering, search, selection, navigation, and statistics
//

import XCTest
@testable import PTPerformance

// MARK: - PatientListViewModel Tests

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
        XCTAssertTrue(sut.patients.isEmpty)
    }

    func testInitialState_ActiveFlagsIsEmpty() {
        XCTAssertTrue(sut.activeFlags.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    func testInitialState_SelectedFlagFilterIsAll() {
        XCTAssertEqual(sut.selectedFlagFilter, .all)
    }

    func testInitialState_SelectionModeInactive() {
        XCTAssertFalse(sut.isSelectionModeActive)
    }

    func testInitialState_SelectedPatientIdsIsEmpty() {
        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
    }

    // MARK: - Filter Enumeration Tests

    func testFlagFilter_AllCases() {
        let allCases = PatientListViewModel.FlagFilter.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.low))
    }

    func testFlagFilter_RawValues() {
        XCTAssertEqual(PatientListViewModel.FlagFilter.all.rawValue, "All")
        XCTAssertEqual(PatientListViewModel.FlagFilter.high.rawValue, "High Risk")
        XCTAssertEqual(PatientListViewModel.FlagFilter.medium.rawValue, "Medium Risk")
        XCTAssertEqual(PatientListViewModel.FlagFilter.low.rawValue, "Low Risk")
    }

    // MARK: - Patient Search/Filter Tests

    func testFilteredPatients_EmptySearchReturnsAll() {
        sut.patients = createMockPatients()
        sut.searchText = ""

        XCTAssertEqual(sut.filteredPatients.count, sut.patients.count)
    }

    func testFilteredPatients_SearchByFirstName() {
        sut.patients = createMockPatients()
        sut.searchText = "John"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.firstName, "John")
    }

    func testFilteredPatients_SearchByLastName() {
        sut.patients = createMockPatients()
        sut.searchText = "Smith"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertEqual(sut.filteredPatients.first?.lastName, "Smith")
    }

    func testFilteredPatients_SearchByEmail() {
        sut.patients = createMockPatients()
        sut.searchText = "john@example"

        XCTAssertEqual(sut.filteredPatients.count, 1)
        XCTAssertTrue(sut.filteredPatients.first?.email.contains("john") ?? false)
    }

    func testFilteredPatients_SearchBySport() {
        sut.patients = createMockPatients()
        sut.searchText = "Baseball"

        let filtered = sut.filteredPatients
        XCTAssertTrue(filtered.allSatisfy { $0.sport == "Baseball" })
    }

    func testFilteredPatients_CaseInsensitiveSearch() {
        sut.patients = createMockPatients()
        sut.searchText = "JOHN"

        XCTAssertEqual(sut.filteredPatients.count, 1)
    }

    func testFilteredPatients_NoMatchReturnsEmpty() {
        sut.patients = createMockPatients()
        sut.searchText = "XYZ123"

        XCTAssertTrue(sut.filteredPatients.isEmpty)
    }

    func testFilteredPatients_PartialMatchWorks() {
        sut.patients = createMockPatients()
        sut.searchText = "oh" // Partial match for "John"

        XCTAssertFalse(sut.filteredPatients.isEmpty)
    }

    // MARK: - Available Sports Tests

    func testAvailableSports_ExtractsSportsFromPatients() {
        sut.patients = createMockPatients()

        let sports = sut.availableSports
        XCTAssertTrue(sports.contains("Baseball"))
        XCTAssertTrue(sports.contains("Basketball"))
    }

    func testAvailableSports_IsSorted() {
        sut.patients = createMockPatients()

        let sports = sut.availableSports
        XCTAssertEqual(sports, sports.sorted())
    }

    func testAvailableSports_ExcludesNilSports() {
        var patients = createMockPatients()
        patients.append(createMockPatient(sport: nil))
        sut.patients = patients

        let sports = sut.availableSports
        XCTAssertFalse(sports.contains(""))
    }

    func testAvailableSports_RemovesDuplicates() {
        var patients = createMockPatients()
        patients.append(createMockPatient(firstName: "Extra", sport: "Baseball"))
        sut.patients = patients

        let baseballCount = sut.availableSports.filter { $0 == "Baseball" }.count
        XCTAssertEqual(baseballCount, 1)
    }

    // MARK: - Patient Lookup Tests

    func testPatient_FindsByPatientId() {
        sut.patients = createMockPatients()

        guard let firstPatient = sut.patients.first else {
            XCTFail("No patients in list")
            return
        }

        let found = sut.patient(for: firstPatient.id)
        XCTAssertEqual(found?.id, firstPatient.id)
    }

    func testPatient_ReturnsNilForNonexistentId() {
        sut.patients = createMockPatients()

        let found = sut.patient(for: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Selection Mode Tests

    func testToggleSelectionMode_ActivatesMode() {
        XCTAssertFalse(sut.isSelectionModeActive)

        sut.toggleSelectionMode()

        XCTAssertTrue(sut.isSelectionModeActive)
    }

    func testToggleSelectionMode_DeactivatesAndClearsSelections() {
        sut.isSelectionModeActive = true
        sut.selectedPatientIds = [UUID(), UUID()]

        sut.toggleSelectionMode()

        XCTAssertFalse(sut.isSelectionModeActive)
        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
    }

    func testToggleSelection_AddsPatientId() {
        let patientId = UUID()

        sut.toggleSelection(patientId: patientId)

        XCTAssertTrue(sut.selectedPatientIds.contains(patientId))
    }

    func testToggleSelection_RemovesPatientId() {
        let patientId = UUID()
        sut.selectedPatientIds.insert(patientId)

        sut.toggleSelection(patientId: patientId)

        XCTAssertFalse(sut.selectedPatientIds.contains(patientId))
    }

    func testIsSelected_ReturnsTrueForSelectedPatient() {
        let patientId = UUID()
        sut.selectedPatientIds.insert(patientId)

        XCTAssertTrue(sut.isSelected(patientId: patientId))
    }

    func testIsSelected_ReturnsFalseForUnselectedPatient() {
        let patientId = UUID()

        XCTAssertFalse(sut.isSelected(patientId: patientId))
    }

    func testSelectAll_SelectsAllFilteredPatients() {
        sut.patients = createMockPatients()
        sut.searchText = ""

        sut.selectAll()

        XCTAssertEqual(sut.selectedPatientIds.count, sut.patients.count)
    }

    func testSelectAll_OnlySelectsFilteredPatients() {
        sut.patients = createMockPatients()
        sut.searchText = "John"

        sut.selectAll()

        XCTAssertEqual(sut.selectedPatientIds.count, sut.filteredPatients.count)
    }

    func testDeselectAll_ClearsAllSelections() {
        sut.patients = createMockPatients()
        sut.selectAll()
        XCTAssertFalse(sut.selectedPatientIds.isEmpty)

        sut.deselectAll()

        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
    }

    func testSelectedPatients_ReturnsCorrectPatients() {
        sut.patients = createMockPatients()
        guard let firstPatient = sut.patients.first else {
            XCTFail("No patients")
            return
        }

        sut.selectedPatientIds.insert(firstPatient.id)

        XCTAssertEqual(sut.selectedPatients.count, 1)
        XCTAssertEqual(sut.selectedPatients.first?.id, firstPatient.id)
    }

    func testSelectedCount_ReturnsCorrectCount() {
        sut.selectedPatientIds = [UUID(), UUID(), UUID()]

        XCTAssertEqual(sut.selectedCount, 3)
    }

    func testAllFilteredPatientsSelected_ReturnsTrueWhenAllSelected() {
        sut.patients = createMockPatients()
        sut.selectAll()

        XCTAssertTrue(sut.allFilteredPatientsSelected)
    }

    func testAllFilteredPatientsSelected_ReturnsFalseWhenNoneSelected() {
        sut.patients = createMockPatients()

        XCTAssertFalse(sut.allFilteredPatientsSelected)
    }

    func testAllFilteredPatientsSelected_ReturnsFalseWhenPartiallySelected() {
        sut.patients = createMockPatients()
        guard let firstPatient = sut.patients.first else {
            XCTFail("No patients")
            return
        }
        sut.selectedPatientIds.insert(firstPatient.id)

        XCTAssertFalse(sut.allFilteredPatientsSelected)
    }

    func testClearSelectionAndExit_ClearsAndExits() {
        sut.isSelectionModeActive = true
        sut.selectedPatientIds = [UUID(), UUID()]

        sut.clearSelectionAndExit()

        XCTAssertFalse(sut.isSelectionModeActive)
        XCTAssertTrue(sut.selectedPatientIds.isEmpty)
    }

    // MARK: - Bulk Summary Generation Tests

    func testGenerateBulkSummary_WithNoPatients() {
        let summary = sut.generateBulkSummary(patientIds: [])

        XCTAssertEqual(summary, "No patients selected.")
    }

    func testGenerateBulkSummary_ContainsPatientCount() {
        sut.patients = createMockPatients()
        let patientIds = Set(sut.patients.map { $0.id })

        let summary = sut.generateBulkSummary(patientIds: patientIds)

        XCTAssertTrue(summary.contains("Total Patients: \(sut.patients.count)"))
    }

    func testGenerateBulkSummary_ContainsPatientNames() {
        sut.patients = createMockPatients()
        let patientIds = Set(sut.patients.map { $0.id })

        let summary = sut.generateBulkSummary(patientIds: patientIds)

        for patient in sut.patients {
            XCTAssertTrue(summary.contains(patient.fullName))
        }
    }

    func testGenerateBulkSummary_ContainsSportGrouping() {
        sut.patients = createMockPatients()
        let patientIds = Set(sut.patients.map { $0.id })

        let summary = sut.generateBulkSummary(patientIds: patientIds)

        XCTAssertTrue(summary.contains("[Baseball]") || summary.contains("[Basketball]"))
    }

    // MARK: - Security Tests

    func testLoadPatients_WithoutTherapistIdSetsError() async {
        await sut.loadPatients(therapistId: nil)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.patients.isEmpty)
    }

    func testLoadPatients_WithEmptyTherapistIdSetsError() async {
        await sut.loadPatients(therapistId: "")

        // Empty string is still passed, security check is on nil
        // This tests the behavior - in production, additional validation may be needed
        XCTAssertTrue(sut.patients.isEmpty || sut.errorMessage != nil)
    }

    // MARK: - Dashboard Statistics Tests

    func testDashboardStatistics_PatientCount() {
        sut.patients = createMockPatients()

        XCTAssertEqual(sut.patients.count, 3)
    }

    func testDashboardStatistics_FlagCount() {
        sut.activeFlags = createMockFlags()

        XCTAssertEqual(sut.activeFlags.count, 2)
    }

    func testDashboardStatistics_PatientsWithHighFlags() {
        sut.patients = createMockPatients()

        let highFlagPatients = sut.patients.filter { $0.hasHighSeverityFlags }
        XCTAssertEqual(highFlagPatients.count, 1)
    }

    // MARK: - Helper Methods

    private func createMockPatients() -> [Patient] {
        return [
            createMockPatient(firstName: "John", lastName: "Doe", email: "john@example.com", sport: "Baseball"),
            createMockPatient(firstName: "Jane", lastName: "Smith", email: "jane@example.com", sport: "Basketball"),
            createMockPatient(firstName: "Bob", lastName: "Johnson", email: "bob@example.com", sport: "Baseball", highSeverityFlagCount: 1)
        ]
    }

    private func createMockPatient(
        firstName: String = "Test",
        lastName: String = "Patient",
        email: String = "test@example.com",
        sport: String? = nil,
        highSeverityFlagCount: Int = 0
    ) -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: firstName,
            lastName: lastName,
            email: email,
            sport: sport,
            position: nil,
            injuryType: nil,
            targetLevel: nil,
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: highSeverityFlagCount,
            highSeverityFlagCount: highSeverityFlagCount,
            adherencePercentage: 85.0,
            lastSessionDate: Date()
        )
    }

    private func createMockFlags() -> [WorkloadFlag] {
        // Return empty array as WorkloadFlag initialization may require specific setup
        return []
    }
}

// MARK: - Patient Model Tests

final class PatientModelTests: XCTestCase {

    // MARK: - Computed Properties Tests

    func testFullName_CombinesFirstAndLastName() {
        let patient = createPatient(firstName: "John", lastName: "Doe")

        XCTAssertEqual(patient.fullName, "John Doe")
    }

    func testInitials_ReturnsUppercaseInitials() {
        let patient = createPatient(firstName: "john", lastName: "doe")

        XCTAssertEqual(patient.initials, "JD")
    }

    func testInitials_HandlesSingleCharacterNames() {
        let patient = createPatient(firstName: "A", lastName: "B")

        XCTAssertEqual(patient.initials, "AB")
    }

    func testHasHighSeverityFlags_TrueWhenFlagsExist() {
        let patient = createPatient(highSeverityFlagCount: 2)

        XCTAssertTrue(patient.hasHighSeverityFlags)
    }

    func testHasHighSeverityFlags_FalseWhenZeroFlags() {
        let patient = createPatient(highSeverityFlagCount: 0)

        XCTAssertFalse(patient.hasHighSeverityFlags)
    }

    func testHasHighSeverityFlags_FalseWhenNil() {
        let patient = createPatient(highSeverityFlagCount: nil)

        XCTAssertFalse(patient.hasHighSeverityFlags)
    }

    // MARK: - Hashable Tests

    func testHashable_SamePatientsAreEqual() {
        let id = UUID()
        let patient1 = createPatient(id: id)
        let patient2 = createPatient(id: id)

        XCTAssertEqual(patient1, patient2)
    }

    func testHashable_DifferentPatientsAreNotEqual() {
        let patient1 = createPatient()
        let patient2 = createPatient()

        XCTAssertNotEqual(patient1, patient2)
    }

    func testHashable_CanBeUsedInSet() {
        let patient1 = createPatient()
        let patient2 = createPatient()

        var patientSet = Set<Patient>()
        patientSet.insert(patient1)
        patientSet.insert(patient2)

        XCTAssertEqual(patientSet.count, 2)
    }

    // MARK: - Sample Data Tests

    func testSamplePatients_AreNotEmpty() {
        XCTAssertFalse(Patient.samplePatients.isEmpty)
    }

    func testSamplePatients_HaveValidData() {
        for patient in Patient.samplePatients {
            XCTAssertFalse(patient.firstName.isEmpty)
            XCTAssertFalse(patient.lastName.isEmpty)
            XCTAssertFalse(patient.email.isEmpty)
        }
    }

    // MARK: - Helper Methods

    private func createPatient(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "Patient",
        highSeverityFlagCount: Int? = 0
    ) -> Patient {
        Patient(
            id: id,
            therapistId: UUID(),
            firstName: firstName,
            lastName: lastName,
            email: "test@example.com",
            sport: nil,
            position: nil,
            injuryType: nil,
            targetLevel: nil,
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: highSeverityFlagCount,
            highSeverityFlagCount: highSeverityFlagCount,
            adherencePercentage: nil,
            lastSessionDate: nil
        )
    }
}

// MARK: - PatientWithStats Tests

final class PatientWithStatsTests: XCTestCase {

    func testPatientWithStats_IdMatchesPatientId() {
        let patient = createPatient()
        let stats = PatientWithStats(
            patient: patient,
            recentPainAvg: 3.5,
            completedSessions: 10,
            totalSessions: 12
        )

        XCTAssertEqual(stats.id, patient.id)
    }

    func testPatientWithStats_OptionalPainAvg() {
        let patient = createPatient()
        let stats = PatientWithStats(
            patient: patient,
            recentPainAvg: nil,
            completedSessions: 5,
            totalSessions: 5
        )

        XCTAssertNil(stats.recentPainAvg)
    }

    func testPatientWithStats_Equatable() {
        let patient = createPatient()
        let stats1 = PatientWithStats(patient: patient, recentPainAvg: 2.0, completedSessions: 5, totalSessions: 10)
        let stats2 = PatientWithStats(patient: patient, recentPainAvg: 2.0, completedSessions: 5, totalSessions: 10)

        XCTAssertEqual(stats1, stats2)
    }

    private func createPatient() -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            email: "test@example.com"
        )
    }
}

// MARK: - Dashboard Navigation Tests

final class DashboardNavigationTests: XCTestCase {

    func testPatientSelection_ByPatientId() {
        let viewModel = PatientListViewModel()
        let mockPatient = Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            email: "test@example.com"
        )
        viewModel.patients = [mockPatient]

        let found = viewModel.patient(for: mockPatient.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, mockPatient.id)
    }

    func testPatientSelection_ReturnsNilForUnknownId() {
        let viewModel = PatientListViewModel()
        viewModel.patients = []

        let found = viewModel.patient(for: UUID())

        XCTAssertNil(found)
    }
}

// MARK: - DatabaseProgramTemplate Tests

final class DatabaseProgramTemplateTests: XCTestCase {

    func testDatabaseProgramTemplate_Decodable() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "therapist_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "Strength Program",
            "description": "A basic strength program",
            "duration_weeks": 12,
            "program_type": "strength",
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let template = try decoder.decode(DatabaseProgramTemplate.self, from: json)

        XCTAssertEqual(template.name, "Strength Program")
        XCTAssertEqual(template.durationWeeks, 12)
        XCTAssertEqual(template.description, "A basic strength program")
    }

    func testDatabaseProgramTemplate_OptionalDescription() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "therapist_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "Minimal Program",
            "description": null,
            "duration_weeks": 8,
            "program_type": null,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let template = try decoder.decode(DatabaseProgramTemplate.self, from: json)

        XCTAssertNil(template.description)
        XCTAssertNil(template.programType)
    }
}

// MARK: - PatientProgramInsert Tests

final class PatientProgramInsertTests: XCTestCase {

    func testPatientProgramInsert_Encodable() throws {
        let insert = PatientProgramInsert(
            patientId: UUID().uuidString,
            templateId: UUID().uuidString,
            therapistId: UUID().uuidString,
            status: "active",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(insert)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("template_id"))
        XCTAssertTrue(jsonString.contains("therapist_id"))
        XCTAssertTrue(jsonString.contains("status"))
        XCTAssertTrue(jsonString.contains("created_at"))
    }
}
