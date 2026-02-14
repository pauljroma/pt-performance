// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  SwipeableSetTrackingView.swift
//  PTPerformance
//
//  ACP-503: Swipe-to-Complete Exercise Integration
//  ACP-1013: Workout Execution Flow Refinement
//  Demonstrates set-by-set swipe tracking using SwipeableExerciseCard
//

import SwiftUI

// MARK: - Set Tracking State

/// Tracks the completion state of individual sets within an exercise
struct SetTrackingState: Identifiable {
    let id: UUID
    let setNumber: Int
    var isCompleted: Bool
    var isSkipped: Bool
    var actualReps: Int?
    var actualWeight: Double?
    var modificationApplied: ExerciseModificationOption?
    var restTimerStarted: Date?
    var isRestTimerActive: Bool = false

    init(setNumber: Int, targetReps: Int? = nil, targetWeight: Double? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.isCompleted = false
        self.isSkipped = false
        self.actualReps = targetReps
        self.actualWeight = targetWeight
        self.modificationApplied = nil
        self.restTimerStarted = nil
        self.isRestTimerActive = false
    }
}

// MARK: - Swipeable Set Tracking View

/// A view that provides swipe-based set tracking for an exercise
/// Each set is displayed as a SwipeableExerciseCard
struct SwipeableSetTrackingView: View {
    // MARK: - Properties

    let exercise: ManualSessionExercise
    let onExerciseComplete: ([SetTrackingState]) -> Void
    let onExerciseSkip: () -> Void

    // MARK: - State

    @State private var sets: [SetTrackingState] = []
    @State private var showCompletionCelebration = false
    @State private var completionFeedbackScale: CGFloat = 1.0
    @State private var editingSetId: UUID?
    @State private var editingField: EditField?
    @State private var editValue: String = ""
    @State private var showRestTimer = false
    @State private var restTimeRemaining: Int = 0
    @State private var restTimerTask: Task<Void, Never>?

    enum EditField {
        case reps
        case weight
    }

    // MARK: - Computed Properties

