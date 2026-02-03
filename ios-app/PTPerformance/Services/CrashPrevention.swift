//
//  CrashPrevention.swift
//  PTPerformance
//
//  ACP-956: Crash-Free Rate Optimization
//  Defensive coding utilities to prevent common crash scenarios
//

import Foundation

// MARK: - Safe Array Access

extension Collection {
    /// Safely access an element at the specified index.
    /// Returns nil if the index is out of bounds instead of crashing.
    ///
    /// Example:
    /// ```swift
    /// let array = [1, 2, 3]
    /// let element = array[safe: 5] // Returns nil instead of crashing
    /// ```
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    /// Safely remove an element at the specified index.
    /// Does nothing if the index is out of bounds.
    ///
    /// - Parameter index: The index of the element to remove
    /// - Returns: The removed element, or nil if index was out of bounds
    @discardableResult
    mutating func safeRemove(at index: Int) -> Element? {
        guard indices.contains(index) else {
            ErrorLogger.shared.logWarning("Attempted to remove element at invalid index \(index) from array of count \(count)")
            return nil
        }
        return remove(at: index)
    }

    /// Safely access the first element.
    /// Returns nil if the array is empty.
    var safeFirst: Element? {
        return isEmpty ? nil : first
    }

    /// Safely access the last element.
    /// Returns nil if the array is empty.
    var safeLast: Element? {
        return isEmpty ? nil : last
    }
}

// MARK: - Safe String Parsing

extension String {
    /// Safely parse an integer from the string.
    /// Returns nil if parsing fails instead of crashing.
    var safeInt: Int? {
        return Int(self)
    }

    /// Safely parse a double from the string.
    /// Returns nil if parsing fails instead of crashing.
    var safeDouble: Double? {
        return Double(self)
    }

    /// Safely parse a UUID from the string.
    /// Returns nil if parsing fails instead of crashing.
    var safeUUID: UUID? {
        return UUID(uuidString: self)
    }
}

// MARK: - Safe Date Parsing

extension ISO8601DateFormatter {
    /// Safely parse a date from a string.
    /// Returns nil if parsing fails instead of crashing.
    func safeDate(from string: String) -> Date? {
        return date(from: string)
    }
}

extension DateFormatter {
    /// Safely parse a date from a string.
    /// Returns nil if parsing fails instead of crashing.
    func safeDate(from string: String) -> Date? {
        return date(from: string)
    }
}

/// Standard date formatters with safe parsing
enum SafeDateParsing {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Parse an ISO8601 date string safely, trying multiple formats
    /// - Parameter string: The date string to parse
    /// - Returns: The parsed date, or nil if parsing fails
    static func parseISO8601(_ string: String) -> Date? {
        // Try with fractional seconds first
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        // Try without fractional seconds
        if let date = iso8601FormatterNoFractional.date(from: string) {
            return date
        }
        // Try date-only format
        if let date = dateOnlyFormatter.date(from: string) {
            return date
        }

        ErrorLogger.shared.logWarning("Failed to parse date string: \(string)")
        return nil
    }

    /// Parse a date-only string (yyyy-MM-dd)
    static func parseDateOnly(_ string: String) -> Date? {
        return dateOnlyFormatter.date(from: string)
    }
}

// MARK: - Safe JSON Decoding

extension JSONDecoder {
    /// Safely decode a type from data with error logging.
    /// Returns nil if decoding fails instead of throwing.
    ///
    /// - Parameters:
    ///   - type: The type to decode
    ///   - data: The data to decode from
    ///   - context: Optional context for error logging
    /// - Returns: The decoded value, or nil if decoding fails
    func safeDecode<T: Decodable>(_ type: T.Type, from data: Data, context: String? = nil) -> T? {
        do {
            return try decode(type, from: data)
        } catch {
            let contextInfo = context ?? String(describing: type)
            ErrorLogger.shared.logError(
                error,
                context: "JSON decoding failed for \(contextInfo)",
                metadata: [
                    "type": String(describing: type),
                    "dataSize": data.count,
                    "preview": String(data: data.prefix(200), encoding: .utf8) ?? "unable to preview"
                ]
            )
            return nil
        }
    }

    /// Decode with a fallback value if decoding fails
    func decodeWithFallback<T: Decodable>(_ type: T.Type, from data: Data, fallback: T, context: String? = nil) -> T {
        return safeDecode(type, from: data, context: context) ?? fallback
    }
}

// MARK: - Safe Dictionary Access

extension Dictionary {
    /// Safely access a value and cast to expected type.
    /// Returns nil if key doesn't exist or value cannot be cast.
    func safeValue<T>(for key: Key, as type: T.Type) -> T? {
        return self[key] as? T
    }
}

// MARK: - Safe Optional Unwrapping with Logging

/// Unwrap an optional or log a warning and return a default value
/// - Parameters:
///   - optional: The optional value to unwrap
///   - default: The default value to return if optional is nil
///   - context: Context for the warning log
/// - Returns: The unwrapped value or the default
func unwrapOrDefault<T>(_ optional: T?, default defaultValue: T, context: String) -> T {
    if let value = optional {
        return value
    } else {
        ErrorLogger.shared.logWarning("Optional value was nil, using default. Context: \(context)")
        return defaultValue
    }
}

/// Unwrap an optional or log an error and return nil
/// Use this when nil is a valid but unexpected case that should be tracked
/// - Parameters:
///   - optional: The optional value to unwrap
///   - context: Context for the error log
/// - Returns: The unwrapped value or nil
func unwrapOrLog<T>(_ optional: T?, context: String) -> T? {
    if optional == nil {
        ErrorLogger.shared.logWarning("Unexpected nil value. Context: \(context)")
    }
    return optional
}

// MARK: - Safe Number Operations

extension Int {
    /// Safely divide by another integer, returning nil if divisor is zero
    func safeDivide(by divisor: Int) -> Int? {
        guard divisor != 0 else {
            ErrorLogger.shared.logWarning("Attempted division by zero")
            return nil
        }
        return self / divisor
    }
}

extension Double {
    /// Safely divide by another double, returning nil if divisor is zero or near-zero
    func safeDivide(by divisor: Double, epsilon: Double = 0.0000001) -> Double? {
        guard abs(divisor) > epsilon else {
            ErrorLogger.shared.logWarning("Attempted division by zero or near-zero value")
            return nil
        }
        return self / divisor
    }

    /// Clamp value to a range to prevent overflow/underflow
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Result Type Helpers

extension Result {
    /// Get the success value or nil
    var successValue: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    /// Get the failure error or nil
    var failureError: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
