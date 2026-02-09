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

// MARK: - Semantic Colors for Dark Mode Support

/// Semantic color tokens that adapt to light/dark mode
/// Uses UIColor dynamic providers for automatic appearance updates
extension DesignTokens {

    // MARK: - Background Colors

    /// Primary background - adapts to systemBackground
    static let backgroundPrimary = Color(.systemBackground)

    /// Secondary background - for cards and elevated surfaces
    static let backgroundSecondary = Color(.secondarySystemBackground)

    /// Tertiary background - for nested containers
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    /// Grouped background - for table/list backgrounds
    static let backgroundGrouped = Color(.systemGroupedBackground)

    /// Elevated surface - cards, sheets, popovers
    static let surfaceElevated = Color(.secondarySystemGroupedBackground)

    // MARK: - Text Colors

    /// Primary text - highest contrast
    static let textPrimary = Color(.label)

    /// Secondary text - medium emphasis
    static let textSecondary = Color(.secondaryLabel)

    /// Tertiary text - lowest emphasis
    static let textTertiary = Color(.tertiaryLabel)

    /// Placeholder text
    static let textPlaceholder = Color(.placeholderText)

    // MARK: - Border & Separator Colors

    /// Standard separator
    static let separator = Color(.separator)

    /// Opaque separator (for non-transparent backgrounds)
    static let separatorOpaque = Color(.opaqueSeparator)

    // MARK: - Fill Colors (for shapes and controls)

    /// Primary fill - most visible
    static let fillPrimary = Color(.systemFill)

    /// Secondary fill
    static let fillSecondary = Color(.secondarySystemFill)

    /// Tertiary fill
    static let fillTertiary = Color(.tertiarySystemFill)

    /// Quaternary fill - least visible
    static let fillQuaternary = Color(.quaternarySystemFill)

    // MARK: - Status Colors with Dark Mode Optimization

    /// Success color - slightly adjusted for dark mode visibility
    static var statusSuccess: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)  // Brighter green
                : UIColor.systemGreen
        })
    }

    /// Warning color - adjusted for dark mode
    static var statusWarning: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)  // Brighter yellow/orange
                : UIColor.systemOrange
        })
    }

    /// Error color - adjusted for dark mode
    static var statusError: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)  // Brighter red
                : UIColor.systemRed
        })
    }

    /// Info color - adjusted for dark mode
    static var statusInfo: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0)  // Brighter blue
                : UIColor.systemBlue
        })
    }

    // MARK: - Chart Colors (Dark Mode Optimized)

    /// Primary chart line/bar color
    static var chartPrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0)  // Brighter blue
                : UIColor.systemBlue
        })
    }

    /// Secondary chart color
    static var chartSecondary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.85, blue: 0.7, alpha: 1.0)  // Brighter teal
                : UIColor.systemTeal
        })
    }

    /// Tertiary chart color
    static var chartTertiary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.6, green: 0.5, blue: 1.0, alpha: 1.0)  // Brighter purple
                : UIColor.systemPurple
        })
    }

    /// Chart fill color with appropriate opacity for dark mode
    static var chartFill: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemBlue.withAlphaComponent(0.3)
                : UIColor.systemBlue.withAlphaComponent(0.15)
        })
    }

    /// Chart grid lines
    static var chartGrid: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.15)
                : UIColor.black.withAlphaComponent(0.1)
        })
    }

    // MARK: - Button Text Colors

    /// Text color for primary buttons (on accent-colored backgrounds)
    /// Uses white in both modes as it contrasts well with brand colors
    static let buttonTextOnAccent = Color.white

    /// Text color for secondary buttons
    static let buttonTextSecondary = Color(.label)

    // MARK: - Shadow Colors

    /// Shadow color that adapts to color scheme
    /// Less visible in dark mode where shadows are less effective
    static var shadowColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.4)
                : UIColor.black.withAlphaComponent(0.1)
        })
    }

    /// Subtle shadow for cards
    static var shadowSubtle: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.25)
                : UIColor.black.withAlphaComponent(0.05)
        })
    }
}
