//
//  PendingChangesQueue.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Offline-first queue for pending changes with automatic sync
//

import Foundation
import Combine

// MARK: - Change Types

/// Represents a type of change that can be queued
enum PendingChangeType: String, Codable {
    case exerciseLog
    case sessionCompletion
    case workoutProgress
    case exerciseModification
    case notesUpdate
    case rpeUpdate
    case painScoreUpdate
}

/// Priority levels for pending changes
enum ChangePriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: ChangePriority, rhs: ChangePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Status of a pending change
enum ChangeStatus: String, Codable {
    case pending      // Waiting to be synced
    case syncing      // Currently being synced
    case completed    // Successfully synced
    case failed       // Sync failed, will retry
    case expired      // Exceeded max retries, needs attention
}

// MARK: - Pending Change

/// Represents a single pending change waiting to be synced
struct PendingChange: Codable, Identifiable {
    let id: UUID
    let type: PendingChangeType
    let priority: ChangePriority
    let createdAt: Date
    let payload: Data  // JSON-encoded payload
    var status: ChangeStatus
    var retryCount: Int
    var lastAttempt: Date?
    var lastError: String?

    /// Unique key for deduplication (e.g., same exercise being updated multiple times)
    let deduplicationKey: String?

    init(
        type: PendingChangeType,
        priority: ChangePriority = .normal,
        payload: Data,
        deduplicationKey: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.createdAt = Date()
        self.payload = payload
        self.status = .pending
        self.retryCount = 0
        self.lastAttempt = nil
        self.lastError = nil
        self.deduplicationKey = deduplicationKey
    }

    /// Time since creation
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Whether this change should be retried
    var shouldRetry: Bool {
        status == .failed && retryCount < PendingChangesQueue.maxRetries
    }
}

// MARK: - Queue Statistics

/// Statistics about the pending changes queue
struct QueueStatistics {
    let totalCount: Int
    let pendingCount: Int
    let syncingCount: Int
    let failedCount: Int
    let expiredCount: Int
    let oldestChangeAge: TimeInterval?
    let byType: [PendingChangeType: Int]
    let byPriority: [ChangePriority: Int]

    var hasIssues: Bool {
        failedCount > 0 || expiredCount > 0
    }

    var summary: String {
        var parts: [String] = []
        if pendingCount > 0 { parts.append("\(pendingCount) pending") }
        if syncingCount > 0 { parts.append("\(syncingCount) syncing") }
        if failedCount > 0 { parts.append("\(failedCount) failed") }
        if expiredCount > 0 { parts.append("\(expiredCount) expired") }
        return parts.isEmpty ? "Queue empty" : parts.joined(separator: ", ")
    }
}

// MARK: - PendingChangesQueue

/// Manages a queue of pending changes for offline-first behavior
///
/// ACP-516: Ensures offline-first behavior by:
/// 1. Immediately accepting changes without blocking on network
/// 2. Persisting changes to survive app termination
/// 3. Automatically syncing when network becomes available
/// 4. Supporting priority-based ordering and deduplication
/// 5. Providing retry logic with exponential backoff
@MainActor
class PendingChangesQueue: ObservableObject {
    static let shared = PendingChangesQueue()
    nonisolated static let maxRetries = 5

    // MARK: - Published State

    @Published private(set) var changes: [PendingChange] = []
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var lastError: String?

    /// Number of pending changes
    var pendingCount: Int {
        changes.filter { $0.status == .pending || $0.status == .failed }.count
    }

    /// Whether there are changes waiting to sync
    var hasPendingChanges: Bool {
        pendingCount > 0
    }

    /// Whether there are failed changes that need attention
    var hasFailedChanges: Bool {
        changes.contains { $0.status == .failed || $0.status == .expired }
    }

    // MARK: - Private Properties

    private let persistenceKey = "pt_pending_changes_queue"
    private let syncBatchSize = 10
    private let retryDelays: [TimeInterval] = [1, 2, 5, 10, 30]  // Exponential backoff

    private var syncTask: Task<Void, Never>?
    private var networkMonitorCancellable: AnyCancellable?
    private var syncTimer: Timer?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Publishers

    /// Emits when queue changes (add, remove, status update)
    let queueChanged = PassthroughSubject<Void, Never>()

    /// Emits when sync completes (success count, failure count)
    let syncCompleted = PassthroughSubject<(success: Int, failed: Int), Never>()

    // MARK: - Initialization

    private init() {
        loadQueue()
        setupNetworkMonitoring()
        setupPeriodicSync()
    }

    // MARK: - Queue Operations

