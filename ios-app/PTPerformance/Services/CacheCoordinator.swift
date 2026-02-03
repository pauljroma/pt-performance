//
//  CacheCoordinator.swift
//  PTPerformance
//
//  Unified cache management for coordinated memory cleanup
//  Responds to memory warnings and provides central cache control
//

import Foundation
import UIKit

/// Status information for all caches
struct CacheStatus {
    let imageCacheSizeBytes: Int64
    let videoCacheSizeBytes: Int64
    let workoutCacheValid: Bool
    let thumbnailCount: Int

    /// Total cache size in bytes
    var totalSizeBytes: Int64 {
        imageCacheSizeBytes + videoCacheSizeBytes
    }

    /// Formatted total size string
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }

    /// Formatted image cache size
    var formattedImageCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: imageCacheSizeBytes)
    }

    /// Formatted video cache size
    var formattedVideoCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: videoCacheSizeBytes)
    }
}

/// Central coordinator for all cache services
/// Provides unified memory management and cleanup
@MainActor
final class CacheCoordinator {

    // MARK: - Singleton

    static let shared = CacheCoordinator()

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private var memoryWarningObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupMemoryWarningObserver()
        logger.log("[CacheCoordinator] Initialized", level: .diagnostic)
    }

    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup

    /// Setup observer for system memory warnings
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMemoryWarning()
            }
        }

        logger.log("[CacheCoordinator] Memory warning observer configured", level: .diagnostic)
    }

    // MARK: - Memory Warning Handling

    /// Handle system memory warning by clearing all caches aggressively
    func handleMemoryWarning() {
        logger.log("[CacheCoordinator] Memory warning received - clearing caches", level: .warning)

        Task {
            await clearAllCaches(aggressive: true)
        }

        // Log the event for monitoring
        ErrorLogger.shared.logUserAction(
            action: "memory_warning_handled",
            properties: [
                "cleared_caches": "all",
                "aggressive": "true"
            ]
        )
    }

    // MARK: - Public API

    /// Clear all caches across the application
    /// - Parameter aggressive: If true, clears everything including valid workout data
    func clearAllCaches(aggressive: Bool = false) async {
        logger.log("[CacheCoordinator] Clearing all caches (aggressive: \(aggressive))", level: .diagnostic)

        // Clear ImageCacheService
        await ImageCacheService.shared.clearCache()
        logger.log("[CacheCoordinator] Cleared image cache", level: .diagnostic)

        // Clear VideoService cache
        do {
            try VideoService.shared.clearCache()
            logger.log("[CacheCoordinator] Cleared video cache", level: .diagnostic)
        } catch {
            logger.log("[CacheCoordinator] Failed to clear video cache: \(error.localizedDescription)", level: .error)
        }

        // Clear PreloadedWorkoutCache
        if aggressive {
            // Full clear including workout data
            PreloadedWorkoutCache.shared.clearAll()
            logger.log("[CacheCoordinator] Cleared workout cache (full)", level: .diagnostic)
        } else {
            // Only invalidate (keeps data but marks as needing refresh)
            PreloadedWorkoutCache.shared.invalidate()
            logger.log("[CacheCoordinator] Invalidated workout cache", level: .diagnostic)
        }

        // Invalidate WorkoutPreloadService cache reference
        WorkoutPreloadService.shared.invalidateCache()

        logger.log("[CacheCoordinator] All caches cleared", level: .success)
    }

    /// Clear only disk caches (images and videos) - preserves in-memory workout data
    func clearDiskCaches() async {
        logger.log("[CacheCoordinator] Clearing disk caches only", level: .diagnostic)

        await ImageCacheService.shared.clearCache()

        do {
            try VideoService.shared.clearCache()
        } catch {
            logger.log("[CacheCoordinator] Failed to clear video cache: \(error.localizedDescription)", level: .error)
        }

        logger.log("[CacheCoordinator] Disk caches cleared", level: .success)
    }

    /// Clear only in-memory caches - preserves disk caches
    func clearMemoryCaches() {
        logger.log("[CacheCoordinator] Clearing memory caches only", level: .diagnostic)

        PreloadedWorkoutCache.shared.clearAll()
        WorkoutPreloadService.shared.invalidateCache()

        logger.log("[CacheCoordinator] Memory caches cleared", level: .success)
    }

    /// Get current cache status across all services
    /// - Returns: CacheStatus with size information
    func getCacheStatus() async -> CacheStatus {
        let imageCacheSize = await ImageCacheService.shared.getCacheSize()
        let videoCacheSize = VideoService.shared.getCacheSize()
        let workoutCacheValid = PreloadedWorkoutCache.shared.isCacheValid
        let thumbnailCount = PreloadedWorkoutCache.shared.cachedThumbnailURLs.count

        return CacheStatus(
            imageCacheSizeBytes: imageCacheSize,
            videoCacheSizeBytes: videoCacheSize,
            workoutCacheValid: workoutCacheValid,
            thumbnailCount: thumbnailCount
        )
    }

    /// Get formatted description of cache status for debugging
    func getStatusDescription() async -> String {
        let status = await getCacheStatus()

        return """
        [CacheCoordinator Status]
        - Image Cache: \(status.formattedImageCacheSize)
        - Video Cache: \(status.formattedVideoCacheSize)
        - Total Disk: \(status.formattedTotalSize)
        - Workout Cache Valid: \(status.workoutCacheValid ? "Yes" : "No")
        - Cached Thumbnails: \(status.thumbnailCount)
        """
    }
}
