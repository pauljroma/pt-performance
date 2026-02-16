//
//  ScreenFlowTracker.swift
//  PTPerformance
//
//  ACP-963: Screen Flow Analytics
//  Tracks screen views with timing, records navigation transitions, and
//  maintains a session-scoped navigation stack for flow analysis.
//
//  Integrates with AnalyticsSDK to emit `screen_viewed`, `screen_exited`,
//  and `screen_transition` events with rich context including time spent,
//  navigation depth, previous screen, and scroll depth.
//
//  Thread safety is guaranteed via @MainActor isolation — all screen
//  lifecycle events originate from SwiftUI view callbacks which run on
//  the main actor.
//

import Foundation
import Combine

// MARK: - Screen Visit

/// A record of a single screen visit within the current session.
///
/// Captures the screen name, entry timestamp, duration, and how the user
/// reached the screen. Used internally by ``ScreenFlowTracker`` to build
/// the session navigation stack and compute flow analytics.
struct ScreenVisit: Sendable {

    /// The screen identifier (e.g. "TodayHub", "WorkoutDetail").
    let screenName: String

    /// The name of the screen the user navigated from, if any.
    let previousScreen: String?

    /// When the user entered this screen.
    let enteredAt: Date

    /// When the user left this screen. Nil while the screen is active.
    private(set) var exitedAt: Date?

    /// Maximum scroll depth reported while the screen was active, as a
    /// percentage (0.0 ... 1.0). Nil if scroll tracking was not enabled
    /// for this screen.
    private(set) var scrollDepth: Double?

    /// Zero-based position in the navigation stack at the time of entry.
    let sessionDepth: Int

    /// Time spent on the screen in seconds. Returns the elapsed time
    /// from entry to exit, or from entry to now if still active.
    var timeSpent: TimeInterval {
        let end = exitedAt ?? Date()
        return end.timeIntervalSince(enteredAt)
    }

    /// Mark the visit as complete.
    mutating func markExited() {
        exitedAt = Date()
    }

    /// Update the maximum observed scroll depth.
    mutating func updateScrollDepth(_ depth: Double) {
        let clamped = min(max(depth, 0.0), 1.0)
        if let current = scrollDepth {
            scrollDepth = max(current, clamped)
        } else {
            scrollDepth = clamped
        }
    }
}

// MARK: - Screen Flow Summary

/// An aggregated summary of a user's navigation flow within the current session.
///
/// Use this to identify common journeys, calculate average dwell times per
/// screen, and find drop-off points where users leave the app.
struct ScreenFlowSummary: Sendable {

    /// Ordered list of screen names visited in this session.
    let screenPath: [String]

    /// Total number of unique screens visited.
    let uniqueScreenCount: Int

    /// Total number of screen transitions (including revisits).
    let totalTransitions: Int

    /// Average time spent per screen in seconds.
    let averageTimePerScreen: TimeInterval

    /// The screen where the user spent the most time.
    let longestDwellScreen: String?

    /// The screen where the user spent the least time (potential drop-off).
    let shortestDwellScreen: String?

    /// Per-screen aggregated dwell times in seconds.
    let dwellTimesByScreen: [String: TimeInterval]

    /// Transition counts between screen pairs ("A -> B": count).
    let transitionCounts: [String: Int]
}

// MARK: - Screen Flow Tracker

/// Tracks screen views, transitions, and timing for flow analytics.
///
/// `ScreenFlowTracker` is a `@MainActor` singleton that maintains a
/// session-scoped navigation stack. It records every screen entry and
/// exit with timing, builds transition paths, and emits analytics events
/// via ``AnalyticsSDK``.
///
/// ## Architecture
/// - All mutations happen on `@MainActor` because SwiftUI view lifecycle
///   callbacks (`onAppear` / `onDisappear`) run on the main thread.
/// - The tracker emits three event types through AnalyticsSDK:
///   - `screen_flow_screen_viewed` — when a screen appears
///   - `screen_flow_screen_exited` — when a screen disappears (includes time spent)
///   - `screen_flow_transition` — captures the A-to-B navigation edge
///
/// ## Usage
/// Prefer the ``ScreenTrackingModifier`` SwiftUI view modifier for automatic
/// tracking. For manual tracking:
/// ```swift
/// // Screen appeared
/// await ScreenFlowTracker.shared.screenAppeared("WorkoutDetail")
///
/// // Report scroll depth
/// await ScreenFlowTracker.shared.reportScrollDepth(0.75, for: "WorkoutDetail")
///
/// // Screen disappeared
/// await ScreenFlowTracker.shared.screenDisappeared("WorkoutDetail")
///
/// // Get session summary
/// let summary = await ScreenFlowTracker.shared.sessionSummary()
/// ```
@MainActor
final class ScreenFlowTracker: ObservableObject {

