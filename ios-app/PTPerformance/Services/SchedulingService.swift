//
//  SchedulingService.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  Business logic for scheduling operations
//

import Foundation
import Supabase

/// Service for managing scheduled workout sessions
class SchedulingService {

    // MARK: - Singleton

    static let shared = SchedulingService()

    private init() {}

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared

    // MARK: - Public Methods

    /// Fetch all scheduled sessions for the current patient
    func fetchScheduledSessions(for patientId: String) async throws -> [ScheduledSession] {
        do {
            let sessions: [ScheduledSession] = try await supabase
                .from("scheduled_sessions")
                .select()
                .eq("patient_id", value: patientId)
                .order("scheduled_date", ascending: true)
                .order("scheduled_time", ascending: true)
                .execute()
                .value

            return sessions
        } catch {
            errorLogger.logError(error, context: "fetchScheduledSessions(patient=\(patientId))")
            throw SchedulingError.fetchFailed(error)
        }
    }

    /// Fetch upcoming scheduled sessions (next N days)
    func fetchUpcomingSessions(for patientId: String, days: Int = 30) async throws -> [ScheduledSession] {
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        do {
            let sessions: [ScheduledSession] = try await supabase
                .from("scheduled_sessions")
                .select()
                .eq("patient_id", value: patientId)
                .eq("status", value: "scheduled")
                .gte("scheduled_date", value: today.iso8601String)
                .lte("scheduled_date", value: futureDate.iso8601String)
                .order("scheduled_date", ascending: true)
                .order("scheduled_time", ascending: true)
                .execute()
                .value

            return sessions
        } catch {
            errorLogger.logError(error, context: "fetchUpcomingSessions(patient=\(patientId), days=\(days))")
            throw SchedulingError.fetchFailed(error)
        }
    }

    /// Schedule a new workout session
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
            scheduledDate: date,
            scheduledTime: time,
            status: "scheduled",
            reminderSent: false,
            notes: notes
        )

        do {
            let created: ScheduledSession = try await supabase
                .from("scheduled_sessions")
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

    /// Reschedule an existing session
    func rescheduleSession(
        scheduledSessionId: String,
        newDate: Date,
        newTime: Date
    ) async throws -> ScheduledSession {
        do {
            let payload = ReschedulePayload(
                scheduledDate: newDate.iso8601String,
                scheduledTime: newTime.iso8601String,
                status: "rescheduled",
                reminderSent: false
            )

            let updated: ScheduledSession = try await supabase
                .from("scheduled_sessions")
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

    /// Cancel a scheduled session
    func cancelSession(scheduledSessionId: String) async throws {
        do {
            try await supabase
                .from("scheduled_sessions")
                .update(["status": "cancelled"])
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "cancelSession(id=\(scheduledSessionId))")
            throw SchedulingError.cancelFailed(error)
        }
    }

    /// Mark a scheduled session as completed
    func completeSession(scheduledSessionId: String) async throws -> ScheduledSession {
        do {
            let updated: ScheduledSession = try await supabase
                .from("scheduled_sessions")
                .update([
                    "status": "completed",
                    "completed_at": Date().iso8601String
                ])
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

    /// Update notes for a scheduled session
    func updateNotes(scheduledSessionId: String, notes: String) async throws {
        do {
            try await supabase
                .from("scheduled_sessions")
                .update(["notes": notes])
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "updateNotes(id=\(scheduledSessionId))")
            throw SchedulingError.updateFailed(error)
        }
    }

    /// Delete a scheduled session
    func deleteSession(scheduledSessionId: String) async throws {
        do {
            try await supabase
                .from("scheduled_sessions")
                .delete()
                .eq("id", value: scheduledSessionId)
                .execute()
        } catch {
            errorLogger.logError(error, context: "deleteSession(id=\(scheduledSessionId))")
            throw SchedulingError.deleteFailed(error)
        }
    }

    // MARK: - Helper Methods

    private func validateSessionForPatient(sessionId: String, patientId: String) async throws {
        do {
            let result: [Session] = try await supabase
                .from("sessions")
                .select("""
                    *,
                    phases!inner (
                        *,
                        programs!inner (
                            id,
                            patient_id,
                            status
                        )
                    )
                """)
                .eq("id", value: sessionId)
                .execute()
                .value

            guard result.first != nil else {
                throw SchedulingError.sessionNotFound
            }
        } catch {
            throw SchedulingError.invalidSession
        }
    }

    private func hasExistingSchedule(patientId: String, sessionId: String, date: Date) async throws -> Bool {
        do {
            let existing: [ScheduledSession] = try await supabase
                .from("scheduled_sessions")
                .select()
                .eq("patient_id", value: patientId)
                .eq("session_id", value: sessionId)
                .eq("scheduled_date", value: date.iso8601String)
                .neq("status", value: "cancelled")
                .execute()
                .value

            return !existing.isEmpty
        } catch {
            errorLogger.logError(error, context: "hasExistingSchedule(patient=\(patientId), session=\(sessionId))")
            return false
        }
    }
}

// MARK: - Supporting Types

private struct ScheduledSessionInsert: Encodable {
    let patientId: String
    let sessionId: String
    let scheduledDate: Date
    let scheduledTime: Date
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

enum SchedulingError: LocalizedError {
    case fetchFailed(Error)
    case scheduleFailed(Error)
    case rescheduleFailed(Error)
    case cancelFailed(Error)
    case completeFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case sessionNotFound
    case invalidSession
    case duplicateSchedule

    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "Failed to fetch scheduled sessions"
        case .scheduleFailed: return "Failed to schedule session"
        case .rescheduleFailed: return "Failed to reschedule session"
        case .cancelFailed: return "Failed to cancel session"
        case .completeFailed: return "Failed to mark session as completed"
        case .updateFailed: return "Failed to update session"
        case .deleteFailed: return "Failed to delete session"
        case .sessionNotFound: return "Session not found"
        case .invalidSession: return "Session does not belong to your active program"
        case .duplicateSchedule: return "You already have this session scheduled on this date"
        }
    }
}

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
