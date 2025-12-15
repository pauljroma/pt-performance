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

    let id: String
    let patientId: String
    let sessionId: String
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
        ScheduledSession(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            sessionId: UUID().uuidString,
            scheduledDate: Date().addingTimeInterval(86400), // Tomorrow
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleCompleted: ScheduledSession {
        ScheduledSession(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            sessionId: UUID().uuidString,
            scheduledDate: Date().addingTimeInterval(-86400), // Yesterday
            scheduledTime: Date(),
            status: .completed,
            completedAt: Date(),
            reminderSent: true,
            notes: "Great workout!",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
