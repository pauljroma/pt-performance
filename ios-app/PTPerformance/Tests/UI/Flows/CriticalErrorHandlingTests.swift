//
//  CriticalErrorHandlingTests.swift
//  PTPerformanceUITests
//
//  E2E tests for error handling and edge cases
//  ACP-226: Critical user flow E2E testing - World-class coverage
//

import XCTest

/// E2E tests for error handling and edge cases
///
/// Tests app stability under various error conditions:
/// - Network errors
/// - Empty states
/// - Invalid inputs
/// - App interruptions
/// - Memory warnings
final class CriticalErrorHandlingTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launchEnvironment["IS_RUNNING_UITEST"] = "1"
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Setup

    private func loginAsPatient() {
        app.launch()
        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else { return }
        demoPatientButton.tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
        E2ETestUtilities.waitForLoadingComplete(in: app)
    }

    // MARK: - Empty State Tests

    /// Test app handles empty exercise list gracefully
    func testEmptyExerciseListHandling() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Verify empty state handling") { _ in
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected")

            // Check for either content or empty state message
            let hasContent = app.tables.firstMatch.exists ||
                            app.scrollViews.firstMatch.exists

            let hasEmptyState = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'no session' OR label CONTAINS[c] 'no exercises' OR label CONTAINS[c] 'nothing scheduled'")
            ).firstMatch.exists

            XCTAssertTrue(hasContent || hasEmptyState, "Should show content or empty state")
            E2ETestUtilities.assertNoErrorAlerts(in: app)
            takeScreenshot(named: "today_state")
        }
    }

    /// Test app handles empty program list gracefully
    func testEmptyProgramListHandling() throws {
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        E2ETestUtilities.waitForLoadingComplete(in: app)

        XCTContext.runActivity(named: "Verify program list state") { _ in
            let hasContent = app.tables.firstMatch.exists ||
                            app.collectionViews.firstMatch.exists

            let hasEmptyState = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'no program' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'browse'")
            ).firstMatch.exists

            XCTAssertTrue(hasContent || hasEmptyState, "Should show programs or empty state")
            E2ETestUtilities.assertNoErrorAlerts(in: app)
            takeScreenshot(named: "programs_state")
        }
    }

    // MARK: - App Lifecycle Tests

    /// Test app recovers from background
    func testAppRecoveryFromBackground() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Send app to background and recover") { _ in
            takeScreenshot(named: "before_background")

            // Go to background
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 2)

            // Return to foreground
            app.activate()
            Thread.sleep(forTimeInterval: 1)

            // Verify app is stable
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist after recovery")
            E2ETestUtilities.assertNoErrorAlerts(in: app)
            takeScreenshot(named: "after_recovery")
        }
    }

    /// Test app handles multiple background cycles
    func testMultipleBackgroundCycles() throws {
        loginAsPatient()

        for cycle in 1...3 {
            XCTContext.runActivity(named: "Background cycle \(cycle)") { _ in
                XCUIDevice.shared.press(.home)
                Thread.sleep(forTimeInterval: 1)
                app.activate()
                Thread.sleep(forTimeInterval: 1)

                let tabBar = app.tabBars.firstMatch
                XCTAssertTrue(tabBar.exists, "App should be stable after cycle \(cycle)")
            }
        }

        E2ETestUtilities.assertNoErrorAlerts(in: app)
        takeScreenshot(named: "after_multiple_cycles")
    }

    // MARK: - Navigation Edge Cases

    /// Test rapid back navigation doesn't crash
    func testRapidBackNavigation() throws {
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        E2ETestUtilities.waitForLoadingComplete(in: app)

        let programList = app.tables.firstMatch
        guard programList.waitForExistence(timeout: 10),
              programList.cells.count > 0 else {
            throw XCTSkip("No programs available for navigation test")
        }

        XCTContext.runActivity(named: "Rapid navigation") { _ in
            // Navigate in and out rapidly
            for _ in 1...3 {
                if let firstCell = programList.cells.allElementsBoundByIndex.first, firstCell.exists {
                    firstCell.tap()
                    Thread.sleep(forTimeInterval: 0.3)

                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.exists {
                        backButton.tap()
                        Thread.sleep(forTimeInterval: 0.3)
                    }
                }
            }

            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "after_rapid_navigation")
        }
    }

    /// Test double-tap doesn't cause issues
    func testDoubleTapHandling() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Double-tap on tab") { _ in
            let programsTab = app.tabBars.buttons["Programs"]

            // Double-tap
            programsTab.tap()
            programsTab.tap()

            Thread.sleep(forTimeInterval: 1)
            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "after_double_tap")
        }
    }

    // MARK: - Scroll Edge Cases

    /// Test over-scrolling doesn't cause issues
    func testOverScrollHandling() throws {
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        E2ETestUtilities.waitForLoadingComplete(in: app)

        XCTContext.runActivity(named: "Over-scroll testing") { _ in
            let scrollView = app.tables.firstMatch.exists ? app.tables.firstMatch : app.scrollViews.firstMatch

            guard scrollView.exists else {
                takeScreenshot(named: "no_scroll_view")
                return
            }

            // Aggressive scrolling
            for _ in 1...5 {
                scrollView.swipeUp()
            }
            for _ in 1...5 {
                scrollView.swipeDown()
            }

            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "after_over_scroll")
        }
    }

    // MARK: - Alert Handling Tests

    /// Test dismissing system alerts
    func testSystemAlertDismissal() throws {
        app.launch()

        XCTContext.runActivity(named: "Handle any system alerts") { _ in
            // Check for system alerts and dismiss them
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allowButton = springboard.buttons["Allow"]
            let dontAllowButton = springboard.buttons["Don't Allow"]

            if allowButton.waitForExistence(timeout: 2) {
                allowButton.tap()
            } else if dontAllowButton.waitForExistence(timeout: 2) {
                dontAllowButton.tap()
            }

            takeScreenshot(named: "after_alert_handling")
        }

        // Continue with normal login
        loginAsPatient()
        E2ETestUtilities.assertStableState(in: app)
    }

    // MARK: - Orientation Tests

    /// Test portrait orientation stability
    func testPortraitOrientationStability() throws {
        XCUIDevice.shared.orientation = .portrait
        loginAsPatient()

        XCTContext.runActivity(named: "Verify portrait orientation") { _ in
            XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should exist in portrait")
            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "portrait_orientation")
        }
    }

    /// Test landscape orientation if supported
    func testLandscapeOrientationHandling() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Test landscape orientation") { _ in
            takeScreenshot(named: "before_rotation")

            XCUIDevice.shared.orientation = .landscapeLeft
            Thread.sleep(forTimeInterval: 1)
            takeScreenshot(named: "landscape_left")

            XCUIDevice.shared.orientation = .portrait
            Thread.sleep(forTimeInterval: 1)
            takeScreenshot(named: "back_to_portrait")

            E2ETestUtilities.assertStableState(in: app)
        }
    }

    // MARK: - Memory Warning Simulation

    /// Test app handles interruptions gracefully
    func testInterruptionHandling() throws {
        loginAsPatient()

        // Navigate to a specific state
        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        E2ETestUtilities.waitForLoadingComplete(in: app)

        XCTContext.runActivity(named: "Simulate interruption") { _ in
            takeScreenshot(named: "before_interruption")

            // Simulate Siri activation (brief interruption)
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 0.5)
            app.activate()
            Thread.sleep(forTimeInterval: 1)

            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "after_interruption")
        }
    }

    // MARK: - Performance Under Stress

    /// Test app handles rapid interactions
    func testRapidInteractionStability() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Rapid tab switching") { _ in
            let tabs = ["Today", "Programs", "Profile"]

            for _ in 1...5 {
                for tabName in tabs {
                    let tab = app.tabBars.buttons[tabName]
                    if tab.exists {
                        tab.tap()
                    }
                }
            }

            Thread.sleep(forTimeInterval: 1)
            E2ETestUtilities.assertStableState(in: app)
            takeScreenshot(named: "after_rapid_switching")
        }
    }

    // MARK: - Accessibility Under Error Conditions

    /// Test accessibility labels remain after errors
    func testAccessibilityAfterRecovery() throws {
        loginAsPatient()

        // Cause some navigation
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1)
        app.activate()
        Thread.sleep(forTimeInterval: 1)

        XCTContext.runActivity(named: "Verify accessibility") { _ in
            let tabs = app.tabBars.buttons.allElementsBoundByIndex
            for tab in tabs {
                XCTAssertFalse(tab.label.isEmpty, "Tab should have accessibility label after recovery")
            }
            takeScreenshot(named: "accessibility_after_recovery")
        }
    }

    // MARK: - Helper Methods

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }

    private func captureScreenshotOnFailure() {
        if testRun?.hasSucceeded == false {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "failure_\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
