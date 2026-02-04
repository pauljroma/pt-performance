import Foundation

/// ACP-901, ACP-902, ACP-903: Extended Recovery Tracking Service
/// Provides additional functionality for the Recovery Tracking UI including
/// streak calculations, protocol templates, and enhanced statistics
@MainActor
final class RecoveryTrackingService: ObservableObject {
    static let shared = RecoveryTrackingService()

    // MARK: - Published State

    @Published private(set) var weeklyStats: RecoveryWeeklyStats?
    @Published private(set) var monthlyStats: RecoveryMonthlyStats?
    @Published private(set) var streakInfo: RecoveryStreakInfo?
    @Published private(set) var protocolTemplates: [RecoveryProtocolTemplate] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // MARK: - Dependencies

    private let recoveryService: RecoveryService
    private let supabase: PTSupabaseClient

    // MARK: - Initialization

    private init(
        recoveryService: RecoveryService = .shared,
        supabase: PTSupabaseClient = .shared
    ) {
        self.recoveryService = recoveryService
        self.supabase = supabase
        loadProtocolTemplates()
    }

    // MARK: - Statistics Calculation

    /// Calculate weekly recovery statistics
    func calculateWeeklyStats() async -> RecoveryWeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let sessions = recoveryService.sessions.filter { $0.loggedAt >= weekAgo }

        let totalSessions = sessions.count
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let avgDuration = totalSessions > 0 ? totalMinutes / totalSessions : 0

        // Calculate by protocol type
        let byType = Dictionary(grouping: sessions, by: { $0.protocolType })
        let breakdowns = byType.map { type, typeSessions in
            RecoveryTypeStats(
                protocolType: type,
                sessionCount: typeSessions.count,
                totalMinutes: typeSessions.reduce(0) { $0 + $1.durationMinutes },
                avgDuration: typeSessions.isEmpty ? 0 : typeSessions.reduce(0) { $0 + $1.durationMinutes } / typeSessions.count
            )
        }.sorted { $0.sessionCount > $1.sessionCount }

        let favoriteType = breakdowns.first?.protocolType

        // Calculate comparison with previous week
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let previousWeekSessions = recoveryService.sessions.filter {
            $0.loggedAt >= twoWeeksAgo && $0.loggedAt < weekAgo
        }
        let previousWeekMinutes = previousWeekSessions.reduce(0) { $0 + $1.durationMinutes }

        let weekOverWeekChange: Double
        if previousWeekMinutes > 0 {
            weekOverWeekChange = Double(totalMinutes - previousWeekMinutes) / Double(previousWeekMinutes) * 100
        } else {
            weekOverWeekChange = totalMinutes > 0 ? 100 : 0
        }

        let stats = RecoveryWeeklyStats(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            avgDurationMinutes: avgDuration,
            favoriteType: favoriteType,
            byType: breakdowns,
            weekOverWeekChange: weekOverWeekChange
        )

