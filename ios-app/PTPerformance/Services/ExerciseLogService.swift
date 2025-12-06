import Foundation
import Supabase

/// Service for submitting exercise logs to Supabase
class ExerciseLogService {
    private let supabase: PTSupabaseClient

    init(supabase: SupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Submit an exercise log to the database
    func submitExerciseLog(
        sessionExerciseId: String,
        patientId: String,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String? = "lbs",
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws -> ExerciseLog {
        let input = CreateExerciseLogInput(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            actualSets: actualSets,
            actualReps: actualReps,
            actualLoad: actualLoad,
            loadUnit: loadUnit,
            rpe: rpe,
            painScore: painScore,
            notes: notes,
            completed: true
        )

        // Insert into exercise_logs table
        let response = try await supabase.client
            .from("exercise_logs")
            .insert(input)
            .select()
            .single()
            .execute()

        let log = try JSONDecoder().decode(ExerciseLog.self, from: response.data)
        return log
    }

    /// Fetch exercise logs for a specific session exercise
    func fetchLogs(for sessionExerciseId: String) async throws -> [ExerciseLog] {
        let response = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("session_exercise_id", value: sessionExerciseId)
            .order("logged_at", ascending: false)
            .execute()

        let logs = try JSONDecoder().decode([ExerciseLog].self, from: response.data)
        return logs
    }

    /// Fetch all exercise logs for a patient
    func fetchPatientLogs(patientId: String, limit: Int = 20) async throws -> [ExerciseLog] {
        let response = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("patient_id", value: patientId)
            .order("logged_at", ascending: false)
            .limit(limit)
            .execute()

        let logs = try JSONDecoder().decode([ExerciseLog].self, from: response.data)
        return logs
    }
}
