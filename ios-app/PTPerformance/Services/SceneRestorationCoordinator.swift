//
//  SceneRestorationCoordinator.swift
//  PTPerformance
//
//  ACP-933: Scene Restoration Coordinator
//  Manages view state snapshots for instant UI restoration on warm start / resume.
//  Captures lightweight state before backgrounding and restores it on foreground
//  so the UI can render immediately with previous data while fresh data loads.
//

import Foundation
import UIKit
import os.log

// MARK: - State Snapshot

/// A serializable snapshot of the app's view state at the moment of backgrounding.
/// Kept intentionally lightweight — only state that is expensive to re-derive is captured.
struct SceneStateSnapshot: Codable, Sendable {

    /// Timestamp when the snapshot was captured.
    let capturedAt: Date

    /// The active tab identifier (e.g., "today", "workouts", "progress").
    var activeTab: String?

    /// The visible workout session ID, if the user was viewing a workout.
    var activeWorkoutSessionId: String?

    /// Scroll position in the primary list (opaque value — pixel offset or index).
    var scrollPosition: Double?

    /// Navigation stack depth (number of pushed views).
    var navigationDepth: Int?

    /// Whether a modal or sheet was presented.
    var hasModalPresented: Bool

    /// Arbitrary key-value pairs for view-specific state that doesn't warrant a dedicated field.
    var customState: [String: String]

    /// Age of this snapshot in seconds.
    var age: TimeInterval {
        Date().timeIntervalSince(capturedAt)
    }

    /// Whether the snapshot is still considered valid for restoration.
    /// Snapshots older than 30 minutes are stale — the user likely expects a fresh start.
    var isValid: Bool {
        age < 1800 // 30 minutes
    }
}

// MARK: - State Provider Protocol

/// Conformers provide a piece of restorable state to `SceneRestorationCoordinator`.
///
/// Views or view models that hold expensive-to-recreate state should register as providers.
/// On backgrounding, the coordinator collects state from all registered providers.
/// On foregrounding, it distributes the restored snapshot so providers can apply it.
///
/// All methods are called on the main actor since they interact with UI state.
@MainActor
protocol SceneStateProvider: AnyObject {
    /// A unique identifier for this provider (e.g., "TodayView", "WorkoutDetail").
    var stateProviderIdentifier: String { get }

    /// Capture the current state into the snapshot's custom state dictionary.
    /// - Returns: Key-value pairs to merge into the snapshot's `customState`.
    func captureState() -> [String: String]

    /// Restore state from a previously captured snapshot.
    /// - Parameter customState: The `customState` dictionary from the snapshot.
    func restoreState(from customState: [String: String])
}

// MARK: - Scene Restoration Coordinator

/// Manages the capture and restoration of view state across backgrounding cycles.
///
/// ## How It Works
/// 1. **Capture**: When the app enters background, `captureSnapshot()` is called.
///    It collects state from all registered `SceneStateProvider`s and persists
///    the snapshot to UserDefaults (lightweight, survives process termination).
///
/// 2. **Pre-Restoration**: On `willEnterForeground`, `prepareForRestoration()` loads
///    the persisted snapshot into memory so it's available before the first SwiftUI
///    render pass.
///
/// 3. **Restoration**: Individual views call `restoreIfAvailable()` during their
///    `.onAppear` or `.task` to apply the snapshot and render cached data immediately,
///    before any network requests complete.
///
/// ## Thread Safety
/// All public API is `@MainActor` since it interacts with UI state.
@MainActor
final class SceneRestorationCoordinator {

    // MARK: - Singleton

