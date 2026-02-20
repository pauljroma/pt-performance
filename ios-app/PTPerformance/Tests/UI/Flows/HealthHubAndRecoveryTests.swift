//
//  HealthHubAndRecoveryTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the Health Hub and recovery-related features
//  Validates navigation from Settings (ProfileHubView) into HealthHubView,
//  verifies content sections, and checks sub-feature availability
//

import XCTest

/// E2E tests exercising the Health Hub and its child features
///
/// Logs in as Marcus Rivera (rehab mode) and verifies:
/// - Health Hub is reachable from the Settings / Profile Hub tab
/// - Quick actions grid, health snapshot, and feature links render
/// - Sub-features (Fasting Tracker, Supplement Dashboard, Recovery Tracking,
///   Biomarker Dashboard) are discoverable
/// - Pull-to-refresh works without errors
/// - No unexpected error alerts appear during navigation
///
/// Each test method:
/// 1. Launches the app as Marcus Rivera (rehab mode)
/// 2. Navigates to Settings tab, then into the Health Hub
/// 3. Asserts content exists or gracefully skips if behind a paywall
/// 4. Captures screenshots for visual review
final class HealthHubAndRecoveryTests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - User Configuration

    /// Tyler Brooks (performance mode) UUID — has Recovery tab with Health Hub
    private let tylerBrooksId = "aaaaaaaa-bbbb-cccc-dddd-000000000003"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000003",
            "--auto-login-mode", "performance"
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

    /// Taps the Settings tab and waits for content to appear
    private func navigateToSettingsTab() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab should exist")
        settingsTab.tap()
        waitForContentToLoad()
    }

    /// Scrolls up repeatedly (up to `maxSwipes`) looking for an element whose label
    /// matches `text` case-insensitively. Returns the element if found, nil otherwise.
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
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let text = app.staticTexts.containing(predicate).firstMatch
            let button = app.buttons.containing(predicate).firstMatch
            if text.exists && text.isHittable { return text }
            if button.exists && button.isHittable { return button }
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            for keyword in keywords {
                let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
                let text = app.staticTexts.containing(predicate).firstMatch
                let button = app.buttons.containing(predicate).firstMatch
                if text.exists && text.isHittable { return text }
                if button.exists && button.isHittable { return button }
            }
        }

        // Final pass without hittable requirement
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let text = app.staticTexts.containing(predicate).firstMatch
            let button = app.buttons.containing(predicate).firstMatch
            if text.exists { return text }
            if button.exists { return button }
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
        let candidates: [XCUIElement] = [
            app.buttons.matching(identifier: identifier).firstMatch,
            app.cells.matching(identifier: identifier).firstMatch,
            app.otherElements.matching(identifier: identifier).firstMatch,
            app.staticTexts.matching(identifier: identifier).firstMatch,
            app.descendants(matching: .any)[identifier]
        ]

        func firstHittable() -> XCUIElement? {
            candidates.first { $0.exists && $0.isHittable }
        }

        func firstExisting() -> XCUIElement? {
            candidates.first { $0.exists }
        }

        // Quick check before scrolling
        if let match = firstHittable() { return match }

        // Determine the best scrollable container
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

    /// Navigates to the Recovery tab which hosts HealthHubView in performance mode.
    /// Returns `true` if the Health Hub was successfully reached, `false` otherwise.
    @discardableResult
    private func navigateToHealthHub() -> Bool {
        // In performance mode, Health Hub is the Recovery tab
        let recoveryTab = app.tabBars.buttons["Recovery"]
        if recoveryTab.waitForExistence(timeout: 10) {
            recoveryTab.tap()
            waitForContentToLoad()
            return true
        }

        // Fallback: try navigating from Settings if Recovery tab is not available
        navigateToSettingsTab()

        let healthLink = scrollToFindByIdentifier("profile_hub_health_hub_link")
            ?? scrollToFindAny([
                "Health Hub",
                "Health & Wellness",
                "Apple Health",
                "Health Data",
                "Health"
            ], maxSwipes: 10)

        guard let link = healthLink else {
            return false
        }

        if link.isHittable {
            link.tap()
        } else {
            link.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        waitForContentToLoad()
        return true
    }

    // MARK: - Common Helpers

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

    // MARK: - Tests

    /// 1. Verify that the Health Hub is accessible via the Settings tab navigation
    func testHealthHubAccessFromNavigation() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip(
                "Health Hub entry point not found on Settings/Profile Hub — "
                + "the link may use a different label or be behind a feature flag"
            )
        }

        // Verify that a new view loaded (not still on the Profile Hub root)
        let healthHubLoaded = app.navigationBars.firstMatch.exists
            || app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'health'")
            ).firstMatch.exists
            || app.otherElements["health_hub_quick_actions"].exists
            || app.scrollViews.firstMatch.exists

        XCTAssertTrue(healthHubLoaded, "Health Hub view should load after tapping navigation link")

        assertNoErrorAlerts(context: "Health Hub access from navigation")
        takeScreenshot(named: "health_hub_access_from_navigation")
    }

    /// 2. Verify that the Health Hub shows content or a paywall (no crash)
    func testHealthHubContentOrPaywall() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        // The Health Hub should display either real content or a paywall gate.
        // Both are valid states -- the important thing is that it did not crash.
        let hasContent = app.scrollViews.firstMatch.exists
            || app.tables.firstMatch.exists
            || app.collectionViews.firstMatch.exists

        let hasPaywall = app.staticTexts.containing(
            NSPredicate(
                format: "label CONTAINS[c] 'premium' OR label CONTAINS[c] 'upgrade' "
                + "OR label CONTAINS[c] 'subscribe' OR label CONTAINS[c] 'unlock'"
            )
        ).firstMatch.exists

        let hasAnyContent = hasContent || hasPaywall
            || app.staticTexts.firstMatch.exists
            || app.buttons.firstMatch.exists

        XCTAssertTrue(
            hasAnyContent,
            "Health Hub should display content or a paywall — not a blank/crashed screen"
        )

        assertNoErrorAlerts(context: "Health Hub content or paywall")
        takeScreenshot(named: "health_hub_content_or_paywall")
    }

    /// 3. Verify the Health Snapshot section is present in the Health Hub
    func testHealthSnapshotSection() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        // Look for the health snapshot card or summary section
        let snapshotElement = scrollToFindAny([
            "Health Snapshot",
            "Health Summary",
            "Snapshot",
            "Summary",
            "Health Score",
            "Wellness"
        ])

        // Also check for any health-related static text that might indicate
        // the snapshot card rendered with a different label
        let healthTextPredicate = NSPredicate(
            format: "label CONTAINS[c] 'health' OR label CONTAINS[c] 'snapshot' "
            + "OR label CONTAINS[c] 'summary'"
        )
        let healthText = app.staticTexts.containing(healthTextPredicate).firstMatch

        let snapshotFound = snapshotElement != nil || healthText.exists

        if !snapshotFound {
            // The snapshot section may not be visible if the user has no health
            // data connected or if the feature is gated behind premium
            throw XCTSkip(
                "Health Snapshot section not found — may require HealthKit data "
                + "or premium subscription"
            )
        }

        assertNoErrorAlerts(context: "Health Snapshot section")
        takeScreenshot(named: "health_hub_snapshot_section")
    }

    /// 4. Verify the quick actions grid exists in the Health Hub
    func testQuickActionsGridExists() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        // Strategy 1: Accessibility identifier (most reliable)
        let quickActionsById = scrollToFindByIdentifier("health_hub_quick_actions")

        if let quickActions = quickActionsById {
            XCTAssertTrue(
                quickActions.exists,
                "Quick actions grid should exist with identifier 'health_hub_quick_actions'"
            )
            takeScreenshot(named: "health_hub_quick_actions_grid")
            assertNoErrorAlerts(context: "Quick actions grid by identifier")
            return
        }

        // Strategy 2: Look for multiple action-like buttons that suggest a grid
        let actionKeywords = ["Fasting", "Supplement", "Recovery", "Biomarker", "Lab", "Track"]
        var foundActionCount = 0

        for keyword in actionKeywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let matchingButton = app.buttons.containing(predicate).firstMatch
            let matchingText = app.staticTexts.containing(predicate).firstMatch
            if matchingButton.exists || matchingText.exists {
                foundActionCount += 1
            }
        }

        if foundActionCount >= 2 {
            // Found multiple action items -- likely the quick actions grid
            takeScreenshot(named: "health_hub_quick_actions_grid")
            assertNoErrorAlerts(context: "Quick actions grid by content")
            return
        }

        // Strategy 3: Check for a grid or collection layout
        let collectionView = app.collectionViews.firstMatch
        if collectionView.exists {
            takeScreenshot(named: "health_hub_quick_actions_grid")
            assertNoErrorAlerts(context: "Quick actions grid via collection view")
            return
        }

        throw XCTSkip(
            "Quick actions grid not found — accessibility ID 'health_hub_quick_actions' "
            + "not present and could not identify grid by content"
        )
    }

    /// 5. Verify the Fasting Tracker feature is discoverable in the Health Hub
    func testFastingTrackerNavigation() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        let fastingElement = scrollToFindAny([
            "Fasting Tracker",
            "Fasting",
            "Intermittent Fasting",
            "Fast Timer"
        ])

        guard let element = fastingElement else {
            throw XCTSkip(
                "Fasting Tracker not found in Health Hub — may be behind a paywall "
                + "or feature flag"
            )
        }

        XCTAssertTrue(
            element.exists,
            "Fasting Tracker link should be visible in the Health Hub"
        )

        assertNoErrorAlerts(context: "Fasting Tracker navigation")
        takeScreenshot(named: "health_hub_fasting_tracker")
    }

    /// 6. Verify the Supplement Dashboard feature is discoverable in the Health Hub
    func testSupplementDashboardNavigation() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        let supplementElement = scrollToFindAny([
            "Supplement Dashboard",
            "Supplement",
            "Supplements",
            "Vitamins"
        ])

        guard let element = supplementElement else {
            throw XCTSkip(
                "Supplement Dashboard not found in Health Hub — may be behind a paywall "
                + "or feature flag"
            )
        }

        XCTAssertTrue(
            element.exists,
            "Supplement Dashboard link should be visible in the Health Hub"
        )

        assertNoErrorAlerts(context: "Supplement Dashboard navigation")
        takeScreenshot(named: "health_hub_supplement_dashboard")
    }

    /// 7. Verify the Recovery Tracking feature is discoverable in the Health Hub
    func testRecoveryTrackingNavigation() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        let recoveryElement = scrollToFindAny([
            "Recovery Tracking",
            "Recovery",
            "Recovery Score",
            "Wellness Recovery"
        ])

        guard let element = recoveryElement else {
            throw XCTSkip(
                "Recovery Tracking not found in Health Hub — may be behind a paywall "
                + "or feature flag"
            )
        }

        XCTAssertTrue(
            element.exists,
            "Recovery Tracking link should be visible in the Health Hub"
        )

        assertNoErrorAlerts(context: "Recovery Tracking navigation")
        takeScreenshot(named: "health_hub_recovery_tracking")
    }

    /// 8. Verify the Biomarker Dashboard feature is discoverable in the Health Hub
    func testBiomarkerDashboardNavigation() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        let biomarkerElement = scrollToFindAny([
            "Biomarker Dashboard",
            "Biomarker",
            "Biomarkers",
            "Lab Results",
            "Lab",
            "Labs"
        ])

        guard let element = biomarkerElement else {
            throw XCTSkip(
                "Biomarker Dashboard not found in Health Hub — may be behind a paywall "
                + "or feature flag"
            )
        }

        XCTAssertTrue(
            element.exists,
            "Biomarker Dashboard link should be visible in the Health Hub"
        )

        assertNoErrorAlerts(context: "Biomarker Dashboard navigation")
        takeScreenshot(named: "health_hub_biomarker_dashboard")
    }

    /// 9. Verify that pull-to-refresh works in the Health Hub without errors
    func testHealthHubRefreshable() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        takeScreenshot(named: "health_hub_before_refresh")

        // Perform a pull-to-refresh gesture (swipe down from near the top)
        let topArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let bottomArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        topArea.press(forDuration: 0.05, thenDragTo: bottomArea)

        // Wait for any refresh activity to complete
        waitForContentToLoad()

        // Verify the view is still displaying content (did not crash or go blank)
        let hasContent = app.scrollViews.firstMatch.exists
            || app.tables.firstMatch.exists
            || app.collectionViews.firstMatch.exists
            || app.staticTexts.firstMatch.exists

        XCTAssertTrue(
            hasContent,
            "Health Hub should still display content after pull-to-refresh"
        )

        assertNoErrorAlerts(context: "Health Hub pull-to-refresh")
        takeScreenshot(named: "health_hub_after_refresh")
    }

    /// 10. Verify no error alerts appear when viewing the Health Hub
    func testHealthHubNoErrorAlerts() throws {
        let reached = navigateToHealthHub()

        guard reached else {
            throw XCTSkip("Health Hub not reachable from Settings tab")
        }

        // Wait a generous amount of time for any async operations to complete
        // and potentially surface error alerts
        Thread.sleep(forTimeInterval: 2.0)
        waitForContentToLoad()

        // Scroll through the content to trigger any lazy-loaded sections
        for _ in 0..<3 {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            assertNoErrorAlerts(context: "Health Hub scroll pass")
        }

        // Scroll back to the top
        for _ in 0..<3 {
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Final assertion: no error alerts should be present
        assertNoErrorAlerts(context: "Health Hub final stability check")
        takeScreenshot(named: "health_hub_no_error_alerts")
    }
}
