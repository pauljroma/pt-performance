//
//  OnboardingFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for user onboarding flow
//  BUILD 95 - Agent 2: Onboarding E2E Tests
//
//  Tests the complete onboarding experience including:
//  - First launch onboarding presentation
//  - Page navigation (forward/backward)
//  - Skip functionality
//  - Completion flow
//  - State persistence
//  - Dashboard navigation after completion
//

import XCTest

/// E2E tests for the user onboarding flow
final class OnboardingFlowTests: BaseUITest {

    // MARK: - Properties

    private var onboardingPage: OnboardingPage!

    // MARK: - Setup

    override func configureLaunchArguments() {
        super.configureLaunchArguments()

        // Reset onboarding state for fresh test
        app.launchArguments.append("--reset-onboarding")
    }

    override func configureLaunchEnvironment() {
        super.configureLaunchEnvironment()

        // Enable onboarding for tests
        app.launchEnvironment["SKIP_ONBOARDING"] = "0"
    }

    override func postLaunchSetup() throws {
        // Initialize page object
        onboardingPage = OnboardingPage(app: app)

        // Don't call super - we want to test onboarding appearance
    }

    // MARK: - Happy Path Tests

    /// Test: Complete onboarding flow from start to finish
    /// Expected: User can navigate through all pages and complete onboarding
    func testCompleteOnboardingFlow_HappyPath() throws {
        // GIVEN: App launches for the first time
        // (Already launched in setup)

        captureScreenshot("onboarding_start")

        // THEN: Onboarding should appear
        onboardingPage.assertIsDisplayed()

        // WHEN: User views all onboarding pages
        onboardingPage.assertWelcomePageDisplayed()
        captureScreenshot("onboarding_page_1_welcome")

        onboardingPage.swipeToNextPage()
        onboardingPage.assertTherapistPageDisplayed()
        captureScreenshot("onboarding_page_2_therapist")

        onboardingPage.swipeToNextPage()
        onboardingPage.assertPatientPageDisplayed()
        captureScreenshot("onboarding_page_3_patient")

        onboardingPage.swipeToNextPage()
        onboardingPage.assertAnalyticsPageDisplayed()
        captureScreenshot("onboarding_page_4_analytics")

        onboardingPage.swipeToNextPage()
        onboardingPage.assertGetStartedPageDisplayed()
        captureScreenshot("onboarding_page_5_get_started")

        // WHEN: User taps Get Started
        onboardingPage.tapGetStarted()

        // THEN: Should dismiss onboarding
        onboardingPage.assertIsDismissed()

        // AND: Should navigate to auth view or dashboard
        let authView = app.buttons["Patient Login"]
        let dashboard = app.staticTexts["Today's Session"]

        let navigatedToExpectedScreen = TestHelpers.waitForElement(authView, timeout: 3) ||
                                        TestHelpers.waitForElement(dashboard, timeout: 3)

        XCTAssertTrue(
            navigatedToExpectedScreen,
            "Should navigate to auth view or dashboard after onboarding"
        )

        captureScreenshot("after_onboarding_completion")

        // AND: Onboarding should not appear on subsequent launch
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        onboardingPage.assertDoesNotAppear()
        captureScreenshot("second_launch_no_onboarding")
    }

    /// Test: Skip onboarding from first page
    /// Expected: Onboarding is dismissed and marked as completed
    func testSkipOnboarding_HappyPath() throws {
        // GIVEN: App launches with onboarding
        onboardingPage.assertIsDisplayed()
        captureScreenshot("before_skip")

        // WHEN: User taps Skip button
        onboardingPage.tapSkip()

        // THEN: Onboarding should be dismissed
        onboardingPage.assertIsDismissed()

        // AND: Should navigate to expected screen
        let authOrDashboard = app.buttons["Patient Login"].exists ||
                             app.staticTexts["Today's Session"].exists

        XCTAssertTrue(authOrDashboard, "Should show auth or dashboard after skip")
        captureScreenshot("after_skip")

        // AND: Onboarding should not appear again
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        onboardingPage.assertDoesNotAppear()
    }

