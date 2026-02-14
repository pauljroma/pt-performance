//
//  GestureSetLogger.swift
//  PTPerformance
//
//  ACP-514: Gesture-Based Set Logging
//  A touch-optimized component for logging sets during workouts
//
//  Gestures:
//  - Single tap: +1 rep
//  - Double tap: Complete set
//  - Swipe up: +5 lbs weight
//  - Swipe down: -5 lbs weight
//

import SwiftUI

// MARK: - Gesture Set Logger View

/// A gesture-based interface for quickly logging sets during workouts
/// Optimized for single-hand operation during exercises
struct GestureSetLogger: View {

    // MARK: - Properties

    @StateObject private var viewModel: GestureSetLoggerViewModel

    /// Callback when a set is completed
    var onSetComplete: ((Int, Int, Double) -> Void)?  // (setNumber, reps, weight)

    /// Callback when all target sets are complete
    var onAllSetsComplete: (() -> Void)?

    /// Binding for external rep count control (optional)
    @Binding var externalRepCount: Int?

    /// Binding for external weight control (optional)
    @Binding var externalWeight: Double?

    // MARK: - Private State

    @State private var showUndoConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    // MARK: - Initialization

    init(
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        weightUnit: String = "lbs",
        onSetComplete: ((Int, Int, Double) -> Void)? = nil,
        onAllSetsComplete: (() -> Void)? = nil,
        externalRepCount: Binding<Int?> = .constant(nil),
        externalWeight: Binding<Double?> = .constant(nil)
    ) {
        self._viewModel = StateObject(wrappedValue: GestureSetLoggerViewModel(
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: targetWeight,
            weightUnit: weightUnit
        ))
        self.onSetComplete = onSetComplete
        self.onAllSetsComplete = onAllSetsComplete
        self._externalRepCount = externalRepCount
        self._externalWeight = externalWeight
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Sets Progress Header
            setsProgressHeader

            // Main Gesture Area
            gestureArea

            // Logged Sets Summary
            if !viewModel.loggedSets.isEmpty {
                loggedSetsSummary
            }

            // Error Message
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
        .onChange(of: viewModel.repCount) { _, newValue in
            externalRepCount = newValue
        }
        .onChange(of: viewModel.weight) { _, newValue in
            externalWeight = newValue
        }
        .onChange(of: viewModel.completedSets) { oldValue, newValue in
            // Notify when a set is completed
            if newValue > oldValue, let lastSet = viewModel.loggedSets.last {
                onSetComplete?(lastSet.setNumber, lastSet.reps, lastSet.weight)

                // Check if all sets are complete
                if viewModel.allSetsComplete {
                    onAllSetsComplete?()
                }
            }
        }
        .confirmationDialog("Undo Last Set?", isPresented: $showUndoConfirmation) {
            Button("Undo", role: .destructive) {
                viewModel.undoLastSet()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the last logged set.")
        }
    }

    // MARK: - Sets Progress Header

    private var setsProgressHeader: some View {
        VStack(spacing: Spacing.xs) {
            // Set number display
            Text(viewModel.setsDisplay)
                .font(.headline)
                .foregroundColor(.secondary)

            // Progress bar (if target sets defined)
            if let targetSets = viewModel.targetSets, targetSets > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.allSetsComplete ? Color.green : Color.modusCyan)
                            .frame(
                                width: geometry.size.width * viewModel.setsProgress,
                                height: 8
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.setsProgress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Main Gesture Area

    private var gestureArea: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(gestureAreaBackground)
                .shadow(color: Color(.systemGray4).opacity(0.1), radius: 8, y: 4)

            // Content
            VStack(spacing: Spacing.xl) {
                // Weight Display (top)
                weightDisplay

                // Rep Counter (center)
                repCounter

                // Gesture Hints (bottom)
                gestureHints
            }
            .padding(Spacing.lg)

            // Drag indicator overlay
            if isDragging {
                dragIndicator
            }
        }
        .frame(height: 320)
        .contentShape(Rectangle())
        .gesture(combinedGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Set logger. \(viewModel.repCount) reps at \(viewModel.weightDisplay)")
        .accessibilityHint("Tap to add rep, double tap to complete set, swipe up or down to adjust weight")
    }

    private var gestureAreaBackground: Color {
        if viewModel.isSetComplete {
            return Color.green.opacity(0.15)
        } else if viewModel.repCount > 0 {
            return Color.modusCyan.opacity(0.08)
        }
        return Color(.secondarySystemBackground)
    }

    // MARK: - Weight Display

    private var weightDisplay: some View {
        VStack(spacing: Spacing.xxs) {
            // Weight change indicator
            HStack(spacing: Spacing.xs) {
                if viewModel.lastWeightChangeDirection == .up {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if viewModel.lastWeightChangeDirection == .down {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.orange)
                        .transition(.scale.combined(with: .opacity))
                }

                Text(viewModel.weightDisplay)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(viewModel.weightAnimationTrigger ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.weightAnimationTrigger)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.lastWeightChangeDirection)

            // Target weight indicator
            if let targetWeight = viewModel.targetWeight, targetWeight > 0 {
                Text("Target: \(Int(targetWeight)) \(viewModel.weightUnit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weight: \(viewModel.weightDisplay)")
    }

    // MARK: - Rep Counter

    private var repCounter: some View {
        VStack(spacing: Spacing.xs) {
            // Large rep count
            Text("\(viewModel.repCount)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(viewModel.repCount > 0 ? .primary : .secondary)
                .scaleEffect(viewModel.repAnimationTrigger ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.repAnimationTrigger)
                .accessibilityHidden(true)

            // Rep label
            HStack(spacing: Spacing.xxs) {
                Text("REPS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if let targetReps = viewModel.targetReps {
                    Text("/ \(targetReps)")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.repCount) reps")
    }

    // MARK: - Gesture Hints

    private var gestureHints: some View {
        HStack(spacing: Spacing.lg) {
            gestureHint(icon: "hand.tap.fill", text: "Tap +1")
            gestureHint(icon: "hand.tap.fill", text: "2x Done")
            gestureHint(icon: "arrow.up.arrow.down", text: "Swipe Weight")
        }
        .padding(.horizontal)
    }

    private func gestureHint(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        VStack {
            if dragOffset.height < -20 {
                // Swiping up
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("+\(Int(viewModel.weightIncrement)) \(viewModel.weightUnit)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if dragOffset.height > 20 {
                // Swiping down
                VStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("-\(Int(viewModel.weightIncrement)) \(viewModel.weightUnit)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: dragOffset.height)
    }

    // MARK: - Logged Sets Summary

    private var loggedSetsSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Logged Sets")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Undo button
                Button {
                    showUndoConfirmation = true
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Undo last set")
            }

            // Set chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(viewModel.loggedSets) { loggedSet in
                        setChip(loggedSet)
                    }
                }
            }

            // Volume summary
            let totalVolume = viewModel.getTotalVolume()
            if totalVolume > 0 {
                HStack {
                    Text("Total Volume:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalVolume >= 1000 ? String(format: "%.1fk lbs", totalVolume / 1000) : "\(Int(totalVolume)) lbs")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func setChip(_ loggedSet: GestureSetLoggerViewModel.LoggedSet) -> some View {
        VStack(spacing: 2) {
            Text("Set \(loggedSet.setNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text("\(loggedSet.reps)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if loggedSet.weight > 0 {
                    Text("@")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(loggedSet.weight))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.green.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Combined Gesture

    private var combinedGesture: some Gesture {
        // Simultaneous tap and drag gestures
        SimultaneousGesture(
            tapGestures,
            dragGesture
        )
    }

    private var tapGestures: some Gesture {
        // Use ExclusiveGesture to prioritize double tap over single tap
        ExclusiveGesture(
            // Double tap (higher priority)
            TapGesture(count: 2)
                .onEnded {
                    viewModel.handleDoubleTap()
                },
            // Single tap
            TapGesture(count: 1)
                .onEnded {
                    viewModel.handleTap()
                }
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                dragOffset = .zero

                // Determine swipe direction
                let verticalMovement = value.translation.height
                let threshold: CGFloat = 50

                if verticalMovement < -threshold {
                    // Swipe up - increase weight
                    viewModel.handleSwipeUp()
                } else if verticalMovement > threshold {
                    // Swipe down - decrease weight
                    viewModel.handleSwipeDown()
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
struct GestureSetLogger_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GestureSetLogger(
                targetSets: 4,
                targetReps: 10,
                targetWeight: 135,
                weightUnit: "lbs",
                onSetComplete: { setNumber, reps, weight in
                    print("Set \(setNumber): \(reps) reps @ \(weight) lbs")
                },
                onAllSetsComplete: {
                    print("All sets complete!")
                }
            )
            .padding()
        }
        .previewDisplayName("With Targets")

        VStack {
            GestureSetLogger(
                onSetComplete: { setNumber, reps, weight in
                    print("Set \(setNumber): \(reps) reps @ \(weight) lbs")
                }
            )
            .padding()
        }
        .previewDisplayName("No Targets")
    }
}
#endif

// MARK: - Compact Gesture Set Logger

/// A more compact version of GestureSetLogger for inline use
struct CompactGestureSetLogger: View {

    @StateObject private var viewModel: GestureSetLoggerViewModel

    var onSetComplete: ((Int, Int, Double) -> Void)?

    @State private var dragOffset: CGSize = .zero

    init(
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        weightUnit: String = "lbs",
        onSetComplete: ((Int, Int, Double) -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: GestureSetLoggerViewModel(
            targetSets: nil,
            targetReps: targetReps,
            targetWeight: targetWeight,
            weightUnit: weightUnit
        ))
        self.onSetComplete = onSetComplete
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rep counter
            VStack(spacing: 2) {
                Text("\(viewModel.repCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(viewModel.repAnimationTrigger ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: viewModel.repAnimationTrigger)

                Text("reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            // Divider
            Divider()
                .frame(height: 40)

            // Weight display
            VStack(spacing: 2) {
                Text(viewModel.weightDisplay)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(viewModel.weightAnimationTrigger ? 1.05 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: viewModel.weightAnimationTrigger)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                    Text("swipe")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .frame(width: 80)

            Spacer()

            // Complete button
            Button {
                viewModel.handleDoubleTap()
                if let lastSet = viewModel.loggedSets.last {
                    onSetComplete?(lastSet.setNumber, lastSet.reps, lastSet.weight)
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.repCount > 0 ? .green : .secondary)
            }
            .disabled(viewModel.repCount == 0)
            .accessibilityLabel("Complete set")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                TapGesture()
                    .onEnded {
                        viewModel.handleTap()
                    },
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.height < -50 {
                            viewModel.handleSwipeUp()
                        } else if value.translation.height > 50 {
                            viewModel.handleSwipeDown()
                        }
                    }
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.repCount) reps at \(viewModel.weightDisplay)")
        .accessibilityHint("Tap to add rep, swipe up or down to adjust weight")
    }
}
