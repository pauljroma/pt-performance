//
//  PreloadedWorkoutCache.swift
//  PTPerformance
//
//  ACP-502: Smart Workout Pre-Loading
//  In-memory cache for instant access to today's workout data
//

import Foundation
import UIKit

/// Cached workout data for instant UI display
struct CachedWorkoutData: Codable {
    let session: Session?
    let exercises: [Exercise]
    let cachedAt: Date
    let patientId: String

    /// Check if cache is still valid (less than 5 minutes old)
    var isValid: Bool {
        let cacheLifetime: TimeInterval = 5 * 60 // 5 minutes
        return Date().timeIntervalSince(cachedAt) < cacheLifetime
    }

    /// Check if cache was created today
    var isTodayCache: Bool {
        Calendar.current.isDateInToday(cachedAt)
    }
}

/// ACP-502: In-memory cache for preloaded workout data
/// Provides instant access to today's session without loading states
@MainActor
final class PreloadedWorkoutCache: ObservableObject {

    // MARK: - Singleton

    static let shared = PreloadedWorkoutCache()

    // MARK: - Published Properties

    /// Cached today's session data
    @Published private(set) var cachedSession: Session?

    /// Cached exercises for today's session
    @Published private(set) var cachedExercises: [Exercise] = []

    /// Whether cache has valid data ready
    @Published private(set) var isPreloaded: Bool = false

    /// Timestamp of last successful preload
    @Published private(set) var lastPreloadTime: Date?

    /// Patient ID for current cache
    @Published private(set) var cachedPatientId: String?

    // MARK: - Private Properties

    /// In-memory cache for video thumbnails (URL string -> UIImage)
    private var thumbnailCache: [String: UIImage] = [:]

    /// Maximum number of cached thumbnails
    private let maxThumbnailCacheSize = 20

    /// Cache validity duration (5 minutes)
    private let cacheValidityDuration: TimeInterval = 5 * 60

    private let logger = DebugLogger.shared

    // MARK: - Initialization

    private init() {
        // Clear cache on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        logger.log("[PreloadedWorkoutCache] Initialized", level: .diagnostic)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Cache Management

    /// Store preloaded workout data
    /// - Parameters:
    ///   - session: Today's session (nil if no workout today)
    ///   - exercises: Exercises for today's session
    ///   - patientId: Patient ID for cache validation
    func store(session: Session?, exercises: [Exercise], patientId: String) {
        self.cachedSession = session
        self.cachedExercises = exercises
        self.cachedPatientId = patientId
        self.lastPreloadTime = Date()
        self.isPreloaded = true

        logger.log("[PreloadedWorkoutCache] Stored session: \(session?.name ?? "nil"), \(exercises.count) exercises", level: .success)
    }

    /// Get cached data if valid
    /// - Parameter patientId: Patient ID to validate cache ownership
    /// - Returns: Tuple of session and exercises, or nil if cache invalid
    func getCachedData(for patientId: String) -> (session: Session?, exercises: [Exercise])? {
        guard isPreloaded,
              cachedPatientId == patientId,
              isCacheValid else {
            logger.log("[PreloadedWorkoutCache] Cache miss for patient \(patientId)", level: .diagnostic)
            return nil
        }

        logger.log("[PreloadedWorkoutCache] Cache hit! Returning \(cachedExercises.count) exercises", level: .success)
        return (cachedSession, cachedExercises)
    }

    /// Check if cache is valid (not expired and for today)
    var isCacheValid: Bool {
        guard let preloadTime = lastPreloadTime else { return false }

        // Cache must be from today
        guard Calendar.current.isDateInToday(preloadTime) else {
            logger.log("[PreloadedWorkoutCache] Cache invalid - not from today", level: .diagnostic)
            return false
        }

        // Cache must be within validity window
        let age = Date().timeIntervalSince(preloadTime)
        guard age < cacheValidityDuration else {
            logger.log("[PreloadedWorkoutCache] Cache expired (age: \(Int(age))s)", level: .diagnostic)
            return false
        }

        return true
    }

    /// Invalidate cache (e.g., after completing a workout)
    func invalidate() {
        cachedSession = nil
        cachedExercises = []
        cachedPatientId = nil
        lastPreloadTime = nil
        isPreloaded = false

        logger.log("[PreloadedWorkoutCache] Cache invalidated", level: .diagnostic)
    }

    /// Clear all cached data including thumbnails
    func clearAll() {
        invalidate()
        thumbnailCache.removeAll()

        logger.log("[PreloadedWorkoutCache] All caches cleared", level: .diagnostic)
    }

    // MARK: - Thumbnail Cache

    /// Store a preloaded video thumbnail
    /// - Parameters:
    ///   - image: The thumbnail image
    ///   - urlString: URL string as cache key
    func storeThumbnail(_ image: UIImage, for urlString: String) {
        // Enforce cache size limit
        if thumbnailCache.count >= maxThumbnailCacheSize {
            // Remove oldest entries (arbitrary - just remove first)
            if let firstKey = thumbnailCache.keys.first {
                thumbnailCache.removeValue(forKey: firstKey)
            }
        }

        thumbnailCache[urlString] = image
    }

    /// Get cached thumbnail
    /// - Parameter urlString: URL string as cache key
    /// - Returns: Cached UIImage or nil
    func getThumbnail(for urlString: String) -> UIImage? {
        return thumbnailCache[urlString]
    }

    /// Check if thumbnail is cached
    func hasThumbnail(for urlString: String) -> Bool {
        return thumbnailCache[urlString] != nil
    }

    /// Get all cached thumbnail URLs
    var cachedThumbnailURLs: [String] {
        return Array(thumbnailCache.keys)
    }

    // MARK: - Memory Management

    @objc private func handleMemoryWarning() {
        // Clear thumbnail cache on memory warning
        thumbnailCache.removeAll()
        logger.log("[PreloadedWorkoutCache] Cleared thumbnail cache due to memory warning", level: .warning)
    }

    // MARK: - Debug Info

    /// Get cache statistics for debugging
    var cacheStats: String {
        let sessionName = cachedSession?.name ?? "None"
        let exerciseCount = cachedExercises.count
        let thumbnailCount = thumbnailCache.count
        let ageSeconds = lastPreloadTime.map { Int(Date().timeIntervalSince($0)) } ?? -1
        let isValid = isCacheValid ? "Yes" : "No"

        return """
        [PreloadedWorkoutCache Stats]
        - Session: \(sessionName)
        - Exercises: \(exerciseCount)
        - Thumbnails: \(thumbnailCount)
        - Cache Age: \(ageSeconds)s
        - Valid: \(isValid)
        """
    }
}
