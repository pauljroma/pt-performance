//
//  E2ETestUtilities.swift
//  PTPerformanceUITests
//
//  World-class E2E testing utilities for reliable, maintainable tests
//  ACP-226: Critical user flow E2E testing
//

import XCTest
import UIKit

/// Advanced E2E testing utilities for reliable test execution
enum E2ETestUtilities {

    // MARK: - Configuration

    /// Standard timeouts for different operation types
    enum Timeout {
        static let immediate: TimeInterval = 2
        static let fast: TimeInterval = 5
        static let standard: TimeInterval = 10
        static let network: TimeInterval = 15
        static let slow: TimeInterval = 30
        static let veryLong: TimeInterval = 60
    }

    /// Test stability configuration
    enum Stability {
        static let retryCount = 3
        static let retryDelay: TimeInterval = 0.5
        static let animationBuffer: TimeInterval = 0.3
    }

    // MARK: - Reliable Wait Functions

    /// Wait for element with retry logic for flaky scenarios
    /// - Parameters:
    ///   - element: Element to wait for
    ///   - timeout: Maximum wait time
    ///   - retries: Number of retries
    /// - Returns: True if element exists
    static func waitForElementReliably(
        _ element: XCUIElement,
        timeout: TimeInterval = Timeout.standard,
        retries: Int = Stability.retryCount
    ) -> Bool {
        var attempts = 0
        while attempts < retries {
            if element.waitForExistence(timeout: timeout / TimeInterval(retries)) {
                return true
            }
            attempts += 1
            Thread.sleep(forTimeInterval: Stability.retryDelay)
        }
        return element.exists
    }

