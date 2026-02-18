//
//  LaunchOptimizer.swift
//  PTPerformance
//
//  ACP-932: Cold Start Optimization - Phased initialization for <1 second cold start
//

import Foundation
import os.log

/// Phased launch optimizer that splits app initialization into three phases:
/// - Phase 1 (Critical Path, <200ms): Only PerformanceMonitor launch tracking
/// - Phase 2 (Visible UI, <500ms): StoreKit products and subscription status
/// - Phase 3 (Background, async): Everything else — Sentry, health sync, security, push, etc.
///
/// This ensures the first frame renders as fast as possible while deferring
/// non-essential work to background priorities.
final class LaunchOptimizer {

    // MARK: - Singleton

    static let shared = LaunchOptimizer()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "LaunchOptimizer")

    /// Use mach_absolute_time for high-precision launch timing
    /// This is captured at static-init time, before main() runs,
    /// giving the most accurate cold start measurement.
    static let launchStartMachTime: UInt64 = {
        return mach_absolute_time()
    }()

    /// Cached mach timebase conversion factor (numer/denom), computed once.
    private static let machTimebaseNanosPerTick: Double = {
        var timebaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timebaseInfo)
        return Double(timebaseInfo.numer) / Double(timebaseInfo.denom)
    }()

    /// Convert mach absolute time to seconds
    private static func machTimeToSeconds(_ elapsed: UInt64) -> Double {
        let nanos = Double(elapsed) * machTimebaseNanosPerTick
        return nanos / 1_000_000_000.0
    }

    /// Elapsed time since launch in seconds (high precision)
    static var elapsedSinceLaunch: Double {
        let now = mach_absolute_time()
        // Guard against unsigned underflow: if launchStartMachTime was captured
        // after `now` (static init ordering), return 0 instead of trapping.
        guard now >= launchStartMachTime else { return 0 }
        return machTimeToSeconds(now &- launchStartMachTime)
    }

    /// Elapsed time since launch in milliseconds (high precision)
    static var elapsedSinceLaunchMs: Double {
        return elapsedSinceLaunch * 1000.0
    }

    private init() {}

    // MARK: - Phase 1: Critical Path (<200ms)

    /// Phase 1: Minimal synchronous work required before first frame.
    /// Only tracks app launch via PerformanceMonitor. Must complete synchronously in init().
    func runCriticalPath() {
        PerformanceMonitor.shared.trackAppLaunch()
        PerformanceMonitor.shared.recordColdStartMilestone("phase1_critical_path")

        let elapsedMs = Self.elapsedSinceLaunchMs
        logger.info("Phase 1 (critical path) complete: \(String(format: "%.1f", elapsedMs))ms")
    }

    // MARK: - Phase 2: Visible UI (<500ms)

    /// Phase 2: Load data needed for the initial visible UI.
    /// StoreKit products and subscription status affect premium feature gating.
    /// Called from the .task {} modifier on RootView so it runs concurrently with first render.
    func runVisibleUI() async {
        PerformanceMonitor.shared.recordColdStartMilestone("phase2_visible_ui_start")

        // StoreKit and subscription status affect UI state (premium badges, feature gates)
        async let storeKitProducts = StoreKitService.shared.loadProducts()
        async let subscriptionStatus = StoreKitService.shared.updateSubscriptionStatus()

        _ = await storeKitProducts
        _ = await subscriptionStatus

        PerformanceMonitor.shared.recordColdStartMilestone("phase2_visible_ui_end")

        let elapsedMs = Self.elapsedSinceLaunchMs
        logger.info("Phase 2 (visible UI) complete: \(String(format: "%.1f", elapsedMs))ms since launch")
    }

    // MARK: - Phase 3: Background (async, no target)

    /// Phase 3: All remaining initialization that does not affect the initial UI.
    /// Runs at utility priority to avoid competing with UI rendering.
    func runBackground() async {
        PerformanceMonitor.shared.recordColdStartMilestone("phase3_background_start")

        // Initialize Sentry error monitoring (ACP-599)
        SentryConfig.initialize()

        // ACP-826: Register App Shortcuts for Siri integration
        if #available(iOS 16.0, *) {
            await MainActor.run {
                PTPerformanceShortcuts.updateAppShortcutParameters()
            }
        }

        // ACP-827: Register background tasks for Apple Health sync
        await MainActor.run {
            HealthSyncManager.shared.registerBackgroundTasks()
        }

        // Initialize CacheCoordinator for unified memory management
        await MainActor.run {
            _ = CacheCoordinator.shared
        }

        // Initialize PushNotificationService for prescription alerts
        await PushNotificationService.shared.initialize()

        // ACP-1044: Keychain security migration and audit
        SecureStore.shared.migrateIfNeeded()

        #if DEBUG
        // ACP-1044: Log keychain audit in debug builds
        SecureStore.shared.auditKeychainItems()
        #endif

        // ACP-1043: Initialize data encryption key on first launch
        do {
            try DataEncryptionService.shared.initializeKeyIfNeeded()
        } catch {
            DebugLogger.shared.error("LaunchOptimizer", "Failed to initialize encryption key: \(error.localizedDescription)")
        }

        // ACP-1045: Apply file protection to app directories
        SecureFileManager.shared.applyFileProtection()

        // ACP-1045: Jailbreak detection
        JailbreakDetector.shared.check()

        // ACP-1043: Verify App Transport Security configuration
        TransportSecurityService.shared.verifyConfiguration()

        // ACP-1056: Start real-time security monitoring
        await MainActor.run {
            SecurityMonitor.shared.startMonitoring()
        }

        // ACP-1051: Log app launch in audit trail
        await AuditLogger.shared.logAuthentication(
            action: "app_launched",
            success: true,
            details: "cold_start"
        )

        PerformanceMonitor.shared.recordColdStartMilestone("phase3_background_end")

        let elapsedMs = Self.elapsedSinceLaunchMs
        logger.info("Phase 3 (background) complete: \(String(format: "%.1f", elapsedMs))ms since launch")
    }
}
