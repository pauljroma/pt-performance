//
//  TherapistProgramBuilderViewModel.swift
//  PTPerformance
//
//  ViewModel for therapist-side program building (creating programs for program_library)
//

import SwiftUI

// MARK: - Data Models

/// Represents a phase being built by the therapist
struct TherapistPhaseData: Identifiable {
    let id: UUID
    var name: String
    var sequence: Int
    var durationWeeks: Int
    var goals: String
    var workoutAssignments: [TherapistWorkoutAssignment]

    init(
        id: UUID = UUID(),
        name: String = "",
        sequence: Int = 1,
        durationWeeks: Int = 4,
        goals: String = "",
        workoutAssignments: [TherapistWorkoutAssignment] = []
    ) {
        self.id = id
        self.name = name
        self.sequence = sequence
        self.durationWeeks = durationWeeks
        self.goals = goals
        self.workoutAssignments = workoutAssignments
    }
}

/// Represents a workout template assignment to a specific week/day
struct TherapistWorkoutAssignment: Identifiable {
    let id: UUID
    var templateId: UUID
    var templateName: String
    var weekNumber: Int
    var dayOfWeek: Int

    init(
        id: UUID = UUID(),
        templateId: UUID,
        templateName: String,
        weekNumber: Int,
        dayOfWeek: Int
    ) {
        self.id = id
        self.templateId = templateId
        self.templateName = templateName
        self.weekNumber = weekNumber
        self.dayOfWeek = dayOfWeek
    }
}

// MARK: - ViewModel

@MainActor
class TherapistProgramBuilderViewModel: ObservableObject {

    // MARK: - Published Properties - Program Metadata

    @Published var programName: String = ""
    @Published var description: String = ""
    @Published var category: String = ProgramCategory.strength.rawValue
    @Published var difficultyLevel: String = DifficultyLevel.intermediate.rawValue
    @Published var durationWeeks: Int = 12
    @Published var equipmentRequired: [String] = []
    @Published var tags: [String] = []

    // Input fields for adding equipment/tags
    @Published var equipmentInput: String = ""
    @Published var tagsInput: String = ""

    // MARK: - Published Properties - Phases

    @Published var phases: [TherapistPhaseData] = []

    // MARK: - Published Properties - State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared
    private var createdProgramId: UUID?

    // MARK: - Computed Properties

    /// Validates the program has minimum required data
    var isValid: Bool {
        let nameValid = !programName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        programName.count >= 3 &&
                        programName.count <= 100

        return nameValid
    }

    /// Validates the program is ready to publish (has phases with workouts)
    var isReadyToPublish: Bool {
        guard isValid else { return false }
        guard !phases.isEmpty else { return false }

        // Check that at least one phase has workout assignments
        let hasAssignments = phases.contains { !$0.workoutAssignments.isEmpty }
        return hasAssignments
    }

    /// Total duration of all phases combined
    var totalPhaseDuration: Int {
        phases.reduce(0) { $0 + $1.durationWeeks }
    }

    // MARK: - Equipment Management

    func addEquipmentFromInput() {
        let items = equipmentInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !equipmentRequired.contains($0) }