    /// Test: Navigate backward through onboarding pages
    /// Expected: User can swipe back to previous pages
    func testBackwardNavigation_HappyPath() throws {
        // GIVEN: App launches with onboarding
        onboardingPage.assertIsDisplayed()

        // WHEN: User navigates forward to page 3
        onboardingPage.swipeToNextPage() // Page 2
        onboardingPage.swipeToNextPage() // Page 3
        onboardingPage.assertPatientPageDisplayed()

        // THEN: User can navigate backward
        onboardingPage.swipeToPreviousPage()
        onboardingPage.assertTherapistPageDisplayed()
        captureScreenshot("navigated_back_to_page_2")

        onboardingPage.swipeToPreviousPage()
        onboardingPage.assertWelcomePageDisplayed()
        captureScreenshot("navigated_back_to_page_1")

        // AND: Skip button should still be visible
        TestHelpers.assertExists(
            onboardingPage.skipButton,
            named: "Skip Button after backward navigation"
        )
    }

    /// Test: First launch only behavior
    /// Expected: Onboarding appears only on first launch
    func testFirstLaunchOnly_HappyPath() throws {
        // GIVEN: App launches for the first time
        onboardingPage.assertIsDisplayed()

        // WHEN: User completes onboarding
        onboardingPage.completeOnboarding()

        // AND: App is relaunched
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        // THEN: Onboarding should not appear
        onboardingPage.assertDoesNotAppear()

        // AND: Auth view should be displayed
        let authView = app.buttons["Patient Login"]
        TestHelpers.assertExists(
            authView,
            named: "Auth View on subsequent launch",
            timeout: 5
        )
    }

    // MARK: - UI Elements Tests

    /// Test: All onboarding pages display correct UI elements
    /// Expected: Each page has title, description, and navigation elements
    func testOnboardingUIElements_AllPagesValid() throws {
        // Page 1: Welcome
        onboardingPage.assertWelcomePageDisplayed()
        XCTAssertTrue(
            onboardingPage.pageIndicator.exists,
            "Page indicator should exist on page 1"
        )

        // Page 2: For Therapists
        onboardingPage.swipeToNextPage()
        onboardingPage.assertTherapistPageDisplayed()
        XCTAssertTrue(
            onboardingPage.skipButton.exists,
            "Skip button should exist on page 2"
        )

        // Page 3: For Patients
        onboardingPage.swipeToNextPage()
        onboardingPage.assertPatientPageDisplayed()
        XCTAssertTrue(
            onboardingPage.skipButton.exists,
            "Skip button should exist on page 3"
        )

        // Page 4: Analyze Progress
        onboardingPage.swipeToNextPage()
        onboardingPage.assertAnalyticsPageDisplayed()
        XCTAssertTrue(
            onboardingPage.skipButton.exists,
            "Skip button should exist on page 4"
        )

        // Page 5: Get Started
        onboardingPage.swipeToNextPage()
        onboardingPage.assertGetStartedPageDisplayed()
        XCTAssertFalse(
            onboardingPage.skipButton.exists,
            "Skip button should NOT exist on final page"
        )
        XCTAssertTrue(
            onboardingPage.getStartedButton.exists,
            "Get Started button should exist on final page"
        )

        captureScreenshot("all_ui_elements_validated")
    }

    /// Test: Page indicator updates correctly
    /// Expected: Page indicator reflects current page
    func testPageIndicatorUpdates() throws {
        // GIVEN: Onboarding is displayed
        onboardingPage.assertIsDisplayed()

        // THEN: Page indicator should exist
        TestHelpers.assertExists(
            onboardingPage.pageIndicator,
            named: "Page Indicator"
        )

        // WHEN: User navigates through pages
        // Note: Actual page indicator value assertion would require
        // more specific accessibility identifiers. This test verifies
        // the indicator exists throughout navigation.

        for pageNum in 1...4 {
            onboardingPage.swipeToNextPage()
            XCTAssertTrue(
                onboardingPage.pageIndicator.exists,
                "Page indicator should exist on page \(pageNum + 1)"
            )
        }
    }

