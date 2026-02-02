//
//  WorkoutDataProtocol.swift
//  PT Performance Shared
//
//  Shared protocol for workout data access between iOS and watchOS
//  ACP-824: Apple Watch Standalone App
//

import Foundation

// MARK: - Workout Data Provider Protocol

/// Protocol for providing workout data to both iOS and Watch apps
public protocol WorkoutDataProviding {
    /// Fetches today's scheduled workout sessions
    func fetchTodaysSessions() async throws -> [WatchWorkoutSession]

    /// Fetches exercises for a specific session
    func fetchExercises(for sessionId: UUID) async throws -> [WatchExercise]

    /// Logs a completed set for an exercise
    func logSet(_ set: WatchCompletedSet, for exerciseId: UUID) async throws

    /// Marks a workout session as completed
    func completeSession(_ sessionId: UUID) async throws

    /// Fetches any pending sync data (for offline support)
    func fetchPendingLogs() -> [WatchCompletedSet]

    /// Syncs pending logs when connection is available
    func syncPendingLogs() async throws
}

// MARK: - Workout State Protocol

/// Protocol for observing workout state changes
public protocol WorkoutStateObserver: AnyObject {
    func workoutDidStart(_ session: WatchWorkoutSession)
    func exerciseDidComplete(_ exercise: WatchExercise, in session: WatchWorkoutSession)
    func setDidLog(_ set: WatchCompletedSet, for exercise: WatchExercise)
    func restTimerDidComplete()
    func workoutDidComplete(_ session: WatchWorkoutSession)
}

// MARK: - Haptic Feedback Protocol

/// Protocol for providing haptic feedback (platform-specific implementations)
public protocol HapticFeedbackProviding {
    func restIntervalPulse()
    func restComplete()
    func setLogged()
    func workoutComplete()
    func error()
    func warning()
}

// MARK: - Voice Command Protocol

/// Protocol for voice command handling
public protocol VoiceCommandHandling {
    var isListening: Bool { get }
    func startListening() async throws
    func stopListening()
    func processCommand(_ text: String) -> VoiceCommandResult?
}

// MARK: - Offline Queue Protocol

/// Protocol for managing offline data queue
public protocol OfflineQueueManaging {
    associatedtype Item: Codable

    /// Adds an item to the offline queue
    func enqueue(_ item: Item)

    /// Retrieves all queued items
    func getQueuedItems() -> [Item]

    /// Removes an item after successful sync
    func dequeue(_ item: Item)

    /// Clears all items from the queue
    func clearQueue()

    /// Returns the number of items waiting to sync
    var pendingCount: Int { get }
}
