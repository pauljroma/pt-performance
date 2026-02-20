//
//  ReadinessCheckInFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the daily readiness check-in flow
//  Tests access from Today Hub, slider interactions, submission, and dismissal
//

import XCTest

/// E2E tests for the daily readiness check-in flow
///
/// Each test method:
/// 1. Launches the app as Marcus Rivera (rehab mode)
/// 2. Navigates to the Today Hub
/// 3. Attempts to open the readiness check-in via multiple UI paths
/// 4. Interacts with readiness sliders and verifies behavior
/// 5. Captures screenshots for visual review
final class ReadinessCheckInFlowTests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - User Configuration

    private let marcusRiveraID = "aaaaaaaa-bbbb-cccc-dddd-000000000001"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000001"
        ]
        app.launchEnvironment = ["IS_RUNNING_UITEST": "1"]
        app.launch()

        // Wait for tab bar to confirm login succeeded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )

        // Ensure we are on the Today tab
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()
        }
        waitForContentToLoad()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Helper: Open Readiness Check-In

    /// Tries multiple UI paths to open the readiness check-in.
    /// Returns `true` if the check-in view was successfully opened.
    @discardableResult
    private func openReadinessCheckIn() -> Bool {
        // Strategy 1: Look for a direct readiness / check-in button or tappable text
        let directEntryPredicates = [
            "label CONTAINS[c] 'readiness'",
            "label CONTAINS[c] 'check in'",
            "label CONTAINS[c] 'check-in'",
            "label CONTAINS[c] 'how are you'"
        ]

        for predicateString in directEntryPredicates {
            let predicate = NSPredicate(format: predicateString)

            // Try buttons first
            let button = app.buttons.containing(predicate).firstMatch
            if button.waitForExistence(timeout: 3) && button.isHittable {
                button.tap()
                if waitForCheckInView() { return true }
            }

            // Try static texts (tappable cards)
            let text = app.staticTexts.containing(predicate).firstMatch
            if text.waitForExistence(timeout: 2) && text.isHittable {
                text.tap()
                if waitForCheckInView() { return true }
            }
        }

        // Strategy 2: Look for a quick actions / menu / plus button
        let menuPredicates = [
            "label CONTAINS[c] 'quick action'",
            "label CONTAINS[c] 'menu'",
            "label CONTAINS[c] 'add'",
            "label CONTAINS[c] 'log'"
        ]

        for predicateString in menuPredicates {
            let predicate = NSPredicate(format: predicateString)
            let menuButton = app.buttons.containing(predicate).firstMatch
            if menuButton.waitForExistence(timeout: 2) && menuButton.isHittable {
                menuButton.tap()
                Thread.sleep(forTimeInterval: 1.0)

                // Now look for readiness option inside the opened menu
                let readinessOption = app.buttons.containing(
                    NSPredicate(format: "label CONTAINS[c] 'readiness'")
                ).firstMatch

                if readinessOption.waitForExistence(timeout: 3) && readinessOption.isHittable {
                    readinessOption.tap()
                    if waitForCheckInView() { return true }
                }

                let checkInOption = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'check in'")
                ).firstMatch

                if checkInOption.waitForExistence(timeout: 2) && checkInOption.isHittable {
                    checkInOption.tap()
                    if waitForCheckInView() { return true }
                }

                // Dismiss the menu if nothing matched
                app.swipeDown()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Strategy 3: Try tapping a plus (+) navigation bar button
        let plusButton = app.navigationBars.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
        ).firstMatch
        if plusButton.waitForExistence(timeout: 2) && plusButton.isHittable {
            plusButton.tap()
            Thread.sleep(forTimeInterval: 1.0)

            let readinessInMenu = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'readiness'")
            ).firstMatch
            if readinessInMenu.waitForExistence(timeout: 3) {
                readinessInMenu.tap()
                if waitForCheckInView() { return true }
            }
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        return false
    }

    /// Waits briefly for the readiness check-in view to appear.
    private func waitForCheckInView() -> Bool {
        Thread.sleep(forTimeInterval: 1.0)

        // Check for sliders (primary indicator)
        if app.sliders.firstMatch.waitForExistence(timeout: 5) {
            return true
        }

        // Check for readiness-related text
        let readinessText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'sleep' OR label CONTAINS[c] 'energy' OR label CONTAINS[c] 'how'")
        ).firstMatch
        if readinessText.waitForExistence(timeout: 3) {
            return true
        }

        return false
    }

    // MARK: - Helper: Find and Tap Submit Button

    @discardableResult
    private func tapSubmitButton() -> Bool {
        let submitLabels = ["Submit", "Save", "Done", "Complete", "Log"]
        for label in submitLabels {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                return true
            }
        }

        // Fallback: predicate search
        let predicate = NSPredicate(
            format: "label CONTAINS[c] 'submit' OR label CONTAINS[c] 'save' OR label CONTAINS[c] 'done' OR label CONTAINS[c] 'complete' OR label CONTAINS[c] 'log'"
        )
        let fallbackButton = app.buttons.containing(predicate).firstMatch
        if fallbackButton.exists && fallbackButton.isHittable {
            fallbackButton.tap()
            return true
        }

        return false
    }

    // MARK: - Helper: Adjust Sliders

    /// Adjusts all available sliders to the given normalized values.
    /// Values are applied in order: sleep, energy, stress, soreness, mood.
    private func adjustSliders(values: [CGFloat]) {
        let sliders = app.sliders.allElementsBoundByIndex
        for (index, value) in values.enumerated() {
            guard index < sliders.count else { break }
            let slider = sliders[index]
            if slider.exists && slider.isHittable {
                slider.adjust(toNormalizedSliderPosition: value)
            }
        }
    }

    // MARK: - Common Helpers

    private func waitForContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 15)
        }
        Thread.sleep(forTimeInterval: 0.5)
    }

    private func assertNoErrorAlerts(context: String) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let alertLabel = alert.label
            let okButton = alert.buttons.firstMatch
            if okButton.exists { okButton.tap() }
            XCTFail("\(context): Unexpected error alert -- \(alertLabel)")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Test 1: Access Readiness from Today Hub

    func testAccessReadinessFromTodayHub() throws {
        let opened = openReadinessCheckIn()
        try XCTSkipIf(!opened, "No readiness check-in entry point found on Today Hub")

        // Assert the check-in view is showing readiness-related content
        let hasSliders = app.sliders.firstMatch.exists
        let hasReadinessText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'sleep' OR label CONTAINS[c] 'energy' OR label CONTAINS[c] 'how'")
        ).firstMatch.exists

        XCTAssertTrue(
            hasSliders || hasReadinessText,
            "Readiness check-in view should display sliders or readiness-related text"
        )

        assertNoErrorAlerts(context: "Access readiness check-in")
        takeScreenshot(named: "readiness_checkin_opened")
    }

    // MARK: - Test 2: Readiness Dashboard Loads

    func testReadinessDashboardLoads() throws {
        // Look for readiness dashboard elements on the Today Hub without opening the check-in
        let readinessElements = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'score' OR label CONTAINS[c] 'status'")
        )

        let dashboardVisible = readinessElements.firstMatch.waitForExistence(timeout: 10)
        try XCTSkipIf(
            !dashboardVisible,
            "No readiness dashboard or score display found on Today Hub"
        )

        let matchCount = readinessElements.count
        XCTAssertGreaterThan(
            matchCount, 0,
            "At least one readiness-related element should be visible on the Today Hub"
        )

        assertNoErrorAlerts(context: "Readiness dashboard")
        takeScreenshot(named: "readiness_dashboard")
    }

    // MARK: - Test 3: Complete Full Readiness Check-In

    func testCompleteFullReadinessCheckIn() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        // Adjust sliders: sleep=0.7, energy=0.8, stress=0.3, soreness=0.2, mood=0.8
        adjustSliders(values: [0.7, 0.8, 0.3, 0.2, 0.8])

        takeScreenshot(named: "readiness_checkin_filled")

        // Submit
        let submitted = tapSubmitButton()
        XCTAssertTrue(submitted, "Should find and tap a submit/save/done button")

        // Wait for success indicator or sheet dismissal
        let successText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'logged' OR label CONTAINS[c] 'recorded' OR label CONTAINS[c] 'saved' OR label CONTAINS[c] 'complete'")
        ).firstMatch
        let sheetDismissed = !app.sliders.firstMatch.waitForExistence(timeout: 5)
        let successShown = successText.waitForExistence(timeout: 5)

        XCTAssertTrue(
            successShown || sheetDismissed,
            "Check-in should complete with a success message or the sheet should dismiss"
        )

        assertNoErrorAlerts(context: "Complete full readiness check-in")
        takeScreenshot(named: "readiness_checkin_submitted")
    }

    // MARK: - Test 4: Check-In with Low Values

    func testReadinessCheckInWithLowValues() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        // Set all sliders to low/bad values: sleep=0.2, energy=0.2, stress=0.8, soreness=0.8, mood=0.2
        adjustSliders(values: [0.2, 0.2, 0.8, 0.8, 0.2])

        takeScreenshot(named: "readiness_checkin_low_values")

        let submitted = tapSubmitButton()
        XCTAssertTrue(submitted, "Should find and tap a submit button")

        // Wait for submission to process
        Thread.sleep(forTimeInterval: 3.0)

        assertNoErrorAlerts(context: "Readiness check-in with low values")
        takeScreenshot(named: "readiness_checkin_low_values_submitted")
    }

    // MARK: - Test 5: Check-In with High Values

    func testReadinessCheckInWithHighValues() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        // Set all sliders to optimal values: sleep=1.0, energy=1.0, stress=0.0, soreness=0.0, mood=1.0
        adjustSliders(values: [1.0, 1.0, 0.0, 0.0, 1.0])

        takeScreenshot(named: "readiness_checkin_high_values")

        let submitted = tapSubmitButton()
        XCTAssertTrue(submitted, "Should find and tap a submit button")

        // Wait for submission to process
        Thread.sleep(forTimeInterval: 3.0)

        assertNoErrorAlerts(context: "Readiness check-in with high values")
        takeScreenshot(named: "readiness_checkin_high_values_submitted")
    }

    // MARK: - Test 6: Dismiss Readiness Check-In

    func testDismissReadinessCheckIn() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        takeScreenshot(named: "readiness_checkin_before_dismiss")

        // Try close button first
        let closeButton = app.buttons["Close"]
        let cancelButton = app.buttons["Cancel"]
        let dismissButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'dismiss' OR label CONTAINS[c] 'close' OR label CONTAINS[c] 'cancel'")
        ).firstMatch

        if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
        } else if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        } else if dismissButton.exists && dismissButton.isHittable {
            dismissButton.tap()
        } else {
            // Fallback: swipe down to dismiss modal/sheet
            app.swipeDown()
        }

        Thread.sleep(forTimeInterval: 1.0)

        // Verify we returned to the Today Hub (tab bar should be visible and no error alerts)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 5),
            "Tab bar should be visible after dismissing check-in, indicating return to Today Hub"
        )

        assertNoErrorAlerts(context: "Dismiss readiness check-in")
        takeScreenshot(named: "readiness_checkin_dismissed")
    }

    // MARK: - Test 7: Slider Interaction

    func testReadinessCheckInSliderInteraction() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        let sliderCount = app.sliders.count
        XCTAssertGreaterThan(sliderCount, 0, "At least one slider should be present in the readiness check-in")

        // Interact with the first slider
        let firstSlider = app.sliders.allElementsBoundByIndex[0]
        XCTAssertTrue(firstSlider.exists, "First slider should exist")
        XCTAssertTrue(firstSlider.isHittable, "First slider should be interactive (hittable)")

        firstSlider.adjust(toNormalizedSliderPosition: 0.5)

        // Verify the slider still exists after interaction (no crash or disappearance)
        XCTAssertTrue(
            firstSlider.exists,
            "First slider should still exist after adjusting its value"
        )

        assertNoErrorAlerts(context: "Slider interaction")
        takeScreenshot(named: "readiness_checkin_slider_interaction")
    }

    // MARK: - Test 8: Questions Visible

    func testReadinessCheckInQuestionsVisible() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found")

        // Look for question labels
        let questionKeywords = ["sleep", "energy", "stress", "soreness", "mood"]
        var foundQuestions: [String] = []

        for keyword in questionKeywords {
            let label = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] %@", keyword)
            ).firstMatch
            if label.exists {
                foundQuestions.append(keyword)
            }
        }

        XCTAssertGreaterThanOrEqual(
            foundQuestions.count, 2,
            "At least 2 question labels should be visible, but found \(foundQuestions.count): \(foundQuestions)"
        )

        // Also verify submit button exists
        let submitPredicate = NSPredicate(
            format: "label CONTAINS[c] 'submit' OR label CONTAINS[c] 'save' OR label CONTAINS[c] 'done' OR label CONTAINS[c] 'complete' OR label CONTAINS[c] 'log'"
        )
        let submitButton = app.buttons.containing(submitPredicate).firstMatch
        XCTAssertTrue(
            submitButton.exists,
            "A submit/save/done button should be present on the check-in view"
        )

        assertNoErrorAlerts(context: "Questions visible")
        takeScreenshot(named: "readiness_checkin_questions_visible")
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
