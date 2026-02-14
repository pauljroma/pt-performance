//
//  StreakRecord.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Models for streak records and history
//

import Foundation

// MARK: - Shared Date Formatter

private let _streakDateOnlyFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = TimeZone.current
    return f
}()

// MARK: - Streak Type

/// Types of streaks that can be tracked
enum StreakType: String, Codable, CaseIterable, Identifiable {
    case workout = "workout"
    case armCare = "arm_care"
    case combined = "combined"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .armCare: return "Arm Care"
        case .combined: return "Training"
        }
    }

    var iconName: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .armCare: return "arm.flexed.fill"
        case .combined: return "flame.fill"
        }
    }

    var colorName: String {
        switch self {
        case .workout: return "blue"
        case .armCare: return "orange"
        case .combined: return "red"
        }
    }
}

// MARK: - Streak Record

/// Represents a streak record from the database
struct StreakRecord: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let streakType: StreakType
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let streakStartDate: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case streakStartDate = "streak_start_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle streak_type as string
        let typeString = try container.decode(String.self, forKey: .streakType)
        streakType = StreakType(rawValue: typeString) ?? .combined

        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)

        // Handle date fields that may come as DATE format (YYYY-MM-DD)
        lastActivityDate = try Self.decodeDateField(container: container, forKey: .lastActivityDate)
        streakStartDate = try Self.decodeDateField(container: container, forKey: .streakStartDate)

        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private static func decodeDateField(container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        if let dateString = try? container.decode(String.self, forKey: key) {
            return _streakDateOnlyFormatter.date(from: dateString)
        }
        return try? container.decode(Date.self, forKey: key)
    }

    // MARK: - Computed Properties

    /// Check if streak is at risk (no activity today)
    var isAtRisk: Bool {
        guard let lastDate = lastActivityDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Motivational message based on streak
    var motivationalMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks! Amazing!"
        case 30...59: return "One month! Incredible!"
        case 60...89: return "Two months! Unstoppable!"
        default: return "Legendary consistency!"
        }
    }

    /// Badge level based on longest streak
    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }
}

// MARK: - Streak History

/// Represents daily activity history
struct StreakHistory: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let activityDate: Date
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let sessionId: UUID?
    let manualSessionId: UUID?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case activityDate = "activity_date"
        case workoutCompleted = "workout_completed"
        case armCareCompleted = "arm_care_completed"
        case sessionId = "session_id"
        case manualSessionId = "manual_session_id"
        case notes
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle DATE format
        if let dateString = try? container.decode(String.self, forKey: .activityDate) {
            activityDate = _streakDateOnlyFormatter.date(from: dateString) ?? Date()
        } else {
            activityDate = try container.decode(Date.self, forKey: .activityDate)
        }

        workoutCompleted = try container.decodeIfPresent(Bool.self, forKey: .workoutCompleted) ?? false
        armCareCompleted = try container.decodeIfPresent(Bool.self, forKey: .armCareCompleted) ?? false
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        manualSessionId = try container.decodeIfPresent(UUID.self, forKey: .manualSessionId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// Check if any activity was completed
    var hasAnyActivity: Bool {
        workoutCompleted || armCareCompleted
    }
}

// MARK: - Streak Statistics

/// Comprehensive streak statistics from database function
struct StreakStatistics: Codable, Hashable, Equatable {
    let streakType: String
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let streakStartDate: Date?
    let totalActivityDays: Int
    let thisWeekDays: Int
    let thisMonthDays: Int

    enum CodingKeys: String, CodingKey {
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case streakStartDate = "streak_start_date"
        case totalActivityDays = "total_activity_days"
        case thisWeekDays = "this_week_days"
        case thisMonthDays = "this_month_days"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        streakType = try container.decode(String.self, forKey: .streakType)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalActivityDays = try container.decode(Int.self, forKey: .totalActivityDays)
        thisWeekDays = try container.decode(Int.self, forKey: .thisWeekDays)
        thisMonthDays = try container.decode(Int.self, forKey: .thisMonthDays)

        // Handle DATE format for optional dates
        if let dateString = try? container.decode(String.self, forKey: .lastActivityDate) {
            lastActivityDate = _streakDateOnlyFormatter.date(from: dateString)
        } else {
            lastActivityDate = try? container.decode(Date.self, forKey: .lastActivityDate)
        }

        if let dateString = try? container.decode(String.self, forKey: .streakStartDate) {
            streakStartDate = _streakDateOnlyFormatter.date(from: dateString)
        } else {
            streakStartDate = try? container.decode(Date.self, forKey: .streakStartDate)
        }
    }