    private var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }

    private var skippedSetsCount: Int {
        sets.filter { $0.isSkipped }.count
    }

    private var remainingSetsCount: Int {
        sets.filter { !$0.isCompleted && !$0.isSkipped }.count
    }

    private var isExerciseComplete: Bool {
        remainingSetsCount == 0
    }

    private var progressPercentage: Double {
        guard !sets.isEmpty else { return 0 }
        return Double(completedSetsCount + skippedSetsCount) / Double(sets.count)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.lg) {
                // Exercise header
                exerciseHeader

                // Progress indicator
                progressIndicator

                // Rest timer (if active)
                if showRestTimer {
                    restTimerView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Instructions
                instructionsBanner

                // Set cards
                setCardsSection

                // Action buttons
                if isExerciseComplete {
                    completionActions
                }
            }
            .padding()
            .blur(radius: editingSetId != nil ? 3 : 0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: editingSetId != nil)

            // Quick edit overlay
            if editingSetId != nil {
                quickEditOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            initializeSets()
        }
        .onChange(of: isExerciseComplete) { _, complete in
            if complete {
                showCompletionCelebration = true
                HapticFeedback.success()
                stopRestTimer()

                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    completionFeedbackScale = 1.1
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) {
                    completionFeedbackScale = 1.0
                }
            }
        }
        .onDisappear {
            stopRestTimer()
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                // Target prescription
                Label("\(exercise.targetSets ?? 3) sets", systemImage: "number.square")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Label("\(exercise.targetReps ?? "10") reps", systemImage: "repeat")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let load = exercise.targetLoad, load > 0 {
                    Label(exercise.loadDisplay, systemImage: "scalemass")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: Spacing.xs) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    // Completed progress (teal accent)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.modusTealAccent)
                        .frame(width: geometry.size.width * (Double(completedSetsCount) / Double(max(sets.count, 1))))

                    // Skipped overlay (warning color, stacked after completed)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.statusWarning)
                        .frame(width: geometry.size.width * (Double(skippedSetsCount) / Double(max(sets.count, 1))))
                        .offset(x: geometry.size.width * (Double(completedSetsCount) / Double(max(sets.count, 1))))
                }
            }
            .frame(height: 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: completedSetsCount)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: skippedSetsCount)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress: \(Int(progressPercentage * 100)) percent complete")
            .accessibilityValue("\(completedSetsCount) completed, \(skippedSetsCount) skipped, \(remainingSetsCount) remaining")

            // Status text
            HStack {
                if completedSetsCount > 0 {
                    Label("\(completedSetsCount) completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.modusTealAccent)
                        .accessibilityLabel("\(completedSetsCount) sets completed")
                }

                if skippedSetsCount > 0 {
                    Label("\(skippedSetsCount) skipped", systemImage: "forward.circle.fill")
                        .font(.caption)
                        .foregroundColor(DesignTokens.statusWarning)
                        .accessibilityLabel("\(skippedSetsCount) sets skipped")
                }

                Spacer()

                if remainingSetsCount > 0 {
                    Text("\(remainingSetsCount) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("\(remainingSetsCount) sets remaining")
                }
            }
        }
        .scaleEffect(completionFeedbackScale)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: completionFeedbackScale)
    }

    // MARK: - Rest Timer View

    private var restTimerView: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.modusCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(formatRestTime(restTimeRemaining))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                        .monospacedDigit()
                }

                Spacer()

                Button {
                    HapticFeedback.light()
                    stopRestTimer()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Stop rest timer")
                .accessibilityHint("Double tap to stop the rest timer")
            }
            .padding(Spacing.md)
            .background(Color.modusCyan.opacity(0.1))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.modusCyan.opacity(0.3), lineWidth: 2)
            )

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * restProgress)
                        .animation(.linear(duration: 1.0), value: restProgress)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rest timer: \(formatRestTime(restTimeRemaining)) remaining")
    }

    private var restProgress: CGFloat {
        guard let restPeriod = exercise.restPeriodSeconds, restPeriod > 0 else { return 0 }
        return 1.0 - (CGFloat(restTimeRemaining) / CGFloat(restPeriod))
    }

    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Quick Edit Overlay

    private var quickEditOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissQuickEdit()
                }

            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    Text(editingField == .reps ? "Edit Reps" : "Edit Weight")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.modusPrimary)

                    if let set = sets.first(where: { $0.id == editingSetId }) {
                        Text("Set \(set.setNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                TextField(editingField == .reps ? "Reps" : "Weight", text: $editValue)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.modusLightTeal)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.modusCyan, lineWidth: 2)
                    )
                    .accessibilityLabel(editingField == .reps ? "Edit reps value" : "Edit weight value")
                    .accessibilityHint("Enter the new value")

                HStack(spacing: Spacing.md) {
                    Button {
                        HapticFeedback.light()
                        dismissQuickEdit()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Double tap to cancel editing")

                    Button {
                        saveQuickEdit()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.modusCyan)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel("Save")
                    .accessibilityHint("Double tap to save changes")
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.systemBackground))
                    .shadow(color: Shadow.prominent.color, radius: Shadow.prominent.radius, x: Shadow.prominent.x, y: Shadow.prominent.y)
            )
            .padding(Spacing.xl)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Instructions Banner

    private var instructionsBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "hand.draw")
                .font(.title2)
                .foregroundColor(.modusCyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Swipe to Track Sets")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Swipe right to complete • Tap values to edit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Instructions: Swipe right to complete sets, tap weight or reps values to edit them quickly")
    }

    // MARK: - Set Cards Section

    private var setCardsSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach($sets) { $set in
                SwipeableExerciseCard(
                    exercise: exercise,
                    setNumber: set.setNumber,
                    totalSets: sets.count,
                    isCompleted: set.isCompleted,
                    isSkipped: set.isSkipped,
                    actualReps: set.actualReps,
                    actualWeight: set.actualWeight,
                    onComplete: {
                        handleSetComplete(set.id)
                    },
                    onModify: { option in
                        handleSetModify(set.id, option: option)
                    },
                    onEditReps: {
                        startQuickEdit(setId: set.id, field: .reps, currentValue: set.actualReps)
                    },
                    onEditWeight: {
                        startQuickEdit(setId: set.id, field: .weight, currentValue: set.actualWeight)
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Completion Actions

    private var completionActions: some View {
        VStack(spacing: Spacing.md) {
            // Celebration message
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.modusTealAccent)
                Text("Exercise Complete!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusPrimary)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.modusTealAccent)
            }
            .padding(Spacing.md)
            .background(Color.modusTealAccent.opacity(0.15))
            .cornerRadius(CornerRadius.md)
            .accessibilityLabel("Exercise completed successfully")

            // Summary
            HStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xxs) {
                    Text("\(completedSetsCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.modusTealAccent)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(completedSetsCount) sets completed")

                if skippedSetsCount > 0 {
                    VStack(spacing: Spacing.xxs) {
                        Text("\(skippedSetsCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.statusWarning)
                        Text("Skipped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(skippedSetsCount) sets skipped")
                }
            }

            // Continue button
            Button {
                HapticFeedback.medium()
                onExerciseComplete(sets)
            } label: {
                Text("Continue to Next Exercise")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
            }
            .adaptiveShadow(Shadow.medium)
            .accessibilityLabel("Continue to next exercise")
            .accessibilityHint("Double tap to proceed to the next exercise")
            .accessibilityAddTraits(.isButton)
        }
        .transition(.scale.combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Helper Methods

    private func initializeSets() {
        let numSets = exercise.targetSets ?? 3
        let targetReps = Int(exercise.targetReps ?? "10") ?? 10
        let targetWeight = exercise.targetLoad ?? 0

        sets = (1...numSets).map { setNumber in
            SetTrackingState(
                setNumber: setNumber,
                targetReps: targetReps,
                targetWeight: targetWeight
            )
        }
    }

    private func handleSetComplete(_ setId: UUID) {
        guard let index = sets.firstIndex(where: { $0.id == setId }) else { return }

        HapticFeedback.success()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            sets[index].isCompleted = true
            sets[index].isSkipped = false
        }

        // Start rest timer if there are more sets and rest period is defined
        if !isExerciseComplete, let restPeriod = exercise.restPeriodSeconds, restPeriod > 0 {
            startRestTimer(duration: restPeriod)
        }
    }

    private func handleSetModify(_ setId: UUID, option: ExerciseModificationOption) {
        guard let index = sets.firstIndex(where: { $0.id == setId }) else { return }

        HapticFeedback.light()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            sets[index].modificationApplied = option

            switch option {
            case .skip:
                sets[index].isSkipped = true
                sets[index].isCompleted = false

            case .reduceReps:
                // Reduce reps by 2
                if let currentReps = sets[index].actualReps {
                    sets[index].actualReps = max(1, currentReps - 2)
                }
                // Still mark as completed with modified reps
                sets[index].isCompleted = true

            case .reduceSets:
                // Skip this set (effectively reducing total sets)
                sets[index].isSkipped = true

            case .reduceWeight:
                // Reduce weight by 10%
                if let currentWeight = sets[index].actualWeight {
                    sets[index].actualWeight = currentWeight * 0.9
                }
                // Still mark as completed with modified weight
                sets[index].isCompleted = true

            case .substituteExercise:
                // This would typically navigate to substitution flow
                // For now, skip the set
                sets[index].isSkipped = true
            }
        }
    }

    // MARK: - Quick Edit Methods

    private func startQuickEdit(setId: UUID, field: EditField, currentValue: Any?) {
        HapticFeedback.light()

        editingSetId = setId
        editingField = field

        if field == .reps, let reps = currentValue as? Int {
            editValue = String(reps)
        } else if field == .weight, let weight = currentValue as? Double {
            editValue = String(format: "%.1f", weight)
        } else {
            editValue = ""
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Overlay will appear
        }
    }

    private func saveQuickEdit() {
        guard let setId = editingSetId,
              let index = sets.firstIndex(where: { $0.id == setId }),
              let field = editingField else {
            dismissQuickEdit()
            return
        }

        HapticFeedback.success()

        if field == .reps, let reps = Int(editValue), reps > 0 {
            sets[index].actualReps = reps
        } else if field == .weight, let weight = Double(editValue), weight >= 0 {
            sets[index].actualWeight = weight
        }

        dismissQuickEdit()
    }

    private func dismissQuickEdit() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            editingSetId = nil
            editingField = nil
            editValue = ""
        }
    }

    // MARK: - Rest Timer Methods

    private func startRestTimer(duration: Int) {
        HapticFeedback.medium()

        restTimeRemaining = duration
        showRestTimer = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // Timer view will appear
        }

        // Cancel existing timer
        restTimerTask?.cancel()

        // Start countdown
        restTimerTask = Task {
            while restTimeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if !Task.isCancelled {
                    restTimeRemaining -= 1

                    // Haptic at halfway point
                    if restTimeRemaining == duration / 2 {
                        HapticFeedback.light()
                    }

                    // Haptic at 3, 2, 1
                    if restTimeRemaining <= 3 && restTimeRemaining > 0 {
                        HapticFeedback.light()
                    }

                    // Success haptic when complete
                    if restTimeRemaining == 0 {
                        HapticFeedback.success()
                        stopRestTimer()
                    }
                }
            }
        }
    }

    private func stopRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showRestTimer = false
            restTimeRemaining = 0
        }
    }
}

// MARK: - Preview

#Preview("Swipeable Set Tracking") {
    NavigationStack {
        SwipeableSetTrackingView(
            exercise: ManualSessionExercise(
                id: UUID(),
                manualSessionId: UUID(),
                exerciseTemplateId: nil,
                exerciseName: "Barbell Back Squat",
                blockName: "Strength",
                sequence: 1,
                targetSets: 4,
                targetReps: "8",
                targetLoad: 185,
                loadUnit: "lbs",
                restPeriodSeconds: 120,
                notes: "Focus on depth and bracing",
                createdAt: Date()
            ),
            onExerciseComplete: { sets in
                print("Exercise completed with \(sets.count) sets")
            },
            onExerciseSkip: {
                print("Exercise skipped")
            }
        )
        .navigationTitle("Workout")
    }
}
