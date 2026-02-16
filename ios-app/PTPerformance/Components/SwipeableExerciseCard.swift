//
//  SwipeableExerciseCard.swift
//  PTPerformance
//
//  ACP-503: Swipe-to-Complete Exercise
//  Gesture-based exercise card with swipe-to-complete and swipe-to-modify functionality
//

import SwiftUI
import UIKit

// MARK: - Modification Option

/// Options available when swiping left on an exercise
enum ExerciseModificationOption: String, CaseIterable, Identifiable {
    case skip = "Skip"
    case reduceReps = "Reduce Reps"
    case reduceSets = "Reduce Sets"
    case reduceWeight = "Reduce Weight"
    case substituteExercise = "Substitute"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .skip: return "forward.fill"
        case .reduceReps: return "minus.circle"
        case .reduceSets: return "minus.square.fill"
        case .reduceWeight: return "scalemass"
        case .substituteExercise: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .skip: return .orange
        case .reduceReps: return .blue
        case .reduceSets: return .purple
        case .reduceWeight: return .teal
        case .substituteExercise: return .indigo
        }
    }
}

// MARK: - Card State

/// Visual state of the exercise card
enum ExerciseCardState: Equatable {
    case idle
    case swipingRight(progress: CGFloat)
    case swipingLeft(progress: CGFloat)
    case completed
    case skipped
    case modified

    static func == (lhs: ExerciseCardState, rhs: ExerciseCardState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.completed, .completed): return true
        case (.skipped, .skipped): return true
        case (.modified, .modified): return true
        case let (.swipingRight(p1), .swipingRight(p2)): return p1 == p2
        case let (.swipingLeft(p1), .swipingLeft(p2)): return p1 == p2
        default: return false
        }
    }
}

// MARK: - Swipeable Exercise Card

/// A gesture-driven exercise card with swipe-to-complete and swipe-to-modify interactions
/// - Swipe right: Marks the set as complete with haptic feedback
/// - Swipe left: Shows modification options (skip, reduce reps, etc.)
struct SwipeableExerciseCard: View {
    // MARK: - Properties

    let exercise: ManualSessionExercise
    let setNumber: Int
    let totalSets: Int
    let isCompleted: Bool
    let isSkipped: Bool
    var actualReps: Int?
    var actualWeight: Double?

    /// Called when the exercise set is completed via swipe
    let onComplete: () -> Void

    /// Called when a modification option is selected
    let onModify: (ExerciseModificationOption) -> Void

    /// Optional: Called when the card is tapped (for detailed logging)
    var onTap: (() -> Void)?

    /// Optional: Called when user taps reps to edit
    var onEditReps: (() -> Void)?

    /// Optional: Called when user taps weight to edit
    var onEditWeight: (() -> Void)?

    // MARK: - State

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var showModificationSheet = false
    @State private var cardState: ExerciseCardState = .idle
    @State private var completionScale: CGFloat = 1.0
    @State private var completionOpacity: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var backgroundGradientProgress: CGFloat = 0
    @State private var showCompletionCheckmark = false
    @State private var hasTriggeredThresholdHaptic = false

    // Gesture thresholds
    private let completeThreshold: CGFloat = 120
    private let modifyThreshold: CGFloat = -80

    // MARK: - Computed Properties

    private var swipeProgress: CGFloat {
        if offset > 0 {
            return min(1.0, offset / completeThreshold)
        } else if offset < 0 {
            return min(1.0, -offset / abs(modifyThreshold))
        }
        return 0
    }

    private var isDisabled: Bool {
        isCompleted || isSkipped
    }

    private var cardBackgroundColor: Color {
        if isCompleted {
            return Color.modusTealAccent.opacity(0.1)
        } else if isSkipped {
            return DesignTokens.statusWarning.opacity(0.1)
        }
        return Color(.systemBackground)
    }

    private var statusIcon: String? {
        if isCompleted {
            return "checkmark.circle.fill"
        } else if isSkipped {
            return "forward.circle.fill"
        }
        return nil
    }

