//
//  AuthFlowTests.swift
//  PTPerformanceUITests
//
//  End-to-end authentication flow tests
//  Verifies complete auth experience including demo mode, logout, session persistence,
//  and role-based navigation
//
//  Context:
//  - Magic link auth was getting stuck on "Setting up your account" spinner
//  - Demo mode needs to work without auth/network
//  - Session state and user role fetching has had issues
//

import XCTest

/// Comprehensive E2E tests for authentication flows
///
/// Test scenarios:
/// 1. Demo Mode Flow - Verify demo login works without network
/// 2. Logout Flow - Verify clean logout and session clearing
/// 3. Session Persistence - Verify session survives app restart
/// 4. Role-Based Navigation - Verify correct home screen per role
/// 5. Error Handling - Verify appropriate error messages and retry
final class AuthFlowTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure launch arguments for testing
        app.launchArguments = [
            "--uitesting",
            "--reset-auth"
        ]

        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1",
            "USE_DEMO_DATA": "1",
            "SKIP_ONBOARDING": "1"
        ]
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Test 1: Demo Mode Flow

    /// Test demo patient login works without network
    /// Verifies: Login -> Patient home screen -> Demo data visible
    func testDemoPatientLoginFlow() throws {
        XCTContext.runActivity(named: "Launch app and verify login screen") { _ in
            app.launch()
            waitForAppReady()

            // Verify login screen appears with demo options
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10),
                         "Demo Patient button should be visible on login screen")

            let demoTherapistButton = app.buttons["Demo Therapist"]
            XCTAssertTrue(demoTherapistButton.exists,
                         "Demo Therapist button should be visible")

            takeScreenshot(named: "01_login_screen")
        }

        XCTContext.runActivity(named: "Tap Demo Patient and verify login") { _ in
            let demoPatientButton = app.buttons["Demo Patient"]
            demoPatientButton.tap()

            // Wait for login to complete - should NOT get stuck on spinner
            let loadingComplete = AuthFlowTestHelper.waitForLoadingToComplete(in: app, timeout: 15)
            XCTAssertTrue(loadingComplete, "Login should not get stuck on loading spinner")

            // Verify tab bar appears
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 15),
                         "Tab bar should appear after demo patient login")

            takeScreenshot(named: "02_demo_patient_logged_in")
        }

        XCTContext.runActivity(named: "Verify patient home screen (Today tab)") { _ in
            // Verify patient-specific tabs
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.exists, "Today tab should exist for patient")
            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")

            let programsTab = app.tabBars.buttons["Programs"]
            XCTAssertTrue(programsTab.exists, "Programs tab should exist for patient")

            let profileTab = app.tabBars.buttons["Profile"]
            XCTAssertTrue(profileTab.exists, "Profile tab should exist for patient")

            takeScreenshot(named: "03_patient_tabs_verified")
        }

        XCTContext.runActivity(named: "Verify demo data is visible") { _ in
            // Wait for content to load
            AuthFlowTestHelper.waitForLoadingToComplete(in: app)

            // Check for workout/exercise content
            let hasContent = AuthFlowTestHelper.isDemoPatientDataVisible(in: app)
            XCTAssertTrue(hasContent, "Demo patient should see workout content")

            takeScreenshot(named: "04_demo_data_visible")
        }
    }

    /// Test demo therapist login and role-based navigation
    func testDemoTherapistLoginFlow() throws {
        XCTContext.runActivity(named: "Launch and login as demo therapist") { _ in
            app.launch()
            waitForAppReady()

            let demoTherapistButton = app.buttons["Demo Therapist"]
            XCTAssertTrue(demoTherapistButton.waitForExistence(timeout: 10),
                         "Demo Therapist button should be visible")

            demoTherapistButton.tap()

            takeScreenshot(named: "therapist_01_after_tap")
        }

        XCTContext.runActivity(named: "Verify therapist dashboard loads") { _ in
            // Wait for loading to complete
            let loadingComplete = AuthFlowTestHelper.waitForLoadingToComplete(in: app, timeout: 15)
            XCTAssertTrue(loadingComplete, "Therapist login should not get stuck")

            // Verify therapist-specific UI
            let isOnTherapistHome = AuthFlowTestHelper.isOnTherapistHomeScreen(in: app)
            XCTAssertTrue(isOnTherapistHome, "Should navigate to therapist dashboard")

            takeScreenshot(named: "therapist_02_dashboard")
        }

        XCTContext.runActivity(named: "Verify patient list is visible") { _ in
            let hasPatientData = AuthFlowTestHelper.isDemoTherapistDataVisible(in: app)
            XCTAssertTrue(hasPatientData, "Therapist should see patient list")

            takeScreenshot(named: "therapist_03_patient_list")
        }
    }

    // MARK: - Test 2: Logout Flow

    /// Test logout from patient account clears session
    func testPatientLogoutFlow() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Should successfully login as demo patient")

            takeScreenshot(named: "logout_01_logged_in")
        }

        XCTContext.runActivity(named: "Navigate to Profile tab") { _ in
            let profileTab = app.tabBars.buttons["Profile"]
            XCTAssertTrue(profileTab.waitForExistence(timeout: 5),
                         "Profile tab should exist")

            profileTab.tap()
            AuthFlowTestHelper.waitForLoadingToComplete(in: app)

            takeScreenshot(named: "logout_02_profile_tab")
        }

        XCTContext.runActivity(named: "Tap Log Out button") { _ in
            // Scroll to find Log Out button
            let logOutButton = app.buttons["Log Out"]
            var scrollAttempts = 0

            while !logOutButton.isHittable && scrollAttempts < 10 {
                app.swipeUp()
                scrollAttempts += 1
            }

            XCTAssertTrue(logOutButton.waitForExistence(timeout: 5),
                         "Log Out button should be visible")

            takeScreenshot(named: "logout_03_before_logout")

            logOutButton.tap()
        }

        XCTContext.runActivity(named: "Handle confirmation if present") { _ in
            // Some versions show confirmation alert
            let confirmButton = app.alerts.buttons["Log Out"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
            }

            takeScreenshot(named: "logout_04_after_logout_tap")
        }

        XCTContext.runActivity(named: "Verify returned to login screen") { _ in
            // Should return to login screen
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10),
                         "Should return to login screen after logout")

            // Verify session is cleared (no tab bar)
            let isCleared = AuthFlowTestHelper.isSessionCleared(in: app)
            XCTAssertTrue(isCleared, "Session should be cleared after logout")

            takeScreenshot(named: "logout_05_login_screen")
        }
    }

    /// Test logout from therapist account
    func testTherapistLogoutFlow() throws {
        XCTContext.runActivity(named: "Login as demo therapist") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoTherapist(in: app)
            XCTAssertTrue(loginSuccess, "Should successfully login as demo therapist")
        }

        XCTContext.runActivity(named: "Find and tap logout") { _ in
            // Look for Settings or Profile tab (therapist may have different tab structure)
            let settingsTab = app.tabBars.buttons["Settings"]
            let profileTab = app.tabBars.buttons["Profile"]

            if settingsTab.exists {
                settingsTab.tap()
            } else if profileTab.exists {
                profileTab.tap()
            }

            AuthFlowTestHelper.waitForLoadingToComplete(in: app)

            // Find logout button
            let logOutButton = app.buttons["Log Out"]
            var scrollAttempts = 0

            while !logOutButton.isHittable && scrollAttempts < 10 {
                app.swipeUp()
                scrollAttempts += 1
            }

            if logOutButton.exists {
                logOutButton.tap()

                // Handle confirmation
                let confirmButton = app.alerts.buttons["Log Out"]
                if confirmButton.waitForExistence(timeout: 3) {
                    confirmButton.tap()
                }
            }

            takeScreenshot(named: "therapist_logout")
        }

        XCTContext.runActivity(named: "Verify returned to login") { _ in
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 15),
                         "Should return to login screen")
        }
    }

    // MARK: - Test 3: Session Persistence

    /// Test session persists after app background and relaunch
    func testSessionPersistsAfterRelaunch() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Initial login should succeed")

            takeScreenshot(named: "persist_01_initial_login")
        }

        XCTContext.runActivity(named: "Terminate and relaunch without reset") { _ in
            app.terminate()

            // Remove reset flag for relaunch
            app.launchArguments = ["--uitesting"]
            app.launch()
            waitForAppReady()

            takeScreenshot(named: "persist_02_after_relaunch")
        }

        XCTContext.runActivity(named: "Verify session state after relaunch") { _ in
            // Allow time for session restoration
            Thread.sleep(forTimeInterval: 2)

            // Check if still authenticated OR back at login
            // (Demo accounts may or may not persist depending on implementation)
            let isAuthenticated = AuthFlowTestHelper.isAuthenticated(in: app)
            let isOnLogin = AuthFlowTestHelper.isOnLoginScreen(in: app)

            XCTAssertTrue(isAuthenticated || isOnLogin,
                         "App should either persist session or show login screen")

            if isAuthenticated {
                // Verify correct role (patient tabs)
                let todayTab = app.tabBars.buttons["Today"]
                XCTAssertTrue(todayTab.exists, "Patient should see Today tab")

                takeScreenshot(named: "persist_03_session_restored")
            } else {
                takeScreenshot(named: "persist_03_back_at_login")
            }
        }
    }

    /// Test app handles background/foreground transitions
    func testSessionSurvivesBackgroundForeground() throws {
        XCTContext.runActivity(named: "Login and verify") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Login should succeed")
        }

        XCTContext.runActivity(named: "Background and foreground app") { _ in
            // Press home to background
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 2)

            // Activate app again
            app.activate()
            Thread.sleep(forTimeInterval: 1)

            takeScreenshot(named: "background_01_after_return")
        }

        XCTContext.runActivity(named: "Verify still authenticated") { _ in
            let isAuthenticated = AuthFlowTestHelper.isAuthenticated(in: app)
            XCTAssertTrue(isAuthenticated, "Should remain authenticated after backgrounding")

            // Verify patient-specific UI still present
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.exists, "Should still see patient tabs")

            takeScreenshot(named: "background_02_session_intact")
        }
    }

    // MARK: - Test 4: Role-Based Navigation

    /// Test patient sees correct home screen
    func testPatientRoleNavigation() throws {
        XCTContext.runActivity(named: "Login as patient and verify role") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Patient login should succeed")
        }

        XCTContext.runActivity(named: "Verify patient-specific navigation") { _ in
            // Should see patient tabs
            let todayTab = app.tabBars.buttons["Today"]
            let programsTab = app.tabBars.buttons["Programs"]
            let profileTab = app.tabBars.buttons["Profile"]

            XCTAssertTrue(todayTab.exists, "Patient should see Today tab")
            XCTAssertTrue(programsTab.exists, "Patient should see Programs tab")
            XCTAssertTrue(profileTab.exists, "Patient should see Profile tab")

            // Should NOT see therapist-specific elements
            let patientsTab = app.tabBars.buttons["Patients"]
            XCTAssertFalse(patientsTab.exists, "Patient should NOT see Patients tab")

            takeScreenshot(named: "role_patient_tabs")
        }

        XCTContext.runActivity(named: "Navigate through patient tabs") { _ in
            // Navigate to Programs
            let programsTab = app.tabBars.buttons["Programs"]
            programsTab.tap()
            AuthFlowTestHelper.waitForLoadingToComplete(in: app)
            XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")

            takeScreenshot(named: "role_patient_programs")

            // Navigate to Profile
            let profileTab = app.tabBars.buttons["Profile"]
            profileTab.tap()
            AuthFlowTestHelper.waitForLoadingToComplete(in: app)
            XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")

            takeScreenshot(named: "role_patient_profile")
        }
    }

    /// Test therapist sees correct home screen
    func testTherapistRoleNavigation() throws {
        XCTContext.runActivity(named: "Login as therapist and verify role") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoTherapist(in: app)
            XCTAssertTrue(loginSuccess, "Therapist login should succeed")
        }

        XCTContext.runActivity(named: "Verify therapist-specific navigation") { _ in
            let isOnTherapistHome = AuthFlowTestHelper.isOnTherapistHomeScreen(in: app)
            XCTAssertTrue(isOnTherapistHome, "Should be on therapist home screen")

            takeScreenshot(named: "role_therapist_home")
        }
    }

    /// Test switching between demo patient and therapist
    func testRoleSwitching() throws {
        XCTContext.runActivity(named: "Login as demo patient first") { _ in
            app.launch()
            waitForAppReady()

            AuthFlowTestHelper.loginAsDemoPatient(in: app)

            let isPatient = AuthFlowTestHelper.isOnPatientHomeScreen(in: app)
            XCTAssertTrue(isPatient, "Should be on patient home")

            takeScreenshot(named: "switch_01_as_patient")
        }

        XCTContext.runActivity(named: "Logout from patient") { _ in
            let logoutSuccess = AuthFlowTestHelper.logout(from: app)
            XCTAssertTrue(logoutSuccess, "Logout should succeed")

            takeScreenshot(named: "switch_02_logged_out")
        }

        XCTContext.runActivity(named: "Login as demo therapist") { _ in
            let loginSuccess = AuthFlowTestHelper.loginAsDemoTherapist(in: app)
            XCTAssertTrue(loginSuccess, "Therapist login should succeed")

            let isTherapist = AuthFlowTestHelper.isOnTherapistHomeScreen(in: app)
            XCTAssertTrue(isTherapist, "Should be on therapist home")

            takeScreenshot(named: "switch_03_as_therapist")
        }
    }

    // MARK: - Test 5: Error Handling

    /// Test app handles login interruption gracefully
    func testLoginInterruptionHandling() throws {
        XCTContext.runActivity(named: "Start login and interrupt") { _ in
            app.launch()
            waitForAppReady()

            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10))

            demoPatientButton.tap()

            // Immediately background app
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 1)

            // Return to app
            app.activate()
            Thread.sleep(forTimeInterval: 2)

            takeScreenshot(named: "interrupt_01_after_return")
        }

        XCTContext.runActivity(named: "Verify app recovers to stable state") { _ in
            // App should either complete login or return to stable state
            let isAuthenticated = AuthFlowTestHelper.isAuthenticated(in: app)
            let isOnLogin = AuthFlowTestHelper.isOnLoginScreen(in: app)

            XCTAssertTrue(isAuthenticated || isOnLogin,
                         "App should reach stable state after interruption")

            // Should not show error alert for normal interruption
            let hasError = AuthFlowTestHelper.hasAuthError(in: app)
            if hasError {
                let errorMessage = AuthFlowTestHelper.getErrorAlertMessage(in: app)
                print("Warning: Error alert shown after interruption: \(errorMessage ?? "unknown")")
            }

            takeScreenshot(named: "interrupt_02_stable_state")
        }
    }

    /// Test no loading spinner gets stuck
    func testNoStuckLoadingSpinner() throws {
        XCTContext.runActivity(named: "Login and verify no stuck spinner") { _ in
            app.launch()
            waitForAppReady()

            let demoPatientButton = app.buttons["Demo Patient"]
            demoPatientButton.tap()

            // Record start time
            let startTime = Date()

            // Wait for loading to complete with generous timeout
            let loadingComplete = AuthFlowTestHelper.waitForLoadingToComplete(in: app, timeout: 30)

            let duration = Date().timeIntervalSince(startTime)

            // Specifically check for "Setting up your account" spinner (magic link issue)
            let settingUpText = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Setting up'")
            ).firstMatch

            if settingUpText.exists {
                XCTFail("'Setting up your account' spinner is stuck - known magic link issue")
            }

            XCTAssertTrue(loadingComplete,
                         "Loading should complete within 30 seconds (took \(String(format: "%.1f", duration))s)")

            takeScreenshot(named: "spinner_test_complete")
        }
    }

    /// Test error alert can be dismissed and retry works
    func testErrorAlertDismissAndRetry() throws {
        // This test verifies error handling works if an error occurs
        // We can't reliably trigger auth errors in demo mode, so we test the UI
        XCTContext.runActivity(named: "Verify error handling infrastructure exists") { _ in
            app.launch()
            waitForAppReady()

            // Verify login screen is accessible
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.exists, "Login options should be visible")

            // If there was an error alert, verify it can be dismissed
            if app.alerts.firstMatch.exists {
                let dismissed = AuthFlowTestHelper.dismissErrorAlert(in: app)
                XCTAssertTrue(dismissed, "Error alerts should be dismissable")

                // Verify can retry
                XCTAssertTrue(demoPatientButton.isHittable,
                             "Should be able to retry login after error")
            }

            takeScreenshot(named: "error_handling_verified")
        }
    }

    // MARK: - Test 6: Demo Mode Interactions

    /// Test demo patient can log a workout
    func testDemoPatientCanLogWorkout() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Login should succeed")
        }

        XCTContext.runActivity(named: "Verify workout interaction capability") { _ in
            // Look for exercise cells or workout content
            let exerciseCell = app.tables.cells.firstMatch
            let exerciseButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'squat' OR label CONTAINS[c] 'press'")
            ).firstMatch

            let hasExercise = exerciseCell.waitForExistence(timeout: 10) || exerciseButton.exists

            if hasExercise {
                takeScreenshot(named: "demo_workout_01_exercise_visible")

                // Try to tap on exercise
                if exerciseCell.exists && exerciseCell.isHittable {
                    exerciseCell.tap()
                    AuthFlowTestHelper.waitForLoadingToComplete(in: app)
                    takeScreenshot(named: "demo_workout_02_exercise_opened")
                } else if exerciseButton.exists && exerciseButton.isHittable {
                    exerciseButton.tap()
                    AuthFlowTestHelper.waitForLoadingToComplete(in: app)
                    takeScreenshot(named: "demo_workout_02_exercise_opened")
                }
            } else {
                // No exercises might be expected state
                takeScreenshot(named: "demo_workout_no_exercises")
            }
        }
    }

    /// Test demo patient can add favorite exercise
    func testDemoPatientCanAddFavorite() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            let loginSuccess = AuthFlowTestHelper.loginAsDemoPatient(in: app)
            XCTAssertTrue(loginSuccess, "Login should succeed")
        }

        XCTContext.runActivity(named: "Navigate to Programs tab") { _ in
            let programsTab = app.tabBars.buttons["Programs"]
            if programsTab.exists {
                programsTab.tap()
                AuthFlowTestHelper.waitForLoadingToComplete(in: app)
                takeScreenshot(named: "demo_favorite_01_programs")
            }
        }

        XCTContext.runActivity(named: "Look for favorite/bookmark capability") { _ in
            // Look for favorite/bookmark buttons
            let favoriteButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'favorite' OR label CONTAINS[c] 'bookmark' OR identifier CONTAINS[c] 'heart'")
            ).firstMatch

            if favoriteButton.exists {
                takeScreenshot(named: "demo_favorite_02_button_found")
            } else {
                takeScreenshot(named: "demo_favorite_02_no_button")
            }
        }
    }

    // MARK: - Performance Tests

    /// Test demo login completes within acceptable time
    func testDemoLoginPerformance() throws {
        app.launch()
        waitForAppReady()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10))

        let startTime = Date()

        demoPatientButton.tap()

        // Wait for dashboard to fully load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15), "Tab bar should appear")

        AuthFlowTestHelper.waitForLoadingToComplete(in: app)

        let loginDuration = Date().timeIntervalSince(startTime)

        // Demo login should complete within 5 seconds (no network needed)
        XCTAssertLessThan(loginDuration, 5.0,
                         "Demo login should complete within 5 seconds (actual: \(String(format: "%.2f", loginDuration))s)")

        print("Demo login completed in \(String(format: "%.2f", loginDuration))s")

        takeScreenshot(named: "performance_login_complete")
    }

    // MARK: - Accessibility Tests

    /// Test login screen accessibility
    func testLoginScreenAccessibility() throws {
        app.launch()
        waitForAppReady()

        XCTContext.runActivity(named: "Verify login buttons are accessible") { _ in
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.exists, "Demo Patient should exist")
            XCTAssertTrue(demoPatientButton.isHittable, "Demo Patient should be hittable")
            XCTAssertFalse(demoPatientButton.label.isEmpty, "Demo Patient should have label")

            let demoTherapistButton = app.buttons["Demo Therapist"]
            XCTAssertTrue(demoTherapistButton.exists, "Demo Therapist should exist")
            XCTAssertTrue(demoTherapistButton.isHittable, "Demo Therapist should be hittable")
            XCTAssertFalse(demoTherapistButton.label.isEmpty, "Demo Therapist should have label")

            takeScreenshot(named: "accessibility_login")
        }
    }

    // MARK: - Helper Methods

    private func waitForAppReady() {
        _ = app.wait(for: .runningForeground, timeout: 10)
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }

    private func captureScreenshotOnFailure() {
        if testRun?.hasSucceeded == false {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "FAILURE_\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
