//
//  WorkoutPreloadService.swift
//  PTPerformance
//
//  ACP-502: Smart Workout Pre-Loading
//  Fetches today's workout data on app launch for instant access
//

import Foundation
import UIKit
import Combine

/// ACP-502: Service for pre-loading today's workout data
/// Triggers on app launch and when app becomes active
/// Caches session, exercises, and video thumbnails for instant display
@MainActor
final class WorkoutPreloadService: ObservableObject {

    // MARK: - Singleton

    static let shared = WorkoutPreloadService()

    // MARK: - Published Properties

    /// Whether preload is currently in progress
    @Published private(set) var isPreloading: Bool = false

    /// Last preload error (nil if successful)
    @Published private(set) var lastError: String?

    /// Time of last successful preload
    @Published private(set) var lastPreloadTime: Date?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let cache = PreloadedWorkoutCache.shared
    private let imageCache = ImageCacheService.shared
    private let logger = DebugLogger.shared

    /// Task tracking for deduplication
    private var preloadTask: Task<Void, Never>?

    /// Cancellables for observers
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupObservers()
        logger.log("[WorkoutPreloadService] Initialized", level: .diagnostic)
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Setup

    /// Setup observers for app lifecycle events
    private func setupObservers() {
        // Observe app becoming active to refresh cache
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.preloadIfNeeded()
                }
            }
            .store(in: &cancellables)

        // Observe authentication changes
        supabase.$userId
            .removeDuplicates()
            .sink { [weak self] userId in
                if userId != nil {
                    Task { @MainActor [weak self] in
                        await self?.preloadTodayWorkout()
                    }
                } else {
                    // User logged out - clear cache
                    self?.cache.clearAll()
                }
            }
            .store(in: &cancellables)

        logger.log("[WorkoutPreloadService] Observers configured", level: .diagnostic)
    }

    // MARK: - Public API

    /// Preload today's workout data on app launch
    /// Called from PTPerformanceApp.swift during initialization
    func preloadOnLaunch() async {
        logger.log("[WorkoutPreloadService] App launch preload triggered", level: .diagnostic)
        await preloadTodayWorkout()
    }

    /// Preload if cache is invalid or expired
    /// Called when app becomes active
    func preloadIfNeeded() async {
        guard !cache.isCacheValid else {
            logger.log("[WorkoutPreloadService] Cache still valid, skipping preload", level: .diagnostic)
            return
        }

        await preloadTodayWorkout()
    }

    /// Force a fresh preload (invalidates existing cache)
    func forceRefresh() async {
        cache.invalidate()
        await preloadTodayWorkout()
    }

    /// Invalidate cache (e.g., after workout completion)
    func invalidateCache() {
        cache.invalidate()
        logger.log("[WorkoutPreloadService] Cache invalidated by request", level: .diagnostic)
    }

    // MARK: - Core Preload Logic

    /// Main preload function - fetches session, exercises, and thumbnails
    func preloadTodayWorkout() async {
        // Cancel any existing preload task and wait for it to finish
        if let existingTask = preloadTask {
            existingTask.cancel()
            _ = await existingTask.value
        }

        // Reset preloading flag after cancellation
        isPreloading = false

        // Create new preload task
        preloadTask = Task { @MainActor in
            await performPreload()
        }

        // Wait for completion
        await preloadTask?.value
    }

    /// Internal preload implementation
    private func performPreload() async {
        guard let patientId = supabase.userId else {
            logger.log("[WorkoutPreloadService] No patient ID, skipping preload", level: .warning)
            return
        }

        // Double-check we're not already preloading (should be reset by caller)
        guard !isPreloading else {
            logger.log("[WorkoutPreloadService] Preload already in progress", level: .diagnostic)
            return
        }

        isPreloading = true
        lastError = nil

        logger.log("[WorkoutPreloadService] Starting preload for patient: \(patientId)", level: .diagnostic)

        do {
            // Check for cancellation
            try Task.checkCancellation()

            // Step 1: Fetch today's session
            let (session, sessionId) = try await fetchTodaySession(patientId: patientId)

            // Check for cancellation
            try Task.checkCancellation()

            // Step 2: Fetch exercises for session
            var exercises: [Exercise] = []
            if let sessionId = sessionId {
                exercises = try await fetchExercises(sessionId: sessionId)
            }

            // Check for cancellation
            try Task.checkCancellation()

            // Step 3: Pre-download video thumbnails
            await preloadThumbnails(exercises: exercises)

            // Store in cache
            cache.store(session: session, exercises: exercises, patientId: patientId)

            lastPreloadTime = Date()
            lastError = nil

            logger.log("[WorkoutPreloadService] Preload complete! Session: \(session?.name ?? "none"), \(exercises.count) exercises", level: .success)

        } catch is CancellationError {
            logger.log("[WorkoutPreloadService] Preload cancelled", level: .warning)
        } catch {
            lastError = error.localizedDescription
            logger.log("[WorkoutPreloadService] Preload failed: \(error.localizedDescription)", level: .error)
        }

        isPreloading = false
    }

    // MARK: - Data Fetching

    /// Fetch today's scheduled session or first active session
    private func fetchTodaySession(patientId: String) async throws -> (Session?, String?) {
        // First, check for a scheduled session today
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

        // Try scheduled session first
        let scheduledResponse = try await supabase.client
            .from("scheduled_sessions")
            .select("session_id, status")
            .eq("patient_id", value: patientId)
            .eq("scheduled_date", value: String(today))
            .eq("status", value: "scheduled")
            .limit(1)
            .execute()

        struct ScheduledRow: Codable {
            let session_id: String
        }

        let scheduledSessions = try JSONDecoder().decode([ScheduledRow].self, from: scheduledResponse.data)

        if let scheduled = scheduledSessions.first {
            // Fetch the scheduled session details
            let sessionResponse = try await supabase.client
                .from("sessions")
                .select("*")
                .eq("id", value: scheduled.session_id)
                .limit(1)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sessions = try decoder.decode([Session].self, from: sessionResponse.data)

            if let session = sessions.first {
                logger.log("[WorkoutPreloadService] Found scheduled session: \(session.name)", level: .diagnostic)
                return (session, session.id.uuidString)
            }
        }

        // Fallback: Get first active session from program
        let response = try await supabase.client
            .from("sessions")
            .select("""
                *,
                phases!inner(
                    id,
                    name,
                    program_id,
                    programs!inner(
                        id,
                        name,
                        patient_id,
                        status
                    )
                )
            """)
            .eq("phases.programs.patient_id", value: patientId)
            .eq("phases.programs.status", value: "active")
            .order("sequence", ascending: true)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sessions = try decoder.decode([Session].self, from: response.data)

        if let session = sessions.first {
            logger.log("[WorkoutPreloadService] Found program session: \(session.name)", level: .diagnostic)
            return (session, session.id.uuidString)
        }

        logger.log("[WorkoutPreloadService] No session found for today", level: .diagnostic)
        return (nil, nil)
    }

    /// Fetch exercises for a session
    private func fetchExercises(sessionId: String) async throws -> [Exercise] {
        let response = try await supabase.client
            .from("session_exercises")
            .select("""
                *,
                exercise_templates!inner(
                    id,
                    name,
                    category,
                    body_region,
                    video_url,
                    video_thumbnail_url,
                    video_duration,
                    technique_cues,
                    common_mistakes,
                    safety_notes
                )
            """)
            .eq("session_id", value: sessionId)
            .order("sequence", ascending: true)
            .order("created_at", ascending: true)
            .order("id", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exercises = try decoder.decode([Exercise].self, from: response.data)

        logger.log("[WorkoutPreloadService] Fetched \(exercises.count) exercises", level: .diagnostic)
        return exercises
    }

    // MARK: - Thumbnail Preloading

    /// Validates that a URL is suitable for thumbnail preloading
    /// Filters out malformed URLs, placeholder values, and unreachable hosts
    private func isValidThumbnailURL(_ url: URL) -> Bool {
        // Must have https scheme
        guard url.scheme == "https" else { return false }

        // Must have a valid host
        guard let host = url.host, !host.isEmpty else { return false }

        // Filter out placeholder or malformed hostnames
        let invalidHostPatterns = [
            "example.com",
            "placeholder",
            "localhost",
            "127.0.0.1",
            ".local",
            "your-",
            "undefined",
            "null"
        ]

        let lowercaseHost = host.lowercased()
        for pattern in invalidHostPatterns {
            if lowercaseHost.contains(pattern) {
                return false
            }
        }

        // Must have a path (not just root)
        guard url.path.count > 1 else { return false }

        // Validate common CDN/storage hosts
        let validHostPatterns = [
            "supabase.co",
            "supabase.in",
            "cloudfront.net",
            "amazonaws.com",
            "storage.googleapis.com",
            "cloudinary.com",
            "imgix.net",
            "cdn.ptperformance"
        ]

        // If host matches a known valid pattern, accept it
        for pattern in validHostPatterns {
            if lowercaseHost.contains(pattern) {
                return true
            }
        }

        // For unknown hosts, at least require a proper TLD
        let components = lowercaseHost.components(separatedBy: ".")
        guard components.count >= 2,
              let tld = components.last,
              tld.count >= 2 && tld.count <= 6 else {
            return false
        }

        return true
    }

    /// Pre-download video thumbnails for all exercises
    private func preloadThumbnails(exercises: [Exercise]) async {
        let thumbnailURLs = exercises.compactMap { exercise -> URL? in
            guard let urlString = exercise.exercise_templates?.videoThumbnailUrl,
                  !urlString.isEmpty,
                  let url = URL(string: urlString),
                  isValidThumbnailURL(url) else {
                return nil
            }
            return url
        }

        guard !thumbnailURLs.isEmpty else {
            logger.log("[WorkoutPreloadService] No thumbnails to preload", level: .diagnostic)
            return
        }

        logger.log("[WorkoutPreloadService] Preloading \(thumbnailURLs.count) thumbnails...", level: .diagnostic)

        // Use TaskGroup for parallel thumbnail loading
        await withTaskGroup(of: Void.self) { group in
            for url in thumbnailURLs {
                group.addTask { [weak self] in
                    await self?.preloadSingleThumbnail(url: url)
                }
            }
        }

        logger.log("[WorkoutPreloadService] Thumbnail preload complete", level: .success)
    }

    /// Preload a single thumbnail
    private func preloadSingleThumbnail(url: URL) async {
        // Check if already in our cache
        if cache.hasThumbnail(for: url.absoluteString) {
            return
        }

        do {
            // Use ImageCacheService for download and disk caching
            let image = try await imageCache.loadImage(from: url)

            // Also store in our memory cache for instant access
            await MainActor.run {
                cache.storeThumbnail(image, for: url.absoluteString)
            }
        } catch {
            logger.log("[WorkoutPreloadService] Failed to preload thumbnail: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: - Debug

    /// Get preload status for debugging
    var statusDescription: String {
        let preloading = isPreloading ? "Yes" : "No"
        let lastTime = lastPreloadTime?.formatted() ?? "Never"
        let error = lastError ?? "None"
        let cacheValid = cache.isCacheValid ? "Yes" : "No"

        return """
        [WorkoutPreloadService Status]
        - Preloading: \(preloading)
        - Last Preload: \(lastTime)
        - Last Error: \(error)
        - Cache Valid: \(cacheValid)
        \(cache.cacheStats)
        """
    }
}
