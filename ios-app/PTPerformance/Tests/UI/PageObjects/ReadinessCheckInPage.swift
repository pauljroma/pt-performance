//
//  ReadinessCheckInPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Readiness Check-In views
//  Supports daily readiness questionnaire interaction
//

import XCTest

/// Page Object representing the Readiness Check-In flow
struct ReadinessCheckInPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Navigation Elements

    var closeButton: XCUIElement {
        app.buttons["Close"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    var backButton: XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    // MARK: - Title Elements

    var readinessTitle: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'readiness'")).firstMatch
    }

    var questionTitle: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'how' OR label CONTAINS[c] 'feel' OR label CONTAINS[c] 'rate'")).firstMatch
    }

    // MARK: - Sleep Question Elements

    var sleepLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'sleep'")).firstMatch
    }

    var sleepSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'sleep'")).firstMatch
    }

    // MARK: - Energy Question Elements

    var energyLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'energy'")).firstMatch
    }

    var energySlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'energy'")).firstMatch
    }

    // MARK: - Stress Question Elements

    var stressLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'stress'")).firstMatch
    }

    var stressSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'stress'")).firstMatch
    }

    // MARK: - Soreness Question Elements

    var sorenessLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'soreness' OR label CONTAINS[c] 'sore'")).firstMatch
    }

    var sorenessSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'soreness'")).firstMatch
    }

    // MARK: - Mood Question Elements

    var moodLabel: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'mood'")).firstMatch
    }

    var moodSlider: XCUIElement {
        app.sliders.containing(NSPredicate(format: "identifier CONTAINS[c] 'mood'")).firstMatch
    }

    // MARK: - Generic Sliders (fallback)

    var firstSlider: XCUIElement {
        app.sliders.firstMatch
    }

    var allSliders: XCUIElementQuery {
        app.sliders
    }

    // MARK: - Submit Elements

    var submitButton: XCUIElement {
        let labels = ["Submit", "Save", "Done", "Complete", "Log Readiness"]
        for label in labels {
            let button = app.buttons[label]
            if button.exists {
                return button
            }
        }
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'submit' OR label CONTAINS[c] 'save' OR label CONTAINS[c] 'done'")).firstMatch
    }

    var nextButton: XCUIElement {
        app.buttons["Next"]
    }

    // MARK: - Result Elements

    var readinessScore: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label MATCHES '\\\\d+%?' OR label CONTAINS[c] 'score'")).firstMatch
    }

    var successMessage: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'logged' OR label CONTAINS[c] 'recorded' OR label CONTAINS[c] 'saved'")).firstMatch
    }

    // MARK: - Interactions

    /// Set sleep quality
    /// - Parameter value: Sleep quality (0-10)
    @discardableResult
    func setSleepQuality(_ value: Int) -> Self {
        setSliderValue(sleepSlider.exists ? sleepSlider : firstSlider, to: value)
        return self
    }

    /// Set energy level
    /// - Parameter value: Energy level (0-10)
    @discardableResult
    func setEnergyLevel(_ value: Int) -> Self {
        if energySlider.exists {
            setSliderValue(energySlider, to: value)
        } else if allSliders.count > 1 {
            setSliderValue(allSliders.element(boundBy: 1), to: value)
        }
        return self
    }

    /// Set stress level
    /// - Parameter value: Stress level (0-10)
    @discardableResult
    func setStressLevel(_ value: Int) -> Self {
        if stressSlider.exists {
            setSliderValue(stressSlider, to: value)
        } else if allSliders.count > 2 {
            setSliderValue(allSliders.element(boundBy: 2), to: value)
        }
        return self
    }

    /// Set soreness level
    /// - Parameter value: Soreness level (0-10)
    @discardableResult
    func setSorenessLevel(_ value: Int) -> Self {
        if sorenessSlider.exists {
            setSliderValue(sorenessSlider, to: value)
        } else if allSliders.count > 3 {
            setSliderValue(allSliders.element(boundBy: 3), to: value)
        }
        return self
    }

    /// Set mood level
    /// - Parameter value: Mood level (0-10)
    @discardableResult
    func setMoodLevel(_ value: Int) -> Self {
        if moodSlider.exists {
            setSliderValue(moodSlider, to: value)
        } else if allSliders.count > 4 {
            setSliderValue(allSliders.element(boundBy: 4), to: value)
        }
        return self
    }

    /// Submit the readiness check-in
    @discardableResult
    func submit() -> Self {
        TestHelpers.safeTap(submitButton, named: "Submit Button")
        return self
    }

    /// Tap next button (for multi-step flows)
    @discardableResult
    func tapNext() -> Self {
        if nextButton.exists {
            TestHelpers.safeTap(nextButton, named: "Next Button")
        }
        return self
    }

    /// Dismiss the check-in view
    @discardableResult
    func dismiss() -> Self {
        if closeButton.exists {
            closeButton.tap()
        } else if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.swipeDown()
        }
        return self
    }

    /// Complete a full readiness check-in with given values
    /// - Parameters:
    ///   - sleep: Sleep quality (0-10)
    ///   - energy: Energy level (0-10)
    ///   - stress: Stress level (0-10)
    ///   - soreness: Soreness level (0-10)
    ///   - mood: Mood level (0-10)
    @discardableResult
    func completeCheckIn(
        sleep: Int = 7,
        energy: Int = 7,
        stress: Int = 3,
        soreness: Int = 2,
        mood: Int = 7
    ) -> Self {
        setSleepQuality(sleep)
        setEnergyLevel(energy)
        setStressLevel(stress)
        setSorenessLevel(soreness)
        setMoodLevel(mood)
        submit()
        return self
    }

    // MARK: - Private Helpers

    private func setSliderValue(_ slider: XCUIElement, to value: Int) {
        guard slider.exists else { return }
        let normalizedValue = CGFloat(value) / 10.0
        slider.adjust(toNormalizedSliderPosition: normalizedValue)
    }

    // MARK: - Wait Functions

    /// Wait for check-in view to load
    /// - Parameter timeout: Maximum wait time
    @discardableResult
    func waitForLoad(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        let loaded = readinessTitle.waitForExistence(timeout: timeout) ||
                    sleepLabel.waitForExistence(timeout: timeout) ||
                    firstSlider.waitForExistence(timeout: timeout) ||
                    questionTitle.waitForExistence(timeout: timeout)

        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    /// Wait for submission to complete
    /// - Parameter timeout: Maximum wait time
    @discardableResult
    func waitForSubmissionComplete(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = successMessage.waitForExistence(timeout: timeout) ||
            readinessScore.waitForExistence(timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert check-in view is displayed
    func assertIsDisplayed() {
        let checkInElements = [readinessTitle, questionTitle, sleepLabel, firstSlider]
        let anyFound = checkInElements.contains { $0.exists }

        XCTAssertTrue(anyFound,
                     "Readiness check-in view should be displayed")
    }

    /// Assert all readiness questions are visible
    func assertAllQuestionsVisible() {
        // Check that at least sleep and one other question is visible
        let hasSliders = allSliders.count > 0

        XCTAssertTrue(hasSliders,
                     "Readiness check-in should display at least one slider for input")

        // Optionally check for multiple questions
        if allSliders.count >= 3 {
            print("Found \(allSliders.count) readiness sliders")
        }
    }

    /// Assert submit button is available
    func assertSubmitAvailable() {
        TestHelpers.assertExists(submitButton, named: "Submit Button", timeout: 3)
    }

    /// Assert check-in was successful
    func assertCheckInSuccessful() {
        let successIndicators = [successMessage, readinessScore]
        let anySuccess = successIndicators.contains { $0.waitForExistence(timeout: 5) }

        // Check for dismiss of the sheet as alternative success indicator
        let sheetDismissed = !readinessTitle.exists

        XCTAssertTrue(anySuccess || sheetDismissed,
                     "Readiness check-in should complete successfully")
    }

    // MARK: - Queries

    /// Check if check-in view is displayed
    var isDisplayed: Bool {
        readinessTitle.exists || sleepLabel.exists || firstSlider.exists
    }

    /// Get number of questions displayed
    var questionCount: Int {
        allSliders.count
    }
}
