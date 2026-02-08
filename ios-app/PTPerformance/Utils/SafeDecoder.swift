//
//  SafeDecoder.swift
//  PTPerformance
//
//  Defensive decoding utilities to prevent crashes from unexpected database values.
//  Handles nulls, different date formats, missing fields, and type mismatches.
//

import Foundation

// MARK: - Safe Date Parsing

/// Utility for parsing dates from various formats that may come from the database
enum SafeDateParser {

    /// ISO8601 formatters for different precision levels
    private static let iso8601Full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// DateFormatter for PostgreSQL date-only format (YYYY-MM-DD)
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// DateFormatter for PostgreSQL timestamp format
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// DateFormatter for timestamp with timezone
    private static let timestampTZFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// DateFormatter for time-only format (HH:mm:ss)
    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Parse a date string using multiple format attempts
    /// - Parameter string: The date string to parse
    /// - Returns: Parsed Date or nil if all formats fail
    static func parse(_ string: String) -> Date? {
        // Try ISO8601 with fractional seconds first (most common from Supabase)
        if let date = iso8601Full.date(from: string) {
            return date
        }

        // Try standard ISO8601
        if let date = iso8601Standard.date(from: string) {
            return date
        }

        // Try PostgreSQL date-only format
        if let date = dateOnlyFormatter.date(from: string) {
            return date
        }

        // Try PostgreSQL timestamp format
        if let date = timestampFormatter.date(from: string) {
            return date
        }

        // Try timestamp with timezone
        if let date = timestampTZFormatter.date(from: string) {
            return date
        }

        return nil
    }

    /// Parse a time-only string (HH:mm:ss)
    /// - Parameter string: The time string to parse
    /// - Returns: Parsed Date or nil if parsing fails
    static func parseTime(_ string: String) -> Date? {
        return timeOnlyFormatter.date(from: string)
    }

    /// Parse date with fallback to current date
    /// - Parameter string: The date string to parse
    /// - Returns: Parsed Date or current date if parsing fails
    static func parseWithFallback(_ string: String) -> Date {
        return parse(string) ?? Date()
    }
}

// MARK: - KeyedDecodingContainer Extensions

extension KeyedDecodingContainer {

    // MARK: - Safe String Decoding

    /// Decode a string with fallback default
    func safeString(forKey key: Key, default defaultValue: String = "") -> String {
        return (try? decodeIfPresent(String.self, forKey: key)) ?? defaultValue
    }

    /// Decode an optional string safely
    func safeOptionalString(forKey key: Key) -> String? {
        return try? decodeIfPresent(String.self, forKey: key)
    }

    // MARK: - Safe Int Decoding

