//
//  TimelineEvent.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  Unified timeline event model for all health events
//

import Foundation
import SwiftUI

// MARK: - Timeline Event Type

/// Types of events that can appear in the canonical timeline
enum TimelineEventType: String, Codable, CaseIterable, Hashable, Identifiable {
    case checkIn = "check_in"
    case workout = "workout"
    case sleep = "sleep"
    case recovery = "recovery"
    case vital = "vital"
    case note = "note"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .checkIn: return "Check-in"
        case .workout: return "Workout"
        case .sleep: return "Sleep"
        case .recovery: return "Recovery"
        case .vital: return "Vital"
        case .note: return "Note"
        }
    }

    /// Plural display name for filter chips
    var pluralName: String {
        switch self {
        case .checkIn: return "Check-ins"
        case .workout: return "Workouts"
        case .sleep: return "Sleep"
        case .recovery: return "Recovery"
        case .vital: return "Vitals"
        case .note: return "Notes"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .checkIn: return "checkmark.circle.fill"
        case .workout: return "figure.run"
        case .sleep: return "bed.double.fill"
        case .recovery: return "heart.fill"
        case .vital: return "waveform.path.ecg"
        case .note: return "note.text"
        }
    }

    /// Primary color for this event type
    var color: Color {
        switch self {
        case .checkIn: return .blue
        case .workout: return .orange
        case .sleep: return .indigo
        case .recovery: return .green
        case .vital: return .red
        case .note: return .gray
        }
    }
}

// MARK: - Data Source

/// Source of the timeline event data
enum TimelineDataSource: String, Codable, Hashable {
    case manual = "manual"
    case healthKit = "health_kit"
    case whoop = "whoop"
    case oura = "oura"
    case garmin = "garmin"
    case fitbit = "fitbit"
    case appleWatch = "apple_watch"
    case supabase = "supabase"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .healthKit: return "Apple Health"
        case .whoop: return "WHOOP"
        case .oura: return "Oura"
        case .garmin: return "Garmin"
        case .fitbit: return "Fitbit"
        case .appleWatch: return "Apple Watch"
        case .supabase: return "Korza Training"
        }
    }

    /// Icon for the data source
    var iconName: String {
        switch self {
        case .manual: return "hand.draw.fill"
        case .healthKit: return "heart.fill"
        case .whoop: return "w.circle.fill"
        case .oura: return "circle.dashed"
        case .garmin: return "g.circle.fill"
        case .fitbit: return "f.circle.fill"
        case .appleWatch: return "applewatch"
        case .supabase: return "server.rack"
        }
    }
}

// MARK: - Timeline Event

/// Represents a single event in the canonical timeline
struct TimelineEvent: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let eventType: TimelineEventType
    let timestamp: Date
    let title: String
    let summary: String
    let sourceType: TimelineDataSource
    let conflictsWith: [UUID]?
    let metadata: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case eventType = "event_type"
        case timestamp
        case title
        case summary
        case sourceType = "source_type"
        case conflictsWith = "conflicts_with"
        case metadata
    }
}

// MARK: - Hashable & Equatable

extension TimelineEvent: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension TimelineEvent: Equatable {
    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    /// Whether this event has conflicts with other events
    var hasConflicts: Bool {
        guard let conflicts = conflictsWith else { return false }
        return !conflicts.isEmpty
    }

    /// Number of conflicting events
    var conflictCount: Int {
        conflictsWith?.count ?? 0
    }

    /// Formatted timestamp for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Relative time string (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Date formatted for section headers
    var sectionDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                  timestamp >= weekAgo {
            return "This Week"
        } else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()),
                  timestamp >= monthAgo {
            return "This Month"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: timestamp)
        }
    }

    /// Day of week and date for timeline display
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: timestamp)
    }

    // MARK: - Metadata Accessors

    /// Get a string value from metadata
    func metadataString(for key: String) -> String? {
        metadata?[key]?.stringValue
    }

    /// Get an integer value from metadata
    func metadataInt(for key: String) -> Int? {
        metadata?[key]?.intValue
    }

    /// Get a double value from metadata
    func metadataDouble(for key: String) -> Double? {
        guard let value = metadata?[key] else { return nil }
        if let intVal = value.intValue {
            return Double(intVal)
        }
        if case .double(let val) = value {
            return val
        }
        return nil
    }
}

// MARK: - Timeline Event Detail

/// Detailed information about a timeline event for expanded view
struct TimelineEventDetail: Codable, Identifiable {
    let id: UUID
    let event: TimelineEvent
    let detailSections: [DetailSection]
    let relatedEvents: [TimelineEvent]?
    let conflictingEvents: [TimelineEvent]?

    struct DetailSection: Codable, Identifiable, Hashable {
        let id: UUID
        let title: String
        let items: [DetailItem]

        init(id: UUID = UUID(), title: String, items: [DetailItem]) {
            self.id = id
            self.title = title
            self.items = items
        }
    }

    struct DetailItem: Codable, Identifiable, Hashable {
        let id: UUID
        let label: String
        let value: String
        let icon: String?
        let valueColor: String?