        equipmentRequired.append(contentsOf: items)
        equipmentInput = ""
    }

    func removeEquipment(_ equipment: String) {
        equipmentRequired.removeAll { $0 == equipment }
    }

    // MARK: - Tag Management

    func addTagsFromInput() {
        let items = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && !tags.contains($0) }

        tags.append(contentsOf: items)
        tagsInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    // MARK: - Phase Management

    func addPhase() {
        let newSequence = phases.count + 1
        let newPhase = TherapistPhaseData(
            name: "Phase \(newSequence)",
            sequence: newSequence,
            durationWeeks: 4,
            goals: ""
        )
        phases.append(newPhase)
    }

    func updatePhase(_ phase: TherapistPhaseData) {
        if let index = phases.firstIndex(where: { $0.id == phase.id }) {
            phases[index] = phase
        }
    }

    func deletePhase(at index: Int) {
        guard phases.indices.contains(index) else { return }
        phases.remove(at: index)

        // Resequence remaining phases
        for i in phases.indices {
            phases[i].sequence = i + 1
        }
    }

    func movePhases(from source: IndexSet, to destination: Int) {
        phases.move(fromOffsets: source, toOffset: destination)

        // Resequence after move
        for i in phases.indices {
            phases[i].sequence = i + 1
        }
    }

    // MARK: - CRUD Operations

    /// Creates a program (draft - not published to library yet)
    func createProgram() async throws -> UUID {
        guard isValid else {
            throw TherapistProgramBuilderError.invalidProgram
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        logger.log("Creating program: \(programName)", level: .diagnostic)

        do {
            // Step 1: Create the program record
            let programInput = TherapistCreateProgramInput(
                name: programName.trimmingCharacters(in: .whitespacesAndNewlines),
                targetLevel: difficultyLevel.capitalized,
                durationWeeks: totalPhaseDuration > 0 ? totalPhaseDuration : durationWeeks,
                programType: "training"
            )

            let programResponse = try await supabase.client
                .from("programs")
                .insert(programInput)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program = try decoder.decode(Program.self, from: programResponse.data)
            createdProgramId = program.id

            logger.log("Program created with ID: \(program.id)", level: .success)

            // Step 2: Create phases
            for phase in phases {
                try await createPhase(phase, programId: program.id)
            }

            successMessage = "Program '\(programName)' saved as draft"
            logger.log("Program draft saved successfully", level: .success)

            return program.id

        } catch {
            logger.log("Failed to create program: \(error)", level: .error)
            errorMessage = "Unable to save your program. Please check your connection and try again."
            throw error
        }
    }

    /// Creates a phase for a program
    private func createPhase(_ phase: TherapistPhaseData, programId: UUID) async throws {
        logger.log("Creating phase: \(phase.name)", level: .diagnostic)

        let phaseInput = TherapistCreatePhaseInput(
            programId: programId.uuidString,
            phaseNumber: phase.sequence,
            name: phase.name.trimmingCharacters(in: .whitespacesAndNewlines),
            durationWeeks: phase.durationWeeks,
            goals: phase.goals.isEmpty ? nil : phase.goals
        )

        let phaseResponse = try await supabase.client
            .from("phases")
            .insert(phaseInput)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        let createdPhase = try decoder.decode(Phase.self, from: phaseResponse.data)

        logger.log("Phase created with ID: \(createdPhase.id)", level: .success)

        // Create workout assignments for this phase
        for assignment in phase.workoutAssignments {
            try await createWorkoutAssignment(assignment, phaseId: createdPhase.id, programId: programId)
        }
    }

    /// Creates a workout assignment (links a workout template to a phase)
    private func createWorkoutAssignment(
        _ assignment: TherapistWorkoutAssignment,
        phaseId: UUID,
        programId: UUID
    ) async throws {
        logger.log("Creating workout assignment: \(assignment.templateName) for Week \(assignment.weekNumber), Day \(assignment.dayOfWeek)", level: .diagnostic)

        let assignmentInput = TherapistCreateWorkoutAssignmentInput(
            programId: programId.uuidString,
            phaseId: phaseId.uuidString,
            templateId: assignment.templateId.uuidString,
            weekNumber: assignment.weekNumber,
            dayOfWeek: assignment.dayOfWeek
        )

        try await supabase.client
            .from("program_workout_assignments")
            .insert(assignmentInput)
            .execute()

        logger.log("Workout assignment created", level: .success)
    }

    /// Publishes the program to the program_library for patients to browse
    func publishToLibrary() async throws {
        guard isReadyToPublish else {
            throw TherapistProgramBuilderError.notReadyToPublish
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        logger.log("Publishing program to library: \(programName)", level: .diagnostic)

        do {
            // First create/save the program if not already created
            let programId: UUID
            if let existingId = createdProgramId {
                programId = existingId
            } else {
                programId = try await createProgram()
            }

            // Create the program_library entry
            let libraryInput = TherapistCreateLibraryEntryInput(
                title: programName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                category: category,
                durationWeeks: totalPhaseDuration > 0 ? totalPhaseDuration : durationWeeks,
                difficultyLevel: difficultyLevel,
                equipmentRequired: equipmentRequired,
                programId: programId.uuidString,
                isFeatured: false,
                tags: tags,
                author: await getCurrentTherapistName()
            )

            let libraryResponse = try await supabase.client
                .from("program_library")
                .insert(libraryInput)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let libraryEntry = try decoder.decode(ProgramLibrary.self, from: libraryResponse.data)

            logger.log("Program published to library with ID: \(libraryEntry.id)", level: .success)

            successMessage = "Program '\(programName)' published to library!"

        } catch {
            logger.log("Failed to publish to library: \(error)", level: .error)
            errorMessage = "Unable to publish your program. Please try again."
            throw error
        }
    }

    /// Gets the current therapist's name for the author field
    private func getCurrentTherapistName() async -> String? {
        guard let userId = supabase.userId else { return nil }

        do {
            struct ProfileResponse: Codable {
                let fullName: String?

                enum CodingKeys: String, CodingKey {
                    case fullName = "full_name"
                }
            }

            let response = try await supabase.client
                .from("profiles")
                .select("full_name")
                .eq("id", value: userId)
                .single()
                .execute()

            let profile = try JSONDecoder().decode(ProfileResponse.self, from: response.data)
            return profile.fullName
        } catch {
            logger.log("Failed to get therapist name: \(error)", level: .warning)
            return nil
        }
    }
}

// MARK: - Input Models

private struct TherapistCreateProgramInput: Codable {
    let name: String
    let targetLevel: String
    let durationWeeks: Int
    let programType: String

    enum CodingKeys: String, CodingKey {
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
        case programType = "program_type"
    }
}

private struct TherapistCreatePhaseInput: Codable {
    let programId: String
    let phaseNumber: Int
    let name: String
    let durationWeeks: Int?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case phaseNumber = "phase_number"
        case name
        case durationWeeks = "duration_weeks"
        case goals
    }
}

private struct TherapistCreateWorkoutAssignmentInput: Codable {
    let programId: String
    let phaseId: String
    let templateId: String
    let weekNumber: Int
    let dayOfWeek: Int

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case phaseId = "phase_id"
        case templateId = "template_id"
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
    }
}

private struct TherapistCreateLibraryEntryInput: Codable {
    let title: String
    let description: String?
    let category: String
    let durationWeeks: Int
    let difficultyLevel: String
    let equipmentRequired: [String]
    let programId: String
    let isFeatured: Bool
    let tags: [String]
    let author: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case durationWeeks = "duration_weeks"
        case difficultyLevel = "difficulty_level"
        case equipmentRequired = "equipment_required"
        case programId = "program_id"
        case isFeatured = "is_featured"
        case tags
        case author
    }
}

// MARK: - Error Types

enum TherapistProgramBuilderError: LocalizedError {
    case invalidProgram
    case notReadyToPublish
    case programCreationFailed
    case phaseCreationFailed
    case publishFailed

    var errorDescription: String? {
        switch self {
        case .invalidProgram:
            return "Please fill in all required program details"
        case .notReadyToPublish:
            return "Add at least one phase with workout assignments to publish"
        case .programCreationFailed:
            return "Failed to create program"
        case .phaseCreationFailed:
            return "Failed to create phase"
        case .publishFailed:
            return "Failed to publish to library"
        }
    }
}