        weeklyStats = stats
        return stats
    }

    /// Calculate monthly recovery statistics
    func calculateMonthlyStats() async -> RecoveryMonthlyStats {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        let sessions = recoveryService.sessions.filter { $0.loggedAt >= monthAgo }

        let totalSessions = sessions.count
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }

        // Group by week
        var weeklyTotals: [Int] = []
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .day, value: -(weekOffset + 1) * 7, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: -weekOffset * 7, to: now) ?? now

            let weekSessions = sessions.filter { $0.loggedAt >= weekStart && $0.loggedAt < weekEnd }
            weeklyTotals.append(weekSessions.reduce(0) { $0 + $1.durationMinutes })
        }

        // Calculate days with recovery
        let daysWithRecovery = Set(sessions.map { calendar.startOfDay(for: $0.loggedAt) }).count

        let stats = RecoveryMonthlyStats(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            daysWithRecovery: daysWithRecovery,
            weeklyMinutesTotals: weeklyTotals.reversed()
        )

        monthlyStats = stats
        return stats
    }

    // MARK: - Streak Calculation

    /// Calculate recovery streak information
    func calculateStreakInfo() async -> RecoveryStreakInfo {
        let calendar = Calendar.current
        let sessions = recoveryService.sessions
        guard !sessions.isEmpty else {
            return RecoveryStreakInfo(currentStreak: 0, longestStreak: 0, hasRecoveredToday: false, streakStartDate: nil)
        }

        // Get unique dates with sessions
        let sessionDates = Set(sessions.map { calendar.startOfDay(for: $0.loggedAt) })
        let sortedDates = sessionDates.sorted(by: >)

        // Check if recovered today
        let today = calendar.startOfDay(for: Date())
        let hasRecoveredToday = sessionDates.contains(today)

        // Calculate current streak
        var currentStreak = 0
        var checkDate = today

        // If hasn't recovered today, start checking from yesterday
        if !hasRecoveredToday {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        while sessionDates.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 1
        var previousDate: Date?

        for date in sortedDates {
            if let previous = previousDate {
                let expectedPrevious = calendar.date(byAdding: .day, value: 1, to: date)
                if expectedPrevious != nil && calendar.isDate(previous, inSameDayAs: expectedPrevious!) {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            }
            previousDate = date
        }
        longestStreak = max(longestStreak, tempStreak)

        // Get streak start date
        var streakStartDate: Date?
        if currentStreak > 0 {
            streakStartDate = calendar.date(byAdding: .day, value: -(currentStreak - 1), to: hasRecoveredToday ? today : calendar.date(byAdding: .day, value: -1, to: today)!)
        }

        let info = RecoveryStreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasRecoveredToday: hasRecoveredToday,
            streakStartDate: streakStartDate
        )

        streakInfo = info
        return info
    }

    // MARK: - Protocol Templates

    /// Load predefined protocol templates
    private func loadProtocolTemplates() {
        protocolTemplates = [
            // Sauna Protocols
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Standard Sauna",
                protocolType: .saunaTraditional,
                suggestedDuration: 15,
                suggestedTemperature: 175,
                description: "Traditional dry sauna session at moderate heat",
                benefits: ["Improved circulation", "Stress relief", "Muscle relaxation"],
                precautions: ["Stay hydrated", "Exit if lightheaded", "Cool down gradually"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Deep Heat Sauna",
                protocolType: .saunaTraditional,
                suggestedDuration: 20,
                suggestedTemperature: 195,
                description: "Intense heat exposure for experienced users",
                benefits: ["Enhanced detoxification", "Heat shock protein activation", "Cardiovascular conditioning"],
                precautions: ["For experienced users only", "Maximum 20 minutes", "Hydrate before and after"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Infrared Sauna",
                protocolType: .saunaInfrared,
                suggestedDuration: 30,
                suggestedTemperature: 135,
                description: "Lower temperature infrared heat therapy",
                benefits: ["Deep tissue relaxation", "Detoxification", "Pain relief"],
                precautions: ["Stay hydrated", "Longer sessions ok", "Cool down gradually"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Steam Room",
                protocolType: .saunaSteam,
                suggestedDuration: 15,
                suggestedTemperature: 115,
                description: "Humid heat therapy for respiratory benefits",
                benefits: ["Respiratory health", "Skin cleansing", "Muscle relaxation"],
                precautions: ["High humidity - exit if uncomfortable", "Stay hydrated", "Shorter sessions recommended"]
            ),

            // Cold Plunge Protocols
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Quick Cold Plunge",
                protocolType: .coldPlunge,
                suggestedDuration: 2,
                suggestedTemperature: 55,
                description: "Short cold exposure for beginners",
                benefits: ["Reduced inflammation", "Mental clarity", "Dopamine boost"],
                precautions: ["Focus on breathing", "Exit if uncomfortable", "Warm up gradually"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Ice Bath",
                protocolType: .iceBath,
                suggestedDuration: 5,
                suggestedTemperature: 39,
                description: "Extended cold exposure for advanced practitioners",
                benefits: ["Enhanced recovery", "Improved cold tolerance", "Immune system boost"],
                precautions: ["Never alone", "Maximum 10 minutes", "Have warm clothes ready"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Cold Shower",
                protocolType: .coldShower,
                suggestedDuration: 3,
                suggestedTemperature: nil,
                description: "Cold shower for daily recovery",
                benefits: ["Increased alertness", "Improved circulation", "Mental resilience"],
                precautions: ["Start warm and finish cold", "Focus on breathing", "1-3 minutes is effective"]
            ),

            // Contrast Therapy Protocols
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Standard Contrast",
                protocolType: .contrast,
                suggestedDuration: 15,
                suggestedTemperature: 175,
                description: "Alternating hot (3 min) and cold (1 min) exposure",
                benefits: ["Enhanced circulation", "Reduced muscle soreness", "Improved recovery"],
                precautions: ["End on cold", "3-4 rounds typical", "Listen to your body"]
            ),
            RecoveryProtocolTemplate(
                id: UUID(),
                name: "Athletic Recovery Contrast",
                protocolType: .contrast,
                suggestedDuration: 20,
                suggestedTemperature: 185,
                description: "Extended contrast therapy for post-workout recovery",
                benefits: ["Faster recovery", "Reduced DOMS", "Performance optimization"],
                precautions: ["Wait 1 hour after workout", "4-5 rounds recommended", "Hydrate throughout"]
            )
        ]
    }

    /// Get templates for a specific protocol type
    func templates(for type: RecoveryProtocolType) -> [RecoveryProtocolTemplate] {
        protocolTemplates.filter { $0.protocolType == type }
    }

    // MARK: - Session Analytics

    /// Get sessions for a specific date range
    func sessions(from startDate: Date, to endDate: Date) -> [RecoverySession] {
        recoveryService.sessions.filter {
            $0.loggedAt >= startDate && $0.loggedAt <= endDate
        }
    }

    /// Get sessions grouped by day for a date range
    func sessionsByDay(from startDate: Date, to endDate: Date) -> [Date: [RecoverySession]] {
        let calendar = Calendar.current
        let filteredSessions = sessions(from: startDate, to: endDate)

        return Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.loggedAt)
        }
    }

    /// Calculate average session duration by protocol type
    func averageDuration(for type: RecoveryProtocolType) -> Int {
        let typeSessions = recoveryService.sessions.filter { $0.protocolType == type }
        guard !typeSessions.isEmpty else { return 0 }
        return typeSessions.reduce(0) { $0 + $1.durationMinutes } / typeSessions.count
    }

    /// Get optimal recovery recommendations based on session history
    func generateOptimalSchedule() -> [RecoveryRecommendation] {
        var recommendations: [RecoveryRecommendation] = []

        // Analyze which protocols work best (most frequently used + positive feedback)
        let sessionsByType = Dictionary(grouping: recoveryService.sessions, by: { $0.protocolType })
        let sortedTypes = sessionsByType.sorted { $0.value.count > $1.value.count }

        for (index, (type, sessions)) in sortedTypes.prefix(3).enumerated() {
            let avgDuration = sessions.isEmpty ? type.defaultDuration : sessions.reduce(0) { $0 + $1.durationMinutes } / sessions.count

            let priority: RecoveryPriority
            switch index {
            case 0: priority = .high
            case 1: priority = .medium
            default: priority = .low
            }

            recommendations.append(RecoveryRecommendation(
                id: UUID(),
                protocolType: type,
                reason: "Based on your \(sessions.count) previous \(type.displayName.lowercased()) sessions",
                priority: priority,
                suggestedDuration: avgDuration
            ))
        }

        // Add variety recommendation if user only does one type
        if sortedTypes.count == 1 {
            let unusedTypes = RecoveryProtocolType.allCases.filter { $0 != sortedTypes.first?.key }
            if let suggestedType = unusedTypes.randomElement() {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(),
                    protocolType: suggestedType,
                    reason: "Try adding variety to your recovery routine",
                    priority: .low,
                    suggestedDuration: suggestedType.defaultDuration
                ))
            }
        }

        return recommendations
    }
}

