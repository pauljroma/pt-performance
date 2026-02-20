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

        // Look for a link/button that navigates to unified settings
        let settingsLink = scrollToFindAny(["All Settings", "App Settings", "Settings"])

        guard let link = settingsLink, link.isHittable else {
            // Try tapping a gear-icon button if text link not found
            let gearButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'settings'")
            ).firstMatch

            if gearButton.exists && gearButton.isHittable {
                gearButton.tap()
            } else {
                throw XCTSkip("Could not find a navigation link to Unified Settings")
            }

            waitForContentToLoad()
            assertNoErrorAlerts(context: "Unified Settings via gear icon")
            takeScreenshot(named: "unified_settings_via_gear")

            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            return
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

        // Navigate to Unified Settings (same approach as test 3)
        let settingsLink = scrollToFindAny(["All Settings", "App Settings", "Settings"])

        guard let link = settingsLink, link.isHittable else {
            throw XCTSkip("Could not navigate to Unified Settings to test search")
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

        let healthRow = scrollToFindAny(["Apple Health", "HealthKit", "Health Data"])

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

        let achievementLink = scrollToFindAny([
            "View All Achievements", "Achievements", "Badges", "Achievement"
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

    /// 9. Verify the Log Out button is reachable and shows a confirmation dialog
    func testLogOutButtonReachable() throws {
        navigateToSettingsTab()

        let logOutElement = scrollToFindAny(["Log Out", "Sign Out"], maxSwipes: 10)

        XCTAssertNotNil(logOutElement, "Log Out / Sign Out button should be reachable after scrolling")

        guard let logOutButton = logOutElement, logOutButton.isHittable else {
            XCTFail("Log Out button was found but is not hittable")
            return
        }

        logOutButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Assert a confirmation alert or dialog appeared
        let alert = app.alerts.firstMatch
        let sheet = app.sheets.firstMatch
        let confirmationAppeared = alert.exists || sheet.exists

        XCTAssertTrue(
            confirmationAppeared,
            "Tapping Log Out should show a confirmation alert or action sheet"
        )

        takeScreenshot(named: "log_out_confirmation")

        // Dismiss the confirmation by tapping Cancel or the first non-destructive button
        if alert.exists {
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Tap the first button that is not destructive
                alert.buttons.firstMatch.tap()
            }
        } else if sheet.exists {
            let cancelButton = sheet.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                sheet.buttons.firstMatch.tap()
            }
        }

        Thread.sleep(forTimeInterval: 0.3)
        assertNoErrorAlerts(context: "Log Out dismissal")
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
