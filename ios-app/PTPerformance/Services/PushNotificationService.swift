//
//  PushNotificationService.swift
//  PTPerformance
//
//  Service for handling Apple Push Notification Service (APNs) registration,
//  notification categories, and remote notification processing.
//

import Foundation
import UserNotifications
import UIKit
import Supabase

// MARK: - Push Notification Service

/// Service for managing push notifications and APNs registration.
///
/// Thread-safe actor that handles:
/// - Device token registration with backend
/// - Notification category and action setup
/// - Remote notification processing
/// - Deep link extraction from notifications
///
/// ## Usage
/// ```swift
/// // Register for push notifications
/// await PushNotificationService.shared.registerForRemoteNotifications()
///
/// // Handle incoming notification
/// await PushNotificationService.shared.handleNotification(userInfo: userInfo)
/// ```
actor PushNotificationService: NSObject {

    // MARK: - Singleton

    static let shared = PushNotificationService()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let debugLogger = DebugLogger.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Current device token (hex string)
    private(set) var deviceToken: String?

    /// Whether the service has been initialized
    private var isInitialized = false

    // MARK: - Notification Category Identifiers

    private enum CategoryIdentifier {
        static let prescription = "PRESCRIPTION_NOTIFICATION"
        static let therapistFollowUp = "THERAPIST_FOLLOW_UP"
        static let workoutReminder = "WORKOUT_REMINDER"
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Initialize the push notification service.
    ///
    /// Call this early in app launch to set up notification categories and delegate.
    func initialize() async {
        guard !isInitialized else { return }

        debugLogger.log("Initializing PushNotificationService", level: .info)

        // Register notification categories with actions
        await registerNotificationCategories()

        isInitialized = true
        debugLogger.log("PushNotificationService initialized", level: .success)
    }

    /// Register notification categories with interactive actions.
    private func registerNotificationCategories() async {
        // Prescription notification actions
        let startWorkoutAction = UNNotificationAction(
            identifier: PrescriptionNotificationAction.startWorkout.identifier,
            title: PrescriptionNotificationAction.startWorkout.title,
            options: [.foreground]
        )

        let snooze1HourAction = UNNotificationAction(
            identifier: PrescriptionNotificationAction.snooze1Hour.identifier,
            title: PrescriptionNotificationAction.snooze1Hour.title,
            options: []
        )

        let snooze3HoursAction = UNNotificationAction(
            identifier: PrescriptionNotificationAction.snooze3Hours.identifier,
            title: PrescriptionNotificationAction.snooze3Hours.title,
            options: []
        )

        let viewDetailsAction = UNNotificationAction(
            identifier: PrescriptionNotificationAction.viewDetails.identifier,
            title: PrescriptionNotificationAction.viewDetails.title,
            options: [.foreground]
        )

        // Prescription notification category
        let prescriptionCategory = UNNotificationCategory(
            identifier: CategoryIdentifier.prescription,
            actions: [startWorkoutAction, snooze1HourAction, snooze3HoursAction, viewDetailsAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "New prescription available",
            options: [.customDismissAction]
        )

        // Therapist follow-up actions
        let viewPatientAction = UNNotificationAction(
            identifier: TherapistFollowUpAction.viewPatient.identifier,
            title: TherapistFollowUpAction.viewPatient.title,
            options: [.foreground]
        )

        let sendMessageAction = UNNotificationAction(
            identifier: TherapistFollowUpAction.sendMessage.identifier,
            title: TherapistFollowUpAction.sendMessage.title,
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: TherapistFollowUpAction.dismiss.identifier,
            title: TherapistFollowUpAction.dismiss.title,
            options: [.destructive]
        )

        // Therapist follow-up category
        let therapistCategory = UNNotificationCategory(
            identifier: CategoryIdentifier.therapistFollowUp,
            actions: [viewPatientAction, sendMessageAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Workout reminder category (simple with just snooze)
        let workoutCategory = UNNotificationCategory(
            identifier: CategoryIdentifier.workoutReminder,
            actions: [startWorkoutAction, snooze1HourAction],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories
        notificationCenter.setNotificationCategories([
            prescriptionCategory,
            therapistCategory,
            workoutCategory
        ])

        debugLogger.log("Registered notification categories", level: .success)
    }

    // MARK: - Remote Notification Registration

    /// Request authorization and register for remote notifications.
    ///
    /// - Returns: `true` if registration was initiated successfully
    @discardableResult
    func registerForRemoteNotifications() async throws -> Bool {
        // Request authorization first
        let granted = try await notificationCenter.requestAuthorization(
            options: [.alert, .sound, .badge, .provisional]
        )

        guard granted else {
            debugLogger.log("Push notification permission denied", level: .warning)
            return false
        }

        debugLogger.log("Push notification permission granted", level: .success)

        // Register with APNs on main thread
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return true
    }

    /// Handle successful device token registration from APNs.
    ///
    /// - Parameter deviceToken: Raw device token data from APNs
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        #if DEBUG
        debugLogger.log("Received APNs device token: \(tokenString.prefix(16))...", level: .success)
        #endif

        // Register token with backend
        await registerDeviceTokenWithBackend(tokenString)
    }

    /// Handle failed device token registration.
    ///
    /// - Parameter error: The registration error
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        errorLogger.logError(error, context: "PushNotificationService.didFailToRegisterForRemoteNotifications")
        debugLogger.log("Failed to register for remote notifications: \(error.localizedDescription)", level: .error)
    }

    /// Register device token with the backend server.
    private func registerDeviceTokenWithBackend(_ token: String) async {
        guard let userId = PTSupabaseClient.shared.userId else {
            #if DEBUG
            debugLogger.log("Cannot register device token: no user ID", level: .warning)
            #endif
            return
        }

        let payload = DeviceTokenPayload(userId: userId, deviceToken: token)

        do {
            try await supabase
                .from("device_tokens")
                .upsert(payload, onConflict: "user_id,device_token")
                .execute()

            #if DEBUG
            debugLogger.log("Device token registered with backend", level: .success)
            #endif

            // Also call edge function for any additional server-side setup
            try await supabase.functions.invoke(
                "register-device-token",
                options: .init(body: payload)
            )
        } catch {
            errorLogger.logError(error, context: "PushNotificationService.registerDeviceTokenWithBackend")
            #if DEBUG
            debugLogger.log("Failed to register device token: \(error.localizedDescription)", level: .error)
            #endif
        }
    }

    /// Unregister device token when user logs out.
    func unregisterDeviceToken() async {
        guard let userId = PTSupabaseClient.shared.userId,
              let token = deviceToken else {
            return
        }

        do {
            try await supabase
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userId)
                .eq("device_token", value: token)
                .execute()

            #if DEBUG
            debugLogger.log("Device token unregistered", level: .success)
            #endif
            self.deviceToken = nil
        } catch {
            errorLogger.logError(error, context: "PushNotificationService.unregisterDeviceToken")
        }
    }

    // MARK: - Notification Handling

    /// Handle incoming remote notification.
    ///
    /// - Parameters:
    ///   - userInfo: Notification payload dictionary
    ///   - completionHandler: Optional completion handler for background fetch
    /// - Returns: Deep link destination if applicable
    @discardableResult
    func handleNotification(
        userInfo: [AnyHashable: Any],
        completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil
    ) async -> DeepLinkDestination? {
        debugLogger.log("Handling remote notification", level: .info)

        guard let payload = RemoteNotificationPayload.from(userInfo: userInfo) else {
            debugLogger.log("Failed to parse notification payload", level: .warning)
            completionHandler?(.noData)
            return nil
        }

        // Log notification received
        if let notificationType = payload.notificationType {
            errorLogger.logUserAction(
                action: "notification_received",
                properties: [
                    "type": notificationType.rawValue,
                    "prescription_id": payload.prescriptionId ?? "none"
                ]
            )
        }

        // Extract deep link
        let destination = extractDeepLink(from: payload)

        completionHandler?(.newData)
        return destination
    }

    /// Handle notification action response.
    ///
    /// - Parameter response: The user's response to the notification
    /// - Returns: Deep link destination based on the action
    func handleNotificationAction(_ response: UNNotificationResponse) async -> DeepLinkDestination? {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        debugLogger.log("Handling notification action: \(actionIdentifier)", level: .info)

        guard let payload = RemoteNotificationPayload.from(userInfo: userInfo) else {
            return nil
        }

        // Log action taken
        errorLogger.logUserAction(
            action: "notification_action_taken",
            properties: [
                "action": actionIdentifier,
                "type": payload.notificationType?.rawValue ?? "unknown"
            ]
        )

        // Handle specific actions
        switch actionIdentifier {
        case PrescriptionNotificationAction.startWorkout.identifier:
            return handleStartWorkoutAction(payload: payload)

        case PrescriptionNotificationAction.snooze1Hour.identifier:
            await handleSnoozeAction(payload: payload, hours: 1)
            return nil

        case PrescriptionNotificationAction.snooze3Hours.identifier:
            await handleSnoozeAction(payload: payload, hours: 3)
            return nil

        case PrescriptionNotificationAction.viewDetails.identifier,
             TherapistFollowUpAction.viewPatient.identifier:
            return extractDeepLink(from: payload)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            return extractDeepLink(from: payload)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            return nil

        default:
            return nil
        }
    }

    /// Handle the "Start Workout" action.
    private func handleStartWorkoutAction(payload: RemoteNotificationPayload) -> DeepLinkDestination? {
        if let prescriptionId = payload.prescriptionId {
            return .workout(sessionId: prescriptionId)
        }
        return .startWorkout
    }

    /// Handle snooze action by rescheduling the notification.
    private func handleSnoozeAction(payload: RemoteNotificationPayload, hours: Int) async {
        guard let prescriptionId = payload.prescriptionId else {
            return
        }

        let aps = payload.aps
        let content = UNMutableNotificationContent()
        content.title = aps.alert?.title ?? "Prescription Reminder"
        content.body = aps.alert?.body ?? "You have a prescription to complete"
        content.sound = .default
        content.categoryIdentifier = CategoryIdentifier.prescription
        content.userInfo = ["prescription_id": prescriptionId]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snoozed_\(prescriptionId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            debugLogger.log("Snoozed notification for \(hours) hour(s)", level: .success)
        } catch {
            errorLogger.logError(error, context: "PushNotificationService.handleSnoozeAction")
        }
    }

    /// Extract deep link destination from notification payload.
    private func extractDeepLink(from payload: RemoteNotificationPayload) -> DeepLinkDestination? {
        // Check for explicit deep link
        if let deepLinkString = payload.deepLink,
           let url = URL(string: deepLinkString) {
            return DeepLinkDestination.from(url: url)
        }

        // Check for prescription ID
        if let prescriptionId = payload.prescriptionId {
            return .workout(sessionId: prescriptionId)
        }

        // Default based on notification type
        switch payload.notificationType {
        case .prescriptionAssigned, .prescriptionDeadline24h, .prescriptionDeadline6h,
             .prescriptionDeadline1h, .prescriptionOverdue:
            return .today
        case .therapistFollowUp:
            if let patientId = payload.patientId {
                // For therapist, navigate to patient detail (handled by app)
                return .workout(sessionId: patientId)
            }
            return nil
        case .workoutReminder:
            return .startWorkout
        case .streakAlert:
            return .streak
        case .weeklySummary:
            return .progress
        case .none:
            return nil
        }
    }

    // MARK: - Badge Management

    /// Clear the app badge count.
    func clearBadge() async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        // Also clear via notification center
        try? await notificationCenter.setBadgeCount(0)
    }

    /// Update badge count based on pending prescriptions.
    func updateBadgeCount(_ count: Int) async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }

        try? await notificationCenter.setBadgeCount(count)
    }

    // MARK: - Notification Settings

    /// Get current notification authorization status.
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Check if notifications are enabled.
    func areNotificationsEnabled() async -> Bool {
        let status = await getAuthorizationStatus()
        return status == .authorized || status == .provisional
    }

    /// Open system settings for notification permissions.
    @MainActor
    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - ACP-1002: Permission Flow

    /// Request notification permission with a soft pre-prompt check.
    /// Returns true if the user granted permission, false otherwise.
    /// Uses `.alert`, `.sound`, `.badge` options (no `.provisional` to get explicit consent).
    func requestPermission() async -> Bool {
        debugLogger.info("PushNotificationService", "Requesting notification permission")

        let currentStatus = await getAuthorizationStatus()

        // If already determined, return current status
        if currentStatus == .authorized {
            debugLogger.success("PushNotificationService", "Notifications already authorized")
            return true
        }

        if currentStatus == .denied {
            debugLogger.log("Notification permission previously denied -- user must enable in Settings", level: .warning)
            return false
        }

        // Request authorization (only shows system prompt for .notDetermined)
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                debugLogger.success("PushNotificationService", "Notification permission granted by user")

                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                debugLogger.log("User declined notification permission", level: .warning)
            }

            // Track the permission decision for analytics
            errorLogger.logUserAction(
                action: "notification_permission_response",
                properties: ["granted": String(granted)]
            )

            return granted
        } catch {
            errorLogger.logError(error, context: "PushNotificationService.requestPermission")
            debugLogger.log("Failed to request notification permission: \(error.localizedDescription)", level: .error)
            return false
        }
    }

    // MARK: - ACP-1002: Local Notification Scheduling

    /// Schedule a local notification from a `ScheduledNotification` model.
    ///
    /// - Parameter notification: The notification to schedule.
    func scheduleLocalNotification(_ notification: ScheduledNotification) async {
        debugLogger.info("PushNotificationService", "Scheduling local notification: \(notification.type.rawValue) id=\(notification.id)")

        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.categoryIdentifier = notification.type.categoryIdentifier

        // Attach custom data for deep linking and identification
        var userInfo: [String: Any] = [
            "notification_type": notification.type.rawValue,
            "scheduled_notification_id": notification.id
        ]
        if let data = notification.data {
            for (key, value) in data {
                userInfo[key] = value
            }
        }
        content.userInfo = userInfo

        // Build trigger
        let trigger: UNNotificationTrigger
        if notification.repeats {
            // For repeating notifications, use calendar-based trigger
            let components = Calendar.current.dateComponents(
                [.hour, .minute, .weekday],
                from: notification.scheduledDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        } else {
            let interval = max(1, notification.scheduledDate.timeIntervalSinceNow)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            debugLogger.success("PushNotificationService", "Scheduled notification \(notification.id) for \(notification.scheduledDate)")
        } catch {
            errorLogger.logError(error, context: "PushNotificationService.scheduleLocalNotification")
            debugLogger.log("Failed to schedule notification \(notification.id): \(error.localizedDescription)", level: .error)
        }
    }

    /// Cancel a scheduled or delivered notification by its identifier.
    ///
    /// - Parameter id: The notification identifier to cancel.
    func cancelNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
        debugLogger.info("PushNotificationService", "Cancelled notification: \(id)")
    }

    /// Cancel all pending and delivered notifications.
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        debugLogger.info("PushNotificationService", "Cancelled all notifications")
    }

    /// Get count of all pending notification requests.
    func pendingNotificationCount() async -> Int {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.count
    }

    /// Cancel all notifications of a specific type.
    ///
    /// - Parameter type: The `ScheduledNotificationType` to cancel.
    func cancelNotifications(ofType type: ScheduledNotificationType) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let idsToCancel = pending
            .filter { request in
                guard let notifType = request.content.userInfo["notification_type"] as? String else { return false }
                return notifType == type.rawValue
            }
            .map { $0.identifier }

        if !idsToCancel.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToCancel)
            debugLogger.info("PushNotificationService", "Cancelled \(idsToCancel.count) notifications of type \(type.rawValue)")
        }
    }
}

