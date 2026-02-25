//
//  SchedulingService.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  Refactored by Build 345 - ACP-603
//  Business logic for scheduling operations
//

import Foundation
import Supabase

// MARK: - Encodable Structs for Supabase Updates

/// Update for completing a session
private struct CompleteSessionUpdate: Encodable {
    let status: String
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
    }
}

/// Update for session notes
private struct NotesUpdate: Encodable {
    let notes: String
}

/// Update for session status
private struct StatusUpdate: Encodable {
    let status: String
}

/// Service for managing scheduled workout sessions.
///
/// Thread-safe actor that handles all CRUD operations for patient workout schedules.
/// Uses type-safe status enums and centralized date formatting for consistency.
///
/// ## Usage
/// ```swift
/// let sessions = try await SchedulingService.shared.fetchUpcomingSessions(for: patientId)
/// ```
actor SchedulingService {

    // MARK: - Singleton

    static let shared = SchedulingService()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let tableName = "scheduled_sessions"
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Formatter for DATE columns (yyyy-MM-dd)
    private let sqlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Formatter for TIME columns (HH:mm:ss)
    private let sqlTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Fetch Methods

    /// Fetch all scheduled sessions for a patient.
    ///
    /// Returns all sessions regardless of status, ordered chronologically.
    ///
    /// - Parameter patientId: The patient's UUID string
    /// - Returns: Array of scheduled sessions ordered by date and time
    /// - Throws: `SchedulingError.fetchFailed` if the database query fails
    func fetchScheduledSessions(for patientId: String) async throws -> [ScheduledSession] {
        try await fetchSessions(
            patientId: patientId,
            context: "fetchScheduledSessions"
        )
    }

    /// Fetch upcoming scheduled sessions within a date range.
    ///
    /// Returns only sessions with `scheduled` status that fall within
    /// the specified number of days from today.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - days: Number of days to look ahead (default: 30)
    /// - Returns: Array of upcoming scheduled sessions
    /// - Throws: `SchedulingError.fetchFailed` if the database query fails
    func fetchUpcomingSessions(for patientId: String, days: Int = 30) async throws -> [ScheduledSession] {
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return try await fetchSessions(
            patientId: patientId,
            status: .scheduled,
            dateRange: today...futureDate,
            context: "fetchUpcomingSessions"
        )
    }

    // MARK: - Private Query Builder

    /// Consolidated query method for fetching sessions with optional filters.
    private func fetchSessions(
        patientId: String,
        status: ScheduledSession.ScheduleStatus? = nil,
        dateRange: ClosedRange<Date>? = nil,
        context: String
    ) async throws -> [ScheduledSession] {
        do {
            var query = supabase
                .from(tableName)
                .select()
                .eq("patient_id", value: patientId)

            if let status = status {
                query = query.eq("status", value: status.rawValue)
            }

            if let range = dateRange {
                query = query
                    .gte("scheduled_date", value: dateFormatter.string(from: range.lowerBound))
                    .lte("scheduled_date", value: dateFormatter.string(from: range.upperBound))
            }

            let sessions: [ScheduledSession] = try await query
                .order("scheduled_date", ascending: true)
                .order("scheduled_time", ascending: true)
                .execute()
                .value

            return sessions
        } catch where error.isCancellation {
            throw error
        } catch {
            errorLogger.logError(error, context: "\(context)(patient=\(patientId))")
            throw SchedulingError.fetchFailed(error)
        }
    }

    // MARK: - Create Methods

    /// Schedule a new workout session.
    ///
    /// Validates that the session belongs to the patient's active program and
    /// prevents duplicate scheduling on the same date.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - sessionId: The program session UUID to schedule
    ///   - date: The date to schedule the session
    ///   - time: The time of day for the session
    ///   - notes: Optional notes for the scheduled session
    /// - Returns: The newly created ScheduledSession
    /// - Throws: `SchedulingError.duplicateSchedule` if already scheduled for this date,
    ///           `SchedulingError.invalidSession` if session doesn't belong to patient
    func scheduleSession(
        patientId: String,
        sessionId: String,
        date: Date,
        time: Date,
        notes: String? = nil
    ) async throws -> ScheduledSession {
        try await validateSessionForPatient(sessionId: sessionId, patientId: patientId)

        if try await hasExistingSchedule(patientId: patientId, sessionId: sessionId, date: date) {
            throw SchedulingError.duplicateSchedule
        }

        let newSession = ScheduledSessionInsert(
            patientId: patientId,
            sessionId: sessionId,
            scheduledDate: sqlDateFormatter.string(from: date),  // "yyyy-MM-dd"
            scheduledTime: sqlTimeFormatter.string(from: time),  // "HH:mm:ss"
            status: ScheduledSession.ScheduleStatus.scheduled.rawValue,
            reminderSent: false,
            notes: notes
        )

        do {
            let created: ScheduledSession = try await supabase
                .from(tableName)
                .insert(newSession)
                .select()
                .single()
                .execute()
                .value

            return created
        } catch {
            errorLogger.logError(error, context: "scheduleSession(patient=\(patientId), session=\(sessionId))")
            throw SchedulingError.scheduleFailed(error)
        }
    }

    // MARK: - Update Methods

    /// Reschedule an existing session to a new date and time.
    ///
    /// Updates the session status to `rescheduled` and resets the reminder flag.
    ///
    /// - Parameters:
    ///   - scheduledSessionId: The scheduled session UUID to update
    ///   - newDate: The new date for the session
    ///   - newTime: The new time for the session
    /// - Returns: The updated ScheduledSession
    /// - Throws: `SchedulingError.rescheduleFailed` if the update fails
    func rescheduleSession(
        scheduledSessionId: String,
        newDate: Date,
        newTime: Date
    ) async throws -> ScheduledSession {
        do {
            let payload = ReschedulePayload(
                scheduledDate: dateFormatter.string(from: newDate),
                scheduledTime: dateFormatter.string(from: newTime),
                status: ScheduledSession.ScheduleStatus.rescheduled.rawValue,
                reminderSent: false
            )

            let updated: ScheduledSession = try await supabase
                .from(tableName)
                .update(payload)
                .eq("id", value: scheduledSessionId)
                .select()
                .single()
                .execute()
                .value

            return updated
        } catch {
            errorLogger.logError(error, context: "rescheduleSession(id=\(scheduledSessionId))")
            throw SchedulingError.rescheduleFailed(error)
        }
    }

    /// Cancel a scheduled session.
    ///
    /// Sets the session status to `cancelled`. This is a soft delete;
    /// the session remains in the database for historical purposes.
    ///
    /// - Parameter scheduledSessionId: The scheduled session UUID to cancel
    /// - Throws: `SchedulingError.cancelFailed` if the update fails
    func cancelSession(scheduledSessionId: String) async throws {
        try await updateStatus(
            scheduledSessionId: scheduledSessionId,
            status: .cancelled,
            context: "cancelSession"
        )
    }

    /// Mark a scheduled session as completed.
    ///
    /// Sets the session status to `completed` and records the completion timestamp.
    ///
    /// - Parameter scheduledSessionId: The scheduled session UUID to complete
    /// - Returns: The updated ScheduledSession with completion details
    /// - Throws: `SchedulingError.completeFailed` if the update fails
    func completeSession(scheduledSessionId: String) async throws -> ScheduledSession {
        do {
            let updateInput = CompleteSessionUpdate(
                status: ScheduledSession.ScheduleStatus.completed.rawValue,
                completedAt: dateFormatter.string(from: Date())
            )
            let updated: ScheduledSession = try await supabase
                .from(tableName)
                .update(updateInput)
                .eq("id", value: scheduledSessionId)
                .select()
                .single()
                .execute()
                .value

            return updated
        } catch {
            errorLogger.logError(error, context: "completeSession(id=\(scheduledSessionId))")
            throw SchedulingError.completeFailed(error)
        }
    }

    /// Update notes for a scheduled session.
    ///
    /// - Parameters:
    ///   - scheduledSessionId: The scheduled session UUID to update
    ///   - notes: The new notes content
    /// - Throws: `SchedulingError.updateFailed` if the update fails
    func updateNotes(scheduledSessionId: String, notes: String) async throws {
        do {
            try await supabase
                .from(tableName)
                .update(NotesUpdate(notes: notes))
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "updateNotes(id=\(scheduledSessionId))")
            throw SchedulingError.updateFailed(error)
        }
    }

    // MARK: - Delete Methods

    /// Delete a scheduled session permanently.
    ///
    /// - Warning: This permanently removes the session. Consider using
    ///   `cancelSession` instead for soft deletion.
    ///
    /// - Parameter scheduledSessionId: The scheduled session UUID to delete
    /// - Throws: `SchedulingError.deleteFailed` if the deletion fails
    func deleteSession(scheduledSessionId: String) async throws {
        do {
            try await supabase
                .from(tableName)
                .delete()
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "deleteSession(id=\(scheduledSessionId))")
            throw SchedulingError.deleteFailed(error)
        }
    }

    // MARK: - Private Status Update Helper

    /// Update only the status of a scheduled session.
    private func updateStatus(
        scheduledSessionId: String,
        status: ScheduledSession.ScheduleStatus,
        context: String
    ) async throws {
        do {
            try await supabase
                .from(tableName)
                .update(StatusUpdate(status: status.rawValue))
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "\(context)(id=\(scheduledSessionId))")
            switch status {
            case .cancelled:
                throw SchedulingError.cancelFailed(error)
            case .completed:
                throw SchedulingError.completeFailed(error)
            default:
                throw SchedulingError.updateFailed(error)
            }
        }
    }

    // MARK: - Program Session Methods

    /// Fetch available program sessions for scheduling.
    ///
    /// Returns all sessions from the patient's active programs that can be scheduled.
    /// Sessions are ordered by their sequence within the program.
    ///
    /// - Parameter patientId: The patient's UUID string
    /// - Returns: Array of Session objects from active programs
    /// - Throws: `SchedulingError.fetchFailed` if the query fails
    func fetchAvailableProgramSessions(for patientId: String) async throws -> [Session] {
        do {
            let sessions: [Session] = try await supabase
                .from("sessions")
                .select("*, phases!inner(*, programs!inner(id, patient_id, status))")
                .eq("phases.programs.patient_id", value: patientId)
                .eq("phases.programs.status", value: "active")
                .order("sequence", ascending: true)
                .execute()
                .value
            return sessions
        } catch {
            errorLogger.logError(error, context: "fetchAvailableProgramSessions(patient=\(patientId))")
            throw SchedulingError.fetchFailed(error)
        }
    }

    // MARK: - Validation Helpers

    /// Validate that a session belongs to the patient's active program.
    private func validateSessionForPatient(sessionId: String, patientId: String) async throws {
        do {
            let result: [Session] = try await supabase
                .from("sessions")
                .select("""
                    id,
                    phases!inner (
                        id,
                        programs!inner (
                            id,
                            patient_id,
                            status
                        )
                    )
                """)
                .eq("id", value: sessionId)
                .eq("phases.programs.patient_id", value: patientId)
                .eq("phases.programs.status", value: "active")
                .execute()
                .value

            guard !result.isEmpty else {
                throw SchedulingError.invalidSession
            }
        } catch let error as SchedulingError {
            throw error
        } catch {
            errorLogger.logError(error, context: "validateSessionForPatient(session=\(sessionId), patient=\(patientId))")
            throw SchedulingError.invalidSession
        }
    }

    /// Check if a session is already scheduled for the given date.
    private func hasExistingSchedule(patientId: String, sessionId: String, date: Date) async throws -> Bool {
        do {
            let existing: [ScheduledSession] = try await supabase
                .from(tableName)
                .select("id")
                .eq("patient_id", value: patientId)
                .eq("session_id", value: sessionId)
                .eq("scheduled_date", value: dateFormatter.string(from: date))
                .neq("status", value: ScheduledSession.ScheduleStatus.cancelled.rawValue)
                .limit(1)
                .execute()
                .value

            return !existing.isEmpty
        } catch {
            errorLogger.logError(error, context: "hasExistingSchedule(patient=\(patientId), session=\(sessionId))")
            return false
        }
    }
}

