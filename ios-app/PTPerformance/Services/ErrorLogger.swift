//
//  ErrorLogger.swift
//  PTPerformance
//
//  Build 47: Error logging and user action tracking
//

import Foundation
import os.log
#if canImport(Sentry)
import Sentry
#endif

/// Centralized error logging service for the application
/// Integrates with system logging and can be extended with Sentry when available
class ErrorLogger {

    // MARK: - Singleton

    static let shared = ErrorLogger()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.ptperformance.app", category: "ErrorLogger")
    private var currentUserId: String?
    private var currentUserType: String?
    private var sessionStartTime: Date

    // MARK: - Initialization

    private init() {
        self.sessionStartTime = Date()
        logger.info("ErrorLogger initialized")
    }

    // MARK: - User Context

    /// Set user context for error tracking
    func setUser(userId: String, email: String?, userType: String) {
        self.currentUserId = userId
        self.currentUserType = userType

        logger.info("User context set: userId=\(userId), userType=\(userType)")

        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            let user = Sentry.User(userId: userId)
            user.email = email
            user.data = ["userType": userType]
            scope.setUser(user)
        }
        #endif
    }

    /// Clear user context (e.g., on logout)
    func clearUser() {
        logger.info("User context cleared: userId=\(self.currentUserId ?? "none")")

        self.currentUserId = nil
        self.currentUserType = nil

        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            scope.setUser(nil)
        }
        #endif
    }

    // MARK: - User Actions

    /// Log a user action for analytics and debugging
    func logUserAction(action: String, properties: [String: Any] = [:]) {
        var logMessage = "User action: \(action)"

        if let userId = currentUserId {
            logMessage += " | userId=\(userId)"
        }

        if let userType = currentUserType {
            logMessage += " | userType=\(userType)"
        }

        if !properties.isEmpty {
            let propsString = properties.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " | properties: \(propsString)"
        }

        logger.info("\(logMessage)")

        #if canImport(Sentry)
        let breadcrumb = Breadcrumb(level: .info, category: "user.action")
        breadcrumb.message = action
        breadcrumb.data = properties
        SentrySDK.addBreadcrumb(breadcrumb)
        #endif
    }

    // MARK: - Error Logging

    /// Log an error with context
    func logError(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "Error in \(fileName):\(function):\(line) - \(error.localizedDescription)"

        if let context = context {
            logMessage += " | Context: \(context)"
        }

        if let userId = currentUserId {
            logMessage += " | userId=\(userId)"
        }

        logger.error("\(logMessage)")

        #if canImport(Sentry)
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: ["context": context], key: "error_context")
            }
            scope.setTag(value: fileName, key: "file")
            scope.setTag(value: function, key: "function")
            scope.setTag(value: String(line), key: "line")
        }
        #endif
    }

    /// Log a warning message
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("\(fileName):\(function):\(line) - \(message)")

        #if canImport(Sentry)
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(.warning)
        }
        #endif
    }

    /// Log an info message
    func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("\(fileName):\(function):\(line) - \(message)")
    }

    // MARK: - Network Errors

    /// Log a network error with request/response details
    func logNetworkError(
        _ error: Error,
        url: URL?,
        statusCode: Int?,
        requestBody: Data? = nil,
        responseBody: Data? = nil
    ) {
        var logMessage = "Network error: \(error.localizedDescription)"

        if let url = url {
            logMessage += " | URL: \(url.absoluteString)"
        }

        if let statusCode = statusCode {
            logMessage += " | Status: \(statusCode)"
        }

        logger.error("\(logMessage)")

        #if canImport(Sentry)
        SentrySDK.capture(error: error) { scope in
            var context: [String: Any] = [:]
            if let url = url {
                context["url"] = url.absoluteString
            }
            if let statusCode = statusCode {
                context["status_code"] = statusCode
            }
            scope.setContext(value: context, key: "network")
        }
        #endif
    }

    // MARK: - Database Errors

    /// Log a database/Supabase error
    func logDatabaseError(_ error: Error, query: String? = nil, table: String? = nil) {
        var logMessage = "Database error: \(error.localizedDescription)"

        if let table = table {
            logMessage += " | Table: \(table)"
        }

        if let query = query {
            logMessage += " | Query: \(query)"
        }

        logger.error("\(logMessage)")

        #if canImport(Sentry)
        SentrySDK.capture(error: error) { scope in
            var context: [String: Any] = [:]
            if let table = table {
                context["table"] = table
            }
            if let query = query {
                context["query"] = query
            }
            scope.setContext(value: context, key: "database")
        }
        #endif
    }

    // MARK: - Session Info

    /// Get current session duration in seconds
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }

    /// Log session ended
    func endSession() {
        let duration = sessionDuration
        logger.info("Session ended after \(Int(duration)) seconds")

        logUserAction(action: "session_ended", properties: [
            "duration_seconds": Int(duration),
            "user_id": currentUserId ?? "unknown"
        ])
    }
}
