//
//  BackgroundDecoder.swift
//  PTPerformance
//
//  ACP-945: Main Thread Optimization — Off-main-thread JSON decoding.
//  Provides an actor-isolated decoder that ensures all JSON parsing happens
//  on a background thread, keeping the main thread free for rendering.
//

import Foundation

/// Actor that performs JSON decoding on a background thread.
///
/// Supabase responses can contain large JSON payloads (exercise libraries,
/// workout histories, meal plans). Decoding these on the main thread blocks
/// rendering and causes frame drops. This actor wraps `JSONDecoder` and
/// guarantees decoding runs off the main thread via `Task.detached`.
///
/// Usage:
/// ```swift
/// let workouts = try await BackgroundDecoder.shared.decode([Workout].self, from: data)
/// ```
actor BackgroundDecoder {

    // MARK: - Singleton

    static let shared = BackgroundDecoder()

    // MARK: - Decoders

    /// Default decoder configured for ISO8601 dates (most common Supabase format).
    private let iso8601Decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = PTSupabaseClient.flexibleDecoder.dateDecodingStrategy
        return decoder
    }()

    /// Pre-cached date formatters for the flexible decoder (allocated once)
    private static let isoFullFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoStandardFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// Flexible decoder that handles multiple Supabase/PostgreSQL date formats.
    /// Mirrors the strategy used in `PTSupabaseClient.flexibleDecoder`.
    private let flexibleDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = BackgroundDecoder.isoFullFormatter.date(from: dateString) {
                return date
            }
            if let date = BackgroundDecoder.isoStandardFormatter.date(from: dateString) {
                return date
            }
            if let date = BackgroundDecoder.dateOnlyFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "BackgroundDecoder: Cannot decode date from '\(dateString)'"
            )
        }
        return decoder
    }()

    // MARK: - Init

    private init() {}

    // MARK: - Decoding

    /// Decode a single `Decodable` value from JSON data on a background thread.
    ///
    /// - Parameters:
    ///   - type: The type to decode into.
    ///   - data: Raw JSON data.
    ///   - useFlexibleDates: When `true`, uses the flexible date decoder that handles
    ///     multiple PostgreSQL date formats. Defaults to `false` (ISO8601 only).
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        useFlexibleDates: Bool = false
    ) async throws -> T {
        let decoder = useFlexibleDates ? flexibleDecoder : iso8601Decoder

        // Detach to guarantee we are NOT on the main thread or any actor.
        return try await Task.detached(priority: .userInitiated) {
            try decoder.decode(type, from: data)
        }.value
    }

    /// Convenience: decode a JSON array on a background thread.
    ///
    /// - Parameters:
    ///   - type: The element type (e.g. `Workout.self`).
    ///   - data: Raw JSON data containing a JSON array.
    ///   - useFlexibleDates: When `true`, uses the flexible date decoder.
    /// - Returns: Array of decoded values.
    func decodeArray<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        useFlexibleDates: Bool = false
    ) async throws -> [T] {
        let decoder = useFlexibleDates ? flexibleDecoder : iso8601Decoder

        return try await Task.detached(priority: .userInitiated) {
            try decoder.decode([T].self, from: data)
        }.value
    }
}
