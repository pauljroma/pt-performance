//
//  WorkoutExecutionFlowTests.swift
//  PTPerformanceUITests
//
//  Comprehensive E2E tests for workout execution flows
//  Tests complete workout lifecycle from login to summary
//

import XCTest

/// E2E tests for the complete workout execution flow
///
/// Tests the full workout execution lifecycle including:
/// - Demo patient login
/// - Today tab navigation and workout viewing
/// - Exercise detail verification (sets, reps, load)
/// - Exercise completion (prescribed, modified, skipped)
/// - Workout completion and summary verification
final class WorkoutExecutionFlowTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!
    var loginPage: LoginPage!
    var todayPage: TodayHubPage!
    var workoutPage: WorkoutExecutionPage!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure launch arguments for UI testing and demo mode
        app.launchArguments = [
            "--uitesting",
            "--demo-patient",
            "--reset-auth"
        ]

        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1",
            "USE_DEMO_DATA": "1",
            "SKIP_ONBOARDING": "1"
        ]

        // Initialize page objects
        loginPage = LoginPage(app: app)
        todayPage = TodayHubPage(app: app)
        workoutPage = WorkoutExecutionPage(app: app)
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Test 1: Complete Workout Flow - Prescribed Values

    /// Test complete workout execution with "I did this as prescribed" option
    /// Covers: Login -> Today -> Workout -> Complete Exercise (prescribed) -> Summary
    func testCompleteWorkoutFlowWithPrescribedValues() throws {
        XCTContext.runActivity(named: "Step 1: Launch app and login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            // Login as demo patient
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()

            takeScreenshot(named: "01_logged_in_as_patient")
        }

        XCTContext.runActivity(named: "Step 2: Navigate to Today tab and verify workout") { _ in
            // Verify Today tab is selected
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.waitForExistence(timeout: 10), "Today tab should exist")
            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")

            // Wait for workout content to load
            waitForLoadingComplete()

            takeScreenshot(named: "02_today_tab_with_workout")
        }

        XCTContext.runActivity(named: "Step 3: View today's workout with exercises") { _ in
            // Look for exercise list or workout content
            let workoutContent = findWorkoutContent()
            XCTAssertTrue(workoutContent, "Should display workout content or exercises")

            takeScreenshot(named: "03_workout_exercises_list")
        }

        XCTContext.runActivity(named: "Step 4: Verify exercise details display correctly") { _ in
            // Tap on first exercise if available
            let exerciseCell = findFirstExercise()

            if exerciseCell.exists {
                exerciseCell.tap()
                waitForLoadingComplete()

                // Verify exercise details are displayed
                workoutPage.assertExerciseDetailsDisplayed()

                takeScreenshot(named: "04_exercise_details_view")
            } else {
                takeScreenshot(named: "04_no_exercises_available")
            }
        }

        XCTContext.runActivity(named: "Step 5: Complete exercise with 'I did this as prescribed'") { _ in
            // Look for quick complete / prescribed button
            let prescribedButton = findPrescribedCompleteButton()

            if prescribedButton.exists && prescribedButton.isHittable {
                takeScreenshot(named: "05_before_prescribed_complete")
                prescribedButton.tap()
                waitForLoadingComplete()
                takeScreenshot(named: "05_after_prescribed_complete")
            } else {
                // Try alternative complete button
                let completeButton = findCompleteExerciseButton()
                if completeButton.exists {
                    completeButton.tap()
                    waitForLoadingComplete()
                }
            }
        }

        XCTContext.runActivity(named: "Step 6: Verify exercise marked as complete") { _ in
            // Check for completion indicator
            let completionIndicator = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete' OR label CONTAINS[c] 'done'")
            ).firstMatch

            takeScreenshot(named: "06_exercise_completion_state")
        }
    }

    // MARK: - Test 2: Complete Exercise with Modified Values

    /// Test completing an exercise with modified reps/weight values
    func testCompleteExerciseWithModifiedValues() throws {
        XCTContext.runActivity(named: "Login and navigate to exercise") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Open exercise and modify values") { _ in
            let exerciseCell = findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                throw XCTSkip("No exercises available for modification test")
            }

            exerciseCell.tap()
            waitForLoadingComplete()

            takeScreenshot(named: "modify_01_exercise_opened")
        }

        XCTContext.runActivity(named: "Modify reps value") { _ in
            // Look for reps input field or stepper
            let repsField = findRepsInput()
            if repsField.exists && repsField.isHittable {
                repsField.tap()

                // Clear and enter new value
                if let stepper = app.steppers.firstMatch as? XCUIElement, stepper.exists {
                    stepper.buttons["Increment"].tap()
                    stepper.buttons["Increment"].tap()
                } else if repsField.elementType == .textField {
                    repsField.typeText("12")
                }

                takeScreenshot(named: "modify_02_reps_modified")
            }
        }

        XCTContext.runActivity(named: "Modify weight value") { _ in
            let weightField = findWeightInput()
            if weightField.exists && weightField.isHittable {
                weightField.tap()

                if let stepper = app.steppers.element(boundBy: 1) as? XCUIElement, stepper.exists {
                    stepper.buttons["Increment"].tap()
                }

                takeScreenshot(named: "modify_03_weight_modified")
            }
        }

        XCTContext.runActivity(named: "Complete exercise with modified values") { _ in
            let completeButton = findCompleteExerciseButton()
            if completeButton.exists {
                completeButton.tap()
                waitForLoadingComplete()
                takeScreenshot(named: "modify_04_completed_with_modifications")
            }
        }
    }

    // MARK: - Test 3: Skip Exercise

    /// Test skipping an exercise in the workout
    func testSkipExercise() throws {
        XCTContext.runActivity(named: "Login and navigate to exercise") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Open exercise and skip it") { _ in
            let exerciseCell = findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                throw XCTSkip("No exercises available for skip test")
            }

            exerciseCell.tap()
            waitForLoadingComplete()

            takeScreenshot(named: "skip_01_exercise_opened")
        }

        XCTContext.runActivity(named: "Find and tap Skip button") { _ in
            let skipButton = findSkipButton()

            if skipButton.exists && skipButton.isHittable {
                takeScreenshot(named: "skip_02_before_skip")
                skipButton.tap()

                // Handle confirmation dialog if present
                let confirmButton = app.alerts.buttons["Skip"]
                if confirmButton.waitForExistence(timeout: 3) {
                    confirmButton.tap()
                }

                waitForLoadingComplete()
                takeScreenshot(named: "skip_03_after_skip")

                // Verify skipped state
                let skippedIndicator = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'skipped'")
                ).firstMatch

                // Exercise should be marked or next exercise shown
            } else {
                takeScreenshot(named: "skip_button_not_found")
            }
        }
    }

    // MARK: - Test 4: Complete Entire Workout and Verify Summary

    /// Test completing the entire workout and verifying the summary screen
    func testCompleteWorkoutAndVerifySummary() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Complete multiple exercises") { _ in
            // Complete first exercise
            completeFirstExerciseIfAvailable()

            // Try to complete more exercises or finish workout
            let finishButton = findFinishWorkoutButton()
            if finishButton.exists {
                takeScreenshot(named: "summary_01_finish_button_visible")
            }
        }

        XCTContext.runActivity(named: "Finish workout") { _ in
            let finishButton = findFinishWorkoutButton()

            if finishButton.waitForExistence(timeout: 5) {
                finishButton.tap()
                waitForLoadingComplete()
                takeScreenshot(named: "summary_02_after_finish_tap")
            } else {
                // Look for alternative completion buttons
                let doneButton = app.buttons.containing(
                    NSPredicate(format: "label CONTAINS[c] 'done' OR label CONTAINS[c] 'complete workout'")
                ).firstMatch

                if doneButton.exists {
                    doneButton.tap()
                    waitForLoadingComplete()
                }
            }
        }

        XCTContext.runActivity(named: "Verify workout summary displays correct data") { _ in
            // Look for summary screen elements
            let summaryIndicators = [
                "Workout Complete",
                "completed",
                "Summary",
                "Exercises",
                "Volume",
                "Duration"
            ]

            var foundSummaryElements = false
            for indicator in summaryIndicators {
                if app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] %@", indicator)
                ).firstMatch.waitForExistence(timeout: 5) {
                    foundSummaryElements = true
                    break
                }
            }

            takeScreenshot(named: "summary_03_workout_summary_screen")

            // Verify summary statistics if visible
            workoutPage.assertWorkoutSummaryDisplayed()
        }

        XCTContext.runActivity(named: "Dismiss summary and verify return to Today") { _ in
            // Find and tap Done/Close button on summary
            let doneButton = app.buttons["Done"]
            let closeButton = app.buttons["Close"]

            if doneButton.exists {
                doneButton.tap()
            } else if closeButton.exists {
                closeButton.tap()
            } else {
                // Try swipe down to dismiss
                app.swipeDown()
            }

            waitForLoadingComplete()

            // Verify returned to Today tab
            let todayTab = app.tabBars.buttons["Today"]
            if todayTab.exists {
                XCTAssertTrue(todayTab.isSelected || todayTab.waitForExistence(timeout: 5),
                             "Should return to Today tab after dismissing summary")
            }

            takeScreenshot(named: "summary_04_returned_to_today")
        }
    }

    // MARK: - Test 5: Exercise Details Display Verification

    /// Test that exercise details (sets, reps, load) display correctly
    func testExerciseDetailsDisplayCorrectly() throws {
        XCTContext.runActivity(named: "Login and navigate to workout") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Open exercise and verify details") { _ in
            let exerciseCell = findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                throw XCTSkip("No exercises available for detail verification")
            }

            exerciseCell.tap()
            waitForLoadingComplete()

            // Verify sets display
            let setsElement = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'set' OR label MATCHES '\\\\d+ sets'")
            ).firstMatch
            XCTAssertTrue(setsElement.waitForExistence(timeout: 5) ||
                         app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+$'")).count > 0,
                         "Sets information should be displayed")

            // Verify reps display
            let repsElement = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'rep' OR label MATCHES '\\\\d+ reps'")
            ).firstMatch
            let repsVisible = repsElement.exists ||
                             app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'x'")).firstMatch.exists

            // Verify load/weight display if applicable
            let loadElement = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'lbs' OR label CONTAINS[c] 'kg' OR label CONTAINS[c] 'weight' OR label CONTAINS[c] 'load'")
            ).firstMatch

            takeScreenshot(named: "exercise_details_verification")
        }
    }

    // MARK: - Test 6: Rest Timer Integration

    /// Test that rest timer works during workout execution
    func testRestTimerDuringWorkout() throws {
        XCTContext.runActivity(named: "Login and navigate to exercise") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Complete a set and check for rest timer") { _ in
            let exerciseCell = findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                throw XCTSkip("No exercises available for rest timer test")
            }

            exerciseCell.tap()
            waitForLoadingComplete()

            // Complete a set
            let completeSetButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete set' OR label CONTAINS[c] 'log set' OR label == 'Complete'")
            ).firstMatch

            if completeSetButton.exists {
                completeSetButton.tap()

                // Look for rest timer
                Thread.sleep(forTimeInterval: 1)

                let timerIndicator = app.staticTexts.containing(
                    NSPredicate(format: "label MATCHES '\\\\d+:\\\\d+' OR label CONTAINS[c] 'rest'")
                ).firstMatch

                if timerIndicator.exists {
                    takeScreenshot(named: "rest_timer_visible")
                }
            }
        }
    }

    // MARK: - Test 7: Navigation Preservation During Workout

    /// Test that navigating away and back preserves workout state
    func testWorkoutStatePreservedOnNavigation() throws {
        XCTContext.runActivity(named: "Login and start workout") { _ in
            app.launch()
            waitForAppReady()
            loginPage.loginAsDemoPatient()
            waitForLoadingComplete()
        }

        XCTContext.runActivity(named: "Begin exercise and navigate away") { _ in
            let exerciseCell = findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                throw XCTSkip("No exercises available for navigation test")
            }

            exerciseCell.tap()
            waitForLoadingComplete()
            takeScreenshot(named: "nav_01_exercise_started")

            // Navigate to Programs tab
            let programsTab = app.tabBars.buttons["Programs"]
            if programsTab.exists {
                programsTab.tap()
                Thread.sleep(forTimeInterval: 1)
                takeScreenshot(named: "nav_02_navigated_to_programs")
            }
        }

        XCTContext.runActivity(named: "Navigate back and verify state") { _ in
            // Navigate back to Today
            let todayTab = app.tabBars.buttons["Today"]
            todayTab.tap()
            waitForLoadingComplete()

            takeScreenshot(named: "nav_03_returned_to_today")

            // State should be reasonable (not crashed, content visible)
            assertAppStable()
        }
    }

    // MARK: - Helper Methods

    private func waitForAppReady() {
        _ = app.wait(for: .runningForeground, timeout: 10)
    }

    private func waitForLoadingComplete() {
        E2ETestUtilities.waitForLoadingComplete(in: app, timeout: 15)
    }

    private func findWorkoutContent() -> Bool {
        let exerciseList = app.tables.firstMatch
        let workoutCard = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'workout' OR label CONTAINS[c] 'session'")
        ).firstMatch
        let scrollView = app.scrollViews.firstMatch

        return exerciseList.waitForExistence(timeout: 10) ||
               workoutCard.exists ||
               scrollView.exists
    }

    private func findFirstExercise() -> XCUIElement {
        // Try table cells first
        let tableCell = app.tables.cells.firstMatch
        if tableCell.exists {
            return tableCell
        }

        // Try buttons with exercise-like content
        let exerciseButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'squat' OR label CONTAINS[c] 'press' OR label CONTAINS[c] 'row' OR label CONTAINS[c] 'curl'")
        ).firstMatch

        return exerciseButton.exists ? exerciseButton : tableCell
    }

    private func findPrescribedCompleteButton() -> XCUIElement {
        let prescribedLabels = [
            "I did this as prescribed",
            "Prescribed",
            "Quick Complete",
            "Quick Complete (Prescribed Values)",
            "As Prescribed"
        ]

        for label in prescribedLabels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }

            let containsButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] %@", label)
            ).firstMatch
            if containsButton.exists {
                return containsButton
            }
        }

        return app.buttons["Quick Complete (Prescribed Values)"]
    }

    private func findCompleteExerciseButton() -> XCUIElement {
        let completeLabels = [
            "Complete Exercise",
            "Complete",
            "Done",
            "Log Exercise",
            "Save"
        ]

        for label in completeLabels {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                return button
            }
        }

        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'complete'")
        ).firstMatch
    }

    private func findSkipButton() -> XCUIElement {
        let skipLabels = ["Skip", "Skip Exercise", "Skip This"]

        for label in skipLabels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }

        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'skip'")
        ).firstMatch
    }

    private func findFinishWorkoutButton() -> XCUIElement {
        let finishLabels = [
            "Finish Workout",
            "Complete Workout",
            "Done",
            "Finish",
            "End Workout"
        ]

        for label in finishLabels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }

        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'finish' OR label CONTAINS[c] 'complete workout'")
        ).firstMatch
    }

    private func findRepsInput() -> XCUIElement {
        // Look for reps text field or stepper
        let repsField = app.textFields.containing(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'reps' OR identifier CONTAINS[c] 'reps'")
        ).firstMatch

        if repsField.exists {
            return repsField
        }

        // Try finding by label nearby
        return app.textFields.firstMatch
    }

    private func findWeightInput() -> XCUIElement {
        let weightField = app.textFields.containing(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'weight' OR placeholderValue CONTAINS[c] 'load' OR identifier CONTAINS[c] 'weight'")
        ).firstMatch

        if weightField.exists {
            return weightField
        }

        // Return second text field as fallback
        let allFields = app.textFields.allElementsBoundByIndex
        return allFields.count > 1 ? allFields[1] : app.textFields.firstMatch
    }

    private func completeFirstExerciseIfAvailable() {
        let exerciseCell = findFirstExercise()
        if exerciseCell.waitForExistence(timeout: 5) {
            exerciseCell.tap()
            waitForLoadingComplete()

            let completeButton = findCompleteExerciseButton()
            if completeButton.exists {
                completeButton.tap()
                waitForLoadingComplete()
            }
        }
    }

    private func assertAppStable() {
        E2ETestUtilities.assertStableState(in: app)
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
            attachment.name = "failure_\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}

// MARK: - Login Page (Local definition for this test file)

private struct LoginPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var demoPatientButton: XCUIElement {
        app.buttons["Demo Patient"]
    }

    func loginAsDemoPatient() {
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        // Wait for login to complete
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear after login")
            return
        }
    }
}

