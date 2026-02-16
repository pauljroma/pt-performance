//
//  VideoAnalyticsService.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 3
//  Service for tracking video watch history and analytics
//

import Foundation
import Supabase

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for video watch statistics
private struct GetVideoWatchStatisticsParams: Encodable {
    let pPatientId: String
    let pDays: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDays = "p_days"
    }
}

/// RPC parameters for total watch time
private struct GetTotalWatchTimeParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

/// Service for tracking video watch events and history
/// Logs user engagement with exercise videos for analytics
@MainActor
class VideoAnalyticsService: ObservableObject {

    // MARK: - Singleton

    static let shared = VideoAnalyticsService()

    private init() {}

    // MARK: - Published Properties

    @Published var recentHistory: [WatchHistory] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let client = PTSupabaseClient.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Models

    /// Event to log when a user watches a video
    struct WatchEvent: Codable {
        let exerciseTemplateId: UUID
        let watchDurationSeconds: Int
        let completed: Bool
        let qualityUsed: String?

        enum CodingKeys: String, CodingKey {
            case exerciseTemplateId = "exercise_template_id"
            case watchDurationSeconds = "watch_duration_seconds"
            case completed
            case qualityUsed = "quality_used"
        }
    }

    /// Record of a video watch session
    struct WatchHistory: Codable, Identifiable {
        let id: UUID
        let exerciseTemplateId: UUID
        let watchedAt: Date
        let watchDurationSeconds: Int
        let completed: Bool
        let qualityUsed: String?
        let exerciseName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case exerciseTemplateId = "exercise_template_id"
            case watchedAt = "watched_at"
            case watchDurationSeconds = "watch_duration_seconds"
            case completed
            case qualityUsed = "quality_used"
            case exerciseName = "exercise_name"
        }

