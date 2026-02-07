//
//  SOAPNoteEditorView.swift
//  PTPerformance
//
//  Clinical SOAP note editing interface for therapists
//

import SwiftUI

/// SOAP note editor view for creating and editing clinical documentation
struct SOAPNoteEditorView: View {
    let patientId: String
    let sessionId: UUID?

    @StateObject private var viewModel = SOAPNoteEditorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showTemplatePickerSheet = false
    @State private var showSignConfirmation = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading note...")
            } else {
                noteEditorContent
            }

            // Auto-save indicator
            if viewModel.isSaving {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        autoSaveIndicator
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("SOAP Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showTemplatePickerSheet = true
                    } label: {
                        Label("Use Template", systemImage: "doc.text")
                    }

                    Button {
                        Task {
                            await viewModel.saveDraft()
                        }
                    } label: {
                        Label("Save Draft", systemImage: "square.and.arrow.down")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.clearAll()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showTemplatePickerSheet) {
            TemplatePickerView(templateType: .soapNote) { template in
                viewModel.applyTemplate(template)
            }
        }
        .alert("Sign Note", isPresented: $showSignConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign & Lock") {
                Task {
                    await viewModel.signNote()
                    dismiss()
                }
            }
        } message: {
            Text("Signing this note will lock it for editing. This action cannot be undone.")
        }
        .task {
            await viewModel.loadNote(patientId: patientId, sessionId: sessionId)
        }
        .onChange(of: viewModel.subjective) { _, _ in viewModel.scheduleAutoSave() }
        .onChange(of: viewModel.objective) { _, _ in viewModel.scheduleAutoSave() }
        .onChange(of: viewModel.assessment) { _, _ in viewModel.scheduleAutoSave() }
        .onChange(of: viewModel.plan) { _, _ in viewModel.scheduleAutoSave() }
    }

    // MARK: - Note Editor Content

    private var noteEditorContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Patient/Session Header
                noteHeader

                // SOAP Sections
                soapSections

                // Sign Button
                signButton
            }
            .padding()
        }
    }

    // MARK: - Note Header

    private var noteHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let patientName = viewModel.patientName {
                        Text(patientName)
                            .font(.headline)
                    }

                    Text("Date: \(viewModel.noteDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            if viewModel.isDraft {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                    Text("Draft - Last saved \(viewModel.lastSavedAt?.formatted(date: .omitted, time: .shortened) ?? "never")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var statusBadge: some View {
        Group {
            if viewModel.isSigned {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Signed")
                }
                .font(.caption)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .cornerRadius(6)
            } else if viewModel.isDraft {
                HStack(spacing: 4) {
                    Image(systemName: "doc.badge.ellipsis")
                    Text("Draft")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - SOAP Sections

    private var soapSections: some View {
        VStack(spacing: 16) {
            // Subjective
            SOAPSectionEditor(
                title: "Subjective",
                icon: "person.wave.2",
                iconColor: .blue,
                placeholder: "Patient's reported symptoms, concerns, and history...",
                text: $viewModel.subjective,
                isLocked: viewModel.isSigned
            )

            // Objective
            SOAPSectionEditor(
                title: "Objective",
                icon: "ruler",
                iconColor: .green,
                placeholder: "Measurable findings, vital signs, ROM, strength testing...",
                text: $viewModel.objective,
                isLocked: viewModel.isSigned
            )

            // Assessment
            SOAPSectionEditor(
                title: "Assessment",
                icon: "stethoscope",
                iconColor: .purple,
                placeholder: "Clinical impression, diagnosis, progress evaluation...",
                text: $viewModel.assessment,
                isLocked: viewModel.isSigned
            )

            // Plan
            SOAPSectionEditor(
                title: "Plan",
                icon: "list.clipboard",
                iconColor: .orange,
                placeholder: "Treatment plan, goals, next steps, patient education...",
                text: $viewModel.plan,
                isLocked: viewModel.isSigned
            )
        }
    }

    // MARK: - Sign Button

    private var signButton: some View {
        Group {
            if !viewModel.isSigned {
                Button {
                    showSignConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Sign Note")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canSign ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canSign)

                if !viewModel.canSign {
                    Text("Complete all sections to sign")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Signed by \(viewModel.signedBy ?? "Unknown")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let signedAt = viewModel.signedAt {
                            Text(signedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Auto-Save Indicator

    private var autoSaveIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Saving...")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

// MARK: - SOAP Section Editor

struct SOAPSectionEditor: View {
    let title: String
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String
    let isLocked: Bool

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .frame(width: 24)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if !text.isEmpty {
                        Text("\(text.count) chars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            // Editor
            if isExpanded {
                if isLocked {
                    Text(text.isEmpty ? "No content" : text)
                        .font(.body)
                        .foregroundColor(text.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                } else {
                    TextEditor(text: $text)
                        .font(.body)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if text.isEmpty {
                                    Text(placeholder)
                                        .font(.body)
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - SOAP Note Editor ViewModel (Local)

@MainActor
class SOAPNoteEditorViewModel: ObservableObject {
    @Published var subjective: String = ""
    @Published var objective: String = ""
    @Published var assessment: String = ""
    @Published var plan: String = ""

    @Published var patientName: String?
    @Published var noteDate: Date = Date()
    @Published var isDraft: Bool = true
    @Published var isSigned: Bool = false
    @Published var signedBy: String?
    @Published var signedAt: Date?
    @Published var lastSavedAt: Date?

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private var noteId: UUID?
    private var patientId: String?
    private var sessionId: UUID?
    private var autoSaveTask: Task<Void, Never>?

    var canSign: Bool {
        !subjective.isEmpty && !objective.isEmpty && !assessment.isEmpty && !plan.isEmpty
    }

    func loadNote(patientId: String, sessionId: UUID?) async {
        self.patientId = patientId
        self.sessionId = sessionId
        isLoading = true

        do {
            // Fetch patient info
            let patient: Patient = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("*")
                .eq("id", value: patientId)
                .single()
                .execute()
                .value

            patientName = patient.fullName

            // Check for existing draft
            if let existingNote = try await fetchExistingNote(patientId: patientId, sessionId: sessionId) {
                noteId = existingNote.id
                subjective = existingNote.subjective ?? ""
                objective = existingNote.objective ?? ""
                assessment = existingNote.assessment ?? ""
                plan = existingNote.plan ?? ""
                isDraft = existingNote.status == "draft"
                isSigned = existingNote.status == "signed"
                signedBy = existingNote.signedBy
                signedAt = existingNote.signedAt
                lastSavedAt = existingNote.updatedAt
                noteDate = existingNote.noteDate ?? Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchExistingNote(patientId: String, sessionId: UUID?) async throws -> LocalSOAPNote? {
        var query = PTSupabaseClient.shared.client
            .from("soap_notes")
            .select("*")
            .eq("patient_id", value: patientId)

        if let sessionId = sessionId {
            query = query.eq("session_id", value: sessionId.uuidString)
        }

        let notes: [LocalSOAPNote] = try await query
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return notes.first
    }

    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await saveDraft()
            }
        }
    }

    func saveDraft() async {
        guard let patientId = patientId else { return }
        isSaving = true

        do {
            let noteData = LocalSOAPNoteInput(
                patientId: patientId,
                sessionId: sessionId?.uuidString,
                subjective: subjective,
                objective: objective,
                assessment: assessment,
                plan: plan,
                status: "draft",
                noteDate: noteDate
            )

            if let existingId = noteId {
                // Update existing
                try await PTSupabaseClient.shared.client
                    .from("soap_notes")
                    .update(noteData)
                    .eq("id", value: existingId.uuidString)
                    .execute()
            } else {
                // Create new
                let response: LocalSOAPNote = try await PTSupabaseClient.shared.client
                    .from("soap_notes")
                    .insert(noteData)
                    .select()
                    .single()
                    .execute()
                    .value

                noteId = response.id
            }

            lastSavedAt = Date()
            isDraft = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func signNote() async {
        if noteId == nil {
            await saveDraft()
        }
        guard let currentNoteId = noteId else { return }

        isSaving = true

        do {
            let signData = SignNoteUpdate(
                status: "signed",
                signedAt: ISO8601DateFormatter().string(from: Date()),
                signedBy: PTSupabaseClient.shared.userId ?? "unknown"
            )

            try await PTSupabaseClient.shared.client
                .from("soap_notes")
                .update(signData)
                .eq("id", value: currentNoteId.uuidString)
                .execute()

            isSigned = true
            isDraft = false
            signedAt = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func applyTemplate(_ template: DocumentationTemplate) {
        subjective = template.subjectiveTemplate ?? subjective
        objective = template.objectiveTemplate ?? objective
        assessment = template.assessmentTemplate ?? assessment
        plan = template.planTemplate ?? plan
    }

    func clearAll() {
        subjective = ""
        objective = ""
        assessment = ""
        plan = ""
    }
}

// MARK: - Local Supporting Models

private struct LocalSOAPNote: Codable, Identifiable {
    let id: UUID
    let patientId: String
    let sessionId: String?
    let subjective: String?
    let objective: String?
    let assessment: String?
    let plan: String?
    let status: String
    let noteDate: Date?
    let signedBy: String?
    let signedAt: Date?
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case subjective, objective, assessment, plan, status
        case noteDate = "note_date"
        case signedBy = "signed_by"
        case signedAt = "signed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct SignNoteUpdate: Codable {
    let status: String
    let signedAt: String
    let signedBy: String

    enum CodingKeys: String, CodingKey {
        case status
        case signedAt = "signed_at"
        case signedBy = "signed_by"
    }
}

private struct LocalSOAPNoteInput: Codable {
    let patientId: String
    let sessionId: String?
    let subjective: String
    let objective: String
    let assessment: String
    let plan: String
    let status: String
    let noteDate: Date

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionId = "session_id"
        case subjective, objective, assessment, plan, status
        case noteDate = "note_date"
    }
}

struct DocumentationTemplate: Identifiable {
    let id: UUID
    let name: String
    let subjectiveTemplate: String?
    let objectiveTemplate: String?
    let assessmentTemplate: String?
    let planTemplate: String?
}

// MARK: - Preview

#if DEBUG
struct SOAPNoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SOAPNoteEditorView(patientId: "patient-1", sessionId: nil)
        }
        .preferredColorScheme(.light)

        NavigationView {
            SOAPNoteEditorView(patientId: "patient-1", sessionId: nil)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
