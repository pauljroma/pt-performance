//
//  AnimationPerformanceKit.swift
//  PTPerformance
//
//  ACP-944: Animation Performance — Comprehensive animation performance toolkit.
//  Provides optimized animation presets tuned for 60fps, animation throttling during
//  low-power and thermal-throttling states, automatic reduced-motion responder, and
//  a debug-only frame drop detector for animations.
//

import SwiftUI
import UIKit
import Combine

// MARK: - AnimationPerformanceKit Namespace

/// Centralized animation performance utilities namespace.
///
/// `AnimationPerformanceKit` provides pre-tuned animation curves, power-aware
/// throttling, reduced-motion adaptation, and debug instrumentation to ensure
/// animations run at a consistent 60fps across all supported devices.
enum AnimationPerformanceKit {}

// MARK: - Optimized Animation Presets

extension AnimationPerformanceKit {

    /// Pre-tuned animation presets optimized for 60fps on all supported devices.
    ///
    /// These presets use carefully chosen parameters to minimize frame drops:
    /// - Spring animations use critically-damped or slightly over-damped curves to
    ///   avoid oscillation that extends animation duration and increases GPU load.
    /// - Duration-based animations use values that align with vsync intervals
    ///   (multiples of ~16.67ms) for clean frame boundaries.
    /// - All presets automatically degrade to `.identity` (no animation) when
    ///   Reduce Motion is enabled or the device is under thermal pressure.
    enum Presets {

        // MARK: Springs

        /// A snappy spring for interactive feedback (e.g., button presses, toggles).
        /// Duration: ~200ms. Critically damped to avoid bounce.
        static var springSnappy: Animation {
            guard shouldAnimate else { return .identity }
            return .spring(response: 0.25, dampingFraction: 0.9, blendDuration: 0)
        }

        /// A standard spring for general UI transitions (cards, sheets, modals).
        /// Duration: ~350ms. Slight bounce for a natural feel.
        static var springStandard: Animation {
            guard shouldAnimate else { return .identity }
            return .spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0)
        }

        /// A gentle spring for large layout changes (expanding sections, page transitions).
        /// Duration: ~500ms. Smooth deceleration.
        static var springGentle: Animation {
            guard shouldAnimate else { return .identity }
            return .spring(response: 0.5, dampingFraction: 0.88, blendDuration: 0)
        }

        /// A bouncy spring for celebratory or attention-grabbing animations
        /// (achievement badges, completion checkmarks).
        /// Duration: ~600ms. Noticeable bounce.
        static var springBouncy: Animation {
            guard shouldAnimate else { return .identity }
            return .spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)
        }

        // MARK: Ease Curves

        /// A fast ease-out for elements entering the screen.
        /// Duration: 150ms (9 frames at 60fps).
        static var easeOutFast: Animation {
            guard shouldAnimate else { return .identity }
            return .easeOut(duration: DesignTokens.animationDurationFast)
        }

        /// A standard ease-out for general transitions.
        /// Duration: 300ms (18 frames at 60fps).
        static var easeOutStandard: Animation {
            guard shouldAnimate else { return .identity }
            return .easeOut(duration: DesignTokens.animationDurationNormal)
        }

        /// A smooth ease-in-out for symmetric transitions (cross-fades, swaps).
        /// Duration: 300ms.
        static var easeInOutStandard: Animation {
            guard shouldAnimate else { return .identity }
            return .easeInOut(duration: DesignTokens.animationDurationNormal)
        }

        /// A slow ease for emphasis animations (hero transitions, onboarding).
        /// Duration: 500ms (30 frames at 60fps).
        static var easeOutSlow: Animation {
            guard shouldAnimate else { return .identity }
            return .easeOut(duration: DesignTokens.animationDurationSlow)
        }

        // MARK: Linear

        /// A linear animation for progress indicators and continuous motion.
        /// Duration: 300ms.
        static var linear: Animation {
            guard shouldAnimate else { return .identity }
            return .linear(duration: DesignTokens.animationDurationNormal)
        }

        // MARK: Helpers

        /// Returns `false` when animations should be suppressed (reduce motion
        /// enabled or device under significant thermal/power pressure).
        private static var shouldAnimate: Bool {
            !ReducedMotionResponder.shared.shouldReduceMotion &&
            !AnimationThrottler.shared.shouldSuppressAnimations
        }
    }
}

// MARK: - Animation Identity Extension