        /// Formatted watch duration (e.g., "2:30")
        var formattedDuration: String {
            let minutes = watchDurationSeconds / 60
            let seconds = watchDurationSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        /// Formatted watched date (e.g., "Today", "Yesterday", or date)
        var formattedDate: String {
            let calendar = Calendar.current
            if calendar.isDateInToday(watchedAt) {
                return "Today"
            } else if calendar.isDateInYesterday(watchedAt) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: watchedAt)
            }
        }
    }

    /// Summary statistics for video engagement
    struct WatchStatistics: Codable {
        let totalWatched: Int
        let totalMinutesWatched: Int
        let completionRate: Double
        let mostWatchedExerciseId: UUID?
        let averageWatchDuration: Int

        enum CodingKeys: String, CodingKey {
            case totalWatched = "total_watched"
            case totalMinutesWatched = "total_minutes_watched"
            case completionRate = "completion_rate"
            case mostWatchedExerciseId = "most_watched_exercise_id"
            case averageWatchDuration = "average_watch_duration"
        }

        var formattedCompletionRate: String {
            String(format: "%.0f%%", completionRate * 100)
        }

        var formattedTotalTime: String {
            if totalMinutesWatched >= 60 {
                let hours = totalMinutesWatched / 60
                let minutes = totalMinutesWatched % 60
                return "\(hours)h \(minutes)m"
            } else {
                return "\(totalMinutesWatched)m"
            }
        }
    }

    // MARK: - Log Watch Events

    /// Log a video watch event
    /// - Parameter event: The watch event to log
    /// - Throws: VideoAnalyticsError if logging fails
    func logWatchEvent(_ event: WatchEvent) async throws {
        guard let patientId = client.userId else {
            throw VideoAnalyticsError.noAuthenticatedUser
        }

        do {
            let insertData = WatchEventInsert(
                patientId: patientId,
                exerciseTemplateId: event.exerciseTemplateId.uuidString,
                watchDurationSeconds: event.watchDurationSeconds,
                completed: event.completed,
                qualityUsed: event.qualityUsed
            )

            try await client.client
                .from("video_watch_history")
                .insert(insertData)
                .execute()

            DebugLogger.shared.log("[VideoAnalytics] Logged watch event: \(event.exerciseTemplateId), duration: \(event.watchDurationSeconds)s, completed: \(event.completed)", level: .diagnostic)
        } catch {
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.logWatchEvent [exercise_template_id: \(event.exerciseTemplateId.uuidString), watch_duration: \(event.watchDurationSeconds)]"
            )
            throw VideoAnalyticsError.loggingFailed(error)
        }
    }

    /// Log video start (creates initial event that can be updated)
    /// - Parameter exerciseTemplateId: The exercise template UUID
    /// - Returns: The watch history ID for later updates
    func logVideoStart(exerciseTemplateId: UUID) async throws -> UUID {
        guard let patientId = client.userId else {
            throw VideoAnalyticsError.noAuthenticatedUser
        }

        let quality = VideoPreferencesService.shared.currentQuality.rawValue

        let insertData = WatchEventInsert(
            patientId: patientId,
            exerciseTemplateId: exerciseTemplateId.uuidString,
            watchDurationSeconds: 0,
            completed: false,
            qualityUsed: quality
        )

        do {
            let result: WatchHistory = try await client.client
                .from("video_watch_history")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value

            return result.id
        } catch {
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.logVideoStart [exercise_template_id: \(exerciseTemplateId.uuidString)]"
            )
            throw VideoAnalyticsError.loggingFailed(error)
        }
    }

    /// Update an existing watch event (e.g., when video ends)
    /// - Parameters:
    ///   - historyId: The watch history record ID
    ///   - duration: Final watch duration in seconds
    ///   - completed: Whether the video was completed
    func updateWatchEvent(historyId: UUID, duration: Int, completed: Bool) async throws {
        do {
            let update = WatchEventUpdate(
                watchDurationSeconds: duration,
                completed: completed
            )

            try await client.client
                .from("video_watch_history")
                .update(update)
                .eq("id", value: historyId.uuidString)
                .execute()

            DebugLogger.shared.log("[VideoAnalytics] Updated watch event \(historyId): duration=\(duration)s, completed=\(completed)", level: .diagnostic)
        } catch {
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.updateWatchEvent [history_id: \(historyId.uuidString)]"
            )
            throw VideoAnalyticsError.updateFailed(error)
        }
    }

    // MARK: - Fetch History

    /// Fetch watch history for the current user
    /// - Parameter limit: Maximum number of records to return (default 20)
    /// - Returns: Array of watch history records
    /// - Throws: VideoAnalyticsError if fetch fails
    func fetchWatchHistory(limit: Int = 20) async throws -> [WatchHistory] {
        guard let patientId = client.userId else {
            throw VideoAnalyticsError.noAuthenticatedUser
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Join with exercise_templates to get exercise names
            let history: [WatchHistory] = try await client.client
                .from("video_watch_history")
                .select("""
                    id,
                    exercise_template_id,
                    watched_at,
                    watch_duration_seconds,
                    completed,
                    quality_used,
                    exercise_templates(name)
                """)
                .eq("patient_id", value: patientId)
                .order("watched_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            self.recentHistory = history
            return history
        } catch {
            self.error = error.localizedDescription
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.fetchWatchHistory [patient_id: \(patientId), limit: \(limit)]"
            )
            throw VideoAnalyticsError.fetchFailed(error)
        }
    }

    /// Get recently watched videos (convenience method)
    /// Returns the last 10 videos watched
    /// - Returns: Array of recent watch history records
    func getRecentlyWatched() async throws -> [WatchHistory] {
        return try await fetchWatchHistory(limit: 10)
    }

    /// Fetch watch history for a specific exercise
    /// - Parameters:
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - limit: Maximum number of records (default 10)
    /// - Returns: Array of watch history records for the exercise
    func fetchHistoryForExercise(exerciseTemplateId: UUID, limit: Int = 10) async throws -> [WatchHistory] {
        guard let patientId = client.userId else {
            throw VideoAnalyticsError.noAuthenticatedUser
        }

        do {
            let history: [WatchHistory] = try await client.client
                .from("video_watch_history")
                .select()
                .eq("patient_id", value: patientId)
                .eq("exercise_template_id", value: exerciseTemplateId.uuidString)
                .order("watched_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            return history
        } catch {
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.fetchHistoryForExercise [exercise_template_id: \(exerciseTemplateId.uuidString)]"
            )
            throw VideoAnalyticsError.fetchFailed(error)
        }
    }

    // MARK: - Statistics

    /// Fetch watch statistics for the current user
    /// - Parameter days: Number of days to analyze (default 30)
    /// - Returns: Watch statistics summary
    func fetchWatchStatistics(days: Int = 30) async throws -> WatchStatistics {
        guard let patientId = client.userId else {
            throw VideoAnalyticsError.noAuthenticatedUser
        }

        do {
            let params = GetVideoWatchStatisticsParams(
                pPatientId: patientId,
                pDays: String(days)
            )
            let result: WatchStatistics = try await client.client
                .rpc("get_video_watch_statistics", params: params)
                .single()
                .execute()
                .value

            return result
        } catch {
            errorLogger.logError(
                error,
                context: "VideoAnalyticsService.fetchWatchStatistics [patient_id: \(patientId), days: \(days)]"
            )
            throw VideoAnalyticsError.statisticsFailed(error)
        }
    }

    /// Check if user has watched a specific video before
    /// - Parameter exerciseTemplateId: The exercise template UUID
    /// - Returns: True if the user has watched this video
    func hasWatched(exerciseTemplateId: UUID) async -> Bool {
        guard let patientId = client.userId else {
            return false
        }

        do {
            let count: Int = try await client.client
                .from("video_watch_history")
                .select("id", head: true, count: .exact)
                .eq("patient_id", value: patientId)
                .eq("exercise_template_id", value: exerciseTemplateId.uuidString)
                .execute()
                .count ?? 0

            return count > 0
        } catch {
            ErrorLogger.shared.logError(error, context: "VideoAnalyticsService.hasWatched")
            return false
        }
    }

    /// Get total watch time for the current user (in minutes)
    /// - Returns: Total minutes watched
    func getTotalWatchTime() async -> Int {
        guard let patientId = client.userId else {
            return 0
        }

        do {
            // Use RPC for efficient server-side aggregation
            let params = GetTotalWatchTimeParams(pPatientId: patientId)
            let result: Int = try await client.client
                .rpc("get_total_watch_time", params: params)
                .single()
                .execute()
                .value

            return result / 60  // Convert seconds to minutes
        } catch {
            ErrorLogger.shared.logError(error, context: "VideoAnalyticsService.getTotalWatchTime")
            return 0
        }
    }
}

