//
//  SOAPNoteViewModel.swift
//  PTPerformance
//
//  ViewModel for SOAP note editing including template application,
//  auto-save drafts, and signing workflow.
//

import SwiftUI
import Combine

// MARK: - SOAP Section

/// Represents a section of the SOAP note
enum SOAPSection: String, CaseIterable, Identifiable {
    case subjective = "S"
    case objective = "O"
    case assessment = "A"
    case plan = "P"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subjective: return "Subjective"
        case .objective: return "Objective"
        case .assessment: return "Assessment"
        case .plan: return "Plan"
        }
    }

    var description: String {
        switch self {
        case .subjective:
            return "Patient's reported symptoms, concerns, and progress"
        case .objective:
            return "Measurable findings, observations, and test results"
        case .assessment:
            return "Clinical impression and interpretation of findings"
        case .plan:
            return "Treatment plan, goals, and next steps"
        }
    }

    var iconName: String {
        switch self {
        case .subjective: return "person.bubble"
        case .objective: return "ruler"
        case .assessment: return "brain.head.profile"
        case .plan: return "list.bullet.clipboard"
        }
    }
}

// MARK: - SOAPNoteViewModel

/// ViewModel for SOAP note editing and management
@MainActor
class SOAPNoteViewModel: ObservableObject {

    // MARK: - Published Properties - Form State

    @Published var patientId: UUID?
    @Published var therapistId: UUID?
    @Published var sessionId: UUID?
    @Published var noteDate: Date = Date()

    // SOAP Sections
    @Published var subjective: String = ""
    @Published var objective: String = ""
    @Published var assessment: String = ""
    @Published var plan: String = ""

    // Clinical Measurements
    @Published var vitals: Vitals = Vitals()
    @Published var painLevel: Int = 0
    @Published var functionalStatus: FunctionalStatus = .stable

    // Billing
    @Published var timeSpentMinutes: Int = 0
    @Published var selectedCptCodes: [String] = []

    // MARK: - Published Properties - UI State

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var currentNote: SOAPNote?
    @Published var activeSection: SOAPSection = .subjective
    @Published var lastAutoSaveDate: Date?
    @Published var hasUnsavedChanges = false
    @Published var showValidationErrors = false

    // Template Management
    @Published var availableTemplates: [SOAPNoteTemplate] = []
    @Published var selectedTemplate: SOAPNoteTemplate?

    // MARK: - Dependencies

    private let noteService: SOAPNoteService
    private var autoSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    private enum Config {
        static let autoSaveInterval: TimeInterval = 30.0
    }

    // MARK: - Computed Properties

    /// Whether the note is editable
    var isEditable: Bool {
        guard let note = currentNote else { return true }
        return note.status.isEditable
    }

