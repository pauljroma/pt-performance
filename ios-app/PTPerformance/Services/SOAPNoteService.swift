//
//  SOAPNoteService.swift
//  PTPerformance
//
//  Service for managing SOAP clinical documentation
//

import Foundation
import Supabase
import Combine

// MARK: - SOAP Note Service

/// Service for managing SOAP note clinical documentation
/// Handles CRUD operations, signing workflow, template application, and auto-save
@MainActor
class SOAPNoteService: ObservableObject {

    // MARK: - Singleton

    static let shared = SOAPNoteService()

    // MARK: - Published Properties

    @Published var notes: [SOAPNote] = []
    @Published var currentNote: SOAPNote?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: SOAPNoteServiceError?
    @Published var lastAutoSaveDate: Date?

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared

    // MARK: - Auto-Save Configuration

    private var autoSaveTimer: Timer?
    private var autoSaveInterval: TimeInterval = 30.0 // 30 seconds
    private var pendingDraft: SOAPNote?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupAutoSave()
    }

    deinit {
        autoSaveTimer?.invalidate()
    }

    // MARK: - CRUD Operations

    /// Fetch all SOAP notes for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of SOAP notes sorted by date descending
    func fetchNotes(for patientId: String) async throws -> [SOAPNote] {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedNotes: [SOAPNote] = try await supabase
                .from("soap_notes")
                .select()
                .eq("patient_id", value: patientId)
                .order("note_date", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            self.notes = fetchedNotes
            return fetchedNotes
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.fetchNotes",
                metadata: ["patient_id": patientId]
            )
            self.error = .fetchFailed(error)
            throw SOAPNoteServiceError.fetchFailed(error)
        }
    }

    /// Fetch SOAP notes for a therapist
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of SOAP notes for all the therapist's patients
    func fetchNotesForTherapist(_ therapistId: String) async throws -> [SOAPNote] {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedNotes: [SOAPNote] = try await supabase
                .from("soap_notes")
                .select()
                .eq("therapist_id", value: therapistId)
                .order("note_date", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            self.notes = fetchedNotes
            return fetchedNotes
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.fetchNotesForTherapist",
                metadata: ["therapist_id": therapistId]
            )
            self.error = .fetchFailed(error)
            throw SOAPNoteServiceError.fetchFailed(error)
        }
    }

    /// Fetch a single SOAP note by ID
    /// - Parameter noteId: The note's UUID
    /// - Returns: The SOAP note
    func fetchNote(id noteId: String) async throws -> SOAPNote {
        isLoading = true
        defer { isLoading = false }

        do {
            let note: SOAPNote = try await supabase
                .from("soap_notes")
                .select()
                .eq("id", value: noteId)
                .single()
                .execute()
                .value

            self.currentNote = note
            return note
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.fetchNote",
                metadata: ["note_id": noteId]
            )
            self.error = .fetchFailed(error)
            throw SOAPNoteServiceError.fetchFailed(error)
        }
    }

    /// Fetch draft notes for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of draft SOAP notes
    func fetchDrafts(for patientId: String) async throws -> [SOAPNote] {
        do {
            let drafts: [SOAPNote] = try await supabase
                .from("soap_notes")
                .select()
                .eq("patient_id", value: patientId)
                .eq("status", value: NoteStatus.draft.rawValue)
                .order("updated_at", ascending: false)
                .execute()
                .value

            return drafts
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.fetchDrafts",
                metadata: ["patient_id": patientId]
            )
            throw SOAPNoteServiceError.fetchFailed(error)
        }
    }

    /// Create a new SOAP note
    /// - Parameter input: The note input data
    /// - Returns: The created SOAP note
    func createNote(input: SOAPNoteInput) async throws -> SOAPNote {
        isSaving = true
        defer { isSaving = false }

        do {
            try input.validate()

            let note: SOAPNote = try await supabase
                .from("soap_notes")
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            self.notes.insert(note, at: 0)
            self.currentNote = note

            return note
        } catch let validationError as SOAPNoteError {
            self.error = .validationFailed(validationError.localizedDescription ?? "Validation failed")
            throw validationError
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.createNote",
                metadata: ["patient_id": input.patientId ?? "unknown"]
            )
            self.error = .saveFailed(error)
            throw SOAPNoteServiceError.saveFailed(error)
        }
    }

    /// Update an existing SOAP note
    /// - Parameters:
    ///   - noteId: The note's UUID
    ///   - update: The fields to update
    /// - Returns: The updated SOAP note
    func updateNote(id noteId: String, update: SOAPNoteUpdate) async throws -> SOAPNote {
        isSaving = true
        defer { isSaving = false }

        do {
            // Validate the update
            try update.validate()

            // Check if note is editable
            if let existingNote = notes.first(where: { $0.id.uuidString == noteId }) {
                guard existingNote.status.isEditable else {
                    throw SOAPNoteServiceError.cannotEditSigned
                }
            }

            let updatedNote: SOAPNote = try await supabase
                .from("soap_notes")
                .update(update)
                .eq("id", value: noteId)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            if let index = notes.firstIndex(where: { $0.id.uuidString == noteId }) {
                notes[index] = updatedNote
            }
            if currentNote?.id.uuidString == noteId {
                currentNote = updatedNote
            }

            return updatedNote
        } catch let serviceError as SOAPNoteServiceError {
            self.error = serviceError
            throw serviceError
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.updateNote",
                metadata: ["note_id": noteId]
            )
            self.error = .saveFailed(error)
            throw SOAPNoteServiceError.saveFailed(error)
        }
    }

    /// Delete a SOAP note
    /// - Parameter noteId: The note's UUID
    func deleteNote(id noteId: String) async throws {
        do {
            // Check if note can be deleted (only drafts)
            if let existingNote = notes.first(where: { $0.id.uuidString == noteId }) {
                guard existingNote.status == .draft else {
                    throw SOAPNoteServiceError.cannotDeleteSigned
                }
            }

            try await supabase
                .from("soap_notes")
                .delete()
                .eq("id", value: noteId)
                .execute()

            // Update local cache
            notes.removeAll { $0.id.uuidString == noteId }
            if currentNote?.id.uuidString == noteId {
                currentNote = nil
            }
        } catch let serviceError as SOAPNoteServiceError {
            self.error = serviceError
            throw serviceError
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.deleteNote",
                metadata: ["note_id": noteId]
            )
            self.error = .deleteFailed(error)
            throw SOAPNoteServiceError.deleteFailed(error)
        }
    }

    // MARK: - Signing Workflow

    /// Mark a note as complete (ready for signature)
    /// - Parameter noteId: The note's UUID
    /// - Returns: The updated SOAP note
    func markComplete(id noteId: String) async throws -> SOAPNote {
        do {
            // Verify note has all required sections
            if let existingNote = notes.first(where: { $0.id.uuidString == noteId }) {
                guard existingNote.subjective != nil && !existingNote.subjective!.isEmpty,
                      existingNote.objective != nil && !existingNote.objective!.isEmpty,
                      existingNote.assessment != nil && !existingNote.assessment!.isEmpty,
                      existingNote.plan != nil && !existingNote.plan!.isEmpty else {
                    throw SOAPNoteServiceError.incompleteNote
                }
            }

            let update = SOAPNoteUpdate(status: NoteStatus.complete.rawValue)
            return try await updateNote(id: noteId, update: update)
        } catch let serviceError as SOAPNoteServiceError {
            throw serviceError
        } catch {
            throw SOAPNoteServiceError.saveFailed(error)
        }
    }

    /// Sign a completed note
    /// - Parameters:
    ///   - noteId: The note's UUID
    ///   - signedBy: The name of the signer (therapist name)
    /// - Returns: The signed SOAP note
    func signNote(id noteId: String, signedBy: String) async throws -> SOAPNote {
        isSaving = true
        defer { isSaving = false }

        do {
            // Verify note is complete and ready for signature
            if let existingNote = notes.first(where: { $0.id.uuidString == noteId }) {
                guard existingNote.status == .complete else {
                    throw SOAPNoteServiceError.noteNotReadyForSignature
                }
                guard existingNote.isReadyForSignature else {
                    throw SOAPNoteServiceError.incompleteNote
                }
            }

            let update = SOAPNoteSignatureUpdate(
                status: NoteStatus.signed.rawValue,
                signedAt: Date().iso8601String,
                signedBy: signedBy
            )

            let signedNote: SOAPNote = try await supabase
                .from("soap_notes")
                .update(update)
                .eq("id", value: noteId)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            if let index = notes.firstIndex(where: { $0.id.uuidString == noteId }) {
                notes[index] = signedNote
            }
            if currentNote?.id.uuidString == noteId {
                currentNote = signedNote
            }

            return signedNote
        } catch let serviceError as SOAPNoteServiceError {
            self.error = serviceError
            throw serviceError
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.signNote",
                metadata: ["note_id": noteId, "signed_by": signedBy]
            )
            self.error = .signatureFailed(error)
            throw SOAPNoteServiceError.signatureFailed(error)
        }
    }

    /// Create an addendum to a signed note
    /// - Parameters:
    ///   - parentNoteId: The original signed note's UUID
    ///   - addendumText: The addendum content
    /// - Returns: The new addendum SOAP note
    func createAddendum(
        parentNoteId: String,
        addendumText: String,
        therapistId: String
    ) async throws -> SOAPNote {
        do {
            // Fetch the parent note
            let parentNote = try await fetchNote(id: parentNoteId)

            guard parentNote.status == .signed else {
                throw SOAPNoteServiceError.cannotAddendumUnsigned
            }

            let input = SOAPNoteInput(
                patientId: parentNote.patientId.uuidString,
                therapistId: therapistId,
                sessionId: parentNote.sessionId?.uuidString,
                noteDate: Date().iso8601String,
                subjective: addendumText,
                status: NoteStatus.addendum.rawValue,
                parentNoteId: parentNoteId
            )

            return try await createNote(input: input)
        } catch let serviceError as SOAPNoteServiceError {
            throw serviceError
        } catch {
            throw SOAPNoteServiceError.saveFailed(error)
        }
    }

    // MARK: - Template Application

    /// Apply a template to a SOAP note
    /// - Parameters:
    ///   - template: The template to apply
    ///   - noteId: The note's UUID (if updating existing note)
    ///   - patientId: The patient's UUID (if creating new note)
    ///   - therapistId: The therapist's UUID
    /// - Returns: The SOAP note with template applied
    func applyTemplate(
        _ template: SOAPNoteTemplate,
        toNoteId noteId: String? = nil,
        patientId: String? = nil,
        therapistId: String
    ) async throws -> SOAPNote {
        if let noteId = noteId {
            // Update existing note with template content
            let update = SOAPNoteUpdate(
                subjective: template.subjective,
                objective: template.objective,
                assessment: template.assessment,
                plan: template.plan,
                cptCodes: template.defaultCptCodes
            )
            return try await updateNote(id: noteId, update: update)
        } else {
            // Create new note with template content
            guard let patientId = patientId else {
                throw SOAPNoteServiceError.missingPatientId
            }

            let input = SOAPNoteInput(
                patientId: patientId,
                therapistId: therapistId,
                noteDate: Date().iso8601String,
                subjective: template.subjective,
                objective: template.objective,
                assessment: template.assessment,
                plan: template.plan,
                cptCodes: template.defaultCptCodes,
                status: NoteStatus.draft.rawValue
            )
            return try await createNote(input: input)
        }
    }

    /// Fetch available SOAP note templates
    /// - Parameter category: Optional category filter
    /// - Returns: Array of templates
    func fetchTemplates(category: String? = nil) async throws -> [SOAPNoteTemplate] {
        do {
            var query = supabase
                .from("soap_note_templates")
                .select()
                .eq("is_active", value: true)

            if let category = category {
                query = query.eq("category", value: category)
            }

            let templates: [SOAPNoteTemplate] = try await query
                .order("name", ascending: true)
                .execute()
                .value

            return templates
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.fetchTemplates"
            )
            throw SOAPNoteServiceError.fetchFailed(error)
        }
    }

    // MARK: - Auto-Save Drafts

    /// Set up auto-save timer for draft notes
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.autoSavePendingDraft()
            }
        }
    }

    /// Queue a note for auto-save
    /// - Parameter note: The draft note to save
    func queueForAutoSave(_ note: SOAPNote) {
        guard note.status == .draft else { return }
        pendingDraft = note
    }

    /// Perform auto-save of pending draft
    private func autoSavePendingDraft() async {
        guard let draft = pendingDraft else { return }

        do {
            let update = SOAPNoteUpdate(
                subjective: draft.subjective,
                objective: draft.objective,
                assessment: draft.assessment,
                plan: draft.plan,
                vitals: draft.vitals,
                painLevel: draft.painLevel,
                functionalStatus: draft.functionalStatus?.rawValue,
                timeSpentMinutes: draft.timeSpentMinutes,
                cptCodes: draft.cptCodes
            )

            _ = try await supabase
                .from("soap_notes")
                .update(update)
                .eq("id", value: draft.id.uuidString)
                .execute()

            lastAutoSaveDate = Date()
            pendingDraft = nil

            #if DEBUG
            print("[SOAPNoteService] Auto-saved draft: \(draft.id)")
            #endif
        } catch {
            errorLogger.logError(
                error,
                context: "SOAPNoteService.autoSavePendingDraft",
                metadata: ["note_id": draft.id.uuidString]
            )
        }
    }

    /// Force save any pending draft immediately
    func forceSaveDraft() async {
        await autoSavePendingDraft()
    }

    /// Configure auto-save interval
    /// - Parameter interval: Time interval in seconds
    func setAutoSaveInterval(_ interval: TimeInterval) {
        autoSaveInterval = interval
        autoSaveTimer?.invalidate()
        setupAutoSave()
    }

    // MARK: - Helper Methods

    /// Get notes by status
    /// - Parameter status: The note status to filter by
    /// - Returns: Filtered array of notes
    func notes(byStatus status: NoteStatus) -> [SOAPNote] {
        return notes.filter { $0.status == status }
    }

    /// Get notes for a specific session
    /// - Parameter sessionId: The session's UUID
    /// - Returns: Filtered array of notes
    func notes(forSession sessionId: String) -> [SOAPNote] {
        return notes.filter { $0.sessionId?.uuidString == sessionId }
    }

    /// Clear the current error
    func clearError() {
        error = nil
    }

    /// Refresh notes from server
    /// - Parameter patientId: The patient's UUID
    func refresh(for patientId: String) async {
        do {
            _ = try await fetchNotes(for: patientId)
        } catch {
            // Error already logged and stored
        }
    }
}

