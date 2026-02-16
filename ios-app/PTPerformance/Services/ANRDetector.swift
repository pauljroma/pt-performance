//
//  ANRDetector.swift
//  PTPerformance
//
//  ACP-956: Crash-Free Rate Optimization
//  Application Not Responding (ANR) detection via background watchdog thread.
//

import Foundation
import os.log
#if canImport(Sentry)
import Sentry
#endif

/// Detects Application Not Responding (ANR) events by pinging the main thread
/// from a background watchdog thread. If the main thread fails to respond within
/// the configured timeout, an ANR event is logged and reported to Sentry.
///
/// Usage:
/// ```swift
/// ANRDetector.shared.start()
/// // ...later, if needed...
/// ANRDetector.shared.stop()
/// ```
final class ANRDetector {

    // MARK: - Singleton

    static let shared = ANRDetector()

    // MARK: - Configuration

    /// How often the watchdog pings the main thread (seconds)
    private let pingInterval: TimeInterval = 1.0

    /// How long to wait for the main thread to respond before declaring ANR (seconds)
    private let anrThreshold: TimeInterval = 2.0

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "ANRDetector")
    private var watchdogThread: Thread?
    private var isRunning = false
    private let lock = NSLock()

    /// Number of ANR events detected during this session
    private(set) var anrCount: Int = 0

    /// Total cumulative ANR duration (seconds) during this session
    private(set) var totalANRDuration: TimeInterval = 0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Start the ANR watchdog. Safe to call multiple times; subsequent calls are no-ops.
    func start() {
        let didStart = lock.withLock { () -> Bool in
            guard !isRunning else {
                return false
            }

            isRunning = true

            let thread = Thread { [weak self] in
                self?.watchdogLoop()
            }
            thread.name = "com.ptperformance.anr-detector"
            thread.qualityOfService = .userInitiated
            thread.start()
            watchdogThread = thread

            return true
        }

        if didStart {
            logger.info("ANRDetector started: ping=\(self.pingInterval)s, threshold=\(self.anrThreshold)s")
        } else {
            logger.info("ANRDetector already running, skipping start")
        }
    }

    /// Stop the ANR watchdog.
    func stop() {
        let stats: (count: Int, duration: TimeInterval)? = lock.withLock {
            guard isRunning else { return nil }

            isRunning = false
            watchdogThread?.cancel()
            watchdogThread = nil

            return (anrCount, totalANRDuration)
        }

        if let stats {
            logger.info("ANRDetector stopped. Session ANRs: \(stats.count), total duration: \(String(format: "%.1f", stats.duration))s")
        }
    }

    // MARK: - Watchdog Loop

    private func watchdogLoop() {
        while !Thread.current.isCancelled {
            let responded = pingMainThread()

            if !responded {
                handleANRDetected()
            }

            // Sleep for the ping interval before next check
            Thread.sleep(forTimeInterval: pingInterval)
        }
    }

    /// Ping the main thread and wait up to `anrThreshold` for a response.
    /// Returns `true` if the main thread responded in time.
    private func pingMainThread() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            semaphore.signal()
        }

        let result = semaphore.wait(timeout: .now() + anrThreshold)
        return result == .success
    }

    // MARK: - ANR Handling

    private func handleANRDetected() {
        // Capture the main thread call stack while it is still blocked
        let callStack = captureMainThreadCallStack()
        let anrStart = Date()

        let currentCount = lock.withLock { () -> Int in
            anrCount += 1
            return anrCount
        }

        logger.error("ANR detected (#\(currentCount))! Main thread unresponsive for >\(self.anrThreshold)s")

        // Wait for the main thread to recover so we can measure total ANR duration.
        // This blocks (up to 30s) so it must NOT be done while holding the lock.
        let recoverySemaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            recoverySemaphore.signal()
        }
        // Wait up to 30 seconds for recovery; after that, assume permanent hang
        let recovered = recoverySemaphore.wait(timeout: .now() + 30.0)
        let anrDuration = Date().timeIntervalSince(anrStart)

        let cumulativeDuration = lock.withLock { () -> TimeInterval in
            totalANRDuration += anrDuration
            return totalANRDuration
        }

        if recovered == .success {
            logger.info("Main thread recovered after \(String(format: "%.1f", anrDuration))s")
        } else {
            logger.error("Main thread did not recover within 30s after ANR detection")
        }

        reportANRToSentry(
            callStack: callStack,
            duration: anrDuration,
            totalDuration: cumulativeDuration,
            count: currentCount,
            recovered: recovered == .success
        )

        // Also log via ErrorLogger for local tracking
        ErrorLogger.shared.logWarning(
            "ANR detected (#\(currentCount)): main thread blocked for \(String(format: "%.1f", anrDuration))s"
        )
    }

    /// Capture call stack information when ANR is detected.
    ///
    /// Note: `Thread.callStackSymbols` returns the calling thread's stack (the watchdog),
    /// not the main thread's. For accurate main-thread stack traces during ANR,
    /// use Sentry's native app hang tracking (`enableAppHangTracking`) which has
    /// access to thread enumeration APIs. This capture provides supplementary context.
    private func captureMainThreadCallStack() -> [String] {
        // Thread.callStackSymbols returns the watchdog thread's stack here.
        // The main thread's actual stack is captured by Sentry's app hang tracker
        // (enabled via enableAppHangTracking = true in SentryConfig).
        // We include the watchdog stack for diagnostic context.
        var stack = ["[ANR Watchdog Thread Stack — main thread stack captured by Sentry App Hang Tracker]"]
        stack.append(contentsOf: Thread.callStackSymbols.prefix(15))
        return stack
    }

    // MARK: - Sentry Reporting

    private func reportANRToSentry(callStack: [String], duration: TimeInterval, totalDuration: TimeInterval, count: Int, recovered: Bool) {
        #if canImport(Sentry)
        let event = Event(level: .warning)
        event.message = SentryMessage(formatted: "ANR Detected: Main thread unresponsive for \(String(format: "%.1f", duration))s")

        event.tags = [
            "anr": "true",
            "anr.recovered": String(recovered),
            "anr.session_count": String(count)
        ]

        event.extra = [
            "anr_duration_seconds": duration,
            "anr_session_count": count,
            "anr_total_duration_seconds": totalDuration,
            "anr_recovered": recovered,
            "call_stack": callStack.joined(separator: "\n")
        ]

        // Add as a breadcrumb as well
        let breadcrumb = Breadcrumb(level: .warning, category: "anr")
        breadcrumb.message = "ANR detected: \(String(format: "%.1f", duration))s"
        breadcrumb.data = [
            "duration_seconds": duration,
            "count": count,
            "recovered": recovered
        ]
        SentrySDK.addBreadcrumb(breadcrumb)

        // Send the event
        SentrySDK.capture(event: event)
        #endif
    }
}
