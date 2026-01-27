//
//  PerformanceMonitor.swift
//  PTPerformance
//
//  Build 47: App performance monitoring and metrics
//

import Foundation
import os.log
#if canImport(Sentry)
import Sentry
#endif

/// Performance monitoring service for tracking app launch time, view load times, and other metrics
class PerformanceMonitor {

    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.ptperformance.app", category: "Performance")
    private var appLaunchStartTime: Date?
    private var appLaunchEndTime: Date?
    private var viewLoadTimes: [String: TimeInterval] = [:]
    private var ongoingOperations: [String: Date] = [:]

    // MARK: - Initialization

    private init() {
        logger.info("PerformanceMonitor initialized")
    }

    // MARK: - App Launch Tracking

    /// Track app launch start (call in app init)
    func trackAppLaunch() {
        appLaunchStartTime = Date()
        logger.info("App launch started")
    }

    /// Finish app launch tracking (call when first view appears)
    func finishAppLaunch() {
        guard let startTime = appLaunchStartTime else {
            logger.warning("finishAppLaunch called but no start time recorded")
            return
        }

        appLaunchEndTime = Date()
        guard let endTime = appLaunchEndTime else {
            logger.error("Failed to record app launch end time")
            return
        }
        let launchDuration = endTime.timeIntervalSince(startTime)

        logger.info("App launch completed in \(String(format: "%.2f", launchDuration * 1000))ms")

        // Log to ErrorLogger for analytics
        ErrorLogger.shared.logUserAction(action: "app_launch_complete", properties: [
            "duration_ms": Int(launchDuration * 1000)
        ])

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "app.launch", operation: "app.lifecycle")
        transaction.finish()
        #endif
    }

    /// Get app launch duration in milliseconds
    var appLaunchDuration: TimeInterval? {
        guard let start = appLaunchStartTime, let end = appLaunchEndTime else {
            return nil
        }
        return end.timeIntervalSince(start) * 1000
    }

    // MARK: - View Load Tracking

    /// Start tracking view load time
    func startViewLoad(_ viewName: String) {
        ongoingOperations[viewName] = Date()
        logger.debug("Started loading view: \(viewName)")
    }

    /// Finish tracking view load time
    func finishViewLoad(_ viewName: String) {
        guard let startTime = ongoingOperations[viewName] else {
            logger.warning("finishViewLoad called for \(viewName) but no start time found")
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        viewLoadTimes[viewName] = duration
        ongoingOperations.removeValue(forKey: viewName)

        logger.info("View \(viewName) loaded in \(String(format: "%.2f", duration * 1000))ms")

        // Log slow view loads (>500ms) as warnings
        if duration > 0.5 {
            ErrorLogger.shared.logWarning("Slow view load: \(viewName) took \(Int(duration * 1000))ms")
        }

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "view.load.\(viewName)", operation: "ui.load")
        transaction.finish()
        #endif
    }

    /// Get view load duration in milliseconds
    func getViewLoadDuration(_ viewName: String) -> TimeInterval? {
        return viewLoadTimes[viewName].map { $0 * 1000 }
    }

    // MARK: - Database Query Tracking

    /// Start tracking a database query
    func startDatabaseQuery(_ queryName: String) {
        let key = "db_\(queryName)"
        ongoingOperations[key] = Date()
        logger.debug("Started database query: \(queryName)")
    }

    /// Finish tracking a database query
    func finishDatabaseQuery(_ queryName: String, recordCount: Int? = nil) {
        let key = "db_\(queryName)"
        guard let startTime = ongoingOperations[key] else {
            logger.warning("finishDatabaseQuery called for \(queryName) but no start time found")
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        ongoingOperations.removeValue(forKey: key)

        var logMessage = "Database query \(queryName) completed in \(String(format: "%.2f", duration * 1000))ms"
        if let count = recordCount {
            logMessage += " (\(count) records)"
        }

        logger.info("\(logMessage)")

        // Log slow queries (>1s) as warnings
        if duration > 1.0 {
            var properties: [String: Any] = [
                "query": queryName,
                "duration_ms": Int(duration * 1000)
            ]
            if let count = recordCount {
                properties["record_count"] = count
            }
            ErrorLogger.shared.logWarning("Slow database query: \(queryName) took \(Int(duration * 1000))ms")
        }

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "db.query.\(queryName)", operation: "db.query")
        if let count = recordCount {
            transaction.setData(value: count, key: "record_count")
        }
        transaction.finish()
        #endif
    }

    // MARK: - Network Request Tracking

    /// Start tracking a network request
    func startNetworkRequest(_ requestName: String, url: URL? = nil) {
        let key = "net_\(requestName)"
        ongoingOperations[key] = Date()

        var logMessage = "Started network request: \(requestName)"
        if let url = url {
            logMessage += " | URL: \(url.absoluteString)"
        }

        logger.debug("\(logMessage)")
    }

    /// Finish tracking a network request
    func finishNetworkRequest(_ requestName: String, statusCode: Int? = nil, bytesSent: Int? = nil, bytesReceived: Int? = nil) {
        let key = "net_\(requestName)"
        guard let startTime = ongoingOperations[key] else {
            logger.warning("finishNetworkRequest called for \(requestName) but no start time found")
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        ongoingOperations.removeValue(forKey: key)

        var logMessage = "Network request \(requestName) completed in \(String(format: "%.2f", duration * 1000))ms"
        if let status = statusCode {
            logMessage += " | Status: \(status)"
        }
        if let sent = bytesSent {
            logMessage += " | Sent: \(sent) bytes"
        }
        if let received = bytesReceived {
            logMessage += " | Received: \(received) bytes"
        }

        logger.info("\(logMessage)")

        // Log slow network requests (>3s) as warnings
        if duration > 3.0 {
            var properties: [String: Any] = [
                "request": requestName,
                "duration_ms": Int(duration * 1000)
            ]
            if let status = statusCode {
                properties["status_code"] = status
            }
            ErrorLogger.shared.logWarning("Slow network request: \(requestName) took \(Int(duration * 1000))ms")
        }

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "http.\(requestName)", operation: "http.request")
        if let status = statusCode {
            transaction.setData(value: status, key: "status_code")
        }
        transaction.finish()
        #endif
    }

    // MARK: - Custom Operation Tracking

    /// Start tracking a custom operation
    func startOperation(_ operationName: String) {
        let key = "op_\(operationName)"
        ongoingOperations[key] = Date()
        logger.debug("Started operation: \(operationName)")
    }

    /// Finish tracking a custom operation
    func finishOperation(_ operationName: String) {
        let key = "op_\(operationName)"
        guard let startTime = ongoingOperations[key] else {
            logger.warning("finishOperation called for \(operationName) but no start time found")
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        ongoingOperations.removeValue(forKey: key)

        logger.info("Operation \(operationName) completed in \(String(format: "%.2f", duration * 1000))ms")

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "op.\(operationName)", operation: "custom")
        transaction.finish()
        #endif
    }

    // MARK: - Memory Tracking

    /// Get current memory usage in MB
    var memoryUsageMB: Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            logger.error("Failed to get memory usage")
            return 0
        }

        return Double(info.resident_size) / 1024.0 / 1024.0
    }

    /// Log current memory usage
    func logMemoryUsage(context: String? = nil) {
        let usage = memoryUsageMB
        var logMessage = "Memory usage: \(String(format: "%.1f", usage)) MB"
        if let context = context {
            logMessage += " | Context: \(context)"
        }

        logger.info("\(logMessage)")

        // Warn if memory usage is high (>500MB)
        if usage > 500 {
            ErrorLogger.shared.logWarning("High memory usage: \(String(format: "%.1f", usage)) MB")
        }
    }

    // MARK: - Summary

    /// Get performance summary for debugging
    func getPerformanceSummary() -> String {
        var summary = "=== Performance Summary ===\n"

        if let launchDuration = appLaunchDuration {
            summary += "App Launch: \(String(format: "%.0f", launchDuration))ms\n"
        }

        if !viewLoadTimes.isEmpty {
            summary += "View Load Times:\n"
            for (view, duration) in viewLoadTimes.sorted(by: { $0.value > $1.value }) {
                summary += "  - \(view): \(String(format: "%.0f", duration * 1000))ms\n"
            }
        }

        summary += "Memory Usage: \(String(format: "%.1f", memoryUsageMB)) MB\n"
        summary += "=========================="

        return summary
    }

    /// Print performance summary to console
    func printPerformanceSummary() {
        #if DEBUG
        print(getPerformanceSummary())
        #else
        logger.debug("\(self.getPerformanceSummary())")
        #endif
    }
}
