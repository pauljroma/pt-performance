//
//  NotificationPayload.swift
//  PTPerformance
//
//  Push notification data models for prescription alerts and remote notifications
//

import Foundation

// MARK: - Notification Types

/// Types of push notifications supported by the app
enum PushNotificationType: String, Codable, CaseIterable {
    // Workout notifications
    case workoutReminder = "workout_reminder"
    case streakAlert = "streak_alert"
    case weeklySummary = "weekly_summary"

    // Prescription notifications
    case prescriptionAssigned = "prescription_assigned"
    case prescriptionDeadline24h = "prescription_deadline_24h"
    case prescriptionDeadline6h = "prescription_deadline_6h"
    case prescriptionDeadline1h = "prescription_deadline_1h"
    case prescriptionOverdue = "prescription_overdue"
    case therapistFollowUp = "therapist_follow_up"
    case unknown = "unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .workoutReminder: return "Workout Reminder"
        case .streakAlert: return "Streak Alert"
        case .weeklySummary: return "Weekly Summary"
        case .prescriptionAssigned: return "New Prescription"
        case .prescriptionDeadline24h: return "Deadline (24 hours)"
        case .prescriptionDeadline6h: return "Deadline (6 hours)"
        case .prescriptionDeadline1h: return "Deadline (1 hour)"
        case .prescriptionOverdue: return "Overdue Alert"
        case .therapistFollowUp: return "Therapist Follow-up"
        case .unknown: return "Unknown"
        }
    }

    /// Category for grouping in settings
    var category: NotificationCategory {
        switch self {
        case .workoutReminder, .streakAlert, .weeklySummary:
            return .workout
        case .prescriptionAssigned, .prescriptionDeadline24h, .prescriptionDeadline6h,
             .prescriptionDeadline1h, .prescriptionOverdue, .therapistFollowUp:
            return .prescription
        case .unknown:
            return .workout
        }
    }

    /// Notification category identifier for UNNotificationCategory
    var categoryIdentifier: String {
        switch self {
        case .prescriptionAssigned, .prescriptionDeadline24h, .prescriptionDeadline6h,
             .prescriptionDeadline1h, .prescriptionOverdue:
            return "PRESCRIPTION_NOTIFICATION"
        case .therapistFollowUp:
            return "THERAPIST_FOLLOW_UP"
        case .workoutReminder:
            return "WORKOUT_REMINDER"
        case .streakAlert:
            return "STREAK_ALERT"
        case .weeklySummary:
            return "WEEKLY_SUMMARY"
        case .unknown:
            return "UNKNOWN"
        }
    }
}

/// Category grouping for notification types
enum NotificationCategory: String, Codable {
    case workout
    case prescription

    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .prescription: return "Prescriptions"
        }
    }
}

// MARK: - Notification Payloads

/// Base protocol for notification payloads
protocol NotificationPayloadProtocol: Codable {
    var notificationType: PushNotificationType { get }
    var title: String { get }
    var body: String { get }
    var deepLinkURL: URL? { get }
}

/// Payload for prescription-related notifications
struct PrescriptionNotificationPayload: NotificationPayloadProtocol, Codable {
    let notificationType: PushNotificationType
    let title: String
    let body: String
    let prescriptionId: UUID
    let prescriptionName: String
    let patientId: UUID
    let therapistId: UUID?
    let therapistName: String?
    let dueDate: Date?
    let priority: PrescriptionPriority?

    /// Deep link URL for navigating to the prescription
    var deepLinkURL: URL? {
        URL(string: "modus://prescription/\(prescriptionId.uuidString)")
    }

    enum CodingKeys: String, CodingKey {
        case notificationType = "notification_type"
        case title
        case body
        case prescriptionId = "prescription_id"
        case prescriptionName = "prescription_name"
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case therapistName = "therapist_name"
        case dueDate = "due_date"
        case priority
    }
}

/// Payload for therapist follow-up notifications
struct TherapistFollowUpPayload: NotificationPayloadProtocol, Codable {
    let notificationType: PushNotificationType
    let title: String
    let body: String
    let patientId: UUID
    let patientName: String
    let prescriptionId: UUID?
    let prescriptionName: String?
    let followUpReason: FollowUpReason

    /// Deep link URL for navigating to the patient
    var deepLinkURL: URL? {
        if let prescriptionId = prescriptionId {
            return URL(string: "modus://prescription/\(prescriptionId.uuidString)")
        }
        return URL(string: "modus://patient/\(patientId.uuidString)")
    }

    enum CodingKeys: String, CodingKey {
        case notificationType = "notification_type"
        case title
        case body
        case patientId = "patient_id"
        case patientName = "patient_name"
        case prescriptionId = "prescription_id"
        case prescriptionName = "prescription_name"
        case followUpReason = "follow_up_reason"
    }
}

/// Reasons for therapist follow-up reminders
enum FollowUpReason: String, Codable {
    case prescriptionCompleted = "prescription_completed"
    case prescriptionOverdue = "prescription_overdue"
    case patientInactive = "patient_inactive"
    case weeklyCheckIn = "weekly_check_in"

    var displayName: String {
        switch self {
        case .prescriptionCompleted: return "Prescription Completed"
        case .prescriptionOverdue: return "Prescription Overdue"
        case .patientInactive: return "Patient Inactive"
        case .weeklyCheckIn: return "Weekly Check-in"
        }
    }
}

// MARK: - Notification Actions

/// Quick actions available on prescription notifications
enum PrescriptionNotificationAction: String, CaseIterable {
    case startWorkout = "START_WORKOUT"
    case snooze1Hour = "SNOOZE_1H"
    case snooze3Hours = "SNOOZE_3H"
    case viewDetails = "VIEW_DETAILS"

