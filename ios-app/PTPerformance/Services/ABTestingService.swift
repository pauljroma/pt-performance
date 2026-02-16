//
//  ABTestingService.swift
//  PTPerformance
//
//  ACP-971: A/B Testing Framework — Service Layer
//  Manages experiment registration, deterministic variant assignment, exposure
//  tracking, conversion tracking, and provides a SwiftUI property wrapper API.
//
//  ## Architecture
//  - `ABTestingService` is the central coordinator (actor-based singleton).
//  - Experiments are registered at app launch via `registerExperiment(_:)`.
//  - Variant assignments are deterministic (hash-based) and persisted to
//    UserDefaults for sticky cross-session behavior.
//  - Exposure events fire once per experiment per session (deduped).
//  - Conversion events can fire multiple times with optional metadata.
//  - All events flow through `AnalyticsSDK` and `AnalyticsTracker`.
//
//  ## SwiftUI Integration
//  Use `@ABTestVariant("experiment_id")` in SwiftUI views for automatic
//  variant resolution and exposure tracking:
//  ```swift
//  struct MyView: View {
//      @ABTestVariant("new_onboarding") var variant
//
//      var body: some View {
//          if variant.name == "treatment" {
//              NewOnboardingView()
//          } else {
//              ClassicOnboardingView()
//          }
//      }
//  }
//  ```
//
//  ## Feature Flags
//  For boolean feature flags, use `isFeatureEnabled(_:)`:
//  ```swift
//  if await ABTestingService.shared.isFeatureEnabled("dark_mode_v2") {
//      applyDarkModeV2()
//  }
//  ```
//

import Foundation
import SwiftUI
import Combine

// MARK: - ABTestingService

