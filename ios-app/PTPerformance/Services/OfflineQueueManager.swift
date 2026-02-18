//
//  OfflineQueueManager.swift
//  PTPerformance
//
//  Manages offline queue for exercise log writes with automatic sync
//

import Foundation
import Combine

/// Represents a pending exercise log write stored in the offline queue
struct PendingExerciseLog: Codable, Identifiable {
    let id: UUID
    let sessionExerciseId: UUID
    let patientId: UUID
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let createdAt: Date
    var retryCount: Int
    var lastError: String?

    init(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String?,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) {
        self.id = UUID()
        self.sessionExerciseId = sessionExerciseId
        self.patientId = patientId
        self.actualSets = actualSets
        self.actualReps = actualReps
        self.actualLoad = actualLoad
        self.loadUnit = loadUnit
        self.rpe = rpe
        self.painScore = painScore
        self.notes = notes
        self.createdAt = Date()
        self.retryCount = 0
        self.lastError = nil
    }
}

/// Manages offline queue for exercise log writes
/// Stores pending writes in UserDefaults and syncs when network returns
@MainActor
class OfflineQueueManager: ObservableObject {
    static let shared = OfflineQueueManager()

    // MARK: - Published Properties

    @Published private(set) var pendingLogs: [PendingExerciseLog] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncError: String?

    /// Number of pending items waiting to sync
    var pendingCount: Int { pendingLogs.count }

    /// Whether there are items pending sync
    var hasPendingItems: Bool { !pendingLogs.isEmpty }

    // MARK: - Private Properties

    private let queueKey = "pt_offline_exercise_log_queue"
    private let maxRetries = 3
    private var syncTask: Task<Void, Never>?
    private var networkMonitorCancellable: AnyCancellable?

    // MARK: - Initialization

    private init() {
        loadQueue()
        setupNetworkMonitoring()
    }

    // MARK: - Queue Management

    /// Add an exercise log to the offline queue
    func enqueue(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String?,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) {
        let pendingLog = PendingExerciseLog(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            actualSets: actualSets,
            actualReps: actualReps,
            actualLoad: actualLoad,
            loadUnit: loadUnit,
            rpe: rpe,
            painScore: painScore,
            notes: notes
        )

        pendingLogs.append(pendingLog)
        saveQueue()

        DebugLogger.shared.log("📥 Queued exercise log for offline sync: \(pendingLog.id)", level: .diagnostic)
    }

    /// Remove a successfully synced log from the queue
    private func dequeue(_ logId: UUID) {
        pendingLogs.removeAll { $0.id == logId }
        saveQueue()

        DebugLogger.shared.log("✅ Removed synced log from queue: \(logId)", level: .success)
    }

    /// Update retry count for a failed log
    private func markRetry(_ logId: UUID, error: String) {
        if let index = pendingLogs.firstIndex(where: { $0.id == logId }) {
            pendingLogs[index].retryCount += 1
            pendingLogs[index].lastError = error
            saveQueue()
        }
    }

    // MARK: - Persistence

    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            pendingLogs = []
            return
        }

        do {
            pendingLogs = try SafeJSON.decoder().decode([PendingExerciseLog].self, from: data)
            DebugLogger.shared.log("📦 Loaded \(pendingLogs.count) pending logs from queue", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to load offline queue: \(error.localizedDescription)", level: .warning)
            pendingLogs = []
        }
    }

    private func saveQueue() {
        do {
            let data = try SafeJSON.encoder().encode(pendingLogs)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            DebugLogger.shared.log("⚠️ Failed to save offline queue: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        // Listen for offline status changes from PTSupabaseClient
        networkMonitorCancellable = PTSupabaseClient.shared.$isOffline
            .removeDuplicates()
            .sink { [weak self] isOffline in
                if !isOffline {
                    // Network came back online - trigger sync
                    Task { @MainActor [weak self] in
                        await self?.syncPendingLogs()
                    }
                }
            }
    }

    // MARK: - Sync Operations

    /// Sync all pending logs to the server
    /// Called automatically when network returns, or manually by user
    func syncPendingLogs() async {
        guard !pendingLogs.isEmpty else {
            DebugLogger.shared.log("📤 No pending logs to sync", level: .diagnostic)
            return
        }

        guard !isSyncing else {
            DebugLogger.shared.log("⏳ Sync already in progress", level: .diagnostic)
            return
        }

        guard !PTSupabaseClient.shared.isOffline else {
            DebugLogger.shared.log("📵 Still offline, skipping sync", level: .diagnostic)
            return
        }

        isSyncing = true
        lastSyncError = nil

        DebugLogger.shared.log("📤 Starting sync of \(pendingLogs.count) pending logs...", level: .diagnostic)

        let logsToSync = pendingLogs.filter { $0.retryCount < maxRetries }
        var successCount = 0
        var failCount = 0

        for log in logsToSync {
            do {
                try await syncSingleLog(log)
                dequeue(log.id)
                successCount += 1
            } catch {
                markRetry(log.id, error: error.localizedDescription)
                failCount += 1
                DebugLogger.shared.log("❌ Failed to sync log \(log.id): \(error.localizedDescription)", level: .error)
            }
        }

        // Remove logs that exceeded max retries
        let expiredLogs = pendingLogs.filter { $0.retryCount >= maxRetries }
        for log in expiredLogs {
            DebugLogger.shared.log("⚠️ Removing expired log (max retries exceeded): \(log.id)", level: .warning)
            pendingLogs.removeAll { $0.id == log.id }
        }
        saveQueue()

        isSyncing = false

        if failCount > 0 {
            lastSyncError = "Failed to sync \(failCount) log(s)"
        }

        DebugLogger.shared.log("📤 Sync complete: \(successCount) success, \(failCount) failed", level: .success)
    }

    /// Sync a single log to the server
    private func syncSingleLog(_ log: PendingExerciseLog) async throws {
        let supabase = PTSupabaseClient.shared

        let input = CreateExerciseLogInput(
            sessionExerciseId: log.sessionExerciseId,
            patientId: log.patientId,
            actualSets: log.actualSets,
            actualReps: log.actualReps,
            actualLoad: log.actualLoad,
            loadUnit: log.loadUnit,
            rpe: log.rpe,
            painScore: log.painScore,
            notes: log.notes,
            completed: true
        )

        _ = try await supabase.client
            .from("exercise_logs")
            .insert(input)
            .execute()

        DebugLogger.shared.log("✅ Synced exercise log: \(log.id)", level: .success)
    }

    /// Force a manual sync attempt
    func forcSync() async {
        // Check network first
        let isOnline = await PTSupabaseClient.shared.checkNetworkStatus()
        if isOnline {
            await syncPendingLogs()
        } else {
            lastSyncError = "No network connection"
        }
    }

    /// Clear all pending logs (use with caution)
    func clearQueue() {
        pendingLogs = []
        saveQueue()
        DebugLogger.shared.log("🗑️ Cleared offline queue", level: .warning)
    }
}
