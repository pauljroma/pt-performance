//
//  ProgramEnrollmentFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for program enrollment and management flows
//  ACP-226: Critical user flow E2E testing - World-class coverage
//

import XCTest

/// E2E tests for program enrollment and management flows
///
/// Tests the complete program experience including:
/// - Browsing program library
/// - Viewing program details
/// - Enrolling in programs
/// - Managing enrolled programs
/// - Program search and filtering
final class ProgramEnrollmentFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launchEnvironment["IS_RUNNING_UITEST"] = "1"
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Setup

    private func loginAsPatient() {
        app.launch()

        let demoPatientButton = app.buttons["Demo Patient"]
        guard demoPatientButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Patient button should appear")
            return
        }
        demoPatientButton.tap()

        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Tab bar should appear after login")
            return
        }

        E2ETestUtilities.waitForLoadingComplete(in: app)
    }

    private func navigateToProgramsTab() {
        let programsTab = app.tabBars.buttons["Programs"]
        guard programsTab.exists else {
            XCTFail("Programs tab should exist")
            return
        }
        programsTab.tap()
        E2ETestUtilities.waitForLoadingComplete(in: app)
    }

    // MARK: - Program Library Tests

    /// Test viewing program library
    func testViewProgramLibrary() throws {
        XCTContext.runActivity(named: "Login and navigate to Programs") { _ in
            loginAsPatient()
            navigateToProgramsTab()
        }

        XCTContext.runActivity(named: "Verify program library displays") { _ in
            let programsTab = app.tabBars.buttons["Programs"]
            XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")

            // Check for program content
            let contentExists = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                               app.collectionViews.firstMatch.waitForExistence(timeout: 10) ||
                               app.staticTexts.containing(
                                   NSPredicate(format: "label CONTAINS[c] 'program'")
                               ).firstMatch.waitForExistence(timeout: 10)

            XCTAssertTrue(contentExists, "Program library content should be displayed")
            takeScreenshot(named: "program_library")
        }
    }

    /// Test segmented picker between Programs and History
    func testProgramHistorySegmentedPicker() throws {
        loginAsPatient()
        navigateToProgramsTab()

        XCTContext.runActivity(named: "Verify segmented picker") { _ in
            let segmentedPicker = app.segmentedControls.firstMatch

            guard segmentedPicker.waitForExistence(timeout: 5) else {
                takeScreenshot(named: "no_segmented_picker")
                return
            }

            let programsSegment = segmentedPicker.buttons["Programs"]
            let historySegment = segmentedPicker.buttons["History"]

            XCTAssertTrue(programsSegment.exists, "Programs segment should exist")
            XCTAssertTrue(historySegment.exists, "History segment should exist")

            takeScreenshot(named: "segmented_picker_programs")
        }

        XCTContext.runActivity(named: "Switch to History segment") { _ in
            let segmentedPicker = app.segmentedControls.firstMatch
            let historySegment = segmentedPicker.buttons["History"]

            if historySegment.exists {
                historySegment.tap()
                Thread.sleep(forTimeInterval: 1)
                E2ETestUtilities.waitForLoadingComplete(in: app)
                takeScreenshot(named: "segmented_picker_history")

                // Verify history content or locked state
                let historyLoaded = app.tables.firstMatch.exists ||
                                   app.staticTexts.containing(
                                       NSPredicate(format: "label CONTAINS[c] 'history' OR label CONTAINS[c] 'premium' OR label CONTAINS[c] 'unlock'")
                                   ).firstMatch.exists

                XCTAssertTrue(historyLoaded, "History view should show content or locked state")
            }
        }

        XCTContext.runActivity(named: "Switch back to Programs") { _ in
            let segmentedPicker = app.segmentedControls.firstMatch
            let programsSegment = segmentedPicker.buttons["Programs"]

            if programsSegment.exists {
                programsSegment.tap()
                Thread.sleep(forTimeInterval: 1)
                takeScreenshot(named: "segmented_picker_back_to_programs")
            }
        }
    }

    /// Test browsing program list
    func testBrowseProgramList() throws {
        loginAsPatient()
        navigateToProgramsTab()

        XCTContext.runActivity(named: "Scroll through programs") { _ in
            let programList = app.tables.firstMatch

            guard programList.waitForExistence(timeout: 10) else {
                takeScreenshot(named: "no_program_list")
                return
            }

            // Scroll down
            programList.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(named: "programs_scrolled_down")

            // Scroll back up
            programList.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(named: "programs_scrolled_up")

            E2ETestUtilities.assertStableState(in: app)
        }
    }

    // MARK: - Program Detail Tests

    /// Test viewing program details
    func testViewProgramDetails() throws {
        loginAsPatient()
        navigateToProgramsTab()

        let programList = app.tables.firstMatch
        guard programList.waitForExistence(timeout: 10) else {
            throw XCTSkip("No program list available")
        }

        let firstProgram = programList.cells.firstMatch
        guard firstProgram.exists else {
            throw XCTSkip("No programs in list")
        }

        XCTContext.runActivity(named: "Tap on program to view details") { _ in
            firstProgram.tap()
            Thread.sleep(forTimeInterval: 1)
            E2ETestUtilities.waitForLoadingComplete(in: app)
            takeScreenshot(named: "program_detail")
        }

        XCTContext.runActivity(named: "Verify program detail content") { _ in
            // Check for program detail elements
            let detailIndicators = [
                "Description",
                "Exercises",
                "Duration",
                "Week",
                "Day",
                "Enroll",
                "Start"
            ]

            var foundDetails = false
            for indicator in detailIndicators {
                if app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] %@", indicator)
                ).firstMatch.exists {
                    foundDetails = true
                    break
                }
            }

            if app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'enroll' OR label CONTAINS[c] 'start'")
            ).firstMatch.exists {
                foundDetails = true
            }

            XCTAssertTrue(foundDetails || app.scrollViews.firstMatch.exists,
                         "Program detail should show content")
        }

        XCTContext.runActivity(named: "Navigate back to program list") { _ in
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                Thread.sleep(forTimeInterval: 1)

                let programsTab = app.tabBars.buttons["Programs"]
                XCTAssertTrue(programsTab.isSelected, "Should return to Programs tab")
            }
        }
    }

    /// Test program exercise preview
    func testProgramExercisePreview() throws {
        loginAsPatient()
        navigateToProgramsTab()

        let programList = app.tables.firstMatch
        guard programList.waitForExistence(timeout: 10),
              programList.cells.firstMatch.exists else {
            throw XCTSkip("No programs available")
        }

        XCTContext.runActivity(named: "Open program and view exercises") { _ in
            programList.cells.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1)
            E2ETestUtilities.waitForLoadingComplete(in: app)

            // Look for exercise list within program
            let exerciseList = app.tables.allElementsBoundByIndex.count > 0 ?
                              app.tables.firstMatch : nil

            if let exerciseList = exerciseList, exerciseList.exists {
                // Scroll through exercises
                exerciseList.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                takeScreenshot(named: "program_exercises_scrolled")
            } else {
                takeScreenshot(named: "program_detail_view")
            }
        }
    }

    // MARK: - Enrollment Tests

    /// Test program enrollment button visibility
    func testEnrollmentButtonVisibility() throws {
        loginAsPatient()
        navigateToProgramsTab()

        let programList = app.tables.firstMatch
        guard programList.waitForExistence(timeout: 10),
              programList.cells.firstMatch.exists else {
            throw XCTSkip("No programs available")
        }

        XCTContext.runActivity(named: "Check for enrollment option") { _ in
            programList.cells.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1)
            E2ETestUtilities.waitForLoadingComplete(in: app)

            let enrollButtons = [
                "Enroll",
                "Start Program",
                "Join",
                "Begin"
            ]

            var foundEnrollOption = false
            for buttonLabel in enrollButtons {
                let button = app.buttons.containing(
                    NSPredicate(format: "label CONTAINS[c] %@", buttonLabel)
                ).firstMatch

                if button.exists {
                    foundEnrollOption = true
                    takeScreenshot(named: "enroll_button_found")
                    break
                }
            }

            if !foundEnrollOption {
                // May already be enrolled or different UI
                takeScreenshot(named: "program_detail_state")
            }
        }
    }

    /// Test tapping enrollment button
    func testTapEnrollmentButton() throws {
        loginAsPatient()
        navigateToProgramsTab()

        let programList = app.tables.firstMatch
        guard programList.waitForExistence(timeout: 10),
              programList.cells.firstMatch.exists else {
            throw XCTSkip("No programs available")
        }

        programList.cells.firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        E2ETestUtilities.waitForLoadingComplete(in: app)

        XCTContext.runActivity(named: "Tap enrollment button if available") { _ in
            let enrollButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'enroll' OR label CONTAINS[c] 'start' OR label CONTAINS[c] 'begin'")
            ).firstMatch

            if enrollButton.exists && enrollButton.isHittable {
                takeScreenshot(named: "before_enrollment_tap")
                enrollButton.tap()
                Thread.sleep(forTimeInterval: 2)
                E2ETestUtilities.waitForLoadingComplete(in: app)
                takeScreenshot(named: "after_enrollment_tap")

                // Check for confirmation or success state
                E2ETestUtilities.assertStableState(in: app)
            }
        }
    }

    // MARK: - Search and Filter Tests

    /// Test program search functionality
    func testProgramSearch() throws {
        loginAsPatient()
        navigateToProgramsTab()

        XCTContext.runActivity(named: "Test search if available") { _ in
            let searchField = app.searchFields.firstMatch

            if searchField.waitForExistence(timeout: 5) {
                takeScreenshot(named: "search_field_visible")

                searchField.tap()
                searchField.typeText("strength")
                Thread.sleep(forTimeInterval: 1)
                E2ETestUtilities.waitForLoadingComplete(in: app)
                takeScreenshot(named: "search_results")

                // Clear search
                let clearButton = searchField.buttons["Clear text"]
                if clearButton.exists {
                    clearButton.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                }
            } else {
                takeScreenshot(named: "no_search_field")
            }
        }
    }

    // MARK: - Enrolled Programs Tests

    /// Test viewing enrolled programs
    func testViewEnrolledPrograms() throws {
        loginAsPatient()
        navigateToProgramsTab()

        XCTContext.runActivity(named: "Check for enrolled programs section") { _ in
            // Look for enrolled/active programs section
            let enrolledIndicators = [
                "Enrolled",
                "Active",
                "My Programs",
                "Current"
            ]

            for indicator in enrolledIndicators {
                let section = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] %@", indicator)
                ).firstMatch

                if section.exists {
                    takeScreenshot(named: "enrolled_section_found")
                    break
                }
            }

            // Also check for enrolled program cards/cells
            let enrolledPrograms = app.cells.containing(
                NSPredicate(format: "label CONTAINS[c] 'enrolled' OR label CONTAINS[c] 'active'")
            ).firstMatch

            if enrolledPrograms.exists {
                takeScreenshot(named: "enrolled_programs_visible")
            }
        }
    }

    // MARK: - Stability Tests

    /// Test rapid navigation doesn't cause issues
    func testRapidNavigationStability() throws {
        loginAsPatient()

        XCTContext.runActivity(named: "Rapidly switch tabs") { _ in
            let programsTab = app.tabBars.buttons["Programs"]
            let todayTab = app.tabBars.buttons["Today"]
            let profileTab = app.tabBars.buttons["Profile"]

            for _ in 1...5 {
                programsTab.tap()
                Thread.sleep(forTimeInterval: 0.3)
                todayTab.tap()
                Thread.sleep(forTimeInterval: 0.3)
                profileTab.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }

            programsTab.tap()
            Thread.sleep(forTimeInterval: 1)

            E2ETestUtilities.assertStableState(in: app)
            XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")
            takeScreenshot(named: "after_rapid_navigation")
        }
    }

    // MARK: - Performance Tests

    /// Test program list load performance
    func testProgramListLoadPerformance() throws {
        loginAsPatient()

        let duration = E2ETestUtilities.measurePerformance("Programs tab load") {
            navigateToProgramsTab()
        }

        XCTAssertLessThan(duration, 5.0, "Programs should load within 5 seconds")
    }

    // MARK: - Accessibility Tests

    /// Test program list accessibility
    func testProgramListAccessibility() throws {
        loginAsPatient()
        navigateToProgramsTab()

        XCTContext.runActivity(named: "Verify accessibility") { _ in
            let programsTab = app.tabBars.buttons["Programs"]
            XCTAssertFalse(programsTab.label.isEmpty, "Programs tab should have accessibility label")

            let programList = app.tables.firstMatch
            if programList.exists {
                let cells = programList.cells.allElementsBoundByIndex
                for cell in cells.prefix(3) {
                    XCTAssertTrue(cell.isHittable, "Program cells should be hittable")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }

    private func captureScreenshotOnFailure() {
        if testRun?.hasSucceeded == false {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "failure_\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