/// Actor-based singleton that manages A/B test experiments, variant assignment,
/// and event tracking for the PT Performance app.
///
/// ## Lifecycle
/// 1. Register experiments at app launch via `registerExperiment(_:)`.
/// 2. Assign variants via `getVariant(for:)` or the `@ExperimentVariant` property wrapper.
/// 3. Track exposure automatically (first time a variant is accessed per session).
/// 4. Track conversions via `trackConversion(experimentId:metadata:)`.
///
/// ## Thread Safety
/// All mutable state is isolated within the actor. The SwiftUI property wrapper
/// bridges to the actor via `Task` for non-blocking UI integration.
actor ABTestingService {

    // MARK: - Singleton

    static let shared = ABTestingService()

    // MARK: - Dependencies

    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    // MARK: - State

    /// Registered experiments keyed by experiment ID.
    private var experiments: [String: Experiment] = [:]

    /// Persisted variant assignment records keyed by experiment ID.
    private var assignments: [String: VariantAssignmentRecord] = [:]

    /// Set of experiment IDs for which exposure has been tracked this session.
    /// Cleared on each app launch to ensure at-most-once-per-session exposure tracking.
    private var sessionExposures: Set<String> = []

    /// The current user ID used for deterministic hashing.
    /// Set via `setUserId(_:)` after authentication.
    private var userId: String?

    // MARK: - UserDefaults Keys

    private enum DefaultsKeys {
        static let assignments = "ab_testing_assignments"
        static let userId = "ab_testing_user_id"
    }

    // MARK: - JSON Coders

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {
        restoreAssignments()
        restoreUserId()
        logger.info("ABTesting", "Service initialized (\(assignments.count) persisted assignments)")
    }

    // MARK: - User Identity

    /// Sets the user ID used for deterministic variant assignment.
    ///
    /// Must be called after authentication. If the user ID changes (e.g.,
    /// different account login), existing assignments are cleared because
    /// the new user should get their own deterministic assignments.
    ///
    /// - Parameter userId: The authenticated user's stable identifier.
    func setUserId(_ userId: String) {
        let previousUserId = self.userId
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: DefaultsKeys.userId)

        // If the user changed, clear assignments so the new user gets fresh bucketing
        if let previous = previousUserId, previous != userId {
            logger.info("ABTesting", "User changed from \(previous) to \(userId), clearing assignments")
            clearAllAssignments()
        }

        logger.info("ABTesting", "User ID set: \(userId)")
    }

    /// Clears the user identity and all assignments (call on logout).
    func reset() {
        userId = nil
        sessionExposures.removeAll()
        UserDefaults.standard.removeObject(forKey: DefaultsKeys.userId)
        logger.info("ABTesting", "Service reset (user cleared)")
    }

    // MARK: - Experiment Registration

    /// Registers an experiment with the service.
    ///
    /// Experiments must be registered before variants can be assigned. Typically
    /// called once during app initialization.
    ///
    /// If an experiment with the same ID is already registered, it is replaced.
    /// Existing variant assignments are preserved if the variant still exists
    /// in the updated experiment definition.
    ///
    /// - Parameter experiment: The experiment configuration to register.
    func registerExperiment(_ experiment: Experiment) {
        let previousExperiment = experiments[experiment.id]
        experiments[experiment.id] = experiment

        // Validate that any existing assignment still references a valid variant
        if let assignment = assignments[experiment.id] {
            let variantStillExists = experiment.variants.contains { $0.id == assignment.variantId }
            if !variantStillExists {
                // Variant was removed from the experiment — clear the stale assignment
                assignments.removeValue(forKey: experiment.id)
                persistAssignments()
                logger.warning("ABTesting", "Cleared stale assignment for experiment '\(experiment.id)': variant '\(assignment.variantId)' no longer exists")
            }
        }

        let status = previousExperiment == nil ? "registered" : "updated"
        logger.info("ABTesting", "Experiment \(status): '\(experiment.id)' (\(experiment.variants.count) variants, status=\(experiment.status.rawValue))")
    }

    /// Registers multiple experiments at once.
    ///
    /// Convenience wrapper around `registerExperiment(_:)` for bulk registration.
    ///
    /// - Parameter experiments: The experiments to register.
    func registerExperiments(_ experiments: [Experiment]) {
        for experiment in experiments {
            registerExperiment(experiment)
        }
    }

    /// Removes an experiment from the registry and clears its assignment.
    ///
    /// - Parameter experimentId: The experiment to remove.
    func unregisterExperiment(_ experimentId: String) {
        experiments.removeValue(forKey: experimentId)
        assignments.removeValue(forKey: experimentId)
        sessionExposures.remove(experimentId)
        persistAssignments()
        logger.info("ABTesting", "Experiment unregistered: '\(experimentId)'")
    }

    // MARK: - Variant Assignment

    /// Returns the assigned variant for an experiment.
    ///
    /// This is the primary API for accessing a user's variant. The method:
    /// 1. Returns the persisted (sticky) assignment if one exists.
    /// 2. Otherwise, computes a deterministic assignment using hash(userId + experimentId).
    /// 3. Persists the new assignment for future sessions.
    /// 4. Tracks an exposure event (at most once per session per experiment).
    ///
    /// If the experiment is not registered, not active, or no user ID is set,
    /// returns `nil`.
    ///
    /// - Parameters:
    ///   - experimentId: The experiment to get a variant for.
    ///   - trackExposure: Whether to auto-track exposure. Defaults to `true`.
    ///     Set to `false` if you need the variant for logic without triggering
    ///     an exposure event (e.g., pre-fetching or conditional checks).
    /// - Returns: The assigned variant, or `nil` if assignment is not possible.
    func getVariant(for experimentId: String, trackExposure: Bool = true) -> ExperimentVariant? {
        guard let experiment = experiments[experimentId] else {
            logger.diagnostic("[ABTesting] Experiment '\(experimentId)' not registered")
            return nil
        }

        // If concluded with a winner, always return the winner
        if let winner = experiment.winningVariant {
            if trackExposure { trackExposureEvent(experimentId: experimentId, variant: winner) }
            return winner
        }

        // Experiment must be active for new assignments
        guard experiment.isActive || assignments[experimentId] != nil else {
            logger.diagnostic("[ABTesting] Experiment '\(experimentId)' is not active (status=\(experiment.status.rawValue))")
            // Return existing assignment even if experiment is paused
            if let existingAssignment = assignments[experimentId],
               let variant = experiment.variants.first(where: { $0.id == existingAssignment.variantId }) {
                if trackExposure { trackExposureEvent(experimentId: experimentId, variant: variant) }
                return variant
            }
            return nil
        }

        // Return sticky assignment if it exists
        if let existingAssignment = assignments[experimentId],
           let variant = experiment.variants.first(where: { $0.id == existingAssignment.variantId }) {
            if trackExposure { trackExposureEvent(experimentId: experimentId, variant: variant) }
            return variant
        }

        // Need a userId for deterministic assignment
        guard let userId = userId else {
            logger.warning("ABTesting", "Cannot assign variant for '\(experimentId)': no user ID set")
            return nil
        }

        // Compute deterministic assignment
        guard let variant = ExperimentAssignment.assign(userId: userId, experiment: experiment) else {
            logger.warning("ABTesting", "Assignment failed for experiment '\(experimentId)': no variants")
            return nil
        }

        // Persist the assignment
        let record = VariantAssignmentRecord(
            experimentId: experimentId,
            variantId: variant.id,
            variantName: variant.name
        )
        assignments[experimentId] = record
        persistAssignments()

        logger.info("ABTesting", "Assigned variant '\(variant.name)' for experiment '\(experimentId)' (userId=\(userId))")

        // Track assignment event via analytics
        analyticsTracker.track(event: "experiment_assigned", properties: [
            "experiment_id": experimentId,
            "experiment_name": experiment.name,
            "variant_id": variant.id,
            "variant_name": variant.name,
            "is_feature_flag": experiment.isFeatureFlag
        ])

        if trackExposure { trackExposureEvent(experimentId: experimentId, variant: variant) }

        return variant
    }

    /// Returns the assigned variant name for an experiment, or "control" if not assigned.
    ///
    /// Convenience wrapper around `getVariant(for:)` for simple name-based branching.
    ///
    /// - Parameter experimentId: The experiment to check.
    /// - Returns: The variant name, or "control" if not assigned.
    func getVariantName(for experimentId: String) -> String {
        return getVariant(for: experimentId)?.name ?? "control"
    }

    /// Returns the variant payload value for a specific key.
    ///
    /// Useful for reading configuration values from the variant without
    /// needing to handle the full `ExperimentVariant` struct.
    ///
    /// - Parameters:
    ///   - experimentId: The experiment to check.
    ///   - key: The payload key to read.
    /// - Returns: The payload value, or `nil` if not found.
    func getPayloadValue(for experimentId: String, key: String) -> String? {
        return getVariant(for: experimentId)?.payload[key]
    }

    // MARK: - Feature Flags

    /// Checks whether a feature flag is enabled for the current user.
    ///
    /// This is a convenience method for feature flag experiments. Returns `false`
    /// if the experiment is not registered, not a feature flag, or the user is
    /// not assigned to the treatment variant.
    ///
    /// - Parameters:
    ///   - experimentId: The feature flag experiment ID.
    ///   - trackExposure: Whether to track exposure. Defaults to `true`.
    /// - Returns: `true` if the user is assigned to the enabled (treatment) variant.
    func isFeatureEnabled(_ experimentId: String, trackExposure: Bool = true) -> Bool {
        guard let variant = getVariant(for: experimentId, trackExposure: trackExposure) else {
            return false
        }
        return variant.isFeatureFlagEnabled
    }

    // MARK: - Exposure Tracking

    /// Tracks an experiment exposure event.
    ///
    /// Exposure is tracked at most once per experiment per app session.
    /// This prevents inflated exposure counts when a user views the same
    /// experiment variant multiple times in one session.
    ///
    /// - Parameters:
    ///   - experimentId: The experiment that was exposed.
    ///   - variant: The variant the user saw.
    private func trackExposureEvent(experimentId: String, variant: ExperimentVariant) {
        // Deduplicate within the session
        guard !sessionExposures.contains(experimentId) else { return }
        sessionExposures.insert(experimentId)

        let experiment = experiments[experimentId]

        // Mark exposure as tracked in the persisted record
        if var record = assignments[experimentId] {
            record.exposureTracked = true
            assignments[experimentId] = record
            persistAssignments()
        }

        // Fire analytics event via AnalyticsTracker (which forwards to AnalyticsSDK)
        analyticsTracker.track(event: "experiment_exposure", properties: [
            "experiment_id": experimentId,
            "experiment_name": experiment?.name ?? experimentId,
            "variant_id": variant.id,
            "variant_name": variant.name,
            "is_feature_flag": experiment?.isFeatureFlag ?? false
        ])

        // Also fire directly to AnalyticsSDK for the batched pipeline
        Task {
            await AnalyticsSDK.shared.track("experiment_exposure", properties: [
                "experiment_id": experimentId,
                "experiment_name": experiment?.name ?? experimentId,
                "variant_id": variant.id,
                "variant_name": variant.name,
                "is_feature_flag": String(experiment?.isFeatureFlag ?? false)
            ])
        }

        logger.info("ABTesting", "Exposure tracked: experiment='\(experimentId)', variant='\(variant.name)'")
    }

    // MARK: - Conversion Tracking

    /// Tracks a conversion event for an experiment.
    ///
    /// Call this when the user completes a desired action within an experiment
    /// (e.g., completes onboarding, makes a purchase, enables a feature).
    ///
    /// Unlike exposure events, conversions can be tracked multiple times per
    /// session (e.g., multiple purchases).
    ///
    /// - Parameters:
    ///   - experimentId: The experiment the conversion is for.
    ///   - conversionType: A descriptive name for the conversion action
    ///     (default: "conversion"). Examples: "purchase", "signup", "feature_used".
    ///   - metadata: Additional key-value pairs for the conversion event.
    func trackConversion(
        experimentId: String,
        conversionType: String = "conversion",
        metadata: [String: String] = [:]
    ) {
        guard let assignment = assignments[experimentId] else {
            logger.warning("ABTesting", "Cannot track conversion for '\(experimentId)': no assignment found")
            return
        }

        let experiment = experiments[experimentId]

        var properties: [String: Any] = [
            "experiment_id": experimentId,
            "experiment_name": experiment?.name ?? experimentId,
            "variant_id": assignment.variantId,
            "variant_name": assignment.variantName,
            "conversion_type": conversionType,
            "is_feature_flag": experiment?.isFeatureFlag ?? false
        ]
        for (key, value) in metadata {
            properties["meta_\(key)"] = value
        }

        analyticsTracker.track(event: "experiment_conversion", properties: properties)

        // Also fire directly to AnalyticsSDK
        var sdkProperties: [String: Any] = [
            "experiment_id": experimentId,
            "experiment_name": experiment?.name ?? experimentId,
            "variant_id": assignment.variantId,
            "variant_name": assignment.variantName,
            "conversion_type": conversionType,
            "is_feature_flag": String(experiment?.isFeatureFlag ?? false)
        ]
        for (key, value) in metadata {
            sdkProperties["meta_\(key)"] = value
        }

        Task {
            await AnalyticsSDK.shared.track("experiment_conversion", properties: sdkProperties)
        }

        logger.info("ABTesting", "Conversion tracked: experiment='\(experimentId)', variant='\(assignment.variantName)', type='\(conversionType)'")
    }

    // MARK: - Queries

    /// Returns all registered experiments.
    func getAllExperiments() -> [Experiment] {
        return Array(experiments.values)
    }

    /// Returns a specific registered experiment by ID.
    func getExperiment(_ experimentId: String) -> Experiment? {
        return experiments[experimentId]
    }

    /// Returns all active experiments (status == .running and within date range).
    func getActiveExperiments() -> [Experiment] {
        return experiments.values.filter { $0.isActive }
    }

    /// Returns all current variant assignments.
    func getAllAssignments() -> [String: VariantAssignmentRecord] {
        return assignments
    }

    /// Returns the assignment record for a specific experiment.
    func getAssignment(for experimentId: String) -> VariantAssignmentRecord? {
        return assignments[experimentId]
    }

    /// Returns whether a specific experiment has a persisted assignment.
    func hasAssignment(for experimentId: String) -> Bool {
        return assignments[experimentId] != nil
    }

    // MARK: - Assignment Management

    /// Clears the variant assignment for a specific experiment.
    ///
    /// The user will be re-assigned on the next call to `getVariant(for:)`.
    /// Use sparingly — this breaks the deterministic guarantee for that experiment.
    ///
    /// - Parameter experimentId: The experiment to clear.
    func clearAssignment(for experimentId: String) {
        assignments.removeValue(forKey: experimentId)
        sessionExposures.remove(experimentId)
        persistAssignments()
        logger.info("ABTesting", "Assignment cleared for experiment '\(experimentId)'")
    }

    /// Clears all variant assignments.
    ///
    /// Intended for account switching or testing. All users will be
    /// re-assigned on their next variant access.
    func clearAllAssignments() {
        assignments.removeAll()
        sessionExposures.removeAll()
        persistAssignments()
        logger.info("ABTesting", "All assignments cleared")
    }

    /// Forces a specific variant assignment for an experiment.
    ///
    /// Intended for QA testing and debug overrides. Overrides the deterministic
    /// hash-based assignment. The override persists across sessions.
    ///
    /// - Parameters:
    ///   - experimentId: The experiment to override.
    ///   - variantId: The variant ID to force-assign.
    func overrideVariant(experimentId: String, variantId: String) {
        guard let experiment = experiments[experimentId],
              let variant = experiment.variants.first(where: { $0.id == variantId }) else {
            logger.warning("ABTesting", "Override failed: experiment '\(experimentId)' or variant '\(variantId)' not found")
            return
        }

        let record = VariantAssignmentRecord(
            experimentId: experimentId,
            variantId: variant.id,
            variantName: variant.name
        )
        assignments[experimentId] = record
        sessionExposures.remove(experimentId) // Allow re-tracking exposure for the override
        persistAssignments()

        logger.info("ABTesting", "Override applied: experiment='\(experimentId)', variant='\(variant.name)'")
    }

    // MARK: - Diagnostics

    /// Returns a formatted diagnostic summary of all experiments and assignments.
    ///
    /// Useful for debug screens and diagnostic exports.
    func diagnosticSummary() -> String {
        var lines: [String] = []
        lines.append("=== A/B Testing Diagnostics ===")
        lines.append("User ID: \(userId ?? "not set")")
        lines.append("Registered experiments: \(experiments.count)")
        lines.append("Active assignments: \(assignments.count)")
        lines.append("Session exposures: \(sessionExposures.count)")
        lines.append("")

        for (id, experiment) in experiments.sorted(by: { $0.key < $1.key }) {
            let assignment = assignments[id]
            let variantName = assignment?.variantName ?? "(unassigned)"
            let exposed = sessionExposures.contains(id) ? "yes" : "no"
            lines.append("[\(experiment.status.rawValue)] \(id)")
            lines.append("  Name: \(experiment.name)")
            lines.append("  Variants: \(experiment.variants.map { $0.name }.joined(separator: ", "))")
            lines.append("  Assignment: \(variantName)")
            lines.append("  Exposed this session: \(exposed)")
            if experiment.isFeatureFlag {
                let enabled = assignment.map { a in experiment.variants.first { $0.id == a.variantId }?.isFeatureFlagEnabled ?? false } ?? false
                lines.append("  Feature flag: \(enabled ? "enabled" : "disabled")")
            }
            lines.append("")
        }

        lines.append("================================")
        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence

    /// Saves the current assignments to UserDefaults.
    private func persistAssignments() {
        do {
            let data = try Self.encoder.encode(assignments)
            UserDefaults.standard.set(data, forKey: DefaultsKeys.assignments)
        } catch {
            logger.warning("ABTesting", "Failed to persist assignments: \(error.localizedDescription)")
        }
    }

    /// Restores assignments from UserDefaults.
    private func restoreAssignments() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKeys.assignments) else { return }

        do {
            let restored = try Self.decoder.decode([String: VariantAssignmentRecord].self, from: data)
            assignments = restored
            if !restored.isEmpty {
                logger.info("ABTesting", "Restored \(restored.count) assignments from disk")
            }
        } catch {
            logger.warning("ABTesting", "Failed to restore assignments: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.assignments)
        }
    }

    /// Restores the persisted user ID from UserDefaults.
    private func restoreUserId() {
        if let stored = UserDefaults.standard.string(forKey: DefaultsKeys.userId) {
            userId = stored
            logger.diagnostic("[ABTesting] Restored userId from disk: \(stored)")
        }
    }
}

