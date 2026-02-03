//
//  OptimisticUpdateManager.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Manages optimistic UI updates with background sync and rollback support
//

import Foundation
import Combine

// MARK: - Optimistic Update Types

/// Represents a pending optimistic update that needs server confirmation
struct PendingOptimisticUpdate: Codable, Identifiable {
    let id: UUID
    let type: OptimisticUpdateType
    let timestamp: Date
    let payload: Data  // JSON-encoded payload
    var retryCount: Int
    var lastError: String?
    var status: UpdateStatus

    enum UpdateStatus: String, Codable {
        case pending
        case syncing
        case confirmed
        case failed
        case rolledBack
    }

    init(type: OptimisticUpdateType, payload: Data) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date()
        self.payload = payload
        self.retryCount = 0
        self.lastError = nil
        self.status = .pending
    }
}

/// Types of optimistic updates supported
enum OptimisticUpdateType: String, Codable {
    case setCompletion       // Completing a set during workout
    case exerciseCompletion  // Completing an entire exercise
    case weightChange        // Changing weight during exercise
    case repsChange          // Changing reps during exercise
    case rpeChange           // Changing RPE rating
    case painScoreChange     // Changing pain score
    case workoutCompletion   // Completing entire workout
    case sessionStart        // Starting a workout session
    case exerciseSkip        // Skipping an exercise
    case notesUpdate         // Updating exercise notes
}

// MARK: - Update Payloads

/// Payload for set/exercise completion updates
struct SetCompletionPayload: Codable {
    let sessionExerciseId: UUID
    let patientId: UUID
    let setNumber: Int
    let reps: Int
    let weight: Double?
    let loadUnit: String
    let timestamp: Date
}

/// Payload for exercise completion updates
struct ExerciseCompletionPayload: Codable {
    let sessionExerciseId: UUID
    let patientId: UUID
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String
    let rpe: Int
    let painScore: Int
    let notes: String?
    let timestamp: Date
}

/// Payload for weight change updates
struct WeightChangePayload: Codable {
    let sessionExerciseId: UUID
    let patientId: UUID
    let setNumber: Int?  // nil means all sets
    let newWeight: Double
    let loadUnit: String
    let timestamp: Date
}

/// Payload for workout completion updates
struct WorkoutCompletionPayload: Codable {
    let sessionId: UUID
    let patientId: UUID
    let startedAt: Date
    let completedAt: Date
    let totalVolume: Double
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int
}

// MARK: - Optimistic State Publisher

/// Observable state for a single exercise during workout execution
class OptimisticExerciseState: ObservableObject, Identifiable {
    let id: UUID
    let sessionExerciseId: UUID

    @Published var completedSets: Int = 0
    @Published var repsPerSet: [Int] = []
    @Published var weightPerSet: [Double] = []
    @Published var rpe: Int = 5
    @Published var painScore: Int = 0
    @Published var notes: String = ""
    @Published var isCompleted: Bool = false
    @Published var isSkipped: Bool = false
    @Published var syncStatus: SyncStatus = .synced

    enum SyncStatus {
        case synced
        case pendingSync
        case syncing
        case failed
    }

    init(sessionExerciseId: UUID) {
        self.id = UUID()
        self.sessionExerciseId = sessionExerciseId
    }

