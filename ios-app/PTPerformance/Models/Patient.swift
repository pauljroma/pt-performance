import Foundation

/// Patient model
struct Patient: Codable, Identifiable, Hashable {
    let id: UUID
    let therapistId: UUID
    let firstName: String
    let lastName: String
    let email: String
    let sport: String?
    let position: String?
    let injuryType: String?
    let targetLevel: String?
    let profileImageUrl: String?
    let createdAt: Date
    let flagCount: Int?
    let highSeverityFlagCount: Int?
    let adherencePercentage: Double?
    let lastSessionDate: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var hasHighSeverityFlags: Bool {
        (highSeverityFlagCount ?? 0) > 0
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Patient, rhs: Patient) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID,
        therapistId: UUID,
        firstName: String,
        lastName: String,
        email: String,
        sport: String? = nil,
        position: String? = nil,
        injuryType: String? = nil,
        targetLevel: String? = nil,
        profileImageUrl: String? = nil,
        createdAt: Date = Date(),
        flagCount: Int? = nil,
        highSeverityFlagCount: Int? = nil,
        adherencePercentage: Double? = nil,
        lastSessionDate: Date? = nil
    ) {
        self.id = id
        self.therapistId = therapistId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.sport = sport
        self.position = position
        self.injuryType = injuryType
        self.targetLevel = targetLevel
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.flagCount = flagCount
        self.highSeverityFlagCount = highSeverityFlagCount
        self.adherencePercentage = adherencePercentage
        self.lastSessionDate = lastSessionDate
    }

    // MARK: - Defensive Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        therapistId = container.safeUUID(forKey: .therapistId)

        // Required strings with fallback
        firstName = container.safeString(forKey: .firstName, default: "Unknown")
        lastName = container.safeString(forKey: .lastName, default: "Patient")
        email = container.safeString(forKey: .email, default: "")

        // Optional strings
        sport = container.safeOptionalString(forKey: .sport)
        position = container.safeOptionalString(forKey: .position)
        injuryType = container.safeOptionalString(forKey: .injuryType)
        targetLevel = container.safeOptionalString(forKey: .targetLevel)
        profileImageUrl = container.safeOptionalString(forKey: .profileImageUrl)

        // Date with fallback
        createdAt = container.safeDate(forKey: .createdAt)

        // Optional ints (handles PostgreSQL numeric as string)
        flagCount = container.safeOptionalInt(forKey: .flagCount)
        highSeverityFlagCount = container.safeOptionalInt(forKey: .highSeverityFlagCount)

        // Optional double (handles PostgreSQL numeric as string)
        adherencePercentage = container.safeOptionalDouble(forKey: .adherencePercentage)

        // Optional date
        lastSessionDate = container.safeOptionalDate(forKey: .lastSessionDate)
    }

    static let samplePatients: [Patient] = [
        Patient(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            firstName: "John",
            lastName: "Brebbia",
            email: "demo-patient@ptperformance.app",
            sport: "Baseball",
            position: "Pitcher",
            injuryType: "Tommy John Recovery",
            targetLevel: "MLB",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 0,
            highSeverityFlagCount: 0,
            adherencePercentage: 92.5,
            lastSessionDate: Date()
        ),
        Patient(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            sport: "Basketball",
            position: "Guard",
            injuryType: "ACL Recovery",
            targetLevel: "College",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 1,
            highSeverityFlagCount: 0,
            adherencePercentage: 87.0,
            lastSessionDate: Date()
        )
    ]

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
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case flagCount = "flag_count"
        case highSeverityFlagCount = "high_severity_flag_count"
        case adherencePercentage = "adherence_percentage"
        case lastSessionDate = "last_session_date"
    }
}

/// Extended patient data with analytics
struct PatientWithStats: Codable, Identifiable, Hashable, Equatable {
    let patient: Patient
    let recentPainAvg: Double?
    let completedSessions: Int
    let totalSessions: Int

    var id: UUID { patient.id }
}

// MARK: - Mock Data Extension

extension Patient {
    /// Mock patients for development and preview purposes
    static var mockPatients: [Patient] {
        [
            Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "John",
                lastName: "Smith",
                email: "john.smith@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Rotator Cuff Strain",
                targetLevel: "College",
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 88.5
            ),
            Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah.johnson@example.com",
                sport: "Basketball",
                position: "Guard",
                injuryType: "ACL Recovery",
                targetLevel: "Professional",
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 92.0
            ),
            Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "Mike",
                lastName: "Williams",
                email: "mike.williams@example.com",
                sport: "Football",
                position: "Quarterback",
                injuryType: "Shoulder Impingement",
                targetLevel: "High School",
                createdAt: Date(),
                flagCount: 1,
                highSeverityFlagCount: 0,
                adherencePercentage: 75.0
            ),
            Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "Emily",
                lastName: "Davis",
                email: "emily.davis@example.com",
                sport: "Soccer",
                position: "Forward",
                injuryType: "Hamstring Strain",
                targetLevel: "College",
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 95.0
            ),
            Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "Chris",
                lastName: "Brown",
                email: "chris.brown@example.com",
                sport: "Tennis",
                position: nil,
                injuryType: "Tennis Elbow",
                targetLevel: "Recreational",
                createdAt: Date(),
                flagCount: 3,
                highSeverityFlagCount: 2,
                adherencePercentage: 65.0
            )
        ]
    }
}