// MARK: - ABTestVariant SwiftUI Property Wrapper

/// A SwiftUI property wrapper that resolves an experiment variant and
/// automatically tracks exposure when the view appears.
///
/// The wrapper provides a convenient way to access experiment variants
/// in SwiftUI views without manually calling `ABTestingService`.
///
/// ## Usage
/// ```swift
/// struct PaywallView: View {
///     @ABTestVariant("paywall_redesign") var variant
///
///     var body: some View {
///         if variant.name == "treatment" {
///             NewPaywallContent()
///         } else {
///             DefaultPaywallContent()
///         }
///     }
/// }
/// ```
///
/// ## Feature Flags
/// For boolean feature flags, check the `isEnabled` convenience:
/// ```swift
/// struct SettingsView: View {
///     @ABTestVariant("dark_mode_v2") var darkMode
///
///     var body: some View {
///         if darkMode.isEnabled {
///             DarkModeV2Toggle()
///         }
///     }
/// }
/// ```
///
/// ## How It Works
/// 1. On initialization, the wrapper asynchronously resolves the variant via
///    `ABTestingService.shared.getVariant(for:)`.
/// 2. The resolved variant is cached in a `@State`-backed `ObservableObject`.
/// 3. Exposure is tracked once per view appearance via `onAppear`.
/// 4. If the variant cannot be resolved (no user, experiment not found), a
///    default "control" variant is provided.
@propertyWrapper
struct ABTestVariant: DynamicProperty {

