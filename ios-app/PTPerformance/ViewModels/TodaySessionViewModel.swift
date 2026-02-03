import Foundation
import SwiftUI

/// ViewModel for Today's Session screen
/// Fetches today's session and exercises from Supabase or backend API
@MainActor
class TodaySessionViewModel: ObservableObject {
    // MARK: - Pain Alert Thresholds

    /// Pain threshold above which therapist should be notified
    private static let painNotificationThreshold = 5
    @Published var session: Session?
    @Published var exercises: [Exercise] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Daily workout tracking
    @Published var completedTodayCount: Int = 0
    @Published var todaysCompletedWorkouts: [TodayWorkoutSummary] = []

    private let supabase = PTSupabaseClient.shared

    // MARK: - Request Deduplication
    /// Task tracking for fetchTodaySession to prevent concurrent duplicate calls
    private var fetchSessionTask: Task<Void, Never>?
    /// Task tracking for fetchTodaysCompletedWorkouts to prevent concurrent duplicate calls
    private var fetchCompletedWorkoutsTask: Task<Void, Never>?

    /// Offline status passthrough for views (ACP-600)
    var isOffline: Bool {
        supabase.isOffline
    }

    /// Patient ID for current session (derived from Supabase auth)
    var patientId: UUID? {
        guard let userIdString = supabase.userId else { return nil }
        return UUID(uuidString: userIdString)
    }

    // MARK: - Codable Models

    /// Codable struct for exercise log insertion
    private struct ExerciseLogInsert: Codable {
        let session_exercise_id: String
        let patient_id: String
        let logged_at: String
        let actual_sets: Int
        let actual_reps: [Int]
        let actual_load: Double
        let load_unit: String
        let rpe: Int
        let pain_score: Int
        let notes: String?
    }

    /// Codable wrapper for offline caching of today's session data (ACP-600)
    private struct CachedTodaySession: Codable {
        let session: Session?
        let exercises: [Exercise]
    }

