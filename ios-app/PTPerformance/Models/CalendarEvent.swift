//
//  CalendarEvent.swift
//  PTPerformance
//
//  Created for ACP-832: Calendar Integration
//  Models for calendar synchronization
//

import Foundation
import EventKit

// MARK: - PT Calendar Event

/// Represents a calendar event managed by PTPerformance
struct PTCalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let eventType: EventType
    let sessionId: UUID?
    let calendarEventId: String?
    let notes: String?
    let location: String?

    /// Type of calendar event
    enum EventType: String, Codable, CaseIterable {
        case workout = "workout"
        case game = "game"
        case rest = "rest"
        case practice = "practice"
        case competition = "competition"

        var displayName: String {
            switch self {
            case .workout: return "Workout"
            case .game: return "Game"
            case .rest: return "Rest Day"
            case .practice: return "Practice"
            case .competition: return "Competition"
            }
        }

        var iconName: String {
            switch self {
            case .workout: return "figure.strengthtraining.traditional"
            case .game: return "sportscourt"
            case .rest: return "bed.double"
            case .practice: return "figure.run"
            case .competition: return "trophy"
            }
        }

        var color: String {
            switch self {
            case .workout: return "blue"
            case .game: return "red"
            case .rest: return "green"
            case .practice: return "orange"
            case .competition: return "purple"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        eventType: EventType,
        sessionId: UUID? = nil,
        calendarEventId: String? = nil,
        notes: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.eventType = eventType
        self.sessionId = sessionId
        self.calendarEventId = calendarEventId
        self.notes = notes
        self.location = location
    }

    /// Duration of the event in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Whether this event is in the past
    var isPast: Bool {
        endDate < Date()
    }

    /// Whether this event is happening today
    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    /// Formatted time range string
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startDate)
    }
}

// MARK: - Game Event (Imported from external calendar)

/// Represents a game or competition event imported from an external calendar
struct GameEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isHomeGame: Bool?
    let opponent: String?
    let sourceCalendarId: String
    let externalEventId: String
    let importedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        isHomeGame: Bool? = nil,
        opponent: String? = nil,
        sourceCalendarId: String,
        externalEventId: String,
        importedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isHomeGame = isHomeGame
        self.opponent = opponent
        self.sourceCalendarId = sourceCalendarId
        self.externalEventId = externalEventId
        self.importedAt = importedAt
    }

    /// Days until the game
    var daysUntil: Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: startDate)
        return components.day
    }

    /// Whether the game is upcoming
    var isUpcoming: Bool {
        startDate > Date()
    }

    /// Formatted date and time string
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}

// MARK: - Calendar Sync Settings

/// User preferences for calendar synchronization
struct CalendarSyncSettings: Codable {
    var isEnabled: Bool
    var targetCalendarId: String?
    var syncWorkouts: Bool
    var syncRestDays: Bool
    var defaultWorkoutDuration: Int // minutes
    var reminderMinutesBefore: Int?
    var importGameCalendarIds: [String]
    var autoAdjustForGames: Bool
    var lastSyncDate: Date?

    init(
        isEnabled: Bool = false,
        targetCalendarId: String? = nil,
        syncWorkouts: Bool = true,
        syncRestDays: Bool = false,
        defaultWorkoutDuration: Int = 60,
        reminderMinutesBefore: Int? = 30,
        importGameCalendarIds: [String] = [],
        autoAdjustForGames: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.targetCalendarId = targetCalendarId
        self.syncWorkouts = syncWorkouts
        self.syncRestDays = syncRestDays
        self.defaultWorkoutDuration = defaultWorkoutDuration
        self.reminderMinutesBefore = reminderMinutesBefore
        self.importGameCalendarIds = importGameCalendarIds
        self.autoAdjustForGames = autoAdjustForGames
        self.lastSyncDate = lastSyncDate
    }

    static let `default` = CalendarSyncSettings()
}

// MARK: - Calendar Info

