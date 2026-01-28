//
//  ManualWorkoutService.swift
//  PTPerformance
//
//  Service for managing manual workout templates and sessions
//

import Foundation
import Supabase

// MARK: - Service Enums

/// Source template type for manual sessions
enum SourceTemplateType: String, Codable {
    case system
    case patient
    case none
}

/// Manual workout session status
enum ManualSessionStatus: String, Codable {
    case draft
    case inProgress = "in_progress"
    case completed
    case cancelled
}

// MARK: - Input Models

/// Input for template exercises
struct TemplateExerciseInput: Codable {
    let exerciseTemplateId: UUID
    let name: String
    let sets: Int?
    let reps: Int?
    let load: Double?
    let loadUnit: String?
    let notes: String?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case name, sets, reps, load, notes
        case exerciseTemplateId = "exercise_template_id"
        case loadUnit = "load_unit"
        case orderIndex = "order_index"
    }
}

/// Input for creating a manual session
struct CreateManualSessionInput: Codable {
    let patientId: UUID
    let name: String
    let sourceTemplateId: UUID?
    let sourceTemplateType: String?

    enum CodingKeys: String, CodingKey {
        case name
        case patientId = "patient_id"
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
    }
}

/// Input for adding exercise to manual session
struct AddManualSessionExerciseInput: Codable {
    let manualSessionId: UUID
    let exerciseTemplateId: UUID?
    let exerciseName: String
    let blockName: String?
    let sequence: Int
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case manualSessionId = "manual_session_id"
        case exerciseTemplateId = "exercise_template_id"
        case exerciseName = "exercise_name"
        case blockName = "block_name"
        case sequence
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
    }
}

/// Input for updating manual session exercise
struct UpdateManualSessionExerciseInput: Codable {
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let notes: String?
    let sequence: Int?

    enum CodingKeys: String, CodingKey {
        case notes
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case sequence
    }
}

/// Input for logging manual exercise
struct CreateManualExerciseLogInput: Codable {
    let manualSessionExerciseId: UUID
    let patientId: UUID
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case rpe, notes, completed
        case manualSessionExerciseId = "manual_session_exercise_id"
        case patientId = "patient_id"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case painScore = "pain_score"
    }
}

/// BUILD 258: Input for logging prescribed exercise (session_exercise_id reference)
struct CreatePrescribedExerciseLogInput: Codable {
    let sessionExerciseId: UUID
    let patientId: UUID
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case rpe, notes
        case sessionExerciseId = "session_exercise_id"
        case patientId = "patient_id"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case painScore = "pain_score"
        case loggedAt = "logged_at"
    }
}

/// Input for completing a workout session
struct CompleteWorkoutInput: Codable {
    let completed: Bool
    let completedAt: String
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case completed
        case completedAt = "completed_at"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
    }
}

/// Input for adding exercise to prescribed session
struct AddToPrescribedSessionInput: Codable {
    let sessionId: UUID
    let exerciseTemplateId: UUID
    let sets: Int
    let reps: Int
    let load: Double?
    let loadUnit: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case sets, reps, load, notes
        case sessionId = "session_id"
        case exerciseTemplateId = "exercise_template_id"
        case loadUnit = "load_unit"
    }
}

// MARK: - Service

/// Service for managing manual workout templates and sessions
class ManualWorkoutService: ObservableObject {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - System Templates

