//
//  SetLoggingComponents.swift
//  PTPerformance
//
//  Extracted from ManualWorkoutExecutionView.swift
//  Gesture-based input components for logging sets, reps, and weight
//

import SwiftUI

// MARK: - Tappable Rep Counter

/// Tappable rep counter with gesture interactions for fast logging
/// - Tap: +1 rep
/// - Long press: -1 rep
/// - Double tap: Reset to prescribed
struct TappableRepCounter: View {
    @Binding var reps: Int
    let prescribedReps: Int

    @State private var isPressed = false

    var body: some View {
        Text("\(reps)")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(minWidth: 50)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(reps == prescribedReps ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(reps == prescribedReps ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Double tap = reset to prescribed
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            reps = prescribedReps
                            isPressed = true
                        }
                        HapticFeedback.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2)) {
                                isPressed = false
                            }
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                        // Long press = -1
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            reps = max(0, reps - 1)
                            isPressed = true
                        }
                        HapticFeedback.medium()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2)) {
                                isPressed = false
                            }
                        }
                    }
            )
            .onTapGesture {
                // Single tap = +1
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    reps += 1
                    isPressed = true
                }
                HapticFeedback.light()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
            }
            .accessibilityLabel("Reps: \(reps)")
            .accessibilityHint("Tap to add one rep, long press to subtract, double tap to reset to \(prescribedReps)")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Swipeable Weight Control

/// Swipeable weight control with drag gestures for fast adjustment
/// - Swipe up: +5 lbs (or custom increment)
/// - Swipe down: -5 lbs (or custom increment)
struct SwipeableWeightControl: View {
    @Binding var weight: Double
    var increment: Double = 5.0

    @State private var dragOffset: CGFloat = 0
    @State private var showIncrement = false
    @State private var lastChangeDirection: Int = 0 // -1 down, 0 none, 1 up

    private let threshold: CGFloat = 30

    var body: some View {
        VStack(spacing: 2) {
            // Up indicator (appears on drag up)
            Image(systemName: "chevron.up")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .opacity(dragOffset < -10 ? min(1, abs(dragOffset) / threshold) : 0)
                .scaleEffect(dragOffset < -threshold ? 1.2 : 1.0)

            ZStack {
                // Weight display
                Text("\(Int(weight))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 60)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(abs(dragOffset) > threshold ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
                    .offset(y: min(max(dragOffset * 0.2, -15), 15))

                // Increment indicator overlay
                if showIncrement && lastChangeDirection != 0 {
                    Text(lastChangeDirection > 0 ? "+\(Int(increment))" : "-\(Int(increment))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(lastChangeDirection > 0 ? .green : .orange)
                        .offset(y: lastChangeDirection > 0 ? -30 : 30)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height < -threshold {
                            // Swiped up = increase weight
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                weight += increment
                                lastChangeDirection = 1
                                showIncrement = true
                            }
                            HapticFeedback.light()
                        } else if value.translation.height > threshold {
                            // Swiped down = decrease weight
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                weight = max(0, weight - increment)
                                lastChangeDirection = -1
                                showIncrement = true
                            }
                            HapticFeedback.light()
                        }

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }

                        // Hide increment indicator after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showIncrement = false
                            }
                        }
                    }
            )

            // Down indicator (appears on drag down)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .opacity(dragOffset > 10 ? min(1, dragOffset / threshold) : 0)
                .scaleEffect(dragOffset > threshold ? 1.2 : 1.0)
        }
        .accessibilityLabel("Weight: \(Int(weight)) pounds")
        .accessibilityHint("Swipe up to add \(Int(increment)) pounds, swipe down to subtract")
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                weight += increment
                HapticFeedback.light()
            case .decrement:
                weight = max(0, weight - increment)
                HapticFeedback.light()
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Gesture Set Row

/// Combined gesture-enabled set row with tappable reps and swipeable weight
struct GestureSetRow: View {
    let setNumber: Int
    @Binding var reps: Int
    @Binding var weight: Double
    let prescribedReps: Int
    let prescribedWeight: Double
    let loadUnit: String

