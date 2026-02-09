//
//  ScrollAnimations.swift
//  PTPerformance
//
//  Scroll-triggered micro-animations for enhanced visual feedback
//  Respects accessibilityReduceMotion for users who prefer reduced motion
//

import SwiftUI

// MARK: - Scroll Offset Preference Key

/// Preference key for tracking scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Offset Reader

/// A view that tracks scroll position and reports it via a preference key
/// Use this as the first child in a ScrollView to track scroll offset
struct ScrollOffsetReader: View {
    var coordinateSpace: String = "scroll"

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Visibility Preference Key

/// Preference key for tracking when a view becomes visible in the scroll view
struct ViewVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - Reveal On Scroll Modifier

/// Animates a view into visibility when it enters the viewport
/// Respects accessibilityReduceMotion environment value
struct RevealOnScrollModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The delay before the animation starts (useful for staggered reveals)
    var delay: Double = 0

    /// The offset from which the view animates in
    var offsetY: CGFloat = 30

    /// The duration of the reveal animation
    var duration: Double = 0.4

    /// Internal state tracking visibility
    @State private var hasAppeared = false
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : (isVisible ? 1 : 0))
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : offsetY))
            .animation(
                reduceMotion ? nil : .easeOut(duration: duration).delay(delay),
                value: isVisible
            )
            .onAppear {
                // Only animate on first appearance
                guard !hasAppeared else { return }
                hasAppeared = true

                // Slight delay to allow the view to render before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 + delay) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Parallax Modifier

/// Applies a subtle parallax effect based on scroll position
/// Creates a sense of depth as the user scrolls
struct ParallaxModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The scroll offset from the scroll view
    var scrollOffset: CGFloat

    /// The intensity of the parallax effect (0.0 - 1.0)
    /// Higher values create more pronounced parallax
    var intensity: CGFloat = 0.3

    /// Maximum parallax offset in points
    var maxOffset: CGFloat = 50

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : parallaxOffset)
    }

    private var parallaxOffset: CGFloat {
        // Calculate parallax based on scroll position
        // Negative scroll offset means scrolling down
        let offset = scrollOffset * intensity

        // Clamp the offset to prevent excessive movement
        return max(-maxOffset, min(maxOffset, offset))
    }
}

// MARK: - Scale On Scroll Modifier

/// Applies a subtle scale effect based on scroll position
/// Useful for hero sections that shrink as user scrolls
struct ScaleOnScrollModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The scroll offset from the scroll view
    var scrollOffset: CGFloat

    /// Minimum scale factor (when fully scrolled)
    var minScale: CGFloat = 0.95

    /// The scroll range over which scaling occurs
    var scrollRange: CGFloat = 100

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : scaleValue)
    }

    private var scaleValue: CGFloat {
        guard scrollOffset < 0 else { return 1.0 }

        let progress = min(1.0, abs(scrollOffset) / scrollRange)
        return 1.0 - (progress * (1.0 - minScale))
    }
}

// MARK: - Fade On Scroll Modifier

/// Fades a view based on scroll position
/// Useful for headers that fade out as user scrolls down
struct FadeOnScrollModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The scroll offset from the scroll view
    var scrollOffset: CGFloat

    /// The scroll range over which fading occurs
    var scrollRange: CGFloat = 100

    /// Minimum opacity (when fully scrolled)
    var minOpacity: CGFloat = 0.0

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : opacityValue)
    }

    private var opacityValue: CGFloat {
        guard scrollOffset < 0 else { return 1.0 }

        let progress = min(1.0, abs(scrollOffset) / scrollRange)
        return 1.0 - (progress * (1.0 - minOpacity))
    }
}

// MARK: - Staggered Reveal Container

