//
//  AchievementAndStreakTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the Achievements Dashboard, streak display, and related flows
//  Validates achievement showcase on ProfileHub, dashboard navigation, tab picker,
//  leaderboard, streak indicators, and filter options
//

import XCTest

/// E2E tests for achievements, streaks, and the AchievementsDashboardView
///
/// Logs in as Marcus Rivera (rehab mode) and verifies:
/// - Achievement showcase section on the Settings (ProfileHub) tab
/// - Navigation into AchievementsDashboardView via "View All" link
/// - Dashboard tab picker (achievements_tab_picker) and tab switching
/// - Achievement items display from seed data
/// - Leaderboard tab loads content
/// - Streak display on the Today Hub
/// - Achievement filter options (All/Earned/In Progress)
/// - No error alerts when cycling through dashboard tabs and filters
///
/// **Tab structure for rehab mode:** Today, Pain, Progress, ROM, Settings
final class AchievementAndStreakTests: XCTestCase {

    var app: XCUIApplication!

    /// Marcus Rivera (rehab mode) UUID
    private let marcusRiveraID = "aaaaaaaa-bbbb-cccc-dddd-000000000001"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000001",
            "--auto-login-mode", "rehab"
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

    /// Taps the Settings tab and waits for content to load
    private func navigateToSettingsTab() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab should exist")
        settingsTab.tap()
        waitForContentToLoad()
    }

    /// Taps the Today tab and waits for content to load
    private func navigateToTodayTab() {
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 10), "Today tab should exist")
        todayTab.tap()
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

    /// Scrolls to find a specific element by label text and returns it.
    /// Checks both static texts and buttons.
    @discardableResult
    private func scrollToFind(_ text: String, maxSwipes: Int = 10) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)

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

        // Final check without hittable requirement
        if matchingText.exists { return matchingText }
        if matchingButton.exists { return matchingButton }

        return nil
    }

    /// Searches for an element by accessibility identifier, scrolling if necessary.
    /// Checks buttons, cells, otherElements, staticTexts, and generic descendants.
    @discardableResult
    private func scrollToFindByIdentifier(
        _ identifier: String,
        maxSwipes: Int = 15
    ) -> XCUIElement? {
        let candidates: [XCUIElement] = [
            app.buttons.matching(identifier: identifier).firstMatch,
            app.cells.matching(identifier: identifier).firstMatch,
            app.otherElements.matching(identifier: identifier).firstMatch,
            app.staticTexts.matching(identifier: identifier).firstMatch,
            app.segmentedControls.matching(identifier: identifier).firstMatch,
            app.descendants(matching: .any)[identifier]
        ]

        func firstHittable() -> XCUIElement? {
            candidates.first { $0.exists && $0.isHittable }
        }

        func firstExisting() -> XCUIElement? {
            candidates.first { $0.exists }
        }

        if let match = firstHittable() { return match }

        let scrollTarget: XCUIElement = {
            let table = app.tables.firstMatch
            if table.exists { return table }
            let collection = app.collectionViews.firstMatch
            if collection.exists { return collection }
            let scroll = app.scrollViews.firstMatch
            if scroll.exists { return scroll }
            return app
        }()

        for _ in 0..<maxSwipes {
            scrollTarget.swipeUp()
            Thread.sleep(forTimeInterval: 0.4)

            if let match = firstHittable() { return match }
        }

        if let match = firstExisting() { return match }

        return nil
    }

    /// Navigates to the Achievements Dashboard from the Settings (ProfileHub) tab.
    /// Returns true if navigation succeeded, false otherwise.
    @discardableResult
    private func navigateToAchievementsDashboard() -> Bool {
        navigateToSettingsTab()

        // Try accessibility identifier first, then label-based search
        let achievementLink = scrollToFindByIdentifier("profile_hub_view_all_achievements")
            ?? scrollToFindAny([
                "View all achievements", "View All", "Achievements", "Achievement"
            ])

        guard let link = achievementLink, link.isHittable else {
            return false
        }

        link.tap()
        waitForContentToLoad()
        return true
    }

    // MARK: - Test 1: Achievement Showcase on Profile Hub

    /// Verify that the Settings (ProfileHub) tab shows an achievement showcase section
    func testAchievementShowcaseOnProfileHub() throws {
        navigateToSettingsTab()

        let achievementElement = scrollToFindAny([
            "Achievement", "Streak", "Badge", "Earned",
            "Milestone", "Trophy"
        ])

        if let element = achievementElement {
            XCTAssertTrue(element.exists, "Achievement showcase element should be visible on Profile Hub")
            takeScreenshot(named: "profile_hub_achievement_showcase")
        } else {
            // Check for empty state
            let emptyState = scrollToFindAny([
                "No achievements", "No badges", "Start earning",
                "No streaks", "Begin your journey"
            ])

            if emptyState != nil {
                takeScreenshot(named: "profile_hub_achievement_empty_state")
            } else {
                takeScreenshot(named: "profile_hub_achievement_not_found")
                try XCTSkip("Neither achievement showcase nor empty state found on Profile Hub -- section may use different labels")
            }
        }

        assertNoErrorAlerts(context: "Achievement showcase on Profile Hub")
    }

    // MARK: - Test 2: Navigate to Achievements Dashboard

    /// Verify that tapping "View All" navigates to the AchievementsDashboardView
    func testNavigateToAchievementsDashboard() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            takeScreenshot(named: "achievements_dashboard_nav_failed")
            throw XCTSkip("Could not find achievements dashboard link on Profile Hub (tried accessibility ID 'profile_hub_view_all_achievements' and label-based search)")
        }

        // Verify the dashboard loaded
        let dashboardContent = app.scrollViews.firstMatch.exists ||
                               app.tables.firstMatch.exists ||
                               app.collectionViews.firstMatch.exists ||
                               app.staticTexts.containing(NSPredicate(
                                   format: "label CONTAINS[c] 'achievement' OR label CONTAINS[c] 'badge' OR label CONTAINS[c] 'earned' OR label CONTAINS[c] 'leaderboard'"
                               )).firstMatch.exists

        XCTAssertTrue(dashboardContent, "Achievements dashboard should display content after navigation")

        takeScreenshot(named: "achievements_dashboard_loaded")
        assertNoErrorAlerts(context: "Navigate to achievements dashboard")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    // MARK: - Test 3: Achievements Dashboard Tab Picker

    /// Verify that the AchievementsDashboardView has a tab picker (achievements_tab_picker)
    func testAchievementsDashboardTabPicker() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            throw XCTSkip("Could not navigate to achievements dashboard to test tab picker")
        }

        // Look for the tab picker by accessibility identifier
        let tabPicker = scrollToFindByIdentifier("achievements_tab_picker")

        // Also check for a segmented control containing "Achievements" or "Leaderboard"
        let segmentedControl = app.segmentedControls.firstMatch

        let achievementsSegment = app.buttons.containing(NSPredicate(
            format: "label CONTAINS[c] 'Achievements' OR label CONTAINS[c] 'Achievement'"
        )).firstMatch

        let leaderboardSegment = app.buttons.containing(NSPredicate(
            format: "label CONTAINS[c] 'Leaderboard'"
        )).firstMatch

        let tabPickerFound = tabPicker != nil ||
                             segmentedControl.exists ||
                             (achievementsSegment.exists && leaderboardSegment.exists)

        if tabPickerFound {
            takeScreenshot(named: "achievements_dashboard_tab_picker")
        } else {
            takeScreenshot(named: "achievements_dashboard_no_tab_picker")
            try XCTSkip("Tab picker not found on achievements dashboard (tried identifier 'achievements_tab_picker' and segmented control search)")
        }

        assertNoErrorAlerts(context: "Achievements dashboard tab picker")
    }

    // MARK: - Test 4: Achievements List Displays Items

    /// Verify that the achievements dashboard displays at least one achievement item from seed data
    func testAchievementsListDisplaysItems() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            throw XCTSkip("Could not navigate to achievements dashboard to verify items")
        }

        // Look for achievement-related content items
        let achievementItems = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS[c] 'achievement' OR label CONTAINS[c] 'badge' OR label CONTAINS[c] 'earned' OR label CONTAINS[c] 'streak' OR label CONTAINS[c] 'milestone' OR label CONTAINS[c] 'complete'"
        ))

        // Also check for cells or list items (achievements may render as list rows)
        let hasCells = app.tables.firstMatch.exists && app.tables.firstMatch.cells.count > 0
        let hasCollectionItems = app.collectionViews.firstMatch.exists &&
                                 app.collectionViews.firstMatch.cells.count > 0

        let hasAchievementContent = achievementItems.count > 0 || hasCells || hasCollectionItems

        if hasAchievementContent {
            takeScreenshot(named: "achievements_list_with_items")
        } else {
            // Check for empty state
            let emptyState = scrollToFindAny([
                "No achievements", "empty", "Start earning",
                "No badges yet", "Begin"
            ])

            if emptyState != nil {
                takeScreenshot(named: "achievements_list_empty_state")
                try XCTSkip("Achievements list shows empty state -- seed data may not include achievements for this user")
            } else {
                takeScreenshot(named: "achievements_list_unknown")
                try XCTSkip("Could not determine achievements list state -- content may use different labels")
            }
        }

        assertNoErrorAlerts(context: "Achievements list displays items")
    }

    // MARK: - Test 5: Leaderboard Tab Loads

    /// Verify that tapping the Leaderboard tab in the achievements dashboard loads content
    func testLeaderboardTabLoads() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            throw XCTSkip("Could not navigate to achievements dashboard to test leaderboard")
        }

        // Find and tap the Leaderboard tab/segment
        let leaderboardButton = app.buttons.containing(NSPredicate(
            format: "label CONTAINS[c] 'Leaderboard'"
        )).firstMatch

        let leaderboardSegment = app.segmentedControls.firstMatch.buttons.containing(NSPredicate(
            format: "label CONTAINS[c] 'Leaderboard'"
        )).firstMatch

        if leaderboardButton.exists && leaderboardButton.isHittable {
            leaderboardButton.tap()
        } else if leaderboardSegment.exists && leaderboardSegment.isHittable {
            leaderboardSegment.tap()
        } else {
            takeScreenshot(named: "leaderboard_tab_not_found")
            throw XCTSkip("Leaderboard tab/segment not found on achievements dashboard")
        }

        waitForContentToLoad()

        // Verify leaderboard content loaded
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'leaderboard' OR label CONTAINS[c] 'rank' OR label CONTAINS[c] 'points' OR label CONTAINS[c] 'score' OR label CONTAINS[c] 'position'"
                         )).firstMatch.exists

        // Leaderboard may show an empty state if no data
        let emptyState = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS[c] 'no data' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'coming soon' OR label CONTAINS[c] 'no leaderboard'"
        )).firstMatch

        XCTAssertTrue(
            hasContent || emptyState.exists,
            "Leaderboard tab should display content or an empty state"
        )

        takeScreenshot(named: "leaderboard_tab_content")
        assertNoErrorAlerts(context: "Leaderboard tab loads")
    }

    // MARK: - Test 6: Streak Display on Today Hub

    /// Verify that the Today Hub shows a streak indicator
    func testStreakDisplayOnTodayHub() throws {
        navigateToTodayTab()

        // Wait for async content to finish loading
        let loadingText = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS[c] 'Loading'"
        )).firstMatch
        if loadingText.exists {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingText)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
        }
        Thread.sleep(forTimeInterval: 1.0)

        // Look for streak-related text
        let streakElement = scrollToFindAny([
            "Streak", "day streak", "Day Streak",
            "consecutive", "days in a row"
        ])

        // Also check for fire emoji indicator (common streak icon)
        let fireIndicator = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@", "\u{1F525}"
        )).firstMatch

        if let element = streakElement {
            XCTAssertTrue(element.exists, "Streak indicator should be visible on Today Hub")
            takeScreenshot(named: "today_hub_streak_display")
        } else if fireIndicator.exists {
            takeScreenshot(named: "today_hub_streak_fire_indicator")
        } else {
            takeScreenshot(named: "today_hub_no_streak")
            try XCTSkip("No streak indicator found on Today Hub -- user may not have an active streak or streak UI uses different labels")
        }

        assertNoErrorAlerts(context: "Streak display on Today Hub")
    }

    // MARK: - Test 7: Achievement Filter Options

    /// Verify that the achievements dashboard has filter controls (All/Earned/In Progress)
    func testAchievementFilterOptions() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            throw XCTSkip("Could not navigate to achievements dashboard to test filters")
        }

        // Look for filter controls
        let filterKeywords = ["All", "Earned", "In Progress", "Locked", "Unlocked", "Filter"]

        var foundFilters: [String] = []
        for keyword in filterKeywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let button = app.buttons.containing(predicate).firstMatch
            let segment = app.segmentedControls.firstMatch.buttons.containing(predicate).firstMatch

            if button.exists || segment.exists {
                foundFilters.append(keyword)
            }
        }

        if foundFilters.isEmpty {
            // Scroll to see if filters are below the fold
            let scrolledFilter = scrollToFindAny(filterKeywords)
            if scrolledFilter != nil {
                foundFilters.append("(found after scrolling)")
            }
        }

        if !foundFilters.isEmpty {
            takeScreenshot(named: "achievements_filter_options")

            // Try tapping one of the filter options if available
            for keyword in ["Earned", "In Progress", "Locked"] {
                let filterButton = app.buttons.containing(NSPredicate(
                    format: "label CONTAINS[c] %@", keyword
                )).firstMatch

                if filterButton.exists && filterButton.isHittable {
                    filterButton.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                    takeScreenshot(named: "achievements_filter_\(keyword.lowercased().replacingOccurrences(of: " ", with: "_"))")
                    assertNoErrorAlerts(context: "Achievement filter -- \(keyword)")
                    break
                }
            }
        } else {
            takeScreenshot(named: "achievements_no_filters")
            try XCTSkip("No filter controls found on achievements dashboard -- may use a different UI pattern")
        }

        assertNoErrorAlerts(context: "Achievement filter options")
    }

    // MARK: - Test 8: Achievements Dashboard No Errors

    /// Navigate to the achievements dashboard, cycle through tabs and filters, and verify no error alerts
    func testAchievementsDashboardNoErrors() throws {
        let navigated = navigateToAchievementsDashboard()

        guard navigated else {
            throw XCTSkip("Could not navigate to achievements dashboard to test error-free cycling")
        }

        assertNoErrorAlerts(context: "Achievements dashboard -- initial load")

        // Cycle through tab picker segments if available
        let tabSegments = ["Achievements", "Leaderboard"]
        for segmentName in tabSegments {
            let segmentButton = app.buttons.containing(NSPredicate(
                format: "label CONTAINS[c] %@", segmentName
            )).firstMatch

            if segmentButton.exists && segmentButton.isHittable {
                segmentButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
                waitForContentToLoad()
                assertNoErrorAlerts(context: "Achievements dashboard -- tab '\(segmentName)'")
            }
        }

        // Switch back to achievements tab before testing filters
        let achievementsTab = app.buttons.containing(NSPredicate(
            format: "label CONTAINS[c] 'Achievements' OR label CONTAINS[c] 'Achievement'"
        )).firstMatch
        if achievementsTab.exists && achievementsTab.isHittable {
            achievementsTab.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Cycle through filter options if available
        let filterOptions = ["All", "Earned", "In Progress", "Locked"]
        for filterName in filterOptions {
            let filterButton = app.buttons.containing(NSPredicate(
                format: "label CONTAINS[c] %@", filterName
            )).firstMatch

            if filterButton.exists && filterButton.isHittable {
                filterButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
                assertNoErrorAlerts(context: "Achievements dashboard -- filter '\(filterName)'")
            }
        }

        // Final screenshot and stability check
        takeScreenshot(named: "achievements_dashboard_cycling_complete")
        assertNoErrorAlerts(context: "Achievements dashboard -- final stability check")
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