    static let shared = SceneRestorationCoordinator()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "SceneRestoration")

    /// The current in-memory snapshot, loaded from disk on `prepareForRestoration()`.
    private(set) var currentSnapshot: SceneStateSnapshot?

    /// Registered state providers (weak references to avoid retain cycles).
    private var providers: [WeakStateProvider] = []

    /// UserDefaults key for persisted snapshot.
    private let snapshotKey = "com.getmodus.sceneStateSnapshot"

    /// Whether a restoration is currently prepared and waiting to be consumed.
    private(set) var isRestorationPrepared = false

    // MARK: - Initialization

    private init() {
        logger.info("SceneRestorationCoordinator initialized")
    }

    // MARK: - Provider Registration

    /// Register a state provider for snapshot capture and restoration.
    ///
    /// Providers are held weakly — they do not need to explicitly unregister.
    /// Duplicate registrations for the same identifier are ignored.
    ///
    /// - Parameter provider: The state provider to register.
    func registerProvider(_ provider: SceneStateProvider) {
        // Prune any deallocated providers
        providers.removeAll { $0.value == nil }

        // Avoid duplicates
        let identifier = provider.stateProviderIdentifier
        guard !providers.contains(where: { $0.value?.stateProviderIdentifier == identifier }) else {
            return
        }

        providers.append(WeakStateProvider(value: provider))
        logger.info("Registered state provider: \(identifier)")
    }

    /// Unregister a state provider.
    ///
    /// - Parameter provider: The provider to remove.
    func unregisterProvider(_ provider: SceneStateProvider) {
        providers.removeAll { $0.value === provider || $0.value == nil }
        logger.info("Unregistered state provider: \(provider.stateProviderIdentifier)")
    }

    // MARK: - Capture

    /// Capture the current app state into a snapshot and persist it.
    ///
    /// Called by `WarmStartOptimizer` when the app enters background.
    func captureSnapshot() {
        // Prune deallocated providers
        providers.removeAll { $0.value == nil }

        // Collect custom state from all providers
        var mergedCustomState: [String: String] = [:]
        for weakProvider in providers {
            guard let provider = weakProvider.value else { continue }
            let state = provider.captureState()
            for (key, value) in state {
                // Namespace keys to avoid collisions: "ProviderID.key"
                let namespacedKey = "\(provider.stateProviderIdentifier).\(key)"
                mergedCustomState[namespacedKey] = value
            }
        }

        let snapshot = SceneStateSnapshot(
            capturedAt: Date(),
            activeTab: resolveActiveTab(),
            activeWorkoutSessionId: resolveActiveWorkoutSession(),
            scrollPosition: nil, // Providers contribute scroll position via customState
            navigationDepth: nil,
            hasModalPresented: false,
            customState: mergedCustomState
        )

        // Persist to UserDefaults (snapshot is lightweight — typically < 1 KB)
        persistSnapshot(snapshot)
        currentSnapshot = snapshot

        let providerCount = providers.filter({ $0.value != nil }).count
        logger.info("Captured state snapshot (\(providerCount) providers, \(mergedCustomState.count) custom entries)")

        PerformanceMonitor.shared.addBreadcrumb(
            category: "scene_restoration",
            message: "Snapshot captured",
            data: [
                "providers": String(providerCount),
                "custom_entries": String(mergedCustomState.count)
            ]
        )
    }

    // MARK: - Restoration

    /// Load the persisted snapshot into memory for restoration.
    ///
    /// Called by `WarmStartOptimizer` on `willEnterForeground`, before SwiftUI renders.
    func prepareForRestoration() {
        guard let snapshot = loadPersistedSnapshot() else {
            logger.info("No persisted snapshot found — fresh start")
            isRestorationPrepared = false
            return
        }

        guard snapshot.isValid else {
            logger.info("Persisted snapshot too old (\(String(format: "%.0f", snapshot.age))s) — discarding")
            clearPersistedSnapshot()
            currentSnapshot = nil
            isRestorationPrepared = false
            return
        }

        currentSnapshot = snapshot
        isRestorationPrepared = true

        logger.info("Restoration prepared (snapshot age: \(String(format: "%.1f", snapshot.age))s)")
    }

    /// Restore state for a specific provider from the current snapshot.
    ///
    /// Views should call this in their `.onAppear` or `.task` to apply cached state
    /// before network data arrives.
    ///
    /// - Parameter provider: The provider requesting restoration.
    /// - Returns: `true` if state was successfully restored.
    @discardableResult
    func restoreIfAvailable(for provider: SceneStateProvider) -> Bool {
        guard let snapshot = currentSnapshot, snapshot.isValid else {
            return false
        }

        let prefix = "\(provider.stateProviderIdentifier)."
        let relevantState = snapshot.customState
            .filter { $0.key.hasPrefix(prefix) }
            .reduce(into: [String: String]()) { result, pair in
                let strippedKey = String(pair.key.dropFirst(prefix.count))
                result[strippedKey] = pair.value
            }

        guard !relevantState.isEmpty else {
            return false
        }

        provider.restoreState(from: relevantState)

        logger.info("Restored state for \(provider.stateProviderIdentifier) (\(relevantState.count) entries)")
        return true
    }

    /// Get the persisted active tab for immediate tab restoration.
    ///
    /// This can be called before full restoration to set the initial tab
    /// without waiting for providers.
    ///
    /// - Returns: The tab identifier from the last snapshot, or `nil`.
    func getPersistedActiveTab() -> String? {
        if let snapshot = currentSnapshot, snapshot.isValid {
            return snapshot.activeTab
        }
        if let snapshot = loadPersistedSnapshot(), snapshot.isValid {
            return snapshot.activeTab
        }
        return nil
    }

    /// Get the persisted active workout session ID for instant navigation.
    ///
    /// - Returns: The session ID from the last snapshot, or `nil`.
    func getPersistedActiveWorkoutSessionId() -> String? {
        if let snapshot = currentSnapshot, snapshot.isValid {
            return snapshot.activeWorkoutSessionId
        }
        return nil
    }

    /// Mark restoration as consumed after all providers have been restored.
    /// Prevents stale snapshots from being applied on subsequent view appearances.
    func markRestorationConsumed() {
        isRestorationPrepared = false
        logger.info("Restoration consumed")
    }

    // MARK: - Persistence

    /// Persist a snapshot to UserDefaults as JSON.
    private func persistSnapshot(_ snapshot: SceneStateSnapshot) {
        do {
            let data = try SafeJSON.encoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: snapshotKey)
        } catch {
            logger.error("Failed to persist snapshot: \(error.localizedDescription)")
        }
    }

    /// Load a persisted snapshot from UserDefaults.
    private func loadPersistedSnapshot() -> SceneStateSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey) else {
            return nil
        }
        do {
            return try SafeJSON.decoder().decode(SceneStateSnapshot.self, from: data)
        } catch {
            logger.error("Failed to decode persisted snapshot: \(error.localizedDescription)")
            clearPersistedSnapshot()
            return nil
        }
    }

    /// Remove the persisted snapshot from UserDefaults.
    func clearPersistedSnapshot() {
        UserDefaults.standard.removeObject(forKey: snapshotKey)
        currentSnapshot = nil
        isRestorationPrepared = false
    }

    // MARK: - State Resolution Helpers

    /// Resolve the active tab from registered providers or app state.
    /// Returns the tab identifier if a provider has published it.
    private func resolveActiveTab() -> String? {
        // Look for a provider that has published an active tab
        for weakProvider in providers {
            guard let provider = weakProvider.value else { continue }
            let state = provider.captureState()
            if let tab = state["activeTab"] {
                return tab
            }
        }
        return nil
    }

    /// Resolve the active workout session ID from registered providers.
    private func resolveActiveWorkoutSession() -> String? {
        for weakProvider in providers {
            guard let provider = weakProvider.value else { continue }
            let state = provider.captureState()
            if let sessionId = state["activeWorkoutSessionId"] {
                return sessionId
            }
        }
        return nil
    }

    // MARK: - Diagnostics

    /// Get a diagnostic report of the restoration coordinator state.
    func getStatusReport() -> String {
        // Prune deallocated providers
        providers.removeAll { $0.value == nil }

        var report = "=== Scene Restoration Status ===\n"
        report += "Registered providers: \(providers.count)\n"

        for weakProvider in providers {
            if let provider = weakProvider.value {
                report += "  - \(provider.stateProviderIdentifier)\n"
            }
        }

        if let snapshot = currentSnapshot {
            report += "Current snapshot:\n"
            report += "  Age: \(String(format: "%.1f", snapshot.age))s\n"
            report += "  Valid: \(snapshot.isValid)\n"
            report += "  Active tab: \(snapshot.activeTab ?? "none")\n"
            report += "  Active workout: \(snapshot.activeWorkoutSessionId ?? "none")\n"
            report += "  Custom entries: \(snapshot.customState.count)\n"
            report += "  Has modal: \(snapshot.hasModalPresented)\n"
        } else {
            report += "No current snapshot\n"
        }

        report += "Restoration prepared: \(isRestorationPrepared)\n"
        report += "================================="
        return report
    }
}

// MARK: - Weak Provider Wrapper

/// Weak wrapper for `SceneStateProvider` references to avoid retain cycles.
private struct WeakStateProvider {
    weak var value: (any SceneStateProvider)?
}
