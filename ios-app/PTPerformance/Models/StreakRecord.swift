//
//  StreakRecord.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Models for streak records and history
//

import Foundation
import SwiftUI

// MARK: - Streak Type

/// Types of streaks that can be tracked
enum StreakType: String, Codable, CaseIterable, Identifiable {
    case workout = "workout"
    case armCare = "arm_care"
    case combined = "combined"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .armCare: return "Arm Care"
        case .combined: return "Training"
        }
    }

    var iconName: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .armCare: return "arm.flexed.fill"
        case .combined: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .workout: return .blue
        case .armCare: return .orange
        case .combined: return .red
        }
    }
}

// MARK: - Streak Record

/// Represents a streak record from the database
struct StreakRecord: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let streakType: StreakType
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let streakStartDate: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case streakStartDate = "streak_start_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle streak_type as string
        let typeString = try container.decode(String.self, forKey: .streakType)
        streakType = StreakType(rawValue: typeString) ?? .combined

        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)

        // Handle date fields that may come as DATE format (YYYY-MM-DD)
        lastActivityDate = try Self.decodeDateField(container: container, forKey: .lastActivityDate)
        streakStartDate = try Self.decodeDateField(container: container, forKey: .streakStartDate)

        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private static func decodeDateField(container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        if let dateString = try? container.decode(String.self, forKey: key) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.date(from: dateString)
        }
        return try? container.decode(Date.self, forKey: key)
    }

    // MARK: - Computed Properties

    /// Check if streak is at risk (no activity today)
    var isAtRisk: Bool {
        guard let lastDate = lastActivityDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Motivational message based on streak
    var motivationalMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks! Amazing!"
        case 30...59: return "One month! Incredible!"
        case 60...89: return "Two months! Unstoppable!"
        default: return "Legendary consistency!"
        }
    }

    /// Badge level based on longest streak
    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }
}

// MARK: - Streak History

/// Represents daily activity history
struct StreakHistory: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let activityDate: Date
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let sessionId: UUID?
    let manualSessionId: UUID?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case activityDate = "activity_date"
        case workoutCompleted = "workout_completed"
        case armCareCompleted = "arm_care_completed"
        case sessionId = "session_id"
        case manualSessionId = "manual_session_id"
        case notes
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle DATE format
        if let dateString = try? container.decode(String.self, forKey: .activityDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            activityDate = dateFormatter.date(from: dateString) ?? Date()
        } else {
            activityDate = try container.decode(Date.self, forKey: .activityDate)
        }

        workoutCompleted = try container.decodeIfPresent(Bool.self, forKey: .workoutCompleted) ?? false
        armCareCompleted = try container.decodeIfPresent(Bool.self, forKey: .armCareCompleted) ?? false
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        manualSessionId = try container.decodeIfPresent(UUID.self, forKey: .manualSessionId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// Check if any activity was completed
    var hasAnyActivity: Bool {
        workoutCompleted || armCareCompleted
    }
}

// MARK: - Streak Statistics

/// Comprehensive streak statistics from database function
struct StreakStatistics: Codable {
    let streakType: String
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let streakStartDate: Date?
    let totalActivityDays: Int
    let thisWeekDays: Int
    let thisMonthDays: Int

    enum CodingKeys: String, CodingKey {
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case streakStartDate = "streak_start_date"
        case totalActivityDays = "total_activity_days"
        case thisWeekDays = "this_week_days"
        case thisMonthDays = "this_month_days"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        streakType = try container.decode(String.self, forKey: .streakType)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalActivityDays = try container.decode(Int.self, forKey: .totalActivityDays)
        thisWeekDays = try container.decode(Int.self, forKey: .thisWeekDays)
        thisMonthDays = try container.decode(Int.self, forKey: .thisMonthDays)

        // Handle DATE format for optional dates
        if let dateString = try? container.decode(String.self, forKey: .lastActivityDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            lastActivityDate = dateFormatter.date(from: dateString)
        } else {
            lastActivityDate = try? container.decode(Date.self, forKey: .lastActivityDate)
        }