    /// Observable container that holds the resolved variant.
    @StateObject private var container: ExperimentVariantContainer

    /// The experiment ID this wrapper resolves.
    private let experimentId: String

    /// Creates an experiment variant property wrapper.
    ///
    /// - Parameter experimentId: The unique ID of the experiment to resolve.
    init(_ experimentId: String) {
        self.experimentId = experimentId
        _container = StateObject(wrappedValue: ExperimentVariantContainer(experimentId: experimentId))
    }

    /// The resolved experiment variant.
    ///
    /// Returns a default "control" variant if the experiment is not found,
    /// the user is not set, or the experiment is not active.
    var wrappedValue: ResolvedVariant {
        container.resolved
    }

    /// Provides access to the container for SwiftUI integration.
    var projectedValue: ExperimentVariantContainer {
        container
    }
}

// MARK: - Resolved Variant

/// A resolved variant value with convenience accessors.
///
/// This struct wraps the `ExperimentVariant` model with ergonomic properties
/// for common access patterns (name checks, feature flag booleans, payload reads).
struct ResolvedVariant: Sendable {

    /// The underlying experiment variant, or `nil` if unresolved.
    let variant: ExperimentVariant?

    /// The experiment ID this variant belongs to.
    let experimentId: String

    /// The variant name, or "control" if unresolved.
    var name: String {
        variant?.name ?? "control"
    }

