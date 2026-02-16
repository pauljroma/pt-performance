//
//  FeatureUsageTracker.swift
//  PTPerformance
//
//  ACP-964: Feature Usage Tracking
//  Actor-based service that tracks which features users engage with, measures
//  adoption rates (first use, repeat use, power use), records how users discover
//  features, and captures feature-specific metrics.
//
//  Integrates with AnalyticsSDK for backend event ingestion and persists records
//  locally for session-spanning analysis.
//

import Foundation

// MARK: - FeatureUsageTracker

/// Actor-based singleton that tracks feature usage across the entire PT Performance app.
///
/// Records every feature interaction with its action type, discovery source, and
/// feature-specific metadata. Events are persisted to disk for offline access and
/// forwarded to ``AnalyticsSDK`` for backend ingestion.
///
/// ## Quick Start
/// ```swift
/// // Simple usage tracking
/// await FeatureTracker.track(.workoutSession, action: .used)
///
/// // Track with discovery source
/// await FeatureTracker.track(.aiCoach, action: .discovered, source: .todayHub)
///
/// // Track with feature-specific metadata
/// await FeatureTracker.track(.programBuilder, action: .completed, metadata: [
///     "exercise_count": "8",
///     "session_count": "3"
/// ])
///
/// // Get adoption report
/// let report = await FeatureTracker.shared.getAdoptionReport()
/// ```
actor FeatureUsageTracker {

    // MARK: - Singleton

    static let shared = FeatureUsageTracker()

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    /// All recorded feature usage events, loaded from and persisted to disk.
    private var records: [FeatureUsageRecord] = []

    /// In-memory cache of per-feature use counts for fast adoption-stage lookups.
    /// Rebuilt from `records` on load and updated incrementally on new events.
    private var useCounts: [AppFeature: Int] = [:]

    /// In-memory cache of first-use dates per feature for fast lookups.
    private var firstUseDates: [AppFeature: Date] = [:]

    /// File URL for persisting feature usage records across sessions.
    private let persistenceURL: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directory.appendingPathComponent("PTPerformance", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.appendingPathComponent("feature_usage_records.json")
    }()

    // MARK: - JSON Coders

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Date Formatter

    private nonisolated static let calendarDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    private nonisolated static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        logger.info("FeatureUsage", "FeatureUsageTracker initialized")
        loadPersistedRecords()
        rebuildCaches()
    }

    // MARK: - Public API: Tracking

    /// Records a feature usage event.
    ///
    /// This is the primary tracking entry point. Every call:
    /// 1. Creates a timestamped ``FeatureUsageRecord``
    /// 2. Updates in-memory caches (use counts, first-use dates)
    /// 3. Persists the record to disk
    /// 4. Forwards the event to ``AnalyticsTracker`` and ``AnalyticsSDK`` for backend ingestion
    ///
    /// - Parameters:
    ///   - feature: The app feature being interacted with.
    ///   - action: The type of interaction (discovered, used, completed).
    ///   - source: How the user navigated to this feature (nil if unknown).
    ///   - metadata: Feature-specific key-value pairs (e.g. `["exercise_count": "8"]`).
    func track(
        _ feature: AppFeature,
        action: FeatureAction,
        source: DiscoverySource? = nil,
        metadata: [String: String] = [:]
    ) {
        let record = FeatureUsageRecord(
            feature: feature,
            action: action,
            discoverySource: source,
            metadata: metadata
        )

        records.append(record)

        // Update caches
        useCounts[feature, default: 0] += 1
        if firstUseDates[feature] == nil {
            firstUseDates[feature] = record.timestamp
        }

        // Persist to disk
        persistRecords()

        // Determine adoption stage for analytics properties
        let totalUses = useCounts[feature, default: 0]
        let adoptionStage = AdoptionStage.stage(forTotalUses: totalUses)

        // Build analytics properties
        var properties: [String: Any] = [
            "feature": feature.rawValue,
            "feature_name": feature.displayName,
            "feature_category": feature.category.rawValue,
            "action": action.rawValue,
            "adoption_stage": adoptionStage.rawValue,
            "total_uses": totalUses
        ]
        if let source = source {
            properties["discovery_source"] = source.rawValue
        }
        for (key, value) in metadata {
            properties["meta_\(key)"] = value
        }

        // Forward to AnalyticsTracker (which internally forwards to AnalyticsSDK)
        analyticsTracker.track(event: "feature_usage", properties: properties)

        // Log adoption stage transitions
        if totalUses == 1 {
            analyticsTracker.track(event: "feature_first_use", properties: [
                "feature": feature.rawValue,
                "feature_name": feature.displayName,
                "feature_category": feature.category.rawValue,
                "discovery_source": source?.rawValue ?? DiscoverySource.unknown.rawValue
            ])
            logger.info("FeatureUsage", "First use: \(feature.displayName) (source: \(source?.rawValue ?? "unknown"))")
        } else if totalUses == 10 {
            analyticsTracker.track(event: "feature_power_user_reached", properties: [
                "feature": feature.rawValue,
                "feature_name": feature.displayName,
                "feature_category": feature.category.rawValue
            ])
            logger.info("FeatureUsage", "Power user reached: \(feature.displayName) (\(totalUses) uses)")
        }

        logger.diagnostic("FeatureUsage: \(feature.rawValue) | \(action.rawValue) | stage=\(adoptionStage.rawValue) | uses=\(totalUses)")
    }

    // MARK: - Public API: Queries

    /// Returns the current adoption stage for a feature.
    ///
    /// - Parameter feature: The feature to check.
    /// - Returns: The adoption stage based on total use count.
    func getAdoptionStage(for feature: AppFeature) -> AdoptionStage {
        let count = useCounts[feature, default: 0]
        return AdoptionStage.stage(forTotalUses: count)
    }

    /// Returns the total number of times a feature has been used.
    ///
    /// - Parameter feature: The feature to check.
    /// - Returns: Total interaction count across all action types.
    func getTotalUses(for feature: AppFeature) -> Int {
        return useCounts[feature, default: 0]
    }

    /// Returns the date the user first interacted with a feature.
    ///
    /// - Parameter feature: The feature to check.
    /// - Returns: The timestamp of the first recorded interaction, or nil if never used.
    func getFirstUseDate(for feature: AppFeature) -> Date? {
        return firstUseDates[feature]
    }

    /// Returns a full usage summary for a single feature.
    ///
    /// Computes action breakdowns, distinct days used, and discovery source counts
    /// from the persisted record history.
    ///
    /// - Parameter feature: The feature to summarize.
    /// - Returns: A ``FeatureUsageSummary`` with aggregated statistics.
    func getSummary(for feature: AppFeature) -> FeatureUsageSummary {
        return buildSummary(for: feature)
    }

    /// Returns usage summaries for all features that have at least one recorded interaction.
    ///
    /// - Returns: Array of ``FeatureUsageSummary`` sorted by total uses descending.
    func getAllUsedFeatureSummaries() -> [FeatureUsageSummary] {
        let usedFeatures = AppFeature.allCases.filter { (useCounts[$0] ?? 0) > 0 }
        return usedFeatures
            .map { buildSummary(for: $0) }
            .sorted { $0.totalUses > $1.totalUses }
    }

    /// Returns the most-used features, limited to the specified count.
    ///
    /// - Parameter limit: Maximum number of features to return (default: 10).
    /// - Returns: Array of ``FeatureUsageSummary`` sorted by total uses descending.
    func getTopFeatures(limit: Int = 10) -> [FeatureUsageSummary] {
        return Array(getAllUsedFeatureSummaries().prefix(limit))
    }

    /// Returns all features at a specific adoption stage.
    ///
    /// - Parameter stage: The adoption stage to filter by.
    /// - Returns: Array of features currently at the given stage.
    func getFeatures(atStage stage: AdoptionStage) -> [AppFeature] {
        return AppFeature.allCases.filter { getAdoptionStage(for: $0) == stage }
    }

    /// Returns features the user has never interacted with.
    ///
    /// Useful for identifying unadopted features and driving feature discovery campaigns.
    ///
    /// - Returns: Array of features with zero recorded interactions.
    func getUndiscoveredFeatures() -> [AppFeature] {
        return getFeatures(atStage: .new)
    }

    /// Returns features grouped by their category with usage counts.
    ///
    /// - Returns: Dictionary mapping each category to the count of features used at least once.
    func getCategoryAdoption() -> [FeatureCategory: Int] {
        var result: [FeatureCategory: Int] = [:]
        for feature in AppFeature.allCases {
            if (useCounts[feature] ?? 0) > 0 {
                result[feature.category, default: 0] += 1
            }
        }
        return result
    }

    /// Returns all records for a specific feature, optionally filtered by action.
    ///
    /// - Parameters:
    ///   - feature: The feature to retrieve records for.
    ///   - action: Optional action filter. If nil, all actions are included.
    /// - Returns: Array of ``FeatureUsageRecord`` sorted by timestamp ascending.
    func getRecords(for feature: AppFeature, action: FeatureAction? = nil) -> [FeatureUsageRecord] {
        var filtered = records.filter { $0.feature == feature }
        if let action = action {
            filtered = filtered.filter { $0.action == action }
        }
        return filtered.sorted { $0.timestamp < $1.timestamp }
    }

    /// Returns all records within a date range.
    ///
    /// - Parameters:
    ///   - startDate: The beginning of the date range (inclusive).
    ///   - endDate: The end of the date range (inclusive).
    /// - Returns: Array of ``FeatureUsageRecord`` within the range, sorted by timestamp ascending.
    func getRecords(from startDate: Date, to endDate: Date) -> [FeatureUsageRecord] {
        return records
            .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
            .sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Public API: Reports

    /// Generates a comprehensive adoption report across all features.
    ///
    /// Includes per-feature summaries, adoption distribution, category adoption,
    /// and top discovery sources.
    ///
    /// - Returns: A ``FeatureAdoptionReport`` snapshot.
    func getAdoptionReport() -> FeatureAdoptionReport {
        // Build per-feature summaries
        var summaries: [String: FeatureUsageSummary] = [:]
        for feature in AppFeature.allCases {
            let summary = buildSummary(for: feature)
            if summary.totalUses > 0 {
                summaries[feature.rawValue] = summary
            }
        }

        // Adoption distribution
        var adoptionDist: [AdoptionStage: Int] = [:]
        for stage in AdoptionStage.allCases {
            adoptionDist[stage] = getFeatures(atStage: stage).count
        }

        // Category adoption
        let categoryAdoption = getCategoryAdoption()

        // Top discovery sources
        var sourceCounts: [DiscoverySource: Int] = [:]
        for record in records {
            if let source = record.discoverySource {
                sourceCounts[source, default: 0] += 1
            }
        }

        let adoptedCount = AppFeature.allCases.filter { (useCounts[$0] ?? 0) > 0 }.count

        return FeatureAdoptionReport(
            generatedAt: Date(),
            featureSummaries: summaries,
            adoptionDistribution: adoptionDist,
            categoryAdoption: categoryAdoption,
            topDiscoverySources: sourceCounts,
            totalFeaturesTracked: AppFeature.allCases.count,
            totalFeaturesAdopted: adoptedCount
        )
    }

    /// Generates a formatted text report of feature usage and adoption.
    ///
    /// Suitable for debug consoles and diagnostic exports.
    ///
    /// - Returns: A multi-line formatted string summarizing feature adoption.
    func getFormattedReport() -> String {
        let report = getAdoptionReport()
        var lines: [String] = []

        lines.append("=== Feature Usage Report ===")
        lines.append("Generated: \(Self.reportDateFormatter.string(from: report.generatedAt))")
        lines.append("Total Features: \(report.totalFeaturesTracked)")
        lines.append("Features Adopted: \(report.totalFeaturesAdopted)")
        let adoptionRate = report.totalFeaturesTracked > 0
            ? Double(report.totalFeaturesAdopted) / Double(report.totalFeaturesTracked) * 100.0
            : 0
        lines.append("Adoption Rate: \(String(format: "%.1f", adoptionRate))%")
        lines.append("")

        // Adoption stage distribution
        lines.append("--- Adoption Distribution ---")
        for stage in AdoptionStage.allCases {
            let count = report.adoptionDistribution[stage] ?? 0
            lines.append("  \(stage.displayName): \(count)")
        }
        lines.append("")

        // Category adoption
        lines.append("--- Category Adoption ---")
        for category in FeatureCategory.allCases {
            let adopted = report.categoryAdoption[category] ?? 0
            let total = AppFeature.allCases.filter { $0.category == category }.count
            lines.append("  \(category.displayName): \(adopted)/\(total)")
        }
        lines.append("")

        // Top features
        let topFeatures = getTopFeatures(limit: 10)
        if !topFeatures.isEmpty {
            lines.append("--- Top 10 Features ---")
            for (index, summary) in topFeatures.enumerated() {
                lines.append("  \(index + 1). \(summary.feature.displayName): \(summary.totalUses) uses (\(summary.adoptionStage.displayName))")
            }
            lines.append("")
        }

        // Top discovery sources
        if !report.topDiscoverySources.isEmpty {
            lines.append("--- Top Discovery Sources ---")
            let sorted = report.topDiscoverySources.sorted { $0.value > $1.value }
            for (source, count) in sorted {
                lines.append("  \(source.rawValue): \(count)")
            }
            lines.append("")
        }

        // Undiscovered features
        let undiscovered = getUndiscoveredFeatures()
        if !undiscovered.isEmpty {
            lines.append("--- Undiscovered Features (\(undiscovered.count)) ---")
            for feature in undiscovered.prefix(15) {
                lines.append("  - \(feature.displayName) [\(feature.category.displayName)]")
            }
            if undiscovered.count > 15 {
                lines.append("  ... and \(undiscovered.count - 15) more")
            }
        }

        lines.append("================================")

        let formatted = lines.joined(separator: "\n")
        logger.info("FeatureUsage", "Generated adoption report (\(records.count) records, \(report.totalFeaturesAdopted) adopted)")
        return formatted
    }

    // MARK: - Public API: Maintenance

    /// Removes all records older than the specified date.
    ///
    /// Use this to keep the local record store from growing unbounded.
    ///
    /// - Parameter date: Records with timestamps before this date are removed.
    /// - Returns: The number of records removed.
    @discardableResult
    func pruneRecords(olderThan date: Date) -> Int {
        let beforeCount = records.count
        records.removeAll { $0.timestamp < date }
        let removed = beforeCount - records.count

        if removed > 0 {
            rebuildCaches()
            persistRecords()
            logger.info("FeatureUsage", "Pruned \(removed) records older than \(Self.reportDateFormatter.string(from: date))")
        }

        return removed
    }

    /// Removes all persisted records and resets in-memory caches.
    ///
    /// Intended for logout/account-switch scenarios.
    func reset() {
        records.removeAll()
        useCounts.removeAll()
        firstUseDates.removeAll()
        persistRecords()
        logger.info("FeatureUsage", "All feature usage data reset")
    }

    /// Returns the total number of persisted records.
    var recordCount: Int {
        records.count
    }

    // MARK: - Private Helpers

    /// Builds an aggregated summary for a single feature from the raw records.
    private func buildSummary(for feature: AppFeature) -> FeatureUsageSummary {
        let featureRecords = records.filter { $0.feature == feature }

        // Action breakdown
        var actionCounts: [FeatureAction: Int] = [:]
        for record in featureRecords {
            actionCounts[record.action, default: 0] += 1
        }

        // Date range
        let sortedByDate = featureRecords.sorted { $0.timestamp < $1.timestamp }
        let firstDate = sortedByDate.first?.timestamp
        let lastDate = sortedByDate.last?.timestamp

        // Distinct calendar days
        let dayStrings = Set(featureRecords.map { Self.calendarDayFormatter.string(from: $0.timestamp) })

        // Discovery sources
        var sourceCounts: [DiscoverySource: Int] = [:]
        for record in featureRecords {
            if let source = record.discoverySource {
                sourceCounts[source, default: 0] += 1
            }
        }

        let totalUses = featureRecords.count

        return FeatureUsageSummary(
            feature: feature,
            totalUses: totalUses,
            usesByAction: actionCounts,
            firstUsedDate: firstDate,
            lastUsedDate: lastDate,
            adoptionStage: AdoptionStage.stage(forTotalUses: totalUses),
            distinctDaysUsed: dayStrings.count,
            discoverySourceCounts: sourceCounts
        )
    }

    /// Rebuilds the in-memory caches from the persisted records array.
    private func rebuildCaches() {
        useCounts.removeAll()
        firstUseDates.removeAll()

        for record in records {
            useCounts[record.feature, default: 0] += 1

            if let existing = firstUseDates[record.feature] {
                if record.timestamp < existing {
                    firstUseDates[record.feature] = record.timestamp
                }
            } else {
                firstUseDates[record.feature] = record.timestamp
            }
        }
    }

    // MARK: - Persistence

    /// Saves all records to the local JSON file.
    private func persistRecords() {
        do {
            let data = try Self.encoder.encode(records)
            try data.write(to: persistenceURL, options: .atomic)
            logger.diagnostic("FeatureUsage: Persisted \(records.count) records to disk")
        } catch {
            logger.warning("FeatureUsage", "Failed to persist records: \(error.localizedDescription)")
        }
    }

    /// Loads previously persisted records from the local JSON file.
    private func loadPersistedRecords() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else {
            logger.diagnostic("FeatureUsage: No persisted records file found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: persistenceURL)
            let loaded = try Self.decoder.decode([FeatureUsageRecord].self, from: data)
            records = loaded
            logger.info("FeatureUsage", "Loaded \(loaded.count) persisted records from previous sessions")
        } catch {
            logger.warning("FeatureUsage", "Failed to load persisted records: \(error.localizedDescription)")
        }
    }
}

