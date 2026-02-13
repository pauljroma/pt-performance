//
//  WorkoutTemplateBuilderViewModel.swift
//  PTPerformance
//
//  ViewModel for creating custom workout templates
//  Handles form state, validation, and saving to system_workout_templates
//

import SwiftUI

// MARK: - Template Exercise Item

/// Represents an exercise within a template being built
struct TemplateExerciseItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: String
    var notes: String

    // Exercise library reference (optional - nil for custom exercises)
    var templateId: UUID?
    var category: String?
    var bodyRegion: String?

    init(
        id: UUID = UUID(),
        name: String = "",
        sets: Int = 3,
        reps: String = "10",
        notes: String = "",
        templateId: UUID? = nil,
        category: String? = nil,
        bodyRegion: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.templateId = templateId
        self.category = category
        self.bodyRegion = bodyRegion
    }

    /// Whether this exercise was selected from the library
    var isFromLibrary: Bool {
        templateId != nil
    }
}

// MARK: - Workout Category

/// Categories for workout templates
enum WorkoutCategory: String, CaseIterable, Identifiable {
    case strength
    case mobility
    case cardio
    case hybrid
    case fullBody = "full_body"
    case upper
    case lower
    case push
    case pull
    case legs
    case crossfit
    case functional

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .mobility: return "Mobility"
        case .cardio: return "Cardio"
        case .hybrid: return "Hybrid"
        case .fullBody: return "Full Body"
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .crossfit: return "CrossFit"
        case .functional: return "Functional"
        }
    }

    var iconName: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .cardio: return "heart.fill"
        case .hybrid: return "arrow.triangle.merge"
        case .fullBody: return "figure.stand"
        case .upper: return "figure.arms.open"
        case .lower: return "figure.walk"
        case .push: return "arrow.right.circle.fill"
        case .pull: return "arrow.left.circle.fill"
        case .legs: return "figure.run"
        case .crossfit: return "figure.highintensity.intervaltraining"
        case .functional: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Workout Difficulty

/// Difficulty levels for workout templates
enum WorkoutDifficulty: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Constants

private enum Limits {
    static let minNameLength = 3
    static let maxNameLength = 100
    static let maxDescriptionLength = 500
    static let minDuration = 5
    static let maxDuration = 180
    static let maxExercises = 50
    static let maxTags = 10
}

// MARK: - ViewModel

@MainActor
class WorkoutTemplateBuilderViewModel: ObservableObject {
    // MARK: - Exercise Library State

    /// Exercise templates loaded from the database
    @Published var exerciseLibrary: [ExerciseTemplateData] = []

    /// Search text for filtering exercise suggestions
    @Published var exerciseSearchText: String = ""

    /// Whether exercise library is loading
    @Published var isLoadingLibrary: Bool = false

    /// Filtered exercises based on search text
    var filteredExercises: [ExerciseTemplateData] {
        guard !exerciseSearchText.isEmpty else { return [] }

        let searchLower = exerciseSearchText.lowercased()
        return exerciseLibrary
            .filter { template in
                template.name.lowercased().contains(searchLower) ||
                (template.category?.lowercased().contains(searchLower) ?? false) ||
                (template.bodyRegion?.lowercased().contains(searchLower) ?? false)
            }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Form State

    /// Template name (required, 3-100 characters)
    @Published var name: String = ""

    /// Template category
    @Published var category: WorkoutCategory = .strength

    /// Template difficulty
    @Published var difficulty: WorkoutDifficulty = .intermediate

    /// Duration in minutes
    @Published var durationMinutes: Int = 45

    /// Optional description
    @Published var description: String = ""

    /// Equipment required (comma-separated in UI, stored as array)
    @Published var equipmentText: String = ""

    /// Tags (comma-separated in UI, stored as array)
    @Published var tagsText: String = ""

    /// List of exercises in the template
    @Published var exercises: [TemplateExerciseItem] = []

    // MARK: - UI State

    /// Whether save operation is in progress
    @Published var isSaving: Bool = false

    /// Whether to show error alert
    @Published var showError: Bool = false

    /// Error message to display
    @Published var errorMessage: String = ""

    /// Whether to show success alert
    @Published var showSuccess: Bool = false

    /// Success message to display
    @Published var successMessage: String = ""

    /// Whether form is valid for submission (computed lazily to avoid cascading updates)
    var isValid: Bool {
        validationMessage == nil
    }

    /// Validation error message (nil if valid) - computed lazily to avoid cascading updates
    var validationMessage: String? {
        computeValidation()
    }

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase

        // Load exercise library on initialization
        Task {
            await loadExerciseLibrary()
        }
    }

    // MARK: - Exercise Library Loading

