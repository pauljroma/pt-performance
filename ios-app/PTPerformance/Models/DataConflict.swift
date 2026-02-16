//
//  DataConflict.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Models for handling data conflicts between WHOOP, Apple Health, and manual entry
//

import Foundation
import SwiftUI

// MARK: - Shared Date Formatters

private let _conflictMediumDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

private let _conflictShortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f
}()

private let _conflictShortTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .none
    f.timeStyle = .short
    return f
}()

private let _conflictMediumDateTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

// MARK: - Data Conflict

/// Represents a data conflict between multiple sources for a given metric
struct DataConflict: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let metricType: ConflictMetricType
    let conflictDate: Date
    let sources: [ConflictingSource]
    let status: ConflictStatus
    let resolvedValue: AnyCodableValue?
    let resolvedSource: String?
    let resolvedAt: Date?
    let resolvedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case metricType = "metric_type"
        case conflictDate = "conflict_date"
        case sources
        case status
        case resolvedValue = "resolved_value"
        case resolvedSource = "resolved_source"
        case resolvedAt = "resolved_at"
        case resolvedBy = "resolved_by"
    }

    // MARK: - Computed Properties

    /// Whether this conflict is still pending resolution
    var isPending: Bool {
        status == .pending
    }

    /// Whether this conflict was auto-resolved
    var isAutoResolved: Bool {
        status == .autoResolved
    }

    /// Number of conflicting sources
    var sourceCount: Int {
        sources.count
    }

    /// The source with the highest confidence
    var highestConfidenceSource: ConflictingSource? {
        sources.max(by: { $0.confidence < $1.confidence })
    }

    /// Formatted date for display
    var formattedDate: String {
        _conflictMediumDateFormatter.string(from: conflictDate)
    }

    /// Short formatted date for cards
    var shortFormattedDate: String {
        _conflictShortDateFormatter.string(from: conflictDate)
    }

    /// Relative date string (e.g., "Today", "Yesterday")
    var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(conflictDate) {
            return "Today"
        } else if calendar.isDateInYesterday(conflictDate) {
            return "Yesterday"
        } else {
            return shortFormattedDate
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DataConflict, rhs: DataConflict) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Conflicting Source

/// A single data source with its reported value
struct ConflictingSource: Codable, Identifiable, Hashable {
    var id: String { sourceType }
    let sourceType: String  // "whoop", "apple_health", "manual"
    let value: AnyCodableValue
    let timestamp: Date
    let confidence: Double  // 0-1

    enum CodingKeys: String, CodingKey {
        case sourceType = "source_type"
        case value
        case timestamp
        case confidence
    }

    // MARK: - Computed Properties

    /// Display name for the source
    var displayName: String {
        switch sourceType {
        case "whoop": return "WHOOP"
        case "apple_health": return "Apple Health"
        case "manual": return "Manual Entry"
        case "oura": return "Oura"
        case "garmin": return "Garmin"
        case "fitbit": return "Fitbit"
        default: return sourceType.capitalized
        }
    }

    /// Icon name for the source
    var iconName: String {
        switch sourceType {
        case "whoop": return "w.circle.fill"
        case "apple_health": return "heart.fill"
        case "manual": return "hand.draw.fill"
        case "oura": return "circle.dashed"
        case "garmin": return "g.circle.fill"
        case "fitbit": return "f.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    /// Color for the source
    var color: Color {
        switch sourceType {
        case "whoop": return .red
        case "apple_health": return .pink
        case "manual": return .blue
        case "oura": return .purple
        case "garmin": return .orange
        case "fitbit": return .cyan
        default: return .gray
        }
    }

    /// Confidence level as a string
    var confidenceLevel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5..<0.8: return "Medium"
        default: return "Low"
        }
    }

    /// Confidence color
    var confidenceColor: Color {
        switch confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .yellow
        default: return .orange
        }
    }

    /// Formatted value based on metric type
    func formattedValue(for metricType: ConflictMetricType) -> String {
        if let stringVal = value.stringValue {
            return stringVal
        }

        if let intVal = value.intValue {
            return "\(intVal) \(metricType.unit)"
        }

        if case .double(let doubleVal) = value {
            switch metricType {
            case .sleepDuration:
                let hours = Int(doubleVal)
                let minutes = Int((doubleVal - Double(hours)) * 60)
                return "\(hours)h \(minutes)m"
            case .sleepQuality, .recoveryScore:
                return String(format: "%.0f%%", doubleVal)
            case .heartRate:
                return String(format: "%.0f bpm", doubleVal)
            case .hrv:
                return String(format: "%.0f ms", doubleVal)
            case .steps:
                return String(format: "%.0f", doubleVal)
            case .calories:
                return String(format: "%.0f kcal", doubleVal)
            case .workout:
                return String(format: "%.0f min", doubleVal)
            case .unknown:
                return String(format: "%.1f", doubleVal)
            }
        }

        return "Unknown"
    }

    /// Formatted timestamp
    var formattedTimestamp: String {
        _conflictShortTimeFormatter.string(from: timestamp)
    }
}