        if let dateString = try? container.decode(String.self, forKey: .streakStartDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            streakStartDate = dateFormatter.date(from: dateString)
        } else {
            streakStartDate = try? container.decode(Date.self, forKey: .streakStartDate)
        }
    }

    /// Parsed streak type
    var type: StreakType {
        StreakType(rawValue: streakType) ?? .combined
    }
}

// MARK: - Calendar History Entry

/// History entry for calendar view (from RPC function)
struct CalendarHistoryEntry: Codable, Identifiable {
    var id: Date { activityDate }
    let activityDate: Date
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let hasAnyActivity: Bool
    let sessionId: UUID?
    let manualSessionId: UUID?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case activityDate = "activity_date"
        case workoutCompleted = "workout_completed"
        case armCareCompleted = "arm_care_completed"
        case hasAnyActivity = "has_any_activity"
        case sessionId = "session_id"
        case manualSessionId = "manual_session_id"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle DATE format
        if let dateString = try? container.decode(String.self, forKey: .activityDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            activityDate = dateFormatter.date(from: dateString) ?? Date()
        } else {
            activityDate = try container.decode(Date.self, forKey: .activityDate)
        }

        workoutCompleted = try container.decodeIfPresent(Bool.self, forKey: .workoutCompleted) ?? false
        armCareCompleted = try container.decodeIfPresent(Bool.self, forKey: .armCareCompleted) ?? false
        hasAnyActivity = try container.decodeIfPresent(Bool.self, forKey: .hasAnyActivity) ?? false
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        manualSessionId = try container.decodeIfPresent(UUID.self, forKey: .manualSessionId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Streak Badge

/// Achievement badges based on streak milestones
enum StreakBadge: Int, CaseIterable {
    case starter = 0      // 0-6 days
    case committed = 7    // 7-13 days
    case dedicated = 14   // 14-29 days
    case champion = 30    // 30-59 days
    case elite = 60       // 60-89 days
    case legend = 90      // 90+ days

    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .committed: return "Committed"
        case .dedicated: return "Dedicated"
        case .champion: return "Champion"
        case .elite: return "Elite"
        case .legend: return "Legend"
        }
    }

    var iconName: String {
        switch self {
        case .starter: return "flame"
        case .committed: return "flame.fill"
        case .dedicated: return "star.fill"
        case .champion: return "crown.fill"
        case .elite: return "trophy.fill"
        case .legend: return "medal.fill"
        }
    }

    var color: Color {
        switch self {
        case .starter: return .gray
        case .committed: return .blue
        case .dedicated: return .green
        case .champion: return .orange
        case .elite: return .purple
        case .legend: return .yellow
        }
    }

    var minDays: Int {
        rawValue
    }

    var description: String {
        switch self {
        case .starter: return "Just getting started"
        case .committed: return "One week strong!"
        case .dedicated: return "Two weeks of dedication"
        case .champion: return "A full month!"
        case .elite: return "Two months of consistency"
        case .legend: return "Three months of excellence"
        }
    }

    static func badge(for days: Int) -> StreakBadge {
        if days >= 90 { return .legend }
        if days >= 60 { return .elite }
        if days >= 30 { return .champion }
        if days >= 14 { return .dedicated }
        if days >= 7 { return .committed }
        return .starter
    }

    /// Next badge to achieve
    var nextBadge: StreakBadge? {
        switch self {
        case .starter: return .committed
        case .committed: return .dedicated
        case .dedicated: return .champion
        case .champion: return .elite
        case .elite: return .legend
        case .legend: return nil
        }
    }
}

// MARK: - Activity Input

/// Input for recording streak activity
struct StreakActivityInput: Codable {
    let patientId: String
    let activityDate: String
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let sessionId: String?
    let manualSessionId: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "p_patient_id"
        case activityDate = "p_activity_date"
        case workoutCompleted = "p_workout_completed"
        case armCareCompleted = "p_arm_care_completed"
        case sessionId = "p_session_id"
        case manualSessionId = "p_manual_session_id"
        case notes = "p_notes"
    }
}