/// Information about an available calendar
struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let color: CGColor
    let isWritable: Bool
    let source: String
    let calendarType: EKCalendarType

    init(from ekCalendar: EKCalendar) {
        self.id = ekCalendar.calendarIdentifier
        self.title = ekCalendar.title
        self.color = ekCalendar.cgColor
        self.isWritable = ekCalendar.allowsContentModifications
        self.source = ekCalendar.source.title
        self.calendarType = ekCalendar.type
    }

    /// Whether this is a local calendar
    var isLocal: Bool {
        calendarType == .local
    }

    /// Display name including source
    var displayName: String {
        "\(title) (\(source))"
    }
}

// MARK: - Sync Result

/// Result of a calendar sync operation
struct CalendarSyncResult {
    let eventsCreated: Int
    let eventsUpdated: Int
    let eventsRemoved: Int
    let errors: [CalendarSyncError]
    let syncDate: Date

    var totalChanges: Int {
        eventsCreated + eventsUpdated + eventsRemoved
    }

    var hasErrors: Bool {
        !errors.isEmpty
    }

    var summary: String {
        if hasErrors {
            return "Sync completed with \(errors.count) error(s)"
        }
        if totalChanges == 0 {
            return "Calendar is up to date"
        }
        var parts: [String] = []
        if eventsCreated > 0 { parts.append("\(eventsCreated) added") }
        if eventsUpdated > 0 { parts.append("\(eventsUpdated) updated") }
        if eventsRemoved > 0 { parts.append("\(eventsRemoved) removed") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Sync Error

/// Errors that can occur during calendar sync
enum CalendarSyncError: LocalizedError, Identifiable {
    case accessDenied
    case calendarNotFound
    case eventCreationFailed(String)
    case eventUpdateFailed(String)
    case eventDeletionFailed(String)
    case invalidSession
    case syncFailed(Error)

    var id: String {
        switch self {
        case .accessDenied: return "access_denied"
        case .calendarNotFound: return "calendar_not_found"
        case .eventCreationFailed(let id): return "creation_failed_\(id)"
        case .eventUpdateFailed(let id): return "update_failed_\(id)"
        case .eventDeletionFailed(let id): return "deletion_failed_\(id)"
        case .invalidSession: return "invalid_session"
        case .syncFailed: return "sync_failed"
        }
    }

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar Access Required"
        case .calendarNotFound:
            return "Calendar Not Found"
        case .eventCreationFailed:
            return "Couldn't Create Event"
        case .eventUpdateFailed:
            return "Couldn't Update Event"
        case .eventDeletionFailed:
            return "Couldn't Remove Event"
        case .invalidSession:
            return "Invalid Session"
        case .syncFailed:
            return "Sync Failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return "Please enable calendar access in Settings to sync your workouts."
        case .calendarNotFound:
            return "The selected calendar is no longer available. Please choose a different calendar."
        case .eventCreationFailed:
            return "We couldn't add this workout to your calendar. Please try again."
        case .eventUpdateFailed:
            return "We couldn't update this event. Please try again."
        case .eventDeletionFailed:
            return "We couldn't remove this event from your calendar. Please try again."
        case .invalidSession:
            return "This session is no longer available for scheduling."
        case .syncFailed:
            return "Calendar sync failed. Please check your connection and try again."
        }
    }
}

// MARK: - Sample Data

extension PTCalendarEvent {
    static var sample: PTCalendarEvent {
        PTCalendarEvent(
            title: "Upper Body Strength",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            eventType: .workout,
            sessionId: UUID(),
            notes: "Focus on form"
        )
    }

    static var sampleGame: PTCalendarEvent {
        PTCalendarEvent(
            title: "vs. Rival High School",
            startDate: Date().addingTimeInterval(86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 3 + 10800),
            eventType: .game,
            location: "Home Field"
        )
    }
}

extension GameEvent {
    static var sample: GameEvent {
        GameEvent(
            title: "Varsity Baseball vs. Eagles",
            startDate: Date().addingTimeInterval(86400 * 5),
            endDate: Date().addingTimeInterval(86400 * 5 + 10800),
            location: "Home Field",
            isHomeGame: true,
            opponent: "Eagles",
            sourceCalendarId: "calendar-123",
            externalEventId: "event-456"
        )
    }
}