    private var statusColor: Color {
        if isCompleted {
            return .modusTealAccent
        } else if isSkipped {
            return DesignTokens.statusWarning
        }
        return .clear
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background action indicators
            backgroundActionsView

            // Main card content
            ZStack {
                mainCardView
                    .offset(x: offset)
                    .scaleEffect(completionScale)
                    .opacity(completionOpacity)
                    .gesture(isDisabled ? nil : dragGesture)
                    .onTapGesture {
                        if !isDisabled {
                            onTap?()
                        }
                    }

                // Completion checkmark overlay
                if showCompletionCheckmark {
                    completionOverlay
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: cardState)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: offset)
        .sheet(isPresented: $showModificationSheet) {
            ModificationOptionsSheet(
                exercise: exercise,
                onSelect: { option in
                    handleModificationSelected(option)
                }
            )
            .presentationDetents([.medium])
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(named: "Complete Set") {
            if !isDisabled {
                triggerCompletion()
            }
        }
        .accessibilityAction(named: "Show Options") {
            if !isDisabled {
                showModificationSheet = true
            }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.modusTealAccent.opacity(0.95))

            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(iconRotation))

                Text("Complete!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Background Actions View

    private var backgroundActionsView: some View {
        HStack(spacing: 0) {
            // Complete action (revealed on right swipe)
            completeActionBackground

            Spacer()

            // Modify action (revealed on left swipe)
            modifyActionBackground
        }
        .cornerRadius(CornerRadius.md)
    }

    private var completeActionBackground: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .fontWeight(.bold)
                .rotationEffect(.degrees(iconRotation))

            VStack(alignment: .leading, spacing: 2) {
                Text("Complete")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Set \(setNumber)")
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .foregroundColor(.white)
        .frame(width: completeThreshold + 40)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.modusTealAccent.opacity(0.9), Color.modusTealAccent],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .opacity(offset > 20 ? min(1.0, offset / 60) : 0)
        .scaleEffect(x: offset > completeThreshold ? 1.0 + (offset - completeThreshold) * 0.002 : 1.0, y: 1.0, anchor: .leading)
    }

    private var modifyActionBackground: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Options")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Modify")
                    .font(.caption)
                    .opacity(0.8)
            }

            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 28))
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .frame(width: abs(modifyThreshold) + 40)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [DesignTokens.statusWarning, DesignTokens.statusWarning.opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .opacity(offset < -20 ? min(1.0, -offset / 40) : 0)
    }

    // MARK: - Main Card View

    private var mainCardView: some View {
        HStack(spacing: 16) {
            // Set indicator
            setIndicator

            // Exercise info
            exerciseInfo

            Spacer()

            // Prescription details
            prescriptionDetails

            // Status indicator
            if let icon = statusIcon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(cardBackgroundColor)

                // Progress gradient overlay for right swipe
                if offset > 0 {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.modusTealAccent.opacity(0.2 * swipeProgress),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                // Progress gradient overlay for left swipe
                if offset < 0 {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    DesignTokens.statusWarning.opacity(0.15 * swipeProgress)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .adaptiveShadow(Shadow.subtle)
    }

    private var setIndicator: some View {
        ZStack {
            Circle()
                .fill(setIndicatorColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Circle()
                .stroke(setIndicatorColor, lineWidth: 2)
                .frame(width: 44, height: 44)

            Text("\(setNumber)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(setIndicatorColor)
        }
    }

    private var setIndicatorColor: Color {
        if isCompleted {
            return .modusTealAccent
        } else if isSkipped {
            return DesignTokens.statusWarning
        } else if offset > 0 {
            return Color.modusTealAccent.opacity(0.5 + swipeProgress * 0.5)
        }
        return .modusCyan
    }

    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.exerciseName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isDisabled ? .secondary : .primary)
                .lineLimit(1)

            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var prescriptionDetails: some View {
        VStack(alignment: .trailing, spacing: Spacing.xxs) {
            // Reps (tappable for quick edit)
            Button {
                if !isDisabled, let onEditReps = onEditReps {
                    HapticFeedback.light()
                    onEditReps()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(String(actualReps ?? Int(exercise.targetReps ?? "10") ?? 10))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isDisabled ? .secondary : .modusPrimary)
                    Text("reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !isDisabled && onEditReps != nil {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(.modusCyan.opacity(0.6))
                    }
                }
            }
            .disabled(isDisabled || onEditReps == nil)
            .accessibilityLabel("\(actualReps ?? Int(exercise.targetReps ?? "10") ?? 10) reps")
            .accessibilityHint(isDisabled ? "" : "Double tap to edit reps")
            .accessibilityAddTraits(isDisabled || onEditReps == nil ? [] : .isButton)

            // Weight if applicable (tappable for quick edit)
            if let load = exercise.targetLoad, load > 0 {
                Button {
                    if !isDisabled, let onEditWeight = onEditWeight {
                        HapticFeedback.light()
                        onEditWeight()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(formatWeight(actualWeight ?? load))
                            .font(.caption)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                        if !isDisabled && onEditWeight != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.modusCyan.opacity(0.6))
                        }
                    }
                }
                .disabled(isDisabled || onEditWeight == nil)
                .accessibilityLabel("\(formatWeight(actualWeight ?? load))")
                .accessibilityHint(isDisabled ? "" : "Double tap to edit weight")
                .accessibilityAddTraits(isDisabled || onEditWeight == nil ? [] : .isButton)
            }
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(exercise.loadUnit ?? "lbs")"
        } else {
            return String(format: "%.1f %@", weight, exercise.loadUnit ?? "lbs")
        }
    }

    private var borderColor: Color {
        if isCompleted {
            return .modusTealAccent.opacity(0.4)
        } else if isSkipped {
            return DesignTokens.statusWarning.opacity(0.4)
        } else if offset > completeThreshold * 0.8 {
            return .modusTealAccent.opacity(swipeProgress)
        } else if offset < modifyThreshold * 0.8 {
            return DesignTokens.statusWarning.opacity(swipeProgress)
        }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isCompleted || isSkipped {
            return 1.5
        } else if abs(offset) > 50 {
            return 2
        }
        return 0
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .local)
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

        isDragging = true
        let translation = value.translation.width

        // Apply different behavior based on direction
        if translation > 0 {
            // Right swipe (complete) - allow full travel
            if translation > completeThreshold {
                // Rubber-band effect past threshold
                let overshoot = translation - completeThreshold
                offset = completeThreshold + (overshoot * 0.3)

                // Trigger threshold haptic once
                if !hasTriggeredThresholdHaptic {
                    HapticFeedback.medium()
                    hasTriggeredThresholdHaptic = true
                }
            } else {
                offset = translation
                hasTriggeredThresholdHaptic = false
            }
            cardState = .swipingRight(progress: swipeProgress)

            // Update icon rotation based on progress
            iconRotation = swipeProgress * 360

            // Light haptic at 50% threshold
            if offset > completeThreshold * 0.5 && offset < completeThreshold * 0.55 {
                HapticFeedback.light()
            }
        } else {
            // Left swipe (modify) - more resistance
            if -translation > abs(modifyThreshold) {
                let overshoot = -translation - abs(modifyThreshold)
                offset = modifyThreshold - (overshoot * 0.2)

                // Trigger threshold haptic once
                if !hasTriggeredThresholdHaptic {
                    HapticFeedback.light()
                    hasTriggeredThresholdHaptic = true
                }
            } else {
                offset = translation
                hasTriggeredThresholdHaptic = false
            }
            cardState = .swipingLeft(progress: swipeProgress)
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        hasTriggeredThresholdHaptic = false

        if offset > completeThreshold {
            triggerCompletion()
        } else if offset < modifyThreshold {
            triggerModificationSheet()
        } else {
            // Snap back with light haptic
            HapticFeedback.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                offset = 0
                cardState = .idle
                iconRotation = 0
            }
        }
    }

    // MARK: - Actions

    private func triggerCompletion() {
        // Success haptic
        HapticFeedback.success()

        // Show checkmark overlay briefly
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCompletionCheckmark = true
            iconRotation = 360
        }

        // Then animate off and callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCompletionCheckmark = false
                offset = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 400
                completionOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()

                // Reset for next appearance
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    offset = 0
                    completionScale = 1.0
                    completionOpacity = 1.0
                    iconRotation = 0
                    cardState = .completed
                }
            }
        }
    }

    private func triggerModificationSheet() {
        // Medium haptic for showing options
        HapticFeedback.medium()

        // Snap back and show sheet
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            offset = 0
            cardState = .idle
        }

        showModificationSheet = true
    }

    private func handleModificationSelected(_ option: ExerciseModificationOption) {
        showModificationSheet = false

        // Selection haptic
        HapticFeedback.selectionChanged()

        if option == .skip {
            // Animate skip similar to complete but to the left
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                offset = -((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 400)
                completionOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onModify(option)

                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    offset = 0
                    completionOpacity = 1.0
                    cardState = .skipped
                }
            }
        } else {
            // Just notify for other modifications with haptic
            HapticFeedback.light()
            cardState = .modified
            onModify(option)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "Set \(setNumber) of \(totalSets), \(exercise.exerciseName)"
        if let reps = exercise.targetReps {
            label += ", \(reps) reps"
        }
        if let load = exercise.targetLoad, load > 0 {
            label += ", \(exercise.loadDisplay)"
        }
        if isCompleted {
            label += ", completed"
        } else if isSkipped {
            label += ", skipped"
        }
        return label
    }

    private var accessibilityHint: String {
        if isDisabled {
            return "This set has been \(isCompleted ? "completed" : "skipped")"
        }
        return "Swipe right to complete, swipe left for options"
    }
}

