//
//  ScreenTrackingModifier.swift
//  PTPerformance
//
//  ACP-963: Screen Flow Analytics
//  SwiftUI view modifier for automatic screen view tracking.
//
//  Hooks into `onAppear` / `onDisappear` to notify ``ScreenFlowTracker``
//  of screen lifecycle events. Optionally tracks scroll depth via a
//  GeometryReader-based approach.
//
//  Usage:
//  ```swift
//  TodayHubView()
//      .trackScreen("TodayHub")
//
//  WorkoutDetailView()
//      .trackScreen("WorkoutDetail", trackScrollDepth: true)
//
//  SettingsView()
//      .trackScreen("Settings", additionalProperties: ["section": "account"])
//  ```
//

import SwiftUI

// MARK: - Screen Tracking Modifier

/// A view modifier that automatically tracks screen views and timing
/// via ``ScreenFlowTracker``.
///
/// When the modified view appears, it records a screen entry. When the
/// view disappears, it records the exit with time spent. Optionally
/// tracks scroll depth by observing the content offset within a scroll view.
///
/// The modifier is lightweight in release builds — it adds only the
/// `onAppear` / `onDisappear` callbacks and delegates all work to the
/// ``ScreenFlowTracker`` singleton.
private struct ScreenTrackingModifier: ViewModifier {

    // MARK: - Properties

    /// Stable identifier for the screen being tracked.
    let screenName: String

    /// Whether to track scroll depth for this screen.
    let trackScrollDepth: Bool

    /// Additional properties to include with the screen viewed event.
    let additionalProperties: [String: String]

    // MARK: - State

    /// Tracks whether the screen is currently visible to prevent
    /// duplicate appear/disappear calls from SwiftUI lifecycle quirks.
    @State private var isVisible = false

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isVisible else { return }
                isVisible = true
                ScreenFlowTracker.shared.screenAppeared(screenName)

                // Track additional properties as a separate event if provided
                if !additionalProperties.isEmpty {
                    Task {
                        var properties: [String: Any] = additionalProperties
                        properties["screen_name"] = screenName
                        await AnalyticsSDK.shared.track(
                            "screen_flow_screen_context",
                            properties: properties
                        )
                    }
                }
            }
            .onDisappear {
                guard isVisible else { return }
                isVisible = false
                ScreenFlowTracker.shared.screenDisappeared(screenName)
            }
    }
}

// MARK: - Scroll Depth Tracking Modifier

/// A view modifier that reports scroll depth to ``ScreenFlowTracker``.
///
/// Wrap a `ScrollView`'s content in this modifier to automatically report
/// the maximum scroll depth reached. The depth is calculated as the ratio
/// of content scrolled to total scrollable content height.
///
/// This is separated from ``ScreenTrackingModifier`` so it can be applied
/// specifically to scroll view content without interfering with the screen
/// lifecycle tracking.
private struct ScrollDepthTrackingModifier: ViewModifier {

    /// The screen name to associate the scroll depth with.
    let screenName: String

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { contentGeometry in
                    Color.clear
                        .preference(
                            key: ScrollContentHeightPreferenceKey.self,
                            value: contentGeometry.size.height
                        )
                }
            )
            .onPreferenceChange(ScrollContentHeightPreferenceKey.self) { contentHeight in
                // We need the scroll view frame to compute depth; use a
                // reasonable heuristic based on screen height.
                let screenHeight = UIScreen.main.bounds.height
                guard contentHeight > screenHeight else {
                    // Content fits on screen — full depth
                    ScreenFlowTracker.shared.reportScrollDepth(1.0, for: screenName)
                    return
                }

                // This preference fires once with the content height. For
                // continuous scroll tracking, pair with a ScrollViewReader or
                // overlay GeometryReader on the scroll view itself.
            }
    }
}

/// Preference key for tracking scroll content height.
private struct ScrollContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Scroll Offset Tracking Modifier

