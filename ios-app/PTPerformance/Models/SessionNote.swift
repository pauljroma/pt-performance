import Foundation

/// Session note model
struct SessionNote: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let sessionId: UUID?
    let noteType: String
    let noteText: String
    let createdBy: String?  // Optional - some old notes have null created_by
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case noteType = "note_type"
        case noteText = "note_text"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    // MARK: - Safe Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        sessionId = container.safeOptionalUUID(forKey: .sessionId)
        noteType = container.safeString(forKey: .noteType, default: "general")
        noteText = container.safeString(forKey: .noteText, default: "")
        createdBy = container.safeOptionalString(forKey: .createdBy)
        createdAt = container.safeDate(forKey: .createdAt, default: Date())
    }

    var typeIcon: String {
        switch noteType {
        case "assessment": return "stethoscope"
        case "progress": return "chart.line.uptrend.xyaxis"
        case "clinical": return "cross.case.fill"
        case "general": return "note.text"
        default: return "note.text"
        }
    }

    var typeColor: String {
        switch noteType {
        case "assessment": return "blue"
        case "progress": return "green"
        case "clinical": return "red"
        case "general": return "gray"
        default: return "gray"
        }
    }
}

/// Input for creating a new note
struct CreateNoteInput: Codable {
    let patientId: UUID
    let sessionId: UUID?
    let noteType: String
    let noteText: String
    let createdBy: String?  // Optional - database will use default if not provided

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionId = "session_id"
        case noteType = "note_type"
        case noteText = "note_text"
        case createdBy = "created_by"
    }
}
