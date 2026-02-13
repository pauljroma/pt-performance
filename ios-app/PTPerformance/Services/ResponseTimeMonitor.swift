//
//  ResponseTimeMonitor.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Debug-only tool to measure tap-to-response times and ensure sub-100ms interactions
//

import Foundation
import os.log

// MARK: - Interaction Types

/// Types of user interactions that are monitored for response time
enum InteractionType: String, CaseIterable {
    case setCompletion = "set_completion"
    case exerciseCompletion = "exercise_completion"
    case weightChange = "weight_change"
    case repsChange = "reps_change"
    case exerciseNavigation = "exercise_navigation"
    case workoutCompletion = "workout_completion"
    case timerStart = "timer_start"
    case timerStop = "timer_stop"
    case buttonTap = "button_tap"
    case exerciseSkip = "exercise_skip"
    case rpeChange = "rpe_change"
    case painScoreChange = "pain_score_change"

    var targetResponseMs: Double {
        switch self {
        case .setCompletion, .weightChange, .repsChange, .rpeChange, .painScoreChange:
            return 50  // Critical path - must be instant
        case .exerciseCompletion, .exerciseNavigation, .buttonTap, .exerciseSkip:
            return 80  // Important interactions
        case .workoutCompletion, .timerStart, .timerStop:
            return 100  // Can tolerate slightly more
        }
    }

    var description: String {
        switch self {
        case .setCompletion: return "Set Completion"
        case .exerciseCompletion: return "Exercise Completion"
        case .weightChange: return "Weight Change"
        case .repsChange: return "Reps Change"
        case .exerciseNavigation: return "Exercise Navigation"
        case .workoutCompletion: return "Workout Completion"
        case .timerStart: return "Timer Start"
        case .timerStop: return "Timer Stop"
        case .buttonTap: return "Button Tap"
        case .exerciseSkip: return "Exercise Skip"
        case .rpeChange: return "RPE Change"
        case .painScoreChange: return "Pain Score Change"
        }
    }
}

// MARK: - Interaction Measurement

/// A single interaction measurement
struct InteractionMeasurement: Identifiable {
    let id = UUID()
    let type: InteractionType
    let startTime: Date
    let endTime: Date
    let durationMs: Double
    let meetsTarget: Bool
    let context: String?

    init(type: InteractionType, startTime: Date, endTime: Date, context: String? = nil) {
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.durationMs = endTime.timeIntervalSince(startTime) * 1000
        self.meetsTarget = durationMs <= type.targetResponseMs
        self.context = context
    }
}

// MARK: - Statistics

/// Aggregated statistics for an interaction type
struct InteractionStatistics {
    let type: InteractionType
    let count: Int
    let avgMs: Double
    let minMs: Double
    let maxMs: Double
    let p50Ms: Double  // Median
    let p95Ms: Double  // 95th percentile
    let p99Ms: Double  // 99th percentile
    let successRate: Double  // Percentage meeting target

    var isHealthy: Bool {
        // Healthy if 95% of interactions meet target
        successRate >= 0.95
    }

    var statusEmoji: String {
        if successRate >= 0.99 { return "green" }
        if successRate >= 0.95 { return "yellow" }
        if successRate >= 0.80 { return "orange" }
        return "red"
    }
}

// MARK: - ResponseTimeMonitor

/// Debug-only monitor for measuring interaction response times
///
/// ACP-516: Ensures every tap responds in under 100ms by:
/// 1. Measuring actual response times for all critical interactions
/// 2. Logging warnings when targets are missed
/// 3. Providing statistics and reports for debugging
/// 4. Enabling/disabling monitoring based on build configuration
class ResponseTimeMonitor {
    static let shared = ResponseTimeMonitor()

    // MARK: - Configuration

    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false
    #endif

    private let maxStoredMeasurements = 1000  // Rolling buffer
    private let logger = Logger(subsystem: "com.getmodus.app", category: "ResponseTime")

    // MARK: - State

    private var measurements: [InteractionMeasurement] = []
    private var pendingInteractions: [UUID: (type: InteractionType, startTime: Date, context: String?)] = [:]
    private let lock = NSLock()

    // MARK: - Session Tracking

    private var sessionStartTime: Date?
    private var sessionInteractionCount: Int = 0
    private var sessionViolationCount: Int = 0

    private init() {
        #if DEBUG
        startSession()
        #endif
    }

    // MARK: - Measurement API

    /// Start timing an interaction. Returns a token to pass to endInteraction.
    func startInteraction(_ type: InteractionType, context: String? = nil) -> UUID {
        guard isEnabled else { return UUID() }

        let token = UUID()
        lock.lock()
        pendingInteractions[token] = (type, Date(), context)
        lock.unlock()
        return token
    }

