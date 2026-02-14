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

    // MARK: - ACP-1028: Personalized Insights

    /// Generates personalized highlight based on user's training mode
    func personalizedHighlight(for mode: Mode) -> PersonalizedHighlight {
        switch mode {
        case .strength:
            return strengthHighlight
        case .rehab:
            return rehabHighlight
        case .performance:
            return performanceHighlight
        }
    }

    /// Strength-focused highlight: PRs, max weights, progressive overload
    private var strengthHighlight: PersonalizedHighlight {
        let title: String
        let subtitle: String
        let icon: String

        if volumeChangePercent >= 10 {
            title = "Progressive Overload"
            subtitle = "Volume up \(Int(volumeChangePercent))% -- you're pushing limits"
            icon = "arrow.up.right.circle.fill"
        } else if let exercise = topExercise, !exercise.isEmpty {
            title = "Strength Focus"
            subtitle = "\(exercise) led your training this week"
            icon = "dumbbell.fill"
        } else if volumeChangePercent > 0 {
            title = "Steady Progress"
            subtitle = "Volume trending up \(Int(volumeChangePercent))% week over week"
            icon = "chart.line.uptrend.xyaxis"
        } else {
            title = "Recovery Week"
            subtitle = "Lower volume can support strength adaptation"
            icon = "bed.double.fill"
        }

        return PersonalizedHighlight(
            title: title,
            subtitle: subtitle,
            icon: icon,
            accentColor: .modusCyan,
            category: .strength
        )
    }

    /// Rehab/beginner-focused highlight: consistency, adherence, habit building
    private var rehabHighlight: PersonalizedHighlight {
        let title: String
        let subtitle: String
        let icon: String

        if workoutsCompleted == workoutsScheduled && workoutsScheduled > 0 {
            title = "Perfect Consistency"
            subtitle = "Every session completed -- building a strong foundation"
            icon = "checkmark.seal.fill"
        } else if currentStreak >= 7 {
            title = "Habit Locked In"
            subtitle = "\(currentStreak)-day streak proves your commitment"
            icon = "flame.fill"
        } else if adherencePercentage >= 80 {
            title = "Strong Adherence"
            subtitle = "\(Int(adherencePercentage))% adherence keeps recovery on track"
            icon = "heart.circle.fill"
        } else if workoutsCompleted > 0 {
            title = "Showing Up Matters"
            subtitle = "\(workoutsCompleted) session\(workoutsCompleted == 1 ? "" : "s") completed -- every rep counts"
            icon = "figure.walk.circle.fill"
        } else {
            title = "Fresh Start Ahead"
            subtitle = "This week is a clean slate for progress"
            icon = "sunrise.fill"
        }

        return PersonalizedHighlight(
            title: title,
            subtitle: subtitle,
            icon: icon,
            accentColor: .modusTealAccent,
            category: .consistency
        )
    }

    /// Performance-focused highlight: volume, load management, training density
    private var performanceHighlight: PersonalizedHighlight {
        let title: String
        let subtitle: String
        let icon: String

        if totalVolume >= 50_000 && adherencePercentage >= 80 {
            title = "High Output Week"
            subtitle = "\(formattedVolume) moved at \(Int(adherencePercentage))% adherence"
            icon = "bolt.circle.fill"
        } else if volumeChangePercent >= 5 && adherencePercentage >= 80 {
            title = "Volume Ramping"
            subtitle = "Controlled \(Int(volumeChangePercent))% increase with full adherence"
            icon = "chart.line.uptrend.xyaxis"
        } else if adherencePercentage >= 90 {
            title = "Elite Execution"
            subtitle = "\(Int(adherencePercentage))% program adherence this week"
            icon = "medal.fill"
        } else if streakMaintained && currentStreak >= 5 {
            title = "Training Consistency"
            subtitle = "\(currentStreak)-day streak supports periodization"
            icon = "calendar.badge.checkmark"
        } else {
            title = "Manage Your Load"
            subtitle = "Review training density for optimal adaptation"
            icon = "gauge.with.dots.needle.33percent"
        }

        return PersonalizedHighlight(
            title: title,
            subtitle: subtitle,
            icon: icon,
            accentColor: .modusDeepTeal,
            category: .volume
        )
    }

    /// Actionable next-week suggestions based on current data and mode
    func nextWeekSuggestions(for mode: Mode) -> [NextWeekSuggestion] {
        var suggestions: [NextWeekSuggestion] = []

        switch mode {
        case .strength:
            if volumeChangePercent < 0 {
                suggestions.append(NextWeekSuggestion(
                    text: "Add one extra set per major lift to restore volume",
                    icon: "plus.circle.fill",
                    priority: .high
                ))
            }
            if adherencePercentage < 80 {
                suggestions.append(NextWeekSuggestion(
                    text: "Hit at least \(workoutsScheduled) sessions for strength gains",
                    icon: "calendar.badge.plus",
                    priority: .medium
                ))
            }
            if volumeChangePercent >= 0 {
                suggestions.append(NextWeekSuggestion(
                    text: "Try increasing weight by 2.5-5 lbs on compound lifts",
                    icon: "arrow.up.circle.fill",
                    priority: .low
                ))
            }

        case .rehab:
            if !streakMaintained {
                suggestions.append(NextWeekSuggestion(
                    text: "Set a daily reminder to rebuild your workout streak",
                    icon: "bell.badge.fill",
                    priority: .high
                ))
            }
            if adherencePercentage < 60 {
                suggestions.append(NextWeekSuggestion(
                    text: "Aim for \(max(workoutsCompleted + 1, 3)) sessions next week",
                    icon: "target",
                    priority: .high
                ))
            } else {
                suggestions.append(NextWeekSuggestion(
                    text: "Maintain your \(Int(adherencePercentage))% adherence rate",
                    icon: "checkmark.shield.fill",
                    priority: .medium
                ))
            }
            suggestions.append(NextWeekSuggestion(
                text: "Log pain levels to track recovery trends",
                icon: "waveform.path.ecg",
                priority: .low
            ))

        case .performance:
            if volumeChangePercent > 15 {
                suggestions.append(NextWeekSuggestion(
                    text: "Consider a deload -- volume jumped \(Int(volumeChangePercent))%",
                    icon: "arrow.down.circle.fill",
                    priority: .high
                ))
            }
            if adherencePercentage < 90 {
                suggestions.append(NextWeekSuggestion(
                    text: "Target 100% adherence for optimal periodization",
                    icon: "scope",
                    priority: .medium
                ))
            }
            if totalVolume > 0 {
                suggestions.append(NextWeekSuggestion(
                    text: "Review RPE scores to calibrate training intensity",
                    icon: "gauge.with.dots.needle.50percent",
                    priority: .low
                ))
            }
        }

        // Cap at 3 suggestions
        return Array(suggestions.prefix(3))
    }

    /// Motivational insight based on data patterns
    func motivationalInsight(for mode: Mode) -> MotivationalInsight {
        // Check for streaks first -- universal motivator
        if currentStreak >= 14 {
            return MotivationalInsight(
                text: "Two weeks strong. Consistency is the foundation of every transformation.",
                icon: "flame.fill",
                category: .streak
            )
        }

        if workoutsCompleted == workoutsScheduled && workoutsScheduled >= 4 {
            return MotivationalInsight(
                text: "Perfect adherence with \(workoutsScheduled)+ sessions shows you're ready for the next level.",
                icon: "trophy.fill",
                category: .perfection
            )
        }

        if volumeChangePercent >= 10 {
            return MotivationalInsight(
                text: "A \(Int(volumeChangePercent))% volume increase means your body is adapting. Keep the momentum.",
                icon: "chart.line.uptrend.xyaxis",
                category: .growth
            )
        }

        if currentStreak >= 5 {
            return MotivationalInsight(
                text: "\(currentStreak) days in a row. Discipline is doing what needs to be done, even when you don't want to.",
                icon: "flame.fill",
                category: .streak
            )
        }

        // Mode-specific fallback motivational insights
        switch mode {
        case .strength:
            return MotivationalInsight(
                text: "Strength isn't built in a day. Each session adds to your foundation.",
                icon: "dumbbell.fill",
                category: .encouragement
            )
        case .rehab:
            return MotivationalInsight(
                text: "Recovery is progress. Every controlled movement brings you closer to full function.",
                icon: "heart.circle.fill",
                category: .encouragement
            )
        case .performance:
            return MotivationalInsight(
                text: "Elite performance comes from elite preparation. Trust the process.",
                icon: "medal.fill",
                category: .encouragement
            )
        }
    }

    /// Adherence progress as a value between 0 and 1 for progress rings
    var adherenceProgress: Double {
        adherencePercentage / 100.0
    }

    /// Workout completion progress as a value between 0 and 1
    var workoutCompletionProgress: Double {
        guard workoutsScheduled > 0 else { return 0 }
        return min(Double(workoutsCompleted) / Double(workoutsScheduled), 1.0)
    }

    /// Streak progress normalized to a 7-day goal (capped at 1.0)
    var streakProgress: Double {
        min(Double(currentStreak) / 7.0, 1.0)
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

// MARK: - ACP-1028: Personalization Support Types

/// Personalized highlight card data for mode-specific summary focus
struct PersonalizedHighlight {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let category: HighlightCategory

    enum HighlightCategory {
        case strength
        case consistency
        case volume
    }
}

/// Actionable suggestion for the upcoming week
struct NextWeekSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
    let priority: Priority

    enum Priority {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .modusCyan
            case .medium: return .modusTealAccent
            case .low: return .modusLightTeal
            }
        }

        var label: String {
            switch self {
            case .high: return "Priority"
            case .medium: return "Suggested"
            case .low: return "Optional"
            }
        }
    }
}

/// Motivational insight derived from user data patterns
struct MotivationalInsight {
    let text: String
    let icon: String
    let category: InsightCategory

    enum InsightCategory {
        case streak, perfection, growth, encouragement
    }
}

// MARK: - Week-over-Week Comparison

/// Comparison metrics between current and previous week
struct WeekComparison {
    let workoutsDelta: Int
    let adherenceDelta: Double
    let volumeDelta: Double
    let volumePercentDelta: Double
    let streakDelta: Int

    /// Creates a comparison from current and previous summaries
    static func compare(current: WeeklySummary, previous: WeeklySummary) -> WeekComparison {
        WeekComparison(
            workoutsDelta: current.workoutsCompleted - previous.workoutsCompleted,
            adherenceDelta: current.adherencePercentage - previous.adherencePercentage,
            volumeDelta: current.totalVolume - previous.totalVolume,
            volumePercentDelta: current.volumeChangePercent,
            streakDelta: current.currentStreak - previous.currentStreak
        )
    }

    /// Creates an empty comparison when no previous data exists
    static var empty: WeekComparison {
        WeekComparison(
            workoutsDelta: 0,
            adherenceDelta: 0,
            volumeDelta: 0,
            volumePercentDelta: 0,
            streakDelta: 0
        )
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
