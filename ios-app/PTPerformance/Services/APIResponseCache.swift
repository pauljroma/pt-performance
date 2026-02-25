//
//  APIResponseCache.swift
//  PTPerformance
//
//  ACP-938: API Response Caching
//  Actor-based cache for Supabase API responses with configurable TTL,
//  stale-while-revalidate, ETag support, offline mode, and cache metrics.
//

import Foundation

// MARK: - Cache Entry

/// A single cached API response with metadata for freshness evaluation and invalidation.
struct APICacheEntry: Codable, Sendable {

    /// The cached response data (JSON-encoded).
    let data: Data

    /// The time this entry was stored.
    let cachedAt: Date

    /// The cache key that identifies this entry.
    let key: String

    /// Tags associated with this entry for bulk invalidation.
    let tags: Set<String>

    /// Priority level for eviction ordering (stored as raw value for Codable).
    let priorityRawValue: Int

    /// ETag from the server response, if available.
    let etag: String?

    /// The TTL that was in effect when this entry was created.
    let ttl: TimeInterval

    /// The stale-while-revalidate window that was in effect when created.
    let staleWhileRevalidateWindow: TimeInterval?

    /// Computed priority from the stored raw value.
    var priority: CachePriority {
        CachePriority(rawValue: priorityRawValue) ?? .normal
    }

    /// Age of this cache entry in seconds.
    var age: TimeInterval {
        Date().timeIntervalSince(cachedAt)
    }

    /// Evaluate freshness using the policy that was active when cached.
    var freshness: CacheFreshness {
        let currentAge = age
        if currentAge <= ttl {
            return .fresh
        }
        if let swr = staleWhileRevalidateWindow, currentAge <= (ttl + swr) {
            return .stale
        }
        return .expired
    }
}

// MARK: - Cache Metrics

/// Thread-safe metrics tracker for cache hit/miss rates and performance monitoring.
actor APICacheMetrics {

    // MARK: - Counters

    private var hits: Int = 0
    private var misses: Int = 0
    private var staleHits: Int = 0
    private var revalidations: Int = 0
    private var revalidationFailures: Int = 0
    private var evictions: Int = 0
    private var diskReads: Int = 0
    private var diskWrites: Int = 0
    private var offlineServes: Int = 0

    /// Per-key hit tracking for identifying hot and cold cache keys.
    private var keyHits: [String: Int] = [:]
    private var keyMisses: [String: Int] = [:]

    /// Rolling window of recent operation durations (last 100).
    private var recentFetchDurations: [TimeInterval] = []
    private let maxStoredDurations = 100

    // MARK: - Recording

    func recordHit(key: String) {
        hits += 1
        keyHits[key, default: 0] += 1
    }

    func recordMiss(key: String) {
        misses += 1
        keyMisses[key, default: 0] += 1
    }

    func recordStaleHit(key: String) {
        staleHits += 1
        keyHits[key, default: 0] += 1
    }

    func recordRevalidation(success: Bool) {
        revalidations += 1
        if !success {
            revalidationFailures += 1
        }
    }

    func recordEviction() {
        evictions += 1
    }

    func recordDiskRead() {
        diskReads += 1
    }

    func recordDiskWrite() {
        diskWrites += 1
    }

    func recordOfflineServe() {
        offlineServes += 1
    }

    func recordFetchDuration(_ duration: TimeInterval) {
        recentFetchDurations.append(duration)
        if recentFetchDurations.count > maxStoredDurations {
            recentFetchDurations.removeFirst(recentFetchDurations.count - maxStoredDurations)
        }
    }

    // MARK: - Queries

    /// Overall cache hit rate as a percentage (0.0 - 1.0).
    var hitRate: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits + staleHits) / Double(total + staleHits)
    }

    /// Generate a snapshot of all metrics.
    func snapshot() -> APICacheMetricsSnapshot {
        let total = hits + misses + staleHits
        let avgDuration: TimeInterval?
        if recentFetchDurations.isEmpty {
            avgDuration = nil
        } else {
            avgDuration = recentFetchDurations.reduce(0, +) / Double(recentFetchDurations.count)
        }

        return APICacheMetricsSnapshot(
            totalRequests: total,
            hits: hits,
            misses: misses,
            staleHits: staleHits,
            hitRate: hitRate,
            revalidations: revalidations,
            revalidationFailures: revalidationFailures,
            evictions: evictions,
            diskReads: diskReads,
            diskWrites: diskWrites,
            offlineServes: offlineServes,
            averageFetchDurationMs: avgDuration.map { $0 * 1000 },
            topHitKeys: topKeys(from: keyHits, limit: 5),
            topMissKeys: topKeys(from: keyMisses, limit: 5)
        )
    }

    /// Reset all metrics counters.
    func reset() {
        hits = 0
        misses = 0
        staleHits = 0
        revalidations = 0
        revalidationFailures = 0
        evictions = 0
        diskReads = 0
        diskWrites = 0
        offlineServes = 0
        keyHits.removeAll()
        keyMisses.removeAll()
        recentFetchDurations.removeAll()
    }

    // MARK: - Private

    private func topKeys(from dict: [String: Int], limit: Int) -> [CacheKeyCount] {
        dict.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { CacheKeyCount(key: $0.key, count: $0.value) }
    }
}

