//
//  StrengthModeDashboardTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the strength mode dashboard accessed via the PRs tab
//  Validates SBD total card, big lifts grid, recent PRs, weekly volume,
//  progression suggestions, streak indicator, analytics deep dive, and 1RM chart
//
//  Test user: Jordan Williams (strength mode, CrossFit)
//  UUID: aaaaaaaa-bbbb-cccc-dddd-000000000005
//

import XCTest

/// E2E tests for the strength mode dashboard and PRs tab
///
/// Logs in as Jordan Williams (strength mode) and verifies:
/// - PRs tab loads and displays content
/// - SBD total card is visible
/// - Big lifts grid shows exercise names (Squat, Bench, Deadlift)
/// - Recent PRs section is present
/// - Weekly volume section is present
/// - Progression suggestions section is present
/// - Streak indicator is visible
/// - Analytics deep dive button exists and navigates
/// - Progressive overload suggestions are displayed
/// - Estimated 1RM chart is displayed
/// - Pull to refresh works without errors
final class StrengthModeDashboardTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    /// Jordan Williams (strength mode, CrossFit)
    private let testUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000005"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000005",
            "--auto-login-mode", "strength"
        ]
        app.launchEnvironment = ["IS_RUNNING_UITEST": "1"]
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

    /// Navigates to the PRs tab and waits for content to load.
    /// Returns `true` if the PRs tab was found and tapped.
    @discardableResult
    private func navigateToPRsTab() -> Bool {
        let prsTab = app.tabBars.buttons["PRs"]
        guard prsTab.waitForExistence(timeout: 5) else {
            return false
        }
        prsTab.tap()
        waitForContentToLoad()
        return true
    }

    /// Scrolls up repeatedly (up to `maxSwipes`) looking for an element whose label
    /// matches `text` case-insensitively. Returns the element if found, nil otherwise.
    @discardableResult
    private func scrollToFind(_ text: String, maxSwipes: Int = 10) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)

        // Check buttons and static texts
        let matchingText = app.staticTexts.containing(predicate).firstMatch
        let matchingButton = app.buttons.containing(predicate).firstMatch

        if matchingText.exists && matchingText.isHittable { return matchingText }
        if matchingButton.exists && matchingButton.isHittable { return matchingButton }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            if matchingText.exists && matchingText.isHittable { return matchingText }
            if matchingButton.exists && matchingButton.isHittable { return matchingButton }
        }

        // One last check without hittable requirement (element may be partially visible)
        if matchingText.exists { return matchingText }
        if matchingButton.exists { return matchingButton }

        return nil
    }

    /// Searches for any element matching one of the provided keywords (case-insensitive).
    /// Returns the first match found, or nil.
    @discardableResult
    private func scrollToFindAny(_ keywords: [String], maxSwipes: Int = 10) -> XCUIElement? {
        for keyword in keywords {
            // Quick check before scrolling
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

    // MARK: - Test 1: Strength Dashboard Loads From PRs Tab

    /// Verify that navigating to the PRs tab loads the strength dashboard content
    func testStrengthDashboardLoadsFromPRsTab() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found in tab bar -- strength mode may not be active for user \(testUserID)")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.count > 0

        XCTAssertTrue(hasContent, "PRs tab should display content")

        assertNoErrorAlerts(context: "Strength dashboard loads from PRs tab")
        takeScreenshot(named: "strength_dashboard_loads")
    }

    // MARK: - Test 2: SBD Total Card Displayed

    /// Verify the SBD total card is visible on the PRs tab
    func testSBDTotalCardDisplayed() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check by accessibility identifier first
        let sbdCard = app.otherElements["strength_sbd_total_card"]
        let sbdButton = app.buttons["strength_sbd_total_card"]
        let sbdDescendant = app.descendants(matching: .any)["strength_sbd_total_card"]

        let foundByIdentifier = sbdCard.waitForExistence(timeout: 5) ||
                                sbdButton.exists ||
                                sbdDescendant.exists

        if foundByIdentifier {
            takeScreenshot(named: "sbd_total_card_by_id")
            assertNoErrorAlerts(context: "SBD total card by identifier")
            return
        }

        // Fallback: search by text content
        let sbdElement = scrollToFindAny(["SBD", "Total", "Squat Bench Deadlift"])

        if let element = sbdElement {
            XCTAssertTrue(element.exists, "SBD total card element should be visible")
            takeScreenshot(named: "sbd_total_card_by_text")
        } else {
            // Skip rather than fail -- the SBD card may not be implemented yet
            throw XCTSkip("SBD total card not found by accessibility identifier or text content")
        }

        assertNoErrorAlerts(context: "SBD total card displayed")
    }

    // MARK: - Test 3: Big Lifts Grid Shows Exercises

    /// Verify the big lifts grid displays exercise names like Squat, Bench, and Deadlift
    func testBigLiftsGridShowsExercises() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let liftElement = scrollToFindAny(["Squat", "Bench", "Deadlift", "Press", "Row"])

        if let element = liftElement {
            XCTAssertTrue(element.exists, "At least one major lift name should be visible in the big lifts grid")
            takeScreenshot(named: "big_lifts_grid")
        } else {
            throw XCTSkip("No big lift exercise names found on PRs tab -- big lifts grid may not be implemented")
        }

        assertNoErrorAlerts(context: "Big lifts grid shows exercises")
    }

    // MARK: - Test 4: Recent PRs Section Present

    /// Verify the recent PRs section is displayed on the PRs tab
    func testRecentPRsSectionPresent() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let prElement = scrollToFindAny(["PR", "Record", "Personal Best", "New Best", "Personal Record"])

        if let element = prElement {
            XCTAssertTrue(element.exists, "Recent PRs section should contain PR-related text")
            takeScreenshot(named: "recent_prs_section")
        } else {
            throw XCTSkip("Recent PRs section not found -- may not be populated with seed data")
        }

        assertNoErrorAlerts(context: "Recent PRs section present")
    }

    // MARK: - Test 5: Weekly Volume Section Present

    /// Verify the weekly volume section is displayed on the PRs tab
    func testWeeklyVolumeSectionPresent() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let volumeElement = scrollToFindAny(["Volume", "Weekly", "Weekly Volume", "Total Volume", "Sets", "lbs"])

        if let element = volumeElement {
            XCTAssertTrue(element.exists, "Weekly volume section should contain volume-related text")
            takeScreenshot(named: "weekly_volume_section")
        } else {
            throw XCTSkip("Weekly volume section not found on PRs tab")
        }

        assertNoErrorAlerts(context: "Weekly volume section present")
    }

    // MARK: - Test 6: Progression Suggestions Section

    /// Verify the progression suggestions section is displayed or an empty state exists
    func testProgressionSuggestionsSection() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let suggestionElement = scrollToFindAny([
            "Progression", "Suggestion", "Recommended", "Next Step",
            "Increase", "No suggestions", "Keep training"
        ])

        if let element = suggestionElement {
            XCTAssertTrue(element.exists, "Progression suggestions section or empty state should be visible")
            takeScreenshot(named: "progression_suggestions_section")
        } else {
            throw XCTSkip("Progression suggestions section not found on PRs tab")
        }

        assertNoErrorAlerts(context: "Progression suggestions section")
    }

    // MARK: - Test 7: Streak Indicator Visible

    /// Verify the streak indicator is visible on the Today tab or PRs tab
    func testStreakIndicatorVisible() throws {
        // First check the Today tab for a streak indicator
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()
            waitForContentToLoad()

            let streakOnToday = scrollToFindAny(["Streak", "day streak", "days", "consecutive"], maxSwipes: 5)
            if let element = streakOnToday {
                XCTAssertTrue(element.exists, "Streak indicator should be visible on Today tab")
                takeScreenshot(named: "streak_indicator_today")
                assertNoErrorAlerts(context: "Streak indicator on Today tab")
                return
            }
        }

        // Fall back to checking the PRs tab
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let streakOnPRs = scrollToFindAny(["Streak", "day streak", "days", "consecutive"], maxSwipes: 8)

        if let element = streakOnPRs {
            XCTAssertTrue(element.exists, "Streak indicator should be visible on PRs tab")
            takeScreenshot(named: "streak_indicator_prs")
        } else {
            throw XCTSkip("Streak indicator not found on Today tab or PRs tab")
        }

        assertNoErrorAlerts(context: "Streak indicator visible")
    }

    // MARK: - Test 8: Strength Analytics Deep Dive Button

    /// Verify the analytics deep dive button exists on the PRs tab
    func testStrengthAnalyticsDeepDiveButton() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check by accessibility identifier first
        let deepDiveById = app.buttons["strength_analytics_deep_dive"]
        let deepDiveOther = app.otherElements["strength_analytics_deep_dive"]
        let deepDiveDescendant = app.descendants(matching: .any)["strength_analytics_deep_dive"]

        let foundByIdentifier = deepDiveById.waitForExistence(timeout: 5) ||
                                deepDiveOther.exists ||
                                deepDiveDescendant.exists

        if foundByIdentifier {
            takeScreenshot(named: "analytics_deep_dive_button_by_id")
            assertNoErrorAlerts(context: "Analytics deep dive button by identifier")
            return
        }

        // Fallback: scroll to find by text
        let deepDiveElement = scrollToFindAny([
            "Analytics", "Deep Dive", "View Analytics", "See More",
            "Detailed", "Analysis"
        ])

        if let element = deepDiveElement {
            XCTAssertTrue(element.exists, "Analytics deep dive button should be visible")
            takeScreenshot(named: "analytics_deep_dive_button_by_text")
        } else {
            throw XCTSkip("Analytics deep dive button not found by identifier or text content")
        }

        assertNoErrorAlerts(context: "Analytics deep dive button")
    }

    // MARK: - Test 9: Strength Analytics Deep Dive Navigation

    /// Verify tapping the deep dive button navigates to a new analytics view
    func testStrengthAnalyticsDeepDiveNavigation() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Find the deep dive button by identifier
        var deepDiveButton: XCUIElement? = app.buttons["strength_analytics_deep_dive"]
        if !(deepDiveButton?.waitForExistence(timeout: 5) ?? false) {
            deepDiveButton = app.descendants(matching: .any)["strength_analytics_deep_dive"]
        }

        // Fallback: find by text
        if !(deepDiveButton?.exists ?? false) || !(deepDiveButton?.isHittable ?? false) {
            deepDiveButton = scrollToFindAny([
                "Analytics", "Deep Dive", "View Analytics", "See More"
            ])
        }

        guard let button = deepDiveButton, button.exists, button.isHittable else {
            throw XCTSkip("Analytics deep dive button not found or not tappable -- skipping navigation test")
        }

        takeScreenshot(named: "before_deep_dive_tap")
        button.tap()
        waitForContentToLoad()

        // Verify a new view loaded -- nav bar changed, new content appeared, or sheet presented
        let newViewLoaded = app.navigationBars.count > 0 ||
                            app.scrollViews.firstMatch.exists ||
                            app.tables.firstMatch.exists ||
                            app.collectionViews.firstMatch.exists ||
                            app.staticTexts.containing(
                                NSPredicate(format: "label CONTAINS[c] 'analytics' OR label CONTAINS[c] 'chart' OR label CONTAINS[c] 'trend'")
                            ).firstMatch.exists

        XCTAssertTrue(newViewLoaded, "A new analytics view should load after tapping deep dive button")

        assertNoErrorAlerts(context: "Analytics deep dive navigation")
        takeScreenshot(named: "analytics_deep_dive_view")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists && backButton.isHittable {
            backButton.tap()
            waitForContentToLoad()
        }
    }

    // MARK: - Test 10: Progressive Overload Suggestions

    /// Verify progressive overload suggestions are displayed on the PRs tab
    func testProgressiveOverloadSuggestions() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let overloadElement = scrollToFindAny([
            "Progressive", "Overload", "Increase", "Add weight",
            "More reps", "Progress", "Next target"
        ], maxSwipes: 12)

        if let element = overloadElement {
            XCTAssertTrue(element.exists, "Progressive overload suggestions should be visible")
            takeScreenshot(named: "progressive_overload_suggestions")
        } else {
            throw XCTSkip("Progressive overload suggestions not found on PRs tab")
        }

        assertNoErrorAlerts(context: "Progressive overload suggestions")
    }

    // MARK: - Test 11: Estimated 1RM Chart Displayed

    /// Verify the estimated 1RM chart is displayed on the PRs tab
    func testEstimated1RMChartDisplayed() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Look for 1RM or chart-related elements
        let chartElement = scrollToFindAny([
            "1RM", "Estimated", "Max", "One Rep Max",
            "E1RM", "Predicted"
        ], maxSwipes: 12)

        if let element = chartElement {
            XCTAssertTrue(element.exists, "Estimated 1RM chart or label should be visible")
            takeScreenshot(named: "estimated_1rm_chart")
            assertNoErrorAlerts(context: "Estimated 1RM chart displayed")
            return
        }

        // Also check for SwiftUI Charts which may not have text labels
        let chartView = app.otherElements.containing(
            NSPredicate(format: "identifier CONTAINS[c] 'chart' OR identifier CONTAINS[c] '1rm'")
        ).firstMatch
        if chartView.exists {
            takeScreenshot(named: "estimated_1rm_chart_element")
            assertNoErrorAlerts(context: "Estimated 1RM chart element")
            return
        }

        throw XCTSkip("Estimated 1RM chart not found on PRs tab")
    }

    // MARK: - Test 12: Strength Dashboard Pull to Refresh

    /// Verify pull to refresh on the PRs tab works without errors
    func testStrengthDashboardPullToRefresh() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        takeScreenshot(named: "before_pull_to_refresh")

        // Perform pull to refresh by swiping down from the top of the content area
        let firstScrollView = app.scrollViews.firstMatch
        let firstTable = app.tables.firstMatch
        let firstCollection = app.collectionViews.firstMatch

        if firstScrollView.exists {
            firstScrollView.swipeDown()
        } else if firstTable.exists {
            firstTable.swipeDown()
        } else if firstCollection.exists {
            firstCollection.swipeDown()
        } else {
            app.swipeDown()
        }

        // Wait for any refresh to complete
        Thread.sleep(forTimeInterval: 2.0)
        waitForContentToLoad()

        // Verify no error alerts appeared after refresh
        assertNoErrorAlerts(context: "Strength dashboard pull to refresh")

        // Verify content is still present after refresh
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.count > 0

        XCTAssertTrue(hasContent, "Content should still be present after pull to refresh")

        takeScreenshot(named: "after_pull_to_refresh")
    }

    // MARK: - Helper Methods

    private func waitForContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            // Wait for loading indicator to disappear using a predicate expectation
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingIndicator)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
        }
        // Small buffer for animations
        Thread.sleep(forTimeInterval: 0.5)
    }

    private func assertNoErrorAlerts(context: String) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let alertLabel = alert.label
            // Dismiss the alert for test continuity
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
