import Foundation

/// Represents a single exercise item within a block
struct BlockItem: Codable, Identifiable, Hashable {
    let id: UUID
    let blockId: UUID
    let exerciseId: UUID
    let exerciseName: String
    let orderIndex: Int
    let prescribedSets: Int
    let prescribedReps: String // Can be "8", "8-12", "AMRAP", etc.
    let prescribedLoad: Double? // In lbs or kg
    let prescribedRPE: Int? // 1-10 scale
    let restSeconds: Int?
    let tempo: String? // e.g., "3-1-1-0"
    let notes: String?
    var completedSets: [CompletedSet]
    var isCompleted: Bool
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case blockId = "block_id"
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case orderIndex = "order_index"
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case prescribedRPE = "prescribed_rpe"
        case restSeconds = "rest_seconds"
        case tempo
        case notes
        case completedSets = "completed_sets"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
    }

    init(id: UUID = UUID(), blockId: UUID, exerciseId: UUID, exerciseName: String, orderIndex: Int, prescribedSets: Int, prescribedReps: String, prescribedLoad: Double? = nil, prescribedRPE: Int? = nil, restSeconds: Int? = nil, tempo: String? = nil, notes: String? = nil, completedSets: [CompletedSet] = [], isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.blockId = blockId
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.prescribedSets = prescribedSets
        self.prescribedReps = prescribedReps
        self.prescribedLoad = prescribedLoad
        self.prescribedRPE = prescribedRPE
        self.restSeconds = restSeconds
        self.tempo = tempo
        self.notes = notes
        self.completedSets = completedSets
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard prescribedSets > 0 else { return 0.0 }
        return Double(completedSets.count) / Double(prescribedSets)
    }

    /// Estimated time in minutes (sets × rest period)
    var estimatedTimeMinutes: Int {
        let restMinutes = (restSeconds ?? 60) * prescribedSets / 60
        return max(1, restMinutes / 60)
    }

    /// Check if any completed sets have pain flags
    var hasPainFlags: Bool {
        completedSets.contains { $0.painLevel != nil && $0.painLevel! > 0 }
    }

    /// Get average RPE across completed sets
    var averageRPE: Double? {
        let rpeValues = completedSets.compactMap { $0.actualRPE }
        guard !rpeValues.isEmpty else { return nil }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }

    /// Get total volume (sets × reps × load)
    var totalVolume: Double? {
        guard let load = prescribedLoad else { return nil }
        let totalReps = completedSets.reduce(0) { $0 + $1.actualReps }
        return Double(totalReps) * load
    }

    /// Complete all sets as prescribed (1-tap completion)
    mutating func completeAsPrescribed() {
        completedSets = []
        let reps = Int(prescribedReps) ?? 0 // Parse simple rep schemes

        for setNumber in 1...prescribedSets {
            let set = CompletedSet(
                setNumber: setNumber,
                actualReps: reps,
                actualLoad: prescribedLoad,
                actualRPE: prescribedRPE,
                painLevel: nil,
                painLocation: nil,
                completedAt: Date()
            )
            completedSets.append(set)
        }

        isCompleted = true
        completedAt = Date()
    }

    /// Quick adjust load by delta (e.g., +5 or -5 lbs)
    mutating func adjustLoad(by delta: Double) {
        guard let currentLoad = prescribedLoad else { return }
        // Apply to last completed set or create new adjustment
        if var lastSet = completedSets.last {
            lastSet.actualLoad = (lastSet.actualLoad ?? currentLoad) + delta
            completedSets[completedSets.count - 1] = lastSet
        }
    }

    /// Quick adjust reps by delta (e.g., +1 or -1)
    mutating func adjustReps(by delta: Int) {
        // Apply to last completed set
        if var lastSet = completedSets.last {
            lastSet.actualReps = max(0, lastSet.actualReps + delta)
            completedSets[completedSets.count - 1] = lastSet
        }
    }
}

// MARK: - Completed Set

/// Represents a completed set within a block item
struct CompletedSet: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let setNumber: Int
    var actualReps: Int
    var actualLoad: Double?
    var actualRPE: Int? // 1-10 scale
    var painLevel: Int? // 0-10 scale
    var painLocation: String?
    let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case setNumber = "set_number"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case actualRPE = "actual_rpe"
        case painLevel = "pain_level"
        case painLocation = "pain_location"
        case completedAt = "completed_at"
    }

    init(id: UUID = UUID(), setNumber: Int, actualReps: Int, actualLoad: Double? = nil, actualRPE: Int? = nil, painLevel: Int? = nil, painLocation: String? = nil, completedAt: Date) {
        self.id = id
        self.setNumber = setNumber
        self.actualReps = actualReps
        self.actualLoad = actualLoad
        self.actualRPE = actualRPE
        self.painLevel = painLevel
        self.painLocation = painLocation
        self.completedAt = completedAt
    }

    /// Check if this set has a pain flag
    var hasPainFlag: Bool {
        return painLevel != nil && painLevel! > 0
    }

    /// Format load for display
    var formattedLoad: String? {
        guard let load = actualLoad else { return nil }
        return String(format: "%.1f lbs", load)
    }
}