    /// Whether all SOAP sections are complete
    var isComplete: Bool {
        !subjective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !assessment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether the note can be submitted
    var canSubmit: Bool {
        isComplete && isEditable && !isSaving
    }

    /// Whether the note can be signed
    var canSign: Bool {
        guard let note = currentNote else { return false }
        return note.status == .complete && isComplete && !isSaving
    }

    /// Whether the note can be saved as draft
    var canSaveDraft: Bool {
        patientId != nil && therapistId != nil && isEditable && !isSaving
    }

    /// Completion percentage for progress display
    var completionPercentage: Double {
        var filled = 0
        if !subjective.isEmpty { filled += 1 }
        if !objective.isEmpty { filled += 1 }
        if !assessment.isEmpty { filled += 1 }
        if !plan.isEmpty { filled += 1 }
        return Double(filled) / 4.0 * 100
    }

    /// Preview text for the note
    var previewText: String {
        if !subjective.isEmpty {
            let preview = subjective.prefix(100)
            return preview.count < subjective.count ? "\(preview)..." : String(preview)
        }
        return "No content"
    }

    /// Formatted time spent
    var formattedTimeSpent: String {
        if timeSpentMinutes >= 60 {
            let hours = timeSpentMinutes / 60
            let minutes = timeSpentMinutes % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(timeSpentMinutes) min"
    }

    /// Formatted note date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: noteDate)
    }

    // MARK: - Initialization

    init(noteService: SOAPNoteService = .shared) {
        self.noteService = noteService
        setupAutoSave()
        setupFormObservers()
    }

    deinit {
        autoSaveTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: Config.autoSaveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.autoSaveDraft()
            }
        }
    }

    private func setupFormObservers() {
        // Track changes to form fields
        Publishers.CombineLatest4($subjective, $objective, $assessment, $plan)
            .sink { [weak self] _, _, _, _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($painLevel, $timeSpentMinutes)
            .sink { [weak self] _, _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Form Actions

    /// Initialize for a new note
    func initializeNewNote(
        patientId: UUID,
        therapistId: UUID,
        sessionId: UUID? = nil
    ) {
        self.patientId = patientId
        self.therapistId = therapistId
        self.sessionId = sessionId
        self.noteDate = Date()

        resetForm()
    }

    /// Load an existing note for editing
    func loadNote(_ note: SOAPNote) {
        currentNote = note
        patientId = note.patientId
        therapistId = note.therapistId
        sessionId = note.sessionId
        noteDate = note.noteDate

        subjective = note.subjective ?? ""
        objective = note.objective ?? ""
        assessment = note.assessment ?? ""
        plan = note.plan ?? ""

        vitals = note.vitals ?? Vitals()
        painLevel = note.painLevel ?? 0
        functionalStatus = note.functionalStatus ?? .stable

        timeSpentMinutes = note.timeSpentMinutes ?? 0
        selectedCptCodes = note.cptCodes ?? []

        hasUnsavedChanges = false
    }

    /// Reset form to initial state
    func resetForm() {
        subjective = ""
        objective = ""
        assessment = ""
        plan = ""

        vitals = Vitals()
        painLevel = 0
        functionalStatus = .stable

        timeSpentMinutes = 0
        selectedCptCodes = []

        currentNote = nil
        activeSection = .subjective
        hasUnsavedChanges = false
        errorMessage = nil
        successMessage = nil
        showValidationErrors = false
    }

    /// Navigate to next section
    func nextSection() {
        let sections = SOAPSection.allCases
        if let currentIndex = sections.firstIndex(of: activeSection),
           currentIndex < sections.count - 1 {
            activeSection = sections[currentIndex + 1]
        }
    }

    /// Navigate to previous section
    func previousSection() {
        let sections = SOAPSection.allCases
        if let currentIndex = sections.firstIndex(of: activeSection),
           currentIndex > 0 {
            activeSection = sections[currentIndex - 1]
        }
    }

    // MARK: - Template Operations

    /// Fetch available templates
    func fetchTemplates(category: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            availableTemplates = try await noteService.fetchTemplates(category: category)
        } catch {
            errorMessage = "Failed to load templates: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Apply a template to the current note
    func applyTemplate(_ template: SOAPNoteTemplate) {
        if let templateSubjective = template.subjective {
            subjective = templateSubjective
        }
        if let templateObjective = template.objective {
            objective = templateObjective
        }
        if let templateAssessment = template.assessment {
            assessment = templateAssessment
        }
        if let templatePlan = template.plan {
            plan = templatePlan
        }
        if let defaultCodes = template.defaultCptCodes {
            selectedCptCodes = defaultCodes
        }

        selectedTemplate = template
        hasUnsavedChanges = true

        #if DEBUG
        print("[SOAPNoteVM] Applied template: \(template.name)")
        #endif
    }

    // MARK: - CPT Code Management

    /// Toggle a CPT code selection
    func toggleCptCode(_ code: String) {
        if selectedCptCodes.contains(code) {
            selectedCptCodes.removeAll { $0 == code }
        } else {
            selectedCptCodes.append(code)
        }
        hasUnsavedChanges = true
    }

    /// Check if a CPT code is selected
    func isCptCodeSelected(_ code: String) -> Bool {
        selectedCptCodes.contains(code)
    }

    // MARK: - Save Operations

    /// Create a new note
    private func createNote() async throws -> SOAPNote {
        guard let patientId = patientId,
              let therapistId = therapistId else {
            throw SOAPNoteServiceError.missingPatientId
        }

        let input = SOAPNoteInput(
            patientId: patientId.uuidString,
            therapistId: therapistId.uuidString,
            sessionId: sessionId?.uuidString,
            noteDate: noteDate.iso8601String,
            subjective: subjective.isEmpty ? nil : subjective,
            objective: objective.isEmpty ? nil : objective,
            assessment: assessment.isEmpty ? nil : assessment,
            plan: plan.isEmpty ? nil : plan,
            vitals: vitals.hasData ? vitals : nil,
            painLevel: painLevel > 0 ? painLevel : nil,
            functionalStatus: functionalStatus.rawValue,
            timeSpentMinutes: timeSpentMinutes > 0 ? timeSpentMinutes : nil,
            cptCodes: selectedCptCodes.isEmpty ? nil : selectedCptCodes,
            status: NoteStatus.draft.rawValue
        )

        return try await noteService.createNote(input: input)
    }

    /// Save current form state as draft
    func saveDraft() async {
        if currentNote == nil {
            // Create new note first
            isSaving = true
            errorMessage = nil

            do {
                let note = try await createNote()
                currentNote = note
                hasUnsavedChanges = false
                lastAutoSaveDate = Date()
                successMessage = "Draft created"
            } catch {
                errorMessage = "Failed to create draft: \(error.localizedDescription)"
                DebugLogger.shared.error("SOAPNoteViewModel", "Create draft error: \(error)")
            }

            isSaving = false
            return
        }

        guard isEditable else {
            errorMessage = "Cannot edit a signed note"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let update = SOAPNoteUpdate(
                subjective: subjective.isEmpty ? nil : subjective,
                objective: objective.isEmpty ? nil : objective,
                assessment: assessment.isEmpty ? nil : assessment,
                plan: plan.isEmpty ? nil : plan,
                vitals: vitals.hasData ? vitals : nil,
                painLevel: painLevel > 0 ? painLevel : nil,
                functionalStatus: functionalStatus.rawValue,
                timeSpentMinutes: timeSpentMinutes > 0 ? timeSpentMinutes : nil,
                cptCodes: selectedCptCodes.isEmpty ? nil : selectedCptCodes
            )

            let updatedNote = try await noteService.updateNote(
                id: currentNote!.id.uuidString,
                update: update
            )

            currentNote = updatedNote
            hasUnsavedChanges = false
            lastAutoSaveDate = Date()
            successMessage = "Draft saved"

            #if DEBUG
            print("[SOAPNoteVM] Draft saved: \(updatedNote.id)")
            #endif
        } catch {
            errorMessage = "Failed to save draft: \(error.localizedDescription)"
            DebugLogger.shared.error("SOAPNoteViewModel", "Save draft error: \(error)")
        }

        isSaving = false
    }

    /// Auto-save draft silently
    private func autoSaveDraft() async {
        guard hasUnsavedChanges, currentNote != nil, !isSaving else { return }

        // Queue for auto-save in service
        if let note = buildCurrentNote() {
            noteService.queueForAutoSave(note)
        }
    }

    /// Build current note from form state
    private func buildCurrentNote() -> SOAPNote? {
        guard let patientId = patientId,
              let therapistId = therapistId else { return nil }

        return SOAPNote(
            id: currentNote?.id ?? UUID(),
            patientId: patientId,
            therapistId: therapistId,
            sessionId: sessionId,
            noteDate: noteDate,
            subjective: subjective.isEmpty ? nil : subjective,
            objective: objective.isEmpty ? nil : objective,
            assessment: assessment.isEmpty ? nil : assessment,
            plan: plan.isEmpty ? nil : plan,
            vitals: vitals.hasData ? vitals : nil,
            painLevel: painLevel > 0 ? painLevel : nil,
            functionalStatus: functionalStatus,
            timeSpentMinutes: timeSpentMinutes > 0 ? timeSpentMinutes : nil,
            cptCodes: selectedCptCodes.isEmpty ? nil : selectedCptCodes,
            status: currentNote?.status ?? .draft
        )
    }

    /// Mark note as complete (ready for signature)
    func submitNote() async {
        guard let note = currentNote else {
            // Create and submit
            await saveDraft()
            guard let createdNote = currentNote else { return }
            await submitNoteById(createdNote.id.uuidString)
            return
        }

        // Validate completeness
        guard validateForSubmission() else {
            showValidationErrors = true
            return
        }

        await submitNoteById(note.id.uuidString)
    }

    private func submitNoteById(_ noteId: String) async {
        isSaving = true
        errorMessage = nil

        do {
            // First save any pending changes
            await saveDraft()

            // Then mark as complete
            let completedNote = try await noteService.markComplete(id: noteId)
            currentNote = completedNote
            successMessage = "Note submitted and ready for signature"
        } catch {
            errorMessage = "Failed to submit note: \(error.localizedDescription)"
            DebugLogger.shared.error("SOAPNoteViewModel", "Submit error: \(error)")
        }

        isSaving = false
    }

    /// Sign the note
    func signNote(signedBy: String) async {
        guard let note = currentNote else {
            errorMessage = "No note to sign"
            return
        }

        guard note.status == .complete else {
            errorMessage = "Note must be complete before signing"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let signedNote = try await noteService.signNote(
                id: note.id.uuidString,
                signedBy: signedBy
            )

            currentNote = signedNote
            successMessage = "Note signed successfully"

            // Stop auto-save since note is now locked
            autoSaveTimer?.invalidate()
        } catch {
            errorMessage = "Failed to sign note: \(error.localizedDescription)"
            DebugLogger.shared.error("SOAPNoteViewModel", "Sign error: \(error)")
        }

        isSaving = false
    }

    /// Create an addendum to a signed note
    func createAddendum(addendumText: String) async {
        guard let note = currentNote,
              let therapistId = therapistId else {
            errorMessage = "Cannot create addendum"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let addendum = try await noteService.createAddendum(
                parentNoteId: note.id.uuidString,
                addendumText: addendumText,
                therapistId: therapistId.uuidString
            )

            currentNote = addendum
            subjective = addendumText
            successMessage = "Addendum created"
        } catch {
            errorMessage = "Failed to create addendum: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Validation

    /// Validate note for submission
    private func validateForSubmission() -> Bool {
        if subjective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Subjective section is required"
            return false
        }
        if objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Objective section is required"
            return false
        }
        if assessment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Assessment section is required"
            return false
        }
        if plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Plan section is required"
            return false
        }
        return true
    }

    // MARK: - Helpers

    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// Delete the current note (drafts only)
    func deleteNote() async {
        guard let note = currentNote else { return }

        guard note.status == .draft else {
            errorMessage = "Only draft notes can be deleted"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await noteService.deleteNote(id: note.id.uuidString)
            resetForm()
            successMessage = "Note deleted"
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension SOAPNoteViewModel {
    static var preview: SOAPNoteViewModel {
        let viewModel = SOAPNoteViewModel()
        viewModel.patientId = UUID()
        viewModel.therapistId = UUID()
        viewModel.subjective = "Patient reports decreased shoulder pain since last visit. Pain is now 4/10 with overhead activities."
        viewModel.objective = "AROM: Shoulder flexion 160 degrees. Strength: 4/5 rotator cuff."
        viewModel.assessment = "Patient demonstrating good progress with decreased pain and improved ROM."
        viewModel.plan = "Continue therapeutic exercise program. Progress strengthening next visit."
        viewModel.painLevel = 4
        viewModel.functionalStatus = .improving
        viewModel.timeSpentMinutes = 45
        viewModel.selectedCptCodes = ["97110", "97140"]
        return viewModel
    }
}
#endif