// MARK: - Supporting Types

/// Update model for SOAP notes
struct SOAPNoteUpdate: Encodable {
    var subjective: String?
    var objective: String?
    var assessment: String?
    var plan: String?
    var vitals: Vitals?
    var painLevel: Int?
    var functionalStatus: String?
    var timeSpentMinutes: Int?
    var cptCodes: [String]?
    var status: String?

    enum CodingKeys: String, CodingKey {
        case subjective
        case objective
        case assessment
        case plan
        case vitals
        case painLevel = "pain_level"
        case functionalStatus = "functional_status"
        case timeSpentMinutes = "time_spent_minutes"
        case cptCodes = "cpt_codes"
        case status
    }

    init(
        subjective: String? = nil,
        objective: String? = nil,
        assessment: String? = nil,
        plan: String? = nil,
        vitals: Vitals? = nil,
        painLevel: Int? = nil,
        functionalStatus: String? = nil,
        timeSpentMinutes: Int? = nil,
        cptCodes: [String]? = nil,
        status: String? = nil
    ) {
        self.subjective = subjective
        self.objective = objective
        self.assessment = assessment
        self.plan = plan
        self.vitals = vitals
        self.painLevel = painLevel
        self.functionalStatus = functionalStatus
        self.timeSpentMinutes = timeSpentMinutes
        self.cptCodes = cptCodes
        self.status = status
    }

