//
//  PatientAlert.swift
//  PTPerformance
//
//  Clinical Safety Checks - Alert model for triggered safety rules
//

import SwiftUI

// MARK: - Alert Type

/// Type of patient alert
enum AlertType: String, Codable, CaseIterable, Identifiable {
    case safety = "safety"
    case adherence = "adherence"
    case progress = "progress"
    case milestone = "milestone"
    case checkIn = "check_in"
    case workload = "workload"
    case clinical = "clinical"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .safety: return "Safety Alert"
        case .adherence: return "Adherence Alert"
        case .progress: return "Progress Alert"
        case .milestone: return "Milestone"
        case .checkIn: return "Check-In Alert"
        case .workload: return "Workload Alert"
        case .clinical: return "Clinical Alert"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .safety: return "exclamationmark.shield.fill"
        case .adherence: return "calendar.badge.exclamationmark"
        case .progress: return "chart.line.downtrend.xyaxis"
        case .milestone: return "flag.checkered"
        case .checkIn: return "person.crop.circle.badge.questionmark"
        case .workload: return "chart.bar.fill"
        case .clinical: return "cross.circle.fill"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .safety: return .red
        case .adherence: return .orange
        case .progress: return .yellow
        case .milestone: return .blue
        case .checkIn: return .purple
        case .workload: return .pink
        case .clinical: return .teal
        }
    }
}

// MARK: - Alert Severity

/// Severity level for coaching alerts (renamed to avoid conflict with ShoulderHealthModels.AlertSeverity)
enum CoachingAlertSeverity: String, Codable, CaseIterable, Identifiable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case info = "info"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .info: return "Info"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .gray
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        case .info: return "info.circle"
        }
    }

    /// Numeric priority for sorting (lower is more urgent)
    var sortPriority: Int {
        switch self {
        case .critical: return 1
        case .high: return 2
        case .medium: return 3
        case .low: return 4
        case .info: return 5
        }
    }
}

// MARK: - Alert Status

/// Status of an alert
enum AlertStatus: String, Codable, CaseIterable, Identifiable {
    case active = "active"
    case acknowledged = "acknowledged"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case dismissed = "dismissed"
    case escalated = "escalated"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .acknowledged: return "Acknowledged"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        case .escalated: return "Escalated"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .active: return .red
        case .acknowledged: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        case .escalated: return .purple
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .active: return "bell.badge.fill"
        case .acknowledged: return "eye.fill"
        case .inProgress: return "hourglass"
        case .resolved: return "checkmark.circle.fill"
        case .dismissed: return "xmark.circle.fill"
        case .escalated: return "arrow.up.circle.fill"
        }
    }

    /// Whether the alert requires action
    var requiresAction: Bool {
        switch self {
        case .active, .acknowledged, .inProgress, .escalated:
            return true
        case .resolved, .dismissed:
            return false
        }
    }
}

// MARK: - Trigger Data

/// Data that triggered the alert
struct TriggerData: Codable, Equatable, Hashable {
    let metric: String
    let value: Double
    let threshold: Double
    let unit: String?
    let baseline: Double?
    let percentChange: Double?
    let dataPointsCount: Int?
    let timeRangeStart: Date?
    let timeRangeEnd: Date?

    enum CodingKeys: String, CodingKey {
        case metric
        case value
        case threshold
        case unit
        case baseline
        case percentChange = "percent_change"
        case dataPointsCount = "data_points_count"
        case timeRangeStart = "time_range_start"
        case timeRangeEnd = "time_range_end"
    }

    /// Formatted value with unit
    var formattedValue: String {
        let unitSuffix = unit.map { " \($0)" } ?? ""
        if value == floor(value) {
            return "\(Int(value))\(unitSuffix)"
        }
        return String(format: "%.1f%@", value, unitSuffix)
    }

    /// Formatted threshold with unit
    var formattedThreshold: String {
        let unitSuffix = unit.map { " \($0)" } ?? ""
        if threshold == floor(threshold) {
            return "\(Int(threshold))\(unitSuffix)"
        }
        return String(format: "%.1f%@", threshold, unitSuffix)
    }

    /// Formatted percent change
    var formattedPercentChange: String? {
        guard let change = percentChange else { return nil }
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, change)
    }

    /// Summary description
    var summary: String {
        var parts: [String] = []
        parts.append("\(metric): \(formattedValue)")
        parts.append("Threshold: \(formattedThreshold)")
        if let change = formattedPercentChange {
            parts.append("Change: \(change)")
        }
        return parts.joined(separator: " | ")
    }
}

// MARK: - Patient Alert

