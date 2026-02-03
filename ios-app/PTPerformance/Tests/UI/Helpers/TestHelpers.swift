//
//  TestHelpers.swift
//  PTPerformanceUITests
//
//  Common test utilities and helper functions for UI testing
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import XCTest

/// Common test utilities for PTPerformance UI tests
enum TestHelpers {

    // MARK: - Wait Helpers

    /// Standard timeout for UI elements (in seconds)
    static let standardTimeout: TimeInterval = 5.0

    /// Extended timeout for network operations (in seconds)
    static let networkTimeout: TimeInterval = 15.0

    /// Quick timeout for instant checks (in seconds)
    static let quickTimeout: TimeInterval = 2.0

    /// Wait for element to exist with custom timeout
    /// - Parameters:
    ///   - element: The XCUIElement to wait for
    ///   - timeout: Maximum time to wait
    ///   - message: Optional custom assertion message
    /// - Returns: True if element exists within timeout
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
    /// - Parameters:
    ///   - element: The XCUIElement to wait for disappearance
    ///   - timeout: Maximum time to wait
    /// - Returns: True if element disappeared within timeout
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
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait
    /// - Returns: True if all loading indicators disappeared
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
    /// - Parameters:
    ///   - element: The XCUIElement to check
    ///   - elementName: Human-readable name for error message
    ///   - timeout: Maximum time to wait
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
    /// - Parameters:
    ///   - element: The XCUIElement to check
    ///   - elementName: Human-readable name for error message
    static func assertDoesNotExist(
        _ element: XCUIElement,
        named elementName: String
    ) {
        XCTAssertFalse(
            element.exists,
            "❌ '\(elementName)' should not exist but was found"
        )
    }

    /// Assert element is hittable (visible and interactive)
    /// - Parameters:
    ///   - element: The XCUIElement to check
    ///   - elementName: Human-readable name for error message
    static func assertIsHittable(
        _ element: XCUIElement,
        named elementName: String
    ) {
        XCTAssertTrue(
            element.isHittable,
            "❌ '\(elementName)' exists but is not hittable (visible and interactive)"
        )
    }

    // MARK: - Interaction Helpers

    /// Safely tap an element with existence check
    /// - Parameters:
    ///   - element: The XCUIElement to tap
    ///   - elementName: Human-readable name for error message
    ///   - timeout: Maximum time to wait for element
    static func safeTap(
        _ element: XCUIElement,
        named elementName: String,
        timeout: TimeInterval = standardTimeout
    ) {
        assertExists(element, named: elementName, timeout: timeout)
        element.tap()
    }

    /// Type text into a field with existence check
    /// - Parameters:
    ///   - element: The XCUIElement to type into
    ///   - text: The text to type
    ///   - elementName: Human-readable name for error message
    ///   - clearFirst: Whether to clear existing text first
    ///   - timeout: Maximum time to wait for element
    static func safeTypeText(
        into element: XCUIElement,
        text: String,
        named elementName: String,
        clearFirst: Bool = false,
        timeout: TimeInterval = standardTimeout
    ) {
        assertExists(element, named: elementName, timeout: timeout)
        element.tap()

        if clearFirst {
            clearText(in: element)
        }

        element.typeText(text)
    }

    /// Clear text from a text field
    /// - Parameter element: The text field to clear
    static func clearText(in element: XCUIElement) {
        guard let currentValue = element.value as? String else {
            return
        }

        // Delete each character
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        element.typeText(deleteString)
    }

    /// Scroll to element if needed
    /// - Parameters:
    ///   - element: The element to scroll to
    ///   - scrollView: The scroll view containing the element
    static func scrollToElement(
        _ element: XCUIElement,
        in scrollView: XCUIElement
    ) {
        var attempts = 0
        let maxAttempts = 5

        while !element.isHittable && attempts < maxAttempts {
            scrollView.swipeUp()
            attempts += 1
        }

        if attempts == maxAttempts {
            XCTFail("❌ Could not scroll to element after \(maxAttempts) attempts")
        }
    }

    // MARK: - Screenshot Helpers

    /// Take a screenshot with a descriptive name
    /// - Parameters:
    ///   - name: Name for the screenshot
    ///   - testCase: The XCTestCase instance
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

    // MARK: - Error Detection Helpers

    /// Check for error messages in the UI
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - keywords: Keywords to search for in error messages
    /// - Returns: True if error message found
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

        // Also check for system alerts
        return app.alerts.firstMatch.exists
    }

    /// Get error message text if present
    /// - Parameter app: The XCUIApplication instance
    /// - Returns: Error message text or nil
    static func getErrorMessage(in app: XCUIApplication) -> String? {
        // Check for alert
        let alert = app.alerts.firstMatch
        if alert.exists {
            return alert.label
        }

        // Check for error text
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

    /// Get device size category
    static var deviceSizeCategory: DeviceSizeCategory {
        let bounds = UIScreen.main.bounds
        let minDimension = min(bounds.width, bounds.height)

        if isIPad {
            return .iPad
        } else if minDimension <= 375 {
            return .iPhoneSmall
        } else if minDimension <= 414 {
            return .iPhoneRegular
        } else {
            return .iPhoneLarge
        }
    }

    enum DeviceSizeCategory {
        case iPhoneSmall  // SE, Mini
        case iPhoneRegular // Standard sizes
        case iPhoneLarge  // Plus, Max, Pro Max
        case iPad
    }

    // MARK: - Login Helpers

    /// Perform demo login flow
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - userType: "Patient" or "Therapist"
    static func performLogin(
        in app: XCUIApplication,
        userType: String = "Patient"
    ) {
        let buttonLabel = userType == "Patient" ? "Demo Patient" : "Demo Therapist"
        let loginButton = app.buttons[buttonLabel]
        safeTap(loginButton, named: "\(buttonLabel) Button")

        // Wait for login to complete
        waitForLoadingToComplete(in: app)
    }

    // MARK: - Debug Helpers

    /// Print element hierarchy for debugging
    /// - Parameter element: Root element to print from
    static func printElementHierarchy(_ element: XCUIElement) {
        print("=== Element Hierarchy ===")
        print(element.debugDescription)
        print("========================")
    }

    /// Print all buttons in the app
    /// - Parameter app: The XCUIApplication instance
    static func printAllButtons(in app: XCUIApplication) {
        print("=== All Buttons ===")
        let buttons = app.buttons.allElementsBoundByIndex
        for (index, button) in buttons.enumerated() {
            print("\(index): \(button.label)")
        }
        print("==================")
    }

    /// Print all text fields in the app
    /// - Parameter app: The XCUIApplication instance
    static func printAllTextFields(in app: XCUIApplication) {
        print("=== All Text Fields ===")
        let fields = app.textFields.allElementsBoundByIndex
        for (index, field) in fields.enumerated() {
            print("\(index): \(field.label)")
        }
        print("======================")
    }

    // MARK: - Performance Helpers

    /// Measure time for an action to complete
    /// - Parameters:
    ///   - name: Name of the action being measured
    ///   - action: The action to measure
    /// - Returns: Time taken in seconds
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
}