/// Provides a static `.identity` animation that performs no visual transition.
/// Used as the fallback when animations are suppressed.
private extension Animation {
    static var identity: Animation {
        .linear(duration: 0)
    }
}

// MARK: - ReducedMotionResponder

extension AnimationPerformanceKit {

    /// Observes `UIAccessibility.isReduceMotionEnabled` and publishes changes
    /// so that animation code can react in real time when the user toggles the
    /// setting in Control Center or Settings.
    ///
    /// Usage:
    /// ```swift
    /// // Check synchronously
    /// if ReducedMotionResponder.shared.shouldReduceMotion {
    ///     // use opacity-only transition
    /// }
    ///
    /// // Observe reactively in SwiftUI
    /// @ObservedObject var motion = AnimationPerformanceKit.ReducedMotionResponder.shared
    /// ```
    final class ReducedMotionResponder: ObservableObject {

        // MARK: Singleton

        static let shared = ReducedMotionResponder()

        // MARK: Published State

        /// `true` when the user has enabled Reduce Motion in Accessibility settings.
        @Published private(set) var shouldReduceMotion: Bool

        // MARK: Private

        private var cancellables = Set<AnyCancellable>()

        // MARK: Init

        private init() {
            self.shouldReduceMotion = UIAccessibility.isReduceMotionEnabled

            // Listen for runtime changes via NotificationCenter.
            NotificationCenter.default.publisher(
                for: UIAccessibility.reduceMotionStatusDidChangeNotification
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
            }
            .store(in: &cancellables)
        }

        // MARK: Public Helpers

        /// Returns the preferred animation for the current reduce-motion state.
        /// When reduce motion is on, returns an instant transition (duration 0).
        /// Otherwise returns the provided animation.
        func preferred(_ animation: Animation) -> Animation {
            shouldReduceMotion ? .linear(duration: 0) : animation
        }

        /// Returns the appropriate transition for the current reduce-motion state.
        /// When reduce motion is on, returns `.opacity` (a cross-fade).
        /// Otherwise returns the provided transition.
        func preferred(_ transition: AnyTransition, reducedAlternative: AnyTransition = .opacity) -> AnyTransition {
            shouldReduceMotion ? reducedAlternative : transition
        }
    }
}

// MARK: - AnimationThrottler

extension AnimationPerformanceKit {

    /// Monitors device thermal state and Low Power Mode to automatically throttle
    /// or suppress animations when the device is under pressure.
    ///
    /// Throttle levels:
    /// - **nominal/fair**: All animations run normally.
    /// - **serious**: Complex animations (springs, bounces) are simplified to ease curves.
    /// - **critical** or **Low Power Mode**: All animations are suppressed.
    ///
    /// Usage:
    /// ```swift
    /// if AnimationThrottler.shared.shouldSuppressAnimations {
    ///     // skip animation entirely
    /// }
    ///
    /// let animation = AnimationThrottler.shared.throttled(.spring(response: 0.35, dampingFraction: 0.8))
    /// ```
    final class AnimationThrottler: ObservableObject {

        // MARK: Singleton

        static let shared = AnimationThrottler()

        // MARK: Throttle Level

        /// Represents the current animation throttle level.
        enum ThrottleLevel: Int, Comparable {
            /// No throttling. All animations run at full fidelity.
            case none = 0
            /// Moderate throttling. Complex animations simplified to ease curves.
            case reduced = 1
            /// Full suppression. No animations run.
            case suppressed = 2

            static func < (lhs: ThrottleLevel, rhs: ThrottleLevel) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }

        // MARK: Published State

        /// The current throttle level based on device conditions.
        @Published private(set) var throttleLevel: ThrottleLevel = .none

        /// Convenience: `true` when animations should be completely suppressed.
        var shouldSuppressAnimations: Bool {
            throttleLevel == .suppressed
        }

        /// Convenience: `true` when animations should be simplified.
        var shouldReduceAnimations: Bool {
            throttleLevel >= .reduced
        }

        // MARK: Private

        private var cancellables = Set<AnyCancellable>()

        // MARK: Init

        private init() {
            updateThrottleLevel()

            // Observe thermal state changes.
            NotificationCenter.default.publisher(
                for: ProcessInfo.thermalStateDidChangeNotification
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateThrottleLevel()
            }
            .store(in: &cancellables)

            // Observe Low Power Mode changes.
            NotificationCenter.default.publisher(
                for: .NSProcessInfoPowerStateDidChange
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateThrottleLevel()
            }
            .store(in: &cancellables)
        }

