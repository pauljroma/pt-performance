import Foundation

/// Recovery session tracking (sauna, cold plunge, etc.)
struct RecoverySession: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let protocolType: RecoveryProtocolType
    let startTime: Date
    let duration: Int // seconds
    let temperature: Double? // Fahrenheit for sauna, Celsius for cold
    let heartRateAvg: Int?
    let heartRateMax: Int?
    let perceivedEffort: Int? // 1-10 RPE
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case protocolType = "protocol_type"
        case startTime = "start_time"
        case duration, temperature
        case heartRateAvg = "heart_rate_avg"
        case heartRateMax = "heart_rate_max"
        case perceivedEffort = "perceived_effort"
        case notes
        case createdAt = "created_at"
    }
}

enum RecoveryProtocolType: String, Codable, CaseIterable {
    case sauna = "sauna"
    case coldPlunge = "cold_plunge"
    case contrast = "contrast"
    case cryotherapy = "cryotherapy"
    case floatTank = "float_tank"
    case massage = "massage"
    case stretching = "stretching"
    case meditation = "meditation"

    var displayName: String {
        switch self {
        case .sauna: return "Sauna"
        case .coldPlunge: return "Cold Plunge"
        case .contrast: return "Contrast Therapy"
        case .cryotherapy: return "Cryotherapy"
        case .floatTank: return "Float Tank"
        case .massage: return "Massage"
        case .stretching: return "Stretching"
        case .meditation: return "Meditation"
        }
    }

    var icon: String {
        switch self {
        case .sauna: return "flame.fill"
        case .coldPlunge: return "snowflake"
        case .contrast: return "arrow.left.arrow.right"
        case .cryotherapy: return "thermometer.snowflake"
        case .floatTank: return "drop.fill"
        case .massage: return "hand.raised.fill"
        case .stretching: return "figure.flexibility"
        case .meditation: return "brain.head.profile"
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

enum RecoveryPriority: String, Codable {
    case high
    case medium
    case low
}