// MARK: - UUID Convenience Methods

extension SchedulingService {
    /// Fetch all scheduled sessions for a patient (UUID version).
    func fetchScheduledSessions(for patientId: UUID) async throws -> [ScheduledSession] {
        try await fetchScheduledSessions(for: patientId.uuidString)
    }

    /// Fetch upcoming scheduled sessions (UUID version).
    func fetchUpcomingSessions(for patientId: UUID, days: Int = 30) async throws -> [ScheduledSession] {
        try await fetchUpcomingSessions(for: patientId.uuidString, days: days)
    }

    /// Cancel a scheduled session (UUID version).
    func cancelSession(scheduledSessionId: UUID) async throws {
        try await cancelSession(scheduledSessionId: scheduledSessionId.uuidString)
    }

    /// Mark a scheduled session as completed (UUID version).
    func completeSession(scheduledSessionId: UUID) async throws -> ScheduledSession {
        try await completeSession(scheduledSessionId: scheduledSessionId.uuidString)
    }

    /// Delete a scheduled session (UUID version).
    func deleteSession(scheduledSessionId: UUID) async throws {
        try await deleteSession(scheduledSessionId: scheduledSessionId.uuidString)
    }

    /// Update notes for a scheduled session (UUID version).
    func updateNotes(scheduledSessionId: UUID, notes: String) async throws {
        try await updateNotes(scheduledSessionId: scheduledSessionId.uuidString, notes: notes)
    }

