//
//  Experiment.swift
//  PTPerformance
//
//  ACP-971: A/B Testing Framework — Data Models
//  Defines experiment configuration, variant definitions, traffic allocation,
//  lifecycle states, and deterministic hash-based assignment logic.
//
//  ## Design
//  - An `Experiment` contains one or more `ExperimentVariant`s, each with a
//    traffic weight that determines allocation percentages.
//  - Feature flags are modeled as a two-variant experiment (control=off, treatment=on).
//  - Variant assignment uses a SHA-256 hash of `userId + experimentId` to produce
//    a deterministic bucket in [0, 10000). This guarantees the same user always
//    sees the same variant for a given experiment, across sessions and reinstalls
//    (as long as userId is stable).
//  - Experiments follow a lifecycle: draft -> running -> paused -> concluded.
//

import Foundation
import CryptoKit

// MARK: - Experiment Lifecycle

/// The lifecycle stage of an experiment.
///
/// Experiments progress linearly through stages, though they may be paused
/// and resumed. Only `running` experiments assign variants to users.
///
/// ```
/// draft -> running -> concluded
///             |           ^
///             v           |
///           paused -------+
/// ```
enum ExperimentStatus: String, Codable, Sendable, CaseIterable {
    /// Experiment is configured but not yet launched.
    case draft

    /// Experiment is actively assigning users to variants and tracking events.
    case running

    /// Experiment is temporarily halted. Existing assignments are preserved
    /// but no new users are enrolled.
    case paused

    /// Experiment has finished. Results are final. No new assignments are made,
    /// and the winning variant (if any) is served to all users.
    case concluded
}

// MARK: - Experiment Variant

/// A single variant within an experiment.
///
/// Each variant has a `weight` that determines its share of traffic. Weights
/// are relative — a two-variant experiment with weights [50, 50] splits
/// traffic 50/50, while [1, 3] splits 25/75.
struct ExperimentVariant: Codable, Identifiable, Equatable, Sendable {

    /// Unique identifier for this variant.
    let id: String

    /// Human-readable name (e.g. "control", "treatment_large_cta").
    let name: String

    /// Relative traffic weight. Must be > 0. The actual allocation percentage
    /// is `weight / sum(all variant weights) * 100`.
    let weight: Double

    /// Arbitrary key-value configuration for this variant.
    /// Views can read these to vary behavior per-variant.
    /// For example: `["cta_text": "Start Free Trial", "show_discount": "true"]`
    let payload: [String: String]

    /// Whether this variant represents the "on" state for feature flags.
    let isFeatureFlagEnabled: Bool

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case weight
        case payload
        case isFeatureFlagEnabled = "is_feature_flag_enabled"
    }

    // MARK: - Convenience Initializers

    init(
        id: String = UUID().uuidString,
        name: String,
        weight: Double,
        payload: [String: String] = [:],
        isFeatureFlagEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.weight = max(weight, 0)
        self.payload = payload
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
    }
}

// MARK: - Experiment

/// Configuration for a single A/B test experiment.
///
/// An experiment defines:
/// - A set of variants with traffic allocation weights
/// - A lifecycle status controlling enrollment behavior
/// - Optional start/end dates for scheduled experiments
/// - A winning variant (set when the experiment is concluded)
///
/// ## Feature Flags
/// Feature flags are a special case where an experiment has exactly two variants:
/// `control` (feature off) and `treatment` (feature on). Use the static factory
/// `Experiment.featureFlag(...)` to create these.
struct Experiment: Codable, Identifiable, Equatable, Sendable {

    /// Unique experiment identifier (e.g. "onboarding_v2", "new_paywall_layout").
    let id: String

    /// Human-readable name for dashboards and logging.
    let name: String

    /// Description of the experiment hypothesis and what is being tested.
    let description: String

    /// The ordered set of variants. Must contain at least one variant.
    let variants: [ExperimentVariant]

    /// Current lifecycle status.
    var status: ExperimentStatus

    /// When the experiment should start accepting enrollments.
    /// If nil, the experiment starts immediately when status is set to `.running`.
    let startDate: Date?