    /// Create a snapshot for rollback purposes
    func snapshot() -> ExerciseStateSnapshot {
        ExerciseStateSnapshot(
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

    /// Restore from a snapshot (rollback)
    func restore(from snapshot: ExerciseStateSnapshot) {
        completedSets = snapshot.completedSets
        repsPerSet = snapshot.repsPerSet
        weightPerSet = snapshot.weightPerSet
        rpe = snapshot.rpe
        painScore = snapshot.painScore
        notes = snapshot.notes
        isCompleted = snapshot.isCompleted
        isSkipped = snapshot.isSkipped
        syncStatus = .synced
    }
}

/// Snapshot of exercise state for rollback
struct ExerciseStateSnapshot {
    let completedSets: Int
    let repsPerSet: [Int]
    let weightPerSet: [Double]
    let rpe: Int
    let painScore: Int
    let notes: String
    let isCompleted: Bool
    let isSkipped: Bool
}

// MARK: - OptimisticUpdateManager

/// Manages optimistic UI updates with background sync and automatic rollback
///
/// ACP-516: Ensures every tap responds in under 100ms by:
/// 1. Immediately updating UI state before server response
/// 2. Queueing actual API calls in background
/// 3. Handling rollback if API call fails
/// 4. Syncing pending changes when network becomes available
@MainActor
class OptimisticUpdateManager: ObservableObject {
    static let shared = OptimisticUpdateManager()

    // MARK: - Published State

    /// Exercise states keyed by session_exercise_id
    @Published private(set) var exerciseStates: [UUID: OptimisticExerciseState] = [:]

    /// Overall sync status
    @Published private(set) var isSyncing: Bool = false

    /// Number of pending updates waiting to sync
    @Published private(set) var pendingUpdateCount: Int = 0

    /// Last sync error for user feedback
    @Published private(set) var lastSyncError: String?

    /// Whether there are failed updates that need attention
    @Published private(set) var hasFailedUpdates: Bool = false

    // MARK: - Private Properties

    private let persistenceKey = "pt_optimistic_updates_queue"
    private let maxRetries = 3
    private let syncDebounceInterval: TimeInterval = 0.5  // Batch updates within 500ms

    private var pendingUpdates: [PendingOptimisticUpdate] = []
    private var stateSnapshots: [UUID: ExerciseStateSnapshot] = [:]  // For rollback
    private var syncTask: Task<Void, Never>?
    private var syncDebounceTimer: Timer?
    private var networkMonitorCancellable: AnyCancellable?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Publishers for UI Binding

    /// Publisher that emits when any exercise state changes
    let exerciseStateChanged = PassthroughSubject<UUID, Never>()

    /// Publisher that emits when sync completes (success or failure)
    let syncCompleted = PassthroughSubject<Result<Int, Error>, Never>()

    // MARK: - Initialization

    private init() {
        loadPendingUpdates()
        setupNetworkMonitoring()
    }

    // MARK: - Exercise State Management

    /// Get or create optimistic state for an exercise
    func state(for sessionExerciseId: UUID) -> OptimisticExerciseState {
        if let existing = exerciseStates[sessionExerciseId] {
            return existing
        }

        let newState = OptimisticExerciseState(sessionExerciseId: sessionExerciseId)
        exerciseStates[sessionExerciseId] = newState
        return newState
    }

    /// Initialize states for a batch of exercises (e.g., when starting a workout)
    func initializeExerciseStates(for exercises: [Exercise]) {
        for exercise in exercises {
            let state = state(for: exercise.id)
            state.repsPerSet = parseReps(exercise.prescribed_reps, sets: exercise.prescribed_sets)
            state.weightPerSet = Array(repeating: exercise.prescribed_load ?? 0, count: exercise.prescribed_sets)
        }
    }

    /// Clear all exercise states (e.g., when ending a workout)
    func clearExerciseStates() {
        exerciseStates.removeAll()
        stateSnapshots.removeAll()
    }

    // MARK: - Optimistic Updates

    /// Complete a set with immediate UI update and background sync
    /// Returns immediately (< 1ms) while sync happens in background
    func completeSet(
        sessionExerciseId: UUID,
        patientId: UUID,
        setNumber: Int,
        reps: Int,
        weight: Double?,
        loadUnit: String = "lbs"
    ) {
        let startTime = ResponseTimeMonitor.shared.startInteraction(.setCompletion)

        // 1. Capture state for potential rollback
        let state = state(for: sessionExerciseId)
        stateSnapshots[sessionExerciseId] = state.snapshot()

        // 2. Immediately update UI state (optimistic)
        state.completedSets = max(state.completedSets, setNumber)
        if setNumber <= state.repsPerSet.count {
            state.repsPerSet[setNumber - 1] = reps
        }
        if let weight = weight, setNumber <= state.weightPerSet.count {
            state.weightPerSet[setNumber - 1] = weight
        }
        state.syncStatus = .pendingSync

        // 3. Emit change notification
        exerciseStateChanged.send(sessionExerciseId)

        // 4. Queue background sync
        let payload = SetCompletionPayload(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            setNumber: setNumber,
            reps: reps,
            weight: weight,
            loadUnit: loadUnit,
            timestamp: Date()
        )

        queueUpdate(type: .setCompletion, payload: payload)

        ResponseTimeMonitor.shared.endInteraction(startTime, type: .setCompletion)
    }

    /// Complete an exercise with immediate UI update and background sync
    func completeExercise(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String = "lbs",
        rpe: Int,
        painScore: Int,
        notes: String?
    ) {
        let startTime = ResponseTimeMonitor.shared.startInteraction(.exerciseCompletion)

        // 1. Capture state for potential rollback
        let state = state(for: sessionExerciseId)
        stateSnapshots[sessionExerciseId] = state.snapshot()

        // 2. Immediately update UI state (optimistic)
        state.completedSets = actualSets
        state.repsPerSet = actualReps
        if let load = actualLoad {
            state.weightPerSet = Array(repeating: load, count: actualSets)
        }
        state.rpe = rpe
        state.painScore = painScore
        state.notes = notes ?? ""
        state.isCompleted = true
        state.syncStatus = .pendingSync

        // 3. Emit change notification
        exerciseStateChanged.send(sessionExerciseId)

        // 4. Haptic feedback (immediate response)
        HapticService.success()

        // 5. Queue background sync
        let payload = ExerciseCompletionPayload(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            actualSets: actualSets,
            actualReps: actualReps,
            actualLoad: actualLoad,
            loadUnit: loadUnit,
            rpe: rpe,
            painScore: painScore,
            notes: notes,
            timestamp: Date()
        )

        queueUpdate(type: .exerciseCompletion, payload: payload)

        ResponseTimeMonitor.shared.endInteraction(startTime, type: .exerciseCompletion)
    }

    /// Update weight with immediate UI update and background sync
    func updateWeight(
        sessionExerciseId: UUID,
        patientId: UUID,
        setNumber: Int?,
        newWeight: Double,
        loadUnit: String = "lbs"
    ) {
        let startTime = ResponseTimeMonitor.shared.startInteraction(.weightChange)

        // 1. Capture state for potential rollback
        let state = state(for: sessionExerciseId)
        stateSnapshots[sessionExerciseId] = state.snapshot()

        // 2. Immediately update UI state (optimistic)
        if let setNum = setNumber, setNum <= state.weightPerSet.count {
            state.weightPerSet[setNum - 1] = newWeight
        } else {
            // Update all sets
            state.weightPerSet = state.weightPerSet.map { _ in newWeight }
        }
        state.syncStatus = .pendingSync

        // 3. Emit change notification
        exerciseStateChanged.send(sessionExerciseId)

        // 4. Queue background sync
        let payload = WeightChangePayload(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            setNumber: setNumber,
            newWeight: newWeight,
            loadUnit: loadUnit,
            timestamp: Date()
        )

        queueUpdate(type: .weightChange, payload: payload)

        ResponseTimeMonitor.shared.endInteraction(startTime, type: .weightChange)
    }

    /// Skip an exercise with immediate UI update
    func skipExercise(sessionExerciseId: UUID) {
        let startTime = ResponseTimeMonitor.shared.startInteraction(.exerciseSkip)

        let state = state(for: sessionExerciseId)
        stateSnapshots[sessionExerciseId] = state.snapshot()

        state.isSkipped = true
        state.syncStatus = .synced  // Skip is local-only, no server sync needed

        exerciseStateChanged.send(sessionExerciseId)

        ResponseTimeMonitor.shared.endInteraction(startTime, type: .exerciseSkip)
    }

    // MARK: - Workout-Level Operations

    /// Complete a workout session with immediate UI update and background sync
    func completeWorkout(
        sessionId: UUID,
        patientId: UUID,
        startedAt: Date,
        completedAt: Date = Date(),
        totalVolume: Double,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int
    ) {
        let startTime = ResponseTimeMonitor.shared.startInteraction(.workoutCompletion)

        let payload = WorkoutCompletionPayload(
            sessionId: sessionId,
            patientId: patientId,
            startedAt: startedAt,
            completedAt: completedAt,
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )

        // Haptic feedback immediately
        HapticService.success()

        queueUpdate(type: .workoutCompletion, payload: payload)

        ResponseTimeMonitor.shared.endInteraction(startTime, type: .workoutCompletion)
    }

    // MARK: - Sync Operations

    /// Queue an update for background sync
    private func queueUpdate<T: Codable>(type: OptimisticUpdateType, payload: T) {
        do {
            let payloadData = try JSONEncoder().encode(payload)
            let update = PendingOptimisticUpdate(type: type, payload: payloadData)
            pendingUpdates.append(update)
            pendingUpdateCount = pendingUpdates.count
            savePendingUpdates()

            // Debounce sync to batch rapid updates
            scheduleDebouncedSync()

            DebugLogger.shared.log("📤 Queued optimistic update: \(type.rawValue)", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("❌ Failed to encode update payload: \(error)", level: .error)
        }
    }

    /// Schedule a debounced sync (batches rapid updates)
    private func scheduleDebouncedSync() {
        syncDebounceTimer?.invalidate()
        syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: syncDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncPendingUpdates()
            }
        }
    }

    /// Sync all pending updates to the server
    func syncPendingUpdates() async {
        guard !pendingUpdates.isEmpty else {
            DebugLogger.shared.log("📤 No pending updates to sync", level: .diagnostic)
            return
        }

        guard !isSyncing else {
            DebugLogger.shared.log("⏳ Sync already in progress", level: .diagnostic)
            return
        }

        guard !supabase.isOffline else {
            DebugLogger.shared.log("📵 Device offline, deferring sync", level: .diagnostic)
            return
        }

        isSyncing = true
        lastSyncError = nil

        let updatesToSync = pendingUpdates.filter { $0.status == .pending && $0.retryCount < maxRetries }
        var successCount = 0
        var failCount = 0

        DebugLogger.shared.log("📤 Starting sync of \(updatesToSync.count) updates...", level: .diagnostic)

        for update in updatesToSync {
            do {
                try await syncSingleUpdate(update)

                // Mark as confirmed and remove from queue
                if let index = pendingUpdates.firstIndex(where: { $0.id == update.id }) {
                    pendingUpdates.remove(at: index)
                }

                // Update exercise sync status
                updateExerciseSyncStatus(for: update, status: .synced)

                successCount += 1
            } catch {
                // Mark retry and keep in queue
                if let index = pendingUpdates.firstIndex(where: { $0.id == update.id }) {
                    pendingUpdates[index].retryCount += 1
                    pendingUpdates[index].lastError = error.localizedDescription

                    if pendingUpdates[index].retryCount >= maxRetries {
                        pendingUpdates[index].status = .failed
                        handleFailedUpdate(update)
                    }
                }

                failCount += 1
                DebugLogger.shared.log("❌ Failed to sync update \(update.id): \(error.localizedDescription)", level: .error)
            }
        }

        // Clean up failed updates that exceeded retries
        pendingUpdates.removeAll { $0.status == .failed }

        pendingUpdateCount = pendingUpdates.count
        savePendingUpdates()

        isSyncing = false
        hasFailedUpdates = failCount > 0

        if failCount > 0 {
            lastSyncError = "Failed to sync \(failCount) update(s)"
        }

        syncCompleted.send(failCount > 0 ? .failure(NSError(domain: "OptimisticUpdateManager", code: 1)) : .success(successCount))

        DebugLogger.shared.log("📤 Sync complete: \(successCount) success, \(failCount) failed", level: .success)
    }

    /// Sync a single update to the server
    private func syncSingleUpdate(_ update: PendingOptimisticUpdate) async throws {
        switch update.type {
        case .setCompletion:
            // Set completions are aggregated into exercise completion, no direct API call needed
            _ = try JSONDecoder().decode(SetCompletionPayload.self, from: update.payload)
            break

        case .exerciseCompletion:
            let payload = try JSONDecoder().decode(ExerciseCompletionPayload.self, from: update.payload)
            try await syncExerciseCompletion(payload)

        case .weightChange:
            // Weight changes are included in exercise completion, no direct API call needed
            break

        case .workoutCompletion:
            let payload = try JSONDecoder().decode(WorkoutCompletionPayload.self, from: update.payload)
            try await syncWorkoutCompletion(payload)

        case .repsChange, .rpeChange, .painScoreChange, .sessionStart, .exerciseSkip, .notesUpdate:
            // These are either local-only or included in exercise completion
            break
        }
    }

    /// Sync exercise completion to Supabase
    private func syncExerciseCompletion(_ payload: ExerciseCompletionPayload) async throws {
        let input = CreateExerciseLogInput(
            sessionExerciseId: payload.sessionExerciseId,
            patientId: payload.patientId,
            actualSets: payload.actualSets,
            actualReps: payload.actualReps,
            actualLoad: payload.actualLoad,
            loadUnit: payload.loadUnit,
            rpe: payload.rpe,
            painScore: payload.painScore,
            notes: payload.notes,
            completed: true
        )

        _ = try await supabase.client
            .from("exercise_logs")
            .insert(input)
            .execute()
    }

    /// Sync workout completion to Supabase
    private func syncWorkoutCompletion(_ payload: WorkoutCompletionPayload) async throws {
        let updateData = SessionUpdateData(
            completed: true,
            started_at: ISO8601DateFormatter().string(from: payload.startedAt),
            completed_at: ISO8601DateFormatter().string(from: payload.completedAt),
            total_volume: payload.totalVolume,
            avg_rpe: payload.avgRpe ?? 0,
            avg_pain: payload.avgPain ?? 0,
            duration_minutes: payload.durationMinutes
        )

        _ = try await supabase.client
            .from("sessions")
            .update(updateData)
            .eq("id", value: payload.sessionId.uuidString)
            .execute()
    }

    // MARK: - Rollback Handling

    /// Handle a failed update by rolling back UI state
    private func handleFailedUpdate(_ update: PendingOptimisticUpdate) {
        switch update.type {
        case .exerciseCompletion:
            if let payload = try? JSONDecoder().decode(ExerciseCompletionPayload.self, from: update.payload),
               let snapshot = stateSnapshots[payload.sessionExerciseId],
               let state = exerciseStates[payload.sessionExerciseId] {
                state.restore(from: snapshot)
                state.syncStatus = .failed
                exerciseStateChanged.send(payload.sessionExerciseId)
                DebugLogger.shared.log("🔄 Rolled back exercise state for \(payload.sessionExerciseId)", level: .warning)
            }

        case .setCompletion:
            if let payload = try? JSONDecoder().decode(SetCompletionPayload.self, from: update.payload),
               let snapshot = stateSnapshots[payload.sessionExerciseId],
               let state = exerciseStates[payload.sessionExerciseId] {
                state.restore(from: snapshot)
                state.syncStatus = .failed
                exerciseStateChanged.send(payload.sessionExerciseId)
            }

        default:
            break
        }
    }

    /// Update exercise sync status based on update type
    private func updateExerciseSyncStatus(for update: PendingOptimisticUpdate, status: OptimisticExerciseState.SyncStatus) {
        switch update.type {
        case .exerciseCompletion:
            if let payload = try? JSONDecoder().decode(ExerciseCompletionPayload.self, from: update.payload),
               let state = exerciseStates[payload.sessionExerciseId] {
                state.syncStatus = status
            }
        case .setCompletion:
            if let payload = try? JSONDecoder().decode(SetCompletionPayload.self, from: update.payload),
               let state = exerciseStates[payload.sessionExerciseId] {
                state.syncStatus = status
            }
        default:
            break
        }
    }

    // MARK: - Persistence

    private func loadPendingUpdates() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            pendingUpdates = []
            return
        }

