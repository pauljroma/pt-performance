import Foundation

// MARK: - Fasting Protocol

/// Fasting protocol template (matches fasting_protocols table)
struct FastingProtocol: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let fastingType: FastingType
    let fastingHours: Int
    let eatingHours: Int
    let description: String?
    let benefits: [String]?
    let difficulty: FastingDifficulty
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fastingType = "fasting_type"
        case fastingHours = "fasting_hours"
        case eatingHours = "eating_hours"
        case description
        case benefits
        case difficulty
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Formatted display string for the protocol
    var formattedSchedule: String {
        "\(fastingHours):\(eatingHours)"
    }
}

/// Difficulty level for fasting protocols
enum FastingDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case expert

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

// MARK: - Fasting Streak

/// Fasting streak tracking (matches fasting_streaks table)
struct FastingStreak: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var totalFasts: Int
    var totalHoursFasted: Double
    var lastFastDate: Date?
    var streakStartDate: Date?
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalFasts = "total_fasts"
        case totalHoursFasted = "total_hours_fasted"
        case lastFastDate = "last_fast_date"
        case streakStartDate = "streak_start_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Average fast duration in hours
    var averageFastDuration: Double {
        guard totalFasts > 0 else { return 0 }
        return totalHoursFasted / Double(totalFasts)
    }

    /// Whether the streak is at risk (no fast in last 36 hours)
    var isStreakAtRisk: Bool {
        guard let lastDate = lastFastDate else { return currentStreak > 0 }
        let hoursSinceLast = Date().timeIntervalSince(lastDate) / 3600
        return hoursSinceLast > 36 && currentStreak > 0
    }

    /// Days since last fast
    var daysSinceLastFast: Int? {
        guard let lastDate = lastFastDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}

// MARK: - Fasting Goal

/// Fasting goals (matches fasting_goals table)
struct FastingGoal: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    var weeklyFastTarget: Int // Number of fasts per week
    var targetHoursPerFast: Int
    var preferredProtocol: FastingType?
    var targetStreak: Int?
    var notes: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case weeklyFastTarget = "weekly_fast_target"
        case targetHoursPerFast = "target_hours_per_fast"
        case preferredProtocol = "preferred_protocol"
        case targetStreak = "target_streak"
        case notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Weekly Stats

/// Weekly fasting statistics
struct FastingWeeklyStats: Codable, Hashable {
    let weekStartDate: Date
    let totalFasts: Int
    let completedFasts: Int
    let totalHoursFasted: Double
    let averageFastDuration: Double
    let longestFast: Double
    let shortestFast: Double
    let complianceRate: Double // 0.0 - 1.0
    let fastsPerDay: [Date: Int]

    enum CodingKeys: String, CodingKey {
        case weekStartDate = "week_start_date"
        case totalFasts = "total_fasts"
        case completedFasts = "completed_fasts"
        case totalHoursFasted = "total_hours_fasted"
        case averageFastDuration = "average_fast_duration"
        case longestFast = "longest_fast"
        case shortestFast = "shortest_fast"
        case complianceRate = "compliance_rate"
        case fastsPerDay = "fasts_per_day"
    }

    /// Formatted compliance percentage
    var formattedCompliance: String {
        "\(Int(complianceRate * 100))%"
    }

    /// Whether compliance is meeting goal (80%+)
    var isOnTrack: Bool {
        complianceRate >= 0.8
    }

    /// Creates empty stats for a given week
    static func empty(weekStartDate: Date = Date()) -> FastingWeeklyStats {
        FastingWeeklyStats(
            weekStartDate: weekStartDate,
            totalFasts: 0,
            completedFasts: 0,
            totalHoursFasted: 0,
            averageFastDuration: 0,
            longestFast: 0,
            shortestFast: 0,
            complianceRate: 0,
            fastsPerDay: [:]
        )
    }
}

// MARK: - Fasting Phase

/// Current phase of a fast
enum FastingPhase: String, Codable {
    case fed = "fed"
    case earlyFast = "early_fast" // 0-4 hours
    case fatBurning = "fat_burning" // 4-16 hours
    case ketosis = "ketosis" // 16-24 hours
    case deepKetosis = "deep_ketosis" // 24-48 hours
    case autophagy = "autophagy" // 48+ hours

