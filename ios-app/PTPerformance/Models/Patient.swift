import Foundation

/// Patient model
struct Patient: Codable, Identifiable {
    let id: String
    let therapistId: String
    let firstName: String
    let lastName: String
    let email: String
    let sport: String?
    let position: String?
    let injuryType: String?
    let targetLevel: String?
    let createdAt: Date
    let flagCount: Int?
    let highSeverityFlagCount: Int?
    let adherencePercentage: Double?
    let lastSessionDate: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var hasHighSeverityFlags: Bool {
        (highSeverityFlagCount ?? 0) > 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case sport
        case position
        case injuryType = "injury_type"
        case targetLevel = "target_level"
        case createdAt = "created_at"
        case flagCount = "flag_count"
        case highSeverityFlagCount = "high_severity_flag_count"
        case adherencePercentage = "adherence_percentage"
        case lastSessionDate = "last_session_date"
    }
}

/// Extended patient data with analytics
struct PatientWithStats: Codable, Identifiable {
    let patient: Patient
    let recentPainAvg: Double?
    let completedSessions: Int
    let totalSessions: Int

    var id: String { patient.id }
}
