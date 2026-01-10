//
//  QueryOptimizer.swift
//  PTPerformance
//
//  Build 96: Performance optimization utilities
//  Provides helper methods for optimizing Supabase queries
//

import Foundation

/// Query optimization utilities for reducing data transfer and improving performance
enum QueryOptimizer {

    // MARK: - Field Selection Patterns

    /// Minimal patient fields for list views
    /// Reduces payload size by ~60% compared to SELECT *
    static let patientListFields = """
        id,
        first_name,
        last_name,
        email,
        sport,
        position,
        adherence_percentage,
        last_session_date,
        therapist_id
        """

    /// Minimal session fields for list views
    static let sessionListFields = """
        id,
        name,
        sequence,
        completed,
        completed_at,
        phase_id
        """

    /// Minimal exercise fields for session display
    static let exerciseListFields = """
        id,
        sequence,
        target_sets,
        target_reps,
        target_load,
        load_unit,
        exercise_template_id,
        exercise_templates!inner(
            id,
            name,
            category,
            body_region
        )
        """

    /// Full patient fields (for detail view)
    static let patientDetailFields = """
        id,
        first_name,
        last_name,
        email,
        sport,
        position,
        birth_date,
        height_inches,
        weight_lbs,
        phone,
        adherence_percentage,
        last_session_date,
        therapist_id,
        created_at,
        updated_at
        """

    /// Session with nested relationships (optimized)
    static let sessionWithPhaseFields = """
        id,
        name,
        sequence,
        completed,
        completed_at,
        total_volume,
        avg_rpe,
        avg_pain,
        duration_minutes,
        phase_id,
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
        """

    // MARK: - Query Optimization Patterns

    /// Optimize pagination by using range instead of limit/offset
    /// range() is more efficient for large datasets
    static func optimizedPagination(page: Int, pageSize: Int) -> (from: Int, to: Int) {
        let from = page * pageSize
        let to = from + pageSize - 1
        return (from, to)
    }

    /// Optimize sorting by limiting to essential sort columns
    /// Multiple sorts can be expensive on large tables
    static func optimizedSort(primary: String, secondary: String? = nil) -> [(column: String, ascending: Bool)] {
        var sorts: [(String, Bool)] = [(primary, false)]
        if let sec = secondary {
            sorts.append((sec, false))
        }
        return sorts
    }

    /// Cache key generator for query results
    /// Use this to implement in-memory caching of frequently accessed data
    static func cacheKey(table: String, filters: [String: Any], userId: String) -> String {
        let filterString = filters.map { "\($0)=\($1)" }.sorted().joined(separator:"&")
        return "\(table):\(userId):\(filterString)"
    }
}

/// Query result cache for frequently accessed data
/// Reduces redundant database queries
@MainActor
class QueryCache {
    static let shared = QueryCache()

    private var cache: [String: CachedResult] = [:]
    private let maxCacheSize = 100 // Maximum number of cached queries
    private let defaultTTL: TimeInterval = 60 // 1 minute default cache lifetime

    private init() {}

    struct CachedResult {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    /// Get cached result if available and not expired
    func get(key: String) -> Data? {
        guard let cached = cache[key], !cached.isExpired else {
            cache.removeValue(forKey: key)
            return nil
        }
        return cached.data
    }

    /// Store result in cache
    func set(key: String, data: Data, ttl: TimeInterval? = nil) {
        // Evict oldest entries if cache is full
        if cache.count >= maxCacheSize {
            let oldestKey = cache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let key = oldestKey {
                cache.removeValue(forKey: key)
            }
        }

        cache[key] = CachedResult(
            data: data,
            timestamp: Date(),
            ttl: ttl ?? defaultTTL
        )
    }

    /// Clear all cached results
    func clear() {
        cache.removeAll()
    }

    /// Clear expired entries
    func clearExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }

    /// Get cache statistics
    func stats() -> (count: Int, size: Int) {
        let size = cache.values.reduce(0) { $0 + $1.data.count }
        return (cache.count, size)
    }
}

/// Extension for Supabase PostgrestQueryBuilder to add performance monitoring
extension Supabase.PostgrestQueryBuilder {
    /// Execute query with performance tracking
    func executeWithTracking(queryName: String) async throws -> Supabase.PostgrestResponse {
        PerformanceMonitor.shared.startDatabaseQuery(queryName)
        defer {
            PerformanceMonitor.shared.finishDatabaseQuery(queryName)
        }
        return try await execute()
    }
}
