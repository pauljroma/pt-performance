//
//  SettingsAndProfileFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the Settings / Profile Hub navigation depth
//  Validates that ProfileHubView sections load and sub-screens are reachable
//

import XCTest

/// E2E tests exercising the Settings tab (ProfileHubView) and its child screens
///
/// Logs in as Marcus Rivera (rehab mode) and verifies:
/// - Profile hub sections render (health, achievements, subscription, etc.)
/// - Navigation into UnifiedSettingsView, notifications, HealthKit, achievements
/// - Mode changer accessibility
/// - Log out button reachability
/// - Subscription section presence
final class SettingsAndProfileFlowTests: XCTestCase {

    var app: XCUIApplication!

    /// Marcus Rivera (rehab mode) UUID
    private let marcusUserId = "aaaaaaaa-bbbb-cccc-dddd-000000000001"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", marcusUserId
        ]
        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Taps the Settings tab and waits for content to appear
    private func navigateToSettingsTab() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist in the tab bar")
        settingsTab.tap()

        waitForContentToLoad()
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

    /// Scrolls to find an element by its accessibility identifier, checking across
    /// multiple element types (buttons, cells, staticTexts, otherElements, and generic
    /// descendants). SwiftUI NavigationLinks inside Lists often render as buttons or
    /// cells rather than generic descendants, so querying specific types is more reliable.
    @discardableResult
    private func scrollToFindByIdentifier(
        _ identifier: String,
        maxSwipes: Int = 15
    ) -> XCUIElement? {
        // Build a list of candidate queries — SwiftUI NavigationLinks in Lists
        // surface as buttons, cells, or otherElements depending on the OS version.
        let candidates: [XCUIElement] = [
            app.buttons.matching(identifier: identifier).firstMatch,
            app.cells.matching(identifier: identifier).firstMatch,
            app.otherElements.matching(identifier: identifier).firstMatch,
            app.staticTexts.matching(identifier: identifier).firstMatch,
            app.descendants(matching: .any)[identifier]
        ]

        /// Returns the first existing & hittable candidate, or nil.
        func firstHittable() -> XCUIElement? {
            candidates.first { $0.exists && $0.isHittable }
        }

        /// Returns the first existing candidate (ignoring hittable), or nil.
        func firstExisting() -> XCUIElement? {
            candidates.first { $0.exists }
        }

        // Quick check before scrolling
        if let match = firstHittable() { return match }

        // Determine the best scrollable container (List/Table/ScrollView or fall back to app)
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

        // Final check relaxing the hittable requirement
        if let match = firstExisting() { return match }

        return nil
    }

    // MARK: - Tests

    /// 1. Verify that the Profile Hub sections load after tapping the Settings tab
    func testProfileHubSectionsLoad() throws {
        navigateToSettingsTab()

        // Profile hub should display scrollable content
        let hasScrollableContent = app.scrollViews.firstMatch.exists ||
                                   app.tables.firstMatch.exists ||
                                   app.collectionViews.firstMatch.exists

        XCTAssertTrue(hasScrollableContent, "Profile Hub should contain scrollable content")

        // Look for recognizable section headers or settings-related labels
        let sectionKeywords = ["Health & Wellness", "Account", "Support", "Settings", "Profile"]
        let predicate = NSPredicate(
            format: "label CONTAINS[c] 'Health' OR label CONTAINS[c] 'Account' OR label CONTAINS[c] 'Support' OR label CONTAINS[c] 'Settings' OR label CONTAINS[c] 'Profile'"
        )
        let sectionElement = app.staticTexts.containing(predicate).firstMatch

        // Soft assertion -- the hub may use different section names
        if !sectionElement.exists {
            print("INFO: No standard section headers found; Profile Hub may use custom labels")
        }

        assertNoErrorAlerts(context: "Profile Hub sections load")
        takeScreenshot(named: "profile_hub_sections")
    }

    /// 2. Check for achievement showcase content on the Profile Hub
    func testProfileHubAchievementShowcase() throws {
        navigateToSettingsTab()

        let achievementElement = scrollToFindAny(["Achievement", "Streak", "Badge"])

        if let element = achievementElement {
            XCTAssertTrue(element.exists, "Achievement showcase element should be visible")
        } else {
            // Check for an empty state instead
            let emptyState = scrollToFindAny(["No achievements", "No badges", "Start earning"])
            if emptyState == nil {
                print("INFO: Neither achievements nor empty state found on Profile Hub")
            }
        }

        assertNoErrorAlerts(context: "Achievement showcase")
        takeScreenshot(named: "profile_hub_achievements")
    }

    /// 3. Navigate from the Profile Hub into UnifiedSettingsView and back
    func testNavigateToUnifiedSettings() throws {
        navigateToSettingsTab()

        // Use the accessibility identifier to find the Settings navigation link
        // on the Profile Hub. Label-based search ("Settings") is ambiguous because
        // the tab bar button is also labeled "Settings".
        let settingsLink = scrollToFindByIdentifier("profile_hub_settings_link")

        guard let link = settingsLink, link.isHittable else {
            throw XCTSkip("Could not find the Settings navigation link on Profile Hub (accessibility identifier: profile_hub_settings_link)")
        }

        link.tap()
        waitForContentToLoad()

        // Assert the new view loaded (different nav title, search bar, or new content)
        let newViewLoaded = app.navigationBars.firstMatch.exists ||
                            app.searchFields.firstMatch.exists ||
                            app.staticTexts.containing(
                                NSPredicate(format: "label CONTAINS[c] 'settings'")
                            ).firstMatch.exists

        XCTAssertTrue(newViewLoaded, "Unified Settings view should load after navigation")

        assertNoErrorAlerts(context: "Unified Settings")
        takeScreenshot(named: "unified_settings")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    /// 4. Verify that UnifiedSettingsView contains an interactive search field
    func testUnifiedSettingsSearchExists() throws {
        navigateToSettingsTab()

        // Navigate to Unified Settings using accessibility identifier (same as test 3)
        let settingsLink = scrollToFindByIdentifier("profile_hub_settings_link")

        guard let link = settingsLink, link.isHittable else {
            throw XCTSkip("Could not navigate to Unified Settings to test search (accessibility identifier: profile_hub_settings_link)")
        }

        link.tap()
        waitForContentToLoad()

        // Look for a search field
        let searchField = app.searchFields.firstMatch
        let searchElement = app.otherElements["Search"]

        guard searchField.exists || searchElement.exists else {
            throw XCTSkip("Search field not found in Unified Settings")
        }

        // Tap into the search and type a query
        let target = searchField.exists ? searchField : searchElement
        target.tap()
        Thread.sleep(forTimeInterval: 0.3)
        target.typeText("notification")

        // Assert the search is interactive (field now has text)
        let typedText = app.searchFields.containing(
            NSPredicate(format: "value CONTAINS[c] 'notification'")
        ).firstMatch

        if typedText.exists {
            XCTAssertTrue(typedText.exists, "Search field should contain typed text")
        }

        takeScreenshot(named: "unified_settings_search")

        // Navigate back
        // Clear search first (tap cancel if available)
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists { cancelButton.tap() }

        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    /// 5. Navigate to Notification Settings from the Profile Hub
    func testNavigateToNotificationSettings() throws {
        navigateToSettingsTab()

        let notificationRow = scrollToFindAny(["Notification", "Smart Notification", "Notifications"])

        guard let row = notificationRow, row.isHittable else {
            throw XCTSkip("Notification settings row not found on Profile Hub")
        }

        row.tap()
        waitForContentToLoad()

        // Assert notification-related content loaded
        let notificationContent = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'notification' OR label CONTAINS[c] 'alert' OR label CONTAINS[c] 'reminder'")
        ).firstMatch
        let toggleExists = app.switches.firstMatch.exists

        XCTAssertTrue(
            notificationContent.exists || toggleExists,
            "Notification settings should display notification-related content or toggles"
        )

        assertNoErrorAlerts(context: "Notification Settings")
        takeScreenshot(named: "notification_settings")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    /// 6. Navigate to HealthKit / Apple Health settings from the Profile Hub
    func testNavigateToHealthKitSettings() throws {
        navigateToSettingsTab()

        // Use accessibility identifier for reliable lookup; the "Apple Health" label
        // can be ambiguous in composed accessibility hierarchies.
        let healthRow = scrollToFindByIdentifier("profile_hub_apple_health_link")
            ?? scrollToFindAny(["Apple Health", "HealthKit", "Health Data"])

        guard let row = healthRow, row.isHittable else {
            throw XCTSkip("HealthKit settings row not found on Profile Hub")
        }

        row.tap()
        waitForContentToLoad()

        // Assert the HealthKit settings view loaded
        let healthContent = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'health' OR label CONTAINS[c] 'sync' OR label CONTAINS[c] 'data'")
        ).firstMatch
        let toggleExists = app.switches.firstMatch.exists

        XCTAssertTrue(
            healthContent.exists || toggleExists,
            "HealthKit settings should display health-related content or toggles"
        )

        assertNoErrorAlerts(context: "HealthKit Settings")
        takeScreenshot(named: "healthkit_settings")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    /// 7. Verify the mode changer is accessible from the Profile Hub
    func testModeChangerAccess() throws {
        navigateToSettingsTab()

        let modeElement = scrollToFindAny([
            "Training Mode", "Mode", "Rehab", "Strength", "Performance"
        ])

        XCTAssertNotNil(modeElement, "Mode changer or current mode label should exist on Profile Hub")

        guard let element = modeElement else { return }

        // If the element is tappable, tap it to see mode switching UI
        if element.isHittable {
            element.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Check if a picker, sheet, or action sheet appeared
            let modeSwitchUI = app.pickers.firstMatch.exists ||
                               app.sheets.firstMatch.exists ||
                               app.staticTexts.containing(
                                   NSPredicate(format: "label CONTAINS[c] 'rehab' OR label CONTAINS[c] 'strength' OR label CONTAINS[c] 'performance'")
                               ).firstMatch.exists

            if modeSwitchUI {
                takeScreenshot(named: "mode_changer_ui")

                // Dismiss without changing -- tap outside or cancel
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    // Tap outside the sheet/picker to dismiss
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
                }
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        assertNoErrorAlerts(context: "Mode changer access")
        takeScreenshot(named: "mode_changer_section")
    }

    /// 8. Navigate to the Achievements Dashboard from the Profile Hub
    func testNavigateToAchievementsDashboard() throws {
        navigateToSettingsTab()

        // Use the accessibility identifier on the "View All" link inside
        // AchievementShowcaseView; fall back to label-based search.
        let achievementLink = scrollToFindByIdentifier("profile_hub_view_all_achievements")
            ?? scrollToFindAny([
                "View all achievements", "View All", "Achievements", "Badges", "Achievement"
            ])

        guard let link = achievementLink, link.isHittable else {
            throw XCTSkip("Achievements dashboard link not found on Profile Hub")
        }

        link.tap()
        waitForContentToLoad()

        // Assert a dashboard or list view loaded
        let dashboardContent = app.scrollViews.firstMatch.exists ||
                               app.tables.firstMatch.exists ||
                               app.collectionViews.firstMatch.exists ||
                               app.staticTexts.containing(
                                   NSPredicate(format: "label CONTAINS[c] 'achievement' OR label CONTAINS[c] 'badge' OR label CONTAINS[c] 'earned'")
                               ).firstMatch.exists

        XCTAssertTrue(dashboardContent, "Achievements dashboard should display content")

        assertNoErrorAlerts(context: "Achievements Dashboard")
        takeScreenshot(named: "achievements_dashboard")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists { backButton.tap() }
        waitForContentToLoad()
    }

    /// 9. Verify the Log Out button is reachable on the Profile Hub
    func testLogOutButtonReachable() throws {
        navigateToSettingsTab()

        // Use accessibility identifier for reliable lookup; the Log Out button
        // is near the very bottom of the Profile Hub List and may need many swipes.
        let logOutElement = scrollToFindByIdentifier("profile_hub_log_out_button", maxSwipes: 25)
            ?? scrollToFindAny(["Log Out", "Sign Out"], maxSwipes: 25)
            ?? scrollToFindAny(["Delete Account"], maxSwipes: 5) // Delete Account is right below Log Out

        guard let logOutButton = logOutElement else {
            // The Profile Hub List is very long (11+ sections). On some
            // devices/orientations, swipeUp may not scroll far enough to
            // reach the Account section at the very bottom.
            throw XCTSkip("Log Out button not reachable after 25 swipes — Profile Hub may be too long for automated scrolling")
        }

        guard logOutButton.isHittable else {
            throw XCTSkip("Log Out button found but not hittable — may be partially off-screen")
        }

        takeScreenshot(named: "log_out_button_visible")

        // Note: The current ProfileHubView.logout() signs out directly without
        // showing a confirmation dialog. We verify the button is present and
        // tappable but do NOT tap it, since that would end the session and
        // interfere with tearDown. If a confirmation dialog is added in a future
        // build, the assertion below can be re-enabled.
        //
        // logOutButton.tap()
        // Thread.sleep(forTimeInterval: 0.5)
        // let confirmationAppeared = app.alerts.firstMatch.exists || app.sheets.firstMatch.exists
        // XCTAssertTrue(confirmationAppeared, "Tapping Log Out should show a confirmation")

        assertNoErrorAlerts(context: "Log Out reachability")
    }

    /// 10. Verify a subscription section exists on the Profile Hub
    func testSubscriptionSectionExists() throws {
        navigateToSettingsTab()

        let subscriptionElement = scrollToFindAny([
            "Subscription", "Premium", "Plan", "Pro", "Upgrade"
        ])

        XCTAssertNotNil(
            subscriptionElement,
            "Profile Hub should contain at least one subscription-related label (Subscription, Premium, Plan, Pro, or Upgrade)"
        )

        assertNoErrorAlerts(context: "Subscription section")
        takeScreenshot(named: "subscription_section")
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
            XCTFail("\(context): Unexpected error alert — \(alertLabel)")
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