    /// Validate update fields
    func validate() throws {
        if let pain = painLevel, !(0...10).contains(pain) {
            throw SOAPNoteError.invalidPainLevel("Pain level must be 0-10")
        }
        if let minutes = timeSpentMinutes, minutes < 0 {
            throw SOAPNoteError.invalidTimeSpent("Time spent cannot be negative")
        }
    }
}

/// Signature update model
private struct SOAPNoteSignatureUpdate: Encodable {
    let status: String
    let signedAt: String
    let signedBy: String

    enum CodingKeys: String, CodingKey {
        case status
        case signedAt = "signed_at"
        case signedBy = "signed_by"
    }
}

/// SOAP Note Template model
struct SOAPNoteTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let subjective: String?
    let objective: String?
    let assessment: String?
    let plan: String?
    let defaultCptCodes: [String]?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case subjective
        case objective
        case assessment
        case plan
        case defaultCptCodes = "default_cpt_codes"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Service-specific errors
enum SOAPNoteServiceError: LocalizedError {
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case signatureFailed(Error)
    case validationFailed(String)
    case cannotEditSigned
    case cannotDeleteSigned
    case cannotAddendumUnsigned
    case noteNotReadyForSignature
    case incompleteNote
    case missingPatientId
    case noteNotFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch SOAP notes"
        case .saveFailed:
            return "Failed to save SOAP note"
        case .deleteFailed:
            return "Failed to delete SOAP note"
        case .signatureFailed:
            return "Failed to sign SOAP note"
        case .validationFailed(let message):
            return message
        case .cannotEditSigned:
            return "Cannot edit a signed note. Create an addendum instead."
        case .cannotDeleteSigned:
            return "Cannot delete a signed note"
        case .cannotAddendumUnsigned:
            return "Can only create addendums for signed notes"
        case .noteNotReadyForSignature:
            return "Note must be marked complete before signing"
        case .incompleteNote:
            return "Please complete all SOAP sections (Subjective, Objective, Assessment, Plan) before proceeding"
        case .missingPatientId:
            return "Patient ID is required"
        case .noteNotFound:
            return "SOAP note not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .saveFailed:
            return "Your note couldn't be saved. Please try again."
        case .deleteFailed:
            return "The note couldn't be deleted. Please try again."
        case .signatureFailed:
            return "The signature couldn't be applied. Please try again."
        case .validationFailed:
            return "Please correct the validation errors and try again."
        case .cannotEditSigned:
            return "Create an addendum to add information to this note."
        case .cannotDeleteSigned:
            return "Signed notes are part of the permanent medical record."
        case .cannotAddendumUnsigned:
            return "Complete and sign the original note first."
        case .noteNotReadyForSignature:
            return "Mark the note as complete before signing."
        case .incompleteNote:
            return "Fill in all required SOAP sections."
        case .missingPatientId:
            return "Please select a patient."
        case .noteNotFound:
            return "The note may have been deleted. Please refresh."
        }
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

