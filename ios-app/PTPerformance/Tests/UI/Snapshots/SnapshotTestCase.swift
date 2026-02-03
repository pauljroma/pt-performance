//
//  SnapshotTestCase.swift
//  PTPerformanceTests
//
//  Base class for UI snapshot/preview verification tests.
//  Verifies SwiftUI previews compile and render without crashing.
//
//  Since swift-snapshot-testing is not available, this uses Preview verification
//  to ensure views can be instantiated with various states and configurations.
//

import XCTest
import SwiftUI

/// Base class for snapshot/preview verification tests
///
/// Provides utilities for testing SwiftUI views across different:
/// - Color schemes (light/dark mode)
/// - Dynamic Type sizes (accessibility)
/// - Data states (loading, empty, error, populated)
class SnapshotTestCase: XCTestCase {

    // MARK: - Test Environment Configuration

    /// Color scheme configurations for testing
    enum TestColorScheme: CaseIterable {
        case light
        case dark

        var colorScheme: ColorScheme {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }

        var name: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    /// Dynamic Type sizes for accessibility testing
    enum TestDynamicTypeSize: CaseIterable {
        case standard
        case large
        case accessibilityMedium
        case accessibilityExtraExtraLarge

        var size: DynamicTypeSize {
            switch self {
            case .standard: return .medium
            case .large: return .large
            case .accessibilityMedium: return .accessibility2
            case .accessibilityExtraExtraLarge: return .accessibility5
            }
        }

        var name: String {
            switch self {
            case .standard: return "Standard"
            case .large: return "Large"
            case .accessibilityMedium: return "AccessibilityMedium"
            case .accessibilityExtraExtraLarge: return "AccessibilityXXL"
            }
        }
    }

    /// Device size classes for testing responsive layouts
    enum TestDevice: CaseIterable {
        case iPhoneSE
        case iPhone15Pro
        case iPhone15ProMax
        case iPadMini
        case iPadPro

        var size: CGSize {
            switch self {
            case .iPhoneSE: return CGSize(width: 375, height: 667)
            case .iPhone15Pro: return CGSize(width: 393, height: 852)
            case .iPhone15ProMax: return CGSize(width: 430, height: 932)
            case .iPadMini: return CGSize(width: 768, height: 1024)
            case .iPadPro: return CGSize(width: 1024, height: 1366)
            }
        }

        var name: String {
            switch self {
            case .iPhoneSE: return "iPhoneSE"
            case .iPhone15Pro: return "iPhone15Pro"
            case .iPhone15ProMax: return "iPhone15ProMax"
            case .iPadMini: return "iPadMini"
            case .iPadPro: return "iPadPro"
            }
        }
    }

    // MARK: - View Verification Utilities

    /// Verifies a SwiftUI view can be instantiated and rendered without crashing
    /// - Parameters:
    ///   - view: The view to verify
    ///   - name: A descriptive name for test output
    ///   - file: Source file for assertion
    ///   - line: Source line for assertion
    func verifyViewRenders<V: View>(
        _ view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Create a hosting controller to trigger view body evaluation
        let hostingController = UIHostingController(rootView: view)

        // Force layout to trigger any layout-related crashes
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        // If we get here without crashing, the view renders successfully
        XCTAssertNotNil(hostingController.view, "\(name) should render without crashing", file: file, line: line)
    }

    /// Verifies a view renders correctly across light and dark mode
    /// - Parameters:
    ///   - view: The view to verify
    ///   - name: A descriptive name for test output
    func verifyViewInBothColorSchemes<V: View>(
        _ view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for colorScheme in TestColorScheme.allCases {
            let themedView = view
                .environment(\.colorScheme, colorScheme.colorScheme)

            verifyViewRenders(
                themedView,
                named: "\(name)_\(colorScheme.name)",
                file: file,
                line: line
            )
        }
    }

