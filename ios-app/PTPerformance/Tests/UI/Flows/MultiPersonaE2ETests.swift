//
//  MultiPersonaE2ETests.swift
//  PTPerformanceUITests
//
//  E2E tests for all 10 test user personas
//  Validates that each persona can log in, navigate all tabs, and see data without errors
//

import XCTest

/// E2E tests that exercise all 10 test user personas
///
/// Each test method:
/// 1. Launches the app with --auto-login-user-id <UUID>
/// 2. Waits for the patient dashboard to load
/// 3. Navigates Today, Programs, and Profile tabs
/// 4. Asserts no error alerts appear
/// 5. Captures screenshots at each hub for visual review
final class MultiPersonaE2ETests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Test User Definitions

    private struct TestPersona {
        let id: String
        let name: String
        let mode: String
        let sport: String
    }

    private static let personas: [TestPersona] = [
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000001", name: "Marcus Rivera", mode: "rehab", sport: "Baseball"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000002", name: "Alyssa Chen", mode: "rehab", sport: "Basketball"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000003", name: "Tyler Brooks", mode: "performance", sport: "Football"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000004", name: "Emma Fitzgerald", mode: "rehab", sport: "Soccer"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000005", name: "Jordan Williams", mode: "strength", sport: "CrossFit"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000006", name: "Sophia Nakamura", mode: "rehab", sport: "Swimming"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000007", name: "Deshawn Patterson", mode: "performance", sport: "Track"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000008", name: "Olivia Martinez", mode: "strength", sport: "Volleyball"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-000000000009", name: "Liam O'Connor", mode: "rehab", sport: "Hockey"),
        TestPersona(id: "aaaaaaaa-bbbb-cccc-dddd-00000000000a", name: "Isabella Rossi", mode: "strength", sport: "Tennis"),
    ]

    // MARK: - Launch Helper

    private func launchAsUser(_ persona: TestPersona) {
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", persona.id
        ]
        app.launchEnvironment = [
            "IS_RUNNING_UITEST": "1"
        ]
        app.launch()
    }

    // MARK: - Common Verification Flow

    private func verifyAllHubs(for persona: TestPersona) {
        let safeName = persona.name.replacingOccurrences(of: " ", with: "_").lowercased()

        // Wait for dashboard to load (tab bar appears)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "\(persona.name): Tab bar should appear after auto-login"
        )

        // Assert no error alerts on launch
        assertNoErrorAlerts(context: "\(persona.name) - launch")

        // MARK: Today Hub
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()
            waitForContentToLoad()
            assertNoErrorAlerts(context: "\(persona.name) - Today Hub")

            // Verify some content exists (session, workout, or empty state)
            let hasContent = app.scrollViews.firstMatch.exists ||
                             app.tables.firstMatch.exists ||
                             app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'session' OR label CONTAINS[c] 'today' OR label CONTAINS[c] 'workout' OR label CONTAINS[c] 'rest day' OR label CONTAINS[c] 'no session'")).firstMatch.exists

            XCTAssertTrue(hasContent, "\(persona.name): Today Hub should display content")

            takeScreenshot(named: "\(safeName)_today_hub")
        }

        // MARK: Programs Hub
        let programsTab = app.tabBars.buttons["Programs"]
        if programsTab.exists {
            programsTab.tap()
            waitForContentToLoad()
            assertNoErrorAlerts(context: "\(persona.name) - Programs Hub")

            // Programs tab should load (list, empty state, or segmented picker)
            let hasContent = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                             app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'program' OR label CONTAINS[c] 'daily' OR label CONTAINS[c] 'no active'")).firstMatch.waitForExistence(timeout: 5) ||
                             app.segmentedControls.firstMatch.waitForExistence(timeout: 5)

            XCTAssertTrue(hasContent, "\(persona.name): Programs Hub should display content")

            takeScreenshot(named: "\(safeName)_programs_hub")
        }

        // MARK: Profile Hub
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            waitForContentToLoad()
            assertNoErrorAlerts(context: "\(persona.name) - Profile Hub")

            // Profile should show sections
            let profileContent = app.tables.firstMatch.waitForExistence(timeout: 10) ||
                                 app.staticTexts["Health & Wellness"].waitForExistence(timeout: 5) ||
                                 app.staticTexts["Account"].waitForExistence(timeout: 5)

            XCTAssertTrue(profileContent, "\(persona.name): Profile Hub should display content")

            takeScreenshot(named: "\(safeName)_profile_hub")

            // Scroll down to verify more sections load
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
                waitForContentToLoad()
                assertNoErrorAlerts(context: "\(persona.name) - Profile Hub scrolled")
                takeScreenshot(named: "\(safeName)_profile_hub_scrolled")
            }
        }

        // Final stability check
        assertNoErrorAlerts(context: "\(persona.name) - final")
    }

    // MARK: - Persona Tests

    func testPersona_01_MarcusRivera_RehabBaseball() throws {
        let persona = Self.personas[0]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_02_AlyssaChen_RehabBasketball() throws {
        let persona = Self.personas[1]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_03_TylerBrooks_PerfFootball() throws {
        let persona = Self.personas[2]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_04_EmmaFitzgerald_RehabSoccer() throws {
        let persona = Self.personas[3]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_05_JordanWilliams_StrengthCrossfit() throws {
        let persona = Self.personas[4]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_06_SophiaNakamura_RehabSwimming() throws {
        let persona = Self.personas[5]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_07_DeshawnPatterson_PerfTrack() throws {
        let persona = Self.personas[6]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_08_OliviaMartinez_StrengthVolleyball() throws {
        let persona = Self.personas[7]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_09_LiamOConnor_RehabHockey() throws {
        let persona = Self.personas[8]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    func testPersona_10_IsabellaRossi_StrengthTennis() throws {
        let persona = Self.personas[9]
        launchAsUser(persona)
        verifyAllHubs(for: persona)
    }

    // MARK: - Helper Methods

    private func waitForContentToLoad() {
        // Wait for loading indicators to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForNonExistence(timeout: 15)
        }
        // Small buffer for animations
        Thread.sleep(forTimeInterval: 0.5)
    }

    private func assertNoErrorAlerts(context: String) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let alertLabel = alert.label
            // Dismiss the alert for test continuity
            let okButton = alert.buttons.firstMatch
            if okButton.exists { okButton.tap() }
            XCTFail("\(context): Unexpected error alert — \(alertLabel)")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - XCUIElement Convenience

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