// MARK: - Supporting Types

struct RecoveryWeeklyStats {
    let totalSessions: Int
    let totalMinutes: Int
    let avgDurationMinutes: Int
    let favoriteType: RecoveryProtocolType?
    let byType: [RecoveryTypeStats]
    let weekOverWeekChange: Double // Percentage change
}

struct RecoveryMonthlyStats {
    let totalSessions: Int
    let totalMinutes: Int
    let daysWithRecovery: Int
    let weeklyMinutesTotals: [Int]
}

struct RecoveryTypeStats {
    let protocolType: RecoveryProtocolType
    let sessionCount: Int
    let totalMinutes: Int
    let avgDuration: Int
}

struct RecoveryStreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let hasRecoveredToday: Bool
    let streakStartDate: Date?
}

struct RecoveryProtocolTemplate: Identifiable {
    let id: UUID
    let name: String
    let protocolType: RecoveryProtocolType
    let suggestedDuration: Int // minutes
    let suggestedTemperature: Double? // Fahrenheit
    let description: String
    let benefits: [String]
    let precautions: [String]
}

// MARK: - RecoveryProtocolType Extension

extension RecoveryProtocolType {
    var defaultDuration: Int {
        switch self {
        case .saunaTraditional: return 15
        case .saunaInfrared: return 30
        case .saunaSteam: return 15
        case .coldPlunge: return 3
        case .coldShower: return 3
        case .iceBath: return 5
        case .contrast: return 15
        }
    }

    var defaultTemperature: Double? {
        switch self {
        case .saunaTraditional: return 175
        case .saunaInfrared: return 135
        case .saunaSteam: return 115
        case .coldPlunge: return 50
        case .coldShower: return nil
        case .iceBath: return 39
        case .contrast: return 175
        }
    }
}
