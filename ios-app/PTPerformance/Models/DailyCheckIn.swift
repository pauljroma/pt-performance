//
//  DailyCheckIn.swift
//  PTPerformance
//
//  X2Index M8: Athlete Daily Check-in System
//  Core athlete action loop - captures wellness metrics for readiness calculation
//

import SwiftUI

// MARK: - Daily Check-In Model

/// Daily wellness check-in for athletes
/// Captures sleep, soreness, stress, energy, and optional pain metrics
/// Used by X2Index to calculate daily readiness and adapt training prescriptions
struct DailyCheckIn: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let athleteId: UUID
    let date: Date

    // Core wellness metrics
    let sleepQuality: Int           // 1-5 scale
    let sleepHours: Double?         // Optional hours slept
    let soreness: Int               // 1-10 scale (1=none, 10=extreme)
    let sorenessLocations: [String]? // Body parts with soreness
    let stress: Int                 // 1-10 scale
    let energy: Int                 // 1-10 scale (1=exhausted, 10=energized)

    // Optional pain tracking
    let painScore: Int?             // 0-10 scale, nil if no pain
    let painLocations: [String]?    // Body parts with pain

    // Mood and notes
    let mood: Int                   // 1-5 scale
    let freeText: String?           // Optional athlete notes

    // Timestamps
    let completedAt: Date
    let syncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case date
        case sleepQuality = "sleep_quality"
        case sleepHours = "sleep_hours"
        case soreness
        case sorenessLocations = "soreness_locations"
        case stress
        case energy
        case painScore = "pain_score"
        case painLocations = "pain_locations"
        case mood
        case freeText = "free_text"
        case completedAt = "completed_at"
        case syncedAt = "synced_at"
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        athleteId: UUID,
        date: Date = Date(),
        sleepQuality: Int,
        sleepHours: Double? = nil,
        soreness: Int,
        sorenessLocations: [String]? = nil,
        stress: Int,
        energy: Int,
        painScore: Int? = nil,
        painLocations: [String]? = nil,
        mood: Int,
        freeText: String? = nil,
        completedAt: Date = Date(),
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.athleteId = athleteId
        self.date = date
        self.sleepQuality = sleepQuality
        self.sleepHours = sleepHours
        self.soreness = soreness
        self.sorenessLocations = sorenessLocations
        self.stress = stress
        self.energy = energy
        self.painScore = painScore
        self.painLocations = painLocations
        self.mood = mood
        self.freeText = freeText
        self.completedAt = completedAt
        self.syncedAt = syncedAt
    }

    // MARK: - Custom Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        athleteId = container.safeUUID(forKey: .athleteId)

        // Date handling for PostgreSQL DATE format
        date = container.safeDate(forKey: .date)

        // Required integers with safe decoding
        sleepQuality = container.safeInt(forKey: .sleepQuality, default: 3)
        soreness = container.safeInt(forKey: .soreness, default: 1)
        stress = container.safeInt(forKey: .stress, default: 1)
        energy = container.safeInt(forKey: .energy, default: 5)
        mood = container.safeInt(forKey: .mood, default: 3)

        // Optional fields
        sleepHours = container.safeOptionalDouble(forKey: .sleepHours)
        painScore = container.safeOptionalInt(forKey: .painScore)
        freeText = container.safeOptionalString(forKey: .freeText)

        // Array fields
        sorenessLocations = try? container.decodeIfPresent([String].self, forKey: .sorenessLocations)
        painLocations = try? container.decodeIfPresent([String].self, forKey: .painLocations)

        // Timestamps
        completedAt = container.safeDate(forKey: .completedAt)
        syncedAt = container.safeOptionalDate(forKey: .syncedAt)
    }

    // MARK: - Computed Properties

    /// Calculate estimated readiness impact (0-100)
    var estimatedReadiness: Double {
        // Weighted formula:
        // Sleep Quality: 30% (inverted - higher is better)
        // Energy: 25% (inverted - higher is better)
        // Soreness: 20% (lower is better)
        // Stress: 15% (lower is better)
        // Mood: 10% (inverted - higher is better)

        let sleepComponent = Double(sleepQuality) / 5.0 * 30.0
        let energyComponent = Double(energy) / 10.0 * 25.0
        let sorenessComponent = Double(11 - soreness) / 10.0 * 20.0
        let stressComponent = Double(11 - stress) / 10.0 * 15.0
        let moodComponent = Double(mood) / 5.0 * 10.0

        var score = sleepComponent + energyComponent + sorenessComponent + stressComponent + moodComponent

        // Pain penalty
        if let pain = painScore, pain > 0 {
            score -= Double(pain) * 2
        }

        return max(0, min(100, score))
    }

    /// Readiness band based on score
    var readinessBand: ReadinessBand {
        let score = estimatedReadiness
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    /// Has pain reported
    var hasPain: Bool {
        if let score = painScore {
            return score > 0
        }
        return false
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Sleep quality emoji
    var sleepEmoji: String {
        switch sleepQuality {
        case 1: return "😴"
        case 2: return "😑"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😃"
        default: return "😐"
        }
    }

    /// Mood emoji
    var moodEmoji: String {
        switch mood {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😁"
        default: return "😐"
        }
    }
}

// MARK: - Check-In Streak

/// Tracks athlete check-in consistency
struct CheckInStreak: Codable, Hashable, Equatable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let lastCheckInDate: Date?
    let totalCheckIns: Int

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastCheckInDate = "last_check_in_date"
        case totalCheckIns = "total_check_ins"
    }

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCheckInDate: Date? = nil,
        totalCheckIns: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCheckInDate = lastCheckInDate
        self.totalCheckIns = totalCheckIns
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        currentStreak = (try? container.decode(Int.self, forKey: .currentStreak)) ?? 0
        longestStreak = (try? container.decode(Int.self, forKey: .longestStreak)) ?? 0
        totalCheckIns = (try? container.decode(Int.self, forKey: .totalCheckIns)) ?? 0

        // Handle date format
        if let dateString = try? container.decode(String.self, forKey: .lastCheckInDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            lastCheckInDate = dateFormatter.date(from: dateString)
        } else {
            lastCheckInDate = try? container.decode(Date.self, forKey: .lastCheckInDate)
        }
    }

    /// Check if streak is at risk (no check-in today)
    var isAtRisk: Bool {
        guard let lastDate = lastCheckInDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Motivational message based on streak
    var motivationalMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep it going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks! Amazing!"
        case 30...59: return "One month champion!"
        case 60...89: return "Two months! Incredible!"
        default: return "Legendary consistency!"
        }
    }

    /// Progress to next milestone
    var nextMilestone: Int {
        switch currentStreak {
        case 0..<7: return 7
        case 7..<14: return 14
        case 14..<30: return 30
        case 30..<60: return 60
        case 60..<90: return 90
        case 90..<180: return 180
        case 180..<365: return 365
        default: return currentStreak + 30
        }
    }

    /// Progress percentage to next milestone
    var progressToNextMilestone: Double {
        let next = nextMilestone
        let prev: Int
        switch currentStreak {
        case 0..<7: prev = 0
        case 7..<14: prev = 7
        case 14..<30: prev = 14
        case 30..<60: prev = 30
        case 60..<90: prev = 60
        case 90..<180: prev = 90
        case 180..<365: prev = 180
        default: prev = ((currentStreak / 30) * 30)
        }
        return Double(currentStreak - prev) / Double(next - prev)
    }
}

