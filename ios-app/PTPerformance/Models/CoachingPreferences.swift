//
//  CoachingPreferences.swift
//  PTPerformance
//
//  Exception-Based Coaching - Therapist preferences for alerts and digests
//

import SwiftUI

// MARK: - Digest Frequency

/// Frequency for exception digest notifications
enum DigestFrequency: String, Codable, CaseIterable, Identifiable {
    case realtime = "realtime"
    case hourly = "hourly"
    case twiceDaily = "twice_daily"
    case daily = "daily"
    case weekly = "weekly"
    case disabled = "disabled"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .realtime: return "Real-time"
        case .hourly: return "Hourly"
        case .twiceDaily: return "Twice Daily"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .disabled: return "Disabled"
        }
    }

    /// Description for settings
    var description: String {
        switch self {
        case .realtime:
            return "Get notified immediately for all alerts"
        case .hourly:
            return "Receive a summary every hour"
        case .twiceDaily:
            return "Receive summaries at 8 AM and 4 PM"
        case .daily:
            return "Receive a daily summary each morning"
        case .weekly:
            return "Receive a weekly summary on Mondays"
        case .disabled:
            return "No digest notifications"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .realtime: return "bolt.fill"
        case .hourly: return "clock.fill"
        case .twiceDaily: return "clock.badge.checkmark.fill"
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .disabled: return "bell.slash.fill"
        }
    }

    /// Whether this frequency is enabled
    var isEnabled: Bool {
        self != .disabled
    }
}

// MARK: - Notification Channel

/// Channels for receiving notifications
enum NotificationChannel: String, Codable, CaseIterable, Identifiable {
    case push = "push"
    case email = "email"
    case sms = "sms"
    case inApp = "in_app"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .push: return "Push Notifications"
        case .email: return "Email"
        case .sms: return "SMS"
        case .inApp: return "In-App"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .push: return "bell.badge.fill"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .inApp: return "app.badge.fill"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .push: return .red
        case .email: return .blue
        case .sms: return .green
        case .inApp: return .purple
        }
    }
}

// MARK: - Alert Priority Filter

/// Minimum priority level for notifications
enum AlertPriorityFilter: String, Codable, CaseIterable, Identifiable {
    case all = "all"
    case mediumAndAbove = "medium_and_above"
    case highAndAbove = "high_and_above"
    case criticalOnly = "critical_only"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .all: return "All Priorities"
        case .mediumAndAbove: return "Medium and Above"
        case .highAndAbove: return "High and Above"
        case .criticalOnly: return "Critical Only"
        }
    }

    /// Description for settings
    var description: String {
        switch self {
        case .all:
            return "Receive notifications for all priority levels"
        case .mediumAndAbove:
            return "Only medium, high, and critical alerts"
        case .highAndAbove:
            return "Only high and critical alerts"
        case .criticalOnly:
            return "Only critical alerts"
        }
    }
}

// MARK: - Quiet Hours

/// Quiet hours configuration
struct QuietHours: Codable, Equatable, Hashable {
    var isEnabled: Bool
    var startHour: Int          // 0-23
    var startMinute: Int        // 0-59
    var endHour: Int            // 0-23
    var endMinute: Int          // 0-59
    var timezone: String
    var allowCritical: Bool     // Allow critical alerts during quiet hours

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case startHour = "start_hour"
        case startMinute = "start_minute"
        case endHour = "end_hour"
        case endMinute = "end_minute"
        case timezone
        case allowCritical = "allow_critical"
    }

    /// Formatted start time
    var formattedStartTime: String {
        formatTime(hour: startHour, minute: startMinute)
    }

    /// Formatted end time
    var formattedEndTime: String {
        formatTime(hour: endHour, minute: endMinute)
    }

    /// Format time for display
    private func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }

    /// Summary description
    var summary: String {
        if isEnabled {
            let criticalNote = allowCritical ? " (critical alerts allowed)" : ""
            return "\(formattedStartTime) - \(formattedEndTime)\(criticalNote)"
        }
        return "Disabled"
    }

    /// Default quiet hours (10 PM - 7 AM)
    static let `default` = QuietHours(
        isEnabled: false,
        startHour: 22,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        timezone: TimeZone.current.identifier,
        allowCritical: true
    )
}

// MARK: - Exception Type Preferences

/// Preferences for specific exception types
struct ExceptionTypePreference: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let exceptionType: String
    var isEnabled: Bool
    var priorityOverride: String?
    var customThreshold: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case exceptionType = "exception_type"
        case isEnabled = "is_enabled"
        case priorityOverride = "priority_override"
        case customThreshold = "custom_threshold"
    }
}

// MARK: - Coaching Preferences

