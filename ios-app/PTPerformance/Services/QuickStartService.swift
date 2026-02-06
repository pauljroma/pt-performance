//
//  QuickStartService.swift
//  PTPerformance
//
//  ACP-501: One-Tap Start Today's Workout
//  Service for quick-start workout functionality - auto-detects today's scheduled session
//  and pre-loads workout data for immediate execution without dialogs or confirmations.
//

import SwiftUI

// MARK: - Quick Start Result

/// Result type for quick start operation
enum QuickStartResult {
    /// Successfully found and loaded today's workout
    case ready(session: Session, exercises: [Exercise])
    /// No workout scheduled for today
    case noWorkoutToday
    /// Multiple workouts scheduled - returns the next uncompleted one
    case multipleWorkouts(session: Session, exercises: [Exercise], remainingCount: Int)
    /// Today's workout already completed
    case alreadyCompleted(session: Session)
    /// Error occurred during loading
    case error(QuickStartError)
}

/// Errors that can occur during quick start
enum QuickStartError: LocalizedError {
    case notAuthenticated
    case fetchFailed(Error)
    case noActiveProgram

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to start your workout"
        case .fetchFailed:
            return "Couldn't load your workout"
        case .noActiveProgram:
            return "No active program assigned"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Sign in with your account to access your workouts."
        case .fetchFailed:
            return "Check your connection and try again."
        case .noActiveProgram:
            return "Contact your therapist to get a program assigned."
        }
    }
}

// MARK: - Quick Start Service

/// Service for one-tap workout start functionality
/// Fetches today's scheduled session and pre-loads workout data for immediate execution
@MainActor
class QuickStartService: ObservableObject {

    // MARK: - Singleton

    static let shared = QuickStartService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var result: QuickStartResult?
    @Published var lastError: QuickStartError?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // Cached session for quick navigation
    private var cachedSession: Session?
    private var cachedExercises: [Exercise] = []
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetch and prepare today's workout for immediate start
    /// Returns the result indicating workout status and data
    func prepareQuickStart() async -> QuickStartResult {
        logger.log("🚀 [QuickStart] Preparing quick start...", level: .diagnostic)

        isLoading = true
        defer { isLoading = false }

        // Check authentication
        guard let patientId = supabase.userId else {
            let error = QuickStartError.notAuthenticated
            lastError = error
            result = .error(error)
            logger.log("❌ [QuickStart] Not authenticated", level: .error)
            return .error(error)
        }

        // Check cache validity
        if let cached = cachedSession,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration,
           !cachedExercises.isEmpty {
            logger.log("✅ [QuickStart] Using cached session: \(cached.name)", level: .success)
            let cachedResult = QuickStartResult.ready(session: cached, exercises: cachedExercises)
            result = cachedResult
            return cachedResult
        }

        do {
            // Fetch today's scheduled sessions
            let todayResult = try await fetchTodaysSessions(patientId: patientId)
            result = todayResult
            return todayResult
        } catch {
            let quickStartError = QuickStartError.fetchFailed(error)
            lastError = quickStartError
            result = .error(quickStartError)
            logger.log("❌ [QuickStart] Fetch failed: \(error.localizedDescription)", level: .error)
            return .error(quickStartError)
        }
    }

    /// Check if quick start is available (has a workout ready)
    func checkQuickStartAvailable() async -> Bool {
        let result = await prepareQuickStart()
        switch result {
        case .ready, .multipleWorkouts:
            return true
        case .noWorkoutToday, .alreadyCompleted, .error:
            return false
        }
    }

    /// Get the cached session if available (for display purposes)
    func getCachedSession() -> Session? {
        guard let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        return cachedSession
    }

