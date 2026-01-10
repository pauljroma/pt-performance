//
//  ModeThemeModifier.swift
//  PTPerformance
//
//  Created by Claude (BUILD 115) on 2026-01-02.
//  ViewModifier for automatic mode theming
//

import SwiftUI

/// View modifier that applies mode-specific styling
struct ModeThemeModifier: ViewModifier {
    @ObservedObject var modeService = ModeService.shared
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let theme = ModeTheme.theme(for: modeService.currentMode)

        content
            .environment(\.mode, modeService.currentMode)
            .accentColor(theme.accentColor)
            .preferredColorScheme(preferredColorScheme(for: modeService.currentMode))
    }

    /// Determine preferred color scheme based on mode
    private func preferredColorScheme(for mode: Mode) -> ColorScheme? {
        switch mode {
        case .rehab:
            return .light  // Medical blue looks best on light
        case .strength:
            return .light  // Performance black on light gray
        case .performance:
            return .dark  // Elite gold on dark background
        }
    }
}

extension View {
    /// Apply mode theme to this view (automatically updates when mode changes)
    func withModeTheme() -> some View {
        self.modifier(ModeThemeModifier())
    }
}

/// Mode-aware card background
struct ModeCardBackground: View {
    @ObservedObject var modeService = ModeService.shared

    var body: some View {
        let theme = ModeTheme.theme(for: modeService.currentMode)

        RoundedRectangle(cornerRadius: 12)
            .fill(theme.backgroundColor)
            .shadow(
                color: theme.primaryColor.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

/// Mode-aware button style
struct ModeButtonStyle: ButtonStyle {
    @ObservedObject var modeService = ModeService.shared
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let theme = ModeTheme.theme(for: modeService.currentMode)

        configuration.label
            .font(.headline)
            .foregroundColor(isPrimary ? .white : theme.primaryColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isPrimary ? theme.primaryColor : Color.clear
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.primaryColor, lineWidth: isPrimary ? 0 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Mode-aware text style
extension Text {
    func modeStyled(_ style: ModeTextStyle = .body) -> some View {
        ModeStyledText(text: self, style: style)
    }
}

enum ModeTextStyle {
    case title
    case headline
    case body
    case caption
}

struct ModeStyledText: View {
    @ObservedObject var modeService = ModeService.shared
    let text: Text
    let style: ModeTextStyle

    var body: some View {
        let theme = ModeTheme.theme(for: modeService.currentMode)

        text
            .font(font(for: style))
            .foregroundColor(textColor(for: style, theme: theme))
    }

    private func font(for style: ModeTextStyle) -> Font {
        switch style {
        case .title:
            return .largeTitle.bold()
        case .headline:
            return .headline
        case .body:
            return .body
        case .caption:
            return .caption
        }
    }

    private func textColor(for style: ModeTextStyle, theme: ModeTheme) -> Color {
        switch style {
        case .title, .headline:
            return theme.primaryColor
        case .body:
            return theme.textColor
        case .caption:
            return theme.textColor.opacity(0.6)
        }
    }
}
