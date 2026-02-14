//
//  Formatters.swift
//  PTPerformance
//
//  Centralized formatting utilities for common display patterns.
//  Consolidates duplicate formatVolume/formatWeight/formatDuration implementations.
//
//  Call sites can be migrated incrementally from their local private functions
//  to use these canonical versions.
//

import Foundation

/// Canonical formatting utilities for volume, weight, and duration values.
/// Use these static methods instead of local private formatting functions.
enum Formatters {

    // MARK: - Volume Formatting

    /// Formats a volume value (e.g., total weight lifted) for display.
    ///
    /// - Values >= 1,000 are shown as "1.2K lbs"
    /// - Values < 1,000 are shown as "450 lbs"
    ///
    /// - Parameters:
    ///   - volume: The volume value in pounds
    ///   - unit: The unit label (defaults to "lbs")
    ///   - includeUnit: Whether to append the unit string (defaults to true)
    /// - Returns: A formatted string representation of the volume
    static func formatVolume(_ volume: Double, unit: String = "lbs", includeUnit: Bool = true) -> String {
        let suffix = includeUnit ? " \(unit)" : ""
        if volume >= 1000 {
            return String(format: "%.1fK%@", volume / 1000, suffix)
        } else {
            return String(format: "%.0f%@", volume, suffix)
        }
    }

    // MARK: - Weight Formatting

    /// Formats a weight value for display, removing unnecessary decimal places.
    ///
    /// - Whole numbers are shown as "225 lbs"
    /// - Fractional values are shown as "132.5 lbs"
    ///
    /// - Parameters:
    ///   - weight: The weight value
    ///   - unit: The unit label (defaults to "lbs")
    /// - Returns: A formatted string representation of the weight
    static func formatWeight(_ weight: Double, unit: String = "lbs") -> String {
        if weight == floor(weight) {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f %@", weight, unit)
    }

    // MARK: - Duration Formatting

    /// Formats a time interval as a human-readable duration string.
    ///
    /// Supports two output styles:
    /// - `.timer`: Digital clock format, e.g., "1:05:30" or "5:30" (for timers, countdowns)
    /// - `.natural`: Human-readable format, e.g., "1h 5m" or "45 min" (for summaries, cards)
    ///
    /// - Parameters:
    ///   - duration: The duration in seconds
    ///   - style: The output style (defaults to `.timer`)
    /// - Returns: A formatted string representation of the duration
    static func formatDuration(_ duration: TimeInterval, style: DurationStyle = .timer) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        switch style {
        case .timer:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }

        case .natural:
            if hours > 0 {
                if minutes == 0 {
                    return "\(hours)h"
                }
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes) min"
        }
    }

    /// Formats a duration given in minutes as a human-readable string.
    ///
    /// - "1h 30m" for durations >= 60 minutes
    /// - "45 min" for durations < 60 minutes
    ///
    /// - Parameter minutes: The duration in minutes
    /// - Returns: A formatted string representation
    static func formatDurationMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }

    /// Duration formatting style
    enum DurationStyle {
        /// Digital clock format: "1:05:30" or "5:30"
        case timer
        /// Human-readable format: "1h 5m" or "45 min"
        case natural
    }
}