// MARK: - Conflict Metric Type

/// Types of metrics that can have conflicts
enum ConflictMetricType: String, Codable, CaseIterable, Identifiable, Hashable {
    case sleepDuration = "sleep_duration"
    case sleepQuality = "sleep_quality"
    case recoveryScore = "recovery_score"
    case heartRate = "heart_rate"
    case hrv = "hrv"
    case steps = "steps"
    case calories = "calories"
    case workout = "workout"
    case unknown = "unknown"

    /// Custom decoder that falls back to `.unknown` for unrecognized values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .sleepDuration: return "Sleep Duration"
        case .sleepQuality: return "Sleep Quality"
        case .recoveryScore: return "Recovery Score"
        case .heartRate: return "Heart Rate"
        case .hrv: return "HRV"
        case .steps: return "Steps"
        case .calories: return "Calories"
        case .workout: return "Workout"
        case .unknown: return "Unknown"
        }
    }

    /// Short display name for compact views
    var shortName: String {
        switch self {
        case .sleepDuration: return "Sleep"
        case .sleepQuality: return "Quality"
        case .recoveryScore: return "Recovery"
        case .heartRate: return "HR"
        case .hrv: return "HRV"
        case .steps: return "Steps"
        case .calories: return "Cal"
        case .workout: return "Workout"
        case .unknown: return "Unknown"
        }
    }

    /// Unit for the metric
    var unit: String {
        switch self {
        case .sleepDuration: return "hours"
        case .sleepQuality: return "%"
        case .recoveryScore: return "%"
        case .heartRate: return "bpm"
        case .hrv: return "ms"
        case .steps: return "steps"
        case .calories: return "kcal"
        case .workout: return "min"
        case .unknown: return ""
        }
    }

    /// Icon name for the metric
    var iconName: String {
        switch self {
        case .sleepDuration: return "bed.double.fill"
        case .sleepQuality: return "moon.stars.fill"
        case .recoveryScore: return "heart.fill"
        case .heartRate: return "heart.circle.fill"
        case .hrv: return "waveform.path.ecg"
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .workout: return "figure.run"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Color for the metric
    var color: Color {
        switch self {
        case .sleepDuration, .sleepQuality: return .indigo
        case .recoveryScore: return .green
        case .heartRate: return .red
        case .hrv: return .purple
        case .steps: return .orange
        case .calories: return .yellow
        case .workout: return .blue
        case .unknown: return .gray
        }
    }
}

// MARK: - Conflict Status

/// Status of a data conflict
enum ConflictStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case pending = "pending"
    case autoResolved = "auto_resolved"
    case userResolved = "user_resolved"
    case dismissed = "dismissed"
    case unknown = "unknown"

    /// Custom decoder that falls back to `.unknown` for unrecognized values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var id: String { rawValue }

    /// Display name for the status
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .autoResolved: return "Auto-Resolved"
        case .userResolved: return "Resolved"
        case .dismissed: return "Dismissed"
        case .unknown: return "Unknown"
        }
    }

    /// Icon for the status
    var iconName: String {
        switch self {
        case .pending: return "exclamationmark.triangle.fill"
        case .autoResolved: return "checkmark.circle.fill"
        case .userResolved: return "checkmark.seal.fill"
        case .dismissed: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Color for the status
    var color: Color {
        switch self {
        case .pending: return .orange
        case .autoResolved: return .blue
        case .userResolved: return .green
        case .dismissed: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - Conflict Resolution Audit Entry

/// Audit log entry for conflict resolutions
struct ConflictAuditEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let conflictId: UUID
    let action: ConflictAction
    let previousStatus: ConflictStatus?
    let newStatus: ConflictStatus
    let resolvedValue: AnyCodableValue?
    let resolvedSource: String?
    let resolvedBy: UUID?
    let reason: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conflictId = "conflict_id"
        case action
        case previousStatus = "previous_status"
        case newStatus = "new_status"
        case resolvedValue = "resolved_value"
        case resolvedSource = "resolved_source"
        case resolvedBy = "resolved_by"
        case reason
        case createdAt = "created_at"
    }

    /// Formatted date for display
    var formattedDate: String {
        _conflictMediumDateTimeFormatter.string(from: createdAt)
    }
}

/// Actions that can be taken on a conflict
enum ConflictAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case created = "created"
    case autoResolved = "auto_resolved"
    case userResolved = "user_resolved"
    case dismissed = "dismissed"
    case reopened = "reopened"

    var id: String { rawValue }

    /// Display name for the action
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .autoResolved: return "Auto-Resolved"
        case .userResolved: return "Resolved by User"
        case .dismissed: return "Dismissed"
        case .reopened: return "Reopened"
        }
    }

    /// Icon for the action
    var iconName: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .autoResolved: return "sparkles"
        case .userResolved: return "hand.tap.fill"
        case .dismissed: return "xmark.circle.fill"
        case .reopened: return "arrow.counterclockwise.circle.fill"
        }
    }

    /// Color for the action
    var color: Color {
        switch self {
        case .created: return .blue
        case .autoResolved: return .purple
        case .userResolved: return .green
        case .dismissed: return .gray
        case .reopened: return .orange
        }
    }
}