/// Container that applies staggered reveal animations to its children
/// Each child animates in sequence with a configurable delay
struct StaggeredRevealContainer<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The content to display with staggered reveals
    let content: Content

    /// The base delay between each item
    var staggerDelay: Double = 0.08

    /// Whether animations should play (set to true when container becomes visible)
    @State private var shouldAnimate = false

    init(staggerDelay: Double = 0.08, @ViewBuilder content: () -> Content) {
        self.staggerDelay = staggerDelay
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation {
                    shouldAnimate = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies reveal-on-scroll animation to the view
    /// - Parameters:
    ///   - delay: The delay before the animation starts (default: 0)
    ///   - offsetY: The vertical offset from which the view animates in (default: 30)
    ///   - duration: The duration of the reveal animation (default: 0.4)
    /// - Returns: A view with reveal animation applied
    func revealOnScroll(delay: Double = 0, offsetY: CGFloat = 30, duration: Double = 0.4) -> some View {
        modifier(RevealOnScrollModifier(delay: delay, offsetY: offsetY, duration: duration))
    }

    /// Applies parallax effect based on scroll position
    /// - Parameters:
    ///   - scrollOffset: The current scroll offset
    ///   - intensity: The intensity of the parallax effect (0.0 - 1.0, default: 0.3)
    ///   - maxOffset: Maximum parallax offset in points (default: 50)
    /// - Returns: A view with parallax effect applied
    func parallax(scrollOffset: CGFloat, intensity: CGFloat = 0.3, maxOffset: CGFloat = 50) -> some View {
        modifier(ParallaxModifier(scrollOffset: scrollOffset, intensity: intensity, maxOffset: maxOffset))
    }

    /// Applies scale effect based on scroll position
    /// - Parameters:
    ///   - scrollOffset: The current scroll offset
    ///   - minScale: Minimum scale factor when fully scrolled (default: 0.95)
    ///   - scrollRange: The scroll range over which scaling occurs (default: 100)
    /// - Returns: A view with scale effect applied
    func scaleOnScroll(scrollOffset: CGFloat, minScale: CGFloat = 0.95, scrollRange: CGFloat = 100) -> some View {
        modifier(ScaleOnScrollModifier(scrollOffset: scrollOffset, minScale: minScale, scrollRange: scrollRange))
    }

    /// Applies fade effect based on scroll position
    /// - Parameters:
    ///   - scrollOffset: The current scroll offset
    ///   - scrollRange: The scroll range over which fading occurs (default: 100)
    ///   - minOpacity: Minimum opacity when fully scrolled (default: 0.0)
    /// - Returns: A view with fade effect applied
    func fadeOnScroll(scrollOffset: CGFloat, scrollRange: CGFloat = 100, minOpacity: CGFloat = 0.0) -> some View {
        modifier(FadeOnScrollModifier(scrollOffset: scrollOffset, scrollRange: scrollRange, minOpacity: minOpacity))
    }
}

// MARK: - Scroll Tracking Container

/// A scroll view wrapper that tracks scroll position and provides it to child views
/// Use this when you need to apply scroll-based animations to multiple children
struct ScrollTrackingContainer<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The current scroll offset, accessible by child views
    @Binding var scrollOffset: CGFloat

    /// Whether to show scroll indicators
    var showsIndicators: Bool = true

    /// The content of the scroll view
    let content: Content

    /// Coordinate space name for tracking
    private let coordinateSpace = "scrollTracking"

    init(
        scrollOffset: Binding<CGFloat>,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._scrollOffset = scrollOffset
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            VStack(spacing: 0) {
                ScrollOffsetReader(coordinateSpace: coordinateSpace)
                content
            }
        }
        .coordinateSpace(name: coordinateSpace)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ScrollAnimations_Previews: PreviewProvider {
    static var previews: some View {
        ScrollAnimationsPreview()
    }
}

struct ScrollAnimationsPreview: View {
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollTrackingContainer(scrollOffset: $scrollOffset) {
                VStack(spacing: 16) {
                    // Hero section with parallax
                    ZStack {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Text("Hero Section")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .parallax(scrollOffset: scrollOffset, intensity: 0.2)
                    .scaleOnScroll(scrollOffset: scrollOffset)
                    .padding()

                    // Staggered reveal cards
                    ForEach(0..<10) { index in
                        CardPreviewItem(index: index)
                            .revealOnScroll(delay: Double(index) * 0.05)
                    }
                }
            }
            .navigationTitle("Scroll Animations")
        }
    }
}

struct CardPreviewItem: View {
    let index: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Card Item \(index + 1)")
                    .font(.headline)
                Text("This card reveals with animation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
#endif
