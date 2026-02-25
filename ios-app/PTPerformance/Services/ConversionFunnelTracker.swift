//
//  ConversionFunnelTracker.swift
//  PTPerformance
//
//  ACP-968: Subscription Conversion Tracking
//  Dedicated actor-based service for tracking the complete free-to-paid conversion funnel.
//  Tracks paywall impressions vs purchases, trial conversion rates, and revenue attribution by source.
//

import Foundation

// MARK: - Conversion Funnel Tracker

/// Actor-based service for tracking the complete free-to-paid subscription conversion funnel.
///
/// Records user progression through funnel stages from free user through paywall interaction
/// to purchase completion. Persists events locally for session-spanning analysis and
/// provides conversion rate calculations and attribution reporting.
///
/// ## Funnel Stages
/// `freeUser` -> `featureGateHit` -> `paywallImpression` -> `paywallEngaged` ->
/// `purchaseInitiated` -> `purchaseCompleted` (or `trialStarted` -> `trialConverted` / `trialCanceled`)
///
/// ## Usage
/// ```swift
/// await ConversionFunnelTracker.shared.recordStage(
///     .paywallImpression,
///     source: "ai_coach_limit",
///     tier: "pro",
///     revenue: nil,
///     paywallVariant: "feature_gate_standard"
/// )
///
/// let rate = await ConversionFunnelTracker.shared.getPaywallConversionRate()
/// ```
actor ConversionFunnelTracker {

    // MARK: - Singleton

    static let shared = ConversionFunnelTracker()

    // MARK: - Conversion Stage

    /// Stages in the free-to-paid conversion funnel, ordered from entry to completion.
    enum ConversionStage: String, CaseIterable, Codable, Sendable {
        /// User is on the free tier (funnel entry point)
        case freeUser = "free_user"
        /// User hit a premium feature gate
        case featureGateHit = "feature_gate_hit"
        /// Paywall was displayed to the user
        case paywallImpression = "paywall_impression"
        /// User interacted with the paywall (scrolled, tapped pricing, etc.)
        case paywallEngaged = "paywall_engaged"
        /// User initiated a purchase flow
        case purchaseInitiated = "purchase_initiated"
        /// Purchase was completed successfully
        case purchaseCompleted = "purchase_completed"
        /// User started a free trial
        case trialStarted = "trial_started"
        /// User converted from trial to paid subscription
        case trialConverted = "trial_converted"
        /// User canceled during trial period
        case trialCanceled = "trial_canceled"
    }

    // MARK: - Conversion Event

    /// A single recorded event in the conversion funnel.
    struct ConversionEvent: Codable, Sendable {
        /// The funnel stage this event represents
        let stage: ConversionStage
        /// When the event occurred
        let timestamp: Date
        /// What triggered this event (e.g. "ai_coach_limit", "export_feature", "manual")
        let source: String
        /// The A/B paywall variant shown, if applicable
        let paywallVariant: String?
        /// The subscription tier involved, if applicable (e.g. "pro", "elite")
        let tier: String?
        /// Revenue amount for purchase events, in dollars
        let revenue: Double?
    }

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    /// All recorded conversion events, loaded from and persisted to disk
    private var events: [ConversionEvent] = []

    /// File URL for persisting conversion events across sessions
    private let persistenceURL: URL = {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("conversion_funnel_events.json")
        }
        let appDirectory = directory.appendingPathComponent("PTPerformance", isDirectory: true)
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.appendingPathComponent("conversion_funnel_events.json")
    }()

    private nonisolated static let iso8601Encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private nonisolated static let iso8601Decoder: JSONDecoder = PTSupabaseClient.flexibleDecoder

    // MARK: - Initialization

    private init() {
        logger.info("ConversionFunnel", "ConversionFunnelTracker initialized")
        loadPersistedEvents()
    }

    // MARK: - Event Recording

    /// Records a conversion funnel stage event.
    ///
    /// Logs the event locally, persists to disk, and dispatches to the analytics tracker
    /// for backend synchronization.
    ///
    /// - Parameters:
    ///   - stage: The conversion funnel stage to record
    ///   - source: What triggered this stage (e.g. "ai_coach_limit", "export_feature", "manual", "onboarding")
    ///   - tier: The subscription tier involved, if applicable (e.g. "pro", "elite")
    ///   - revenue: Revenue amount in dollars for purchase events (nil for non-purchase stages)
    ///   - paywallVariant: The A/B paywall variant name, if a paywall was shown
    func recordStage(
        _ stage: ConversionStage,
        source: String,
        tier: String? = nil,
        revenue: Double? = nil,
        paywallVariant: String? = nil
    ) {
        let event = ConversionEvent(
            stage: stage,
            timestamp: Date(),
            source: source,
            paywallVariant: paywallVariant,
            tier: tier,
            revenue: revenue
        )

        events.append(event)
        persistEvents()

        // Build analytics properties
        var properties: [String: Any] = [
            "stage": stage.rawValue,
            "source": source
        ]
        if let tier = tier {
            properties["tier"] = tier
        }
        if let revenue = revenue {
            properties["revenue"] = revenue
        }
        if let paywallVariant = paywallVariant {
            properties["paywall_variant"] = paywallVariant
        }

        // Dispatch to AnalyticsTracker for backend sync
        analyticsTracker.track(event: "conversion_funnel_stage", properties: properties)

        logger.info("ConversionFunnel", "Recorded stage: \(stage.rawValue) | source: \(source) | tier: \(tier ?? "none") | variant: \(paywallVariant ?? "none") | revenue: \(revenue.map { String(format: "$%.2f", $0) } ?? "none")")
    }

    // MARK: - Conversion Rate Calculations

    /// Calculates the conversion rate between any two funnel stages.
    ///
    /// - Parameters:
    ///   - from: The entry stage (denominator)
    ///   - to: The target stage (numerator)
    /// - Returns: Conversion rate as a percentage (0-100), or nil if there are no events for the `from` stage
    func getConversionRate(from: ConversionStage, to: ConversionStage) -> Double? {
        let fromCount = events.filter { $0.stage == from }.count
        let toCount = events.filter { $0.stage == to }.count

        guard fromCount > 0 else { return nil }

        let rate = (Double(toCount) / Double(fromCount)) * 100.0
        logger.diagnostic("ConversionFunnel: Rate \(from.rawValue) -> \(to.rawValue) = \(String(format: "%.1f", rate))% (\(toCount)/\(fromCount))")
        return rate
    }

    /// Calculates the paywall-to-purchase conversion rate.
    ///
    /// Measures what percentage of paywall impressions result in a completed purchase.
    ///
    /// - Returns: Conversion rate as a percentage (0-100), or nil if there are no paywall impressions
    func getPaywallConversionRate() -> Double? {
        return getConversionRate(from: .paywallImpression, to: .purchaseCompleted)
    }

    /// Calculates the trial-to-paid conversion rate.
    ///
    /// Measures what percentage of trial starts result in a paid conversion.
    ///
    /// - Returns: Conversion rate as a percentage (0-100), or nil if there are no trial starts
    func getTrialConversionRate() -> Double? {
        return getConversionRate(from: .trialStarted, to: .trialConverted)
    }

    // MARK: - Attribution Report

    /// Generates a breakdown of completed conversions (purchases) by source.
    ///
    /// Counts how many `purchaseCompleted` events came from each attribution source
    /// (e.g. "ai_coach_limit", "export_feature", "manual").
    ///
    /// - Returns: Dictionary mapping source strings to their conversion counts, sorted by count descending
    func getAttributionReport() -> [String: Int] {
        let purchaseEvents = events.filter { $0.stage == .purchaseCompleted }
        var report: [String: Int] = [:]

        for event in purchaseEvents {
            report[event.source, default: 0] += 1
        }

        logger.info("ConversionFunnel", "Attribution report: \(report.count) sources, \(purchaseEvents.count) total conversions")
        return report
    }

    // MARK: - Conversion Report

    /// Generates a formatted text report of the conversion funnel.
    ///
    /// Includes counts per stage, key conversion rates, total revenue,
    /// and attribution breakdown by source.
    ///
    /// - Returns: A multi-line formatted string summarizing the conversion funnel
    func getConversionReport() -> String {
        var lines: [String] = []

        lines.append("=== Conversion Funnel Report ===")
        lines.append("Generated: \(Self.reportDateFormatter.string(from: Date()))")
        lines.append("Total Events: \(events.count)")
        lines.append("")

        // Stage counts
        lines.append("--- Stage Counts ---")
        for stage in ConversionStage.allCases {
            let count = events.filter { $0.stage == stage }.count
            lines.append("  \(stage.rawValue): \(count)")
        }
        lines.append("")

        // Key conversion rates
        lines.append("--- Key Conversion Rates ---")

        if let paywallRate = getPaywallConversionRate() {
            lines.append("  Paywall -> Purchase: \(String(format: "%.1f", paywallRate))%")
        } else {
            lines.append("  Paywall -> Purchase: N/A (no impressions)")
        }

        if let trialRate = getTrialConversionRate() {
            lines.append("  Trial -> Converted: \(String(format: "%.1f", trialRate))%")
        } else {
            lines.append("  Trial -> Converted: N/A (no trials)")
        }

        if let gateToImpressionRate = getConversionRate(from: .featureGateHit, to: .paywallImpression) {
            lines.append("  Feature Gate -> Paywall: \(String(format: "%.1f", gateToImpressionRate))%")
        }

        if let impressionToEngagedRate = getConversionRate(from: .paywallImpression, to: .paywallEngaged) {
            lines.append("  Paywall Impression -> Engaged: \(String(format: "%.1f", impressionToEngagedRate))%")
        }

        if let engagedToPurchaseRate = getConversionRate(from: .paywallEngaged, to: .purchaseCompleted) {
            lines.append("  Paywall Engaged -> Purchase: \(String(format: "%.1f", engagedToPurchaseRate))%")
        }
        lines.append("")

        // Revenue summary
        let totalRevenue = events
            .filter { $0.stage == .purchaseCompleted }
            .compactMap { $0.revenue }
            .reduce(0, +)
        lines.append("--- Revenue ---")
        lines.append("  Total Revenue: \(String(format: "$%.2f", totalRevenue))")
        lines.append("")

        // Attribution breakdown
        let attribution = getAttributionReport()
        if !attribution.isEmpty {
            lines.append("--- Attribution (Purchases by Source) ---")
            let sorted = attribution.sorted { $0.value > $1.value }
            for (source, count) in sorted {
                lines.append("  \(source): \(count)")
            }
        }

        lines.append("================================")

        let report = lines.joined(separator: "\n")
        logger.info("ConversionFunnel", "Generated conversion report (\(events.count) events)")
        return report
    }

    // MARK: - Persistence

    /// Saves all events to the local JSON file.
    private func persistEvents() {
        do {
            let data = try Self.iso8601Encoder.encode(events)
            try data.write(to: persistenceURL, options: .atomic)
            logger.diagnostic("ConversionFunnel: Persisted \(events.count) events to disk")
        } catch {
            logger.warning("ConversionFunnel", "Failed to persist events: \(error.localizedDescription)")
        }
    }

    /// Loads previously persisted events from the local JSON file.
    private func loadPersistedEvents() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else {
            logger.diagnostic("ConversionFunnel: No persisted events file found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: persistenceURL)
            let loaded = try Self.iso8601Decoder.decode([ConversionEvent].self, from: data)
            events = loaded
            logger.info("ConversionFunnel", "Loaded \(loaded.count) persisted events from previous sessions")
        } catch {
            logger.warning("ConversionFunnel", "Failed to load persisted events: \(error.localizedDescription)")
        }
    }

    // MARK: - Formatters

    private nonisolated static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
