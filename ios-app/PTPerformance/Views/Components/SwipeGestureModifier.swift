//
//  SwipeGestureModifier.swift
//  PTPerformance
//
//  ACP-503: Swipe-to-Complete Exercise
//  Reusable swipe gesture detection modifier for horizontal swipe interactions
//

import SwiftUI
import UIKit

// MARK: - Swipe Direction

/// Direction of a swipe gesture
enum SwipeDirection {
    case left
    case right
    case none
}

// MARK: - Swipe Action

/// Represents an action that can be triggered by a swipe
struct SwipeAction {
    let direction: SwipeDirection
    let threshold: CGFloat
    let color: Color
    let icon: String
    let label: String
    let action: () -> Void

    init(
        direction: SwipeDirection,
        threshold: CGFloat = 100,
        color: Color,
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) {
        self.direction = direction
        self.threshold = threshold
        self.color = color
        self.icon = icon
        self.label = label
        self.action = action
    }
}

// MARK: - Swipe State

/// Observable state for swipe gesture tracking
class SwipeGestureState: ObservableObject {
    @Published var offset: CGFloat = 0
    @Published var isDragging: Bool = false
    @Published var triggeredAction: SwipeDirection = .none

    /// Progress toward threshold (0.0 to 1.0)
    func progress(for direction: SwipeDirection, threshold: CGFloat) -> CGFloat {
        switch direction {
        case .right:
            return min(1.0, max(0, offset / threshold))
        case .left:
            return min(1.0, max(0, -offset / threshold))
        case .none:
            return 0
        }
    }

    /// Whether the gesture has passed the threshold for a direction
    func isPastThreshold(for direction: SwipeDirection, threshold: CGFloat) -> Bool {
        progress(for: direction, threshold: threshold) >= 1.0
    }

    /// Reset state to initial values
    func reset() {
        offset = 0
        isDragging = false
        triggeredAction = .none
    }
}

// MARK: - Swipe Gesture Modifier

/// A view modifier that adds horizontal swipe gesture detection with visual feedback
struct SwipeGestureModifier: ViewModifier {
    // MARK: - Properties

    let rightAction: SwipeAction?
    let leftAction: SwipeAction?
    let isEnabled: Bool
    let onSwipeProgress: ((SwipeDirection, CGFloat) -> Void)?

    @StateObject private var state = SwipeGestureState()
    @State private var actionTriggered = false

    // MARK: - Initialization

