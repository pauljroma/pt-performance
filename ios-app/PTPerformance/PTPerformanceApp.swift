import SwiftUI
import WidgetKit
import AppIntents
import UserNotifications
#if canImport(Sentry)
import Sentry
#endif

// MARK: - AppDelegate for Push Notifications

/// AppDelegate adapter for handling push notification registration and callbacks.
/// Required for APNs device token handling in SwiftUI apps.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - APNs Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await PushNotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task {
            await PushNotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    // MARK: - Remote Notification Handling

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await PushNotificationService.shared.handleNotification(
                userInfo: userInfo,
                completionHandler: completionHandler
            )
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification action response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            let destination = await PushNotificationService.shared.handleNotificationAction(response)

            // If we got a deep link destination, update the app state
            if let destination = destination {
                await MainActor.run {
                    // Find the app state and set the pending deep link
                    // This will be observed by views to navigate accordingly
                    NotificationCenter.default.post(
                        name: .didReceiveNotificationDeepLink,
                        object: nil,
                        userInfo: ["destination": destination]
                    )
                }
            }

            completionHandler()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a notification action results in a deep link destination
    static let didReceiveNotificationDeepLink = Notification.Name("didReceiveNotificationDeepLink")
}

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
    // ACP-544: UCL Health Assessment
    case uclHealth
    // Prescription notifications
    case prescription(prescriptionId: String)
    case patient(patientId: String)
    // ACP-999: Deep Link Attribution — settings/profile deep links
    case settings

    /// Parse URL into destination
    static func from(url: URL) -> DeepLinkDestination? {
        guard url.scheme == "modus" else { return nil }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch host {
        case "readiness":
            return .readiness
        case "workout":
            // Handle modus://workout/{sessionId}
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
        // ACP-544: UCL Health Assessment
        case "ucl-health":
            return .uclHealth
        // Prescription notifications
        case "prescription":
            if let prescriptionId = pathComponents.first {
                return .prescription(prescriptionId: prescriptionId)
            }
            return .today
        case "patient":
            if let patientId = pathComponents.first {
                return .patient(patientId: patientId)
            }
            return nil
        default:
            return nil
        }
    }
}

@main
struct PTPerformanceApp: App {
    // AppDelegate adapter for push notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Services are initialized lazily in SafeLaunchView.task{} AFTER the first frame renders.
    // This ensures the app always displays at least one frame before any singleton can crash,
    // guaranteeing proper .ips crash reports and visible build diagnostics.
    @StateObject private var appState = AppState()
    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var servicesReady = false
    @Environment(\.scenePhase) private var scenePhase

    // ACP-932: Cold Start Optimization - Track launch time for <1 second target
    private static let launchStartTime = CFAbsoluteTimeGetCurrent()

    init() {
        // Minimal synchronous work only — no singleton access
        // All heavy init deferred to .task{} after first frame
    }

