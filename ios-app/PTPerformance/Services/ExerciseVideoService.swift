//
//  ExerciseVideoService.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Video service with offline caching
//  Features: Fetch videos, cache for offline, preload upcoming exercises
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for logging detailed video view
private struct LogDetailedVideoViewParams: Encodable {
    let pPatientId: String
    let pExerciseId: String
    let pVideoId: String
    let pWatchDuration: String
    let pCompleted: String
    let pPlaybackSpeed: String
    let pAngleWatched: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pExerciseId = "p_exercise_id"
        case pVideoId = "p_video_id"
        case pWatchDuration = "p_watch_duration"
        case pCompleted = "p_completed"
        case pPlaybackSpeed = "p_playback_speed"
        case pAngleWatched = "p_angle_watched"
    }
}

/// RPC parameters for logging video cached
private struct LogVideoCachedParams: Encodable {
    let pPatientId: String
    let pVideoId: String
    let pCacheSizeBytes: String
    let pContentHash: String
    let pDeviceIdentifier: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pVideoId = "p_video_id"
        case pCacheSizeBytes = "p_cache_size_bytes"
        case pContentHash = "p_content_hash"
        case pDeviceIdentifier = "p_device_identifier"
    }
}

/// Service for managing exercise video loading, caching, and preloading
@MainActor
class ExerciseVideoService: ObservableObject {

    // MARK: - Singleton

    static let shared = ExerciseVideoService()

    // MARK: - Published Properties

    @Published private(set) var isLoading = false
    @Published private(set) var cacheProgress: Double = 0
    @Published private(set) var cacheSizeBytes: Int64 = 0
    @Published private(set) var cachedVideoCount: Int = 0

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    // FileManager and cacheDirectory are safe to access from any context (immutable after init)
    nonisolated(unsafe) private let fileManager = FileManager.default
    nonisolated(unsafe) private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 1_000_000_000 // 1 GB for HD videos
    private let preloadQueue = OperationQueue()
    private var preloadTasks: [UUID: Task<Void, Never>] = [:]

    // Device identifier for cache tracking
    private var deviceIdentifier: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Initialization