    /// Load all exercise templates from the database for autocomplete
    func loadExerciseLibrary() async {
        guard exerciseLibrary.isEmpty else { return } // Only load once

        isLoadingLibrary = true
        defer { isLoadingLibrary = false }

        do {
            DebugLogger.shared.log("Loading exercise library for autocomplete", level: .diagnostic)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try await supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region")
                .order("name")
                .execute()

            let templates = try decoder.decode([ExerciseTemplateData].self, from: result.data)

            exerciseLibrary = templates
            DebugLogger.shared.log("Loaded \(templates.count) exercise templates for autocomplete", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to load exercise library: \(error)", level: .error)
            // Don't show error to user - autocomplete is optional enhancement
        }
    }

    /// Select an exercise from the library and add it to the current exercise being edited
    func selectExerciseFromLibrary(_ template: ExerciseTemplateData, forExerciseAt index: Int) {
        guard index >= 0 && index < exercises.count else { return }

        exercises[index].name = template.name
        exercises[index].templateId = template.id
        exercises[index].category = template.category
        exercises[index].bodyRegion = template.bodyRegion
        exerciseSearchText = ""
    }

    // MARK: - Computed Properties

    /// Parsed equipment list from comma-separated text
    var equipmentList: [String] {
        equipmentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Parsed tags list from comma-separated text
    var tagsList: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    /// Total exercise count
    var exerciseCount: Int {
        exercises.count
    }

    // MARK: - Validation

    /// Compute validation state based on current form values (lazy evaluation)
    /// Returns nil if valid, or an error message if invalid
    private func computeValidation() -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        // Name validation
        if trimmedName.isEmpty {
            return "Template name is required"
        }

        if trimmedName.count < Limits.minNameLength {
            return "Name must be at least \(Limits.minNameLength) characters"
        }

        if trimmedName.count > Limits.maxNameLength {
            return "Name must be \(Limits.maxNameLength) characters or less"
        }

        // Description validation
        if description.count > Limits.maxDescriptionLength {
            return "Description must be \(Limits.maxDescriptionLength) characters or less"
        }

        // Duration validation
        if durationMinutes < Limits.minDuration {
            return "Duration must be at least \(Limits.minDuration) minutes"
        }

        if durationMinutes > Limits.maxDuration {
            return "Duration cannot exceed \(Limits.maxDuration) minutes"
        }

        // Exercise validation
        if exercises.count > Limits.maxExercises {
            return "Maximum \(Limits.maxExercises) exercises allowed"
        }

        // Validate each exercise has a name
        for (index, exercise) in exercises.enumerated() {
            if exercise.name.trimmingCharacters(in: .whitespaces).isEmpty {
                return "Exercise \(index + 1) needs a name"
            }
        }

        // Tags validation
        if tagsList.count > Limits.maxTags {
            return "Maximum \(Limits.maxTags) tags allowed"
        }

        return nil
    }

    // MARK: - Exercise Management

    /// Add a new empty exercise to the list
    func addExercise() {
        guard exercises.count < Limits.maxExercises else {
            errorMessage = "Maximum \(Limits.maxExercises) exercises allowed"
            showError = true
            return
        }

        exercises.append(TemplateExerciseItem())
    }

    /// Remove exercise at specified index
    func removeExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    /// Move exercise from one position to another
    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    /// Update exercise at specified index
    func updateExercise(at index: Int, name: String? = nil, sets: Int? = nil, reps: String? = nil, notes: String? = nil) {
        guard index >= 0 && index < exercises.count else { return }

        if let name = name {
            exercises[index].name = name
        }
        if let sets = sets {
            exercises[index].sets = max(1, min(sets, 20))
        }
        if let reps = reps {
            exercises[index].reps = reps
        }
        if let notes = notes {
            exercises[index].notes = notes
        }
    }

    // MARK: - Save Template

    /// Save the template to Supabase
    /// - Returns: The created template ID if successful
    func saveTemplate() async throws -> UUID {
        // Validate first (computed lazily)
        guard isValid else {
            throw WorkoutTemplateBuilderError.validationFailed(validationMessage ?? "Invalid form data")
        }

        isSaving = true

        defer {
            isSaving = false
        }

        do {
            // Build exercises JSONB structure
            let exerciseBlocks = buildExerciseBlocks()

            // Build the template input
            let templateInput = CreateWorkoutTemplateInput(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                category: category.rawValue,
                difficulty: difficulty.rawValue,
                durationMinutes: durationMinutes,
                exercises: exerciseBlocks,
                tags: tagsList.isEmpty ? nil : tagsList
            )

            DebugLogger.shared.log("Saving workout template: \(templateInput.name)", level: .diagnostic)

            // Insert into system_workout_templates
            let response = try await supabase.client
                .from("system_workout_templates")
                .insert(templateInput)
                .select()
                .single()
                .execute()

            // Decode response to get the ID
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let createdTemplate = try decoder.decode(CreatedTemplateResponse.self, from: response.data)

            DebugLogger.shared.log("Workout template created with ID: \(createdTemplate.id)", level: .success)

            successMessage = "Template '\(name)' created successfully!"
            showSuccess = true

            return createdTemplate.id

        } catch {
            DebugLogger.shared.log("Failed to save workout template: \(error)", level: .error)

            let userMessage = translateError(error)
            errorMessage = userMessage
            showError = true

            throw WorkoutTemplateBuilderError.saveFailed(userMessage)
        }
    }

    /// Build exercise blocks structure for JSONB storage
    private func buildExerciseBlocks() -> WorkoutExercises {
        // Group exercises into a single "Main" block for simplicity
        let databaseExercises = exercises.enumerated().map { index, exercise in
            DatabaseExercise(
                id: UUID(),
                exerciseTemplateId: exercise.templateId,
                name: exercise.name.trimmingCharacters(in: .whitespaces),
                sequence: index,
                prescribedSets: exercise.sets,
                prescribedReps: exercise.reps,
                notes: exercise.notes.isEmpty ? nil : exercise.notes.trimmingCharacters(in: .whitespaces),
                rpe: nil,
                duration: nil
            )
        }

        let mainBlock = DatabaseBlock(
            id: UUID(),
            name: "Main",
            blockType: "main",
            sequence: 0,
            exercises: databaseExercises
        )

        return WorkoutExercises(blocks: [mainBlock])
    }

    /// Translate technical errors into user-friendly messages
    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("connection") {
            return "Unable to connect to the server. Please check your internet connection."
        }

        if errorString.contains("timeout") {
            return "The request timed out. Please try again."
        }

        if errorString.contains("unauthorized") || errorString.contains("permission") {
            return "You don't have permission to create templates. Please contact support."
        }

        if errorString.contains("duplicate") || errorString.contains("unique") {
            return "A template with this name already exists. Please choose a different name."
        }

        return "An unexpected error occurred. Please try again."
    }

