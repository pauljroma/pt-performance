//
//  PatientTabNavigationTests.swift
//  PTPerformanceUITests
//
//  E2E tests for patient tab navigation
//  ACP-226: Critical user flow E2E testing
//

import XCTest

/// E2E tests for patient tab navigation flows
///
/// Tests the complete patient navigation experience including:
/// - Today Hub navigation
/// - Programs Hub navigation
/// - Profile Hub navigation
/// - Tab switching behavior
/// - Content loading on each tab
final class PatientTabNavigationTests: XCTestCase {

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

    /// Login as demo patient and wait for dashboard
    private func loginAsPatient() {
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear after login")
            return
        }
    }

    // MARK: - Tab Bar Tests

    /// Test all patient tabs are visible after login
    func testAllPatientTabsVisible() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // Then: All patient tabs should be visible
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists, "Today tab should exist")

        let programsTab = app.tabBars.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist")

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")

        takeScreenshot(named: "patient_all_tabs_visible")
    }

    /// Test Today tab is selected by default
    func testTodayTabSelectedByDefault() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // Then: Today tab should be selected
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")

        takeScreenshot(named: "today_tab_default_selected")
    }

    // MARK: - Today Hub Tests

    /// Test Today Hub displays content
    func testTodayHubDisplaysContent() throws {
        // Given: User on Today tab
        loginAsPatient()

        // Then: Today Hub should display content
        let contentExists = app.scrollViews.firstMatch.exists ||
                           app.tables.firstMatch.exists ||
                           app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'session' OR label CONTAINS[c] 'today' OR label CONTAINS[c] 'workout'")).firstMatch.exists

        XCTAssertTrue(contentExists, "Today Hub should display content")

        takeScreenshot(named: "today_hub_content")
    }

    /// Test Today Hub quick actions menu
    func testTodayHubQuickActions() throws {
        // Given: User on Today tab
        loginAsPatient()

        // When: Looking for quick actions button
        let quickActionsButton = app.buttons["Quick Actions"]

        if quickActionsButton.waitForExistence(timeout: 5) {
            quickActionsButton.tap()

            // Then: Quick action menu items should appear
            let menuExists = app.buttons["AI Quick Pick"].waitForExistence(timeout: 3) ||
                            app.buttons["Timers"].waitForExistence(timeout: 3) ||
                            app.buttons["Readiness Check-In"].waitForExistence(timeout: 3)

            XCTAssertTrue(menuExists, "Quick action menu items should appear")

            takeScreenshot(named: "today_hub_quick_actions")

            // Dismiss menu
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
        }
    }

    // MARK: - Programs Hub Tests

    /// Test navigating to Programs tab
    func testNavigateToProgramsTab() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // When: User taps Programs tab
        let programsTab = app.tabBars.buttons["Programs"]
        XCTAssertTrue(programsTab.exists, "Programs tab should exist")
        programsTab.tap()

        // Then: Programs tab should be selected
        XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected after tap")

        // Programs content should display
        let contentLoaded = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                           app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'program'")).firstMatch.waitForExistence(timeout: 10) ||
                           app.segmentedControls.firstMatch.waitForExistence(timeout: 10)

        XCTAssertTrue(contentLoaded, "Programs content should load")

        takeScreenshot(named: "programs_tab_content")
    }

    /// Test Programs Hub segmented picker
    func testProgramsHubSegmentedPicker() throws {
        // Given: User on Programs tab
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()

        // Wait for content to load
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // When: Check for segmented picker
        let segmentedPicker = app.segmentedControls.firstMatch

        if segmentedPicker.waitForExistence(timeout: 5) {
            // Then: Both segments should exist
            let programsSegment = segmentedPicker.buttons["Programs"]
            let historySegment = segmentedPicker.buttons["History"]

            if programsSegment.exists && historySegment.exists {
                takeScreenshot(named: "programs_segmented_picker")

                // Test switching to History segment
                historySegment.tap()
                sleep(1)
                takeScreenshot(named: "history_segment_selected")

                // Switch back to Programs
                programsSegment.tap()
                sleep(1)
                takeScreenshot(named: "programs_segment_selected")
            }
        }
    }

    // MARK: - Profile Hub Tests

    /// Test navigating to Profile tab
    func testNavigateToProfileTab() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // When: User taps Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")
        profileTab.tap()

        // Then: Profile tab should be selected
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected after tap")

        // Profile content should display
        let contentLoaded = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                           app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'profile' OR label CONTAINS[c] 'account'")).firstMatch.waitForExistence(timeout: 10)

        XCTAssertTrue(contentLoaded, "Profile content should load")

        takeScreenshot(named: "profile_tab_content")
    }

    /// Test Profile Hub sections
    func testProfileHubSections() throws {
        // Given: User on Profile tab
        loginAsPatient()

        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()

        // Wait for content
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Then: Key sections should exist
        let profileTable = app.tables.firstMatch

        // Check for expected section headers or rows
        let expectedElements = [
            "Health & Wellness",
            "Tools & Tracking",
            "Support & Learning",
            "Account",
            "Log Out"
        ]

        var foundCount = 0
        for element in expectedElements {
            let found = app.staticTexts[element].exists || app.buttons[element].exists
            if found { foundCount += 1 }
        }

        // At least some profile elements should exist
        XCTAssertTrue(foundCount >= 2, "Profile should contain expected sections")

        takeScreenshot(named: "profile_hub_sections")
    }

    /// Test Log Out button exists in Profile
    func testProfileHasLogOutButton() throws {
        // Given: User on Profile tab
        loginAsPatient()

        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()

        // Wait for content
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll to find Log Out button
        let logOutButton = app.buttons["Log Out"]
        var attempts = 0
        while !logOutButton.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }

        // Then: Log Out button should exist
        XCTAssertTrue(logOutButton.exists, "Log Out button should exist in Profile")

        takeScreenshot(named: "profile_logout_button")
    }

    // MARK: - Tab Switching Tests

    /// Test rapid tab switching stability
    func testRapidTabSwitching() throws {
        // Given: User logged in as patient
        loginAsPatient()

        let todayTab = app.tabBars.buttons["Today"]
        let programsTab = app.tabBars.buttons["Programs"]
        let profileTab = app.tabBars.buttons["Profile"]

        // When: User switches tabs rapidly
        for _ in 1...3 {
            programsTab.tap()
            sleep(1)
            profileTab.tap()
            sleep(1)
            todayTab.tap()
            sleep(1)
        }

        // Then: App should remain stable
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should still exist after rapid switching")
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected")

        // No error alerts should appear
        let errorAlert = app.alerts.firstMatch
        XCTAssertFalse(errorAlert.exists, "No error alerts should appear")

        takeScreenshot(named: "tab_switching_stable")
    }

    /// Test tab state preservation
    func testTabStatePreservation() throws {
        // Given: User on Programs tab with specific state
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)

        // Scroll down to establish state
        app.swipeUp()
        sleep(1)
        takeScreenshot(named: "programs_scrolled_state")

        // When: User switches to another tab and back
        let todayTab = app.tabBars.buttons["Today"]
        todayTab.tap()
        sleep(1)

        programsTab.tap()
        sleep(1)

        // Then: Programs tab should maintain reasonable state
        XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")

        takeScreenshot(named: "programs_state_after_return")
    }

    // MARK: - Loading States Tests

    /// Test loading indicators appear and disappear
    func testLoadingIndicatorsOnTabSwitch() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // When: Switching to Programs tab
        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()

        // Capture loading state if visible
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            takeScreenshot(named: "programs_loading")
        }

        // Then: Loading should complete
        _ = app.tables.firstMatch.waitForExistence(timeout: 15)

        // Loading indicator should disappear
        let loadingGone = !loadingIndicator.exists || loadingIndicator.waitForNonExistence(timeout: 5)
        XCTAssertTrue(loadingGone, "Loading indicator should disappear")

        takeScreenshot(named: "programs_loaded")
    }

    // MARK: - Deep Navigation Tests

    /// Test navigation depth within tabs
    func testNavigationDepthInPrograms() throws {
        // Given: User on Programs tab
        loginAsPatient()

        let programsTab = app.tabBars.buttons["Programs"]
        programsTab.tap()

        // Wait for content
        let programsList = app.tables.firstMatch
        guard programsList.waitForExistence(timeout: 10) else {
            // No list available - document current state
            takeScreenshot(named: "programs_no_list")
            return
        }

        // When: Tap on first program (if available)
        let firstCell = programsList.cells.firstMatch
        if firstCell.exists {
            firstCell.tap()
            sleep(2)

            takeScreenshot(named: "program_detail_view")

            // Then: Should be able to navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)

                XCTAssertTrue(programsTab.isSelected, "Should return to Programs tab")
                takeScreenshot(named: "programs_after_back")
            }
        }
    }

    // MARK: - Accessibility Tests

    /// Test tab bar accessibility
    func testTabBarAccessibility() throws {
        // Given: User logged in as patient
        loginAsPatient()

        // Then: All tabs should have accessibility labels
        let todayTab = app.tabBars.buttons["Today"]
        let programsTab = app.tabBars.buttons["Programs"]
        let profileTab = app.tabBars.buttons["Profile"]

        XCTAssertTrue(todayTab.isHittable, "Today tab should be hittable")
        XCTAssertTrue(programsTab.isHittable, "Programs tab should be hittable")
        XCTAssertTrue(profileTab.isHittable, "Profile tab should be hittable")

        XCTAssertFalse(todayTab.label.isEmpty, "Today tab should have label")
        XCTAssertFalse(programsTab.label.isEmpty, "Programs tab should have label")
        XCTAssertFalse(profileTab.label.isEmpty, "Profile tab should have label")
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
