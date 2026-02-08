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

    // MARK: - Safe Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        flagType = container.safeString(forKey: .flagType, default: "unknown")
        severity = container.safeString(forKey: .severity, default: "LOW")
        description = container.safeString(forKey: .description, default: "")
        createdAt = container.safeDate(forKey: .createdAt, default: Date())
        resolvedAt = container.safeOptionalDate(forKey: .resolvedAt)
        autoCreated = container.safeBool(forKey: .autoCreated, default: false)
    }
}
