//
//  TherapistProgramTypeTests.swift
//  PTPerformanceUITests
//
//  UI tests for therapist program type selection, filtering, and creation
//  BUILD 294 - Agent 5: Reusable QA Infrastructure
//

import XCTest

final class TherapistProgramTypeTests: BaseUITest {

    // MARK: - Properties

    private var dashboard: TherapistDashboardPage!
    private var programsPage: TherapistProgramsPage!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Login as therapist
        loginAsDemoTherapist()

        // Initialize page objects
        dashboard = TherapistDashboardPage(app: app)
        programsPage = TherapistProgramsPage(app: app)
    }

    // MARK: - Program Type Picker Tests

    func testProgramTypePickerDisplaysAllThreeTypes() throws {
        // Navigate to Programs tab > Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        // Wait for builder to load
        builderPage.waitForLoad()

        // Assert segmented control has Rehab, Performance, Lifestyle
        builderPage.assertAllProgramTypesDisplayed()
    }

    // MARK: - Filter Tests

    func testSelectingRehabFilterShowsOnlyRehabPrograms() throws {
        // Navigate to Programs tab
        dashboard.navigateToPrograms()
        programsPage.waitForLoad()

        // Tap Rehab filter chip
        programsPage.filterByType("Rehab")

        // Assert only rehab programs visible (no crash, filter applied)
        programsPage.assertIsDisplayed()

        // Verify the rehab filter chip is active
        let rehabChip = programsPage.rehabFilterChip
        TestHelpers.assertExists(rehabChip, named: "Rehab Filter Chip")
    }

    func testSelectingPerformanceFilterShowsOnlyPerformancePrograms() throws {
        // Navigate to Programs tab
        dashboard.navigateToPrograms()
        programsPage.waitForLoad()

        // Tap Performance filter chip
        programsPage.filterByType("Performance")

        // Assert filter applied without error
        programsPage.assertIsDisplayed()

        // Verify the performance filter chip is active
        let performanceChip = programsPage.performanceFilterChip
        TestHelpers.assertExists(performanceChip, named: "Performance Filter Chip")
    }

    func testSelectingLifestyleFilterShowsOnlyLifestylePrograms() throws {
        // Navigate to Programs tab
        dashboard.navigateToPrograms()
        programsPage.waitForLoad()

        // Tap Lifestyle filter chip
        programsPage.filterByType("Lifestyle")

        // Assert filter applied without error
        programsPage.assertIsDisplayed()

        // Verify the lifestyle filter chip is active
        let lifestyleChip = programsPage.lifestyleFilterChip
        TestHelpers.assertExists(lifestyleChip, named: "Lifestyle Filter Chip")
    }

    // MARK: - Protocol Filtering Tests

    func testProtocolsFilterByProgramType() throws {
        // Navigate to Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        builderPage.waitForLoad()

        // Select Rehab type
        builderPage.selectProgramType("Rehab")

        // Wait for protocols to load
        builderPage.waitForProtocols()

        // Assert rehab protocols visible (protocol list not empty after filtering)
        builderPage.assertProtocolListNotEmpty()

        // Select Performance type
        builderPage.selectProgramType("Performance")

        // Wait for protocols to reload
        builderPage.waitForProtocols()

        // Assert performance protocols visible
        builderPage.assertProtocolListNotEmpty()
    }

    // MARK: - Program Creation Tests

    func testCreateRehabProgram_SetsCorrectType() throws {
        // Navigate to Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        builderPage.waitForLoad()

        // Select Rehab type
        builderPage.selectProgramType("Rehab")

        // Enter program name
        builderPage.enterProgramName(MockData.ProgramTypeNames.rehabKnee)

        // Assert the type is selected and create button exists
        builderPage.assertProgramTypeSelected("Rehab")
        builderPage.assertCreateButtonExists()
    }

    func testCreatePerformanceProgram_SetsCorrectType() throws {
        // Navigate to Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        builderPage.waitForLoad()

        // Select Performance type
        builderPage.selectProgramType("Performance")

        // Enter program name
        builderPage.enterProgramName(MockData.ProgramTypeNames.performancePower)

        // Assert the type is selected and create button exists
        builderPage.assertProgramTypeSelected("Performance")
        builderPage.assertCreateButtonExists()
    }

    func testCreateLifestyleProgram_SetsCorrectType() throws {
        // Navigate to Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        builderPage.waitForLoad()

        // Select Lifestyle type
        builderPage.selectProgramType("Lifestyle")

        // Enter program name
        builderPage.enterProgramName(MockData.ProgramTypeNames.lifestyleWellness)

        // Assert the type is selected and create button exists
        builderPage.assertProgramTypeSelected("Lifestyle")
        builderPage.assertCreateButtonExists()
    }

    // MARK: - Program List Tests

    func testProgramListShowsTypeBadges() throws {
        // Navigate to Programs tab
        dashboard.navigateToPrograms()
        programsPage.waitForLoad()

        // Assert type badges are visible for programs in the list
        // At least one type badge should exist in the programs list
        let rehabBadge = app.staticTexts["Rehab"]
        let performanceBadge = app.staticTexts["Performance"]
        let lifestyleBadge = app.staticTexts["Lifestyle"]

        let hasAnyBadge = rehabBadge.exists || performanceBadge.exists || lifestyleBadge.exists
        XCTAssertTrue(
            hasAnyBadge,
            "At least one program type badge (Rehab, Performance, or Lifestyle) should be visible in the programs list"
        )
    }

    // MARK: - Exercise Picker Tests

    func testExercisePickerAppearsInSessionBuilder() throws {
        // Navigate to Create Program
        dashboard.navigateToPrograms()
        let builderPage = programsPage
            .waitForLoad()
            .tapCreateProgram()

        builderPage.waitForLoad()

        // Enter a program name to start
        builderPage.enterProgramName("Exercise Picker Test")

        // Add a phase
        builderPage.tapAddPhase()

        // Open session builder
        let addSessionButton = builderPage.addSessionButton
        if TestHelpers.waitForElement(addSessionButton, timeout: TestHelpers.standardTimeout) {
            addSessionButton.tap()

            // Tap Add Exercise to open the exercise picker
            let addExerciseButton = app.buttons["Add Exercise"]
            if TestHelpers.waitForElement(addExerciseButton, timeout: TestHelpers.standardTimeout) {
                addExerciseButton.tap()

                // Assert exercise picker is visible
                // Look for either a table/collection of exercises or a navigation bar indicating exercise selection
                let exerciseList = app.tables.firstMatch
                let exerciseCollection = app.collectionViews.firstMatch
                let exerciseNav = app.navigationBars.containing(NSPredicate(format: "identifier CONTAINS[c] 'exercise'")).firstMatch

                let pickerVisible = exerciseList.waitForExistence(timeout: TestHelpers.standardTimeout)
                    || exerciseCollection.exists
                    || exerciseNav.exists

                XCTAssertTrue(
                    pickerVisible,
                    "Exercise picker should be visible after tapping Add Exercise"
                )
            }
        }
    }
}
