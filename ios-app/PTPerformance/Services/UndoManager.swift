//
//  UndoManager.swift
//  PTPerformance
//
//  ACP-515: Eliminate Confirmation Dialogs
//  Service that tracks recent actions that can be undone.
//  Stores action type, data needed to reverse, and timestamp.
//  Auto-expires undo options after 5 seconds.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Undoable Action Protocol

/// Protocol for actions that can be undone
/// Conforming types define how to reverse an action and display it to users
protocol UndoableAction: Identifiable {
    /// Unique identifier for this action
    var id: UUID { get }

    /// Human-readable description of what was done (e.g., "Set deleted")
    var actionDescription: String { get }

    /// Timestamp when the action occurred
    var timestamp: Date { get }

    /// Execute the undo operation
    func undo() async throws
}

// MARK: - Action Type Enum

/// Common action types for categorization and theming
enum UndoActionType {
    case deleteExercise
    case skipSet
    case skipExercise
    case endWorkout
    case deleteProgram
    case deletePhase
    case deleteSession
    case deleteTimer
    case deleteMeal
    case generic

    /// SF Symbol for this action type
    var iconName: String {
        switch self {
        case .deleteExercise, .deleteProgram, .deletePhase, .deleteSession, .deleteTimer, .deleteMeal:
            return "trash"
        case .skipSet, .skipExercise:
            return "forward.fill"
        case .endWorkout:
            return "stop.circle"
        case .generic:
            return "arrow.uturn.backward"
        }
    }
}

// MARK: - Concrete Undoable Actions

/// Undoable action for deleting an exercise
struct DeleteExerciseAction: UndoableAction {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "\(exerciseName) deleted"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for skipping a set
struct SkipSetAction: UndoableAction {
    let id: UUID
    let exerciseId: UUID
    let setNumber: Int
    let exerciseName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "Set \(setNumber) skipped"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for skipping an exercise
struct SkipExerciseAction: UndoableAction {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "\(exerciseName) skipped"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for ending a workout early
struct EndWorkoutAction: UndoableAction {
    let id: UUID
    let workoutName: String
    let completedExercises: Int
    let totalExercises: Int
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "Workout ended early"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for deleting a program
struct DeleteProgramAction: UndoableAction {
    let id: UUID
    let programId: String
    let programName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "\(programName) deleted"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for deleting a phase
struct DeletePhaseAction: UndoableAction {
    let id: UUID
    let phaseIndex: Int
    let phaseName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "\(phaseName) deleted"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Undoable action for deleting a timer session
struct DeleteTimerAction: UndoableAction {
    let id: UUID
    let sessionId: UUID
    let timerName: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    var actionDescription: String {
        "Timer deleted"
    }

    func undo() async throws {
        try await restoreHandler()
    }
}

/// Generic undoable action for custom use cases
struct GenericUndoAction: UndoableAction {
    let id: UUID
    let actionDescription: String
    let timestamp: Date
    let restoreHandler: () async throws -> Void

    func undo() async throws {
        try await restoreHandler()
    }
}

// MARK: - Undo Manager

/// Singleton service that manages undoable actions with auto-expiration
@MainActor
final class PTUndoManager: ObservableObject {

    // MARK: - Singleton

    static let shared = PTUndoManager()

    // MARK: - Configuration

    /// Time in seconds before an undo option expires
    private let undoExpirationSeconds: TimeInterval = 5.0

    /// Maximum number of actions to keep in the stack
    private let maxStackSize: Int = 5

    // MARK: - Published State

    /// Stack of undoable actions (most recent first)
    @Published private(set) var undoStack: [any UndoableAction] = []

    /// Whether an undo is currently in progress
    @Published private(set) var isUndoing: Bool = false

    /// Error message if undo fails
    @Published var undoError: String?

    // MARK: - Private Properties

    /// Timers for auto-expiration of each action
    private var expirationTimers: [UUID: Task<Void, Never>] = [:]

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        DebugLogger.shared.info("UNDO_MANAGER", "PTUndoManager initialized")
    }

    // MARK: - Public Methods

    /// Register a new undoable action
    /// - Parameter action: The action to register
    func registerAction(_ action: any UndoableAction) {
        // Add to stack
        undoStack.insert(action, at: 0)

        // Trim stack if needed
        if undoStack.count > maxStackSize {
            let removedActions = undoStack.suffix(from: maxStackSize)
            for removed in removedActions {
                cancelExpiration(for: removed.id)
            }
            undoStack = Array(undoStack.prefix(maxStackSize))
        }

        // Schedule auto-expiration
        scheduleExpiration(for: action.id)

        // Haptic feedback
        HapticService.medium()

        DebugLogger.shared.info("UNDO_MANAGER", "Registered action: \(action.actionDescription)")
    }

