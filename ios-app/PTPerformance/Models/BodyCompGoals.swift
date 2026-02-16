//
//  BodyCompGoals.swift
//  PTPerformance
//
//  Body Composition Goals model for goal setting and progress tracking
//

import SwiftUI

// MARK: - Body Comp Goal Status

/// Status of a body composition goal
enum BodyCompGoalStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case achieved
    case paused
    case cancelled
    case unknown = "unknown"

    /// Custom decoder that falls back to `.unknown` for unrecognized values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .achieved: return "Achieved"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .active: return "target"
        case .achieved: return "checkmark.seal.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .active: return .blue
        case .achieved: return .green
        case .paused: return .orange
        case .cancelled: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - Goal Progress Status

/// Indicates whether the user is on track, ahead, or behind their goal
enum GoalProgressStatus: String, Codable {
    case onTrack
    case ahead
    case behind
    case achieved

    var displayName: String {
        switch self {
        case .onTrack: return "On Track"
        case .ahead: return "Ahead"
        case .behind: return "Behind"
        case .achieved: return "Achieved"
        }
    }

    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle"
        case .ahead: return "arrow.up.circle.fill"
        case .behind: return "exclamationmark.triangle"
        case .achieved: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .onTrack: return .blue
        case .ahead: return .green
        case .behind: return .orange
        case .achieved: return .yellow
        }
    }
}

// MARK: - Body Comp Goals Model