        // MARK: Public API

        /// Returns a throttled version of the given animation based on current device conditions.
        ///
        /// - Parameter animation: The desired animation.
        /// - Returns: The original animation, a simplified version, or no animation.
        func throttled(_ animation: Animation) -> Animation {
            switch throttleLevel {
            case .none:
                return animation
            case .reduced:
                // Replace with a simple ease-out that completes quickly.
                return .easeOut(duration: DesignTokens.animationDurationFast)
            case .suppressed:
                return .linear(duration: 0)
            }
        }

        /// Returns the throttled duration multiplier. Use when computing custom
        /// animation timings that aren't expressed as `Animation` values.
        ///
        /// - `.none`: 1.0 (full duration)
        /// - `.reduced`: 0.5 (halved)
        /// - `.suppressed`: 0.0 (instant)
        var durationMultiplier: Double {
            switch throttleLevel {
            case .none: return 1.0
            case .reduced: return 0.5
            case .suppressed: return 0.0
            }
        }

        // MARK: Private

        private func updateThrottleLevel() {
            let thermalState = ProcessInfo.processInfo.thermalState
            let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

            if isLowPower || thermalState == .critical {
                throttleLevel = .suppressed
            } else if thermalState == .serious {
                throttleLevel = .reduced
            } else {
                throttleLevel = .none
            }

            #if DEBUG
            DebugLogger.shared.log(
                "[AnimationPerformanceKit] Throttle level updated: \(throttleLevel) (thermal: \(thermalState.debugDescription), lowPower: \(isLowPower))",
                level: .diagnostic
            )
            #endif
        }
    }
}

// MARK: - ProcessInfo.ThermalState Debug Description