// MARK: - ACP-1002: Scheduled Notification Types

/// Comprehensive notification types for the app notification strategy.
enum ScheduledNotificationType: String, Codable, CaseIterable {
    case workoutReminder = "workout_reminder"
    case streakAtRisk = "streak_at_risk"
    case streakAchieved = "streak_achieved"
    case weeklyProgress = "weekly_progress"
    case trialExpiring = "trial_expiring"
    case reEngagement = "re_engagement"
    case socialActivity = "social_activity"
    case achievementUnlocked = "achievement_unlocked"

    /// User-facing display name for notification settings.
    var displayName: String {
        switch self {
        case .workoutReminder: return "Workout Reminders"
        case .streakAtRisk: return "Streak Alerts"
        case .streakAchieved: return "Streak Milestones"
        case .weeklyProgress: return "Weekly Progress"
        case .trialExpiring: return "Trial Reminders"
        case .reEngagement: return "Come Back Reminders"
        case .socialActivity: return "Social Updates"
        case .achievementUnlocked: return "Achievement Alerts"
        }
    }

    /// SF Symbol icon name for the notification type.
    var iconName: String {
        switch self {
        case .workoutReminder: return "figure.strengthtraining.traditional"
        case .streakAtRisk: return "flame.fill"
        case .streakAchieved: return "trophy.fill"
        case .weeklyProgress: return "chart.bar.fill"
        case .trialExpiring: return "clock.badge.exclamationmark"
        case .reEngagement: return "hand.wave.fill"
        case .socialActivity: return "person.2.fill"
        case .achievementUnlocked: return "medal.fill"
        }
    }