    private init() {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("ExerciseVideos", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure preload queue
        preloadQueue.maxConcurrentOperationCount = 2
        preloadQueue.qualityOfService = .utility

        // Calculate initial cache size
        Task {
            await refreshCacheStats()
        }
    }

    // MARK: - Fetch Videos

    /// Fetch all videos for an exercise
    /// - Parameter exerciseId: The exercise UUID
    /// - Returns: Array of ExerciseVideo objects
    func fetchVideos(exerciseId: UUID) async throws -> [ExerciseVideo] {
        isLoading = true
        defer { isLoading = false }

        do {
            let videos: [ExerciseVideo] = try await supabase.client
                .from("exercise_videos")
                .select()
                .eq("exercise_id", value: exerciseId.uuidString)
                .order("is_primary", ascending: false)
                .execute()
                .value

            return videos.sorted { $0.angle.sortOrder < $1.angle.sortOrder }
        } catch {
            ErrorLogger.shared.logError(
                error,
                context: "ExerciseVideoService.fetchVideos - exercise_id: \(exerciseId.uuidString)"
            )
            throw ExerciseVideoError.fetchFailed(error)
        }
    }

    /// Fetch primary video for an exercise
    /// - Parameter exerciseId: The exercise UUID
    /// - Returns: Primary ExerciseVideo if available
    func fetchPrimaryVideo(exerciseId: UUID) async throws -> ExerciseVideo? {
        do {
            let videos: [ExerciseVideo] = try await supabase.client
                .from("exercise_videos")
                .select()
                .eq("exercise_id", value: exerciseId.uuidString)
                .eq("is_primary", value: true)
                .limit(1)
                .execute()
                .value

            return videos.first
        } catch {
            ErrorLogger.shared.logError(
                error,
                context: "ExerciseVideoService.fetchPrimaryVideo - exercise_id: \(exerciseId.uuidString)"
            )
            throw ExerciseVideoError.fetchFailed(error)
        }
    }

    /// Fetch video collection for an exercise with all angles
    /// - Parameters:
    ///   - exerciseId: The exercise UUID
    ///   - exerciseName: The exercise name
    /// - Returns: ExerciseVideoCollection with all videos
    func fetchVideoCollection(exerciseId: UUID, exerciseName: String) async throws -> ExerciseVideoCollection {
        let videos = try await fetchVideos(exerciseId: exerciseId)
        let primaryVideo = videos.first { $0.isPrimary } ?? videos.first

        return ExerciseVideoCollection(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            videos: videos,
            primaryVideo: primaryVideo
        )
    }

    // MARK: - Video Caching

    /// Cache a video for offline viewing
    /// - Parameter video: The video to cache
    /// - Returns: Local file URL
    @discardableResult
    func cacheVideo(_ video: ExerciseVideo) async throws -> URL {
        guard let remoteUrl = video.url else {
            throw ExerciseVideoError.invalidUrl
        }

        let localUrl = cacheFileUrl(for: video)

        // Check if already cached with same hash
        if fileManager.fileExists(atPath: localUrl.path) {
            if let cachedHash = getCachedHash(for: video.id),
               cachedHash == video.contentHash {
                return localUrl
            }
            // Hash mismatch - delete and re-download
            try? fileManager.removeItem(at: localUrl)
        }

        // Check cache size before downloading
        await ensureCacheSpace(for: video.fileSizeBytes ?? 50_000_000)

        // Download video
        cacheProgress = 0
        let (tempUrl, _) = try await URLSession.shared.download(from: remoteUrl)

        // Move to cache directory
        try fileManager.moveItem(at: tempUrl, to: localUrl)

        // Store metadata
        saveCacheMetadata(for: video, localPath: localUrl.path)

        // Update cache stats
        await refreshCacheStats()

        // Log to backend
        try? await logVideoCached(video: video, localUrl: localUrl)

        return localUrl
    }

    /// Check if a video is cached locally
    /// - Parameter video: The video to check
    /// - Returns: True if cached and valid
    func isVideoCached(_ video: ExerciseVideo) -> Bool {
        let localUrl = cacheFileUrl(for: video)
        guard fileManager.fileExists(atPath: localUrl.path) else {
            return false
        }

        // Verify hash if available
        if let remoteHash = video.contentHash,
           let cachedHash = getCachedHash(for: video.id) {
            return remoteHash == cachedHash
        }

        return true
    }

    /// Get local URL for a video (cached or remote)
    /// - Parameter video: The video
    /// - Returns: Local cached URL or remote URL
    func getVideoUrl(_ video: ExerciseVideo) -> URL? {
        if isVideoCached(video) {
            return cacheFileUrl(for: video)
        }
        return video.url
    }

    /// Delete a cached video
    /// - Parameter video: The video to delete
    func deleteCachedVideo(_ video: ExerciseVideo) throws {
        let localUrl = cacheFileUrl(for: video)
        if fileManager.fileExists(atPath: localUrl.path) {
            try fileManager.removeItem(at: localUrl)
            deleteCacheMetadata(for: video.id)
        }
        Task {
            await refreshCacheStats()
        }
    }

    /// Clear all cached videos
    func clearCache() throws {
        try fileManager.removeItem(at: cacheDirectory)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        clearAllCacheMetadata()
        Task {
            await refreshCacheStats()
        }
    }

    // MARK: - Preloading

    /// Preload videos for upcoming exercises in a session
    /// - Parameters:
    ///   - exerciseIds: Array of exercise UUIDs
    ///   - priority: Whether to prioritize primary videos only
    func preloadNextExercises(_ exerciseIds: [UUID], primaryOnly: Bool = true) {
        // Cancel any existing preload tasks
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()

        for exerciseId in exerciseIds {
            let task = Task {
                do {
                    if primaryOnly {
                        if let video = try await fetchPrimaryVideo(exerciseId: exerciseId) {
                            if !isVideoCached(video) {
                                try await cacheVideo(video)
                            }
                        }
                    } else {
                        let videos = try await fetchVideos(exerciseId: exerciseId)
                        for video in videos where !isVideoCached(video) {
                            try await cacheVideo(video)
                        }
                    }
                } catch {
                    // Preload failures are non-critical
                    DebugLogger.shared.log(
                        "Preload failed for exercise \(exerciseId): \(error.localizedDescription)",
                        level: .warning
                    )
                }
            }
            preloadTasks[exerciseId] = task
        }
    }

    /// Cancel all preloading
    func cancelPreloading() {
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
    }

    // MARK: - Video View Logging

    /// Log a video view to the backend
    /// - Parameters:
    ///   - video: The video that was viewed
    ///   - patientId: The patient who viewed it
    ///   - watchDuration: How long they watched
    ///   - completed: Whether they watched to the end
    ///   - playbackSpeed: The playback speed used
    func logVideoView(
        video: ExerciseVideo,
        patientId: UUID,
        watchDuration: Int?,
        completed: Bool,
        playbackSpeed: PlaybackSpeed = .normal
    ) async throws {
        do {
            let params = LogDetailedVideoViewParams(
                pPatientId: patientId.uuidString,
                pExerciseId: video.exerciseId.uuidString,
                pVideoId: video.id.uuidString,
                pWatchDuration: String(watchDuration ?? 0),
                pCompleted: String(completed),
                pPlaybackSpeed: String(playbackSpeed.rawValue),
                pAngleWatched: video.angle.rawValue
            )
            _ = try await supabase.client
                .rpc("log_detailed_video_view", params: params)
                .execute()
        } catch {
            ErrorLogger.shared.logError(
                error,
                context: "ExerciseVideoService.logVideoView - video_id: \(video.id.uuidString), patient_id: \(patientId.uuidString)"
            )
            // Don't throw - logging failures shouldn't interrupt the user
        }
    }

    // MARK: - Cache Management

    /// Refresh cache statistics
    func refreshCacheStats() async {
        // Collect file stats synchronously to avoid async iterator issues
        let stats = calculateCacheStats()
        cacheSizeBytes = stats.totalSize
        cachedVideoCount = stats.count
    }

    /// Calculate cache statistics synchronously
    private nonisolated func calculateCacheStats() -> (totalSize: Int64, count: Int) {
        var totalSize: Int64 = 0
        var count = 0

        if let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            for case let fileUrl as URL in enumerator {
                if let fileSize = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                    count += 1
                }
            }
        }

