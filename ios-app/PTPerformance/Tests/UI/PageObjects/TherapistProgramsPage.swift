//
//  TherapistProgramsPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Therapist Programs list screen
//  BUILD 294 - Agent 5: Reusable QA Infrastructure
//

import XCTest

/// Page Object representing the Therapist Programs list view
struct TherapistProgramsPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    var createButton: XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'create'")).firstMatch
    }

    var manageProgramsButton: XCUIElement {
        app.buttons["Manage Programs"]
    }

    var programsList: XCUIElement {
        app.tables.firstMatch
    }

    var rehabFilterChip: XCUIElement {
        app.buttons["Rehab"]
    }

    var performanceFilterChip: XCUIElement {
        app.buttons["Performance"]
    }

    var lifestyleFilterChip: XCUIElement {
        app.buttons["Lifestyle"]
    }

    var allFilterChip: XCUIElement {
        app.buttons["All"]
    }

    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Filter Interactions

    /// Filter programs by type
    /// - Parameter type: The program type to filter by (e.g. "Rehab", "Performance", "Lifestyle")
    @discardableResult
    func filterByType(_ type: String) -> Self {
        let filterButton = app.buttons[type]
        TestHelpers.safeTap(filterButton, named: "\(type) Filter")
        return self
    }

    /// Clear active filter by tapping "All"
    @discardableResult
    func clearFilter() -> Self {
        TestHelpers.safeTap(allFilterChip, named: "All Filter")
        return self
    }

    /// Tap the All filter chip
    @discardableResult
    func tapAllFilter() -> Self {
        TestHelpers.safeTap(allFilterChip, named: "All Filter")
        return self
    }

    // MARK: - Navigation

    /// Tap the Create Program button and return a ProgramBuilderPage
    /// - Returns: ProgramBuilderPage for the program creation screen
    func tapCreateProgram() -> ProgramBuilderPage {
        TestHelpers.safeTap(createButton, named: "Create Program Button")
        return ProgramBuilderPage(app: app)
    }

    /// Tap on a specific program by name
    /// - Parameter name: The program name to tap
    @discardableResult
    func tapProgram(named name: String) -> Self {
        let programCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        TestHelpers.safeTap(programCell, named: "Program: \(name)")
        return self
    }

    // MARK: - Waiting

    /// Wait for programs list to load
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForLoad(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = TestHelpers.waitForElement(programsList, timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert that program type filter chips exist
    func assertProgramTypeFilterExists() {
        TestHelpers.assertExists(allFilterChip, named: "All Filter Chip")
        TestHelpers.assertExists(rehabFilterChip, named: "Rehab Filter Chip")
        TestHelpers.assertExists(performanceFilterChip, named: "Performance Filter Chip")
        TestHelpers.assertExists(lifestyleFilterChip, named: "Lifestyle Filter Chip")
    }

    /// Assert a specific program is visible in the list
    /// - Parameter name: The program name to check
    func assertProgramVisible(_ name: String) {
        let programCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        TestHelpers.assertExists(programCell, named: "Program: \(name)")
    }

    /// Assert the number of programs displayed in the list
    /// - Parameter count: Expected number of programs
    func assertProgramCount(_ count: Int) {
        let cellCount = programsList.cells.count
        XCTAssertEqual(
            cellCount,
            count,
            "Expected \(count) programs in list but found \(cellCount)"
        )
    }

    /// Assert type badge is visible for a program
    /// - Parameter type: The type badge text (e.g. "Rehab", "Performance", "Lifestyle")
    func assertTypeBadgeVisible(_ type: String) {
        let badge = app.staticTexts[type]
        TestHelpers.assertExists(badge, named: "\(type) Type Badge")
    }

    /// Assert programs list is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(programsList, named: "Programs List")
    }

    /// Assert programs list is not empty
    func assertProgramsLoaded() {
        let cellCount = programsList.cells.count
        XCTAssertGreaterThan(
            cellCount,
            0,
            "Programs list should contain at least one program"
        )
    }

    // MARK: - Queries

    /// Get number of programs in list
    var programCount: Int {
        return programsList.cells.count
    }

    /// Check if a program exists by name
    /// - Parameter name: Program name
    /// - Returns: True if program exists in the list
    func hasProgram(named name: String) -> Bool {
        let programCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        return programCell.exists
    }
}