// MARK: - Check-In Input

/// Input model for creating a new check-in
struct DailyCheckInInput: Codable, Sendable {
    var sleepQuality: Int = 3
    var sleepHours: Double?
    var soreness: Int = 1
    var sorenessLocations: [String]?
    var stress: Int = 1
    var energy: Int = 5
    var painScore: Int?
    var painLocations: [String]?
    var mood: Int = 3
    var freeText: String?

    // Internal fields for database
    var athleteId: String?
    var date: String?

    enum CodingKeys: String, CodingKey {
        case sleepQuality = "sleep_quality"
        case sleepHours = "sleep_hours"
        case soreness
        case sorenessLocations = "soreness_locations"
        case stress
        case energy
        case painScore = "pain_score"
        case painLocations = "pain_locations"
        case mood
        case freeText = "free_text"
        case athleteId = "athlete_id"
        case date
    }

    /// Validate input before submission
    func validate() throws {
        guard (1...5).contains(sleepQuality) else {
            throw CheckInError.invalidSleepQuality
        }
        guard (1...10).contains(soreness) else {
            throw CheckInError.invalidSoreness
        }
        guard (1...10).contains(stress) else {
            throw CheckInError.invalidStress
        }
        guard (1...10).contains(energy) else {
            throw CheckInError.invalidEnergy
        }
        guard (1...5).contains(mood) else {
            throw CheckInError.invalidMood
        }
        if let pain = painScore {
            guard (0...10).contains(pain) else {
                throw CheckInError.invalidPainScore
            }
        }
        if let hours = sleepHours {
            guard hours >= 0 && hours <= 24 else {
                throw CheckInError.invalidSleepHours
            }
        }
    }
}