/// A cache key with its access count, used in metrics reporting.
struct CacheKeyCount: Sendable {
    let key: String
    let count: Int
}

/// Immutable snapshot of cache metrics for reporting.
struct APICacheMetricsSnapshot: Sendable {
    let totalRequests: Int
    let hits: Int
    let misses: Int
    let staleHits: Int
    let hitRate: Double
    let revalidations: Int
    let revalidationFailures: Int
    let evictions: Int
    let diskReads: Int
    let diskWrites: Int
    let offlineServes: Int
    let averageFetchDurationMs: Double?
    let topHitKeys: [CacheKeyCount]
    let topMissKeys: [CacheKeyCount]

    /// Human-readable report suitable for logging or debug display.
    var report: String {
        var output = "=== API Cache Metrics ===\n"
        output += "Total Requests: \(totalRequests)\n"
        output += "Hit Rate: \(String(format: "%.1f%%", hitRate * 100))\n"
        output += "  Fresh Hits: \(hits)\n"
        output += "  Stale Hits: \(staleHits)\n"
        output += "  Misses: \(misses)\n"
        output += "Revalidations: \(revalidations) (failures: \(revalidationFailures))\n"
        output += "Evictions: \(evictions)\n"
        output += "Disk I/O: \(diskReads) reads, \(diskWrites) writes\n"
        output += "Offline Serves: \(offlineServes)\n"
        if let avg = averageFetchDurationMs {
            output += "Avg Fetch Duration: \(String(format: "%.0f", avg))ms\n"
        }
        if !topHitKeys.isEmpty {
            output += "Top Hit Keys:\n"
            for item in topHitKeys {
                output += "  \(item.key): \(item.count)\n"
            }
        }
        if !topMissKeys.isEmpty {
            output += "Top Miss Keys:\n"
            for item in topMissKeys {
                output += "  \(item.key): \(item.count)\n"
            }
        }
        output += "========================="
        return output
    }
}

// MARK: - API Response Cache

