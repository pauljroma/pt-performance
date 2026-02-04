import Foundation

/// Recovery session tracking (sauna, cold plunge, etc.)
struct RecoverySession: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let protocolType: RecoveryProtocolType
    let loggedAt: Date
    let durationMinutes: Int
    let temperature: Double? // Fahrenheit for sauna, Celsius for cold
    let heartRateAvg: Int?
    let heartRateMax: Int?
    let perceivedEffort: Int? // 1-10 RPE
    let rating: Int? // 1-5 scale
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case protocolType = "session_type"  // Database uses session_type, not protocol_type
        case loggedAt = "logged_at"
        case durationMinutes = "duration_minutes"
        case temperature = "temperature_f"  // Database uses temperature_f
        case heartRateAvg = "heart_rate_avg"
        case heartRateMax = "heart_rate_max"
        case perceivedEffort = "perceived_effort"
        case rating
        case notes
        case createdAt = "created_at"
    }

    /// Custom encoder to exclude fields not in database schema
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(patientId, forKey: .patientId)
        try container.encode(protocolType, forKey: .protocolType)
        try container.encode(loggedAt, forKey: .loggedAt)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(notes, forKey: .notes)
        // Note: heartRateAvg, heartRateMax, perceivedEffort, rating are NOT in database
        // They are only used locally in the app
    }

    /// Custom decoder to handle fields not in database schema
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        protocolType = try container.decode(RecoveryProtocolType.self, forKey: .protocolType)
        loggedAt = try container.decode(Date.self, forKey: .loggedAt)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        // These fields are NOT in database - set to nil when decoding from Supabase
        heartRateAvg = try container.decodeIfPresent(Int.self, forKey: .heartRateAvg)
        heartRateMax = try container.decodeIfPresent(Int.self, forKey: .heartRateMax)
        perceivedEffort = try container.decodeIfPresent(Int.self, forKey: .perceivedEffort)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
    }

    /// Duration in seconds (for backward compatibility with UI code)
    var durationSeconds: Int {
        durationMinutes * 60
    }

    /// Convenience initializer that accepts seconds and converts to minutes
    init(
        id: UUID,
        patientId: UUID,
        protocolType: RecoveryProtocolType,
        loggedAt: Date,
        durationSeconds: Int,
        temperature: Double? = nil,
        heartRateAvg: Int? = nil,
        heartRateMax: Int? = nil,
        perceivedEffort: Int? = nil,
        rating: Int? = nil,
        notes: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.patientId = patientId
        self.protocolType = protocolType
        self.loggedAt = loggedAt
        self.durationMinutes = durationSeconds / 60
        self.temperature = temperature
        self.heartRateAvg = heartRateAvg
        self.heartRateMax = heartRateMax
        self.perceivedEffort = perceivedEffort
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum RecoveryProtocolType: String, Codable, CaseIterable, Equatable {
    case saunaTraditional = "sauna_traditional"
    case saunaInfrared = "sauna_infrared"
    case saunaSteam = "sauna_steam"
    case coldPlunge = "cold_plunge"
    case coldShower = "cold_shower"
    case iceBath = "ice_bath"
    case contrast = "contrast"

    var displayName: String {
        switch self {
        case .saunaTraditional: return "Traditional Sauna"
        case .saunaInfrared: return "Infrared Sauna"
        case .saunaSteam: return "Steam Room"
        case .coldPlunge: return "Cold Plunge"
        case .coldShower: return "Cold Shower"
        case .iceBath: return "Ice Bath"
        case .contrast: return "Contrast Therapy"
        }
    }

    var icon: String {
        switch self {
        case .saunaTraditional: return "flame.fill"
        case .saunaInfrared: return "flame"
        case .saunaSteam: return "cloud.fill"
        case .coldPlunge: return "snowflake"
        case .coldShower: return "drop.fill"
        case .iceBath: return "snowflake.circle.fill"
        case .contrast: return "arrow.left.arrow.right"
        }
    }

    /// Whether this is a heat-based therapy
    var isHeatTherapy: Bool {
        switch self {
        case .saunaTraditional, .saunaInfrared, .saunaSteam:
            return true
        default:
            return false
        }
    }

    /// Whether this is a cold-based therapy
    var isColdTherapy: Bool {
        switch self {
        case .coldPlunge, .coldShower, .iceBath:
            return true
        default:
            return false
        }
    }
}

/// Recovery recommendation from AI
struct RecoveryRecommendation: Identifiable, Codable {
    let id: UUID
    let protocolType: RecoveryProtocolType
    let reason: String
    let priority: RecoveryPriority
    let suggestedDuration: Int // minutes

    enum CodingKeys: String, CodingKey {
        case id
        case protocolType = "protocol_type"
        case reason, priority
        case suggestedDuration = "suggested_duration"
    }
}

enum RecoveryPriority: String, Codable, Equatable {
    case high
    case medium
    case low
}
