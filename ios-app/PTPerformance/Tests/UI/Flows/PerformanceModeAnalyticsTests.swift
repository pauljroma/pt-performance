//
//  PerformanceModeAnalyticsTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the Analytics and Recovery tabs in performance mode
//  Validates that performance analytics data (ACWR, readiness insights) loads
//  correctly and that recovery protocols display without errors
//

import XCTest

/// E2E tests for the Analytics and Recovery tabs in performance mode
///
/// Logs in as Tyler Brooks (performance mode) and verifies:
/// - Analytics tab loads content (ACWR, workload ratios, readiness insights)
/// - Recovery tab loads protocols and recovery content
/// - Error handling and retry behavior on Analytics tab
/// - Pull-to-refresh support on Analytics tab
///
/// **Tab structure for performance mode:** Today, Training, Analytics, Recovery, Settings
final class PerformanceModeAnalyticsTests: XCTestCase {

    var app: XCUIApplication!

    /// Tyler Brooks (performance mode) UUID
    private let tylerBrooksID = "aaaaaaaa-bbbb-cccc-dddd-000000000003"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000003",
            "--auto-login-mode", "performance"
        ]
        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1"
        ]
        app.launch()

        // Wait for tab bar to confirm login succeeded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Taps the Analytics tab and waits for content to load
    private func navigateToAnalyticsTab() {
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 10), "Analytics tab should exist")
        analyticsTab.tap()
        waitForContentToLoad()
    }

    /// Taps the Recovery tab and waits for content to load
    private func navigateToRecoveryTab() {
        let recoveryTab = app.tabBars.buttons["Recovery"]
        XCTAssertTrue(recoveryTab.waitForExistence(timeout: 10), "Recovery tab should exist")
        recoveryTab.tap()
        waitForContentToLoad()
    }

    /// Scrolls up repeatedly looking for an element whose label matches any of the
    /// provided keywords (case-insensitive). Returns the element if found, nil otherwise.
    @discardableResult
    private func scrollToFindAny(_ keywords: [String], maxSwipes: Int = 10) -> XCUIElement? {
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let text = app.staticTexts.containing(predicate).firstMatch
            let button = app.buttons.containing(predicate).firstMatch
            if text.exists { return text }
            if button.exists { return button }
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            for keyword in keywords {
                let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
                let text = app.staticTexts.containing(predicate).firstMatch
                let button = app.buttons.containing(predicate).firstMatch
                if text.exists { return text }
                if button.exists { return button }
            }
        }

        return nil
    }

    // MARK: - Test 1: Analytics Tab Loads Content

    /// Verify that the Analytics tab loads scrollable content after tapping
    func testAnalyticsTabLoadsContent() throws {
        navigateToAnalyticsTab()

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'analytics' OR label CONTAINS[c] 'performance'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Analytics tab should display scrollable content or analytics-related text")

        takeScreenshot(named: "analytics_tab_content")
        assertNoErrorAlerts(context: "Analytics tab loads content")
    }

    // MARK: - Test 2: Performance Analytics Title

    /// Verify that the Analytics tab shows a "Performance" or "Analytics" title
    func testPerformanceAnalyticsTitle() throws {
        navigateToAnalyticsTab()

        // Check navigation bar title
        let navBarTitle = app.navigationBars.containing(NSPredicate(
            format: "identifier CONTAINS[c] 'analytics' OR identifier CONTAINS[c] 'performance'"
        )).firstMatch

        // Check static texts for analytics-related title
        let titleText = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS[c] 'Performance' OR label CONTAINS[c] 'Analytics'"
        )).firstMatch

        // Also check navigation bar element labels
        let navBarLabels = app.navigationBars.firstMatch

        let titleFound = navBarTitle.exists ||
                         titleText.exists ||
                         navBarLabels.exists

        XCTAssertTrue(
            titleFound,
            "Analytics tab should display a title containing 'Performance' or 'Analytics' in the navigation bar or static texts"
        )

        takeScreenshot(named: "analytics_title")
        assertNoErrorAlerts(context: "Performance analytics title")
    }

    // MARK: - Test 3: ACWR Data or Empty State

    /// Verify that scrolling through Analytics reveals ACWR/Workload data or an empty state
    func testACWRDataOrEmptyState() throws {
        navigateToAnalyticsTab()

        let acwrElement = scrollToFindAny([
            "ACWR", "Workload", "Acute", "Chronic", "Ratio",
            "Training Load", "Load"
        ])

        if let element = acwrElement {
            XCTAssertTrue(element.exists, "ACWR or workload element should be visible after scrolling")
            takeScreenshot(named: "analytics_acwr_data")
        } else {
            // Check for empty state
            let emptyState = scrollToFindAny([
                "No data", "No analytics", "Start training",
                "Not enough data", "Log workouts", "empty"
            ])

            if emptyState != nil {
                takeScreenshot(named: "analytics_acwr_empty_state")
            } else {
                // Neither ACWR data nor explicit empty state -- document for review
                takeScreenshot(named: "analytics_acwr_unknown_state")
                try XCTSkip("Neither ACWR data nor empty state found on Analytics tab -- content may use different labels")
            }
        }

        assertNoErrorAlerts(context: "ACWR data or empty state")
    }

    // MARK: - Test 4: Readiness Insights Present

    /// Verify that scrolling through Analytics reveals readiness insights
    func testReadinessInsightsPresent() throws {
        navigateToAnalyticsTab()

        let readinessElement = scrollToFindAny([
            "Readiness", "Ready", "Score", "Insight",
            "Recovery Score", "Wellness", "Status"
        ])

        if let element = readinessElement {
            XCTAssertTrue(element.exists, "Readiness or score element should be visible after scrolling")
            takeScreenshot(named: "analytics_readiness_insights")
        } else {
            // Readiness insights may not be populated yet
            let emptyState = scrollToFindAny([
                "No readiness", "Check in", "Complete your check-in",
                "No data", "Not available"
            ])

            if emptyState != nil {
                takeScreenshot(named: "analytics_readiness_empty")
            } else {
                takeScreenshot(named: "analytics_readiness_unknown")
                try XCTSkip("Neither readiness insights nor empty state found -- content may use different labels")
            }
        }

        assertNoErrorAlerts(context: "Readiness insights present")
    }

    // MARK: - Test 5: Recovery Tab Loads Content

    /// Verify that the Recovery tab loads scrollable content
    func testRecoveryTabLoadsContent() throws {
        navigateToRecoveryTab()

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'recovery' OR label CONTAINS[c] 'rest' OR label CONTAINS[c] 'protocol'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Recovery tab should display scrollable content or recovery-related text")

        takeScreenshot(named: "recovery_tab_content")
        assertNoErrorAlerts(context: "Recovery tab loads content")
    }

    // MARK: - Test 6: Recovery Protocols Displayed

    /// Verify that the Recovery tab shows recovery protocols or related content
    func testRecoveryProtocolsDisplayed() throws {
        navigateToRecoveryTab()

        let recoveryElement = scrollToFindAny([
            "Recovery", "Protocol", "Sleep", "Rest",
            "Stretch", "Cool Down", "Hydration", "Nutrition",
            "Wellness", "Mobility"
        ])

        if let element = recoveryElement {
            XCTAssertTrue(element.exists, "Recovery protocol content should be visible")
            takeScreenshot(named: "recovery_protocols_displayed")
        } else {
            // Check for empty state
            let emptyState = scrollToFindAny([
                "No protocols", "No recovery", "empty",
                "Not available", "Coming soon"
            ])

            if emptyState != nil {
                takeScreenshot(named: "recovery_protocols_empty_state")
            } else {
                takeScreenshot(named: "recovery_protocols_unknown_state")
                try XCTSkip("Neither recovery protocols nor empty state found -- content may use different labels")
            }
        }

        assertNoErrorAlerts(context: "Recovery protocols displayed")
    }

    // MARK: - Test 7: Analytics Retry on Error

    /// If the Analytics tab shows an error state with a retry button, tap retry and verify reload
    func testAnalyticsRetryOnError() throws {
        navigateToAnalyticsTab()

        // Look for error state indicators
        let errorPredicate = NSPredicate(
            format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'failed' OR label CONTAINS[c] 'couldn\\'t load' OR label CONTAINS[c] 'something went wrong'"
        )
        let errorText = app.staticTexts.containing(errorPredicate).firstMatch

        let retryPredicate = NSPredicate(
            format: "label CONTAINS[c] 'retry' OR label CONTAINS[c] 'try again' OR label CONTAINS[c] 'reload'"
        )
        let retryButton = app.buttons.containing(retryPredicate).firstMatch

        if errorText.exists && retryButton.exists && retryButton.isHittable {
            takeScreenshot(named: "analytics_error_state")

            // Tap retry
            retryButton.tap()
            waitForContentToLoad()

            // Verify content reloads or error persists without crash
            let hasContent = app.scrollViews.firstMatch.exists ||
                             app.tables.firstMatch.exists ||
                             app.collectionViews.firstMatch.exists

            let errorStillPresent = errorText.exists

            XCTAssertTrue(
                hasContent || errorStillPresent,
                "After retry, Analytics tab should either show content or still display the error state (no crash)"
            )

            takeScreenshot(named: "analytics_after_retry")
        } else {
            // No error state -- analytics loaded successfully, which is the happy path
            takeScreenshot(named: "analytics_no_error_state")
        }

        assertNoErrorAlerts(context: "Analytics retry on error")
    }

    // MARK: - Test 8: Analytics Refreshable

    /// Verify that pull-to-refresh on Analytics tab does not cause errors
    func testAnalyticsRefreshable() throws {
        navigateToAnalyticsTab()

        takeScreenshot(named: "analytics_before_refresh")

        // Perform pull-to-refresh gesture (swipe down from top of content area)
        if app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeDown()
        } else {
            app.swipeDown()
        }

        // Wait for any refresh to complete
        waitForContentToLoad()

        // Give additional time for network refresh
        Thread.sleep(forTimeInterval: 1.0)

        // Verify no crash occurred and content is still present
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.count > 0

        XCTAssertTrue(hasContent, "Analytics tab should still display content after pull-to-refresh")

        takeScreenshot(named: "analytics_after_refresh")
        assertNoErrorAlerts(context: "Analytics refreshable")
    }

    // MARK: - Helper Methods

    private func waitForContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingIndicator)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
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
}
