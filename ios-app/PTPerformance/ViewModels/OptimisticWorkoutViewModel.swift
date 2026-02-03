//
//  OptimisticWorkoutViewModel.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  ViewModel with optimistic updates for instant workout execution response
//

import Foundation
import SwiftUI
import Combine

// MARK: - Optimistic Workout State

/// Represents the optimistic UI state for a workout session
/// Changes are reflected immediately without waiting for server
class OptimisticWorkoutState: ObservableObject {
    // MARK: - Published State (Immediate Updates)

    /// Current exercise states by ID
    @Published var exerciseStates: [UUID: ExerciseUIState] = [:]

    /// Total completed exercises count
    @Published var completedCount: Int = 0

    /// Total skipped exercises count
    @Published var skippedCount: Int = 0

    /// Whether workout is completed
    @Published var isWorkoutCompleted: Bool = false

    /// Current elapsed time
    @Published var elapsedTime: TimeInterval = 0

    /// Background sync status
    @Published var syncStatus: SyncStatus = .synced

    enum SyncStatus {
        case synced
        case pending(count: Int)
        case syncing
        case error(String)
    }

    // MARK: - Computed Properties

    var hasPendingSync: Bool {
        if case .pending = syncStatus { return true }
        return false
    }

    var hasError: Bool {
        if case .error = syncStatus { return true }
        return false
    }
}

/// UI state for a single exercise
class ExerciseUIState: ObservableObject, Identifiable {
    let id: UUID
    let exerciseId: UUID

    @Published var completedSets: Int = 0
    @Published var totalSets: Int = 3
    @Published var repsPerSet: [Int] = []
    @Published var weightPerSet: [Double] = []
    @Published var loadUnit: String = "lbs"
    @Published var rpe: Int = 5
    @Published var painScore: Int = 0
    @Published var notes: String = ""
    @Published var isCompleted: Bool = false
    @Published var isSkipped: Bool = false
    @Published var isPendingSync: Bool = false

    init(exerciseId: UUID, totalSets: Int = 3, targetReps: Int = 10, targetLoad: Double = 0) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.totalSets = totalSets
        self.repsPerSet = Array(repeating: targetReps, count: totalSets)
        self.weightPerSet = Array(repeating: targetLoad, count: totalSets)
    }

    /// Snapshot for rollback
    func snapshot() -> ExerciseUIStateSnapshot {
        ExerciseUIStateSnapshot(
            completedSets: completedSets,
            repsPerSet: repsPerSet,
            weightPerSet: weightPerSet,
            rpe: rpe,
            painScore: painScore,
            notes: notes,
            isCompleted: isCompleted,
            isSkipped: isSkipped
        )
    }

    func restore(from snapshot: ExerciseUIStateSnapshot) {
        completedSets = snapshot.completedSets
        repsPerSet = snapshot.repsPerSet
        weightPerSet = snapshot.weightPerSet
        rpe = snapshot.rpe
        painScore = snapshot.painScore
        notes = snapshot.notes
        isCompleted = snapshot.isCompleted
        isSkipped = snapshot.isSkipped
        isPendingSync = false
    }
}

struct ExerciseUIStateSnapshot {
    let completedSets: Int
    let repsPerSet: [Int]
    let weightPerSet: [Double]
    let rpe: Int
    let painScore: Int
    let notes: String
    let isCompleted: Bool
    let isSkipped: Bool
}

// MARK: - OptimisticWorkoutViewModel

/// ViewModel that provides sub-100ms response for all workout interactions
///
/// ACP-516 Implementation:
/// - Immediately updates UI state on user action (< 10ms)
/// - Queues server sync in background
/// - Handles rollback on sync failure
/// - Provides reactive Combine publishers for UI binding
@MainActor
class OptimisticWorkoutViewModel: ObservableObject {

    // MARK: - Published State

    @Published var workoutState = OptimisticWorkoutState()
    @Published var currentExerciseIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Workout Info

    let sessionId: UUID
    let patientId: UUID
    private(set) var exercises: [Exercise] = []
    private var startTime: Date?
    private var snapshots: [UUID: ExerciseUIStateSnapshot] = [:]

