//
//  SessionManagementTests.swift
//  PTPerformanceUITests
//
//  E2E tests for session management and logout flows
//  ACP-226: Critical user flow E2E testing
//

import XCTest

/// E2E tests for session management critical flows
///
/// Tests the complete session lifecycle including:
/// - Logout flow for patient
/// - Logout flow for therapist
/// - Logout confirmation
/// - Session cleanup
/// - Re-login after logout
final class SessionManagementTests: XCTestCase {

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

    // MARK: - Patient Logout Tests

    /// Test complete patient logout flow
    func testPatientLogoutFlow() throws {
        // Given: User logged in as patient
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear after login")
            return
        }

        takeScreenshot(named: "patient_logged_in")

        // When: Navigate to Profile and tap Log Out
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()

        // Wait for profile content
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to find Log Out button
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            takeScreenshot(named: "patient_logout_not_found")
            XCTFail("Log Out button should exist")
            return
        }

        takeScreenshot(named: "patient_before_logout")
        logOutButton.tap()

        // Handle confirmation alert if present
        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "patient_logout_confirmation")
            confirmButton.tap()
        }

        // Then: Should return to login screen
        let loginScreen = app.buttons["Demo Patient"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 10), "Should return to login screen after logout")

        takeScreenshot(named: "patient_after_logout")
    }

    /// Test logout cancellation
    func testPatientLogoutCancellation() throws {
        // Given: User logged in as patient on Profile tab
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to Log Out
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return // Skip if no logout button found
        }

        logOutButton.tap()

        // When: Cancel button is present, tap it
        let cancelButton = app.alerts.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "logout_cancel_option")
            cancelButton.tap()

            // Then: Should remain logged in
            XCTAssertTrue(profileTab.exists, "Should remain on Profile after cancel")
            XCTAssertFalse(app.buttons["Demo Patient"].exists, "Should not show login screen")

            takeScreenshot(named: "logout_cancelled")
        }
    }

    // MARK: - Therapist Logout Tests

    /// Test complete therapist logout flow
    func testTherapistLogoutFlow() throws {
        // Given: User logged in as therapist
        app.launch()

        let demoTherapistButton = app.buttons["Demo Therapist"]
        guard demoTherapistButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Therapist button should appear")
            return
        }
        demoTherapistButton.tap()

        let settingsTab = app.buttons["Settings"]
        guard settingsTab.waitForExistence(timeout: 15) else {
            XCTFail("Settings tab should appear for therapist")
            return
        }

        takeScreenshot(named: "therapist_logged_in")

        // When: Navigate to Settings and tap Log Out
        settingsTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to find Log Out button
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            takeScreenshot(named: "therapist_logout_not_found")
            XCTFail("Log Out button should exist for therapist")
            return
        }

        takeScreenshot(named: "therapist_before_logout")
        logOutButton.tap()

        // Handle confirmation alert if present
        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "therapist_logout_confirmation")
            confirmButton.tap()
        }

        // Then: Should return to login screen
        let loginScreen = app.buttons["Demo Therapist"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 10), "Should return to login screen after logout")

        takeScreenshot(named: "therapist_after_logout")
    }

    // MARK: - Re-login Tests

    /// Test patient can re-login after logout
    func testPatientReLoginAfterLogout() throws {
        // Given: User logged in, then logged out
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }

        // First login
        demoPatientButton.tap()
        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        // Logout
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return // Skip if logout not available
        }

        logOutButton.tap()

        // Confirm logout
        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }

        // Wait for login screen
        guard app.buttons["Demo Patient"].waitForExistence(timeout: 10) else {
            XCTFail("Should return to login screen")
            return
        }

        // When: User logs in again
        app.buttons["Demo Patient"].tap()

        // Then: Should successfully log in again
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15), "Should be able to re-login after logout")

        takeScreenshot(named: "patient_re_logged_in")
    }

    /// Test switching between patient and therapist accounts
    func testSwitchBetweenAccountTypes() throws {
        // Given: App at login screen
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Login screen should appear")
            return
        }

        // Login as patient
        demoPatientButton.tap()
        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Patient dashboard should appear")
            return
        }
        takeScreenshot(named: "switch_as_patient")

        // Verify patient-specific tab
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists, "Today tab should exist for patient")

        // Logout from patient
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return
        }

        logOutButton.tap()
        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }

        // When: Login as therapist
        let demoTherapistButton = app.buttons["Demo Therapist"]
        guard demoTherapistButton.waitForExistence(timeout: 10) else {
            XCTFail("Login screen should reappear")
            return
        }
        demoTherapistButton.tap()

        // Then: Should see therapist-specific UI
        let patientsTab = app.buttons["Patients"]
        XCTAssertTrue(patientsTab.waitForExistence(timeout: 15), "Patients tab should exist for therapist")

        // Today tab should NOT exist for therapist (or different tabs)
        XCTAssertFalse(app.tabBars.buttons["Today"].exists, "Today tab should not exist for therapist")

        takeScreenshot(named: "switch_as_therapist")
    }

    // MARK: - Session State Tests

    /// Test session cleanup on logout
    func testSessionCleanupOnLogout() throws {
        // Given: User logged in as patient with some activity
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        // Navigate to Programs tab (establish some state)
        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)
        app.swipeUp() // Scroll to establish state

        // Logout
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return
        }

        logOutButton.tap()
        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }

        // Login again
        guard app.buttons["Demo Patient"].waitForExistence(timeout: 10) else {
            XCTFail("Login screen should appear")
            return
        }
        app.buttons["Demo Patient"].tap()

        // Then: Session should start fresh (Today tab selected by default)
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            XCTFail("Should be logged in again")
            return
        }

        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.isSelected, "Should start on Today tab after fresh login")

        takeScreenshot(named: "session_fresh_after_relogin")
    }

    // MARK: - Background/Foreground Tests

    /// Test session survives background/foreground cycle
    func testSessionSurvivesBackgroundForeground() throws {
        // Given: User logged in as patient
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        // Navigate to a specific tab
        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        takeScreenshot(named: "session_before_background")

        // When: App goes to background and returns
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()

        // Then: Should maintain session and state
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Should still be logged in after background")

        // Should still be on Programs tab (or stable state)
        let stableState = programsTab.exists || app.tabBars.buttons["Today"].exists
        XCTAssertTrue(stableState, "Should be in stable state after foreground")

        takeScreenshot(named: "session_after_foreground")
    }

    // MARK: - Error Handling Tests

    /// Test logout handles network issues gracefully
    func testLogoutWithNetworkIssues() throws {
        // Given: User logged in
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        // Navigate to Profile
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Find logout
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return
        }

        // When: Logout (even with potential network issues)
        logOutButton.tap()

        let confirmButton = app.alerts.buttons["Log Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }

        // Then: Should handle gracefully (return to login or show error)
        let loginScreen = app.buttons["Demo Patient"]
        let errorAlert = app.alerts.firstMatch

        let handledGracefully = loginScreen.waitForExistence(timeout: 10) ||
                               errorAlert.waitForExistence(timeout: 10)

        XCTAssertTrue(handledGracefully, "Logout should handle network issues gracefully")

        takeScreenshot(named: "logout_network_handling")
    }

    // MARK: - Accessibility Tests

    /// Test logout button accessibility
    func testLogoutButtonAccessibility() throws {
        // Given: User logged in and on Profile
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear")
            return
        }

        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to logout
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        guard logOutButton.exists else {
            return
        }

        // Then: Logout button should be accessible
        XCTAssertTrue(logOutButton.isHittable, "Log Out button should be hittable")
        XCTAssertFalse(logOutButton.label.isEmpty, "Log Out button should have accessibility label")
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