/// Actor-based API response cache with memory + disk storage, TTL,
/// stale-while-revalidate, ETag support, and offline mode.
///
/// ## Overview
/// `APIResponseCache` sits between the app's services and the Supabase backend.
/// It caches JSON-encoded API responses using a two-tier storage strategy:
/// - **Memory (L1):** `NSCache`-backed fast lookup for hot data.
/// - **Disk (L2):** File-based persistent storage for offline access and app restarts.
///
/// ## Stale-While-Revalidate
/// When a cached entry is past its TTL but within the stale-while-revalidate window,
/// the cache returns the stale data immediately and triggers a background revalidation.
/// This provides instant perceived performance while keeping data fresh.
///
/// ## Thread Safety
/// All state is protected by the actor isolation boundary. The only shared mutable
/// state outside the actor is `NSCache`, which is internally thread-safe.
///
/// ## Usage
/// ```swift
/// let sessions: [Session] = try await APIResponseCache.shared.fetch(
///     key: "patient_123_sessions",
///     policy: .workoutSession
/// ) {
///     // This closure runs only on cache miss or revalidation
///     try await PTSupabaseClient.shared.client
///         .from("sessions")
///         .select()
///         .eq("patient_id", value: "123")
///         .execute()
///         .value
/// }
/// ```
actor APIResponseCache {

    // MARK: - Singleton

    static let shared = APIResponseCache()

    // MARK: - Configuration

    /// Maximum number of entries in the memory cache.
    private let maxMemoryEntries: Int = 200

    /// Maximum disk cache size in bytes (50 MB).
    private let maxDiskCacheBytes: Int64 = 50_000_000

    /// Subdirectory name within the system caches directory.
    private let diskCacheDirectoryName = "APIResponseCache"

    // MARK: - Storage

    /// In-memory cache (L1). NSCache provides automatic eviction under memory pressure.
    /// We wrap entries in `NSCacheEntryWrapper` because NSCache requires reference-type values.
    /// NSCache is thread-safe and only accessed within actor-isolated methods.
    nonisolated(unsafe) private let memoryCache = NSCache<NSString, NSCacheEntryWrapper>()

    /// Index of all cache entries by key. Used for tag-based lookups, eviction ordering,
    /// and iterating entries without hitting disk.
    private var entryIndex: [String: CacheEntryMetadata] = [:]

    /// Set of keys currently undergoing background revalidation, to prevent duplicate fetches.
    private var revalidatingKeys: Set<String> = []

    /// Disk cache directory URL.
    private let diskCacheDirectory: URL

    /// Metrics tracker.
    let metrics = APICacheMetrics()

    /// Shared JSON encoder for serializing cache entries.
    /// Uses ISO 8601 date encoding so APICacheEntry dates round-trip correctly
    /// with the ISO 8601 decoder used for disk reads.
    nonisolated(unsafe) private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    /// Shared JSON decoder for deserializing cache entries. Uses the flexible date
    /// decoding strategy from PTSupabaseClient for Supabase compatibility.
    nonisolated(unsafe) private let decoder: JSONDecoder = PTSupabaseClient.flexibleDecoder

    // MARK: - Initialization

    private init() {
        // Configure memory cache limits
        memoryCache.countLimit = 200

        // Resolve disk cache directory
        let cacheDir: URL
        if let systemCachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDir = systemCachesDir.appendingPathComponent("APIResponseCache", isDirectory: true)
        } else {
            cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("APIResponseCache", isDirectory: true)
        }
        self.diskCacheDirectory = cacheDir

        // Create disk cache directory
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)

        // Restore entry index from disk on launch
        Task { [weak self] in
            await self?.restoreIndexFromDisk()
        }
    }

    // MARK: - Public API: Fetch with Cache

    /// Fetch data using the cache, with automatic stale-while-revalidate.
    ///
    /// This is the primary API for cached data access. It:
    /// 1. Checks memory cache (L1), then disk cache (L2).
    /// 2. If a **fresh** entry is found, returns it immediately.
    /// 3. If a **stale** entry is found, returns it immediately and triggers
    ///    a background revalidation using `fetcher`.
    /// 4. If no entry or an **expired** entry is found, calls `fetcher` synchronously
    ///    and caches the result.
    ///
    /// - Parameters:
    ///   - key: Unique cache key for this request.
    ///   - policy: Cache policy controlling TTL, staleness, and storage behavior.
    ///   - fetcher: Async closure that fetches fresh data from the network.
    /// - Returns: The decoded response data.
    /// - Throws: Rethrows errors from `fetcher` when no cached data is available.
    func fetch<T: Codable & Sendable>(
        key: String,
        policy: CachePolicy = .standard,
        fetcher: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        let startTime = Date()

        // Step 1: Check for cached entry
        if let entry = lookupEntry(forKey: key) {
            let freshness = policy.freshness(forAge: entry.age)

            switch freshness {
            case .fresh:
                // Cache hit: data is fresh, serve directly
                await metrics.recordHit(key: key)
                let duration = Date().timeIntervalSince(startTime)
                await metrics.recordFetchDuration(duration)

                return try decodeEntry(entry)

            case .stale:
                // Stale-while-revalidate: serve stale data, refresh in background
                await metrics.recordStaleHit(key: key)
                let duration = Date().timeIntervalSince(startTime)
                await metrics.recordFetchDuration(duration)

                triggerBackgroundRevalidation(key: key, policy: policy, entry: entry, fetcher: fetcher)

                return try decodeEntry(entry)

            case .expired:
                // Entry is too old; fall through to fetch
                break
            }
        }

        // Step 2: Check offline mode - serve any cached data regardless of freshness
        let isOffline = await checkOfflineStatus()
        if isOffline {
            if let entry = lookupEntry(forKey: key) {
                await metrics.recordOfflineServe()
                DebugLogger.shared.log("[APIResponseCache] Serving offline cached data for: \(key)", level: .warning)
                return try decodeEntry(entry)
            }
        }

        // Step 3: Cache miss or expired - fetch fresh data
        await metrics.recordMiss(key: key)

        do {
            let result = try await fetcher()
            let duration = Date().timeIntervalSince(startTime)
            await metrics.recordFetchDuration(duration)

            // Cache the result
            try await storeEntry(result, forKey: key, policy: policy, etag: nil)

            return result
        } catch {
            // On network failure, try to serve expired cached data as fallback
            if let entry = lookupEntry(forKey: key) {
                await metrics.recordOfflineServe()
                DebugLogger.shared.log(
                    "[APIResponseCache] Network error, serving expired cache for: \(key) - \(error.localizedDescription)",
                    level: .warning
                )
                return try decodeEntry(entry)
            }
            throw error
        }
    }

    /// Fetch data with ETag-based conditional request support.
    ///
    /// If a cached entry with an ETag exists, the `conditionalFetcher` is called with
    /// the ETag so the caller can send an `If-None-Match` header. If the server responds
    /// with 304 Not Modified, the closure should return `nil` and this method serves the cache.
    ///
    /// - Parameters:
    ///   - key: Unique cache key.
    ///   - policy: Cache policy.
    ///   - conditionalFetcher: Closure receiving an optional ETag. Returns `nil` if 304.
    /// - Returns: The decoded response.
    func fetchWithETag<T: Codable & Sendable>(
        key: String,
        policy: CachePolicy = .longLived,
        conditionalFetcher: @Sendable (_ etag: String?) async throws -> (data: T, etag: String?)?
    ) async throws -> T {
        let startTime = Date()
        let existingEntry = lookupEntry(forKey: key)
        let existingETag = existingEntry?.etag

        // If we have a fresh entry, return it without a network call
        if let entry = existingEntry {
            let freshness = policy.freshness(forAge: entry.age)
            if freshness == .fresh {
                await metrics.recordHit(key: key)
                let duration = Date().timeIntervalSince(startTime)
                await metrics.recordFetchDuration(duration)
                return try decodeEntry(entry)
            }
        }

        // Check offline
        let isOffline = await checkOfflineStatus()
        if isOffline, let entry = existingEntry {
            await metrics.recordOfflineServe()
            return try decodeEntry(entry)
        }

        // Make conditional request
        do {
            if let result = try await conditionalFetcher(existingETag) {
                // New data received
                await metrics.recordMiss(key: key)
                let duration = Date().timeIntervalSince(startTime)
                await metrics.recordFetchDuration(duration)

                try await storeEntry(result.data, forKey: key, policy: policy, etag: result.etag)
                return result.data
            } else {
                // 304 Not Modified - serve cached data and update timestamp
                if let entry = existingEntry {
                    await metrics.recordHit(key: key)
                    await metrics.recordRevalidation(success: true)

                    // Refresh the entry timestamp since server confirmed it is still valid
                    let decoded: T = try decodeEntry(entry)
                    try await storeEntry(decoded, forKey: key, policy: policy, etag: existingETag)

                    let duration = Date().timeIntervalSince(startTime)
                    await metrics.recordFetchDuration(duration)
                    return decoded
                }
                throw APICacheError.conditionalRequestFailed
            }
        } catch {
            // On failure, try cached data
            if let entry = existingEntry {
                await metrics.recordOfflineServe()
                DebugLogger.shared.log(
                    "[APIResponseCache] ETag fetch failed, serving cached for: \(key) - \(error.localizedDescription)",
                    level: .warning
                )
                return try decodeEntry(entry)
            }
            throw error
        }
    }

    // MARK: - Public API: Manual Cache Operations

    /// Store a value in the cache manually.
    ///
    /// Use this to pre-populate the cache or cache data obtained outside of `fetch`.
    ///
    /// - Parameters:
    ///   - value: The value to cache.
    ///   - key: Cache key.
    ///   - policy: Cache policy.
    func store<T: Codable & Sendable>(_ value: T, forKey key: String, policy: CachePolicy = .standard) async {
        do {
            try await storeEntry(value, forKey: key, policy: policy, etag: nil)
        } catch {
            DebugLogger.shared.log(
                "[APIResponseCache] Failed to manually store cache for: \(key) - \(error.localizedDescription)",
                level: .warning
            )
        }
    }

    /// Retrieve a cached value without fetching from the network.
    ///
    /// Returns `nil` if no entry exists. Does not check freshness; returns
    /// any cached data regardless of age. Use `fetch` for freshness-aware access.
    ///
    /// - Parameters:
    ///   - key: Cache key.
    ///   - type: The expected decoded type.
    /// - Returns: The cached value or `nil`.
    func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let entry = lookupEntry(forKey: key) else { return nil }
        return try? decodeEntry(entry) as T
    }

    // MARK: - Public API: Invalidation

    /// Invalidate cache entries according to the given rule.
    ///
    /// - Parameter rule: The invalidation rule describing which entries to remove.
    /// - Returns: The number of entries invalidated.
    @discardableResult
    func invalidate(_ rule: CacheInvalidationRule) async -> Int {
        let keysToRemove: [String]

        switch rule {
        case .key(let key):
            keysToRemove = entryIndex[key] != nil ? [key] : []

        case .keyPrefix(let prefix):
            keysToRemove = entryIndex.keys.filter { $0.hasPrefix(prefix) }

        case .tag(let tag):
            keysToRemove = entryIndex.filter { $0.value.tags.contains(tag) }.map(\.key)

        case .anyTag(let tags):
            keysToRemove = entryIndex.filter { !$0.value.tags.isDisjoint(with: tags) }.map(\.key)

        case .allTags(let tags):
            keysToRemove = entryIndex.filter { tags.isSubset(of: $0.value.tags) }.map(\.key)

        case .all:
            keysToRemove = Array(entryIndex.keys)
        }

        for key in keysToRemove {
            removeEntry(forKey: key)
        }

        if !keysToRemove.isEmpty {
            DebugLogger.shared.log(
                "[APIResponseCache] Invalidated \(keysToRemove.count) entries (rule: \(rule))",
                level: .diagnostic
            )
        }

        return keysToRemove.count
    }

    /// Invalidate all cache entries for a specific user.
    ///
    /// Convenience method for sign-out or user-switch scenarios.
    ///
    /// - Parameter userId: The user ID whose cache entries should be removed.
    @discardableResult
    func invalidateUser(_ userId: String) async -> Int {
        await invalidate(.tag("user_\(userId)"))
    }

    // MARK: - Public API: Maintenance

    /// Remove all entries from both memory and disk caches.
    func clearAll() async {
        memoryCache.removeAllObjects()
        entryIndex.removeAll()
        revalidatingKeys.removeAll()

        // Clear disk
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)

        DebugLogger.shared.log("[APIResponseCache] All caches cleared", level: .diagnostic)
    }

    /// Remove expired entries from both memory and disk.
    ///
    /// Call periodically or on app backgrounding to reclaim storage.
    func purgeExpired() async {
        var purgedCount = 0

        for (key, meta) in entryIndex {
            let age = Date().timeIntervalSince(meta.cachedAt)
            let maxAge = meta.ttl + (meta.staleWhileRevalidateWindow ?? 0)
            if age > maxAge {
                removeEntry(forKey: key)
                purgedCount += 1
            }
        }

        if purgedCount > 0 {
            DebugLogger.shared.log("[APIResponseCache] Purged \(purgedCount) expired entries", level: .diagnostic)
        }
    }

    /// Evict lowest-priority entries until disk cache is under the size limit.
    func trimDiskCache() async {
        let currentSize = await calculateDiskCacheSize()
        guard currentSize > maxDiskCacheBytes else { return }

        // Sort entries by priority (ascending) then age (oldest first)
        let sortedEntries = entryIndex.sorted { lhs, rhs in
            if lhs.value.priority != rhs.value.priority {
                return lhs.value.priority < rhs.value.priority
            }
            return lhs.value.cachedAt < rhs.value.cachedAt
        }

        var freedBytes: Int64 = 0
        let targetReduction = currentSize - maxDiskCacheBytes

        for (key, _) in sortedEntries {
            if freedBytes >= targetReduction { break }

            let fileURL = diskFileURL(forKey: key)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? Int64 {
                freedBytes += size
            }
            removeEntry(forKey: key)
            await metrics.recordEviction()
        }

        DebugLogger.shared.log(
            "[APIResponseCache] Trimmed disk cache, freed \(freedBytes) bytes",
            level: .diagnostic
        )
    }

    /// Get the current number of entries in the cache.
    var entryCount: Int {
        entryIndex.count
    }

    /// Get a metrics snapshot for monitoring.
    func getMetrics() async -> APICacheMetricsSnapshot {
        await metrics.snapshot()
    }

    /// Reset metrics counters.
    func resetMetrics() async {
        await metrics.reset()
    }

    /// Get a human-readable status description for debugging.
    func getStatusDescription() async -> String {
        let metricsSnap = await metrics.snapshot()
        let diskSize = await calculateDiskCacheSize()

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let diskSizeStr = formatter.string(fromByteCount: diskSize)

        return """
        [APIResponseCache Status]
        - Entries: \(entryIndex.count)
        - Disk Usage: \(diskSizeStr) / \(formatter.string(fromByteCount: maxDiskCacheBytes))
        - Revalidating: \(revalidatingKeys.count) keys
        \(metricsSnap.report)
        """
    }

    // MARK: - Internal: Storage Operations

    /// Store an encoded entry in both memory and (optionally) disk.
    private func storeEntry<T: Codable>(
        _ value: T,
        forKey key: String,
        policy: CachePolicy,
        etag: String?
    ) async throws {
        let data = try encoder.encode(value)

        let entry = APICacheEntry(
            data: data,
            cachedAt: Date(),
            key: key,
            tags: policy.tags,
            priorityRawValue: policy.priority.rawValue,
            etag: etag,
            ttl: policy.ttl,
            staleWhileRevalidateWindow: policy.staleWhileRevalidate
        )

        // Store in memory (L1)
        let wrapper = NSCacheEntryWrapper(entry: entry)
        memoryCache.setObject(wrapper, forKey: key as NSString)

        // Update index
        entryIndex[key] = CacheEntryMetadata(
            cachedAt: entry.cachedAt,
            tags: policy.tags,
            priority: policy.priority,
            ttl: policy.ttl,
            staleWhileRevalidateWindow: policy.staleWhileRevalidate,
            etag: etag
        )

        // Store on disk (L2) if policy allows
        if policy.persistToDisk {
            await writeToDisk(entry: entry)
        }
    }

    /// Look up a cache entry, checking memory first, then disk.
    private func lookupEntry(forKey key: String) -> APICacheEntry? {
        // Check memory (L1)
        if let wrapper = memoryCache.object(forKey: key as NSString) {
            return wrapper.entry
        }

        // Check disk (L2) - only if we have it in the index
        guard entryIndex[key] != nil else { return nil }

        if let entry = readFromDisk(forKey: key) {
            // Promote to memory cache
            let wrapper = NSCacheEntryWrapper(entry: entry)
            memoryCache.setObject(wrapper, forKey: key as NSString)
            return entry
        }

        // Index entry exists but disk file is missing; clean up
        entryIndex.removeValue(forKey: key)
        return nil
    }

    /// Remove an entry from memory, disk, and the index.
    private func removeEntry(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        entryIndex.removeValue(forKey: key)
        removeDiskFile(forKey: key)
    }

    /// Decode a cache entry's data into the expected type.
    private func decodeEntry<T: Codable>(_ entry: APICacheEntry) throws -> T {
        try decoder.decode(T.self, from: entry.data)
    }

    // MARK: - Internal: Disk Operations

    /// Compute the file URL for a given cache key.
    private func diskFileURL(forKey key: String) -> URL {
        let safeFilename = key.data(using: .utf8)?
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(128)
            ?? "unknown"

        return diskCacheDirectory.appendingPathComponent(String(safeFilename) + ".cache")
    }

    /// Write a cache entry to disk as JSON.
    private func writeToDisk(entry: APICacheEntry) async {
        let fileURL = diskFileURL(forKey: entry.key)
        do {
            let data = try encoder.encode(entry)
            try data.write(to: fileURL, options: .atomic)
            await metrics.recordDiskWrite()
        } catch {
            DebugLogger.shared.log(
                "[APIResponseCache] Disk write failed for: \(entry.key) - \(error.localizedDescription)",
                level: .warning
            )
        }
    }

    /// Read a cache entry from disk.
    private func readFromDisk(forKey key: String) -> APICacheEntry? {
        let fileURL = diskFileURL(forKey: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        do {
            let entryDecoder = PTSupabaseClient.flexibleDecoder
            let entry = try entryDecoder.decode(APICacheEntry.self, from: data)
            Task { await metrics.recordDiskRead() }
            return entry
        } catch {
            // Corrupted file; remove it
            try? FileManager.default.removeItem(at: fileURL)
            DebugLogger.shared.log(
                "[APIResponseCache] Corrupted disk cache removed for: \(key)",
                level: .warning
            )
            return nil
        }
    }

    /// Delete a cache file from disk.
    private func removeDiskFile(forKey key: String) {
        let fileURL = diskFileURL(forKey: key)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Calculate total disk cache size in bytes.
    private func calculateDiskCacheSize() async -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var totalSize: Int64 = 0
        let fileURLs = enumerator.allObjects.compactMap { $0 as? URL }
        for fileURL in fileURLs {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }

    /// Restore the entry index from existing disk cache files on launch.
    private func restoreIndexFromDisk() async {
        guard let enumerator = FileManager.default.enumerator(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        let fileURLs = enumerator.allObjects.compactMap { $0 as? URL }
        var restoredCount = 0

        let entryDecoder = PTSupabaseClient.flexibleDecoder

        for fileURL in fileURLs {
            guard fileURL.pathExtension == "cache" else { continue }
            guard let data = try? Data(contentsOf: fileURL),
                  let entry = try? entryDecoder.decode(APICacheEntry.self, from: data) else {
                // Remove corrupted files
                try? FileManager.default.removeItem(at: fileURL)
                continue
            }

            // Only restore entries that are not fully expired
            let maxAge = entry.ttl + (entry.staleWhileRevalidateWindow ?? 0)
            guard entry.age <= maxAge else {
                try? FileManager.default.removeItem(at: fileURL)
                continue
            }

            entryIndex[entry.key] = CacheEntryMetadata(
                cachedAt: entry.cachedAt,
                tags: entry.tags,
                priority: entry.priority,
                ttl: entry.ttl,
                staleWhileRevalidateWindow: entry.staleWhileRevalidateWindow,
                etag: entry.etag
            )
            restoredCount += 1
        }

        if restoredCount > 0 {
            DebugLogger.shared.log(
                "[APIResponseCache] Restored \(restoredCount) cache entries from disk",
                level: .diagnostic
            )
        }
    }

    // MARK: - Internal: Background Revalidation

    /// Trigger a background revalidation for a stale cache entry.
    ///
    /// This method is nonisolated so it can fire-and-forget from the actor.
    /// The actual work runs in a detached task that re-enters the actor.
    private func triggerBackgroundRevalidation<T: Codable & Sendable>(
        key: String,
        policy: CachePolicy,
        entry: APICacheEntry,
        fetcher: @Sendable @escaping () async throws -> T
    ) {
        // Prevent duplicate revalidation for the same key
        guard !revalidatingKeys.contains(key) else { return }
        revalidatingKeys.insert(key)

        Task { [weak self] in
            defer {
                Task { [weak self] in
                    await self?.clearRevalidatingKey(key)
                }
            }

            guard let self = self else { return }

            do {
                let freshData = try await fetcher()
                try await self.storeEntry(freshData, forKey: key, policy: policy, etag: nil)
                await self.metrics.recordRevalidation(success: true)

                DebugLogger.shared.log(
                    "[APIResponseCache] Background revalidation succeeded for: \(key)",
                    level: .diagnostic
                )
            } catch {
                await self.metrics.recordRevalidation(success: false)

                // Do not log cancellation errors as they are normal during navigation
                if !error.isCancellation {
                    DebugLogger.shared.log(
                        "[APIResponseCache] Background revalidation failed for: \(key) - \(error.localizedDescription)",
                        level: .warning
                    )
                }
            }
        }
    }

    /// Remove a key from the revalidating set.
    private func clearRevalidatingKey(_ key: String) {
        revalidatingKeys.remove(key)
    }

    // MARK: - Internal: Network Status

    /// Check if the app is currently offline.
    /// Hops to MainActor to read the `@Published` property on PTSupabaseClient.
    private func checkOfflineStatus() async -> Bool {
        await MainActor.run {
            PTSupabaseClient.shared.isOffline
        }
    }

    // MARK: - Memory Warning Handling

    /// Evict low-priority entries from memory in response to system memory pressure.
    ///
    /// Called by `CacheCoordinator` during memory warnings.
    func handleMemoryWarning() {
        // NSCache automatically evicts under memory pressure, but we can help
        // by proactively clearing the lowest-priority entries from our index
        // to free associated resources.
        let lowPriorityKeys = entryIndex
            .filter { $0.value.priority == .low }
            .map(\.key)

        for key in lowPriorityKeys {
            memoryCache.removeObject(forKey: key as NSString)
        }

        DebugLogger.shared.log(
            "[APIResponseCache] Memory warning: evicted \(lowPriorityKeys.count) low-priority memory entries",
            level: .warning
        )
    }
}

// MARK: - Supporting Types

/// Wrapper to store `APICacheEntry` in `NSCache`, which requires reference-type values.
/// Marked `@unchecked Sendable` because the wrapped entry is immutable and `Sendable`,
/// and NSCache is internally thread-safe.
private final class NSCacheEntryWrapper: NSObject, @unchecked Sendable {
    let entry: APICacheEntry

    init(entry: APICacheEntry) {
        self.entry = entry
    }
}

/// Lightweight metadata stored in the entry index for fast lookups without
/// deserializing the full cache entry from disk.
private struct CacheEntryMetadata {
    let cachedAt: Date
    let tags: Set<String>
    let priority: CachePriority
    let ttl: TimeInterval
    let staleWhileRevalidateWindow: TimeInterval?
    let etag: String?
}

// MARK: - Errors

/// Errors specific to the API response cache.
enum APICacheError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case conditionalRequestFailed
    case entryNotFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode cache entry"
        case .decodingFailed:
            return "Failed to decode cached data"
        case .conditionalRequestFailed:
            return "Conditional request returned no data and no cache available"
        case .entryNotFound:
            return "Cache entry not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed, .decodingFailed:
            return "The cache may be corrupted. Please try again."
        case .conditionalRequestFailed:
            return "Please check your connection and try again."
        case .entryNotFound:
            return "The requested data is not cached. Please refresh."
        }
    }
}