// MARK: - Check-In Error

enum CheckInError: LocalizedError, Equatable {
    case invalidSleepQuality
    case invalidSoreness
    case invalidStress
    case invalidEnergy
    case invalidMood
    case invalidPainScore
    case invalidSleepHours
    case alreadyCheckedIn
    case saveFailed
    case fetchFailed(String)
    case syncFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidSleepQuality:
            return "Sleep quality must be between 1 and 5"
        case .invalidSoreness:
            return "Soreness must be between 1 and 10"
        case .invalidStress:
            return "Stress must be between 1 and 10"
        case .invalidEnergy:
            return "Energy must be between 1 and 10"
        case .invalidMood:
            return "Mood must be between 1 and 5"
        case .invalidPainScore:
            return "Pain score must be between 0 and 10"
        case .invalidSleepHours:
            return "Sleep hours must be between 0 and 24"
        case .alreadyCheckedIn:
            return "You've already completed today's check-in"
        case .saveFailed:
            return "Failed to save your check-in"
        case .fetchFailed(let message):
            return "Failed to load check-in: \(message)"
        case .syncFailed:
            return "Failed to sync check-in data"
        case .notAuthenticated:
            return "Please sign in to complete check-in"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .fetchFailed, .syncFailed:
            return "Please check your connection and try again."
        case .notAuthenticated:
            return "Sign in with your athlete account."
        default:
            return nil
        }
    }
}

// MARK: - Soreness/Pain Locations

/// Common body locations for soreness/pain tracking
enum BodyLocation: String, CaseIterable, Identifiable, Codable, Sendable {
    case neck
    case shoulder
    case upperBack = "upper_back"
    case lowerBack = "lower_back"
    case chest
    case biceps
    case triceps
    case forearm
    case wrist
    case hip
    case glutes
    case quadriceps
    case hamstrings
    case knee
    case calf
    case ankle
    case foot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .quadriceps: return "Quads"
        case .hamstrings: return "Hamstrings"
        default: return rawValue.capitalized
        }
    }

    var emoji: String {
        switch self {
        case .neck, .shoulder, .upperBack: return "🦴"
        case .lowerBack, .hip, .glutes: return "🍑"
        case .chest, .biceps, .triceps, .forearm: return "💪"
        case .wrist, .ankle, .foot: return "🦶"
        case .quadriceps, .hamstrings, .knee, .calf: return "🦵"
        }
    }
}

// MARK: - Check-In Step

/// Steps in the check-in flow
enum CheckInStep: Int, CaseIterable, Identifiable {
    case sleep = 0
    case soreness = 1
    case energy = 2
    case stress = 3
    case pain = 4
    case notes = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sleep: return "Sleep"
        case .soreness: return "Soreness"
        case .energy: return "Energy"
        case .stress: return "Stress"
        case .pain: return "Pain"
        case .notes: return "Notes"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .soreness: return "figure.walk"
        case .energy: return "bolt.fill"
        case .stress: return "brain.head.profile"
        case .pain: return "bandage.fill"
        case .notes: return "note.text"
        }
    }

    var isOptional: Bool {
        switch self {
        case .pain, .notes: return true
        default: return false
        }
    }

    var next: CheckInStep? {
        CheckInStep(rawValue: rawValue + 1)
    }

    var previous: CheckInStep? {
        CheckInStep(rawValue: rawValue - 1)
    }
}
