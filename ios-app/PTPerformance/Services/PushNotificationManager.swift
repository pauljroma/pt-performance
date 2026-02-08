//
//  PushNotificationManager.swift
//  PTPerformance
//
//  X2Index Phase 2: Push Notification Manager
//  Singleton service for managing push notifications, scheduling, and handling
//

import Foundation
import UserNotifications
import UIKit
import Supabase

// MARK: - Push Notification Manager

/// Singleton manager for push notification operations
///
/// Thread-safe actor that handles:
/// - Permission requests and status
/// - Device token registration
/// - Local notification scheduling (check-in reminders, task reminders)
/// - Notification tap handling and deep link extraction
/// - Notification cancellation
///
/// ## Usage
/// ```swift
/// // Request permission
/// let granted = await PushNotificationManager.shared.requestPermission()
///
/// // Schedule a check-in reminder
/// await PushNotificationManager.shared.scheduleCheckInReminder(at: DateComponents(hour: 8, minute: 0))
///
/// // Handle notification tap
/// if let url = await PushNotificationManager.shared.handleNotificationTap(payload: userInfo) {
///     // Navigate to deep link
/// }
/// ```
actor PushNotificationManager {

    // MARK: - Singleton

    static let shared = PushNotificationManager()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let debugLogger = DebugLogger.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Current device token (hex string)
    private(set) var deviceToken: String?

    /// Whether manager has been initialized
    private var isInitialized = false

    // MARK: - Notification Identifiers

    private enum NotificationIdentifierPrefix {
        static let checkInReminder = "com.getmodus.checkin.reminder"
        static let taskReminder = "com.getmodus.task.reminder"
        static let briefAvailable = "com.getmodus.brief.available"
        static let safetyAlert = "com.getmodus.safety.alert"
        static let streakMilestone = "com.getmodus.streak.milestone"
    }

    // MARK: - Initialization

    private init() {}

    /// Initialize the push notification manager
    ///
    /// Call this early in app launch to set up notification categories
    func initialize() async {
        guard !isInitialized else { return }

        debugLogger.log("Initializing PushNotificationManager", level: .info)

        // Register notification categories with actions
        await registerNotificationCategories()

        isInitialized = true
        debugLogger.log("PushNotificationManager initialized", level: .success)
    }

    /// Register notification categories with interactive actions
    private func registerNotificationCategories() async {
        // Check-in reminder actions
        let startCheckInAction = UNNotificationAction(
            identifier: "START_CHECK_IN",
            title: "Start Check-In",
            options: [.foreground]
        )

        let snooze15MinAction = UNNotificationAction(
            identifier: "SNOOZE_15MIN",
            title: "Snooze 15 min",
            options: []
        )

        let checkInCategory = UNNotificationCategory(
            identifier: NotificationType.checkInReminder.categoryIdentifier,
            actions: [startCheckInAction, snooze15MinAction],
            intentIdentifiers: [],
            options: []
        )

        // Task due actions
        let startTaskAction = UNNotificationAction(
            identifier: "START_TASK",
            title: "Start Task",
            options: [.foreground]
        )

        let markCompleteAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: []
        )

        let taskDueCategory = UNNotificationCategory(
            identifier: NotificationType.taskDue.categoryIdentifier,
            actions: [startTaskAction, markCompleteAction, snooze15MinAction],
            intentIdentifiers: [],
            options: []
        )

        // Brief available actions
        let viewBriefAction = UNNotificationAction(
            identifier: "VIEW_BRIEF",
            title: "View Brief",
            options: [.foreground]
        )

        let briefCategory = UNNotificationCategory(
            identifier: NotificationType.briefAvailable.categoryIdentifier,
            actions: [viewBriefAction],
            intentIdentifiers: [],
            options: []
        )

        // Safety alert actions
        let viewPatientAction = UNNotificationAction(
            identifier: "VIEW_PATIENT",
            title: "View Patient",
            options: [.foreground]
        )

        let callPatientAction = UNNotificationAction(
            identifier: "CALL_PATIENT",
            title: "Call Patient",
            options: [.foreground]
        )

        let safetyCategory = UNNotificationCategory(
            identifier: NotificationType.safetyAlert.categoryIdentifier,
            actions: [viewPatientAction, callPatientAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Streak milestone actions
        let shareStreakAction = UNNotificationAction(
            identifier: "SHARE_STREAK",
            title: "Share",
            options: [.foreground]
        )

        let streakCategory = UNNotificationCategory(
            identifier: NotificationType.streakMilestone.categoryIdentifier,
            actions: [shareStreakAction],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories
        notificationCenter.setNotificationCategories([
            checkInCategory,
            taskDueCategory,
            briefCategory,
            safetyCategory,
            streakCategory
        ])

        debugLogger.log("Registered notification categories", level: .success)
    }

    // MARK: - Permission Management

    /// Request notification permission from the user
    ///
    /// - Returns: `true` if permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional]
            )

            debugLogger.log(
                "Notification permission \(granted ? "granted" : "denied")",
                level: granted ? .success : .warning
            )

            if granted {
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            errorLogger.logError(error, context: "PushNotificationManager.requestPermission")
            return false
        }
    }

    /// Get current notification authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Check if notifications are currently authorized
    func isAuthorized() async -> Bool {
        let status = await getAuthorizationStatus()
        return status == .authorized || status == .provisional
    }

    // MARK: - Device Token Registration

    /// Register device token with the backend
    ///
    /// - Parameter token: Raw device token data from APNs
    func registerDeviceToken(token: Data) async throws {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        debugLogger.log("Received APNs device token: \(tokenString.prefix(16))...", level: .success)

        guard let userId = PTSupabaseClient.shared.userId else {
            debugLogger.log("Cannot register device token: no user ID", level: .warning)
            throw PushNotificationManagerError.notAuthenticated
        }

        // Prepare payload
        struct TokenPayload: Encodable {
            let user_id: String
            let device_token: String
            let platform: String
            let app_version: String
            let bundle_id: String
            let environment: String
            let is_active: Bool
        }

        let payload = TokenPayload(
            user_id: userId,
            device_token: tokenString,
            platform: "ios",
            app_version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            bundle_id: Bundle.main.bundleIdentifier ?? "com.getmodus.app",
            environment: isDebugBuild ? "development" : "production",
            is_active: true
        )

        do {
            // Upsert token in database
            try await supabase
                .from("push_notification_tokens")
                .upsert(payload)
                .execute()

            debugLogger.log("Device token registered with backend", level: .success)
        } catch {
            errorLogger.logError(error, context: "PushNotificationManager.registerDeviceToken")
            throw PushNotificationManagerError.registrationFailed(error)
        }
    }

    /// Unregister device token when user logs out
    func unregisterDeviceToken() async {
        guard let userId = PTSupabaseClient.shared.userId,
              let token = deviceToken else {
            return
        }

        do {
            try await supabase
                .from("push_notification_tokens")
                .update(["is_active": false])
                .eq("user_id", value: userId)
                .eq("device_token", value: token)
                .execute()

            debugLogger.log("Device token unregistered", level: .success)
            self.deviceToken = nil
        } catch {
            errorLogger.logError(error, context: "PushNotificationManager.unregisterDeviceToken")
        }
    }

    // MARK: - Check-In Reminder Scheduling

    /// Schedule a daily check-in reminder
    ///
    /// - Parameter time: Time components for the reminder (hour and minute)
    func scheduleCheckInReminder(at time: DateComponents) async {
        guard await isAuthorized() else {
            debugLogger.log("Cannot schedule check-in reminder: not authorized", level: .warning)
            return
        }

        // Cancel existing check-in reminders first
        await cancelNotifications(withPrefix: NotificationIdentifierPrefix.checkInReminder)

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-In"
        content.body = "Time to complete your daily check-in. How are you feeling today?"
        content.sound = .default
        content.categoryIdentifier = NotificationType.checkInReminder.categoryIdentifier
        content.userInfo = [
            "notification_type": NotificationType.checkInReminder.rawValue,
            "deep_link": "modus://check-in"
        ]

        // Create daily repeating trigger
        var triggerComponents = time
        triggerComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifierPrefix.checkInReminder).daily",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            debugLogger.log(
                "Check-in reminder scheduled for \(time.hour ?? 0):\(String(format: "%02d", time.minute ?? 0))",
                level: .success
            )
        } catch {
            errorLogger.logError(error, context: "PushNotificationManager.scheduleCheckInReminder")
        }
    }

    // MARK: - Task Reminder Scheduling

    /// Schedule a reminder for a protocol task
    ///
    /// - Parameters:
    ///   - task: The protocol task to remind about
    ///   - minutesBefore: Minutes before the task is due to send the reminder
    func scheduleTaskReminder(task: ProtocolTask, minutesBefore: Int) async {
        guard await isAuthorized() else {
            debugLogger.log("Cannot schedule task reminder: not authorized", level: .warning)
            return
        }

        guard let timeString = task.defaultTime,
              let (hour, minute) = parseTimeString(timeString) else {
            debugLogger.log("Cannot schedule task reminder: no default time", level: .warning)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(task.title)"

        let timeDisplay = minutesBefore < 60
            ? "\(minutesBefore) minutes"
            : "\(minutesBefore / 60) hour\(minutesBefore >= 120 ? "s" : "")"

        content.body = "Your \(task.taskType.displayName.lowercased()) task is coming up in \(timeDisplay)."
        content.sound = .default
        content.categoryIdentifier = NotificationType.taskDue.categoryIdentifier
        content.userInfo = [
            "notification_type": NotificationType.taskDue.rawValue,
            "task_id": task.id.uuidString,
            "task_type": task.taskType.rawValue,
            "deep_link": "modus://task/\(task.id.uuidString)"
        ]

        // Calculate reminder time
        var triggerComponents = DateComponents()
        triggerComponents.hour = hour
        triggerComponents.minute = minute

        // Adjust for minutes before
        let calendar = Calendar.current
        let baseDate = calendar.date(from: triggerComponents) ?? Date()
        let reminderDate = calendar.date(byAdding: .minute, value: -minutesBefore, to: baseDate) ?? baseDate

        let adjustedComponents = calendar.dateComponents([.hour, .minute], from: reminderDate)

        // Create trigger based on frequency
        let trigger: UNNotificationTrigger
        switch task.frequency {
        case .daily, .twiceDaily:
            trigger = UNCalendarNotificationTrigger(dateMatching: adjustedComponents, repeats: true)
        case .everyOtherDay, .weekly:
            // For less frequent tasks, schedule as one-time and reschedule after completion
            trigger = UNCalendarNotificationTrigger(dateMatching: adjustedComponents, repeats: false)
        case .asNeeded:
            // Don't schedule reminders for as-needed tasks
            return
        }

        let identifier = "\(NotificationIdentifierPrefix.taskReminder).\(task.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            debugLogger.log(
                "Task reminder scheduled for \(task.title) at \(adjustedComponents.hour ?? 0):\(String(format: "%02d", adjustedComponents.minute ?? 0))",
                level: .success
            )
        } catch {
            errorLogger.logError(error, context: "PushNotificationManager.scheduleTaskReminder")
        }
    }

    /// Cancel a specific task reminder
    func cancelTaskReminder(taskId: UUID) async {
        let identifier = "\(NotificationIdentifierPrefix.taskReminder).\(taskId.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        debugLogger.log("Cancelled task reminder for \(taskId)", level: .info)
    }

    // MARK: - Cancel Notifications

    /// Cancel all scheduled notifications
    func cancelAllScheduled() async {
        notificationCenter.removeAllPendingNotificationRequests()
        debugLogger.log("Cancelled all scheduled notifications", level: .info)
    }

    /// Cancel notifications with a specific prefix
    func cancelNotifications(withPrefix prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let toRemove = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)
        debugLogger.log("Cancelled \(toRemove.count) notifications with prefix: \(prefix)", level: .info)
    }

    // MARK: - Notification Tap Handling

    /// Handle notification tap and extract deep link URL
    ///
    /// - Parameter payload: Notification userInfo dictionary
    /// - Returns: Deep link URL if available
    func handleNotificationTap(payload: [AnyHashable: Any]) -> URL? {
        // Log the tap
        let notificationType = payload["notification_type"] as? String ?? "unknown"
        errorLogger.logUserAction(
            action: "notification_tapped",
            properties: ["type": notificationType]
        )

        // Extract deep link
        if let deepLink = payload["deep_link"] as? String,
           let url = URL(string: deepLink) {
            debugLogger.log("Notification tap deep link: \(deepLink)", level: .info)
            return url
        }

        // Fallback: construct URL from notification type
        if let typeString = payload["notification_type"] as? String,
           let type = NotificationType(rawValue: typeString) {
            return constructDeepLink(for: type, with: payload)
        }

        return nil
    }

    /// Construct a deep link URL for a notification type
    private func constructDeepLink(for type: NotificationType, with payload: [AnyHashable: Any]) -> URL? {
        switch type {
        case .checkInReminder:
            return URL(string: "modus://check-in")

        case .taskDue:
            if let taskId = payload["task_id"] as? String {
                return URL(string: "modus://task/\(taskId)")
            }
            return URL(string: "modus://today")

        case .briefAvailable:
            if let briefId = payload["brief_id"] as? String {
                return URL(string: "modus://brief/\(briefId)")
            }
            return URL(string: "modus://briefs")

        case .safetyAlert:
            if let patientId = payload["patient_id"] as? String {
                return URL(string: "modus://patient/\(patientId)/safety")
            }
            return URL(string: "modus://patients")

        case .streakMilestone:
            return URL(string: "modus://streak")
        }
    }

    // MARK: - Helper Methods

    /// Parse time string in "HH:mm" format
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }

    /// Check if running in debug build
    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Badge Management

    /// Clear app badge count
    func clearBadge() async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        try? await notificationCenter.setBadgeCount(0)
    }

    /// Set app badge count
    func setBadgeCount(_ count: Int) async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
        try? await notificationCenter.setBadgeCount(count)
    }

    // MARK: - Pending Notifications

    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Get count of pending notifications by type
    func getPendingCount(for type: NotificationType) async -> Int {
        let pending = await getPendingNotifications()
        return pending.filter { request in
            if let notificationType = request.content.userInfo["notification_type"] as? String {
                return notificationType == type.rawValue
            }
            return false
        }.count
    }
}

// MARK: - Errors

/// Errors specific to push notification manager operations
enum PushNotificationManagerError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case registrationFailed(Error)
    case schedulingFailed(Error)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User Not Authenticated"
        case .notAuthorized:
            return "Notifications Not Authorized"
        case .registrationFailed:
            return "Token Registration Failed"
        case .schedulingFailed:
            return "Scheduling Failed"
        case .invalidPayload:
            return "Invalid Notification"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to enable push notifications."
        case .notAuthorized:
            return "Please enable notifications in Settings to receive reminders."
        case .registrationFailed:
            return "We couldn't register your device. Please try again later."
        case .schedulingFailed:
            return "We couldn't schedule your notification. Please try again."
        case .invalidPayload:
            return "The notification couldn't be processed."
        }
    }
}