private extension ProcessInfo.ThermalState {
    var debugDescription: String {
        switch self {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - FrameDropDetector (Debug Only)

#if DEBUG

extension AnimationPerformanceKit {

    /// Debug-only frame drop detector that uses `CADisplayLink` to monitor the
    /// render loop during animations. Logs a warning whenever a frame exceeds
    /// the target frame time (16.67ms for 60fps), helping developers identify
    /// animations that cause jank.
    ///
    /// Usage:
    /// ```swift
    /// // Start monitoring before an animation
    /// AnimationPerformanceKit.FrameDropDetector.shared.startMonitoring(label: "CardExpand")
    ///
    /// // Stop when animation completes
    /// AnimationPerformanceKit.FrameDropDetector.shared.stopMonitoring()
    ///
    /// // Or use the view modifier for automatic lifecycle management:
    /// MyView()
    ///     .detectFrameDrops(label: "MyAnimation", during: $isAnimating)
    /// ```
    final class FrameDropDetector {

        // MARK: Singleton

        static let shared = FrameDropDetector()

        // MARK: Configuration

        /// Frame time threshold in seconds. Frames exceeding this are considered drops.
        /// Default: 16.67ms (60fps target).
        var frameTimeThreshold: TimeInterval = 1.0 / 60.0

        /// Minimum number of consecutive dropped frames before logging a warning.
        /// Prevents noise from isolated single-frame drops.
        var minimumDropCount: Int = 2

        // MARK: State

        private var displayLink: CADisplayLink?
        private var previousTimestamp: CFTimeInterval = 0
        private var droppedFrameCount: Int = 0
        private var totalFrameCount: Int = 0
        private var currentLabel: String = ""
        private var monitoringStartTime: CFTimeInterval = 0
        private var consecutiveDrops: Int = 0
        private var maxConsecutiveDrops: Int = 0
        private(set) var isMonitoring: Bool = false

        // MARK: Init

        private init() {}

        // MARK: Public API

        /// Begin monitoring frame delivery via CADisplayLink.
        ///
        /// - Parameter label: A descriptive label for the animation being monitored
        ///   (appears in log output).
        func startMonitoring(label: String) {
            guard !isMonitoring else { return }

            currentLabel = label
            droppedFrameCount = 0
            totalFrameCount = 0
            consecutiveDrops = 0
            maxConsecutiveDrops = 0
            previousTimestamp = 0
            isMonitoring = true

            let link = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
            monitoringStartTime = CACurrentMediaTime()

            DebugLogger.shared.log(
                "[FrameDropDetector] Started monitoring: \(label)",
                level: .diagnostic
            )
        }

        /// Stop monitoring and log a summary of frame performance.
        func stopMonitoring() {
            guard isMonitoring else { return }

            displayLink?.invalidate()
            displayLink = nil
            isMonitoring = false

            let elapsed = CACurrentMediaTime() - monitoringStartTime
            let dropRate = totalFrameCount > 0
                ? Double(droppedFrameCount) / Double(totalFrameCount) * 100
                : 0

            let summary = """
            [FrameDropDetector] \(currentLabel) summary: \
            \(totalFrameCount) frames in \(String(format: "%.0f", elapsed * 1000))ms | \
            \(droppedFrameCount) dropped (\(String(format: "%.1f", dropRate))%) | \
            max consecutive drops: \(maxConsecutiveDrops)
            """

            if droppedFrameCount >= minimumDropCount {
                DebugLogger.shared.log(summary, level: .warning)
            } else {
                DebugLogger.shared.log(summary, level: .diagnostic)
            }
        }

        // MARK: Display Link Handler

        @objc private func handleFrame(_ link: CADisplayLink) {
            let currentTimestamp = link.timestamp

            guard previousTimestamp > 0 else {
                previousTimestamp = currentTimestamp
                return
            }

            totalFrameCount += 1

            let frameDuration = currentTimestamp - previousTimestamp
            // Allow a 20% tolerance over the ideal frame time to account for
            // minor scheduling jitter that doesn't cause visible jank.
            let threshold = frameTimeThreshold * 1.2

            if frameDuration > threshold {
                droppedFrameCount += 1
                consecutiveDrops += 1
                maxConsecutiveDrops = max(maxConsecutiveDrops, consecutiveDrops)

                let droppedCount = Int(frameDuration / frameTimeThreshold) - 1
                DebugLogger.shared.log(
                    "[FrameDropDetector] \(currentLabel): frame took \(String(format: "%.1f", frameDuration * 1000))ms (~\(droppedCount) dropped frames)",
                    level: .warning
                )
            } else {
                consecutiveDrops = 0
            }

            previousTimestamp = currentTimestamp
        }
    }
}

#endif

// MARK: - Frame Drop Detector View Modifier (Debug Only)

/// View modifier that starts and stops the `FrameDropDetector` based on a
/// boolean binding. Attach to any view that triggers an animation to
/// automatically track frame drops for the duration of that animation.
///
/// In release builds this modifier is a complete no-op.
private struct FrameDropDetectorModifier: ViewModifier {

    let label: String
    @Binding var isAnimating: Bool

    func body(content: Content) -> some View {
        #if DEBUG
        content
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    AnimationPerformanceKit.FrameDropDetector.shared.startMonitoring(label: label)
                } else {
                    AnimationPerformanceKit.FrameDropDetector.shared.stopMonitoring()
                }
            }
        #else
        content
        #endif
    }
}

extension View {

    /// Attach a frame drop detector to this view.
    ///
    /// When `isAnimating` becomes `true`, the detector starts monitoring frame delivery.
    /// When it becomes `false`, monitoring stops and a summary is logged.
    ///
    /// In release builds this is a no-op with zero runtime cost.
    ///
    /// - Parameters:
    ///   - label: A descriptive label for the animation being monitored.
    ///   - isAnimating: A binding that is `true` while the animation is running.
    /// - Returns: The modified view.
    ///
    /// ```swift
    /// @State private var isExpanded = false
    ///
    /// CardView()
    ///     .detectFrameDrops(label: "CardExpand", during: $isExpanded)
    ///     .onTapGesture {
    ///         withAnimation(AnimationPerformanceKit.Presets.springStandard) {
    ///             isExpanded.toggle()
    ///         }
    ///     }
    /// ```
    func detectFrameDrops(label: String, during isAnimating: Binding<Bool>) -> some View {
        modifier(FrameDropDetectorModifier(label: label, isAnimating: isAnimating))
    }
}

// MARK: - Adaptive Animation Modifier

/// View modifier that selects the best animation for the current device conditions
/// and accessibility settings. Combines the logic of `ReducedMotionResponder` and
/// `AnimationThrottler` into a single, easy-to-use modifier.
private struct AdaptiveAnimationModifier: ViewModifier {

    let animation: Animation
    let reducedMotionAlternative: Animation?

