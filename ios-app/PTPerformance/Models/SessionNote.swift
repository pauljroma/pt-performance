import Foundation

/// Session note model
struct SessionNote: Codable, Identifiable {
    let id: String
    let patientId: String
    let sessionId: String?
    let noteType: String
    let noteText: String
    let createdBy: String
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
    let patientId: String
    let sessionId: String?
    let noteType: String
    let noteText: String
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionId = "session_id"
        case noteType = "note_type"
        case noteText = "note_text"
        case createdBy = "created_by"
    }
}