    /// End timing an interaction and record the measurement
    func endInteraction(_ token: UUID, type: InteractionType? = nil) {
        guard isEnabled else { return }

        let endTime = Date()

        lock.lock()
        guard let pending = pendingInteractions.removeValue(forKey: token) else {
            lock.unlock()
            return
        }
        lock.unlock()

        let measurement = InteractionMeasurement(
            type: type ?? pending.type,
            startTime: pending.startTime,
            endTime: endTime,
            context: pending.context
        )

        recordMeasurement(measurement)
    }

    /// Convenience method for measuring a synchronous block
    func measure<T>(_ type: InteractionType, context: String? = nil, block: () -> T) -> T {
        guard isEnabled else { return block() }

        let token = startInteraction(type, context: context)
        let result = block()
        endInteraction(token)
        return result
    }

    /// Convenience method for measuring an async block
    func measureAsync<T>(_ type: InteractionType, context: String? = nil, block: () async -> T) async -> T {
        guard isEnabled else { return await block() }

        let token = startInteraction(type, context: context)
        let result = await block()
        endInteraction(token)
        return result
    }

    // MARK: - Recording

    private func recordMeasurement(_ measurement: InteractionMeasurement) {
        lock.lock()
        measurements.append(measurement)
        sessionInteractionCount += 1

        // Maintain rolling buffer
        if measurements.count > maxStoredMeasurements {
            measurements.removeFirst(measurements.count - maxStoredMeasurements)
        }

        // Check for violations
        if !measurement.meetsTarget {
            sessionViolationCount += 1
            logViolation(measurement)
        }
        lock.unlock()

        #if DEBUG
        // Log all measurements in verbose mode
        if ProcessInfo.processInfo.environment["VERBOSE_RESPONSE_TIME"] != nil {
            logger.debug("\(measurement.type.rawValue): \(String(format: "%.2f", measurement.durationMs))ms")
        }
        #endif
    }

    private func logViolation(_ measurement: InteractionMeasurement) {
        let message = """
            RESPONSE TIME VIOLATION: \(measurement.type.description)
            Duration: \(String(format: "%.2f", measurement.durationMs))ms
            Target: \(measurement.type.targetResponseMs)ms
            Context: \(measurement.context ?? "none")
            """

        logger.warning("\(message)")

        DebugLogger.shared.log("[ResponseTimeMonitor] " + message, level: .warning)

        // Log to error tracking in production builds
        ErrorLogger.shared.logWarning("Response time violation: \(measurement.type.rawValue) took \(Int(measurement.durationMs))ms (target: \(Int(measurement.type.targetResponseMs))ms)")
    }

    // MARK: - Statistics

    /// Get statistics for a specific interaction type
    func statistics(for type: InteractionType) -> InteractionStatistics? {
        guard isEnabled else { return nil }

        lock.lock()
        let typeMeasurements = measurements.filter { $0.type == type }
        lock.unlock()

        guard !typeMeasurements.isEmpty else { return nil }

        let durations = typeMeasurements.map { $0.durationMs }.sorted()
        let successCount = typeMeasurements.filter { $0.meetsTarget }.count

        return InteractionStatistics(
            type: type,
            count: typeMeasurements.count,
            avgMs: durations.reduce(0, +) / Double(durations.count),
            minMs: durations.first ?? 0,
            maxMs: durations.last ?? 0,
            p50Ms: percentile(durations, 0.50),
            p95Ms: percentile(durations, 0.95),
            p99Ms: percentile(durations, 0.99),
            successRate: Double(successCount) / Double(typeMeasurements.count)
        )
    }

    /// Get statistics for all interaction types
    func allStatistics() -> [InteractionStatistics] {
        InteractionType.allCases.compactMap { statistics(for: $0) }
    }

    /// Get overall success rate across all interactions
    var overallSuccessRate: Double {
        guard isEnabled else { return 1.0 }

        lock.lock()
        let total = measurements.count
        let success = measurements.filter { $0.meetsTarget }.count
        lock.unlock()

        guard total > 0 else { return 1.0 }
        return Double(success) / Double(total)
    }

    // MARK: - Session Management

    /// Start a new measurement session
    func startSession() {
        lock.lock()
        sessionStartTime = Date()
        sessionInteractionCount = 0
        sessionViolationCount = 0
        measurements.removeAll()
        lock.unlock()

        logger.info("Response time monitoring session started")
    }

