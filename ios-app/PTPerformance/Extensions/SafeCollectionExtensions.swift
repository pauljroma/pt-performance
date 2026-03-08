//
//  SafeCollectionExtensions.swift
//  PTPerformance
//
//  ACP-956: Crash-Free Rate Optimization
//  Swift extensions for crash-safe collection and optional access patterns.
//

import Foundation

// MARK: - Safe Dictionary Access

extension Dictionary {
    /// Retrieve a value for the given key, cast to the expected type, with a default fallback.
    ///
    /// - Parameters:
    ///   - key: The dictionary key
    ///   - type: The expected type of the value
    ///   - defaultValue: The value to return if the key is missing or the cast fails
    /// - Returns: The value cast to `T`, or `defaultValue`
    func value<T>(forKey key: Key, as type: T.Type, default defaultValue: T) -> T {
        guard let raw = self[key] else {
            return defaultValue
        }
        guard let typed = raw as? T else {
            ErrorLogger.shared.logDefensiveFallback(
                context: "Dictionary.value(forKey:as:default:)",
                expected: String(describing: T.self),
                actual: String(describing: Swift.type(of: raw)),
                fallback: String(describing: defaultValue)
            )
            return defaultValue
        }
        return typed
    }
}

// MARK: - Safe Dictionary Grouping

extension Array {
    /// Safe alternative to Dictionary(grouping:by:) that avoids a Swift stdlib crash
    /// on iOS 26 beta where the inlined specialization of Dictionary.init(grouping:by:)
    /// traps (brk #1) with certain value witnesses (e.g. Date).
    func safeGrouped<Key: Hashable>(by keyForValue: (Element) -> Key) -> [Key: [Element]] {
        var result = [Key: [Element]]()
        for element in self {
            let key = keyForValue(element)
            result[key, default: []].append(element)
        }
        return result
    }
}

// MARK: - Safe Optional Unwrapping

extension Optional {
    /// Unwrap the optional, or log a warning and return nil.
    ///
    /// Use this at call sites where nil is unexpected and should be tracked
    /// for crash-free rate monitoring.
    ///
    /// - Parameters:
    ///   - message: A description of what was expected to be non-nil
    ///   - file: The source file (auto-captured)
    ///   - line: The source line (auto-captured)
    /// - Returns: The wrapped value, or nil after logging
    func unwrapOrLog(_ message: String, file: String = #file, line: Int = #line) -> Wrapped? {
        if case .none = self {
            let fileName = (file as NSString).lastPathComponent
            let context = "\(fileName):\(line)"
            ErrorLogger.shared.logUnexpectedNil(context: context, variable: message)
            return nil
        }
        return self
    }
}
