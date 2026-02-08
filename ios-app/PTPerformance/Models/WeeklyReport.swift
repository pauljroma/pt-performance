//
//  WeeklyReport.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  Therapist weekly summary reports for patient progress review
//

import Foundation
import SwiftUI

// MARK: - Weekly Report Model

/// Comprehensive weekly report for therapist review of patient progress
struct WeeklyReport: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    let generatedAt: Date

    // Session Metrics
    let sessionCompletionRate: Double
    let totalSessionsScheduled: Int
    let totalSessionsCompleted: Int

    // Pain Metrics
    let averagePainLevel: Double?
    let painTrend: TrendDirection

    // Recovery Metrics
    let averageRecoveryScore: Double?
    let recoveryTrend: TrendDirection

    // Adherence
    let adherenceScore: Double

    // Goals Progress
    let goalsProgress: [GoalProgress]

    // AI Recommendations
    let aiRecommendationsAdopted: Int
    let aiRecommendationsTotal: Int

    // Highlights
    let achievements: [String]
    let concerns: [String]
    let recommendations: [String]

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
        case generatedAt = "generated_at"
        case sessionCompletionRate = "session_completion_rate"
        case totalSessionsScheduled = "total_sessions_scheduled"
        case totalSessionsCompleted = "total_sessions_completed"
        case averagePainLevel = "average_pain_level"
        case painTrend = "pain_trend"
        case averageRecoveryScore = "average_recovery_score"
        case recoveryTrend = "recovery_trend"
        case adherenceScore = "adherence_score"
        case goalsProgress = "goals_progress"
        case aiRecommendationsAdopted = "ai_recommendations_adopted"
        case aiRecommendationsTotal = "ai_recommendations_total"
        case achievements
        case concerns
        case recommendations
    }

    // MARK: - Computed Properties

    /// Formatted date range string
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: weekStartDate)
        let endStr = formatter.string(from: weekEndDate)
        return "\(startStr) - \(endStr)"
    }

    /// Week number for the year
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: weekStartDate)
    }

    /// AI recommendation adoption rate as percentage
    var aiAdoptionRate: Double {
        guard aiRecommendationsTotal > 0 else { return 0 }
        return Double(aiRecommendationsAdopted) / Double(aiRecommendationsTotal) * 100
    }

    /// Session completion as formatted percentage string
    var completionRateDisplay: String {
        String(format: "%.0f%%", sessionCompletionRate * 100)
    }

    /// Adherence as formatted percentage string
    var adherenceDisplay: String {
        String(format: "%.0f%%", adherenceScore * 100)
    }

    /// Overall status based on key metrics
    var overallStatus: ReportStatus {
        let score = (sessionCompletionRate * 40) +
                   (adherenceScore * 30) +
                   (painTrend == .improving ? 0.15 : painTrend == .declining ? 0.0 : 0.1) * 100 +
                   (recoveryTrend == .improving ? 0.15 : recoveryTrend == .declining ? 0.0 : 0.1) * 100

        if score >= 80 {
            return .excellent
        } else if score >= 60 {
            return .good
        } else if score >= 40 {
            return .fair
        } else {
            return .needsAttention
        }
    }

    /// Goals completion percentage
    var goalsCompletionPercentage: Double {
        guard !goalsProgress.isEmpty else { return 0 }
        let total = goalsProgress.map { $0.percentComplete }.reduce(0, +)
        return total / Double(goalsProgress.count)
    }

    /// Count of goals that are on track or ahead
    var goalsOnTrack: Int {
        goalsProgress.filter { $0.percentComplete >= 75 || $0.trend == .improving }.count
    }

    // MARK: - Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        therapistId = try container.decode(UUID.self, forKey: .therapistId)

        // Handle dates that may come as strings
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

        generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()

        // Handle numeric fields that might come as strings from PostgreSQL
        if let stringValue = try? container.decode(String.self, forKey: .sessionCompletionRate) {
            sessionCompletionRate = Double(stringValue) ?? 0
        } else {
            sessionCompletionRate = try container.decodeIfPresent(Double.self, forKey: .sessionCompletionRate) ?? 0
        }

        totalSessionsScheduled = try container.decodeIfPresent(Int.self, forKey: .totalSessionsScheduled) ?? 0
        totalSessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .totalSessionsCompleted) ?? 0

        if let stringValue = try? container.decode(String.self, forKey: .averagePainLevel) {
            averagePainLevel = Double(stringValue)
        } else {
            averagePainLevel = try container.decodeIfPresent(Double.self, forKey: .averagePainLevel)
        }

        painTrend = try container.decodeIfPresent(TrendDirection.self, forKey: .painTrend) ?? .stable

        if let stringValue = try? container.decode(String.self, forKey: .averageRecoveryScore) {
            averageRecoveryScore = Double(stringValue)
        } else {
            averageRecoveryScore = try container.decodeIfPresent(Double.self, forKey: .averageRecoveryScore)
        }

        recoveryTrend = try container.decodeIfPresent(TrendDirection.self, forKey: .recoveryTrend) ?? .stable

        if let stringValue = try? container.decode(String.self, forKey: .adherenceScore) {
            adherenceScore = Double(stringValue) ?? 0
        } else {
            adherenceScore = try container.decodeIfPresent(Double.self, forKey: .adherenceScore) ?? 0
        }

        goalsProgress = try container.decodeIfPresent([GoalProgress].self, forKey: .goalsProgress) ?? []
        aiRecommendationsAdopted = try container.decodeIfPresent(Int.self, forKey: .aiRecommendationsAdopted) ?? 0
        aiRecommendationsTotal = try container.decodeIfPresent(Int.self, forKey: .aiRecommendationsTotal) ?? 0
        achievements = try container.decodeIfPresent([String].self, forKey: .achievements) ?? []
        concerns = try container.decodeIfPresent([String].self, forKey: .concerns) ?? []
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID,
        weekStartDate: Date,
        weekEndDate: Date,
        generatedAt: Date = Date(),
        sessionCompletionRate: Double,
        totalSessionsScheduled: Int,
        totalSessionsCompleted: Int,
        averagePainLevel: Double?,
        painTrend: TrendDirection,
        averageRecoveryScore: Double?,
        recoveryTrend: TrendDirection,
        adherenceScore: Double,
        goalsProgress: [GoalProgress],
        aiRecommendationsAdopted: Int,
        aiRecommendationsTotal: Int,
        achievements: [String],
        concerns: [String],
        recommendations: [String]
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.generatedAt = generatedAt
        self.sessionCompletionRate = sessionCompletionRate
        self.totalSessionsScheduled = totalSessionsScheduled
        self.totalSessionsCompleted = totalSessionsCompleted
        self.averagePainLevel = averagePainLevel
        self.painTrend = painTrend
        self.averageRecoveryScore = averageRecoveryScore
        self.recoveryTrend = recoveryTrend
        self.adherenceScore = adherenceScore
        self.goalsProgress = goalsProgress
        self.aiRecommendationsAdopted = aiRecommendationsAdopted
        self.aiRecommendationsTotal = aiRecommendationsTotal
        self.achievements = achievements
        self.concerns = concerns
        self.recommendations = recommendations
    }
}