    /// Fetch today's session for the authenticated patient
    /// Uses request deduplication to prevent concurrent duplicate API calls
    /// ACP-502: Now checks preloaded cache first for zero loading states
    func fetchTodaySession() async {
        // Cancel any existing fetch to prevent duplicate concurrent requests
        fetchSessionTask?.cancel()

        // Create new task for this fetch
        fetchSessionTask = Task {
            let logger = DebugLogger.shared
            errorMessage = nil

            guard let patientId = supabase.userId else {
                logger.log("❌ No patient ID available", level: .error)
                errorMessage = "We couldn't find your account. Please sign out and sign back in to continue."
                isLoading = false
                return
            }

            // ACP-502: Check preloaded cache first for instant display
            if let cached = PreloadedWorkoutCache.shared.getCachedData(for: patientId) {
                self.session = cached.session
                self.exercises = cached.exercises
                logger.log("⚡ Using preloaded cache - zero loading state!", level: .success)
                #if DEBUG
                print("⚡ [TodaySession] Cache hit! Session: \(cached.session?.name ?? "nil"), \(cached.exercises.count) exercises")
                #endif
                // Still fetch in background to ensure freshness
                isLoading = false
                await fetchTodaysCompletedWorkouts()

                // Background refresh (non-blocking)
                Task.detached(priority: .utility) { @MainActor in
                    await self.backgroundRefreshFromSupabase(patientId: patientId)
                }
                return
            }

            // No cache - show loading state and fetch
            isLoading = true

            logger.log("📱 Starting fetchTodaySession for patient: \(patientId)")
            #if DEBUG
            print("📱 [TodaySession] Starting fetch for patient: \(patientId)")
            #endif

            do {
                // Check for cancellation before network call
                try Task.checkCancellation()

                // Fetch directly from Supabase (backend API not deployed yet)
                logger.log("📱 Fetching from Supabase...")
                #if DEBUG
                print("📱 [TodaySession] Fetching from Supabase...")
                #endif
                try await fetchFromSupabase(patientId: patientId)

                // Check for cancellation after network call
                try Task.checkCancellation()

                logger.log("✅ Supabase fetch succeeded", level: .success)
                #if DEBUG
                print("✅ [TodaySession] Supabase fetch succeeded")
                #endif

                // Cache session data for offline use (ACP-600)
                let cachedData = CachedTodaySession(session: self.session, exercises: self.exercises)
                supabase.cacheData(cachedData, forKey: "today_session_\(patientId)")
                logger.log("💾 Cached today's session for offline use", level: .success)

                // ACP-502: Update preload cache with fresh data
                PreloadedWorkoutCache.shared.store(
                    session: self.session,
                    exercises: self.exercises,
                    patientId: patientId
                )
                logger.log("⚡ Updated preload cache", level: .success)

                // Also fetch today's completed workouts count
                await fetchTodaysCompletedWorkouts()

                isLoading = false
            } catch is CancellationError {
                // Task was cancelled, don't update state
                logger.log("⏹️ fetchTodaySession cancelled (superseded by new request)", level: .warning)
                return
            } catch let error {
                logger.log("❌ Supabase fetch failed", level: .error)
                logger.log("   Error: \(error.localizedDescription)", level: .error)
                #if DEBUG
                print("❌ [TodaySession] Supabase fetch failed")
                print("   Error: \(error.localizedDescription)")
                #endif

                // Serve cached data when offline (ACP-600)
                if supabase.isOffline,
                   let cached = supabase.getCachedData(
                       forKey: "today_session_\(patientId)",
                       type: CachedTodaySession.self
                   ) {
                    self.session = cached.session
                    self.exercises = cached.exercises
                    logger.log("📦 Serving cached session data (offline mode)", level: .success)
                    #if DEBUG
                    print("📦 [TodaySession] Serving cached data - session: \(cached.session?.name ?? "nil"), exercises: \(cached.exercises.count)")
                    #endif
                    // Don't set errorMessage - OfflineBanner handles offline indication
                } else {
                    errorMessage = """
                    We couldn't load your workout for today.

                    Here's what you can try:
                    • Check your internet connection
                    • Pull down to refresh
                    • Make sure you have a program assigned by your therapist

                    If this keeps happening, contact your therapist for help.
                    """
                }
                isLoading = false
            }
        }

        // Await the task completion
        await fetchSessionTask?.value

        // NOTE: Backend API with Edge Functions not yet deployed
        // To enable backend API, uncomment the code below and comment out the Supabase-only code above:
        /*
        do {
            // Option 1: Call backend /today-session endpoint
            logger.log("📱 Trying backend API...")
            #if DEBUG
            print("📱 [TodaySession] Trying backend API...")
            #endif
            let response = try await fetchFromBackend(patientId: patientId)

            self.session = response.session
            self.exercises = response.exercises
            logger.log("✅ Backend API succeeded - session: \(response.session?.name ?? "nil")", level: .success)
            #if DEBUG
            print("✅ [TodaySession] Backend API succeeded")
            #endif
            isLoading = false
        } catch let backendError {
            // Fallback to direct Supabase query if backend unavailable
            logger.log("⚠️ Backend failed, trying Supabase...", level: .warning)
            logger.log("   Backend error: \(backendError.localizedDescription)", level: .warning)
            #if DEBUG
            print("⚠️ [TodaySession] Backend failed (\(backendError.localizedDescription)), trying Supabase...")
            #endif

            do {
                try await fetchFromSupabase(patientId: patientId)
                logger.log("✅ Supabase fallback succeeded", level: .success)
                #if DEBUG
                print("✅ [TodaySession] Supabase fallback succeeded")
                #endif
                isLoading = false
            } catch let supabaseError {
                logger.log("❌ BOTH backend AND Supabase FAILED", level: .error)
                logger.log("   Backend error: \(backendError.localizedDescription)", level: .error)
                logger.log("   Supabase error: \(supabaseError.localizedDescription)", level: .error)
                #if DEBUG
                print("❌ [TodaySession] Both backend and Supabase failed")
                print("   Backend error: \(backendError.localizedDescription)")
                print("   Supabase error: \(supabaseError.localizedDescription)")
                #endif

                errorMessage = """
                We couldn't load your workout for today.

                Here's what you can try:
                • Check your internet connection
                • Pull down to refresh
                • Make sure you have a program assigned by your therapist

                If this keeps happening, contact your therapist for help.
                """
                isLoading = false
            }
        }
        */
    }

