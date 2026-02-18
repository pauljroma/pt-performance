//
//  SafeJSON.swift
//  PTPerformance
//
//  Safe JSONDecoder/JSONEncoder that prevent EXC_BREAKPOINT (brk 1) crashes
//  from corrupted Date values in UserDefaults or disk-persisted data.
//
//  Swift's auto-synthesized Codable for Date uses timeIntervalSinceReferenceDate
//  (a Double). If the stored Double is NaN, Inf, or otherwise corrupted,
//  the default encoder/decoder can trigger a runtime trap that bypasses try?.
//  These safe variants use custom date strategies that validate values before use.
//

import Foundation

enum SafeJSON {

    /// JSONDecoder that won't trap on corrupted Date values.
    /// Use for all UserDefaults / disk persistence decode paths.
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            // Try Double (timeIntervalSinceReferenceDate) — the default encoding
            if let ti = try? container.decode(Double.self), ti.isFinite {
                return Date(timeIntervalSinceReferenceDate: ti)
            }
            // Try ISO 8601 string as fallback
            if let str = try? container.decode(String.self), !str.isEmpty {
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = fmt.date(from: str) { return date }
                fmt.formatOptions = [.withInternetDateTime]
                if let date = fmt.date(from: str) { return date }
            }
            // Return current date as safe fallback
            return Date()
        }
        return decoder
    }

    /// JSONEncoder that won't trap on NaN/Inf Date values.
    /// Use for all UserDefaults / disk persistence encode paths.
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let ti = date.timeIntervalSinceReferenceDate
            try container.encode(ti.isFinite ? ti : 0)
        }
        return encoder
    }
}
