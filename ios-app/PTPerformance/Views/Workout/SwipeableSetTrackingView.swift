// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  SwipeableSetTrackingView.swift
//  PTPerformance
//
//  ACP-503: Swipe-to-Complete Exercise Integration
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

    init(setNumber: Int, targetReps: Int? = nil, targetWeight: Double? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.isCompleted = false
        self.isSkipped = false
        self.actualReps = targetReps
        self.actualWeight = targetWeight
        self.modificationApplied = nil
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
        VStack(spacing: 20) {
            // Exercise header
            exerciseHeader

            // Progress indicator
            progressIndicator

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
        .onAppear {
            initializeSets()
        }
        .onChange(of: isExerciseComplete) { _, complete in
            if complete {
                showCompletionCelebration = true
                HapticFeedback.success()

                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    completionFeedbackScale = 1.1
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) {
                    completionFeedbackScale = 1.0
                }
            }
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
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    // Completed progress (green)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGreen))
                        .frame(width: geometry.size.width * (Double(completedSetsCount) / Double(max(sets.count, 1))))

                    // Skipped overlay (orange, stacked after completed)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemOrange))
                        .frame(width: geometry.size.width * (Double(skippedSetsCount) / Double(max(sets.count, 1))))
                        .offset(x: geometry.size.width * (Double(completedSetsCount) / Double(max(sets.count, 1))))
                }
            }
            .frame(height: 10)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: completedSetsCount)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: skippedSetsCount)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress: \(Int(progressPercentage * 100)) percent complete")
            .accessibilityValue("\(completedSetsCount) completed, \(skippedSetsCount) skipped, \(remainingSetsCount) remaining")

            // Status text
            HStack {
                if completedSetsCount > 0 {
                    Label("\(completedSetsCount) completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(.systemGreen))
                }

                if skippedSetsCount > 0 {
                    Label("\(skippedSetsCount) skipped", systemImage: "forward.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(.systemOrange))
                }

                Spacer()

                if remainingSetsCount > 0 {
                    Text("\(remainingSetsCount) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .scaleEffect(completionFeedbackScale)
    }

    // MARK: - Instructions Banner

    private var instructionsBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.draw")
                .font(.title2)
                .foregroundColor(Color(.systemBlue))

            VStack(alignment: .leading, spacing: 2) {
                Text("Swipe to Track Sets")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Swipe right to complete, left for options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.15))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Instructions: Swipe right to complete, left for options")
    }

    // MARK: - Set Cards Section

    private var setCardsSection: some View {
        VStack(spacing: 12) {
            ForEach($sets) { $set in
                SwipeableExerciseCard(
                    exercise: exercise,
                    setNumber: set.setNumber,
                    totalSets: sets.count,
                    isCompleted: set.isCompleted,
                    isSkipped: set.isSkipped,
                    onComplete: {
                        handleSetComplete(set.id)
                    },
                    onModify: { option in
                        handleSetModify(set.id, option: option)
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
        VStack(spacing: 12) {
            // Celebration message
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(.systemYellow))
                Text("Exercise Complete!")
                    .font(.headline)
                    .fontWeight(.bold)
                Image(systemName: "star.fill")
                    .foregroundColor(Color(.systemYellow))
            }
            .padding()
            .background(Color(.systemGreen).opacity(0.15))
            .cornerRadius(CornerRadius.md)

            // Summary
            HStack(spacing: 20) {
                VStack {
                    Text("\(completedSetsCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.systemGreen))
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if skippedSetsCount > 0 {
                    VStack {
                        Text("\(skippedSetsCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemOrange))
                        Text("Skipped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Continue button
            Button {
                onExerciseComplete(sets)
            } label: {
                Text("Continue to Next Exercise")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Continue to next exercise")
            .accessibilityHint("Double tap to proceed to the next exercise")
        }
        .transition(.scale.combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Exercise complete summary")
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

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            sets[index].isCompleted = true
            sets[index].isSkipped = false
        }
    }

    private func handleSetModify(_ setId: UUID, option: ExerciseModificationOption) {
        guard let index = sets.firstIndex(where: { $0.id == setId }) else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
