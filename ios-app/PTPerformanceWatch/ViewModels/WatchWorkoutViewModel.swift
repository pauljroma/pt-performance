//
//  WatchWorkoutViewModel.swift
//  PTPerformanceWatch
//
//  View model for Watch workout management
//  ACP-824: Apple Watch Standalone App
//

import Foundation
import Combine

/// Main view model for Watch workout functionality
@MainActor
class WatchWorkoutViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var todaysSessions: [WatchWorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentSession: WatchWorkoutSession?

    // MARK: - Private Properties

    private let sessionManager = WatchSessionManager.shared
    private let storage = WatchWorkoutStorage.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupBindings()
        loadCachedSessions()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Listen for workout data from iPhone
        sessionManager.onWorkoutDataReceived = { [weak self] session in
            Task { @MainActor in
                self?.handleReceivedSession(session)
            }
        }

        sessionManager.onSyncCompleted = { [weak self] in
            Task { @MainActor in
                self?.markPendingSetsAsSynced()
            }
        }
    }

    private func loadCachedSessions() {
        todaysSessions = storage.loadTodaysSessions()
    }

    // MARK: - Data Loading

    func loadTodaysSessions() async {
        isLoading = true
        errorMessage = nil

        // Load from cache first
        todaysSessions = storage.loadTodaysSessions()

        // Request fresh data from iPhone if available
        if sessionManager.isReachable {
            sessionManager.requestSync()
        } else {
            // Use sample data for standalone testing
            if todaysSessions.isEmpty {
                todaysSessions = createSampleSessions()
                storage.saveTodaysSessions(todaysSessions)
            }
        }

        isLoading = false
    }

    func refreshSessions() async {
        if sessionManager.isReachable {
            isLoading = true
            sessionManager.requestSync()
            // Wait a bit for response
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        } else {
            errorMessage = "iPhone not connected"
        }
    }

    // MARK: - Session Management

    private func handleReceivedSession(_ session: WatchWorkoutSession) {
        // Update or add the session
        if let index = todaysSessions.firstIndex(where: { $0.id == session.id }) {
            todaysSessions[index] = session
        } else {
            todaysSessions.append(session)
        }

        // Sort by scheduled time
        todaysSessions.sort { $0.scheduledTime < $1.scheduledTime }

        // Save to cache
        storage.saveTodaysSessions(todaysSessions)
    }

    // MARK: - Set Logging

    func logSet(_ set: WatchCompletedSet, for exerciseId: UUID, in sessionId: UUID) async {
        // Find and update the local session
        guard let sessionIndex = todaysSessions.firstIndex(where: { $0.id == sessionId }),
              let exerciseIndex = todaysSessions[sessionIndex].exercises.firstIndex(where: { $0.id == exerciseId }) else {
            return
        }

        // Add the completed set locally
        todaysSessions[sessionIndex].exercises[exerciseIndex].completedSets.append(set)

        // Save to local storage
        storage.saveTodaysSessions(todaysSessions)

        // Queue for sync with iPhone
        storage.queueSetForSync(set, exerciseId: exerciseId, sessionId: sessionId)

        // Send to iPhone if connected
        sessionManager.sendLoggedSet(set, exerciseId: exerciseId, sessionId: sessionId)
    }

    func completeSession(_ sessionId: UUID) async {
        guard let index = todaysSessions.firstIndex(where: { $0.id == sessionId }) else {
            return
        }

        // Update status
        var updatedSession = todaysSessions[index]
        updatedSession = WatchWorkoutSession(
            id: updatedSession.id,
            sessionId: updatedSession.sessionId,
            name: updatedSession.name,
            scheduledDate: updatedSession.scheduledDate,
            scheduledTime: updatedSession.scheduledTime,
            status: .completed,
            exercises: updatedSession.exercises
        )

        todaysSessions[index] = updatedSession

        // Save to storage
        storage.saveTodaysSessions(todaysSessions)

        // Notify iPhone
        sessionManager.sendWorkoutCompleted(sessionId)
    }

    private func markPendingSetsAsSynced() {
        storage.clearSyncQueue()
    }

    // MARK: - Sample Data

    private func createSampleSessions() -> [WatchWorkoutSession] {
        [
            WatchWorkoutSession(
                id: UUID(),
                sessionId: UUID(),
                name: "Upper Body Strength",
                scheduledDate: Date(),
                scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(),
                status: .scheduled,
                exercises: [
                    WatchExercise(
                        id: UUID(),
                        templateId: UUID(),
                        name: "Bench Press",
                        prescribedSets: 3,
                        prescribedReps: "8-10",
                        prescribedLoad: 135,
                        loadUnit: "lbs",
                        restSeconds: 90,
                        completedSets: [],
                        sequence: 1
                    ),
                    WatchExercise(
                        id: UUID(),
                        templateId: UUID(),
                        name: "Incline DB Press",
                        prescribedSets: 3,
                        prescribedReps: "10-12",
                        prescribedLoad: 50,
                        loadUnit: "lbs",
                        restSeconds: 60,
                        completedSets: [],
                        sequence: 2
                    ),
                    WatchExercise(
                        id: UUID(),
                        templateId: UUID(),
                        name: "Cable Flyes",
                        prescribedSets: 3,
                        prescribedReps: "12-15",
                        prescribedLoad: 30,
                        loadUnit: "lbs",
                        restSeconds: 45,
                        completedSets: [],
                        sequence: 3
                    ),
                    WatchExercise(
                        id: UUID(),
                        templateId: UUID(),
                        name: "Tricep Pushdowns",
                        prescribedSets: 3,
                        prescribedReps: "12-15",
                        prescribedLoad: 40,
                        loadUnit: "lbs",
                        restSeconds: 45,
                        completedSets: [],
                        sequence: 4
                    )
                ]
            )
        ]
    }
}

