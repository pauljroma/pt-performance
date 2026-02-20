//
//  PainAndROMTrackingTests.swift
//  PTPerformanceUITests
//
//  E2E tests for Pain Tracking and ROM (Range of Motion) tabs in rehab mode.
//  Logs in as Marcus Rivera (rehab patient #1) and validates that the Pain
//  and ROM tabs load content, display expected UI elements, and remain stable
//  under navigation stress.
//

import XCTest

/// E2E tests for the Pain and ROM tabs in rehab mode
///
/// Marcus Rivera is a rehab-mode patient whose tab bar shows:
/// **Today, Pain, Progress, ROM, Settings**
///
/// The Pain tab renders `PainTrackingView` with:
/// - A body diagram (`pain_body_diagram`)
/// - A save button (`pain_save_log`)
/// - Pain log entries from seed data (5 entries over 14 days)
///
/// The ROM tab renders `ROMExercisesView` with:
/// - A progress card (`rom_progress_card`)
/// - A list of ROM exercises
///
/// Each test method:
/// 1. Launches the app as Marcus Rivera in rehab mode
/// 2. Navigates to the Pain or ROM tab
/// 3. Verifies content, accessibility identifiers, and stability
/// 4. Captures screenshots for visual review
final class PainAndROMTrackingTests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - User Configuration

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

    // MARK: - Pain Tab Tests

    /// Test 1: Verify the Pain tab loads content (scroll view, table, or pain-related text)
    func testPainTabLoadsContent() throws {
        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist in rehab mode")
        painTab.tap()

        waitForContentToLoad()

        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTable = app.tables.firstMatch.exists
        let painTextPredicate = NSPredicate(
            format: "label CONTAINS[c] 'pain' OR label CONTAINS[c] 'track'"
        )
        let hasPainText = app.staticTexts.containing(painTextPredicate).firstMatch.exists

        XCTAssertTrue(
            hasScrollView || hasTable || hasPainText,
            "Pain tab should display content (scroll view, table, or pain/track text)"
        )

        takeScreenshot(named: "pain_tab_loads_content")
    }

    /// Test 2: Verify the body diagram element is displayed on the Pain tab
    func testPainBodyDiagramDisplayed() throws {
        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        painTab.tap()

        waitForContentToLoad()

        // Look for the body diagram via accessibility identifier
        let bodyDiagram = app.otherElements["pain_body_diagram"]
        let bodyDiagramImage = app.images["pain_body_diagram"]

        let diagramFound = bodyDiagram.waitForExistence(timeout: 5) ||
                           bodyDiagramImage.waitForExistence(timeout: 3)

        if !diagramFound {
            // Scroll to find it if it is below the fold
            let scrollableArea = app.scrollViews.firstMatch
            if scrollableArea.exists {
                for _ in 0..<3 {
                    scrollableArea.swipeUp()
                    Thread.sleep(forTimeInterval: 0.5)
                    if bodyDiagram.exists || bodyDiagramImage.exists { break }
                }
            }
        }

        XCTAssertTrue(
            bodyDiagram.exists || bodyDiagramImage.exists,
            "Pain tab should display a body diagram with identifier 'pain_body_diagram'"
        )

        takeScreenshot(named: "pain_body_diagram_displayed")
    }

    /// Test 3: Verify pain log entries exist from seed data (decreasing shoulder pain)
    func testPainLogEntryExists() throws {
        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        painTab.tap()

        waitForContentToLoad()

        // Scroll through the Pain tab to look for seed data entries
        let scrollableArea = app.scrollViews.firstMatch
        let painEntryPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'shoulder' OR label CONTAINS[c] 'pain' \
            OR label CONTAINS[c] '/10' OR label CONTAINS[c] 'log'
            """
        )

        var foundEntry = app.staticTexts.containing(painEntryPredicate).firstMatch.exists

        if !foundEntry && scrollableArea.exists {
            for _ in 0..<5 {
                scrollableArea.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                if app.staticTexts.containing(painEntryPredicate).firstMatch.exists {
                    foundEntry = true
                    break
                }
            }
        }

        XCTAssertTrue(
            foundEntry,
            "Pain tab should contain at least one log entry with 'shoulder', 'pain', '/10', or 'log' from seed data"
        )

        takeScreenshot(named: "pain_log_entry_found")
    }

    /// Test 4: Verify the Pain tab does not show any error alerts
    func testPainTabNoErrorAlerts() throws {
        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        painTab.tap()

        waitForContentToLoad()

        // Wait an extra beat to let any deferred errors surface
        Thread.sleep(forTimeInterval: 1.0)

        assertNoErrorAlerts(context: "Pain tab after loading")

        takeScreenshot(named: "pain_tab_no_error_alerts")
    }

    // MARK: - ROM Tab Tests

    /// Test 5: Verify the ROM tab loads content
    func testROMTabLoadsContent() throws {
        let romTab = app.tabBars.buttons["ROM"]
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist in rehab mode")
        romTab.tap()

        waitForContentToLoad()

        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTable = app.tables.firstMatch.exists
        let hasCollectionView = app.collectionViews.firstMatch.exists
        let romTextPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'range' OR label CONTAINS[c] 'ROM' \
            OR label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'motion'
            """
        )
        let hasROMText = app.staticTexts.containing(romTextPredicate).firstMatch.exists

        XCTAssertTrue(
            hasScrollView || hasTable || hasCollectionView || hasROMText,
            "ROM tab should display content (scroll view, table, collection view, or ROM text)"
        )

        takeScreenshot(named: "rom_tab_loads_content")
    }

    /// Test 6: Verify the ROM progress card is displayed
    func testROMProgressCardDisplayed() throws {
        let romTab = app.tabBars.buttons["ROM"]
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist")
        romTab.tap()

        waitForContentToLoad()

        // Look for the progress card via accessibility identifier
        let progressCard = app.otherElements["rom_progress_card"]

        var cardFound = progressCard.waitForExistence(timeout: 5)

        if !cardFound {
            // Also check for text-based fallback
            let progressPredicate = NSPredicate(
                format: """
                label CONTAINS[c] 'progress' OR label CONTAINS[c] 'range' \
                OR label CONTAINS[c] 'improvement'
                """
            )
            let progressText = app.staticTexts.containing(progressPredicate).firstMatch

            // Scroll if needed
            let scrollableArea = app.scrollViews.firstMatch
            if scrollableArea.exists {
                for _ in 0..<3 {
                    scrollableArea.swipeUp()
                    Thread.sleep(forTimeInterval: 0.5)
                    if progressCard.exists || progressText.exists {
                        cardFound = true
                        break
                    }
                }
            }

            if !cardFound {
                cardFound = progressText.exists
            }
        }

        XCTAssertTrue(
            cardFound,
            "ROM tab should display a progress card with identifier 'rom_progress_card' or progress-related text"
        )

        takeScreenshot(named: "rom_progress_card_displayed")
    }

    /// Test 7: Verify the ROM tab shows either exercise data or a meaningful empty state
    func testROMDataOrEmptyState() throws {
        let romTab = app.tabBars.buttons["ROM"]
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist")
        romTab.tap()

        waitForContentToLoad()

        // Check for data (exercise list, cells, or ROM-related text)
        let dataPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'ROM' \
            OR label CONTAINS[c] 'degrees' OR label CONTAINS[c] 'range' \
            OR label CONTAINS[c] 'motion' OR label CONTAINS[c] 'flexion' \
            OR label CONTAINS[c] 'extension'
            """
        )
        let hasData = app.staticTexts.containing(dataPredicate).firstMatch.exists
            || app.tables.firstMatch.cells.count > 0
            || app.collectionViews.firstMatch.cells.count > 0

        // Check for empty state
        let emptyPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'No ROM' OR label CONTAINS[c] 'no data' \
            OR label CONTAINS[c] 'no exercises' OR label CONTAINS[c] 'empty' \
            OR label CONTAINS[c] 'get started' OR label CONTAINS[c] 'no results'
            """
        )
        let hasEmptyState = app.staticTexts.containing(emptyPredicate).firstMatch.exists

        XCTAssertTrue(
            hasData || hasEmptyState,
            "ROM tab should show either exercise data or a meaningful empty state message"
        )

        takeScreenshot(named: "rom_data_or_empty_state")
    }

    // MARK: - Scrolling & Stability Tests

    /// Test 8: Verify the Pain tab can be scrolled without crashing
    func testPainTrackingScrollable() throws {
        let painTab = app.tabBars.buttons["Pain"]
        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        painTab.tap()

        waitForContentToLoad()

        // Swipe up multiple times to verify scrolling stability
        let scrollableArea = app.scrollViews.firstMatch.exists
            ? app.scrollViews.firstMatch
            : app.collectionViews.firstMatch

        if scrollableArea.exists {
            for _ in 0..<5 {
                scrollableArea.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }

            // Swipe back down to reset
            for _ in 0..<3 {
                scrollableArea.swipeDown()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        // The app should still be responsive after scrolling
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should still be visible after extensive scrolling")

        assertNoErrorAlerts(context: "Pain tab after scrolling")

        takeScreenshot(named: "pain_tracking_scrollable")
    }

    /// Test 9: Verify the ROM tab handles a retry button if an error state is shown
    func testROMTabRetryOnError() throws {
        let romTab = app.tabBars.buttons["ROM"]
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist")
        romTab.tap()

        waitForContentToLoad()

        // Look for error/retry elements
        let retryPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'retry' OR label CONTAINS[c] 'try again' \
            OR label CONTAINS[c] 'reload' OR label CONTAINS[c] 'refresh'
            """
        )
        let retryButton = app.buttons.containing(retryPredicate).firstMatch

        if retryButton.waitForExistence(timeout: 3) {
            // An error state is showing — tap retry
            retryButton.tap()
            waitForContentToLoad()

            // After retry, verify content reloaded or the button is gone
            let hasScrollView = app.scrollViews.firstMatch.exists
            let hasTable = app.tables.firstMatch.exists
            let retryStillExists = retryButton.exists

            XCTAssertTrue(
                hasScrollView || hasTable || !retryStillExists,
                "After tapping retry, ROM tab should show content or dismiss the error state"
            )

            takeScreenshot(named: "rom_tab_after_retry")
        } else {
            // No error state — content loaded successfully, which is the happy path
            let hasContent = app.scrollViews.firstMatch.exists
                || app.tables.firstMatch.exists
                || app.collectionViews.firstMatch.exists

            XCTAssertTrue(
                hasContent,
                "ROM tab loaded without error — content should be visible"
            )

            takeScreenshot(named: "rom_tab_no_error_state")
        }
    }

    /// Test 10: Verify rapidly switching between Pain and ROM tabs does not produce errors
    func testPainAndROMTabCycleStability() throws {
        let painTab = app.tabBars.buttons["Pain"]
        let romTab = app.tabBars.buttons["ROM"]

        XCTAssertTrue(painTab.waitForExistence(timeout: 5), "Pain tab should exist")
        XCTAssertTrue(romTab.waitForExistence(timeout: 5), "ROM tab should exist")

        // Rapidly switch between Pain and ROM tabs 5 times
        for cycle in 1...5 {
            painTab.tap()
            Thread.sleep(forTimeInterval: 0.3)
            assertNoErrorAlerts(context: "Pain/ROM cycle \(cycle) — Pain tab")

            romTab.tap()
            Thread.sleep(forTimeInterval: 0.3)
            assertNoErrorAlerts(context: "Pain/ROM cycle \(cycle) — ROM tab")
        }

        // Final stability check — allow content to settle
        waitForContentToLoad()
        assertNoErrorAlerts(context: "Pain/ROM rapid cycling — final stability check")

        // Tab bar should still be functional
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should remain visible after rapid Pain/ROM cycling")

        takeScreenshot(named: "pain_rom_cycle_stability")
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
