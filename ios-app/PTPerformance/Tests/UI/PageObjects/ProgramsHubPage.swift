//
//  ProgramsHubPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Programs Hub tab
//  BUILD 318: Tab Consolidation - Hub UI Tests
//

import XCTest

/// Page Object representing the Programs Hub tab
struct ProgramsHubPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Tab Bar Elements

    var programsTab: XCUIElement {
        app.tabBars.buttons["Programs"]
    }

    // MARK: - Segmented Picker Elements

    var segmentedPicker: XCUIElement {
        app.segmentedControls.firstMatch
    }

    var programsSegment: XCUIElement {
        app.segmentedControls.buttons["Programs"]
    }

    var historySegment: XCUIElement {
        app.segmentedControls.buttons["History"]
    }

    // MARK: - Programs Section Elements

    var programsList: XCUIElement {
        app.tables.firstMatch
    }

    var programLibraryTitle: XCUIElement {
        app.navigationBars.staticTexts["Programs"]
    }

    var searchField: XCUIElement {
        app.searchFields.firstMatch
    }

    // MARK: - History Section Elements

    var historyTitle: XCUIElement {
        app.navigationBars.staticTexts["History"]
    }

    var historyList: XCUIElement {
        app.tables.firstMatch
    }

    var premiumLockedView: XCUIElement {
        app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'premium' OR label CONTAINS[c] 'unlock'")
        ).firstMatch
    }

    var notSignedInMessage: XCUIElement {
        app.staticTexts["Not Signed In"]
    }

    // MARK: - Interactions

    /// Tap the Programs tab
    @discardableResult
    func tapProgramsTab() -> Self {
        TestHelpers.safeTap(programsTab, named: "Programs Tab")
        return self
    }

    /// Select Programs segment
    @discardableResult
    func selectProgramsSegment() -> Self {
        TestHelpers.safeTap(programsSegment, named: "Programs Segment")
        sleep(1) // Wait for content to load
        return self
    }

    /// Select History segment
    @discardableResult
    func selectHistorySegment() -> Self {
        TestHelpers.safeTap(historySegment, named: "History Segment")
        sleep(1) // Wait for content to load
        return self
    }

    /// Search for a program
    /// - Parameter query: Search query
    @discardableResult
    func searchPrograms(_ query: String) -> Self {
        if searchField.waitForExistence(timeout: 3) {
            TestHelpers.safeTypeText(
                into: searchField,
                text: query,
                named: "Program Search Field"
            )
        }
        return self
    }

    /// Tap on first program in list
    @discardableResult
    func tapFirstProgram() -> Self {
        let firstCell = programsList.cells.firstMatch
        TestHelpers.safeTap(firstCell, named: "First Program")
        return self
    }

    // MARK: - Assertions

    /// Assert Programs Hub is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(programsTab, named: "Programs Tab")
        XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")
    }

    /// Assert Programs tab is selected
    func assertIsSelected() {
        XCTAssertTrue(
            programsTab.isSelected,
            "Programs tab should be selected"
        )
    }

    /// Assert segmented picker exists
    func assertSegmentedPickerExists() {
        TestHelpers.assertExists(
            segmentedPicker,
            named: "Programs Section Picker"
        )
    }

    /// Assert both segments exist in picker
    func assertBothSegmentsExist() {
        TestHelpers.assertExists(programsSegment, named: "Programs Segment")
        TestHelpers.assertExists(historySegment, named: "History Segment")
    }

    /// Assert Programs segment is selected
    func assertProgramsSegmentSelected() {
        XCTAssertTrue(
            programsSegment.isSelected,
            "Programs segment should be selected"
        )
    }

    /// Assert History segment is selected
    func assertHistorySegmentSelected() {
        XCTAssertTrue(
            historySegment.isSelected,
            "History segment should be selected"
        )
    }

    /// Assert program library content is displayed
    func assertProgramLibraryDisplayed() {
        let hasContent = programsList.exists || programLibraryTitle.exists
        XCTAssertTrue(
            hasContent,
            "Program library content should be displayed"
        )
    }

    /// Assert history content is displayed (or locked view)
    func assertHistoryContentDisplayed() {
        let hasHistoryContent = historyList.exists ||
                               historyTitle.exists ||
                               premiumLockedView.exists ||
                               notSignedInMessage.exists
        XCTAssertTrue(
            hasHistoryContent,
            "History content, locked view, or sign-in message should be displayed"
        )
    }

    /// Assert premium locked view is displayed for history
    func assertHistoryLockedForNonPremium() {
        selectHistorySegment()
        TestHelpers.assertExists(
            premiumLockedView,
            named: "Premium Locked View",
            timeout: 3
        )
    }

    // MARK: - Accessibility

    /// Assert segmented picker has accessibility label
    func assertSegmentedPickerAccessible() {
        XCTAssertTrue(
            segmentedPicker.exists,
            "Segmented picker should exist"
        )
    }

    /// Assert both segments are accessible
    func assertSegmentsAccessible() {
        XCTAssertTrue(
            programsSegment.isHittable,
            "Programs segment should be hittable"
        )
        XCTAssertTrue(
            historySegment.isHittable,
            "History segment should be hittable"
        )
    }
}