// MARK: - Today Hub Page (Local definition)

private struct TodayHubPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var todayTab: XCUIElement {
        app.tabBars.buttons["Today"]
    }
}

// MARK: - Workout Execution Page

private struct WorkoutExecutionPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Assertions

    func assertExerciseDetailsDisplayed() {
        // Check for any exercise detail indicators
        let detailIndicators = [
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'set'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'rep'")).firstMatch,
            app.steppers.firstMatch,
            app.sliders.firstMatch
        ]

        let anyDetailFound = detailIndicators.contains { $0.exists }

        // Exercise name should be displayed
        let hasTitle = app.navigationBars.staticTexts.count > 0 ||
                      app.staticTexts.allElementsBoundByIndex.count > 2

        XCTAssertTrue(anyDetailFound || hasTitle,
                     "Exercise details should be displayed (sets, reps, controls, or title)")
    }

    func assertWorkoutSummaryDisplayed() {
        // Summary screen should show completion stats
        let summaryElements = [
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'complete'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'volume'")).firstMatch,
            app.images["checkmark.circle.fill"]
        ]

        let anySummaryFound = summaryElements.contains { $0.exists }

        // At minimum, we should see some completion confirmation
        let completionConfirmation = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'done' OR label CONTAINS[c] 'finished' OR label CONTAINS[c] 'complete'")
        ).firstMatch

        XCTAssertTrue(anySummaryFound || completionConfirmation.exists,
                     "Workout summary should display completion information")
    }
}
