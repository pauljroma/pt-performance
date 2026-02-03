import SwiftUI
import UIKit

// MARK: - Modus Brand Colors
extension Color {
    // Primary Brand Colors
    /// Deep Teal - Headlines, headers, primary text
    /// Hex: #0D4F4F | RGB: 13, 79, 79
    static let modusDeepTeal = Color(red: 13/255, green: 79/255, blue: 79/255)

    /// Cyan - CTAs, links, tint color, interactive elements
    /// Hex: #0891B2 | RGB: 8, 145, 178
    static let modusCyan = Color(red: 8/255, green: 145/255, blue: 178/255)

    /// Teal Accent - Accents, success states, highlights
    /// Hex: #14B8A6 | RGB: 20, 184, 166
    static let modusTealAccent = Color(red: 20/255, green: 184/255, blue: 166/255)

    /// Light Teal - Backgrounds, cards, subtle fills
    /// Hex: #F0FDFA | RGB: 240, 253, 250
    static let modusLightTeal = Color(red: 240/255, green: 253/255, blue: 250/255)

    // MARK: - Semantic Color Aliases

    /// Primary brand color for headlines and emphasis
    static let modusPrimary = modusDeepTeal

    /// Tint color for buttons, links, and interactive elements
    static let modusTint = modusCyan

    /// Success color for completed states, positive indicators
    static let modusSuccess = modusTealAccent

    /// Background color for cards and containers
    static let modusBackground = modusLightTeal

    // MARK: - Gradients

    /// Primary brand gradient (bottom-left to top-right)
    static var modusGradient: LinearGradient {
        LinearGradient(
            colors: [modusDeepTeal, modusTealAccent],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    /// Subtle gradient for backgrounds
    static var modusSubtleGradient: LinearGradient {
        LinearGradient(
            colors: [modusLightTeal, .white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - UIColor Extensions for UIKit compatibility
extension UIColor {
    static let modusDeepTeal = UIColor(red: 13/255, green: 79/255, blue: 79/255, alpha: 1.0)
    static let modusCyan = UIColor(red: 8/255, green: 145/255, blue: 178/255, alpha: 1.0)
    static let modusTealAccent = UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0)
    static let modusLightTeal = UIColor(red: 240/255, green: 253/255, blue: 250/255, alpha: 1.0)
}

// MARK: - View Modifiers
extension View {
    /// Apply Modus gradient as background
    func modusGradientBackground() -> some View {
        self.background(Color.modusGradient)
    }

    /// Apply Modus tint color
    func modusTinted() -> some View {
        self.tint(.modusCyan)
    }
}
