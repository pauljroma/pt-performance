//
//  AccessibilityModifiers.swift
//  PTPerformance
//
//  ACP-925: VoiceOver Audit & Fix
//  Reusable SwiftUI view modifiers for common accessibility patterns.
//
//  Usage:
//  ```swift
//  WorkoutCard(workout: workout)
//      .accessibleCard(label: "Push day workout", hint: "Double tap to start")
//
//  PainTrendChart(data: painData)
//      .accessibleChart(title: "Pain trend", summary: chartSummary)
//  ```
//

import SwiftUI

// MARK: - Accessible Card Modifier

/// Makes a card-like view a single accessibility element with combined children.
///
/// VoiceOver reads the entire card as one unit instead of announcing every
/// child label individually. Use for workout cards, stat tiles, list rows, etc.
private struct AccessibleCardModifier: ViewModifier {

    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Accessible Chart Modifier

/// Marks a chart view as a single accessibility element with a descriptive
/// text summary replacing the visual content for VoiceOver users.
private struct AccessibleChartModifier: ViewModifier {

    let title: String
    let summary: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(summary)
    }
}

// MARK: - Accessible Toggle Modifier

/// Provides proper toggle accessibility with value announcement.
///
/// VoiceOver announces both the label and the current on/off state so users
/// know the toggle's position before interacting with it.
private struct AccessibleToggleModifier: ViewModifier {

    let label: String
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessible Progress Bar Modifier

/// Announces progress in a human-readable format.
///
/// Example announcement: "Progress: 3 of 10 exercises completed, 30 percent"
private struct AccessibleProgressBarModifier: ViewModifier {

    let label: String
    let value: Double
    let total: Double

    func body(content: Content) -> some View {
        let intValue = Int(value)
        let intTotal = Int(total)
        let pct = total > 0 ? Int((value / total * 100).rounded()) : 0

        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue("\(intValue) of \(intTotal) completed, \(pct) percent")
    }
}

// MARK: - Accessible Sort Button Modifier

/// Announces the current sort state alongside the button label.
///
/// Example: "Sort exercises, currently sorted by date"
private struct AccessibleSortButtonModifier: ViewModifier {

    let label: String
    let currentSort: String

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityValue("Currently sorted by \(currentSort)")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Announce Change Modifier

/// Posts a `UIAccessibility.post(notification: .announcement)` whenever the
/// observed value changes.
///
/// Useful for live-updating content such as timers, rep counters, or score
/// changes where VoiceOver should announce the new value without requiring
/// the user to re-focus the element.
private struct AnnounceChangeModifier<V: Equatable>: ViewModifier {

    let value: V
    let message: (V) -> String

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                let announcement = message(newValue)
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
    }
}

// MARK: - Accessible Heading Modifier

/// Marks text as a heading for VoiceOver navigation.
///
/// VoiceOver users can navigate between headings using the rotor. Marking
/// section headers with this modifier greatly improves page navigation.
private struct AccessibleHeadingModifier: ViewModifier {

    let level: AccessibilityHeadingLevel

    func body(content: Content) -> some View {
        content
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
}

// MARK: - View Extensions

extension View {

    /// Makes a card-like view a single accessibility element.
    ///
    /// Combines all children into one VoiceOver element and sets the label/hint.
    ///
    /// - Parameters:
    ///   - label: The accessibility label read by VoiceOver.
    ///   - hint: Optional hint describing what happens on activation.
    /// - Returns: The modified view.
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        modifier(AccessibleCardModifier(label: label, hint: hint))
    }

    /// Marks a chart view as a single accessibility element with a summary.
    ///
    /// VoiceOver ignores the chart's visual children and instead reads the
    /// provided title and summary text.
    ///
    /// - Parameters:
    ///   - title: Chart title, e.g. "Pain trend chart".
    ///   - summary: A text summary of the chart's data (use `AccessibilityKit.ChartAccessibility.summary`).
    /// - Returns: The modified view.
    func accessibleChart(title: String, summary: String) -> some View {
        modifier(AccessibleChartModifier(title: title, summary: summary))
    }

    /// Provides proper toggle accessibility with value announcement.
    ///
    /// - Parameters:
    ///   - label: The toggle's accessibility label.
    ///   - isOn: The current state of the toggle.
    /// - Returns: The modified view.
    func accessibleToggle(label: String, isOn: Bool) -> some View {
        modifier(AccessibleToggleModifier(label: label, isOn: isOn))
    }

    /// Announces progress in a human-readable format for VoiceOver.
    ///
    /// Example: "Progress: 3 of 10 exercises completed, 30 percent"
    ///
    /// - Parameters:
    ///   - label: A label describing what the progress represents.
    ///   - value: Current progress value.
    ///   - total: Total/maximum value.
    /// - Returns: The modified view.
    func accessibleProgressBar(label: String, value: Double, total: Double) -> some View {
        modifier(AccessibleProgressBarModifier(label: label, value: value, total: total))
    }

    /// Announces the current sort state alongside the button label.
    ///
    /// - Parameters:
    ///   - label: The sort button's label.
    ///   - currentSort: Description of the current sort order.
    /// - Returns: The modified view.
    func accessibleSortButton(label: String, currentSort: String) -> some View {
        modifier(AccessibleSortButtonModifier(label: label, currentSort: currentSort))
    }

    /// Posts a VoiceOver announcement when the observed value changes.
    ///
    /// - Parameters:
    ///   - value: The value to observe for changes.
    ///   - message: A closure that produces the announcement string from the new value.
    /// - Returns: The modified view.
    func announceChange<V: Equatable>(_ value: V, message: @escaping (V) -> String) -> some View {
        modifier(AnnounceChangeModifier(value: value, message: message))
    }

    /// Marks this view as a heading for VoiceOver rotor navigation.
    ///
    /// - Parameter level: The heading level (`.unspecified`, `.h1`, `.h2`, etc.).
    /// - Returns: The modified view.
    func accessibleHeading(_ level: AccessibilityHeadingLevel = .unspecified) -> some View {
        modifier(AccessibleHeadingModifier(level: level))
    }
}
