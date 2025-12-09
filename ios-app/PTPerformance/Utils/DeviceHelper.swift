import SwiftUI
import UIKit

/// Centralized device detection and layout utilities for adaptive iPad/iPhone layouts
enum DeviceHelper {
    /// Check if currently running on iPad device
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Check if current size class indicates regular width (iPad landscape, large iPhone)
    static func isRegularWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }

    /// Determine if NavigationSplitView should be used based on device and size class
    /// - Parameters:
    ///   - horizontalSizeClass: Current horizontal size class from @Environment
    ///   - device: Device idiom (defaults to current device)
    /// - Returns: True if split view should be displayed (iPad in regular width)
    static func shouldUseSplitView(
        horizontalSizeClass: UserInterfaceSizeClass?,
        device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> Bool {
        device == .pad && horizontalSizeClass == .regular
    }

    /// Get recommended sidebar width for NavigationSplitView
    static var sidebarWidth: (min: CGFloat, ideal: CGFloat, max: CGFloat) {
        (min: 320, ideal: 400, max: 500)
    }
}

/// Environment key for device detection
struct DeviceEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Indicates if current layout should use iPad-specific patterns
    var isIPadLayout: Bool {
        get { self[DeviceEnvironmentKey.self] }
        set { self[DeviceEnvironmentKey.self] = newValue }
    }
}