    /// Wait for element to become hittable (visible and interactive)
    /// - Parameters:
    ///   - element: Element to wait for
    ///   - timeout: Maximum wait time
    /// - Returns: True if element is hittable
    static func waitForElementHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = Timeout.standard
    ) -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if element.exists && element.isHittable {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return element.exists && element.isHittable
    }

    /// Wait for all loading indicators to disappear
    /// - Parameters:
    ///   - app: Application instance
    ///   - timeout: Maximum wait time
    /// - Returns: True if loading completed
    @discardableResult
    static func waitForLoadingComplete(
        in app: XCUIApplication,
        timeout: TimeInterval = Timeout.network
    ) -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let spinners = app.activityIndicators.allElementsBoundByIndex
            let visibleSpinners = spinners.filter { $0.exists && $0.isHittable }
            if visibleSpinners.isEmpty {
                // Extra buffer for animations
                Thread.sleep(forTimeInterval: Stability.animationBuffer)
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }

    /// Wait for any network content to load
    /// - Parameters:
    ///   - app: Application instance
    ///   - contentPredicate: Predicate to identify loaded content
    ///   - timeout: Maximum wait time
    /// - Returns: True if content loaded
    static func waitForContentLoad(
        in app: XCUIApplication,
        matching contentPredicate: NSPredicate,
        timeout: TimeInterval = Timeout.network
    ) -> Bool {
        let element = app.staticTexts.containing(contentPredicate).firstMatch
        return waitForElementReliably(element, timeout: timeout)
    }

    // MARK: - Safe Interactions

    /// Safely tap an element with retry logic
    /// - Parameters:
    ///   - element: Element to tap
    ///   - elementName: Name for error messages
    ///   - timeout: Maximum wait time
    ///   - retries: Number of retries
    /// - Returns: True if tap succeeded
    @discardableResult
    static func safeTap(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = Timeout.standard,
        retries: Int = Stability.retryCount
    ) -> Bool {
        var attempts = 0
        while attempts < retries {
            if waitForElementHittable(element, timeout: timeout / TimeInterval(retries)) {
                element.tap()
                Thread.sleep(forTimeInterval: Stability.animationBuffer)
                return true
            }
            attempts += 1
            Thread.sleep(forTimeInterval: Stability.retryDelay)
        }
        XCTFail("Failed to tap '\(elementName)' after \(retries) attempts")
        return false
    }

    /// Safely type text into an element
    /// - Parameters:
    ///   - element: Text field element
    ///   - text: Text to type
    ///   - elementName: Name for error messages
    ///   - clearFirst: Whether to clear existing text
    /// - Returns: True if typing succeeded
    @discardableResult
    static func safeType(
        into element: XCUIElement,
        text: String,
        named elementName: String,
        clearFirst: Bool = true
    ) -> Bool {
        guard waitForElementHittable(element) else {
            XCTFail("Text field '\(elementName)' not hittable")
            return false
        }

        element.tap()

        if clearFirst, let currentValue = element.value as? String, !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteString)
        }

        element.typeText(text)
        return true
    }

    /// Scroll to find an element
    /// - Parameters:
    ///   - element: Element to find
    ///   - scrollView: Scroll view to scroll within
    ///   - direction: Scroll direction
    ///   - maxAttempts: Maximum scroll attempts
    /// - Returns: True if element found
    @discardableResult
    static func scrollToElement(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        direction: ScrollDirection = .down,
        maxAttempts: Int = 10
    ) -> Bool {
        var attempts = 0
        while attempts < maxAttempts {
            if element.exists && element.isHittable {
                return true
            }

            switch direction {
            case .down: scrollView.swipeUp()
            case .up: scrollView.swipeDown()
            case .left: scrollView.swipeRight()
            case .right: scrollView.swipeLeft()
            }

            Thread.sleep(forTimeInterval: Stability.animationBuffer)
            attempts += 1
        }
        return element.exists && element.isHittable
    }

    enum ScrollDirection {
        case up, down, left, right
    }

    // MARK: - Assertion Helpers

    /// Assert element exists with detailed error message
    /// - Parameters:
    ///   - element: Element to check
    ///   - elementName: Name for error message
    ///   - timeout: Maximum wait time
    ///   - file: Source file
    ///   - line: Source line
    static func assertExists(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = Timeout.standard,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "❌ Expected '\(elementName)' to exist but it was not found within \(timeout)s",
            file: file,
            line: line
        )
    }

    /// Assert element does not exist
    /// - Parameters:
    ///   - element: Element to check
    ///   - elementName: Name for error message
    ///   - file: Source file
    ///   - line: Source line
    static func assertDoesNotExist(
        _ element: XCUIElement,
        named elementName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Small wait to ensure element has time to disappear
        Thread.sleep(forTimeInterval: Stability.animationBuffer)
        XCTAssertFalse(
            element.exists,
            "❌ Expected '\(elementName)' to NOT exist but it was found",
            file: file,
            line: line
        )
    }

    /// Assert no error alerts are showing
    /// - Parameters:
    ///   - app: Application instance
    ///   - file: Source file
    ///   - line: Source line
    static func assertNoErrorAlerts(
        in app: XCUIApplication,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let alertTitle = alert.label
            XCTFail(
                "❌ Unexpected error alert: \(alertTitle)",
                file: file,
                line: line
            )
        }
    }

    /// Assert app is in stable state (no loading, no errors)
    /// - Parameters:
    ///   - app: Application instance
    ///   - file: Source file
    ///   - line: Source line
    static func assertStableState(
        in app: XCUIApplication,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        waitForLoadingComplete(in: app)
        assertNoErrorAlerts(in: app, file: file, line: line)
    }

    // MARK: - Performance Helpers

    /// Measure and log performance of an action
    /// - Parameters:
    ///   - name: Action name
    ///   - threshold: Warning threshold in seconds
    ///   - action: Action to measure
    /// - Returns: Duration in seconds
    @discardableResult
    static func measurePerformance(
        _ name: String,
        warningThreshold threshold: TimeInterval = 5.0,
        action: () -> Void
    ) -> TimeInterval {
        let start = Date()
        action()
        let duration = Date().timeIntervalSince(start)

        let status = duration > threshold ? "⚠️ SLOW" : "✅"
        print("\(status) '\(name)' took \(String(format: "%.2f", duration))s")

        return duration
    }

    // MARK: - Screenshot Helpers

    /// Capture screenshot with metadata
    /// - Parameters:
    ///   - name: Screenshot name
    ///   - testCase: Test case instance
    ///   - lifetime: Attachment lifetime
    static func captureScreenshot(
        named name: String,
        in testCase: XCTestCase,
        lifetime: XCTAttachment.Lifetime = .deleteOnSuccess
    ) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(Date().timeIntervalSince1970)"
        attachment.lifetime = lifetime
        testCase.add(attachment)
    }

    /// Capture diagnostic information on failure
    /// - Parameters:
    ///   - app: Application instance
    ///   - testCase: Test case instance
    ///   - error: Error description
    static func captureDiagnostics(
        for app: XCUIApplication,
        in testCase: XCTestCase,
        error: String
    ) {
        captureScreenshot(named: "failure_state", in: testCase, lifetime: .keepAlways)

        // Log visible elements for debugging
        print("=== Diagnostic Info ===")
        print("Error: \(error)")
        print("Visible buttons: \(app.buttons.allElementsBoundByIndex.filter { $0.isHittable }.map { $0.label })")
        print("Visible tabs: \(app.tabBars.buttons.allElementsBoundByIndex.map { $0.label })")
        print("======================")
    }

    // MARK: - State Management

    /// Verify app is on expected screen
    /// - Parameters:
    ///   - app: Application instance
    ///   - identifier: Screen identifier (button, text, or element label)
    /// - Returns: True if on expected screen
    static func isOnScreen(
        _ app: XCUIApplication,
        identifiedBy identifier: String
    ) -> Bool {
        let buttonMatch = app.buttons[identifier].exists
        let textMatch = app.staticTexts[identifier].exists
        let tabMatch = app.tabBars.buttons[identifier].isSelected

        return buttonMatch || textMatch || tabMatch
    }

    /// Ensure app is in clean state for testing
    /// - Parameters:
    ///   - app: Application instance
    ///   - timeout: Maximum wait time
    static func ensureCleanState(
        in app: XCUIApplication,
        timeout: TimeInterval = Timeout.network
    ) {
        // Dismiss any alerts
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: Timeout.fast) {
            if let cancelButton = alert.buttons.allElementsBoundByIndex.first(where: { $0.label.lowercased().contains("cancel") }) {
                cancelButton.tap()
            } else {
                alert.buttons.firstMatch.tap()
            }
        }

        // Wait for loading to complete
        waitForLoadingComplete(in: app, timeout: timeout)

        // Dismiss any sheets/modals
        let sheet = app.sheets.firstMatch
        if sheet.exists {
            app.swipeDown()
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {

    /// Check if element is visible on screen
    var isVisibleOnScreen: Bool {
        guard exists && isHittable else { return false }
        return !frame.isEmpty
    }

    /// Wait for element to disappear
    /// - Parameter timeout: Maximum wait time
    /// - Returns: True if element disappeared
    func waitForNonExistence(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for element to become enabled
    /// - Parameter timeout: Maximum wait time
    /// - Returns: True if element is enabled
    func waitForEnabled(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {

    /// Run test with automatic retry on failure
    /// - Parameters:
    ///   - retries: Number of retries
    ///   - testBlock: Test code to run
    func runWithRetry(retries: Int = 2, _ testBlock: () throws -> Void) throws {
        var lastError: Error?

        for attempt in 1...(retries + 1) {
            do {
                try testBlock()
                return // Success
            } catch {
                lastError = error
                print("⚠️ Test attempt \(attempt) failed: \(error)")

                if attempt <= retries {
                    print("🔄 Retrying...")
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }

        if let error = lastError {
            throw error
        }
    }

    /// Add test step documentation
    /// - Parameters:
    ///   - step: Step number
    ///   - description: Step description
    func testStep(_ step: Int, _ description: String) {
        XCTContext.runActivity(named: "Step \(step): \(description)") { _ in }
    }
}

// MARK: - TestHelpers Compatibility Layer

/// Common test utilities for PTPerformance UI tests
/// Provides compatibility with page objects that reference TestHelpers
enum TestHelpers {

    // MARK: - Wait Helpers

    /// Standard timeout for UI elements (in seconds)
    static let standardTimeout: TimeInterval = 5.0

    /// Extended timeout for network operations (in seconds)
    static let networkTimeout: TimeInterval = 15.0

    /// Quick timeout for instant checks (in seconds)
    static let quickTimeout: TimeInterval = 2.0

    /// Wait for element to exist with custom timeout
    @discardableResult
    static func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = standardTimeout,
        message: String? = nil
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists, let message = message {
            XCTFail(message)
        }
        return exists
    }

    /// Wait for element to disappear
    @discardableResult
    static func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = standardTimeout
    ) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for loading indicators to disappear
    @discardableResult
    static func waitForLoadingToComplete(
        in app: XCUIApplication,
        timeout: TimeInterval = networkTimeout
    ) -> Bool {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            return waitForElementToDisappear(loadingIndicator, timeout: timeout)
        }
        return true
    }

    // MARK: - Assertion Helpers

    /// Assert element exists with descriptive failure message
    static func assertExists(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = standardTimeout
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "❌ '\(elementName)' should exist but was not found"
        )
    }

    /// Assert element does not exist
    static func assertDoesNotExist(
        _ element: XCUIElement,
        named elementName: String
    ) {
        XCTAssertFalse(
            element.exists,
            "❌ '\(elementName)' should not exist but was found"
        )
    }

    // MARK: - Interaction Helpers

    /// Safely tap an element with existence check
    static func safeTap(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = standardTimeout
    ) {
        assertExists(element, named: elementName, timeout: timeout)
        element.tap()
    }

    /// Type text into a field with existence check
    static func safeTypeText(
        into element: XCUIElement,
        text: String,
        named elementName: String,
        clearFirst: Bool = false,
        timeout: TimeInterval = standardTimeout
    ) {
        assertExists(element, named: elementName, timeout: timeout)
        element.tap()

        if clearFirst, let currentValue = element.value as? String, !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteString)
        }

        element.typeText(text)
    }

    // MARK: - Screenshot Helpers

    /// Take a screenshot with a descriptive name
    static func takeScreenshot(
        named name: String,
        in testCase: XCTestCase
    ) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }

    // MARK: - Login Helpers

    /// Perform demo login flow
    static func performLogin(
        in app: XCUIApplication,
        userType: String = "Patient"
    ) {
        let buttonLabel = userType == "Patient" ? "Demo Patient" : "Demo Therapist"
        let loginButton = app.buttons[buttonLabel]
        safeTap(loginButton, named: "\(buttonLabel) Button")
        waitForLoadingToComplete(in: app)
    }

    // MARK: - Hittable Assertions

    /// Assert element is hittable (visible and interactive)
    static func assertIsHittable(
        _ element: XCUIElement,
        named elementName: String
    ) {
        XCTAssertTrue(
            element.isHittable,
            "❌ '\(elementName)' exists but is not hittable (visible and interactive)"
        )
    }

    // MARK: - Error Detection Helpers

    /// Check for error messages in the UI
    static func hasErrorMessage(
        in app: XCUIApplication,
        containing keywords: [String] = ["error", "failed", "could not"]
    ) -> Bool {
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let errorText = app.staticTexts.containing(predicate).firstMatch
            if errorText.exists {
                return true
            }
        }
        return app.alerts.firstMatch.exists
    }

    /// Get error message text if present
    static func getErrorMessage(in app: XCUIApplication) -> String? {
        let alert = app.alerts.firstMatch
        if alert.exists {
            return alert.label
        }

        let keywords = ["error", "failed", "could not"]
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let errorText = app.staticTexts.containing(predicate).firstMatch
            if errorText.exists {
                return errorText.label
            }
        }
        return nil
    }

    // MARK: - Device Helpers

    /// Check if running on iPad
    static var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Check if running on iPhone
    static var isIPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    // MARK: - Performance Helpers

    /// Measure time for an action to complete
    @discardableResult
    static func measureTime(
        for name: String,
        action: () -> Void
    ) -> TimeInterval {
        let start = Date()
        action()
        let elapsed = Date().timeIntervalSince(start)
        print("⏱️ \(name) took \(String(format: "%.2f", elapsed))s")
        return elapsed
    }

    // MARK: - Debug Helpers

    /// Print element hierarchy for debugging
    static func printElementHierarchy(_ element: XCUIElement) {
        print("=== Element Hierarchy ===")
        print(element.debugDescription)
        print("========================")
    }

    /// Print all buttons in the app
    static func printAllButtons(in app: XCUIApplication) {
        print("=== All Buttons ===")
        let buttons = app.buttons.allElementsBoundByIndex
        for (index, button) in buttons.enumerated() {
            print("\(index): \(button.label)")
        }
        print("==================")
    }

    /// Print all text fields in the app
    static func printAllTextFields(in app: XCUIApplication) {
        print("=== All Text Fields ===")
        let fields = app.textFields.allElementsBoundByIndex
        for (index, field) in fields.enumerated() {
            print("\(index): \(field.label)")
        }
        print("======================")
    }
}
