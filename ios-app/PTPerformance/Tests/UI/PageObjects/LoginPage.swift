//
//  LoginPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Login screen
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import XCTest

/// Page Object representing the Login screen
struct LoginPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Elements

    var demoPatientButton: XCUIElement {
        app.buttons["Demo Patient"]
    }

    var demoTherapistButton: XCUIElement {
        app.buttons["Demo Therapist"]
    }

    var emailField: XCUIElement {
        app.textFields["Email"]
    }

    var passwordField: XCUIElement {
        app.secureTextFields["Password"]
    }

    var loginButton: XCUIElement {
        app.buttons["Log In"]
    }

    var forgotPasswordButton: XCUIElement {
        app.buttons["Forgot Password?"]
    }

    var signUpButton: XCUIElement {
        app.buttons["Sign Up"]
    }

    var errorAlert: XCUIElement {
        app.alerts.firstMatch
    }

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Interactions

    /// Tap the demo patient button
    @discardableResult
    func tapDemoPatient() -> Self {
        TestHelpers.safeTap(demoPatientButton, named: "Demo Patient Button")
        return self
    }

    /// Tap the demo therapist button
    @discardableResult
    func tapDemoTherapist() -> Self {
        TestHelpers.safeTap(demoTherapistButton, named: "Demo Therapist Button")
        return self
    }

    /// Enter email address
    /// - Parameter email: Email to enter
    @discardableResult
    func enterEmail(_ email: String) -> Self {
        TestHelpers.safeTypeText(
            into: emailField,
            text: email,
            named: "Email Field",
            clearFirst: true
        )
        return self
    }

    /// Enter password
    /// - Parameter password: Password to enter
    @discardableResult
    func enterPassword(_ password: String) -> Self {
        TestHelpers.safeTypeText(
            into: passwordField,
            text: password,
            named: "Password Field",
            clearFirst: true
        )
        return self
    }

    /// Tap the login button
    @discardableResult
    func tapLogin() -> Self {
        TestHelpers.safeTap(loginButton, named: "Login Button")
        return self
    }

    /// Tap forgot password button
    @discardableResult
    func tapForgotPassword() -> Self {
        TestHelpers.safeTap(forgotPasswordButton, named: "Forgot Password Button")
        return self
    }

    /// Tap sign up button
    @discardableResult
    func tapSignUp() -> Self {
        TestHelpers.safeTap(signUpButton, named: "Sign Up Button")
        return self
    }

    // MARK: - Assertions

    /// Assert login screen is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(demoPatientButton, named: "Demo Patient Button")
        TestHelpers.assertExists(demoTherapistButton, named: "Demo Therapist Button")
    }

    /// Assert login form is displayed
    func assertLoginFormDisplayed() {
        TestHelpers.assertExists(emailField, named: "Email Field")
        TestHelpers.assertExists(passwordField, named: "Password Field")
        TestHelpers.assertExists(loginButton, named: "Login Button")
    }

    /// Assert error is displayed
    /// - Parameter expectedMessage: Expected error message (optional)
    func assertErrorDisplayed(containing expectedMessage: String? = nil) {
        TestHelpers.assertExists(errorAlert, named: "Error Alert")

        if let expectedMessage = expectedMessage {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedMessage)
            let errorText = errorAlert.staticTexts.containing(predicate).firstMatch
            XCTAssertTrue(
                errorText.exists,
                "Error should contain: '\(expectedMessage)'"
            )
        }
    }

    /// Assert no error is displayed
    func assertNoError() {
        XCTAssertFalse(errorAlert.exists, "Error alert should not be displayed")
    }

    // MARK: - Workflows

    /// Login as demo patient
    func loginAsDemoPatient() {
        tapDemoPatient()
    }

    /// Login as demo therapist
    func loginAsDemoTherapist() {
        tapDemoTherapist()
    }

}