        do {
            pendingUpdates = try JSONDecoder().decode([PendingOptimisticUpdate].self, from: data)
            pendingUpdateCount = pendingUpdates.count
            DebugLogger.shared.log("📦 Loaded \(pendingUpdates.count) pending optimistic updates", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to load optimistic updates: \(error)", level: .warning)
            pendingUpdates = []
        }
    }

    private func savePendingUpdates() {
        do {
            let data = try JSONEncoder().encode(pendingUpdates)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to save optimistic updates: \(error)", level: .warning)
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitorCancellable = PTSupabaseClient.shared.$isOffline
            .removeDuplicates()
            .sink { [weak self] isOffline in
                if !isOffline {
                    Task { @MainActor [weak self] in
                        await self?.syncPendingUpdates()
                    }
                }
            }
    }

    // MARK: - Utilities

    private func parseReps(_ repsString: String?, sets: Int) -> [Int] {
        guard let repsStr = repsString else {
            return Array(repeating: 10, count: sets)
        }

        if let reps = Int(repsStr) {
            return Array(repeating: reps, count: sets)
        }

        // Handle range format like "8-10"
        if repsStr.contains("-") {
            let parts = repsStr.split(separator: "-")
            if let low = Int(parts.first ?? ""), let high = Int(parts.last ?? "") {
                return Array(repeating: (low + high) / 2, count: sets)
            }
        }

        return Array(repeating: 10, count: sets)
    }

    /// Force sync now (for manual refresh)
    func forceSync() async {
        syncDebounceTimer?.invalidate()
        await syncPendingUpdates()
    }

    /// Clear all pending updates (use with caution)
    func clearPendingUpdates() {
        pendingUpdates = []
        pendingUpdateCount = 0
        savePendingUpdates()
        DebugLogger.shared.log("🗑️ Cleared all pending optimistic updates", level: .warning)
    }
}
