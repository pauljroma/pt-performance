//
//  CalendarSyncService.swift
//  PTPerformance
//
//  Created for ACP-832: Calendar Integration
//  Service for syncing workouts with iOS Calendar
//

import EventKit
import SwiftUI

/// Service for synchronizing PTPerformance sessions with the iOS Calendar.
///
/// Provides functionality to:
/// - Export scheduled sessions to the calendar
/// - Import game schedules from external calendars
/// - Manage the PT Performance calendar
/// - Handle calendar permissions
///
/// ## Usage
/// ```swift
/// let hasAccess = try await CalendarSyncService.shared.requestAccess()
/// if hasAccess {
///     try await CalendarSyncService.shared.syncSessionsToCalendar(sessions: sessions)
/// }
/// ```
@MainActor
final class CalendarSyncService: ObservableObject {

    // MARK: - Singleton

    static let shared = CalendarSyncService()

    // MARK: - Published Properties

    @Published private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncResult: CalendarSyncResult?
    @Published var settings: CalendarSyncSettings {
        didSet {
            saveSettings()
        }
    }

    // MARK: - Private Properties

    private let eventStore = EKEventStore()
    private let calendarName = "PT Performance"
    private let calendarIdentifierKey = "PTPerformanceCalendarIdentifier"
    private let settingsKey = "CalendarSyncSettings"
    private let eventMappingKey = "CalendarEventMapping" // Maps session ID to calendar event ID