    /// Decode an Int with fallback, handling String representations
    func safeInt(forKey key: Key, default defaultValue: Int = 0) -> Int {
        // Try direct Int decode
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        // Try String to Int conversion
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }
        return defaultValue
    }

    /// Decode an optional Int safely, handling String representations
    func safeOptionalInt(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }

    // MARK: - Safe Double Decoding

    /// Decode a Double with fallback, handling String representations
    func safeDouble(forKey key: Key, default defaultValue: Double = 0.0) -> Double {
        // Try direct Double decode
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        // Try String to Double conversion (PostgreSQL numeric type)
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }
        // Try Int to Double conversion
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }
        return defaultValue
    }

    /// Decode an optional Double safely, handling String representations
    func safeOptionalDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }
        return nil
    }

    // MARK: - Safe Bool Decoding

    /// Decode a Bool with fallback, handling various representations
    func safeBool(forKey key: Key, default defaultValue: Bool = false) -> Bool {
        // Try direct Bool decode
        if let value = try? decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        // Try Int to Bool (0/1)
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        // Try String to Bool
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            let lowercased = stringValue.lowercased()
            return lowercased == "true" || lowercased == "1" || lowercased == "yes"
        }
        return defaultValue
    }

    // MARK: - Safe Date Decoding

    /// Decode a Date with multiple format attempts and fallback
    func safeDate(forKey key: Key, default defaultValue: Date = Date()) -> Date {
        // Try direct Date decode (uses decoder's dateDecodingStrategy)
        if let date = try? decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        // Try String to Date with multiple formats
        if let dateString = try? decodeIfPresent(String.self, forKey: key) {
            if let date = SafeDateParser.parse(dateString) {
                return date
            }
        }
        return defaultValue
    }

    /// Decode an optional Date safely with multiple format attempts
    func safeOptionalDate(forKey key: Key) -> Date? {
        // Try direct Date decode
        if let date = try? decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        // Try String to Date with multiple formats
        if let dateString = try? decodeIfPresent(String.self, forKey: key) {
            return SafeDateParser.parse(dateString)
        }
        return nil
    }

    /// Decode a time-only value (HH:mm:ss string from PostgreSQL TIME type)
    func safeTime(forKey key: Key, default defaultValue: Date = Date()) -> Date {
        if let timeString = try? decodeIfPresent(String.self, forKey: key),
           let date = SafeDateParser.parseTime(timeString) {
            return date
        }
        return defaultValue
    }

    // MARK: - Safe UUID Decoding

    /// Decode a UUID with fallback to new UUID
    func safeUUID(forKey key: Key) -> UUID {
        // Try direct UUID decode
        if let uuid = try? decode(UUID.self, forKey: key) {
            return uuid
        }
        // Try String to UUID conversion
        if let uuidString = try? decodeIfPresent(String.self, forKey: key),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        return UUID()
    }

    /// Decode an optional UUID safely
    func safeOptionalUUID(forKey key: Key) -> UUID? {
        if let uuid = try? decodeIfPresent(UUID.self, forKey: key) {
            return uuid
        }
        if let uuidString = try? decodeIfPresent(String.self, forKey: key),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        return nil
    }

    // MARK: - Safe Array Decoding

    /// Decode an array with fallback to empty array
    func safeArray<T: Decodable>(of type: T.Type, forKey key: Key) -> [T] {
        return (try? decodeIfPresent([T].self, forKey: key)) ?? []
    }

    // MARK: - Safe Enum Decoding

    /// Decode a RawRepresentable enum with fallback default
    func safeEnum<T: RawRepresentable & Decodable>(
        _ type: T.Type,
        forKey key: Key,
        default defaultValue: T
    ) -> T where T.RawValue: Decodable {
        return (try? decodeIfPresent(T.self, forKey: key)) ?? defaultValue
    }

    /// Decode an optional RawRepresentable enum safely
    func safeOptionalEnum<T: RawRepresentable & Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) -> T? where T.RawValue: Decodable {
        return try? decodeIfPresent(T.self, forKey: key)
    }
}

// MARK: - Decoder Extensions

extension Decoder {
    /// Convenience method to get a keyed container with error handling
    func safeContainer<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key>? {
        return try? container(keyedBy: type)
    }
}

// MARK: - Safe Decodable Protocol

/// Protocol for types that provide safe decoding with defaults
protocol SafeDecodable: Decodable {
    /// Create an instance with default values when decoding fails completely
    static var defaultInstance: Self { get }
}

extension SafeDecodable {
    /// Attempt to decode, returning default instance on failure
    static func safeDecode(from decoder: Decoder) -> Self {
        do {
            return try Self(from: decoder)
        } catch {
            #if DEBUG
            print("[SafeDecoder] Failed to decode \(Self.self), using default. Error: \(error)")
            #endif
            return Self.defaultInstance
        }
    }
}

// MARK: - JSON Decoder Configuration

extension JSONDecoder {
    /// Create a decoder configured for Supabase/PostgreSQL date formats
    static func supabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            // Try Date first (for when strategy already applied)
            if let date = try? container.decode(Date.self) {
                return date
            }

            // Try String parsing
            let dateString = try container.decode(String.self)
            if let date = SafeDateParser.parse(dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }
        return decoder
    }
}