// MARK: - Watch Workout Storage

class WatchWorkoutStorage {
    static let shared = WatchWorkoutStorage()

    private let sessionsKey = "PTPerformance.WatchSessions"
    private let syncQueueKey = "PTPerformance.WatchSyncQueue"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Sessions

    func saveTodaysSessions(_ sessions: [WatchWorkoutSession]) {
        do {
            let data = try encoder.encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
        } catch {
            #if DEBUG
            print("Failed to save sessions: \(error.localizedDescription)")
            #endif
        }
    }

    func loadTodaysSessions() -> [WatchWorkoutSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            return []
        }

        do {
            let sessions = try decoder.decode([WatchWorkoutSession].self, from: data)
            // Filter to only today's sessions
            return sessions.filter { Calendar.current.isDateInToday($0.scheduledDate) }
        } catch {
            #if DEBUG
            print("Failed to load sessions: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Sync Queue

    func queueSetForSync(_ set: WatchCompletedSet, exerciseId: UUID, sessionId: UUID) {
        var queue = loadSyncQueue()
        let item = SyncQueueItem(set: set, exerciseId: exerciseId, sessionId: sessionId)
        queue.append(item)
        saveSyncQueue(queue)
    }

    func loadSyncQueue() -> [SyncQueueItem] {
        guard let data = UserDefaults.standard.data(forKey: syncQueueKey) else {
            return []
        }

        do {
            return try decoder.decode([SyncQueueItem].self, from: data)
        } catch {
            return []
        }
    }

    func saveSyncQueue(_ queue: [SyncQueueItem]) {
        do {
            let data = try encoder.encode(queue)
            UserDefaults.standard.set(data, forKey: syncQueueKey)
        } catch {
            #if DEBUG
            print("Failed to save sync queue: \(error.localizedDescription)")
            #endif
        }
    }

    func clearSyncQueue() {
        UserDefaults.standard.removeObject(forKey: syncQueueKey)
    }
}

// MARK: - Sync Queue Item

struct SyncQueueItem: Codable {
    let set: WatchCompletedSet
    let exerciseId: UUID
    let sessionId: UUID
    let queuedAt: Date

    init(set: WatchCompletedSet, exerciseId: UUID, sessionId: UUID) {
        self.set = set
        self.exerciseId = exerciseId
        self.sessionId = sessionId
        self.queuedAt = Date()
    }
}