    /// Verifies a view renders correctly across different Dynamic Type sizes
    /// - Parameters:
    ///   - view: The view to verify
    ///   - name: A descriptive name for test output
    func verifyViewAcrossDynamicTypeSizes<V: View>(
        _ view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for typeSize in TestDynamicTypeSize.allCases {
            let sizedView = view
                .environment(\.dynamicTypeSize, typeSize.size)

            verifyViewRenders(
                sizedView,
                named: "\(name)_\(typeSize.name)",
                file: file,
                line: line
            )
        }
    }

    /// Verifies a view renders correctly at different device sizes
    /// - Parameters:
    ///   - view: The view to verify
    ///   - name: A descriptive name for test output
    ///   - devices: The devices to test (defaults to all)
    func verifyViewAcrossDevices<V: View>(
        _ view: V,
        named name: String,
        devices: [TestDevice] = TestDevice.allCases,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for device in devices {
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(origin: .zero, size: device.size)
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()

            XCTAssertNotNil(
                hostingController.view,
                "\(name)_\(device.name) should render without crashing",
                file: file,
                line: line
            )
        }
    }

    /// Comprehensive verification across color schemes and dynamic type sizes
    /// - Parameters:
    ///   - view: The view to verify
    ///   - name: A descriptive name for test output
    func verifyViewComprehensively<V: View>(
        _ view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Test both color schemes
        verifyViewInBothColorSchemes(view, named: name, file: file, line: line)

        // Test accessibility sizes
        verifyViewAcrossDynamicTypeSizes(view, named: name, file: file, line: line)
    }

    // MARK: - Preview Verification

    /// Verifies a PreviewProvider's previews can be instantiated
    /// - Parameters:
    ///   - previewsBlock: A closure that returns the previews
    ///   - name: A descriptive name for test output
    func verifyPreviewsCompile<V: View>(
        _ previewsBlock: () -> V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let previews = previewsBlock()
        verifyViewRenders(previews, named: name, file: file, line: line)
    }

    // MARK: - Mock Data Verification

    /// Verifies a view handles empty state correctly
    func verifyEmptyState<V: View>(
        _ viewBuilder: () -> V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = viewBuilder()
        verifyViewRenders(view, named: "\(name)_EmptyState", file: file, line: line)
    }

    /// Verifies a view handles loading state correctly
    func verifyLoadingState<V: View>(
        _ viewBuilder: () -> V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = viewBuilder()
        verifyViewRenders(view, named: "\(name)_LoadingState", file: file, line: line)
    }

    /// Verifies a view handles error state correctly
    func verifyErrorState<V: View>(
        _ viewBuilder: () -> V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = viewBuilder()
        verifyViewRenders(view, named: "\(name)_ErrorState", file: file, line: line)
    }

    /// Verifies a view handles populated state correctly
    func verifyPopulatedState<V: View>(
        _ viewBuilder: () -> V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = viewBuilder()
        verifyViewRenders(view, named: "\(name)_PopulatedState", file: file, line: line)
    }
}

// MARK: - Test Helpers

/// Protocol for views that provide sample/mock data for testing
protocol PreviewDataProvider {
    associatedtype SampleData
    static var sampleData: SampleData { get }
    static var emptySampleData: SampleData { get }
}

/// Helper to wrap a view with environment objects for testing
struct TestViewWrapper<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

/// Stateful wrapper for testing views with @State properties
struct StatefulTestWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

// MARK: - Environment Extensions for Testing

extension View {
    /// Applies test environment configuration
    func testEnvironment(
        colorScheme: ColorScheme = .light,
        dynamicTypeSize: DynamicTypeSize = .medium
    ) -> some View {
        self
            .environment(\.colorScheme, colorScheme)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
    }

    /// Applies light mode test environment
    func lightModeTest() -> some View {
        self.environment(\.colorScheme, .light)
    }

    /// Applies dark mode test environment
    func darkModeTest() -> some View {
        self.environment(\.colorScheme, .dark)
    }

    /// Applies accessibility extra large text size
    func accessibilityTextTest() -> some View {
        self.environment(\.dynamicTypeSize, .accessibility3)
    }
}
