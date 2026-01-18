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

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let templates = try decoder.decode([PatientWorkoutTemplate].self, from: response.data)

            logger.log("Fetched \(templates.count) patient templates", level: .success)
            return templates
        } catch {
            logger.log("Failed to fetch patient templates: \(error.localizedDescription)", level: .error)
            throw error
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

        let input = CreatePatientTemplateInput(
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

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(ManualSession.self, from: response.data)

            logger.log("Manual session created with ID: \(session.id)", level: .success)
            return session
        } catch {
            logger.log("Failed to create manual session: \(error.localizedDescription)", level: .error)
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
                .from("manual_exercise_logs")
                .insert(input)
                .execute()

            logger.log("Exercise logged successfully", level: .success)
        } catch {
            logger.log("Failed to log exercise: \(error.localizedDescription)", level: .error)
            throw error
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