    /// Fetch system workout templates with optional filters
    func fetchSystemTemplates(category: String? = nil, search: String? = nil) async throws -> [SystemWorkoutTemplate] {
        let logger = DebugLogger.shared
        logger.log("Fetching system workout templates...", level: .diagnostic)

        var query = supabase.client
            .from("system_workout_templates")
            .select()

        if let category = category, !category.isEmpty {
            query = query.eq("category", value: category)
        }

        if let search = search, !search.isEmpty {
            query = query.ilike("name", pattern: "%\(search)%")
        }

        do {
            let response = try await query
                .order("name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let templates = try decoder.decode([SystemWorkoutTemplate].self, from: response.data)

            logger.log("Fetched \(templates.count) system templates", level: .success)
            return templates
        } catch {
            logger.log("Failed to fetch system templates: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Patient Templates

    /// Fetch patient-specific workout templates
    /// Returns empty array if table doesn't exist or other errors occur
    func fetchPatientTemplates(patientId: UUID) async throws -> [PatientWorkoutTemplate] {
        let logger = DebugLogger.shared
        logger.log("Fetching patient templates for: \(patientId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("patient_workout_templates")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("usage_count", ascending: false)
                .execute()

            // Log raw response for debugging
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("Patient templates raw response: \(jsonString.prefix(200))", level: .diagnostic)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let templates = try decoder.decode([PatientWorkoutTemplate].self, from: response.data)

            logger.log("Fetched \(templates.count) patient templates", level: .success)
            return templates
        } catch {
            // Log detailed error info
            logger.log("Failed to fetch patient templates: \(error.localizedDescription)", level: .error)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    logger.log("  Missing key: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                case .typeMismatch(let type, let context):
                    logger.log("  Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                case .valueNotFound(let type, let context):
                    logger.log("  Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                default:
                    break
                }
            }
            // Return empty array instead of throwing - table may not exist yet
            logger.log("Returning empty patient templates (table may not exist)", level: .warning)
            return []
        }
    }

    /// Save exercises as a patient template
    func saveAsTemplate(
        name: String,
        description: String?,
        blocks: WorkoutBlocks,
        patientId: UUID,
        category: String? = nil
    ) async throws -> PatientWorkoutTemplate {
        let logger = DebugLogger.shared
        logger.log("Saving template '\(name)' for patient: \(patientId)", level: .diagnostic)

        let input = CreatePatientTemplateDTO(
            patientId: patientId,
            name: name,
            description: description,
            category: category,
            blocks: blocks
        )

        do {
            let response = try await supabase.client
                .from("patient_workout_templates")
                .insert(input)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let template = try decoder.decode(PatientWorkoutTemplate.self, from: response.data)

            logger.log("Template saved with ID: \(template.id)", level: .success)
            return template
        } catch {
            logger.log("Failed to save template: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Delete a patient template
    func deleteTemplate(_ templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Deleting template: \(templateId)", level: .diagnostic)

        do {
            try await supabase.client
                .from("patient_workout_templates")
                .delete()
                .eq("id", value: templateId.uuidString)
                .execute()

            logger.log("Template deleted successfully", level: .success)
        } catch {
            logger.log("Failed to delete template: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Increment usage count for a template
    func incrementUsageCount(_ templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Incrementing usage count for template: \(templateId)", level: .diagnostic)

        do {
            // First fetch current count
            let fetchResponse = try await supabase.client
                .from("patient_workout_templates")
                .select("usage_count")
                .eq("id", value: templateId.uuidString)
                .single()
                .execute()

            struct UsageCount: Codable {
                let usageCount: Int
                enum CodingKeys: String, CodingKey {
                    case usageCount = "usage_count"
                }
            }

            let current = try JSONDecoder().decode(UsageCount.self, from: fetchResponse.data)
            let newCount = current.usageCount + 1

            // Update with new count
            try await supabase.client
                .from("patient_workout_templates")
                .update(["usage_count": newCount])
                .eq("id", value: templateId.uuidString)
                .execute()

            logger.log("Usage count incremented to \(newCount)", level: .success)
        } catch {
            logger.log("Failed to increment usage count: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Manual Sessions

    /// Create a new manual workout session
    func createManualSession(
        name: String,
        patientId: UUID,
        sourceTemplateId: UUID? = nil,
        sourceTemplateType: SourceTemplateType? = nil
    ) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Creating manual session '\(name)' for patient: \(patientId)", level: .diagnostic)

        let input = CreateManualSessionInput(
            patientId: patientId,
            name: name,
            sourceTemplateId: sourceTemplateId,
            sourceTemplateType: sourceTemplateType?.rawValue
        )

        do {
            let response = try await supabase.client
                .from("manual_sessions")
                .insert(input)
                .select()
                .single()
                .execute()

            // Log raw response for debugging
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("📦 createSession response: \(jsonString.prefix(500))", level: .diagnostic)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(ManualSession.self, from: response.data)

            logger.log("Manual session created with ID: \(session.id)", level: .success)
            return session
        } catch {
            logger.log("Failed to create manual session: \(error.localizedDescription)", level: .error)
            // Log detailed decode error
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    logger.log("  Missing key: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                case .typeMismatch(let type, let context):
                    logger.log("  Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                case .valueNotFound(let type, let context):
                    logger.log("  Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error)
                default:
                    logger.log("  Decode error: \(decodingError)", level: .error)
                }
            }
            throw error
        }
    }

    /// Add an exercise to a manual session
    func addExercise(
        to sessionId: UUID,
        exercise: AddManualSessionExerciseInput
    ) async throws -> ManualSessionExercise {
        let logger = DebugLogger.shared
        logger.log("Adding exercise to session: \(sessionId)", level: .diagnostic)

        // Ensure the session ID matches
        let correctedInput = AddManualSessionExerciseInput(
            manualSessionId: sessionId,
            exerciseTemplateId: exercise.exerciseTemplateId,
            exerciseName: exercise.exerciseName,
            blockName: exercise.blockName,
            sequence: exercise.sequence,
            targetSets: exercise.targetSets,
            targetReps: exercise.targetReps,
            targetLoad: exercise.targetLoad,
            loadUnit: exercise.loadUnit,
            restPeriodSeconds: exercise.restPeriodSeconds,
            notes: exercise.notes
        )

        do {
            let response = try await supabase.client
                .from("manual_session_exercises")
                .insert(correctedInput)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sessionExercise = try decoder.decode(ManualSessionExercise.self, from: response.data)

            logger.log("Exercise added with ID: \(sessionExercise.id)", level: .success)
            return sessionExercise
        } catch {
            logger.log("Failed to add exercise: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Update an exercise in a manual session
    func updateExercise(_ exercise: ManualSessionExercise) async throws {
        let logger = DebugLogger.shared
        logger.log("Updating exercise: \(exercise.id)", level: .diagnostic)

        let input = UpdateManualSessionExerciseInput(
            targetSets: exercise.targetSets,
            targetReps: exercise.targetReps,
            targetLoad: exercise.targetLoad,
            loadUnit: exercise.loadUnit,
            notes: exercise.notes,
            sequence: exercise.sequence
        )

        do {
            try await supabase.client
                .from("manual_session_exercises")
                .update(input)
                .eq("id", value: exercise.id.uuidString)
                .execute()

            logger.log("Exercise updated successfully", level: .success)
        } catch {
            logger.log("Failed to update exercise: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Remove an exercise from a manual session
    func removeExercise(_ exerciseId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Removing exercise: \(exerciseId)", level: .diagnostic)

        do {
            try await supabase.client
                .from("manual_session_exercises")
                .delete()
                .eq("id", value: exerciseId.uuidString)
                .execute()

            logger.log("Exercise removed successfully", level: .success)
        } catch {
            logger.log("Failed to remove exercise: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Reorder exercises in a manual session
    func reorderExercises(sessionId: UUID, exerciseIds: [UUID]) async throws {
        let logger = DebugLogger.shared
        logger.log("Reordering \(exerciseIds.count) exercises in session: \(sessionId)", level: .diagnostic)

        do {
            // Update each exercise with its new order index
            for (index, exerciseId) in exerciseIds.enumerated() {
                try await supabase.client
                    .from("manual_session_exercises")
                    .update(["order_index": index])
                    .eq("id", value: exerciseId.uuidString)
                    .eq("manual_session_id", value: sessionId.uuidString)
                    .execute()
            }

            logger.log("Exercises reordered successfully", level: .success)
        } catch {
            logger.log("Failed to reorder exercises: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Start a manual workout session
    func startWorkout(_ sessionId: UUID) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Starting workout session: \(sessionId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let response = try await supabase.client
                .from("manual_sessions")
                .update([
                    "started_at": now
                ])
                .eq("id", value: sessionId.uuidString)
                .select()
                .single()
                .execute()

            logger.log("📦 startWorkout response size: \(response.data.count) bytes", level: .diagnostic)

            // Log raw JSON for debugging
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("📦 startWorkout JSON: \(jsonString.prefix(500))", level: .diagnostic)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let session = try decoder.decode(ManualSession.self, from: response.data)
                logger.log("✅ Workout started at \(now)", level: .success)
                return session
            } catch let decodeError {
                logger.log("❌ Decode error: \(decodeError)", level: .error)
                throw decodeError
            }
        } catch {
            logger.log("❌ Failed to start workout: \(error)", level: .error)
            throw error
        }
    }

    /// Complete a manual workout session
    func completeWorkout(
        _ sessionId: UUID,
        totalVolume: Double?,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int?
    ) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Completing workout session: \(sessionId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let updateInput = CompleteWorkoutInput(
                completed: true,
                completedAt: now,
                totalVolume: totalVolume,
                avgRpe: avgRpe,
                avgPain: avgPain,
                durationMinutes: durationMinutes
            )

            let response = try await supabase.client
                .from("manual_sessions")
                .update(updateInput)
                .eq("id", value: sessionId.uuidString)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(ManualSession.self, from: response.data)

            logger.log("Workout completed successfully", level: .success)
            return session
        } catch {
            logger.log("Failed to complete workout: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// BUILD 265: Complete a prescribed session (in sessions table)
    /// BUILD 272: Include all metrics in update
    /// BUILD 309: Added startedAt parameter for accurate session duration and summary filtering
    func completePrescribedSession(
        _ sessionId: UUID,
        startedAt: Date?,
        totalVolume: Double?,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int?
    ) async throws {
        let logger = DebugLogger.shared
        logger.log("Completing prescribed session: \(sessionId)", level: .diagnostic)
        logger.log("  Volume: \(totalVolume ?? 0), RPE: \(avgRpe ?? 0), Pain: \(avgPain ?? 0), Duration: \(durationMinutes ?? 0) min", level: .diagnostic)

        do {
            let formatter = ISO8601DateFormatter()
            let now = formatter.string(from: Date())

            // BUILD 309: Include started_at for proper session summary time-based filtering
            struct CompletePrescribedInput: Codable {
                let completed: Bool
                let startedAt: String?
                let completedAt: String
                let totalVolume: Double?
                let avgRpe: Double?
                let avgPain: Double?
                let durationMinutes: Int?

                enum CodingKeys: String, CodingKey {
                    case completed
                    case startedAt = "started_at"
                    case completedAt = "completed_at"
                    case totalVolume = "total_volume"
                    case avgRpe = "avg_rpe"
                    case avgPain = "avg_pain"
                    case durationMinutes = "duration_minutes"
                }
            }

            let updateInput = CompletePrescribedInput(
                completed: true,
                startedAt: startedAt.map { formatter.string(from: $0) },
                completedAt: now,
                totalVolume: totalVolume,
                avgRpe: avgRpe,
                avgPain: avgPain,
                durationMinutes: durationMinutes
            )

            try await supabase.client
                .from("sessions")
                .update(updateInput)
                .eq("id", value: sessionId.uuidString)
                .execute()

            logger.log("Prescribed session completed successfully with all metrics", level: .success)
        } catch {
            logger.log("Failed to complete prescribed session: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch a manual session by ID
    func fetchManualSession(_ sessionId: UUID) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Fetching manual session: \(sessionId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("manual_sessions")
                .select()
                .eq("id", value: sessionId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(ManualSession.self, from: response.data)

            logger.log("Session fetched successfully", level: .success)
            return session
        } catch {
            logger.log("Failed to fetch session: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch exercises for a manual session
    func fetchSessionExercises(sessionId: UUID) async throws -> [ManualSessionExercise] {
        let logger = DebugLogger.shared
        logger.log("Fetching exercises for session: \(sessionId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("manual_session_exercises")
                .select()
                .eq("manual_session_id", value: sessionId.uuidString)
                .order("sequence", ascending: true)
                .order("created_at", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exercises = try decoder.decode([ManualSessionExercise].self, from: response.data)

            logger.log("Fetched \(exercises.count) exercises for session", level: .success)
            return exercises
        } catch {
            logger.log("Failed to fetch session exercises: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch manual workout history for a patient
    func fetchManualWorkoutHistory(patientId: UUID, limit: Int = 20) async throws -> [ManualSession] {
        let logger = DebugLogger.shared
        logger.log("Fetching manual workout history for patient: \(patientId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("manual_sessions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("completed", value: true)
                .order("completed_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sessions = try decoder.decode([ManualSession].self, from: response.data)

            logger.log("Fetched \(sessions.count) completed sessions", level: .success)
            return sessions
        } catch {
            logger.log("Failed to fetch workout history: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Exercise Logging

    /// Log exercise completion in a manual session
    func logManualExercise(
        manualSessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String? = "lbs",
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws {
        let logger = DebugLogger.shared
        logger.log("Logging manual exercise: \(manualSessionExerciseId)", level: .diagnostic)

        let input = CreateManualExerciseLogInput(
            manualSessionExerciseId: manualSessionExerciseId,
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
            try await supabase.client
                .from("exercise_logs")
                .insert(input)
                .execute()

            logger.log("Manual exercise logged successfully to exercise_logs", level: .success)
        } catch {
            logger.log("Failed to log exercise: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// BUILD 258: Log exercise completion in a prescribed session
    func logPrescribedExercise(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String? = "lbs",
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws {
        let logger = DebugLogger.shared
        logger.log("Logging prescribed exercise: \(sessionExerciseId)", level: .diagnostic)

        let formatter = ISO8601DateFormatter()
        let input = CreatePrescribedExerciseLogInput(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            actualSets: actualSets,
            actualReps: actualReps,
            actualLoad: actualLoad,
            loadUnit: loadUnit,
            rpe: rpe,
            painScore: painScore,
            notes: notes,
            loggedAt: formatter.string(from: Date())
        )

        do {
            try await supabase.client
                .from("exercise_logs")
                .insert(input)
                .execute()

            logger.log("Prescribed exercise logged successfully to exercise_logs", level: .success)
        } catch {
            logger.log("Failed to log prescribed exercise: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Favorites (BUILD 282)

    /// Fetch patient's favorite template IDs
    func fetchFavoriteTemplateIds(patientId: UUID) async throws -> (systemIds: Set<UUID>, patientIds: Set<UUID>) {
        let logger = DebugLogger.shared
        logger.log("Fetching favorite template IDs for patient: \(patientId)", level: .diagnostic)

        struct FavoriteRow: Codable {
            let systemTemplateId: UUID?
            let patientTemplateId: UUID?

            enum CodingKeys: String, CodingKey {
                case systemTemplateId = "system_template_id"
                case patientTemplateId = "patient_template_id"
            }
        }

        do {
            let response = try await supabase.client
                .from("patient_favorite_templates")
                .select("system_template_id, patient_template_id")
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            let rows = try decoder.decode([FavoriteRow].self, from: response.data)

            var systemIds: Set<UUID> = []
            var patientIds: Set<UUID> = []

            for row in rows {
                if let sysId = row.systemTemplateId {
                    systemIds.insert(sysId)
                }
                if let patId = row.patientTemplateId {
                    patientIds.insert(patId)
                }
            }

            logger.log("Fetched \(systemIds.count) system favorites, \(patientIds.count) patient favorites", level: .success)
            return (systemIds, patientIds)
        } catch {
            logger.log("Failed to fetch favorites: \(error.localizedDescription)", level: .error)
            // Return empty sets if table doesn't exist
            return ([], [])
        }
    }

    /// Add a system template to favorites
    func addSystemTemplateToFavorites(patientId: UUID, templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Adding system template \(templateId) to favorites", level: .diagnostic)

        struct InsertFavorite: Codable {
            let patientId: UUID
            let systemTemplateId: UUID

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case systemTemplateId = "system_template_id"
            }
        }

        do {
            try await supabase.client
                .from("patient_favorite_templates")
                .insert(InsertFavorite(patientId: patientId, systemTemplateId: templateId))
                .execute()

            logger.log("System template added to favorites", level: .success)
        } catch {
            logger.log("Failed to add to favorites: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Add a patient template to favorites
    func addPatientTemplateToFavorites(patientId: UUID, templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Adding patient template \(templateId) to favorites", level: .diagnostic)

        struct InsertFavorite: Codable {
            let patientId: UUID
            let patientTemplateId: UUID

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case patientTemplateId = "patient_template_id"
            }
        }

        do {
            try await supabase.client
                .from("patient_favorite_templates")
                .insert(InsertFavorite(patientId: patientId, patientTemplateId: templateId))
                .execute()

            logger.log("Patient template added to favorites", level: .success)
        } catch {
            logger.log("Failed to add to favorites: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Remove a system template from favorites
    func removeSystemTemplateFromFavorites(patientId: UUID, templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Removing system template \(templateId) from favorites", level: .diagnostic)

        do {
            try await supabase.client
                .from("patient_favorite_templates")
                .delete()
                .eq("patient_id", value: patientId.uuidString)
                .eq("system_template_id", value: templateId.uuidString)
                .execute()

            logger.log("System template removed from favorites", level: .success)
        } catch {
            logger.log("Failed to remove from favorites: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Remove a patient template from favorites
    func removePatientTemplateFromFavorites(patientId: UUID, templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Removing patient template \(templateId) from favorites", level: .diagnostic)

        do {
            try await supabase.client
                .from("patient_favorite_templates")
                .delete()
                .eq("patient_id", value: patientId.uuidString)
                .eq("patient_template_id", value: templateId.uuidString)
                .execute()

            logger.log("Patient template removed from favorites", level: .success)
        } catch {
            logger.log("Failed to remove from favorites: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Trainer Recommendations (BUILD 282)

    /// Fetch trainer-recommended templates for a patient
    func fetchTrainerRecommendations(patientId: UUID) async throws -> [SystemWorkoutTemplate] {
        let logger = DebugLogger.shared
        logger.log("Fetching trainer recommendations for patient: \(patientId)", level: .diagnostic)

        struct RecommendationRow: Codable {
            let systemTemplateId: UUID
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case systemTemplateId = "system_template_id"
                case notes
            }
        }

        do {
            // First get the recommendation IDs
            let recResponse = try await supabase.client
                .from("trainer_recommended_templates")
                .select("system_template_id, notes")
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            let rows = try decoder.decode([RecommendationRow].self, from: recResponse.data)

            if rows.isEmpty {
                logger.log("No trainer recommendations found", level: .info)
                return []
            }

            // Fetch the actual templates
            let templateIds = rows.map { $0.systemTemplateId.uuidString }
            let templatesResponse = try await supabase.client
                .from("system_workout_templates")
                .select()
                .in("id", values: templateIds)
                .execute()

            decoder.dateDecodingStrategy = .iso8601
            let templates = try decoder.decode([SystemWorkoutTemplate].self, from: templatesResponse.data)

            logger.log("Fetched \(templates.count) trainer-recommended templates", level: .success)
            return templates
        } catch {
            logger.log("Failed to fetch trainer recommendations: \(error.localizedDescription)", level: .error)
            // Return empty array if table doesn't exist
            return []
        }
    }

    // MARK: - Add to Prescribed Session

    /// Add an exercise to a prescribed (scheduled) session
    func addExerciseToPrescribedSession(
        sessionId: UUID,
        exerciseTemplateId: UUID,
        sets: Int,
        reps: Int,
        load: Double?,
        loadUnit: String? = "lbs",
        notes: String?
    ) async throws {
        let logger = DebugLogger.shared
        logger.log("Adding exercise to prescribed session: \(sessionId)", level: .diagnostic)

        let input = AddToPrescribedSessionInput(
            sessionId: sessionId,
            exerciseTemplateId: exerciseTemplateId,
            sets: sets,
            reps: reps,
            load: load,
            loadUnit: loadUnit,
            notes: notes
        )

        do {
            try await supabase.client
                .from("session_exercises")
                .insert(input)
                .execute()

            logger.log("Exercise added to prescribed session successfully", level: .success)
        } catch {
            logger.log("Failed to add exercise to prescribed session: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
