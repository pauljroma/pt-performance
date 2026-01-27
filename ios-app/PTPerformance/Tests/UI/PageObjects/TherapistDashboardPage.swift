//
//  TherapistDashboardPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Therapist Dashboard (tab bar navigation)
//  BUILD 294 - Agent 5: Reusable QA Infrastructure
//

import XCTest

/// Page Object representing the Therapist Dashboard with tab bar navigation
struct TherapistDashboardPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    var patientsTab: XCUIElement {
        app.buttons["Patients"]
    }

    var programsTab: XCUIElement {
        app.buttons["Programs"]
    }

    var scheduleTab: XCUIElement {
        app.buttons["Schedule"]
    }

    var reportsTab: XCUIElement {
        app.buttons["Reports"]
    }

    var settingsTab: XCUIElement {
        app.buttons["Settings"]
    }

    var title: XCUIElement {
        app.staticTexts["Patients"]
    }

    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Navigation

    /// Navigate to Programs tab
    @discardableResult
    func navigateToPrograms() -> Self {
        TestHelpers.safeTap(programsTab, named: "Programs Tab")
        return self
    }

    /// Navigate to Schedule tab
    @discardableResult
    func navigateToSchedule() -> Self {
        TestHelpers.safeTap(scheduleTab, named: "Schedule Tab")
        return self
    }

    /// Navigate to Reports tab
    @discardableResult
    func navigateToReports() -> Self {
        TestHelpers.safeTap(reportsTab, named: "Reports Tab")
        return self
    }

    /// Navigate to Patients tab
    @discardableResult
    func navigateToPatients() -> Self {
        TestHelpers.safeTap(patientsTab, named: "Patients Tab")
        return self
    }

    /// Navigate to Settings tab
    @discardableResult
    func navigateToSettings() -> Self {
        TestHelpers.safeTap(settingsTab, named: "Settings Tab")
        return self
    }

    // MARK: - Waiting

    /// Wait for dashboard to load
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForLoad(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = TestHelpers.waitForElement(title, timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert therapist dashboard is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(patientsTab, named: "Patients Tab")
    }

    /// Assert all tab bar items are visible
    func assertAllTabsVisible() {
        TestHelpers.assertExists(patientsTab, named: "Patients Tab")
        TestHelpers.assertExists(programsTab, named: "Programs Tab")
        TestHelpers.assertExists(scheduleTab, named: "Schedule Tab")
        TestHelpers.assertExists(reportsTab, named: "Reports Tab")
        TestHelpers.assertExists(settingsTab, named: "Settings Tab")
    }

    /// Assert loading is complete
    func assertLoadingComplete() {
        XCTAssertFalse(
            loadingIndicator.exists,
            "Loading indicator should not be visible"
        )
    }
}
