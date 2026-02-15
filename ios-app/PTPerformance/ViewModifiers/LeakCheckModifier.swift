//
//  LeakCheckModifier.swift
//  PTPerformance
//
//  ACP-937: Memory Leak Detection & Fix
//  Debug-only view modifier that tracks a view's associated ViewModel
//  through MemoryLeakDetector when the view disappears.
//

import SwiftUI

// MARK: - LeakCheckModifier

/// A view modifier that, in DEBUG builds, registers an associated object (typically
/// a ViewModel) with `MemoryLeakDetector` when the view disappears. If the object
/// is not deallocated within the detector's check window, a warning is logged.
///
/// In release builds this modifier is a complete no-op.
///
/// Usage:
/// ```swift
/// MyView()
///     .leakCheck("MyView", tracking: viewModel)
/// ```
private struct LeakCheckModifier: ViewModifier {

    let viewName: String
    let trackedObject: AnyObject?

    func body(content: Content) -> some View {
        #if DEBUG
        content
            .onDisappear {
                guard let object = trackedObject else { return }

                let label = "\(viewName).ViewModel"

                DebugLogger.shared.log(
                    "[LeakCheck] \(viewName) disappeared - tracking \(label) for deallocation",
                    level: .diagnostic
                )

                Task {
                    await MemoryLeakDetector.shared.track(object, label: label)
                }
            }
        #else
        content
        #endif
    }
}

// MARK: - View Extension

extension View {

    /// Attach leak detection to this view.
    ///
    /// When the view disappears, the `trackedObject` (typically the view's ViewModel)
    /// is registered with `MemoryLeakDetector`. If it is not deallocated within
    /// the configured delay, a warning is logged via `DebugLogger`.
    ///
    /// In release builds this is a no-op and has zero runtime cost.
    ///
    /// - Parameters:
    ///   - viewName: A human-readable name for the view (used in log messages).
    ///   - trackedObject: The object to monitor for deallocation (usually a ViewModel).
    /// - Returns: The modified view.
    ///
    /// ```swift
    /// struct WorkoutDetailView: View {
    ///     @StateObject private var viewModel = WorkoutDetailViewModel()
    ///
    ///     var body: some View {
    ///         VStack { /* ... */ }
    ///             .leakCheck("WorkoutDetail", tracking: viewModel)
    ///     }
    /// }
    /// ```
    func leakCheck(_ viewName: String, tracking trackedObject: AnyObject? = nil) -> some View {
        modifier(LeakCheckModifier(viewName: viewName, trackedObject: trackedObject))
    }
}