    // MARK: - Reset Form

    /// Reset all form fields to default values
    func resetForm() {
        name = ""
        category = .strength
        difficulty = .intermediate
        durationMinutes = 45
        description = ""
        equipmentText = ""
        tagsText = ""
        exercises = []
        isSaving = false
        showError = false
        errorMessage = ""
        showSuccess = false
        successMessage = ""
        // Validation is now computed lazily, no need to call updateValidation()
    }

    // MARK: - Error Handling

    /// Dismiss error alert
    func dismissError() {
        showError = false
        errorMessage = ""
    }

    /// Dismiss success alert
    func dismissSuccess() {
        showSuccess = false
        successMessage = ""
    }
}

// MARK: - Input Models

/// Input model for creating a workout template
private struct CreateWorkoutTemplateInput: Codable {
    let name: String
    let description: String?
    let category: String
    let difficulty: String
    let durationMinutes: Int
    let exercises: WorkoutExercises
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case category
        case difficulty
        case durationMinutes = "duration_minutes"
        case exercises
        case tags
    }
}

/// Response model for created template
private struct CreatedTemplateResponse: Codable {
    let id: UUID
}

// MARK: - Error Types

enum WorkoutTemplateBuilderError: LocalizedError {
    case validationFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return message
        }
    }
}

// MARK: - Preview Support

extension WorkoutTemplateBuilderViewModel {
    /// Preview instance with default state
    static var preview: WorkoutTemplateBuilderViewModel {
        WorkoutTemplateBuilderViewModel()
    }

    /// Preview instance with sample data
    static var previewWithData: WorkoutTemplateBuilderViewModel {
        let vm = WorkoutTemplateBuilderViewModel()
        vm.name = "Upper Body Push Day"
        vm.category = .push
        vm.difficulty = .intermediate
        vm.durationMinutes = 60
        vm.description = "Focus on chest, shoulders, and triceps with compound movements."
        vm.equipmentText = "Barbell, Dumbbells, Bench"
        vm.tagsText = "upper, push, chest, shoulders"
        vm.exercises = [
            TemplateExerciseItem(name: "Bench Press", sets: 4, reps: "8-10", notes: "Control the descent"),
            TemplateExerciseItem(name: "Overhead Press", sets: 3, reps: "8-10", notes: ""),
            TemplateExerciseItem(name: "Incline Dumbbell Press", sets: 3, reps: "10-12", notes: ""),
            TemplateExerciseItem(name: "Tricep Pushdowns", sets: 3, reps: "12-15", notes: "")
        ]
        return vm
    }
}
