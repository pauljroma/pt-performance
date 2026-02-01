//
//  HubNavigationTests.swift
//  PTPerformanceUITests
//
//  E2E tests for Hub tab navigation (Today, Programs, Profile)
//  BUILD 318: Tab Consolidation - Friction-Free UX Sprint
//
//  Tests the consolidated 3-tab navigation including:
//  - Tab bar presence and navigation
//  - Today Hub (quick access menu, session content)
//  - Programs Hub (segmented picker, programs/history)
//  - Profile Hub (all settings sections)
//  - Accessibility compliance
//

import XCTest

/// E2E tests for Hub navigation and content
final class HubNavigationTests: BaseUITest {

    // MARK: - Properties

    private var todayHubPage: TodayHubPage!
    private var programsHubPage: ProgramsHubPage!
    private var profileHubPage: ProfileHubPage!

    // MARK: - Setup

    override func configureLaunchArguments() {
        super.configureLaunchArguments()
        // Start authenticated to skip login
        app.launchArguments.append("StartAuthenticated")
    }

    override func postLaunchSetup() throws {
        try super.postLaunchSetup()

        // Initialize page objects
        todayHubPage = TodayHubPage(app: app)
        programsHubPage = ProgramsHubPage(app: app)
        profileHubPage = ProfileHubPage(app: app)

        // Wait for hub view to load
        TestHelpers.waitForLoadingToComplete(in: app)
    }

    // MARK: - Tab Bar Navigation Tests

    /// Test: Tab bar contains exactly 3 tabs
    /// Expected: Today, Programs, Profile tabs exist
    func testTabBarHas3Tabs() throws {
        // GIVEN: App is launched and authenticated

        // THEN: Tab bar should have exactly 3 tabs
        let tabBar = app.tabBars.firstMatch
        TestHelpers.assertExists(tabBar, named: "Tab Bar")

        let tabCount = tabBar.buttons.count
        XCTAssertEqual(
            tabCount,
            3,
            "Tab bar should have exactly 3 tabs, found \(tabCount)"
        )

        // AND: All expected tabs should exist
        TestHelpers.assertExists(todayHubPage.todayTab, named: "Today Tab")
        TestHelpers.assertExists(programsHubPage.programsTab, named: "Programs Tab")
        TestHelpers.assertExists(profileHubPage.profileTab, named: "Profile Tab")

        captureScreenshot("tab_bar_3_tabs")
    }

    /// Test: Today tab is selected by default on launch
    /// Expected: Today tab is selected, others are not
    func testTodayTabIsDefault() throws {
        // GIVEN: App is launched and authenticated

        // THEN: Today tab should be selected
        todayHubPage.assertIsSelected()

        // AND: Other tabs should not be selected
        XCTAssertFalse(
            programsHubPage.programsTab.isSelected,
            "Programs tab should not be selected on launch"
        )
        XCTAssertFalse(
            profileHubPage.profileTab.isSelected,
            "Profile tab should not be selected on launch"
        )

        captureScreenshot("today_tab_default_selected")
    }

    /// Test: Navigate to Programs tab
    /// Expected: Programs tab becomes selected, content loads
    func testNavigateToProgramsTab() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // WHEN: User taps Programs tab
        programsHubPage.tapProgramsTab()

        // THEN: Programs tab should be selected
        programsHubPage.assertIsSelected()

        // AND: Today tab should no longer be selected
        XCTAssertFalse(
            todayHubPage.todayTab.isSelected,
            "Today tab should not be selected after navigating to Programs"
        )

        // AND: Programs content should load
        programsHubPage.assertSegmentedPickerExists()