    /// The variant ID, or an empty string if unresolved.
    var id: String {
        variant?.id ?? ""
    }

    /// Whether this is the control variant (either explicitly named "control" or unresolved).
    var isControl: Bool {
        variant == nil || variant?.name == "control"
    }

    /// Whether this variant represents an enabled feature flag.
    ///
    /// Returns `false` for non-feature-flag experiments or unresolved variants.
    var isEnabled: Bool {
        variant?.isFeatureFlagEnabled ?? false
    }

    /// Returns a payload value for the given key, or `nil` if not found.
    ///
    /// - Parameter key: The payload key.
    /// - Returns: The string value, or `nil`.
    func payload(_ key: String) -> String? {
        variant?.payload[key]
    }

    /// Returns a payload value for the given key, or a default value if not found.
    ///
    /// - Parameters:
    ///   - key: The payload key.
    ///   - defaultValue: The value to return if the key is not in the payload.
    /// - Returns: The string value or the default.
    func payload(_ key: String, default defaultValue: String) -> String {
        variant?.payload[key] ?? defaultValue
    }

    /// Default unresolved variant.
    static func defaultControl(experimentId: String) -> ResolvedVariant {
        ResolvedVariant(variant: nil, experimentId: experimentId)
    }
}

// MARK: - ExperimentVariantContainer

