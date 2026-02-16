//
//  OptimizedTransitions.swift
//  PTPerformance
//
//  ACP-944: Animation Performance — Pre-optimized transition view modifiers.
//  Provides ready-to-use animated transitions (fade, slide, scale, combined) that
//  respect Reduce Motion, adapt to thermal/power state via AnimationPerformanceKit,
//  and are tuned for 60fps on all supported devices.
//
//  These modifiers complement (and do not duplicate) the scroll-focused modifiers
//  in ViewPerformanceModifiers.swift and ScrollPerformanceKit.swift. While those
//  target list/scroll performance, these target discrete animated transitions
//  such as appearing content, expanding cards, and page-level entrances.
//

import SwiftUI

// MARK: - Optimized Fade In Modifier

/// Fades content from transparent to opaque when it appears.
///
/// Automatically uses `.opacity` only (no movement) when Reduce Motion is enabled,
/// and skips the animation entirely when animations are suppressed by the throttler.
///
/// Usage:
/// ```swift
/// Text("Welcome")
///     .optimizedFadeIn()
///
/// // With custom delay for staggered lists:
/// ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
///     ItemRow(item: item)
///         .optimizedFadeIn(delay: Double(index) * 0.05)
/// }
/// ```
private struct OptimizedFadeInModifier: ViewModifier {

    let delay: TimeInterval
    let duration: TimeInterval

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                let animation = resolvedAnimation
                if delay > 0 {
                    withAnimation(animation.delay(delay * durationMultiplier)) {
                        isVisible = true
                    }
                } else {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }

    private var resolvedAnimation: Animation {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .linear(duration: 0)
        }
        let throttled = AnimationPerformanceKit.AnimationThrottler.shared.throttled(
            .easeOut(duration: duration)
        )
        return throttled
    }

    private var durationMultiplier: Double {
        AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }
}

// MARK: - Optimized Slide In Modifier

/// Slides content in from a specified edge when it appears.
///
/// When Reduce Motion is enabled, falls back to a simple cross-fade (opacity only).
/// When the device is thermally throttled, the slide distance and duration are reduced.
///
/// Usage:
/// ```swift
/// DetailPanel()
///     .optimizedSlideIn(from: .trailing)
///
/// BottomSheet()
///     .optimizedSlideIn(from: .bottom, distance: 40)
/// ```
private struct OptimizedSlideInModifier: ViewModifier {

    let edge: Edge
    let distance: CGFloat
    let delay: TimeInterval

    @State private var isVisible = false

    func body(content: Content) -> some View {
        let shouldMove = !AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion

        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: shouldMove ? (isVisible ? 0 : horizontalOffset) : 0,
                y: shouldMove ? (isVisible ? 0 : verticalOffset) : 0
            )
            .onAppear {
                let animation = resolvedAnimation
                if delay > 0 {
                    withAnimation(animation.delay(delay * durationMultiplier)) {
                        isVisible = true
                    }
                } else {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }

    private var horizontalOffset: CGFloat {
        let effectiveDistance = AnimationPerformanceKit.AnimationThrottler.shared.shouldReduceAnimations
            ? distance * 0.5
            : distance
        switch edge {
        case .leading: return -effectiveDistance
        case .trailing: return effectiveDistance
        default: return 0
        }
    }

    private var verticalOffset: CGFloat {
        let effectiveDistance = AnimationPerformanceKit.AnimationThrottler.shared.shouldReduceAnimations
            ? distance * 0.5
            : distance
        switch edge {
        case .top: return -effectiveDistance
        case .bottom: return effectiveDistance
        default: return 0
        }
    }

    private var resolvedAnimation: Animation {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .linear(duration: 0)
        }
        return AnimationPerformanceKit.AnimationThrottler.shared.throttled(
            .spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0)
        )
    }

    private var durationMultiplier: Double {
        AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }
}

// MARK: - Optimized Scale In Modifier

/// Scales content from a smaller size to full size when it appears.
///
/// When Reduce Motion is enabled, falls back to a simple cross-fade.
/// Uses a spring curve for a natural feel, automatically throttled under pressure.
///
/// Usage:
/// ```swift
/// AchievementBadge()
///     .optimizedScaleIn()
///
/// // Custom scale for subtle entrance:
/// StatCard()
///     .optimizedScaleIn(from: 0.95)
/// ```
private struct OptimizedScaleInModifier: ViewModifier {

    let initialScale: CGFloat
    let delay: TimeInterval

