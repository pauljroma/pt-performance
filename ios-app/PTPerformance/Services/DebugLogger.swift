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

    private let logger = Logger(subsystem: "com.ptperformance.app", category: "Debug")
    private let isEnabled: Bool

    // MARK: - Log Levels

    enum LogLevel: String {
        case diagnostic = "🔍"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
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
        guard isEnabled else { return }

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
    func logRequest(url: URL, method: String = "GET", body: Data? = nil) {
        guard isEnabled else { return }

        var message = "🌐 HTTP \(method) \(url.absoluteString)"

        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            message += "\n   Body: \(bodyString)"
        }

        logger.info("\(message)")
    }

    /// Log a network response
    func logResponse(url: URL, statusCode: Int, data: Data? = nil) {
        guard isEnabled else { return }

        let statusEmoji = statusCode < 300 ? "✅" : "❌"
        var message = "\(statusEmoji) HTTP \(statusCode) \(url.absoluteString)"

        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            let preview = String(dataString.prefix(200))
            message += "\n   Response: \(preview)"
            if dataString.count > 200 {
                message += "... (truncated)"
            }
        }

        logger.info("\(message)")
    }

    /// Log function entry (for tracing execution flow)
    func entering(_ function: String = #function, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("→ Entering \(fileName):\(function)")
    }

    /// Log function exit (for tracing execution flow)
    func exiting(_ function: String = #function, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("← Exiting \(fileName):\(function)")
    }

    /// Log a database query
    func logQuery(table: String, query: String, params: [String: Any] = [:]) {
        guard isEnabled else { return }

        var message = "🗄️ \(table): \(query)"

        if !params.isEmpty {
            let paramStrings = params.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += "\n   Params: \(paramStrings)"
        }

        logger.info("\(message)")
    }

    /// Log a date conversion for timezone debugging
    func logDateConversion(original: Date, formatted: String, formatter: String) {
        guard isEnabled else { return }

        let message = "📅 Date Conversion: \(original) → \(formatted) (using \(formatter))"
        logger.info("\(message)")
    }
}
