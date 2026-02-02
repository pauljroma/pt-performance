//
//  UndoIntegration.swift
//  PTPerformance
//
//  ACP-515: Eliminate Confirmation Dialogs - Integration Helpers
//  Provides view modifiers and extensions for integrating the undo pattern
//  with existing workout, program, and timer management views.
//

import SwiftUI

// MARK: - Undoable Skip Exercise View Modifier

/// Wrapper that provides undo capability for skip exercise actions
struct UndoableSkipExerciseModifier: ViewModifier {
    let exercise: ManualSessionExercise
    let viewModel: ManualWorkoutExecutionViewModel
    @ObservedObject var undoManager: PTUndoManager

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .exerciseSkipped)) { notification in
                guard let exerciseId = notification.userInfo?["exerciseId"] as? UUID,
                      exerciseId == exercise.id else { return }

                // Register undo action
                undoManager.registerSkipExercise(
                    exerciseId: exercise.id,
                    exerciseName: exercise.exerciseName
                ) { [weak viewModel] in
                    viewModel?.unskipExercise(exercise)
                }
            }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exerciseSkipped = Notification.Name("PTPerformance.exerciseSkipped")
    static let exerciseDeleted = Notification.Name("PTPerformance.exerciseDeleted")
    static let workoutEndedEarly = Notification.Name("PTPerformance.workoutEndedEarly")
    static let programDeleted = Notification.Name("PTPerformance.programDeleted")
    static let phaseDeleted = Notification.Name("PTPerformance.phaseDeleted")
}

// MARK: - View Model Extensions for Undo Support

extension ManualWorkoutExecutionViewModel {

    /// Skip exercise with undo support
    /// - Parameter exercise: The exercise to skip
    func skipExerciseWithUndo(_ exercise: ManualSessionExercise) {
        // Store state before skip for undo
        let wasSkipped = skippedExerciseIds.contains(exercise.id)

        // Perform the skip
        skipExercise(exercise)

        // Only register undo if it wasn't already skipped
        guard !wasSkipped else { return }

        // Register undo action
        PTUndoManager.shared.registerSkipExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.exerciseName
        ) { [weak self] in
            self?.unskipExercise(exercise)
        }
    }

    /// Skip current exercise with undo support
    func skipCurrentExerciseWithUndo() {
        guard let exercise = currentExercise else { return }
        skipExerciseWithUndo(exercise)
    }

    /// Unskip an exercise (restore it to active state)
    func unskipExercise(_ exercise: ManualSessionExercise) {
        skippedExerciseIds.remove(exercise.id)
        DebugLogger.shared.info("UNDO", "Exercise '\(exercise.exerciseName)' restored from skip")

        // Haptic feedback
        HapticService.success()
    }

    /// End workout early with undo support
    /// Returns the completion handler that should be called after the view completes
    func endWorkoutEarlyWithUndo() async -> (() -> Void)? {
        // Store state before ending for potential undo
        let completedCount = self.completedCount
        let totalCount = self.totalExercises
        let workoutName = self.workoutName

        // Create a snapshot of current state for undo
        let skippedSnapshot = skippedExerciseIds
        let completedSnapshot = completedExerciseIds
        let wasCompleted = isWorkoutCompleted

        // Complete the workout
        await completeWorkout()

        // Register undo action (only effective within 5 seconds)
        PTUndoManager.shared.registerEndWorkout(
            workoutName: workoutName,
            completedExercises: completedCount,
            totalExercises: totalCount
        ) { [weak self] in
            // Restore workout state
            self?.skippedExerciseIds = skippedSnapshot
            self?.completedExerciseIds = completedSnapshot
            self?.isWorkoutCompleted = wasCompleted
            DebugLogger.shared.info("UNDO", "Workout '\(workoutName)' end action undone")
        }

        return nil
    }
}

// MARK: - Program Editor Undo Extensions

/// Extension for program deletion with undo
struct UndoableProgramDeletion {

    /// Delete a program with undo support
    /// - Parameters:
    ///   - programId: The ID of the program to delete
    ///   - programName: The name of the program (for display)
    ///   - deleteAction: The async action that performs the deletion
    ///   - restoreAction: The async action that restores the program
    static func delete(
        programId: String,
        programName: String,
        deleteAction: @escaping () async throws -> Void,
        restoreAction: @escaping () async throws -> Void
    ) async throws {
        // Perform deletion immediately
        try await deleteAction()

        // Register undo
        await MainActor.run {
            PTUndoManager.shared.registerDeleteProgram(
                programId: programId,
                programName: programName,
                restoreHandler: restoreAction
            )
        }
    }
}

/// Extension for phase deletion with undo
struct UndoablePhaseDeletion {

    /// Delete a phase with undo support
    @MainActor
    static func delete(
        phaseIndex: Int,
        phaseName: String,
        deleteAction: @escaping () -> Void,
        restoreAction: @escaping () async throws -> Void
    ) {
        // Perform deletion immediately
        deleteAction()

        // Register undo
        PTUndoManager.shared.registerDeletePhase(
            phaseIndex: phaseIndex,
            phaseName: phaseName,
            restoreHandler: restoreAction
        )
    }
}

