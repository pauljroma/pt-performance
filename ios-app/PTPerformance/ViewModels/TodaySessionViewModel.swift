import Foundation
import SwiftUI

/// ViewModel for Today's Session screen
/// Fetches today's session and exercises from Supabase or backend API
@MainActor
class TodaySessionViewModel: ObservableObject {
    @Published var session: Session?
    @Published var exercises: [Exercise] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    /// Fetch today's session for the authenticated patient
    func fetchTodaySession() async {
        let logger = DebugLogger.shared
        isLoading = true
        errorMessage = nil

        guard let patientId = supabase.userId else {
            logger.log("❌ No patient ID available", level: .error)
            errorMessage = "No patient ID available. Please log in again."
            isLoading = false
            return
        }

        logger.log("📱 Starting fetchTodaySession for patient: \(patientId)")
        print("📱 [TodaySession] Starting fetch for patient: \(patientId)")

        do {
            // Fetch directly from Supabase (backend API not deployed yet)
            logger.log("📱 Fetching from Supabase...")
            print("📱 [TodaySession] Fetching from Supabase...")
            try await fetchFromSupabase(patientId: patientId)
            logger.log("✅ Supabase fetch succeeded", level: .success)
            print("✅ [TodaySession] Supabase fetch succeeded")
            isLoading = false
        } catch let error {
            logger.log("❌ Supabase fetch failed", level: .error)
            logger.log("   Error: \(error.localizedDescription)", level: .error)
            print("❌ [TodaySession] Supabase fetch failed")
            print("   Error: \(error.localizedDescription)")

            errorMessage = """
            Failed to load today's session.

            Please check:
            • Your internet connection
            • That you have an active program assigned

            Error: \(error.localizedDescription)
            """
            isLoading = false
        }

        // NOTE: Backend API with Edge Functions not yet deployed
        // To enable backend API, uncomment the code below and comment out the Supabase-only code above:
        /*
        do {
            // Option 1: Call backend /today-session endpoint
            logger.log("📱 Trying backend API...")
            print("📱 [TodaySession] Trying backend API...")
            let response = try await fetchFromBackend(patientId: patientId)

            self.session = response.session
            self.exercises = response.exercises
            logger.log("✅ Backend API succeeded - session: \(response.session?.name ?? "nil")", level: .success)
            print("✅ [TodaySession] Backend API succeeded")
            isLoading = false
        } catch let backendError {
            // Fallback to direct Supabase query if backend unavailable
            logger.log("⚠️ Backend failed, trying Supabase...", level: .warning)
            logger.log("   Backend error: \(backendError.localizedDescription)", level: .warning)
            print("⚠️ [TodaySession] Backend failed (\(backendError.localizedDescription)), trying Supabase...")

            do {
                try await fetchFromSupabase(patientId: patientId)
                logger.log("✅ Supabase fallback succeeded", level: .success)
                print("✅ [TodaySession] Supabase fallback succeeded")
                isLoading = false
            } catch let supabaseError {
                logger.log("❌ BOTH backend AND Supabase FAILED", level: .error)
                logger.log("   Backend error: \(backendError.localizedDescription)", level: .error)
                logger.log("   Supabase error: \(supabaseError.localizedDescription)", level: .error)
                print("❌ [TodaySession] Both backend and Supabase failed")
                print("   Backend error: \(backendError.localizedDescription)")
                print("   Supabase error: \(supabaseError.localizedDescription)")

                errorMessage = """
                Failed to load today's session.

                Please check:
                • Your internet connection
                • That you have an active program assigned

                Error: \(supabaseError.localizedDescription)
                """
                isLoading = false
            }
        }
        */
    }

    /// Fetch from backend API (/today-session/:patientId)
    private func fetchFromBackend(patientId: String) async throws -> TodaySessionResponse {
        let backendURL = Config.backendURL
        print("📱 [TodaySession] Backend URL: \(backendURL)")

        guard let url = URL(string: "\(backendURL)/today-session/\(patientId)") else {
            print("❌ [TodaySession] Invalid backend URL: \(backendURL)")
            throw URLError(.badURL)
        }

        print("📱 [TodaySession] Calling: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [TodaySession] No HTTP response")
            throw URLError(.badServerResponse)
        }

        print("📱 [TodaySession] Backend response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ [TodaySession] Backend error response: \(responseString)")
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
        logger.log("📱 Query filters: phases.programs.patient_id=\(patientId), status=active")
        print("📱 [TodaySession] Fetching session for patient: \(patientId)")
        print("📱 [TodaySession] Querying sessions table with filters:")
        print("   - phases.programs.patient_id = \(patientId)")
        print("   - phases.programs.status = active")

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
            print("📱 [TodaySession] Supabase returned \(sessionsResponse.count) sessions")