    // Note: ViewModifier structs cannot use @StateObject; @ObservedObject is acceptable
    // here because these observe long-lived singletons.
    @ObservedObject private var motionResponder = AnimationPerformanceKit.ReducedMotionResponder.shared
    @ObservedObject private var throttler = AnimationPerformanceKit.AnimationThrottler.shared

    func body(content: Content) -> some View {
        content
            .animation(resolvedAnimation, value: UUID())
    }

    private var resolvedAnimation: Animation {
        if motionResponder.shouldReduceMotion {
            return reducedMotionAlternative ?? .linear(duration: 0)
        }
        return throttler.throttled(animation)
    }
}

extension View {

    /// Apply an adaptive animation that automatically degrades based on device
    /// conditions and accessibility settings.
    ///
    /// - Parameters:
    ///   - animation: The desired animation for optimal conditions.
    ///   - reducedMotionAlternative: An optional alternative animation when Reduce Motion
    ///     is enabled. Defaults to no animation (instant transition).
    /// - Returns: The modified view.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .adaptiveAnimation(.spring(response: 0.35, dampingFraction: 0.8))
    /// ```
    func adaptiveAnimation(
        _ animation: Animation,
        reducedMotionAlternative: Animation? = nil
    ) -> some View {
        modifier(AdaptiveAnimationModifier(
            animation: animation,
            reducedMotionAlternative: reducedMotionAlternative
        ))
    }
}

// MARK: - withOptimizedAnimation

extension AnimationPerformanceKit {

    /// A drop-in replacement for `withAnimation(_:_:)` that automatically
    /// applies reduced-motion and throttling logic.
    ///
    /// Usage:
    /// ```swift
    /// AnimationPerformanceKit.withOptimizedAnimation(.springStandard) {
    ///     isExpanded.toggle()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - animation: The desired animation preset.
    ///   - body: The state mutation to animate.
    @MainActor
    static func withOptimizedAnimation(_ animation: Animation, _ body: () -> Void) {
        let resolvedAnimation: Animation
        if ReducedMotionResponder.shared.shouldReduceMotion {
            resolvedAnimation = .linear(duration: 0)
        } else {
            resolvedAnimation = AnimationThrottler.shared.throttled(animation)
        }
        withAnimation(resolvedAnimation) {
            body()
        }
    }

    /// A drop-in replacement for `withAnimation(_:_:)` that uses a preset
    /// and automatically applies reduced-motion and throttling logic.
    ///
    /// Usage:
    /// ```swift
    /// AnimationPerformanceKit.withOptimizedAnimation {
    ///     showDetail = true
    /// }
    /// ```
    ///
    /// - Parameter body: The state mutation to animate. Uses `springStandard` by default.
    @MainActor
    static func withOptimizedAnimation(_ body: () -> Void) {
        withOptimizedAnimation(Presets.springStandard, body)
    }
}

// MARK: - Reduced Motion Environment Key

/// Environment key that exposes the current reduced-motion state to the view hierarchy
/// without requiring views to observe the full `ReducedMotionResponder` object.
private struct ReducedMotionEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    /// `true` when the user has enabled Reduce Motion in Accessibility settings.
    /// Automatically updated when the setting changes.
    var prefersReducedMotion: Bool {
        get { self[ReducedMotionEnvironmentKey.self] }
        set { self[ReducedMotionEnvironmentKey.self] = newValue }
    }
}

// MARK: - ReducedMotionProvider

/// Injects the current reduced-motion state into the environment so child views
/// can read `@Environment(\.prefersReducedMotion)` without needing to import
/// or observe `ReducedMotionResponder` directly.
///
/// Usage — apply once near the root of the app:
/// ```swift
/// ContentView()
///     .injectReducedMotionState()
/// ```
private struct ReducedMotionProviderModifier: ViewModifier {

    // Note: ViewModifier structs cannot use @StateObject; @ObservedObject is acceptable
    // here because this observes a long-lived singleton.
    @ObservedObject private var responder = AnimationPerformanceKit.ReducedMotionResponder.shared

    func body(content: Content) -> some View {
        content
            .environment(\.prefersReducedMotion, responder.shouldReduceMotion)
    }
}

extension View {

    /// Inject the live reduced-motion state into the environment.
    /// Apply once near the root of the view hierarchy.
    func injectReducedMotionState() -> some View {
        modifier(ReducedMotionProviderModifier())
    }
}
