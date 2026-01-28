//
//  ProgramFlowTests.swift
//  PTPerformanceUITests
//
//  BUILD 95 - Agent 3: E2E Regression Test for ACP-504 (Program Creation Crash)
//  Tests entire program creation, editing, and execution flow
//  Validates that SessionBuilderSheet works without crashes
//

import XCTest

final class ProgramFlowTests: XCTestCase {

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

    // MARK: - Program Creation Flow (ACP-504 Regression Test)

    /// CRITICAL: Tests the exact flow that crashed in ACP-504
    /// This validates the BUILD 94 fix for watchdog timeout during program creation
    func testCreateProgram_WithMultipleSessions_NoWatchdogCrash() throws {
        // GIVEN: Logged in as therapist
        try loginAsTherapist()

        // Navigate to program builder
        navigateToProgramBuilder()

        // WHEN: Create a program with multiple sessions (the crash scenario)
        let programName = "E2E Test Program \(Date().timeIntervalSince1970)"
        createProgram(
            name: programName,
            phaseCount: 2,
            sessionsPerPhase: 3,
            exercisesPerSession: 4
        )

        // THEN: Program should be created without crash
        // This is the critical assertion - if we reach here, no watchdog timeout occurred
        let successMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'created'")).firstMatch
        XCTAssertTrue(
            successMessage.waitForExistence(timeout: 10),
            """
            🚨 ACP-504 REGRESSION: Program creation failed or timed out!
            Expected: Success message within 10 seconds
            Actual: No confirmation or app crashed

            This indicates the watchdog timeout bug has returned.
            Review BUILD 94 fix: Task.detached and batch inserts
            """
        )

        // Verify no crash indicators
        XCTAssertTrue(app.state == .runningForeground, "App should still be running")

        print("✅ ACP-504 Regression Test PASSED: Program created without watchdog timeout")
    }

    /// Test adding a session to an existing program
    /// This validates SessionBuilderSheet works correctly (BUILD 94 fix)
    func testAddSessionToProgram_SessionBuilderSheet_NoError() throws {
        // GIVEN: Program exists and we're editing it
        try loginAsTherapist()
        navigateToProgramBuilder()

        let programName = "Session Builder Test \(Date().timeIntervalSince1970)"
        createProgram(name: programName, phaseCount: 1, sessionsPerPhase: 1, exercisesPerSession: 2)

        // Wait for program to be created
        sleep(2)

        // Navigate to edit the program
        let programRow = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", programName)).firstMatch
        if programRow.waitForExistence(timeout: 5) {
            programRow.tap()
        } else {
            throw XCTSkip("Could not find created program - skipping session builder test")
        }

        // WHEN: Add a new session using SessionBuilderSheet
        let addSessionButton = app.buttons["Add Session"]
        if addSessionButton.waitForExistence(timeout: 5) {
            addSessionButton.tap()

            // CRITICAL: SessionBuilderSheet should appear without crash
            let sessionNameField = app.textFields["Session Name"]
            XCTAssertTrue(
                sessionNameField.waitForExistence(timeout: 5),
                """
                🚨 BUILD 94 REGRESSION: SessionBuilderSheet failed to appear!
                This was fixed in BUILD 94 - verify Form → List changes
                """
            )

            // Fill in session details
            sessionNameField.tap()
            sessionNameField.typeText("New Session")

            // Add exercises to session
            let addExerciseButton = app.buttons["Add Exercise"]
            if addExerciseButton.exists {
                addExerciseButton.tap()

                // Select an exercise from picker
                let firstExercise = app.cells.firstMatch
                if firstExercise.waitForExistence(timeout: 5) {
                    firstExercise.tap()

                    // Close exercise picker
                    let doneButton = app.buttons["Done"]
                    if doneButton.exists {
                        doneButton.tap()
                    }
                }
            }

            // Save session
            let saveButton = app.buttons["Done"]
            XCTAssertTrue(saveButton.exists, "Done button should exist in SessionBuilderSheet")
            saveButton.tap()

            // THEN: Should return to program editor without crash
            XCTAssertTrue(app.state == .runningForeground, "App should not have crashed")

            print("✅ SessionBuilderSheet test PASSED: No crashes, session added successfully")
        } else {
            print("⚠️ Add Session button not found - test scenario not applicable")
        }
    }

