import SwiftUI
import UIKit

// MARK: - Modus Brand Colors
extension Color {
    // MARK: - Adaptive Brand Colors (Dark Mode Aware)

    /// Deep Teal - Headlines, headers, primary text
    /// Light: #0D4F4F | Dark: Brightened for visibility
    static var modusDeepTeal: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 45/255, green: 140/255, blue: 140/255, alpha: 1.0)  // Brighter teal
                : UIColor(red: 13/255, green: 79/255, blue: 79/255, alpha: 1.0)
        })
    }

    /// Cyan - CTAs, links, tint color, interactive elements
    /// Light: #0891B2 | Dark: Brightened for visibility
    static var modusCyan: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 56/255, green: 189/255, blue: 220/255, alpha: 1.0)  // Brighter cyan
                : UIColor(red: 8/255, green: 145/255, blue: 178/255, alpha: 1.0)
        })
    }

    /// Teal Accent - Accents, success states, highlights
    /// Light: #14B8A6 | Dark: Brightened for visibility
    static var modusTealAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 60/255, green: 210/255, blue: 195/255, alpha: 1.0)  // Brighter teal accent
                : UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0)
        })
    }

    /// Light Teal - Backgrounds, cards, subtle fills
    /// Light: #F0FDFA | Dark: Dark teal-tinted background
    static var modusLightTeal: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 18/255, green: 35/255, blue: 35/255, alpha: 1.0)  // Dark teal-tinted
                : UIColor(red: 240/255, green: 253/255, blue: 250/255, alpha: 1.0)
        })
    }

    // MARK: - Static Brand Colors (Non-Adaptive)
    // Use these when you need the exact brand color regardless of mode

    /// Static Deep Teal - use modusDeepTeal for adaptive version
    static let modusDeepTealStatic = Color(red: 13/255, green: 79/255, blue: 79/255)

    /// Static Cyan - use modusCyan for adaptive version
    static let modusCyanStatic = Color(red: 8/255, green: 145/255, blue: 178/255)

    /// Static Teal Accent - use modusTealAccent for adaptive version
    static let modusTealAccentStatic = Color(red: 20/255, green: 184/255, blue: 166/255)

    /// Static Light Teal - use modusLightTeal for adaptive version
    static let modusLightTealStatic = Color(red: 240/255, green: 253/255, blue: 250/255)

    // MARK: - Semantic Color Aliases

    /// Primary brand color for headlines and emphasis
    static var modusPrimary: Color { modusDeepTeal }

    /// Tint color for buttons, links, and interactive elements
    static var modusTint: Color { modusCyan }

    /// Success color for completed states, positive indicators
    static var modusSuccess: Color { modusTealAccent }

    /// Background color for cards and containers (adaptive)
    static var modusBackground: Color { modusLightTeal }

    // MARK: - Gradients

    /// Primary brand gradient (bottom-left to top-right)
    /// Adapts to dark mode with brighter colors
    static var modusGradient: LinearGradient {
        LinearGradient(
            colors: [modusDeepTeal, modusTealAccent],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    /// Subtle gradient for backgrounds (adaptive)
    static var modusSubtleGradient: LinearGradient {
        LinearGradient(
            colors: [
                modusLightTeal,
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor.secondarySystemBackground
                        : UIColor.white
                })
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Hero gradient for prominent headers (adaptive)
    static var modusHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 8/255, green: 50/255, blue: 60/255, alpha: 1.0)
                        : UIColor(red: 8/255, green: 145/255, blue: 178/255, alpha: 1.0)
                }),
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 15/255, green: 45/255, blue: 45/255, alpha: 1.0)
                        : UIColor(red: 13/255, green: 79/255, blue: 79/255, alpha: 1.0)
                })
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - UIColor Extensions for UIKit compatibility
extension UIColor {
    /// Adaptive Deep Teal
    static var modusDeepTeal: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 45/255, green: 140/255, blue: 140/255, alpha: 1.0)
                : UIColor(red: 13/255, green: 79/255, blue: 79/255, alpha: 1.0)
        }
    }

    /// Adaptive Cyan
    static var modusCyan: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 56/255, green: 189/255, blue: 220/255, alpha: 1.0)
                : UIColor(red: 8/255, green: 145/255, blue: 178/255, alpha: 1.0)
        }
    }

    /// Adaptive Teal Accent
    static var modusTealAccent: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 60/255, green: 210/255, blue: 195/255, alpha: 1.0)
                : UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0)
        }
    }

    /// Adaptive Light Teal
    static var modusLightTeal: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 18/255, green: 35/255, blue: 35/255, alpha: 1.0)
                : UIColor(red: 240/255, green: 253/255, blue: 250/255, alpha: 1.0)
        }
    }

    // Static versions for when exact color is needed
    static let modusDeepTealStatic = UIColor(red: 13/255, green: 79/255, blue: 79/255, alpha: 1.0)
    static let modusCyanStatic = UIColor(red: 8/255, green: 145/255, blue: 178/255, alpha: 1.0)
    static let modusTealAccentStatic = UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0)
    static let modusLightTealStatic = UIColor(red: 240/255, green: 253/255, blue: 250/255, alpha: 1.0)
}

// MARK: - View Modifiers
extension View {
    /// Apply Modus gradient as background
    func modusGradientBackground() -> some View {
        self.background(Color.modusGradient)
    }

    /// Apply Modus hero gradient as background
    func modusHeroGradientBackground() -> some View {
        self.background(Color.modusHeroGradient)
    }

    /// Apply Modus tint color
    func modusTinted() -> some View {
        self.tint(.modusCyan)
    }

    /// Apply Modus-themed card styling with dark mode support
    func modusCardStyle() -> some View {
        self.modifier(ModusCardStyleModifier())
    }
}

// MARK: - Modus Card Style Modifier

/// Self-contained modifier for Modus-themed cards with dark mode support
private struct ModusCardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.modusLightTeal)
            .cornerRadius(CornerRadius.md)
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.25)
                    : Color.black.opacity(0.05),
                radius: 4,
                x: 0,
                y: 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        colorScheme == .dark
                            ? Color.modusTealAccent.opacity(0.2)
                            : Color.clear,
                        lineWidth: 0.5
                    )
            )
    }
}