    /// Parsed streak type
    var type: StreakType {
        StreakType(rawValue: streakType) ?? .combined
    }
}

// MARK: - Calendar History Entry

/// History entry for calendar view (from RPC function)
struct CalendarHistoryEntry: Codable, Identifiable, Hashable, Equatable {
    var id: Date { activityDate }
    let activityDate: Date
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let hasAnyActivity: Bool
    let sessionId: UUID?
    let manualSessionId: UUID?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case activityDate = "activity_date"
        case workoutCompleted = "workout_completed"
        case armCareCompleted = "arm_care_completed"
        case hasAnyActivity = "has_any_activity"
        case sessionId = "session_id"
        case manualSessionId = "manual_session_id"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle DATE format
        if let dateString = try? container.decode(String.self, forKey: .activityDate) {
            activityDate = _streakDateOnlyFormatter.date(from: dateString) ?? Date()
        } else {
            activityDate = try container.decode(Date.self, forKey: .activityDate)
        }

        workoutCompleted = try container.decodeIfPresent(Bool.self, forKey: .workoutCompleted) ?? false
        armCareCompleted = try container.decodeIfPresent(Bool.self, forKey: .armCareCompleted) ?? false
        hasAnyActivity = try container.decodeIfPresent(Bool.self, forKey: .hasAnyActivity) ?? false
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        manualSessionId = try container.decodeIfPresent(UUID.self, forKey: .manualSessionId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Streak Badge

/// Achievement badges based on streak milestones
enum StreakBadge: Int, CaseIterable {
    case starter = 0      // 0-6 days
    case committed = 7    // 7-13 days
    case dedicated = 14   // 14-29 days
    case champion = 30    // 30-59 days
    case elite = 60       // 60-89 days
    case legend = 90      // 90+ days

    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .committed: return "Committed"
        case .dedicated: return "Dedicated"
        case .champion: return "Champion"
        case .elite: return "Elite"
        case .legend: return "Legend"
        }
    }

    var iconName: String {
        switch self {
        case .starter: return "flame"
        case .committed: return "flame.fill"
        case .dedicated: return "star.fill"
        case .champion: return "crown.fill"
        case .elite: return "trophy.fill"
        case .legend: return "medal.fill"
        }
    }

    var colorName: String {
        switch self {
        case .starter: return "gray"
        case .committed: return "blue"
        case .dedicated: return "green"
        case .champion: return "orange"
        case .elite: return "purple"
        case .legend: return "yellow"
        }
    }

    var minDays: Int {
        rawValue
    }

    var description: String {
        switch self {
        case .starter: return "Just getting started"
        case .committed: return "One week strong!"
        case .dedicated: return "Two weeks of dedication"
        case .champion: return "A full month!"
        case .elite: return "Two months of consistency"
        case .legend: return "Three months of excellence"
        }
    }

    static func badge(for days: Int) -> StreakBadge {
        if days >= 90 { return .legend }
        if days >= 60 { return .elite }
        if days >= 30 { return .champion }
        if days >= 14 { return .dedicated }
        if days >= 7 { return .committed }
        return .starter
    }

    /// Next badge to achieve
    var nextBadge: StreakBadge? {
        switch self {
        case .starter: return .committed
        case .committed: return .dedicated
        case .dedicated: return .champion
        case .champion: return .elite
        case .elite: return .legend
        case .legend: return nil
        }
    }
}

// MARK: - Activity Input

/// Input for recording streak activity
struct StreakActivityInput: Codable {
    let patientId: String
    let activityDate: String
    let workoutCompleted: Bool
    let armCareCompleted: Bool
    let sessionId: String?
    let manualSessionId: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "p_patient_id"
        case activityDate = "p_activity_date"
        case workoutCompleted = "p_workout_completed"
        case armCareCompleted = "p_arm_care_completed"
        case sessionId = "p_session_id"
        case manualSessionId = "p_manual_session_id"
        case notes = "p_notes"
    }
}

// MARK: - ACP-1029: Streak Freeze

/// Represents a streak freeze that can preserve a streak during rest days
struct StreakFreeze: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let earnedAt: Date
    var usedAt: Date?
    var usedForDate: Date?

    /// Whether this freeze has been used
    var isUsed: Bool { usedAt != nil }

    /// Whether this freeze is available to use
    var isAvailable: Bool { !isUsed }

    /// Create a new available freeze
    init(id: UUID = UUID(), earnedAt: Date = Date(), usedAt: Date? = nil, usedForDate: Date? = nil) {
        self.id = id
        self.earnedAt = earnedAt
        self.usedAt = usedAt
        self.usedForDate = usedForDate
    }
}

