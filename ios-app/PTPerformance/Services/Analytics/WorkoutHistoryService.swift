//
//  WorkoutHistoryService.swift
//  PTPerformance
//
//  Service for workout history queries
//  Extracted from AnalyticsService for single responsibility
//

import Foundation
import Supabase

/// Service responsible for workout history queries
///
/// Provides methods for fetching completed workout sessions (both prescribed
/// and manual) with full exercise details. Supports pagination for large
/// history datasets.
///
/// ## Usage Example
/// ```swift
/// let historyService = WorkoutHistoryService()
///
/// // Get recent sessions
/// let sessions = try await historyService.fetchRecentSessions(
///     patientId: patientId,
///     limit: 10
/// )
///
/// // Get exercise details for a session
/// let exercises = try await historyService.fetchSessionExerciseLogs(
///     sessionId: sessionId,
///     patientId: patientId
/// )
/// ```
final class WorkoutHistoryService {

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Prescribed Session History

    /// Fetch recent completed session summaries for history view
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - limit: Maximum number of sessions to return
    /// - Returns: Array of session summaries
    func fetchRecentSessions(patientId: String, limit: Int = 10) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("vw_patient_sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count,
                avg_pain_score,
                completed_at,
                total_volume,
                avg_rpe,
                duration_minutes
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()

        return try PTSupabaseClient.flexibleDecoder.decode([SessionSummary].self, from: response.data)
    }

    /// Fetch recent completed sessions with pagination support
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - limit: Number of sessions per page
    ///   - offset: Starting offset for pagination
    /// - Returns: Array of session summaries
    func fetchRecentSessionsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("vw_patient_sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count,
                avg_pain_score,
                completed_at,
                total_volume,
                avg_rpe,
                duration_minutes
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        return try PTSupabaseClient.flexibleDecoder.decode([SessionSummary].self, from: response.data)
    }

    /// Fetch exercise logs for a prescribed session with exercise names
    /// - Parameters:
    ///   - sessionId: The session UUID
    ///   - patientId: The patient UUID
    /// - Returns: Array of exercise log details
    func fetchSessionExerciseLogs(sessionId: String, patientId: String) async throws -> [ExerciseLogDetail] {
        let response = try await supabase.client
            .from("exercise_logs")
            .select("""
                id,
                actual_sets,
                actual_reps,
                actual_load,
                load_unit,
                rpe,
                pain_score,
                notes,
                logged_at,
                session_exercises!inner(
                    exercise_templates!inner(
                        exercise_name,
                        id,
                        video_url
                    )
                )
            """)
            .eq("patient_id", value: patientId)
            .eq("session_exercises.session_id", value: sessionId)
            .order("logged_at", ascending: true)
            .execute()

        struct ExerciseLogJoined: Codable {
            let id: UUID
            let actual_sets: Int
            let actual_reps: [Int]
            let actual_load: Double?
            let load_unit: String?
            let rpe: Int
            let pain_score: Int
            let notes: String?
            let logged_at: Date
            let session_exercises: SessionExerciseJoin

            struct SessionExerciseJoin: Codable {
                let exercise_templates: ExerciseTemplateJoin
            }

            struct ExerciseTemplateJoin: Codable {
                let exercise_name: String
                let id: UUID
                let video_url: String?
            }
        }

        let joined = try PTSupabaseClient.flexibleDecoder.decode([ExerciseLogJoined].self, from: response.data)

        return joined.map { log in
            ExerciseLogDetail(
                id: log.id.uuidString,
                exerciseName: log.session_exercises.exercise_templates.exercise_name,
                actualSets: log.actual_sets,
                actualReps: log.actual_reps,
                actualLoad: log.actual_load,
                loadUnit: log.load_unit,
                rpe: log.rpe,
                painScore: log.pain_score,
                notes: log.notes,
                loggedAt: log.logged_at,
                exerciseTemplateId: log.session_exercises.exercise_templates.id.uuidString,
                videoUrl: log.session_exercises.exercise_templates.video_url
            )
        }
    }

    // MARK: - Manual Workout History

    /// Fetch recent completed manual workouts
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - limit: Maximum number of workouts to return
    /// - Returns: Array of manual workout summaries
    func fetchRecentManualWorkouts(patientId: String, limit: Int = 10) async throws -> [ManualWorkoutSummary] {
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                name,
                completed_at,
                created_at,
                completed,
                total_volume,
                avg_rpe,
                avg_pain,
                duration_minutes,
                assigned_by_user_id,
                session_source,
                manual_session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()

        return try decodeManualWorkouts(from: response.data)
    }

    /// Fetch recent completed manual workouts with pagination support
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - limit: Number of workouts per page
    ///   - offset: Starting offset for pagination
    /// - Returns: Array of manual workout summaries
    func fetchRecentManualWorkoutsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [ManualWorkoutSummary] {
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                name,
                completed_at,
                created_at,
                completed,
                total_volume,
                avg_rpe,
                avg_pain,
                duration_minutes,
                assigned_by_user_id,
                session_source,
                manual_session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        return try decodeManualWorkouts(from: response.data)
    }