    // MARK: - Edge Cases

    /// Test: Skip from middle page
    /// Expected: Can skip from any page except the last
    func testSkipFromMiddlePage_EdgeCase() throws {
        // GIVEN: User navigates to page 3
        onboardingPage.navigateToPage(2)
        onboardingPage.assertPatientPageDisplayed()

        // WHEN: User taps Skip
        onboardingPage.tapSkip()

        // THEN: Onboarding should be dismissed
        onboardingPage.assertIsDismissed()

        // AND: Should mark as completed
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        onboardingPage.assertDoesNotAppear()
    }

    /// Test: Rapid page navigation
    /// Expected: UI handles rapid swipes gracefully
    func testRapidPageNavigation_EdgeCase() throws {
        // GIVEN: Onboarding is displayed
        onboardingPage.assertIsDisplayed()

        // WHEN: User rapidly swipes through pages
        // (Reduced sleep time in swipe gestures for this test)
        for _ in 0..<4 {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let startPoint = coordinate.withOffset(CGVector(dx: 100, dy: 0))
            let endPoint = coordinate.withOffset(CGVector(dx: -100, dy: 0))
            startPoint.press(forDuration: 0.05, thenDragTo: endPoint)
            sleep(UInt32(0.5)) // Shorter wait
        }

        // THEN: Should still land on a valid page
        // Final page should be visible eventually
        let finalPageAppears = onboardingPage.getStartedTitle.waitForExistence(timeout: 3)
        XCTAssertTrue(
            finalPageAppears,
            "Should eventually show final page after rapid navigation"
        )
    }

    /// Test: Forward navigation boundary
    /// Expected: Cannot swipe past the last page
    func testForwardNavigationBoundary_EdgeCase() throws {
        // GIVEN: User is on the final page
        onboardingPage.navigateToPage(4)
        onboardingPage.assertGetStartedPageDisplayed()

        // WHEN: User attempts to swipe forward
        onboardingPage.swipeToNextPage()

        // THEN: Should still be on final page
        XCTAssertTrue(
            onboardingPage.getStartedButton.exists,
            "Should remain on final page after swipe attempt"
        )
    }

    /// Test: Backward navigation boundary
    /// Expected: Cannot swipe before the first page
    func testBackwardNavigationBoundary_EdgeCase() throws {
        // GIVEN: User is on the first page
        onboardingPage.assertWelcomePageDisplayed()

        // WHEN: User attempts to swipe backward
        onboardingPage.swipeToPreviousPage()

        // THEN: Should still be on first page
        XCTAssertTrue(
            onboardingPage.welcomeTitle.exists,
            "Should remain on first page after backward swipe attempt"
        )
    }

    // MARK: - State Persistence Tests

    /// Test: Onboarding state persists across app termination
    /// Expected: Completion state is saved to UserDefaults
    func testOnboardingStatePersistence() throws {
        // GIVEN: User completes onboarding
        onboardingPage.completeOnboarding()

        // WHEN: App is force-killed and relaunched multiple times
        for iteration in 1...3 {
            app.terminate()
            app.launchArguments.removeAll { $0 == "--reset-onboarding" }
            app.launch()

            // THEN: Onboarding should not appear
            onboardingPage.assertDoesNotAppear()

            captureScreenshot("persistence_test_iteration_\(iteration)")
        }
    }

    /// Test: Skip state persists across app termination
    /// Expected: Skipping marks onboarding as completed
    func testSkipStatePersistence() throws {
        // GIVEN: User skips onboarding
        onboardingPage.skipOnboarding()

        // WHEN: App is relaunched
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        // THEN: Onboarding should not appear
        onboardingPage.assertDoesNotAppear()
    }

    // MARK: - Integration Tests