// MARK: - Insert/Update Models

private struct WatchEventInsert: Encodable {
    let patientId: String
    let exerciseTemplateId: String
    let watchDurationSeconds: Int
    let completed: Bool
    let qualityUsed: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case exerciseTemplateId = "exercise_template_id"
        case watchDurationSeconds = "watch_duration_seconds"
        case completed
        case qualityUsed = "quality_used"
    }
}

private struct WatchEventUpdate: Encodable {
    let watchDurationSeconds: Int
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case watchDurationSeconds = "watch_duration_seconds"
        case completed
    }
}

// MARK: - Errors

enum VideoAnalyticsError: LocalizedError {
    case noAuthenticatedUser
    case loggingFailed(Error)
    case updateFailed(Error)
    case fetchFailed(Error)
    case statisticsFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user"
        case .loggingFailed:
            return "Failed to log video event"
        case .updateFailed:
            return "Failed to update watch record"
        case .fetchFailed:
            return "Failed to load watch history"
        case .statisticsFailed:
            return "Failed to load video statistics"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noAuthenticatedUser:
            return "Please sign in to track video history."
        case .loggingFailed:
            return "Your video progress couldn't be saved, but you can continue watching."
        case .updateFailed:
            return "Watch time couldn't be updated."
        case .fetchFailed:
            return "Please check your connection and try again."
        case .statisticsFailed:
            return "Video statistics couldn't be loaded."
        }
    }

    /// Whether the operation should be retried
    var shouldRetry: Bool {
        switch self {
        case .noAuthenticatedUser:
            return false
        case .loggingFailed, .updateFailed, .fetchFailed, .statisticsFailed:
            return true
        }
    }
}
