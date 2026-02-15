//
//  MemoryLeakDetector.swift
//  PTPerformance
//
//  ACP-937: Memory Leak Detection & Fix
//  Debug-only service that tracks object allocations/deallocations
//  and reports potential retain cycles by checking weak references after a delay.
//

import Foundation

#if DEBUG

// MARK: - Tracked Object Entry

/// Internal record for a tracked object. Stores a weak reference so the detector
/// itself never prevents deallocation.
private struct TrackedEntry {
    let label: String
    weak var object: AnyObject?
    let identifier: ObjectIdentifier
    let trackTime: Date
}

// MARK: - MemoryLeakDetector

/// A debug-only actor that detects potential memory leaks by tracking objects via
/// weak references. After a configurable delay (default 5 seconds), it checks
/// whether the object has been deallocated. If it is still alive, a warning is
/// logged through DebugLogger.
///
/// Usage:
/// ```swift
/// await MemoryLeakDetector.shared.track(viewModel, label: "WorkoutViewModel")
/// ```
///
/// Because this is an actor, all access is inherently thread-safe.
actor MemoryLeakDetector {

    // MARK: - Singleton

    static let shared = MemoryLeakDetector()

    // MARK: - Configuration

    /// How long to wait (in seconds) before checking if a tracked object was deallocated.
    let checkDelay: TimeInterval = 5.0

    // MARK: - Private Properties

    private let logger = DebugLogger.shared

    /// All entries currently being tracked. Keyed by `ObjectIdentifier` to allow
    /// O(1) lookups and to avoid duplicate tracking of the same instance.
    private var trackedEntries: [ObjectIdentifier: TrackedEntry] = [:]

    // MARK: - Initialization

    private init() {
        logger.log("[MemoryLeakDetector] Initialized (DEBUG only)", level: .diagnostic)
    }

    // MARK: - Public API

    /// Track an object for potential leak detection.
    ///
    /// A weak reference to `object` is stored. After `checkDelay` seconds a
    /// background task verifies that the object has been deallocated. If it has
    /// not, a warning is logged.
    ///
    /// - Parameters:
    ///   - object: The instance to track. A weak reference is held.
    ///   - label: A human-readable label (e.g. the class name or view name).
    func track(_ object: AnyObject, label: String) {
        let identifier = ObjectIdentifier(object)

        let entry = TrackedEntry(
            label: label,
            object: object,
            identifier: identifier,
            trackTime: Date()
        )

        trackedEntries[identifier] = entry

        logger.log("[MemoryLeakDetector] Tracking \(label) (\(identifier))", level: .diagnostic)

        // Schedule a deallocation check after the delay.
        Task { [weak self, checkDelay] in
            try? await Task.sleep(nanoseconds: UInt64(checkDelay * 1_000_000_000))
            await self?.checkDeallocation(for: identifier, label: label)
        }
    }

    /// Returns labels of all currently tracked objects that have NOT been deallocated.
    /// Useful for on-demand leak reporting (e.g. from a debug menu).
    func reportLeaks() -> [String] {
        // Compact entries first: remove any that have already been deallocated.
        compactEntries()

        return trackedEntries.values.map { entry in
            let age = Date().timeIntervalSince(entry.trackTime)
            return "\(entry.label) (alive for \(String(format: "%.1f", age))s)"
        }
    }

    /// Remove all tracked entries. Primarily useful for resetting state between
    /// test scenarios or after a full navigation reset.
    func reset() {
        trackedEntries.removeAll()
        logger.log("[MemoryLeakDetector] Reset - all entries cleared", level: .diagnostic)
    }

    /// The number of objects currently being tracked (including already-deallocated
    /// entries that have not yet been compacted).
    var trackedCount: Int {
        trackedEntries.count
    }

    // MARK: - Private Helpers

    /// Check whether the object identified by `identifier` has been deallocated.
    /// If it is still alive, log a warning.
    private func checkDeallocation(for identifier: ObjectIdentifier, label: String) {
        guard let entry = trackedEntries[identifier] else {
            // Entry was removed (e.g. via reset) before the check fired.
            return
        }

        if entry.object != nil {
            // Object is still alive after the delay -- potential leak.
            let age = Date().timeIntervalSince(entry.trackTime)
            logger.log(
                "[MemoryLeakDetector] POTENTIAL LEAK: \(label) still alive after \(String(format: "%.1f", age))s",
                level: .warning
            )
        } else {
            // Object was properly deallocated. Clean up the entry.
            trackedEntries.removeValue(forKey: identifier)
            logger.log("[MemoryLeakDetector] \(label) deallocated (OK)", level: .diagnostic)
        }
    }

    /// Remove entries whose objects have already been deallocated.
    private func compactEntries() {
        trackedEntries = trackedEntries.filter { $0.value.object != nil }
    }
}

#else

// MARK: - Release Stub

/// In release builds, MemoryLeakDetector is a no-op actor so that call sites
/// compile without `#if DEBUG` guards everywhere.
actor MemoryLeakDetector {

    static let shared = MemoryLeakDetector()

    private init() {}

    /// No-op in release builds.
    func track(_ object: AnyObject, label: String) {}

    /// Always returns an empty array in release builds.
    func reportLeaks() -> [String] { [] }

    /// No-op in release builds.
    func reset() {}

    /// Always returns 0 in release builds.
    var trackedCount: Int { 0 }
}

#endif
