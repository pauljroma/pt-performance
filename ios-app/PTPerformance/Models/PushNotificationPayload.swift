//
//  PushNotificationPayload.swift
//  PTPerformance
//
//  X2Index Phase 2: Push Notification Infrastructure
//  Notification payload models for athlete reminders and PT alerts
//

import Foundation

// MARK: - Notification Type

/// Types of push notifications for the action loop
enum NotificationType: String, Codable, CaseIterable, Sendable {
    case checkInReminder = "check_in_reminder"
    case taskDue = "task_due"
    case briefAvailable = "brief_available"
    case safetyAlert = "safety_alert"
    case streakMilestone = "streak_milestone"

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .checkInReminder: return "Check-In Reminder"
        case .taskDue: return "Task Due"
        case .briefAvailable: return "Brief Available"
        case .safetyAlert: return "Safety Alert"
        case .streakMilestone: return "Streak Milestone"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .checkInReminder: return "bell.badge"
        case .taskDue: return "checklist"
        case .briefAvailable: return "doc.text.fill"
        case .safetyAlert: return "exclamationmark.triangle.fill"
        case .streakMilestone: return "flame.fill"
        }
    }

    /// Whether this notification type requires immediate attention
    var isUrgent: Bool {
        switch self {
        case .safetyAlert: return true
        case .checkInReminder, .taskDue, .briefAvailable, .streakMilestone: return false
        }
    }

    /// Default priority for this notification type
    var defaultPriority: NotificationPriority {
        switch self {
        case .safetyAlert: return .high
        case .checkInReminder, .taskDue, .briefAvailable: return .normal
        case .streakMilestone: return .low
        }
    }

    /// Notification category identifier for UNNotificationCategory
    var categoryIdentifier: String {
        switch self {
        case .checkInReminder: return "CHECK_IN_REMINDER"
        case .taskDue: return "TASK_DUE"
        case .briefAvailable: return "BRIEF_AVAILABLE"
        case .safetyAlert: return "SAFETY_ALERT"
        case .streakMilestone: return "STREAK_MILESTONE"
        }
    }
}

// MARK: - Notification Priority

/// Priority levels for push notifications
enum NotificationPriority: String, Codable, CaseIterable, Sendable {
    case high
    case normal
    case low

    /// Display name for settings
    var displayName: String {
        switch self {
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }

    /// APNs priority value (10 = immediate, 5 = conserve power)
    var apnsPriority: Int {
        switch self {
        case .high: return 10
        case .normal: return 5
        case .low: return 5
        }
    }

    /// iOS interruption level
    @available(iOS 15.0, *)
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .high: return .timeSensitive
        case .normal: return .active
        case .low: return .passive
        }
    }
}

// MARK: - Push Notification Payload

/// X2Index push notification payload for athlete reminders and PT alerts
struct PushNotificationPayload: Codable, Identifiable, Sendable {
    /// Unique identifier for this notification
    let id: UUID

    /// Type of notification
    let type: NotificationType

    /// Notification title
    let title: String

    /// Notification body text
    let body: String

    /// Additional data for deep linking and context
    let data: [String: String]

    /// When this notification should be delivered (nil for immediate)
    let scheduledFor: Date?

    /// Notification priority
    let priority: NotificationPriority

    /// When this payload was created
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case data
        case scheduledFor = "scheduled_for"
        case priority
        case createdAt = "created_at"
    }

    /// Initialize a new notification payload
    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        body: String,
        data: [String: String] = [:],
        scheduledFor: Date? = nil,
        priority: NotificationPriority? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.scheduledFor = scheduledFor
        self.priority = priority ?? type.defaultPriority
        self.createdAt = createdAt
    }

    /// Deep link URL extracted from data
    var deepLinkURL: URL? {
        guard let deepLink = data["deep_link"] else { return nil }
        return URL(string: deepLink)
    }

    /// Patient ID from data if present
    var patientId: UUID? {
        guard let idString = data["patient_id"] else { return nil }
        return UUID(uuidString: idString)
    }

    /// Task ID from data if present
    var taskId: UUID? {
        guard let idString = data["task_id"] else { return nil }
        return UUID(uuidString: idString)
    }

    /// Plan ID from data if present
    var planId: UUID? {
        guard let idString = data["plan_id"] else { return nil }
        return UUID(uuidString: idString)
    }

    /// Streak count from data if present (for milestone notifications)
    var streakCount: Int? {
        guard let countString = data["streak_count"] else { return nil }
        return Int(countString)
    }

    /// Whether this is a scheduled notification
    var isScheduled: Bool {
        scheduledFor != nil
    }

    /// Whether the scheduled time has passed
    var isPastDue: Bool {
        guard let scheduledFor = scheduledFor else { return false }
        return scheduledFor < Date()
    }
}

// MARK: - Factory Methods

extension PushNotificationPayload {

    /// Create a check-in reminder notification
    static func checkInReminder(
        patientId: UUID,
        scheduledFor: Date
    ) -> PushNotificationPayload {
        PushNotificationPayload(
            type: .checkInReminder,
            title: "Daily Check-In",
            body: "Time to complete your daily check-in. How are you feeling today?",
            data: [
                "patient_id": patientId.uuidString,
                "deep_link": "korza://check-in"
            ],
            scheduledFor: scheduledFor,
            priority: .normal
        )
    }

