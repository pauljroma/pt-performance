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
        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        scheduledDate = try container.decode(Date.self, forKey: .scheduledDate)
        status = try container.decode(ScheduleStatus.self, forKey: .status)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        reminderSent = try container.decode(Bool.self, forKey: .reminderSent)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Parse TIME type from "HH:MM:SS" string
        let timeString = try container.decode(String.self, forKey: .scheduledTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        scheduledTime = formatter.date(from: timeString) ?? Date()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "\(formatter.string(from: scheduledDate)) Session"
    }

    // Computed property: Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: scheduledDate)
    }

    // Computed property: Formatted time string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
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
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE" // Day of week
            return "\(dayFormatter.string(from: scheduledDate)) at \(formattedTime)"
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

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let isoFormatter = ISO8601DateFormatter()

        let directSession = DirectScheduledSession(
            id: id.uuidString,
            patient_id: patientId.uuidString,
            session_id: sessionId.uuidString,
            scheduled_date: isoFormatter.string(from: scheduledDate),
            scheduled_time: formatter.string(from: scheduledTime),
            status: status.rawValue,
            completed_at: completedAt.map { isoFormatter.string(from: $0) },
            reminder_sent: reminderSent,
            notes: notes,
            created_at: isoFormatter.string(from: createdAt),
            updated_at: isoFormatter.string(from: updatedAt)
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
