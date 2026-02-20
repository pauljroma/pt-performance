//
//  ModeSpecificTabTests.swift
//  PTPerformanceUITests
//
//  E2E tests for mode-specific tab bar configurations
//  Validates that each training mode (rehab, strength, performance) shows
//  the correct set of tabs and that each tab loads content without errors
//

import XCTest

/// E2E tests that verify mode-aware tab bar configurations
///
/// The patient app displays different tabs based on the user's training mode:
/// - **Rehab**: Today, Pain, Progress, ROM, Settings
/// - **Strength**: Today, Workouts, PRs, Progress, Settings
/// - **Performance**: Today, Training, Analytics, Recovery, Settings
///
/// Each test method:
/// 1. Launches the app with --auto-login-user-id for a specific persona
/// 2. Waits for the tab bar to appear (dashboard loaded)
/// 3. Asserts the correct tabs are present (and incorrect ones are absent)
/// 4. Taps into tabs and verifies content loads without errors
/// 5. Captures screenshots for visual review
final class ModeSpecificTabTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Persona UUIDs

    private static let rehabUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000001"       // Marcus Rivera
    private static let strengthUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000005"    // Jordan Williams
    private static let performanceUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000003" // Tyler Brooks

    // MARK: - Tab Name Constants

    private static let rehabTabs = ["Today", "Pain", "Progress", "ROM", "Settings"]
    private static let strengthTabs = ["Today", "Workouts", "PRs", "Progress", "Settings"]
    private static let performanceTabs = ["Today", "Training", "Analytics", "Recovery", "Settings"]

    // MARK: - Launch Helper

    private func launchAsUser(_ userId: String) {
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", userId
        ]
        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1"
        ]
        app.launch()

        // Wait for tab bar to appear (dashboard loaded)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )
    }

    // MARK: - Rehab Mode Tests (Marcus Rivera)

    func testRehabMode_AllTabsVisible() throws {
        launchAsUser(Self.rehabUserID)

        let tabBar = app.tabBars

        // Assert all rehab tabs are present
        for tabName in Self.rehabTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(
                tab.waitForExistence(timeout: 5),
                "Rehab mode should show '\(tabName)' tab"
            )
        }

        // Assert strength-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Workouts"].exists,
            "Rehab mode should NOT show 'Workouts' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["PRs"].exists,
            "Rehab mode should NOT show 'PRs' tab"
        )

        // Assert performance-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Training"].exists,
            "Rehab mode should NOT show 'Training' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["Analytics"].exists,
            "Rehab mode should NOT show 'Analytics' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["Recovery"].exists,
            "Rehab mode should NOT show 'Recovery' tab"
        )

        takeScreenshot(named: "rehab_mode_all_tabs")
    }

    func testRehabMode_PainTrackingTabLoads() throws {
        launchAsUser(Self.rehabUserID)

        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        painTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rehab - Pain tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'pain' OR label CONTAINS[c] 'track' OR label CONTAINS[c] 'log'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Pain tab should display content")

        takeScreenshot(named: "rehab_mode_pain_tab")
    }

    func testRehabMode_ProgressTabLoads() throws {
        launchAsUser(Self.rehabUserID)

        let progressTab = app.tabBars.buttons["Progress"]
        XCTAssertTrue(progressTab.waitForExistence(timeout: 5), "Progress tab should exist")
        progressTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rehab - Progress tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'progress' OR label CONTAINS[c] 'chart' OR label CONTAINS[c] 'week'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Progress tab should display content")

        takeScreenshot(named: "rehab_mode_progress_tab")
    }

    func testRehabMode_ROMExercisesTabLoads() throws {
        launchAsUser(Self.rehabUserID)

        let romTab = app.tabBars.buttons["ROM"]
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist")
        romTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rehab - ROM tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'range' OR label CONTAINS[c] 'ROM' OR label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'motion'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "ROM tab should display content")

        takeScreenshot(named: "rehab_mode_rom_tab")
    }

    func testRehabMode_SettingsTabLoads() throws {
        launchAsUser(Self.rehabUserID)

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rehab - Settings tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'account' OR label CONTAINS[c] 'profile' OR label CONTAINS[c] 'notification'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Settings tab should display content")

        takeScreenshot(named: "rehab_mode_settings_tab")
    }

    // MARK: - Strength Mode Tests (Jordan Williams)

    func testStrengthMode_AllTabsVisible() throws {
        launchAsUser(Self.strengthUserID)

        let tabBar = app.tabBars

        // Assert all strength tabs are present
        for tabName in Self.strengthTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(
                tab.waitForExistence(timeout: 5),
                "Strength mode should show '\(tabName)' tab"
            )
        }

        // Assert rehab-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Pain"].exists,
            "Strength mode should NOT show 'Pain' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["ROM"].exists,
            "Strength mode should NOT show 'ROM' tab"
        )

        // Assert performance-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Training"].exists,
            "Strength mode should NOT show 'Training' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["Analytics"].exists,
            "Strength mode should NOT show 'Analytics' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["Recovery"].exists,
            "Strength mode should NOT show 'Recovery' tab"
        )

        takeScreenshot(named: "strength_mode_all_tabs")
    }

    func testStrengthMode_WorkoutsTabLoads() throws {
        launchAsUser(Self.strengthUserID)

        let workoutsTab = app.tabBars.buttons["Workouts"]
        XCTAssertTrue(workoutsTab.waitForExistence(timeout: 5), "Workouts tab should exist")
        workoutsTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Strength - Workouts tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'workout' OR label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'set'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Workouts tab should display content")

        takeScreenshot(named: "strength_mode_workouts_tab")
    }

    func testStrengthMode_PRsTabLoads() throws {
        launchAsUser(Self.strengthUserID)

        let prsTab = app.tabBars.buttons["PRs"]
        XCTAssertTrue(prsTab.waitForExistence(timeout: 5), "PRs tab should exist")
        prsTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Strength - PRs tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'PR' OR label CONTAINS[c] 'record' OR label CONTAINS[c] 'personal' OR label CONTAINS[c] 'best'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "PRs tab should display content")

        takeScreenshot(named: "strength_mode_prs_tab")
    }

    func testStrengthMode_ProgressTabLoads() throws {
        launchAsUser(Self.strengthUserID)

        let progressTab = app.tabBars.buttons["Progress"]
        XCTAssertTrue(progressTab.waitForExistence(timeout: 5), "Progress tab should exist")
        progressTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Strength - Progress tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'progress' OR label CONTAINS[c] 'chart' OR label CONTAINS[c] 'week'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Progress tab should display content")

        takeScreenshot(named: "strength_mode_progress_tab")
    }

    // MARK: - Performance Mode Tests (Tyler Brooks)

    func testPerformanceMode_AllTabsVisible() throws {
        launchAsUser(Self.performanceUserID)

        let tabBar = app.tabBars

        // Assert all performance tabs are present
        for tabName in Self.performanceTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(
                tab.waitForExistence(timeout: 5),
                "Performance mode should show '\(tabName)' tab"
            )
        }

        // Assert rehab-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Pain"].exists,
            "Performance mode should NOT show 'Pain' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["ROM"].exists,
            "Performance mode should NOT show 'ROM' tab"
        )

        // Assert strength-specific tabs are absent
        XCTAssertFalse(
            tabBar.buttons["Workouts"].exists,
            "Performance mode should NOT show 'Workouts' tab"
        )
        XCTAssertFalse(
            tabBar.buttons["PRs"].exists,
            "Performance mode should NOT show 'PRs' tab"
        )

        takeScreenshot(named: "performance_mode_all_tabs")
    }

    func testPerformanceMode_TrainingTabLoads() throws {
        launchAsUser(Self.performanceUserID)

        let trainingTab = app.tabBars.buttons["Training"]
        XCTAssertTrue(trainingTab.waitForExistence(timeout: 5), "Training tab should exist")
        trainingTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Performance - Training tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'training' OR label CONTAINS[c] 'plan' OR label CONTAINS[c] 'session'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Training tab should display content")

        takeScreenshot(named: "performance_mode_training_tab")
    }

    func testPerformanceMode_AnalyticsTabLoads() throws {
        launchAsUser(Self.performanceUserID)

        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Performance - Analytics tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'analytics' OR label CONTAINS[c] 'metric' OR label CONTAINS[c] 'stat' OR label CONTAINS[c] 'data'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Analytics tab should display content")

        takeScreenshot(named: "performance_mode_analytics_tab")
    }

    func testPerformanceMode_RecoveryTabLoads() throws {
        launchAsUser(Self.performanceUserID)

        let recoveryTab = app.tabBars.buttons["Recovery"]
        XCTAssertTrue(recoveryTab.waitForExistence(timeout: 5), "Recovery tab should exist")
        recoveryTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Performance - Recovery tab")

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.staticTexts.containing(NSPredicate(
                             format: "label CONTAINS[c] 'recovery' OR label CONTAINS[c] 'rest' OR label CONTAINS[c] 'sleep' OR label CONTAINS[c] 'wellness'"
                         )).firstMatch.exists

        XCTAssertTrue(hasContent, "Recovery tab should display content")

        takeScreenshot(named: "performance_mode_recovery_tab")
    }

    // MARK: - Cross-Mode Stability Test

    func testModeSpecificTabSwitching_NoErrors() throws {
        launchAsUser(Self.performanceUserID)

        let tabBar = app.tabBars

        // Verify all performance tabs exist before cycling
        for tabName in Self.performanceTabs {
            XCTAssertTrue(
                tabBar.buttons[tabName].waitForExistence(timeout: 5),
                "Performance tab '\(tabName)' should exist before rapid cycling"
            )
        }

        // Rapidly cycle through all 5 tabs, 3 times
        for cycle in 1...3 {
            for tabName in Self.performanceTabs {
                let tab = tabBar.buttons[tabName]
                XCTAssertTrue(tab.exists, "Tab '\(tabName)' should still exist on cycle \(cycle)")
                tab.tap()

                // Brief pause to let the UI settle (shorter than full content load)
                Thread.sleep(forTimeInterval: 0.3)

                assertNoErrorAlerts(context: "Rapid cycling - cycle \(cycle), tab '\(tabName)'")
            }
        }

        // Final stability check after all cycling
        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rapid cycling - final stability check")

        takeScreenshot(named: "performance_mode_rapid_cycle_complete")
    }

    // MARK: - Helper Methods

    private func waitForContentToLoad() {
        // Wait for loading indicators to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 15)
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

// MARK: - XCUIElement Convenience

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