/// Manages streak freeze inventory for a user
struct StreakFreezeInventory: Codable, Hashable, Equatable {
    var freezes: [StreakFreeze]
    var maxFreezes: Int

    /// Number of available (unused) freezes
    var availableCount: Int {
        freezes.filter { $0.isAvailable }.count
    }

    /// Number of used freezes
    var usedCount: Int {
        freezes.filter { $0.isUsed }.count
    }

    /// Whether the user can earn more freezes
    var canEarnMore: Bool {
        freezes.count < maxFreezes
    }

    /// Get the next available freeze
    var nextAvailable: StreakFreeze? {
        freezes.first { $0.isAvailable }
    }

    init(freezes: [StreakFreeze] = [], maxFreezes: Int = 3) {
        self.freezes = freezes
        self.maxFreezes = maxFreezes
    }

    /// Use a freeze to protect the streak for a given date
    mutating func useFreeze(for date: Date) -> Bool {
        guard let index = freezes.firstIndex(where: { $0.isAvailable }) else { return false }
        freezes[index].usedAt = Date()
        freezes[index].usedForDate = date
        return true
    }

    /// Award a new freeze (earned through milestones or consistency)
    mutating func awardFreeze() -> Bool {
        guard freezes.filter({ $0.isAvailable }).count < maxFreezes else { return false }
        freezes.append(StreakFreeze())
        return true
    }
}

// MARK: - ACP-1029: Streak Freeze Milestones

/// Defines when streak freezes are earned as rewards
enum StreakFreezeReward: CaseIterable {
    case firstWeek       // Earn 1 freeze at 7-day streak
    case twoWeeks        // Earn 1 freeze at 14-day streak
    case oneMonth        // Earn 1 freeze at 30-day streak
    case twoMonths       // Earn 1 freeze at 60-day streak
    case threeMonths     // Earn 1 freeze at 90-day streak
    case hundredDays     // Earn 1 freeze at 100-day streak

    var requiredStreak: Int {
        switch self {
        case .firstWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .twoMonths: return 60
        case .threeMonths: return 90
        case .hundredDays: return 100
        }
    }

    var freezesAwarded: Int { 1 }

    var displayMessage: String {
        switch self {
        case .firstWeek: return "You earned a Streak Shield for reaching 7 days!"
        case .twoWeeks: return "Two weeks strong! Here's a Streak Shield!"
        case .oneMonth: return "One month milestone! Enjoy a Streak Shield!"
        case .twoMonths: return "Two months! You've earned another Streak Shield!"
        case .threeMonths: return "Three months of excellence! Streak Shield earned!"
        case .hundredDays: return "100 days! Legendary! Streak Shield is yours!"
        }
    }

    /// Check if this reward should be given for a particular streak count
    static func reward(for streak: Int) -> StreakFreezeReward? {
        allCases.first { $0.requiredStreak == streak }
    }
}

// MARK: - ACP-1029: Comeback Mechanics

/// Represents a comeback state after a streak break
struct StreakComebackState: Equatable {
    let previousStreak: Int
    let daysSinceLastActivity: Int
    let comebackPhase: ComebackPhase

    /// The motivational message for this comeback state
    var message: String {
        comebackPhase.message(previousStreak: previousStreak)
    }

    /// Reduced daily target during comeback (percentage of normal)
    var targetMultiplier: Double {
        comebackPhase.targetMultiplier
    }

    /// Number of days in the comeback period before returning to normal
    var comebackDuration: Int {
        comebackPhase.comebackDuration
    }
}

/// Phases of comeback after a streak break
enum ComebackPhase: Equatable {
    case fresh          // 1-2 days missed: gentle nudge
    case shortBreak     // 3-5 days missed: encouraging comeback
    case extended       // 6-14 days missed: supportive restart
    case longAbsence    // 15+ days missed: full restart with guidance

    /// Determine the comeback phase based on days since last activity
    static func phase(for daysMissed: Int) -> ComebackPhase {
        switch daysMissed {
        case 1...2: return .fresh
        case 3...5: return .shortBreak
        case 6...14: return .extended
        default: return .longAbsence
        }
    }

    /// Motivational message for the comeback
    func message(previousStreak: Int) -> String {
        switch self {
        case .fresh:
            return "Welcome back! You had a \(previousStreak)-day streak. Let's pick up where you left off!"
        case .shortBreak:
            return "Everyone needs a break! Your \(previousStreak)-day streak shows what you're capable of. Let's build a new one!"
        case .extended:
            if previousStreak >= 30 {
                return "You built an amazing \(previousStreak)-day streak before. That discipline is still in you. Start with something small today!"
            }
            return "Hey, you're back! That's what matters. Start with a quick session and build from there."
        case .longAbsence:
            return "Welcome back to training! No pressure -- start with a light session and we'll ease back in together."
        }
    }

