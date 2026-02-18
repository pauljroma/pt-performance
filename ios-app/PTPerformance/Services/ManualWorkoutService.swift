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
    let assignedByUserId: UUID?
    let sessionSource: String?

    enum CodingKeys: String, CodingKey {
        case name
        case patientId = "patient_id"
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
        case assignedByUserId = "assigned_by_user_id"
        case sessionSource = "session_source"
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

/// Input for logging prescribed exercise (session_exercise_id reference)
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

/// Input for updating usage count
struct UsageCountUpdate: Encodable {
    let usageCount: Int

    enum CodingKeys: String, CodingKey {
        case usageCount = "usage_count"
    }
}

/// Input for updating order index
struct OrderIndexUpdate: Encodable {
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case orderIndex = "order_index"
    }
}

/// Input for starting a workout (setting started_at)
struct StartWorkoutUpdate: Encodable {
    let startedAt: String

    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
    }
}

// MARK: - Service

/// Service for managing manual workout templates and sessions

class ManualWorkoutService: ObservableObject {
    private let supabase: PTSupabaseClient

    // MARK: - Static Formatters

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - System Templates

    /// Fetch system workout templates with optional category and search filters.
    ///
    /// System templates are pre-defined workout templates created by trainers that
    /// all patients can access. Results are ordered alphabetically by name.
    ///
    /// - Parameters:
    ///   - category: Optional category filter (e.g., "strength", "mobility")
    ///   - search: Optional search string to filter by template name (case-insensitive)
    /// - Returns: Array of matching system workout templates
    /// - Throws: Database errors if the query fails
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchSystemTemplates")
            throw error
        }
    }

    // MARK: - Patient Templates

    /// Fetch workout templates created by a specific patient.
    ///
    /// Patient templates are custom workouts saved by the user for reuse.
    /// Results are ordered by usage count (most used first).
    ///
    /// - Parameter patientId: The UUID of the patient whose templates to fetch
    /// - Returns: Array of patient workout templates, or empty array if none exist
    /// - Note: Returns empty array instead of throwing if the table doesn't exist,
    ///         allowing graceful degradation for new installations.
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchPatientTemplates", metadata: ["patient_id": patientId.uuidString])
            #if DEBUG
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
            #endif
            // Return empty array instead of throwing - table may not exist yet
            logger.log("Returning empty patient templates (table may not exist)", level: .diagnostic)
            return []
        }
    }

    /// Save a collection of exercises as a reusable patient template.
    ///
    /// Creates a new patient-owned template that can be used to quickly start
    /// future workouts with the same exercise configuration.
    ///
    /// - Parameters:
    ///   - name: Display name for the template
    ///   - description: Optional description of the template's purpose
    ///   - blocks: The workout blocks containing exercises to save
    ///   - patientId: The UUID of the patient who owns this template
    ///   - category: Optional category for organizing templates
    /// - Returns: The newly created patient workout template
    /// - Throws: Database errors if the insert fails
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.saveAsTemplate", metadata: ["patient_id": patientId.uuidString, "name": name])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.deleteTemplate", metadata: ["template_id": templateId.uuidString])
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
                .update(UsageCountUpdate(usageCount: newCount))
                .eq("id", value: templateId.uuidString)
                .execute()

            logger.log("Usage count incremented to \(newCount)", level: .success)
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.incrementUsageCount", metadata: ["template_id": templateId.uuidString])
            throw error
        }
    }

    // MARK: - Manual Sessions

    /// Create a new manual workout session for a patient.
    ///
    /// A manual session represents an ad-hoc workout that the patient creates
    /// themselves, as opposed to a prescribed session from their program.
    /// The session can optionally be based on a template.
    ///
    /// - Parameters:
    ///   - name: Display name for the session
    ///   - patientId: The UUID of the patient performing the workout
    ///   - sourceTemplateId: Optional ID of the template this session is based on
    ///   - sourceTemplateType: Type of source template (system or patient)
    ///   - assignedByUserId: Optional ID of trainer who assigned the workout
    ///   - sessionSource: How the workout was initiated (defaults to .chosen)
    /// - Returns: The newly created manual session
    /// - Throws: Database errors if the insert fails
    func createManualSession(
        name: String,
        patientId: UUID,
        sourceTemplateId: UUID? = nil,
        sourceTemplateType: SourceTemplateType? = nil,
        assignedByUserId: UUID? = nil,
        sessionSource: SessionSource = .chosen
    ) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Creating manual session '\(name)' for patient: \(patientId) with source: \(sessionSource.rawValue)", level: .diagnostic)

        let input = CreateManualSessionInput(
            patientId: patientId,
            name: name,
            sourceTemplateId: sourceTemplateId,
            sourceTemplateType: sourceTemplateType?.rawValue,
            assignedByUserId: assignedByUserId,
            sessionSource: sessionSource.rawValue
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.createManualSession", metadata: ["patient_id": patientId.uuidString, "name": name])
            #if DEBUG
            // Log detailed decode error for debugging
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
            #endif
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.addExercise", metadata: ["session_id": sessionId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.updateExercise", metadata: ["exercise_id": exercise.id.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.removeExercise", metadata: ["exercise_id": exerciseId.uuidString])
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
                    .update(OrderIndexUpdate(orderIndex: index))
                    .eq("id", value: exerciseId.uuidString)
                    .eq("manual_session_id", value: sessionId.uuidString)
                    .execute()
            }

            logger.log("Exercises reordered successfully", level: .success)
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.reorderExercises", metadata: ["session_id": sessionId.uuidString])
            throw error
        }
    }

    /// Start a manual workout session by recording the start timestamp.
    ///
    /// This marks the beginning of an active workout. The `started_at` timestamp
    /// is used to calculate workout duration when the session is completed.
    ///
    /// - Parameter sessionId: The UUID of the manual session to start
    /// - Returns: The updated manual session with `started_at` set
    /// - Throws: Database errors if the update fails or session not found
    func startWorkout(_ sessionId: UUID) async throws -> ManualSession {
        let logger = DebugLogger.shared
        logger.log("Starting workout session: \(sessionId)", level: .diagnostic)

        do {
            let now = Self.iso8601Formatter.string(from: Date())

            let response = try await supabase.client
                .from("manual_sessions")
                .update(StartWorkoutUpdate(startedAt: now))
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
                logger.log("Workout started at \(now)", level: .success)
                return session
            } catch let decodeError {
                ErrorLogger.shared.logError(decodeError, context: "ManualWorkoutService.startWorkout.decode", metadata: ["session_id": sessionId.uuidString])
                throw decodeError
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.startWorkout", metadata: ["session_id": sessionId.uuidString])
            throw error
        }
    }

    /// Complete a manual workout session with summary metrics.
    ///
    /// Marks the session as completed and records aggregate workout metrics.
    /// Also triggers side effects including:
    /// - Recording workout completion for smart notification learning
    /// - Exporting the workout to Apple Health (if enabled)
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the manual session to complete
    ///   - totalVolume: Total workout volume (sets x reps x load)
    ///   - avgRpe: Average RPE across all exercises
    ///   - avgPain: Average pain score across all exercises
    ///   - durationMinutes: Total workout duration in minutes
    /// - Returns: The completed manual session with all metrics recorded
    /// - Throws: Database errors if the update fails
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
            let now = Self.iso8601Formatter.string(from: Date())

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

            // ACP-841: Record workout completion for smart notification pattern learning
            if let patientIdString = PTSupabaseClient.shared.userId,
               let patientUUID = UUID(uuidString: patientIdString) {
                Task {
                    do {
                        try await SmartNotificationService.shared.recordWorkoutCompletion(
                            for: patientUUID,
                            completionTime: Date()
                        )
                    } catch {
                        DebugLogger.shared.log("Failed to record workout completion notification: \(error.localizedDescription)", level: .warning)
                    }
                }
            }

            // ACP-827: Export completed workout to Apple Health
            Task { @MainActor in
                await HealthSyncManager.shared.exportCompletedManualSession(session)
            }

            // ACP-979: Track workout completion for App Store review prompting
            Task { @MainActor in
                ASOService.shared.trackWorkoutCompleted()
            }

            return session
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.completeWorkout", metadata: ["session_id": sessionId.uuidString])
            throw error
        }
    }

    /// Complete a prescribed workout session from the patient's program.
    ///
    /// Unlike manual sessions, prescribed sessions come from the patient's
    /// assigned program and are stored in the `sessions` table. This method
    /// records completion metrics for trainer review and progress tracking.
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the prescribed session to complete
    ///   - startedAt: When the patient started the workout (for duration calculation)
    ///   - totalVolume: Total workout volume (sets x reps x load)
    ///   - avgRpe: Average RPE across all exercises
    ///   - avgPain: Average pain score across all exercises
    ///   - durationMinutes: Total workout duration in minutes
    /// - Throws: Database errors if the update fails
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
            let now = Self.iso8601Formatter.string(from: Date())

            // Include started_at for proper session summary time-based filtering
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
                startedAt: startedAt.map { Self.iso8601Formatter.string(from: $0) },
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

            // ACP-841: Record workout completion for smart notification pattern learning
            if let patientIdString = PTSupabaseClient.shared.userId,
               let patientUUID = UUID(uuidString: patientIdString) {
                Task {
                    do {
                        try await SmartNotificationService.shared.recordWorkoutCompletion(
                            for: patientUUID,
                            completionTime: Date()
                        )
                    } catch {
                        DebugLogger.shared.log("Failed to record prescribed session completion notification: \(error.localizedDescription)", level: .warning)
                    }
                }
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.completePrescribedSession", metadata: ["session_id": sessionId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchManualSession", metadata: ["session_id": sessionId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchSessionExercises", metadata: ["session_id": sessionId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchManualWorkoutHistory", metadata: ["patient_id": patientId.uuidString])
            throw error
        }
    }

    // MARK: - Exercise Logging

    /// Log completion of an exercise within a manual workout session.
    ///
    /// Records the actual performance data for an exercise, including sets,
    /// reps per set, load used, and subjective feedback (RPE and pain).
    /// This data is used for progression calculations and trainer review.
    ///
    /// - Parameters:
    ///   - manualSessionExerciseId: The UUID of the exercise to log
    ///   - patientId: The UUID of the patient performing the exercise
    ///   - actualSets: Number of sets completed
    ///   - actualReps: Array of reps completed per set
    ///   - actualLoad: Weight/load used (optional for bodyweight exercises)
    ///   - loadUnit: Unit of measurement for load (defaults to "lbs")
    ///   - rpe: Rate of Perceived Exertion (1-10 scale)
    ///   - painScore: Pain level during exercise (0-10 scale)
    ///   - notes: Optional notes about the exercise performance
    /// - Throws: Database errors if the insert fails
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.logManualExercise", metadata: ["exercise_id": manualSessionExerciseId.uuidString, "patient_id": patientId.uuidString])
            throw error
        }
    }

    /// Log completion of an exercise within a prescribed workout session.
    ///
    /// Similar to `logManualExercise`, but for exercises that are part of
    /// the patient's assigned program. The logged data is compared against
    /// prescribed targets for compliance tracking.
    ///
    /// - Parameters:
    ///   - sessionExerciseId: The UUID of the prescribed exercise to log
    ///   - patientId: The UUID of the patient performing the exercise
    ///   - actualSets: Number of sets completed
    ///   - actualReps: Array of reps completed per set
    ///   - actualLoad: Weight/load used (optional for bodyweight exercises)
    ///   - loadUnit: Unit of measurement for load (defaults to "lbs")
    ///   - rpe: Rate of Perceived Exertion (1-10 scale)
    ///   - painScore: Pain level during exercise (0-10 scale)
    ///   - notes: Optional notes about the exercise performance
    /// - Throws: Database errors if the insert fails
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
            loggedAt: Self.iso8601Formatter.string(from: Date())
        )

        do {
            try await supabase.client
                .from("exercise_logs")
                .insert(input)
                .execute()

            logger.log("Prescribed exercise logged successfully to exercise_logs", level: .success)
        } catch {
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.logPrescribedExercise", metadata: ["exercise_id": sessionExerciseId.uuidString, "patient_id": patientId.uuidString])
            throw error
        }
    }

    // MARK: - Favorites

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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchFavoriteTemplateIds", metadata: ["patient_id": patientId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.addSystemTemplateToFavorites", metadata: ["patient_id": patientId.uuidString, "template_id": templateId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.addPatientTemplateToFavorites", metadata: ["patient_id": patientId.uuidString, "template_id": templateId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.removeSystemTemplateFromFavorites", metadata: ["patient_id": patientId.uuidString, "template_id": templateId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.removePatientTemplateFromFavorites", metadata: ["patient_id": patientId.uuidString, "template_id": templateId.uuidString])
            throw error
        }
    }

    // MARK: - Trainer Recommendations

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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.fetchTrainerRecommendations", metadata: ["patient_id": patientId.uuidString])
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
            ErrorLogger.shared.logError(error, context: "ManualWorkoutService.addExerciseToPrescribedSession", metadata: ["session_id": sessionId.uuidString, "exercise_template_id": exerciseTemplateId.uuidString])
            throw error
        }
    }
}