    /// Enqueue a change for background sync
    /// Returns immediately (< 1ms) - never blocks on network
    @discardableResult
    func enqueue<T: Codable>(
        type: PendingChangeType,
        priority: ChangePriority = .normal,
        payload: T,
        deduplicationKey: String? = nil
    ) -> UUID {
        do {
            let payloadData = try JSONEncoder().encode(payload)

            // Handle deduplication - replace existing if same key
            if let key = deduplicationKey,
               let existingIndex = changes.firstIndex(where: {
                   $0.deduplicationKey == key && $0.status == .pending
               }) {
                // Replace with new change
                var updatedChange = PendingChange(
                    type: type,
                    priority: priority,
                    payload: payloadData,
                    deduplicationKey: key
                )
                updatedChange.retryCount = changes[existingIndex].retryCount
                changes[existingIndex] = updatedChange
                DebugLogger.shared.log("🔄 Deduplicated change: \(key)", level: .diagnostic)
            } else {
                // Add new change
                let change = PendingChange(
                    type: type,
                    priority: priority,
                    payload: payloadData,
                    deduplicationKey: deduplicationKey
                )
                changes.append(change)
            }

            saveQueue()
            queueChanged.send()

            DebugLogger.shared.log("📥 Enqueued \(type.rawValue) change (priority: \(priority))", level: .diagnostic)

            // Trigger sync if online
            if !supabase.isOffline {
                scheduleSyncSoon()
            }

            return changes.last?.id ?? UUID()
        } catch {
            DebugLogger.shared.log("❌ Failed to encode change payload: \(error)", level: .error)
            return UUID()
        }
    }

    /// Remove a specific change from the queue
    func remove(_ changeId: UUID) {
        changes.removeAll { $0.id == changeId }
        saveQueue()
        queueChanged.send()
    }

    /// Remove all completed changes
    func removeCompleted() {
        changes.removeAll { $0.status == .completed }
        saveQueue()
        queueChanged.send()
    }

    /// Clear all expired/failed changes (user acknowledgement required)
    func clearFailedChanges() {
        let failedCount = changes.filter { $0.status == .failed || $0.status == .expired }.count
        changes.removeAll { $0.status == .failed || $0.status == .expired }
        saveQueue()
        queueChanged.send()
        DebugLogger.shared.log("🗑️ Cleared \(failedCount) failed changes", level: .warning)
    }

    // MARK: - Sync Operations

    /// Sync all pending changes to the server
    func sync() async {
        guard !isSyncing else {
            DebugLogger.shared.log("⏳ Sync already in progress", level: .diagnostic)
            return
        }

        guard !supabase.isOffline else {
            DebugLogger.shared.log("📵 Device offline, deferring sync", level: .diagnostic)
            return
        }

        let pendingChanges = changes.filter { $0.status == .pending || $0.shouldRetry }
            .sorted { $0.priority > $1.priority }  // Higher priority first

        guard !pendingChanges.isEmpty else {
            DebugLogger.shared.log("📤 No pending changes to sync", level: .diagnostic)
            return
        }

        isSyncing = true
        lastError = nil

        var successCount = 0
        var failCount = 0

        DebugLogger.shared.log("📤 Starting sync of \(pendingChanges.count) changes...", level: .diagnostic)

        // Process in batches
        for change in pendingChanges.prefix(syncBatchSize) {
            // Update status to syncing
            if let index = changes.firstIndex(where: { $0.id == change.id }) {
                changes[index].status = .syncing
                changes[index].lastAttempt = Date()
            }

            do {
                try await syncChange(change)

                // Mark as completed
                if let index = changes.firstIndex(where: { $0.id == change.id }) {
                    changes[index].status = .completed
                }
                successCount += 1

            } catch {
                // Mark as failed with retry logic
                if let index = changes.firstIndex(where: { $0.id == change.id }) {
                    changes[index].retryCount += 1
                    changes[index].lastError = error.localizedDescription

                    if changes[index].retryCount >= Self.maxRetries {
                        changes[index].status = .expired
                    } else {
                        changes[index].status = .failed
                    }
                }
                failCount += 1
                DebugLogger.shared.log("❌ Failed to sync change: \(error.localizedDescription)", level: .error)
            }
        }

        // Clean up completed changes
        changes.removeAll { $0.status == .completed }

        saveQueue()
        queueChanged.send()

        isSyncing = false
        lastSyncTime = Date()

        if failCount > 0 {
            lastError = "Failed to sync \(failCount) change(s)"
        }

        syncCompleted.send((success: successCount, failed: failCount))

        DebugLogger.shared.log("📤 Sync complete: \(successCount) success, \(failCount) failed", level: .success)

        // Schedule retry if there are still pending changes
        if hasPendingChanges {
            scheduleRetrySync()
        }
    }

    /// Sync a single change to the server
    private func syncChange(_ change: PendingChange) async throws {
        switch change.type {
        case .exerciseLog:
            try await syncExerciseLog(change)

        case .sessionCompletion:
            try await syncSessionCompletion(change)

        case .workoutProgress:
            try await syncWorkoutProgress(change)

        case .exerciseModification:
            try await syncExerciseModification(change)

        case .notesUpdate:
            try await syncNotesUpdate(change)

        case .rpeUpdate:
            try await syncRpeUpdate(change)

        case .painScoreUpdate:
            try await syncPainScoreUpdate(change)
        }
    }

    // MARK: - Sync Implementations

