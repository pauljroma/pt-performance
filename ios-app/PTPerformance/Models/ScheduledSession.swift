//
//  ScheduledSession.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  Model for patient scheduled workout sessions
//

import Foundation

/// Represents a scheduled workout session
struct ScheduledSession: Codable, Identifiable, Hashable {

    // MARK: - Static Formatters

    private static let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let timeOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    let id: UUID
    let patientId: UUID
    let sessionId: UUID
    let scheduledDate: Date
    let scheduledTime: Date
    let status: ScheduleStatus
    let completedAt: Date?
    let reminderSent: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case status
        case completedAt = "completed_at"
        case reminderSent = "reminder_sent"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        patientId: UUID,
        sessionId: UUID,
        scheduledDate: Date,
        scheduledTime: Date,
        status: ScheduleStatus,
        completedAt: Date?,
        reminderSent: Bool,
        notes: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.patientId = patientId
        self.sessionId = sessionId
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.status = status
        self.completedAt = completedAt
        self.reminderSent = reminderSent
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        sessionId = container.safeUUID(forKey: .sessionId)

        // Date fields with fallback
        scheduledDate = container.safeDate(forKey: .scheduledDate)

        // Enum with fallback
        status = container.safeEnum(ScheduleStatus.self, forKey: .status, default: .scheduled)

        // Optional date
        completedAt = container.safeOptionalDate(forKey: .completedAt)

        // Bool with fallback
        reminderSent = container.safeBool(forKey: .reminderSent, default: false)

        // Optional string
        notes = container.safeOptionalString(forKey: .notes)

        // Date fields with fallback
        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)

        // Parse TIME type from "HH:MM:SS" string with fallback
        scheduledTime = container.safeTime(forKey: .scheduledTime)
    }

    enum ScheduleStatus: String, Codable {
        case scheduled
        case completed
        case cancelled
        case rescheduled

        var displayName: String {
            switch self {
            case .scheduled: return "Scheduled"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            case .rescheduled: return "Rescheduled"
            }
        }

        var color: String {
            switch self {
            case .scheduled: return "blue"
            case .completed: return "green"
            case .cancelled: return "red"
            case .rescheduled: return "orange"
            }
        }
    }

    // Computed property: Combined date and time
    var scheduledDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute

        return calendar.date(from: combinedComponents) ?? scheduledDate
    }

    // Computed property: Is upcoming
    var isUpcoming: Bool {
        scheduledDateTime > Date() && status == .scheduled
    }

    // Computed property: Is past due
    var isPastDue: Bool {
        scheduledDateTime < Date() && status == .scheduled
    }

    // Computed property: Display name (uses notes or formatted date since session name requires join)
    var displayName: String {
        if let notes = notes, !notes.isEmpty {
            return notes
        }
        return "\(Self.dayOfWeekFormatter.string(from: scheduledDate)) Session"
    }

    // Computed property: Formatted date string
    var formattedDate: String {
        Self.mediumDateFormatter.string(from: scheduledDate)
    }

    // Computed property: Formatted time string
    var formattedTime: String {
        Self.shortTimeFormatter.string(from: scheduledTime)
    }

    // Computed property: Relative time string (e.g., "Tomorrow at 2:00 PM")
    var relativeTimeString: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(scheduledDate) {
            return "Today at \(formattedTime)"
        } else if calendar.isDateInTomorrow(scheduledDate) {
            return "Tomorrow at \(formattedTime)"
        } else if let daysUntil = calendar.dateComponents([.day], from: Date(), to: scheduledDate).day,
                  daysUntil >= 0 && daysUntil <= 7 {
            return "\(Self.dayOfWeekFormatter.string(from: scheduledDate)) at \(formattedTime)"
        } else {
            return "\(formattedDate) at \(formattedTime)"
        }
    }
}

// MARK: - Sample Data

extension ScheduledSession {
    static var sample: ScheduledSession {
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date().addingTimeInterval(86400), // Tomorrow
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        return session
    }

    static var sampleCompleted: ScheduledSession {
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date().addingTimeInterval(-86400), // Yesterday
            scheduledTime: Date(),
            status: .completed,
            completedAt: Date(),
            reminderSent: true,
            notes: "Great workout!",
            createdAt: Date(),
            updatedAt: Date()
        )
        return session
    }

    // Internal helper for creating instances (bypasses custom decoder)
    static func __createDirectly(
        id: UUID,
        patientId: UUID,
        sessionId: UUID,
        scheduledDate: Date,
        scheduledTime: Date,
        status: ScheduleStatus,
        completedAt: Date?,
        reminderSent: Bool,
        notes: String?,
        createdAt: Date,
        updatedAt: Date
    ) -> ScheduledSession {
        // Create a properly encodable struct
        struct DirectScheduledSession: Codable {
            let id: String
            let patient_id: String
            let session_id: String
            let scheduled_date: String
            let scheduled_time: String
            let status: String
            let completed_at: String?
            let reminder_sent: Bool
            let notes: String?
            let created_at: String
            let updated_at: String
        }

        let directSession = DirectScheduledSession(
            id: id.uuidString,
            patient_id: patientId.uuidString,
            session_id: sessionId.uuidString,
            scheduled_date: iso8601Formatter.string(from: scheduledDate),
            scheduled_time: timeOnlyFormatter.string(from: scheduledTime),
            status: status.rawValue,
            completed_at: completedAt.map { iso8601Formatter.string(from: $0) },
            reminder_sent: reminderSent,
            notes: notes,
            created_at: iso8601Formatter.string(from: createdAt),
            updated_at: iso8601Formatter.string(from: updatedAt)
        )

        do {
            let data = try JSONEncoder().encode(directSession)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ScheduledSession.self, from: data)
        } catch {
            // Fallback: Create a minimal valid session using direct initialization
            // This should never fail with valid input, but provides safety
            return ScheduledSession(
                id: id,
                patientId: patientId,
                sessionId: sessionId,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                status: status,
                completedAt: completedAt,
                reminderSent: reminderSent,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
}