        guard let session = sessionsResponse.first else {
            logger.log("⚠️ No sessions found - possible causes:", level: .warning)
            logger.log("   1. Patient has no active program", level: .warning)
            logger.log("   2. Active program has no phases", level: .warning)
            logger.log("   3. Phases have no sessions", level: .warning)
            logger.log("   4. Database relationship joins failing", level: .warning)
            print("⚠️ [TodaySession] No sessions found - possible causes:")
            print("   1. Patient has no active program (check programs table)")
            print("   2. Active program has no phases (check phases table)")
            print("   3. Phases have no sessions (check sessions table)")
            print("   4. Database relationship joins failing (check foreign keys)")
            // No active sessions found
            self.session = nil
            self.exercises = []
            return
        }

        logger.log("✅ Found session: \(session.name) (ID: \(session.id))", level: .success)
        print("✅ [TodaySession] Found session: \(session.name) (ID: \(session.id))")
        self.session = session

        // Fetch exercises for this session
        do {
            logger.log("📱 Fetching exercises for session \(session.id)...")
            let response = try await supabase.client
                .from("session_exercises")
                .select("""
                    *,
                    exercise_templates!inner(
                        id,
                        name,
                        category,
                        body_region
                    )
                """)
                .eq("session_id", value: session.id)
                .order("sequence", ascending: true)
                .execute()

            logger.log("📱 Exercises response size: \(response.data.count) bytes")
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("📱 Exercises JSON: \(jsonString.prefix(500))")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exercisesResponse = try decoder.decode([Exercise].self, from: response.data)

            logger.log("✅ Found \(exercisesResponse.count) exercises", level: .success)
            print("✅ [TodaySession] Found \(exercisesResponse.count) exercises")
            self.exercises = exercisesResponse
        } catch let decodingError as DecodingError {
            logger.log("❌ EXERCISE DECODING ERROR:", level: .error)
            switch decodingError {
            case .typeMismatch(let type, let context):
                logger.log("  Type mismatch: Expected \(type)", level: .error)
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
            // If exercise fetch fails, still show session but with empty exercises
            logger.log("⚠️ Setting exercises to empty array", level: .warning)
            print("⚠️ [TodaySession] Failed to fetch exercises: \(decodingError.localizedDescription)")
            self.exercises = []
        } catch {
            // If exercise fetch fails, still show session but with empty exercises
            logger.log("⚠️ Failed to fetch exercises: \(error.localizedDescription)", level: .warning)
            print("⚠️ [TodaySession] Failed to fetch exercises: \(error.localizedDescription)")
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

    /// Refresh data
    func refresh() async {
        await fetchTodaySession()
    }

    // MARK: - Build 33: Session Completion

    /// Complete the current session
    /// Calculates metrics from exercise logs and marks session as complete
    func completeSession() async -> Result<Session, Error> {
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
            let updateData = SessionUpdateData(
                completed: true,
                completed_at: ISO8601DateFormatter().string(from: Date()),
                total_volume: metrics.totalVolume,
                avg_rpe: metrics.avgRpe,
                avg_pain: metrics.avgPain,
                duration_minutes: metrics.durationMinutes
            )

            _ = try await supabase.client
                .from("sessions")
                .update(updateData)
                .eq("id", value: session.id)
                .execute()

            logger.log("✅ Session marked as complete!", level: .success)

            // Refresh session data
            await fetchTodaySession()

            guard let updatedSession = self.session else {
                return .failure(NSError(domain: "TodaySessionViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated session"]))
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
            let setsCount = Double(log.actual_sets)
            let repsSum = log.actual_reps.reduce(0, +) // Sum all reps across sets
            let load = log.actual_load ?? 0
            let exerciseVolume = (Double(repsSum) * load)  // Total reps × load
            return sum + exerciseVolume
        }

        // Calculate average RPE
        let avgRpe = logs.map { Double($0.rpe) }.reduce(0, +) / Double(logs.count)

        // Calculate average pain
        let avgPain = logs.map { Double($0.pain_score) }.reduce(0, +) / Double(logs.count)

        // Calculate duration in minutes
        let sortedLogs = logs.sorted { $0.logged_at < $1.logged_at }
        var durationMinutes = 0
        if let firstLog = sortedLogs.first, let lastLog = sortedLogs.last {
            let duration = lastLog.logged_at.timeIntervalSince(firstLog.logged_at)
            durationMinutes = max(1, Int(duration / 60))  // At least 1 minute
        }

        return SessionMetrics(
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )
    }
}

// MARK: - Build 33: Supporting Types

/// Session update data for completing a session
struct SessionUpdateData: Codable {
    let completed: Bool
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
struct ExerciseLogRecord: Codable {
    let id: String
    let session_exercise_id: String
    let patient_id: String
    let logged_at: Date
    let actual_sets: Int
    let actual_reps: [Int]
    let actual_load: Double?
    let rpe: Int
    let pain_score: Int

    enum CodingKeys: String, CodingKey {
        case id
        case session_exercise_id
        case patient_id
        case logged_at
        case actual_sets
        case actual_reps
        case actual_load
        case rpe
        case pain_score
    }
}