    /// Fetch exercises for a manual workout
    /// - Parameter workoutId: The manual workout UUID
    /// - Returns: Array of exercise log details
    func fetchManualWorkoutExercises(workoutId: UUID) async throws -> [ExerciseLogDetail] {
        let response = try await supabase.client
            .from("manual_session_exercises")
            .select("""
                id,
                exercise_name,
                target_sets,
                target_reps,
                target_load,
                load_unit,
                notes,
                created_at,
                exercise_template_id
            """)
            .eq("manual_session_id", value: workoutId)
            .order("sequence", ascending: true)
            .execute()

        struct ManualExerciseRow: Codable {
            let id: UUID
            let exercise_name: String
            let target_sets: Int?
            let target_reps: String?
            let target_load: Double?
            let load_unit: String?
            let notes: String?
            let created_at: Date
            let exercise_template_id: UUID?
        }

        let rows = try PTSupabaseClient.flexibleDecoder.decode([ManualExerciseRow].self, from: response.data)

        return rows.map { row in
            // Parse target_reps string into [Int] array
            let repsArray = parseRepsString(row.target_reps, sets: row.target_sets)

            return ExerciseLogDetail(
                id: row.id.uuidString,
                exerciseName: row.exercise_name,
                actualSets: row.target_sets ?? 0,
                actualReps: repsArray,
                actualLoad: row.target_load,
                loadUnit: row.load_unit,
                rpe: 0,
                painScore: 0,
                notes: row.notes,
                loggedAt: row.created_at,
                exerciseTemplateId: row.exercise_template_id?.uuidString,
                videoUrl: nil
            )
        }
    }

    /// Fetch recent session history for a specific exercise
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - exerciseName: The exercise name
    ///   - limit: Maximum sessions to return
    /// - Returns: Array of exercise session records
    func fetchExerciseRecentHistory(
        patientId: String,
        exerciseName: String,
        limit: Int = 10
    ) async throws -> [ExerciseSessionRecord] {
        // Use strength service to get time-series data
        let strengthService = StrengthAnalyticsService(supabase: supabase)
        let dataPoints = try await strengthService.fetchExerciseProgressTimeSeries(
            patientId: patientId,
            exerciseName: exerciseName,
            limit: limit
        )

        // Convert to session records (reverse order for most recent first)
        return dataPoints.reversed().map { point in
            ExerciseSessionRecord(
                id: point.id,
                date: point.date,
                sets: point.sets,
                reps: point.reps,
                weight: point.weight > 0 ? point.weight : nil,
                volume: point.volume,
                isPersonalRecord: point.isPersonalRecord,
                loadUnit: nil
            )
        }
    }

    // MARK: - Private Methods

    /// Decode manual workout response data
    private func decodeManualWorkouts(from data: Data) throws -> [ManualWorkoutSummary] {
        struct ManualSessionWithCount: Codable {
            let id: UUID
            let name: String?
            let completed_at: Date?
            let created_at: Date
            let completed: Bool
            let total_volume: Double?
            let avg_rpe: Double?
            let avg_pain: Double?
            let duration_minutes: Int?
            let manual_session_exercises: [CountResult]?
            let assigned_by_user_id: UUID?
            let session_source: String?

            struct CountResult: Codable {
                let count: Int
            }
        }

        let rawSessions = try PTSupabaseClient.flexibleDecoder.decode([ManualSessionWithCount].self, from: data)

        return rawSessions.map { raw in
            ManualWorkoutSummary(
                id: raw.id,
                name: raw.name,
                completedAt: raw.completed_at,
                createdAt: raw.created_at,
                completed: raw.completed,
                totalVolume: raw.total_volume,
                avgRpe: raw.avg_rpe,
                avgPain: raw.avg_pain,
                durationMinutes: raw.duration_minutes,
                exerciseCount: raw.manual_session_exercises?.first?.count,
                assignedByUserId: raw.assigned_by_user_id,
                sessionSource: raw.session_source.flatMap { sourceString in
                    if let source = SessionSource(rawValue: sourceString) {
                        return source
                    } else {
                        DebugLogger.shared.log("Unknown session source '\(sourceString)' for workout \(raw.id), defaulting to nil", level: .warning)
                        return nil
                    }
                }
            )
        }
    }

    /// Parse reps string into array
    private func parseRepsString(_ repsStr: String?, sets: Int?) -> [Int] {
        guard let repsStr = repsStr else { return [] }
        let parsed = repsStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if !parsed.isEmpty {
            return parsed
        } else if let directParsed = Int(repsStr), let sets = sets {
            return Array(repeating: directParsed, count: sets)
        }
        #if DEBUG
        DebugLogger.shared.warning("ANALYTICS", "Failed to parse repsArray from string: '\(repsStr)', using empty array")
        #endif
        return []
    }
}

// MARK: - Exercise Session Record

/// Record of a single exercise session for history display
struct ExerciseSessionRecord: Identifiable {
    let id: String
    let date: Date
    let sets: Int
    let reps: Int
    let weight: Double?
    let volume: Double
    let isPersonalRecord: Bool
    let loadUnit: String?
}