    // MARK: - Singleton

    static let shared = ScreenFlowTracker()

    // MARK: - Published State

    /// The name of the currently active screen, or nil if none is tracked.
    @Published private(set) var currentScreen: String?

    /// The number of screens in the current navigation stack.
    @Published private(set) var navigationDepth: Int = 0

    // MARK: - Internal State

    /// Chronological history of all screen visits in this session.
    private var visitHistory: [ScreenVisit] = []

    /// Stack of currently active screen names. Supports nested navigation
    /// (e.g. pushing a detail view on top of a list).
    private var activeScreenStack: [String] = []

    /// Index into `visitHistory` for the currently active visit of each
    /// screen name. Allows O(1) lookup when updating scroll depth or
    /// marking exit.
    private var activeVisitIndices: [String: Int] = [:]

    /// Counts of transitions between screen pairs ("A -> B": count).
    private var transitionCounts: [String: Int] = [:]

    // MARK: - Dependencies

    private let logger = DebugLogger.shared

    // MARK: - Configuration

    /// Minimum time in seconds a screen must be visible to be recorded.
    /// Screens dismissed faster than this threshold are treated as transient
    /// (e.g. loading screens) and still recorded but flagged.
    private let transientThreshold: TimeInterval = 0.5

    // MARK: - Initialisation

    private init() {
        logger.info("ScreenFlowTracker", "Initialized")
    }

    // MARK: - Public API: Screen Lifecycle