        return (totalSize, count)
    }

    /// Get cache size formatted string
    var cacheSizeDisplay: String {
        let megabytes = Double(cacheSizeBytes) / 1_000_000
        if megabytes >= 1000 {
            return String(format: "%.1f GB", megabytes / 1000)
        } else {
            return String(format: "%.0f MB", megabytes)
        }
    }

    /// Get max cache size formatted string
    var maxCacheSizeDisplay: String {
        let megabytes = Double(maxCacheSize) / 1_000_000
        return String(format: "%.0f MB", megabytes)
    }

    /// Cache utilization percentage
    var cacheUtilization: Double {
        Double(cacheSizeBytes) / Double(maxCacheSize)
    }

    // MARK: - Private Helpers

    private func cacheFileUrl(for video: ExerciseVideo) -> URL {
        let filename = "\(video.id.uuidString).\(video.resolution.rawValue).mp4"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Collect cache files with metadata synchronously (sorted oldest first)
    private nonisolated func collectCacheFiles() -> [(url: URL, date: Date, size: Int64)] {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return []
        }

        var files: [(url: URL, date: Date, size: Int64)] = []

        for case let fileUrl as URL in enumerator {
            if let values = try? fileUrl.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let date = values.contentModificationDate,
               let size = values.fileSize {
                files.append((url: fileUrl, date: date, size: Int64(size)))
            }
        }

        // Sort by date (oldest first)
        return files.sorted { $0.date < $1.date }
    }

    private func ensureCacheSpace(for requiredBytes: Int64) async {
        let availableSpace = maxCacheSize - cacheSizeBytes

        if requiredBytes > availableSpace {
            // Need to clear old videos
            await cleanupOldCache(targetFreeBytes: requiredBytes)
        }
    }

    private func cleanupOldCache(targetFreeBytes: Int64) async {
        // Collect files synchronously to avoid async iterator issues
        let files = collectCacheFiles()

        // Remove oldest files until we have enough space
        var freedBytes: Int64 = 0
        for file in files {
            if freedBytes >= targetFreeBytes {
                break
            }
            try? fileManager.removeItem(at: file.url)
            freedBytes += file.size

            // Also delete metadata
            if let videoId = UUID(uuidString: file.url.deletingPathExtension().lastPathComponent.components(separatedBy: ".").first ?? "") {
                deleteCacheMetadata(for: videoId)
            }
        }

        await refreshCacheStats()
    }

    // MARK: - Cache Metadata Storage

    private var metadataUrl: URL {
        cacheDirectory.appendingPathComponent("cache_metadata.json")
    }

    private func saveCacheMetadata(for video: ExerciseVideo, localPath: String) {
        var metadata = loadAllCacheMetadata()
        metadata[video.id.uuidString] = VideoCacheMetadata(
            videoId: video.id,
            contentHash: video.contentHash,
            cachedAt: Date(),
            localPath: localPath
        )
        saveAllCacheMetadata(metadata)
    }

    private func getCachedHash(for videoId: UUID) -> String? {
        let metadata = loadAllCacheMetadata()
        return metadata[videoId.uuidString]?.contentHash
    }

    private func deleteCacheMetadata(for videoId: UUID) {
        var metadata = loadAllCacheMetadata()
        metadata.removeValue(forKey: videoId.uuidString)
        saveAllCacheMetadata(metadata)
    }

    private func clearAllCacheMetadata() {
        try? fileManager.removeItem(at: metadataUrl)
    }

    private func loadAllCacheMetadata() -> [String: VideoCacheMetadata] {
        guard let data = try? Data(contentsOf: metadataUrl),
              let metadata = try? JSONDecoder().decode([String: VideoCacheMetadata].self, from: data) else {
            return [:]
        }
        return metadata
    }

    private func saveAllCacheMetadata(_ metadata: [String: VideoCacheMetadata]) {
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataUrl)
        }
    }

    private func logVideoCached(video: ExerciseVideo, localUrl: URL) async throws {
        guard let patientIdString = PTSupabaseClient.shared.userId,
              let patientId = UUID(uuidString: patientIdString) else { return }

        let fileSize = (try? fileManager.attributesOfItem(atPath: localUrl.path)[.size] as? Int64) ?? 0

        let params = LogVideoCachedParams(
            pPatientId: patientId.uuidString,
            pVideoId: video.id.uuidString,
            pCacheSizeBytes: String(fileSize),
            pContentHash: video.contentHash ?? "",
            pDeviceIdentifier: deviceIdentifier
        )
        _ = try await supabase.client
            .rpc("log_video_cached", params: params)
            .execute()
    }
}

// MARK: - Supporting Types

private struct VideoCacheMetadata: Codable {
    let videoId: UUID
    let contentHash: String?
    let cachedAt: Date
    let localPath: String
}

// MARK: - Errors

enum ExerciseVideoError: LocalizedError {
    case fetchFailed(Error)
    case cacheFailed(Error)
    case invalidUrl
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to Load Videos"
        case .cacheFailed:
            return "Unable to Save Video"
        case .invalidUrl:
            return "Invalid Video URL"
        case .notFound:
            return "Video Not Found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your internet connection and try again."
        case .cacheFailed:
            return "There may not be enough storage space. Try clearing some cached videos."
        case .invalidUrl:
            return "The video URL is invalid. Please contact support."
        case .notFound:
            return "This video is no longer available."
        }
    }
}
