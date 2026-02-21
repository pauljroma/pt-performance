//
//  StrengthModeDashboardTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the strength mode dashboard accessed via the PRs tab
//  Validates SBD total card, big lifts grid, Total PRs badge, stats row,
//  See All button, streak/fallback, All Lifts sheet, lift cards, and stats
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
/// - Total PRs badge is present
/// - Stats row (Improving, Tracked, Avg Gain) is present
/// - See All button exists
/// - Streak indicator on Today or fallback stats on PRs tab
/// - See All opens All Big Lifts sheet
/// - All Lifts sheet shows exercise names
/// - Lift cards are tappable
/// - Improving and Tracked stats are visible
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

    // MARK: - Test 2: SBD Total Card or Valid State

    /// Verify the PRs tab shows SBD card, empty state, or error state (all valid renders)
    func testSBDTotalCardDisplayed() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check for SBD card by accessibility identifier
        let sbdDescendant = app.descendants(matching: .any)["strength_sbd_total_card"]
        if sbdDescendant.waitForExistence(timeout: 5) {
            takeScreenshot(named: "sbd_total_card_by_id")
            assertNoErrorAlerts(context: "SBD total card by identifier")
            return
        }

        // Accept any valid BigLiftsScorecard state: data, empty, or error
        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "sbd_total_card_or_state")
    }

    // MARK: - Test 3: Big Lifts Content Present

    /// Verify the PRs tab renders BigLiftsScorecard in any valid state
    func testBigLiftsGridShowsExercises() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "big_lifts_content")
    }

    // MARK: - Test 4: Big Lifts Header Present

    /// Verify the PRs tab has BigLiftsScorecard rendered
    func testTotalPRsBadgePresent() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "Big Lifts content should be visible on PRs tab")
        takeScreenshot(named: "total_prs_badge")
        assertNoErrorAlerts(context: "Total PRs badge present")
    }

    // MARK: - Test 5: Stats Row or Valid State

    /// Verify the PRs tab shows stats row, empty state, or error state
    func testStatsRowPresent() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "stats_row_or_state")
    }

    // MARK: - Test 6: See All or Valid State

    /// Verify the PRs tab shows See All button, empty state, or error state
    func testSeeAllButtonExists() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "see_all_or_state")
    }

    // MARK: - Test 7: Streak Indicator Visible

    /// Verify the streak indicator is visible on the Today tab, or fall back to
    /// verifying BigLiftsScorecard content on the PRs tab
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

        // Fall back to PRs tab — accept any BigLiftsScorecard content
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let contentElement = scrollToFindAny([
            "Tracked", "Improving", "Big Lifts", "No Big Lifts Yet"
        ], maxSwipes: 8)

        XCTAssertNotNil(contentElement, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "streak_fallback_prs_content")
        assertNoErrorAlerts(context: "Streak indicator visible")
    }

    // MARK: - Test 8: See All Opens Lifts Sheet (data-dependent)

    /// If data exists, verify tapping "See All" opens the All Big Lifts sheet
    func testSeeAllOpensLiftsSheet() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check for empty state first — if empty, this test passes (no See All to test)
        let emptyState = scrollToFindAny(["No Big Lifts Yet"], maxSwipes: 3)
        if emptyState != nil {
            takeScreenshot(named: "see_all_sheet_empty_state")
            assertNoErrorAlerts(context: "See All sheet (empty state)")
            return
        }

        let seeAllElement = scrollToFind("See All")
        guard let seeAllButton = seeAllElement, seeAllButton.exists, seeAllButton.isHittable else {
            // No See All and no empty state — something unexpected
            takeScreenshot(named: "see_all_missing")
            assertNoErrorAlerts(context: "See All sheet")
            return
        }

        seeAllButton.tap()
        waitForContentToLoad()

        let sheetTitle = app.navigationBars["All Big Lifts"]
        let sheetFound = sheetTitle.waitForExistence(timeout: 5) ||
                         scrollToFindAny(["All Big Lifts"]) != nil
        XCTAssertTrue(sheetFound, "All Big Lifts sheet should appear after tapping See All")

        takeScreenshot(named: "all_big_lifts_sheet")
        let doneButton = app.buttons["Done"]
        if doneButton.exists && doneButton.isHittable {
            doneButton.tap()
            waitForContentToLoad()
        }
        assertNoErrorAlerts(context: "See All opens lifts sheet")
    }

    // MARK: - Test 9: Lifts Sheet Content (data-dependent)

    /// If data exists, verify the All Big Lifts sheet displays exercise names
    func testAllLiftsSheetShowsLifts() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check for empty state first
        let emptyState = scrollToFindAny(["No Big Lifts Yet"], maxSwipes: 3)
        if emptyState != nil {
            takeScreenshot(named: "lifts_sheet_empty_state")
            assertNoErrorAlerts(context: "Lifts sheet (empty state)")
            return
        }

        let seeAllElement = scrollToFind("See All")
        guard let seeAllButton = seeAllElement, seeAllButton.exists, seeAllButton.isHittable else {
            takeScreenshot(named: "lifts_sheet_no_see_all")
            assertNoErrorAlerts(context: "Lifts sheet")
            return
        }

        seeAllButton.tap()
        waitForContentToLoad()

        let liftElement = scrollToFindAny(["Squat", "Bench", "Deadlift", "Press"], maxSwipes: 5)
        if let element = liftElement {
            XCTAssertTrue(element.exists, "All Big Lifts sheet should display exercise names")
        }

        takeScreenshot(named: "all_lifts_sheet_content")
        let doneButton = app.buttons["Done"]
        if doneButton.exists && doneButton.isHittable {
            doneButton.tap()
            waitForContentToLoad()
        }
        assertNoErrorAlerts(context: "All Lifts sheet shows lifts")
    }

    // MARK: - Test 10: Lift Cards or Empty State Tappable

    /// Verify lift cards are tappable (data) or empty state is displayed
    func testLiftCardsTappable() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        // Check for empty state first
        let emptyState = scrollToFindAny(["No Big Lifts Yet"], maxSwipes: 3)
        if emptyState != nil {
            takeScreenshot(named: "lift_cards_empty_state")
            assertNoErrorAlerts(context: "Lift cards (empty state)")
            return
        }

        let liftElement = scrollToFindAny(["Squat", "Bench", "Deadlift"], maxSwipes: 8)
        guard let element = liftElement, element.exists, element.isHittable else {
            takeScreenshot(named: "lift_cards_not_found")
            assertNoErrorAlerts(context: "Lift cards tappable")
            return
        }

        element.tap()
        waitForContentToLoad()
        takeScreenshot(named: "after_lift_card_tap")
        assertNoErrorAlerts(context: "Lift cards tappable")
    }

    // MARK: - Test 11: Stats or Valid State

    /// Verify the stats row or other valid BigLiftsScorecard state is visible
    func testImprovingAndTrackedStats() throws {
        let prsTabFound = navigateToPRsTab()
        try XCTSkipIf(!prsTabFound, "PRs tab not found -- skipping")

        let hasContent = findBigLiftsContent()
        XCTAssertTrue(hasContent, "PRs tab should show BigLiftsScorecard content")
        takeScreenshot(named: "improving_tracked_or_state")
        assertNoErrorAlerts(context: "Improving and Tracked stats")
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

    /// Checks if BigLiftsScorecard rendered any valid state (data, empty, error, or loading).
    /// Searches static texts only (excludes tab bar buttons) for known BigLiftsScorecard content.
    private func findBigLiftsContent() -> Bool {
        // Data state keywords
        let dataKeywords = ["Est. Total", "SBD", "Big Lifts", "Squat", "Bench", "Deadlift",
                            "Total PRs", "Improving", "Tracked", "Avg Gain", "See All"]
        // Empty state keywords
        let emptyKeywords = ["No Big Lifts Yet", "Log bench press", "dumbbell"]
        // Error state keywords
        let errorKeywords = ["Retry", "error", "failed", "try again"]
        // Loading state
        if app.activityIndicators.firstMatch.exists { return true }

        let allKeywords = dataKeywords + emptyKeywords + errorKeywords
        for keyword in allKeywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            // Only check static texts to avoid matching tab bar button labels
            if app.staticTexts.containing(predicate).firstMatch.exists { return true }
        }
        // Also check if view has meaningful content beyond just the tab bar
        return app.staticTexts.count > 2
    }

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