    /// When the experiment should stop accepting new enrollments.
    /// If nil, the experiment runs until manually concluded.
    let endDate: Date?

    /// The ID of the winning variant, set when the experiment is concluded.
    /// When set, all users (including new ones) receive this variant.
    var winningVariantId: String?

    /// Whether this experiment represents a feature flag (on/off toggle).
    let isFeatureFlag: Bool

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case variants
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case winningVariantId = "winning_variant_id"
        case isFeatureFlag = "is_feature_flag"
    }

    // MARK: - Computed Properties

    /// Whether the experiment is currently accepting new variant assignments.
    ///
    /// An experiment is active when:
    /// 1. Its status is `.running`
    /// 2. The current date is within the start/end window (if dates are set)
    var isActive: Bool {
        guard status == .running else { return false }
        let now = Date()
        if let start = startDate, now < start { return false }
        if let end = endDate, now > end { return false }
        return true
    }

    /// Returns the winning variant if the experiment is concluded and one has been chosen.
    var winningVariant: ExperimentVariant? {
        guard status == .concluded, let winnerId = winningVariantId else { return nil }
        return variants.first { $0.id == winnerId }
    }

    // MARK: - Initializer

    init(
        id: String,
        name: String,
        description: String = "",
        variants: [ExperimentVariant],
        status: ExperimentStatus = .draft,
        startDate: Date? = nil,
        endDate: Date? = nil,
        winningVariantId: String? = nil,
        isFeatureFlag: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.variants = variants
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.winningVariantId = winningVariantId
        self.isFeatureFlag = isFeatureFlag
    }

    // MARK: - Factory Methods

    /// Creates a feature flag experiment with control (off) and treatment (on) variants.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the feature flag.
    ///   - name: Human-readable name.
    ///   - description: What the feature flag controls.
    ///   - enabledPercentage: Percentage of users who should see the feature enabled (0-100).
    ///   - status: Initial lifecycle status (default: `.draft`).
    /// - Returns: A configured feature flag experiment.
    static func featureFlag(
        id: String,
        name: String,
        description: String = "",
        enabledPercentage: Double = 50,
        status: ExperimentStatus = .draft
    ) -> Experiment {
        let controlWeight = max(100 - enabledPercentage, 0)
        let treatmentWeight = max(enabledPercentage, 0)

        let control = ExperimentVariant(
            id: "\(id)_control",
            name: "control",
            weight: controlWeight,
            isFeatureFlagEnabled: false
        )
        let treatment = ExperimentVariant(
            id: "\(id)_treatment",
            name: "treatment",
            weight: treatmentWeight,
            isFeatureFlagEnabled: true
        )

        return Experiment(
            id: id,
            name: name,
            description: description,
            variants: [control, treatment],
            status: status,
            isFeatureFlag: true
        )
    }
}

// MARK: - Deterministic Assignment

/// Hash-based deterministic variant assignment.
///
/// Uses SHA-256 to hash the concatenation of `userId` and `experimentId`,
/// then maps the hash to a bucket in [0, 10000) for fine-grained (0.01%)
/// allocation resolution. The bucket is then matched against cumulative
/// variant weights to select a variant.
///
/// This approach guarantees:
/// - The same user always gets the same variant for the same experiment
/// - Assignment is uniform and statistically unbiased
/// - No network call is required — assignment is purely local
/// - Assignment survives app reinstalls (as long as userId is stable)
enum ExperimentAssignment {

    /// The number of buckets used for traffic allocation.
    /// 10,000 buckets = 0.01% resolution.
    private static let totalBuckets: Int = 10_000

    /// Deterministically assigns a variant for a given user and experiment.
    ///
    /// - Parameters:
    ///   - userId: The stable user identifier used for hashing.
    ///   - experiment: The experiment containing the variants to assign from.
    /// - Returns: The assigned variant, or `nil` if the experiment has no variants.
    static func assign(userId: String, experiment: Experiment) -> ExperimentVariant? {
        // If experiment is concluded with a winner, always return that
        if let winner = experiment.winningVariant {
            return winner
        }

        let variants = experiment.variants
        guard !variants.isEmpty else { return nil }
        guard variants.count > 1 else { return variants[0] }

        let bucket = computeBucket(userId: userId, experimentId: experiment.id)
        return selectVariant(bucket: bucket, variants: variants)
    }

