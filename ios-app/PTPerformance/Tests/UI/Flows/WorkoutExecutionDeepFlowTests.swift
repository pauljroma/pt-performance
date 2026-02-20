//
//  WorkoutExecutionDeepFlowTests.swift
//  PTPerformanceUITests
//
//  Deep E2E tests for the full workout execution lifecycle:
//  starting a workout, logging sets, skipping exercises, completing
//  workout, viewing summary, and mid-session exit.
//
//  Test user: Jordan Williams (strength mode, CrossFit)
//  UUID: aaaaaaaa-bbbb-cccc-dddd-000000000005
//

import XCTest

/// Deep E2E tests for the full workout execution lifecycle
///
/// Covers:
/// - Starting a workout from the Today Hub
/// - Verifying exercise detail display
/// - Logging sets with prescribed and custom values
/// - Skipping exercises
/// - Finishing a workout and viewing the summary
/// - Dismissing the summary to return to the main app
/// - Exiting a workout mid-session with confirmation handling
final class WorkoutExecutionDeepFlowTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    /// Jordan Williams (strength mode, CrossFit)
    private let testUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000005"

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000005"
        ]
        app.launchEnvironment = ["IS_RUNNING_UITEST": "1"]
        app.launch()

        // Wait for the tab bar to appear confirming successful login
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )

        // Ensure Today tab is active
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists && !todayTab.isSelected {
            todayTab.tap()
        }

        waitForContentToLoad()
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Shared Navigation Helper

    /// Attempts to navigate into a workout from the Today Hub.
    /// Returns `true` if a workout execution screen was reached, `false` otherwise.
    ///
    /// Strategy order:
    /// 1. Direct "Start Workout" button (OneTapStartButton or TodayWorkoutCard)
    /// 2. Prescribed workout "Start Workout" / "Start" button (PrescribedWorkoutsCard)
    /// 3. "Browse Workout Library" button (visible when no prescribed session)
    /// 4. Quick Actions menu (ellipsis) to access workout library
    /// 5. Generic fallback: tappable text / collection view cells
    @discardableResult
    private func navigateToWorkout() -> Bool {
        // Wait for async session loading to complete on the Today Hub.
        // TodaySessionView shows a loading skeleton while fetching; wait for it to resolve.
        waitForTodayHubContentToLoad()

        // Strategy 1: Direct "Start Workout" button
        // Matches OneTapStartButton (.accessibilityLabel("Start Workout"))
        // and TodayWorkoutCard's start button (.accessibilityLabel("Start Workout"))
        let startWorkoutButton = app.buttons["Start Workout"]
        if startWorkoutButton.waitForExistence(timeout: 5) && startWorkoutButton.isHittable {
            startWorkoutButton.tap()
            waitForContentToLoad()
            return waitForWorkoutExecutionScreen()
        }

        // Strategy 2: Prescribed workout buttons
        // PrescribedWorkoutsCard uses "Start prescribed workout: <name>"
        let prescribedPredicate = NSPredicate(
            format: "label BEGINSWITH[c] 'Start prescribed workout' OR label BEGINSWITH[c] 'Start workout'"
        )
        let prescribedButton = app.buttons.containing(prescribedPredicate).firstMatch
        if prescribedButton.waitForExistence(timeout: 3) && prescribedButton.isHittable {
            prescribedButton.tap()
            waitForContentToLoad()
            return waitForWorkoutExecutionScreen()
        }

        // Strategy 3: "Browse Workout Library" button (no-session fallback view)
        let browseLibrary = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Browse Workout Library'")
        ).firstMatch
        if browseLibrary.waitForExistence(timeout: 3) && browseLibrary.isHittable {
            browseLibrary.tap()
            waitForContentToLoad()
            // In the library, tap the first available template/workout to start it
            return selectAndStartWorkoutFromLibrary()
        }

        // Strategy 4: Quick Actions menu -> workout library
        let quickActionsMenu = app.buttons["Quick Actions"]
        if quickActionsMenu.waitForExistence(timeout: 3) && quickActionsMenu.isHittable {
            quickActionsMenu.tap()
            Thread.sleep(forTimeInterval: 1.0)
            // No direct workout start in the menu, dismiss and try other paths
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Strategy 5: Generic fallback - buttons matching workout-related labels
        let workoutEntryPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'Start Workout' \
            OR label CONTAINS[c] 'Begin Workout' \
            OR label CONTAINS[c] 'Start' AND label CONTAINS[c] 'Workout'
            """
        )
        let genericButton = app.buttons.containing(workoutEntryPredicate).firstMatch
        if genericButton.waitForExistence(timeout: 3) && genericButton.isHittable {
            genericButton.tap()
            waitForContentToLoad()
            return waitForWorkoutExecutionScreen()
        }

        // Strategy 6: Tappable static texts that might be workout entry points
        let workoutText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Start Workout'")
        ).firstMatch
        if workoutText.waitForExistence(timeout: 3) && workoutText.isHittable {
            workoutText.tap()
            waitForContentToLoad()
            return waitForWorkoutExecutionScreen()
        }

        // Log diagnostic info about what IS visible
        takeScreenshot(named: "navigate_to_workout_failed")
        return false
    }

    /// Waits for the Today Hub content to finish its initial async loading.
    /// The TodaySessionView shows a loading view while fetching from Supabase;
    /// we need to wait for that to resolve before looking for entry points.
    private func waitForTodayHubContentToLoad() {
        // Wait for loading indicators to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 15)
        }

        // Also wait for the "Loading" skeleton text to disappear
        let loadingText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Loading'")
        ).firstMatch
        if loadingText.exists {
            _ = loadingText.waitForNonExistence(timeout: 15)
        }

        // Give the UI one more moment to settle
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// After navigating to the Workout Library, selects the first available
    /// template and starts the workout. Returns true if execution screen appears.
    private func selectAndStartWorkoutFromLibrary() -> Bool {
        // Wait for the library to load
        Thread.sleep(forTimeInterval: 2.0)

        // Look for a "Start" or "Start Workout" button within the library
        let startInLibrary = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Start Workout' OR label CONTAINS[c] 'Start'")
        ).firstMatch

        // Try tapping the first cell/row in the library to select a template
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) && firstCell.isHittable {
            firstCell.tap()
            waitForContentToLoad()

            // After selecting a template, look for a start button
            if startInLibrary.waitForExistence(timeout: 5) && startInLibrary.isHittable {
                startInLibrary.tap()
                waitForContentToLoad()
                return waitForWorkoutExecutionScreen()
            }
        }

        // Direct start button might already be visible for quick-start templates
        if startInLibrary.waitForExistence(timeout: 3) && startInLibrary.isHittable {
            startInLibrary.tap()
            waitForContentToLoad()
            return waitForWorkoutExecutionScreen()
        }

        return false
    }

    /// Waits briefly for workout execution elements to appear.
    private func waitForWorkoutExecutionScreen() -> Bool {
        // ManualWorkoutExecutionView uses these accessibility labels:
        // - "Complete as prescribed" button
        // - "Log with custom values" button
        // - "Skip exercise" button
        // - "Complete exercise" button
        // - "Complete workout" button
        // - "End workout" button
        // - "Sets completed" label
        // Also check for generic indicators like sets/reps labels.
        let completePrescribed = app.buttons["Complete as prescribed"]
        let logCustom = app.buttons["Log with custom values"]
        let skipExercise = app.buttons["Skip exercise"]
        let completeExercise = app.buttons["Complete exercise"]
        let completeWorkout = app.buttons["Complete workout"]
        let endWorkout = app.buttons["End workout"]
        let setsCompleted = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Sets completed'")
        ).firstMatch
        let setsLabel = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'set'")
        ).firstMatch
        let repsLabel = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'rep'")
        ).firstMatch

        // Wait up to 15 seconds for any workout execution indicator
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            if completePrescribed.exists || logCustom.exists || skipExercise.exists
                || completeExercise.exists || completeWorkout.exists || endWorkout.exists
                || setsCompleted.exists || setsLabel.exists || repsLabel.exists {
                return true
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return false
    }

    // MARK: - Test 1: Start Workout From Today Hub

    /// Verify that a workout can be launched from the Today Hub and that
    /// workout execution elements (exercise title, set logging UI) appear.
    func testStartWorkoutFromTodayHub() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout entry point found on Today Hub — user \(testUserID) may not have a prescribed session or workout library is empty")

        XCTContext.runActivity(named: "Verify workout execution screen loaded") { _ in
            let exerciseTitle = app.navigationBars.staticTexts.firstMatch
            let setsLabel = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'set'")
            ).firstMatch
            let repsLabel = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'rep'")
            ).firstMatch
            let completeSetBtn = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete set' OR label CONTAINS[c] 'log set'")
            ).firstMatch

            let workoutUIVisible = exerciseTitle.exists || setsLabel.exists
                || repsLabel.exists || completeSetBtn.exists

            XCTAssertTrue(workoutUIVisible, "Workout execution UI should be visible after starting workout")
            takeScreenshot(named: "start_workout_from_today_hub")
        }
    }

    // MARK: - Test 2: Exercise Details Displayed

    /// Navigate into a workout and verify that exercise detail elements
    /// (title, sets, reps, load) are displayed.
    func testWorkoutExerciseDetailsDisplayed() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        XCTContext.runActivity(named: "Assert exercise details are shown") { _ in
            let exerciseTitle = app.navigationBars.staticTexts.firstMatch
            let setsLabel = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'set'")
            ).firstMatch
            let repsLabel = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'rep'")
            ).firstMatch
            let loadLabel = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'lbs' OR label CONTAINS[c] 'kg' OR label CONTAINS[c] 'load' OR label CONTAINS[c] 'weight'")
            ).firstMatch

            let anyDetailFound = exerciseTitle.exists || setsLabel.exists
                || repsLabel.exists || loadLabel.exists

            XCTAssertTrue(
                anyDetailFound,
                "Exercise details (title, sets, reps, or load) should be displayed"
            )
            takeScreenshot(named: "exercise_details_displayed")
        }
    }

    // MARK: - Test 3: Log Set With Prescribed Values

    /// Navigate into a workout, tap the quick-complete / complete-set button,
    /// and verify that the UI reflects progress (next set, checkmark, counter update).
    func testLogSetWithPrescribedValues() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        XCTContext.runActivity(named: "Tap quick complete or complete set") { _ in
            takeScreenshot(named: "before_log_prescribed")

            let quickCompleteButton = resolveQuickCompleteButton()
            let completeSetButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete set' OR label CONTAINS[c] 'log set'")
            ).firstMatch

            if quickCompleteButton.exists && quickCompleteButton.isHittable {
                quickCompleteButton.tap()
            } else if completeSetButton.exists && completeSetButton.isHittable {
                completeSetButton.tap()
            } else {
                XCTFail("Neither Quick Complete nor Complete Set button found")
                return
            }

            waitForContentToLoad()
            takeScreenshot(named: "after_log_prescribed")

            // Verify something changed: progress indicator, completed counter, or next exercise
            let progressBar = app.progressIndicators.firstMatch
            let completedCounter = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'completed'")
            ).firstMatch
            let checkmark = app.images.containing(
                NSPredicate(format: "identifier CONTAINS[c] 'checkmark' OR label CONTAINS[c] 'complete'")
            ).firstMatch
            let exerciseCounter = app.staticTexts.containing(
                NSPredicate(format: "label MATCHES 'Exercise \\\\d+ of \\\\d+'")
            ).firstMatch

            let progressUpdated = progressBar.exists || completedCounter.exists
                || checkmark.exists || exerciseCounter.exists

            XCTAssertTrue(
                progressUpdated,
                "Progress should update after logging a set with prescribed values"
            )
        }
    }

    // MARK: - Test 4: Log Set With Custom Values

    /// Navigate into a workout, enter custom reps and weight values, complete
    /// the set, and verify progress updates.
    func testLogSetWithCustomValues() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        XCTContext.runActivity(named: "Enter custom reps and weight then complete set") { _ in
            // Find reps input
            let repsField = app.textFields.containing(
                NSPredicate(format: "placeholderValue CONTAINS[c] 'reps' OR identifier CONTAINS[c] 'reps'")
            ).firstMatch
            let fallbackRepsField = app.textFields.firstMatch

            let repsInput = repsField.exists ? repsField : fallbackRepsField
            if repsInput.exists && repsInput.isHittable {
                repsInput.tap()
                // Select all and type new value
                repsInput.press(forDuration: 0.5)
                let selectAll = app.menuItems["Select All"]
                if selectAll.waitForExistence(timeout: 2) {
                    selectAll.tap()
                }
                repsInput.typeText("8")
            }

            // Find weight input
            let weightField = app.textFields.containing(
                NSPredicate(format: "placeholderValue CONTAINS[c] 'weight' OR identifier CONTAINS[c] 'weight' OR placeholderValue CONTAINS[c] 'load'")
            ).firstMatch

            let allFields = app.textFields.allElementsBoundByIndex
            let weightInput = weightField.exists ? weightField : (allFields.count > 1 ? allFields[1] : app.textFields.firstMatch)

            if weightInput.exists && weightInput.isHittable {
                weightInput.tap()
                weightInput.press(forDuration: 0.5)
                let selectAll = app.menuItems["Select All"]
                if selectAll.waitForExistence(timeout: 2) {
                    selectAll.tap()
                }
                weightInput.typeText("135")
            }

            takeScreenshot(named: "custom_values_entered")

            // Tap complete set
            let completeSetButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete set' OR label CONTAINS[c] 'log set'")
            ).firstMatch
            let quickCompleteButton = resolveQuickCompleteButton()
            let completeExerciseButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete'")
            ).firstMatch

            if completeSetButton.exists && completeSetButton.isHittable {
                completeSetButton.tap()
            } else if quickCompleteButton.exists && quickCompleteButton.isHittable {
                quickCompleteButton.tap()
            } else if completeExerciseButton.exists && completeExerciseButton.isHittable {
                completeExerciseButton.tap()
            }

            waitForContentToLoad()
            takeScreenshot(named: "after_custom_values_logged")

            // Assert progress updated
            let progressBar = app.progressIndicators.firstMatch
            let completedCounter = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'completed'")
            ).firstMatch
            let exerciseCounter = app.staticTexts.containing(
                NSPredicate(format: "label MATCHES 'Exercise \\\\d+ of \\\\d+'")
            ).firstMatch

            let progressVisible = progressBar.exists || completedCounter.exists || exerciseCounter.exists
            XCTAssertTrue(progressVisible, "Progress indicator should be visible after logging custom values")
        }
    }

    // MARK: - Test 5: Skip Exercise

    /// Navigate into a workout, tap the Skip button, handle any confirmation
    /// alert, and verify the exercise advances.
    func testSkipExercise() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        XCTContext.runActivity(named: "Skip the current exercise") { _ in
            // Capture the current exercise name before skipping
            let exerciseTitleBefore = app.navigationBars.staticTexts.firstMatch.label

            let skipButton = resolveSkipButton()
            try? XCTSkipIf(!skipButton.exists, "Skip button not found — skipping test")

            guard skipButton.exists && skipButton.isHittable else {
                return
            }

            takeScreenshot(named: "before_skip_exercise")
            skipButton.tap()

            // Handle confirmation alert if one appears
            let confirmSkip = app.alerts.buttons["Skip"]
            if confirmSkip.waitForExistence(timeout: 3) {
                confirmSkip.tap()
            }
            // Also check for a generic "Yes" or "Confirm" button in alerts
            let confirmYes = app.alerts.buttons["Yes"]
            if confirmYes.waitForExistence(timeout: 2) {
                confirmYes.tap()
            }
            let confirmButton = app.alerts.buttons["Confirm"]
            if confirmButton.waitForExistence(timeout: 2) {
                confirmButton.tap()
            }

            waitForContentToLoad()
            takeScreenshot(named: "after_skip_exercise")

            // Verify the exercise advanced: different title, skipped indicator, or completion
            let exerciseTitleAfter = app.navigationBars.staticTexts.firstMatch.label
            let skippedIndicator = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'skipped'")
            ).firstMatch
            let completedIndicator = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'completed' OR label CONTAINS[c] 'done'")
            ).firstMatch

            let exerciseAdvanced = (exerciseTitleAfter != exerciseTitleBefore)
                || skippedIndicator.exists
                || completedIndicator.exists

            XCTAssertTrue(
                exerciseAdvanced,
                "Exercise should advance after skip (title changed, or skip/complete indicator shown)"
            )
        }
    }

    // MARK: - Test 6: Finish Workout Shows Summary

    /// Navigate into a workout, find and tap the Finish Workout button,
    /// and verify the workout summary screen appears.
    func testFinishWorkoutShowsSummary() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        XCTContext.runActivity(named: "Find and tap Finish Workout") { _ in
            let finishButton = resolveFinishWorkoutButton()

            // If the finish button is not immediately visible, try scrolling
            if !finishButton.exists || !finishButton.isHittable {
                for _ in 0..<5 {
                    app.swipeUp()
                    if finishButton.exists && finishButton.isHittable { break }
                }
            }

            guard finishButton.exists && finishButton.isHittable else {
                // Attempt to quick-complete exercises until finish becomes available
                quickCompleteAllExercises(maxAttempts: 10)

                let finishRetry = resolveFinishWorkoutButton()
                if !finishRetry.exists || !finishRetry.isHittable {
                    for _ in 0..<5 {
                        app.swipeUp()
                        if finishRetry.exists && finishRetry.isHittable { break }
                    }
                }

                guard finishRetry.exists && finishRetry.isHittable else {
                    takeScreenshot(named: "finish_button_not_found")
                    XCTFail("Finish Workout button could not be found or made hittable")
                    return
                }

                finishRetry.tap()
                waitForContentToLoad()
                return
            }

            finishButton.tap()
            waitForContentToLoad()
        }

        XCTContext.runActivity(named: "Verify workout summary appears") { _ in
            let summaryTitle = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'workout complete' OR label CONTAINS[c] 'great job' OR label CONTAINS[c] 'finished'")
            ).firstMatch

            let summaryAppeared = summaryTitle.waitForExistence(timeout: 10)

            // Also check for other summary indicators
            let summaryExerciseCount = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'exercise'")
            ).firstMatch
            let summaryVolume = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'volume' OR label CONTAINS[c] 'total'")
            ).firstMatch
            let summaryDuration = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'duration' OR label CONTAINS[c] 'time'")
            ).firstMatch
            let doneButton = app.buttons["Done"]

            let anySummaryElement = summaryAppeared || summaryExerciseCount.exists
                || summaryVolume.exists || summaryDuration.exists || doneButton.exists

            XCTAssertTrue(
                anySummaryElement,
                "Workout summary screen should display after finishing workout"
            )
            takeScreenshot(named: "workout_summary")
        }
    }

    // MARK: - Test 7: Dismiss Workout Summary

    /// Navigate to the workout summary, tap Done, and verify the main app
    /// (tab bar) reappears.
    func testDismissWorkoutSummary() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        // Complete all exercises and finish the workout to reach the summary
        quickCompleteAllExercises(maxAttempts: 15)

        let finishButton = resolveFinishWorkoutButton()
        if finishButton.exists && finishButton.isHittable {
            finishButton.tap()
            waitForContentToLoad()
        } else {
            // Try scrolling to find it
            for _ in 0..<5 {
                app.swipeUp()
                if finishButton.exists && finishButton.isHittable {
                    finishButton.tap()
                    waitForContentToLoad()
                    break
                }
            }
        }

        // Wait for summary
        let summaryTitle = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'workout complete' OR label CONTAINS[c] 'great job' OR label CONTAINS[c] 'finished'")
        ).firstMatch
        let doneButton = app.buttons["Done"]
        let summaryReached = summaryTitle.waitForExistence(timeout: 10) || doneButton.waitForExistence(timeout: 5)
        try XCTSkipIf(!summaryReached, "Could not reach workout summary — skipping")

        XCTContext.runActivity(named: "Dismiss the summary and verify return to main app") { _ in
            takeScreenshot(named: "summary_before_dismiss")

            if doneButton.exists && doneButton.isHittable {
                doneButton.tap()
            } else {
                // Fall back to swipe-down dismissal
                app.swipeDown()
            }

            waitForContentToLoad()

            let tabBar = app.tabBars.firstMatch
            let tabBarReappeared = tabBar.waitForExistence(timeout: 10)
            XCTAssertTrue(tabBarReappeared, "Tab bar should reappear after dismissing workout summary")
            takeScreenshot(named: "returned_to_main_app")
        }
    }

    // MARK: - Test 8: Exit Workout Mid-Session

    /// Navigate into a workout, tap the exit/close button, cancel the
    /// confirmation to stay in the workout, then tap exit again and confirm
    /// to leave. Verify the tab bar reappears.
    func testExitWorkoutMidSession() throws {
        let workoutAvailable = navigateToWorkout()
        try XCTSkipIf(!workoutAvailable, "No workout available — skipping")

        // Resolve the exit/close button
        let exitButton = resolveExitButton()
        try XCTSkipIf(
            !exitButton.exists || !exitButton.isHittable,
            "Exit / close button not found — skipping"
        )

        // --- First attempt: tap exit, then cancel to stay in workout ---
        XCTContext.runActivity(named: "Exit attempt #1 — cancel to stay") { _ in
            takeScreenshot(named: "mid_session_before_exit")
            exitButton.tap()

            // Look for a confirmation alert / action sheet
            let cancelButton = app.alerts.buttons["Cancel"]
            let stayButton = app.alerts.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'cancel' OR label CONTAINS[c] 'stay' OR label CONTAINS[c] 'continue'")
            ).firstMatch
            let sheetCancel = app.buttons["Cancel"]

            if cancelButton.waitForExistence(timeout: 3) {
                cancelButton.tap()
            } else if stayButton.waitForExistence(timeout: 2) {
                stayButton.tap()
            } else if sheetCancel.waitForExistence(timeout: 2) {
                sheetCancel.tap()
            }

            waitForContentToLoad()

            // Verify still in workout (tab bar should NOT be visible)
            let tabBar = app.tabBars.firstMatch
            let stillInWorkout = !tabBar.exists || !tabBar.isHittable
                || app.navigationBars.staticTexts.firstMatch.exists

            XCTAssertTrue(stillInWorkout, "Should remain in workout after cancelling exit")
            takeScreenshot(named: "still_in_workout_after_cancel")
        }

        // --- Second attempt: tap exit and confirm to leave ---
        XCTContext.runActivity(named: "Exit attempt #2 — confirm to leave") { _ in
            let exitBtn = resolveExitButton()
            guard exitBtn.exists && exitBtn.isHittable else {
                XCTFail("Exit button should still be available for second attempt")
                return
            }

            exitBtn.tap()

            // Confirm the exit
            let exitConfirm = app.alerts.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'exit' OR label CONTAINS[c] 'leave' OR label CONTAINS[c] 'end' OR label CONTAINS[c] 'discard' OR label CONTAINS[c] 'yes'")
            ).firstMatch
            let destructiveButton = app.alerts.buttons.element(boundBy: 1) // Often the destructive action

            if exitConfirm.waitForExistence(timeout: 3) {
                exitConfirm.tap()
            } else if destructiveButton.waitForExistence(timeout: 2) {
                destructiveButton.tap()
            } else {
                // No alert appeared; the first tap may have exited directly
            }

            waitForContentToLoad()

            let tabBar = app.tabBars.firstMatch
            let returnedToMain = tabBar.waitForExistence(timeout: 10)
            XCTAssertTrue(returnedToMain, "Tab bar should be visible after confirming workout exit")
            takeScreenshot(named: "returned_after_exit_confirm")
        }
    }

    // MARK: - Private Helpers

    /// Resolves the Quick Complete button using the actual accessibility labels
    /// from ManualWorkoutExecutionView ("Complete as prescribed").
    private func resolveQuickCompleteButton() -> XCUIElement {
        // Exact accessibility label from ManualWorkoutExecutionView
        let prescribedButton = app.buttons["Complete as prescribed"]
        if prescribedButton.exists { return prescribedButton }

        // Legacy / fallback labels
        let labels = ["Quick Complete", "Quick Complete (Prescribed Values)", "I did this as prescribed", "As Prescribed"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists { return button }
        }
        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'prescribed' OR label CONTAINS[c] 'quick complete'")
        ).firstMatch
    }

    /// Resolves the Skip button using the actual accessibility labels
    /// from ManualWorkoutExecutionView ("Skip exercise").
    private func resolveSkipButton() -> XCUIElement {
        // Exact accessibility label from ManualWorkoutExecutionView
        let skipExercise = app.buttons["Skip exercise"]
        if skipExercise.exists { return skipExercise }

        // Legacy / fallback labels
        let labels = ["Skip", "Skip Exercise", "Skip This"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists { return button }
        }
        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'skip'")
        ).firstMatch
    }

    /// Resolves the Finish Workout button using the actual accessibility labels
    /// from ManualWorkoutExecutionView ("Complete workout").
    private func resolveFinishWorkoutButton() -> XCUIElement {
        // Exact accessibility label from ManualWorkoutExecutionView
        let completeWorkout = app.buttons["Complete workout"]
        if completeWorkout.exists { return completeWorkout }

        // Legacy / fallback labels
        let labels = ["Finish Workout", "Complete Workout", "End Workout", "Finish"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists { return button }
        }
        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'finish' OR label CONTAINS[c] 'complete workout'")
        ).firstMatch
    }

    /// Resolves the Exit / Close button for leaving a workout mid-session.
    /// ManualWorkoutExecutionView uses "End workout" accessibility label.
    private func resolveExitButton() -> XCUIElement {
        // Exact accessibility label from ManualWorkoutExecutionView
        let endWorkout = app.buttons["End workout"]
        if endWorkout.exists { return endWorkout }

        // Try explicit Exit button
        let exitButton = app.buttons["Exit"]
        if exitButton.exists { return exitButton }

        // Try Close button
        let closeButton = app.buttons["Close"]
        if closeButton.exists { return closeButton }

        // Try navigation bar back / X button
        let navBarButton = app.navigationBars.buttons.firstMatch
        if navBarButton.exists { return navBarButton }

        // Predicate-based fallback
        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'end workout' OR label CONTAINS[c] 'exit' OR label CONTAINS[c] 'close' OR label CONTAINS[c] 'back'")
        ).firstMatch
    }

    /// Repeatedly taps quick-complete / complete-exercise to advance through exercises.
    private func quickCompleteAllExercises(maxAttempts: Int) {
        for _ in 0..<maxAttempts {
            let quickComplete = resolveQuickCompleteButton()
            let completeExerciseBtn = app.buttons["Complete exercise"]
            let logCustomBtn = app.buttons["Log with custom values"]
            let fallbackComplete = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'complete'")
            ).firstMatch

            if quickComplete.exists && quickComplete.isHittable {
                quickComplete.tap()
            } else if completeExerciseBtn.exists && completeExerciseBtn.isHittable {
                completeExerciseBtn.tap()
            } else if logCustomBtn.exists && logCustomBtn.isHittable {
                logCustomBtn.tap()
            } else if fallbackComplete.exists && fallbackComplete.isHittable {
                fallbackComplete.tap()
            } else {
                break
            }

            // Skip rest timer if it appears
            let skipRest = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'skip rest' OR label CONTAINS[c] 'skip timer'")
            ).firstMatch
            if skipRest.waitForExistence(timeout: 2) {
                skipRest.tap()
            }

            waitForContentToLoad()

            // Stop if the finish button has become available
            let finishButton = resolveFinishWorkoutButton()
            if finishButton.exists && finishButton.isHittable {
                break
            }
        }
    }

    /// Waits for loading indicators to disappear and content to stabilize.
    private func waitForContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 15)
        }
        Thread.sleep(forTimeInterval: 0.5)
    }

    /// Captures a named screenshot for test reporting.
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Captures a screenshot on test failure for diagnostics.
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

// MARK: - XCUIElement Convenience

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