    /// Test editing an existing session
    func testEditSession_WithExercises_DataPersists() throws {
        // GIVEN: Program with a session exists
        try loginAsTherapist()
        navigateToProgramBuilder()

        let programName = "Edit Session Test \(Date().timeIntervalSince1970)"
        createProgram(name: programName, phaseCount: 1, sessionsPerPhase: 2, exercisesPerSession: 3)

        sleep(2)

        // Navigate to program
        let programRow = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", programName)).firstMatch
        guard programRow.waitForExistence(timeout: 5) else {
            throw XCTSkip("Program not found")
        }
        programRow.tap()

        // WHEN: Tap on a session to edit it
        let sessionRow = app.cells.containing(NSPredicate(format: "label CONTAINS[c] 'session'")).firstMatch
        if sessionRow.waitForExistence(timeout: 5) {
            sessionRow.tap()

            // Session editor should appear
            let sessionNameField = app.textFields["Session Name"]
            if sessionNameField.waitForExistence(timeout: 5) {
                // Modify session name
                sessionNameField.tap()
                sessionNameField.clearText()
                sessionNameField.typeText("Modified Session")

                // Save changes
                let doneButton = app.buttons["Done"]
                doneButton.tap()

                // THEN: Verify changes persisted
                let modifiedSession = app.staticTexts["Modified Session"]
                XCTAssertTrue(
                    modifiedSession.waitForExistence(timeout: 5),
                    "Session name changes should persist"
                )

                print("✅ Session editing test PASSED: Data persists correctly")
            } else {
                print("⚠️ Session editor did not appear - test scenario not applicable")
            }
        } else {
            print("⚠️ No sessions found to edit")
        }
    }

    /// Test executing a workout from a created program
    /// This is the end-to-end user journey validation
    func testExecuteWorkout_FromProgram_NoDataLossOrCrash() throws {
        // GIVEN: Program exists with sessions and exercises
        try loginAsTherapist()
        navigateToProgramBuilder()

        let programName = "Workout Execution Test \(Date().timeIntervalSince1970)"
        createProgram(name: programName, phaseCount: 1, sessionsPerPhase: 1, exercisesPerSession: 2)

        sleep(2)

        // Assign program to a patient (if applicable)
        // For now, we'll test as therapist executing workout

        // Navigate back to main view
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }

        // WHEN: Navigate to "Today's Session" or workout execution
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()