    /// Create a task due reminder notification
    static func taskDue(
        task: ProtocolTask,
        planId: UUID,
        patientId: UUID,
        dueDate: Date,
        minutesBefore: Int
    ) -> PushNotificationPayload {
        let reminderDate = Calendar.current.date(
            byAdding: .minute,
            value: -minutesBefore,
            to: dueDate
        ) ?? dueDate

        let timeString = minutesBefore < 60
            ? "\(minutesBefore) minutes"
            : "\(minutesBefore / 60) hour\(minutesBefore >= 120 ? "s" : "")"

        return PushNotificationPayload(
            type: .taskDue,
            title: "Task Reminder: \(task.title)",
            body: "Your \(task.taskType.displayName.lowercased()) task is due in \(timeString).",
            data: [
                "task_id": task.id.uuidString,
                "plan_id": planId.uuidString,
                "patient_id": patientId.uuidString,
                "task_type": task.taskType.rawValue,
                "deep_link": "korza://task/\(task.id.uuidString)"
            ],
            scheduledFor: reminderDate,
            priority: .normal
        )
    }

    /// Create a PT brief available notification
    static func briefAvailable(
        patientId: UUID,
        therapistId: UUID,
        therapistName: String,
        briefId: UUID
    ) -> PushNotificationPayload {
        PushNotificationPayload(
            type: .briefAvailable,
            title: "New Brief from \(therapistName)",
            body: "Your PT has shared a new brief with you. Tap to view.",
            data: [
                "patient_id": patientId.uuidString,
                "therapist_id": therapistId.uuidString,
                "brief_id": briefId.uuidString,
                "deep_link": "korza://brief/\(briefId.uuidString)"
            ],
            scheduledFor: nil,
            priority: .normal
        )
    }

    /// Create a safety incident alert for PTs
    static func safetyAlert(
        patientId: UUID,
        patientName: String,
        therapistId: UUID,
        incidentId: UUID,
        severity: String,
        summary: String
    ) -> PushNotificationPayload {
        PushNotificationPayload(
            type: .safetyAlert,
            title: "Safety Alert: \(patientName)",
            body: summary,
            data: [
                "patient_id": patientId.uuidString,
                "therapist_id": therapistId.uuidString,
                "incident_id": incidentId.uuidString,
                "severity": severity,
                "deep_link": "korza://patient/\(patientId.uuidString)/safety"
            ],
            scheduledFor: nil,
            priority: .high
        )
    }

    /// Create a streak milestone celebration notification
    static func streakMilestone(
        patientId: UUID,
        streakCount: Int,
        streakType: String
    ) -> PushNotificationPayload {
        let (title, body) = streakMilestoneContent(count: streakCount, type: streakType)

        return PushNotificationPayload(
            type: .streakMilestone,
            title: title,
            body: body,
            data: [
                "patient_id": patientId.uuidString,
                "streak_count": String(streakCount),
                "streak_type": streakType,
                "deep_link": "korza://streak"
            ],
            scheduledFor: nil,
            priority: .low
        )
    }

    /// Generate appropriate title and body for streak milestones
    private static func streakMilestoneContent(count: Int, type: String) -> (title: String, body: String) {
        switch count {
        case 7:
            return ("1 Week Streak!", "You've completed 7 days in a row. Keep up the great work!")
        case 14:
            return ("2 Week Streak!", "Two weeks of consistency! You're building great habits.")
        case 21:
            return ("3 Week Streak!", "21 days! They say it takes 21 days to form a habit.")
        case 30:
            return ("30 Day Streak!", "A full month of dedication! You're crushing it!")
        case 60:
            return ("60 Day Streak!", "Two months strong! Your commitment is inspiring.")
        case 90:
            return ("90 Day Streak!", "Three months! You've made this a lifestyle.")
        case 100:
            return ("100 Day Streak!", "Triple digits! 100 days of excellence!")
        case 365:
            return ("1 Year Streak!", "Incredible! A full year of consistency. You're a champion!")
        default:
            if count % 100 == 0 {
                return ("\(count) Day Streak!", "What an achievement! \(count) days of dedication!")
            } else if count % 50 == 0 {
                return ("\(count) Day Streak!", "Amazing progress! \(count) days and counting!")
            } else if count % 7 == 0 {
                let weeks = count / 7
                return ("\(weeks) Week Streak!", "You've completed \(weeks) weeks in a row!")
            } else {
                return ("Streak Milestone!", "You've hit \(count) days! Keep going!")
            }
        }
    }
}

// MARK: - Notification Record (for database storage)

/// Record of a sent notification for tracking and analytics
struct NotificationDeliveryRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let payload: PushNotificationPayload
    let status: DeliveryStatus
    let sentAt: Date?
    let deliveredAt: Date?
    let readAt: Date?
    let actionTaken: String?
    let errorMessage: String?
    let createdAt: Date

    enum DeliveryStatus: String, Codable {
        case pending
        case sent
        case delivered
        case failed
        case cancelled
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case payload
        case status
        case sentAt = "sent_at"
        case deliveredAt = "delivered_at"
        case readAt = "read_at"
        case actionTaken = "action_taken"
        case errorMessage = "error_message"
        case createdAt = "created_at"
    }
}

// MARK: - UNUserNotificationCenter Import

import UserNotifications
