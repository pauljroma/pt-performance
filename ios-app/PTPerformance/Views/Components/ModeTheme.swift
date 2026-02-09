//
//  ModeTheme.swift
//  PTPerformance
//
//  Created by Claude (BUILD 115) on 2026-01-02.
//  Visual themes for 3-mode architecture
//

import SwiftUI

/// Visual theme for each mode
struct ModeTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color

    /// Get theme for a specific mode
    static func theme(for mode: Mode) -> ModeTheme {
        switch mode {
        case .rehab:
            return ModeTheme.rehab
        case .strength:
            return ModeTheme.strength
        case .performance:
            return ModeTheme.performance
        }
    }

    // MARK: - REHAB Theme (Medical Blue)
    static let rehab = ModeTheme(
        primaryColor: Color(red: 0/255, green: 102/255, blue: 204/255),  // #0066CC
        secondaryColor: Color(red: 51/255, green: 153/255, blue: 255/255),  // Lighter blue
        backgroundColor: Color(.systemBackground),
        textColor: Color(.label),
        accentColor: Color(red: 0/255, green: 102/255, blue: 204/255)
    )

    // MARK: - STRENGTH Theme (Performance Black)
    static let strength = ModeTheme(
        primaryColor: Color(.label),
        secondaryColor: Color(.secondaryLabel),
        backgroundColor: Color(.systemGroupedBackground),
        textColor: Color(.label),
        accentColor: Color(red: 0/255, green: 122/255, blue: 255/255)  // iOS blue
    )

    // MARK: - PERFORMANCE Theme (Elite Gold)
    // Uses adaptive colors for proper dark mode support
    static var performance: ModeTheme {
        ModeTheme(
            primaryColor: Color(UIColor { traitCollection in
                // Gold color - slightly brighter in dark mode
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 255/255, green: 220/255, blue: 50/255, alpha: 1.0)
                    : UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
            }),
            secondaryColor: Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1.0)
                    : UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
            }),
            backgroundColor: Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 12/255, green: 12/255, blue: 12/255, alpha: 1.0)  // Darker in dark mode
                    : UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1.0)
            }),
            textColor: Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 255/255, green: 220/255, blue: 50/255, alpha: 1.0)
                    : UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
            }),
            accentColor: Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 255/255, green: 220/255, blue: 50/255, alpha: 1.0)
                    : UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
            })
        )
    }
}

/// Environment key for current mode
struct ModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Mode = .rehab
}

extension EnvironmentValues {
    var mode: Mode {
        get { self[ModeEnvironmentKey.self] }
        set { self[ModeEnvironmentKey.self] = newValue }
    }
}

/// SwiftUI View extension for mode-aware theming
extension View {
    /// Apply mode-specific theme to this view
    func modeThemed(_ mode: Mode) -> some View {
        let theme = ModeTheme.theme(for: mode)
        return self
            .environment(\.mode, mode)
            .accentColor(theme.accentColor)
    }
}
