//
//  MainActorBatcher.swift
//  PTPerformance
//
//  ACP-945: Main Thread Optimization — Batches @MainActor state mutations.
//  Collects multiple state updates and applies them in a single transaction
//  on the next run loop cycle, preventing cascading SwiftUI view re-renders
//  when multiple @Published properties need updating at once.
//

import Foundation

/// Batches main-actor state mutations into a single render pass.
///
/// When multiple `@Published` properties on an `ObservableObject` are set
/// individually, each assignment triggers `objectWillChange` and a SwiftUI
/// diff cycle. This batcher collects closures via `enqueue(_:)` and applies
/// them all together after a configurable coalescing window, so the view
/// hierarchy only re-renders once.
///
/// Usage:
/// ```swift
/// let batcher = MainActorBatcher()
///
/// // These two updates will be applied together in a single render pass:
/// batcher.enqueue { viewModel.isLoading = false }
/// batcher.enqueue { viewModel.items = newItems }
/// ```
@MainActor
final class MainActorBatcher {

    // MARK: - Properties

    /// Coalescing window in seconds. Updates enqueued within this window
    /// are merged into a single application. Default is 8ms (half a frame).
    let coalescingWindow: TimeInterval

    /// Queued update closures waiting to be applied.
    private var pendingUpdates: [@MainActor () -> Void] = []

    /// Whether a flush has already been scheduled for the current window.
    private var isFlushScheduled = false

    // MARK: - Init

    /// Create a batcher with a custom coalescing window.
    /// - Parameter coalescingWindow: Seconds to wait before flushing. Defaults to 0.008 (8ms).
    init(coalescingWindow: TimeInterval = 0.008) {
        self.coalescingWindow = coalescingWindow
    }

    // MARK: - Public API

    /// Enqueue a state mutation to be applied in the next batched flush.
    ///
    /// The update closure runs on `@MainActor` and is guaranteed to execute
    /// within one run loop cycle after the coalescing window expires.
    ///
    /// - Parameter update: A closure that mutates `@MainActor`-isolated state.
    func enqueue(_ update: @escaping @MainActor () -> Void) {
        pendingUpdates.append(update)

        guard !isFlushScheduled else { return }
        isFlushScheduled = true

        // Schedule the flush on the next run loop cycle after the coalescing window.
        // RunLoop.main.perform runs at the end of the current run loop iteration,
        // giving other enqueue calls within the same cycle a chance to piggyback.
        if coalescingWindow <= 0 {
            // Zero window: flush on the very next run loop pass.
            RunLoop.main.perform { [weak self] in
                self?.flush()
            }
        } else {
            // Use a timer-based approach for the coalescing window.
            // This allows updates arriving within the window to batch together.
            let timer = Timer(timeInterval: coalescingWindow, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.flush()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Immediately apply all pending updates without waiting for the coalescing window.
    /// Useful for critical state transitions that must take effect immediately.
    func flushNow() {
        flush()
    }

    /// The number of updates currently waiting to be applied.
    var pendingCount: Int {
        pendingUpdates.count
    }

    // MARK: - Internal

    /// Apply all pending updates in a single pass and reset state.
    private func flush() {
        let updates = pendingUpdates
        pendingUpdates = []
        isFlushScheduled = false

        // Apply all mutations in sequence — SwiftUI coalesces the resulting
        // objectWillChange notifications within the same run loop iteration,
        // so the view hierarchy diffs only once.
        for update in updates {
            update()
        }
    }
}