    var title: String {
        switch self {
        case .startWorkout: return "Start Workout"
        case .snooze1Hour: return "Snooze 1 Hour"
        case .snooze3Hours: return "Snooze 3 Hours"
        case .viewDetails: return "View Details"
        }
    }

    var identifier: String { rawValue }

    /// System image name for the action icon
    var systemImageName: String {
        switch self {
        case .startWorkout: return "play.fill"
        case .snooze1Hour, .snooze3Hours: return "clock.fill"
        case .viewDetails: return "doc.text.fill"
        }
    }
}

/// Quick actions for therapist follow-up notifications
enum TherapistFollowUpAction: String, CaseIterable {
    case viewPatient = "VIEW_PATIENT"
    case sendMessage = "SEND_MESSAGE"
    case dismiss = "DISMISS"

    var title: String {
        switch self {
        case .viewPatient: return "View Patient"
        case .sendMessage: return "Send Message"
        case .dismiss: return "Dismiss"
        }
    }

    var identifier: String { rawValue }
}

// MARK: - Remote Notification Payload

/// Full APNs payload structure received from server
struct RemoteNotificationPayload: Codable {
    let aps: APSPayload
    let notificationType: PushNotificationType?
    let prescriptionId: String?
    let patientId: String?
    let therapistId: String?
    let deepLink: String?
    let customData: [String: String]?

    enum CodingKeys: String, CodingKey {
        case aps
        case notificationType = "notification_type"
        case prescriptionId = "prescription_id"
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case deepLink = "deep_link"
        case customData = "custom_data"
    }

    /// Parse from raw notification userInfo dictionary
    static func from(userInfo: [AnyHashable: Any]) -> RemoteNotificationPayload? {
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(RemoteNotificationPayload.self, from: data)
    }
}

/// Apple Push Notification Service payload
struct APSPayload: Codable {
    let alert: APSAlert?
    let badge: Int?
    let sound: String?
    let contentAvailable: Int?
    let mutableContent: Int?
    let category: String?
    let threadId: String?

    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case contentAvailable = "content-available"
        case mutableContent = "mutable-content"
        case category
        case threadId = "thread-id"
    }
}

/// APNs alert content
struct APSAlert: Codable {
    let title: String?
    let subtitle: String?
    let body: String?
    let titleLocKey: String?
    let titleLocArgs: [String]?
    let bodyLocKey: String?
    let bodyLocArgs: [String]?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case body
        case titleLocKey = "title-loc-key"
        case titleLocArgs = "title-loc-args"
        case bodyLocKey = "body-loc-key"
        case bodyLocArgs = "body-loc-args"
    }
}

// MARK: - Device Token

/// Device token registration payload for server
struct DeviceTokenPayload: Encodable {
    let userId: String
    let deviceToken: String
    let platform: String = "ios"
    let appVersion: String
    let bundleId: String
    let environment: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceToken = "device_token"
        case platform
        case appVersion = "app_version"
        case bundleId = "bundle_id"
        case environment
    }

    init(userId: String, deviceToken: String) {
        self.userId = userId
        self.deviceToken = deviceToken
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        self.bundleId = Bundle.main.bundleIdentifier ?? "com.getmodus.app"

        #if DEBUG
        self.environment = "development"
        #else
        self.environment = "production"
        #endif
    }
}

// MARK: - Prescription Notification Preferences

/// User preferences for prescription notifications
struct PrescriptionNotificationPreferences: Codable {
    var newPrescriptionEnabled: Bool
    var deadline24hEnabled: Bool
    var deadline6hEnabled: Bool
    var deadline1hEnabled: Bool
    var overdueEnabled: Bool
    var therapistFollowUpEnabled: Bool

    /// Default preferences with all enabled
    static let defaults = PrescriptionNotificationPreferences(
        newPrescriptionEnabled: true,
        deadline24hEnabled: true,
        deadline6hEnabled: true,
        deadline1hEnabled: true,
        overdueEnabled: true,
        therapistFollowUpEnabled: true
    )

    enum CodingKeys: String, CodingKey {
        case newPrescriptionEnabled = "new_prescription_enabled"
        case deadline24hEnabled = "deadline_24h_enabled"
        case deadline6hEnabled = "deadline_6h_enabled"
        case deadline1hEnabled = "deadline_1h_enabled"
        case overdueEnabled = "overdue_enabled"
        case therapistFollowUpEnabled = "therapist_follow_up_enabled"
    }

    /// Check if a specific notification type is enabled
    func isEnabled(for type: PushNotificationType) -> Bool {
        switch type {
        case .prescriptionAssigned:
            return newPrescriptionEnabled
        case .prescriptionDeadline24h:
            return deadline24hEnabled
        case .prescriptionDeadline6h:
            return deadline6hEnabled
        case .prescriptionDeadline1h:
            return deadline1hEnabled
        case .prescriptionOverdue:
            return overdueEnabled
        case .therapistFollowUp:
            return therapistFollowUpEnabled
        default:
            return true
        }
    }
}

// MARK: - Notification History

/// Record of a sent notification for tracking
struct NotificationRecord: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let notificationType: PushNotificationType
    let title: String
    let body: String?
    let prescriptionId: UUID?
    let scheduledFor: Date?
    let sentAt: Date?
    let readAt: Date?
    let actionTaken: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case notificationType = "notification_type"
        case title
        case body
        case prescriptionId = "prescription_id"
        case scheduledFor = "scheduled_for"
        case sentAt = "sent_at"
        case readAt = "read_at"
        case actionTaken = "action_taken"
        case createdAt = "created_at"
    }
}
