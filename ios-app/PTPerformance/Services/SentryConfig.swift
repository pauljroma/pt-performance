//
//  SentryConfig.swift
//  PTPerformance
//
//  BUILD 95 - Agent 10: Sentry configuration and initialization
//

import Foundation
#if canImport(Sentry)
import Sentry
#endif

/// Sentry configuration for error and performance monitoring
enum SentryConfig {

    // MARK: - DSN Configuration

    /// Sentry DSN (Data Source Name)
    /// This should be set via environment variable in production
    static var dsn: String {
        #if DEBUG
        // Empty DSN for debug builds - only use local logging
        return ""
        #else
        // Production DSN from environment or fallback
        return ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
        #endif
    }

    // MARK: - Environment

    static var environment: String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }

    // MARK: - Release Information

    static var releaseName: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        return "\(version) (\(build))"
    }

    // MARK: - Sampling Rates

    /// Sample rate for performance traces (0.0 to 1.0)
    /// 1.0 = capture 100% of transactions
    static var tracesSampleRate: Double {
        #if DEBUG
        return 1.0 // Capture all in development
        #else
        return 0.3 // Capture 30% in production to reduce cost
        #endif
    }

    /// Sample rate for error events (0.0 to 1.0)
    static var errorSampleRate: Double {
        return 1.0 // Capture all errors
    }

    // MARK: - Feature Flags

    static var enableAutoSessionTracking: Bool {
        return true
    }

    static var enableAutoBreadcrumbTracking: Bool {
        return true
    }

    static var attachStacktrace: Bool {
        return true
    }

    // MARK: - Alert Thresholds

    /// Production alert thresholds for monitoring
    enum AlertThresholds {
        /// Crash rate threshold (percentage) - alert if exceeded
        static let crashRatePercent: Double = 1.0

        /// Error rate threshold (errors per user session) - alert if exceeded
        static let errorRatePerSession: Double = 5.0

        /// Slow transaction threshold (seconds) - alert if p95 exceeds
        static let slowTransactionSeconds: Double = 3.0

        /// API error rate (percentage) - alert if exceeded
        static let apiErrorRatePercent: Double = 5.0

        /// Memory usage threshold (MB) - warn if exceeded
        static let memoryUsageMB: Double = 500.0

        /// App launch time threshold (seconds) - warn if p95 exceeds
        static let appLaunchTimeSeconds: Double = 2.0
    }

    // MARK: - Initialization

    /// Initialize Sentry SDK
    /// Call this in PTPerformanceApp.init()
    static func initialize() {
        #if canImport(Sentry)
        guard !dsn.isEmpty else {
            print("[Sentry] No DSN configured, skipping initialization")
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.releaseName = releaseName
            options.tracesSampleRate = NSNumber(value: tracesSampleRate)
            options.enableAutoSessionTracking = enableAutoSessionTracking
            options.enableAutoBreadcrumbTracking = enableAutoBreadcrumbTracking
            options.enableNetworkTracking = true
            options.attachStacktrace = attachStacktrace
            options.attachScreenshot = true
            options.attachViewHierarchy = true

            options.beforeSend = { event in
                return filterSensitiveData(event)
            }

            #if DEBUG
            options.debug = true
            #endif
        }

        print("[Sentry] Initialized: env=\(environment), release=\(releaseName)")
        #else
        print("[Sentry] SDK not installed. Add sentry-cocoa SPM package to enable.")
        print("  Environment: \(environment), Release: \(releaseName)")
        #endif
    }

    // MARK: - Privacy Filtering

    #if canImport(Sentry)
    /// Filter sensitive data from Sentry events (HIPAA compliance)
    private static func filterSensitiveData(_ event: Event) -> Event? {
        // Remove email addresses for privacy
        if event.user != nil {
            event.user?.email = nil
        }
        // Remove auth headers from request data
        if event.request != nil {
            event.request?.headers?.removeValue(forKey: "Authorization")
            event.request?.headers?.removeValue(forKey: "Cookie")
        }
        return event
    }
    #else
    private static func filterSensitiveData(_ event: Any) -> Any? {
        return event
    }
    #endif
}