// MARK: - Sample Data

#if DEBUG
extension SOAPNoteTemplate {
    static let sampleInitialEval = SOAPNoteTemplate(
        id: UUID(),
        name: "Initial Evaluation",
        description: "Template for initial patient evaluations",
        category: "evaluation",
        subjective: "Patient presents with chief complaint of [COMPLAINT]. Onset: [ONSET]. Mechanism of injury: [MOI]. Current pain level: [PAIN]/10. Aggravating factors: [AGGRAVATING]. Alleviating factors: [ALLEVIATING]. Prior treatment: [PRIOR TX].",
        objective: "Observation: [OBS]\nPalpation: [PALP]\nROM: [ROM]\nStrength: [STRENGTH]\nSpecial Tests: [SPECIAL TESTS]\nFunctional Assessment: [FUNCTIONAL]",
        assessment: "Patient presents with [DIAGNOSIS/IMPRESSION]. Prognosis: [PROGNOSIS]. Patient is appropriate for skilled physical therapy intervention.",
        plan: "Plan of Care:\n- Frequency: [FREQ]\n- Duration: [DURATION]\n- Goals: [GOALS]\n- Treatment interventions: [INTERVENTIONS]",
        defaultCptCodes: ["97163"],
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let sampleFollowUp = SOAPNoteTemplate(
        id: UUID(),
        name: "Follow-Up Visit",
        description: "Template for regular follow-up visits",
        category: "follow_up",
        subjective: "Patient reports [PROGRESS] since last visit. Current pain: [PAIN]/10 (previous: [PREV PAIN]/10). Sleep: [SLEEP]. ADL status: [ADL].",
        objective: "ROM: [ROM]\nStrength: [STRENGTH]\nFunctional mobility: [FUNCTIONAL]\nExercise performance: [EXERCISE PERFORMANCE]",
        assessment: "Patient is [IMPROVING/STABLE/DECLINING]. [ASSESSMENT DETAILS]. Continue current POC.",
        plan: "Continue [INTERVENTIONS]. Progress [PROGRESSIONS]. Next visit: [NEXT VISIT].",
        defaultCptCodes: ["97110", "97140"],
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