    private var eventMapping: [String: String] {
        get {
            UserDefaults.standard.dictionary(forKey: eventMappingKey) as? [String: String] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: eventMappingKey)
        }
    }

    // MARK: - Initialization

    private init() {
        self.settings = Self.loadSettings()
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request access to the user's calendar.
    ///
    /// - Returns: `true` if access was granted, `false` otherwise
    /// - Throws: `CalendarSyncError.accessDenied` if the user denies access
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                updateAuthorizationStatus()
            }
            if !granted {
                throw CalendarSyncError.accessDenied
            }
            return granted
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    Task { @MainActor [weak self] in
                        self?.updateAuthorizationStatus()
                    }
                    if let error = error {
                        continuation.resume(throwing: CalendarSyncError.syncFailed(error))
                    } else if granted {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(throwing: CalendarSyncError.accessDenied)
                    }
                }
            }
        }
    }

    /// Check if calendar access is authorized.
    var hasCalendarAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    /// Update the current authorization status.
    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Calendar Management

    /// Get or create the PT Performance calendar.
    ///
    /// Creates a new calendar if one doesn't exist, or returns the existing one.
    ///
    /// - Returns: The PT Performance calendar
    /// - Throws: `CalendarSyncError` if calendar creation fails
    func getOrCreatePTCalendar() async throws -> EKCalendar {
        // Check for existing calendar
        if let identifier = UserDefaults.standard.string(forKey: calendarIdentifierKey),
           let existingCalendar = eventStore.calendar(withIdentifier: identifier) {
            return existingCalendar
        }

        // Look for calendar by name
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == calendarName }) {
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: calendarIdentifierKey)
            return existing
        }

        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarName

        // Find the best source for the calendar
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultSource
        } else {
            throw CalendarSyncError.calendarNotFound
        }

        // Set calendar color (blue to match PT Performance branding)
        newCalendar.cgColor = UIColor.systemBlue.cgColor

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
            return newCalendar
        } catch {
            throw CalendarSyncError.syncFailed(error)
        }
    }

    /// Get all available calendars for reading/writing.
    ///
    /// - Returns: Array of calendar information
    func getAvailableCalendars() -> [CalendarInfo] {
        eventStore.calendars(for: .event)
            .map { CalendarInfo(from: $0) }
            .sorted { $0.title < $1.title }
    }

    /// Get writable calendars only.
    ///
    /// - Returns: Array of writable calendar information
    func getWritableCalendars() -> [CalendarInfo] {
        getAvailableCalendars().filter { $0.isWritable }
    }

    // MARK: - Sync Sessions to Calendar

    /// Sync scheduled sessions to the calendar.
    ///
    /// Creates or updates calendar events for each scheduled session.
    ///
    /// - Parameter sessions: Array of scheduled sessions to sync
    /// - Returns: Result of the sync operation
    /// - Throws: `CalendarSyncError` if sync fails
    @discardableResult
    func syncSessionsToCalendar(sessions: [ScheduledSession]) async throws -> CalendarSyncResult {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        isSyncing = true
        defer { isSyncing = false }

        let calendar = try await getOrCreatePTCalendar()
        var eventsCreated = 0
        var eventsUpdated = 0
        var eventsRemoved = 0
        var errors: [CalendarSyncError] = []

        // Get existing event mapping
        var mapping = eventMapping

        // Track which sessions we've processed
        var processedSessionIds = Set<String>()

        for session in sessions where session.status == .scheduled || session.status == .rescheduled {
            let sessionIdString = session.id.uuidString
            processedSessionIds.insert(sessionIdString)

            do {
                if let existingEventId = mapping[sessionIdString],
                   let existingEvent = eventStore.event(withIdentifier: existingEventId) {
                    // Update existing event
                    updateEvent(existingEvent, from: session)
                    try eventStore.save(existingEvent, span: .thisEvent, commit: false)
                    eventsUpdated += 1
                } else {
                    // Create new event
                    let event = try createEvent(from: session, calendar: calendar)
                    try eventStore.save(event, span: .thisEvent, commit: false)
                    mapping[sessionIdString] = event.eventIdentifier
                    eventsCreated += 1
                }
            } catch {
                errors.append(.eventCreationFailed(sessionIdString))
            }
        }

        // Remove events for cancelled sessions
        let cancelledSessions = sessions.filter { $0.status == .cancelled }
        for session in cancelledSessions {
            let sessionIdString = session.id.uuidString
            if let eventId = mapping[sessionIdString],
               let event = eventStore.event(withIdentifier: eventId) {
                do {
                    try eventStore.remove(event, span: .thisEvent, commit: false)
                    mapping.removeValue(forKey: sessionIdString)
                    eventsRemoved += 1
                } catch {
                    errors.append(.eventDeletionFailed(sessionIdString))
                }
            }
        }

        // Commit all changes
        do {
            try eventStore.commit()
        } catch {
            throw CalendarSyncError.syncFailed(error)
        }

        // Save updated mapping
        eventMapping = mapping

        let result = CalendarSyncResult(
            eventsCreated: eventsCreated,
            eventsUpdated: eventsUpdated,
            eventsRemoved: eventsRemoved,
            errors: errors,
            syncDate: Date()
        )

        lastSyncResult = result
        settings.lastSyncDate = Date()

        return result
    }

    // MARK: - Export Single Session

    /// Export a single session as a calendar event.
    ///
    /// - Parameter session: The session to export
    /// - Returns: The created calendar event
    /// - Throws: `CalendarSyncError` if export fails
    @discardableResult
    func exportSessionAsEvent(session: ScheduledSession) async throws -> EKEvent {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        let calendar: EKCalendar
        if let targetId = settings.targetCalendarId,
           let targetCalendar = eventStore.calendar(withIdentifier: targetId) {
            calendar = targetCalendar
        } else {
            calendar = try await getOrCreatePTCalendar()
        }

        let event = try createEvent(from: session, calendar: calendar)

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)

            // Save mapping
            var mapping = eventMapping
            mapping[session.id.uuidString] = event.eventIdentifier
            eventMapping = mapping

            return event
        } catch {
            throw CalendarSyncError.eventCreationFailed(session.id.uuidString)
        }
    }

    // MARK: - Remove Session from Calendar

    /// Remove a session's calendar event.
    ///
    /// - Parameter sessionId: The ID of the session to remove
    /// - Throws: `CalendarSyncError` if removal fails
    func removeSessionFromCalendar(sessionId: UUID) async throws {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        let sessionIdString = sessionId.uuidString
        guard let eventId = eventMapping[sessionIdString],
              let event = eventStore.event(withIdentifier: eventId) else {
            // Event doesn't exist, nothing to remove
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            var mapping = eventMapping
            mapping.removeValue(forKey: sessionIdString)
            eventMapping = mapping
        } catch {
            throw CalendarSyncError.eventDeletionFailed(sessionIdString)
        }
    }

    // MARK: - Import Games from Calendar

    /// Import game events from an external calendar.
    ///
    /// Looks for events that appear to be games or competitions and imports them.
    ///
    /// - Parameters:
    ///   - calendar: The calendar to import from
    ///   - startDate: Start of the date range (defaults to today)
    ///   - endDate: End of the date range (defaults to 90 days from now)
    /// - Returns: Array of imported game events
    /// - Throws: `CalendarSyncError` if import fails
    func importGamesFromCalendar(
        calendar: EKCalendar,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) async throws -> [GameEvent] {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        let end = endDate ?? Calendar.current.date(byAdding: .day, value: 90, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: end,
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)

        // Filter for events that look like games
        let gameKeywords = ["game", "vs", "versus", "match", "tournament", "competition", "playoff", "championship"]

        let gameEvents = events.compactMap { event -> GameEvent? in
            let titleLower = event.title?.lowercased() ?? ""
            let isGame = gameKeywords.contains { titleLower.contains($0) }

            guard isGame else { return nil }

            return GameEvent(
                title: event.title ?? "Game",
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                isHomeGame: detectHomeGame(from: event),
                opponent: extractOpponent(from: event.title ?? ""),
                sourceCalendarId: calendar.calendarIdentifier,
                externalEventId: event.eventIdentifier
            )
        }

        return gameEvents
    }

    /// Import games from multiple calendars.
    ///
    /// - Returns: Array of all imported game events
    func importGamesFromConfiguredCalendars() async throws -> [GameEvent] {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        var allGames: [GameEvent] = []

        for calendarId in settings.importGameCalendarIds {
            if let calendar = eventStore.calendar(withIdentifier: calendarId) {
                let games = try await importGamesFromCalendar(calendar: calendar)
                allGames.append(contentsOf: games)
            }
        }

        // Sort by date
        return allGames.sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Private Helpers

    /// Create a calendar event from a scheduled session.
    private func createEvent(from session: ScheduledSession, calendar: EKCalendar) throws -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        updateEvent(event, from: session)
        return event
    }

    /// Update an existing event with session data.
    private func updateEvent(_ event: EKEvent, from session: ScheduledSession) {
        event.title = "PT Performance: \(session.displayName)"
        event.startDate = session.scheduledDateTime
        event.endDate = session.scheduledDateTime.addingTimeInterval(TimeInterval(settings.defaultWorkoutDuration * 60))

        if let notes = session.notes {
            event.notes = notes
        }

        // Add reminder if configured
        if let reminderMinutes = settings.reminderMinutesBefore {
            event.alarms = [EKAlarm(relativeOffset: TimeInterval(-reminderMinutes * 60))]
        }
    }

    /// Detect if an event is a home game based on location or title.
    private func detectHomeGame(from event: EKEvent) -> Bool? {
        let titleLower = event.title?.lowercased() ?? ""
        let locationLower = event.location?.lowercased() ?? ""

        if titleLower.contains("home") || locationLower.contains("home") {
            return true
        } else if titleLower.contains("away") || titleLower.contains("@") {
            return false
        }
        return nil
    }

    /// Extract opponent name from event title.
    private func extractOpponent(from title: String) -> String? {
        // Try to extract opponent from "vs. Opponent" or "versus Opponent" patterns
        let patterns = ["vs\\. ?(.+)", "vs (.+)", "versus (.+)", "@ (.+)"]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               let range = Range(match.range(at: 1), in: title) {
                return String(title[range]).trimmingCharacters(in: .whitespaces)
            }
        }

        return nil
    }

    // MARK: - Settings Persistence

    /// Save settings to UserDefaults.
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            ErrorLogger.shared.logError(error, context: "CalendarSyncService.saveSettings")
        }
    }

    /// Load settings from UserDefaults.
    private static func loadSettings() -> CalendarSyncSettings {
        guard let data = UserDefaults.standard.data(forKey: "CalendarSyncSettings"),
              let settings = try? JSONDecoder().decode(CalendarSyncSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    // MARK: - Cleanup

    /// Remove all PT Performance events from the calendar.
    ///
    /// Use with caution - this removes all synced events.
    func removeAllSyncedEvents() async throws {
        guard hasCalendarAccess else {
            throw CalendarSyncError.accessDenied
        }

        for (_, eventId) in eventMapping {
            if let event = eventStore.event(withIdentifier: eventId) {
                try? eventStore.remove(event, span: .thisEvent, commit: false)
            }
        }

        try eventStore.commit()
        eventMapping = [:]
    }
}