/// Observable container for the `@ExperimentVariant` property wrapper.
///
/// Handles asynchronous variant resolution from the actor-based
/// `ABTestingService` and publishes updates to the SwiftUI view.
final class ExperimentVariantContainer: ObservableObject {

    /// The resolved variant value. Updated asynchronously after initialization.
    @Published var resolved: ResolvedVariant

    /// The experiment ID being resolved.
    let experimentId: String

    /// Whether the variant has been resolved from the service.
    @Published var isResolved: Bool = false

    init(experimentId: String) {
        self.experimentId = experimentId
        self.resolved = ResolvedVariant.defaultControl(experimentId: experimentId)
        resolveVariant()
    }

    /// Asynchronously resolves the variant from ABTestingService.
    private func resolveVariant() {
        Task { @MainActor [weak self] in
            let variant = await ABTestingService.shared.getVariant(for: experimentId, trackExposure: true)
            self?.resolved = ResolvedVariant(variant: variant, experimentId: experimentId)
            self?.isResolved = true
        }
    }

    /// Manually triggers re-resolution of the variant.
    ///
    /// Useful if the experiment configuration has changed after the view was created.
    func refresh() {
        Task { @MainActor [weak self] in
            let variant = await ABTestingService.shared.getVariant(for: experimentId, trackExposure: false)
            self?.resolved = ResolvedVariant(variant: variant, experimentId: experimentId)
        }
    }