    /// The UNNotificationCategory identifier associated with this type.
    var categoryIdentifier: String {
        switch self {
        case .workoutReminder: return "WORKOUT_REMINDER"
        case .streakAtRisk: return "STREAK_ALERT"
        case .streakAchieved: return "STREAK_MILESTONE"
        case .weeklyProgress: return "WEEKLY_SUMMARY"
        case .trialExpiring: return "TRIAL_EXPIRING"
        case .reEngagement: return "RE_ENGAGEMENT"
        case .socialActivity: return "SOCIAL_ACTIVITY"
        case .achievementUnlocked: return "ACHIEVEMENT_UNLOCKED"
        }
    }

    /// Deep link destination for tapping the notification.
    var defaultDeepLink: DeepLinkDestination {
        switch self {
        case .workoutReminder: return .startWorkout
        case .streakAtRisk: return .streak
        case .streakAchieved: return .streak
        case .weeklyProgress: return .progress
        case .trialExpiring: return .today
        case .reEngagement: return .today
        case .socialActivity: return .today
        case .achievementUnlocked: return .streak
        }
    }
}

// MARK: - ACP-1002: Scheduled Notification Model

/// Model representing a local notification to be scheduled.
struct ScheduledNotification: Identifiable, Codable {
    /// Unique identifier for the notification (used as UNNotificationRequest identifier).
    let id: String
    /// The notification type category.
    let type: ScheduledNotificationType
    /// Title displayed in the notification banner.
    let title: String
    /// Body text displayed in the notification banner.
    let body: String
    /// When this notification should fire.
    let scheduledDate: Date
    /// Whether the notification should repeat (daily at the same time).
    let repeats: Bool
    /// Optional key-value data attached to the notification for deep linking.
    let data: [String: String]?

    init(
        id: String = UUID().uuidString,
        type: ScheduledNotificationType,
        title: String,
        body: String,
        scheduledDate: Date,
        repeats: Bool = false,
        data: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.repeats = repeats
        self.data = data
    }
}

// MARK: - Push Notification Errors

/// Errors specific to push notification operations
enum PushNotificationError: LocalizedError {
    case permissionDenied
    case tokenRegistrationFailed(Error)
    case invalidPayload
    case scheduleFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification Permission Required"
        case .tokenRegistrationFailed:
            return "Token Registration Failed"
        case .invalidPayload:
            return "Invalid Notification"
        case .scheduleFailed:
            return "Couldn't Schedule Notification"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable notifications in Settings to receive prescription alerts."
        case .tokenRegistrationFailed:
            return "We couldn't register your device for push notifications. Please try again later."
        case .invalidPayload:
            return "The notification couldn't be processed."
        case .scheduleFailed:
            return "We couldn't schedule your notification. Please try again."
        }
    }
}
