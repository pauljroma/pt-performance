//
//  DebugLogger.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Debug logging service for development
//

import Foundation
import os.log

/// Debug logger for development and diagnostic logging
/// Separate from ErrorLogger to keep production error tracking clean
class DebugLogger {

    // MARK: - Singleton

    static let shared = DebugLogger()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "Debug")
    private let isEnabled: Bool

    /// Minimum log level — messages below this threshold are silently dropped.
    /// Release builds only show warnings and errors to reduce noise.
    #if DEBUG
    private let minimumLevel: LogLevel = .diagnostic
    #else
    private let minimumLevel: LogLevel = .warning
    #endif

    // MARK: - Log Levels

    enum LogLevel: String, Comparable {
        case diagnostic = "🔍"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"

        private var severity: Int {
            switch self {
            case .diagnostic: return 0
            case .info: return 1
            case .success: return 2
            case .warning: return 3
            case .error: return 4
            }
        }

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.severity < rhs.severity
        }
    }

    // MARK: - Initialization

    private init() {
        // CRITICAL: Always enable logging for TestFlight builds
        // Users need to see errors in production via LoggingService
        self.isEnabled = true
    }

    // MARK: - Logging Methods

    /// Log a message with level
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled, level >= minimumLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.rawValue) [\(fileName):\(line)] \(message)"

        // Log to os.log for system console
        switch level {
        case .diagnostic, .info:
            logger.info("\(logMessage)")
        case .success:
            logger.notice("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }

        // CRITICAL: Also log to LoggingService for UI display
        let uiLevel: LoggingService.LogLevel
        switch level {
        case .diagnostic, .info:
            uiLevel = .diagnostic
        case .success:
            uiLevel = .success
        case .warning:
            uiLevel = .warning
        case .error:
            uiLevel = .error
        }
        LoggingService.shared.log(message, level: uiLevel)
    }

    /// Log a diagnostic message (verbose details)
    func diagnostic(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .diagnostic, file: file, function: function, line: line)
    }

    /// Log an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Log an info message with tag
    func info(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("[\(tag)] \(message)", level: .info, file: file, function: function, line: line)
    }

    /// Log a success message
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, file: file, function: function, line: line)
    }

    /// Log a success message with tag
    func success(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("[\(tag)] \(message)", level: .success, file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Log a warning message with tag
    func warning(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("[\(tag)] \(message)", level: .warning, file: file, function: function, line: line)
    }

    /// Log an error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    /// Log an error message with tag
    func error(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("[\(tag)] \(message)", level: .error, file: file, function: function, line: line)
    }

    /// Log a network request
    ///
    /// ACP-1055: All URLs are sanitized to strip sensitive query parameters, tokens, and PII.
    /// Request bodies are redacted in release builds and sanitized in debug builds.
    func logRequest(url: URL, method: String = "GET", body: Data? = nil) {
        guard isEnabled, minimumLevel <= .info else { return }

        let sanitizer = NetworkSanitizer.shared
        let sanitizedURL = sanitizer.sanitizeURL(url)
        var message = "🌐 HTTP \(method) \(sanitizedURL)"

        #if DEBUG
        if let sanitizedBody = sanitizer.sanitizeBody(body) {
            message += "\n   Body: \(sanitizedBody)"
        }
        #endif

        logger.info("\(message)")
    }

    /// Log a network response
    ///
    /// ACP-1055: Response URLs are sanitized. Response bodies are never logged in release builds.
    /// In debug builds, response previews are sanitized to redact PII and tokens.
    func logResponse(url: URL, statusCode: Int, data: Data? = nil) {
        guard isEnabled, minimumLevel <= .info else { return }

        let sanitizer = NetworkSanitizer.shared
        let sanitizedURL = sanitizer.sanitizeURL(url)
        let statusEmoji = statusCode < 300 ? "✅" : "❌"
        var message = "\(statusEmoji) HTTP \(statusCode) \(sanitizedURL)"

        #if DEBUG
        if let sanitizedBody = sanitizer.sanitizeBody(data) {
            let preview = String(sanitizedBody.prefix(200))
            message += "\n   Response: \(preview)"
            if sanitizedBody.count > 200 {
                message += "... (truncated)"
            }
        }
        #endif

        logger.info("\(message)")
    }

    /// Log function entry (for tracing execution flow)
    func entering(_ function: String = #function, file: String = #file, line: Int = #line) {
        guard isEnabled, minimumLevel <= .diagnostic else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("→ Entering \(fileName):\(function)")
    }

    /// Log function exit (for tracing execution flow)
    func exiting(_ function: String = #function, file: String = #file, line: Int = #line) {
        guard isEnabled, minimumLevel <= .diagnostic else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("← Exiting \(fileName):\(function)")
    }

    /// Log a database query
    func logQuery(table: String, query: String, params: [String: Any] = [:]) {
        guard isEnabled, minimumLevel <= .info else { return }

        var message = "🗄️ \(table): \(query)"

        if !params.isEmpty {
            let paramStrings = params.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += "\n   Params: \(paramStrings)"
        }

        logger.info("\(message)")
    }

    /// Log a date conversion for timezone debugging
    func logDateConversion(original: Date, formatted: String, formatter: String) {
        guard isEnabled, minimumLevel <= .diagnostic else { return }

        let message = "📅 Date Conversion: \(original) → \(formatted) (using \(formatter))"
        logger.info("\(message)")
    }
}
