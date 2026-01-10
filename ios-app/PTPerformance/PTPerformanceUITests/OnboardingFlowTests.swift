import XCTest

/// E2E tests for user onboarding flow
///
/// Tests the complete onboarding experience including:
/// - First launch onboarding presentation
/// - Page navigation (forward/backward)
/// - Skip functionality
/// - Completion flow
/// - State persistence
final class OnboardingFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false

        app = XCUIApplication()

        // Reset onboarding state for fresh test
        app.launchArguments = ["--uitesting", "--reset-onboarding"]

        // Enable screenshots on failure
        if #available(iOS 13.0, *) {
            addUIInterruptionMonitor(withDescription: "System Dialog") { alert in
                return false
            }
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    // MARK: - Test Cases

    /// Test complete onboarding flow from start to finish
    func testCompleteOnboardingFlow() throws {
        // Given: App launches for the first time
        app.launch()

        // Wait for onboarding to appear
        let onboardingTitle = app.staticTexts["Welcome to PT Performance"]
        XCTAssertTrue(onboardingTitle.waitForExistence(timeout: 5), "Onboarding should appear on first launch")

        // When: User swipes through all pages
        let pageIndicator = app.pageIndicators.firstMatch
        XCTAssertTrue(pageIndicator.exists, "Page indicator should be visible")

        // Page 1: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].exists, "Welcome page title should be visible")
        XCTAssertTrue(app.images["figure.wave"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome'")).firstMatch.exists, "Welcome icon or text should be visible")

        // Swipe to Page 2: For Therapists
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Therapists"].waitForExistence(timeout: 2), "For Therapists page should appear")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Create custom exercise programs'")).firstMatch.exists, "Therapist description should be visible")

        // Swipe to Page 3: For Patients
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Patients"].waitForExistence(timeout: 2), "For Patients page should appear")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Log your workouts'")).firstMatch.exists, "Patient description should be visible")

        // Swipe to Page 4: Analyze Progress
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["Analyze Progress"].waitForExistence(timeout: 2), "Analyze Progress page should appear")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'detailed analytics'")).firstMatch.exists, "Analytics description should be visible")

        // Swipe to Page 5: Get Started
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["Get Started"].waitForExistence(timeout: 2), "Get Started page should appear")

        // Then: Get Started button should be visible
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 2), "Get Started button should appear on final page")

        // Take screenshot before completion
        takeScreenshot(named: "onboarding_final_page")

        // When: User taps Get Started
        getStartedButton.tap()

        // Then: Should navigate to auth view or main dashboard
        let authOrDashboard = app.staticTexts["PT Performance"].exists ||
                              app.staticTexts["Sign in as Demo Patient"].exists ||
                              app.tabBars.firstMatch.exists
        XCTAssertTrue(authOrDashboard, "Should navigate to auth or dashboard after onboarding")

        // Verify onboarding doesn't appear again
        app.terminate()
        app.launch()

        // Onboarding should NOT appear on second launch
        let onboardingTitleReappears = app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 3)
        XCTAssertFalse(onboardingTitleReappears, "Onboarding should not appear on subsequent launches")
    }

    /// Test skip functionality during onboarding
    func testSkipOnboarding() throws {
        // Given: App launches with onboarding
        app.launch()

        let onboardingTitle = app.staticTexts["Welcome to PT Performance"]
        XCTAssertTrue(onboardingTitle.waitForExistence(timeout: 5), "Onboarding should appear")

        // When: User taps Skip button
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.exists, "Skip button should be visible on first page")

        takeScreenshot(named: "onboarding_skip_button")
        skipButton.tap()

        // Then: Should dismiss onboarding and show auth/dashboard
        let onboardingDismissed = !app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 2)
        XCTAssertTrue(onboardingDismissed, "Onboarding should be dismissed after skip")

        // Verify we're on auth view or main view
        let authOrDashboard = app.staticTexts["PT Performance"].exists ||
                              app.buttons["Sign in as Demo Patient"].exists ||
                              app.tabBars.firstMatch.exists
        XCTAssertTrue(authOrDashboard, "Should show auth or dashboard after skip")

        // Verify onboarding is marked as completed (won't show again)
        app.terminate()
        app.launch()

        let onboardingReappears = app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 3)
        XCTAssertFalse(onboardingReappears, "Onboarding should not reappear after skip")
    }

    /// Test backward navigation through onboarding pages
    func testBackwardNavigation() throws {
        // Given: App launches with onboarding
        app.launch()

        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 5), "Onboarding should appear")

        // When: User swipes forward then backward
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Therapists"].waitForExistence(timeout: 2), "Should be on page 2")

        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Patients"].waitForExistence(timeout: 2), "Should be on page 3")

        // Then: Swipe right to go back
        swipeRightToPreviousPage()
        XCTAssertTrue(app.staticTexts["For Therapists"].waitForExistence(timeout: 2), "Should go back to page 2")

        swipeRightToPreviousPage()
        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 2), "Should go back to page 1")

        // Skip button should still be visible on first page
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button should be visible on first page")
    }

    /// Test that onboarding appears on first launch only
    func testFirstLaunchOnlyBehavior() throws {
        // Given: App launches for the first time
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()

        // Then: Onboarding should appear
        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 5), "Onboarding should appear on first launch")

        // When: Complete onboarding
        let getStartedButton = app.buttons["Get Started"]

        // Navigate to final page
        for _ in 1...4 {
            swipeLeftToNextPage()
        }

        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 2), "Should reach final page")
        getStartedButton.tap()

        // Restart app
        app.terminate()
        app.launchArguments = ["--uitesting"] // Remove reset flag
        app.launch()

        // Then: Onboarding should NOT appear
        let onboardingReappears = app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 3)
        XCTAssertFalse(onboardingReappears, "Onboarding should not appear on second launch")

        // Should show auth view instead
        XCTAssertTrue(app.staticTexts["PT Performance"].exists || app.buttons["Sign in as Demo Patient"].exists,
                     "Should show auth view on subsequent launches")
    }

    /// Test all UI elements are present and accessible
    func testOnboardingUIElements() throws {
        // Given: App launches with onboarding
        app.launch()

        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].waitForExistence(timeout: 5), "Onboarding should appear")

        // Then: All key UI elements should be present

        // Page 1
        XCTAssertTrue(app.staticTexts["Welcome to PT Performance"].exists, "Welcome title should exist")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'complete platform'")).firstMatch.exists,
                     "Welcome description should exist")
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button should exist")
        XCTAssertTrue(app.pageIndicators.firstMatch.exists, "Page indicator should exist")

        // Navigate and verify Page 2
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Therapists"].waitForExistence(timeout: 2), "Therapist title should exist")
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button should exist on page 2")

        // Navigate and verify Page 3
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["For Patients"].waitForExistence(timeout: 2), "Patient title should exist")
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button should exist on page 3")

        // Navigate and verify Page 4
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["Analyze Progress"].waitForExistence(timeout: 2), "Analytics title should exist")
        XCTAssertTrue(app.buttons["Skip"].exists, "Skip button should exist on page 4")

        // Navigate and verify Page 5
        swipeLeftToNextPage()
        XCTAssertTrue(app.staticTexts["Get Started"].waitForExistence(timeout: 2), "Final page title should exist")

        // Skip button should NOT exist on final page
        XCTAssertFalse(app.buttons["Skip"].exists, "Skip button should not exist on final page")

        // Get Started button should exist
        XCTAssertTrue(app.buttons["Get Started"].exists, "Get Started button should exist on final page")

        takeScreenshot(named: "onboarding_ui_elements")
    }

    // MARK: - Helper Methods

    /// Swipe left to go to next page
    private func swipeLeftToNextPage() {
        let app = XCUIApplication()
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let startPoint = coordinate.withOffset(CGVector(dx: 100, dy: 0))
        let endPoint = coordinate.withOffset(CGVector(dx: -100, dy: 0))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        sleep(1) // Wait for animation
    }

    /// Swipe right to go to previous page
    private func swipeRightToPreviousPage() {
        let app = XCUIApplication()
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let startPoint = coordinate.withOffset(CGVector(dx: -100, dy: 0))
        let endPoint = coordinate.withOffset(CGVector(dx: 100, dy: 0))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        sleep(1) // Wait for animation
    }

    /// Take a screenshot with a given name
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