// MARK: - Goal Progress

/// Progress tracking for individual patient goals
struct GoalProgress: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let goalName: String
    let targetValue: Double
    let currentValue: Double
    let percentComplete: Double
    let trend: TrendDirection

    enum CodingKeys: String, CodingKey {
        case id
        case goalName = "goal_name"
        case targetValue = "target_value"
        case currentValue = "current_value"
        case percentComplete = "percent_complete"
        case trend
    }

    /// Formatted percentage string
    var percentDisplay: String {
        String(format: "%.0f%%", percentComplete)
    }

    /// Progress as a fraction (0-1) for progress bars
    var progressFraction: Double {
        min(max(percentComplete / 100, 0), 1)
    }

    /// Status color based on progress
    var statusColor: Color {
        if percentComplete >= 100 {
            return .green
        } else if percentComplete >= 75 {
            return .blue
        } else if percentComplete >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        goalName = try container.decode(String.self, forKey: .goalName)

        // Handle numeric fields that might be strings
        if let stringValue = try? container.decode(String.self, forKey: .targetValue) {
            targetValue = Double(stringValue) ?? 0
        } else {
            targetValue = try container.decodeIfPresent(Double.self, forKey: .targetValue) ?? 0
        }

        if let stringValue = try? container.decode(String.self, forKey: .currentValue) {
            currentValue = Double(stringValue) ?? 0
        } else {
            currentValue = try container.decodeIfPresent(Double.self, forKey: .currentValue) ?? 0
        }

        if let stringValue = try? container.decode(String.self, forKey: .percentComplete) {
            percentComplete = Double(stringValue) ?? 0
        } else {
            percentComplete = try container.decodeIfPresent(Double.self, forKey: .percentComplete) ?? 0
        }

        trend = try container.decodeIfPresent(TrendDirection.self, forKey: .trend) ?? .stable
    }

    init(
        id: UUID = UUID(),
        goalName: String,
        targetValue: Double,
        currentValue: Double,
        percentComplete: Double,
        trend: TrendDirection
    ) {
        self.id = id
        self.goalName = goalName
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.percentComplete = percentComplete
        self.trend = trend
    }
}

