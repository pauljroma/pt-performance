//
//  ProgramBuilderPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Program Builder / Creation screen
//  BUILD 294 - Agent 5: Reusable QA Infrastructure
//

import XCTest

/// Page Object representing the Program Builder (program creation) screen
struct ProgramBuilderPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    var programNameField: XCUIElement {
        app.textFields["Program Name"]
    }

    var createButton: XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'create' OR label CONTAINS[c] 'save'")).firstMatch
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    var addPhaseButton: XCUIElement {
        app.buttons["Add Phase"]
    }

    var addSessionButton: XCUIElement {
        app.buttons["Add Session"]
    }

    var addExerciseButton: XCUIElement {
        app.buttons["Add Exercise"]
    }

    var programTypeSegmentedControl: XCUIElement {
        app.segmentedControls.firstMatch
    }

    var rehabSegment: XCUIElement {
        app.segmentedControls.buttons["Rehab"]
    }

    var performanceSegment: XCUIElement {
        app.segmentedControls.buttons["Performance"]
    }

    var lifestyleSegment: XCUIElement {
        app.segmentedControls.buttons["Lifestyle"]
    }

    var protocolList: XCUIElement {
        app.tables.firstMatch
    }

    var exercisePicker: XCUIElement {
        app.sheets.firstMatch
    }

    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Type Selection

    /// Select a program type from the segmented control
    /// - Parameter type: The program type to select (e.g. "Rehab", "Performance", "Lifestyle")
    @discardableResult
    func selectProgramType(_ type: String) -> Self {
        let segment = app.segmentedControls.buttons[type]
        TestHelpers.safeTap(segment, named: "\(type) Segment")
        return self
    }

    // MARK: - Form Interactions

    /// Enter a program name
    /// - Parameter name: The program name to enter
    @discardableResult
    func enterProgramName(_ name: String) -> Self {
        TestHelpers.safeTypeText(
            into: programNameField,
            text: name,
            named: "Program Name Field",
            clearFirst: true
        )
        return self
    }

    /// Tap the Create/Save button
    @discardableResult
    func tapCreate() -> Self {
        TestHelpers.safeTap(createButton, named: "Create Button")
        return self
    }

    /// Tap the Cancel button
    @discardableResult
    func tapCancel() -> Self {
        TestHelpers.safeTap(cancelButton, named: "Cancel Button")
        return self
    }

    /// Tap the Add Phase button
    @discardableResult
    func tapAddPhase() -> Self {
        TestHelpers.safeTap(addPhaseButton, named: "Add Phase Button")
        return self
    }

    /// Tap the Add Session button
    @discardableResult
    func tapAddSession() -> Self {
        TestHelpers.safeTap(addSessionButton, named: "Add Session Button")
        return self
    }

    /// Tap the Add Exercise button
    @discardableResult
    func tapAddExercise() -> Self {
        TestHelpers.safeTap(addExerciseButton, named: "Add Exercise Button")
        return self
    }

    // MARK: - Waiting

    /// Wait for program builder to load
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForLoad(timeout: TimeInterval = TestHelpers.standardTimeout) -> Self {
        _ = TestHelpers.waitForElement(programNameField, timeout: timeout)
        return self
    }

    /// Wait for protocol list to load
    /// - Parameter timeout: Maximum time to wait
    @discardableResult
    func waitForProtocols(timeout: TimeInterval = TestHelpers.networkTimeout) -> Self {
        _ = TestHelpers.waitForElement(protocolList, timeout: timeout)
        _ = TestHelpers.waitForLoadingToComplete(in: app, timeout: timeout)
        return self
    }

    // MARK: - Assertions

    /// Assert that a specific program type is selected in the segmented control
    /// - Parameter type: The expected selected type (e.g. "Rehab", "Performance", "Lifestyle")
    func assertProgramTypeSelected(_ type: String) {
        let segment = app.segmentedControls.buttons[type]
        TestHelpers.assertExists(segment, named: "\(type) Segment")
        XCTAssertTrue(
            segment.isSelected,
            "'\(type)' segment should be selected"
        )
    }

    /// Assert the protocol list is not empty
    func assertProtocolListNotEmpty() {
        TestHelpers.assertExists(protocolList, named: "Protocol List")
        let cellCount = protocolList.cells.count
        XCTAssertGreaterThan(
            cellCount,
            0,
            "Protocol list should contain at least one protocol"
        )
    }

    /// Assert all three program type segments are present
    func assertAllProgramTypesDisplayed() {
        TestHelpers.assertExists(rehabSegment, named: "Rehab Segment")
        TestHelpers.assertExists(performanceSegment, named: "Performance Segment")
        TestHelpers.assertExists(lifestyleSegment, named: "Lifestyle Segment")
    }

    /// Assert the program builder screen is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(programNameField, named: "Program Name Field")
    }

    /// Assert create button exists and is interactive
    func assertCreateButtonExists() {
        TestHelpers.assertExists(createButton, named: "Create Button")
    }

    /// Assert exercise picker is visible
    func assertExercisePickerVisible() {
        let picker = app.tables.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch
        let pickerExists = picker.exists || exercisePicker.exists || app.navigationBars.containing(NSPredicate(format: "identifier CONTAINS[c] 'exercise'")).firstMatch.exists
        XCTAssertTrue(
            pickerExists,
            "Exercise picker should be visible"
        )
    }

    /// Assert a specific protocol is visible
    /// - Parameter name: The protocol name to check
    func assertProtocolVisible(_ name: String) {
        let protocolCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        TestHelpers.assertExists(protocolCell, named: "Protocol: \(name)")
    }

    // MARK: - Queries

    /// Get number of protocols in the list
    var protocolCount: Int {
        return protocolList.cells.count
    }

    /// Check if a protocol exists by name
    /// - Parameter name: Protocol name
    /// - Returns: True if protocol exists in the list
    func hasProtocol(named name: String) -> Bool {
        let protocolCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        return protocolCell.exists
    }
}
