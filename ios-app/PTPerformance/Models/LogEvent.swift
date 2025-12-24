import Foundation

/// Log event model conforming to ptos.events.v1 schema
/// Represents workout events emitted throughout the training session
struct LogEvent: Codable, Identifiable, Equatable {
    // MARK: - Properties

    let id: UUID
    let eventType: EventType
    let patientId: UUID
    let sessionId: UUID?
    let exerciseId: UUID?
    let blockNumber: Int?
    let timestamp: Date
    let metadata: [String: String]?

    // MARK: - Event Types

    enum EventType: String, Codable {
        case blockCompleted = "block_completed"
        case painReported = "pain_reported"
        case readinessCheckIn = "readiness_check_in"
        case sessionStarted = "session_started"
        case sessionCompleted = "session_completed"
        case exerciseStarted = "exercise_started"
        case exerciseCompleted = "exercise_completed"
        case workloadFlagged = "workload_flagged"
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case patientId = "patient_id"
        case sessionId = "session_id"
        case exerciseId = "exercise_id"
        case blockNumber = "block_number"
        case timestamp
        case metadata
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        eventType: EventType,
        patientId: UUID,
        sessionId: UUID? = nil,
        exerciseId: UUID? = nil,
        blockNumber: Int? = nil,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.patientId = patientId
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.blockNumber = blockNumber
        self.timestamp = timestamp
        self.metadata = metadata
    }

    // MARK: - Factory Methods

    /// Create a block completion event
    static func blockCompleted(
        patientId: UUID,
        sessionId: UUID,
        blockNumber: Int,
        exerciseId: UUID? = nil,
        metadata: [String: String]? = nil
    ) -> LogEvent {
        LogEvent(
            eventType: .blockCompleted,
            patientId: patientId,
            sessionId: sessionId,
            exerciseId: exerciseId,
            blockNumber: blockNumber,
            metadata: metadata
        )
    }

    /// Create a pain reported event
    static func painReported(
        patientId: UUID,
        sessionId: UUID?,
        painLevel: Int,
        location: String? = nil,
        metadata: [String: String]? = nil
    ) -> LogEvent {
        var eventMetadata = metadata ?? [:]
        eventMetadata["pain_level"] = String(painLevel)
        if let location = location {
            eventMetadata["location"] = location
        }

        return LogEvent(
            eventType: .painReported,
            patientId: patientId,
            sessionId: sessionId,
            metadata: eventMetadata
        )
    }

    /// Create a readiness check-in event
    static func readinessCheckIn(
        patientId: UUID,
        readinessScore: Double,
        hrv: Double? = nil,
        sleepHours: Double? = nil,
        metadata: [String: String]? = nil
    ) -> LogEvent {
        var eventMetadata = metadata ?? [:]
        eventMetadata["readiness_score"] = String(format: "%.2f", readinessScore)
        if let hrv = hrv {
            eventMetadata["hrv"] = String(format: "%.2f", hrv)
        }
        if let sleepHours = sleepHours {
            eventMetadata["sleep_hours"] = String(format: "%.2f", sleepHours)
        }

        return LogEvent(
            eventType: .readinessCheckIn,
            patientId: patientId,
            metadata: eventMetadata
        )
    }

    // MARK: - Equatable

    static func == (lhs: LogEvent, rhs: LogEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Database Mapping

extension LogEvent {
    /// Convert to dictionary for Supabase insertion
    func toDatabaseDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "event_type": eventType.rawValue,
            "patient_id": patientId.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]

        if let sessionId = sessionId {
            dict["session_id"] = sessionId.uuidString
        }

        if let exerciseId = exerciseId {
            dict["exercise_id"] = exerciseId.uuidString
        }

        if let blockNumber = blockNumber {
            dict["block_number"] = blockNumber
        }

        if let metadata = metadata, !metadata.isEmpty {
            // Convert metadata dict to JSON string or JSONB
            if let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                dict["metadata"] = jsonString
            }
        }

        return dict
    }
}

// MARK: - Event Validation

extension LogEvent {
    /// Validate event data before emission
    var isValid: Bool {
        // Basic validation rules
        switch eventType {
        case .blockCompleted:
            return sessionId != nil && blockNumber != nil
        case .painReported:
            return metadata?["pain_level"] != nil
        case .readinessCheckIn:
            return metadata?["readiness_score"] != nil
        default:
            return true
        }
    }

    /// Get human-readable description of the event
    var description: String {
        switch eventType {
        case .blockCompleted:
            return "Block \(blockNumber ?? 0) completed"
        case .painReported:
            if let painLevel = metadata?["pain_level"] {
                return "Pain reported (level: \(painLevel))"
            }
            return "Pain reported"
        case .readinessCheckIn:
            if let score = metadata?["readiness_score"] {
                return "Readiness check-in (score: \(score))"
            }
            return "Readiness check-in"
        case .sessionStarted:
            return "Session started"
        case .sessionCompleted:
            return "Session completed"
        case .exerciseStarted:
            return "Exercise started"
        case .exerciseCompleted:
            return "Exercise completed"
        case .workloadFlagged:
            return "Workload flagged"
        }
    }
}