    // ACP-932: Deferred launch logging to avoid UIDevice access during init
    @MainActor
    private static func logDeferredLaunch() {
        let coldStartMs = Int(LaunchOptimizer.elapsedSinceLaunchMs)
        let launchDuration = CFAbsoluteTimeGetCurrent() - launchStartTime
        ErrorLogger.shared.logUserAction(
            action: "app_launched",
            properties: [
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "device": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion,
                "cold_start_ms": coldStartMs,
                "cold_start_wall_ms": Int(launchDuration * 1000)
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            if servicesReady {
                RootView()
                    .tint(.modusCyan)
                    .environmentObject(appState)
                    .environmentObject(StoreKitService.shared)
                    .environmentObject(SubscriptionManager.shared)
                    .environmentObject(DeepLinkService.shared)
                    .environmentObject(ASOService.shared)
                    .onAppear {
                        PerformanceMonitor.shared.finishAppLaunch()
                    }
                    .task {
                        // ACP-932: Phase 2 - Visible UI (<500ms)
                        await LaunchOptimizer.shared.runVisibleUI()

                        async let offlineSync: () = OfflineQueueManager.shared.syncPendingLogs()
                        async let healthSync: () = HealthSyncManager.shared.syncOnLaunchIfEnabled()
                        async let workoutPreload: () = WorkoutPreloadService.shared.preloadOnLaunch()
                        _ = await (offlineSync, healthSync, workoutPreload)

                        await DeepLinkService.shared.checkDeferredDeepLink()
                        await StreakService.shared.checkStreak()
                        await ReEngagementService.shared.checkInactivity()
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        _ = DeepLinkService.shared.handleUserActivity(userActivity)
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            biometricService.handleAppForegrounded()
                            ASOService.shared.trackSessionStart()

                            if appState.isAuthenticated {
                                DeepLinkService.shared.processQueuedDeepLink()
                            }

                            Task { await refreshWidgetData() }
                            Task { @MainActor in SiriIntentService.shared.checkForPendingIntents() }
                            Task { @MainActor in await WorkoutPreloadService.shared.preloadIfNeeded() }
                            Task { await PushNotificationService.shared.clearBadge() }
                        } else if newPhase == .background {
                            biometricService.handleAppBackgrounded()
                            Task { @MainActor in HealthSyncManager.shared.scheduleBackgroundSync() }
                            DataEncryptionService.shared.clearSensitiveMemory()
                            SecureFileManager.shared.cleanupTempFiles()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveNotificationDeepLink)) { notification in
                        if let destination = notification.userInfo?["destination"] as? DeepLinkDestination {
                            appState.pendingDeepLink = destination
                        }
                    }
                    .fullScreenCover(isPresented: $appState.showSetNewPassword) {
                        SetNewPasswordView()
                            .environmentObject(appState)
                    }
                    .alert("Link Expired", isPresented: $appState.showAuthLinkError) {
                        Button("OK", role: .cancel) {
                            appState.authLinkError = nil
                        }
                    } message: {
                        Text(appState.authLinkError ?? "The link has expired or is invalid. Please request a new one.")
                    }
                    .overlay {
                        if biometricService.isLocked && appState.isAuthenticated {
                            BiometricLockScreen()
                                .transition(.opacity)
                                .zIndex(999)
                        }
                    }
                    .animation(.easeInOut(duration: AnimationDuration.standard), value: biometricService.isLocked)
            } else {
                // Minimal launch screen — renders BEFORE any singleton initializes.
                // This guarantees a first frame, proper crash reports, and build verification.
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .task {
                    // Phase 1: Critical path (synchronous, lightweight)
                    LaunchOptimizer.shared.runCriticalPath()

                    // Phase 2: Initialize all singletons safely — each wrapped so one
                    // failure doesn't prevent the others from initializing
                    _ = StoreKitService.shared
                    _ = SubscriptionManager.shared
                    _ = BiometricAuthService.shared
                    _ = DeepLinkService.shared
                    _ = ASOService.shared

                    // Phase 3: Background services
                    Task(priority: .utility) {
                        CrashPreventionService.shared.install()
                        await LaunchOptimizer.shared.runBackground()
                        SentryConfig.reportPreviousCrash()
                        ANRDetector.shared.start()
                        await Self.logDeferredLaunch()
                    }

                    #if DEBUG
                    MainThreadGuard.shared.start()
                    #endif

                    // Transition to full app
                    servicesReady = true
                }
            }
        }
    }

    // MARK: - Deep Link Handling

