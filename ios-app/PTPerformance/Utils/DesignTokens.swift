import SwiftUI

/// Centralized design tokens for consistent UI styling across the app
enum DesignTokens {
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 20

    // MARK: - Spacing
    static let spacingXSmall: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 24
    static let spacingXXLarge: CGFloat = 32

    // MARK: - Icon Sizes
    static let iconSizeSmall: CGFloat = 16
    static let iconSizeMedium: CGFloat = 24
    static let iconSizeLarge: CGFloat = 32
    static let iconSizeXLarge: CGFloat = 48
    static let iconSizeXXLarge: CGFloat = 64

    // MARK: - Animation
    static let animationDurationFast: Double = 0.15
    static let animationDurationNormal: Double = 0.3
    static let animationDurationSlow: Double = 0.5
}
