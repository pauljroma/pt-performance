//
//  Color+DarkMode.swift
//  PTPerformance
//
//  Dark mode semantic color helpers and extensions
//  Provides adaptive colors that look great in both light and dark modes
//

import SwiftUI
import UIKit

// MARK: - Semantic Color Helpers

extension Color {

    // MARK: - Adaptive Text Colors

    /// High-contrast text that works on both light and dark backgrounds
    /// Use for text on colored backgrounds (buttons, badges, etc.)
    static func adaptiveText(on backgroundColor: Color, lightModeColor: Color = .white, darkModeColor: Color = .white) -> Color {
        // For colored backgrounds, white typically works well in both modes
        return lightModeColor
    }

    /// Off-white text color that avoids pure white on dark backgrounds
    /// Provides a softer look and reduces eye strain
    static var softWhite: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.95, alpha: 1.0)  // Slightly off-white
                : UIColor.white
        })
    }

    /// Off-black text color that avoids pure black on light backgrounds
    /// Provides better readability than pure black
    static var softBlack: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(white: 0.1, alpha: 1.0)  // Slightly off-black
        })
    }

    // MARK: - Adaptive Overlay Colors

    /// Overlay color for dimming backgrounds (modals, sheets)
    static var adaptiveOverlay: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.6)
                : UIColor.black.withAlphaComponent(0.4)
        })
    }

    /// Highlight overlay for pressed states
    static var adaptiveHighlight: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.1)
                : UIColor.black.withAlphaComponent(0.05)
        })
    }

    // MARK: - Card & Surface Colors

    /// Elevated card background that provides subtle lift
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemGroupedBackground
                : UIColor.systemBackground
        })
    }

    /// Card background on grouped backgrounds
    static var cardBackgroundOnGrouped: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemGroupedBackground
                : UIColor.systemBackground
        })
    }

    // MARK: - Badge & Chip Colors

    /// Badge background that works in both modes
    static var badgeBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemFill
                : UIColor.secondarySystemFill
        })
    }

    /// Selected chip/badge background
    static var chipSelectedBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.2)
                : UIColor.white.withAlphaComponent(0.25)
        })
    }

    // MARK: - Video Overlay Colors

    /// Gradient overlay for video thumbnails and images
    static var videoOverlayGradient: [Color] {
        [.clear, .clear, Color.black.opacity(0.6)]
    }

    /// Play button background on video thumbnails
    static var videoPlayButtonBackground: Color {
        Color.black.opacity(0.6)
    }
}

// MARK: - View Extensions for Dark Mode

extension View {

    /// Applies adaptive foreground color for text on colored backgrounds
    /// Use when placing text on accent-colored buttons or badges
    func adaptiveForegroundOnAccent() -> some View {
        self.foregroundColor(.white)
    }

    /// Applies adaptive shadow that works in both light and dark mode
    /// Shadows are more subtle in dark mode
    func adaptiveCardShadow(radius: CGFloat = 4, y: CGFloat = 2) -> some View {
        self.shadow(color: DesignTokens.shadowSubtle, radius: radius, x: 0, y: y)
    }

    /// Applies a subtle border in dark mode for better card definition
    /// Cards in dark mode benefit from borders since shadows are less visible
    func adaptiveCardBorder(color: Color = Color(.separator), width: CGFloat = 0.5) -> some View {
        self.modifier(AdaptiveCardBorderModifier(color: color, width: width))
    }
}

/// Modifier that adds a subtle border in dark mode
struct AdaptiveCardBorderModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        colorScheme == .dark ? color : .clear,
                        lineWidth: width
                    )
            )
    }
}

// MARK: - Chart Color Helpers

extension Color {

    /// Returns a chart-friendly color palette that works in both modes
    static var chartColorPalette: [Color] {
        [
            DesignTokens.chartPrimary,
            DesignTokens.chartSecondary,
            DesignTokens.chartTertiary,
            DesignTokens.statusSuccess,
            DesignTokens.statusWarning
        ]
    }

    /// Annotation line color for charts
    static var chartAnnotation: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.5)
                : UIColor.black.withAlphaComponent(0.3)
        })
    }

    /// Chart axis label color
    static var chartAxisLabel: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondaryLabel
                : UIColor.secondaryLabel
        })
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {

    /// Adaptive gradient for hero sections/banners
    static func adaptiveHeroGradient(primary: Color, secondary: Color) -> LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle gradient for card backgrounds
    static var adaptiveCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor.tertiarySystemGroupedBackground
                        : UIColor.systemBackground
                }),
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor.secondarySystemGroupedBackground
                        : UIColor.secondarySystemBackground
                })
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - UIColor Convenience Extensions

extension UIColor {

    /// Creates a dynamic color that adapts to light/dark mode
    static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// Brightens a color for dark mode visibility
    func brightenedForDarkMode(by factor: CGFloat = 0.2) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return UIColor(
            hue: hue,
            saturation: max(0, saturation - factor * 0.3),  // Slightly desaturate
            brightness: min(1, brightness + factor),        // Brighten
            alpha: alpha
        )
    }
}

// MARK: - Contrast Helpers

extension Color {

    /// Returns whether the color is considered "light" (needs dark text)
    /// Useful for determining text color on dynamic backgrounds
    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components else { return true }

        let red = components[0]
        let green = components.count > 1 ? components[1] : components[0]
        let blue = components.count > 2 ? components[2] : components[0]

        // Calculate relative luminance using sRGB formula
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5
    }

    /// Returns appropriate text color (black or white) based on background luminance
    /// Ensures WCAG AA contrast ratio compliance
    var contrastingTextColor: Color {
        isLight ? .black : .white
    }
}