/// Therapist preferences for exception-based coaching
struct CoachingPreferences: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let therapistId: UUID

    // Notification settings
    var digestFrequency: DigestFrequency
    var enabledChannels: [NotificationChannel]
    var priorityFilter: AlertPriorityFilter
    var quietHours: QuietHours

    // Exception settings
    var autoAcknowledgeInfo: Bool
    var defaultSnoozeHours: Int
    var showResolvedAlerts: Bool
    var resolvedAlertRetentionDays: Int

    // Dashboard preferences
    var dashboardSortOrder: String
    var compactView: Bool
    var showMetricTrends: Bool
    var highlightUrgent: Bool

    // Email digest settings
    var emailDigestEnabled: Bool
    var emailDigestTime: String?         // HH:mm format
    var includeResolvedInDigest: Bool
    var digestIncludeCharts: Bool

    // Exception type specific settings
    var exceptionTypePreferences: [ExceptionTypePreference]?

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case digestFrequency = "digest_frequency"
        case enabledChannels = "enabled_channels"
        case priorityFilter = "priority_filter"
        case quietHours = "quiet_hours"
        case autoAcknowledgeInfo = "auto_acknowledge_info"
        case defaultSnoozeHours = "default_snooze_hours"
        case showResolvedAlerts = "show_resolved_alerts"
        case resolvedAlertRetentionDays = "resolved_alert_retention_days"
        case dashboardSortOrder = "dashboard_sort_order"
        case compactView = "compact_view"
        case showMetricTrends = "show_metric_trends"
        case highlightUrgent = "highlight_urgent"
        case emailDigestEnabled = "email_digest_enabled"
        case emailDigestTime = "email_digest_time"
        case includeResolvedInDigest = "include_resolved_in_digest"
        case digestIncludeCharts = "digest_include_charts"
        case exceptionTypePreferences = "exception_type_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Whether push notifications are enabled
    var pushEnabled: Bool {
        enabledChannels.contains(.push)
    }

    /// Whether email notifications are enabled
    var emailEnabled: Bool {
        enabledChannels.contains(.email)
    }

    /// Formatted digest time
    var formattedDigestTime: String? {
        guard let timeString = emailDigestTime else { return nil }
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"

        guard let date = inputFormatter.date(from: timeString) else { return timeString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        return outputFormatter.string(from: date)
    }

    /// Number of enabled channels
    var enabledChannelCount: Int {
        enabledChannels.count
    }

    /// Summary of notification settings
    var notificationSummary: String {
        if digestFrequency == .disabled {
            return "Notifications disabled"
        }
        let channels = enabledChannels.map { $0.displayName }.joined(separator: ", ")
        return "\(digestFrequency.displayName) via \(channels)"
    }

    /// Whether any real-time notifications are enabled
    var hasRealtimeNotifications: Bool {
        digestFrequency == .realtime && !enabledChannels.isEmpty
    }
}

// MARK: - Coaching Preferences Input

/// Input model for updating coaching preferences
struct CoachingPreferencesInput: Codable {
    var digestFrequency: String?
    var enabledChannels: [String]?
    var priorityFilter: String?
    var quietHours: QuietHours?
    var autoAcknowledgeInfo: Bool?
    var defaultSnoozeHours: Int?
    var showResolvedAlerts: Bool?
    var resolvedAlertRetentionDays: Int?
    var dashboardSortOrder: String?
    var compactView: Bool?
    var showMetricTrends: Bool?
    var highlightUrgent: Bool?
    var emailDigestEnabled: Bool?
    var emailDigestTime: String?
    var includeResolvedInDigest: Bool?
    var digestIncludeCharts: Bool?

    enum CodingKeys: String, CodingKey {
        case digestFrequency = "digest_frequency"
        case enabledChannels = "enabled_channels"
        case priorityFilter = "priority_filter"
        case quietHours = "quiet_hours"
        case autoAcknowledgeInfo = "auto_acknowledge_info"
        case defaultSnoozeHours = "default_snooze_hours"
        case showResolvedAlerts = "show_resolved_alerts"
        case resolvedAlertRetentionDays = "resolved_alert_retention_days"
        case dashboardSortOrder = "dashboard_sort_order"
        case compactView = "compact_view"
        case showMetricTrends = "show_metric_trends"
        case highlightUrgent = "highlight_urgent"
        case emailDigestEnabled = "email_digest_enabled"
        case emailDigestTime = "email_digest_time"
        case includeResolvedInDigest = "include_resolved_in_digest"
        case digestIncludeCharts = "digest_include_charts"
    }
}

// MARK: - Sample Data

#if DEBUG
extension CoachingPreferences {
    static let sample = CoachingPreferences(
        id: UUID(),
        therapistId: UUID(),
        digestFrequency: .daily,
        enabledChannels: [.push, .email, .inApp],
        priorityFilter: .mediumAndAbove,
        quietHours: QuietHours(
            isEnabled: true,
            startHour: 22,
            startMinute: 0,
            endHour: 7,
            endMinute: 0,
            timezone: "America/New_York",
            allowCritical: true
        ),
        autoAcknowledgeInfo: true,
        defaultSnoozeHours: 24,
        showResolvedAlerts: true,
        resolvedAlertRetentionDays: 7,
        dashboardSortOrder: "priority",
        compactView: false,
        showMetricTrends: true,
        highlightUrgent: true,
        emailDigestEnabled: true,
        emailDigestTime: "08:00",
        includeResolvedInDigest: false,
        digestIncludeCharts: true,
        exceptionTypePreferences: [
            ExceptionTypePreference(
                id: UUID(),
                exceptionType: "pain_increase",
                isEnabled: true,
                priorityOverride: "urgent",
                customThreshold: 6
            ),
            ExceptionTypePreference(
                id: UUID(),
                exceptionType: "low_adherence",
                isEnabled: true,
                priorityOverride: nil,
                customThreshold: 60
            )
        ],
        createdAt: Date(),
        updatedAt: Date()
    )

    static let minimal = CoachingPreferences(
        id: UUID(),
        therapistId: UUID(),
        digestFrequency: .disabled,
        enabledChannels: [.inApp],
        priorityFilter: .criticalOnly,
        quietHours: .default,
        autoAcknowledgeInfo: false,
        defaultSnoozeHours: 48,
        showResolvedAlerts: false,
        resolvedAlertRetentionDays: 3,
        dashboardSortOrder: "date",
        compactView: true,
        showMetricTrends: false,
        highlightUrgent: true,
        emailDigestEnabled: false,
        emailDigestTime: nil,
        includeResolvedInDigest: false,
        digestIncludeCharts: false,
        exceptionTypePreferences: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension QuietHours {
    static let sample = QuietHours(
        isEnabled: true,
        startHour: 22,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        timezone: "America/New_York",
        allowCritical: true
    )
}
#endif
