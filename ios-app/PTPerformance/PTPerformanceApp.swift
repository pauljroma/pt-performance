import SwiftUI
import WidgetKit
import AppIntents
#if canImport(Sentry)
import Sentry
#endif

// MARK: - Deep Link Destination

/// Deep link destinations for widget tap navigation and Siri intents
enum DeepLinkDestination: Equatable {
    case readiness
    case workout(sessionId: String)
    case streak
    case today
    case schedule
    case recovery
    // ACP-826: Siri Shortcuts deep links
    case startWorkout
    case logExercise
    case restTimer(seconds: Int)
    case progress

    /// Parse URL into destination
    static func from(url: URL) -> DeepLinkDestination? {
        guard url.scheme == "ptperformance" else { return nil }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch host {
        case "readiness":
            return .readiness
        case "workout":
            // Handle ptperformance://workout/{sessionId}
            if let sessionId = pathComponents.first {
                return .workout(sessionId: sessionId)
            }
            return nil
        case "streak":
            return .streak
        case "today":
            return .today
        case "schedule":
            return .schedule
        case "recovery":
            return .recovery
        // ACP-826: Siri Shortcuts deep links
        case "start-workout":
            return .startWorkout
        case "log-exercise":
            return .logExercise
        case "rest-timer":
            if let secondsString = queryItems?.first(where: { $0.name == "seconds" })?.value,
               let seconds = Int(secondsString) {
                return .restTimer(seconds: seconds)
            }
            return .restTimer(seconds: 90) // Default 90 seconds
        case "progress":
            return .progress
        default:
            return nil
        }
    }
}

@main
struct PTPerformanceApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var storeKit = StoreKitService.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // BUILD 286: Initialize Sentry error monitoring (ACP-599)
        SentryConfig.initialize()

        // Track app launch performance
        PerformanceMonitor.shared.trackAppLaunch()

        // ACP-826: Register App Shortcuts for Siri integration
        if #available(iOS 16.0, *) {
            PTPerformanceShortcuts.updateAppShortcutParameters()
        }

        // ACP-827: Register background tasks for Apple Health sync
        HealthSyncManager.shared.registerBackgroundTasks()

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
                .environmentObject(storeKit)
                .onAppear {
                    PerformanceMonitor.shared.finishAppLaunch()
                }
                .task {
                    await storeKit.loadProducts()
                    await storeKit.updateSubscriptionStatus()

                    // Sync any pending offline exercise logs on app launch
                    await OfflineQueueManager.shared.syncPendingLogs()

                    // ACP-827: Sync Apple Health data on launch if enabled
                    await HealthSyncManager.shared.syncOnLaunchIfEnabled()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        // Refresh widget data when app becomes active
                        Task {
                            await refreshWidgetData()
                        }
                        // ACP-826: Check for pending Siri intents
                        Task { @MainActor in
                            SiriIntentService.shared.checkForPendingIntents()
                        }
                    } else if newPhase == .background {
                        // ACP-827: Schedule background health sync when entering background
                        Task { @MainActor in
                            HealthSyncManager.shared.scheduleBackgroundSync()
                        }
                    }
                }
        }
    }

    // MARK: - Deep Link Handling

    /// Handle incoming deep links for both auth and widget navigation
    private func handleDeepLink(_ url: URL) {
        // First, check if this is a widget navigation deep link
        if let destination = DeepLinkDestination.from(url: url) {
            appState.pendingDeepLink = destination

            // Log deep link navigation for analytics
            ErrorLogger.shared.logUserAction(
                action: "deep_link_opened",
                properties: [
                    "destination": String(describing: destination),
                    "url": url.absoluteString
                ]
            )
            return
        }

        // Handle auth deep links (e.g., password reset: ptperformance://reset-password#access_token=...)
        Task {
            do {
                let session = try await PTSupabaseClient.shared.client.auth.session(from: url)
                await MainActor.run {
                    appState.isAuthenticated = true
                    appState.userId = session.user.id.uuidString
                }
                await PTSupabaseClient.shared.fetchUserRole(userId: session.user.id.uuidString)
                await MainActor.run {
                    if let role = PTSupabaseClient.shared.userRole {
                        appState.userRole = role
                    }
                }
            } catch {
                print("Failed to handle auth deep link: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Widget Refresh

    /// Refresh all widget data when app becomes active
    private func refreshWidgetData() async {
        // Only refresh if user is authenticated
        guard appState.isAuthenticated else { return }

        // Reload all widget timelines to ensure fresh data
        WidgetCenter.shared.reloadAllTimelines()

        // Log refresh for debugging
        print("[PTPerformanceApp] Refreshed widget timelines on app active")
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

    /// Pending deep link destination from widget tap or URL scheme
    /// Views should observe this and navigate accordingly, then set to nil
    @Published var pendingDeepLink: DeepLinkDestination? = nil

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