    /// Computes a deterministic bucket in [0, totalBuckets) from userId + experimentId.
    ///
    /// Uses SHA-256 and takes the first 8 bytes of the hash as a UInt64,
    /// then maps it to the bucket range via modulo.
    ///
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - experimentId: The experiment identifier.
    /// - Returns: An integer in [0, 10000).
    static func computeBucket(userId: String, experimentId: String) -> Int {
        let input = "\(userId):\(experimentId)"
        let inputData = Data(input.utf8)
        let hash = SHA256.hash(data: inputData)

        // Take the first 8 bytes and interpret as a UInt64
        let hashBytes = Array(hash)
        var value: UInt64 = 0
        for i in 0..<8 {
            value = (value << 8) | UInt64(hashBytes[i])
        }

        return Int(value % UInt64(totalBuckets))
    }

    /// Selects a variant based on the bucket value and variant weights.
    ///
    /// Normalizes weights to the total bucket space and walks through
    /// cumulative weight ranges to find which variant the bucket falls into.
    ///
    /// - Parameters:
    ///   - bucket: The hash bucket in [0, totalBuckets).
    ///   - variants: The list of variants with their traffic weights.
    /// - Returns: The selected variant.
    private static func selectVariant(bucket: Int, variants: [ExperimentVariant]) -> ExperimentVariant {
        let totalWeight = variants.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return variants[0] }

        // Normalize the bucket to the weight space
        let normalizedPosition = Double(bucket) / Double(totalBuckets) * totalWeight

        var cumulativeWeight: Double = 0
        for variant in variants {
            cumulativeWeight += variant.weight
            if normalizedPosition < cumulativeWeight {
                return variant
            }
        }

        // Fallback for floating-point edge case — return last variant
        return variants[variants.count - 1]
    }
}

// MARK: - Variant Assignment Record

/// A persisted record of a user's variant assignment for an experiment.
///
/// Stored locally in UserDefaults via ``ABTestingService`` to ensure sticky
/// assignments across app sessions.
struct VariantAssignmentRecord: Codable, Sendable {
    /// The experiment this assignment belongs to.
    let experimentId: String

    /// The assigned variant ID.
    let variantId: String

    /// The assigned variant name (for logging and analytics).
    let variantName: String

    /// When the assignment was first made.
    let assignedAt: Date

    /// Whether exposure has been tracked for this assignment.
    var exposureTracked: Bool

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case assignedAt = "assigned_at"
        case exposureTracked = "exposure_tracked"
    }

    init(
        experimentId: String,
        variantId: String,
        variantName: String,
        assignedAt: Date = Date(),
        exposureTracked: Bool = false
    ) {
        self.experimentId = experimentId
        self.variantId = variantId
        self.variantName = variantName
        self.assignedAt = assignedAt
        self.exposureTracked = exposureTracked
    }
}

// MARK: - Experiment Exposure Event

/// An analytics event record for experiment exposure or conversion tracking.
///
/// Sent to the analytics pipeline when a user is first exposed to a variant
/// or when a conversion event occurs.
struct ExperimentEvent: Codable, Sendable {
    /// The experiment this event belongs to.
    let experimentId: String

    /// The variant the user was assigned to.
    let variantId: String

    /// The variant name (for readability in analytics).
    let variantName: String

    /// The type of event ("exposure", "conversion", or a custom event name).
    let eventType: String

    /// The user who triggered the event.
    let userId: String

    /// When the event occurred.
    let timestamp: Date

    /// Additional metadata (e.g., conversion value, screen name).
    let metadata: [String: String]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case eventType = "event_type"
        case userId = "user_id"
        case timestamp
        case metadata
    }

    init(
        experimentId: String,
        variantId: String,
        variantName: String,
        eventType: String,
        userId: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.experimentId = experimentId
        self.variantId = variantId
        self.variantName = variantName
        self.eventType = eventType
        self.userId = userId
        self.timestamp = timestamp
        self.metadata = metadata
    }
}
