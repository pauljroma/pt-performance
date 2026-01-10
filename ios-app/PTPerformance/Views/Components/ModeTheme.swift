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
        backgroundColor: .white,
        textColor: Color(red: 51/255, green: 51/255, blue: 51/255),  // Dark gray
        accentColor: Color(red: 0/255, green: 102/255, blue: 204/255)
    )

    // MARK: - STRENGTH Theme (Performance Black)
    static let strength = ModeTheme(
        primaryColor: Color(red: 26/255, green: 26/255, blue: 26/255),  // #1A1A1A
        secondaryColor: Color(red: 68/255, green: 68/255, blue: 68/255),  // Gray
        backgroundColor: Color(red: 245/255, green: 245/255, blue: 247/255),  // Light gray
        textColor: Color(red: 26/255, green: 26/255, blue: 26/255),
        accentColor: Color(red: 0/255, green: 122/255, blue: 255/255)  // iOS blue
    )

    // MARK: - PERFORMANCE Theme (Elite Gold)
    static let performance = ModeTheme(
        primaryColor: Color(red: 255/255, green: 215/255, blue: 0/255),  // #FFD700
        secondaryColor: Color(red: 26/255, green: 26/255, blue: 26/255),  // Black
        backgroundColor: Color(red: 18/255, green: 18/255, blue: 18/255),  // Very dark gray
        textColor: Color(red: 255/255, green: 215/255, blue: 0/255),  // Gold text
        accentColor: Color(red: 255/255, green: 215/255, blue: 0/255)
    )
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