    /// Target multiplier during comeback (lower = easier targets)
    var targetMultiplier: Double {
        switch self {
        case .fresh: return 1.0        // Normal targets
        case .shortBreak: return 0.75  // 75% of normal
        case .extended: return 0.5     // 50% of normal
        case .longAbsence: return 0.25 // 25% of normal
        }
    }

    /// How many days the reduced targets last
    var comebackDuration: Int {
        switch self {
        case .fresh: return 0      // No reduced period
        case .shortBreak: return 3 // 3 days of easier targets
        case .extended: return 5   // 5 days of easier targets
        case .longAbsence: return 7 // 7 days of easier targets
        }
    }

    /// Suggested quick workout duration in minutes
    var suggestedDuration: Int {
        switch self {
        case .fresh: return 15
        case .shortBreak: return 10
        case .extended: return 10
        case .longAbsence: return 5
        }
    }
}

// MARK: - ACP-1029: Streak Flame Level

/// Growing flame icon that upgrades at milestones
enum StreakFlameLevel: Int, CaseIterable, Comparable {
    case spark = 0       // 0 days: tiny spark
    case ember = 3       // 3+ days: small ember
    case flame = 7       // 7+ days: growing flame
    case blaze = 14      // 14+ days: strong blaze
    case inferno = 30    // 30+ days: roaring inferno
    case wildfire = 60   // 60+ days: wildfire
    case supernova = 100 // 100+ days: supernova

    static func < (lhs: StreakFlameLevel, rhs: StreakFlameLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Determine flame level for a given streak count
    static func level(for streak: Int) -> StreakFlameLevel {
        if streak >= 100 { return .supernova }
        if streak >= 60 { return .wildfire }
        if streak >= 30 { return .inferno }
        if streak >= 14 { return .blaze }
        if streak >= 7 { return .flame }
        if streak >= 3 { return .ember }
        return .spark
    }

    /// SF Symbol name for the flame icon at this level
    var iconName: String {
        switch self {
        case .spark: return "sparkle"
        case .ember: return "flame"
        case .flame: return "flame.fill"
        case .blaze: return "flame.fill"
        case .inferno: return "flame.fill"
        case .wildfire: return "flame.fill"
        case .supernova: return "flame.circle.fill"
        }
    }

    /// The size multiplier for the flame icon
    var sizeMultiplier: CGFloat {
        switch self {
        case .spark: return 0.7
        case .ember: return 0.85
        case .flame: return 1.0
        case .blaze: return 1.15
        case .inferno: return 1.3
        case .wildfire: return 1.45
        case .supernova: return 1.6
        }
    }

    /// Display name
    var displayName: String {
        switch self {
        case .spark: return "Spark"
        case .ember: return "Ember"
        case .flame: return "Flame"
        case .blaze: return "Blaze"
        case .inferno: return "Inferno"
        case .wildfire: return "Wildfire"
        case .supernova: return "Supernova"
        }
    }

    /// Number of glow rings around the flame
    var glowRings: Int {
        switch self {
        case .spark: return 0
        case .ember: return 0
        case .flame: return 1
        case .blaze: return 1
        case .inferno: return 2
        case .wildfire: return 2
        case .supernova: return 3
        }
    }

    /// Whether the flame should animate (pulse)
    var shouldAnimate: Bool {
        self >= .flame
    }
}

// MARK: - ACP-1029: Calendar Activity Density

/// Activity density level for color-coded calendar visualization
enum ActivityDensity: Int, Comparable {
    case none = 0        // No activity
    case light = 1       // One type of activity (workout or arm care)
    case moderate = 2    // Both types of activity
    case high = 3        // Both types + additional notes/sessions

    static func < (lhs: ActivityDensity, rhs: ActivityDensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Compute density from a calendar history entry
    static func density(from entry: CalendarHistoryEntry?) -> ActivityDensity {
        guard let entry = entry, entry.hasAnyActivity else { return .none }

        var score = 0
        if entry.workoutCompleted { score += 1 }
        if entry.armCareCompleted { score += 1 }
        if entry.notes != nil && !(entry.notes?.isEmpty ?? true) { score += 1 }

        switch score {
        case 0: return .none
        case 1: return .light
        case 2: return .moderate
        default: return .high
        }
    }

    /// Opacity for the density indicator (used with Modus brand colors)
    var opacity: Double {
        switch self {
        case .none: return 0.05
        case .light: return 0.3
        case .moderate: return 0.6
        case .high: return 1.0
        }
    }
}