// MARK: - FeatureTracker (Convenience Alias)

/// Convenience namespace for quick feature tracking calls.
///
/// Provides a terse, ergonomic API that delegates to ``FeatureUsageTracker.shared``.
///
/// ```swift
/// await FeatureTracker.track(.workoutSession, action: .used)
/// await FeatureTracker.track(.aiCoach, action: .discovered, source: .todayHub)
/// await FeatureTracker.track(.programBuilder, action: .completed, metadata: ["exercise_count": "8"])
/// ```
enum FeatureTracker {

    /// Tracks a feature usage event. Shorthand for `FeatureUsageTracker.shared.track(...)`.
    ///
    /// - Parameters:
    ///   - feature: The app feature being interacted with.
    ///   - action: The type of interaction (discovered, used, completed).
    ///   - source: How the user navigated to this feature (nil if unknown).
    ///   - metadata: Feature-specific key-value pairs.
    static func track(
        _ feature: AppFeature,
        action: FeatureAction,
        source: DiscoverySource? = nil,
        metadata: [String: String] = [:]
    ) async {
        await shared.track(feature, action: action, source: source, metadata: metadata)
    }

    /// The shared ``FeatureUsageTracker`` instance.
    static var shared: FeatureUsageTracker {
        FeatureUsageTracker.shared
    }
}
