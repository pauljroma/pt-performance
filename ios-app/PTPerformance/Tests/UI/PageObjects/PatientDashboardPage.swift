//
//  PatientDashboardPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Patient Dashboard screen
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import XCTest

/// Page Object representing the Patient Dashboard (Today's Session view)
struct PatientDashboardPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    var title: XCUIElement {
        app.staticTexts["Today's Session"]
    }

    var exerciseList: XCUIElement {
        app.tables.firstMatch
    }

    var firstExercise: XCUIElement {
        app.tables.cells.firstMatch
    }

    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }

    var emptyStateMessage: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no session'")).firstMatch
    }

    var errorMessage: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'could not be read'")).firstMatch
    }

    var profileTab: XCUIElement {
        app.buttons["Profile"]
    }

    var historyTab: XCUIElement {
        app.buttons["History"]
    }

    var calendarTab: XCUIElement {
        app.buttons["Calendar"]
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Interactions

    /// Tap on first exercise in the list
    @discardableResult
    func tapFirstExercise() -> Self {
        TestHelpers.safeTap(firstExercise, named: "First Exercise")
        return self
    }

    /// Tap on exercise by name
    /// - Parameter exerciseName: Name of the exercise
    @discardableResult
    func tapExercise(named exerciseName: String) -> Self {
        let exercise = app.tables.cells.containing(NSPredicate(format: "label CONTAINS %@", exerciseName)).firstMatch
        TestHelpers.safeTap(exercise, named: "Exercise: \(exerciseName)")
        return self
    }

    /// Navigate to profile tab
    @discardableResult
    func goToProfile() -> Self {
        TestHelpers.safeTap(profileTab, named: "Profile Tab")
        return self
    }

    /// Navigate to history tab
    @discardableResult
    func goToHistory() -> Self {
        TestHelpers.safeTap(historyTab, named: "History Tab")
        return self
    }

    /// Navigate to calendar tab
    @discardableResult
    func goToCalendar() -> Self {
        TestHelpers.safeTap(calendarTab, named: "Calendar Tab")
        return self
    }

    /// Pull to refresh the session data
    @discardableResult
    func pullToRefresh() -> Self {
        if exerciseList.exists {
            exerciseList.swipeDown(velocity: .fast)
        }
        return self
    }

    // MARK: - Waiting

    /// Wait for dashboard to load
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForLoad(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = TestHelpers.waitForElement(title, timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    /// Wait for exercise list to appear
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForExerciseList(timeout: TimeInterval = TestHelpers.standardTimeout) -> Self {
        _ = TestHelpers.waitForElement(exerciseList, timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert dashboard is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(title, named: "Dashboard Title")
    }

    /// Assert loading is complete
    func assertLoadingComplete() {
        XCTAssertFalse(
            loadingIndicator.exists,
            "Loading indicator should not be visible"
        )
    }

    /// Assert exercise list is displayed
    func assertExerciseListDisplayed() {
        TestHelpers.assertExists(exerciseList, named: "Exercise List")
    }

    /// Assert exercises are loaded
    func assertExercisesLoaded() {
        let cellCount = exerciseList.cells.count
        XCTAssertGreaterThan(
            cellCount,
            0,
            "Exercise list should contain at least one exercise"
        )
    }

    /// Assert empty state is displayed
    func assertEmptyStateDisplayed() {
        TestHelpers.assertExists(emptyStateMessage, named: "Empty State Message")
    }

    /// Assert no error is displayed
    func assertNoError() {
        XCTAssertFalse(
            errorMessage.exists,
            "❌ Error message should not be displayed"
        )
    }

    /// Assert specific error is displayed (for negative testing)
    func assertErrorDisplayed() {
        TestHelpers.assertExists(errorMessage, named: "Error Message")
    }

    /// Assert data loaded successfully (either exercises or empty state)
    func assertDataLoaded() {
        let hasExercises = exerciseList.exists && exerciseList.cells.count > 0
        let hasEmptyState = emptyStateMessage.exists

        XCTAssertTrue(
            hasExercises || hasEmptyState,
            """
            ❌ CRITICAL: No exercise list AND no empty state message
            Expected: Either exercises loaded OR "no session" message
            Actual: Blank screen
            """
        )
    }

    // MARK: - Queries

    /// Get number of exercises in list
    var exerciseCount: Int {
        return exerciseList.cells.count
    }

    /// Check if exercise exists by name
    /// - Parameter name: Exercise name
    /// - Returns: True if exercise exists
    func hasExercise(named name: String) -> Bool {
        let exercise = app.tables.cells.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        return exercise.exists
    }

    /// Get all exercise names
    var allExerciseNames: [String] {
        return exerciseList.cells.allElementsBoundByIndex
            .compactMap { $0.label }
    }
}