    var body: some View {
        HStack(spacing: 12) {
            // Set number indicator
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)

                Text("\(setNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Reps (tappable)
            VStack(spacing: 4) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                TappableRepCounter(reps: $reps, prescribedReps: prescribedReps)
            }

            Text("x")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            // Weight (swipeable)
            VStack(spacing: 4) {
                Text(loadUnit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                SwipeableWeightControl(weight: $weight, increment: 5.0)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .adaptiveShadow(Shadow.subtle)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Set \(setNumber): \(reps) reps at \(Int(weight)) \(loadUnit)")
    }
}

// MARK: - Gesture Hint Overlay

/// Hint overlay to teach gesture interactions
struct GestureHintOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Quick Gestures")
                        .font(.headline)
                        .fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 16) {
                        gestureHintRow(
                            icon: "hand.tap.fill",
                            title: "Tap Reps",
                            description: "+1 rep"
                        )
                        gestureHintRow(
                            icon: "hand.tap.fill",
                            title: "Long Press Reps",
                            description: "-1 rep"
                        )
                        gestureHintRow(
                            icon: "hand.tap.fill",
                            title: "Double Tap Reps",
                            description: "Reset to prescribed"
                        )

                        Divider()

                        gestureHintRow(
                            icon: "arrow.up",
                            title: "Swipe Weight Up",
                            description: "+5 lbs"
                        )
                        gestureHintRow(
                            icon: "arrow.down",
                            title: "Swipe Weight Down",
                            description: "-5 lbs"
                        )

                        Divider()

                        gestureHintRow(
                            icon: "hand.draw.fill",
                            title: "Swipe Exercise Right",
                            description: "Complete as prescribed"
                        )
                        gestureHintRow(
                            icon: "hand.draw.fill",
                            title: "Swipe Exercise Left",
                            description: "Skip exercise"
                        )
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .adaptiveShadow(Shadow.prominent)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isVisible = false
                    }
                } label: {
                    Text("Got it!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .accessibilityLabel("Dismiss gesture hints")
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.4))
            .transition(.opacity)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private func gestureHintRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Swipeable Exercise Row

/// Swipeable wrapper for exercise rows with complete/skip gestures
/// - Swipe RIGHT: Complete exercise with prescribed values
/// - Swipe LEFT: Skip exercise
struct SwipeableExerciseRow<Content: View>: View {
    let exercise: ManualSessionExercise
    let isCompleted: Bool
    let isSkipped: Bool
    let onComplete: () -> Void
    let onSkip: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var actionTriggered = false

    private let completeThreshold: CGFloat = 100
    private let skipThreshold: CGFloat = -100

    var body: some View {
        ZStack {
            // Background actions (revealed on swipe)
            HStack {
                // Complete action (revealed on right swipe)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 100)
                .frame(maxHeight: .infinity)
                .background(Color.green)
                .opacity(offset > 20 ? 1 : 0)

                Spacer()

                // Skip action (revealed on left swipe)
                HStack(spacing: 8) {
                    Text("Skip")
                    Image(systemName: "forward.fill")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 100)
                .frame(maxHeight: .infinity)
                .background(Color.orange)
                .opacity(offset < -20 ? 1 : 0)
            }
            .cornerRadius(8)

            // Main content
            content()
                .offset(x: offset)
                .gesture(
                    isCompleted || isSkipped ? nil :
                    DragGesture()
                        .onChanged { value in
                            // Only allow horizontal swipes
                            if abs(value.translation.width) > abs(value.translation.height) {
                                withAnimation(.interactiveSpring()) {
                                    offset = value.translation.width
                                }
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > completeThreshold && !actionTriggered {
                                // Complete exercise
                                actionTriggered = true
                                HapticFeedback.success()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onComplete()
                                    offset = 0
                                    actionTriggered = false
                                }
                            } else if value.translation.width < skipThreshold && !actionTriggered {
                                // Skip exercise
                                actionTriggered = true
                                HapticFeedback.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = -UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onSkip()
                                    offset = 0
                                    actionTriggered = false
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .accessibilityAction(named: "Complete as Prescribed") {
            onComplete()
        }
        .accessibilityAction(named: "Skip Exercise") {
            onSkip()
        }
    }
}

// MARK: - Previews

#if DEBUG
struct SetLoggingComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GestureSetRow(
                setNumber: 1,
                reps: .constant(10),
                weight: .constant(135),
                prescribedReps: 10,
                prescribedWeight: 135,
                loadUnit: "lbs"
            )

            GestureSetRow(
                setNumber: 2,
                reps: .constant(8),
                weight: .constant(140),
                prescribedReps: 10,
                prescribedWeight: 135,
                loadUnit: "lbs"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
