//
//  AuthFlowTestHelper.swift
//  PTPerformanceUITests
//
//  Helper methods for authentication flow E2E testing
//  Provides reusable utilities for login, logout, session verification, and error handling
//

import XCTest

/// Helper class for authentication flow testing
/// Provides reusable methods for common auth operations
enum AuthFlowTestHelper {

    // MARK: - Configuration

    /// Timeout values for auth operations
    enum AuthTimeout {
        /// Quick timeout for immediate UI responses
        static let immediate: TimeInterval = 3
        /// Standard timeout for UI transitions
        static let standard: TimeInterval = 10
        /// Extended timeout for network/auth operations
        static let auth: TimeInterval = 15
        /// Long timeout for slow operations
        static let slow: TimeInterval = 30
    }

    /// Accessibility identifiers for auth elements
    enum AccessibilityID {
        // Login screen
        static let demoPatientButton = "Demo Patient"
        static let demoTherapistButton = "Demo Therapist"
        static let signInWithAppleButton = "signInWithAppleButton"
        static let continueWithEmailButton = "continueWithEmailButton"
        static let createAccountButton = "createAccountButton"

        // Navigation
        static let todayTab = "Today"
        static let programsTab = "Programs"
        static let profileTab = "Profile"
        static let patientsTab = "Patients"
        static let settingsTab = "Settings"

        // Profile/Settings
        static let logOutButton = "Log Out"
        static let deleteAccountButton = "Delete Account"

        // Loading states
        static let loadingSpinner = "loadingSpinner"
        static let settingUpAccount = "Setting up your account"
    }

    // MARK: - Login Helpers

    /// Perform demo patient login and wait for dashboard
    /// - Parameter app: Application instance
    /// - Returns: True if login succeeded
    @discardableResult
    static func loginAsDemoPatient(in app: XCUIApplication) -> Bool {
        let demoPatientButton = app.buttons[AccessibilityID.demoPatientButton]

        guard demoPatientButton.waitForExistence(timeout: AuthTimeout.standard) else {
            print("ERROR: Demo Patient button not found")
            return false
        }

        demoPatientButton.tap()

        // Wait for successful navigation to patient dashboard
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: AuthTimeout.auth) else {
            print("ERROR: Tab bar did not appear after login")
            return false
        }

        // Wait for any loading to complete
        waitForLoadingToComplete(in: app)