    // MARK: - Services

    private let optimisticManager = OptimisticUpdateManager.shared
    private let pendingQueue = PendingChangesQueue.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentExercise: Exercise? {
        guard currentExerciseIndex >= 0 && currentExerciseIndex < exercises.count else {
            return nil
        }
        return exercises[currentExerciseIndex]
    }

    var currentExerciseState: ExerciseUIState? {
        guard let exercise = currentExercise else { return nil }
        return workoutState.exerciseStates[exercise.id]
    }

    var progressPercentage: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(workoutState.completedCount + workoutState.skippedCount) / Double(exercises.count)
    }

    var canComplete: Bool {
        workoutState.completedCount > 0
    }

    var allExercisesCompleted: Bool {
        workoutState.completedCount + workoutState.skippedCount >= exercises.count
    }

    var totalVolume: Double {
        var volume: Double = 0
        for (_, state) in workoutState.exerciseStates where state.isCompleted {
            let repsSum = state.repsPerSet.reduce(0, +)
            let avgWeight = state.weightPerSet.reduce(0, +) / max(Double(state.weightPerSet.count), 1)
            volume += Double(repsSum) * avgWeight
        }
        return volume
    }

    var averageRPE: Double? {
        let completedStates = workoutState.exerciseStates.values.filter { $0.isCompleted }
        guard !completedStates.isEmpty else { return nil }
        return Double(completedStates.map { $0.rpe }.reduce(0, +)) / Double(completedStates.count)
    }

    var averagePain: Double? {
        let completedStates = workoutState.exerciseStates.values.filter { $0.isCompleted }
        guard !completedStates.isEmpty else { return nil }
        return Double(completedStates.map { $0.painScore }.reduce(0, +)) / Double(completedStates.count)
    }

    // MARK: - Initialization

    init(sessionId: UUID, patientId: UUID, exercises: [Exercise]) {
        self.sessionId = sessionId
        self.patientId = patientId
        self.exercises = exercises

        initializeExerciseStates()
        setupSyncObservers()
    }

    private func initializeExerciseStates() {
        for exercise in exercises {
            let targetReps = parseTargetReps(exercise.prescribed_reps)
            let state = ExerciseUIState(
                exerciseId: exercise.id,
                totalSets: exercise.prescribed_sets,
                targetReps: targetReps,
                targetLoad: exercise.prescribed_load ?? 0
            )
            state.loadUnit = exercise.load_unit ?? "lbs"
            workoutState.exerciseStates[exercise.id] = state
        }
    }

    private func setupSyncObservers() {
        // Observe pending queue status
        pendingQueue.$changes
            .map { changes -> OptimisticWorkoutState.SyncStatus in
                let pending = changes.filter { $0.status == .pending || $0.status == .failed }
                if pending.isEmpty {
                    return .synced
                }
                return .pending(count: pending.count)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] syncStatus in
                self?.workoutState.syncStatus = syncStatus
            }
            .store(in: &cancellables)

        pendingQueue.syncCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if result.failed > 0 {
                    self?.workoutState.syncStatus = .error("Failed to sync \(result.failed) change(s)")
                } else {
                    self?.workoutState.syncStatus = .synced
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Workout Lifecycle

    func startWorkout() {
        let token = ResponseTimeMonitor.shared.startInteraction(.timerStart)
        startTime = Date()
        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Set Completion (Sub-100ms Response)

    /// Complete a set with immediate UI update
    /// Returns in < 10ms, sync happens in background
    func completeSet(setNumber: Int) {
        let token = ResponseTimeMonitor.shared.startInteraction(.setCompletion)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // 1. Capture snapshot for potential rollback
        snapshots[exercise.id] = state.snapshot()

        // 2. Immediate UI update (< 1ms)
        state.completedSets = max(state.completedSets, setNumber)
        state.isPendingSync = true

        // 3. Haptic feedback (immediate)
        HapticFeedback.light()

        // 4. Queue background sync (non-blocking)
        let reps = setNumber <= state.repsPerSet.count ? state.repsPerSet[setNumber - 1] : 10
        let weight = setNumber <= state.weightPerSet.count ? state.weightPerSet[setNumber - 1] : nil

        optimisticManager.completeSet(
            sessionExerciseId: exercise.id,
            patientId: patientId,
            setNumber: setNumber,
            reps: reps,
            weight: weight,
            loadUnit: state.loadUnit
        )

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Exercise Completion (Sub-100ms Response)

    /// Complete the current exercise with immediate UI update
    func completeCurrentExercise() {
        let token = ResponseTimeMonitor.shared.startInteraction(.exerciseCompletion)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // 1. Capture snapshot
        snapshots[exercise.id] = state.snapshot()

        // 2. Immediate UI update
        state.isCompleted = true
        state.isPendingSync = true
        workoutState.completedCount += 1

        // 3. Haptic feedback
        HapticFeedback.success()

        // 4. Queue background sync
        pendingQueue.enqueueExerciseCompletion(
            sessionExerciseId: exercise.id,
            patientId: patientId,
            actualSets: state.completedSets > 0 ? state.completedSets : state.totalSets,
            actualReps: Array(state.repsPerSet.prefix(state.totalSets)),
            actualLoad: state.weightPerSet.first,
            loadUnit: state.loadUnit,
            rpe: state.rpe,
            painScore: state.painScore,
            notes: state.notes.isEmpty ? nil : state.notes
        )

        // 5. Move to next exercise
        moveToNextExercise()

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    /// Quick-complete with prescribed values
    func quickCompleteExercise(_ exerciseId: UUID) {
        let token = ResponseTimeMonitor.shared.startInteraction(.exerciseCompletion)

        guard let state = workoutState.exerciseStates[exerciseId],
              let exercise = exercises.first(where: { $0.id == exerciseId }) else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // 1. Capture snapshot
        snapshots[exerciseId] = state.snapshot()

        // 2. Immediate UI update
        state.completedSets = state.totalSets
        state.isCompleted = true
        state.isPendingSync = true
        workoutState.completedCount += 1

        // 3. Haptic feedback
        HapticFeedback.success()

        // 4. Queue background sync with prescribed values
        pendingQueue.enqueueExerciseCompletion(
            sessionExerciseId: exercise.id,
            patientId: patientId,
            actualSets: state.totalSets,
            actualReps: state.repsPerSet,
            actualLoad: state.weightPerSet.first,
            loadUnit: state.loadUnit,
            rpe: 5,  // Default for quick complete
            painScore: 0,
            notes: nil
        )

        // 5. Move to next if this was current
        if currentExercise?.id == exerciseId {
            moveToNextExercise()
        }

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Weight Change (Sub-100ms Response)

    /// Update weight for a set with immediate UI update
    func updateWeight(_ newWeight: Double, forSet setNumber: Int? = nil) {
        let token = ResponseTimeMonitor.shared.startInteraction(.weightChange)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // 1. Capture snapshot
        snapshots[exercise.id] = state.snapshot()

        // 2. Immediate UI update
        if let setNum = setNumber, setNum > 0 && setNum <= state.weightPerSet.count {
            state.weightPerSet[setNum - 1] = newWeight
        } else {
            // Update all sets
            state.weightPerSet = state.weightPerSet.map { _ in newWeight }
        }
        state.isPendingSync = true

        // 3. Queue background sync
        optimisticManager.updateWeight(
            sessionExerciseId: exercise.id,
            patientId: patientId,
            setNumber: setNumber,
            newWeight: newWeight,
            loadUnit: state.loadUnit
        )

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Reps Change (Sub-100ms Response)

    /// Update reps for a set with immediate UI update
    func updateReps(_ newReps: Int, forSet setNumber: Int) {
        let token = ResponseTimeMonitor.shared.startInteraction(.repsChange)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id],
              setNumber > 0 && setNumber <= state.repsPerSet.count else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // 1. Capture snapshot
        snapshots[exercise.id] = state.snapshot()

        // 2. Immediate UI update
        state.repsPerSet[setNumber - 1] = newReps
        state.isPendingSync = true

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - RPE/Pain Updates (Sub-100ms Response)

    func updateRPE(_ newRPE: Int) {
        let token = ResponseTimeMonitor.shared.startInteraction(.rpeChange)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        state.rpe = min(max(newRPE, 0), 10)
        state.isPendingSync = true

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    func updatePainScore(_ newPain: Int) {
        let token = ResponseTimeMonitor.shared.startInteraction(.painScoreChange)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        state.painScore = min(max(newPain, 0), 10)
        state.isPendingSync = true

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Exercise Navigation (Sub-100ms Response)

    /// Skip the current exercise with immediate UI update
    func skipCurrentExercise() {
        let token = ResponseTimeMonitor.shared.startInteraction(.exerciseSkip)

        guard let exercise = currentExercise,
              let state = workoutState.exerciseStates[exercise.id] else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        // Immediate UI update
        state.isSkipped = true
        workoutState.skippedCount += 1

        // Move to next
        moveToNextExercise()

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    /// Navigate to a specific exercise
    func navigateToExercise(at index: Int) {
        let token = ResponseTimeMonitor.shared.startInteraction(.exerciseNavigation)

        guard index >= 0 && index < exercises.count else {
            ResponseTimeMonitor.shared.endInteraction(token)
            return
        }

        currentExerciseIndex = index

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    /// Move to the next incomplete exercise
    private func moveToNextExercise() {
        // Find next incomplete exercise
        for i in (currentExerciseIndex + 1)..<exercises.count {
            let exercise = exercises[i]
            if let state = workoutState.exerciseStates[exercise.id],
               !state.isCompleted && !state.isSkipped {
                currentExerciseIndex = i
                return
            }
        }

        // Wrap around to find any incomplete
        for i in 0..<currentExerciseIndex {
            let exercise = exercises[i]
            if let state = workoutState.exerciseStates[exercise.id],
               !state.isCompleted && !state.isSkipped {
                currentExerciseIndex = i
                return
            }
        }

        // All complete - stay at current
    }

    // MARK: - Workout Completion

    /// Complete the workout with immediate UI update and background sync
    func completeWorkout() {
        let token = ResponseTimeMonitor.shared.startInteraction(.workoutCompletion)

        // 1. Immediate UI update
        workoutState.isWorkoutCompleted = true

        // 2. Haptic feedback
        HapticFeedback.success()

        // 3. Queue background sync
        let durationMinutes = startTime.map { Int(Date().timeIntervalSince($0) / 60) } ?? 0

        pendingQueue.enqueueWorkoutCompletion(
            sessionId: sessionId,
            patientId: patientId,
            startedAt: startTime ?? Date(),
            totalVolume: totalVolume,
            avgRpe: averageRPE,
            avgPain: averagePain,
            durationMinutes: durationMinutes
        )

        ResponseTimeMonitor.shared.endInteraction(token)
    }

    // MARK: - Rollback

    /// Roll back an exercise to its previous state (on sync failure)
    func rollbackExercise(_ exerciseId: UUID) {
        guard let snapshot = snapshots[exerciseId],
              let state = workoutState.exerciseStates[exerciseId] else {
            return
        }

        let wasCompleted = state.isCompleted

        state.restore(from: snapshot)

        // Adjust counts if needed
        if wasCompleted && !state.isCompleted {
            workoutState.completedCount = max(0, workoutState.completedCount - 1)
        }

        DebugLogger.shared.log("Rolled back exercise \(exerciseId)", level: .warning)
    }

    // MARK: - Manual Sync

    /// Force sync all pending changes
    func forceSync() async {
        await pendingQueue.forceSync()
    }

    // MARK: - Utilities

    private func parseTargetReps(_ repsString: String?) -> Int {
        guard let repsStr = repsString else { return 10 }

        if let reps = Int(repsStr) {
            return reps
        }

        // Handle range format like "8-10"
        if repsStr.contains("-") {
            let parts = repsStr.split(separator: "-")
            if let low = Int(parts.first ?? ""), let high = Int(parts.last ?? "") {
                return (low + high) / 2
            }
        }

        return 10
    }
}

