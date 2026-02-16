//
//  CrashPreventionService.swift
//  PTPerformance
//
//  ACP-956: Crash-Free Rate Optimization
//  Comprehensive crash prevention layer with safe operations,
//  global exception handling, and signal handlers.
//

import Foundation
import os.log
#if canImport(Sentry)
import Sentry
#endif

/// Comprehensive crash prevention service that provides safe operation wrappers
/// and installs last-resort crash handlers for maximizing crash-free session rate.
///
/// Install early in the app lifecycle via `CrashPreventionService.shared.install()`.
/// On next launch, call `SentryConfig.reportPreviousCrash()` to forward any
/// captured crash info to Sentry.
final class CrashPreventionService {

    // MARK: - Singleton

    static let shared = CrashPreventionService()

    // MARK: - Constants

    /// UserDefaults keys for persisting last-resort crash info
    private enum Keys {
        static let crashInfoName = "com.ptperformance.crashPrevention.crashName"
        static let crashInfoReason = "com.ptperformance.crashPrevention.crashReason"
        static let crashInfoCallStack = "com.ptperformance.crashPrevention.crashCallStack"
        static let crashInfoTimestamp = "com.ptperformance.crashPrevention.crashTimestamp"
        static let crashInfoSignal = "com.ptperformance.crashPrevention.crashSignal"
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "CrashPrevention")
    private var isInstalled = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Installation

    /// Install global crash handlers. Call once during app startup, before Sentry initializes
    /// its own handlers so that our handler runs first (handlers are LIFO).
    func install() {
        guard !isInstalled else {
            logger.info("CrashPreventionService already installed, skipping")
            return
        }
        isInstalled = true

        // Install uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashPreventionService.handleUncaughtException(exception)
        }

        // Install signal handlers for common fatal signals
        signal(SIGSEGV) { sig in CrashPreventionService.handleSignal(sig) }
        signal(SIGABRT) { sig in CrashPreventionService.handleSignal(sig) }
        signal(SIGBUS) { sig in CrashPreventionService.handleSignal(sig) }
        signal(SIGFPE) { sig in CrashPreventionService.handleSignal(sig) }

