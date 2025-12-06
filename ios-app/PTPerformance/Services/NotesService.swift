import Foundation
import Supabase

/// Service for managing session notes
class NotesService {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch notes for a patient
    func fetchNotes(for patientId: String) async throws -> [SessionNote] {
        let response = try await supabase.client
            .from("session_notes")
            .select()
            .eq("patient_id", value: patientId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([SessionNote].self, from: response.data)
    }

    /// Create a new note
    func saveNote(
        patientId: String,
        sessionId: String?,
        noteType: String,
        noteText: String,
        createdBy: String
    ) async throws -> SessionNote {
        let input = CreateNoteInput(
            patientId: patientId,
            sessionId: sessionId,
            noteType: noteType,
            noteText: noteText,
            createdBy: createdBy
        )

        let response = try await supabase.client
            .from("session_notes")
            .insert(input)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(SessionNote.self, from: response.data)
    }

    /// Delete a note
    func deleteNote(id: String) async throws {
        try await supabase.client
            .from("session_notes")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