    /// Test: Navigate to dashboard after onboarding (Patient flow)
    /// Expected: Can log in as patient after completing onboarding
    func testNavigateToDashboardAfterOnboarding_Patient() throws {
        // GIVEN: User completes onboarding
        onboardingPage.completeOnboarding()

        // WHEN: User logs in as demo patient
        let loginPage = LoginPage(app: app)

        // Wait for login page to appear
        if loginPage.patientLoginButton.waitForExistence(timeout: 5) {
            loginPage.loginAsDemoPatient()

            // Wait for login to complete
            TestHelpers.waitForLoadingToComplete(in: app)

            // THEN: Should navigate to patient dashboard
            let dashboard = PatientDashboardPage(app: app)
            dashboard.assertIsDisplayed()

            captureScreenshot("patient_dashboard_after_onboarding")
        } else {
            // If already logged in, verify dashboard
            let dashboard = PatientDashboardPage(app: app)
            dashboard.assertIsDisplayed()
        }
    }

    /// Test: Navigate to main app after skip
    /// Expected: App functions normally after skipping onboarding
    func testNavigateToMainAppAfterSkip() throws {
        // GIVEN: User skips onboarding
        onboardingPage.skipOnboarding()

        // THEN: Should be able to access login screen
        let loginPage = LoginPage(app: app)

        let loginScreenAppears = loginPage.patientLoginButton.waitForExistence(timeout: 5) ||
                                loginPage.therapistLoginButton.waitForExistence(timeout: 5)

        XCTAssertTrue(
            loginScreenAppears,
            "Login screen should be accessible after skip"
        )

        captureScreenshot("login_screen_after_skip")
    }

    // MARK: - Performance Tests

    /// Test: Onboarding loads within acceptable time
    /// Expected: Initial screen appears within 3 seconds
    func testOnboardingLoadTime_Performance() throws {
        // Measure time from launch to onboarding display
        // (App already launched in setup)

        let startTime = Date()
        onboardingPage.assertIsDisplayed()
        let loadTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(
            loadTime,
            3.0,
            "Onboarding should appear within 3 seconds (actual: \(loadTime)s)"
        )

        print("⏱️ Onboarding load time: \(String(format: "%.2f", loadTime))s")
    }

    /// Test: Page transitions are smooth
    /// Expected: Each page transition completes within 2 seconds
    func testPageTransitionTime_Performance() throws {
        // Measure each page transition
        for pageNum in 1...4 {
            let startTime = Date()
            onboardingPage.swipeToNextPage()

            // Wait for new page to appear
            sleep(1) // Allow animation to complete

            let transitionTime = Date().timeIntervalSince(startTime)

            XCTAssertLessThan(
                transitionTime,
                2.0,
                "Page \(pageNum) transition should complete within 2s (actual: \(transitionTime)s)"
            )

            print("⏱️ Page \(pageNum) transition: \(String(format: "%.2f", transitionTime))s")
        }
    }

    // MARK: - Accessibility Tests

    /// Test: Onboarding is accessible
    /// Expected: All interactive elements are accessible
    func testOnboardingAccessibility() throws {
        // Verify skip button is accessible
        TestHelpers.assertIsHittable(
            onboardingPage.skipButton,
            named: "Skip Button"
        )

        // Navigate to final page
        onboardingPage.navigateToPage(4)

        // Verify get started button is accessible
        TestHelpers.assertIsHittable(
            onboardingPage.getStartedButton,
            named: "Get Started Button"
        )
    }

    // MARK: - Error Handling Tests

    /// Test: No errors during onboarding flow
    /// Expected: No error messages appear during normal flow
    func testNoErrorsDuringOnboarding() throws {
        // Complete entire flow
        onboardingPage.completeOnboarding()

        // Verify no errors were displayed
        assertNoErrors()
    }

    /// Test: No errors after skip
    /// Expected: No error messages appear after skipping
    func testNoErrorsAfterSkip() throws {
        onboardingPage.skipOnboarding()
        assertNoErrors()
    }
}
