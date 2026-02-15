//
//  SubscriptionAnalyticsService.swift
//  PTPerformance
//
//  ACP-989: Subscription Analytics Dashboard
//  Actor-based service for tracking subscription events, calculating metrics,
//  and syncing analytics data with Supabase backend.
//

import Foundation
import Supabase

/// Actor-based service for subscription analytics tracking and metric calculation
///
/// Manages a local event queue that batches subscription events for efficient
/// Supabase synchronization. Falls back to cached metrics when offline.
///
/// ## Usage Example
/// ```swift
/// let service = SubscriptionAnalyticsService.shared
///
/// // Record a subscription event
/// await service.recordEvent(SubscriptionEvent(
///     userId: userId,
///     type: .purchase,
///     tier: .pro,
///     revenue: 29.99
/// ))
///
/// // Fetch current metrics
/// let metrics = await service.fetchMetrics()
/// print("MRR: \(metrics.formattedMRR)")
/// ```
actor SubscriptionAnalyticsService {

    // MARK: - Singleton

    static let shared = SubscriptionAnalyticsService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    // MARK: - Local Event Queue

    /// Pending events that have not yet been synced to Supabase
    private var eventQueue: [SubscriptionEvent] = []

    /// Maximum number of events to batch before forcing a sync
    private let batchSize = 20

    /// Interval in seconds between automatic batch syncs
    private let syncInterval: TimeInterval = 60

    /// Last time a batch sync was performed
    private var lastSyncTime: Date = .distantPast

    // MARK: - Cache

    /// Cached metrics for offline fallback
    private var cachedMetrics: SubscriptionMetrics?

    /// Cached revenue history for offline fallback
    private var cachedRevenueHistory: [RevenueDataPoint]?

    /// Timestamp of the last successful metrics fetch
    private var metricsLastFetched: Date?

    /// Cache duration in seconds (5 minutes)
    private let cacheDuration: TimeInterval = 300

    // MARK: - UserDefaults Keys

    private enum DefaultsKeys {
        static let cachedMetrics = "subscription_analytics_cached_metrics"
        static let cachedRevenue = "subscription_analytics_cached_revenue"
        static let pendingEvents = "subscription_analytics_pending_events"
    }

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        logger.info("SubscriptionAnalytics", "Service initialized")
        // Restore any persisted pending events
        Task { await restorePendingEvents() }
    }

    // MARK: - Event Recording

    /// Record a subscription lifecycle event
    ///
    /// Events are queued locally and batch-synced to Supabase. If the queue
    /// exceeds the batch size, an immediate sync is triggered.
    ///
    /// - Parameter event: The subscription event to record
    func recordEvent(_ event: SubscriptionEvent) async {
        eventQueue.append(event)
        logger.info("SubscriptionAnalytics", "Recorded event: \(event.type.rawValue) for user \(event.userId), tier: \(event.tier.rawValue)")

        // Invalidate cached metrics since data has changed
        metricsLastFetched = nil

        // Persist pending events for crash recovery
        persistPendingEvents()

        // Check if we should force a batch sync
        if eventQueue.count >= batchSize {
            logger.info("SubscriptionAnalytics", "Batch size reached (\(eventQueue.count)), triggering sync")
            await syncEventQueue()
        } else if Date().timeIntervalSince(lastSyncTime) >= syncInterval && !eventQueue.isEmpty {
            logger.info("SubscriptionAnalytics", "Sync interval elapsed, triggering sync")
            await syncEventQueue()
        }
    }

    // MARK: - Metrics Fetching

    /// Fetch current subscription metrics
    ///
    /// Returns cached data if available and fresh, otherwise queries Supabase.
    /// Falls back to cached metrics when offline.
    ///
    /// - Returns: Current subscription metrics
    func fetchMetrics() async -> SubscriptionMetrics {
        // Return cached metrics if still fresh
        if let cached = cachedMetrics,
           let lastFetched = metricsLastFetched,
           Date().timeIntervalSince(lastFetched) < cacheDuration {
            logger.diagnostic("[SubscriptionAnalytics]Returning cached metrics (age: \(Int(Date().timeIntervalSince(lastFetched)))s)")
            return cached
        }

        do {
            let response = try await supabase.client
                .from("subscription_metrics")
                .select()
                .order("calculated_at", ascending: false)
                .limit(1)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let metrics = try decoder.decode(SubscriptionMetrics.self, from: response.data)

            // Update cache
            cachedMetrics = metrics
            metricsLastFetched = Date()
            persistCachedMetrics(metrics)

            logger.success("SubscriptionAnalytics", "Fetched metrics: MRR=$\(String(format: "%.0f", metrics.mrr)), subscribers=\(metrics.totalSubscribers)")
            return metrics
        } catch {
            if error.isCancellation {
                logger.diagnostic("[SubscriptionAnalytics]Metrics fetch cancelled")
            } else {
                logger.warning("SubscriptionAnalytics", "Failed to fetch metrics from Supabase: \(error.localizedDescription)")
            }

            // Return cached metrics as fallback
            if let cached = cachedMetrics {
                logger.info("SubscriptionAnalytics", "Returning cached metrics as offline fallback")
                return cached
            }

            // Try to restore from persisted cache
            if let persisted = loadPersistedMetrics() {
                cachedMetrics = persisted
                logger.info("SubscriptionAnalytics", "Returning persisted cached metrics")
                return persisted
            }

            // Last resort: return empty metrics
            logger.warning("SubscriptionAnalytics", "No cached metrics available, returning empty metrics")
            return SubscriptionMetrics(
                mrr: 0, arr: 0, totalSubscribers: 0, activeTrials: 0,
                churnRate: 0, conversionRate: 0, avgRevenuePerUser: 0, ltv: 0
            )
        }
    }

    /// Fetch revenue history over a specified number of days
    ///
    /// - Parameter days: Number of days of history to fetch (default: 30)
    /// - Returns: Array of revenue data points sorted by date ascending
    func fetchRevenueHistory(days: Int = 30) async -> [RevenueDataPoint] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            logger.error("SubscriptionAnalytics", "Failed to calculate start date for revenue history")
            return cachedRevenueHistory ?? []
        }

        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let response = try await supabase.client
                .from("daily_revenue")
                .select("id, date, revenue, subscribers")
                .gte("date", value: formatter.string(from: startDate))
                .order("date", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dataPoints = try decoder.decode([RevenueDataPoint].self, from: response.data)

            cachedRevenueHistory = dataPoints
            logger.success("SubscriptionAnalytics", "Fetched \(dataPoints.count) revenue data points for last \(days) days")
            return dataPoints
        } catch {
            if error.isCancellation {
                logger.diagnostic("[SubscriptionAnalytics]Revenue history fetch cancelled")
            } else {
                logger.warning("SubscriptionAnalytics", "Failed to fetch revenue history: \(error.localizedDescription)")
            }

            if let cached = cachedRevenueHistory {
                logger.info("SubscriptionAnalytics", "Returning cached revenue history (\(cached.count) points)")
                return cached
            }

            return []
        }
    }

    /// Fetch recent churn events
    ///
    /// - Parameter limit: Maximum number of events to return (default: 20)
    /// - Returns: Array of churn events sorted by date descending
    func fetchChurnEvents(limit: Int = 20) async -> [ChurnEvent] {
        do {
            let response = try await supabase.client
                .from("churn_events")
                .select()
                .order("date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([ChurnEvent].self, from: response.data)

            logger.success("SubscriptionAnalytics", "Fetched \(events.count) churn events")
            return events
        } catch {
            if error.isCancellation {
                logger.diagnostic("[SubscriptionAnalytics]Churn events fetch cancelled")
            } else {
                logger.warning("SubscriptionAnalytics", "Failed to fetch churn events: \(error.localizedDescription)")
            }
            return []
        }
    }

    /// Fetch recent conversion events
    ///
    /// - Parameter limit: Maximum number of events to return (default: 20)
    /// - Returns: Array of conversion events sorted by date descending
    func fetchConversionEvents(limit: Int = 20) async -> [ConversionEvent] {
        do {
            let response = try await supabase.client
                .from("conversion_events")
                .select()
                .order("date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([ConversionEvent].self, from: response.data)

            logger.success("SubscriptionAnalytics", "Fetched \(events.count) conversion events")
            return events
        } catch {
            if error.isCancellation {
                logger.diagnostic("[SubscriptionAnalytics]Conversion events fetch cancelled")
            } else {
                logger.warning("SubscriptionAnalytics", "Failed to fetch conversion events: \(error.localizedDescription)")
            }
            return []
        }
    }

    // MARK: - Queue Management

    /// Force a sync of the local event queue to Supabase
    func syncEventQueue() async {
        guard !eventQueue.isEmpty else {
            logger.diagnostic("[SubscriptionAnalytics]Event queue is empty, nothing to sync")
            return
        }

        let eventsToSync = eventQueue
        logger.info("SubscriptionAnalytics", "Syncing \(eventsToSync.count) events to Supabase")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            // Batch insert events
            try await supabase.client
                .from("subscription_events")
                .insert(eventsToSync)
                .execute()

            // Clear synced events from queue
            eventQueue.removeAll { synced in
                eventsToSync.contains(where: { $0.id == synced.id })
            }

            lastSyncTime = Date()
            persistPendingEvents()

            logger.success("SubscriptionAnalytics", "Successfully synced \(eventsToSync.count) events")
        } catch {
            if error.isCancellation {
                logger.diagnostic("[SubscriptionAnalytics]Event sync cancelled")
            } else {
                logger.error("SubscriptionAnalytics", "Failed to sync event queue: \(error.localizedDescription). \(eventQueue.count) events remain queued.")
            }
            // Events remain in queue for retry on next sync attempt
        }
    }

    /// Number of events currently pending sync
    var pendingEventCount: Int {
        eventQueue.count
    }

    // MARK: - Persistence

    private func persistPendingEvents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(eventQueue)
            UserDefaults.standard.set(data, forKey: DefaultsKeys.pendingEvents)
        } catch {
            logger.warning("SubscriptionAnalytics", "Failed to persist pending events: \(error.localizedDescription)")
        }
    }

    private func restorePendingEvents() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKeys.pendingEvents) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([SubscriptionEvent].self, from: data)
            if !events.isEmpty {
                eventQueue.append(contentsOf: events)
                logger.info("SubscriptionAnalytics", "Restored \(events.count) pending events from previous session")
            }
        } catch {
            logger.warning("SubscriptionAnalytics", "Failed to restore pending events: \(error.localizedDescription)")
        }
    }

    private func persistCachedMetrics(_ metrics: SubscriptionMetrics) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metrics)
            UserDefaults.standard.set(data, forKey: DefaultsKeys.cachedMetrics)
        } catch {
            logger.warning("SubscriptionAnalytics", "Failed to persist cached metrics: \(error.localizedDescription)")
        }
    }

    private func loadPersistedMetrics() -> SubscriptionMetrics? {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKeys.cachedMetrics) else { return nil }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SubscriptionMetrics.self, from: data)
        } catch {
            logger.warning("SubscriptionAnalytics", "Failed to load persisted metrics: \(error.localizedDescription)")
            return nil
        }
    }
}
