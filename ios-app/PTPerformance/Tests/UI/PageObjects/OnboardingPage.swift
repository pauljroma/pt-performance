//
//  OnboardingPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Onboarding screens
//  BUILD 95 - Agent 2: Onboarding E2E Tests
//

import XCTest

/// Page Object representing the Onboarding flow
struct OnboardingPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    // Navigation
    var skipButton: XCUIElement {
        app.buttons["Skip"]
    }

    var getStartedButton: XCUIElement {
        app.buttons["Get Started"]
    }

    var pageIndicator: XCUIElement {
        app.pageIndicators.firstMatch
    }

    // Page 1: Welcome
    var welcomeTitle: XCUIElement {
        app.staticTexts["Welcome to PT Performance"]
    }

    var welcomeDescription: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'complete platform'")).firstMatch
    }

    // Page 2: For Therapists
    var therapistTitle: XCUIElement {
        app.staticTexts["For Therapists"]
    }

    var therapistDescription: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Create custom exercise programs'")).firstMatch
    }

    // Page 3: For Patients
    var patientTitle: XCUIElement {
        app.staticTexts["For Patients"]
    }

    var patientDescription: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Log your workouts'")).firstMatch
    }

    // Page 4: Analyze Progress
    var analyticsTitle: XCUIElement {
        app.staticTexts["Analyze Progress"]
    }

    var analyticsDescription: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'detailed analytics'")).firstMatch
    }

    // Page 5: Get Started
    var getStartedTitle: XCUIElement {
        app.staticTexts["Get Started"]
    }

    var getStartedDescription: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'all set'")).firstMatch
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Navigation Actions

    /// Swipe left to go to next page
    @discardableResult
    func swipeToNextPage() -> Self {
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let startPoint = coordinate.withOffset(CGVector(dx: 100, dy: 0))
        let endPoint = coordinate.withOffset(CGVector(dx: -100, dy: 0))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1)) // Wait for animation
        return self
    }

    /// Swipe right to go to previous page
    @discardableResult
    func swipeToPreviousPage() -> Self {
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let startPoint = coordinate.withOffset(CGVector(dx: -100, dy: 0))
        let endPoint = coordinate.withOffset(CGVector(dx: 100, dy: 0))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1)) // Wait for animation
        return self
    }

    /// Tap skip button
    @discardableResult
    func tapSkip() -> Self {
        TestHelpers.safeTap(skipButton, named: "Skip Button")
        return self
    }

    /// Tap get started button
    @discardableResult
    func tapGetStarted() -> Self {
        TestHelpers.safeTap(getStartedButton, named: "Get Started Button")
        return self
    }

    // MARK: - Assertions

    /// Assert onboarding is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(
            welcomeTitle,
            named: "Onboarding Welcome Screen",
            timeout: 5
        )
    }

    /// Assert page 1 (Welcome) is displayed
    func assertWelcomePageDisplayed() {
        TestHelpers.assertExists(welcomeTitle, named: "Welcome Title")
        TestHelpers.assertExists(welcomeDescription, named: "Welcome Description")
        TestHelpers.assertExists(skipButton, named: "Skip Button")
        TestHelpers.assertExists(pageIndicator, named: "Page Indicator")
    }

    /// Assert page 2 (For Therapists) is displayed
    func assertTherapistPageDisplayed() {
        TestHelpers.assertExists(therapistTitle, named: "Therapist Title", timeout: 2)
        TestHelpers.assertExists(therapistDescription, named: "Therapist Description")
        TestHelpers.assertExists(skipButton, named: "Skip Button")
    }

    /// Assert page 3 (For Patients) is displayed
    func assertPatientPageDisplayed() {
        TestHelpers.assertExists(patientTitle, named: "Patient Title", timeout: 2)
        TestHelpers.assertExists(patientDescription, named: "Patient Description")
        TestHelpers.assertExists(skipButton, named: "Skip Button")
    }

    /// Assert page 4 (Analyze Progress) is displayed
    func assertAnalyticsPageDisplayed() {
        TestHelpers.assertExists(analyticsTitle, named: "Analytics Title", timeout: 2)
        TestHelpers.assertExists(analyticsDescription, named: "Analytics Description")
        TestHelpers.assertExists(skipButton, named: "Skip Button")
    }

    /// Assert page 5 (Get Started) is displayed
    func assertGetStartedPageDisplayed() {
        TestHelpers.assertExists(getStartedTitle, named: "Get Started Title", timeout: 2)
        TestHelpers.assertExists(getStartedButton, named: "Get Started Button")
        TestHelpers.assertDoesNotExist(skipButton, named: "Skip Button")
    }

    /// Assert onboarding is dismissed
    func assertIsDismissed() {
        let dismissed = TestHelpers.waitForElementToDisappear(welcomeTitle, timeout: 3)
        XCTAssertTrue(dismissed, "Onboarding should be dismissed")
    }

    /// Assert onboarding does not appear
    func assertDoesNotAppear() {
        let appeared = welcomeTitle.waitForExistence(timeout: 3)
        XCTAssertFalse(appeared, "Onboarding should not appear")
    }

    // MARK: - Workflows

    /// Complete the entire onboarding flow
    func completeOnboarding() {
        assertWelcomePageDisplayed()

        // Navigate through all pages
        swipeToNextPage()
        assertTherapistPageDisplayed()

        swipeToNextPage()
        assertPatientPageDisplayed()

        swipeToNextPage()
        assertAnalyticsPageDisplayed()

        swipeToNextPage()
        assertGetStartedPageDisplayed()

        // Tap Get Started
        tapGetStarted()
    }

    /// Skip onboarding from first page
    func skipOnboarding() {
        assertWelcomePageDisplayed()
        tapSkip()
    }

    /// Navigate to a specific page (0-indexed)
    /// - Parameter pageIndex: The page index (0-4)
    func navigateToPage(_ pageIndex: Int) {
        guard pageIndex >= 0 && pageIndex <= 4 else {
            XCTFail("Invalid page index: \(pageIndex). Must be 0-4")
            return
        }

        // Swipe to the target page
        for _ in 0..<pageIndex {
            swipeToNextPage()
        }
    }

    /// Verify navigation back from a page
    /// - Parameter fromPage: Starting page index (1-4)
    func verifyBackwardNavigation(fromPage: Int) {
        navigateToPage(fromPage)

        // Navigate back one page
        swipeToPreviousPage()

        // Verify we're on the previous page
        switch fromPage - 1 {
        case 0:
            assertWelcomePageDisplayed()
        case 1:
            assertTherapistPageDisplayed()
        case 2:
            assertPatientPageDisplayed()
        case 3:
            assertAnalyticsPageDisplayed()
        default:
            XCTFail("Invalid page index for backward navigation")
        }
    }
}
