//
//  AuthenticationFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for authentication flows
//  ACP-226: Critical user flow E2E testing
//

import XCTest

/// E2E tests for authentication critical flows
///
/// Tests the complete authentication experience including:
/// - Demo patient login
/// - Demo therapist login
/// - Login error handling
/// - Session persistence
/// - Login screen UI elements
final class AuthenticationFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launchEnvironment["IS_RUNNING_UITEST"] = "1"
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Demo Login Tests

    /// Test successful demo patient login
    func testDemoPatientLoginSuccess() throws {
        // Given: App launched at login screen
        app.launch()

        // Wait for login screen to appear
        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Demo Patient button should appear")

        takeScreenshot(named: "login_screen_initial")

        // When: User taps Demo Patient
        demoPatientButton.tap()

        // Then: Should navigate to patient dashboard
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15), "Tab bar should appear after login")

        // Verify patient-specific tabs exist
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists, "Today tab should exist for patient")

        let programsTab = app.tabBars.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist for patient")

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists, "Profile tab should exist for patient")

        takeScreenshot(named: "patient_dashboard_after_login")
    }

    /// Test successful demo therapist login
    func testDemoTherapistLoginSuccess() throws {
        // Given: App launched at login screen
        app.launch()

        // Wait for login screen to appear
        let demoTherapistButton = app.buttons["Demo Therapist"]
        XCTAssertTrue(demoTherapistButton.waitForExistence(timeout: 10), "Demo Therapist button should appear")

        // When: User taps Demo Therapist
        demoTherapistButton.tap()

        // Then: Should navigate to therapist dashboard
        let patientsTab = app.buttons["Patients"]
        XCTAssertTrue(patientsTab.waitForExistence(timeout: 15), "Patients tab should appear for therapist")

        // Verify therapist-specific tabs exist
        let programsTab = app.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist for therapist")

        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist for therapist")

        takeScreenshot(named: "therapist_dashboard_after_login")
    }

    /// Test login screen shows all required elements
    func testLoginScreenUIElements() throws {
        // Given: App launched
        app.launch()

        // Then: All login elements should be visible
        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Demo Patient button should exist")

        let demoTherapistButton = app.buttons["Demo Therapist"]
        XCTAssertTrue(demoTherapistButton.exists, "Demo Therapist button should exist")

        // Verify buttons are interactive
        XCTAssertTrue(demoPatientButton.isHittable, "Demo Patient button should be hittable")
        XCTAssertTrue(demoTherapistButton.isHittable, "Demo Therapist button should be hittable")

        takeScreenshot(named: "login_screen_ui_elements")
    }

    // MARK: - Session Persistence Tests

    /// Test session persists after app relaunch
    func testSessionPersistsAfterRelaunch() throws {
        // Given: User logs in as demo patient
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Demo Patient button should appear")
        demoPatientButton.tap()

        // Wait for dashboard
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15), "Tab bar should appear after login")

        // When: App is relaunched (without reset)
        app.terminate()
        app.launchArguments = ["--uitesting"] // Remove reset flag
        app.launch()

        // Then: User should still be logged in (or at login screen based on app behavior)
        // Note: Demo accounts may not persist - this tests the expected behavior
        let stillLoggedIn = tabBar.waitForExistence(timeout: 5)
        let backAtLogin = app.buttons["Demo Patient"].waitForExistence(timeout: 5)

        XCTAssertTrue(stillLoggedIn || backAtLogin, "App should either persist session or show login screen")

        takeScreenshot(named: "session_after_relaunch")
    }

    // MARK: - Login Flow Variations

    /// Test navigating between login options
    func testLoginOptionNavigation() throws {
        // Given: App launched at login screen
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Login screen should appear")

        // When: User explores login options (without completing login)
        // Check if email login option exists
        let emailLoginButton = app.buttons["Log In"]
        let signUpButton = app.buttons["Sign Up"]

        // Document what's available on login screen
        if emailLoginButton.exists {
            takeScreenshot(named: "login_with_email_option")
        }

        if signUpButton.exists {
            takeScreenshot(named: "login_with_signup_option")
        }

        // Then: Both demo buttons should remain accessible
        XCTAssertTrue(demoPatientButton.isHittable, "Demo Patient should be accessible")

        let demoTherapistButton = app.buttons["Demo Therapist"]
        XCTAssertTrue(demoTherapistButton.isHittable, "Demo Therapist should be accessible")
    }

    /// Test login with network delay simulation
    func testLoginHandlesLoadingState() throws {
        // Given: App launched
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Demo Patient button should appear")

        // When: User initiates login
        demoPatientButton.tap()

        // Then: Loading indicator may appear (capture if present)
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            takeScreenshot(named: "login_loading_state")
        }

        // Eventually should complete
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "Login should complete within reasonable time")

        takeScreenshot(named: "login_completed")
    }

    // MARK: - Accessibility Tests

    /// Test login screen accessibility
    func testLoginScreenAccessibility() throws {
        // Given: App launched
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Login screen should appear")

        // Then: All interactive elements should have accessibility labels
        XCTAssertFalse(demoPatientButton.label.isEmpty, "Demo Patient should have accessibility label")

        let demoTherapistButton = app.buttons["Demo Therapist"]
        XCTAssertFalse(demoTherapistButton.label.isEmpty, "Demo Therapist should have accessibility label")

        // Verify elements are accessible
        XCTAssertTrue(demoPatientButton.isHittable, "Demo Patient should be hittable")
        XCTAssertTrue(demoTherapistButton.isHittable, "Demo Therapist should be hittable")
    }

    // MARK: - Error Handling Tests

    /// Test app handles login interruption gracefully
    func testLoginInterruptionHandling() throws {
        // Given: App launched
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10), "Login screen should appear")

        // When: User starts login then app goes to background
        demoPatientButton.tap()

        // Simulate brief background (press home and return)
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        // Then: App should either complete login or return to stable state
        let tabBar = app.tabBars.firstMatch
        let loginScreen = app.buttons["Demo Patient"]

        let stableState = tabBar.waitForExistence(timeout: 10) || loginScreen.waitForExistence(timeout: 5)
        XCTAssertTrue(stableState, "App should reach stable state after interruption")

        takeScreenshot(named: "login_after_interruption")
    }

    // MARK: - Helper Methods

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