    /// Register a delete exercise action
    func registerDeleteExercise(
        exerciseId: UUID,
        exerciseName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = DeleteExerciseAction(
            id: UUID(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a skip set action
    func registerSkipSet(
        exerciseId: UUID,
        setNumber: Int,
        exerciseName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = SkipSetAction(
            id: UUID(),
            exerciseId: exerciseId,
            setNumber: setNumber,
            exerciseName: exerciseName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a skip exercise action
    func registerSkipExercise(
        exerciseId: UUID,
        exerciseName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = SkipExerciseAction(
            id: UUID(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register an end workout early action
    func registerEndWorkout(
        workoutName: String,
        completedExercises: Int,
        totalExercises: Int,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = EndWorkoutAction(
            id: UUID(),
            workoutName: workoutName,
            completedExercises: completedExercises,
            totalExercises: totalExercises,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a delete program action
    func registerDeleteProgram(
        programId: String,
        programName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = DeleteProgramAction(
            id: UUID(),
            programId: programId,
            programName: programName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a delete phase action
    func registerDeletePhase(
        phaseIndex: Int,
        phaseName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = DeletePhaseAction(
            id: UUID(),
            phaseIndex: phaseIndex,
            phaseName: phaseName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a delete timer action
    func registerDeleteTimer(
        sessionId: UUID,
        timerName: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = DeleteTimerAction(
            id: UUID(),
            sessionId: sessionId,
            timerName: timerName,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Register a generic undoable action
    func registerGenericAction(
        description: String,
        restoreHandler: @escaping () async throws -> Void
    ) {
        let action = GenericUndoAction(
            id: UUID(),
            actionDescription: description,
            timestamp: Date(),
            restoreHandler: restoreHandler
        )
        registerAction(action)
    }

    /// Undo the most recent action
    func undoLast() async {
        guard let action = undoStack.first else { return }
        await undo(action)
    }

    /// Undo a specific action by ID
    func undo(_ action: any UndoableAction) async {
        guard !isUndoing else { return }

        isUndoing = true
        undoError = nil

        // Cancel expiration timer
        cancelExpiration(for: action.id)

        do {
            try await action.undo()

            // Remove from stack
            undoStack.removeAll { $0.id == action.id }

            // Success haptic
            HapticService.success()

            DebugLogger.shared.success("UNDO_MANAGER", "Successfully undid: \(action.actionDescription)")

        } catch {
            undoError = "Failed to undo: \(error.localizedDescription)"
            HapticService.error()
            DebugLogger.shared.error("UNDO_MANAGER", "Failed to undo action: \(error.localizedDescription)")
        }

        isUndoing = false
    }

    /// Dismiss a specific action without undoing
    func dismiss(_ action: any UndoableAction) {
        cancelExpiration(for: action.id)
        undoStack.removeAll { $0.id == action.id }
        DebugLogger.shared.info("UNDO_MANAGER", "Dismissed action: \(action.actionDescription)")
    }

    /// Dismiss all pending undo actions
    func dismissAll() {
        for action in undoStack {
            cancelExpiration(for: action.id)
        }
        undoStack.removeAll()
        DebugLogger.shared.info("UNDO_MANAGER", "Dismissed all undo actions")
    }

    /// Check if there are any actions that can be undone
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// Get the most recent action
    var mostRecentAction: (any UndoableAction)? {
        undoStack.first
    }

    // MARK: - Private Methods

    /// Schedule auto-expiration for an action
    private func scheduleExpiration(for actionId: UUID) {
        // Cancel any existing timer
        cancelExpiration(for: actionId)

        // Create new expiration task
        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.undoExpirationSeconds ?? 5.0) * 1_000_000_000)

            guard !Task.isCancelled else { return }

            self?.expireAction(actionId)
        }

        expirationTimers[actionId] = task
    }

    /// Cancel expiration timer for an action
    private func cancelExpiration(for actionId: UUID) {
        expirationTimers[actionId]?.cancel()
        expirationTimers.removeValue(forKey: actionId)
    }

    /// Expire an action (remove from stack)
    private func expireAction(_ actionId: UUID) {
        undoStack.removeAll { $0.id == actionId }
        expirationTimers.removeValue(forKey: actionId)
        DebugLogger.shared.info("UNDO_MANAGER", "Action expired: \(actionId)")
    }
}

// MARK: - Environment Key

private struct UndoManagerKey: EnvironmentKey {
    // MainActor computed property to safely access shared instance
    @MainActor static var defaultValue: PTUndoManager {
        PTUndoManager.shared
    }
}

extension EnvironmentValues {
    var undoManager: PTUndoManager {
        get { self[UndoManagerKey.self] }
        set { self[UndoManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Add undo manager to the environment
    func withUndoManager() -> some View {
        self.environmentObject(PTUndoManager.shared)
    }
}