    @State private var isVisible = false

    func body(content: Content) -> some View {
        let shouldScale = !AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion

        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(shouldScale ? (isVisible ? 1.0 : initialScale) : 1.0)
            .onAppear {
                let animation = resolvedAnimation
                if delay > 0 {
                    withAnimation(animation.delay(delay * durationMultiplier)) {
                        isVisible = true
                    }
                } else {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }

    private var resolvedAnimation: Animation {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .linear(duration: 0)
        }
        return AnimationPerformanceKit.AnimationThrottler.shared.throttled(
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        )
    }

    private var durationMultiplier: Double {
        AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }
}

// MARK: - Optimized Scale Bounce Modifier

/// Scales content in with a bounce effect — ideal for celebratory or attention-getting
/// animations like achievement badges or completion checkmarks.
///
/// When Reduce Motion is enabled, falls back to a simple cross-fade.
///
/// Usage:
/// ```swift
/// CompletionCheckmark()
///     .optimizedScaleBounce()
/// ```
private struct OptimizedScaleBounceModifier: ViewModifier {

    let delay: TimeInterval

    @State private var isVisible = false

    func body(content: Content) -> some View {
        let shouldScale = !AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion

        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(shouldScale ? (isVisible ? 1.0 : 0.3) : 1.0)
            .onAppear {
                let animation = resolvedAnimation
                if delay > 0 {
                    withAnimation(animation.delay(delay * durationMultiplier)) {
                        isVisible = true
                    }
                } else {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }

    private var resolvedAnimation: Animation {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .linear(duration: 0)
        }
        // Use the bouncy preset when not throttled; the throttler will simplify it
        // if the device is under thermal pressure.
        return AnimationPerformanceKit.AnimationThrottler.shared.throttled(
            AnimationPerformanceKit.Presets.springBouncy
        )
    }

    private var durationMultiplier: Double {
        AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }
}

// MARK: - Optimized Card Expand Modifier

/// Combined slide-up + scale + fade for card expansion transitions.
/// Provides a polished entrance animation commonly used for workout cards,
/// session detail panels, and similar content.
///
/// When Reduce Motion is enabled, falls back to a simple cross-fade.
///
/// Usage:
/// ```swift
/// WorkoutDetailCard(workout: workout)
///     .optimizedCardExpand()
/// ```
private struct OptimizedCardExpandModifier: ViewModifier {

    let delay: TimeInterval

    @State private var isVisible = false

    func body(content: Content) -> some View {
        let shouldAnimate = !AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion

        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(shouldAnimate ? (isVisible ? 1.0 : 0.96) : 1.0)
            .offset(y: shouldAnimate ? (isVisible ? 0 : 12) : 0)
            .onAppear {
                let animation = resolvedAnimation
                if delay > 0 {
                    withAnimation(animation.delay(delay * durationMultiplier)) {
                        isVisible = true
                    }
                } else {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }

    private var resolvedAnimation: Animation {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .linear(duration: 0)
        }
        return AnimationPerformanceKit.AnimationThrottler.shared.throttled(
            AnimationPerformanceKit.Presets.springStandard
        )
    }

    private var durationMultiplier: Double {
        AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }
}

// MARK: - Staggered Appear Modifier

/// Applies a staggered delay to the view's appearance animation based on its
/// index in a list. Wrap your preferred transition modifier with this to get
/// a cascading entrance effect.
///
/// The delay is automatically scaled by the throttler's duration multiplier,
/// and set to zero when Reduce Motion is enabled.
///
/// Usage:
/// ```swift
/// ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
///     ItemRow(item: item)
///         .optimizedFadeIn()
///         .staggeredAppear(index: index)
/// }
/// ```
private struct StaggeredAppearModifier: ViewModifier {

    let index: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    private var effectiveDelay: TimeInterval {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return 0
        }
        let rawDelay = Double(index) * baseDelay
        let cappedDelay = min(rawDelay, maxDelay)
        return cappedDelay * AnimationPerformanceKit.AnimationThrottler.shared.durationMultiplier
    }

    func body(content: Content) -> some View {
        content
            .animation(
                AnimationPerformanceKit.Presets.easeOutStandard.delay(effectiveDelay),
                value: index
            )
    }
}

// MARK: - Optimized Transition Provider

/// Provides pre-built `AnyTransition` values that automatically respect Reduce Motion.
///
/// These transitions are suitable for use with `.transition()` inside `if`/`switch`
/// blocks, sheet presentations, or any conditional view insertion/removal.
///
/// Usage:
/// ```swift
/// if showDetail {
///     DetailView()
///         .transition(OptimizedTransitions.slideUp)
/// }
/// ```
enum OptimizedTransitions {

