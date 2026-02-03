import Foundation

/// Patient flag model
struct PatientFlag: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let patientId: UUID
    let flagType: String
    let severity: String
    let description: String
    let createdAt: Date
    let resolvedAt: Date?
    let autoCreated: Bool

    var isResolved: Bool {
        resolvedAt != nil
    }

    var severityColor: String {
        switch severity {
        case "HIGH": return "red"
        case "MEDIUM": return "orange"
        case "LOW": return "yellow"
        default: return "gray"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case flagType = "flag_type"
        case severity
        case description
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
        case autoCreated = "auto_created"
    }
}