    /// Record that a screen has appeared.
    ///
    /// Creates a new ``ScreenVisit``, pushes the screen onto the navigation
    /// stack, and emits a `screen_flow_screen_viewed` analytics event.
    ///
    /// - Parameter screenName: A stable identifier for the screen (e.g. "TodayHub").
    func screenAppeared(_ screenName: String) {
        let previousScreen = activeScreenStack.last
        let depth = activeScreenStack.count

        // Create the visit record
        let visit = ScreenVisit(
            screenName: screenName,
            previousScreen: previousScreen,
            enteredAt: Date(),
            scrollDepth: nil,
            sessionDepth: depth
        )

        let index = visitHistory.count
        visitHistory.append(visit)
        activeVisitIndices[screenName] = index
        activeScreenStack.append(screenName)
        currentScreen = screenName
        navigationDepth = activeScreenStack.count

        // Record transition edge
        if let from = previousScreen {
            let edge = "\(from) -> \(screenName)"
            transitionCounts[edge, default: 0] += 1

            // Emit transition event
            let transitionProperties: [String: Any] = [
                "from_screen": from,
                "to_screen": screenName,
                "session_depth": depth,
                "transition_count": transitionCounts[edge] ?? 1
            ]

            Task {
                await AnalyticsSDK.shared.track(
                    AnalyticsEventCatalog.ScreenFlow.transition.eventName,
                    properties: transitionProperties
                )
            }
        }

        // Emit screen viewed event
        var viewedProperties: [String: Any] = [
            "screen_name": screenName,
            "session_depth": depth
        ]
        if let prev = previousScreen {
            viewedProperties["previous_screen"] = prev
        }

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.ScreenFlow.screenViewed(name: screenName).eventName,
                properties: viewedProperties
            )
        }

        logger.info("ScreenFlowTracker", "Screen appeared: \(screenName) (depth=\(depth), from=\(previousScreen ?? "none"))")
    }

    /// Record that a screen has disappeared.
    ///
    /// Marks the active visit as exited, pops the screen from the navigation
    /// stack, and emits a `screen_flow_screen_exited` analytics event with
    /// time spent and scroll depth.
    ///
    /// - Parameter screenName: The screen identifier that was passed to ``screenAppeared(_:)``.
    func screenDisappeared(_ screenName: String) {
        guard let visitIndex = activeVisitIndices[screenName] else {
            logger.warning("ScreenFlowTracker", "screenDisappeared called for untracked screen: \(screenName)")
            return
        }

        // Mark the visit as complete
        visitHistory[visitIndex].markExited()
        let visit = visitHistory[visitIndex]
        activeVisitIndices.removeValue(forKey: screenName)

        // Pop from navigation stack
        if let stackIndex = activeScreenStack.lastIndex(of: screenName) {
            activeScreenStack.remove(at: stackIndex)
        }
        currentScreen = activeScreenStack.last
        navigationDepth = activeScreenStack.count

        // Build exit event properties
        let timeSpent = visit.timeSpent
        let isTransient = timeSpent < transientThreshold
        var exitProperties: [String: Any] = [
            "screen_name": screenName,
            "time_spent_seconds": String(format: "%.2f", timeSpent),
            "session_depth": visit.sessionDepth,
            "is_transient": String(isTransient)
        ]
        if let scrollDepth = visit.scrollDepth {
            exitProperties["scroll_depth"] = String(format: "%.2f", scrollDepth)
        }
        if let prev = visit.previousScreen {
            exitProperties["previous_screen"] = prev
        }

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.ScreenFlow.screenExited(name: screenName).eventName,
                properties: exitProperties
            )
        }

        logger.info("ScreenFlowTracker", "Screen exited: \(screenName) (time=\(String(format: "%.1f", timeSpent))s, scroll=\(visit.scrollDepth.map { String(format: "%.0f%%", $0 * 100) } ?? "n/a"))")
    }

    /// Report the current scroll depth for an active screen.
    ///
    /// Call this from a scroll view's offset observer. The tracker records
    /// the maximum scroll depth reached during the visit.
    ///
    /// - Parameters:
    ///   - depth: Scroll depth as a fraction (0.0 = top, 1.0 = bottom).
    ///   - screenName: The screen to update.
    func reportScrollDepth(_ depth: Double, for screenName: String) {
        guard let visitIndex = activeVisitIndices[screenName] else { return }
        visitHistory[visitIndex].updateScrollDepth(depth)
    }

    // MARK: - Public API: Flow Analysis

    /// Returns a summary of the user's navigation flow for the current session.
    ///
    /// The summary includes the full screen path, unique screen count,
    /// average dwell times, transition counts, and identification of
    /// longest/shortest dwell screens (potential engagement/drop-off points).
    ///
    /// - Returns: A ``ScreenFlowSummary`` aggregating all visits in this session.
    func sessionSummary() -> ScreenFlowSummary {
        let completedVisits = visitHistory.filter { $0.exitedAt != nil }

        // Build ordered screen path
        let screenPath = visitHistory.map { $0.screenName }
        let uniqueScreens = Set(screenPath)

        // Aggregate dwell times per screen
        var dwellTimes: [String: TimeInterval] = [:]
        var dwellCounts: [String: Int] = [:]
        for visit in completedVisits {
            dwellTimes[visit.screenName, default: 0] += visit.timeSpent
            dwellCounts[visit.screenName, default: 0] += 1
        }

        // Average dwell times per screen
        var avgDwellTimes: [String: TimeInterval] = [:]
        for (screen, totalTime) in dwellTimes {
            let count = dwellCounts[screen] ?? 1
            avgDwellTimes[screen] = totalTime / Double(count)
        }

        // Find longest and shortest dwell screens
        let sortedByDwell = avgDwellTimes.sorted { $0.value > $1.value }
        let longestDwell = sortedByDwell.first?.key
        let shortestDwell = sortedByDwell.last?.key

        // Total average
        let totalTime = completedVisits.reduce(0.0) { $0 + $1.timeSpent }
        let avgTime = completedVisits.isEmpty ? 0 : totalTime / Double(completedVisits.count)

        return ScreenFlowSummary(
            screenPath: screenPath,
            uniqueScreenCount: uniqueScreens.count,
            totalTransitions: max(0, visitHistory.count - 1),
            averageTimePerScreen: avgTime,
            longestDwellScreen: longestDwell,
            shortestDwellScreen: shortestDwell,
            dwellTimesByScreen: avgDwellTimes,
            transitionCounts: transitionCounts
        )
    }

    /// Returns the ordered list of screen names visited in this session.
    ///
    /// Useful for reconstructing the user's journey through the app.
    var screenPath: [String] {
        visitHistory.map { $0.screenName }
    }

    /// Returns all completed screen visits for external analysis.
    var completedVisits: [ScreenVisit] {
        visitHistory.filter { $0.exitedAt != nil }
    }

    /// Returns the most common screen transition as a string ("A -> B"),
    /// or nil if no transitions have been recorded.
    var mostCommonTransition: (edge: String, count: Int)? {
        transitionCounts.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    /// Identifies potential drop-off screens.
    ///
    /// A drop-off screen is one where the average time spent is below the
    /// given threshold, suggesting users leave or navigate away quickly.
    ///
    /// - Parameter threshold: Maximum average dwell time in seconds to
    ///   qualify as a drop-off point (default: 3.0 seconds).
    /// - Returns: An array of screen names that are potential drop-off points.
    func dropOffScreens(threshold: TimeInterval = 3.0) -> [String] {
        let summary = sessionSummary()
        return summary.dwellTimesByScreen
            .filter { $0.value < threshold }
            .sorted { $0.value < $1.value }
            .map { $0.key }
    }

    // MARK: - Session Management

    /// Reset all tracked data.
    ///
    /// Call this on logout or when starting a new analytics session to
    /// clear the navigation stack and visit history.
    func reset() {
        visitHistory.removeAll()
        activeScreenStack.removeAll()
        activeVisitIndices.removeAll()
        transitionCounts.removeAll()
        currentScreen = nil
        navigationDepth = 0
        logger.info("ScreenFlowTracker", "Session reset")
    }

    /// Emit the session summary as an analytics event.
    ///
    /// Call this before the user logs out or the app is backgrounded
    /// to capture the complete session flow for backend analysis.
    func emitSessionSummary() {
        let summary = sessionSummary()
        guard !summary.screenPath.isEmpty else { return }

        let pathString = summary.screenPath.joined(separator: " -> ")
        // Truncate path to avoid excessively large event payloads
        let truncatedPath = pathString.count > 500
            ? String(pathString.prefix(497)) + "..."
            : pathString

        let properties: [String: Any] = [
            "screen_path": truncatedPath,
            "unique_screen_count": summary.uniqueScreenCount,
            "total_transitions": summary.totalTransitions,
            "average_time_per_screen": String(format: "%.2f", summary.averageTimePerScreen),
            "longest_dwell_screen": summary.longestDwellScreen ?? "none",
            "shortest_dwell_screen": summary.shortestDwellScreen ?? "none"
        ]

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.ScreenFlow.sessionSummaryEmitted.eventName,
                properties: properties
            )
        }

        logger.info("ScreenFlowTracker", "Session summary emitted: \(summary.uniqueScreenCount) unique screens, \(summary.totalTransitions) transitions")
    }
}

// MARK: - AnalyticsEventCatalog Extension

extension AnalyticsEventCatalog {

    /// Events related to screen flow tracking and navigation analytics.
    enum ScreenFlow {
        case screenViewed(name: String)
        case screenExited(name: String)
        case transition
        case sessionSummaryEmitted

        /// Standardized snake_case event name.
        var eventName: String {
            switch self {
            case .screenViewed:
                return "screen_flow_screen_viewed"
            case .screenExited:
                return "screen_flow_screen_exited"
            case .transition:
                return "screen_flow_transition"
            case .sessionSummaryEmitted:
                return "screen_flow_session_summary"
            }
        }

        /// Associated values serialized as a string dictionary.
        var properties: [String: String] {
            switch self {
            case .screenViewed(let name):
                return ["screen_name": name]
            case .screenExited(let name):
                return ["screen_name": name]
            case .transition:
                return [:]
            case .sessionSummaryEmitted:
                return [:]
            }
        }
    }
}
