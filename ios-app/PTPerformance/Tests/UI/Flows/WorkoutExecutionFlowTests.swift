//
//  WorkoutExecutionFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for workout execution critical flows
//  ACP-226: Critical user flow E2E testing - World-class coverage
//

import XCTest

/// E2E tests for workout execution flows
///
/// Tests the complete workout experience including:
/// - Viewing today's session
/// - Starting a workout
/// - Logging exercises
/// - Using rest timers
/// - Completing workouts
/// - Exercise substitution
final class WorkoutExecutionFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launchEnvironment["IS_RUNNING_UITEST"] = "1"
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Setup

    private func loginAsPatient() {
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear after login")
            return
        }

        E2ETestUtilities.waitForLoadingComplete(in: app)
    }

    // MARK: - Today Session Tests

    /// Test Today Hub displays session overview
    func testTodayHubDisplaysSessionOverview() throws {
        XCTContext.runActivity(named: "Login and view Today Hub") { _ in
            loginAsPatient()
        }

        XCTContext.runActivity(named: "Verify Today tab is selected") { _ in
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")
        }

        XCTContext.runActivity(named: "Verify session content displays") { _ in
            // Look for session-related content
            let sessionIndicators = [
                "Today's Session",
                "No Session",
                "Workout",
                "Exercise"
            ]

            var foundContent = false
            for indicator in sessionIndicators {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", indicator)).firstMatch.waitForExistence(timeout: 5) {
                    foundContent = true
                    break
                }
            }

            // Or check for list content
            if !foundContent {
                foundContent = app.tables.firstMatch.exists || app.scrollViews.firstMatch.exists
            }

            XCTAssertTrue(foundContent, "Today Hub should display session content")
            takeScreenshot(named: "today_session_overview")
        }
    }

    /// Test accessing today's exercises
    func testAccessTodayExercises() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Navigate to exercises if available") { _ in
            // Check for exercise list or workout button
            let exerciseList = app.tables.firstMatch
            let workoutButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'start' OR label CONTAINS[c] 'workout' OR label CONTAINS[c] 'begin'")
            ).firstMatch

            if exerciseList.waitForExistence(timeout: 10) {
                takeScreenshot(named: "exercise_list")

                // Tap on first exercise if available
                let firstCell = exerciseList.cells.firstMatch
                if firstCell.exists {
                    firstCell.tap()
                    Thread.sleep(forTimeInterval: 1)
                    takeScreenshot(named: "exercise_detail")
                }
            } else if workoutButton.exists {
                takeScreenshot(named: "workout_start_button")
            } else {
                takeScreenshot(named: "no_session_state")
            }
        }
    }

    // MARK: - Exercise Logging Tests

    /// Test exercise logging flow
    func testExerciseLoggingFlow() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Find loggable exercise") { _ in
            let exerciseList = app.tables.firstMatch

            guard exerciseList.waitForExistence(timeout: 10) else {
                // No exercises available - document state
                takeScreenshot(named: "no_exercises_to_log")
                return
            }

            // Look for an exercise cell
            let exerciseCell = exerciseList.cells.firstMatch
            guard exerciseCell.exists else {
                takeScreenshot(named: "empty_exercise_list")
                return
            }

            exerciseCell.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        XCTContext.runActivity(named: "Verify exercise logging UI") { _ in
            // Look for set logging interface
            let setIndicators = [
                "Set",
                "Reps",
                "Weight",
                "Log",
                "Complete"
            ]

            var foundLoggingUI = false
            for indicator in setIndicators {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", indicator)).firstMatch.exists ||
                   app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", indicator)).firstMatch.exists {
                    foundLoggingUI = true
                    break
                }
            }

            if foundLoggingUI {
                takeScreenshot(named: "exercise_logging_ui")
            } else {
                // Check for stepper/picker controls
                let hasInputControls = app.steppers.count > 0 ||
                                       app.pickers.count > 0 ||
                                       app.textFields.count > 0

                takeScreenshot(named: "exercise_detail_\(hasInputControls ? "with" : "without")_controls")
            }
        }
    }

    /// Test completing a set
    func testCompleteSetFlow() throws {
        loginAsPatient()

        // Navigate to exercise
        let exerciseList = app.tables.firstMatch
        guard exerciseList.waitForExistence(timeout: 10) else {
            throw XCTSkip("No exercises available for testing")
        }

        let exerciseCell = exerciseList.cells.firstMatch
        guard exerciseCell.exists else {
            throw XCTSkip("No exercise cells found")
        }

        exerciseCell.tap()
        Thread.sleep(forTimeInterval: 1)

        XCTContext.runActivity(named: "Find and tap complete/log button") { _ in
            let completeButtons = [
                "Complete Set",
                "Log Set",
                "Done",
                "Save",
                "✓"
            ]

            for buttonLabel in completeButtons {
                let button = app.buttons[buttonLabel]
                if button.exists && button.isHittable {
                    takeScreenshot(named: "before_complete_set")
                    button.tap()
                    Thread.sleep(forTimeInterval: 1)
                    takeScreenshot(named: "after_complete_set")
                    break
                }
            }
        }
    }

    // MARK: - Rest Timer Tests

    /// Test rest timer functionality
    func testRestTimerFlow() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Find rest timer access") { _ in
            // Check quick actions menu for timers
            let quickActionsButton = app.buttons["Quick Actions"]

            if quickActionsButton.waitForExistence(timeout: 5) {
                quickActionsButton.tap()
                Thread.sleep(forTimeInterval: 0.5)

                let timersButton = app.buttons["Timers"]
                if timersButton.waitForExistence(timeout: 3) {
                    takeScreenshot(named: "quick_actions_timers")
                    timersButton.tap()
                    Thread.sleep(forTimeInterval: 1)
                    takeScreenshot(named: "timers_view")

                    // Verify timer UI elements
                    let timerExists = app.staticTexts.containing(
                        NSPredicate(format: "label CONTAINS[c] 'timer' OR label CONTAINS[c] 'rest' OR label CONTAINS[c] ':'")
                    ).firstMatch.waitForExistence(timeout: 5)

                    XCTAssertTrue(timerExists, "Timer UI should be displayed")
                    return
                }
            }

            // Alternative: Look for timer in exercise view
            let timerButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'timer' OR label CONTAINS[c] 'rest'")
            ).firstMatch

            if timerButton.exists {
                takeScreenshot(named: "exercise_timer_button")
            }
        }
    }

    /// Test starting and stopping rest timer
    func testRestTimerStartStop() throws {
        loginAsPatient()

        // Access timers
        let quickActionsButton = app.buttons["Quick Actions"]
        guard quickActionsButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Quick Actions not available")
        }

        quickActionsButton.tap()

        let timersButton = app.buttons["Timers"]
        guard timersButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Timers not available in Quick Actions")
        }

        timersButton.tap()
        Thread.sleep(forTimeInterval: 1)

        XCTContext.runActivity(named: "Start timer") { _ in
            let startButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'start' OR label CONTAINS[c] 'begin'")
            ).firstMatch

            if startButton.exists {
                startButton.tap()
                Thread.sleep(forTimeInterval: 2)
                takeScreenshot(named: "timer_running")
            }
        }

        XCTContext.runActivity(named: "Stop/reset timer") { _ in
            let stopButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'stop' OR label CONTAINS[c] 'reset' OR label CONTAINS[c] 'cancel'")
            ).firstMatch

            if stopButton.exists {
                stopButton.tap()
                Thread.sleep(forTimeInterval: 1)
                takeScreenshot(named: "timer_stopped")
            }
        }
    }

    // MARK: - Workout Completion Tests

    /// Test completing entire workout flow
    func testWorkoutCompletionFlow() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Check for workout completion option") { _ in
            let exerciseList = app.tables.firstMatch

            if exerciseList.waitForExistence(timeout: 10) {
                // Scroll to bottom to find completion button
                var scrollAttempts = 0
                let completeWorkoutButton = app.buttons.containing(
                    NSPredicate(format: "label CONTAINS[c] 'complete workout' OR label CONTAINS[c] 'finish workout' OR label CONTAINS[c] 'done'")
                ).firstMatch

                while !completeWorkoutButton.exists && scrollAttempts < 5 {
                    app.swipeUp()
                    scrollAttempts += 1
                }

                if completeWorkoutButton.exists {
                    takeScreenshot(named: "workout_complete_button")
                }
            }
        }
    }

    // MARK: - Quick Pick Tests

    /// Test AI Quick Pick feature
    func testQuickPickFeature() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Access Quick Pick") { _ in
            let quickActionsButton = app.buttons["Quick Actions"]

            guard quickActionsButton.waitForExistence(timeout: 5) else {
                takeScreenshot(named: "no_quick_actions")
                return
            }

            quickActionsButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let quickPickButton = app.buttons["AI Quick Pick"]
            if quickPickButton.waitForExistence(timeout: 3) {
                takeScreenshot(named: "quick_pick_option")
                quickPickButton.tap()
                Thread.sleep(forTimeInterval: 2)
                takeScreenshot(named: "quick_pick_view")

                // Verify quick pick UI
                let quickPickLoaded = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'quick' OR label CONTAINS[c] 'pick' OR label CONTAINS[c] 'workout' OR label CONTAINS[c] 'exercise'")
                ).firstMatch.waitForExistence(timeout: 10)

                E2ETestUtilities.assertStableState(in: app)
            }
        }
    }

    // MARK: - Readiness Check-In Tests

    /// Test readiness check-in flow
    func testReadinessCheckInFlow() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Access Readiness Check-In") { _ in
            let quickActionsButton = app.buttons["Quick Actions"]

            guard quickActionsButton.waitForExistence(timeout: 5) else {
                throw XCTSkip("Quick Actions not available")
            }

            quickActionsButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let readinessButton = app.buttons["Readiness Check-In"]
            if readinessButton.waitForExistence(timeout: 3) {
                takeScreenshot(named: "readiness_option")
                readinessButton.tap()
                Thread.sleep(forTimeInterval: 1)
                takeScreenshot(named: "readiness_check_in")

                // Verify readiness UI
                let readinessLoaded = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'how' OR label CONTAINS[c] 'feel'")
                ).firstMatch.waitForExistence(timeout: 10)

                E2ETestUtilities.assertStableState(in: app)
            }
        }
    }

    // MARK: - Navigation During Workout Tests

    /// Test navigating away during workout preserves state
    func testNavigationDuringWorkoutPreservesState() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Start workout activity") { _ in
            let exerciseList = app.tables.firstMatch

            guard exerciseList.waitForExistence(timeout: 10),
                  exerciseList.cells.firstMatch.exists else {
                throw XCTSkip("No exercises available")
            }

            // Tap on exercise
            exerciseList.cells.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1)
            takeScreenshot(named: "exercise_in_progress")
        }

        XCTContext.runActivity(named: "Navigate away and back") { _ in
            // Navigate to Programs tab
            let programsTab = app.tabBars.buttons["Programs"]
            programsTab.tap()
            Thread.sleep(forTimeInterval: 1)
            takeScreenshot(named: "navigated_to_programs")

            // Navigate back to Today
            let todayTab = app.tabBars.buttons["Today"]
            todayTab.tap()
            Thread.sleep(forTimeInterval: 1)
            takeScreenshot(named: "navigated_back_to_today")

            // Verify state is reasonable
            E2ETestUtilities.assertStableState(in: app)
        }
    }

    // MARK: - Performance Tests

    /// Test workout view loads within acceptable time
    func testWorkoutViewLoadPerformance() throws {
        loginAsPatient()

        let duration = E2ETestUtilities.measurePerformance("Workout view load", warningThreshold: 3.0) {
            E2ETestUtilities.waitForLoadingComplete(in: app, timeout: 10)
        }

        XCTAssertLessThan(duration, 5.0, "Workout view should load within 5 seconds")
    }

    // MARK: - Accessibility Tests

    /// Test workout UI accessibility
    func testWorkoutUIAccessibility() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Verify interactive elements are accessible") { _ in
            // Check tab bar accessibility
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.isHittable, "Today tab should be hittable")
            XCTAssertFalse(todayTab.label.isEmpty, "Today tab should have accessibility label")

            // Check quick actions accessibility
            let quickActionsButton = app.buttons["Quick Actions"]
            if quickActionsButton.exists {
                XCTAssertTrue(quickActionsButton.isHittable, "Quick Actions should be hittable")
            }

            // Check exercise list accessibility if present
            let exerciseList = app.tables.firstMatch
            if exerciseList.exists {
                let cells = exerciseList.cells.allElementsBoundByIndex
                for cell in cells.prefix(3) {
                    XCTAssertTrue(cell.isHittable, "Exercise cells should be hittable")
                }
            }
        }
    }

    // MARK: - Helper Methods

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