/// Represents a body composition goal from the body_comp_goals table
struct BodyCompGoals: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID

    // Target values (nullable - user may not set all)
    let targetWeight: Double?
    let targetBodyFatPercentage: Double?
    let targetMuscleMass: Double?
    let targetBmi: Double?

    // Starting values (captured when goal is set)
    let startingWeight: Double?
    let startingBodyFatPercentage: Double?
    let startingMuscleMass: Double?

    // Timeline
    let targetDate: Date?
    let startedAt: Date

    // Status
    let status: BodyCompGoalStatus
    let achievedAt: Date?

    // Metadata
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case targetWeight = "target_weight"
        case targetBodyFatPercentage = "target_body_fat_percentage"
        case targetMuscleMass = "target_muscle_mass"
        case targetBmi = "target_bmi"
        case startingWeight = "starting_weight"
        case startingBodyFatPercentage = "starting_body_fat_percentage"
        case startingMuscleMass = "starting_muscle_mass"
        case targetDate = "target_date"
        case startedAt = "started_at"
        case status
        case achievedAt = "achieved_at"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoder to handle PostgreSQL numeric types and dates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle numeric fields that might come as strings from PostgreSQL
        targetWeight = try Self.decodeOptionalDouble(container: container, forKey: .targetWeight)
        targetBodyFatPercentage = try Self.decodeOptionalDouble(container: container, forKey: .targetBodyFatPercentage)
        targetMuscleMass = try Self.decodeOptionalDouble(container: container, forKey: .targetMuscleMass)
        targetBmi = try Self.decodeOptionalDouble(container: container, forKey: .targetBmi)
        startingWeight = try Self.decodeOptionalDouble(container: container, forKey: .startingWeight)
        startingBodyFatPercentage = try Self.decodeOptionalDouble(container: container, forKey: .startingBodyFatPercentage)
        startingMuscleMass = try Self.decodeOptionalDouble(container: container, forKey: .startingMuscleMass)

        // Handle DATE type (YYYY-MM-DD format)
        if let dateString = try? container.decode(String.self, forKey: .targetDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            targetDate = dateFormatter.date(from: dateString)
        } else {
            targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        }

        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        status = try container.decodeIfPresent(BodyCompGoalStatus.self, forKey: .status) ?? .unknown
        achievedAt = try container.decodeIfPresent(Date.self, forKey: .achievedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // Helper to decode optional Double that might be a String
    private static func decodeOptionalDouble(
        container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Double? {
        if let stringValue = try? container.decode(String.self, forKey: key) {
            return Double(stringValue)
        }
        return try container.decodeIfPresent(Double.self, forKey: key)
    }

    // Memberwise initializer for testing/preview
    init(
        id: UUID = UUID(),
        patientId: UUID,
        targetWeight: Double? = nil,
        targetBodyFatPercentage: Double? = nil,
        targetMuscleMass: Double? = nil,
        targetBmi: Double? = nil,
        startingWeight: Double? = nil,
        startingBodyFatPercentage: Double? = nil,
        startingMuscleMass: Double? = nil,
        targetDate: Date? = nil,
        startedAt: Date = Date(),
        status: BodyCompGoalStatus = .active,
        achievedAt: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.targetWeight = targetWeight
        self.targetBodyFatPercentage = targetBodyFatPercentage
        self.targetMuscleMass = targetMuscleMass
        self.targetBmi = targetBmi
        self.startingWeight = startingWeight
        self.startingBodyFatPercentage = startingBodyFatPercentage
        self.startingMuscleMass = startingMuscleMass
        self.targetDate = targetDate
        self.startedAt = startedAt
        self.status = status
        self.achievedAt = achievedAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Days remaining until target date
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(0, components.day ?? 0)
    }

    /// Weeks remaining until target date
    var weeksRemaining: Int? {
        guard let days = daysRemaining else { return nil }
        return max(1, days / 7)
    }

    /// Whether the goal has expired (target date passed)
    var isExpired: Bool {
        guard let targetDate = targetDate else { return false }
        return targetDate < Date()
    }

    /// Formatted target date string
    var formattedTargetDate: String {
        guard let date = targetDate else { return "No target date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formatted start date string
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startedAt)
    }

    /// Formatted target weight string
    var targetWeightText: String {
        guard let weight = targetWeight else { return "--" }
        return String(format: "%.1f lbs", weight)
    }

    /// Formatted target body fat string
    var targetBodyFatText: String {
        guard let bf = targetBodyFatPercentage else { return "--" }
        return String(format: "%.1f%%", bf)
    }

    /// Formatted target muscle mass string
    var targetMuscleMassText: String {
        guard let mm = targetMuscleMass else { return "--" }
        return String(format: "%.1f lbs", mm)
    }

    /// Check if the goal has any targets set
    var hasTargets: Bool {
        targetWeight != nil ||
        targetBodyFatPercentage != nil ||
        targetMuscleMass != nil ||
        targetBmi != nil
    }
}

// MARK: - Progress Calculation Extension

extension BodyCompGoals {
    /// Calculate weight progress (0.0 to 1.0, can exceed 1.0 if goal surpassed)
    func weightProgress(current: Double?) -> Double {
        guard let current = current,
              let start = startingWeight,
              let target = targetWeight,
              target != start else { return 0 }

        let totalChange = target - start
        let currentChange = current - start
        return currentChange / totalChange
    }

    /// Calculate body fat progress (0.0 to 1.0, can exceed 1.0 if goal surpassed)
    func bodyFatProgress(current: Double?) -> Double {
        guard let current = current,
              let start = startingBodyFatPercentage,
              let target = targetBodyFatPercentage,
              target != start else { return 0 }

        let totalChange = target - start
        let currentChange = current - start
        return currentChange / totalChange
    }

    /// Calculate muscle mass progress (0.0 to 1.0, can exceed 1.0 if goal surpassed)
    func muscleMassProgress(current: Double?) -> Double {
        guard let current = current,
              let start = startingMuscleMass,
              let target = targetMuscleMass,
              target != start else { return 0 }

        let totalChange = target - start
        let currentChange = current - start
        return currentChange / totalChange
    }

    /// Calculate weekly weight change needed to reach goal
    func weeklyWeightChangeNeeded(current: Double?) -> Double? {
        guard let current = current,
              let target = targetWeight,
              let weeks = weeksRemaining,
              weeks > 0 else { return nil }

        return (target - current) / Double(weeks)
    }

    /// Calculate weekly body fat change needed to reach goal
    func weeklyBodyFatChangeNeeded(current: Double?) -> Double? {
        guard let current = current,
              let target = targetBodyFatPercentage,
              let weeks = weeksRemaining,
              weeks > 0 else { return nil }

        return (target - current) / Double(weeks)
    }

    /// Determine overall progress status based on expected vs actual progress
    func progressStatus(currentWeight: Double?, currentBodyFat: Double?) -> GoalProgressStatus {
        // Check if achieved
        var achievedCount = 0
        var totalGoals = 0

        if let target = targetWeight, let current = currentWeight {
            totalGoals += 1
            let isLossGoal = (startingWeight ?? current) > target
            if isLossGoal && current <= target {
                achievedCount += 1
            } else if !isLossGoal && current >= target {
                achievedCount += 1
            }
        }

        if let target = targetBodyFatPercentage, let current = currentBodyFat {
            totalGoals += 1
            let isLossGoal = (startingBodyFatPercentage ?? current) > target
            if isLossGoal && current <= target {
                achievedCount += 1
            } else if !isLossGoal && current >= target {
                achievedCount += 1
            }
        }

        if totalGoals > 0 && achievedCount == totalGoals {
            return .achieved
        }

        // Calculate expected progress based on time elapsed
        guard let targetDate = targetDate else { return .onTrack }
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: startedAt, to: targetDate).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        let expectedProgress = min(1.0, Double(elapsedDays) / Double(max(1, totalDays)))

        // Check weight progress
        if let current = currentWeight, startingWeight != nil {
            let actualProgress = weightProgress(current: current)
            if actualProgress > expectedProgress + 0.1 {
                return .ahead
            } else if actualProgress < expectedProgress - 0.1 {
                return .behind
            }
        }

        return .onTrack
    }
}

