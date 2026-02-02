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

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("VideoCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Properties

    private let cache = URLCache.shared
    private let errorLogger = ErrorLogger.shared
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 500_000_000  // 500MB (videos are larger)

    // MARK: - Video Loading

    /// Load a video from URL with caching
    /// - Parameter url: The video URL
    /// - Returns: Cached or remote URL for AVPlayer
    func loadVideo(from url: URL) async throws -> URL {
        // Check disk cache first
        let cachedURL = cacheFileURL(for: url)
        if fileManager.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        // Not cached — return remote URL; AVPlayer handles streaming
        return url
    }

    /// Preload a video for offline viewing
    /// - Parameter url: The video URL
    func preloadVideo(from url: URL) async throws {
        let cachedURL = cacheFileURL(for: url)

        // Skip if already cached
        guard !fileManager.fileExists(atPath: cachedURL.path) else { return }

        // Download video data
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VideoError.downloadFailed(
                NSError(domain: "VideoService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Download returned non-200 status"])
            )
        }

        // Save to disk cache
        try data.write(to: cachedURL)

        // Check cache size and cleanup if over limit
        let currentSize = getCacheSize()
        if currentSize > maxCacheSize {
            cleanupOldCache()
        }
    }

    /// Check if a video is cached locally
    /// - Parameter url: The video URL
    /// - Returns: Whether the video is available offline
    func isVideoCached(url: URL) -> Bool {
        let cachedURL = cacheFileURL(for: url)
        return fileManager.fileExists(atPath: cachedURL.path)
    }

    /// Delete cached video
    /// - Parameter url: The video URL
    func deleteCachedVideo(url: URL) throws {
        let cachedURL = cacheFileURL(for: url)
        if fileManager.fileExists(atPath: cachedURL.path) {
            try fileManager.removeItem(at: cachedURL)
        }
    }

    /// Get total cache size
    /// - Returns: Cache size in bytes
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }

    /// Clear all cached videos
    func clearCache() throws {
        try fileManager.removeItem(at: cacheDirectory)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Private Helpers

    private func cacheFileURL(for url: URL) -> URL {
        let filename = String(url.absoluteString.hashValue)
        return cacheDirectory.appendingPathComponent(filename)
    }

    private func cleanupOldCache() {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return
        }

        var files: [(url: URL, date: Date, size: Int64)] = []

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let date = values.contentModificationDate,
               let size = values.fileSize {
                files.append((url: fileURL, date: date, size: Int64(size)))
            }
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        // Remove oldest files until under the limit
        var currentSize = files.reduce(0) { $0 + $1.size }

        for file in files {
            if currentSize <= maxCacheSize {
                break
            }
            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
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

/// Video service errors with user-friendly messages
enum VideoError: LocalizedError {
    case loggingFailed(Error)
    case fetchFailed(Error)
    case downloadFailed(Error)
    case notFound
    case playbackFailed

    // MARK: - User-Friendly Error Titles

    var errorDescription: String? {
        switch self {
        case .loggingFailed:
            return "Video Tracking Issue"
        case .fetchFailed:
            return "Couldn't Load Video"
        case .downloadFailed:
            return "Video Download Issue"
        case .notFound:
            return "Video Unavailable"
        case .playbackFailed:
            return "Playback Issue"
        }
    }

    // MARK: - User-Friendly Recovery Suggestions

    var recoverySuggestion: String? {
        switch self {
        case .loggingFailed:
            return "Your video progress couldn't be saved, but you can keep watching."
        case .fetchFailed:
            return "We couldn't load the video right now. Please check your connection and try again."
        case .downloadFailed:
            return "The video couldn't be downloaded. Please check your connection and try again."
        case .notFound:
            return "This exercise video is no longer available. Please contact your therapist for guidance."
        case .playbackFailed:
            return "There was a problem playing this video. Please try again."
        }
    }

    // MARK: - Retry Logic

    var shouldRetry: Bool {
        switch self {
        case .loggingFailed, .fetchFailed, .downloadFailed, .playbackFailed:
            return true
        case .notFound:
            return false
        }
    }
}