    init(
        rightAction: SwipeAction? = nil,
        leftAction: SwipeAction? = nil,
        isEnabled: Bool = true,
        onSwipeProgress: ((SwipeDirection, CGFloat) -> Void)? = nil
    ) {
        self.rightAction = rightAction
        self.leftAction = leftAction
        self.isEnabled = isEnabled
        self.onSwipeProgress = onSwipeProgress
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        ZStack {
            // Background action indicators
            HStack(spacing: 0) {
                // Right swipe action (left side background)
                if let action = rightAction {
                    swipeActionBackground(for: action, isRevealed: state.offset > 20)
                }

                Spacer()

                // Left swipe action (right side background)
                if let action = leftAction {
                    swipeActionBackground(for: action, isRevealed: state.offset < -20)
                }
            }
            .cornerRadius(CornerRadius.md)

            // Main content with gesture
            content
                .offset(x: state.offset)
                .gesture(
                    isEnabled ? createDragGesture() : nil
                )
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func swipeActionBackground(for action: SwipeAction, isRevealed: Bool) -> some View {
        HStack(spacing: 8) {
            if action.direction == .right {
                Image(systemName: action.icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(action.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text(action.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: action.icon)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
        .frame(width: action.threshold + 20)
        .frame(maxHeight: .infinity)
        .background(action.color)
        .opacity(isRevealed ? 1 : 0)
        .scaleEffect(isRevealed ? 1.0 : 0.8)
        .animation(.easeOut(duration: 0.15), value: isRevealed)
    }

    // MARK: - Gesture

    private func createDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        // Only respond to horizontal swipes
        guard abs(value.translation.width) > abs(value.translation.height) else { return }

        state.isDragging = true

        // Apply resistance at edges
        let translation = value.translation.width
        _ = max(rightAction?.threshold ?? 0, leftAction?.threshold ?? 0) * 1.3  // maxOffset for future edge resistance

        // Rubber-band effect beyond threshold
        if translation > 0 && rightAction != nil {
            let threshold = rightAction?.threshold ?? 100
            if translation > threshold {
                let overshoot = translation - threshold
                state.offset = threshold + (overshoot * 0.3)
            } else {
                state.offset = translation
            }
        } else if translation < 0 && leftAction != nil {
            let threshold = leftAction?.threshold ?? 100
            if -translation > threshold {
                let overshoot = -translation - threshold
                state.offset = -threshold - (overshoot * 0.3)
            } else {
                state.offset = translation
            }
        } else {
            // No action for this direction - apply heavy resistance
            state.offset = translation * 0.2
        }

        // Notify progress
        let direction: SwipeDirection = state.offset > 0 ? .right : (state.offset < 0 ? .left : .none)
        let progress = direction == .right
            ? state.progress(for: .right, threshold: rightAction?.threshold ?? 100)
            : state.progress(for: .left, threshold: leftAction?.threshold ?? 100)
        onSwipeProgress?(direction, progress)

        // Haptic feedback at threshold
        if let action = rightAction, state.isPastThreshold(for: .right, threshold: action.threshold), !actionTriggered {
            HapticFeedback.medium()
            actionTriggered = true
        } else if let action = leftAction, state.isPastThreshold(for: .left, threshold: action.threshold), !actionTriggered {
            HapticFeedback.medium()
            actionTriggered = true
        } else if !state.isPastThreshold(for: .right, threshold: rightAction?.threshold ?? 100) &&
                    !state.isPastThreshold(for: .left, threshold: leftAction?.threshold ?? 100) {
            actionTriggered = false
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        state.isDragging = false

        // Check if action should be triggered
        if let action = rightAction, state.isPastThreshold(for: .right, threshold: action.threshold) {
            triggerAction(action, direction: .right)
        } else if let action = leftAction, state.isPastThreshold(for: .left, threshold: action.threshold) {
            triggerAction(action, direction: .left)
        } else {
            // Snap back with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.offset = 0
            }
        }

        actionTriggered = false
    }

    private func triggerAction(_ action: SwipeAction, direction: SwipeDirection) {
        state.triggeredAction = direction

        // Haptic feedback for action completion
        HapticFeedback.success()

        // Animate off screen
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            state.offset = direction == .right ? screenWidth : -screenWidth
        }

        // Execute action after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action.action()

            // Reset state
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.reset()
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds swipe gesture handling to a view
    /// - Parameters:
    ///   - rightAction: Action triggered by swiping right (complete)
    ///   - leftAction: Action triggered by swiping left (skip/modify)
    ///   - isEnabled: Whether swipe gestures are enabled
    ///   - onSwipeProgress: Callback for swipe progress updates
    func swipeActions(
        rightAction: SwipeAction? = nil,
        leftAction: SwipeAction? = nil,
        isEnabled: Bool = true,
        onSwipeProgress: ((SwipeDirection, CGFloat) -> Void)? = nil
    ) -> some View {
        self.modifier(SwipeGestureModifier(
            rightAction: rightAction,
            leftAction: leftAction,
            isEnabled: isEnabled,
            onSwipeProgress: onSwipeProgress
        ))
    }
}

// MARK: - Preview

#Preview("Swipe Gesture Demo") {
    VStack(spacing: 20) {
        Text("Swipe the card below")
            .font(.headline)

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue.opacity(0.1))
            .frame(height: 80)
            .overlay(
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Sample Exercise")
                            .font(.headline)
                        Text("3 x 10 reps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            )
            .swipeActions(
                rightAction: SwipeAction(
                    direction: .right,
                    threshold: 100,
                    color: .green,
                    icon: "checkmark.circle.fill",
                    label: "Complete",
                    action: { print("Completed!") }
                ),
                leftAction: SwipeAction(
                    direction: .left,
                    threshold: 100,
                    color: .orange,
                    icon: "forward.fill",
                    label: "Skip",
                    action: { print("Skipped!") }
                )
            )
            .padding(.horizontal)

        Text("Swipe right to complete, left to skip")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
