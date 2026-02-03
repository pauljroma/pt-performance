//
//  AnalyticsService.swift
//  PTPerformance
//
//  Coordinator service that delegates to focused analytics services
//  Maintains backward compatibility as public facade
//

import Foundation
import Supabase

// MARK: - Data Models

/// Data point for pain trend chart
struct PainDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let painScore: Double
    let sessionNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "logged_date"
        case painScore = "avg_pain"
        case sessionNumber = "session_number"
    }
}

/// Adherence data
struct AdherenceData: Codable {
    let adherencePercentage: Double
    let completedSessions: Int
    let totalSessions: Int
    let weeklyBreakdown: [WeeklyAdherence]?

    enum CodingKeys: String, CodingKey {
        case adherencePercentage = "adherence_pct"
        case completedSessions = "completed_sessions"
        case totalSessions = "total_sessions"
        case weeklyBreakdown = "weekly_breakdown"
    }
}

struct WeeklyAdherence: Codable, Identifiable {
    let id: String
    let weekNumber: Int
    let adherencePercentage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case adherencePercentage = "adherence_pct"
    }
}

/// Session summary for history list with completion metrics for history display
struct SessionSummary: Codable, Identifiable {
    let id: String
    let sessionNumber: Int
    let sessionDate: Date
    let completed: Bool
    let exerciseCount: Int
    let avgPainScore: Double?
    // Additional fields for completed session display
    let completedAt: Date?
    let totalVolume: Double?
    let avgRpe: Double?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionNumber = "session_number"
        case sessionDate = "session_date"
        case completed
        case exerciseCount = "exercise_count"
        case avgPainScore = "avg_pain_score"
        case completedAt = "completed_at"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case durationMinutes = "duration_minutes"
    }
}

/// Summary of a completed manual workout for history display
struct ManualWorkoutSummary: Codable, Identifiable {
    let id: UUID
    let name: String?
    let completedAt: Date?
    let createdAt: Date
    let completed: Bool
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?
    let exerciseCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case completed
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
        case exerciseCount = "exercise_count"
    }

    var displayName: String {
        name ?? "Manual Workout"
    }

    var workoutDate: Date {
        completedAt ?? createdAt
    }
}

/// Summary statistics
struct SummaryStats {
    let adherencePercentage: Double
    let avgPainScore: Double
    let completedSessions: Int
    let totalSessions: Int
}

// MARK: - Analytics Service (Coordinator)

/// Coordinator service for fetching analytics data
///
/// Acts as a facade that delegates to focused analytics services while
/// maintaining a unified API for consumers. This design follows the
/// single responsibility principle by separating analytics concerns.
///
/// ## Delegated Services
/// - `VolumeAnalyticsService`: Workout volume calculations
/// - `StrengthAnalyticsService`: Strength progression and PRs
/// - `AdherenceService`: Workout consistency and pain trends
/// - `WorkoutHistoryService`: Session history queries
///
/// ## Usage Example
/// ```swift
/// let analytics = AnalyticsService.shared
///
/// // Fetch pain trend
/// let painTrend = try await analytics.fetchPainTrend(patientId: id, days: 14)
///
/// // Calculate volume data
/// let volumeData = try await analytics.calculateVolumeData(for: id, period: .lastMonth)
/// ```
class AnalyticsService {

    // MARK: - Singleton

    static let shared = AnalyticsService()

    // MARK: - Focused Services

    private let volumeService: VolumeAnalyticsService
    private let strengthService: StrengthAnalyticsService
    private let adherenceService: AdherenceService
    private let historyService: WorkoutHistoryService

