//
//  BaseUITest.swift
//  PTPerformanceUITests
//
//  Base test class with common setup and teardown
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import XCTest

/// Base class for all UI tests with common setup, teardown, and utilities
class BaseUITest: XCTestCase {

    // MARK: - Properties

    /// The main application instance
    var app: XCUIApplication!

    /// Screenshot helper for capturing test artifacts
    lazy var screenshots = ScreenshotHelper(testCase: self)

    /// Whether to capture screenshots at key test steps
    var captureKeySteps = false

    /// Whether to reset app state before each test
    var resetAppState = true

    /// Whether to skip login and start authenticated
    var startAuthenticated = false

    /// Test timeout values
    var standardTimeout: TimeInterval { TestHelpers.standardTimeout }
    var networkTimeout: TimeInterval { TestHelpers.networkTimeout }

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Continue after failures for better diagnostics
        continueAfterFailure = false

        // Initialize app
        app = XCUIApplication()

        // Configure app launch arguments
        configureLaunchArguments()

        // Configure launch environment
        configureLaunchEnvironment()

        // Launch app
        launchApp()

        // Perform post-launch setup
        try postLaunchSetup()
    }

    override func tearDownWithError() throws {
        // Capture final screenshot if test failed
        if screenshots.captureOnFailure {
            captureFailureStateIfNeeded()
        }

        // Terminate app
        app.terminate()
        app = nil

        try super.tearDownWithError()
    }

    // MARK: - Configuration

    /// Configure launch arguments for the app
    func configureLaunchArguments() {
        var args = [String]()

        // Enable UI testing mode
        args.append("UI-Testing")

        // Reset app state if needed
        if resetAppState {
            args.append("ResetState")
        }

        // Start authenticated if needed
        if startAuthenticated {
            args.append("StartAuthenticated")
        }

        // Disable animations for faster, more reliable tests
        args.append("DisableAnimations")

        // Use mock network layer (if available)
        args.append("UseMockNetwork")

        app.launchArguments = args
    }

    /// Configure launch environment variables
    func configureLaunchEnvironment() {
        var env = [String: String]()

        // Set test environment
        env["IS_RUNNING_UITEST"] = "1"

        // Disable onboarding
        env["SKIP_ONBOARDING"] = "1"

        // Use test database
        env["USE_TEST_DATABASE"] = "1"

        app.launchEnvironment = env
    }

    /// Launch the app
    func launchApp() {
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 10),
            "App should launch and reach foreground state"
        )
    }

    /// Perform setup actions after app launch
    func postLaunchSetup() throws {
        // Wait for app to be ready
        waitForAppReady()

        // Subclasses can override to add custom setup
    }

    /// Wait for app to be fully ready
    func waitForAppReady() {
        // Wait for initial loading to complete
        TestHelpers.waitForLoadingToComplete(in: app, timeout: networkTimeout)
    }

    // MARK: - Common Test Flows

    /// Login as demo patient
    func loginAsDemoPatient() {
        TestHelpers.performLogin(
            in: app,
            email: MockData.DemoPatient.email,
            password: MockData.DemoPatient.password,
            userType: "Patient"
        )

        // Wait for patient dashboard
        let dashboard = app.staticTexts["Today's Session"]
        TestHelpers.assertExists(dashboard, named: "Patient Dashboard")
    }

    /// Login as demo therapist
    func loginAsDemoTherapist() {
        TestHelpers.performLogin(
            in: app,
            email: MockData.DemoTherapist.email,
            password: MockData.DemoTherapist.password,
            userType: "Therapist"
        )

        // Wait for therapist dashboard
        let dashboard = app.staticTexts["Patients"]
        TestHelpers.assertExists(dashboard, named: "Therapist Dashboard")
    }

    /// Logout from the app
    func logout() {
        // Navigate to settings/profile
        let profileTab = app.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
        }

        // Tap logout button
        let logoutButton = app.buttons["Log Out"]
        if TestHelpers.waitForElement(logoutButton) {
            logoutButton.tap()

            // Confirm logout if alert appears
            let confirmButton = app.alerts.buttons["Log Out"]
            if confirmButton.exists {
                confirmButton.tap()
            }
        }

        // Verify we're back at login screen
        let loginScreen = app.buttons["Patient Login"]
        TestHelpers.assertExists(loginScreen, named: "Login Screen", timeout: 5)
    }

    // MARK: - Navigation Helpers

    /// Navigate to a specific tab
    /// - Parameter tabName: Name of the tab to navigate to
    func navigateToTab(_ tabName: String) {
        let tabButton = app.buttons[tabName]
        TestHelpers.safeTap(tabButton, named: "\(tabName) Tab")
    }

    /// Navigate back using navigation bar
    func navigateBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            XCTFail("Back button not found in navigation bar")
        }
    }

    /// Dismiss modal/sheet
    func dismissModal() {
        // Try swipe down (for sheets)
        app.swipeDown()

        // If that doesn't work, look for close/cancel button
        let closeButton = app.buttons["Close"]
        if closeButton.exists {
            closeButton.tap()
            return
        }

        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            return
        }

        // Try tapping outside modal
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
        coordinate.tap()
    }

    // MARK: - Assertion Helpers

    /// Assert no error messages are displayed
    func assertNoErrors() {
        let hasError = TestHelpers.hasErrorMessage(in: app)
        if hasError, let errorMessage = TestHelpers.getErrorMessage(in: app) {
            XCTFail("❌ Unexpected error displayed: \(errorMessage)")
        }
    }

    /// Assert specific error message is displayed
    /// - Parameter expectedMessage: The expected error message
    func assertErrorDisplayed(containing expectedMessage: String) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedMessage)
        let errorText = app.staticTexts.containing(predicate).firstMatch
        TestHelpers.assertExists(
            errorText,
            named: "Error message containing '\(expectedMessage)'"
        )
    }

    /// Assert loading indicator is not visible
    func assertNotLoading() {
        let loadingIndicator = app.activityIndicators.firstMatch
        XCTAssertFalse(
            loadingIndicator.exists,
            "Loading indicator should not be visible"
        )
    }

    /// Assert element is visible and interactive
    /// - Parameters:
    ///   - element: Element to check
    ///   - elementName: Name for assertion message
    func assertIsInteractive(_ element: XCUIElement, named elementName: String) {
        TestHelpers.assertExists(element, named: elementName)
        TestHelpers.assertIsHittable(element, named: elementName)
    }

    // MARK: - Screenshot Helpers

    /// Capture screenshot with test name
    /// - Parameter suffix: Optional suffix for the screenshot name
    func captureScreenshot(_ suffix: String = "") {
        let testName = name
        let screenshotName = suffix.isEmpty ? testName : "\(testName)_\(suffix)"
        screenshots.capture(named: screenshotName)
    }

    /// Capture failure state with diagnostics
    func captureFailureStateIfNeeded() {
        // Only capture if test actually failed
        // XCTest doesn't expose test result directly, so we use a heuristic
        let testName = name
        screenshots.captureDiagnostics(
            testName: testName,
            error: NSError(
                domain: "UITest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Test execution completed"]
            ),
            app: app
        )
    }

    // MARK: - Wait Helpers

    /// Wait for element and assert it exists
    /// - Parameters:
    ///   - element: Element to wait for
    ///   - elementName: Name for assertion message
    ///   - timeout: Maximum time to wait
    func waitAndAssert(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = TestHelpers.standardTimeout
    ) {
        TestHelpers.assertExists(element, named: elementName, timeout: timeout)
    }

    /// Wait for element to disappear and assert
    /// - Parameters:
    ///   - element: Element to wait for disappearance
    ///   - elementName: Name for assertion message
    ///   - timeout: Maximum time to wait
    func waitForDisappearance(
        of element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = TestHelpers.standardTimeout
    ) {
        let disappeared = TestHelpers.waitForElementToDisappear(element, timeout: timeout)
        XCTAssertTrue(
            disappeared,
            "❌ '\(elementName)' should disappear within \(timeout)s"
        )
    }

    // MARK: - Form Helpers

    /// Fill out a text field
    /// - Parameters:
    ///   - field: The text field element
    ///   - text: Text to enter
    ///   - fieldName: Name for error messages
    func fillTextField(
        _ field: XCUIElement,
        with text: String,
        named fieldName: String
    ) {
        TestHelpers.safeTypeText(
            into: field,
            text: text,
            named: fieldName,
            clearFirst: true
        )
    }

    /// Fill out multiple form fields
    /// - Parameter fields: Dictionary of field identifiers to values
    func fillForm(_ fields: [String: String]) {
        for (identifier, value) in fields {
            let field = app.textFields[identifier]
            if !field.exists {
                // Try secure text field
                let secureField = app.secureTextFields[identifier]
                TestHelpers.safeTypeText(
                    into: secureField,
                    text: value,
                    named: identifier
                )
            } else {
                TestHelpers.safeTypeText(
                    into: field,
                    text: value,
                    named: identifier,
                    clearFirst: true
                )
            }
        }
    }

    // MARK: - Performance Testing

    /// Measure launch time
    /// - Returns: Launch time in seconds
    @discardableResult
    func measureLaunchTime() -> TimeInterval {
        return TestHelpers.measureTime(for: "App Launch") {
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: 10)
        }
    }

    /// Measure action performance
    /// - Parameters:
    ///   - actionName: Name of the action
    ///   - action: The action to measure
    /// - Returns: Time taken in seconds
    @discardableResult
    func measureAction(
        _ actionName: String,
        action: () -> Void
    ) -> TimeInterval {
        return TestHelpers.measureTime(for: actionName, action: action)
    }

    // MARK: - Device Helpers

    /// Check if running on iPad
    var isIPad: Bool {
        return TestHelpers.isIPad
    }

    /// Check if running on iPhone
    var isIPhone: Bool {
        return TestHelpers.isIPhone
    }

    /// Skip test if not on iPad
    func requireIPad() throws {
        guard isIPad else {
            throw XCTSkip("This test requires iPad")
        }
    }

    /// Skip test if not on iPhone
    func requireIPhone() throws {
        guard isIPhone else {
            throw XCTSkip("This test requires iPhone")
        }
    }

    // MARK: - Debug Helpers

    /// Print current screen state for debugging
    func printScreenState() {
        print("\n=== Screen State ===")
        print("Visible buttons:")
        TestHelpers.printAllButtons(in: app)
        print("\nVisible text fields:")
        TestHelpers.printAllTextFields(in: app)
        print("===================\n")
    }

    /// Print element hierarchy for debugging
    func printElementHierarchy() {
        TestHelpers.printElementHierarchy(app)
    }
}
