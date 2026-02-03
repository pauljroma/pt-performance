//
//  WeeklySummary.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Model for weekly workout progress summary
//

import SwiftUI

// MARK: - Weekly Summary Model

/// Represents a week's workout progress summary
/// Used for weekly recap notifications and historical comparison
struct WeeklySummary: Codable, Identifiable {
    /// Unique identifier (for history records)
    var id: UUID?

    /// Start of the week being summarized
    let weekStartDate: Date

    /// End of the week being summarized
    let weekEndDate: Date

    /// Number of workouts completed
    let workoutsCompleted: Int

    /// Number of workouts scheduled
    let workoutsScheduled: Int

    /// Adherence percentage (0-100)
    let adherencePercentage: Double

    /// Total training volume (sets * reps * weight)
    let totalVolume: Double

    /// Percent change in volume from previous week
    let volumeChangePercent: Double

    /// Whether the workout streak was maintained
    let streakMaintained: Bool

    /// Current consecutive workout streak (days)
    let currentStreak: Int

    /// Top performing exercise of the week
    let topExercise: String?

    /// Primary area identified for improvement
    let improvementArea: String?

    enum CodingKeys: String, CodingKey {
        case id
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
        case workoutsCompleted = "workouts_completed"
        case workoutsScheduled = "workouts_scheduled"
        case adherencePercentage = "adherence_percentage"
        case totalVolume = "total_volume"
        case volumeChangePercent = "volume_change_pct"
        case streakMaintained = "streak_maintained"
        case currentStreak = "current_streak"
        case topExercise = "top_exercise"
        case improvementArea = "improvement_area"
    }

    // Custom decoder to handle various numeric formats from PostgreSQL
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id)

        // Handle date fields (could be Date or String)
        if let dateString = try? container.decode(String.self, forKey: .weekStartDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            weekStartDate = dateFormatter.date(from: dateString) ?? Date()
        } else {
            weekStartDate = try container.decode(Date.self, forKey: .weekStartDate)
        }

        if let dateString = try? container.decode(String.self, forKey: .weekEndDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            weekEndDate = dateFormatter.date(from: dateString) ?? Date()
        } else {
            weekEndDate = try container.decode(Date.self, forKey: .weekEndDate)
        }

        workoutsCompleted = try container.decode(Int.self, forKey: .workoutsCompleted)
        workoutsScheduled = try container.decode(Int.self, forKey: .workoutsScheduled)

        // Handle numeric fields that might come as strings
        if let stringValue = try? container.decode(String.self, forKey: .adherencePercentage) {
            adherencePercentage = Double(stringValue) ?? 0
        } else {
            adherencePercentage = try container.decodeIfPresent(Double.self, forKey: .adherencePercentage) ?? 0
        }

        if let stringValue = try? container.decode(String.self, forKey: .totalVolume) {
            totalVolume = Double(stringValue) ?? 0
        } else {
            totalVolume = try container.decodeIfPresent(Double.self, forKey: .totalVolume) ?? 0
        }

        if let stringValue = try? container.decode(String.self, forKey: .volumeChangePercent) {
            volumeChangePercent = Double(stringValue) ?? 0
        } else {
            volumeChangePercent = try container.decodeIfPresent(Double.self, forKey: .volumeChangePercent) ?? 0
        }

        streakMaintained = try container.decodeIfPresent(Bool.self, forKey: .streakMaintained) ?? false
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        topExercise = try container.decodeIfPresent(String.self, forKey: .topExercise)
        improvementArea = try container.decodeIfPresent(String.self, forKey: .improvementArea)
    }

    // Memberwise initializer
    init(
        id: UUID? = nil,
        weekStartDate: Date,
        weekEndDate: Date,
        workoutsCompleted: Int,
        workoutsScheduled: Int,
        adherencePercentage: Double,
        totalVolume: Double,
        volumeChangePercent: Double,
        streakMaintained: Bool,
        currentStreak: Int,
        topExercise: String?,
        improvementArea: String?
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.workoutsCompleted = workoutsCompleted
        self.workoutsScheduled = workoutsScheduled
        self.adherencePercentage = adherencePercentage
        self.totalVolume = totalVolume
        self.volumeChangePercent = volumeChangePercent
        self.streakMaintained = streakMaintained
        self.currentStreak = currentStreak
        self.topExercise = topExercise
        self.improvementArea = improvementArea
    }

    // MARK: - Computed Properties

    /// Generates a list of "wins" for the week based on achievements
    var wins: [String] {
        var achievements: [String] = []

        // Completion rate win
        if workoutsCompleted == workoutsScheduled && workoutsScheduled > 0 {
            achievements.append("Perfect week! Completed all \(workoutsCompleted) workouts")
        } else if adherencePercentage >= 80 {
            achievements.append("Strong adherence at \(Int(adherencePercentage))%")
        } else if workoutsCompleted > 0 {
            achievements.append("Completed \(workoutsCompleted)/\(workoutsScheduled) workouts")
        }

        // Streak win
        if currentStreak >= 7 {
            achievements.append("\(currentStreak)-day workout streak maintained")
        } else if streakMaintained && currentStreak >= 3 {
            achievements.append("\(currentStreak)-day streak going strong")
        }

        // Volume win
        if volumeChangePercent >= 10 {
            achievements.append("Training volume up \(Int(volumeChangePercent))%")
        } else if volumeChangePercent >= 5 {
            achievements.append("Volume increased \(Int(volumeChangePercent))%")
        }

        // Top exercise
        if let exercise = topExercise, !exercise.isEmpty {
            achievements.append("Top exercise: \(exercise)")
        }

        return achievements
    }

    /// Generates a list of improvement areas
    var improvementAreas: [String] {
        var areas: [String] = []

        // Add main improvement area
        if let area = improvementArea,
           !area.isEmpty,
           area != "Keep up the great work!" {
            areas.append(area)
        }

        // Adherence improvement
        if adherencePercentage < 60 {
            areas.append("Focus on completing scheduled workouts")
        }

        // Volume decline
        if volumeChangePercent < -10 {
            areas.append("Training volume decreased - consider progressive overload")
        }

        // Streak broken
        if !streakMaintained && currentStreak == 0 {
            areas.append("Restart your workout streak")
        }

        // If no areas, add encouraging message
        if areas.isEmpty {
            areas.append("Keep up the momentum!")
        }

        return areas
    }

    /// Performance category based on overall metrics
    var performanceCategory: PerformanceCategory {
        let score = (adherencePercentage * 0.5) +
                   (volumeChangePercent > 0 ? 20 : 0) +
                   (streakMaintained ? 15 : 0) +
                   (Double(currentStreak) * 2)

        if score >= 80 {
            return .excellent
        } else if score >= 60 {
            return .good
        } else if score >= 40 {
            return .average
        } else {
            return .needsWork
        }
    }

    /// Formatted date range string
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: weekStartDate)
        let endStr = formatter.string(from: weekEndDate)
        return "\(startStr) - \(endStr)"
    }

    /// Formatted volume string
    var formattedVolume: String {
        if totalVolume >= 1_000_000 {
            return String(format: "%.1fM lbs", totalVolume / 1_000_000)
        } else if totalVolume >= 1_000 {
            return String(format: "%.1fK lbs", totalVolume / 1_000)
        } else {
            return String(format: "%.0f lbs", totalVolume)
        }
    }

    /// Volume change indicator emoji
    var volumeChangeEmoji: String {
        if volumeChangePercent >= 5 {
            return "chart.line.uptrend.xyaxis"
        } else if volumeChangePercent <= -5 {
            return "chart.line.downtrend.xyaxis"
        } else {
            return "chart.line.flattrend.xyaxis"
        }
    }
}

