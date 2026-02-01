//
//  TodayHubPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Today Hub tab
//  BUILD 318: Tab Consolidation - Hub UI Tests
//

import XCTest

/// Page Object representing the Today Hub tab
struct TodayHubPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Tab Bar Elements

    var todayTab: XCUIElement {
        app.tabBars.buttons["Today"]
    }

    // MARK: - Navigation Elements

    var quickAccessMenuButton: XCUIElement {
        app.buttons["Quick Actions"]
    }

    var navigationTitle: XCUIElement {
        app.navigationBars.staticTexts["Today's Session"]
    }

    // MARK: - Quick Access Menu Items

    var quickPickMenuItem: XCUIElement {
        app.buttons["AI Quick Pick"]
    }

    var timersMenuItem: XCUIElement {
        app.buttons["Timers"]
    }

    var readinessMenuItem: XCUIElement {
        app.buttons["Readiness Check-In"]
    }

    // MARK: - Content Elements

    var sessionContent: XCUIElement {
        app.scrollViews.firstMatch
    }

    var exerciseList: XCUIElement {
        app.tables.firstMatch
    }

    var noSessionMessage: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no session'")).firstMatch
    }

    // MARK: - Sheet Elements

    var quickPickSheet: XCUIElement {
        app.sheets.firstMatch
    }

    var timersSheet: XCUIElement {
        app.sheets.firstMatch
    }

    var readinessSheet: XCUIElement {
        app.sheets.firstMatch
    }

    // MARK: - Interactions

    /// Tap the Today tab
    @discardableResult
    func tapTodayTab() -> Self {
        TestHelpers.safeTap(todayTab, named: "Today Tab")
        return self
    }

    /// Open the quick access menu
    @discardableResult
    func openQuickAccessMenu() -> Self {
        TestHelpers.safeTap(quickAccessMenuButton, named: "Quick Access Menu")
        return self
    }

    /// Select Quick Pick from menu
    @discardableResult
    func selectQuickPick() -> Self {
        openQuickAccessMenu()
        TestHelpers.safeTap(quickPickMenuItem, named: "Quick Pick Menu Item")
        return self
    }

    /// Select Timers from menu
    @discardableResult
    func selectTimers() -> Self {
        openQuickAccessMenu()
        TestHelpers.safeTap(timersMenuItem, named: "Timers Menu Item")
        return self
    }

    /// Select Readiness Check-In from menu
    @discardableResult
    func selectReadiness() -> Self {
        openQuickAccessMenu()
        TestHelpers.safeTap(readinessMenuItem, named: "Readiness Menu Item")
        return self
    }

    /// Dismiss any open sheet
    @discardableResult
    func dismissSheet() -> Self {
        app.swipeDown()
        return self
    }

    // MARK: - Assertions

    /// Assert Today Hub is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(todayTab, named: "Today Tab")
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected")
    }

    /// Assert Today tab is selected
    func assertIsSelected() {
        XCTAssertTrue(
            todayTab.isSelected,
            "Today tab should be selected"
        )
    }

    /// Assert quick access menu button exists
    func assertQuickAccessMenuExists() {
        TestHelpers.assertExists(
            quickAccessMenuButton,
            named: "Quick Access Menu Button"
        )
    }

    /// Assert quick access menu items exist after opening menu
    func assertQuickAccessMenuItemsExist() {
        openQuickAccessMenu()
        TestHelpers.assertExists(quickPickMenuItem, named: "Quick Pick Menu Item")
        TestHelpers.assertExists(timersMenuItem, named: "Timers Menu Item")
        TestHelpers.assertExists(readinessMenuItem, named: "Readiness Menu Item")
        // Dismiss menu by tapping elsewhere
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
    }

    /// Assert session content is displayed
    func assertSessionContentDisplayed() {
        let hasContent = sessionContent.exists || exerciseList.exists || noSessionMessage.exists
        XCTAssertTrue(
            hasContent,
            "Today session should display content, exercise list, or no session message"
        )
    }

    /// Assert quick pick sheet is displayed
    func assertQuickPickSheetDisplayed() {
        let sheetExists = app.otherElements.containing(
            NSPredicate(format: "label CONTAINS[c] 'quick pick' OR label CONTAINS[c] 'workout'")
        ).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(sheetExists, "Quick Pick sheet should be displayed")
    }

    /// Assert timers sheet is displayed
    func assertTimersSheetDisplayed() {
        let sheetExists = app.otherElements.containing(
            NSPredicate(format: "label CONTAINS[c] 'timer'")
        ).firstMatch.waitForExistence(timeout: 3) || app.navigationBars["Timers"].waitForExistence(timeout: 3)
        XCTAssertTrue(sheetExists, "Timers sheet should be displayed")
    }

    /// Assert readiness sheet is displayed
    func assertReadinessSheetDisplayed() {
        let sheetExists = app.otherElements.containing(
            NSPredicate(format: "label CONTAINS[c] 'readiness'")
        ).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(sheetExists, "Readiness sheet should be displayed")
    }

    // MARK: - Accessibility

    /// Assert quick access menu has accessibility label
    func assertQuickAccessMenuAccessible() {
        XCTAssertTrue(
            quickAccessMenuButton.exists,
            "Quick Access menu should have accessibility label"
        )
        XCTAssertFalse(
            quickAccessMenuButton.label.isEmpty,
            "Quick Access menu accessibility label should not be empty"
        )
    }
}
