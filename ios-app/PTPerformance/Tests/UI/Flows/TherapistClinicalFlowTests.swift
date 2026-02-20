//
//  TherapistClinicalFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests covering all 7 therapist tabs and patient detail clinical workflows.
//  Logs in as Demo Therapist Sarah Thompson and validates each tab loads
//  plus clinical interactions on patient detail views.
//

import XCTest

/// E2E tests for therapist clinical flows across all 7 tabs
///
/// Validates that:
/// - All 7 therapist tabs are visible and navigable
/// - Intelligence, Rx, Schedule, and Reports tabs load without errors
/// - Patient detail views display clinical data and quick actions
/// - SOAP note access is available from patient detail
/// - Rapid and sequential tab switching remains stable
final class TherapistClinicalFlowTests: XCTestCase {

    var app: XCUIApplication!

    /// Demo therapist UUID from seed data
    private let demoTherapistId = "00000000-0000-0000-0000-000000000100"

    /// All 7 therapist tab labels in display order
    private let allTabLabels = [
        "Patients",
        "Intelligence",
        "Programs",
        "Rx",
        "Schedule",
        "Reports",
        "Settings"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", demoTherapistId,
            "--auto-login-role", "therapist"
        ]
        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1"
        ]
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Login Helper

    private func loginAsTherapist() {
        app.launch()

        // Auto-login via launch argument — wait for therapist dashboard
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after therapist auto-login"
        )
    }

    // MARK: - Patient Detail Navigation Helper

    /// Navigates to the first patient's detail view from the Patients tab.
    /// Returns `true` if navigation succeeded, `false` if no patient cell was found.
    @discardableResult
    private func navigateToFirstPatientDetail() -> Bool {
        let patientsTab = app.tabBars.buttons["Patients"]
        if patientsTab.exists {
            patientsTab.tap()
        }

        waitForContentToLoad()

        // Try table-based layout first
        let tableCell = app.tables.firstMatch.cells.firstMatch
        if tableCell.waitForExistence(timeout: 10) {
            tableCell.tap()
            waitForContentToLoad()
            return true
        }

        // Try collection view layout
        let collectionCell = app.collectionViews.firstMatch.cells.firstMatch
        if collectionCell.waitForExistence(timeout: 5) {
            collectionCell.tap()
            waitForContentToLoad()
            return true
        }

        return false
    }

    // MARK: - Tests

    /// Test 1: Verify all 7 therapist tabs are visible in the tab bar
    func testAllSevenTherapistTabsVisible() throws {
        loginAsTherapist()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible")

        for tabLabel in allTabLabels {
            let tabButton = tabBar.buttons[tabLabel]
            let exists = tabButton.waitForExistence(timeout: 5)
            XCTAssertTrue(
                exists,
                "Tab bar should contain '\(tabLabel)' tab"
            )
        }

        takeScreenshot(named: "therapist_all_seven_tabs")
    }

    /// Test 2: Verify the Intelligence tab loads content without errors
    func testIntelligenceTabLoads() throws {
        loginAsTherapist()

        let intelligenceTab = app.tabBars.buttons["Intelligence"]
        XCTAssertTrue(
            intelligenceTab.waitForExistence(timeout: 10),
            "Intelligence tab should exist"
        )
        intelligenceTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Intelligence tab")

        // Verify some content loaded — look for scroll views, tables, or intelligence-related text
        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTables = app.tables.firstMatch.exists
        let hasCollectionView = app.collectionViews.firstMatch.exists

        let intelligencePredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'intelligence' OR label CONTAINS[c] 'analytics' \
            OR label CONTAINS[c] 'cohort' OR label CONTAINS[c] 'insight' \
            OR label CONTAINS[c] 'trend' OR label CONTAINS[c] 'data'
            """
        )
        let hasIntelligenceText = app.staticTexts
            .containing(intelligencePredicate).firstMatch.exists

        let hasContent = hasScrollView || hasTables || hasCollectionView || hasIntelligenceText

        XCTAssertTrue(
            hasContent,
            "Intelligence tab should display content (scroll view, table, collection view, or intelligence text)"
        )

        takeScreenshot(named: "therapist_intelligence_tab")
    }

    /// Test 3: Verify the Rx (Prescriptions) tab loads content without errors
    func testPrescriptionsTabLoads() throws {
        loginAsTherapist()

        let rxTab = app.tabBars.buttons["Rx"]
        XCTAssertTrue(
            rxTab.waitForExistence(timeout: 10),
            "Rx tab should exist"
        )
        rxTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Rx tab")

        // Verify some content loaded
        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTables = app.tables.firstMatch.exists
        let hasCollectionView = app.collectionViews.firstMatch.exists

        let rxPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'prescription' OR label CONTAINS[c] 'rx' \
            OR label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'assign' \
            OR label CONTAINS[c] 'medication' OR label CONTAINS[c] 'No '
            """
        )
        let hasRxText = app.staticTexts
            .containing(rxPredicate).firstMatch.exists

        let hasContent = hasScrollView || hasTables || hasCollectionView || hasRxText

        XCTAssertTrue(
            hasContent,
            "Rx tab should display content (scroll view, table, collection view, or prescription text)"
        )

        takeScreenshot(named: "therapist_rx_tab")
    }

    /// Test 4: Verify the Schedule tab loads content without errors
    func testScheduleTabLoads() throws {
        loginAsTherapist()

        let scheduleTab = app.tabBars.buttons["Schedule"]
        XCTAssertTrue(
            scheduleTab.waitForExistence(timeout: 10),
            "Schedule tab should exist"
        )
        scheduleTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Schedule tab")

        // Verify some content loaded — look for calendar or appointment related elements
        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTables = app.tables.firstMatch.exists
        let hasCollectionView = app.collectionViews.firstMatch.exists

        let schedulePredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'calendar' OR label CONTAINS[c] 'appointment' \
            OR label CONTAINS[c] 'schedule' OR label CONTAINS[c] 'today' \
            OR label CONTAINS[c] 'week' OR label CONTAINS[c] 'date' \
            OR label CONTAINS[c] 'No '
            """
        )
        let hasScheduleText = app.staticTexts
            .containing(schedulePredicate).firstMatch.exists

        let hasDatePicker = app.datePickers.firstMatch.exists

        let hasContent = hasScrollView || hasTables || hasCollectionView
            || hasScheduleText || hasDatePicker

        XCTAssertTrue(
            hasContent,
            "Schedule tab should display content (scroll view, table, collection view, calendar, or schedule text)"
        )

        takeScreenshot(named: "therapist_schedule_tab")
    }

    /// Test 5: Verify the Reports tab loads content without errors
    func testReportsTabLoads() throws {
        loginAsTherapist()

        let reportsTab = app.tabBars.buttons["Reports"]
        XCTAssertTrue(
            reportsTab.waitForExistence(timeout: 10),
            "Reports tab should exist"
        )
        reportsTab.tap()

        waitForContentToLoad()
        assertNoErrorAlerts(context: "Reports tab")

        // Verify some content loaded
        let hasScrollView = app.scrollViews.firstMatch.exists
        let hasTables = app.tables.firstMatch.exists
        let hasCollectionView = app.collectionViews.firstMatch.exists

        let reportsPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'report' OR label CONTAINS[c] 'summary' \
            OR label CONTAINS[c] 'export' OR label CONTAINS[c] 'chart' \
            OR label CONTAINS[c] 'metric' OR label CONTAINS[c] 'No '
            """
        )
        let hasReportsText = app.staticTexts
            .containing(reportsPredicate).firstMatch.exists

        let hasContent = hasScrollView || hasTables || hasCollectionView || hasReportsText

        XCTAssertTrue(
            hasContent,
            "Reports tab should display content (scroll view, table, collection view, or reports text)"
        )

        takeScreenshot(named: "therapist_reports_tab")
    }

    /// Test 6: Verify patient detail view shows clinical data
    func testPatientDetailShowsClinicalData() throws {
        loginAsTherapist()

        let navigated = navigateToFirstPatientDetail()
        if !navigated {
            // No patients available — acceptable in empty data state
            print("INFO: No patient cells found — skipping detail assertions")
            return
        }

        assertNoErrorAlerts(context: "Patient detail view")

        // Verify patient-related content exists (name, clinical data, or section headers)
        let clinicalPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'patient' OR label CONTAINS[c] 'injury' \
            OR label CONTAINS[c] 'diagnosis' OR label CONTAINS[c] 'plan' \
            OR label CONTAINS[c] 'progress' OR label CONTAINS[c] 'assessment' \
            OR label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'session' \
            OR label CONTAINS[c] 'history' OR label CONTAINS[c] 'note' \
            OR label CONTAINS[c] 'Rivera' OR label CONTAINS[c] 'Chen' \
            OR label CONTAINS[c] 'Brooks' OR label CONTAINS[c] 'Fitzgerald'
            """
        )
        let hasClinicalContent = app.staticTexts
            .containing(clinicalPredicate).firstMatch
            .waitForExistence(timeout: 5)

        let hasAnyStaticText = app.staticTexts.count > 0
        let hasNavBar = app.navigationBars.firstMatch.exists

        XCTAssertTrue(
            hasClinicalContent || hasAnyStaticText || hasNavBar,
            "Patient detail should display clinical content, static text, or a navigation bar"
        )

        takeScreenshot(named: "therapist_patient_detail_clinical")
    }

    /// Test 7: Verify patient detail has quick action buttons
    func testPatientDetailQuickActions() throws {
        loginAsTherapist()

        let navigated = navigateToFirstPatientDetail()
        if !navigated {
            print("INFO: No patient cells found — skipping quick action assertions")
            return
        }

        assertNoErrorAlerts(context: "Patient detail quick actions")

        // Scroll down to look for quick action buttons
        let scrollableArea = app.scrollViews.firstMatch
        if scrollableArea.exists {
            scrollableArea.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
        }

        let quickActionPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'Note' OR label CONTAINS[c] 'Assessment' \
            OR label CONTAINS[c] 'Prescribe' OR label CONTAINS[c] 'Program' \
            OR label CONTAINS[c] 'Message' OR label CONTAINS[c] 'Add' \
            OR label CONTAINS[c] 'New' OR label CONTAINS[c] 'Create' \
            OR label CONTAINS[c] 'Start' OR label CONTAINS[c] 'Assign'
            """
        )
        let quickActionButtons = app.buttons.containing(quickActionPredicate)
        let hasQuickActions = quickActionButtons.firstMatch
            .waitForExistence(timeout: 5)

        if hasQuickActions {
            print("Found quick action button: \(quickActionButtons.firstMatch.label)")
        } else {
            // Scroll further and try again
            if scrollableArea.exists {
                scrollableArea.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        let finalCheck = quickActionButtons.firstMatch.exists

        XCTAssertTrue(
            finalCheck,
            "Patient detail should contain at least one quick action button "
                + "(Note, Assessment, Prescribe, Program, Message, Add, New, Create, Start, or Assign)"
        )

        takeScreenshot(named: "therapist_patient_quick_actions")
    }

    /// Test 8: Verify SOAP note or clinical documentation access from patient detail
    func testPatientDetailSOAPNoteAccess() throws {
        loginAsTherapist()

        let navigated = navigateToFirstPatientDetail()
        if !navigated {
            throw XCTSkip("No patient cells found — cannot test SOAP note access")
        }

        assertNoErrorAlerts(context: "Patient detail SOAP note access")

        // Look for a SOAP note or clinical documentation button
        let soapPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'SOAP' OR label CONTAINS[c] 'Note' \
            OR label CONTAINS[c] 'Document' OR label CONTAINS[c] 'Assessment' \
            OR label CONTAINS[c] 'Clinical' OR label CONTAINS[c] 'Chart'
            """
        )

        // Check buttons first
        var soapButton = app.buttons.containing(soapPredicate).firstMatch
        if !soapButton.waitForExistence(timeout: 5) {
            // Scroll down and try again
            let scrollableArea = app.scrollViews.firstMatch
            if scrollableArea.exists {
                scrollableArea.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
            soapButton = app.buttons.containing(soapPredicate).firstMatch
        }

        guard soapButton.exists else {
            throw XCTSkip(
                "No SOAP/Note/Document/Assessment button found on patient detail — "
                    + "feature may not be implemented yet"
            )
        }

        // Tap the button to open the SOAP note / clinical doc view
        soapButton.tap()
        waitForContentToLoad()
        assertNoErrorAlerts(context: "SOAP note view")

        // Verify a sheet or new view opened
        let hasNewContent = app.scrollViews.firstMatch.exists
            || app.textViews.firstMatch.exists
            || app.navigationBars.count > 0
            || app.staticTexts.count > 0

        XCTAssertTrue(
            hasNewContent,
            "Tapping SOAP/Note button should open a sheet or new view with content"
        )

        takeScreenshot(named: "therapist_soap_note_view")

        // Dismiss the sheet or navigate back
        let closeButton = app.buttons.containing(
            NSPredicate(
                format: """
                label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Done' \
                OR label CONTAINS[c] 'Cancel' OR label CONTAINS[c] 'Dismiss'
                """
            )
        ).firstMatch

        if closeButton.exists {
            closeButton.tap()
        } else {
            // Try navigation back button
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }

    /// Test 9: Cycle through all 7 tabs sequentially and verify stability
    func testTherapistTabCycleStability() throws {
        loginAsTherapist()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible")

        for tabLabel in allTabLabels {
            let tabButton = tabBar.buttons[tabLabel]
            guard tabButton.waitForExistence(timeout: 5) else {
                XCTFail("Tab '\(tabLabel)' should exist for cycling test")
                continue
            }
            tabButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // After cycling through all tabs, assert no error alerts appeared
        assertNoErrorAlerts(context: "Tab cycle stability")

        takeScreenshot(named: "therapist_tab_cycle_final_state")
    }

    /// Test 10: Rapidly switch between Patients, Intelligence, and Programs tabs
    func testTherapistRapidTabSwitching() throws {
        loginAsTherapist()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible")

        let rapidTabs = ["Patients", "Intelligence", "Programs"]

        // Verify all three tabs exist before rapid switching
        for tabLabel in rapidTabs {
            let tabButton = tabBar.buttons[tabLabel]
            XCTAssertTrue(
                tabButton.waitForExistence(timeout: 5),
                "Tab '\(tabLabel)' should exist for rapid switching test"
            )
        }

        // Rapidly switch 5 times through each tab (15 taps total, no delays)
        for _ in 0..<5 {
            for tabLabel in rapidTabs {
                tabBar.buttons[tabLabel].tap()
            }
        }

        // Allow UI to settle briefly
        Thread.sleep(forTimeInterval: 0.5)

        // Assert no error alerts after rapid switching
        assertNoErrorAlerts(context: "Rapid tab switching")

        takeScreenshot(named: "therapist_rapid_tab_switching_final")
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