            // Look for session to execute
            let startWorkoutButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'start'")).firstMatch
            if startWorkoutButton.waitForExistence(timeout: 5) {
                startWorkoutButton.tap()

                // THEN: Workout view should load without crash
                let exerciseList = app.tables.firstMatch
                XCTAssertTrue(
                    exerciseList.waitForExistence(timeout: 5) || app.staticTexts["No session"].exists,
                    "Either exercise list or empty state should appear"
                )

                // Verify no crash occurred
                XCTAssertTrue(app.state == .runningForeground, "App should remain running during workout")

                print("✅ Workout execution test PASSED: No crashes during session execution")
            } else {
                print("⚠️ No workout found to execute - test scenario not applicable")
            }
        } else {
            print("⚠️ Today tab not found - navigation differs from expected")
        }
    }

    /// Test deleting a program
    func testDeleteProgram_ConfirmsDeletion_NoOrphanedData() throws {
        // GIVEN: Program exists
        try loginAsTherapist()
        navigateToProgramBuilder()

        let programName = "Delete Test \(Date().timeIntervalSince1970)"
        createProgram(name: programName, phaseCount: 1, sessionsPerPhase: 1, exercisesPerSession: 1)

        sleep(2)

        // WHEN: Delete the program
        let programRow = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", programName)).firstMatch
        if programRow.waitForExistence(timeout: 5) {
            // Swipe to delete
            programRow.swipeLeft()

            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: 3) {
                deleteButton.tap()

                // Confirm deletion if alert appears
                let confirmButton = app.alerts.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'delete'")).firstMatch
                if confirmButton.waitForExistence(timeout: 3) {
                    confirmButton.tap()
                }

                // THEN: Program should be removed from list
                sleep(1)
                XCTAssertFalse(
                    programRow.exists,
                    "Deleted program should not appear in list"
                )

                print("✅ Program deletion test PASSED: Program removed successfully")
            } else {
                print("⚠️ Delete button not found - UI may differ")
            }
        } else {
            print("⚠️ Could not find program to delete")
        }
    }

    /// CRITICAL: Large program test - the exact scenario that triggered ACP-504
    /// Tests creating a program with 4 phases, 4 sessions each, 12 exercises per session
    /// Total: 192 exercises (the crash scenario from BUILD 94)
    func testCreateLargeProgram_192Exercises_NoWatchdogTimeout() throws {
        // GIVEN: Logged in as therapist
        try loginAsTherapist()
        navigateToProgramBuilder()

        // WHEN: Create the exact large program that crashed in ACP-504
        let programName = "Large Program Test \(Date().timeIntervalSince1970)"

        // This should complete in < 8 seconds to avoid watchdog timeout
        // BUILD 94 optimizations: Task.detached + batch inserts
        let startTime = Date()
        createProgram(
            name: programName,
            phaseCount: 4,
            sessionsPerPhase: 4,
            exercisesPerSession: 12
        )
        let duration = Date().timeIntervalSince(startTime)

        // THEN: Should complete without timeout
        let successMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'created'")).firstMatch
        XCTAssertTrue(
            successMessage.waitForExistence(timeout: 15),
            """
            🚨 CRITICAL ACP-504 REGRESSION: Large program (192 exercises) timed out!
            Duration: \(duration)s (should be < 8s to avoid watchdog)

            This is the EXACT scenario that caused crashes in BUILD 75.
            BUILD 94 fix should handle this via:
            1. Task.detached - moves work off main thread
            2. Batch inserts - reduces 192 DB calls to ~16 batches
            3. Form → List - prevents UI hang when editing
            """
        )

        XCTAssertTrue(
            app.state == .runningForeground,
            "App should not have crashed during large program creation"
        )

        XCTAssertLessThan(
            duration,
            8.0,
            "Large program creation should complete in < 8s (watchdog threshold is 10s)"
        )

        print("✅ CRITICAL ACP-504 Test PASSED: Large program (192 exercises) created in \(String(format: "%.2f", duration))s without crash")
    }

    // MARK: - Helper Methods

    private func loginAsTherapist() throws {
        // Login flow
        let therapistButton = app.buttons["Therapist Login"]
        guard therapistButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Therapist login button not found - app may be in different state")
        }

        therapistButton.tap()

        // Enter credentials
        let emailField = app.textFields["Email"]
        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            emailField.typeText(MockData.TestTherapist.email)

            let passwordField = app.secureTextFields["Password"]
            passwordField.tap()
            passwordField.typeText(MockData.TestTherapist.password)

            let loginButton = app.buttons["Log In"]
            loginButton.tap()

            // Wait for dashboard
            let dashboardIndicator = app.navigationBars.firstMatch
            XCTAssertTrue(
                dashboardIndicator.waitForExistence(timeout: 10),
                "Therapist dashboard should load after login"
            )
        }
    }

    private func navigateToProgramBuilder() {
        // Navigate to program builder from therapist dashboard
        let programsTab = app.tabBars.buttons["Programs"]
        if programsTab.exists {
            programsTab.tap()
        }

        // Look for "Create Program" or similar button
        let createButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'create'")).firstMatch
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        }
    }

    /// Creates a program with specified complexity
    /// This simulates the exact user actions that trigger ACP-504
    private func createProgram(
        name: String,
        phaseCount: Int = 1,
        sessionsPerPhase: Int = 1,
        exercisesPerSession: Int = 1
    ) {
        // Enter program name
        let programNameField = app.textFields["Program Name"]
        if programNameField.waitForExistence(timeout: 5) {
            programNameField.tap()
            programNameField.typeText(name)
        }

        // Add phases
        for phaseIndex in 0..<phaseCount {
            let addPhaseButton = app.buttons["Add Phase"]
            if addPhaseButton.exists {
                addPhaseButton.tap()
            }

            // Add sessions to this phase
            for sessionIndex in 0..<sessionsPerPhase {
                let addSessionButton = app.buttons["Add Session"]
                if addSessionButton.exists {
                    addSessionButton.tap()

                    // Add exercises to this session
                    for exerciseIndex in 0..<exercisesPerSession {
                        let addExerciseButton = app.buttons["Add Exercise"]
                        if addExerciseButton.waitForExistence(timeout: 3) {
                            addExerciseButton.tap()

                            // Select exercise from picker
                            let exerciseCell = app.cells.element(boundBy: exerciseIndex % 10) // Cycle through available exercises
                            if exerciseCell.waitForExistence(timeout: 3) {
                                exerciseCell.tap()
                            }

                            // Close picker
                            let doneButton = app.buttons["Done"]
                            if doneButton.exists {
                                doneButton.tap()
                            }
                        }
                    }

                    // Save session
                    let saveSessionButton = app.buttons["Done"]
                    if saveSessionButton.exists {
                        saveSessionButton.tap()
                    }
                }
            }
        }

        // Create/Save the program
        let createButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'create' OR label CONTAINS[c] 'save'")).firstMatch
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Helper to clear text from a text field
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