    /// A slide-up + fade transition. Falls back to fade-only with Reduce Motion.
    static var slideUp: AnyTransition {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// A slide-from-trailing + fade transition. Falls back to fade-only with Reduce Motion.
    static var slideTrailing: AnyTransition {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// A scale + fade transition. Falls back to fade-only with Reduce Motion.
    static var scaleAndFade: AnyTransition {
        if AnimationPerformanceKit.ReducedMotionResponder.shared.shouldReduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }

    /// A simple cross-fade. Works identically with or without Reduce Motion.
    static var crossFade: AnyTransition {
        .opacity
    }
}

// MARK: - View Extensions

extension View {

    // MARK: Fade

    /// Fade in from transparent to opaque when this view appears.
    ///
    /// - Parameters:
    ///   - delay: Delay before the animation starts. Default: 0.
    ///   - duration: Animation duration. Default: 0.3s.
    /// - Returns: The modified view.
    func optimizedFadeIn(
        delay: TimeInterval = 0,
        duration: TimeInterval = DesignTokens.animationDurationNormal
    ) -> some View {
        modifier(OptimizedFadeInModifier(delay: delay, duration: duration))
    }

    // MARK: Slide

    /// Slide in from the specified edge when this view appears.
    ///
    /// Falls back to a cross-fade when Reduce Motion is enabled.
    ///
    /// - Parameters:
    ///   - edge: The edge to slide from. Default: `.bottom`.
    ///   - distance: The slide distance in points. Default: 24.
    ///   - delay: Delay before the animation starts. Default: 0.
    /// - Returns: The modified view.
    func optimizedSlideIn(
        from edge: Edge = .bottom,
        distance: CGFloat = 24,
        delay: TimeInterval = 0
    ) -> some View {
        modifier(OptimizedSlideInModifier(edge: edge, distance: distance, delay: delay))
    }

    // MARK: Scale

    /// Scale in from a smaller size when this view appears.
    ///
    /// Falls back to a cross-fade when Reduce Motion is enabled.
    ///
    /// - Parameters:
    ///   - initialScale: The starting scale factor. Default: 0.85.
    ///   - delay: Delay before the animation starts. Default: 0.
    /// - Returns: The modified view.
    func optimizedScaleIn(
        from initialScale: CGFloat = 0.85,
        delay: TimeInterval = 0
    ) -> some View {
        modifier(OptimizedScaleInModifier(initialScale: initialScale, delay: delay))
    }

    // MARK: Scale Bounce

    /// Scale in with a bouncy spring effect. Ideal for celebratory animations.
    ///
    /// Falls back to a cross-fade when Reduce Motion is enabled.
    ///
    /// - Parameter delay: Delay before the animation starts. Default: 0.
    /// - Returns: The modified view.
    func optimizedScaleBounce(delay: TimeInterval = 0) -> some View {
        modifier(OptimizedScaleBounceModifier(delay: delay))
    }

    // MARK: Card Expand

    /// Combined slide-up + scale + fade for card expansion transitions.
    ///
    /// Falls back to a cross-fade when Reduce Motion is enabled.
    ///
    /// - Parameter delay: Delay before the animation starts. Default: 0.
    /// - Returns: The modified view.
    func optimizedCardExpand(delay: TimeInterval = 0) -> some View {
        modifier(OptimizedCardExpandModifier(delay: delay))
    }

    // MARK: Staggered Appear

    /// Apply a staggered delay based on the view's position in a list.
    ///
    /// Combine with another transition modifier (e.g., `.optimizedFadeIn()`)
    /// for a cascading entrance effect.
    ///
    /// - Parameters:
    ///   - index: The item's position in the list (0-based).
    ///   - baseDelay: Per-item delay increment. Default: 0.04s.
    ///   - maxDelay: Maximum total delay cap. Default: 0.4s.
    /// - Returns: The modified view.
    func staggeredAppear(
        index: Int,
        baseDelay: TimeInterval = 0.04,
        maxDelay: TimeInterval = 0.4
    ) -> some View {
        modifier(StaggeredAppearModifier(index: index, baseDelay: baseDelay, maxDelay: maxDelay))
    }
}