        logger.info("CrashPreventionService installed: exception and signal handlers active")
    }

    // MARK: - Safe Operations

    /// Safely divide two doubles, returning a fallback if the divisor is zero or near-zero.
    ///
    /// - Parameters:
    ///   - a: The dividend
    ///   - b: The divisor
    ///   - fallback: Value to return when division is unsafe (default 0)
    /// - Returns: The result of a/b, or `fallback` if b is zero/near-zero
    func safeDivide(_ a: Double, by b: Double, fallback: Double = 0) -> Double {
        guard abs(b) > .ulpOfOne else {
            ErrorLogger.shared.logDefensiveFallback(
                context: "safeDivide",
                expected: "non-zero divisor",
                actual: String(b),
                fallback: String(fallback)
            )
            return fallback
        }
        return a / b
    }

    /// Safely access an array element at the given index.
    ///
    /// - Parameters:
    ///   - array: The source array
    ///   - index: The desired index
    /// - Returns: The element if the index is within bounds, otherwise nil
    func safeIndex<T>(_ array: [T], at index: Int) -> T? {
        guard index >= 0 && index < array.count else {
            ErrorLogger.shared.logBoundsCheckPrevention(
                context: "CrashPreventionService.safeIndex",
                index: index,
                arrayCount: array.count
            )
            return nil
        }
        return array[index]
    }

    /// Safely unwrap an optional, logging and returning a fallback when nil.
    ///
    /// - Parameters:
    ///   - optional: The optional to unwrap
    ///   - context: A human-readable description of where this occurs
    ///   - fallback: The value to return if the optional is nil
    /// - Returns: The unwrapped value, or `fallback`
    func safeUnwrap<T>(_ optional: T?, context: String, fallback: T) -> T {
        if let value = optional {
            return value
        }
        ErrorLogger.shared.logUnexpectedNil(context: context, variable: String(describing: T.self))
        ErrorLogger.shared.logDefensiveFallback(
            context: context,
            expected: String(describing: T.self),
            actual: "nil",
            fallback: String(describing: fallback)
        )
        return fallback
    }

    /// Safely cast a value to the specified type, logging on failure.
    ///
    /// - Parameters:
    ///   - value: The value to cast
    ///   - type: The target type
    ///   - context: A human-readable description of where this occurs
    /// - Returns: The casted value, or nil if the cast fails
    func safeCast<T>(_ value: Any, to type: T.Type, context: String) -> T? {
        if let casted = value as? T {
            return casted
        }
        ErrorLogger.shared.logDefensiveFallback(
            context: context,
            expected: String(describing: T.self),
            actual: String(describing: Swift.type(of: value)),
            fallback: "nil"
        )
        logger.warning("safeCast failed in \(context): expected \(String(describing: T.self)), got \(String(describing: Swift.type(of: value)))")
        return nil
    }

    /// Safely decode JSON data into the specified Decodable type.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode into
    ///   - data: The raw JSON data
    ///   - context: A human-readable description for logging
    /// - Returns: The decoded value, or nil if decoding fails
    func safeJSONDecode<T: Decodable>(_ type: T.Type, from data: Data, context: String) -> T? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            ErrorLogger.shared.logError(
                error,
                context: "safeJSONDecode failed for \(context)",
                metadata: [
                    "type": String(describing: type),
                    "dataSize": data.count,
                    "preview": String(data: data.prefix(200), encoding: .utf8) ?? "non-UTF8 data"
                ]
            )
            return nil
        }
    }

    // MARK: - Crash Info Retrieval

    /// Check whether crash info was persisted from a previous session.
    /// Returns nil if no crash info is stored.
    static func retrievePreviousCrashInfo() -> [String: String]? {
        let defaults = UserDefaults.standard
        guard let timestamp = defaults.string(forKey: Keys.crashInfoTimestamp) else {
            return nil
        }

        var info: [String: String] = ["timestamp": timestamp]

        if let name = defaults.string(forKey: Keys.crashInfoName) {
            info["name"] = name
        }
        if let reason = defaults.string(forKey: Keys.crashInfoReason) {
            info["reason"] = reason
        }
        if let callStack = defaults.string(forKey: Keys.crashInfoCallStack) {
            info["callStack"] = callStack
        }
        if let signalName = defaults.string(forKey: Keys.crashInfoSignal) {
            info["signal"] = signalName
        }

        return info
    }

    /// Clear persisted crash info after it has been reported.
    static func clearPreviousCrashInfo() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.crashInfoName)
        defaults.removeObject(forKey: Keys.crashInfoReason)
        defaults.removeObject(forKey: Keys.crashInfoCallStack)
        defaults.removeObject(forKey: Keys.crashInfoTimestamp)
        defaults.removeObject(forKey: Keys.crashInfoSignal)
    }

    // MARK: - Exception & Signal Handlers (Private)

    /// Last-resort uncaught exception handler.
    /// Persists crash info to UserDefaults so it can be sent to Sentry on next launch.
    private static func handleUncaughtException(_ exception: NSException) {
        let defaults = UserDefaults.standard
        defaults.set(exception.name.rawValue, forKey: Keys.crashInfoName)
        defaults.set(exception.reason ?? "unknown", forKey: Keys.crashInfoReason)
        defaults.set(exception.callStackSymbols.joined(separator: "\n"), forKey: Keys.crashInfoCallStack)
        defaults.set("\(Date().timeIntervalSince1970)", forKey: Keys.crashInfoTimestamp)
    }

    /// Last-resort signal handler.
    /// Persists signal info and the current call stack to UserDefaults.
    ///
    /// **Async-signal-safety warning**: Signal handlers should only call async-signal-safe
    /// POSIX functions. This handler uses `UserDefaults`, `Thread.callStackSymbols`, and
    /// Swift string interpolation, none of which are async-signal-safe. This is a known
    /// limitation — the handler is best-effort and may not succeed in all crash scenarios
    /// (e.g., corrupted heap). Sentry's own signal handler is the primary crash reporter;
    /// this serves as a supplementary last-resort capture.
    private static func handleSignal(_ signal: Int32) {
        let signalName: String
        switch signal {
        case SIGSEGV: signalName = "SIGSEGV"
        case SIGABRT: signalName = "SIGABRT"
        case SIGBUS:  signalName = "SIGBUS"
        case SIGFPE:  signalName = "SIGFPE"
        default:      signalName = "SIGNAL(\(signal))"
        }

        let defaults = UserDefaults.standard
        defaults.set(signalName, forKey: Keys.crashInfoSignal)
        defaults.set(signalName, forKey: Keys.crashInfoName)
        defaults.set("Fatal signal received: \(signalName)", forKey: Keys.crashInfoReason)
        // Best-effort: Thread.callStackSymbols is not async-signal-safe and may
        // fail or deadlock in some crash scenarios (e.g., corrupted heap/stack).
        defaults.set(Thread.callStackSymbols.joined(separator: "\n"), forKey: Keys.crashInfoCallStack)
        defaults.set("\(Date().timeIntervalSince1970)", forKey: Keys.crashInfoTimestamp)

        // Re-raise the signal with the default handler so the OS terminates normally
        Darwin.signal(signal, SIG_DFL)
        Darwin.raise(signal)
    }
}