    /// Reschedule an existing session (UUID version).
    func rescheduleSession(
        scheduledSessionId: UUID,
        newDate: Date,
        newTime: Date
    ) async throws -> ScheduledSession {
        try await rescheduleSession(
            scheduledSessionId: scheduledSessionId.uuidString,
            newDate: newDate,
            newTime: newTime
        )
    }
}

// MARK: - Supporting Types

/// Payload for inserting a new scheduled session.
private struct ScheduledSessionInsert: Encodable {
    let patientId: String
    let sessionId: String
    let scheduledDate: String  // "yyyy-MM-dd" format for DATE column
    let scheduledTime: String  // "HH:mm:ss" format for TIME column
    let status: String
    let reminderSent: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionId = "session_id"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case status
        case reminderSent = "reminder_sent"
        case notes
    }
}

/// Payload for rescheduling an existing session.
private struct ReschedulePayload: Encodable {
    let scheduledDate: String
    let scheduledTime: String
    let status: String
    let reminderSent: Bool

    enum CodingKeys: String, CodingKey {
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case status
        case reminderSent = "reminder_sent"
    }
}

/// Errors that can occur during scheduling operations.
/// User-friendly messages that avoid technical jargon.
enum SchedulingError: LocalizedError {
    /// Failed to fetch scheduled sessions from the database.
    case fetchFailed(Error)
    /// Failed to create a new scheduled session.
    case scheduleFailed(Error)
    /// Failed to reschedule an existing session.
    case rescheduleFailed(Error)
    /// Failed to cancel a scheduled session.
    case cancelFailed(Error)
    /// Failed to mark a session as completed.
    case completeFailed(Error)
    /// Failed to update session details.
    case updateFailed(Error)
    /// Failed to delete a scheduled session.
    case deleteFailed(Error)
    /// The requested session was not found in the database.
    case sessionNotFound
    /// The session does not belong to the patient's active program.
    case invalidSession
    /// A session with this ID is already scheduled for the given date.
    case duplicateSchedule