        captureScreenshot("programs_tab_selected")
    }

    /// Test: Navigate to Profile tab
    /// Expected: Profile tab becomes selected, content loads
    func testNavigateToProfileTab() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // WHEN: User taps Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Profile tab should be selected
        profileHubPage.assertIsSelected()

        // AND: Today tab should no longer be selected
        XCTAssertFalse(
            todayHubPage.todayTab.isSelected,
            "Today tab should not be selected after navigating to Profile"
        )

        // AND: Profile content should load
        TestHelpers.assertExists(
            profileHubPage.profileList,
            named: "Profile List"
        )

        captureScreenshot("profile_tab_selected")
    }

    /// Test: Cycle between all tabs
    /// Expected: Can navigate to each tab and back
    func testCycleBetweenAllTabs() throws {
        // Start at Today
        todayHubPage.assertIsSelected()
        captureScreenshot("cycle_1_today")

        // Go to Programs
        programsHubPage.tapProgramsTab()
        programsHubPage.assertIsSelected()
        captureScreenshot("cycle_2_programs")

        // Go to Profile
        profileHubPage.tapProfileTab()
        profileHubPage.assertIsSelected()
        captureScreenshot("cycle_3_profile")

        // Go back to Today
        todayHubPage.tapTodayTab()
        todayHubPage.assertIsSelected()
        captureScreenshot("cycle_4_back_to_today")

        // Go to Profile directly from Today
        profileHubPage.tapProfileTab()
        profileHubPage.assertIsSelected()

        // Go to Programs from Profile
        programsHubPage.tapProgramsTab()
        programsHubPage.assertIsSelected()

        captureScreenshot("cycle_complete")
    }

    // MARK: - Today Hub Tests

    /// Test: Quick access menu exists on Today Hub
    /// Expected: Ellipsis button is visible in toolbar
    func testTodayHubQuickAccessMenuExists() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // THEN: Quick access menu button should exist
        todayHubPage.assertQuickAccessMenuExists()

        captureScreenshot("today_hub_quick_access_menu")
    }

    /// Test: Quick access menu contains expected options
    /// Expected: Quick Pick, Timers, and Readiness options exist
    func testTodayHubQuickAccessMenuItems() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // WHEN: User opens quick access menu
        // THEN: Menu should contain expected items
        todayHubPage.assertQuickAccessMenuItemsExist()

        captureScreenshot("today_hub_quick_access_menu_items")
    }

    /// Test: Today session content displays
    /// Expected: Session view shows content or empty state
    func testTodayHubSessionContent() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // THEN: Session content should be displayed
        todayHubPage.assertSessionContentDisplayed()

        captureScreenshot("today_hub_session_content")
    }

    // MARK: - Programs Hub Tests

    /// Test: Segmented picker exists on Programs Hub
    /// Expected: Picker with Programs and History segments
    func testProgramsHubSegmentedPickerExists() throws {
        // GIVEN: App navigates to Programs tab
        programsHubPage.tapProgramsTab()

        // THEN: Segmented picker should exist with both segments
        programsHubPage.assertSegmentedPickerExists()
        programsHubPage.assertBothSegmentsExist()

        captureScreenshot("programs_hub_segmented_picker")
    }

    /// Test: Can switch between Programs and History segments
    /// Expected: Content changes when switching segments
    func testProgramsHubSegmentSwitching() throws {
        // GIVEN: App is on Programs tab
        programsHubPage.tapProgramsTab()

        // WHEN: Programs segment is selected (default)
        // THEN: Programs content should display
        programsHubPage.assertProgramLibraryDisplayed()
        captureScreenshot("programs_segment_selected")

        // WHEN: User selects History segment
        programsHubPage.selectHistorySegment()

        // THEN: History content should display
        programsHubPage.assertHistoryContentDisplayed()
        captureScreenshot("history_segment_selected")

        // WHEN: User switches back to Programs
        programsHubPage.selectProgramsSegment()

        // THEN: Programs content should display again
        programsHubPage.assertProgramLibraryDisplayed()
        captureScreenshot("back_to_programs_segment")
    }

    /// Test: Programs section shows program library browser
    /// Expected: ProgramLibraryBrowserView content is visible
    func testProgramsHubShowsProgramLibrary() throws {
        // GIVEN: App is on Programs tab with Programs segment
        programsHubPage.tapProgramsTab()
        programsHubPage.selectProgramsSegment()

        // THEN: Program library should be displayed
        programsHubPage.assertProgramLibraryDisplayed()

        captureScreenshot("programs_library_displayed")
    }

    /// Test: History section shows appropriate content
    /// Expected: History view, locked view, or sign-in message
    func testProgramsHubHistoryContent() throws {
        // GIVEN: App is on Programs tab
        programsHubPage.tapProgramsTab()

        // WHEN: User selects History segment
        programsHubPage.selectHistorySegment()

        // THEN: Appropriate history content should display
        programsHubPage.assertHistoryContentDisplayed()

        captureScreenshot("history_content_displayed")
    }

    // MARK: - Profile Hub Tests

    /// Test: Health & Wellness section exists
    /// Expected: Section header and nutrition/readiness rows
    func testProfileHubHealthSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Health section should exist
        profileHubPage.assertHealthSectionExists()

        captureScreenshot("profile_health_section")
    }

    /// Test: Tools & Tracking section exists
    /// Expected: Section with body composition, calculators, goals
    func testProfileHubToolsSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Tools section should exist
        profileHubPage.assertToolsSectionExists()

        captureScreenshot("profile_tools_section")
    }

    /// Test: Training Mode section exists
    /// Expected: Section showing current training mode
    func testProfileHubTrainingModeSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Training Mode section should exist
        profileHubPage.assertTrainingModeSectionExists()

        captureScreenshot("profile_training_mode_section")
    }

    /// Test: Therapist section exists
    /// Expected: Section with therapist linking option
    func testProfileHubTherapistSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Therapist section should exist
        profileHubPage.assertTherapistSectionExists()

        captureScreenshot("profile_therapist_section")
    }

    /// Test: Support section exists
    /// Expected: Section with AI assistant, learn, tutorial, privacy
    func testProfileHubSupportSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Support section should exist
        profileHubPage.assertSupportSectionExists()

        captureScreenshot("profile_support_section")
    }

    /// Test: Subscription section exists
    /// Expected: Section with manage subscription option
    func testProfileHubSubscriptionSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Subscription section should exist
        profileHubPage.assertSubscriptionSectionExists()

        captureScreenshot("profile_subscription_section")
    }

    /// Test: Account section exists with logout and delete
    /// Expected: Section with log out and delete account options
    func testProfileHubAccountSectionExists() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Account section with options should exist
        profileHubPage.assertAccountSectionExists()
        profileHubPage.assertAccountOptionsExist()

        captureScreenshot("profile_account_section")
    }

    /// Test: All Profile sections exist
    /// Expected: Complete profile with all 7 sections
    func testProfileHubAllSectionsExist() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: All sections should exist
        profileHubPage.assertAllSectionsExist()

        captureScreenshot("profile_all_sections")
    }

    // MARK: - Accessibility Tests

    /// Test: All tabs have accessibility labels
    /// Expected: Each tab is accessible and hittable
    func testTabBarAccessibility() throws {
        // THEN: All tabs should be accessible
        XCTAssertTrue(
            todayHubPage.todayTab.isHittable,
            "Today tab should be hittable"
        )
        XCTAssertTrue(
            programsHubPage.programsTab.isHittable,
            "Programs tab should be hittable"
        )
        XCTAssertTrue(
            profileHubPage.profileTab.isHittable,
            "Profile tab should be hittable"
        )

        captureScreenshot("tab_bar_accessibility")
    }

    /// Test: Quick access menu is accessible
    /// Expected: Menu button has label and hint
    func testQuickAccessMenuAccessibility() throws {
        // GIVEN: App is on Today tab
        todayHubPage.assertIsSelected()

        // THEN: Quick access menu should be accessible
        todayHubPage.assertQuickAccessMenuAccessible()

        captureScreenshot("quick_access_menu_accessibility")
    }

    /// Test: Segmented picker is accessible
    /// Expected: Picker and segments are accessible
    func testSegmentedPickerAccessibility() throws {
        // GIVEN: App is on Programs tab
        programsHubPage.tapProgramsTab()

        // THEN: Segmented picker should be accessible
        programsHubPage.assertSegmentedPickerAccessible()
        programsHubPage.assertSegmentsAccessible()

        captureScreenshot("segmented_picker_accessibility")
    }

    /// Test: Profile buttons are accessible
    /// Expected: Key buttons are hittable
    func testProfileAccessibility() throws {
        // GIVEN: App is on Profile tab
        profileHubPage.tapProfileTab()

        // THEN: Key elements should be accessible
        profileHubPage.assertProfileTabAccessible()
        profileHubPage.assertLogOutAccessible()
        profileHubPage.assertTutorialAccessible()

        captureScreenshot("profile_accessibility")
    }

    // MARK: - Performance Tests

    /// Test: Tab switching is responsive
    /// Expected: Each tab switch completes within 2 seconds
    func testTabSwitchingPerformance() throws {
        // Measure Today -> Programs
        let todayToPrograms = measureAction("Today to Programs") {
            programsHubPage.tapProgramsTab()
            _ = programsHubPage.programsTab.waitForExistence(timeout: 2)
        }
        XCTAssertLessThan(todayToPrograms, 2.0, "Tab switch should be under 2s")

        // Measure Programs -> Profile
        let programsToProfile = measureAction("Programs to Profile") {
            profileHubPage.tapProfileTab()
            _ = profileHubPage.profileTab.waitForExistence(timeout: 2)
        }
        XCTAssertLessThan(programsToProfile, 2.0, "Tab switch should be under 2s")

        // Measure Profile -> Today
        let profileToToday = measureAction("Profile to Today") {
            todayHubPage.tapTodayTab()
            _ = todayHubPage.todayTab.waitForExistence(timeout: 2)
        }
        XCTAssertLessThan(profileToToday, 2.0, "Tab switch should be under 2s")
    }

    // MARK: - Edge Cases

    /// Test: Rapid tab switching doesn't crash
    /// Expected: App remains stable after rapid navigation
    func testRapidTabSwitching() throws {
        // Rapidly switch between tabs
        for _ in 0..<5 {
            programsHubPage.tapProgramsTab()
            profileHubPage.tapProfileTab()
            todayHubPage.tapTodayTab()
        }

        // Verify app is still responsive
        todayHubPage.assertIsSelected()
        assertNoErrors()

        captureScreenshot("after_rapid_tab_switching")
    }

    /// Test: Tab state persists after background/foreground
    /// Expected: Selected tab remains after app cycle
    func testTabStatePersistsAfterBackground() throws {
        // Navigate to Programs tab
        programsHubPage.tapProgramsTab()
        programsHubPage.assertIsSelected()

        // Background and foreground app
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        // Verify Programs tab is still selected
        programsHubPage.assertIsSelected()

        captureScreenshot("tab_state_after_background")
    }
}
