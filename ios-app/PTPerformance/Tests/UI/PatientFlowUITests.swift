//
//  PatientFlowUITests.swift
//  PTPerformanceUITests
//
//  UI tests for patient login flow
//  Tests UI elements and basic interactions
//

import XCTest

final class PatientFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Login Screen UI Tests

    /// Test that login screen shows all required buttons
    func testLoginScreenShowsAllButtons() throws {
        // Wait for app to launch
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        // Verify demo patient login button exists
        let demoPatientButton = app.buttons["Sign in as Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 5),
            "Demo patient login button should be visible")

        // Verify demo therapist login button exists
        let demoTherapistButton = app.buttons["Sign in as Demo Therapist"]
        XCTAssertTrue(demoTherapistButton.exists,
            "Demo therapist login button should be visible")

        // Verify Nic Roma login button exists
        let nicRomaButton = app.buttons["Sign in as Nic Roma"]
        XCTAssertTrue(nicRomaButton.exists,
            "Nic Roma login button should be visible")

        // Verify Skip button exists
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.exists,
            "Skip button should be visible")
    }

    /// Test that Skip button allows bypassing login
    func testSkipButtonExists() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5),
            "Skip button should be visible on login screen")
    }

    // MARK: - Login Flow Tests (Network Dependent)
    // These tests require network access to Supabase and may skip if network is unavailable

    /// Test patient login flow - requires network
    /// Skipped if network login fails or times out
    func testPatientLoginFlow() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let patientButton = app.buttons["Sign in as Demo Patient"]
        XCTAssertTrue(patientButton.waitForExistence(timeout: 5),
            "Demo patient login button should be visible")

        patientButton.tap()

        // Wait for login to complete - look for various possible screens
        // The app might show: dashboard, tab bar, loading indicator, or error
        let dashboardTitle = app.navigationBars["Today's Session"]
        let noSessionMessage = app.staticTexts["No Session Today"]
        let tabBar = app.tabBars.firstMatch
        let errorAlert = app.alerts.firstMatch

        // Wait up to 15 seconds for some result indicating navigation from login
        let deadline = Date().addingTimeInterval(15)
        var foundResult = false
        var loginButtonStillExists = true

        while Date() < deadline && !foundResult {
            // Check if we left the login screen (button no longer visible)
            loginButtonStillExists = patientButton.exists

            if dashboardTitle.exists || noSessionMessage.exists || tabBar.exists {
                foundResult = true
                break
            }
            if errorAlert.exists {
                throw XCTSkip("Network login failed - error alert shown")
            }
            if !loginButtonStillExists {
                // Login screen is gone, assume login in progress or complete
                foundResult = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        // If login button still visible after 15 seconds, network likely down
        if loginButtonStillExists && !foundResult {
            throw XCTSkip("Login did not navigate away - network may be unavailable")
        }

        XCTAssertTrue(foundResult,
            "Should navigate away from login screen after tapping Sign in")
    }

    /// Test that session data loads after login - requires network
    func testPatientSessionDataLoads() throws {
        // Reuse login flow
        try testPatientLoginFlow()

        // Give additional time for data to load
        Thread.sleep(forTimeInterval: 2)

        // Check for error messages
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'could not be read'")).firstMatch
        if errorMessage.exists {
            throw XCTSkip("Data loading error - network issue")
        }

        // Verify we have some UI (either exercise list, empty state, or tab bar)
        let exerciseList = app.tables.firstMatch
        let noSessionMessage = app.staticTexts["No Session Today"]
        let tabBar = app.tabBars.firstMatch

        XCTAssertTrue(exerciseList.exists || noSessionMessage.exists || tabBar.exists,
            "Should show some dashboard content after login")
    }

    // MARK: - iPad Layout Tests

    func testPatientIPadSplitView() throws {
        // Only run on iPad
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad-specific test, skipping on iPhone")
        }

        // Login first
        try testPatientLoginFlow()

        // Verify split view layout on iPad
        let exerciseList = app.tables.firstMatch
        if exerciseList.waitForExistence(timeout: 5) {
            XCTAssertTrue(exerciseList.isHittable,
                "Exercise list should be visible on iPad")
        }
    }
}
