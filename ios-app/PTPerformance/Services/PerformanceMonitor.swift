//
//  PerformanceMonitor.swift
//  PTPerformance
//
//  Build 47: App performance monitoring and metrics
//  ACP-955: Enhanced performance monitoring integration
//

import Foundation
import os.log
#if os(iOS)
import UIKit
#endif
#if canImport(Sentry)
import Sentry
#endif

/// Performance monitoring service for tracking app launch time, view load times, and other metrics
/// ACP-932: Enhanced for cold start optimization tracking (<2 second target)
class PerformanceMonitor {

    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "Performance")
    private var appLaunchStartTime: Date?
    private var appLaunchEndTime: Date?
    private var viewLoadTimes: [String: TimeInterval] = [:]
    private var ongoingOperations: [String: Date] = [:]
    private let lock = NSLock()

    // ACP-955: API response time tracking
    private var apiResponseTimes: [String: [TimeInterval]] = [:]
    private let maxStoredResponseTimes = 100 // Per endpoint

    // ACP-955: Memory warning tracking
    private var memoryWarningCount = 0
    private var lastMemoryWarning: Date?

    // ACP-932: Cold start optimization tracking
    private var coldStartMilestones: [String: CFAbsoluteTime] = [:]
    private let coldStartBegin = CFAbsoluteTimeGetCurrent()

    /// ACP-932: Target cold start time in seconds
    static let coldStartTargetSeconds: TimeInterval = 2.0

    // MARK: - Thresholds

    private enum Thresholds {
        static let slowViewLoadMs: Double = 500
        static let slowQueryMs: Double = 1000
        static let slowNetworkMs: Double = 3000
        static let highMemoryMB: Double = 500
        static let criticalMemoryMB: Double = 750
        // ACP-932: Cold start threshold
        static let coldStartTargetMs: Double = 2000
    }

    // MARK: - Initialization

    private init() {
        // ACP-932/945: Defer logging to avoid blocking during cold start
        Task(priority: .utility) {
            Logger(subsystem: "com.getmodus.app", category: "Performance")
                .info("PerformanceMonitor initialized")
        }
        setupMemoryWarningObserver()
    }

    /// Setup observer for memory warnings
    private func setupMemoryWarningObserver() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    @objc private func handleMemoryWarning() {
        lock.lock()
        memoryWarningCount += 1
        lastMemoryWarning = Date()
        lock.unlock()

        let memoryUsage = memoryUsageMB
        logger.warning("Memory warning received! Current usage: \(String(format: "%.1f", memoryUsage)) MB")

        ErrorLogger.shared.logWarning("Memory warning #\(memoryWarningCount): \(String(format: "%.1f", memoryUsage)) MB")

        // Add Sentry breadcrumb
        addBreadcrumb(
            category: "memory",
            message: "Memory warning received",
            data: [
                "memory_mb": String(format: "%.1f", memoryUsage),
                "warning_count": String(memoryWarningCount)
            ],
            level: .warning
        )
    }

    // MARK: - App Launch Tracking

    /// Track app launch start (call in app init)
    func trackAppLaunch() {
        appLaunchStartTime = Date()
        // ACP-932: Record cold start milestone
        recordColdStartMilestone("app_init")
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

        // ACP-932: Record final cold start milestone
        recordColdStartMilestone("first_view_appeared")

        let launchMs = launchDuration * 1000
        let meetsTarget = launchMs < Thresholds.coldStartTargetMs

        logger.info("App launch completed in \(String(format: "%.2f", launchMs))ms (target: <\(Int(Thresholds.coldStartTargetMs))ms, met: \(meetsTarget))")

        // Log to ErrorLogger for analytics
        ErrorLogger.shared.logUserAction(action: "app_launch_complete", properties: [
            "duration_ms": Int(launchMs),
            "meets_target": meetsTarget,
            "target_ms": Int(Thresholds.coldStartTargetMs)
        ])

        // ACP-932: Warn if cold start target not met
        if !meetsTarget {
            ErrorLogger.shared.logWarning("Cold start exceeded target: \(Int(launchMs))ms > \(Int(Thresholds.coldStartTargetMs))ms")
        }

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "app.launch", operation: "app.lifecycle")
        transaction.setData(value: meetsTarget, key: "meets_target")
        transaction.finish()
        #endif
    }

    // MARK: - ACP-932: Cold Start Milestone Tracking

    /// Record a cold start milestone for performance analysis
    func recordColdStartMilestone(_ milestone: String) {
        lock.lock()
        coldStartMilestones[milestone] = CFAbsoluteTimeGetCurrent()
        lock.unlock()
    }

    /// Get time elapsed from cold start to a milestone in milliseconds
    func getColdStartMilestoneMs(_ milestone: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }
        guard let time = coldStartMilestones[milestone] else { return nil }
        return (time - coldStartBegin) * 1000
    }

    /// Get cold start report for debugging
    func getColdStartReport() -> String {
        lock.lock()
        defer { lock.unlock() }

        var report = "=== Cold Start Report ===\n"
        report += "Target: <\(Int(Thresholds.coldStartTargetMs))ms\n\n"

        let sortedMilestones = coldStartMilestones.sorted { $0.value < $1.value }

        var previousTime = coldStartBegin
        for (milestone, time) in sortedMilestones {
            let totalMs = (time - coldStartBegin) * 1000
            let deltaMs = (time - previousTime) * 1000
            report += "[\(String(format: "%6.0f", totalMs))ms] \(milestone) (+\(String(format: "%.0f", deltaMs))ms)\n"
            previousTime = time
        }

        if let lastMilestone = sortedMilestones.last {
            let totalMs = (lastMilestone.value - coldStartBegin) * 1000
            let meetsTarget = totalMs < Thresholds.coldStartTargetMs
            report += "\nTotal: \(String(format: "%.0f", totalMs))ms - \(meetsTarget ? "PASSED" : "FAILED")\n"
        }

        report += "========================="
        return report
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
        DebugLogger.shared.log(getPerformanceSummary(), level: .diagnostic)
    }

    // MARK: - ACP-955: Enhanced Monitoring

    /// Add a breadcrumb for debugging crashes
    func addBreadcrumb(
        category: String,
        message: String,
        data: [String: String]? = nil,
        level: BreadcrumbLevel = .info
    ) {
        #if canImport(Sentry)
        let breadcrumb = Breadcrumb(level: level.sentryLevel, category: category)
        breadcrumb.message = message
        breadcrumb.data = data
        SentrySDK.addBreadcrumb(breadcrumb)
        #endif

        // Also log locally
        logger.debug("[\(category)] \(message)")
    }

    /// Track API response time for an endpoint
    func trackAPIResponse(endpoint: String, durationMs: Double, statusCode: Int? = nil, success: Bool = true) {
        lock.lock()

        // Store response time
        if apiResponseTimes[endpoint] == nil {
            apiResponseTimes[endpoint] = []
        }
        apiResponseTimes[endpoint]?.append(durationMs)

        // Maintain rolling buffer
        if let count = apiResponseTimes[endpoint]?.count, count > maxStoredResponseTimes {
            apiResponseTimes[endpoint]?.removeFirst(count - maxStoredResponseTimes)
        }
        lock.unlock()

        // Log slow responses
        if durationMs > Thresholds.slowNetworkMs {
            ErrorLogger.shared.logWarning("Slow API response: \(endpoint) took \(Int(durationMs))ms")
        }

        // Add breadcrumb for debugging
        var breadcrumbData: [String: String] = [
            "duration_ms": String(format: "%.0f", durationMs),
            "success": String(success)
        ]
        if let status = statusCode {
            breadcrumbData["status"] = String(status)
        }

        addBreadcrumb(
            category: "api",
            message: "\(endpoint) completed",
            data: breadcrumbData,
            level: success ? .info : .warning
        )

        #if canImport(Sentry)
        // Create Sentry span for API call
        let transaction = SentrySDK.startTransaction(name: "api.\(endpoint)", operation: "http.client")
        if let status = statusCode {
            transaction.setData(value: status, key: "http.status_code")
        }
        transaction.setData(value: durationMs, key: "duration_ms")
        transaction.finish(status: success ? .ok : .unknownError)
        #endif
    }

    /// Get average response time for an endpoint
    func getAverageResponseTime(endpoint: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }

        guard let times = apiResponseTimes[endpoint], !times.isEmpty else {
            return nil
        }
        return times.reduce(0, +) / Double(times.count)
    }

    /// Get P95 response time for an endpoint
    func getP95ResponseTime(endpoint: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }

        guard let times = apiResponseTimes[endpoint], !times.isEmpty else {
            return nil
        }

        let sorted = times.sorted()
        let index = Int(Double(sorted.count - 1) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    /// Track a user navigation event
    func trackNavigation(from: String, to: String) {
        addBreadcrumb(
            category: "navigation",
            message: "Navigated from \(from) to \(to)",
            data: ["from": from, "to": to]
        )
    }

    /// Track a user action for debugging
    func trackUserAction(_ action: String, details: [String: String]? = nil) {
        addBreadcrumb(
            category: "user",
            message: action,
            data: details
        )
    }

    /// Track data sync operation
    func trackDataSync(operation: String, recordCount: Int, durationMs: Double, success: Bool) {
        addBreadcrumb(
            category: "sync",
            message: "\(operation) completed",
            data: [
                "records": String(recordCount),
                "duration_ms": String(format: "%.0f", durationMs),
                "success": String(success)
            ],
            level: success ? .info : .error
        )

        #if canImport(Sentry)
        let transaction = SentrySDK.startTransaction(name: "sync.\(operation)", operation: "task")
        transaction.setData(value: recordCount, key: "record_count")
        transaction.setData(value: durationMs, key: "duration_ms")
        transaction.finish(status: success ? .ok : .unknownError)
        #endif
    }

    /// Check memory health and log if concerning
    func checkMemoryHealth() {
        let usage = memoryUsageMB

        if usage > Thresholds.criticalMemoryMB {
            ErrorLogger.shared.logError(
                NSError(domain: "PerformanceMonitor", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Critical memory usage"
                ]),
                context: "Memory usage critical",
                metadata: ["memory_mb": usage]
            )
        } else if usage > Thresholds.highMemoryMB {
            ErrorLogger.shared.logWarning("High memory usage: \(String(format: "%.1f", usage)) MB")
        }
    }

    /// Get memory warning statistics
    var memoryWarningStats: (count: Int, lastWarning: Date?) {
        lock.lock()
        defer { lock.unlock() }
        return (memoryWarningCount, lastMemoryWarning)
    }

    /// Get API performance report
    func getAPIPerformanceReport() -> String {
        lock.lock()
        defer { lock.unlock() }

        var report = "=== API Performance Report ===\n"

        for (endpoint, times) in apiResponseTimes.sorted(by: { $0.key < $1.key }) {
            guard !times.isEmpty else { continue }

            let sorted = times.sorted()
            let avg = times.reduce(0, +) / Double(times.count)
            let p95Index = Int(Double(sorted.count - 1) * 0.95)
            let p95 = sorted[min(p95Index, sorted.count - 1)]

            report += "\(endpoint):\n"
            report += "  Calls: \(times.count)\n"
            report += "  Avg: \(String(format: "%.0f", avg))ms\n"
            report += "  P95: \(String(format: "%.0f", p95))ms\n"
        }

        report += "=============================="
        return report
    }
}

// MARK: - Breadcrumb Level

enum BreadcrumbLevel {
    case debug
    case info
    case warning
    case error

    #if canImport(Sentry)
    var sentryLevel: SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
    #endif
}