// MARK: - Conflict Summary

/// Summary statistics for conflicts
struct ConflictSummary: Sendable {
    let pendingCount: Int
    let autoResolvedCount: Int
    let userResolvedCount: Int
    let dismissedCount: Int
    let totalCount: Int
    let mostCommonMetric: ConflictMetricType?
    let mostFrequentConflictSource: String?

    /// Whether there are any pending conflicts
    var hasPending: Bool {
        pendingCount > 0
    }

    /// Resolution rate percentage
    var resolutionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(userResolvedCount + autoResolvedCount) / Double(totalCount) * 100
    }
}

// MARK: - Sample Data

extension DataConflict {
    /// Sample conflict for previews
    static var sample: DataConflict {
        DataConflict(
            id: UUID(),
            patientId: UUID(),
            metricType: .sleepDuration,
            conflictDate: Date(),
            sources: [
                ConflictingSource(
                    sourceType: "whoop",
                    value: .double(7.5),
                    timestamp: Date(),
                    confidence: 0.95
                ),
                ConflictingSource(
                    sourceType: "apple_health",
                    value: .double(8.2),
                    timestamp: Date().addingTimeInterval(-300),
                    confidence: 0.85
                )
            ],
            status: .pending,
            resolvedValue: nil,
            resolvedSource: nil,
            resolvedAt: nil,
            resolvedBy: nil
        )
    }

    /// Sample resolved conflict
    static var sampleResolved: DataConflict {
        DataConflict(
            id: UUID(),
            patientId: UUID(),
            metricType: .recoveryScore,
            conflictDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            sources: [
                ConflictingSource(
                    sourceType: "whoop",
                    value: .int(72),
                    timestamp: Date(),
                    confidence: 0.9
                ),
                ConflictingSource(
                    sourceType: "manual",
                    value: .int(80),
                    timestamp: Date(),
                    confidence: 0.7
                )
            ],
            status: .userResolved,
            resolvedValue: .int(72),
            resolvedSource: "whoop",
            resolvedAt: Date(),
            resolvedBy: UUID()
        )
    }

    /// Generate sample conflicts for previews
    static func generateSampleConflicts(count: Int = 5) -> [DataConflict] {
        let metrics = ConflictMetricType.allCases
        let calendar = Calendar.current

        return (0..<count).map { index in
            let metric = metrics[index % metrics.count]
            let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            let status: ConflictStatus = index == 0 ? .pending : (index % 3 == 0 ? .autoResolved : .userResolved)

            return DataConflict(
                id: UUID(),
                patientId: UUID(),
                metricType: metric,
                conflictDate: date,
                sources: [
                    ConflictingSource(
                        sourceType: "whoop",
                        value: .double(Double.random(in: 50...100)),
                        timestamp: date,
                        confidence: Double.random(in: 0.7...0.95)
                    ),
                    ConflictingSource(
                        sourceType: "apple_health",
                        value: .double(Double.random(in: 50...100)),
                        timestamp: date,
                        confidence: Double.random(in: 0.6...0.9)
                    )
                ],
                status: status,
                resolvedValue: status == .pending ? nil : .double(Double.random(in: 50...100)),
                resolvedSource: status == .pending ? nil : "whoop",
                resolvedAt: status == .pending ? nil : date,
                resolvedBy: status == .pending ? nil : UUID()
            )
        }
    }
}