        init(id: UUID = UUID(), label: String, value: String, icon: String? = nil, valueColor: String? = nil) {
            self.id = id
            self.label = label
            self.value = value
            self.icon = icon
            self.valueColor = valueColor
        }
    }
}

// MARK: - Conflict Group

/// Represents a group of events that conflict with each other
struct ConflictGroup: Identifiable, Hashable {
    let id: UUID
    let eventIds: [UUID]
    let conflictType: ConflictType
    let description: String
    let timestamp: Date

    init(id: UUID = UUID(), eventIds: [UUID], conflictType: ConflictType, description: String, timestamp: Date) {
        self.id = id
        self.eventIds = eventIds
        self.conflictType = conflictType
        self.description = description
        self.timestamp = timestamp
    }

    enum ConflictType: String, Codable, Hashable {
        case valueDiscrepancy = "value_discrepancy"
        case duplicateEntry = "duplicate_entry"
        case timeOverlap = "time_overlap"
        case sourceDisagreement = "source_disagreement"
        case missingData = "missing_data"
        case timestampMismatch = "timestamp_mismatch"
        case sourceConflict = "source_conflict"

        var displayName: String {
            switch self {
            case .valueDiscrepancy: return "Value Discrepancy"
            case .duplicateEntry: return "Duplicate Entry"
            case .timeOverlap: return "Time Overlap"
            case .sourceDisagreement: return "Source Disagreement"
            case .missingData: return "Missing Data"
            case .timestampMismatch: return "Timestamp Mismatch"
            case .sourceConflict: return "Source Conflict"
            }
        }

        var iconName: String {
            switch self {
            case .valueDiscrepancy: return "exclamationmark.triangle.fill"
            case .duplicateEntry: return "doc.on.doc.fill"
            case .timeOverlap: return "clock.badge.exclamationmark.fill"
            case .sourceDisagreement: return "arrow.triangle.2.circlepath"
            case .missingData: return "questionmark.circle.fill"
            case .timestampMismatch: return "clock.badge.exclamationmark.fill"
            case .sourceConflict: return "arrow.triangle.2.circlepath"
            }
        }

        var color: Color {
            switch self {
            case .valueDiscrepancy: return .orange
            case .duplicateEntry: return .yellow
            case .timeOverlap: return .purple
            case .sourceDisagreement: return .red
            case .missingData: return .red
            case .timestampMismatch: return .purple
            case .sourceConflict: return .blue
            }
        }
    }
}

// MARK: - ConflictGroup Extensions

extension ConflictGroup {
    /// Create from a DataConflict
    init(from conflict: DataConflict) {
        self.id = conflict.id
        self.eventIds = [conflict.id]
        self.conflictType = .valueDiscrepancy
        self.description = "Conflicting values for \(conflict.metricType.displayName)"
        self.timestamp = conflict.conflictDate
    }
}

// MARK: - Timeline Date Range

/// Predefined date ranges for timeline filtering
enum TimelineDateRange: String, CaseIterable, Identifiable {
    case today = "today"
    case week = "week"
    case month = "month"
    case threeMonths = "three_months"
    case year = "year"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .threeMonths: return "3 Months"
        case .year: return "This Year"
        case .custom: return "Custom"
        }
    }

    /// Get the date interval for this range
    func dateInterval(from referenceDate: Date = Date()) -> DateInterval {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: referenceDate)

        switch self {
        case .today:
            return DateInterval(start: startOfToday, end: referenceDate)
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday
            return DateInterval(start: weekAgo, end: referenceDate)
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) ?? startOfToday
            return DateInterval(start: monthAgo, end: referenceDate)
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: startOfToday) ?? startOfToday
            return DateInterval(start: threeMonthsAgo, end: referenceDate)
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: startOfToday) ?? startOfToday
            return DateInterval(start: yearAgo, end: referenceDate)
        case .custom:
            // Default to last month for custom
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) ?? startOfToday
            return DateInterval(start: monthAgo, end: referenceDate)
        }
    }
}

// MARK: - Sample Data

extension TimelineEvent {
    // Static UUIDs for sample data to avoid unnecessary re-renders
    private static let sampleEventID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    private static let samplePatientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()
    private static let sampleWorkoutID = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
    private static let sampleSleepID = UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID()
    private static let sampleConflictID = UUID(uuidString: "00000000-0000-0000-0000-000000000005") ?? UUID()
    private static let sampleConflictRefID = UUID(uuidString: "00000000-0000-0000-0000-000000000006") ?? UUID()

    /// Sample event for previews
    static var sample: TimelineEvent {
        TimelineEvent(
            id: sampleEventID,
            patientId: samplePatientID,
            eventType: TimelineEventType.checkIn,
            timestamp: Date(),
            title: "Morning Check-in",
            summary: "Feeling good, energy level 8/10, slept 7.5 hours",
            sourceType: TimelineDataSource.supabase,
            conflictsWith: nil,
            metadata: [
                "energy_level": AnyCodableValue.int(8),
                "sleep_hours": AnyCodableValue.double(7.5),
                "soreness_level": AnyCodableValue.int(3)
            ]
        )
    }