// MARK: - Timer Deletion with Undo

struct UndoableTimerDeletion {

    /// Delete a timer session with undo support
    static func delete(
        sessionId: UUID,
        timerName: String,
        deleteAction: @escaping () async throws -> Void,
        restoreAction: @escaping () async throws -> Void
    ) async throws {
        // Perform deletion immediately
        try await deleteAction()

        // Register undo
        await MainActor.run {
            PTUndoManager.shared.registerDeleteTimer(
                sessionId: sessionId,
                timerName: timerName,
                restoreHandler: restoreAction
            )
        }
    }
}

// MARK: - View Modifier for Undo Toast Overlay

/// Convenience view modifier to add undo toast support to any view
struct UndoSupportModifier: ViewModifier {
    @StateObject private var undoManager = PTUndoManager.shared

    func body(content: Content) -> some View {
        content
            .withUndoToasts(undoManager: undoManager)
    }
}

extension View {
    /// Add undo support with toast notifications
    func withUndoSupport() -> some View {
        modifier(UndoSupportModifier())
    }
}

// MARK: - Immediate Action Button

/// A button that performs an action immediately and shows an undo toast
/// instead of showing a confirmation dialog first
struct ImmediateActionButton<Label: View>: View {
    let action: () async throws -> Void
    let undoDescription: String
    let undoAction: () async throws -> Void
    let label: () -> Label

    @State private var isPerforming = false

    init(
        action: @escaping () async throws -> Void,
        undoDescription: String,
        undoAction: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.undoDescription = undoDescription
        self.undoAction = undoAction
        self.label = label
    }

    var body: some View {
        Button {
            guard !isPerforming else { return }
            isPerforming = true

            Task {
                do {
                    try await action()

                    await MainActor.run {
                        PTUndoManager.shared.registerGenericAction(
                            description: undoDescription,
                            restoreHandler: undoAction
                        )
                    }
                } catch {
                    DebugLogger.shared.error("UNDO", "Action failed: \(error.localizedDescription)")
                    HapticService.error()
                }

                isPerforming = false
            }
        } label: {
            label()
        }
        .disabled(isPerforming)
    }
}

// MARK: - Skip Exercise Button (Replacement)

/// A skip exercise button that uses the undo pattern instead of confirmation
struct SkipExerciseButton: View {
    let exercise: ManualSessionExercise
    let onSkip: () -> Void
    let onRestore: () -> Void

    var body: some View {
        Button {
            // Skip immediately
            onSkip()

            // Register undo
            PTUndoManager.shared.registerSkipExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.exerciseName
            ) {
                onRestore()
            }
        } label: {
            HStack {
                Image(systemName: "forward.fill")
                Text("Skip")
            }
            .font(.subheadline)
            .foregroundColor(.orange)
        }
    }
}

// MARK: - End Workout Button (Replacement)

/// An end workout button that ends immediately and provides undo
struct EndWorkoutEarlyButton: View {
    let workoutName: String
    let completedCount: Int
    let totalCount: Int
    let onEnd: () async -> Void
    let onRestore: () async throws -> Void

    @State private var isEnding = false

    var body: some View {
        Button {
            guard !isEnding else { return }
            isEnding = true

            Task {
                await onEnd()

                await MainActor.run {
                    PTUndoManager.shared.registerEndWorkout(
                        workoutName: workoutName,
                        completedExercises: completedCount,
                        totalExercises: totalCount,
                        restoreHandler: onRestore
                    )
                }

                isEnding = false
            }
        } label: {
            if isEnding {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("End")
                    .foregroundColor(.red)
            }
        }
        .disabled(isEnding)
    }
}

// MARK: - Delete Button (Generic)

/// A generic delete button that deletes immediately and provides undo
struct ImmediateDeleteButton<Label: View>: View {
    let itemName: String
    let onDelete: () async throws -> Void
    let onRestore: () async throws -> Void
    let label: () -> Label

    @State private var isDeleting = false

    init(
        itemName: String,
        onDelete: @escaping () async throws -> Void,
        onRestore: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.itemName = itemName
        self.onDelete = onDelete
        self.onRestore = onRestore
        self.label = label
    }

    var body: some View {
        Button(role: .destructive) {
            guard !isDeleting else { return }
            isDeleting = true

            Task {
                do {
                    try await onDelete()

                    await MainActor.run {
                        PTUndoManager.shared.registerGenericAction(
                            description: "\(itemName) deleted"
                        ) {
                            try await onRestore()
                        }
                    }
                } catch {
                    DebugLogger.shared.error("UNDO", "Delete failed: \(error.localizedDescription)")
                    HapticService.error()
                }

                isDeleting = false
            }
        } label: {
            if isDeleting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                label()
            }
        }
        .disabled(isDeleting)
    }
}
