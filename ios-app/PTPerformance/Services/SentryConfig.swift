//
//  SentryConfig.swift
//  PTPerformance
//
//  BUILD 95 - Agent 10: Sentry configuration and initialization
//

import Foundation
// TODO: Add Sentry package dependency via Xcode
// import Sentry

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
        // TODO: Uncomment when Sentry package is added
        /*
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.releaseName = releaseName

            // Performance monitoring
            options.tracesSampleRate = tracesSampleRate

            // Enable profiling for performance insights
            options.profilesSampleRate = 0.1 // Profile 10% of transactions

            // Session tracking
            options.enableAutoSessionTracking = enableAutoSessionTracking
            options.enableAutoBreadcrumbTracking = enableAutoBreadcrumbTracking

            // Enable network tracking
            options.enableNetworkTracking = true
            options.enableFileIOTracking = true

            // Error tracking
            options.attachStacktrace = attachStacktrace
            options.attachScreenshot = true // Capture screenshots on errors
            options.attachViewHierarchy = true // Capture view hierarchy

            // Privacy filters
            options.beforeSend = { event in
                return filterSensitiveData(event)
            }

            // Configure tags for filtering
            options.setTag(value: UIDevice.current.model, key: "device_model")
            options.setTag(value: UIDevice.current.systemVersion, key: "os_version")

            // Debug logging
            #if DEBUG
            options.debug = true
            #endif
        }

        print("[Sentry] Initialized with environment: \(environment), release: \(releaseName)")
        print("[Sentry] Alert Thresholds:")
        print("  - Crash Rate: \(AlertThresholds.crashRatePercent)%")
        print("  - Error Rate: \(AlertThresholds.errorRatePerSession) per session")
        print("  - Slow Transactions: >\(AlertThresholds.slowTransactionSeconds)s")
        */

        print("[Sentry] Configuration ready (SDK not yet integrated)")
        print("  Environment: \(environment)")
        print("  Release: \(releaseName)")
        print("  Traces Sample Rate: \(tracesSampleRate)")
        print("\n[Sentry] Alert Thresholds Configured:")
        print("  - Crash Rate: \(AlertThresholds.crashRatePercent)%")
        print("  - Error Rate: \(AlertThresholds.errorRatePerSession) errors/session")
        print("  - Slow Transactions: >\(AlertThresholds.slowTransactionSeconds)s")
        print("  - API Error Rate: \(AlertThresholds.apiErrorRatePercent)%")
        print("  - Memory Usage: >\(AlertThresholds.memoryUsageMB)MB")
        print("  - App Launch: >\(AlertThresholds.appLaunchTimeSeconds)s (p95)")
    }

    // MARK: - Privacy Filtering

    /// Filter sensitive data from Sentry events
    private static func filterSensitiveData(_ event: Any) -> Any? {
        // TODO: Implement when Sentry is added
        /*
        // Remove email addresses, tokens, passwords
        if var user = event.user {
            user.email = nil // Don't track emails for privacy
        }

        // Remove sensitive request data
        if var request = event.request {
            // Remove auth headers
            request.headers?.removeValue(forKey: "Authorization")
            request.headers?.removeValue(forKey: "Cookie")
        }
        */

        return event
    }
}
