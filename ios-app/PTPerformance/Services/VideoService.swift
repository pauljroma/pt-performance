//
//  VideoService.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 4
//  Service for loading and caching exercise videos
//

import Foundation
import AVFoundation

/// Service for managing exercise video loading and caching
class VideoService {

    // MARK: - Singleton

    static let shared = VideoService()

    private init() {}

    // MARK: - Dependencies

    private let cache = URLCache.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Video Loading

    /// Load a video from URL with caching
    /// - Parameter url: The video URL
    /// - Returns: Cached or remote URL for AVPlayer
    func loadVideo(from url: URL) async throws -> URL {
        // For remote videos, just return the URL
        // AVPlayer handles its own caching
        return url

        // TODO: Implement local caching for offline playback
        // For now, rely on AVPlayer's built-in caching
    }

    /// Preload a video for offline viewing
    /// - Parameter url: The video URL
    func preloadVideo(from url: URL) async throws {
        // Use AVAssetDownloadTask for HLS videos
        // or URLSession.shared.downloadTask for MP4s

        // TODO: Implement download and local storage
        // For now, this is a placeholder
    }

    /// Check if a video is cached locally
    /// - Parameter url: The video URL
    /// - Returns: Whether the video is available offline
    func isVideoCached(url: URL) -> Bool {
        // TODO: Check local storage
        return false
    }

    /// Delete cached video
    /// - Parameter url: The video URL
    func deleteCachedVideo(url: URL) throws {
        // TODO: Remove from local storage
    }

    /// Get total cache size
    /// - Returns: Cache size in bytes
    func getCacheSize() -> Int64 {
        // TODO: Calculate total video cache size
        return 0
    }

    /// Clear all cached videos
    func clearCache() throws {
        // TODO: Remove all cached videos
    }

    // MARK: - Video Logging

    /// Log that a patient viewed a video
    /// - Parameters:
    ///   - exerciseId: Exercise UUID
    ///   - patientId: Patient UUID
    ///   - watchDuration: How long they watched (seconds)
    ///   - completed: Whether they watched to the end
    func logVideoView(
        exerciseId: String,
        patientId: String,
        watchDuration: Int?,
        completed: Bool
    ) async throws {
        // TODO: Call Supabase log_video_view function
        let supabase = PTSupabaseClient.shared.client

        do {
            _ = try await supabase
                .rpc("log_video_view", params: [
                    "p_patient_id": patientId,
                    "p_exercise_id": exerciseId,
                    "p_watch_duration": watchDuration as Any,
                    "p_completed": completed
                ])
                .execute()
        } catch {
            errorLogger.logError(
                error,
                context: "VideoService.logVideoView",
                metadata: [
                    "exercise_id": exerciseId,
                    "patient_id": patientId
                ]
            )
            throw VideoError.loggingFailed(error)
        }
    }

    /// Fetch video statistics for an exercise
    /// - Parameter exerciseId: Exercise UUID
    /// - Returns: Video statistics
    func fetchVideoStats(for exerciseId: String) async throws -> VideoStats {
        let supabase = PTSupabaseClient.shared.client

        do {
            let stats: VideoStats = try await supabase
                .from("exercise_video_stats")
                .select()
                .eq("exercise_id", value: exerciseId)
                .single()
                .execute()
                .value

            return stats
        } catch {
            errorLogger.logError(
                error,
                context: "VideoService.fetchVideoStats",
                metadata: ["exercise_id": exerciseId]
            )
            throw VideoError.fetchFailed(error)
        }
    }
}

// MARK: - Supporting Types

/// Video statistics from database view
struct VideoStats: Codable {
    let exerciseId: String
    let exerciseName: String
    let videoUrl: String?
    let videoDuration: Int?
    let totalViewers: Int
    let totalViews: Int
    let completedViews: Int
    let completionRate: Double
    let avgWatchDuration: Double?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case videoUrl = "video_url"
        case videoDuration = "video_duration"
        case totalViewers = "total_viewers"
        case totalViews = "total_views"
        case completedViews = "completed_views"
        case completionRate = "completion_rate"
        case avgWatchDuration = "avg_watch_duration"
    }

    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate * 100)
    }
}

/// Video service errors
enum VideoError: LocalizedError {
    case loggingFailed(Error)
    case fetchFailed(Error)
    case downloadFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .loggingFailed:
            return "Failed to log video view"
        case .fetchFailed:
            return "Failed to fetch video statistics"
        case .downloadFailed:
            return "Failed to download video"
        case .notFound:
            return "Video not found"
        }
    }
}
