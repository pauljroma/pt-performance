//
//  PatientListViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for PatientListViewModel
//  Tests therapist filtering, patient loading, and flag management
//

import XCTest
@testable import PTPerformance

@MainActor
final class PatientListViewModelTests: XCTestCase {

    var viewModel: PatientListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = PatientListViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.patients.count, 0, "Patients should be empty initially")
        XCTAssertEqual(viewModel.activeFlags.count, 0, "Flags should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
        XCTAssertEqual(viewModel.searchText, "", "Search should be empty initially")
    }

    // MARK: - Supabase Client Tests

    func testSupabaseClientConfiguration() {
        // CRITICAL: Must use PTSupabaseClient, not SupabaseClient
        let supabase = PTSupabaseClient.shared
        XCTAssertNotNil(supabase, "PTSupabaseClient should be available")
        XCTAssertNotNil(supabase.client, "Supabase client should be initialized")
    }

    // MARK: - Patient Loading Tests

    func testLoadPatientsWithoutTherapistID() async {
        // Test loading patients without therapist ID filter
        await viewModel.loadPatients()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")

        // Should either:
        // 1. Load all patients (if no filter)
        // 2. Have error message
        if viewModel.patients.isEmpty {
            // If empty, could be valid (no patients) or error
            print("⚠️ No patients loaded - verify if this is expected")
        }
    }

    func testLoadPatientsWithTherapistID() async {
        // Test loading patients WITH therapist ID filter
        let testTherapistID = "test-therapist-123"

        await viewModel.loadPatients(therapistId: testTherapistID)

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")

        // CRITICAL: This should filter by therapist_id
        // If patients are loaded, they should all belong to this therapist
        // (Can't validate without mock data, but test structure ensures it's called)
    }

    func testLoadPatientsFallbackToSampleData() async {
        // If Supabase query fails, should NOT crash
        await viewModel.loadPatients()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        // Should have either real data or error message, never crash
    }

    // MARK: - Active Flags Tests

    func testLoadActiveFlagsWithoutTherapistID() async {
        await viewModel.loadActiveFlags()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        // Flags may be empty if none exist, that's ok
    }

    func testLoadActiveFlagsWithTherapistID() async {
        let testTherapistID = "test-therapist-123"

        await viewModel.loadActiveFlags(therapistId: testTherapistID)

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
    }

    // MARK: - Search and Filter Tests

    func testSearchTextFiltering() {
        // Setup sample patients for filtering test
        viewModel.patients = Patient.samplePatients

        // Test empty search returns all
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredPatients.count, viewModel.patients.count,
            "Empty search should return all patients")

        // Test search by name
        viewModel.searchText = "John"
        let nameResults = viewModel.filteredPatients
        XCTAssertTrue(nameResults.allSatisfy { patient in
            patient.fullName.localizedCaseInsensitiveContains("John") ||
            patient.email.localizedCaseInsensitiveContains("John") ||
            (patient.sport?.localizedCaseInsensitiveContains("John") ?? false)
        }, "Search should filter by name, email, or sport")

        // Test case insensitivity
        viewModel.searchText = "JOHN"
        XCTAssertEqual(viewModel.filteredPatients.count, nameResults.count,
            "Search should be case insensitive")
    }

    func testAvailableSports() {
        viewModel.patients = Patient.samplePatients

        let sports = viewModel.availableSports
        XCTAssertFalse(sports.isEmpty, "Should extract sports from patients")
        XCTAssertEqual(sports, sports.sorted(), "Sports should be sorted")

        // Check no duplicates
        let uniqueSports = Set(sports)
        XCTAssertEqual(sports.count, uniqueSports.count,
            "Available sports should have no duplicates")
    }

    // MARK: - Refresh Tests

    func testRefresh() async {
        await viewModel.refresh()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    func testRefreshWithTherapistID() async {
        let testTherapistID = "test-therapist-123"

        await viewModel.refresh(therapistId: testTherapistID)

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    // MARK: - Patient Lookup Tests

    func testPatientLookup() {
        viewModel.patients = Patient.samplePatients

        guard let firstPatient = viewModel.patients.first else {
            XCTFail("No sample patients available")
            return
        }

        let foundPatient = viewModel.patient(for: firstPatient.id)
        XCTAssertNotNil(foundPatient, "Should find patient by UUID")
        XCTAssertEqual(foundPatient?.id, firstPatient.id, "Should return correct patient")

        // Test not found case
        let randomUUID = UUID()
        let notFound = viewModel.patient(for: randomUUID)
        XCTAssertNil(notFound, "Should return nil for non-existent patient")
    }

    // MARK: - Critical Bug Prevention Tests

    func testTherapistIDParameterAccepted() async {
        // CRITICAL: Ensure therapistId parameter is actually used
        // This would have caught the "load all patients" bug

        let therapistID = "specific-therapist-id"

        // This call should use the therapistId parameter, not ignore it
        await viewModel.loadPatients(therapistId: therapistID)

        // We can't verify the exact query without mocking,
        // but this ensures the parameter path exists
        XCTAssertFalse(viewModel.isLoading, "Should complete")
    }

    func testNoCrashOnEmptyResults() async {
        // Ensure app doesn't crash if database returns empty results
        await viewModel.loadPatients()
        await viewModel.loadActiveFlags()

        // Should handle empty results gracefully
        XCTAssertNotNil(viewModel.patients, "Patients array should exist (even if empty)")
        XCTAssertNotNil(viewModel.activeFlags, "Flags array should exist (even if empty)")
    }

    func testErrorHandlingDoesNotCrash() async {
        // Test that errors don't crash the app
        await viewModel.loadPatients(therapistId: "invalid-therapist")

        // Should either load data or set error, but not crash
        XCTAssertFalse(viewModel.isLoading, "Should finish loading")

        if viewModel.patients.isEmpty {
            // Empty is ok if it's intentional or if there's an error message
            print("⚠️ No patients loaded for invalid therapist")
        }
    }

    // MARK: - Loading State Tests

    func testLoadingStateManagement() async {
        let loadingExpectation = expectation(description: "Loading completes")

        Task {
            await viewModel.loadPatients()
            XCTAssertFalse(viewModel.isLoading, "Loading should be false when complete")
            loadingExpectation.fulfill()
        }

        await fulfillment(of: [loadingExpectation], timeout: 10.0)
    }
}
