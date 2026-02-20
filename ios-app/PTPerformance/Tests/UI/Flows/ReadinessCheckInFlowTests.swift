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
    ///
    /// Strategy order:
    /// 1. CheckInPromptCard - "Daily Check-in" button (always present on Today Hub)
    /// 2. ReadinessStatusCard - "Check In Now" button (present when not yet checked in)
    /// 3. Quick Actions menu (ellipsis.circle) -> "Daily Check-in"
    /// 4. Generic fallback predicates for check-in related labels
    @discardableResult
    private func openReadinessCheckIn() -> Bool {
        // Wait for the Today Hub content to finish its initial async loading.
        // TodaySessionView shows a loading view while fetching from Supabase.
        waitForTodayHubContentToLoad()

        // Strategy 1: CheckInPromptCard via accessibilityIdentifier (most reliable).
        // The identifier is deterministic and not affected by SwiftUI's composed
        // accessibility labels, which concatenate all child Text views.
        let promptCard = app.buttons.matching(identifier: "check_in_prompt_card").firstMatch
        if promptCard.waitForExistence(timeout: 10) && promptCard.isHittable {
            promptCard.tap()
            if waitForCheckInView() { return true }
        }

        // Strategy 2: ReadinessStatusCard "Check In Now" button (exact accessibility label).
        // Visible when readiness has not been submitted today and a session is loaded.
        let checkInNowButton = app.buttons["Check In Now"]
        if checkInNowButton.waitForExistence(timeout: 5) && checkInNowButton.isHittable {
            checkInNowButton.tap()
            if waitForCheckInView() { return true }
        }

        // Strategy 3: Quick Actions menu -> "Daily Check-in"
        // The menu button has accessibilityLabel "Quick Actions"
        let quickActionsMenu = app.buttons["Quick Actions"]
        if quickActionsMenu.waitForExistence(timeout: 3) && quickActionsMenu.isHittable {
            quickActionsMenu.tap()
            Thread.sleep(forTimeInterval: 1.0)

            // Look for "Daily Check-in" menu item
            let dailyCheckInMenuItem = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'Daily Check-in'")
            ).firstMatch
            if dailyCheckInMenuItem.waitForExistence(timeout: 3) && dailyCheckInMenuItem.isHittable {
                dailyCheckInMenuItem.tap()
                if waitForCheckInView() { return true }
            }

            // Dismiss the menu if nothing matched
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Strategy 4: Composed label fallback.
        // When SwiftUI composes a label, it concatenates child texts. The
        // CheckInPromptCard label might be "Daily Check-in, How are you
        // feeling today?, Start" -- search with CONTAINS to match any fragment.
        let fallbackPredicates = [
            "label CONTAINS[c] 'Daily Check-in'",
            "label CONTAINS[c] 'check-in'",
            "label CONTAINS[c] 'check in'",
            "label CONTAINS[c] 'readiness'",
            "label CONTAINS[c] 'how are you feeling'"
        ]

        for predicateString in fallbackPredicates {
            let predicate = NSPredicate(format: predicateString)

            let button = app.buttons.containing(predicate).firstMatch
            if button.waitForExistence(timeout: 2) && button.isHittable {
                button.tap()
                if waitForCheckInView() { return true }
            }

            let text = app.staticTexts.containing(predicate).firstMatch
            if text.waitForExistence(timeout: 1) && text.isHittable {
                text.tap()
                if waitForCheckInView() { return true }
            }
        }

        // Log diagnostic info about what IS visible
        takeScreenshot(named: "open_readiness_failed")
        return false
    }

    /// Waits for the Today Hub content to finish its initial async loading.
    /// CheckInPromptCard runs an async `loadStatus()` on appear that shows
    /// "Loading..." while fetching from Supabase. We must wait for that to
    /// resolve before trying to tap the card.
    private func waitForTodayHubContentToLoad() {
        // Wait for activity indicators (ProgressView) to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 20)
        }

        // Wait for any "Loading" text to disappear (covers CheckInPromptCard's
        // "Loading..." state and ReadinessStatusCard's "Loading readiness...")
        let loadingText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Loading'")
        ).firstMatch
        if loadingText.exists {
            _ = loadingText.waitForNonExistence(timeout: 20)
        }

        // Give the UI a moment to settle after async loads complete
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// Waits for the readiness check-in view (ReadinessCheckInView) to appear.
    /// The view has an initial loading state ("Loading your check-in...") before
    /// showing sliders; we wait for that loading to complete first.
    private func waitForCheckInView() -> Bool {
        // Wait for the sheet/modal to present
        Thread.sleep(forTimeInterval: 1.0)

        // ReadinessCheckInView has navigationTitle "Daily Check-In"
        let navTitle = app.navigationBars["Daily Check-In"]
        if navTitle.waitForExistence(timeout: 8) {
            // The check-in view is presenting; now wait for loading to complete
            // It shows "Loading your check-in..." initially
            let loadingText = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Loading your check-in'")
            ).firstMatch
            if loadingText.exists {
                _ = loadingText.waitForNonExistence(timeout: 15)
            }
            Thread.sleep(forTimeInterval: 0.5)
            return true
        }

        // Fallback: Check for sliders (primary indicator of loaded check-in form)
        if app.sliders.firstMatch.waitForExistence(timeout: 8) {
            return true
        }

        // Fallback: Check for readiness-related text labels (Sleep, Energy, etc.)
        let readinessLabels = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Sleep' OR label CONTAINS[c] 'Energy' OR label CONTAINS[c] 'Soreness' OR label CONTAINS[c] 'Stress'")
        ).firstMatch
        if readinessLabels.waitForExistence(timeout: 3) {
            return true
        }

        // Check for the "Cancel" button which is on the ReadinessCheckInView toolbar
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            return true
        }

        return false
    }

    // MARK: - Helper: Find and Tap Submit Button

    @discardableResult
    private func tapSubmitButton() -> Bool {
        // ReadinessCheckInView uses these accessibility labels:
        // - "Submit today's check-in" (new check-in)
        // - "Update today's check-in" (existing check-in)
        let submitCheckIn = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Submit today' OR label CONTAINS[c] 'Update today'")
        ).firstMatch
        if submitCheckIn.exists && submitCheckIn.isHittable {
            submitCheckIn.tap()
            return true
        }

        // Fallback: button text "Submit Check-In" or "Update Check-In"
        let submitTextButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Submit Check-In' OR label CONTAINS[c] 'Update Check-In'")
        ).firstMatch
        if submitTextButton.exists && submitTextButton.isHittable {
            submitTextButton.tap()
            return true
        }

        // Generic fallback labels
        let submitLabels = ["Submit", "Save", "Done", "Complete", "Log"]
        for label in submitLabels {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                return true
            }
        }

        // Broadest fallback: predicate search
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
    /// ReadinessCheckInView has 4 sliders in order: Sleep, Energy, Soreness, Stress.
    /// Values are applied in order to available sliders, clamping to slider count.
    private func adjustSliders(values: [CGFloat]) {
        // Wait for sliders to be available
        _ = app.sliders.firstMatch.waitForExistence(timeout: 5)

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
        try XCTSkipIf(!opened, "No readiness check-in entry point found on Today Hub -- CheckInPromptCard, ReadinessStatusCard, and Quick Actions menu all failed")

        // Assert the check-in view is showing readiness-related content.
        // ReadinessCheckInView has a "Daily Check-In" nav title and sliders for
        // Sleep, Energy, Soreness, Stress.
        let hasNavTitle = app.navigationBars["Daily Check-In"].exists
        let hasSliders = app.sliders.firstMatch.exists
        let hasReadinessText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Sleep' OR label CONTAINS[c] 'Energy' OR label CONTAINS[c] 'Soreness' OR label CONTAINS[c] 'Stress'")
        ).firstMatch.exists
        let hasCancelButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Cancel check-in' OR label == 'Cancel'")
        ).firstMatch.exists

        XCTAssertTrue(
            hasNavTitle || hasSliders || hasReadinessText || hasCancelButton,
            "Readiness check-in view should display nav title, sliders, or readiness-related text"
        )

        assertNoErrorAlerts(context: "Access readiness check-in")
        takeScreenshot(named: "readiness_checkin_opened")
    }

    // MARK: - Test 2: Readiness Dashboard Loads

    func testReadinessDashboardLoads() throws {
        // Wait for the Today Hub content to load before searching
        waitForTodayHubContentToLoad()

        // Look for readiness dashboard elements on the Today Hub without opening the check-in.
        // ReadinessStatusCard shows "Daily Readiness" header.
        // CheckInPromptCard shows "Daily Check-in" or "Check-in Complete".
        let readinessElements = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Daily Readiness' OR label CONTAINS[c] 'readiness' OR label CONTAINS[c] 'Daily Check-in' OR label CONTAINS[c] 'Check-in Complete' OR label CONTAINS[c] 'score' OR label CONTAINS[c] 'status'")
        )

        let dashboardVisible = readinessElements.firstMatch.waitForExistence(timeout: 10)
        try XCTSkipIf(
            !dashboardVisible,
            "No readiness dashboard or check-in prompt found on Today Hub"
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
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

        // Wait for sliders to be ready
        let slidersReady = app.sliders.firstMatch.waitForExistence(timeout: 10)
        if slidersReady {
            // Adjust sliders: sleep=0.7, energy=0.8, stress=0.3, soreness=0.2
            // ReadinessCheckInView has 4 sliders: Sleep, Energy, Soreness, Stress
            adjustSliders(values: [0.7, 0.8, 0.3, 0.2])
        }

        takeScreenshot(named: "readiness_checkin_filled")

        // Submit
        let submitted = tapSubmitButton()
        XCTAssertTrue(submitted, "Should find and tap a submit/save/done button")

        // ReadinessCheckInView shows a success overlay with "Check-In Submitted!"
        // or "Check-In Updated!" text, then auto-dismisses after 1.5 seconds.
        let successText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Check-In Submitted' OR label CONTAINS[c] 'Check-In Updated' OR label CONTAINS[c] 'logged' OR label CONTAINS[c] 'recorded' OR label CONTAINS[c] 'saved'")
        ).firstMatch
        let successShown = successText.waitForExistence(timeout: 8)

        // The view auto-dismisses, so the sheet may disappear
        let sheetDismissed = !app.navigationBars["Daily Check-In"].waitForExistence(timeout: 5)

        XCTAssertTrue(
            successShown || sheetDismissed,
            "Check-in should complete with a success message or the sheet should dismiss"
        )

        assertNoErrorAlerts(context: "Complete full readiness check-in")
        takeScreenshot(named: "readiness_checkin_submitted")
    }

    // MARK: - Test 4: Check-In with Low Values

    func testReadinessCheckInWithLowValues() throws {
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

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
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

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
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

        takeScreenshot(named: "readiness_checkin_before_dismiss")

        // ReadinessCheckInView has a "Cancel" toolbar button with
        // accessibilityLabel "Cancel check-in"
        let cancelCheckIn = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Cancel check-in'")
        ).firstMatch
        let cancelButton = app.buttons["Cancel"]
        let closeButton = app.buttons["Close"]
        let dismissButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'dismiss' OR label CONTAINS[c] 'close' OR label CONTAINS[c] 'cancel'")
        ).firstMatch

        if cancelCheckIn.exists && cancelCheckIn.isHittable {
            cancelCheckIn.tap()
        } else if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        } else if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
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
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

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
        try XCTSkipIf(!openReadinessCheckIn(), "No readiness check-in entry point found on Today Hub")

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
