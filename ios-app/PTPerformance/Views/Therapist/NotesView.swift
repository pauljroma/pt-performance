import SwiftUI

/// Notes view for therapists to add and view patient notes
struct NotesView: View {
    let patientId: String

    @StateObject private var viewModel = NotesViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading notes...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.fetchNotes(for: patientId)
                    }
                }
            } else {
                notesContent
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showAddNoteSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddNoteSheet) {
            AddNoteSheet(patientId: patientId) { newNote in
                await viewModel.saveNote(newNote)
            }
        }
        .task {
            await viewModel.fetchNotes(for: patientId)
        }
    }

    private var notesContent: some View {
        Group {
            if viewModel.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Tap + to add your first note")
                )
            } else {
                List {
                    ForEach(viewModel.notes) { note in
                        NoteCard(note: note)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteNote(note.id, for: patientId)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Notes ViewModel

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [SessionNote] = []
    @Published var showAddNoteSheet = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = NotesService()

    func fetchNotes(for patientId: String) async {
        let logger = DebugLogger.shared
        logger.log("📝 Fetching notes for patient: \(patientId)")
        isLoading = true
        errorMessage = nil

        do {
            notes = try await service.fetchNotes(for: patientId)
            logger.log("✅ Fetched \(notes.count) notes successfully", level: .success)
            isLoading = false
        } catch {
            logger.log("❌ Failed to fetch notes: \(error.localizedDescription)", level: .error)
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func saveNote(_ note: CreateNoteInput) async {
        let logger = DebugLogger.shared
        logger.log("📝 Saving note for patient: \(note.patientId)")
        logger.log("📝 Note type: \(note.noteType), session: \(note.sessionId ?? "nil")")

        do {
            let newNote = try await service.saveNote(
                patientId: note.patientId,
                sessionId: note.sessionId,
                noteType: note.noteType,
                noteText: note.noteText,
                createdBy: note.createdBy
            )

            logger.log("✅ Note saved successfully with ID: \(newNote.id)", level: .success)
            logger.log("📝 Current notes count BEFORE insert: \(notes.count)")
            notes.insert(newNote, at: 0)
            logger.log("📝 Current notes count AFTER insert: \(notes.count)")
            logger.log("📝 Closing add note sheet...")
            showAddNoteSheet = false
            logger.log("✅ Note added to list and sheet closed", level: .success)
        } catch {
            logger.log("❌ Failed to save note: \(error.localizedDescription)", level: .error)
            errorMessage = error.localizedDescription
        }
    }

    func deleteNote(_ noteId: String, for patientId: String) async {
        do {
            try await service.deleteNote(id: noteId)
            notes.removeAll { $0.id == noteId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: SessionNote

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: note.typeIcon)
                    .foregroundColor(typeColor)

                Text(note.noteType.capitalized)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(typeColor)

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Note text
            Text(note.noteText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // Footer
            HStack {
                Label(note.createdBy ?? "Unknown", systemImage: "person.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let sessionId = note.sessionId {
                    Label("Session", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private var typeColor: Color {
        switch note.noteType {
        case "assessment": return .blue
        case "progress": return .green
        case "clinical": return .red
        default: return .gray
        }
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    let patientId: String
    let onSave: (CreateNoteInput) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteType: String = "general"
    @State private var noteText: String = ""
    @State private var sessionId: String? = nil
    @State private var isSaving = false

    // Get therapist ID from auth session
    @State private var therapistId: String? = nil

    let noteTypes = ["assessment", "progress", "clinical", "general"]

    var body: some View {
        NavigationView {
            Form {
                // Note type
                Section("Note Type") {
                    Picker("Type", selection: $noteType) {
                        ForEach(noteTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: iconForType(type))
                                Text(type.capitalized)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Note text
                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 150)
                }

                // Session link (optional)
                Section("Link to Session (Optional)") {
                    TextField("Session ID", text: Binding(
                        get: { sessionId ?? "" },
                        set: { sessionId = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteText.isEmpty || isSaving)
                }
            }
            .task {
                // Fetch therapist ID on appear
                await fetchTherapistId()
            }
        }
    }

    private func fetchTherapistId() async {
        do {
            // Get current user ID from auth
            let userId = try await PTSupabaseClient.shared.client.auth.session.user.id.uuidString

            // Query therapists table to get therapist ID
            let response = try await PTSupabaseClient.shared.client
                .from("therapists")
                .select("id")
                .eq("user_id", value: userId)
                .single()
                .execute()

            struct TherapistIdResponse: Codable {
                let id: String
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(TherapistIdResponse.self, from: response.data)
            therapistId = result.id
        } catch {
            // Fallback - nil means database will use default function
            therapistId = nil
        }
    }

    private func saveNote() {
        isSaving = true

        let input = CreateNoteInput(
            patientId: patientId,
            sessionId: sessionId,
            noteType: noteType,
            noteText: noteText,
            createdBy: therapistId  // May be nil - database will use default function
        )

        Task {
            await onSave(input)
            dismiss()
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "assessment": return "stethoscope"
        case "progress": return "chart.line.uptrend.xyaxis"
        case "clinical": return "cross.case.fill"
        default: return "note.text"
        }
    }
}

// Extension to get current user ID
extension PTSupabaseClient {
    func getCurrentUserId() -> String? {
        // This would normally come from the auth session
        // For now, return a placeholder
        return "therapist-user-id"
    }
}

// MARK: - Preview

#if DEBUG
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotesView(patientId: "patient-1")
        }
    }
}
#endif
