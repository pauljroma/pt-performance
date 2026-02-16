//
//  WarmStartOptimizer.swift
//  PTPerformance
//
//  ACP-933: Warm Start & Resume Speed Optimization
//  Detects launch type (cold/warm/resume), preserves state across backgrounding,
//  implements progressive data refresh, and tracks warm start / resume timing.
//

import Foundation
import UIKit
import os.log

// MARK: - Launch Type

/// Categorizes how the app was brought to the foreground.
enum AppLaunchType: String, Sendable {
    /// First launch after process termination. Full initialization required.
    case cold = "cold_start"
    /// App process was alive but not in foreground (e.g., suspended by the system).
    /// UI state may still be in memory; only a data refresh is needed.
    case warm = "warm_start"
    /// App returned from background without process suspension.
    /// Fastest path — UI is intact, only a lightweight data freshness check is needed.
    case resume = "resume"
}

// MARK: - Resume Timing Record

/// A single recorded resume-to-interactive timing measurement.
struct ResumeTimingRecord: Sendable {
    let launchType: AppLaunchType
    let durationMs: Double
    let timestamp: Date
    let preWarmHit: Bool
}

// MARK: - Warm Start Optimizer

/// Optimizes app warm start and resume-from-background performance.
///
/// Responsibilities:
/// - Detect whether the current foreground transition is a cold start, warm start, or resume.
/// - Preserve critical view state snapshots before backgrounding.
/// - Provide progressive data refresh: show cached data immediately, refresh in background.
/// - Pre-warm critical data on `willEnterForeground`.
/// - Track warm start / resume timing for performance monitoring via `PerformanceMonitor`.
///
/// ## Integration
/// The `PTPerformanceApp` scene-phase handler should call `handleScenePhaseChange(_:)` on
/// every phase transition. This single entry point drives all detection, timing, pre-warming,
/// and state preservation logic.
@MainActor
final class WarmStartOptimizer {

    // MARK: - Singleton

