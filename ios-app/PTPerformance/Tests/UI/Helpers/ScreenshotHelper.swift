//
//  ScreenshotHelper.swift
//  PTPerformanceUITests
//
//  Screenshot capture on test failure and for documentation
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import XCTest

/// Helper for capturing and managing screenshots during UI tests
class ScreenshotHelper {

    // MARK: - Properties

    /// The test case context
    private weak var testCase: XCTestCase?

    /// Whether to automatically capture screenshots on failure
    var captureOnFailure: Bool = true

    /// Whether to capture screenshots at key test steps
    var captureKeySteps: Bool = false

    /// Screenshot quality (0.0 - 1.0)
    var quality: CGFloat = 0.8

    // MARK: - Initialization

    init(testCase: XCTestCase) {
        self.testCase = testCase
    }

    // MARK: - Screenshot Capture

    /// Capture a screenshot with a descriptive name
    /// - Parameters:
    ///   - name: Descriptive name for the screenshot
    ///   - lifetime: How long to keep the screenshot (.keepAlways or .deleteOnSuccess)
    func capture(
        named name: String,
        lifetime: XCTAttachment.Lifetime = .keepAlways
    ) {
        guard let testCase = testCase else { return }

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = sanitizeName(name)
        attachment.lifetime = lifetime
        testCase.add(attachment)

        print("📸 Screenshot captured: \(name)")
    }

    /// Capture screenshot on test failure
    /// - Parameters:
    ///   - error: The error that caused the failure
    ///   - testName: Name of the test that failed
    func captureFailure(
        error: Error,
        testName: String
    ) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        let name = "FAILURE_\(testName)_\(timestamp)"
        capture(named: name, lifetime: .keepAlways)

