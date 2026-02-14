//
//  SharedWorkoutModels.swift
//  Modus Shared
//
//  Shared models between iOS and watchOS targets
//  ACP-824: Apple Watch Standalone App
//

import Foundation

// MARK: - Watch Workout Session

/// Lightweight workout session for Watch app
/// Contains only essential data needed for workout execution
public struct WatchWorkoutSession: Codable, Identifiable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let name: String
    public let scheduledDate: Date
    public let scheduledTime: Date
    public let status: WatchSessionStatus
    public var exercises: [WatchExercise]

    public init(
        id: UUID,
        sessionId: UUID,
        name: String,
        scheduledDate: Date,
        scheduledTime: Date,
        status: WatchSessionStatus,
        exercises: [WatchExercise]
    ) {
        self.id = id
        self.sessionId = sessionId
        self.name = name
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.status = status
        self.exercises = exercises
    }

    public var isToday: Bool {
        Calendar.current.isDateInToday(scheduledDate)
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }

    public var totalExercises: Int {
        exercises.count
    }

    public var completedExercises: Int {
        exercises.filter { $0.isCompleted }.count
    }

    public var progressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercises) / Double(totalExercises)
    }
}

// MARK: - Watch Session Status

public enum WatchSessionStatus: String, Codable {
    case scheduled
    case inProgress = "in_progress"
    case completed
    case cancelled

    public var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Watch Exercise

/// Lightweight exercise model for Watch app
public struct WatchExercise: Codable, Identifiable, Hashable {
    public let id: UUID
    public let templateId: UUID
    public let name: String
    public let prescribedSets: Int
    public let prescribedReps: String
    public let prescribedLoad: Double?
    public let loadUnit: String?
    public let restSeconds: Int
    public var completedSets: [WatchCompletedSet]
    public let sequence: Int

    public init(
        id: UUID,
        templateId: UUID,
        name: String,
        prescribedSets: Int,
        prescribedReps: String,
        prescribedLoad: Double?,
        loadUnit: String?,
        restSeconds: Int,
        completedSets: [WatchCompletedSet],
        sequence: Int
    ) {
        self.id = id
        self.templateId = templateId
        self.name = name
        self.prescribedSets = prescribedSets
        self.prescribedReps = prescribedReps
        self.prescribedLoad = prescribedLoad
        self.loadUnit = loadUnit
        self.restSeconds = restSeconds
        self.completedSets = completedSets
        self.sequence = sequence
    }

    public var isCompleted: Bool {
        completedSets.count >= prescribedSets
    }

    public var currentSetNumber: Int {
        min(completedSets.count + 1, prescribedSets)
    }

    public var setsRemaining: Int {
        max(0, prescribedSets - completedSets.count)
    }

    public var loadDisplay: String {
        if let load = prescribedLoad, let unit = loadUnit {
            return "\(Int(load)) \(unit)"
        }
        return "BW"
    }

    public var prescriptionDisplay: String {
        "\(prescribedSets) x \(prescribedReps)"
    }
}

// MARK: - Watch Completed Set

/// Represents a completed set logged on the Watch
public struct WatchCompletedSet: Codable, Identifiable, Hashable {
    public let id: UUID
    public let setNumber: Int
    public let reps: Int
    public let weight: Double?
    public let rpe: Int?
    public let completedAt: Date
    public var synced: Bool

    public init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int,
        weight: Double?,
        rpe: Int?,
        completedAt: Date = Date(),
        synced: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.completedAt = completedAt
        self.synced = synced
    }
}

// MARK: - Voice Command Result

/// Result of parsing a voice command for set logging
public struct VoiceCommandResult: Codable {
    public let reps: Int?
    public let weight: Double?
    public let sets: Int?
    public let rpe: Int?
    public let rawText: String
    public let confidence: Double

    public init(
        reps: Int?,
        weight: Double?,
        sets: Int?,
        rpe: Int?,
        rawText: String,
        confidence: Double
    ) {
        self.reps = reps
        self.weight = weight
        self.sets = sets
        self.rpe = rpe
        self.rawText = rawText
        self.confidence = confidence
    }

    public var isValid: Bool {
        reps != nil || weight != nil || sets != nil
    }

    public var summary: String {
        var parts: [String] = []
        if let sets = sets {
            parts.append("\(sets) sets")
        }
        if let reps = reps {
            parts.append("\(reps) reps")
        }
        if let weight = weight {
            parts.append("\(Int(weight)) lbs")
        }
        if let rpe = rpe {
            parts.append("RPE \(rpe)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Sync Message Types

/// Message types for Watch-iPhone communication
public enum WatchSyncMessageType: String, Codable {
    case workoutData = "workout_data"
    case setLogged = "set_logged"
    case workoutCompleted = "workout_completed"
    case requestSync = "request_sync"
    case syncAcknowledged = "sync_acknowledged"
}

/// Wrapper for sync messages between Watch and iPhone
public struct WatchSyncMessage: Codable {
    public let type: WatchSyncMessageType
    public let payload: Data
    public let timestamp: Date

    public init(type: WatchSyncMessageType, payload: Data, timestamp: Date = Date()) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
    }
}
