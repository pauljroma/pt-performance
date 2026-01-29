import Foundation
import Supabase

/// Service for submitting exercise logs to Supabase
/// Supports offline queueing when network is unavailable
class ExerciseLogService: ObservableObject {
    private let supabase: PTSupabaseClient

    /// Whether the last submission was queued for offline sync
    @Published var wasQueuedOffline = false

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Submit an exercise log to the database
    /// If offline, queues the log for later sync
    /// - Returns: The created ExerciseLog if online, or a placeholder if queued offline
    func submitExerciseLog(
        sessionExerciseId: UUID,
        patientId: UUID,
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

        // Check if offline - queue for later sync
        if supabase.isOffline {
            logger.log("📵 Device is offline - queueing exercise log for sync", level: .warning)

            await MainActor.run {
                OfflineQueueManager.shared.enqueue(
                    sessionExerciseId: sessionExerciseId,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: actualReps,
                    actualLoad: actualLoad,
                    loadUnit: loadUnit,
                    rpe: rpe,
                    painScore: painScore,
                    notes: notes
                )
                wasQueuedOffline = true
            }

            // Return a placeholder log for UI feedback
            return ExerciseLog(
                id: UUID(),
                sessionExerciseId: sessionExerciseId,
                patientId: patientId,
                loggedAt: Date(),
                actualSets: actualSets,
                actualReps: actualReps,
                actualLoad: actualLoad,
                loadUnit: loadUnit,
                rpe: rpe,
                painScore: painScore,
                notes: notes,
                completed: true
            )
        }

        wasQueuedOffline = false

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

            // Queue for offline sync on network errors
            await queueForOfflineIfNetworkError(
                error: decodingError,
                sessionExerciseId: sessionExerciseId,
                patientId: patientId,
                actualSets: actualSets,
                actualReps: actualReps,
                actualLoad: actualLoad,
                loadUnit: loadUnit,
                rpe: rpe,
                painScore: painScore,
                notes: notes
            )

            throw decodingError
        } catch {
            logger.log("❌ EXERCISE LOG SUBMISSION ERROR: \(error.localizedDescription)", level: .error)
            logger.log("   Error type: \(type(of: error))", level: .error)

            // Queue for offline sync on network errors
            let wasQueued = await queueForOfflineIfNetworkError(
                error: error,
                sessionExerciseId: sessionExerciseId,
                patientId: patientId,
                actualSets: actualSets,
                actualReps: actualReps,
                actualLoad: actualLoad,
                loadUnit: loadUnit,
                rpe: rpe,
                painScore: painScore,
                notes: notes
            )

            if wasQueued {
                // Return placeholder since it was queued
                return ExerciseLog(
                    id: UUID(),
                    sessionExerciseId: sessionExerciseId,
                    patientId: patientId,
                    loggedAt: Date(),
                    actualSets: actualSets,
                    actualReps: actualReps,
                    actualLoad: actualLoad,
                    loadUnit: loadUnit,
                    rpe: rpe,
                    painScore: painScore,
                    notes: notes,
                    completed: true
                )
            }

            throw error
        }
    }

    /// Queue the log for offline sync if the error is network-related
    @discardableResult
    private func queueForOfflineIfNetworkError(
        error: Error,
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String?,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async -> Bool {
        // Check for network-related errors
        let isNetworkError = isNetworkRelatedError(error)

        if isNetworkError {
            let logger = DebugLogger.shared
            logger.log("📵 Network error detected - queueing for offline sync", level: .warning)

            await MainActor.run {
                supabase.isOffline = true
                OfflineQueueManager.shared.enqueue(
                    sessionExerciseId: sessionExerciseId,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: actualReps,
                    actualLoad: actualLoad,
                    loadUnit: loadUnit,
                    rpe: rpe,
                    painScore: painScore,
                    notes: notes
                )
                wasQueuedOffline = true
            }

            return true
        }

        return false
    }

    /// Determine if an error is network-related
    private func isNetworkRelatedError(_ error: Error) -> Bool {
        let nsError = error as NSError

        // Check for common network error codes
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorDataNotAllowed
        ]

        if networkErrorCodes.contains(nsError.code) {
            return true
        }

        // Check error description for network-related keywords
        let description = error.localizedDescription.lowercased()
        let networkKeywords = ["network", "internet", "connection", "offline", "timeout", "unreachable"]

        return networkKeywords.contains { description.contains($0) }
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
