//
//  PricingExperimentService.swift
//  PTPerformance
//
//  ACP-988: Pricing Experimentation
//  Service for managing A/B pricing experiments with sticky variant assignment,
//  Supabase-backed experiment configuration, and event tracking.
//

import Foundation
import Supabase

// MARK: - Pricing Experiment Models

/// Configuration for a pricing A/B test experiment
struct PricingExperiment: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let variants: [PricingVariant]
    let startDate: Date
    let endDate: Date?
    let isActive: Bool

    /// Whether the experiment is currently running
    var isRunning: Bool {
        guard isActive else { return false }
        let now = Date()
        if now < startDate { return false }
        if let end = endDate, now > end { return false }
        return true
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case variants
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }
}

/// A pricing variant within an experiment
struct PricingVariant: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let monthlyPrice: Double
    let annualPrice: Double
    let trialDays: Int
    let weight: Double // traffic allocation percentage (0-100)

    var formattedMonthlyPrice: String {
        formatPrice(monthlyPrice)
    }

    var formattedAnnualPrice: String {
        formatPrice(annualPrice)
    }

    var formattedAnnualMonthlyPrice: String {
        formatPrice(annualPrice / 12.0)
    }

    /// Annual savings percentage compared to monthly
    var annualSavingsPercent: Int {
        guard monthlyPrice > 0 else { return 0 }
        let monthlyTotal = monthlyPrice * 12
        let savings = (monthlyTotal - annualPrice) / monthlyTotal * 100
        return Int(savings)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case monthlyPrice = "monthly_price"
        case annualPrice = "annual_price"
        case trialDays = "trial_days"
        case weight
    }

    // MARK: - Helpers

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

/// An experiment event record for analytics
struct PricingExperimentEvent: Codable {
    let experimentId: String
    let variantId: String
    let userId: String
    let event: String
    let timestamp: Date
    let metadata: [String: String]?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case variantId = "variant_id"
        case userId = "user_id"
        case event
        case timestamp
        case metadata
    }
}

// MARK: - Pricing Experiment Service