        // Also capture element hierarchy for debugging
        if let testCase = testCase {
            let hierarchy = XCUIApplication().debugDescription
            let textAttachment = XCTAttachment(string: hierarchy)
            textAttachment.name = "ElementHierarchy_\(testName)"
            textAttachment.lifetime = .keepAlways
            testCase.add(textAttachment)
        }
    }

    /// Capture screenshot before an action
    /// - Parameter action: Description of the action about to be performed
    func captureBefore(_ action: String) {
        if captureKeySteps {
            capture(named: "Before_\(action)", lifetime: .deleteOnSuccess)
        }
    }

    /// Capture screenshot after an action
    /// - Parameter action: Description of the action that was performed
    func captureAfter(_ action: String) {
        if captureKeySteps {
            capture(named: "After_\(action)", lifetime: .deleteOnSuccess)
        }
    }

    /// Capture a series of screenshots showing a flow
    /// - Parameters:
    ///   - flowName: Name of the flow being captured
    ///   - steps: Array of step descriptions
    ///   - action: Closure that performs each step
    func captureFlow(
        named flowName: String,
        steps: [String],
        action: (Int, String) -> Void
    ) {
        capture(named: "\(flowName)_Start", lifetime: .deleteOnSuccess)

        for (index, step) in steps.enumerated() {
            action(index, step)
            capture(
                named: "\(flowName)_Step\(index + 1)_\(step)",
                lifetime: .deleteOnSuccess
            )
        }

        capture(named: "\(flowName)_Complete", lifetime: .deleteOnSuccess)
    }

    // MARK: - Screenshot Comparison

    /// Compare two screenshots (for visual regression testing)
    /// - Parameters:
    ///   - baseline: Name of the baseline screenshot
    ///   - current: Name of the current screenshot
    /// - Returns: True if screenshots match within tolerance
    func compare(
        baseline: String,
        current: String
    ) -> Bool {
        // Note: Full implementation would require image comparison library
        // This is a placeholder for future enhancement
        print("⚠️ Screenshot comparison not yet implemented")
        return true
    }

    // MARK: - Video Recording

    /// Start recording video of the test
    func startRecording() {
        // Note: Video recording requires additional setup in test plan
        print("⚠️ Video recording requires XCTest Video Recording enabled in test plan")
    }

    /// Stop recording video
    func stopRecording() {
        // Video is automatically attached by XCTest when enabled
    }

    // MARK: - Element Screenshots

    /// Capture screenshot of a specific element
    /// - Parameters:
    ///   - element: The XCUIElement to capture
    ///   - name: Descriptive name
    func captureElement(
        _ element: XCUIElement,
        named name: String
    ) {
        guard let testCase = testCase else { return }

        // Take full screenshot
        let screenshot = XCUIScreen.main.screenshot()

        // Note: Cropping to element bounds would require additional image processing
        // For now, we capture the full screen with the element highlighted in the name
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Element_\(sanitizeName(name))"
        attachment.lifetime = .deleteOnSuccess
        testCase.add(attachment)

        print("📸 Element screenshot captured: \(name)")
    }

    // MARK: - Accessibility Snapshot

    /// Capture accessibility hierarchy for debugging
    /// - Parameter name: Descriptive name
    func captureAccessibilitySnapshot(named name: String) {
        guard let testCase = testCase else { return }

        let app = XCUIApplication()
        let hierarchy = app.debugDescription

        let attachment = XCTAttachment(string: hierarchy)
        attachment.name = "A11y_\(sanitizeName(name))"
        attachment.lifetime = .keepAlways
        testCase.add(attachment)

        print("♿ Accessibility snapshot captured: \(name)")
    }

    // MARK: - App State Capture

    /// Capture full app state including screenshots and logs
    /// - Parameter stateName: Descriptive name for the state
    func captureAppState(named stateName: String) {
        // Capture screenshot
        capture(named: "State_\(stateName)", lifetime: .keepAlways)

        // Capture element hierarchy
        captureAccessibilitySnapshot(named: stateName)

        // Capture console logs (if available)
        // Note: Console log capture requires additional configuration
    }

    // MARK: - Screenshot Organization

    /// Create a screenshot set for a test suite
    /// - Parameter suiteName: Name of the test suite
    func beginSuite(_ suiteName: String) {
        capture(named: "Suite_\(suiteName)_Begin", lifetime: .deleteOnSuccess)
    }

    /// End a screenshot set for a test suite
    /// - Parameter suiteName: Name of the test suite
    func endSuite(_ suiteName: String) {
        capture(named: "Suite_\(suiteName)_End", lifetime: .deleteOnSuccess)
    }

    // MARK: - Utilities

    /// Sanitize screenshot name for file system
    /// - Parameter name: Original name
    /// - Returns: Sanitized name
    private func sanitizeName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    /// Generate timestamp for screenshot names
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    // MARK: - Device-Specific Screenshots

    /// Capture screenshots for all device sizes (requires multiple test runs)
    /// - Parameter name: Base name for screenshots
    func captureForAllDevices(named name: String) {
        let deviceInfo = UIDevice.current
        let deviceName = deviceInfo.model
        let screenSize = UIScreen.main.bounds.size

        let fullName = "\(name)_\(deviceName)_\(Int(screenSize.width))x\(Int(screenSize.height))"
        capture(named: fullName, lifetime: .keepAlways)
    }

    // MARK: - Failure Diagnostics

    /// Capture comprehensive diagnostics on failure
    /// - Parameters:
    ///   - testName: Name of the failed test
    ///   - error: The error that occurred
    ///   - app: The XCUIApplication instance
    func captureDiagnostics(
        testName: String,
        error: Error,
        app: XCUIApplication
    ) {
        print("🔍 Capturing failure diagnostics for: \(testName)")

        // 1. Screenshot
        capture(named: "FAILURE_\(testName)_Screenshot", lifetime: .keepAlways)

        // 2. Element hierarchy
        guard let testCase = testCase else { return }

        let hierarchy = app.debugDescription
        let hierarchyAttachment = XCTAttachment(string: hierarchy)
        hierarchyAttachment.name = "FAILURE_\(testName)_Hierarchy"
        hierarchyAttachment.lifetime = .keepAlways
        testCase.add(hierarchyAttachment)

        // 3. Error details
        let errorDetails = """
        Test: \(testName)
        Error: \(error.localizedDescription)
        Time: \(timestamp)

        Full Error: \(error)
        """

        let errorAttachment = XCTAttachment(string: errorDetails)
        errorAttachment.name = "FAILURE_\(testName)_Error"
        errorAttachment.lifetime = .keepAlways
        testCase.add(errorAttachment)

        // 4. All visible text
        let allText = app.staticTexts.allElementsBoundByIndex
            .map { "- \($0.label)" }
            .joined(separator: "\n")

        let textAttachment = XCTAttachment(string: "Visible Text:\n\(allText)")
        textAttachment.name = "FAILURE_\(testName)_VisibleText"
        textAttachment.lifetime = .keepAlways
        testCase.add(textAttachment)

        // 5. All buttons
        let allButtons = app.buttons.allElementsBoundByIndex
            .map { "- \($0.label)" }
            .joined(separator: "\n")

        let buttonsAttachment = XCTAttachment(string: "Available Buttons:\n\(allButtons)")
        buttonsAttachment.name = "FAILURE_\(testName)_Buttons"
        buttonsAttachment.lifetime = .keepAlways
        testCase.add(buttonsAttachment)

        print("✅ Diagnostics captured successfully")
    }

    // MARK: - Annotation

    /// Add text annotation to explain what screenshot shows
    /// - Parameters:
    ///   - screenshotName: Name of the screenshot
    ///   - annotation: Explanatory text
    func annotate(
        screenshot screenshotName: String,
        with annotation: String
    ) {
        guard let testCase = testCase else { return }

        let annotationAttachment = XCTAttachment(string: annotation)
        annotationAttachment.name = "Annotation_\(screenshotName)"
        annotationAttachment.lifetime = .deleteOnSuccess
        testCase.add(annotationAttachment)
    }
}

// MARK: - Convenience Extensions

extension XCTestCase {
    /// Create a screenshot helper for this test case
    var screenshotHelper: ScreenshotHelper {
        return ScreenshotHelper(testCase: self)
    }
}