/// A modifier applied inside a `ScrollView` that continuously reports
/// the vertical scroll offset to ``ScreenFlowTracker``.
///
/// Place this as an overlay or background on the scroll view (not its content)
/// to track the viewport position relative to the content.
///
/// ```swift
/// ScrollView {
///     content
/// }
/// .trackScrollOffset(for: "MyScreen", contentHeight: totalContentHeight)
/// ```
private struct ScrollOffsetTrackingModifier: ViewModifier {

    let screenName: String
    let contentHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.frame(in: .global).minY) { _, newMinY in
                            let viewportHeight = geometry.size.height
                            guard contentHeight > viewportHeight else {
                                ScreenFlowTracker.shared.reportScrollDepth(1.0, for: screenName)
                                return
                            }

                            // Calculate how far down the user has scrolled
                            let scrollOffset = -newMinY
                            let maxScrollable = contentHeight - viewportHeight
                            let depth = min(max(scrollOffset / maxScrollable, 0), 1.0)
                            ScreenFlowTracker.shared.reportScrollDepth(depth, for: screenName)
                        }
                }
            )
    }
}

// MARK: - View Extensions

extension View {

    /// Automatically track screen views for this view via ``ScreenFlowTracker``.
    ///
    /// Records screen entry on `onAppear` and screen exit on `onDisappear`,
    /// including time spent and navigation depth. Events are sent through
    /// ``AnalyticsSDK``.
    ///
    /// - Parameters:
    ///   - screenName: A stable identifier for the screen (e.g. "TodayHub",
    ///     "WorkoutDetail"). Use the same name consistently across the app.
    ///   - trackScrollDepth: Whether to track scroll depth for this screen.
    ///     Defaults to `false`. When enabled, attach `.trackScrollOffset(for:contentHeight:)`
    ///     to the scroll view for continuous tracking.
    ///   - additionalProperties: Extra key-value pairs to include with the
    ///     screen viewed event (e.g. `["workout_id": "abc123"]`).
    /// - Returns: The modified view with screen tracking enabled.
    ///
    /// ## Example
    /// ```swift
    /// struct TodayHubView: View {
    ///     var body: some View {
    ///         VStack { /* ... */ }
    ///             .trackScreen("TodayHub")
    ///     }
    /// }
    ///
    /// struct WorkoutDetailView: View {
    ///     let workoutId: String
    ///
    ///     var body: some View {
    ///         ScrollView { /* ... */ }
    ///             .trackScreen("WorkoutDetail", additionalProperties: ["workout_id": workoutId])
    ///     }
    /// }
    /// ```
    func trackScreen(
        _ screenName: String,
        trackScrollDepth: Bool = false,
        additionalProperties: [String: String] = [:]
    ) -> some View {
        modifier(
            ScreenTrackingModifier(
                screenName: screenName,
                trackScrollDepth: trackScrollDepth,
                additionalProperties: additionalProperties
            )
        )
    }

    /// Track scroll offset within a scroll view and report depth to
    /// ``ScreenFlowTracker``.
    ///
    /// Apply this to a `ScrollView` to continuously report how far the
    /// user has scrolled. The tracker records the maximum depth reached.
    ///
    /// - Parameters:
    ///   - screenName: The screen name matching the `.trackScreen()` call.
    ///   - contentHeight: The total height of the scrollable content.
    /// - Returns: The modified view with scroll offset tracking.
    ///
    /// ## Example
    /// ```swift
    /// ScrollView {
    ///     VStack { /* tall content */ }
    ///         .background(
    ///             GeometryReader { geo in
    ///                 Color.clear.onAppear { contentHeight = geo.size.height }
    ///             }
    ///         )
    /// }
    /// .trackScrollOffset(for: "WorkoutDetail", contentHeight: contentHeight)
    /// .trackScreen("WorkoutDetail", trackScrollDepth: true)
    /// ```
    func trackScrollOffset(for screenName: String, contentHeight: CGFloat) -> some View {
        modifier(
            ScrollOffsetTrackingModifier(
                screenName: screenName,
                contentHeight: contentHeight
            )
        )
    }
}