    /// End the current session and return a summary report
    func endSession() -> String {
        guard isEnabled else { return "Response time monitoring disabled" }

        lock.lock()
        let duration = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let totalCount = sessionInteractionCount
        let violationCount = sessionViolationCount
        lock.unlock()

        let report = generateSessionReport(
            duration: duration,
            totalCount: totalCount,
            violationCount: violationCount
        )

        logger.info("Response time session ended. Report:\n\(report)")

        return report
    }

    // MARK: - Reporting

    /// Generate a detailed report of response time statistics
    func generateReport() -> String {
        guard isEnabled else { return "Response time monitoring disabled" }

        var report = """
            === ACP-516 Response Time Report ===
            Generated: \(ISO8601DateFormatter().string(from: Date()))
            Overall Success Rate: \(String(format: "%.1f", overallSuccessRate * 100))%

            """

        let stats = allStatistics()

        if stats.isEmpty {
            report += "No measurements recorded yet.\n"
        } else {
            report += "Interaction Type                 Avg      P95      P99   Success\n"
            report += "----------------------------------------------------------------\n"

            for stat in stats.sorted(by: { $0.type.rawValue < $1.type.rawValue }) {
                let name = stat.type.description.padding(toLength: 25, withPad: " ", startingAt: 0)
                let avg = String(format: "%6.1f", stat.avgMs)
                let p95 = String(format: "%6.1f", stat.p95Ms)
                let p99 = String(format: "%6.1f", stat.p99Ms)
                let success = String(format: "%6.1f%%", stat.successRate * 100)
                let status = stat.isHealthy ? "[OK]" : "[!!]"

                report += "\(name) \(avg)ms  \(p95)ms  \(p99)ms  \(success) \(status)\n"
            }
        }

        report += "\n==================================="

        return report
    }

    private func generateSessionReport(duration: TimeInterval, totalCount: Int, violationCount: Int) -> String {
        let successRate = totalCount > 0 ? Double(totalCount - violationCount) / Double(totalCount) : 1.0

        return """
            === Session Summary ===
            Duration: \(String(format: "%.1f", duration))s
            Total Interactions: \(totalCount)
            Violations: \(violationCount)
            Success Rate: \(String(format: "%.1f", successRate * 100))%
            ========================
            """
    }

    // MARK: - Debug Console

    /// Print current statistics to console (debug builds only)
    func printStats() {
        DebugLogger.shared.log(generateReport(), level: .diagnostic)
    }

    /// Get recent violations for debugging
    func recentViolations(limit: Int = 10) -> [InteractionMeasurement] {
        guard isEnabled else { return [] }

        lock.lock()
        let violations = measurements.filter { !$0.meetsTarget }.suffix(limit)
        lock.unlock()

        return Array(violations)
    }

    // MARK: - Utilities

    private func percentile(_ sortedValues: [Double], _ percentile: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        let index = Int(Double(sortedValues.count - 1) * percentile)
        return sortedValues[min(index, sortedValues.count - 1)]
    }

    /// Clear all recorded measurements
    func clearMeasurements() {
        lock.lock()
        measurements.removeAll()
        lock.unlock()
    }
}

// MARK: - SwiftUI View Extension for Easy Measurement

#if DEBUG
import SwiftUI

extension View {
    /// Measure the response time of a button action
    func measureResponseTime(_ type: InteractionType, context: String? = nil, action: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                ResponseTimeMonitor.shared.measure(type, context: context) {
                    action()
                }
            }
        )
    }
}
#endif

// MARK: - Performance Assertions

#if DEBUG
/// Assert that a block completes within the target time for an interaction type
/// Only active in DEBUG builds
func assertResponseTime(_ type: InteractionType, file: StaticString = #file, line: UInt = #line, block: () -> Void) {
    let start = Date()
    block()
    let duration = Date().timeIntervalSince(start) * 1000

    if duration > type.targetResponseMs {
        DebugLogger.shared.log("[ResponseTime] Assertion failed at \(file):\(line): \(type.rawValue) took \(String(format: "%.2f", duration))ms (target: \(type.targetResponseMs)ms)", level: .warning)
    }
}

/// Async version of assertResponseTime
func assertResponseTimeAsync(_ type: InteractionType, file: StaticString = #file, line: UInt = #line, block: () async -> Void) async {
    let start = Date()
    await block()
    let duration = Date().timeIntervalSince(start) * 1000

    if duration > type.targetResponseMs {
        DebugLogger.shared.log("[ResponseTime] Assertion failed at \(file):\(line): \(type.rawValue) took \(String(format: "%.2f", duration))ms (target: \(type.targetResponseMs)ms)", level: .warning)
    }
}
#endif