// MARK: - Modification Options Sheet

/// Bottom sheet presenting modification options when user swipes left
struct ModificationOptionsSheet: View {
    let exercise: ManualSessionExercise
    let onSelect: (ExerciseModificationOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise header
                VStack(spacing: 8) {
                    Text(exercise.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(exercise.setsRepsDisplay)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Options grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(ExerciseModificationOption.allCases) { option in
                        ModificationOptionButton(option: option) {
                            onSelect(option)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Modify Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Modification Option Button

struct ModificationOptionButton: View {
    let option: ExerciseModificationOption
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: option.icon)
                    .font(.title)
                    .foregroundColor(option.color)

                Text(option.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(option.color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(option.color.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.rawValue)
        .accessibilityHint("Double tap to apply this modification")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Swipeable Exercise Card") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Swipe right to complete, left for options")
                .font(.caption)
                .foregroundColor(.secondary)

            SwipeableExerciseCard(
                exercise: ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: nil,
                    exerciseName: "Barbell Bench Press",
                    blockName: "Push",
                    sequence: 1,
                    targetSets: 3,
                    targetReps: "8-10",
                    targetLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    notes: "Focus on chest contraction",
                    createdAt: Date()
                ),
                setNumber: 1,
                totalSets: 3,
                isCompleted: false,
                isSkipped: false,
                actualReps: 10,
                actualWeight: 135,
                onComplete: { print("Set 1 completed!") },
                onModify: { option in print("Modified: \(option.rawValue)") },
                onEditReps: { print("Edit reps") },
                onEditWeight: { print("Edit weight") }
            )

            SwipeableExerciseCard(
                exercise: ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: nil,
                    exerciseName: "Barbell Bench Press",
                    blockName: "Push",
                    sequence: 1,
                    targetSets: 3,
                    targetReps: "8-10",
                    targetLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    notes: nil,
                    createdAt: Date()
                ),
                setNumber: 2,
                totalSets: 3,
                isCompleted: true,
                isSkipped: false,
                onComplete: { },
                onModify: { _ in }
            )

            SwipeableExerciseCard(
                exercise: ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: nil,
                    exerciseName: "Barbell Bench Press",
                    blockName: "Push",
                    sequence: 1,
                    targetSets: 3,
                    targetReps: "8-10",
                    targetLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    notes: nil,
                    createdAt: Date()
                ),
                setNumber: 3,
                totalSets: 3,
                isCompleted: false,
                isSkipped: true,
                onComplete: { },
                onModify: { _ in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
