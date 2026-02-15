//
//  FormatterCache.swift
//  PTPerformance
//
//  ACP-945: Main Thread Optimization — Centralized formatter cache.
//  Foundation formatters (DateFormatter, NumberFormatter, etc.) are expensive
//  to allocate. This file provides pre-configured static instances that are
//  created once and reused throughout the app lifetime.
//
//  Thread safety: All instances are `nonisolated(unsafe) static let` constants.
//  They are safe because they are fully configured before any thread can access
//  them (set-once-read-many pattern). No mutations occur after initialization.
//

import Foundation

/// Centralized cache of pre-configured Foundation formatters.
///
/// Allocating a `DateFormatter` or `NumberFormatter` on every cell render is a
/// common source of main-thread overhead. This enum provides shared, read-only
/// instances for the most common formatting patterns in the app.
///
/// Usage:
/// ```swift
/// let label = FormatterCache.shortDate.string(from: workout.date)
/// let price = FormatterCache.currency.string(from: NSNumber(value: 9.99)) ?? "$9.99"
/// ```
enum FormatterCache {

    // MARK: - Date Formatters

    /// Short date style — e.g. "2/15/26" (locale-dependent)
    nonisolated(unsafe) static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    /// Medium date style — e.g. "Feb 15, 2026" (locale-dependent)
    nonisolated(unsafe) static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Full date style — e.g. "Sunday, February 15, 2026" (locale-dependent)
    nonisolated(unsafe) static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    /// Time only — e.g. "3:30 PM" (locale-dependent)
    nonisolated(unsafe) static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// ISO8601 date-only for API/database interactions — "2026-02-15"
    nonisolated(unsafe) static let iso8601Date: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// Timestamp for logging — "14:30:05.123"
    nonisolated(unsafe) static let timestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    // MARK: - Number Formatters

    /// Currency formatter — e.g. "$9.99" (locale-dependent)
    nonisolated(unsafe) static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()

    /// Percentage formatter — e.g. "85%" (multiplies by 100)
    nonisolated(unsafe) static let percentage: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 0
        return f
    }()

    /// Decimal formatter with one fraction digit — e.g. "3.5"
    nonisolated(unsafe) static let decimal1: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    /// Whole-number formatter with grouping — e.g. "1,234"
    nonisolated(unsafe) static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    // MARK: - Byte Count Formatter

    /// File size formatter — e.g. "4.2 MB"
    nonisolated(unsafe) static let fileSize: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB]
        f.countStyle = .file
        return f
    }()

    // MARK: - Date Components Formatter

    /// Duration formatter — e.g. "1h 30m" or "45m"
    nonisolated(unsafe) static let duration: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        return f
    }()

    /// Countdown-style duration — e.g. "1:30:00" or "5:00"
    nonisolated(unsafe) static let countdown: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .positional
        f.zeroFormattingBehavior = .pad
        return f
    }()

    // MARK: - Measurement Formatter

    /// Measurement formatter for body weight / loads — e.g. "185 lb"
    nonisolated(unsafe) static let measurement: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = .providedUnit
        f.numberFormatter.maximumFractionDigits = 1
        return f
    }()
}