// MARK: - Convenience Extensions

extension APIResponseCache {

    /// Fetch data with a user-scoped cache key and policy.
    ///
    /// Automatically prepends the user ID to the key and adds a user tag to the policy
    /// for easy per-user cache invalidation on sign-out.
    ///
    /// - Parameters:
    ///   - key: Base cache key (user ID will be prepended).
    ///   - userId: The current user's ID.
    ///   - policy: Base cache policy (will have user tag added).
    ///   - fetcher: Async closure that fetches fresh data.
    /// - Returns: The decoded response.
    func fetchForUser<T: Codable & Sendable>(
        key: String,
        userId: String,
        policy: CachePolicy = .standard,
        fetcher: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        let scopedKey = "user_\(userId)_\(key)"
        let scopedPolicy = CachePolicy.userScoped(policy, userId: userId)
        return try await fetch(key: scopedKey, policy: scopedPolicy, fetcher: fetcher)
    }

    /// Prefetch and cache data in the background without blocking.
    ///
    /// Use this to warm the cache for data the user is likely to need soon
    /// (e.g., preload tomorrow's workout session on today-tab appearance).
    ///
    /// - Parameters:
    ///   - key: Cache key.
    ///   - policy: Cache policy.
    ///   - fetcher: Async closure that fetches the data.
    func prefetch<T: Codable & Sendable>(
        key: String,
        policy: CachePolicy = .standard,
        fetcher: @Sendable @escaping () async throws -> T
    ) {
        Task { [weak self] in
            do {
                _ = try await self?.fetch(key: key, policy: policy, fetcher: fetcher)
            } catch {
                if !error.isCancellation {
                    DebugLogger.shared.log(
                        "[APIResponseCache] Prefetch failed for: \(key) - \(error.localizedDescription)",
                        level: .diagnostic
                    )
                }
            }
        }
    }
}
