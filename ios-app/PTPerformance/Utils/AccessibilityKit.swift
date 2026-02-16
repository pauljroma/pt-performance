//
//  AccessibilityKit.swift
//  PTPerformance
//
//  ACP-925: VoiceOver Audit & Fix
//  Centralized accessibility utilities for consistent VoiceOver support
//  across the entire PT Performance app.
//

import Foundation

// MARK: - AccessibilityKit Namespace

/// Centralized accessibility utilities namespace.
///
/// `AccessibilityKit` provides pre-defined label builders, chart accessibility helpers,
/// and formatting utilities so that every screen announces content in a clear,
/// consistent way for VoiceOver users.
enum AccessibilityKit {}

// MARK: - Trend Direction

/// Describes the direction of a metric trend for VoiceOver announcements.
enum TrendDirection: String {
    case up
    case down
    case stable

    /// Human-readable description used in accessibility labels.
    var displayString: String {
        switch self {
        case .up: return "trending up"
        case .down: return "trending down"
        case .stable: return "stable"
        }
    }
}

// MARK: - A11yLabel

extension AccessibilityKit {

    /// Pre-defined accessibility label builders for common UI patterns.
    ///
    /// Use these helpers instead of hand-rolling label strings so that every
    /// screen follows the same phrasing conventions.
    struct A11yLabel {

        // MARK: Loading

        /// Returns a loading label with context, e.g. "Loading workouts".
        static func loading(_ context: String) -> String {
            "Loading \(context)"
        }

        // MARK: Button

        /// Returns a button label, e.g. "Save button".
        static func button(_ action: String) -> String {
            "\(action) button"
        }

        // MARK: Count

        /// Returns a count label with proper pluralization.
        ///
        /// Examples:
        /// - `count(1, of: "exercise")` -> "1 exercise"
        /// - `count(5, of: "exercise")` -> "5 exercises"
        /// - `count(0, of: "set")` -> "0 sets"
        static func count(_ count: Int, of item: String) -> String {
            if count == 1 {
                return "\(count) \(item)"
            }
            return "\(count) \(pluralize(item))"
        }

        // MARK: Percentage

        /// Returns a percentage label read naturally by VoiceOver, e.g. "85 percent".
        static func percentage(_ value: Double) -> String {
            let rounded = Int(value.rounded())
            return "\(rounded) percent"
        }

        // MARK: Duration

        /// Returns a human-readable duration label, e.g. "1 hour 30 minutes".
        ///
        /// Uses `DateComponentsFormatter` for natural phrasing. Falls back to
        /// a seconds-based string for very short or zero durations.
        static func duration(_ seconds: TimeInterval) -> String {
            guard seconds > 0 else { return "0 seconds" }

            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.maximumUnitCount = 2 // keep announcements concise

            return formatter.string(from: seconds) ?? "\(Int(seconds)) seconds"
        }

        // MARK: Score

        /// Returns a score label with context, e.g. "Readiness score: 85 out of 100".
        static func score(_ value: Int, outOf max: Int, context: String) -> String {
            "\(context) score: \(value) out of \(max)"
        }

        // MARK: Trend

        /// Returns a trend label, e.g. "Heart rate variability trending up".
        static func trend(_ direction: TrendDirection, metric: String) -> String {
            "\(metric) \(direction.displayString)"
        }

        // MARK: - Pluralization Helper

        /// Naive English pluralization covering common PT/fitness nouns.
        ///
        /// Handles:
        /// - Words ending in "s", "sh", "ch", "x", "z" -> append "es"
        /// - Words ending in consonant + "y" -> replace "y" with "ies"
        /// - Everything else -> append "s"
        private static func pluralize(_ word: String) -> String {
            let lowered = word.lowercased()

            if lowered.hasSuffix("s") || lowered.hasSuffix("sh") ||
                lowered.hasSuffix("ch") || lowered.hasSuffix("x") ||
                lowered.hasSuffix("z") {
                return word + "es"
            }

            if lowered.hasSuffix("y") {
                let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
                let secondToLast = lowered.dropLast().last
                if let char = secondToLast, !vowels.contains(char) {
                    return String(word.dropLast()) + "ies"
                }
            }

            return word + "s"
        }
    }
}

// MARK: - ChartAccessibility

extension AccessibilityKit {

    /// Helpers for making chart views accessible to VoiceOver users.
    ///
    /// Charts are inherently visual. These helpers produce text summaries that
    /// convey the same information the chart communicates visually: overall trend,
    /// value range, data density, and individual data points.
    struct ChartAccessibility {

        /// Returns a full chart summary for VoiceOver.
        ///
        /// Example output:
        /// "Pain trend chart. 14 data points. Trending down. Range: 3 to 8. Latest: 4."
        ///
        /// - Parameters:
        ///   - title: The chart title, e.g. "Pain trend".
        ///   - dataPoints: Number of data points in the chart.
        ///   - trend: Overall trend direction of the data.
        ///   - min: Formatted minimum value.
        ///   - max: Formatted maximum value.
        ///   - latest: Formatted most recent value.
        /// - Returns: A single accessibility label string.
        static func summary(
            title: String,
            dataPoints: Int,
            trend: TrendDirection,
            min: String,
            max: String,
            latest: String
        ) -> String {
            let pointsLabel = dataPoints == 1 ? "1 data point" : "\(dataPoints) data points"
            return "\(title) chart. \(pointsLabel). \(trend.displayString.capitalized). Range: \(min) to \(max). Latest: \(latest)."
        }

        /// Returns a single data point label for VoiceOver navigation within a chart.
        ///
        /// Example output:
        /// "Point 3 of 14: February 10, value 5"
        ///
        /// - Parameters:
        ///   - index: 1-based index of this data point.
        ///   - total: Total number of data points.
        ///   - label: Human-readable label for this point (e.g. a date).
        ///   - value: Formatted value of this data point.
        /// - Returns: A single accessibility label string.
        static func dataPoint(
            index: Int,
            of total: Int,
            label: String,
            value: String
        ) -> String {
            "Point \(index) of \(total): \(label), value \(value)"
        }
    }
}