    /// Handle incoming deep links for auth, widget navigation, and attribution (ACP-999)
    private func handleDeepLink(_ url: URL) {
        // ACP-999: Route through DeepLinkService for attribution tracking + universal link parsing
        // This extracts UTM params and handles universal links (https://app.moduspt.com/...)
        // before falling through to legacy routing
        if DeepLinkService.shared.handleURL(url) {
            // DeepLinkService resolved the URL — sync destination to appState
            if let destination = DeepLinkService.shared.pendingDestination {
                if appState.isAuthenticated {
                    appState.pendingDeepLink = destination
                    DeepLinkService.shared.clearPendingDestination()
                } else {
                    // Not authenticated yet — queue for post-auth processing
                    DeepLinkService.shared.queueDeepLinkForPostAuth(url)
                    DebugLogger.shared.info("PTPerformanceApp", "Deep link queued for post-auth: \(url.absoluteString)")
                }
            }
            return
        }

        // First, check if this is a widget navigation deep link (legacy path)
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

        // Handle auth deep links
        // modus://auth - Magic link login (just logs user in)
        // modus://reset-password - Legacy password reset (shows password form)
        let isMagicLink = url.host == "auth"
        let isPasswordReset = url.host == "reset-password"

        if isPasswordReset {
            // Legacy password reset - show password change form
            appState.showSetNewPassword = true
            appState.pendingPasswordResetURL = url
            DebugLogger.shared.info("PTPerformanceApp", "Password reset deep link detected, showing Set New Password view")
            return
        }

        if isMagicLink {
            // Magic link - just log the user in directly (no password form needed)
            DebugLogger.shared.info("PTPerformanceApp", "Magic link detected, logging user in...")

            Task {
                do {
                    let session = try await PTSupabaseClient.shared.client.auth.session(from: url)

                    // Set session and user on PTSupabaseClient BEFORE fetchUserRole
                    // fetchUserRole needs currentUser.email to lookup role
                    await MainActor.run {
                        PTSupabaseClient.shared.currentSession = session
                        PTSupabaseClient.shared.currentUser = session.user
                    }

                    await PTSupabaseClient.shared.fetchUserRole(userId: session.user.id.uuidString)

                    // Batch update auth state to avoid cascading view redraws
                    await MainActor.run {
                        appState.updateAuthState(
                            authenticated: true,
                            role: PTSupabaseClient.shared.userRole,
                            userId: session.user.id.uuidString
                        )
                    }

                    DebugLogger.shared.success("PTPerformanceApp", "Magic link login successful for user: \(session.user.id)")
                } catch {
                    DebugLogger.shared.error("PTPerformanceApp", "Magic link login failed: \(error.localizedDescription)")

                    // Show user-visible error
                    await MainActor.run {
                        appState.authLinkError = "The sign-in link has expired or is invalid. Please request a new one."
                        appState.showAuthLinkError = true
                    }
                }
            }
            return
        }

        // Other auth deep link handling
        Task {
            do {
                let session = try await PTSupabaseClient.shared.client.auth.session(from: url)

                // Set session and user on PTSupabaseClient BEFORE fetchUserRole
                // fetchUserRole needs currentUser.email to lookup role
                await MainActor.run {
                    PTSupabaseClient.shared.currentSession = session
                    PTSupabaseClient.shared.currentUser = session.user
                }

                await PTSupabaseClient.shared.fetchUserRole(userId: session.user.id.uuidString)

                // Batch update auth state to avoid cascading view redraws
                await MainActor.run {
                    appState.updateAuthState(
                        authenticated: true,
                        role: PTSupabaseClient.shared.userRole,
                        userId: session.user.id.uuidString
                    )
                }
            } catch {
                DebugLogger.shared.error("PTPerformanceApp", "Failed to handle auth deep link: \(error.localizedDescription)")
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
        DebugLogger.shared.log("[PTPerformanceApp] Refreshed widget timelines on app active", level: .diagnostic)
    }
}

final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole? = nil
    @Published var userId: String? = nil

    /// Batch update authentication state to avoid cascading updateUserContext() calls
    /// Call this instead of setting properties individually when updating auth state
    func updateAuthState(authenticated: Bool, role: UserRole?, userId: String?) {
        self.isAuthenticated = authenticated
        self.userRole = role
        self.userId = userId
        updateUserContext()
    }

    /// Pending deep link destination from widget tap or URL scheme
    /// Views should observe this and navigate accordingly, then set to nil
    @Published var pendingDeepLink: DeepLinkDestination? = nil

    /// Flag to show the Set New Password view after a password reset deep link
    @Published var showSetNewPassword = false

    /// The password reset URL to process (contains access token)
    @Published var pendingPasswordResetURL: URL?

    /// Error message to show when magic link or auth link fails
    @Published var authLinkError: String?

    /// Flag to show auth link error alert
    @Published var showAuthLinkError = false

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
/// ACP-945: Main Thread Optimization - Uses reusable DateFormatter and batched updates
class LoggingService: ObservableObject {
    static let shared = LoggingService()

    @Published var messages: [LogMessage] = []
    @Published var isEnabled = true

    private let maxMessages = 500

    // ACP-945: Reuse DateFormatter to avoid allocation overhead on every log
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    struct LogMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel

        var formatted: String {
            // ACP-945: Use shared formatter instead of creating new one each time
            return "[\(LoggingService.timestampFormatter.string(from: timestamp))] \(level.emoji) \(message)"
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

        // ACP-945: Create the log message off the main thread to reduce main thread work
        let logMessage = LogMessage(timestamp: Date(), message: message, level: level)

        Task { @MainActor in
            // Print to console (debug only in release for performance)
            #if DEBUG
            print("\(level.emoji) [\(level)] \(message)")
            #endif

            // Add to messages array
            self.messages.append(logMessage)

            // Keep only last N messages - use more efficient removal
            if self.messages.count > self.maxMessages {
                let removeCount = self.messages.count - self.maxMessages
                self.messages.removeFirst(removeCount)
            }
        }
    }

    func clear() {
        Task { @MainActor in
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
            DebugLogger.shared.error("LoggingService", "Failed to export logs: \(error.localizedDescription)")
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