    /// Sample workout event
    static var sampleWorkout: TimelineEvent {
        TimelineEvent(
            id: sampleWorkoutID,
            patientId: samplePatientID,
            eventType: TimelineEventType.workout,
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            title: "Upper Body Strength",
            summary: "45 min, 12 exercises, 8,500 lbs volume",
            sourceType: TimelineDataSource.supabase,
            conflictsWith: nil,
            metadata: [
                "duration_minutes": AnyCodableValue.int(45),
                "exercise_count": AnyCodableValue.int(12),
                "total_volume": AnyCodableValue.int(8500)
            ]
        )
    }

    /// Sample sleep event
    static var sampleSleep: TimelineEvent {
        TimelineEvent(
            id: sampleSleepID,
            patientId: samplePatientID,
            eventType: TimelineEventType.sleep,
            timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            title: "Sleep Session",
            summary: "7h 32m total, 85% efficiency, 2h deep sleep",
            sourceType: TimelineDataSource.healthKit,
            conflictsWith: nil,
            metadata: [
                "total_hours": AnyCodableValue.double(7.53),
                "efficiency": AnyCodableValue.int(85),
                "deep_sleep_hours": AnyCodableValue.double(2.0)
            ]
        )
    }

    /// Sample with conflict
    static var sampleWithConflict: TimelineEvent {
        TimelineEvent(
            id: sampleConflictID,
            patientId: samplePatientID,
            eventType: TimelineEventType.vital,
            timestamp: Date(),
            title: "Heart Rate",
            summary: "Resting HR: 58 bpm (Apple Watch: 62 bpm)",
            sourceType: TimelineDataSource.whoop,
            conflictsWith: [sampleConflictRefID],
            metadata: [
                "resting_hr": AnyCodableValue.int(58),
                "alternate_hr": AnyCodableValue.int(62)
            ]
        )
    }

    /// Generate sample events for previews
    /// Uses deterministic UUIDs based on index to avoid unnecessary re-renders
    static func generateSampleEvents(count: Int = 10) -> [TimelineEvent] {
        let types = TimelineEventType.allCases
        let sources: [TimelineDataSource] = [.supabase, .healthKit, .whoop, .manual]
        let calendar = Calendar.current

        return (0..<count).map { index in
            let type = types[index % types.count]
            let source = sources[index % sources.count]
            let hoursAgo = index * 4
            let timestamp = calendar.date(byAdding: .hour, value: -hoursAgo, to: Date()) ?? Date()

            // Deterministic UUIDs based on index
            let eventID = UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", index)) ?? UUID()
            let patientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()
            let conflictID = UUID(uuidString: String(format: "00000000-0000-0000-0002-%012d", index)) ?? UUID()

            let conflicts: [UUID]? = index % 5 == 0 ? [conflictID] : nil
            return TimelineEvent(
                id: eventID,
                patientId: patientID,
                eventType: type,
                timestamp: timestamp,
                title: "\(type.displayName) Entry",
                summary: "Sample summary for \(type.displayName.lowercased()) event",
                sourceType: source,
                conflictsWith: conflicts,
                metadata: nil
            )
        }
    }
}

extension TimelineEventDetail {
    // Static UUIDs for sample data to avoid unnecessary re-renders
    private static let sampleDetailID = UUID(uuidString: "00000000-0000-0000-0000-000000000010") ?? UUID()
    private static let sampleSectionMetricsID = UUID(uuidString: "00000000-0000-0000-0000-000000000011") ?? UUID()
    private static let sampleSectionNotesID = UUID(uuidString: "00000000-0000-0000-0000-000000000012") ?? UUID()
    private static let sampleItemEnergyID = UUID(uuidString: "00000000-0000-0000-0000-000000000013") ?? UUID()
    private static let sampleItemSleepID = UUID(uuidString: "00000000-0000-0000-0000-000000000014") ?? UUID()
    private static let sampleItemSorenessID = UUID(uuidString: "00000000-0000-0000-0000-000000000015") ?? UUID()
    private static let sampleItemCommentID = UUID(uuidString: "00000000-0000-0000-0000-000000000016") ?? UUID()

    /// Sample detail for previews
    static var sample: TimelineEventDetail {
        TimelineEventDetail(
            id: sampleDetailID,
            event: .sample,
            detailSections: [
                DetailSection(
                    id: sampleSectionMetricsID,
                    title: "Metrics",
                    items: [
                        DetailItem(id: sampleItemEnergyID, label: "Energy Level", value: "8/10", icon: "bolt.fill"),
                        DetailItem(id: sampleItemSleepID, label: "Sleep Hours", value: "7.5h", icon: "bed.double.fill"),
                        DetailItem(id: sampleItemSorenessID, label: "Soreness", value: "Low (3/10)", icon: "figure.walk")
                    ]
                ),
                DetailSection(
                    id: sampleSectionNotesID,
                    title: "Notes",
                    items: [
                        DetailItem(id: sampleItemCommentID, label: "Comment", value: "Feeling well-rested and ready for training")
                    ]
                )
            ],
            relatedEvents: nil,
            conflictingEvents: nil
        )
    }
}
