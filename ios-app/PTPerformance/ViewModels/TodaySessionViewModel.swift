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
                logger.log("⚡ Cache hit! Session: \(cached.session?.name ?? "nil"), \(cached.exercises.count) exercises", level: .success)
                // Still fetch in background to ensure freshness
                isLoading = false
                await fetchTodaysCompletedWorkouts()

                // Background refresh (non-blocking)
                Task(priority: .utility) { @MainActor in
                    await self.backgroundRefreshFromSupabase(patientId: patientId)
                }
                return
            }

            // No cache - show loading state and fetch
            isLoading = true

            logger.log("📱 Starting fetchTodaySession for patient: \(patientId)")

            do {
                // Check for cancellation before network call
                try Task.checkCancellation()

                // Fetch directly from Supabase (backend API not deployed yet)
                logger.log("📱 Fetching from Supabase...")
                try await fetchFromSupabase(patientId: patientId)

                // Check for cancellation after network call
                try Task.checkCancellation()

                logger.log("✅ Supabase fetch succeeded", level: .success)

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
                // Task was cancelled — normal during navigation, don't update state
                logger.log("fetchTodaySession cancelled (superseded by new request)", level: .diagnostic)
                return
            } catch let error {
                // Check for other cancellation variants (e.g. URLError.cancelled)
                guard !error.isCancellation else {
                    logger.log("fetchTodaySession cancelled (superseded by new request)", level: .diagnostic)
                    return
                }
                logger.log("Supabase fetch failed: \(error.localizedDescription)", level: .error)

                // Serve cached data when offline (ACP-600)
                if supabase.isOffline,
                   let cached = supabase.getCachedData(
                       forKey: "today_session_\(patientId)",
                       type: CachedTodaySession.self
                   ) {
                    self.session = cached.session
                    self.exercises = cached.exercises
                    logger.log("📦 Serving cached session data (offline mode) - session: \(cached.session?.name ?? "nil"), exercises: \(cached.exercises.count)", level: .success)
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
            logger.log("[TodaySession] Trying backend API...", level: .diagnostic)
            let response = try await fetchFromBackend(patientId: patientId)

            self.session = response.session
            self.exercises = response.exercises
            logger.log("[TodaySession] Backend API succeeded - session: \(response.session?.name ?? "nil")", level: .success)
            isLoading = false
        } catch let backendError {
            // Fallback to direct Supabase query if backend unavailable
            logger.log("[TodaySession] Backend failed, trying Supabase...", level: .warning)
            logger.log("  Backend error: \(backendError.localizedDescription)", level: .warning)

            do {
                try await fetchFromSupabase(patientId: patientId)
                logger.log("[TodaySession] Supabase fallback succeeded", level: .success)
                isLoading = false
            } catch let supabaseError {
                logger.log("[TodaySession] BOTH backend AND Supabase FAILED", level: .error)
                logger.log("  Backend error: \(backendError.localizedDescription)", level: .error)
                logger.log("  Supabase error: \(supabaseError.localizedDescription)", level: .error)

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
        let logger = DebugLogger.shared
        let backendURL = Config.backendURL
        logger.log("📱 Backend URL: \(backendURL)")

        guard let url = URL(string: "\(backendURL)/today-session/\(patientId)") else {
            logger.log("❌ Invalid backend URL: \(backendURL)", level: .error)
            throw URLError(.badURL)
        }

        logger.log("📱 Calling: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.log("❌ No HTTP response", level: .error)
            throw URLError(.badServerResponse)
        }

        logger.log("📱 Backend response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                logger.log("❌ Backend error response: \(responseString)", level: .error)
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

        // Try to find a scheduled session for today first
        var sessionId: String? = nil

        do {
            let scheduledResponse = try await supabase.client
                .from("scheduled_sessions")
                .select("session_id, status, enrollment_id, workout_template_id, workout_name")
                .eq("patient_id", value: patientId)
                .eq("scheduled_date", value: String(today))
                .eq("status", value: "scheduled")
                .limit(1)
                .execute()

            if let jsonString = String(data: scheduledResponse.data, encoding: .utf8) {
                logger.log("📱 Scheduled sessions response: \(jsonString)")
            }

            // Decode the scheduled session - session_id may be null for enrollment-based workouts
            struct ScheduledSessionRow: Codable {
                let session_id: String?  // Nullable for enrollment-based workouts
                let status: String
                let enrollment_id: String?
                let workout_template_id: String?
                let workout_name: String?
            }

            let decoder = JSONDecoder()
            let scheduledSessions = try decoder.decode([ScheduledSessionRow].self, from: scheduledResponse.data)

            if let scheduled = scheduledSessions.first {
                if let id = scheduled.session_id {
                    sessionId = id
                    logger.log("✅ Found scheduled session for today: \(id)", level: .success)
                } else if scheduled.enrollment_id != nil, let templateId = scheduled.workout_template_id {
                    // Build 451: Handle enrollment-based workouts (workout_template_id based)
                    logger.log("📱 Found enrollment-based workout: \(scheduled.workout_name ?? "Unknown")")
                    logger.log("📱 Template ID: \(templateId)")

                    // Fetch the template-based workout
                    if let workoutSession = try await fetchTemplateBasedWorkout(
                        templateId: templateId,
                        workoutName: scheduled.workout_name,
                        enrollmentId: scheduled.enrollment_id
                    ) {
                        self.session = workoutSession.session
                        self.exercises = workoutSession.exercises
                        logger.log("✅ Loaded template-based workout: \(workoutSession.session.name)", level: .success)
                        return
                    }
                }
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

        // If no direct program found, try enrolled programs via RPC
        guard let session = sessionsResponse.first else {
            logger.log("📱 No direct program found, trying enrolled programs via RPC...", level: .warning)

            // Build 444: Call RPC to get session via enrollment
            if let enrolledSession = try await fetchEnrolledProgramSession(patientId: patientId) {
                logger.log("✅ Found session via enrollment: \(enrolledSession.name)", level: .success)
                self.session = enrolledSession
                try await fetchExercisesForSession(enrolledSession)
                return
            }

            logger.log("⚠️ No sessions found - possible causes:", level: .warning)
            logger.log("   1. Patient has no active program", level: .warning)
            logger.log("   2. Patient has no active enrollments", level: .warning)
            logger.log("   3. Enrolled programs have no sessions", level: .warning)
            // No active sessions found
            self.session = nil
            self.exercises = []
            return
        }

        logger.log("✅ Found session: \(session.name) (ID: \(session.id))", level: .success)
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

    /// Build 444: Fetch session via enrolled programs RPC
    /// Bypasses patient_id filter by using enrollment relationship
    private func fetchEnrolledProgramSession(patientId: String) async throws -> Session? {
        let logger = DebugLogger.shared
        logger.log("📱 Calling RPC get_today_enrolled_session...")

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
            logger.log("📱 RPC response: \(jsonString)")
        }

        let decoder = JSONDecoder()
        let rows = try decoder.decode([EnrolledSessionRow].self, from: response.data)

        guard let row = rows.first else {
            logger.log("⚠️ RPC returned no enrolled sessions", level: .warning)
            return nil
        }

        logger.log("✅ RPC found session: \(row.session_name) (ID: \(row.session_id))", level: .success)

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

    /// Build 451: Fetch workout from system_workout_templates (for enrollment-based workouts)
    /// Returns a synthetic Session and parsed exercises from the template
    private func fetchTemplateBasedWorkout(
        templateId: String,
        workoutName: String?,
        enrollmentId: String?
    ) async throws -> (session: Session, exercises: [Exercise])? {
        let logger = DebugLogger.shared
        logger.log("📱 Fetching template-based workout: \(templateId)")

        // Codable struct for system_workout_templates
        struct WorkoutTemplate: Codable {
            let id: UUID
            let name: String
            let description: String?
            let category: String?
            let difficulty: String?
            let duration_minutes: Int?
            let exercises: [TemplateExercise]?

            struct TemplateExercise: Codable {
                let exercise_name: String
                let block_name: String?
                let sequence: Int?
                let target_sets: Int?
                let target_reps: String?
                let rest_period_seconds: Int?
                let notes: String?
            }
        }

        let response = try await supabase.client
            .from("system_workout_templates")
            .select("*")
            .eq("id", value: templateId)
            .limit(1)
            .execute()

        if let jsonString = String(data: response.data, encoding: .utf8) {
            logger.log("📱 Template response: \(jsonString.prefix(500))")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let templates = try decoder.decode([WorkoutTemplate].self, from: response.data)

        guard let template = templates.first else {
            logger.log("⚠️ No template found with ID: \(templateId)", level: .warning)
            return nil
        }

        // Create a synthetic Session object for display
        // Use a well-known "template" phase UUID for template-based workouts
        let templatePhaseId = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()

        let syntheticSession = Session(
            id: template.id,  // Use template ID as session ID
            phase_id: templatePhaseId,  // Synthetic phase for template workouts
            name: workoutName ?? template.name,
            sequence: 1,
            weekday: nil,
            notes: template.description ?? template.category,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: template.duration_minutes
        )

        // Convert template exercises to Exercise model
        var exercises: [Exercise] = []
        if let templateExercises = template.exercises {
            for (index, ex) in templateExercises.enumerated() {
                // Create a synthetic ExerciseTemplate for display
                let exerciseTemplate = Exercise.ExerciseTemplate(
                    id: UUID(),
                    name: ex.exercise_name,
                    category: ex.block_name,
                    body_region: nil,
                    videoUrl: nil,
                    videoThumbnailUrl: nil,
                    videoDuration: nil,
                    formCues: nil,
                    techniqueCues: nil,
                    commonMistakes: nil,
                    safetyNotes: ex.notes
                )

                let exercise = Exercise(
                    id: UUID(),  // Generate temporary ID
                    session_id: template.id,
                    exercise_template_id: exerciseTemplate.id,
                    sequence: ex.sequence ?? (index + 1),
                    target_sets: ex.target_sets ?? 3,
                    target_reps: nil,  // Will use prescribed_reps string
                    prescribed_sets: nil,
                    prescribed_reps: ex.target_reps,
                    prescribed_load: nil,
                    load_unit: nil,
                    rest_period_seconds: ex.rest_period_seconds ?? 60,
                    notes: ex.notes,
                    exercise_templates: exerciseTemplate
                )
                exercises.append(exercise)
            }
        }

        logger.log("✅ Loaded template workout: \(template.name) with \(exercises.count) exercises", level: .success)
        return (session: syntheticSession, exercises: exercises)
    }

    /// Helper to parse reps string like "10-12" or "30-45 sec" to Int
    private func parseRepsValue(_ repsString: String?) -> Int {
        guard let reps = repsString else { return 10 }

        // Try to extract first number
        let numbers = reps.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 > 0 }

        return numbers.first ?? 10
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
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                logger.error("📊 Failed to calculate tomorrow's date")
                return
            }

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
                logger.log("fetchTodaysCompletedWorkouts cancelled (superseded by new request)", level: .diagnostic)
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
                logger.log("fetchTodaysCompletedWorkouts cancelled (superseded by new request)", level: .diagnostic)
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
    /// Inserts a real-time alert into the `therapist_notifications` table via PainTrackingService.
    private func notifyTherapistOfHighPain(exerciseName: String, painLevel: Int) async {
        let logger = DebugLogger.shared
        guard let patientId = supabase.userId,
              let athleteId = UUID(uuidString: patientId) else { return }

        logger.log("High pain alert for \(exerciseName): \(painLevel)/10 (patient: \(patientId.prefix(8)))", level: .warning)

        Task {
            await PainTrackingService.shared.checkAndAlertTherapist(
                athleteId: athleteId,
                intensity: painLevel
            )
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
