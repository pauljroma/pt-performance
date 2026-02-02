//
//  HapticService.swift
//  PTPerformance
//
//  Centralized haptic feedback service for consistent tactile feedback throughout the app.
//  Provides a singleton pattern with support for different haptic types and system settings.
//

import UIKit

// MARK: - Haptic Type Enum

/// Types of haptic feedback available throughout the app
enum HapticType {
    // Impact feedback - for physical interactions
    case light      // Button taps, light touches
    case medium     // Selections, moderate interactions
    case heavy      // Significant actions, confirmations

    // Notification feedback - for status updates
    case success    // Completion, set logged, workout finished
    case warning    // Alerts, high pain scores, deload recommendations
    case error      // Validation errors, failed operations

    // Selection feedback - for UI state changes
    case selection  // Tab switches, picker changes, toggles
}

// MARK: - Haptic Service

/// Centralized service for triggering haptic feedback
/// Respects user's system haptic settings automatically (UIFeedbackGenerator handles this)
final class HapticService {

    // MARK: - Singleton

    static let shared = HapticService()

    // MARK: - Private Properties

    /// Pre-initialized generators for better performance
    /// Generators are prepared on first use and reused
    private lazy var lightImpact = UIImpactFeedbackGenerator(style: .light)
    private lazy var mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private lazy var heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var notificationGenerator = UINotificationFeedbackGenerator()
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Private init for singleton pattern
        // Pre-warm generators for faster first-use response
        prepareGenerators()
    }

    // MARK: - Public Methods

    /// Trigger haptic feedback of the specified type
    /// - Parameter type: The type of haptic feedback to trigger
    func trigger(_ type: HapticType) {
        switch type {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .selection:
            selectionGenerator.selectionChanged()
        }
    }

    /// Trigger impact feedback with a specific intensity
    /// - Parameters:
    ///   - style: The style of impact (light, medium, heavy)
    ///   - intensity: The intensity of the impact (0.0 to 1.0)
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }

    /// Prepare all generators for faster response
    /// Call this before an interaction where immediate haptic response is critical
    func prepareGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Prepare a specific generator for faster response
    /// - Parameter type: The type of haptic to prepare
    func prepare(for type: HapticType) {
        switch type {
        case .light:
            lightImpact.prepare()
        case .medium:
            mediumImpact.prepare()
        case .heavy:
            heavyImpact.prepare()
        case .success, .warning, .error:
            notificationGenerator.prepare()
        case .selection:
            selectionGenerator.prepare()
        }
    }
}

// MARK: - Convenience Static Methods

extension HapticService {

    /// Quick access to trigger light haptic
    static func light() {
        shared.trigger(.light)
    }

    /// Quick access to trigger medium haptic
    static func medium() {
        shared.trigger(.medium)
    }

    /// Quick access to trigger heavy haptic
    static func heavy() {
        shared.trigger(.heavy)
    }

    /// Quick access to trigger success haptic
    static func success() {
        shared.trigger(.success)
    }

    /// Quick access to trigger warning haptic
    static func warning() {
        shared.trigger(.warning)
    }

    /// Quick access to trigger error haptic
    static func error() {
        shared.trigger(.error)
    }

    /// Quick access to trigger selection haptic
    static func selection() {
        shared.trigger(.selection)
    }

    /// Alias for selection() to match HapticFeedback API
    static func selectionChanged() {
        shared.trigger(.selection)
    }
}