    /// Tracks a conversion event for this experiment.
    ///
    /// Convenience method that delegates to `ABTestingService.shared.trackConversion(...)`.
    ///
    /// - Parameters:
    ///   - conversionType: A descriptive name for the conversion action.
    ///   - metadata: Additional key-value pairs for the conversion event.
    func trackConversion(type conversionType: String = "conversion", metadata: [String: String] = [:]) {
        Task {
            await ABTestingService.shared.trackConversion(
                experimentId: experimentId,
                conversionType: conversionType,
                metadata: metadata
            )
        }
    }
}

// MARK: - Analytics Event Catalog Extension

extension AnalyticsEventCatalog {

    /// Events related to A/B testing experiments and feature flags.
    enum Experiment {
        case variantAssigned(experimentId: String, variantId: String, variantName: String)
        case exposure(experimentId: String, variantId: String, variantName: String)
        case conversion(experimentId: String, variantId: String, conversionType: String)
        case featureFlagEvaluated(flagId: String, enabled: Bool)

        /// Standardized snake_case event name.
        var eventName: String {
            switch self {
            case .variantAssigned:
                return "experiment_variant_assigned"
            case .exposure:
                return "experiment_exposure"
            case .conversion:
                return "experiment_conversion"
            case .featureFlagEvaluated:
                return "experiment_feature_flag_evaluated"
            }
        }

        /// Associated values serialized as a string dictionary.
        var properties: [String: String] {
            switch self {
            case .variantAssigned(let experimentId, let variantId, let variantName):
                return [
                    "experiment_id": experimentId,
                    "variant_id": variantId,
                    "variant_name": variantName
                ]
            case .exposure(let experimentId, let variantId, let variantName):
                return [
                    "experiment_id": experimentId,
                    "variant_id": variantId,
                    "variant_name": variantName
                ]
            case .conversion(let experimentId, let variantId, let conversionType):
                return [
                    "experiment_id": experimentId,
                    "variant_id": variantId,
                    "conversion_type": conversionType
                ]
            case .featureFlagEvaluated(let flagId, let enabled):
                return [
                    "flag_id": flagId,
                    "enabled": String(enabled)
                ]
            }
        }
    }
}

// MARK: - View Extension for Experiment Tracking

extension View {

    /// Tracks a conversion event for an experiment when a condition is met.
    ///
    /// Attach this modifier to views where a conversion action occurs. The
    /// conversion is tracked once when `condition` transitions to `true`.
    ///
    /// ```swift
    /// PurchaseButton()
    ///     .trackExperimentConversion(
    ///         "paywall_redesign",
    ///         type: "purchase",
    ///         when: purchaseCompleted
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - experimentId: The experiment to track a conversion for.
    ///   - conversionType: A descriptive name for the conversion.
    ///   - condition: When this becomes `true`, the conversion is tracked.
    ///   - metadata: Additional key-value pairs for the event.
    /// - Returns: The modified view with conversion tracking.
    func trackExperimentConversion(
        _ experimentId: String,
        type conversionType: String = "conversion",
        when condition: Bool,
        metadata: [String: String] = [:]
    ) -> some View {
        self.onChange(of: condition) { _, newValue in
            guard newValue else { return }
            Task {
                await ABTestingService.shared.trackConversion(
                    experimentId: experimentId,
                    conversionType: conversionType,
                    metadata: metadata
                )
            }
        }
    }
}