        return true
    }

    /// Perform demo therapist login and wait for dashboard
    /// - Parameter app: Application instance
    /// - Returns: True if login succeeded
    @discardableResult
    static func loginAsDemoTherapist(in app: XCUIApplication) -> Bool {
        let demoTherapistButton = app.buttons[AccessibilityID.demoTherapistButton]

        guard demoTherapistButton.waitForExistence(timeout: AuthTimeout.standard) else {
            print("ERROR: Demo Therapist button not found")
            return false
        }

        demoTherapistButton.tap()

        // Wait for therapist dashboard (Patients tab or tab bar)
        let patientsTab = app.buttons[AccessibilityID.patientsTab]
        let tabBar = app.tabBars.firstMatch

        let loginSucceeded = patientsTab.waitForExistence(timeout: AuthTimeout.auth) ||
                            tabBar.waitForExistence(timeout: AuthTimeout.auth)

        guard loginSucceeded else {
            print("ERROR: Therapist dashboard did not appear after login")
            return false
        }

        waitForLoadingToComplete(in: app)

        return true
    }

    // MARK: - Logout Helpers

    /// Perform logout flow from Profile tab
    /// - Parameter app: Application instance
    /// - Returns: True if logout succeeded
    @discardableResult
    static func logout(from app: XCUIApplication) -> Bool {
        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons[AccessibilityID.profileTab]
        guard profileTab.waitForExistence(timeout: AuthTimeout.standard) else {
            print("ERROR: Profile tab not found")
            return false
        }

        profileTab.tap()
        waitForLoadingToComplete(in: app)

        // Scroll to find Log Out button
        let logOutButton = app.buttons[AccessibilityID.logOutButton]
        var scrollAttempts = 0

        while !logOutButton.isHittable && scrollAttempts < 10 {
            app.swipeUp()
            scrollAttempts += 1
        }

        guard logOutButton.waitForExistence(timeout: AuthTimeout.immediate) else {
            print("ERROR: Log Out button not found after scrolling")
            return false
        }

        logOutButton.tap()

        // Handle confirmation alert if present
        let confirmLogout = app.alerts.buttons["Log Out"]
        if confirmLogout.waitForExistence(timeout: AuthTimeout.immediate) {
            confirmLogout.tap()
        }

        // Verify returned to login screen
        let demoPatientButton = app.buttons[AccessibilityID.demoPatientButton]
        return demoPatientButton.waitForExistence(timeout: AuthTimeout.auth)
    }

    // MARK: - Loading State Helpers

    /// Wait for all loading indicators to disappear
    /// - Parameters:
    ///   - app: Application instance
    ///   - timeout: Maximum wait time
    /// - Returns: True if loading completed
    @discardableResult
    static func waitForLoadingToComplete(
        in app: XCUIApplication,
        timeout: TimeInterval = AuthTimeout.auth
    ) -> Bool {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            // Check for activity indicators
            let spinners = app.activityIndicators.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }

            // Check for "Setting up your account" text (magic link spinner issue)
            let settingUpText = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Setting up'")
            ).firstMatch

            // Check for generic loading text
            let loadingText = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Loading' OR label CONTAINS[c] 'Please wait'")
            ).firstMatch

            let isLoading = !spinners.isEmpty || settingUpText.exists || loadingText.exists

            if !isLoading {
                // Add small buffer for animations
                Thread.sleep(forTimeInterval: 0.3)
                return true
            }

            Thread.sleep(forTimeInterval: 0.2)
        }

        // Log which loading indicator was still showing
        let spinners = app.activityIndicators.allElementsBoundByIndex.filter { $0.exists }
        if !spinners.isEmpty {
            print("WARNING: Loading timeout - activity indicators still present")
        }

        let settingUpText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Setting up'")
        ).firstMatch
        if settingUpText.exists {
            print("WARNING: Loading timeout - 'Setting up your account' still showing (magic link spinner issue)")
        }

        return false
    }

    /// Wait for "Setting up your account" spinner to complete (magic link specific)
    /// - Parameters:
    ///   - app: Application instance
    ///   - timeout: Maximum wait time
    /// - Returns: True if setup completed
    @discardableResult
    static func waitForAccountSetupToComplete(
        in app: XCUIApplication,
        timeout: TimeInterval = AuthTimeout.slow
    ) -> Bool {
        let settingUpText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Setting up'")
        ).firstMatch

        // If not showing, we're already past setup
        if !settingUpText.exists {
            return true
        }

        // Wait for it to disappear
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: settingUpText)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        return result == .completed
    }

    // MARK: - Navigation Verification

    /// Verify navigation to patient home screen (Today tab)
    /// - Parameter app: Application instance
    /// - Returns: True if on patient home
    static func isOnPatientHomeScreen(in app: XCUIApplication) -> Bool {
        let todayTab = app.tabBars.buttons[AccessibilityID.todayTab]
        let programsTab = app.tabBars.buttons[AccessibilityID.programsTab]
        let profileTab = app.tabBars.buttons[AccessibilityID.profileTab]

        // Patient should have Today, Programs, and Profile tabs
        return todayTab.exists && programsTab.exists && profileTab.exists
    }

    /// Verify navigation to therapist home screen (Patients tab)
    /// - Parameter app: Application instance
    /// - Returns: True if on therapist home
    static func isOnTherapistHomeScreen(in app: XCUIApplication) -> Bool {
        let patientsTab = app.buttons[AccessibilityID.patientsTab]

        // Also check for navigation title
        let patientsTitle = app.staticTexts["Patients"]
        let navigationTitle = app.navigationBars.staticTexts["Patients"]

        return patientsTab.exists || patientsTitle.exists || navigationTitle.exists
    }

    /// Verify on login screen
    /// - Parameter app: Application instance
    /// - Returns: True if on login screen
    static func isOnLoginScreen(in app: XCUIApplication) -> Bool {
        let demoPatientButton = app.buttons[AccessibilityID.demoPatientButton]
        let demoTherapistButton = app.buttons[AccessibilityID.demoTherapistButton]

        return demoPatientButton.exists && demoTherapistButton.exists
    }

    /// Verify correct home screen based on role
    /// - Parameters:
    ///   - app: Application instance
    ///   - role: Expected user role
    /// - Returns: True if on correct home screen
    static func isOnCorrectHomeScreen(
        in app: XCUIApplication,
        forRole role: UserRole
    ) -> Bool {
        switch role {
        case .patient:
            return isOnPatientHomeScreen(in: app)
        case .therapist:
            return isOnTherapistHomeScreen(in: app)
        }
    }

    /// User role enum for testing
    enum UserRole {
        case patient
        case therapist
    }

    // MARK: - Error Checking

    /// Check for error alerts
    /// - Parameter app: Application instance
    /// - Returns: Error message if alert present, nil otherwise
    static func getErrorAlertMessage(in app: XCUIApplication) -> String? {
        let alert = app.alerts.firstMatch
        guard alert.exists else { return nil }

        // Get alert title and message
        let title = alert.label
        let messageText = alert.staticTexts.allElementsBoundByIndex
            .compactMap { $0.label }
            .joined(separator: " ")

        return "\(title): \(messageText)"
    }

    /// Dismiss any error alert
    /// - Parameter app: Application instance
    /// - Returns: True if alert was dismissed
    @discardableResult
    static func dismissErrorAlert(in app: XCUIApplication) -> Bool {
        let alert = app.alerts.firstMatch
        guard alert.exists else { return false }

        // Try common dismiss buttons
        let dismissButtons = ["OK", "Dismiss", "Cancel", "Close", "Got it"]

        for buttonLabel in dismissButtons {
            let button = alert.buttons[buttonLabel]
            if button.exists {
                button.tap()
                return true
            }
        }

        // Fall back to first button
        if let firstButton = alert.buttons.allElementsBoundByIndex.first {
            firstButton.tap()
            return true
        }

        return false
    }

    /// Check for auth-specific error messages
    /// - Parameter app: Application instance
    /// - Returns: True if auth error is present
    static func hasAuthError(in app: XCUIApplication) -> Bool {
        let errorKeywords = [
            "error",
            "failed",
            "invalid",
            "expired",
            "could not",
            "unable to",
            "network",
            "connection"
        ]

        for keyword in errorKeywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let errorText = app.staticTexts.containing(predicate).firstMatch
            if errorText.exists {
                return true
            }
        }

        return app.alerts.firstMatch.exists
    }

    /// Assert no auth errors are present
    /// - Parameters:
    ///   - app: Application instance
    ///   - file: Source file
    ///   - line: Source line
    static func assertNoAuthErrors(
        in app: XCUIApplication,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let errorMessage = getErrorAlertMessage(in: app) {
            XCTFail("Unexpected auth error: \(errorMessage)", file: file, line: line)
        }
    }

    // MARK: - Session Verification

    /// Verify session is cleared after logout
    /// - Parameter app: Application instance
    /// - Returns: True if session is cleared
    static func isSessionCleared(in app: XCUIApplication) -> Bool {
        // Should be on login screen
        let onLoginScreen = isOnLoginScreen(in: app)

        // Tab bar should not be visible
        let noTabBar = !app.tabBars.firstMatch.exists

        return onLoginScreen && noTabBar
    }

    /// Verify user is authenticated
    /// - Parameter app: Application instance
    /// - Returns: True if user appears authenticated
    static func isAuthenticated(in app: XCUIApplication) -> Bool {
        // Check for tab bar (indicates logged in state)
        let tabBar = app.tabBars.firstMatch

        // Check for patient or therapist-specific elements
        let todayTab = app.tabBars.buttons[AccessibilityID.todayTab]
        let patientsButton = app.buttons[AccessibilityID.patientsTab]

        return tabBar.exists && (todayTab.exists || patientsButton.exists)
    }

    // MARK: - Demo Data Verification

    /// Verify demo patient data is visible
    /// - Parameter app: Application instance
    /// - Returns: True if demo data is visible
    static func isDemoPatientDataVisible(in app: XCUIApplication) -> Bool {
        // Check for workout content
        let workoutIndicators = [
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'workout'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'session'")).firstMatch,
            app.tables.cells.firstMatch,
            app.scrollViews.firstMatch
        ]

        return workoutIndicators.contains { $0.exists }
    }

    /// Verify demo therapist data is visible (patient list)
    /// - Parameter app: Application instance
    /// - Returns: True if patient list is visible
    static func isDemoTherapistDataVisible(in app: XCUIApplication) -> Bool {
        // Check for patient list
        let patientIndicators = [
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'patient'")).firstMatch,
            app.tables.cells.firstMatch,
            app.staticTexts["Patients"]
        ]

        return patientIndicators.contains { $0.exists }
    }

    // MARK: - Screenshot Helpers

    /// Capture screenshot with descriptive name
    /// - Parameters:
    ///   - name: Screenshot name
    ///   - testCase: Test case for attachment
    ///   - lifetime: Attachment lifetime
    static func captureScreenshot(
        named name: String,
        in testCase: XCTestCase,
        lifetime: XCTAttachment.Lifetime = .deleteOnSuccess
    ) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = lifetime
        testCase.add(attachment)
    }

    /// Capture failure screenshot (always kept)
    /// - Parameters:
    ///   - name: Screenshot name
    ///   - testCase: Test case for attachment
    static func captureFailureScreenshot(
        named name: String,
        in testCase: XCTestCase
    ) {
        captureScreenshot(named: "FAILURE_\(name)", in: testCase, lifetime: .keepAlways)
    }

    // MARK: - Diagnostic Helpers

    /// Log current app state for debugging
    /// - Parameter app: Application instance
    static func logAppState(_ app: XCUIApplication) {
        print("=== App State Diagnostics ===")
        print("Tab bar exists: \(app.tabBars.firstMatch.exists)")
        print("Visible tabs: \(app.tabBars.buttons.allElementsBoundByIndex.map { $0.label })")
        print("Alert present: \(app.alerts.firstMatch.exists)")
        print("Activity indicator: \(app.activityIndicators.firstMatch.exists)")
        print("==============================")
    }

    /// Get list of visible buttons (for debugging)
    /// - Parameter app: Application instance
    /// - Returns: Array of button labels
    static func getVisibleButtons(in app: XCUIApplication) -> [String] {
        return app.buttons.allElementsBoundByIndex
            .filter { $0.exists && $0.isHittable }
            .map { $0.label }
    }
}

// MARK: - XCUIElement Extensions for Auth Testing

extension XCUIElement {

    /// Wait for element to disappear (useful for loading states)
    /// - Parameter timeout: Maximum wait time
    /// - Returns: True if element disappeared
    func waitForDisappearance(timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
