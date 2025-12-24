import Foundation

/// Represents a training session with block-based structure
struct Session: Codable, Identifiable, Hashable {
    let id: UUID
    let patientId: UUID
    let programId: UUID?
    let scheduledFor: Date?
    let startedAt: Date?
    var completedAt: Date?
    let title: String
    let sessionType: SessionType
    var blocks: [Block]
    var isCompleted: Bool
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programId = "program_id"
        case scheduledFor = "scheduled_for"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case title
        case sessionType = "session_type"
        case blocks
        case isCompleted = "is_completed"
        case notes
    }

    init(id: UUID = UUID(), patientId: UUID, programId: UUID? = nil, scheduledFor: Date? = nil, startedAt: Date? = nil, completedAt: Date? = nil, title: String, sessionType: SessionType, blocks: [Block] = [], isCompleted: Bool = false, notes: String? = nil) {
        self.id = id
        self.patientId = patientId
        self.programId = programId
        self.scheduledFor = scheduledFor
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.title = title
        self.sessionType = sessionType
        self.blocks = blocks
        self.isCompleted = isCompleted
        self.notes = notes
    }

    /// Overall session progress (0.0 to 1.0)
    var progress: Double {
        guard !blocks.isEmpty else { return 0.0 }
        let totalProgress = blocks.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(blocks.count)
    }

    /// Quick metrics calculated from blocks
    var quickMetrics: QuickMetrics {
        QuickMetrics.from(blocks: blocks)
    }

    /// Total estimated duration in minutes
    var estimatedDurationMinutes: Int {
        blocks.reduce(0) { $0 + $1.estimatedTimeMinutes }
    }

    /// Actual duration if session is in progress or completed
    var actualDuration: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = completedAt ?? Date()
        return end.timeIntervalSince(start)
    }

    /// Check if session is in progress
    var isInProgress: Bool {
        return startedAt != nil && completedAt == nil
    }

    /// Check if session has pain flags
    var hasPainFlags: Bool {
        blocks.contains { $0.hasPainFlags }
    }

    /// Get next incomplete block
    var nextIncompleteBlock: Block? {
        blocks.first { !$0.isCompleted }
    }

    /// Start the session
    mutating func start() {
        guard startedAt == nil else { return }
        startedAt = Date()
    }

    /// Complete the session
    mutating func complete() {
        completedAt = Date()
        isCompleted = true
    }
}

// MARK: - Session Type

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case strength = "strength"
    case hypertrophy = "hypertrophy"
    case power = "power"
    case endurance = "endurance"
    case mobility = "mobility"
    case recovery = "recovery"
    case assessment = "assessment"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Hypertrophy"
        case .power: return "Power"
        case .endurance: return "Endurance"
        case .mobility: return "Mobility"
        case .recovery: return "Recovery"
        case .assessment: return "Assessment"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .power: return "bolt.fill"
        case .endurance: return "figure.run"
        case .mobility: return "figure.flexibility"
        case .recovery: return "heart.fill"
        case .assessment: return "list.clipboard.fill"
        }
    }

    var color: String {
        switch self {
        case .strength: return "blue"
        case .hypertrophy: return "purple"
        case .power: return "orange"
        case .endurance: return "red"
        case .mobility: return "green"
        case .recovery: return "cyan"
        case .assessment: return "gray"
        }
    }
}