    var displayName: String {
        switch self {
        case .fed: return "Fed State"
        case .earlyFast: return "Early Fast"
        case .fatBurning: return "Fat Burning"
        case .ketosis: return "Ketosis"
        case .deepKetosis: return "Deep Ketosis"
        case .autophagy: return "Autophagy"
        }
    }

    var description: String {
        switch self {
        case .fed: return "Digesting recent meal"
        case .earlyFast: return "Insulin levels normalizing"
        case .fatBurning: return "Body switching to fat for fuel"
        case .ketosis: return "Producing ketones for energy"
        case .deepKetosis: return "Significant ketone production"
        case .autophagy: return "Cellular cleanup and repair"
        }
    }

    var icon: String {
        switch self {
        case .fed: return "fork.knife"
        case .earlyFast: return "hourglass.bottomhalf.filled"
        case .fatBurning: return "flame"
        case .ketosis: return "bolt.fill"
        case .deepKetosis: return "bolt.circle.fill"
        case .autophagy: return "sparkles"
        }
    }

    /// Determine phase from hours fasted
    static func fromHours(_ hours: Double) -> FastingPhase {
        switch hours {
        case ..<0.5: return .fed
        case 0.5..<4: return .earlyFast
        case 4..<16: return .fatBurning
        case 16..<24: return .ketosis
        case 24..<48: return .deepKetosis
        default: return .autophagy
        }
    }
}

// MARK: - Fast Completion Result

/// Result of ending a fast
struct FastCompletionResult: Codable {
    let fastId: UUID
    let wasCompleted: Bool
    let actualHours: Double
    let targetHours: Int
    let streakUpdated: Bool
    let newStreakCount: Int?
    let isPersonalBest: Bool

    enum CodingKeys: String, CodingKey {
        case fastId = "fast_id"
        case wasCompleted = "was_completed"
        case actualHours = "actual_hours"
        case targetHours = "target_hours"
        case streakUpdated = "streak_updated"
        case newStreakCount = "new_streak_count"
        case isPersonalBest = "is_personal_best"
    }

    /// Percentage of target achieved
    var completionPercentage: Double {
        min(actualHours / Double(targetHours), 1.0)
    }
}

// MARK: - Extended FastingLog Properties

extension FastingLog {
    /// Hours elapsed since fast started
    var elapsedHours: Double {
        let reference = endedAt ?? Date()
        return reference.timeIntervalSince(startedAt) / 3600
    }

    /// Hours remaining until target is reached
    var remainingHours: Double {
        max(0, Double(targetHours) - elapsedHours)
    }

    /// Formatted elapsed time string
    var formattedElapsed: String {
        let hours = Int(elapsedHours)
        let minutes = Int((elapsedHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    /// Whether the fast reached its target duration
    var reachedTarget: Bool {
        elapsedHours >= Double(targetHours)
    }

    /// Current fasting phase
    var currentPhase: FastingPhase {
        FastingPhase.fromHours(elapsedHours)
    }
}

// MARK: - Extended EatingWindowRecommendation Properties

extension EatingWindowRecommendation {
    /// Duration of eating window in hours
    var windowDuration: Double {
        suggestedEnd.timeIntervalSince(suggestedStart) / 3600
    }

    /// Formatted eating window string
    var formattedWindow: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: suggestedStart)) - \(formatter.string(from: suggestedEnd))"
    }
}

// MARK: - Extended FastingType Properties

extension FastingType {
    /// Icon for the fasting type
    var icon: String {
        switch self {
        case .intermittent: return "clock"
        case .extended: return "clock.badge.checkmark"
        case .waterOnly: return "drop.fill"
        case .modified: return "fork.knife.circle"
        case .custom: return "slider.horizontal.3"
        }
    }

    /// Detailed description of the fasting protocol
    var protocolDescription: String {
        switch self {
        case .intermittent: return "Daily time-restricted eating with 16-20 hour fasts"
        case .extended: return "Extended fast of 24+ hours"
        case .waterOnly: return "Water-only fast with no caloric intake"
        case .modified: return "Modified fast allowing limited calories (e.g., 500 cal)"
        case .custom: return "Custom fasting schedule"
        }
    }

    /// Difficulty level for the fasting type
    var difficulty: FastingDifficulty {
        switch self {
        case .intermittent: return .beginner
        case .modified: return .intermediate
        case .extended: return .advanced
        case .waterOnly: return .expert
        case .custom: return .intermediate
        }
    }
}
