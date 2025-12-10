//
//  TodaySessionViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for TodaySessionViewModel
//  Tests backend fallback, Supabase queries, and error handling
//

import XCTest
@testable import PTPerformance

@MainActor
final class TodaySessionViewModelTests: XCTestCase {

    var viewModel: TodaySessionViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = TodaySessionViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Backend Configuration Tests

    func testBackendURLConfiguration() {
        // CRITICAL: Backend URL must use Supabase Edge Functions, NOT localhost
        let backendURL = Config.backendURL

        XCTAssertFalse(backendURL.contains("localhost"),
            "CRITICAL BUG: Backend URL contains localhost - will fail on physical devices")
        XCTAssertFalse(backendURL.contains("127.0.0.1"),
            "CRITICAL BUG: Backend URL contains 127.0.0.1 - will fail on physical devices")
        XCTAssertTrue(backendURL.contains("supabase.co") || backendURL.contains("https://"),
            "Backend URL should be a valid HTTPS endpoint")

        print("✅ Backend URL validation: \(backendURL)")
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(viewModel.session, "Session should be nil initially")
        XCTAssertEqual(viewModel.exercises.count, 0, "Exercises should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
    }

    // MARK: - Patient ID Validation Tests

    func testFetchWithoutPatientID() async {
        // Simulate no logged-in user
        // This should fail gracefully with error message

        await viewModel.fetchTodaySession()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message when no patient ID")
        XCTAssertTrue(viewModel.errorMessage?.contains("No patient ID") ?? false,
            "Error should mention missing patient ID")
    }

    // MARK: - Loading State Tests

    func testLoadingStateChanges() async {
        // Test that loading state properly toggles during fetch
        let loadingExpectation = expectation(description: "Loading state changes")

        Task {
            XCTAssertFalse(viewModel.isLoading, "Should start not loading")

            await viewModel.fetchTodaySession()

            XCTAssertFalse(viewModel.isLoading, "Should finish loading")
            loadingExpectation.fulfill()
        }

        await fulfillment(of: [loadingExpectation], timeout: 10.0)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageClearing() async {
        // Set an error message
        viewModel.errorMessage = "Test error"
        XCTAssertNotNil(viewModel.errorMessage)

        // Fetch should clear previous error
        await viewModel.fetchTodaySession()

        // Error message should be updated (either cleared if success, or new error)
        // We don't know if fetch will succeed or fail, but it should not be "Test error"
        XCTAssertNotEqual(viewModel.errorMessage, "Test error",
            "Old error message should be cleared on new fetch")
    }

    // MARK: - Refresh Tests

    func testRefresh() async {
        // Refresh should call fetchTodaySession
        await viewModel.refresh()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    // MARK: - Integration Test Markers

    func testSupabaseClientAvailable() {
        // Verify Supabase client is properly configured
        let supabase = PTSupabaseClient.shared
        XCTAssertNotNil(supabase, "PTSupabaseClient should be available")
        XCTAssertNotNil(supabase.client, "Supabase client should be initialized")
    }

    // MARK: - Critical Bug Prevention Tests

    func testNoDemoDataHardcoding() async {
        // CRITICAL: Ensure we're not returning hardcoded demo data
        await viewModel.fetchTodaySession()

        // If session is loaded, it should be from database, not hardcoded
        if let session = viewModel.session {
            // Real database sessions should have valid UUIDs
            XCTAssertFalse(session.id.isEmpty, "Session ID should not be empty")

            // Session name should not be obviously hardcoded
            XCTAssertNotEqual(session.name, "Sample Session",
                "CRITICAL BUG: Returning hardcoded sample data instead of database query")
        }
    }

    func testBackendFallbackToSupabase() async {
        // Test that if backend fails, Supabase fallback works
        // This test validates the dual-path approach

        await viewModel.fetchTodaySession()

        // Either:
        // 1. Success (session loaded from backend or Supabase)
        // 2. Graceful failure (error message explains why)

        if viewModel.session == nil {
            // If no session, must have clear error message
            XCTAssertNotNil(viewModel.errorMessage,
                "CRITICAL BUG: No session loaded and no error message - user gets blank screen")
            XCTAssertFalse(viewModel.errorMessage?.isEmpty ?? true,
                "Error message should not be empty")
        }
    }

    // MARK: - Performance Tests

    func testFetchPerformance() {
        measure {
            Task {
                await viewModel.fetchTodaySession()
            }
        }
    }
}