// MARK: - Report Status

/// Overall status classification for a weekly report
enum ReportStatus: String, Codable, Sendable, CaseIterable {
    case excellent
    case good
    case fair
    case needsAttention

    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent Progress"
        case .good:
            return "Good Progress"
        case .fair:
            return "Fair Progress"
        case .needsAttention:
            return "Needs Attention"
        }
    }

    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .needsAttention:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "checkmark.circle.fill"
        case .fair:
            return "exclamationmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Report Schedule

/// Configuration for automated weekly report generation
struct ReportSchedule: Codable, Identifiable, Sendable {
    let id: UUID
    let therapistId: UUID
    let dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    let hour: Int // 0-23
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case dayOfWeek = "day_of_week"
        case hour
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Human-readable schedule description
    var scheduleDescription: String {
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let dayName = dayOfWeek >= 1 && dayOfWeek <= 7 ? dayNames[dayOfWeek] : "Unknown"
        let hourFormatted = hour == 0 ? "12:00 AM" : hour < 12 ? "\(hour):00 AM" : hour == 12 ? "12:00 PM" : "\(hour - 12):00 PM"
        return "\(dayName) at \(hourFormatted)"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        therapistId = try container.decode(UUID.self, forKey: .therapistId)
        dayOfWeek = try container.decodeIfPresent(Int.self, forKey: .dayOfWeek) ?? 2 // Default to Monday
        hour = try container.decodeIfPresent(Int.self, forKey: .hour) ?? 8 // Default to 8 AM
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    init(
        id: UUID = UUID(),
        therapistId: UUID,
        dayOfWeek: Int = 2, // Monday
        hour: Int = 8, // 8 AM
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.therapistId = therapistId
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sample Data

extension WeeklyReport {
    static var sample: WeeklyReport {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        return WeeklyReport(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            weekStartDate: weekStart,
            weekEndDate: now,
            generatedAt: now,
            sessionCompletionRate: 0.85,
            totalSessionsScheduled: 5,
            totalSessionsCompleted: 4,
            averagePainLevel: 3.5,
            painTrend: .improving,
            averageRecoveryScore: 75.0,
            recoveryTrend: .stable,
            adherenceScore: 0.92,
            goalsProgress: [
                GoalProgress(
                    id: UUID(),
                    goalName: "Improve ROM",
                    targetValue: 180,
                    currentValue: 155,
                    percentComplete: 86,
                    trend: .improving
                ),
                GoalProgress(
                    id: UUID(),
                    goalName: "Reduce Pain",
                    targetValue: 2,
                    currentValue: 3.5,
                    percentComplete: 65,
                    trend: .improving
                ),
                GoalProgress(
                    id: UUID(),
                    goalName: "Build Strength",
                    targetValue: 100,
                    currentValue: 78,
                    percentComplete: 78,
                    trend: .stable
                )
            ],
            aiRecommendationsAdopted: 3,
            aiRecommendationsTotal: 4,
            achievements: [
                "Completed all prescribed exercises",
                "Pain reduced by 20%",
                "7-day workout streak"
            ],
            concerns: [
                "Slight increase in morning stiffness"
            ],
            recommendations: [
                "Continue current exercise protocol",
                "Consider adding stretching routine",
                "Schedule follow-up assessment"
            ]
        )
    }
}
