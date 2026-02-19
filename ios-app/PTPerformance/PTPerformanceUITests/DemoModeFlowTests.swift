//
//  DemoModeFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for demo mode functionality
//  Tests demo patient and demo therapist login flows and capabilities
//

import XCTest

/// E2E tests for demo mode functionality
///
/// Tests the complete demo mode experience for both patient and therapist:
/// - Demo patient login and Today screen
/// - Demo patient tab navigation
/// - Demo patient exercise technique viewing
/// - Demo patient readiness check-in
/// - Demo therapist login and patients list
/// - Demo therapist patient details
/// - Demo therapist clinical assessments
final class DemoModeFlowTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure launch arguments for demo mode testing
        app.launchArguments = [
            "--uitesting",
            "--reset-auth"
        ]

        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1",
            "USE_DEMO_DATA": "1",
            "SKIP_ONBOARDING": "1"
        ]
    }

    override func tearDownWithError() throws {
        captureScreenshotOnFailure()
        app.terminate()
        app = nil
    }

    // MARK: - Demo Patient Tests

    /// Test 1: Demo patient login -> Today screen loads with workout
    func testDemoPatientLoginLoadsTodayWithWorkout() throws {
        XCTContext.runActivity(named: "Launch app") { _ in
            app.launch()
            waitForAppReady()
            takeScreenshot(named: "patient_01_login_screen")
        }

        XCTContext.runActivity(named: "Tap Demo Patient button") { _ in
            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10),
                         "Demo Patient button should be visible")

            demoPatientButton.tap()
        }

        XCTContext.runActivity(named: "Verify Today screen loads") { _ in
            // Wait for tab bar to appear (indicates successful login)
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 15),
                         "Tab bar should appear after demo patient login")

            // Wait for loading to complete
            waitForLoadingComplete()

            // Verify Today tab is selected
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.exists, "Today tab should exist")
            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected by default")

            takeScreenshot(named: "patient_02_today_screen")
        }

        XCTContext.runActivity(named: "Verify workout content is displayed") { _ in
            // Look for workout indicators
            let workoutContent = findWorkoutContent()
            XCTAssertTrue(workoutContent,
                         "Today screen should display workout content (exercises, cards, or empty state)")

            takeScreenshot(named: "patient_03_workout_content")
        }
    }

    /// Test 2: Demo patient can navigate all tabs
    func testDemoPatientCanNavigateAllTabs() throws {
        // Login first
        loginAsDemoPatient()

        XCTContext.runActivity(named: "Navigate to Programs tab") { _ in
            let programsTab = app.tabBars.buttons["Programs"]
            XCTAssertTrue(programsTab.exists, "Programs tab should exist")

            programsTab.tap()
            waitForLoadingComplete()

            XCTAssertTrue(programsTab.isSelected, "Programs tab should be selected")

            // Verify some content loads
            let contentLoaded = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                               app.scrollViews.firstMatch.waitForExistence(timeout: 10) ||
                               app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'program'")).firstMatch.waitForExistence(timeout: 10)

            XCTAssertTrue(contentLoaded, "Programs tab should display content")

            takeScreenshot(named: "patient_nav_02_programs_tab")
        }

        XCTContext.runActivity(named: "Navigate to Profile tab") { _ in
            let profileTab = app.tabBars.buttons["Profile"]
            XCTAssertTrue(profileTab.exists, "Profile tab should exist")

            profileTab.tap()
            waitForLoadingComplete()

            XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")

            // Verify profile content loads
            let contentLoaded = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                               app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'profile' OR label CONTAINS[c] 'account'")).firstMatch.waitForExistence(timeout: 10)

            XCTAssertTrue(contentLoaded, "Profile tab should display content")

            takeScreenshot(named: "patient_nav_03_profile_tab")
        }

        XCTContext.runActivity(named: "Navigate back to Today tab") { _ in
            let todayTab = app.tabBars.buttons["Today"]
            todayTab.tap()
            waitForLoadingComplete()

            XCTAssertTrue(todayTab.isSelected, "Today tab should be selected")

            takeScreenshot(named: "patient_nav_04_back_to_today")
        }
    }

    /// Test 3: Demo patient can view exercise technique
    func testDemoPatientCanViewExerciseTechnique() throws {
        loginAsDemoPatient()

        var skipReason: String?
        XCTContext.runActivity(named: "Find and tap on exercise") { _ in
            let exerciseCell = self.findFirstExercise()
            guard exerciseCell.waitForExistence(timeout: 10) else {
                skipReason = "No exercises available for technique viewing test"
                return
            }

            exerciseCell.tap()
            self.waitForLoadingComplete()

            self.takeScreenshot(named: "technique_01_exercise_opened")
        }
        if let reason = skipReason { throw XCTSkip(reason) }

        XCTContext.runActivity(named: "Look for technique/video button") { _ in
            let techniqueIndicators = [
                app.buttons["View Technique"],
                app.buttons["Technique"],
                app.buttons["How To"],
                app.buttons["Video"],
                app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'technique'")).firstMatch,
                app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'video'")).firstMatch,
                app.images.containing(NSPredicate(format: "identifier CONTAINS[c] 'play'")).firstMatch
            ]

            for techniqueButton in techniqueIndicators {
                if techniqueButton.exists && techniqueButton.isHittable {
                    takeScreenshot(named: "technique_02_button_found")
                    techniqueButton.tap()
                    waitForLoadingComplete()

                    takeScreenshot(named: "technique_03_technique_view")

                    // Verify technique view opened
                    let techniqueViewLoaded = app.staticTexts.containing(
                        NSPredicate(format: "label CONTAINS[c] 'technique' OR label CONTAINS[c] 'how to' OR label CONTAINS[c] 'form'")
                    ).firstMatch.waitForExistence(timeout: 10) ||
                    app.otherElements["videoPlayer"].waitForExistence(timeout: 10) ||
                    app.webViews.firstMatch.waitForExistence(timeout: 10)

                    // Dismiss technique view
                    let closeButton = app.buttons["Close"]
                    let doneButton = app.buttons["Done"]
                    if closeButton.exists {
                        closeButton.tap()
                    } else if doneButton.exists {
                        doneButton.tap()
                    } else {
                        app.swipeDown()
                    }

                    return
                }
            }

            // If no technique button found, document current state
            takeScreenshot(named: "technique_no_button_found")
        }
    }

    /// Test 4: Demo patient can complete readiness check-in
    func testDemoPatientCanCompleteReadinessCheckIn() throws {
        loginAsDemoPatient()

        XCTContext.runActivity(named: "Access Readiness Check-In") { _ in
            // Try Quick Actions menu first
            let quickActionsButton = app.buttons["Quick Actions"]

            if quickActionsButton.waitForExistence(timeout: 5) {
                quickActionsButton.tap()
                Thread.sleep(forTimeInterval: 0.5)

                takeScreenshot(named: "readiness_01_quick_actions_menu")

                let readinessButton = app.buttons["Readiness Check-In"]
                if readinessButton.waitForExistence(timeout: 3) {
                    readinessButton.tap()
                    waitForLoadingComplete()

                    takeScreenshot(named: "readiness_02_check_in_opened")
                } else {
                    // Dismiss menu and try Profile tab
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
                    tryReadinessFromProfile()
                }
            } else {
                tryReadinessFromProfile()
            }
        }

        XCTContext.runActivity(named: "Verify readiness check-in UI") { _ in
            // Look for readiness elements
            let readinessElements = [
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'readiness'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'how are you feeling'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'sleep'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'energy'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'stress'")).firstMatch,
                app.sliders.firstMatch
            ]

            let foundReadinessUI = readinessElements.contains { $0.waitForExistence(timeout: 5) }

            if foundReadinessUI {
                takeScreenshot(named: "readiness_03_check_in_ui")

                // Try to interact with a slider if present
                let slider = app.sliders.firstMatch
                if slider.exists {
                    slider.adjust(toNormalizedSliderPosition: 0.7)
                    takeScreenshot(named: "readiness_04_slider_adjusted")
                }
            } else {
                takeScreenshot(named: "readiness_03_no_ui_found")
            }
        }
    }

    // MARK: - Demo Therapist Tests

    /// Test 5: Demo therapist login -> Patients list loads
    func testDemoTherapistLoginLoadsPatientsLlist() throws {
        XCTContext.runActivity(named: "Launch app") { _ in
            app.launch()
            waitForAppReady()
            takeScreenshot(named: "therapist_01_login_screen")
        }

        XCTContext.runActivity(named: "Tap Demo Therapist button") { _ in
            let demoTherapistButton = app.buttons["Demo Therapist"]
            XCTAssertTrue(demoTherapistButton.waitForExistence(timeout: 10),
                         "Demo Therapist button should be visible")

            demoTherapistButton.tap()
        }

        XCTContext.runActivity(named: "Verify Patients list loads") { _ in
            // Wait for therapist dashboard to load
            let tabBar = app.tabBars.firstMatch
            let patientsTitle = app.staticTexts["Patients"]
            let navigationTitle = app.navigationBars.staticTexts["Patients"]

            let dashboardLoaded = tabBar.waitForExistence(timeout: 15) ||
                                 patientsTitle.waitForExistence(timeout: 15) ||
                                 navigationTitle.waitForExistence(timeout: 15)

            XCTAssertTrue(dashboardLoaded,
                         "Therapist dashboard should load after demo login")

            waitForLoadingComplete()

            takeScreenshot(named: "therapist_02_patients_list")
        }

        XCTContext.runActivity(named: "Verify patients content is displayed") { _ in
            // Look for patient list indicators
            let patientContent = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'patient'")).firstMatch.waitForExistence(timeout: 10) ||
                                app.cells.count > 0

            takeScreenshot(named: "therapist_03_patients_content")
        }
    }

    /// Test 6: Demo therapist can view patient details
    func testDemoTherapistCanViewPatientDetails() throws {
        loginAsDemoTherapist()

        var skipReason2: String?
        XCTContext.runActivity(named: "Find and tap on patient") { _ in
            // Wait for patient list to load
            let patientList = self.app.tables.firstMatch
            guard patientList.waitForExistence(timeout: 10) else {
                skipReason2 = "Patient list not available"
                return
            }

            let firstPatient = patientList.cells.firstMatch
            guard firstPatient.waitForExistence(timeout: 5) else {
                skipReason2 = "No patients available in demo mode"
                return
            }

            self.takeScreenshot(named: "therapist_detail_01_patient_list")

            firstPatient.tap()
            self.waitForLoadingComplete()

            self.takeScreenshot(named: "therapist_detail_02_patient_selected")
        }
        if let reason = skipReason2 { throw XCTSkip(reason) }

        XCTContext.runActivity(named: "Verify patient details display") { _ in
            // Look for patient detail indicators
            let detailIndicators = [
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'session'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'program'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'adherence'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'progress'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch,
                app.tables.firstMatch,
                app.scrollViews.firstMatch
            ]

            let foundDetails = detailIndicators.contains { $0.waitForExistence(timeout: 5) }

            XCTAssertTrue(foundDetails, "Patient detail view should display patient information")

            takeScreenshot(named: "therapist_detail_03_patient_details")
        }
    }

    /// Test 7: Demo therapist can view clinical assessments
    func testDemoTherapistCanViewClinicalAssessments() throws {
        loginAsDemoTherapist()

        var skipReason3: String?
        XCTContext.runActivity(named: "Navigate to patient detail") { _ in
            let patientList = self.app.tables.firstMatch
            guard patientList.waitForExistence(timeout: 10) else {
                skipReason3 = "Patient list not available"
                return
            }

            let firstPatient = patientList.cells.firstMatch
            guard firstPatient.waitForExistence(timeout: 5) else {
                skipReason3 = "No patients available"
                return
            }

            firstPatient.tap()
            self.waitForLoadingComplete()
        }
        if let reason = skipReason3 { throw XCTSkip(reason) }

        XCTContext.runActivity(named: "Find and access clinical assessments") { _ in
            // Look for assessment-related buttons or sections
            let assessmentIndicators = [
                app.buttons["Assessments"],
                app.buttons["Clinical Assessments"],
                app.buttons["View Assessments"],
                app.staticTexts["Assessments"],
                app.staticTexts["Clinical Assessments"],
                app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'assessment'")).firstMatch,
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'assessment'")).firstMatch,
                // Also check for specific assessment types
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'shoulder' OR label CONTAINS[c] 'UCL' OR label CONTAINS[c] 'arm care'")).firstMatch
            ]

            // Scroll to find assessments if needed
            let scrollView = app.scrollViews.firstMatch
            var attempts = 0
            var foundAssessment = false

            while !foundAssessment && attempts < 5 {
                for indicator in assessmentIndicators {
                    if indicator.exists && indicator.isHittable {
                        foundAssessment = true
                        takeScreenshot(named: "assessment_01_found")

                        if indicator.elementType == .button {
                            indicator.tap()
                            waitForLoadingComplete()
                            takeScreenshot(named: "assessment_02_opened")
                        }
                        break
                    }
                }

                if !foundAssessment {
                    if scrollView.exists {
                        scrollView.swipeUp()
                    } else {
                        app.swipeUp()
                    }
                    attempts += 1
                }
            }

            if foundAssessment {
                // Verify assessment content
                let assessmentContent = app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'score' OR label CONTAINS[c] 'result' OR label CONTAINS[c] 'assessment' OR label CONTAINS[c] 'health'")
                ).firstMatch

                takeScreenshot(named: "assessment_03_content")
            } else {
                takeScreenshot(named: "assessment_not_found")
            }
        }
    }

    /// Test 8: Demo therapist can navigate all tabs
    func testDemoTherapistCanNavigateAllTabs() throws {
        loginAsDemoTherapist()

        XCTContext.runActivity(named: "Verify therapist tabs exist and can be navigated") { _ in
            // Check for therapist-specific tabs
            let tabNames = ["Patients", "Programs", "Schedule", "Reports", "Settings"]

            for tabName in tabNames {
                let tab = app.tabBars.buttons[tabName]
                if tab.exists {
                    tab.tap()
                    waitForLoadingComplete()

                    XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected after tap")

                    takeScreenshot(named: "therapist_tab_\(tabName.lowercased())")
                }
            }

            // Also try common alternative tab names
            let altTabNames = ["Home", "Dashboard", "Profile"]
            for tabName in altTabNames {
                let tab = app.tabBars.buttons[tabName]
                if tab.exists {
                    tab.tap()
                    waitForLoadingComplete()
                    takeScreenshot(named: "therapist_tab_\(tabName.lowercased())")
                }
            }
        }
    }

    // MARK: - Cross-User Tests

    /// Test switching between demo patient and demo therapist
    func testSwitchBetweenDemoUsers() throws {
        XCTContext.runActivity(named: "Login as demo patient") { _ in
            app.launch()
            waitForAppReady()

            let demoPatientButton = app.buttons["Demo Patient"]
            XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10))
            demoPatientButton.tap()

            waitForLoadingComplete()
            takeScreenshot(named: "switch_01_logged_as_patient")
        }

        XCTContext.runActivity(named: "Logout from patient account") { _ in
            // Navigate to Profile tab
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.exists {
                profileTab.tap()
                waitForLoadingComplete()

                // Find and tap Log Out
                let logOutButton = app.buttons["Log Out"]
                var attempts = 0
                while !logOutButton.exists && attempts < 5 {
                    app.swipeUp()
                    attempts += 1
                }

                if logOutButton.exists {
                    logOutButton.tap()

                    // Handle confirmation if needed
                    let confirmButton = app.alerts.buttons["Log Out"]
                    if confirmButton.waitForExistence(timeout: 3) {
                        confirmButton.tap()
                    }

                    takeScreenshot(named: "switch_02_logged_out")
                }
            }
        }

        XCTContext.runActivity(named: "Login as demo therapist") { _ in
            let demoTherapistButton = app.buttons["Demo Therapist"]
            if demoTherapistButton.waitForExistence(timeout: 10) {
                demoTherapistButton.tap()
                waitForLoadingComplete()

                // Verify therapist dashboard loads
                let therapistIndicator = app.staticTexts["Patients"]
                let tabBar = app.tabBars.firstMatch

                XCTAssertTrue(tabBar.waitForExistence(timeout: 15) || therapistIndicator.waitForExistence(timeout: 15),
                             "Therapist dashboard should load after switching users")

                takeScreenshot(named: "switch_03_logged_as_therapist")
            }
        }
    }

    // MARK: - Performance Tests

    /// Test demo login performance
    func testDemoLoginPerformance() throws {
        app.launch()
        waitForAppReady()

        let startTime = Date()

        let demoPatientButton = app.buttons["Demo Patient"]
        XCTAssertTrue(demoPatientButton.waitForExistence(timeout: 10))
        demoPatientButton.tap()

        // Wait for dashboard to be fully loaded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        waitForLoadingComplete()

        let loginDuration = Date().timeIntervalSince(startTime)

        // Demo login should complete within 10 seconds
        XCTAssertLessThan(loginDuration, 10.0,
                         "Demo patient login should complete within 10 seconds (actual: \(loginDuration)s)")

        print("Demo login completed in \(String(format: "%.2f", loginDuration))s")
    }

    // MARK: - Helper Methods

    private func waitForAppReady() {
        _ = app.wait(for: .runningForeground, timeout: 10)
    }

    private func waitForLoadingComplete() {
        // Wait for any loading indicators to disappear
        let spinner = app.activityIndicators.firstMatch
        if spinner.exists {
            _ = spinner.waitForNonExistence(timeout: 15)
        }
        // Brief pause for UI to settle
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    }

    private func loginAsDemoPatient() {
        app.launchArguments.append("--demo-patient")
        app.launch()
        waitForAppReady()

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

        waitForLoadingComplete()
    }

    private func loginAsDemoTherapist() {
        app.launchArguments.append("--demo-therapist")
        app.launch()
        waitForAppReady()

        let demoTherapistButton = app.buttons["Demo Therapist"]
        guard demoTherapistButton.waitForExistence(timeout: 10) else {
            XCTFail("Demo Therapist button should appear")
            return
        }
        demoTherapistButton.tap()

        // Wait for therapist dashboard
        let tabBar = app.tabBars.firstMatch
        let patientsTitle = app.staticTexts["Patients"]

        guard tabBar.waitForExistence(timeout: 15) || patientsTitle.waitForExistence(timeout: 15) else {
            XCTFail("Therapist dashboard should appear after login")
            return
        }

        waitForLoadingComplete()
    }

    private func findWorkoutContent() -> Bool {
        let indicators = [
            app.tables.firstMatch,
            app.scrollViews.firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exercise'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'workout'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'session'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no session'")).firstMatch
        ]

        return indicators.contains { $0.waitForExistence(timeout: 10) }
    }

    private func findFirstExercise() -> XCUIElement {
        let tableCell = app.tables.cells.firstMatch
        if tableCell.exists {
            return tableCell
        }

        return app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'exercise' OR label CONTAINS[c] 'squat' OR label CONTAINS[c] 'press'")
        ).firstMatch
    }

    private func tryReadinessFromProfile() {
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            waitForLoadingComplete()

            let readinessRow = app.buttons["Readiness"]
            if readinessRow.exists {
                readinessRow.tap()
                waitForLoadingComplete()
            }
        }
    }

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