    /// Fetch from backend API (/today-session/:patientId)
    private func fetchFromBackend(patientId: String) async throws -> TodaySessionResponse {
        let backendURL = Config.backendURL
        #if DEBUG
        print("📱 [TodaySession] Backend URL: \(backendURL)")
        #endif

        guard let url = URL(string: "\(backendURL)/today-session/\(patientId)") else {
            #if DEBUG
            print("❌ [TodaySession] Invalid backend URL: \(backendURL)")
            #endif
            throw URLError(.badURL)
        }

        #if DEBUG
        print("📱 [TodaySession] Calling: \(url.absoluteString)")
        #endif
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            #if DEBUG
            print("❌ [TodaySession] No HTTP response")
            #endif
            throw URLError(.badServerResponse)
        }

        #if DEBUG
        print("📱 [TodaySession] Backend response status: \(httpResponse.statusCode)")
        #endif

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                #if DEBUG
                print("❌ [TodaySession] Backend error response: \(responseString)")
                #endif
            }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TodaySessionResponse.self, from: data)
    }

    /// Fetch directly from Supabase (fallback)
    private func fetchFromSupabase(patientId: String) async throws {
        let logger = DebugLogger.shared
        logger.log("📱 Fetching session from Supabase for patient: \(patientId)")

        // First check scheduled_sessions for today
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD
        logger.log("📱 Checking scheduled_sessions for today: \(today)")
        #if DEBUG
        print("📱 [TodaySession] Checking scheduled_sessions for today: \(today)")
        #endif

        // Try to find a scheduled session for today first
        var sessionId: String? = nil

        do {
            let scheduledResponse = try await supabase.client
                .from("scheduled_sessions")
                .select("session_id, status")
                .eq("patient_id", value: patientId)
                .eq("scheduled_date", value: String(today))
                .eq("status", value: "scheduled")
                .limit(1)
                .execute()

            if let jsonString = String(data: scheduledResponse.data, encoding: .utf8) {
                logger.log("📱 Scheduled sessions response: \(jsonString)")
            }

            // Decode the scheduled session to get session_id
            struct ScheduledSessionRow: Codable {
                let session_id: String
                let status: String
            }

            let decoder = JSONDecoder()
            let scheduledSessions = try decoder.decode([ScheduledSessionRow].self, from: scheduledResponse.data)

            if let scheduled = scheduledSessions.first {
                sessionId = scheduled.session_id
                logger.log("✅ Found scheduled session for today: \(sessionId!)", level: .success)
                #if DEBUG
                print("✅ [TodaySession] Found scheduled session for today: \(sessionId!)")
                #endif
            }
        } catch {
            logger.log("⚠️ Failed to fetch scheduled sessions: \(error.localizedDescription)", level: .warning)
        }

        // If we have a scheduled session, fetch it directly
        if let sessionId = sessionId {
            logger.log("📱 Fetching scheduled session by ID: \(sessionId)")
            do {
                // Use limit(1) instead of .single() to avoid "Cannot coerce" error
                // when query returns empty or multiple rows
                let response = try await supabase.client
                    .from("sessions")
                    .select("*")
                    .eq("id", value: sessionId)
                    .limit(1)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let sessions = try decoder.decode([Session].self, from: response.data)

                guard let session = sessions.first else {
                    logger.log("⚠️ No session found with ID: \(sessionId)", level: .warning)
                    throw NSError(domain: "TodaySessionViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Session not found"])
                }

                logger.log("✅ Found scheduled session: \(session.name) (ID: \(session.id))", level: .success)
                #if DEBUG
                print("✅ [TodaySession] Found scheduled session: \(session.name)")
                #endif
                self.session = session

                // Fetch exercises for this session
                try await fetchExercisesForSession(session)
                return
            } catch {
                logger.log("⚠️ Failed to fetch scheduled session: \(error.localizedDescription)", level: .warning)
                // Fall through to program-based lookup
            }
        }

        // Fallback: Query sessions via program chain
        logger.log("📱 No scheduled session, falling back to program-based lookup")
        logger.log("📱 Query filters: phases.programs.patient_id=\(patientId), status=active")
        #if DEBUG
        print("📱 [TodaySession] Falling back to program-based lookup")
        #endif

        // Query sessions via correct relationship chain: sessions -> phases -> programs
        // Use the first active session from the patient's active program
        do {
            logger.log("📱 Executing Supabase query...")
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

            logger.log("📱 Response size: \(response.data.count) bytes")
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("📱 Raw JSON: \(jsonString.prefix(1000))")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sessionsResponse = try decoder.decode([Session].self, from: response.data)

            logger.log("📱 Supabase returned \(sessionsResponse.count) sessions")
            #if DEBUG
            print("📱 [TodaySession] Supabase returned \(sessionsResponse.count) sessions")
            #endif

        guard let session = sessionsResponse.first else {
            logger.log("⚠️ No sessions found - possible causes:", level: .warning)
            logger.log("   1. Patient has no active program", level: .warning)
            logger.log("   2. Active program has no phases", level: .warning)
            logger.log("   3. Phases have no sessions", level: .warning)
            logger.log("   4. Database relationship joins failing", level: .warning)
            #if DEBUG
            print("⚠️ [TodaySession] No sessions found - possible causes:")
            print("   1. Patient has no active program (check programs table)")
            print("   2. Active program has no phases (check phases table)")
            print("   3. Phases have no sessions (check sessions table)")
            print("   4. Database relationship joins failing (check foreign keys)")
            #endif
            // No active sessions found
            self.session = nil
            self.exercises = []
            return
        }

        logger.log("✅ Found session: \(session.name) (ID: \(session.id))", level: .success)
        #if DEBUG
        print("✅ [TodaySession] Found session: \(session.name) (ID: \(session.id))")
        #endif
        self.session = session

        // Fetch exercises for this session using helper
        do {
            try await fetchExercisesForSession(session)
        } catch {
            logger.log("⚠️ Failed to fetch exercises: \(error.localizedDescription)", level: .warning)
            self.exercises = []
        }
        } catch let decodingError as DecodingError {
            logger.log("❌ SESSION DECODING ERROR:", level: .error)
            switch decodingError {
            case .typeMismatch(let type, let context):
                logger.log("  Type mismatch: Expected \(type)", level: .error)
                logger.log("  Context: \(context.debugDescription)", level: .error)
                logger.log("  Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            case .valueNotFound(let type, let context):
                logger.log("  Value not found: \(type)", level: .error)
                logger.log("  Context: \(context.debugDescription)", level: .error)
            case .keyNotFound(let key, let context):
                logger.log("  Key not found: \(key.stringValue)", level: .error)
                logger.log("  Context: \(context.debugDescription)", level: .error)
            case .dataCorrupted(let context):
                logger.log("  Data corrupted: \(context.debugDescription)", level: .error)
            @unknown default:
                logger.log("  Unknown decoding error: \(decodingError)", level: .error)
            }
            throw decodingError
        }
    }

    /// Helper to fetch exercises for a session
    private func fetchExercisesForSession(_ session: Session) async throws {
        let logger = DebugLogger.shared
        logger.log("📱 Fetching exercises for session \(session.id)...")

        // Include video and technique fields for ExerciseTechniqueView
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
            .eq("session_id", value: session.id)
            .order("sequence", ascending: true)
            .order("created_at", ascending: true)
            .order("id", ascending: true)
            .execute()

        logger.log("📱 Exercises response size: \(response.data.count) bytes")
        if let jsonString = String(data: response.data, encoding: .utf8) {
            logger.log("📱 Exercises JSON: \(jsonString.prefix(500))")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exercisesResponse = try decoder.decode([Exercise].self, from: response.data)

        logger.log("✅ Found \(exercisesResponse.count) exercises", level: .success)
        #if DEBUG
        print("✅ [TodaySession] Found \(exercisesResponse.count) exercises")
        #endif
        self.exercises = exercisesResponse
    }

    // MARK: - ACP-502: Background Refresh

    /// Background refresh from Supabase to update cache silently
    /// Called when cache hit occurs but we want to ensure data freshness
    private func backgroundRefreshFromSupabase(patientId: String) async {
        let logger = DebugLogger.shared
        logger.log("🔄 Background refresh starting...", level: .diagnostic)

        do {
            try await fetchFromSupabase(patientId: patientId)

            // Update preload cache with fresh data
            PreloadedWorkoutCache.shared.store(
                session: self.session,
                exercises: self.exercises,
                patientId: patientId
            )

            // Also update offline cache
            let cachedData = CachedTodaySession(session: self.session, exercises: self.exercises)
            supabase.cacheData(cachedData, forKey: "today_session_\(patientId)")

            logger.log("🔄 Background refresh complete", level: .success)
        } catch {
            logger.log("🔄 Background refresh failed (using cached data): \(error.localizedDescription)", level: .warning)
        }
    }

    /// Refresh data
    func refresh() async {
        await fetchTodaySession()
        await fetchTodaysCompletedWorkouts()
    }

    // MARK: - Today's Completed Workouts Counter

    /// Fetch all workouts completed today (both prescribed and manual)
    /// Uses request deduplication to prevent concurrent duplicate API calls
    /// Performance optimized: Uses async let to parallelize both database queries
    func fetchTodaysCompletedWorkouts() async {
        // Cancel any existing fetch to prevent duplicate concurrent requests
        fetchCompletedWorkoutsTask?.cancel()

        // Create new task for this fetch
        fetchCompletedWorkoutsTask = Task {
            guard let patientId = supabase.userId else { return }

            let logger = DebugLogger.shared
            logger.log("📊 Fetching today's completed workouts...")

            // Get today's date range
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            let formatter = ISO8601DateFormatter()
            let todayStr = formatter.string(from: today)
            let tomorrowStr = formatter.string(from: tomorrow)

            // Custom struct for prescribed session view response
            struct PrescribedSessionRow: Codable {
                let id: String
                let phase_name: String?
                let program_name: String?
                let completed_at: String?
                let duration_minutes: Int?
                let total_volume: Double?
                let exercise_count: Int?
            }

            // Check for cancellation before network calls
            guard !Task.isCancelled else {
                logger.log("⏹️ fetchTodaysCompletedWorkouts cancelled (superseded by new request)", level: .warning)
                return
            }

            // Helper function to fetch prescribed sessions
            @Sendable func fetchPrescribedSessions() async -> [PrescribedSessionRow] {
                do {
                    let response = try await supabase.client
                        .from("vw_patient_sessions")
                        .select("id, phase_name, program_name, completed_at, duration_minutes, total_volume, exercise_count")
                        .eq("patient_id", value: patientId)
                        .eq("completed", value: true)
                        .gte("completed_at", value: todayStr)
                        .lt("completed_at", value: tomorrowStr)
                        .execute()

                    let decoder = JSONDecoder()
                    let sessions = try decoder.decode([PrescribedSessionRow].self, from: response.data)
                    logger.log("📊 Found \(sessions.count) prescribed sessions completed today", level: .success)
                    return sessions
                } catch {
                    logger.log("⚠️ Failed to fetch prescribed sessions: \(error.localizedDescription)", level: .warning)
                    return []
                }
            }

            // Helper function to fetch manual sessions
            @Sendable func fetchManualSessions() async -> [CompletedManualSessionRow] {
                do {
                    let response = try await supabase.client
                        .from("manual_sessions")
                        .select("id, name, completed_at, duration_minutes, total_volume")
                        .eq("patient_id", value: patientId)
                        .eq("completed", value: true)
                        .gte("completed_at", value: todayStr)
                        .lt("completed_at", value: tomorrowStr)
                        .execute()

                    let decoder = JSONDecoder()
                    let sessions = try decoder.decode([CompletedManualSessionRow].self, from: response.data)
                    logger.log("📊 Found \(sessions.count) manual sessions completed today", level: .success)
                    return sessions
                } catch {
                    logger.log("⚠️ Failed to fetch manual sessions: \(error.localizedDescription)", level: .warning)
                    return []
                }
            }

            // Execute both queries in parallel using async let
            async let prescribedTask = fetchPrescribedSessions()
            async let manualTask = fetchManualSessions()

            // Await both results concurrently
            let (prescribedSessions, manualSessions) = await (prescribedTask, manualTask)

            // Check for cancellation after network calls
            guard !Task.isCancelled else {
                logger.log("⏹️ fetchTodaysCompletedWorkouts cancelled (superseded by new request)", level: .warning)
                return
            }

            var workouts: [TodayWorkoutSummary] = []

            // Process prescribed sessions
            for session in prescribedSessions {
                if let uuid = UUID(uuidString: session.id) {
                    let completedAt: Date
                    if let completedAtStr = session.completed_at {
                        completedAt = formatter.date(from: completedAtStr) ?? Date()
                    } else {
                        completedAt = Date()
                    }

                    // Use phase_name or program_name as display name
                    let displayName = session.phase_name ?? session.program_name ?? "Workout"

                    workouts.append(TodayWorkoutSummary(
                        id: uuid,
                        name: displayName,
                        completedAt: completedAt,
                        durationMinutes: session.duration_minutes,
                        totalVolume: session.total_volume,
                        exerciseCount: session.exercise_count ?? 0,
                        isPrescribed: true
                    ))
                }
            }

            // Process manual sessions
            for session in manualSessions {
                if let uuid = UUID(uuidString: session.id) {
                    let completedAt: Date
                    if let completedAtStr = session.completed_at {
                        completedAt = formatter.date(from: completedAtStr) ?? Date()
                    } else {
                        completedAt = Date()
                    }

                    workouts.append(TodayWorkoutSummary(
                        id: uuid,
                        name: session.name,
                        completedAt: completedAt,
                        durationMinutes: session.duration_minutes,
                        totalVolume: session.total_volume,
                        exerciseCount: 0,
                        isPrescribed: false
                    ))
                }
            }

            // Sort by completion time (newest first)
            workouts.sort { $0.completedAt > $1.completedAt }

            self.todaysCompletedWorkouts = workouts
            self.completedTodayCount = workouts.count

            logger.log("📊 Total workouts completed today: \(workouts.count)", level: .success)
        }

        // Await the task completion
        await fetchCompletedWorkoutsTask?.value
    }

    // MARK: - Build 33: Session Completion

    /// Complete the current session
    /// Calculates metrics from exercise logs and marks session as complete
    /// - Parameter startedAt: When the workout session actually started
    func completeSession(startedAt: Date) async -> Result<Session, Error> {
        guard let session = session else {
            return .failure(NSError(domain: "TodaySessionViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active session"]))
        }

        guard let patientId = supabase.userId else {
            return .failure(NSError(domain: "TodaySessionViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No patient ID"]))
        }

        let logger = DebugLogger.shared
        logger.log("🎯 Starting session completion for: \(session.name)")

        do {
            // Fetch all exercise logs for this session
            logger.log("📊 Fetching exercise logs to calculate metrics...")
            let response = try await supabase.client
                .from("exercise_logs")
                .select("*")
                .eq("patient_id", value: patientId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exerciseLogs = try decoder.decode([ExerciseLogRecord].self, from: response.data)

            logger.log("📊 Found \(exerciseLogs.count) exercise logs")

            // Calculate metrics
            let metrics = calculateSessionMetrics(from: exerciseLogs)
            logger.log("📊 Calculated metrics:")
            logger.log("   Total volume: \(metrics.totalVolume) lbs")
            logger.log("   Avg RPE: \(metrics.avgRpe)")
            logger.log("   Avg Pain: \(metrics.avgPain)")
            logger.log("   Duration: \(metrics.durationMinutes) min")

            // Update session in database
            logger.log("💾 Updating session in database...")
            let now = Date()
            let updateData = SessionUpdateData(
                completed: true,
                started_at: ISO8601DateFormatter().string(from: startedAt), // Save actual start time
                completed_at: ISO8601DateFormatter().string(from: now),
                total_volume: metrics.totalVolume,
                avg_rpe: metrics.avgRpe,
                avg_pain: metrics.avgPain,
                duration_minutes: Int(now.timeIntervalSince(startedAt) / 60) // Calculate duration from actual times
            )

            _ = try await supabase.client
                .from("sessions")
                .update(updateData)
                .eq("id", value: session.id)
                .execute()

            logger.log("✅ Session marked as complete!", level: .success)

            // Fetch the specific completed session by ID (not fetchTodaySession which gets wrong session)
            let fetchResponse = try await supabase.client
                .from("sessions")
                .select("*")
                .eq("id", value: session.id)
                .single()
                .execute()

            let sessionDecoder = JSONDecoder()
            sessionDecoder.dateDecodingStrategy = .iso8601
            let updatedSession = try sessionDecoder.decode(Session.self, from: fetchResponse.data)

            logger.log("✅ Fetched updated session with started_at: \(updatedSession.started_at?.description ?? "nil")")

            // Also update viewModel.session for UI refresh
            self.session = updatedSession

            // ACP-841: Record workout completion for smart notification pattern learning
            if let patientUUID = UUID(uuidString: patientId) {
                Task {
                    try? await SmartNotificationService.shared.recordWorkoutCompletion(
                        for: patientUUID,
                        completionTime: now
                    )
                }
            }

            // ACP-827: Export completed workout to Apple Health
            Task { @MainActor in
                await HealthSyncManager.shared.exportCompletedSession(updatedSession)
            }

            return .success(updatedSession)

        } catch {
            logger.log("❌ Failed to complete session: \(error.localizedDescription)", level: .error)
            return .failure(error)
        }
    }

    /// Calculate session metrics from exercise logs
    private func calculateSessionMetrics(from logs: [ExerciseLogRecord]) -> SessionMetrics {
        guard !logs.isEmpty else {
            return SessionMetrics(totalVolume: 0, avgRpe: 0, avgPain: 0, durationMinutes: 0)
        }

        // Calculate total volume: sum of (sets × reps × load) for each exercise
        let totalVolume = logs.reduce(0.0) { sum, log in
            let repsSum = (log.actual_reps ?? []).reduce(0, +) // Sum all reps across sets
            let load = log.actual_load ?? 0
            let exerciseVolume = (Double(repsSum) * load)  // Total reps × load
            return sum + exerciseVolume
        }

        // Calculate average RPE (filter out logs without RPE)
        let rpeValues = logs.compactMap { $0.rpe }
        let avgRpe = rpeValues.isEmpty ? 0.0 : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)

        // Calculate average pain (filter out logs without pain score)
        let painValues = logs.compactMap { $0.pain_score }
        let avgPain = painValues.isEmpty ? 0.0 : Double(painValues.reduce(0, +)) / Double(painValues.count)

        // Calculate duration in minutes (filter out logs without logged_at)
        let logsWithDates = logs.compactMap { log -> (date: Date, log: ExerciseLogRecord)? in
            guard let date = log.logged_at else { return nil }
            return (date, log)
        }.sorted { $0.date < $1.date }

        var durationMinutes = 0
        if let firstLog = logsWithDates.first, let lastLog = logsWithDates.last {
            let duration = lastLog.date.timeIntervalSince(firstLog.date)
            durationMinutes = max(1, Int(duration / 60))  // At least 1 minute
        }

        return SessionMetrics(
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )
    }

    // MARK: - Quick Complete & Inline Editing

    /// Quick-complete exercise with prescribed values (1-tap logging)
    func quickCompleteExercise(
        _ exercise: Exercise,
        sets: Int,
        reps: [Int],
        load: Double,
        loadUnit: String,
        rpe: Int,
        pain: Int,
        notes: String?
    ) async {
        await updateExerciseLog(
            exercise,
            sets: sets,
            reps: reps,
            load: load,
            loadUnit: loadUnit,
            rpe: rpe,
            pain: pain,
            notes: notes
        )
    }

    /// Update exercise log with custom values (inline editing)
    func updateExerciseLog(
        _ exercise: Exercise,
        sets: Int,
        reps: [Int],
        load: Double,
        loadUnit: String,
        rpe: Int,
        pain: Int,
        notes: String?
    ) async {
        let logger = DebugLogger.shared
        logger.log("📝 Logging exercise: \(exercise.exercise_name ?? "Unknown")")

        guard let patientId = supabase.userId else {
            logger.log("❌ No patient ID available", level: .error)
            return
        }

        do {
            // Create exercise log record using Codable struct
            let logData = ExerciseLogInsert(
                session_exercise_id: exercise.id.uuidString,
                patient_id: patientId,
                logged_at: ISO8601DateFormatter().string(from: Date()),
                actual_sets: sets,
                actual_reps: reps,
                actual_load: load,
                load_unit: loadUnit,
                rpe: rpe,
                pain_score: pain,
                notes: notes
            )

            try await supabase.client
                .from("exercise_logs")
                .insert(logData)
                .execute()

            logger.log("✅ Exercise log saved successfully", level: .success)

            // Notify therapist if pain exceeds threshold
            if pain > Self.painNotificationThreshold {
                logger.log("⚠️  High pain level (\(pain)) - therapist notification triggered", level: .warning)
                // Notify therapist of high pain (ACP-597)
                Task {
                    await notifyTherapistOfHighPain(exerciseName: exercise.exercise_name ?? "Unknown", painLevel: pain)
                }
            }

        } catch {
            logger.log("❌ Failed to save exercise log: \(error.localizedDescription)", level: .error)
            errorMessage = "We couldn't save your exercise progress. Please try again, and don't worry - your workout is still going strong!"
        }
    }

    /// Notify therapist when patient reports pain > 5 (ACP-597)
    private func notifyTherapistOfHighPain(exerciseName: String, painLevel: Int) async {
        let logger = DebugLogger.shared
        guard let patientId = supabase.userId else { return }

        do {
            let notification: [String: String] = [
                "patient_id": patientId,
                "notification_type": "high_pain",
                "title": "High Pain Alert",
                "message": "Patient reported pain level \(painLevel)/10 during \(exerciseName)",
                "severity": painLevel >= 8 ? "critical" : "warning"
            ]

            try await supabase.client.functions.invoke(
                "send-session-reminders",
                options: .init(body: notification)
            )
            logger.log("✅ Therapist notified of high pain for \(exerciseName)", level: .success)
        } catch {
            logger.log("⚠️  Failed to notify therapist: \(error.localizedDescription)", level: .warning)
        }
    }
}

