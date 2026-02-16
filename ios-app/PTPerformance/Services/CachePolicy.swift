//
//  CachePolicy.swift
//  PTPerformance
//
//  ACP-938: API Response Caching
//  Cache policy definitions with TTL, tags, stale-while-revalidate rules,
//  and invalidation patterns for Supabase API responses.
//

import Foundation

// MARK: - Cache Policy

/// Defines caching behavior for an API endpoint or query.
///
/// Each policy controls how long responses are cached, when stale data is acceptable,
/// and how to group related cache entries for bulk invalidation.
///
/// ## Usage
/// ```swift
/// let policy = CachePolicy(
///     ttl: 300,
///     staleWhileRevalidate: 600,
///     tags: ["workouts", "patient_123"]
/// )
/// ```
///
/// ## Predefined Policies
/// Common policies are available as static properties:
/// ```swift
/// let cached = try await apiCache.fetch("sessions", policy: .standard) { ... }
/// ```
struct CachePolicy: Sendable {

    // MARK: - Properties

    /// Time-to-live in seconds. Cached data younger than this is considered fresh.
    let ttl: TimeInterval

    /// Maximum age in seconds for which stale data may be served while a background
    /// revalidation fetches fresh data. If `nil`, stale data is never served.
    /// The total window where stale data is acceptable equals `ttl + staleWhileRevalidate`.
    let staleWhileRevalidate: TimeInterval?

    /// Tags for grouping cache entries. Used for bulk invalidation
    /// (e.g., invalidate all entries tagged "patient_123" on sign-out).
    let tags: Set<String>

    /// Whether this response should be persisted to disk so it survives app restarts
    /// and can be served in offline mode.
    let persistToDisk: Bool

    /// Whether ETag-based conditional requests should be used when revalidating.
    /// When `true`, the cache stores ETag headers and sends `If-None-Match` on revalidation.
    let supportsETag: Bool

    /// Priority for eviction. Lower-priority entries are evicted first when memory is tight.
    let priority: CachePriority

    // MARK: - Initialization

    /// Create a custom cache policy.
    ///
    /// - Parameters:
    ///   - ttl: Time-to-live in seconds. Default is 300 (5 minutes).
    ///   - staleWhileRevalidate: Additional seconds beyond TTL during which stale data
    ///     may be served while revalidating. Default is `nil` (no stale serving).
    ///   - tags: Tags for grouping and bulk invalidation. Default is empty.
    ///   - persistToDisk: Whether to persist to disk for offline use. Default is `true`.
    ///   - supportsETag: Whether to use conditional requests. Default is `false`.
    ///   - priority: Eviction priority. Default is `.normal`.
    init(
        ttl: TimeInterval = 300,
        staleWhileRevalidate: TimeInterval? = nil,
        tags: Set<String> = [],
        persistToDisk: Bool = true,
        supportsETag: Bool = false,
        priority: CachePriority = .normal
    ) {
        self.ttl = ttl
        self.staleWhileRevalidate = staleWhileRevalidate
        self.tags = tags
        self.persistToDisk = persistToDisk
        self.supportsETag = supportsETag
        self.priority = priority
    }

    // MARK: - Freshness Evaluation

    /// Determine the freshness status of a cached entry given its age.
    ///
    /// - Parameter age: The age of the cached entry in seconds.
    /// - Returns: The freshness status of the cached entry.
    func freshness(forAge age: TimeInterval) -> CacheFreshness {
        if age <= ttl {
            return .fresh
        }

        if let swr = staleWhileRevalidate, age <= (ttl + swr) {
            return .stale
        }

        return .expired
    }
}

// MARK: - Cache Priority

/// Priority level for cache eviction ordering.
/// Higher-priority entries are retained longer under memory pressure.
enum CachePriority: Int, Sendable, Comparable {
    /// Evicted first under memory pressure. Use for large, easily re-fetched data.
    case low = 0

    /// Default eviction priority.
    case normal = 1

    /// Retained longer. Use for data that is expensive to fetch or critical to UX.
    case high = 2

    /// Retained as long as possible. Use for authentication state or configuration.
    case critical = 3