// MARK: - Body Comp Goal Progress

/// Progress data from vw_body_comp_goal_progress view
struct BodyCompGoalProgress: Codable, Identifiable, Hashable, Equatable {
    var id: UUID { goalId }

    let goalId: UUID
    let patientId: UUID

    // Targets
    let targetWeight: Double?
    let targetBodyFatPercentage: Double?
    let targetMuscleMass: Double?

    // Starting values
    let startingWeight: Double?
    let startingBodyFatPercentage: Double?
    let startingMuscleMass: Double?

    // Current values (from latest body composition measurement)
    let currentWeight: Double?
    let currentBodyFat: Double?
    let currentMuscleMass: Double?
    let lastMeasured: Date?

    // Progress percentages (0-100)
    let weightProgressPct: Double?
    let bodyFatProgressPct: Double?
    let muscleMassProgressPct: Double?

    // Goal metadata
    let targetDate: Date?
    let status: String
    let startedAt: Date
    let notes: String?
    let daysRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case patientId = "patient_id"
        case targetWeight = "target_weight"
        case targetBodyFatPercentage = "target_body_fat_percentage"
        case targetMuscleMass = "target_muscle_mass"
        case startingWeight = "starting_weight"
        case startingBodyFatPercentage = "starting_body_fat_percentage"
        case startingMuscleMass = "starting_muscle_mass"
        case currentWeight = "current_weight"
        case currentBodyFat = "current_body_fat"
        case currentMuscleMass = "current_muscle_mass"
        case lastMeasured = "last_measured"
        case weightProgressPct = "weight_progress_pct"
        case bodyFatProgressPct = "body_fat_progress_pct"
        case muscleMassProgressPct = "muscle_mass_progress_pct"
        case targetDate = "target_date"
        case status
        case startedAt = "started_at"
        case notes
        case daysRemaining = "days_remaining"
    }

    // Custom decoder to handle PostgreSQL numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        goalId = try container.decode(UUID.self, forKey: .goalId)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle numeric fields that might come as strings
        targetWeight = try Self.decodeOptionalDouble(container: container, forKey: .targetWeight)
        targetBodyFatPercentage = try Self.decodeOptionalDouble(container: container, forKey: .targetBodyFatPercentage)
        targetMuscleMass = try Self.decodeOptionalDouble(container: container, forKey: .targetMuscleMass)
        startingWeight = try Self.decodeOptionalDouble(container: container, forKey: .startingWeight)
        startingBodyFatPercentage = try Self.decodeOptionalDouble(container: container, forKey: .startingBodyFatPercentage)
        startingMuscleMass = try Self.decodeOptionalDouble(container: container, forKey: .startingMuscleMass)
        currentWeight = try Self.decodeOptionalDouble(container: container, forKey: .currentWeight)
        currentBodyFat = try Self.decodeOptionalDouble(container: container, forKey: .currentBodyFat)
        currentMuscleMass = try Self.decodeOptionalDouble(container: container, forKey: .currentMuscleMass)
        weightProgressPct = try Self.decodeOptionalDouble(container: container, forKey: .weightProgressPct)
        bodyFatProgressPct = try Self.decodeOptionalDouble(container: container, forKey: .bodyFatProgressPct)
        muscleMassProgressPct = try Self.decodeOptionalDouble(container: container, forKey: .muscleMassProgressPct)

        lastMeasured = try container.decodeIfPresent(Date.self, forKey: .lastMeasured)

        // Handle DATE type
        if let dateString = try? container.decode(String.self, forKey: .targetDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            targetDate = dateFormatter.date(from: dateString)
        } else {
            targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        }

        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        daysRemaining = try container.decodeIfPresent(Int.self, forKey: .daysRemaining)
    }

    // Helper to decode optional Double that might be a String
    private static func decodeOptionalDouble(
        container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Double? {
        if let stringValue = try? container.decode(String.self, forKey: key) {
            return Double(stringValue)
        }
        return try container.decodeIfPresent(Double.self, forKey: key)
    }

    // Memberwise initializer for testing/preview
    init(
        goalId: UUID = UUID(),
        patientId: UUID,
        targetWeight: Double? = nil,
        targetBodyFatPercentage: Double? = nil,
        targetMuscleMass: Double? = nil,
        startingWeight: Double? = nil,
        startingBodyFatPercentage: Double? = nil,
        startingMuscleMass: Double? = nil,
        currentWeight: Double? = nil,
        currentBodyFat: Double? = nil,
        currentMuscleMass: Double? = nil,
        lastMeasured: Date? = nil,
        weightProgressPct: Double? = nil,
        bodyFatProgressPct: Double? = nil,
        muscleMassProgressPct: Double? = nil,
        targetDate: Date? = nil,
        status: String = "active",
        startedAt: Date = Date(),
        notes: String? = nil,
        daysRemaining: Int? = nil
    ) {
        self.goalId = goalId
        self.patientId = patientId
        self.targetWeight = targetWeight
        self.targetBodyFatPercentage = targetBodyFatPercentage
        self.targetMuscleMass = targetMuscleMass
        self.startingWeight = startingWeight
        self.startingBodyFatPercentage = startingBodyFatPercentage
        self.startingMuscleMass = startingMuscleMass
        self.currentWeight = currentWeight
        self.currentBodyFat = currentBodyFat
        self.currentMuscleMass = currentMuscleMass
        self.lastMeasured = lastMeasured
        self.weightProgressPct = weightProgressPct
        self.bodyFatProgressPct = bodyFatProgressPct
        self.muscleMassProgressPct = muscleMassProgressPct
        self.targetDate = targetDate
        self.status = status
        self.startedAt = startedAt
        self.notes = notes
        self.daysRemaining = daysRemaining
    }

    // MARK: - Display Properties

    /// Overall progress as an average of all tracked metrics
    var overallProgress: Double? {
        var progressValues: [Double] = []

        if let wp = weightProgressPct { progressValues.append(wp) }
        if let bp = bodyFatProgressPct { progressValues.append(bp) }
        if let mp = muscleMassProgressPct { progressValues.append(mp) }

        guard !progressValues.isEmpty else { return nil }
        return progressValues.reduce(0, +) / Double(progressValues.count)
    }

    /// Formatted last measured date
    var lastMeasuredText: String {
        guard let date = lastMeasured else { return "No measurements" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Color for progress indicator
    func progressColor(for percentage: Double?) -> Color {
        guard let pct = percentage else { return .gray }
        switch pct {
        case 0..<25: return .red
        case 25..<50: return .orange
        case 50..<75: return .yellow
        case 75..<100: return .blue
        default: return .green
        }
    }
}

// MARK: - Insert DTO

/// Data transfer object for creating new body composition goals
struct CreateBodyCompGoalInput: Codable {
    let patientId: UUID
    let targetWeight: Double?
    let targetBodyFatPercentage: Double?
    let targetMuscleMass: Double?
    let targetBmi: Double?
    let startingWeight: Double?
    let startingBodyFatPercentage: Double?
    let startingMuscleMass: Double?
    let targetDate: String?  // Format: YYYY-MM-DD
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case targetWeight = "target_weight"
        case targetBodyFatPercentage = "target_body_fat_percentage"
        case targetMuscleMass = "target_muscle_mass"
        case targetBmi = "target_bmi"
        case startingWeight = "starting_weight"
        case startingBodyFatPercentage = "starting_body_fat_percentage"
        case startingMuscleMass = "starting_muscle_mass"
        case targetDate = "target_date"
        case notes
    }
}

// MARK: - Update DTO

/// Data transfer object for updating body composition goals
struct UpdateBodyCompGoalInput: Codable {
    var targetWeight: Double?
    var targetBodyFatPercentage: Double?
    var targetMuscleMass: Double?
    var targetBmi: Double?
    var targetDate: String?  // Format: YYYY-MM-DD
    var status: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case targetWeight = "target_weight"
        case targetBodyFatPercentage = "target_body_fat_percentage"
        case targetMuscleMass = "target_muscle_mass"
        case targetBmi = "target_bmi"
        case targetDate = "target_date"
        case status
        case notes
    }
}