// MARK: - Build 33: Supporting Types

/// Session update data for completing a session
struct SessionUpdateData: Codable {
    let completed: Bool
    let started_at: String? // Track actual workout start time
    let completed_at: String
    let total_volume: Double
    let avg_rpe: Double
    let avg_pain: Double
    let duration_minutes: Int
}

/// Session metrics calculated from exercise logs
struct SessionMetrics {
    let totalVolume: Double
    let avgRpe: Double
    let avgPain: Double
    let durationMinutes: Int
}

/// Exercise log record from database (for metrics calculation)
/// Includes ALL columns from exercise_logs table to avoid decode errors
struct ExerciseLogRecord: Codable {
    let id: String
    let session_exercise_id: String?  // NULL for manual workout logs
    let manual_session_exercise_id: String?  // NULL for prescribed workout logs
    let patient_id: String
    let logged_at: Date?
    let actual_sets: Int?
    let actual_reps: [Int]?
    let actual_load: Double?
    let load_unit: String?  // Added: returned by SELECT *
    let rpe: Int?
    let pain_score: Int?
    let notes: String?  // Added: returned by SELECT *
    let created_at: Date?  // Added: returned by SELECT *
}

// MARK: - Today's Workout Summary

/// Summary of a completed workout for today's counter
struct TodayWorkoutSummary: Identifiable {
    let id: UUID
    let name: String
    let completedAt: Date
    let durationMinutes: Int?
    let totalVolume: Double?
    let exerciseCount: Int
    let isPrescribed: Bool  // true = prescribed session, false = manual workout
}

/// Codable struct for fetching completed prescribed sessions
struct CompletedSessionRow: Codable {
    let id: String
    let name: String
    let completed_at: String?
    let duration_minutes: Int?
    let total_volume: Double?

    enum CodingKeys: String, CodingKey {
        case id, name
        case completed_at
        case duration_minutes
        case total_volume
    }
}

/// Codable struct for fetching completed manual sessions
struct CompletedManualSessionRow: Codable {
    let id: String
    let name: String
    let completed_at: String?
    let duration_minutes: Int?
    let total_volume: Double?

    enum CodingKeys: String, CodingKey {
        case id, name
        case completed_at
        case duration_minutes
        case total_volume
    }
}