    // MARK: - User-Friendly Error Titles

    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "Couldn't Load Schedule"
        case .scheduleFailed: return "Scheduling Issue"
        case .rescheduleFailed: return "Rescheduling Issue"
        case .cancelFailed: return "Couldn't Cancel Session"
        case .completeFailed: return "Couldn't Complete Session"
        case .updateFailed: return "Couldn't Update Session"
        case .deleteFailed: return "Couldn't Remove Session"
        case .sessionNotFound: return "Session Not Found"
        case .invalidSession: return "Session Unavailable"
        case .duplicateSchedule: return "Already Scheduled"
        }
    }

    // MARK: - User-Friendly Recovery Suggestions

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "We couldn't load your scheduled sessions. Please check your connection and try again."
        case .scheduleFailed:
            return "We couldn't schedule this session right now. Please try again in a moment."
        case .rescheduleFailed:
            return "We couldn't move this session to the new time. Please try again."
        case .cancelFailed:
            return "We couldn't cancel this session right now. Please try again."
        case .completeFailed:
            return "We couldn't mark this session as complete. Don't worry - your progress is saved."
        case .updateFailed:
            return "We couldn't save your changes. Please try again."
        case .deleteFailed:
            return "We couldn't remove this session. Please try again."
        case .sessionNotFound:
            return "This session may have been removed or rescheduled. Please refresh your schedule."
        case .invalidSession:
            return "This session isn't part of your current program. Please contact your therapist if you think this is a mistake."
        case .duplicateSchedule:
            return "You already have this session scheduled for this date. Choose a different date to continue."
        }
    }

    // MARK: - Retry Logic

    /// Whether the user should be offered a retry option
    var shouldRetry: Bool {
        switch self {
        case .fetchFailed, .scheduleFailed, .rescheduleFailed, .cancelFailed,
             .completeFailed, .updateFailed, .deleteFailed:
            return true
        case .sessionNotFound, .invalidSession, .duplicateSchedule:
            return false
        }
    }

    /// The underlying error, if any.
    var underlyingError: Error? {
        switch self {
        case .fetchFailed(let error),
             .scheduleFailed(let error),
             .rescheduleFailed(let error),
             .cancelFailed(let error),
             .completeFailed(let error),
             .updateFailed(let error),
             .deleteFailed(let error):
            return error
        case .sessionNotFound, .invalidSession, .duplicateSchedule:
            return nil
        }
    }
}
