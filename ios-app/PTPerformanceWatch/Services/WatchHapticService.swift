//
//  WatchHapticService.swift
//  PTPerformanceWatch
//
//  Haptic feedback service for Apple Watch
//  ACP-824: Apple Watch Standalone App
//

import WatchKit
import Foundation

/// Centralized haptic feedback service for Apple Watch
/// Provides workout-specific haptic patterns using WKInterfaceDevice
final class WatchHapticService {

    // MARK: - Singleton

    static let shared = WatchHapticService()

    // MARK: - Private Properties

    private let device = WKInterfaceDevice.current()

    // MARK: - Initialization

    private init() {}

    // MARK: - Rest Timer Haptics

    /// Subtle tick during rest intervals (every 15 seconds)
    func restIntervalPulse() {
        device.play(.click)
    }

    /// Strong notification when rest is complete
    func restComplete() {
        // Play a distinct pattern: notification + short delay + notification
        device.play(.notification)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.device.play(.directionUp)
        }
    }

    // MARK: - Set Logging Haptics

    /// Success haptic when set is logged
    func setLogged() {
        device.play(.success)
    }

    /// Success feedback (alias for common use)
    func success() {
        device.play(.success)
    }

    // MARK: - Workout Completion Haptics

    /// Celebration haptic pattern for workout completion
    func workoutComplete() {
        // Victory pattern: success, pause, success, pause, notification
        device.play(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.device.play(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.device.play(.notification)
        }
    }

    // MARK: - UI Feedback Haptics

    /// Selection change feedback
    func selection() {
        device.play(.click)
    }

    /// Error feedback
    func error() {
        device.play(.failure)
    }

    /// Warning feedback
    func warning() {
        device.play(.retry)
    }

    /// Start workout feedback
    func workoutStart() {
        device.play(.start)
    }

    /// Stop workout feedback
    func workoutStop() {
        device.play(.stop)
    }

    // MARK: - Timer Haptics

    /// Countdown haptic (for final seconds)
    func countdownTick() {
        device.play(.click)
    }

    /// Timer start haptic
    func timerStart() {
        device.play(.start)
    }

    /// Timer stop haptic
    func timerStop() {
        device.play(.stop)
    }

    // MARK: - Custom Patterns

    /// Play a custom haptic pattern for special events
    /// - Parameters:
    ///   - types: Array of haptic types to play in sequence
    ///   - interval: Delay between each haptic in seconds
    func playPattern(_ types: [WKHapticType], interval: TimeInterval = 0.2) {
        for (index, type) in types.enumerated() {
            let delay = TimeInterval(index) * interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.device.play(type)
            }
        }
    }

    /// Encouragement haptic for hitting personal records
    func personalRecord() {
        playPattern([.success, .success, .notification], interval: 0.15)
    }

    /// Gentle reminder haptic
    func reminder() {
        device.play(.directionUp)
    }
}

// MARK: - Convenience Extensions

extension WatchHapticService {

    /// Play haptic for a specific rest timer interval
    /// Different intensities based on time remaining
    func restTimerHaptic(secondsRemaining: Int) {
        switch secondsRemaining {
        case 0:
            restComplete()
        case 1...3:
            device.play(.directionDown)
        case 5:
            device.play(.click)
        case 10:
            device.play(.click)
        case 15, 30, 45, 60, 90, 120:
            restIntervalPulse()
        default:
            break
        }
    }

    /// Play haptic based on RPE score
    func rpeHaptic(rpe: Int) {
        switch rpe {
        case 1...3:
            device.play(.click)
        case 4...6:
            device.play(.directionUp)
        case 7...8:
            device.play(.success)
        case 9...10:
            playPattern([.success, .notification], interval: 0.2)
        default:
            break
        }
    }
}