/// An alert triggered by a safety rule for a specific patient
struct PatientAlert: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let ruleId: UUID?
    let alertType: AlertType
    let severity: CoachingAlertSeverity
    let status: AlertStatus
    let title: String
    let message: String
    let triggerData: TriggerData?
    let suggestedActions: [String]?
    let acknowledgedAt: Date?
    let acknowledgedBy: UUID?
    let resolvedAt: Date?
    let resolvedBy: UUID?
    let resolutionNote: String?
    let escalatedTo: UUID?
    let expiresAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case ruleId = "rule_id"
        case alertType = "alert_type"
        case severity
        case status
        case title
        case message
        case triggerData = "trigger_data"
        case suggestedActions = "suggested_actions"
        case acknowledgedAt = "acknowledged_at"
        case acknowledgedBy = "acknowledged_by"
        case resolvedAt = "resolved_at"
        case resolvedBy = "resolved_by"
        case resolutionNote = "resolution_note"
        case escalatedTo = "escalated_to"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Icon name for the alert
    var iconName: String {
        severity.iconName
    }

    /// Color for the alert
    var color: Color {
        severity.color
    }

    /// Whether the alert is still active
    var isActive: Bool {
        status == .active || status == .acknowledged || status == .inProgress || status == .escalated
    }

    /// Whether the alert has been resolved
    var isResolved: Bool {
        status == .resolved || status == .dismissed
    }

    /// Whether the alert has expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    /// Time since alert was created
    var timeSinceCreated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Formatted created date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Formatted resolved date
    var formattedResolvedDate: String? {
        guard let resolvedAt = resolvedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: resolvedAt)
    }

    /// Time to resolution
    var resolutionTime: String? {
        guard let resolvedAt = resolvedAt else { return nil }
        let interval = resolvedAt.timeIntervalSince(createdAt)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Patient Alert Input

/// Input model for creating/updating patient alerts
struct PatientAlertInput: Codable {
    var patientId: String
    var alertType: String
    var severity: String
    var title: String
    var message: String
    var ruleId: String?
    var triggerData: TriggerData?
    var suggestedActions: [String]?
    var expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case alertType = "alert_type"
        case severity
        case title
        case message
        case ruleId = "rule_id"
        case triggerData = "trigger_data"
        case suggestedActions = "suggested_actions"
        case expiresAt = "expires_at"
    }
}

// MARK: - Alert Update Input

/// Input for updating alert status
struct AlertStatusUpdate: Codable {
    var status: String
    var resolutionNote: String?
    var escalatedTo: String?

    enum CodingKeys: String, CodingKey {
        case status
        case resolutionNote = "resolution_note"
        case escalatedTo = "escalated_to"
    }
}

// MARK: - Alert Summary

/// Summary of alerts for a patient or therapist
struct AlertSummary: Codable, Equatable {
    let totalActive: Int
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let resolvedToday: Int
    let avgResolutionTimeHours: Double?

    enum CodingKeys: String, CodingKey {
        case totalActive = "total_active"
        case criticalCount = "critical_count"
        case highCount = "high_count"
        case mediumCount = "medium_count"
        case lowCount = "low_count"
        case resolvedToday = "resolved_today"
        case avgResolutionTimeHours = "avg_resolution_time_hours"
    }

    /// Whether there are any critical or high priority alerts
    var hasUrgentAlerts: Bool {
        criticalCount > 0 || highCount > 0
    }

    /// Formatted average resolution time
    var formattedAvgResolutionTime: String? {
        guard let hours = avgResolutionTimeHours else { return nil }
        if hours > 24 {
            let days = hours / 24
            return String(format: "%.1f days", days)
        }
        return String(format: "%.1f hours", hours)
    }
}

// MARK: - Sample Data

#if DEBUG
extension PatientAlert {
    static let sample = PatientAlert(
        id: UUID(),
        patientId: UUID(),
        therapistId: UUID(),
        ruleId: UUID(),
        alertType: .safety,
        severity: .high,
        status: .active,
        title: "High Pain Reported",
        message: "Patient reported pain level of 8/10 during last session",
        triggerData: TriggerData(
            metric: "pain_level",
            value: 8,
            threshold: 7,
            unit: nil,
            baseline: 4,
            percentChange: 100,
            dataPointsCount: 1,
            timeRangeStart: nil,
            timeRangeEnd: nil
        ),
        suggestedActions: [
            "Contact patient to assess current status",
            "Review recent exercise modifications",
            "Consider reducing intensity"
        ],
        acknowledgedAt: nil,
        acknowledgedBy: nil,
        resolvedAt: nil,
        resolvedBy: nil,
        resolutionNote: nil,
        escalatedTo: nil,
        expiresAt: nil,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date().addingTimeInterval(-3600)
    )

    static let sampleAlerts: [PatientAlert] = [
        sample,
        PatientAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            ruleId: UUID(),
            alertType: .adherence,
            severity: .medium,
            status: .acknowledged,
            title: "Low Adherence Warning",
            message: "Weekly adherence dropped to 55%",
            triggerData: TriggerData(
                metric: "adherence_percentage",
                value: 55,
                threshold: 70,
                unit: "%",
                baseline: 85,
                percentChange: -35.3,
                dataPointsCount: 7,
                timeRangeStart: Date().addingTimeInterval(-604800),
                timeRangeEnd: Date()
            ),
            suggestedActions: [
                "Send encouragement message",
                "Schedule check-in call"
            ],
            acknowledgedAt: Date().addingTimeInterval(-1800),
            acknowledgedBy: UUID(),
            resolvedAt: nil,
            resolvedBy: nil,
            resolutionNote: nil,
            escalatedTo: nil,
            expiresAt: nil,
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-1800)
        ),
        PatientAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            ruleId: nil,
            alertType: .milestone,
            severity: .info,
            status: .active,
            title: "Post-Op Week 6 Review",
            message: "Patient is approaching 6-week post-op milestone",
            triggerData: nil,
            suggestedActions: [
                "Schedule progress assessment",
                "Review phase advancement criteria"
            ],
            acknowledgedAt: nil,
            acknowledgedBy: nil,
            resolvedAt: nil,
            resolvedBy: nil,
            resolutionNote: nil,
            escalatedTo: nil,
            expiresAt: Date().addingTimeInterval(172800),
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

extension TriggerData {
    static let sample = TriggerData(
        metric: "pain_level",
        value: 8,
        threshold: 7,
        unit: nil,
        baseline: 4,
        percentChange: 100,
        dataPointsCount: 1,
        timeRangeStart: nil,
        timeRangeEnd: nil
    )
}

extension AlertSummary {
    static let sample = AlertSummary(
        totalActive: 5,
        criticalCount: 1,
        highCount: 2,
        mediumCount: 1,
        lowCount: 1,
        resolvedToday: 3,
        avgResolutionTimeHours: 4.5
    )
}
#endif