// MARK: - Performance Category

enum PerformanceCategory: String, CaseIterable {
    case excellent
    case good
    case average
    case needsWork

    var displayName: String {
        switch self {
        case .excellent: return "Excellent Week"
        case .good: return "Good Week"
        case .average: return "Solid Week"
        case .needsWork: return "Room to Grow"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .needsWork: return .red
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .average: return "checkmark.circle.fill"
        case .needsWork: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Weekly Summary Preferences

/// User preferences for weekly summary notifications
struct WeeklySummaryPreferences: Codable {
    let id: UUID?
    let patientId: UUID
    var notificationEnabled: Bool
    var notificationDay: NotificationDay
    var notificationHour: Int

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case notificationEnabled = "notification_enabled"
        case notificationDay = "notification_day"
        case notificationHour = "notification_hour"
    }

    enum NotificationDay: String, Codable, CaseIterable {
        case sunday
        case monday

        var displayName: String {
            rawValue.capitalized
        }

        var weekday: Int {
            switch self {
            case .sunday: return 1
            case .monday: return 2
            }
        }
    }

    /// Default preferences for a patient
    static func defaultPreferences(for patientId: UUID) -> WeeklySummaryPreferences {
        WeeklySummaryPreferences(
            id: nil,
            patientId: patientId,
            notificationEnabled: true,
            notificationDay: .sunday,
            notificationHour: 19
        )
    }

    /// Human-readable notification time
    var notificationTimeDescription: String {
        let hour12 = notificationHour > 12 ? notificationHour - 12 : notificationHour
        let amPm = notificationHour >= 12 ? "PM" : "AM"
        return "\(notificationDay.displayName) at \(hour12):00 \(amPm)"
    }
}

// MARK: - Sample Data

extension WeeklySummary {
    /// Sample summary for previews
    static var sample: WeeklySummary {
        WeeklySummary(
            id: UUID(),
            weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            weekEndDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            workoutsCompleted: 5,
            workoutsScheduled: 5,
            adherencePercentage: 100,
            totalVolume: 45000,
            volumeChangePercent: 8.5,
            streakMaintained: true,
            currentStreak: 12,
            topExercise: "Barbell Squat",
            improvementArea: nil
        )
    }

    /// Sample with room for improvement
    static var sampleNeedsWork: WeeklySummary {
        WeeklySummary(
            id: UUID(),
            weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            weekEndDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            workoutsCompleted: 2,
            workoutsScheduled: 5,
            adherencePercentage: 40,
            totalVolume: 15000,
            volumeChangePercent: -12,
            streakMaintained: false,
            currentStreak: 0,
            topExercise: "Dumbbell Curl",
            improvementArea: "Workout Consistency"
        )
    }
}
