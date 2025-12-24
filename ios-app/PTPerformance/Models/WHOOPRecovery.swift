//
//  WHOOPRecovery.swift
//  PTPerformance
//
//  Build 76 - WHOOP Integration
//

import Foundation

struct WHOOPRecovery: Codable, Identifiable {
    let id: UUID
    let athleteId: UUID
    let date: Date
    let recoveryScore: Double  // 0-100
    let hrvRmssd: Double?      // HRV in ms
    let restingHr: Int?
    let hrvBaseline: Double?
    let sleepPerformance: Double?
    let readinessBand: String  // "green", "yellow", "red"
    let syncedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case date
        case recoveryScore = "recovery_score"
        case hrvRmssd = "hrv_rmssd"
        case restingHr = "resting_hr"
        case hrvBaseline = "hrv_baseline"
        case sleepPerformance = "sleep_performance"
        case readinessBand = "readiness_band"
        case syncedAt = "synced_at"
    }

    var readinessBandEnum: ReadinessBand {
        ReadinessBand(rawValue: readinessBand) ?? .yellow
    }

    var recoveryLevel: String {
        switch recoveryScore {
        case 67...100:
            return "High Recovery"
        case 34..<67:
            return "Moderate Recovery"
        default:
            return "Low Recovery"
        }
    }
}

enum ReadinessBand: String, Codable {
    case green = "green"
    case yellow = "yellow"
    case red = "red"

    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    var emoji: String {
        switch self {
        case .green: return "🟢"
        case .yellow: return "🟡"
        case .red: return "🔴"
        }
    }

    var displayName: String {
        switch self {
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .red: return "Red"
        }
    }
}

// Session adjustment data
struct SessionAdjustment {
    let volumeMultiplier: Double
    let intensity: IntensityLevel
    let notes: String
}

enum IntensityLevel: String {
    case low = "Low Intensity"
    case moderate = "Moderate Intensity"
    case high = "High Intensity"
}
