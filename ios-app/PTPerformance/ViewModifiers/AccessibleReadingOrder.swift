//
//  AccessibleReadingOrder.swift
//  PTPerformance
//
//  ACP-925: VoiceOver Audit & Fix
//  Utilities for controlling VoiceOver reading order, grouping related
//  elements, hiding decorative content, and adding custom actions.
//
//  Usage:
//  ```swift
//  // Control reading order (higher priority = read first)
//  HeaderView()
//      .readingOrder(10)
//  BodyView()
//      .readingOrder(5)
//
//  // Group related elements under one label
//  HStack { ... }
//      .accessibleGroup(label: "Workout stats")
//
//  // Hide decorative images from VoiceOver
//  DecorativeDivider()
//      .skipInAccessibility()
//  ```
//

import SwiftUI

// MARK: - Reading Order Modifier

/// Sets `accessibilitySortPriority` to control VoiceOver reading order.
///
/// Higher values are read first. Use this when the visual layout differs
/// from the logical reading order (e.g., a floating header that appears
/// below the content in the view hierarchy).
private struct ReadingOrderModifier: ViewModifier {

    let priority: Int

    func body(content: Content) -> some View {
        content
            .accessibilitySortPriority(Double(priority))
    }
}

// MARK: - Accessible Group Modifier

/// Groups related child elements together with `.accessibilityElement(children: .contain)`
/// and provides a label for the group.
///
/// VoiceOver announces the group label when the user enters the group,
/// then reads each child element individually within the group context.
private struct AccessibleGroupModifier: ViewModifier {

    let label: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }
}

// MARK: - Skip In Accessibility Modifier

/// Hides a view from VoiceOver entirely.
///
/// Use for decorative elements such as dividers, background images, or
/// icons that are already described by an adjacent label.
private struct SkipInAccessibilityModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(true)
    }
}

// MARK: - Accessible Action Modifier

/// Adds a custom accessibility action to a view.
///
/// Custom actions appear in VoiceOver's actions rotor and provide
/// alternative interactions that don't require precise gestures.
/// For example, a swipe-to-delete action on a list row.
private struct AccessibleActionModifier: ViewModifier {

    let label: String
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: Text(label)) {
                action()
            }
    }
}

// MARK: - View Extensions

extension View {

    /// Sets the VoiceOver reading order priority.
    ///
    /// Higher values are read first. Elements with the same priority
    /// fall back to the default geometric reading order.
    ///
    /// - Parameter priority: The sort priority (higher = read sooner).
    /// - Returns: The modified view.
    func readingOrder(_ priority: Int) -> some View {
        modifier(ReadingOrderModifier(priority: priority))
    }

    /// Groups related elements together with a label for VoiceOver.
    ///
    /// Child elements remain individually focusable within the group,
    /// but VoiceOver announces the group label when the user enters
    /// this region.
    ///
    /// - Parameter label: A label describing the group of elements.
    /// - Returns: The modified view.
    func accessibleGroup(label: String) -> some View {
        modifier(AccessibleGroupModifier(label: label))
    }

    /// Hides this view from VoiceOver.
    ///
    /// Use for purely decorative elements (dividers, background images,
    /// ornamental icons) that add no informational value.
    ///
    /// - Returns: The modified view.
    func skipInAccessibility() -> some View {
        modifier(SkipInAccessibilityModifier())
    }

    /// Adds a custom accessibility action to this view.
    ///
    /// Custom actions are listed in VoiceOver's actions rotor and can be
    /// activated with a swipe gesture. Use for secondary actions like
    /// delete, share, or toggle that would otherwise require precise gestures.
    ///
    /// - Parameters:
    ///   - label: The action label announced by VoiceOver.
    ///   - action: The closure to execute when the action is activated.
    /// - Returns: The modified view.
    func accessibleAction(label: String, action: @escaping () -> Void) -> some View {
        modifier(AccessibleActionModifier(label: label, action: action))
    }
}
