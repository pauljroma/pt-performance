import Foundation
import Supabase

/// Service for submitting exercise logs to Supabase
class ExerciseLogService: ObservableObject {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
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
        let logger = DebugLogger.shared

        logger.log("📝 Starting exercise log submission...", level: .diagnostic)
        logger.log("  Session Exercise ID: \(sessionExerciseId)", level: .diagnostic)
        logger.log("  Patient ID: \(patientId)", level: .diagnostic)
        logger.log("  Sets: \(actualSets), Reps: \(actualReps)", level: .diagnostic)
        logger.log("  Load: \(actualLoad ?? 0) \(loadUnit ?? ""), RPE: \(rpe), Pain: \(painScore)", level: .diagnostic)

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

        do {
            logger.log("📝 Inserting into exercise_logs table...", level: .diagnostic)

            // Insert into exercise_logs table
            let response = try await supabase.client
                .from("exercise_logs")
                .insert(input)
                .select()
                .single()
                .execute()

            logger.log("✅ Insert successful - response size: \(response.data.count) bytes", level: .success)

            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("📝 Response JSON: \(jsonString)", level: .diagnostic)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let log = try decoder.decode(ExerciseLog.self, from: response.data)
            logger.log("✅ Exercise log created successfully with ID: \(log.id)", level: .success)
            return log
        } catch let decodingError as DecodingError {
            logger.log("❌ DECODING ERROR:", level: .error)
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
            throw decodingError
        } catch {
            logger.log("❌ EXERCISE LOG SUBMISSION ERROR: \(error.localizedDescription)", level: .error)
            logger.log("   Error type: \(type(of: error))", level: .error)
            throw error
        }
    }

    /// Fetch exercise logs for a specific session exercise
    func fetchLogs(for sessionExerciseId: String) async throws -> [ExerciseLog] {
        let response = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("session_exercise_id", value: sessionExerciseId)
            .order("logged_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let logs = try decoder.decode([ExerciseLog].self, from: response.data)
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let logs = try decoder.decode([ExerciseLog].self, from: response.data)
        return logs
    }
}
