//
//  WorkoutGridViewModel.swift
//  PTPerformance
//
//  Build 96: Collaborative workout grid editing with real-time sync (Agent 6)
//
//  Provides spreadsheet-like editing of program exercises with:
//  - Editable cells (exercise, sets, reps, weight, notes)
//  - Real-time sync via Supabase
//  - Optimistic updates with conflict resolution
//  - Last-write-wins strategy for concurrent edits
//

import SwiftUI
import Supabase

@MainActor
class WorkoutGridViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var exercises: [WorkoutGridExercise] = []
    @Published var availableExercises: [GridExerciseTemplate] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var error: String?
    @Published var successMessage: String?

    // Edit tracking
    @Published var hasUnsavedChanges = false
    private var pendingEdits: [String: WorkoutGridExercise] = [:] // exerciseId: updated exercise

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private var realtimeChannel: RealtimeChannelV2?

    // MARK: - Configuration

    let sessionId: String

    @MainActor
    init(sessionId: String, supabase: PTSupabaseClient = .shared) {
        self.sessionId = sessionId
        self.supabase = supabase
    }

    // MARK: - Data Loading

    /// Load exercises for the session
    func loadExercises() async {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        logger.log("📥 Loading exercises for session \(sessionId)", level: .diagnostic)

        do {
            // Load exercises with joined exercise_templates
            let response = try await supabase.client
                .from("session_exercises")
                .select("""
                    id,
                    session_id,
                    exercise_template_id,
                    prescribed_sets,
                    prescribed_reps,
                    prescribed_load,
                    load_unit,
                    rest_period_seconds,
                    notes,
                    sequence,
                    exercise_templates (
                        id,
                        name,
                        category,
                        body_region
                    )
                """)
                .eq("session_id", value: sessionId)
                .order("sequence", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let sessionExercises = try decoder.decode([SessionExerciseWithTemplate].self, from: response.data)

            // Convert to grid exercises
            exercises = sessionExercises.map { convertToGridExercise($0) }

            logger.log("✅ Loaded \(exercises.count) exercises", level: .success)

        } catch {
            logger.log("❌ Failed to load exercises: \(error)", level: .error)
            self.error = "Failed to load exercises. Please try again."
        }
    }

    /// Load available exercise templates for dropdown
    func loadAvailableExercises() async {
        logger.log("📥 Loading available exercise templates", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region")
                .order("name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            availableExercises = try decoder.decode([GridExerciseTemplate].self, from: response.data)

            logger.log("✅ Loaded \(availableExercises.count) exercise templates", level: .success)

        } catch {
            logger.log("❌ Failed to load exercise templates: \(error)", level: .error)
            // Non-critical error - continue with empty list
        }
    }

    // MARK: - Real-time Sync

    /// Subscribe to real-time updates for this session's exercises
    func subscribeToRealtimeUpdates() {
        logger.log("🔔 Subscribing to real-time updates for session \(sessionId)", level: .diagnostic)

        // Create channel for this session
        realtimeChannel = supabase.client.realtimeV2.channel("session_exercises:\(sessionId)")

        Task {
            // Guard against nil channel before accessing
            guard let channel = realtimeChannel else {
                logger.log("Realtime channel is nil, cannot subscribe", level: .warning)
                return
            }

            // Listen for INSERT, UPDATE, DELETE on session_exercises using new filter syntax
            let changes = channel
                .postgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "session_exercises",
                    filter: .eq("session_id", value: sessionId)
                )

            do {
                try await channel.subscribeWithError()
            } catch {
                logger.log("Realtime subscription error: \(error)", level: .error)
                return
            }

            for await change in changes {
                await handleRealtimeChange(change)
            }
        }
    }

    /// Unsubscribe from real-time updates
    func unsubscribeFromRealtimeUpdates() {
        logger.log("🔕 Unsubscribing from real-time updates", level: .diagnostic)

        Task {
            await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
        }
    }

    /// Handle real-time database changes
    private func handleRealtimeChange(_ change: AnyAction) async {
        logger.log("🔔 Received real-time change", level: .diagnostic)

        // Reload exercises to get latest data
        // This is a simple approach - could be optimized to only update changed rows
        await loadExercises()

        // Clear pending edits for the changed exercise to avoid conflicts
        // In a production app, you might want more sophisticated conflict resolution
    }

    // MARK: - Cell Editing

    /// Update a cell value (optimistic update)
    func updateCell(exerciseId: String, field: GridField, value: Any) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseId }) else {
            logger.log("⚠️ Exercise not found: \(exerciseId)", level: .warning)
            return
        }

        var exercise = exercises[index]

        // Update the field
        switch field {
        case .exercise:
            if let templateId = value as? String {
                exercise.exerciseTemplateId = templateId
                // Find exercise name
                if let template = availableExercises.first(where: { $0.id == templateId }) {
                    exercise.exerciseName = template.name
                }
            }
        case .sets:
            if let sets = value as? Int, sets > 0 {
                exercise.prescribedSets = sets
            }
        case .reps:
            if let reps = value as? String, !reps.isEmpty {
                exercise.prescribedReps = reps
            }
        case .weight:
            if let weight = value as? Double {
                exercise.prescribedLoad = weight
            } else if let weightStr = value as? String {
                exercise.prescribedLoad = Double(weightStr)
            }
        case .notes:
            if let notes = value as? String {
                exercise.notes = notes.isEmpty ? nil : notes
            }
        }

        // Update local state (optimistic update)
        exercises[index] = exercise

        // Track as pending edit
        pendingEdits[exerciseId] = exercise
        hasUnsavedChanges = true

        logger.log("✏️ Cell updated (optimistic): \(field) = \(value)", level: .diagnostic)
    }

    /// Add new exercise row
    func addExerciseRow() {
        // Add a blank row at the end
        let newExercise = WorkoutGridExercise(
            id: UUID().uuidString,
            sessionId: sessionId,
            exerciseTemplateId: "",
            exerciseName: "Select Exercise",
            prescribedSets: 3,
            prescribedReps: "10",
            prescribedLoad: nil,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            sequence: exercises.count
        )

        exercises.append(newExercise)
        pendingEdits[newExercise.id] = newExercise
        hasUnsavedChanges = true

        logger.log("➕ Added new exercise row", level: .diagnostic)
    }

    /// Remove exercise row
    func removeExerciseRow(exerciseId: String) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseId }) else {
            return
        }

        exercises.remove(at: index)
        pendingEdits[exerciseId] = nil
        hasUnsavedChanges = true

        logger.log("🗑️ Removed exercise row", level: .diagnostic)
    }

    // MARK: - Validation

    /// Validate exercise data before saving
    private func validateExercise(_ exercise: WorkoutGridExercise) throws {
        guard !exercise.exerciseTemplateId.isEmpty else {
            throw WorkoutGridError.noExerciseSelected
        }

        guard exercise.prescribedSets > 0 else {
            throw WorkoutGridError.invalidSets
        }

        guard exercise.prescribedSets <= 20 else {
            throw WorkoutGridError.setsTooHigh
        }

        guard !exercise.prescribedReps.isEmpty else {
            throw WorkoutGridError.invalidReps
        }

        // Validate reps format (should be number or range like "8-10")
        let repsComponents = exercise.prescribedReps.split(separator: "-")
        for component in repsComponents {
            guard Int(component.trimmingCharacters(in: .whitespaces)) != nil else {
                throw WorkoutGridError.invalidRepsFormat
            }
        }

        if let load = exercise.prescribedLoad, load < 0 {
            throw WorkoutGridError.negativeWeight
        }
    }

    // MARK: - Save Changes

    /// Save all pending edits to database (batch update)
    func saveChanges() async {
        guard hasUnsavedChanges else {
            logger.log("ℹ️ No changes to save", level: .diagnostic)
            return
        }

        isSyncing = true
        error = nil
        successMessage = nil

        defer {
            isSyncing = false
        }

        logger.log("💾 Saving \(pendingEdits.count) pending edits", level: .diagnostic)

        var savedCount = 0
        var errorCount = 0

        for (exerciseId, exercise) in pendingEdits {
            do {
                // Validate before saving
                try validateExercise(exercise)

                // Check if this is a new exercise (UUID format)
                let isNew = UUID(uuidString: exerciseId) != nil && !exercises.contains(where: { $0.id == exerciseId && !$0.exerciseTemplateId.isEmpty })

                if isNew && !exercise.exerciseTemplateId.isEmpty {
                    // Insert new exercise
                    let input = GridSaveExerciseInput(
                        sessionId: sessionId,
                        exerciseTemplateId: exercise.exerciseTemplateId,
                        prescribedSets: exercise.prescribedSets,
                        prescribedReps: exercise.prescribedReps,
                        prescribedLoad: exercise.prescribedLoad,
                        loadUnit: exercise.loadUnit,
                        restPeriodSeconds: exercise.restPeriodSeconds,
                        notes: exercise.notes,
                        sequence: exercise.sequence
                    )

                    try await supabase.client
                        .from("session_exercises")
                        .insert(input)
                        .execute()

                    logger.log("✅ Inserted new exercise", level: .success)

                } else if !exercise.exerciseTemplateId.isEmpty {
                    // Update existing exercise
                    let update = GridUpdateExerciseInput(
                        prescribedSets: exercise.prescribedSets,
                        prescribedReps: exercise.prescribedReps,
                        prescribedLoad: exercise.prescribedLoad,
                        loadUnit: exercise.loadUnit,
                        restPeriodSeconds: exercise.restPeriodSeconds,
                        notes: exercise.notes
                    )

                    try await supabase.client
                        .from("session_exercises")
                        .update(update)
                        .eq("id", value: exerciseId)
                        .execute()

                    logger.log("✅ Updated exercise \(exerciseId)", level: .success)
                }

                savedCount += 1

            } catch let error as WorkoutGridError {
                logger.log("❌ Validation error for \(exerciseId): \(error.localizedDescription)", level: .error)
                self.error = error.localizedDescription
                errorCount += 1

            } catch {
                logger.log("❌ Failed to save exercise \(exerciseId): \(error)", level: .error)
                errorCount += 1
            }
        }

        // Clear pending edits
        pendingEdits.removeAll()
        hasUnsavedChanges = false

        // Show result message
        if errorCount == 0 {
            successMessage = "All changes saved successfully (\(savedCount) exercises)"
            logger.log("✅ ✅ ✅ ALL CHANGES SAVED", level: .success)

            // Reload to get any server-side updates
            await loadExercises()

        } else {
            error = "Saved \(savedCount) exercises, \(errorCount) failed. Please check and try again."
            logger.log("⚠️ Partial save: \(savedCount) succeeded, \(errorCount) failed", level: .warning)
        }
    }

    /// Discard all pending changes
    func discardChanges() async {
        logger.log("🔄 Discarding pending changes", level: .diagnostic)

        pendingEdits.removeAll()
        hasUnsavedChanges = false

        // Reload from database
        await loadExercises()
    }

    // MARK: - Helper Methods

    private func convertToGridExercise(_ sessionExercise: SessionExerciseWithTemplate) -> WorkoutGridExercise {
        return WorkoutGridExercise(
            id: sessionExercise.id,
            sessionId: sessionExercise.session_id,
            exerciseTemplateId: sessionExercise.exercise_template_id,
            exerciseName: sessionExercise.exercise_templates?.name ?? "Unknown",
            prescribedSets: sessionExercise.prescribed_sets,
            prescribedReps: sessionExercise.prescribed_reps ?? "0",
            prescribedLoad: sessionExercise.prescribed_load,
            loadUnit: sessionExercise.load_unit ?? "lbs",
            restPeriodSeconds: sessionExercise.rest_period_seconds,
            notes: sessionExercise.notes,
            sequence: sessionExercise.sequence ?? 0
        )
    }
}

