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

    // MARK: - Builder Step Enum

    enum BuilderStep: Int, CaseIterable {
        case start = 0
        case quickBuildPicker = 1
        case templatePicker = 2
        case patient = 3
        case basics = 4
        case phases = 5
        case workouts = 6
        case preview = 7

        var displayName: String {
            switch self {
            case .start: return "Start"
            case .quickBuildPicker: return "Quick Build"
            case .templatePicker: return "Template"
            case .patient: return "Patient"
            case .basics: return "Basics"
            case .phases: return "Phases"
            case .workouts: return "Workouts"
            case .preview: return "Preview"
            }
        }
    }

    // MARK: - Creation Mode Enum

    enum CreationMode: String, CaseIterable {
        case quickBuild
        case fromTemplate
        case custom

        var title: String {
            switch self {
            case .quickBuild: return "Quick Build"
            case .fromTemplate: return "From Template"
            case .custom: return "Custom Program"
            }
        }

        var description: String {
            switch self {
            case .quickBuild: return "AI-assisted program creation with smart defaults"
            case .fromTemplate: return "Start from an existing program template"
            case .custom: return "Build from scratch with full control"
            }
        }

        var icon: String {
            switch self {
            case .quickBuild: return "sparkles"
            case .fromTemplate: return "doc.on.doc"
            case .custom: return "hammer"
            }
        }
    }

    // MARK: - Published Properties - Wizard State

    @Published var currentStep: BuilderStep = .start
    @Published var selectedPatient: Patient?
    @Published var creationMode: CreationMode = .custom

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

    // MARK: - Published Properties - Template Selection

    @Published var availableTemplates: [ProgramLibrary] = []
    @Published var selectedTemplate: ProgramLibrary?
    @Published var templateSearchText: String = ""
    @Published var isLoadingTemplates: Bool = false

    // MARK: - Published Properties - Quick Build Template Selection

    @Published var selectedQuickBuildTemplate: QuickBuildTemplate?

    // MARK: - Published Properties - State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var templateLoadFailed: Bool = false
    @Published var showUnsavedChangesAlert: Bool = false

    /// Tracks if user has made changes that would be lost on navigation
    var hasUnsavedChanges: Bool {
        !phases.isEmpty || !programName.isEmpty || selectedPatient != nil
    }

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let programLibraryService = ProgramLibraryService()
    private let programBuilderService = ProgramBuilderService()
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

    /// Whether the current step can proceed to next
    var canProceed: Bool {
        switch currentStep {
        case .start:
            // Always can proceed from start (mode is pre-selected)
            return true
        case .quickBuildPicker:
            // Quick build selection - always can proceed (template is pre-selected)
            return selectedQuickBuildTemplate != nil
        case .templatePicker:
            // Must select a template when in fromTemplate mode
            return selectedTemplate != nil
        case .patient:
            // Patient is optional, can always proceed
            return true
        case .basics:
            // Need a valid program name
            return isValid
        case .phases:
            // Can proceed even without phases (will be validated on preview)
            return true
        case .workouts:
            // Can proceed even without workouts assigned
            return true
        case .preview:
            // Need to be ready to publish
            return isReadyToPublish
        }
    }

    // MARK: - Wizard Navigation

    /// Advance to the next step
    func nextStep() {
        var nextRawValue = currentStep.rawValue + 1

        // Handle conditional step navigation based on creation mode
        if currentStep == .start {
            switch creationMode {
            case .quickBuild:
                nextRawValue = BuilderStep.quickBuildPicker.rawValue
            case .fromTemplate:
                nextRawValue = BuilderStep.templatePicker.rawValue
            case .custom:
                nextRawValue = BuilderStep.patient.rawValue
            }
        } else if currentStep == .quickBuildPicker || currentStep == .templatePicker {
            // After picking a template (quick or from library), go to patient
            // Clear search text when leaving template picker
            templateSearchText = ""
            nextRawValue = BuilderStep.patient.rawValue
        }

        // Clear error message when advancing
        errorMessage = nil

        guard let nextIndex = BuilderStep(rawValue: nextRawValue) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    /// Go back to the previous step
    func previousStep() {
        var prevRawValue = currentStep.rawValue - 1

        // Handle conditional step navigation when going back
        if currentStep == .patient {
            switch creationMode {
            case .quickBuild:
                prevRawValue = BuilderStep.quickBuildPicker.rawValue
            case .fromTemplate:
                prevRawValue = BuilderStep.templatePicker.rawValue
            case .custom:
                prevRawValue = BuilderStep.start.rawValue
            }
        } else if currentStep == .quickBuildPicker || currentStep == .templatePicker {
            prevRawValue = BuilderStep.start.rawValue
        }

        // Clear error message when going back
        errorMessage = nil

        guard let prevIndex = BuilderStep(rawValue: prevRawValue) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    /// Check if navigating back would lose significant work
    func wouldLoseWorkGoingBack() -> Bool {
        switch currentStep {
        case .phases:
            return !phases.isEmpty
        case .workouts:
            return phases.contains { !$0.workoutAssignments.isEmpty }
        default:
            return false
        }
    }

    /// Jump to a specific step
    func goToStep(_ step: BuilderStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    /// Reset the wizard to the beginning
    func resetWizard() {
        currentStep = .start
        selectedPatient = nil
        creationMode = .custom
        programName = ""
        description = ""
        category = ProgramCategory.strength.rawValue
        difficultyLevel = DifficultyLevel.intermediate.rawValue
        durationWeeks = 12
        equipmentRequired = []
        tags = []
        equipmentInput = ""
        tagsInput = ""
        phases = []
        availableTemplates = []
        selectedTemplate = nil
        selectedQuickBuildTemplate = nil
        templateSearchText = ""
        errorMessage = nil
        successMessage = nil
        createdProgramId = nil
    }

    // MARK: - Equipment Management

    /// Maximum length for equipment items
    private let maxEquipmentLength = 50

    func addEquipmentFromInput() {
        let items = equipmentInput
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { item in
                !item.isEmpty &&
                item.count <= maxEquipmentLength &&
                !equipmentRequired.contains(item) &&
                item.rangeOfCharacter(from: CharacterSet.alphanumerics.union(.whitespaces).inverted) == nil
            }
            .prefix(10) // Limit to 10 items at once

        equipmentRequired.append(contentsOf: items)
        equipmentInput = ""
    }

    func removeEquipment(_ equipment: String) {
        equipmentRequired.removeAll { $0 == equipment }
    }

    // MARK: - Tag Management

    /// Maximum length for tag items
    private let maxTagLength = 30

    func addTagsFromInput() {
        let items = tagsInput
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { item in
                !item.isEmpty &&
                item.count <= maxTagLength &&
                !tags.contains(item) &&
                item.rangeOfCharacter(from: CharacterSet.alphanumerics.union(.whitespaces).inverted) == nil
            }
            .prefix(10) // Limit to 10 items at once

        tags.append(contentsOf: items)
        tagsInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    // MARK: - Phase Management

    /// Maximum phase name length
    private let maxPhaseNameLength = 100

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
            // Validate and sanitize phase name
            var updatedPhase = phase
            let trimmedName = phase.name.trimmingCharacters(in: .whitespacesAndNewlines)

            // If name is empty or whitespace, use default
            if trimmedName.isEmpty {
                updatedPhase.name = "Phase \(phase.sequence)"
            } else if trimmedName.count > maxPhaseNameLength {
                // Truncate if too long
                updatedPhase.name = String(trimmedName.prefix(maxPhaseNameLength))
            } else {
                updatedPhase.name = trimmedName
            }

            phases[index] = updatedPhase
        }
    }

    /// Validate a phase name
    func validatePhaseName(_ name: String) -> (isValid: Bool, message: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return (false, "Phase name cannot be empty")
        }
        if trimmed.count > maxPhaseNameLength {
            return (false, "Phase name must be \(maxPhaseNameLength) characters or less")
        }
        return (true, nil)
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

    // MARK: - Template Management

    /// Computed property for filtered templates based on search text
    var filteredTemplates: [ProgramLibrary] {
        if templateSearchText.isEmpty {
            return availableTemplates
        }
        let lowercasedSearch = templateSearchText.lowercased()
        return availableTemplates.filter { template in
            template.title.lowercased().contains(lowercasedSearch) ||
            (template.description?.lowercased().contains(lowercasedSearch) ?? false) ||
            template.category.lowercased().contains(lowercasedSearch) ||
            (template.tagsList.contains { $0.lowercased().contains(lowercasedSearch) })
        }
    }

    /// Load available program templates from the program_library table
    func loadTemplates(forceReload: Bool = false) async {
        guard availableTemplates.isEmpty || forceReload else { return } // Skip if already loaded

        isLoadingTemplates = true
        templateLoadFailed = false
        errorMessage = nil
        logger.log("Loading program templates from library...", level: .diagnostic)

        do {
            let templates = try await programLibraryService.fetchPrograms()
            await MainActor.run {
                self.availableTemplates = templates
                self.isLoadingTemplates = false
                self.templateLoadFailed = false
            }
            logger.log("Loaded \(templates.count) program templates", level: .success)
        } catch {
            logger.log("Failed to load templates: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                self.isLoadingTemplates = false
                self.templateLoadFailed = true
                self.errorMessage = "Unable to load templates. Check your connection and try again."
            }
        }
    }

    /// Retry loading templates after failure
    func retryLoadTemplates() async {
        await loadTemplates(forceReload: true)
    }

    /// Apply a selected template to pre-fill the wizard state
    /// Copies the program's metadata, phases, and workout assignments
    func applyTemplate(_ template: ProgramLibrary) async {
        logger.log("Applying template: \(template.title)", level: .diagnostic)
        selectedTemplate = template

        // Pre-fill basic program metadata from the template
        programName = "\(template.title) (Copy)"
        description = template.description ?? ""
        category = template.category
        difficultyLevel = template.difficultyLevel
        durationWeeks = template.durationWeeks
        equipmentRequired = template.equipment
        tags = template.tagsList

        // If the template has a linked program_id, fetch its phases and workout assignments
        guard let programId = template.programId else {
            logger.log("Template has no linked program_id, using metadata only", level: .warning)
            return
        }

        isLoading = true

        do {
            // Fetch the full program structure including phases and workout assignments
            let programWithPhases = try await programBuilderService.getProgram(id: programId)

            // Convert PhaseWithAssignments to TherapistPhaseData
            var newPhases: [TherapistPhaseData] = []

            for phaseData in programWithPhases.phases {
                // Fetch workout template names for the assignments
                let workoutAssignments = await fetchWorkoutAssignmentNames(for: phaseData.assignments)

                let therapistPhase = TherapistPhaseData(
                    id: UUID(), // New ID for the copy
                    name: phaseData.name,
                    sequence: phaseData.sequence,
                    durationWeeks: phaseData.durationWeeks ?? 4,
                    goals: phaseData.goals ?? "",
                    workoutAssignments: workoutAssignments
                )
                newPhases.append(therapistPhase)
            }

            await MainActor.run {
                self.phases = newPhases
                self.isLoading = false
            }

            logger.log("Applied template with \(newPhases.count) phases", level: .success)

        } catch {
            logger.log("Failed to load template phases: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                self.isLoading = false
                // Template metadata is already applied, just couldn't load phases
                // Show a more actionable error with clear next steps
                self.errorMessage = "Template basics loaded, but phases couldn't be fetched. You can continue and add phases manually, or go back to try a different template."
            }
        }
    }

    /// Check if template application is in a partial state (metadata loaded but no phases)
    var isTemplatePartiallyApplied: Bool {
        selectedTemplate != nil && phases.isEmpty && !programName.isEmpty
    }

    /// Helper to fetch workout template names for assignments
    private func fetchWorkoutAssignmentNames(for assignments: [ProgramWorkoutAssignment]) async -> [TherapistWorkoutAssignment] {
        var therapistAssignments: [TherapistWorkoutAssignment] = []

        // Collect all template IDs
        let templateIds = assignments.map { $0.templateId }

        guard !templateIds.isEmpty else { return [] }

        // Fetch template names in batch
        do {
            let response = try await supabase.client
                .from("system_workout_templates")
                .select("id, name")
                .in("id", values: templateIds.map { $0.uuidString })
                .execute()

            struct TemplateNameRow: Codable {
                let id: UUID
                let name: String
            }

            let templateNames = try JSONDecoder().decode([TemplateNameRow].self, from: response.data)
            let nameLookup = Dictionary(uniqueKeysWithValues: templateNames.map { ($0.id, $0.name) })

            // Create therapist assignments with names
            for assignment in assignments {
                let templateName = nameLookup[assignment.templateId] ?? "Unknown Workout"
                let therapistAssignment = TherapistWorkoutAssignment(
                    id: UUID(), // New ID for the copy
                    templateId: assignment.templateId,
                    templateName: templateName,
                    weekNumber: assignment.weekNumber,
                    dayOfWeek: assignment.dayOfWeek
                )
                therapistAssignments.append(therapistAssignment)
            }
        } catch {
            logger.log("Failed to fetch workout template names: \(error.localizedDescription)", level: .warning)
            // Return assignments with placeholder names
            for assignment in assignments {
                let therapistAssignment = TherapistWorkoutAssignment(
                    id: UUID(),
                    templateId: assignment.templateId,
                    templateName: "Workout",
                    weekNumber: assignment.weekNumber,
                    dayOfWeek: assignment.dayOfWeek
                )
                therapistAssignments.append(therapistAssignment)
            }
        }

        return therapistAssignments
    }

    /// Clear template selection (allows re-selecting)
    func clearTemplateSelection() {
        selectedTemplate = nil
        // Don't clear the pre-filled data - user might want to keep it
    }

    // MARK: - Quick Build Template Application

    /// Apply a QuickBuildTemplate to pre-fill the wizard state
    /// This is used for the "Quick Build" creation mode with pre-built templates
    func applyQuickBuildTemplate(_ template: QuickBuildTemplate) {
        logger.log("Applying quick build template: \(template.name)", level: .diagnostic)

        // Handle custom template (blank slate)
        if template.isCustom {
            // Reset to defaults for custom program
            programName = ""
            description = ""
            category = ProgramCategory.strength.rawValue
            difficultyLevel = DifficultyLevel.intermediate.rawValue
            durationWeeks = 4
            phases = []
            logger.log("Applied custom template - blank slate ready", level: .success)
            return
        }

        // Pre-fill basic program metadata from the template
        programName = template.name
        description = template.description
        category = template.categoryForViewModel
        difficultyLevel = template.difficultyLevel
        durationWeeks = template.durationWeeks

        // Convert PhaseTemplates to TherapistPhaseData
        phases = template.toTherapistPhases()

        logger.log("Applied quick build template with \(phases.count) phases", level: .success)
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
                programType: "training",
                therapistId: supabase.userId
            )

            let programResponse = try await supabase.client
                .from("programs")
                .insert(programInput)
                .select()
                .single()
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
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
            sequence: phase.sequence,
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

        // Track if we created a new program in this call (for rollback)
        var newlyCreatedProgramId: UUID?

        do {
            // First create/save the program if not already created
            let programId: UUID
            if let existingId = createdProgramId {
                programId = existingId
            } else {
                programId = try await createProgram()
                newlyCreatedProgramId = programId // Mark for potential rollback
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
                therapistId: supabase.userId,
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

            let decoder = PTSupabaseClient.flexibleDecoder
            let libraryEntry = try decoder.decode(ProgramLibrary.self, from: libraryResponse.data)

            logger.log("Program published to library with ID: \(libraryEntry.id)", level: .success)

            // Auto-assign to patient if one was selected
            if let patient = selectedPatient {
                // Patient assignment failure should not fail the whole publish
                do {
                    try await assignProgramToPatient(libraryEntryId: libraryEntry.id, patient: patient)
                    successMessage = "Program published and assigned to \(patient.fullName)!"
                } catch {
                    logger.log("Failed to auto-assign to patient: \(error)", level: .warning)
                    successMessage = "Program published! (Patient assignment failed - you can assign manually)"
                }
            } else {
                successMessage = "Program '\(programName)' published to library!"
            }

        } catch {
            logger.log("Failed to publish to library: \(error)", level: .error)

            // If we created a new program but library entry failed, try to clean up
            if let orphanedId = newlyCreatedProgramId {
                logger.log("Attempting to clean up orphaned program \(orphanedId)", level: .diagnostic)
                await cleanupOrphanedProgram(programId: orphanedId)
                createdProgramId = nil // Reset so next attempt creates fresh
            }

            errorMessage = "Unable to publish your program. Please try again."
            throw error
        }
    }

    /// Attempts to delete an orphaned program created during a failed publish
    private func cleanupOrphanedProgram(programId: UUID) async {
        do {
            // Delete phases first (cascade should handle assignments)
            try await supabase.client
                .from("phases")
                .delete()
                .eq("program_id", value: programId.uuidString)
                .execute()

            // Delete the program
            try await supabase.client
                .from("programs")
                .delete()
                .eq("id", value: programId.uuidString)
                .execute()

            logger.log("Cleaned up orphaned program \(programId)", level: .success)
        } catch {
            // Cleanup failed - not critical, just log it
            logger.log("Failed to clean up orphaned program: \(error)", level: .warning)
        }
    }

    /// Assigns a program to a patient by creating a patient_programs record
    /// - Parameters:
    ///   - libraryEntryId: The ID of the program_library entry
    ///   - patient: The patient to assign the program to
    func assignProgramToPatient(libraryEntryId: UUID, patient: Patient) async throws {
        guard let therapistId = supabase.userId else {
            throw TherapistProgramBuilderError.assignmentFailed
        }

        logger.log("Assigning program to patient: \(patient.fullName)", level: .diagnostic)

        let assignmentInput = TherapistPatientProgramInsert(
            patientId: patient.id.uuidString,
            templateId: libraryEntryId.uuidString,
            therapistId: therapistId,
            status: "active",
            startDate: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.client
            .from("patient_programs")
            .insert(assignmentInput)
            .execute()

        logger.log("Program assigned to patient \(patient.fullName)", level: .success)
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
    let therapistId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
        case programType = "program_type"
        case therapistId = "therapist_id"
    }
}

private struct TherapistCreatePhaseInput: Codable {
    let programId: String
    let sequence: Int
    let name: String
    let durationWeeks: Int?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case sequence
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
    let therapistId: String?
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
        case therapistId = "therapist_id"
        case isFeatured = "is_featured"
        case tags
        case author
    }
}

private struct TherapistPatientProgramInsert: Codable {
    let patientId: String
    let templateId: String
    let therapistId: String
    let status: String
    let startDate: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case templateId = "template_id"
        case therapistId = "therapist_id"
        case status
        case startDate = "start_date"
    }
}

// MARK: - Error Types

enum TherapistProgramBuilderError: LocalizedError {
    case invalidProgram
    case notReadyToPublish
    case programCreationFailed
    case phaseCreationFailed
    case publishFailed
    case assignmentFailed

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
        case .assignmentFailed:
            return "Failed to assign program to patient"
        }
    }
}