    /// Get the cached exercises if available
    func getCachedExercises() -> [Exercise] {
        guard let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return []
        }
        return cachedExercises
    }

    /// Clear the cache (call when workout is completed)
    func clearCache() {
        cachedSession = nil
        cachedExercises = []
        cacheTimestamp = nil
        result = nil
        logger.log("🗑️ [QuickStart] Cache cleared", level: .diagnostic)
    }

    /// Refresh data (invalidate cache and refetch)
    func refresh() async -> QuickStartResult {
        clearCache()
        return await prepareQuickStart()
    }

    // MARK: - Private Methods

    /// Fetch today's scheduled sessions and determine the appropriate result
    private func fetchTodaysSessions(patientId: String) async throws -> QuickStartResult {
        logger.log("📱 [QuickStart] Fetching today's sessions for patient: \(patientId)", level: .diagnostic)

        // Get today's date string (YYYY-MM-DD)
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        logger.log("📱 [QuickStart] Today's date: \(today)", level: .diagnostic)

        // First, check for explicitly scheduled sessions
        let scheduledSessions = try await fetchScheduledSessions(patientId: patientId, date: String(today))

        if !scheduledSessions.isEmpty {
            // Filter to uncompleted sessions
            let uncompletedSessions = scheduledSessions.filter { $0.status == .scheduled }

            if uncompletedSessions.isEmpty {
                // All scheduled sessions are completed
                if let lastSession = scheduledSessions.first(where: { $0.status == .completed }) {
                    // Fetch the actual session for display
                    if let session = try await fetchSessionById(sessionId: lastSession.sessionId.uuidString) {
                        return .alreadyCompleted(session: session)
                    }
                }
                return .noWorkoutToday
            }

            // Get the first uncompleted scheduled session
            if let nextScheduled = uncompletedSessions.first {
                let session = try await fetchSessionById(sessionId: nextScheduled.sessionId.uuidString)

                if let session = session {
                    let exercises = try await fetchExercises(for: session)

                    // Cache the results
                    cachedSession = session
                    cachedExercises = exercises
                    cacheTimestamp = Date()

                    if uncompletedSessions.count > 1 {
                        return .multipleWorkouts(
                            session: session,
                            exercises: exercises,
                            remainingCount: uncompletedSessions.count - 1
                        )
                    }

                    return .ready(session: session, exercises: exercises)
                }
            }
        }

        // Fall back to program-based lookup (next session in sequence)
        let programSession = try await fetchNextProgramSession(patientId: patientId)

        if let session = programSession {
            // Check if already completed
            if session.isCompleted {
                return .alreadyCompleted(session: session)
            }

            let exercises = try await fetchExercises(for: session)

            // Cache the results
            cachedSession = session
            cachedExercises = exercises
            cacheTimestamp = Date()

            return .ready(session: session, exercises: exercises)
        }

        return .noWorkoutToday
    }

    /// Fetch scheduled sessions for a specific date
    private func fetchScheduledSessions(patientId: String, date: String) async throws -> [ScheduledSession] {
        logger.log("📱 [QuickStart] Checking scheduled_sessions for: \(date)", level: .diagnostic)

        // Updated struct to handle nullable fields from enrollment-based workouts
        struct ScheduledSessionRow: Codable {
            let id: String
            let session_id: String?  // Nullable for enrollment-based workouts
            let status: String
            let scheduled_date: String
            let scheduled_time: String?  // Nullable for enrollment-based workouts
            let patient_id: String
            let reminder_sent: Bool?
            let notes: String?
            let created_at: String
            let updated_at: String
            // New fields for enrollment-based workouts
            let enrollment_id: String?
            let workout_template_id: String?
            let workout_name: String?
        }

        let response = try await supabase.client
            .from("scheduled_sessions")
            .select("*")
            .eq("patient_id", value: patientId)
            .eq("scheduled_date", value: date)
            .order("created_at", ascending: true)  // Changed from scheduled_time which may be null
            .execute()

        let decoder = JSONDecoder()
        let rows = try decoder.decode([ScheduledSessionRow].self, from: response.data)

        logger.log("📱 [QuickStart] Found \(rows.count) scheduled sessions", level: .diagnostic)

        // Convert to ScheduledSession model - only include rows with session_id (old-style)
        // Enrollment-based workouts are handled differently via enrollment flow
        let sessions = rows.compactMap { row -> ScheduledSession? in
            guard let id = UUID(uuidString: row.id),
                  let patientIdUUID = UUID(uuidString: row.patient_id) else {
                return nil
            }

            // For enrollment-based workouts (no session_id), we still want to know they exist
            // but we'll handle them through a different flow
            let sessionId: UUID
            if let sessionIdString = row.session_id, let uuid = UUID(uuidString: sessionIdString) {
                sessionId = uuid
            } else if row.enrollment_id != nil {
                // Enrollment-based workout - log it but skip for now
                logger.log("📱 [QuickStart] Found enrollment workout: \(row.workout_name ?? "Unknown")", level: .diagnostic)
                // TODO: Handle enrollment-based workouts in a future update
                return nil
            } else {
                return nil
            }

            let status: ScheduledSession.ScheduleStatus
            switch row.status {
            case "scheduled": status = .scheduled
            case "completed": status = .completed
            case "cancelled": status = .cancelled
            case "rescheduled": status = .rescheduled
            default: status = .scheduled
            }

            // Parse dates
            let isoFormatter = ISO8601DateFormatter()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            let scheduledDate = isoFormatter.date(from: row.scheduled_date + "T00:00:00Z") ?? Date()
            let scheduledTime: Date
            if let timeString = row.scheduled_time {
                scheduledTime = timeFormatter.date(from: timeString) ?? Date()
            } else {
                // Default to 9:00 AM for enrollment-based workouts without time
                scheduledTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            }
            let createdAt = isoFormatter.date(from: row.created_at) ?? Date()
            let updatedAt = isoFormatter.date(from: row.updated_at) ?? Date()

            return ScheduledSession.__createDirectly(
                id: id,
                patientId: patientIdUUID,
                sessionId: sessionId,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                status: status,
                completedAt: nil,
                reminderSent: row.reminder_sent ?? false,
                notes: row.notes,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }

        return sessions
    }

    /// Fetch a session by ID
    private func fetchSessionById(sessionId: String) async throws -> Session? {
        logger.log("📱 [QuickStart] Fetching session by ID: \(sessionId)", level: .diagnostic)

        let response = try await supabase.client
            .from("sessions")
            .select("*")
            .eq("id", value: sessionId)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sessions = try decoder.decode([Session].self, from: response.data)

        if let session = sessions.first {
            logger.log("✅ [QuickStart] Found session: \(session.name)", level: .success)
        }

        return sessions.first
    }

    /// Fetch next program session (fallback when no explicit schedule)
    private func fetchNextProgramSession(patientId: String) async throws -> Session? {
        logger.log("📱 [QuickStart] Falling back to program-based session lookup", level: .diagnostic)

        // Query sessions via program chain - get first uncompleted session
        let response = try await supabase.client
            .from("sessions")
            .select("""
                *,
                phases!inner(
                    id,
                    name,
                    program_id,
                    programs!inner(
                        id,
                        name,
                        patient_id,
                        status
                    )
                )
            """)
            .eq("phases.programs.patient_id", value: patientId)
            .eq("phases.programs.status", value: "active")
            .order("sequence", ascending: true)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sessions = try decoder.decode([Session].self, from: response.data)

        if let session = sessions.first {
            logger.log("✅ [QuickStart] Found program session: \(session.name)", level: .success)
            return session
        }

        // Build 444: Try enrolled programs via RPC if direct program lookup fails
        logger.log("📱 [QuickStart] No direct program, trying enrolled programs via RPC...", level: .diagnostic)
        return try await fetchEnrolledProgramSession(patientId: patientId)
    }

    /// Build 444: Fetch session via enrolled programs RPC
    /// Bypasses patient_id filter by using enrollment relationship
    private func fetchEnrolledProgramSession(patientId: String) async throws -> Session? {
        logger.log("📱 [QuickStart] Calling RPC get_today_enrolled_session...", level: .diagnostic)

        // Response struct matching RPC return type
        struct EnrolledSessionRow: Codable {
            let session_id: String
            let session_name: String
            let phase_name: String
            let program_name: String
            let program_library_title: String?
            let enrollment_id: String
        }

        let response = try await supabase.client
            .rpc("get_today_enrolled_session", params: ["p_patient_id": patientId])
            .execute()

        if let jsonString = String(data: response.data, encoding: .utf8) {
            logger.log("📱 [QuickStart] RPC response: \(jsonString)", level: .diagnostic)
        }

        let decoder = JSONDecoder()
        let rows = try decoder.decode([EnrolledSessionRow].self, from: response.data)

        guard let row = rows.first else {
            logger.log("⚠️ [QuickStart] RPC returned no enrolled sessions", level: .warning)
            return nil
        }

        logger.log("✅ [QuickStart] RPC found session: \(row.session_name) (ID: \(row.session_id))", level: .success)

        // Now fetch the full session object by ID
        let sessionResponse = try await supabase.client
            .from("sessions")
            .select("*")
            .eq("id", value: row.session_id)
            .limit(1)
            .execute()

        let sessionDecoder = JSONDecoder()
        sessionDecoder.dateDecodingStrategy = .iso8601
        let sessions = try sessionDecoder.decode([Session].self, from: sessionResponse.data)

        return sessions.first
    }

    /// Fetch exercises for a session
    private func fetchExercises(for session: Session) async throws -> [Exercise] {
        logger.log("📱 [QuickStart] Fetching exercises for session: \(session.id)", level: .diagnostic)

        let response = try await supabase.client
            .from("session_exercises")
            .select("""
                *,
                exercise_templates!inner(
                    id,
                    name,
                    category,
                    body_region,
                    video_url,
                    video_thumbnail_url,
                    video_duration,
                    technique_cues,
                    common_mistakes,
                    safety_notes
                )
            """)
            .eq("session_id", value: session.id.uuidString)
            .order("sequence", ascending: true)
            .order("created_at", ascending: true)
            .order("id", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exercises = try decoder.decode([Exercise].self, from: response.data)

        logger.log("✅ [QuickStart] Loaded \(exercises.count) exercises", level: .success)

        return exercises
    }
}

// MARK: - Quick Start State

/// Observable state for quick start UI components
@MainActor
class QuickStartState: ObservableObject {
    @Published var isAvailable = false
    @Published var sessionName: String?
    @Published var exerciseCount: Int = 0
    @Published var status: QuickStartStatus = .unknown

    enum QuickStartStatus {
        case unknown
        case loading
        case ready
        case noWorkout
        case completed
        case error(String)
    }

    private let service = QuickStartService.shared

    /// Check availability and update state
    func checkAvailability() async {
        status = .loading

        let result = await service.prepareQuickStart()

        switch result {
        case .ready(let session, let exercises):
            isAvailable = true
            sessionName = session.name
            exerciseCount = exercises.count
            status = .ready

        case .multipleWorkouts(let session, let exercises, _):
            isAvailable = true
            sessionName = session.name
            exerciseCount = exercises.count
            status = .ready

        case .noWorkoutToday:
            isAvailable = false
            sessionName = nil
            exerciseCount = 0
            status = .noWorkout

        case .alreadyCompleted(let session):
            isAvailable = false
            sessionName = session.name
            exerciseCount = 0
            status = .completed

        case .error(let error):
            isAvailable = false
            sessionName = nil
            exerciseCount = 0
            status = .error(error.localizedDescription)
        }
    }
}