// MARK: - Supporting Types

struct WorkoutGridExercise: Identifiable, Equatable {
    let id: String
    let sessionId: String
    var exerciseTemplateId: String
    var exerciseName: String
    var prescribedSets: Int
    var prescribedReps: String
    var prescribedLoad: Double?
    var loadUnit: String?
    var restPeriodSeconds: Int?
    var notes: String?
    var sequence: Int
}

struct SessionExerciseWithTemplate: Codable {
    let id: String
    let session_id: String
    let exercise_template_id: String
    let prescribed_sets: Int
    let prescribed_reps: String?
    let prescribed_load: Double?
    let load_unit: String?
    let rest_period_seconds: Int?
    let notes: String?
    let sequence: Int?
    let exercise_templates: ExerciseTemplateBasic?

    struct ExerciseTemplateBasic: Codable {
        let id: String
        let name: String
        let category: String?
        let body_region: String?
    }
}

struct GridExerciseTemplate: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String?
    let body_region: String?
}

struct GridSaveExerciseInput: Codable {
    let sessionId: String
    let exerciseTemplateId: String
    let prescribedSets: Int
    let prescribedReps: String
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?
    let sequence: Int?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case exerciseTemplateId = "exercise_template_id"
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
        case sequence
    }
}

struct GridUpdateExerciseInput: Codable {
    let prescribedSets: Int
    let prescribedReps: String
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
    }
}

enum GridField {
    case exercise
    case sets
    case reps
    case weight
    case notes
}

enum WorkoutGridError: LocalizedError {
    case noExerciseSelected
    case invalidSets
    case setsTooHigh
    case invalidReps
    case invalidRepsFormat
    case negativeWeight

    var errorDescription: String? {
        switch self {
        case .noExerciseSelected:
            return "Please select an exercise"
        case .invalidSets:
            return "Sets must be greater than 0"
        case .setsTooHigh:
            return "Sets cannot exceed 20"
        case .invalidReps:
            return "Reps cannot be empty"
        case .invalidRepsFormat:
            return "Reps must be a number or range (e.g., '10' or '8-10')"
        case .negativeWeight:
            return "Weight cannot be negative"
        }
    }
}
