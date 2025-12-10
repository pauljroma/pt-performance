//
//  PatientFlowUITests.swift
//  PTPerformanceUITests
//
//  UI tests for patient login and data loading flow
//  Tests the exact flow that is FAILING in Build 8
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

    // MARK: - Patient Login Flow

    func testPatientLoginFlow() throws {
        // Step 1: Launch app
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        // Step 2: Find and tap patient login button
        let patientButton = app.buttons["Patient Login"]
        XCTAssertTrue(patientButton.waitForExistence(timeout: 5),
            "Patient login button should be visible")

        patientButton.tap()

        // Step 3: Enter demo credentials
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5),
            "Email field should appear")

        emailField.tap()
        emailField.typeText("demo-athlete@ptperformance.app")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists, "Password field should exist")

        passwordField.tap()
        passwordField.typeText("demo-patient-2025")

        // Step 4: Tap login
        let loginButton = app.buttons["Log In"]
        XCTAssertTrue(loginButton.exists, "Login button should exist")

        loginButton.tap()

        // Step 5: Wait for patient dashboard
        let dashboardTitle = app.staticTexts["Today's Session"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 10),
            """
            🚨 CRITICAL: Patient dashboard did not appear after login!
            This is the Build 8 bug: login works but dashboard fails to load
            """)
    }

    // MARK: - Patient Data Loading Flow (CRITICAL - This is FAILING in Build 8)

    func testPatientSessionDataLoads() throws {
        // Login first
        try testPatientLoginFlow()

        // CRITICAL TEST: Verify session data loads
        // Build 8 fails here with "data could not be read because it doesn't exist"

        // Wait for loading to complete
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let disappeared = loadingIndicator.waitForNonExistence(timeout: 15)
            XCTAssertTrue(disappeared,
                "Loading should complete within 15 seconds")
        }

        // Check for error message (this is what Build 8 shows)
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'could not be read'")).firstMatch
        XCTAssertFalse(errorMessage.exists,
            """
            🚨 BUILD 8 BUG DETECTED: Error message shown
            Message: \(errorMessage.label)

            This is the exact failure reported by user!
            """)

        // Verify exercise list appears
        let exerciseList = app.tables.firstMatch
        let exerciseListExists = exerciseList.waitForExistence(timeout: 5)

        if !exerciseListExists {
            // Check if there's an empty state message
            let emptyState = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no session'")).firstMatch

            XCTAssertTrue(emptyState.exists || exerciseListExists,
                """
                🚨 CRITICAL: No exercise list AND no empty state message
                Expected: Either exercises loaded OR "no session" message
                Actual: Blank screen (Build 8 bug)
                """)
        }

        print("✅ Patient session data loading test passed")
    }

    // MARK: - Patient Exercise Detail Flow

    func testPatientExerciseDetailFlow() throws {
        // Login and load session data first
        try testPatientSessionDataLoads()

        // Find first exercise in list
        let firstExercise = app.tables.cells.firstMatch
        if firstExercise.waitForExistence(timeout: 5) {
            firstExercise.tap()

            // Verify exercise detail appears (on iPad, it's in right panel)
            let exerciseName = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'sets'")).firstMatch
            XCTAssertTrue(exerciseName.waitForExistence(timeout: 5),
                "Exercise detail should appear after tapping exercise")

            // Verify "Log This Exercise" button exists
            let logButton = app.buttons["Log This Exercise"]
            XCTAssertTrue(logButton.waitForExistence(timeout: 3),
                "Log exercise button should be visible in detail view")

            print("✅ Exercise detail flow passed")
        } else {
            print("⚠️ No exercises available to test detail flow")
        }
    }

    // MARK: - Patient Exercise Logging Flow

    func testPatientExerciseLoggingFlow() throws {
        // Load exercise detail first
        try testPatientExerciseDetailFlow()

        // Tap "Log This Exercise" button
        let logButton = app.buttons["Log This Exercise"]
        if logButton.exists {
            logButton.tap()

            // Verify exercise logging form appears
            let setsField = app.textFields["Sets"]
            XCTAssertTrue(setsField.waitForExistence(timeout: 5),
                "Exercise logging form should appear")

            let repsField = app.textFields["Reps"]
            XCTAssertTrue(repsField.exists, "Reps field should exist")

            let loadField = app.textFields["Load"]
            XCTAssertTrue(loadField.exists, "Load field should exist")

            print("✅ Exercise logging form is accessible")

            // Fill out form
            setsField.tap()
            setsField.typeText("3")

            repsField.tap()
            repsField.typeText("10")

            loadField.tap()
            loadField.typeText("135")

            // Find and tap submit button
            let submitButton = app.buttons["Save"]
            if submitButton.exists {
                submitButton.tap()

                // Verify form closes and we return to exercise list
                let exerciseList = app.tables.firstMatch
                XCTAssertTrue(exerciseList.waitForExistence(timeout: 5),
                    "Should return to exercise list after saving")

                print("✅ Exercise logging and save flow passed")
            }
        } else {
            print("⚠️ Log button not available - skipping logging flow test")
        }
    }

    // MARK: - Error Handling Tests

    func testPatientLoginWithInvalidCredentials() throws {
        // Test that invalid credentials show proper error

        let patientButton = app.buttons["Patient Login"]
        patientButton.tap()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("invalid@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")

        let loginButton = app.buttons["Log In"]
        loginButton.tap()

        // Should show error message
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5),
            "Should show error alert for invalid credentials")

        print("✅ Invalid login error handling passed")
    }

    // MARK: - iPad Layout Tests

    func testPatientIPadSplitView() throws {
        // Only run on iPad
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad-specific test, skipping on iPhone")
        }

        // Login and load data
        try testPatientSessionDataLoads()

        // Verify split view layout on iPad
        let exerciseList = app.tables.firstMatch
        XCTAssertTrue(exerciseList.exists, "Exercise list should be in left sidebar")

        // Tap first exercise
        if exerciseList.cells.firstMatch.exists {
            exerciseList.cells.firstMatch.tap()

            // Both list and detail should be visible simultaneously on iPad
            XCTAssertTrue(exerciseList.isHittable,
                "Exercise list should remain visible on iPad (split view)")

            print("✅ iPad split view layout test passed")
        }
    }
}