    private func syncExerciseLog(_ change: PendingChange) async throws {
        let payload = try JSONDecoder().decode(ExerciseCompletionPayload.self, from: change.payload)

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

    private func syncSessionCompletion(_ change: PendingChange) async throws {
        let payload = try JSONDecoder().decode(WorkoutCompletionPayload.self, from: change.payload)

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

    private func syncWorkoutProgress(_ change: PendingChange) async throws {
        // Workout progress is tracked via exercise logs, no separate sync needed
    }

    private func syncExerciseModification(_ change: PendingChange) async throws {
        // Exercise modifications (like substitutions) are handled separately
    }

    private func syncNotesUpdate(_ change: PendingChange) async throws {
        // Notes are included in exercise log sync
    }

    private func syncRpeUpdate(_ change: PendingChange) async throws {
        // RPE is included in exercise log sync
    }

    private func syncPainScoreUpdate(_ change: PendingChange) async throws {
        // Pain score is included in exercise log sync
    }

    // MARK: - Scheduling

    private func scheduleSyncSoon() {
        // Debounce rapid changes
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.sync()
            }
        }
    }

    private func scheduleRetrySync() {
        // Get the appropriate delay based on max retry count in queue
        let maxRetry = changes.filter { $0.shouldRetry }.map { $0.retryCount }.max() ?? 0
        let delay = retryDelays[min(maxRetry, retryDelays.count - 1)]

        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.sync()
            }
        }

        DebugLogger.shared.log("⏰ Scheduled retry sync in \(delay)s", level: .diagnostic)
    }

    private func setupPeriodicSync() {
        // Periodic sync every 30 seconds while app is active
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if self?.hasPendingChanges == true {
                    await self?.sync()
                }
            }
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitorCancellable = PTSupabaseClient.shared.$isOffline
            .removeDuplicates()
            .sink { [weak self] isOffline in
                if !isOffline {
                    // Network came back - trigger sync
                    Task { @MainActor [weak self] in
                        await self?.sync()
                    }
                }
            }
    }

    // MARK: - Persistence

    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            changes = []
            return
        }

        do {
            changes = try JSONDecoder().decode([PendingChange].self, from: data)

            // Reset any "syncing" status to "pending" on load (app was killed mid-sync)
            for i in changes.indices {
                if changes[i].status == .syncing {
                    changes[i].status = .pending
                }
            }

            DebugLogger.shared.log("📦 Loaded \(changes.count) pending changes from queue", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to load pending changes: \(error)", level: .warning)
            changes = []
        }
    }

    private func saveQueue() {
        do {
            let data = try JSONEncoder().encode(changes)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to save pending changes: \(error)", level: .warning)
        }
    }

    // MARK: - Statistics

    /// Get current queue statistics
    func statistics() -> QueueStatistics {
        let pending = changes.filter { $0.status == .pending }
        let syncing = changes.filter { $0.status == .syncing }
        let failed = changes.filter { $0.status == .failed }
        let expired = changes.filter { $0.status == .expired }

        let byType = Dictionary(grouping: changes, by: { $0.type })
            .mapValues { $0.count }

        let byPriority = Dictionary(grouping: changes, by: { $0.priority })
            .mapValues { $0.count }

        return QueueStatistics(
            totalCount: changes.count,
            pendingCount: pending.count,
            syncingCount: syncing.count,
            failedCount: failed.count,
            expiredCount: expired.count,
            oldestChangeAge: changes.map { $0.age }.max(),
            byType: byType,
            byPriority: byPriority
        )
    }

    // MARK: - Debug

    /// Force immediate sync (for debugging/manual refresh)
    func forceSync() async {
        syncTimer?.invalidate()
        await sync()
    }

    /// Clear entire queue (use with caution)
    func clearQueue() {
        changes = []
        saveQueue()
        queueChanged.send()
        DebugLogger.shared.log("🗑️ Cleared entire pending changes queue", level: .warning)
    }

    /// Print queue status to console
    func printStatus() {
        #if DEBUG
        let stats = statistics()
        print("""
            === Pending Changes Queue ===
            \(stats.summary)
            Total: \(stats.totalCount)
            By Type: \(stats.byType)
            By Priority: \(stats.byPriority)
            ==============================
            """)
        #endif
    }
}

// MARK: - Convenience Extensions

extension PendingChangesQueue {
    /// Enqueue an exercise completion for background sync
    func enqueueExerciseCompletion(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) {
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

        enqueue(
            type: .exerciseLog,
            priority: .high,
            payload: payload,
            deduplicationKey: "exercise_\(sessionExerciseId)"
        )
    }

    /// Enqueue a workout completion for background sync
    func enqueueWorkoutCompletion(
        sessionId: UUID,
        patientId: UUID,
        startedAt: Date,
        totalVolume: Double,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int
    ) {
        let payload = WorkoutCompletionPayload(
            sessionId: sessionId,
            patientId: patientId,
            startedAt: startedAt,
            completedAt: Date(),
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )

        enqueue(
            type: .sessionCompletion,
            priority: .critical,
            payload: payload,
            deduplicationKey: "session_\(sessionId)"
        )
    }
}
