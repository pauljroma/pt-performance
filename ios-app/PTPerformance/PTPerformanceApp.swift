import SwiftUI
// TODO: Add Sentry package dependency via Xcode for error monitoring
// import Sentry

@main
struct PTPerformanceApp: App {
    @StateObject private var appState = AppState()

    init() {
        // TODO: Re-enable Sentry initialization once package is added
        /*
        // Initialize Sentry for error monitoring and performance tracking
        SentrySDK.start { options in
            // Get DSN from environment or configuration
            // For now, this should be set via build configuration
            #if DEBUG
            options.dsn = "" // Leave empty for debug builds
            options.debug = true
            options.environment = "development"
            #else
            // Production DSN should be injected via build configuration
            options.dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
            options.environment = "production"
            #endif

            // Enable performance monitoring
            options.tracesSampleRate = 1.0 // Capture 100% of transactions for monitoring

            // Enable automatic breadcrumbs
            options.enableAutoSessionTracking = true
            options.enableAutoBreadcrumbTracking = true

            // Attach stack traces to all messages
            options.attachStacktrace = true

            // Set release version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "\(version) (\(build))"
            }

            // Filter out sensitive data
            options.beforeSend = { event in
                // Remove any sensitive data from event
                return event
            }
        }
        */

        // Track app launch performance
        PerformanceMonitor.shared.trackAppLaunch()

        // Log app startup
        ErrorLogger.shared.logUserAction(
            action: "app_launched",
            properties: [
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "device": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onAppear {
                    PerformanceMonitor.shared.finishAppLaunch()
                }
        }
    }
}

final class AppState: ObservableObject {
    @Published var isAuthenticated = false {
        didSet {
            updateUserContext()
        }
    }
    @Published var userRole: UserRole? = nil {
        didSet {
            updateUserContext()
        }
    }
    @Published var userId: String? = nil {
        didSet {
            updateUserContext()
        }
    }

    /// Update Sentry user context when authentication state changes
    private func updateUserContext() {
        if isAuthenticated, let userId = userId {
            // Set user context for error tracking
            ErrorLogger.shared.setUser(
                userId: userId,
                email: nil, // Don't track email for privacy
                userType: userRole?.rawValue ?? "unknown"
            )

            // Log authentication event
            ErrorLogger.shared.logUserAction(
                action: "user_authenticated",
                properties: [
                    "user_role": userRole?.rawValue ?? "unknown"
                ]
            )
        } else {
            // Clear user context on logout
            ErrorLogger.shared.clearUser()
        }
    }
}

// MARK: - Logging Service for On-Screen Diagnostics

/// Shared logging service that captures all diagnostic messages for UI display
class LoggingService: ObservableObject {
    static let shared = LoggingService()

    @Published var messages: [LogMessage] = []
    @Published var isEnabled = true

    private let maxMessages = 500

    struct LogMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel

        var formatted: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return "[\(formatter.string(from: timestamp))] \(level.emoji) \(message)"
        }
    }

    enum LogLevel {
        case diagnostic
        case success
        case error
        case warning

        var emoji: String {
            switch self {
            case .diagnostic: return "🔍"
            case .success: return "✅"
            case .error: return "❌"
            case .warning: return "⚠️"
            }
        }
    }

    private init() {}

    func log(_ message: String, level: LogLevel = .diagnostic) {
        guard isEnabled else { return }

        DispatchQueue.main.async {
            // Also print to console
            print("\(level.emoji) [\(level)] \(message)")

            // Add to messages array
            let logMessage = LogMessage(timestamp: Date(), message: message, level: level)
            self.messages.append(logMessage)

            // Keep only last N messages
            if self.messages.count > self.maxMessages {
                self.messages.removeFirst(self.messages.count - self.maxMessages)
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }

    func getAllLogs() -> String {
        messages.map { $0.formatted }.joined(separator: "\n")
    }

    /// Export logs to a temporary file
    func exportLogs() -> URL? {
        let logContent = getAllLogs()
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "debug-logs-\(Date().timeIntervalSince1970).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try logContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export logs: \(error)")
            return nil
        }
    }

    /// Statistics about the logs
    struct LogStats {
        let totalMessages: Int
        let errorCount: Int
        let warningCount: Int
        let fileSizeFormatted: String
    }

    var logStats: LogStats {
        let errorCount = messages.filter { $0.level == .error }.count
        let warningCount = messages.filter { $0.level == .warning }.count
        let logContent = getAllLogs()
        let byteCount = logContent.data(using: .utf8)?.count ?? 0
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let sizeFormatted = formatter.string(fromByteCount: Int64(byteCount))

        return LogStats(
            totalMessages: messages.count,
            errorCount: errorCount,
            warningCount: warningCount,
            fileSizeFormatted: sizeFormatted
        )
    }

    // Note: DebugLogView is defined in Views/Settings/DebugLogView.swift
}
