//
//  StaggeredListAnimation.swift
//  PTPerformance
//
//  Reusable staggered list item entrance animations
//  Creates a pleasing cascade effect when list items appear
//

import SwiftUI

// MARK: - Staggered Animation Modifier

/// A view modifier that applies staggered entrance animations to list items
/// Respects the user's reduced motion accessibility preference
struct StaggeredAnimationModifier: ViewModifier {
    /// The index of this item in the list (used for calculating delay)
    let index: Int

    /// Whether the animation should be active
    let isVisible: Bool

    /// Base delay per item in seconds (default: 0.05s)
    var baseDelay: Double = 0.05

    /// Maximum total delay in seconds (default: 0.5s)
    var maxDelay: Double = 0.5

    /// The spring response parameter
    var springResponse: Double = 0.4

    /// The spring damping fraction
    var dampingFraction: Double = 0.8

    /// The vertical offset for the animation start position
    var offsetY: CGFloat = 20

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(animatedOpacity)
            .offset(y: animatedOffset)
            .onAppear {
                guard !hasAppeared else { return }

                if reduceMotion {
                    // Immediately show without animation for reduce motion
                    hasAppeared = true
                } else {
                    // Calculate staggered delay (capped at maxDelay)
                    let delay = min(Double(index) * baseDelay, maxDelay)

                    withAnimation(
                        .spring(response: springResponse, dampingFraction: dampingFraction)
                        .delay(delay)
                    ) {
                        hasAppeared = true
                    }
                }
            }
    }

    private var animatedOpacity: Double {
        if reduceMotion || !isVisible {
            return 1.0
        }
        return hasAppeared ? 1.0 : 0.0
    }

    private var animatedOffset: CGFloat {
        if reduceMotion || !isVisible {
            return 0
        }
        return hasAppeared ? 0 : offsetY
    }
}

// MARK: - AnimatedListItem View

/// A wrapper view that applies staggered entrance animation to its content
struct AnimatedListItem<Content: View>: View {
    /// The index of this item in the list
    let index: Int

    /// Whether the animation should be active (defaults to true)
    var isVisible: Bool = true

    /// The content to animate
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .modifier(StaggeredAnimationModifier(index: index, isVisible: isVisible))
    }
}

// MARK: - View Extension

extension View {
    /// Applies a staggered entrance animation to this view
    /// - Parameters:
    ///   - index: The index of this item in the list (used for delay calculation)
    ///   - isVisible: Whether the animation should be active (default: true)
    ///   - baseDelay: Base delay per item in seconds (default: 0.05s)
    ///   - maxDelay: Maximum total delay in seconds (default: 0.5s)
    /// - Returns: A view with the staggered animation applied
    func staggeredAnimation(
        index: Int,
        isVisible: Bool = true,
        baseDelay: Double = 0.05,
        maxDelay: Double = 0.5
    ) -> some View {
        modifier(
            StaggeredAnimationModifier(
                index: index,
                isVisible: isVisible,
                baseDelay: baseDelay,
                maxDelay: maxDelay
            )
        )
    }

    /// Applies a staggered entrance animation with custom spring parameters
    /// - Parameters:
    ///   - index: The index of this item in the list
    ///   - isVisible: Whether the animation should be active
    ///   - baseDelay: Base delay per item in seconds
    ///   - maxDelay: Maximum total delay
    ///   - springResponse: The spring response parameter
    ///   - dampingFraction: The spring damping fraction
    ///   - offsetY: The vertical offset for animation start
    /// - Returns: A view with the custom staggered animation applied
    func staggeredAnimation(
        index: Int,
        isVisible: Bool = true,
        baseDelay: Double = 0.05,
        maxDelay: Double = 0.5,
        springResponse: Double = 0.4,
        dampingFraction: Double = 0.8,
        offsetY: CGFloat = 20
    ) -> some View {
        modifier(
            StaggeredAnimationModifier(
                index: index,
                isVisible: isVisible,
                baseDelay: baseDelay,
                maxDelay: maxDelay,
                springResponse: springResponse,
                dampingFraction: dampingFraction,
                offsetY: offsetY
            )
        )
    }
}

// MARK: - Preview

#if DEBUG
struct StaggeredListAnimation_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        AnimatedListItem(index: index) {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)

                                VStack(alignment: .leading) {
                                    Text("Item \(index + 1)")
                                        .font(.headline)
                                    Text("Animated list item with stagger effect")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Staggered Animation")
        }
    }
}
#endif