    static func < (lhs: CachePriority, rhs: CachePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Cache Freshness

/// Describes the freshness state of a cached entry.
enum CacheFreshness: Sendable {
    /// The entry is within its TTL and can be served directly.
    case fresh

    /// The entry is past its TTL but within the stale-while-revalidate window.
    /// It should be served immediately while a background revalidation runs.
    case stale

    /// The entry is too old to serve. A network fetch is required.
    case expired
}

// MARK: - Invalidation Rule

/// Describes how cache entries should be invalidated.
enum CacheInvalidationRule: Sendable {
    /// Invalidate a single entry by its exact cache key.
    case key(String)

    /// Invalidate all entries whose keys match the given prefix.
    /// Example: `"patient_123_"` invalidates all of that patient's cached data.
    case keyPrefix(String)

    /// Invalidate all entries tagged with the given tag.
    case tag(String)

    /// Invalidate all entries tagged with any of the given tags.
    case anyTag(Set<String>)

    /// Invalidate all entries tagged with all of the given tags (intersection).
    case allTags(Set<String>)

    /// Invalidate every entry in the cache.
    case all
}

// MARK: - Predefined Policies

extension CachePolicy {

    /// No caching. Every request goes to the network.
    static let noCache = CachePolicy(
        ttl: 0,
        staleWhileRevalidate: nil,
        persistToDisk: false,
        priority: .low
    )

    /// Short-lived cache for frequently changing data (e.g., readiness scores, daily check-ins).
    /// Fresh for 1 minute, stale-while-revalidate for an additional 2 minutes.
    static let shortLived = CachePolicy(
        ttl: 60,
        staleWhileRevalidate: 120,
        persistToDisk: true,
        priority: .normal
    )

    /// Standard cache for moderately stable data (e.g., workout sessions, programs).
    /// Fresh for 5 minutes, stale-while-revalidate for an additional 10 minutes.
    static let standard = CachePolicy(
        ttl: 300,
        staleWhileRevalidate: 600,
        persistToDisk: true,
        priority: .normal
    )

    /// Long-lived cache for rarely changing data (e.g., exercise library, templates).
    /// Fresh for 1 hour, stale-while-revalidate for an additional 3 hours.
    static let longLived = CachePolicy(
        ttl: 3600,
        staleWhileRevalidate: 10800,
        persistToDisk: true,
        supportsETag: true,
        priority: .high
    )

    /// Aggressive cache for effectively static data (e.g., configuration, feature flags).
    /// Fresh for 24 hours, stale-while-revalidate for an additional 48 hours.
    static let aggressive = CachePolicy(
        ttl: 86400,
        staleWhileRevalidate: 172800,
        persistToDisk: true,
        supportsETag: true,
        priority: .critical
    )

    /// Offline-first policy. Data is cached aggressively and always served from cache
    /// when available, with background refresh. Fresh for 30 minutes, but stale data
    /// is acceptable for up to 24 hours.
    static let offlineFirst = CachePolicy(
        ttl: 1800,
        staleWhileRevalidate: 86400,
        persistToDisk: true,
        priority: .high
    )

    /// Memory-only cache that does not persist to disk. Useful for large payloads
    /// that are cheap to re-fetch but expensive to serialize.
    static let memoryOnly = CachePolicy(
        ttl: 300,
        staleWhileRevalidate: 300,
        persistToDisk: false,
        priority: .low
    )

    // MARK: - Domain-Specific Policies

    /// Policy for workout session data. Moderate TTL with stale-while-revalidate
    /// to ensure the user sees their session quickly while refreshing in background.
    static let workoutSession = CachePolicy(
        ttl: 300,
        staleWhileRevalidate: 600,
        tags: ["workouts"],
        persistToDisk: true,
        priority: .high
    )

    /// Policy for exercise library data. Exercises rarely change, so use a long TTL.
    static let exerciseLibrary = CachePolicy(
        ttl: 3600,
        staleWhileRevalidate: 14400,
        tags: ["exercises"],
        persistToDisk: true,
        supportsETag: true,
        priority: .high
    )

    /// Policy for patient profile data. Short TTL since profiles can be updated,
    /// but stale data is acceptable briefly.
    static let patientProfile = CachePolicy(
        ttl: 120,
        staleWhileRevalidate: 300,
        tags: ["profile"],
        persistToDisk: true,
        priority: .normal
    )

    /// Policy for analytics and trend data. Moderate TTL; trends do not change rapidly.
    static let analytics = CachePolicy(
        ttl: 600,
        staleWhileRevalidate: 1800,
        tags: ["analytics"],
        persistToDisk: true,
        priority: .normal
    )

    /// Policy for readiness and daily check-in data. Short TTL because it changes daily.
    static let readiness = CachePolicy(
        ttl: 60,
        staleWhileRevalidate: 180,
        tags: ["readiness"],
        persistToDisk: true,
        priority: .normal
    )

    /// Policy for program templates and library. Rarely changes.
    static let programLibrary = CachePolicy(
        ttl: 1800,
        staleWhileRevalidate: 7200,
        tags: ["programs"],
        persistToDisk: true,
        supportsETag: true,
        priority: .high
    )

    // MARK: - Policy Builder

    /// Create a policy with user-scoped tags for easy per-user invalidation.
    ///
    /// - Parameters:
    ///   - base: The base policy to extend.
    ///   - userId: The user ID to scope the cache to.
    /// - Returns: A new policy with the user-scoped tag added.
    static func userScoped(_ base: CachePolicy, userId: String) -> CachePolicy {
        var tags = base.tags
        tags.insert("user_\(userId)")
        return CachePolicy(
            ttl: base.ttl,
            staleWhileRevalidate: base.staleWhileRevalidate,
            tags: tags,
            persistToDisk: base.persistToDisk,
            supportsETag: base.supportsETag,
            priority: base.priority
        )
    }
}