    static let shared = WarmStartOptimizer()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "WarmStartOptimizer")

    /// The launch type for the most recent foreground transition.
    private(set) var currentLaunchType: AppLaunchType = .cold

    /// Whether the app has completed at least one full cold start cycle.
    private var hasCompletedColdStart = false

    /// Timestamp when the app most recently entered the background.
    private var backgroundEntryTime: Date?

    /// Timestamp when the most recent foreground transition began.
    private var foregroundEntryTime: Date?

    /// Whether a pre-warm cycle ran for the current foreground transition.
    private var didPreWarmForCurrentTransition = false

    /// Rolling buffer of resume timing records (last 50).
    private var timingHistory: [ResumeTimingRecord] = []
    private let maxTimingHistory = 50

    /// Time threshold: if the app was backgrounded for less than this, treat as resume.
    /// Beyond this window the system may have reclaimed resources, so treat as warm start.
    private let resumeThresholdSeconds: TimeInterval = 30.0

    /// Observers for UIKit lifecycle notifications.
    private var willEnterForegroundObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupLifecycleObservers()
        logger.info("WarmStartOptimizer initialized")
    }

    deinit {
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Lifecycle Observers

    /// Register for UIKit lifecycle notifications.
    /// These fire earlier than SwiftUI `scenePhase` changes, giving us a head start
    /// on pre-warming before the UI is visible.
    private func setupLifecycleObservers() {
        willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleWillEnterForeground()
            }
        }

        didEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDidEnterBackground()
            }
        }

        logger.info("Lifecycle observers registered")
    }

    // MARK: - Scene Phase Handling (Primary API)

    /// Handle a SwiftUI scene phase transition.
    ///
    /// Call this from `PTPerformanceApp.onChange(of: scenePhase)` for every phase change.
    /// This is the single entry point that drives launch-type detection, timing,
    /// pre-warming, state preservation, and progressive refresh.
    ///
    /// - Parameter phase: The new `ScenePhase` value.
    func handleScenePhaseChange(_ phase: ScenePhaseValue) {
        switch phase {
        case .active:
            handleBecameActive()
        case .inactive:
            // No action needed; inactive is a transient state
            break
        case .background:
            handleEnteredBackground()
        }
    }

    // MARK: - Active (Foreground)

    /// Called when the scene becomes active.
    /// Finalizes launch-type detection, records timing, and kicks off progressive refresh.
    private func handleBecameActive() {
        let launchType = detectLaunchType()
        currentLaunchType = launchType

        // Mark foreground entry for timing
        if foregroundEntryTime == nil {
            foregroundEntryTime = Date()
        }

        logger.info("Scene active — launch type: \(launchType.rawValue)")

        // Record performance milestone
        PerformanceMonitor.shared.addBreadcrumb(
            category: "lifecycle",
            message: "App became active",
            data: [
                "launch_type": launchType.rawValue,
                "pre_warm_hit": String(didPreWarmForCurrentTransition)
            ]
        )

        // Start progressive data refresh for warm starts and resumes
        if launchType != .cold {
            startProgressiveRefresh(launchType: launchType)
        }

        // Record timing
        recordTransitionTiming(launchType: launchType)

        // Reset per-transition state
        didPreWarmForCurrentTransition = false
    }

    // MARK: - Background

    /// Called when the scene enters background (from scenePhase).
    /// Triggers state snapshot and cache maintenance.
    private func handleEnteredBackground() {
        logger.info("Scene entered background")

        // Snapshot state for restoration
        SceneRestorationCoordinator.shared.captureSnapshot()

        // Purge expired API cache entries to free memory while backgrounded
        Task {
            await APIResponseCache.shared.purgeExpired()
        }
    }

    // MARK: - UIKit Lifecycle Handlers

    /// Called on `willEnterForegroundNotification` — fires before the UI is visible.
    /// This is the ideal moment for pre-warming critical data.
    private func handleWillEnterForeground() {
        foregroundEntryTime = Date()

        logger.info("Will enter foreground — starting pre-warm")

        // Pre-warm critical data before the UI appears
        preWarmCriticalData()
        didPreWarmForCurrentTransition = true
    }

    /// Called on `didEnterBackgroundNotification`.
    /// Records the background entry timestamp for launch-type detection.
    private func handleDidEnterBackground() {
        backgroundEntryTime = Date()
        foregroundEntryTime = nil

        logger.info("Did enter background")
    }

    // MARK: - Launch Type Detection

    /// Determine the launch type based on process state and background duration.
    ///
    /// - Cold: First launch (hasCompletedColdStart is false).
    /// - Resume: Backgrounded for less than `resumeThresholdSeconds`.
    /// - Warm: Backgrounded for longer, but process is still alive.
    private func detectLaunchType() -> AppLaunchType {
        guard hasCompletedColdStart else {
            hasCompletedColdStart = true
            return .cold
        }

        guard let bgTime = backgroundEntryTime else {
            // No background timestamp means this is the first activation after cold start
            return .cold
        }

        let backgroundDuration = Date().timeIntervalSince(bgTime)

        if backgroundDuration < resumeThresholdSeconds {
            return .resume
        } else {
            return .warm
        }
    }

    // MARK: - Pre-Warming

    /// Pre-warm critical data paths before the UI becomes visible.
    ///
    /// This runs on `willEnterForeground`, giving us a head start while the system
    /// is still compositing the snapshot transition animation.
    private func preWarmCriticalData() {
        PerformanceMonitor.shared.startOperation("pre_warm")

        // Pre-warm workout data (most common user action is viewing today's workout)
        Task { @MainActor in
            await WorkoutPreloadService.shared.preloadIfNeeded()
        }

        // Refresh subscription status in case it changed while backgrounded
        Task {
            await StoreKitService.shared.updateSubscriptionStatus()
        }

        // Restore cached scene state so views can render immediately with previous data
        SceneRestorationCoordinator.shared.prepareForRestoration()

        PerformanceMonitor.shared.finishOperation("pre_warm")
    }

    // MARK: - Progressive Data Refresh

    /// Show cached data immediately, then refresh in the background.
    ///
    /// For warm starts, we rely on `APIResponseCache`'s stale-while-revalidate behavior.
    /// This method ensures cache invalidation hints are set so background revalidation
    /// triggers for the most critical data paths.
    ///
    /// - Parameter launchType: The detected launch type (warm or resume).
    private func startProgressiveRefresh(launchType: AppLaunchType) {
        PerformanceMonitor.shared.startOperation("progressive_refresh_\(launchType.rawValue)")

        switch launchType {
        case .resume:
            // Resume: lightweight refresh — only check subscription and streak
            Task {
                async let subscriptionRefresh: () = StoreKitService.shared.updateSubscriptionStatus()
                async let streakRefresh: () = StreakService.shared.checkStreak()
                _ = await (subscriptionRefresh, streakRefresh)

                PerformanceMonitor.shared.finishOperation("progressive_refresh_\(launchType.rawValue)")
            }

        case .warm:
            // Warm: more thorough refresh — workout data, health sync, streak
            Task {
                async let workoutRefresh: () = WorkoutPreloadService.shared.preloadIfNeeded()
                async let subscriptionRefresh: () = StoreKitService.shared.updateSubscriptionStatus()
                async let streakRefresh: () = StreakService.shared.checkStreak()
                async let healthSync: () = HealthSyncManager.shared.syncOnLaunchIfEnabled()
                _ = await (workoutRefresh, subscriptionRefresh, streakRefresh, healthSync)

                PerformanceMonitor.shared.finishOperation("progressive_refresh_\(launchType.rawValue)")
            }

        case .cold:
            // Cold start is handled by LaunchOptimizer — no additional work here
            break
        }
    }

    // MARK: - Timing

    /// Record the foreground transition timing and report to PerformanceMonitor.
    private func recordTransitionTiming(launchType: AppLaunchType) {
        guard let entryTime = foregroundEntryTime else { return }

        let durationMs = Date().timeIntervalSince(entryTime) * 1000.0

        let record = ResumeTimingRecord(
            launchType: launchType,
            durationMs: durationMs,
            timestamp: Date(),
            preWarmHit: didPreWarmForCurrentTransition
        )

        // Store in rolling buffer
        timingHistory.append(record)
        if timingHistory.count > maxTimingHistory {
            timingHistory.removeFirst(timingHistory.count - maxTimingHistory)
        }

        // Report to PerformanceMonitor
        PerformanceMonitor.shared.addBreadcrumb(
            category: "warm_start",
            message: "\(launchType.rawValue) completed",
            data: [
                "duration_ms": String(format: "%.1f", durationMs),
                "pre_warm_hit": String(didPreWarmForCurrentTransition)
            ]
        )

        // Log to analytics
        ErrorLogger.shared.logUserAction(
            action: "foreground_transition",
            properties: [
                "launch_type": launchType.rawValue,
                "duration_ms": Int(durationMs),
                "pre_warm_hit": didPreWarmForCurrentTransition
            ]
        )

        // Warn on slow transitions
        let threshold: Double = launchType == .resume ? 200.0 : 500.0
        if durationMs > threshold {
            logger.warning("Slow \(launchType.rawValue): \(String(format: "%.0f", durationMs))ms (threshold: \(String(format: "%.0f", threshold))ms)")
            ErrorLogger.shared.logWarning("Slow \(launchType.rawValue): \(Int(durationMs))ms > \(Int(threshold))ms")
        } else {
            logger.info("\(launchType.rawValue) completed in \(String(format: "%.1f", durationMs))ms")
        }
    }

    // MARK: - Timing Reports

    /// Average resume-to-interactive time for a given launch type (in milliseconds).
    func averageTimingMs(for launchType: AppLaunchType) -> Double? {
        let relevant = timingHistory.filter { $0.launchType == launchType }
        guard !relevant.isEmpty else { return nil }
        return relevant.map(\.durationMs).reduce(0, +) / Double(relevant.count)
    }

    /// P95 resume-to-interactive time for a given launch type (in milliseconds).
    func p95TimingMs(for launchType: AppLaunchType) -> Double? {
        let relevant = timingHistory.filter { $0.launchType == launchType }.map(\.durationMs).sorted()
        guard !relevant.isEmpty else { return nil }
        let index = Int(Double(relevant.count - 1) * 0.95)
        return relevant[min(index, relevant.count - 1)]
    }

    /// Get a performance report for warm start / resume timings.
    func getTimingReport() -> String {
        var report = "=== Warm Start / Resume Timing Report ===\n"
        report += "Current launch type: \(currentLaunchType.rawValue)\n\n"

        for type in [AppLaunchType.warm, .resume] {
            let records = timingHistory.filter { $0.launchType == type }
            guard !records.isEmpty else { continue }

            let avg = records.map(\.durationMs).reduce(0, +) / Double(records.count)
            let sorted = records.map(\.durationMs).sorted()
            let p95Index = Int(Double(sorted.count - 1) * 0.95)
            let p95 = sorted[min(p95Index, sorted.count - 1)]
            let preWarmRate = Double(records.filter(\.preWarmHit).count) / Double(records.count) * 100

            report += "\(type.rawValue) (\(records.count) samples):\n"
            report += "  Avg: \(String(format: "%.0f", avg))ms\n"
            report += "  P95: \(String(format: "%.0f", p95))ms\n"
            report += "  Pre-warm hit rate: \(String(format: "%.0f", preWarmRate))%\n\n"
        }

        report += "========================================="
        return report
    }
}

// MARK: - Scene Phase Value

/// A Sendable representation of SwiftUI's `ScenePhase` for use with WarmStartOptimizer.
/// This avoids requiring SwiftUI import in the optimizer and simplifies testing.
enum ScenePhaseValue: String, Sendable {
    case active
    case inactive
    case background
}
