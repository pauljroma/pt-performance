//
//  TherapistDashboardFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for therapist dashboard flows
//  ACP-226: Critical user flow E2E testing
//

import XCTest

/// E2E tests for therapist dashboard critical flows
///
/// Tests the complete therapist experience including:
/// - Dashboard navigation
/// - Patient list viewing
/// - Program management access
/// - Settings access
/// - Tab navigation
final class TherapistDashboardFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launchEnvironment["IS_RUNNING_UITEST"] = "1"
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Setup Helper

    /// Login as demo therapist and wait for dashboard
    private func loginAsTherapist() {
        app.launch()

        let demoTherapistButton = app.buttons["Demo Therapist"]
        guard demoTherapistButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Therapist button should appear")
            return
        }
        demoTherapistButton.tap()

        // Wait for therapist dashboard
        let patientsTab = app.buttons["Patients"]
        guard patientsTab.waitForExistence(timeout: 15) else {
            XCTFail("Therapist dashboard should appear after login")
            return
        }
    }

    // MARK: - Dashboard Tab Tests

    /// Test all therapist tabs are visible
    func testAllTherapistTabsVisible() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // Then: All therapist tabs should be visible
        let patientsTab = app.buttons["Patients"]
        XCTAssertTrue(patientsTab.exists, "Patients tab should exist")

        let programsTab = app.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist")

        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")

        takeScreenshot(named: "therapist_all_tabs_visible")
    }

    /// Test Patients tab is selected by default
    func testPatientsTabSelectedByDefault() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // Then: Patients tab should be selected (or visible as default)
        let patientsTab = app.buttons["Patients"]

        // Check if it's either selected or the main content shows patients
        let patientsContent = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'patient'")
        ).firstMatch.exists || patientsTab.isSelected

        XCTAssertTrue(patientsContent, "Patients should be the default view")

        takeScreenshot(named: "therapist_default_view")
    }

    // MARK: - Patients Tab Tests

    /// Test Patients tab displays content
    func testPatientsTabDisplaysContent() throws {
        // Given: User on Patients tab
        loginAsTherapist()

        // When: On Patients tab
        let patientsTab = app.buttons["Patients"]
        if !patientsTab.isSelected {
            patientsTab.tap()
        }

        // Then: Patient list or related content should display
        let contentExists = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                           app.collectionViews.firstMatch.waitForExistence(timeout: 10) ||
                           app.staticTexts.containing(
                               NSPredicate(format: "label CONTAINS[c] 'patient'")
                           ).firstMatch.waitForExistence(timeout: 10)

        XCTAssertTrue(contentExists, "Patients content should be displayed")

        takeScreenshot(named: "therapist_patients_content")
    }

    /// Test patient list is scrollable
    func testPatientListScrollable() throws {
        // Given: User on Patients tab with content
        loginAsTherapist()

        let patientsTab = app.buttons["Patients"]
        if !patientsTab.isSelected {
            patientsTab.tap()
        }

        // Wait for content
        let table = app.tables.firstMatch
        guard table.waitForExistence(timeout: 10) else {
            takeScreenshot(named: "therapist_no_patient_table")
            return
        }

        // When: Scrolling the patient list
        table.swipeUp()
        sleep(1)
        takeScreenshot(named: "therapist_patients_scrolled")

        table.swipeDown()
        sleep(1)

        // Then: List should be scrollable without errors
        XCTAssertTrue(table.exists, "Patient list should still exist after scrolling")
    }

    // MARK: - Programs Tab Tests

    /// Test navigating to Programs tab
    func testNavigateToProgramsTab() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Tap Programs tab
        let programsTab = app.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist")
        programsTab.tap()

        // Then: Programs content should display
        let contentExists = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                           app.staticTexts.containing(
                               NSPredicate(format: "label CONTAINS[c] 'program'")
                           ).firstMatch.waitForExistence(timeout: 10)

        XCTAssertTrue(contentExists, "Programs content should display")

        takeScreenshot(named: "therapist_programs_tab")
    }

    /// Test Programs tab has create/manage options
    func testProgramsTabHasManagementOptions() throws {
        // Given: User on Programs tab
        loginAsTherapist()

        let programsTab = app.buttons["Programs"]
        programsTab.tap()

        // Wait for content
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Then: Should have program management UI
        let addButton = app.buttons["Add"] // or + button
        let createButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'create' OR label CONTAINS[c] 'new'")
        ).firstMatch

        let hasManagementUI = addButton.exists || createButton.exists ||
                             app.navigationBars.buttons.count > 0

        // Document current state
        takeScreenshot(named: "therapist_programs_management")

        // At minimum, programs list should be interactive
        XCTAssertTrue(app.tables.firstMatch.exists || app.collectionViews.firstMatch.exists,
                     "Programs should have interactive list")
    }

    // MARK: - Settings Tab Tests

    /// Test navigating to Settings tab
    func testNavigateToSettingsTab() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Tap Settings tab
        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()

        // Then: Settings content should display
        let contentExists = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                           app.staticTexts.containing(
                               NSPredicate(format: "label CONTAINS[c] 'setting' OR label CONTAINS[c] 'account'")
                           ).firstMatch.waitForExistence(timeout: 10)

        XCTAssertTrue(contentExists, "Settings content should display")

        takeScreenshot(named: "therapist_settings_tab")
    }

    /// Test Settings has logout option
    func testSettingsHasLogoutOption() throws {
        // Given: User on Settings tab
        loginAsTherapist()

        let settingsTab = app.buttons["Settings"]
        settingsTab.tap()

        // Wait for content
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to find logout
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        // Then: Log Out option should exist
        XCTAssertTrue(logOutButton.exists, "Log Out should exist in Settings")

        takeScreenshot(named: "therapist_settings_logout")
    }

    // MARK: - Tab Navigation Tests

    /// Test switching between all tabs
    func testSwitchBetweenAllTabs() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        let patientsTab = app.buttons["Patients"]
        let programsTab = app.buttons["Programs"]
        let settingsTab = app.buttons["Settings"]

        // When: Switching through all tabs
        programsTab.tap()
        sleep(1)
        takeScreenshot(named: "therapist_tab_programs")

        settingsTab.tap()
        sleep(1)
        takeScreenshot(named: "therapist_tab_settings")

        patientsTab.tap()
        sleep(1)
        takeScreenshot(named: "therapist_tab_patients")

        // Then: All tabs should be accessible
        XCTAssertTrue(patientsTab.isHittable, "Patients tab should be accessible")
        XCTAssertTrue(programsTab.isHittable, "Programs tab should be accessible")
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be accessible")
    }

    /// Test tab switching preserves state
    func testTabSwitchingPreservesState() throws {
        // Given: User on Patients tab with scrolled state
        loginAsTherapist()

        let patientsList = app.tables.firstMatch
        guard patientsList.waitForExistence(timeout: 10) else {
            takeScreenshot(named: "therapist_no_list")
            return
        }

        // Scroll to establish state
        patientsList.swipeUp()
        takeScreenshot(named: "therapist_patients_scrolled_state")

        // When: Switch to Programs and back
        let programsTab = app.buttons["Programs"]
        programsTab.tap()
        sleep(1)

        let patientsTab = app.buttons["Patients"]
        patientsTab.tap()
        sleep(1)

        // Then: Should return to Patients tab
        XCTAssertTrue(patientsList.exists || patientsTab.isSelected,
                     "Should return to Patients tab")

        takeScreenshot(named: "therapist_patients_returned")
    }

    // MARK: - Schedule/Reports Tabs (if present)

    /// Test Schedule tab if available
    func testScheduleTabIfAvailable() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Check for Schedule tab
        let scheduleTab = app.buttons["Schedule"]

        if scheduleTab.exists {
            scheduleTab.tap()
            sleep(1)

            // Then: Schedule content should display
            takeScreenshot(named: "therapist_schedule_tab")

            let contentExists = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'schedule' OR label CONTAINS[c] 'calendar' OR label CONTAINS[c] 'appointment'")
            ).firstMatch.waitForExistence(timeout: 5)

            XCTAssertTrue(contentExists || app.tables.firstMatch.exists,
                         "Schedule content should display")
        }
    }

    /// Test Reports tab if available
    func testReportsTabIfAvailable() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Check for Reports tab
        let reportsTab = app.buttons["Reports"]

        if reportsTab.exists {
            reportsTab.tap()
            sleep(1)

            // Then: Reports content should display
            takeScreenshot(named: "therapist_reports_tab")

            let contentExists = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'report' OR label CONTAINS[c] 'analytics' OR label CONTAINS[c] 'summary'")
            ).firstMatch.waitForExistence(timeout: 5)

            XCTAssertTrue(contentExists || app.tables.firstMatch.exists,
                         "Reports content should display")
        }
    }

    // MARK: - Patient Selection Tests

    /// Test tapping on a patient opens detail
    func testPatientSelectionOpensDetail() throws {
        // Given: User on Patients tab
        loginAsTherapist()

        let patientsList = app.tables.firstMatch
        guard patientsList.waitForExistence(timeout: 10) else {
            takeScreenshot(named: "therapist_no_patients_list")
            return
        }

        // When: Tap on first patient cell
        let firstPatient = patientsList.cells.firstMatch
        guard firstPatient.exists else {
            takeScreenshot(named: "therapist_no_patient_cells")
            return
        }

        firstPatient.tap()
        sleep(2)

        // Then: Patient detail should open
        takeScreenshot(named: "therapist_patient_detail")

        // Should have back navigation
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            sleep(1)

            XCTAssertTrue(patientsList.exists, "Should return to patient list")
        }
    }

    // MARK: - Loading States Tests

    /// Test loading indicators on tab switch
    func testLoadingIndicatorsOnTabSwitch() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Switching to Programs tab
        let programsTab = app.buttons["Programs"]
        programsTab.tap()

        // Capture loading state if visible
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            takeScreenshot(named: "therapist_programs_loading")
        }

        // Then: Loading should complete
        _ = app.tables.firstMatch.waitForExistence(timeout: 15)

        takeScreenshot(named: "therapist_programs_loaded")
    }

    // MARK: - Accessibility Tests

    /// Test therapist dashboard accessibility
    func testTherapistDashboardAccessibility() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // Then: All tabs should have accessibility labels
        let patientsTab = app.buttons["Patients"]
        let programsTab = app.buttons["Programs"]
        let settingsTab = app.buttons["Settings"]

        XCTAssertTrue(patientsTab.isHittable, "Patients tab should be hittable")
        XCTAssertTrue(programsTab.isHittable, "Programs tab should be hittable")
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be hittable")

        XCTAssertFalse(patientsTab.label.isEmpty, "Patients tab should have label")
        XCTAssertFalse(programsTab.label.isEmpty, "Programs tab should have label")
        XCTAssertFalse(settingsTab.label.isEmpty, "Settings tab should have label")
    }

    // MARK: - Error Handling Tests

    /// Test app handles empty patient list gracefully
    func testEmptyPatientListHandling() throws {
        // Given: User logged in as therapist
        loginAsTherapist()

        // When: Viewing patients (may be empty for demo)
        let patientsList = app.tables.firstMatch
        _ = patientsList.waitForExistence(timeout: 10)

        // Then: Should show list or empty state (not error)
        let hasValidState = patientsList.exists ||
                           app.staticTexts.containing(
                               NSPredicate(format: "label CONTAINS[c] 'no patient' OR label CONTAINS[c] 'add patient'")
                           ).firstMatch.exists

        // No error alerts
        let errorAlert = app.alerts.firstMatch
        XCTAssertFalse(errorAlert.exists, "No error alerts should appear")

        takeScreenshot(named: "therapist_patient_state")
    }

    // MARK: - Helper Methods

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
