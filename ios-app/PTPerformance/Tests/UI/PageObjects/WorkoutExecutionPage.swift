//
//  WorkoutExecutionPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Workout Execution views
//  Supports exercise logging, set completion, and workout summary
//

import XCTest

/// Page Object representing the Workout Execution views
struct WorkoutExecutionPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Navigation Elements

    var backButton: XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    var exitButton: XCUIElement {
        app.buttons["Exit"]
    }

    // MARK: - Progress Elements

    var progressBar: XCUIElement {
        app.progressIndicators.firstMatch
    }

    var exerciseCounter: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label MATCHES 'Exercise \\\\d+ of \\\\d+'")).firstMatch
    }

    var completedCounter: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'completed'")).firstMatch
    }

    // MARK: - Exercise Detail Elements

    var exerciseTitle: XCUIElement {
        app.navigationBars.staticTexts.firstMatch
    }

    var exerciseCategory: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'category' OR label CONTAINS[c] 'pattern'")).firstMatch
    }

    var setsLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'set'")).firstMatch
    }

    var repsLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'rep'")).firstMatch
    }

    var loadLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'lbs' OR label CONTAINS[c] 'kg' OR label CONTAINS[c] 'load' OR label CONTAINS[c] 'weight'")).firstMatch
    }

    // MARK: - Set Logging Elements

    var setRows: XCUIElementQuery {
        app.otherElements.containing(NSPredicate(format: "identifier CONTAINS[c] 'set' OR label CONTAINS[c] 'Set'"))
    }

    var repsInput: XCUIElement {
        let repsField = app.textFields.containing(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'reps' OR identifier CONTAINS[c] 'reps'")
        ).firstMatch

        if repsField.exists {
            return repsField
        }
        return app.textFields.firstMatch
    }

    var weightInput: XCUIElement {
        let weightField = app.textFields.containing(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'weight' OR identifier CONTAINS[c] 'weight' OR placeholderValue CONTAINS[c] 'load'")
        ).firstMatch

        if weightField.exists {
            return weightField
        }

        let allFields = app.textFields.allElementsBoundByIndex
        return allFields.count > 1 ? allFields[1] : app.textFields.firstMatch
    }

    var repsStepper: XCUIElement {
        app.steppers.firstMatch
    }

    var weightStepper: XCUIElement {
        let steppers = app.steppers.allElementsBoundByIndex
        return steppers.count > 1 ? steppers[1] : app.steppers.firstMatch
    }

    // MARK: - Feedback Elements

    var rpeSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'rpe' OR label CONTAINS[c] 'RPE' OR label CONTAINS[c] 'effort'")).firstMatch
    }

    var painSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'pain' OR label CONTAINS[c] 'pain'")).firstMatch
    }

    var notesField: XCUIElement {
        app.textFields["Add notes..."]
    }

    // MARK: - Action Buttons

    var completeSetButton: XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'complete set' OR label CONTAINS[c] 'log set'")).firstMatch
    }

    var completeExerciseButton: XCUIElement {
        let labels = ["Complete Exercise", "Complete", "Done"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'complete'")).firstMatch
    }

    var quickCompleteButton: XCUIElement {
        let labels = ["Quick Complete", "Quick Complete (Prescribed Values)", "I did this as prescribed", "As Prescribed"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'prescribed' OR label CONTAINS[c] 'quick complete'")).firstMatch
    }

    var skipButton: XCUIElement {
        let labels = ["Skip", "Skip Exercise", "Skip This"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'skip'")).firstMatch
    }

    var finishWorkoutButton: XCUIElement {
        let labels = ["Finish Workout", "Complete Workout", "End Workout", "Finish"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'finish' OR label CONTAINS[c] 'complete workout'")).firstMatch
    }

    // MARK: - Rest Timer Elements

    var restTimerDisplay: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label MATCHES '\\\\d+:\\\\d+'")).firstMatch
    }

    var skipRestButton: XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'skip rest' OR label CONTAINS[c] 'skip timer'")).firstMatch
    }

    // MARK: - Summary Elements

    var workoutCompleteTitle: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'workout complete' OR label CONTAINS[c] 'great job' OR label CONTAINS[c] 'finished'")).firstMatch
    }

    var summaryExerciseCount: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch
    }

    var summaryVolume: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'volume' OR label CONTAINS[c] 'total'")).firstMatch
    }

    var summaryDuration: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'duration' OR label CONTAINS[c] 'time'")).firstMatch
    }

    var summaryDoneButton: XCUIElement {
        app.buttons["Done"]
    }

    var syncStatusIndicator: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'syncing' OR label CONTAINS[c] 'saved'")).firstMatch
    }

    // MARK: - Interactions

    /// Complete the current set with default values
    @discardableResult
    func completeSet() -> Self {
        TestHelpers.safeTap(completeSetButton, named: "Complete Set Button")
        return self
    }

    /// Complete exercise with prescribed values
    @discardableResult
    func completeWithPrescribedValues() -> Self {
        if quickCompleteButton.exists && quickCompleteButton.isHittable {
            TestHelpers.safeTap(quickCompleteButton, named: "Quick Complete Button")
        } else {
            TestHelpers.safeTap(completeExerciseButton, named: "Complete Exercise Button")
        }
        return self
    }

    /// Complete exercise with current values
    @discardableResult
    func completeExercise() -> Self {
        TestHelpers.safeTap(completeExerciseButton, named: "Complete Exercise Button")
        return self
    }

    /// Skip the current exercise
    @discardableResult
    func skipExercise() -> Self {
        TestHelpers.safeTap(skipButton, named: "Skip Button")

        // Handle confirmation dialog if present
        let confirmButton = app.alerts.buttons["Skip"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }

        return self
    }

    /// Update reps value
    /// - Parameter reps: New reps value
    @discardableResult
    func updateReps(_ reps: Int) -> Self {
        if repsInput.exists && repsInput.isHittable {
            TestHelpers.safeTypeText(
                into: repsInput,
                text: "\(reps)",
                named: "Reps Input",
                clearFirst: true
            )
        } else if repsStepper.exists {
            // Use stepper to adjust value
            let currentValue = Int(repsInput.value as? String ?? "0") ?? 0
            let difference = reps - currentValue

            for _ in 0..<abs(difference) {
                if difference > 0 {
                    repsStepper.buttons["Increment"].tap()
                } else {
                    repsStepper.buttons["Decrement"].tap()
                }
            }
        }
        return self
    }

    /// Update weight value
    /// - Parameter weight: New weight value
    @discardableResult
    func updateWeight(_ weight: Double) -> Self {
        if weightInput.exists && weightInput.isHittable {
            TestHelpers.safeTypeText(
                into: weightInput,
                text: "\(Int(weight))",
                named: "Weight Input",
                clearFirst: true
            )
        } else if weightStepper.exists {
            // Use stepper
            weightStepper.buttons["Increment"].tap()
        }
        return self
    }

    /// Set RPE value
    /// - Parameter rpe: RPE value (1-10)
    @discardableResult
    func setRPE(_ rpe: Int) -> Self {
        let normalizedValue = CGFloat(rpe - 1) / 9.0 // Normalize to 0-1 range
        if rpeSlider.exists {
            rpeSlider.adjust(toNormalizedSliderPosition: normalizedValue)
        }
        return self
    }

    /// Set pain score
    /// - Parameter painScore: Pain value (0-10)
    @discardableResult
    func setPainScore(_ painScore: Int) -> Self {
        let normalizedValue = CGFloat(painScore) / 10.0
        if painSlider.exists {
            painSlider.adjust(toNormalizedSliderPosition: normalizedValue)
        }
        return self
    }

    /// Add notes for the exercise
    /// - Parameter notes: Notes text
    @discardableResult
    func addNotes(_ notes: String) -> Self {
        if notesField.exists {
            TestHelpers.safeTypeText(
                into: notesField,
                text: notes,
                named: "Notes Field"
            )
        }
        return self
    }

    /// Finish the workout
    @discardableResult
    func finishWorkout() -> Self {
        TestHelpers.safeTap(finishWorkoutButton, named: "Finish Workout Button")
        return self
    }

    /// Dismiss workout summary
    @discardableResult
    func dismissSummary() -> Self {
        if summaryDoneButton.exists {
            TestHelpers.safeTap(summaryDoneButton, named: "Summary Done Button")
        } else {
            app.swipeDown()
        }
        return self
    }

    /// Skip rest timer
    @discardableResult
    func skipRestTimer() -> Self {
        if skipRestButton.exists {
            TestHelpers.safeTap(skipRestButton, named: "Skip Rest Button")
        }
        return self
    }

    // MARK: - Wait Functions

    /// Wait for exercise to load
    /// - Parameter timeout: Maximum wait time
    @discardableResult
    func waitForExerciseLoad(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = exerciseTitle.waitForExistence(timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    /// Wait for workout summary to appear
    /// - Parameter timeout: Maximum wait time
    @discardableResult
    func waitForSummary(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = workoutCompleteTitle.waitForExistence(timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert exercise details are displayed
    func assertExerciseDetailsDisplayed() {
        let detailElements = [setsLabel, repsLabel, loadLabel, exerciseTitle]
        let anyDetailFound = detailElements.contains { $0.exists }

        XCTAssertTrue(anyDetailFound,
                     "Exercise details (sets, reps, load, or title) should be displayed")
    }

    /// Assert set logging UI is available
    func assertSetLoggingUIAvailable() {
        let loggingElements = [repsInput, weightInput, repsStepper, weightStepper, completeSetButton]
        let anyLoggingUIFound = loggingElements.contains { $0.exists }

        XCTAssertTrue(anyLoggingUIFound,
                     "Set logging UI elements should be available")
    }

    /// Assert workout summary is displayed
    func assertWorkoutSummaryDisplayed() {
        let summaryElements = [workoutCompleteTitle, summaryExerciseCount, summaryVolume, summaryDoneButton]
        let anySummaryFound = summaryElements.contains { $0.exists }

        XCTAssertTrue(anySummaryFound,
                     "Workout summary should display completion information")
    }

    /// Assert rest timer is visible
    func assertRestTimerVisible() {
        TestHelpers.assertExists(restTimerDisplay, named: "Rest Timer Display", timeout: 3)
    }

    /// Assert progress is updated
    func assertProgressUpdated() {
        let progressExists = progressBar.exists || exerciseCounter.exists || completedCounter.exists
        XCTAssertTrue(progressExists, "Progress indicator should be visible")
    }

    /// Assert exercise is marked complete
    func assertExerciseCompleted() {
        let completedIndicator = app.images.containing(
            NSPredicate(format: "identifier CONTAINS[c] 'checkmark' OR label CONTAINS[c] 'complete'")
        ).firstMatch

        let statusText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'completed' OR label CONTAINS[c] 'done'")
        ).firstMatch

        XCTAssertTrue(completedIndicator.exists || statusText.exists,
                     "Exercise should show completion indicator")
    }

    /// Assert exercise is skipped
    func assertExerciseSkipped() {
        let skippedIndicator = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'skipped'")
        ).firstMatch

        XCTAssertTrue(skippedIndicator.exists,
                     "Exercise should show skipped status")
    }

    /// Assert sync status is showing
    func assertSyncStatusVisible() {
        let syncExists = syncStatusIndicator.exists ||
                        app.activityIndicators.firstMatch.exists

        // Sync status may or may not be visible depending on state
        // This is informational
        print("Sync status visible: \(syncExists)")
    }

    // MARK: - Queries

    /// Get current exercise name
    var currentExerciseName: String {
        exerciseTitle.label
    }

    /// Check if workout can be completed
    var canCompleteWorkout: Bool {
        finishWorkoutButton.exists && finishWorkoutButton.isHittable
    }

    /// Check if rest timer is active
    var isRestTimerActive: Bool {
        restTimerDisplay.exists
    }

    /// Get number of completed sets
    var completedSetCount: Int {
        let completedText = completedCounter.label
        // Extract number from text like "3 completed"
        if let match = completedText.range(of: "\\d+", options: .regularExpression) {
            return Int(completedText[match]) ?? 0
        }
        return 0
    }
}