    // MARK: - Legacy Dependencies (for backward compatibility)

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        self.volumeService = VolumeAnalyticsService(supabase: supabase)
        self.strengthService = StrengthAnalyticsService(supabase: supabase)
        self.adherenceService = AdherenceService(supabase: supabase)
        self.historyService = WorkoutHistoryService(supabase: supabase)
    }

    // MARK: - Pain & Adherence (Delegated to AdherenceService)

    /// Fetch pain trend data from vw_pain_trend view
    func fetchPainTrend(patientId: String, days: Int = 14) async throws -> [PainDataPoint] {
        try await adherenceService.fetchPainTrend(patientId: patientId, days: days)
    }

    /// Fetch adherence data from vw_patient_adherence view
    func fetchAdherence(patientId: String, days: Int = 30) async throws -> AdherenceData {
        try await adherenceService.fetchAdherence(patientId: patientId, days: days)
    }

    /// Fetch summary statistics
    func fetchSummaryStats(patientId: String) async throws -> SummaryStats {
        try await adherenceService.fetchSummaryStats(patientId: patientId)
    }

    /// Calculate workout consistency over time
    func calculateConsistencyData(for patientId: String, period: TimePeriod) async throws -> ConsistencyChartData {
        try await adherenceService.calculateConsistencyData(for: patientId, period: period)
    }

    // MARK: - Session History (Delegated to WorkoutHistoryService)

    /// Fetch recent completed session summaries for history view
    func fetchRecentSessions(patientId: String, limit: Int = 10) async throws -> [SessionSummary] {
        try await historyService.fetchRecentSessions(patientId: patientId, limit: limit)
    }

    /// Fetch recent completed sessions with pagination support
    func fetchRecentSessionsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [SessionSummary] {
        try await historyService.fetchRecentSessionsPaginated(patientId: patientId, limit: limit, offset: offset)
    }

    /// Fetch exercise logs for a prescribed session with exercise names
    func fetchSessionExerciseLogs(sessionId: String, patientId: String) async throws -> [ExerciseLogDetail] {
        try await historyService.fetchSessionExerciseLogs(sessionId: sessionId, patientId: patientId)
    }

    // MARK: - Manual Workout History (Delegated to WorkoutHistoryService)

    /// Fetch recent completed manual workouts
    func fetchRecentManualWorkouts(patientId: String, limit: Int = 10) async throws -> [ManualWorkoutSummary] {
        try await historyService.fetchRecentManualWorkouts(patientId: patientId, limit: limit)
    }

    /// Fetch recent completed manual workouts with pagination support
    func fetchRecentManualWorkoutsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [ManualWorkoutSummary] {
        try await historyService.fetchRecentManualWorkoutsPaginated(patientId: patientId, limit: limit, offset: offset)
    }

    /// Fetch exercises for a manual workout
    func fetchManualWorkoutExercises(workoutId: UUID) async throws -> [ExerciseLogDetail] {
        try await historyService.fetchManualWorkoutExercises(workoutId: workoutId)
    }

    /// Fetch recent session history for a specific exercise
    func fetchExerciseRecentHistory(patientId: String, exerciseName: String, limit: Int = 10) async throws -> [ExerciseSessionRecord] {
        try await historyService.fetchExerciseRecentHistory(patientId: patientId, exerciseName: exerciseName, limit: limit)
    }

    // MARK: - Volume Analytics (Delegated to VolumeAnalyticsService)

    /// Calculate volume data for a time period
    func calculateVolumeData(for patientId: String, period: TimePeriod) async throws -> VolumeChartData {
        try await volumeService.calculateVolumeData(for: patientId, period: period)
    }

    // MARK: - Strength Analytics (Delegated to StrengthAnalyticsService)

    /// Calculate strength progression for a specific exercise
    func calculateStrengthData(for patientId: String, exerciseId: String, period: TimePeriod) async throws -> StrengthChartData {
        try await strengthService.calculateStrengthData(for: patientId, exerciseId: exerciseId, period: period)
    }

    /// Fetch time-series exercise progress data for charting
    func fetchExerciseProgressTimeSeries(patientId: String, exerciseName: String, limit: Int = 50) async throws -> [ExerciseProgressDataPoint] {
        try await strengthService.fetchExerciseProgressTimeSeries(patientId: patientId, exerciseName: exerciseName, limit: limit)
    }
}

// MARK: - Analytics Error

enum AnalyticsError: LocalizedError {
    case calculationFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .calculationFailed:
            return "Failed to calculate analytics"
        case .noData:
            return "No data available for the selected period"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .calculationFailed:
            return "Please try again. If the problem persists, contact support."
        case .noData:
            return "Complete some workouts to see your analytics here."
        }
    }
}