/// Service for managing pricing A/B experiments with sticky variant assignments
///
/// Fetches active experiments from Supabase on app launch, assigns users to
/// variants deterministically (sticky via UserDefaults), and tracks experiment
/// events for conversion analysis.
///
/// ## Usage Example
/// ```swift
/// let service = PricingExperimentService.shared
///
/// // Fetch experiments on launch
/// await service.fetchActiveExperiments()
///
/// // Get pricing for a specific experiment
/// let variant = service.assignVariant(for: "pricing-v2")
/// print("Monthly: \(variant.formattedMonthlyPrice)")
///
/// // Record conversion
/// service.recordExperimentEvent("purchase", variant: variant)
/// ```
final class PricingExperimentService: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = PricingExperimentService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    // MARK: - State

    /// Currently active experiments fetched from Supabase
    private var activeExperiments: [PricingExperiment] = []

    /// Lock for thread-safe experiment access
    private let lock = NSLock()

    // MARK: - Default Pricing

    /// Default pricing used when no experiment is active
    static let defaultVariant = PricingVariant(
        id: "default",
        name: "Default",
        monthlyPrice: 29.99,
        annualPrice: 249.99,
        trialDays: 7,
        weight: 100
    )

    // MARK: - UserDefaults Keys

    private enum DefaultsKeys {
        static let assignmentPrefix = "pricing_experiment_variant_"
        static let cachedExperiments = "pricing_experiments_cache"
    }

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        logger.info("PricingExperiment", "Service initialized")
        restoreCachedExperiments()
    }

    // MARK: - Experiment Fetching

    /// Fetch active experiments from Supabase
    ///
    /// Should be called on app launch to ensure fresh experiment configuration.
    /// Falls back to cached experiments if the network request fails.
    func fetchActiveExperiments() async {
        do {
            let response = try await supabase.client
                .from("pricing_experiments")
                .select("id, name, variants, start_date, end_date, is_active")
                .eq("is_active", value: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let experiments = try decoder.decode([PricingExperiment].self, from: response.data)

            lock.lock()
            activeExperiments = experiments.filter { $0.isRunning }
            lock.unlock()

            persistExperiments(activeExperiments)
            logger.success("PricingExperiment", "Fetched \(activeExperiments.count) active experiments")
        } catch {
            if error.isCancellation {
                logger.diagnostic("[PricingExperiment]Experiment fetch cancelled")
            } else {
                logger.warning("PricingExperiment", "Failed to fetch experiments: \(error.localizedDescription). Using cached data.")
            }
        }
    }

    /// Get all currently active experiments
    func getActiveExperiments() -> [PricingExperiment] {
        lock.lock()
        defer { lock.unlock() }
        return activeExperiments
    }

    /// Get a specific experiment by ID
    func getExperiment(id: String) -> PricingExperiment? {
        lock.lock()
        defer { lock.unlock() }
        return activeExperiments.first { $0.id == id }
    }

    // MARK: - Variant Assignment

    /// Assign a pricing variant for the given experiment
    ///
    /// Uses sticky assignment stored in UserDefaults so the same user always
    /// sees the same variant within an experiment. If no experiment is found
    /// or the experiment has ended, returns the default pricing variant.
    ///
    /// - Parameter experimentId: The experiment identifier
    /// - Returns: The assigned pricing variant
    func assignVariant(for experimentId: String) -> PricingVariant {
        lock.lock()
        let experiment = activeExperiments.first { $0.id == experimentId }
        lock.unlock()

        guard let experiment = experiment, experiment.isRunning, !experiment.variants.isEmpty else {
            logger.info("PricingExperiment", "No active experiment '\(experimentId)', returning default pricing")
            return Self.defaultVariant
        }

        // Check for existing sticky assignment
        let assignmentKey = DefaultsKeys.assignmentPrefix + experimentId
        if let existingVariantId = UserDefaults.standard.string(forKey: assignmentKey),
           let existingVariant = experiment.variants.first(where: { $0.id == existingVariantId }) {
            logger.diagnostic("[PricingExperiment]Returning sticky assignment: variant '\(existingVariant.name)' for experiment '\(experimentId)'")
            return existingVariant
        }

        // Assign a new variant based on weights
        let assigned = selectVariantByWeight(from: experiment.variants)
        UserDefaults.standard.set(assigned.id, forKey: assignmentKey)

        logger.info("PricingExperiment", "Assigned variant '\(assigned.name)' (monthly: \(assigned.formattedMonthlyPrice)) for experiment '\(experimentId)'")

        // Track the assignment event
        analyticsTracker.track(event: "pricing_experiment_assigned", properties: [
            "experiment_id": experimentId,
            "variant_id": assigned.id,
            "variant_name": assigned.name,
            "monthly_price": assigned.monthlyPrice,
            "annual_price": assigned.annualPrice,
            "trial_days": assigned.trialDays
        ])

        return assigned
    }

    /// Get the currently assigned variant for an experiment without creating a new assignment
    ///
    /// - Parameter experimentId: The experiment identifier
    /// - Returns: The assigned variant, or nil if no assignment exists
    func currentAssignment(for experimentId: String) -> PricingVariant? {
        let assignmentKey = DefaultsKeys.assignmentPrefix + experimentId

        guard let variantId = UserDefaults.standard.string(forKey: assignmentKey) else {
            return nil
        }

        lock.lock()
        let experiment = activeExperiments.first { $0.id == experimentId }
        lock.unlock()

        return experiment?.variants.first { $0.id == variantId }
    }

    // MARK: - Event Tracking

    /// Record an experiment event (e.g., "viewed_paywall", "started_trial", "purchased")
    ///
    /// Events are tracked both locally via AnalyticsTracker and synced to Supabase
    /// for experiment analysis.
    ///
    /// - Parameters:
    ///   - event: The event name (e.g., "purchase", "paywall_view")
    ///   - variant: The pricing variant the user is seeing
    ///   - metadata: Additional metadata key-value pairs
    func recordExperimentEvent(
        _ event: String,
        variant: PricingVariant,
        metadata: [String: String]? = nil
    ) {
        guard let userId = supabase.userId else {
            logger.warning("PricingExperiment", "Cannot record event: no user ID available")
            return
        }

        // Find which experiment this variant belongs to
        lock.lock()
        let experiment = activeExperiments.first { exp in
            exp.variants.contains(where: { $0.id == variant.id })
        }
        lock.unlock()

        let experimentId = experiment?.id ?? "unknown"

        logger.info("PricingExperiment", "Recording event '\(event)' for experiment '\(experimentId)', variant '\(variant.name)'")

        // Track via AnalyticsTracker
        var properties: [String: Any] = [
            "experiment_id": experimentId,
            "variant_id": variant.id,
            "variant_name": variant.name,
            "monthly_price": variant.monthlyPrice,
            "annual_price": variant.annualPrice
        ]
        if let metadata = metadata {
            for (key, value) in metadata {
                properties["meta_\(key)"] = value
            }
        }
        analyticsTracker.track(event: "pricing_experiment_\(event)", properties: properties)

        // Async sync to Supabase
        let experimentEvent = PricingExperimentEvent(
            experimentId: experimentId,
            variantId: variant.id,
            userId: userId,
            event: event,
            timestamp: Date(),
            metadata: metadata
        )

        Task {
            await syncExperimentEvent(experimentEvent)
        }
    }

    // MARK: - Private Helpers

    /// Select a variant based on weighted random distribution
    private func selectVariantByWeight(from variants: [PricingVariant]) -> PricingVariant {
        let totalWeight = variants.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return variants.first ?? Self.defaultVariant
        }

        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulativeWeight: Double = 0

        for variant in variants {
            cumulativeWeight += variant.weight
            if randomValue < cumulativeWeight {
                return variant
            }
        }

        // Fallback: return last variant (should not normally reach here)
        return variants.last ?? Self.defaultVariant
    }

    /// Sync an experiment event to Supabase
    private func syncExperimentEvent(_ event: PricingExperimentEvent) async {
        do {
            try await supabase.client
                .from("pricing_experiment_events")
                .insert(event)
                .execute()

            logger.diagnostic("[PricingExperiment]Synced experiment event '\(event.event)' to Supabase")
        } catch {
            if !error.isCancellation {
                logger.warning("PricingExperiment", "Failed to sync experiment event: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Experiment Caching

    private func persistExperiments(_ experiments: [PricingExperiment]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(experiments)
            UserDefaults.standard.set(data, forKey: DefaultsKeys.cachedExperiments)
        } catch {
            logger.warning("PricingExperiment", "Failed to cache experiments: \(error.localizedDescription)")
        }
    }

    private func restoreCachedExperiments() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKeys.cachedExperiments) else { return }

        do {
            let decoder = PTSupabaseClient.flexibleDecoder
            let experiments = try decoder.decode([PricingExperiment].self, from: data)
            lock.lock()
            activeExperiments = experiments.filter { $0.isRunning }
            lock.unlock()

            if !activeExperiments.isEmpty {
                logger.info("PricingExperiment", "Restored \(activeExperiments.count) cached experiments")
            }
        } catch {
            logger.warning("PricingExperiment", "Failed to restore cached experiments: \(error.localizedDescription)")
        }
    }

    /// Clear all variant assignments (useful for testing or user reset)
    func clearAllAssignments() {
        lock.lock()
        let experiments = activeExperiments
        lock.unlock()

        for experiment in experiments {
            let key = DefaultsKeys.assignmentPrefix + experiment.id
            UserDefaults.standard.removeObject(forKey: key)
        }
        logger.info("PricingExperiment", "Cleared all variant assignments")
    }
}
