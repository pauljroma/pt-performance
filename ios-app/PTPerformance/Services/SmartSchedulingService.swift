//
//  SmartSchedulingService.swift
//  PTPerformance
//
//  Created for ACP-1034: Smart Scheduling Suggestions
//  AI-powered workout scheduling based on recovery and calendar conflicts
//

import Foundation
import EventKit

/// Service for intelligent workout scheduling suggestions
/// Analyzes recovery data, readiness scores, and calendar conflicts to suggest optimal training times
@MainActor
final class SmartSchedulingService: ObservableObject {

    // MARK: - Singleton

    static let shared = SmartSchedulingService()

    // MARK: - Published Properties

    @Published private(set) var isAnalyzing: Bool = false
    @Published private(set) var lastAnalysisDate: Date?

    // MARK: - Private Properties

    private let readinessService = ReadinessService(client: .shared)
    private let schedulingService = SchedulingService.shared
    private let calendarService = CalendarSyncService.shared
    private let eventStore = EKEventStore()

    // MARK: - Initialization

    private init() {}

    // MARK: - Smart Suggestions

    /// Generate smart scheduling suggestions for the next week
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to analyze (default 7)
    /// - Returns: Array of scheduling suggestions
    func generateSuggestions(for patientId: UUID, days: Int = 7) async throws -> [SchedulingSuggestion] {
        isAnalyzing = true
        defer { isAnalyzing = false }

        // Fetch data concurrently
        async let readinessTrend = readinessService.getReadinessTrend(for: patientId, days: 7)
        async let scheduledSessions = schedulingService.fetchScheduledSessions(for: patientId)
        async let recentReadiness = readinessService.fetchRecentReadiness(for: patientId, limit: 14)

        let trend = try await readinessTrend
        let sessions = try await scheduledSessions
        let readinessHistory = try await recentReadiness

        // Analyze muscle group recovery
        let muscleGroupRecovery = analyzeMuscleGroupRecovery(sessions: sessions)

        // Generate suggestions for next 7 days
        var suggestions: [SchedulingSuggestion] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            // Check if already scheduled
            let existingSessions = sessions.filter { calendar.isDate($0.scheduledDate, inSameDayAs: targetDate) }

            // Skip if already has 2+ sessions
            if existingSessions.count >= 2 {
                continue
            }

            // Predict readiness for this day
            let predictedReadiness = predictReadiness(for: targetDate, history: readinessHistory, trend: trend)

            // Check calendar conflicts
            let hasConflicts = await checkCalendarConflicts(on: targetDate)

            // Determine recommended muscle groups and intensity
            let recommendation = generateRecommendation(
                date: targetDate,
                predictedReadiness: predictedReadiness,
                muscleGroupRecovery: muscleGroupRecovery,
                hasConflicts: hasConflicts
            )

            if let recommendation = recommendation {
                suggestions.append(recommendation)
            }
        }

        lastAnalysisDate = Date()

        // Sort by priority
        return suggestions.sorted { $0.priority > $1.priority }
    }

    /// Get suggestion for today
    /// - Parameter patientId: Patient UUID
    /// - Returns: Today's top suggestion, if available
    func getTodaySuggestion(for patientId: UUID) async throws -> SchedulingSuggestion? {
        let suggestions = try await generateSuggestions(for: patientId, days: 1)
        return suggestions.first
    }

    // MARK: - Best Time to Train

    /// Analyze typical schedule gaps and readiness patterns to suggest best training windows
    /// - Parameter patientId: Patient UUID
    /// - Returns: Array of optimal training time windows
    func analyzeBestTrainingTimes(for patientId: UUID) async throws -> [TrainingTimeWindow] {
        // Fetch scheduled sessions to analyze patterns
        let sessions = try await schedulingService.fetchScheduledSessions(for: patientId)
        let readinessHistory = try await readinessService.fetchRecentReadiness(for: patientId, limit: 30)

        // Analyze time-of-day patterns
        var timeSlots: [Int: TimeSlotAnalysis] = [:] // Hour of day -> analysis

        for session in sessions where session.status == .completed {
            let hour = Calendar.current.component(.hour, from: session.scheduledDateTime)

            if timeSlots[hour] == nil {
                timeSlots[hour] = TimeSlotAnalysis(hour: hour)
            }
            timeSlots[hour]?.completedCount += 1
        }

        // Analyze readiness by day of week
        var dayOfWeekReadiness: [Int: [Double]] = [:]

        for entry in readinessHistory {
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            if let score = entry.readinessScore {
                dayOfWeekReadiness[weekday, default: []].append(score)
            }
        }

        // Calculate average readiness by day
        var dayAverages: [(day: Int, avgReadiness: Double)] = []
        for (day, scores) in dayOfWeekReadiness where !scores.isEmpty {
            let avg = scores.reduce(0, +) / Double(scores.count)
            dayAverages.append((day, avg))
        }

        // Get calendar availability
        let windows = await analyzeCalendarAvailability()

        // Combine insights to generate recommendations
        var recommendations: [TrainingTimeWindow] = []

        // Morning window (6-9 AM)
        if let morningSlot = timeSlots.values.first(where: { $0.hour >= 6 && $0.hour < 9 }) {
            recommendations.append(TrainingTimeWindow(
                timeOfDay: "Early Morning",
                startHour: 6,
                endHour: 9,
                days: dayAverages.filter { $0.avgReadiness >= 70 }.map { SchedulingDayOfWeek(rawValue: $0.day) ?? .monday },
                reason: "Based on your schedule patterns, morning workouts have \(morningSlot.completedCount) completions",
                avgReadiness: dayAverages.first?.avgReadiness ?? 65.0
            ))
        }

        // Midday window (11 AM - 2 PM)
        if windows.contains(where: { $0.hour >= 11 && $0.hour < 14 }) {
            let avgReadiness = dayAverages.map { $0.avgReadiness }.reduce(0, +) / max(Double(dayAverages.count), 1)
            recommendations.append(TrainingTimeWindow(
                timeOfDay: "Midday",
                startHour: 11,
                endHour: 14,
                days: [.monday, .tuesday, .wednesday, .thursday, .friday],
                reason: "You typically have availability during lunch hours",
                avgReadiness: avgReadiness
            ))
        }

        // Evening window (5-8 PM)
        if let eveningSlot = timeSlots.values.first(where: { $0.hour >= 17 && $0.hour < 20 }) {
            recommendations.append(TrainingTimeWindow(
                timeOfDay: "Evening",
                startHour: 17,
                endHour: 20,
                days: dayAverages.filter { $0.avgReadiness >= 60 }.map { SchedulingDayOfWeek(rawValue: $0.day) ?? .monday },
                reason: "Evening sessions show strong completion rate (\(eveningSlot.completedCount) workouts)",
                avgReadiness: dayAverages.first?.avgReadiness ?? 65.0
            ))
        }

        return recommendations.sorted { $0.avgReadiness > $1.avgReadiness }
    }

    // MARK: - Missed Workout Auto-Adjustment

    /// Automatically reschedule missed workouts to the next available optimal day
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - autoApply: Whether to automatically apply the rescheduling (default false)
    /// - Returns: Array of proposed rescheduling actions
    func autoAdjustMissedWorkouts(for patientId: UUID, autoApply: Bool = false) async throws -> [ReschedulingProposal] {
        let sessions = try await schedulingService.fetchScheduledSessions(for: patientId)
        let missedSessions = sessions.filter { $0.isPastDue && $0.status == .scheduled }

        guard !missedSessions.isEmpty else {
            return []
        }

        var proposals: [ReschedulingProposal] = []

        for missedSession in missedSessions {
            // Find next optimal day
            let suggestions = try await generateSuggestions(for: patientId, days: 7)

            // Match suggestion to missed workout type (if we had muscle group info)
            if let bestSuggestion = suggestions.first {
                let proposal = ReschedulingProposal(
                    originalSession: missedSession,
                    suggestedDate: bestSuggestion.date,
                    suggestedTime: bestSuggestion.suggestedTime,
                    reason: "Rescheduled from \(missedSession.formattedDate). \(bestSuggestion.reason)",
                    readinessScore: bestSuggestion.predictedReadiness
                )
                proposals.append(proposal)

                // Auto-apply if requested
                if autoApply {
                    let newDate = Calendar.current.date(bySettingHour: bestSuggestion.suggestedTime.hour,
                                                        minute: bestSuggestion.suggestedTime.minute,
                                                        second: 0,
                                                        of: bestSuggestion.date) ?? bestSuggestion.date

                    _ = try? await schedulingService.rescheduleSession(
                        scheduledSessionId: missedSession.id,
                        newDate: bestSuggestion.date,
                        newTime: newDate
                    )
                }
            }
        }

        return proposals
    }

    // MARK: - Calendar Conflict Detection

    /// Check for calendar conflicts on a specific date
    /// - Parameter date: Date to check
    /// - Returns: True if there are conflicts
    func checkCalendarConflicts(on date: Date) async -> Bool {
        guard calendarService.hasCalendarAccess else {
            return false
        }

        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            return false
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)

        // Consider it a conflict if there are 3+ events (busy day)
        return events.count >= 3
    }

    /// Get detailed calendar conflicts for a date
    /// - Parameter date: Date to check
    /// - Returns: Array of conflicting events
    func getCalendarConflicts(on date: Date) async -> [CalendarConflictInfo] {
        guard calendarService.hasCalendarAccess else {
            return []
        }

        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events.map { event in
            CalendarConflictInfo(
                title: event.title ?? "Event",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay
            )
        }
    }

    // MARK: - Private Helpers

    /// Analyze recovery status by muscle group based on recent sessions
    private func analyzeMuscleGroupRecovery(sessions: [ScheduledSession]) -> [SchedulingMuscleGroup: MuscleGroupRecoveryStatus] {
        // This is a simplified version - in production would need muscle group data from sessions
        // For now, return default recovery states
        var recovery: [SchedulingMuscleGroup: MuscleGroupRecoveryStatus] = [:]

        let calendar = Calendar.current
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()

        for group in SchedulingMuscleGroup.allCases {
            // Simplified logic: assume fresh if no recent sessions
            let recentSessions = sessions.filter { $0.scheduledDate >= twoDaysAgo }

            if recentSessions.isEmpty {
                recovery[group] = .fresh
            } else if sessions.filter({ $0.scheduledDate >= oneDayAgo }).isEmpty {
                recovery[group] = .recovered
            } else {
                recovery[group] = .fatigued
            }
        }

        return recovery
    }

    /// Predict readiness score for a future date
    private func predictReadiness(for date: Date, history: [DailyReadiness], trend: ReadinessTrend) -> Double {
        // Simple prediction based on average + trend
        guard let avgReadiness = trend.statistics.avgReadiness else {
            return 65.0 // Default moderate readiness
        }

        let calendar = Calendar.current
        let daysAhead = calendar.dateComponents([.day], from: Date(), to: date).day ?? 1

        // Trend adjustment diminishes with distance
        let trendFactor = 0.8 / Double(max(daysAhead, 1))
        var prediction = avgReadiness

        // Apply trend if improving/declining
        if let recentScore = history.first?.readinessScore {
            let trendDirection = recentScore - avgReadiness
            prediction += trendDirection * trendFactor
        }

        return max(0, min(100, prediction))
    }

    /// Generate workout recommendation for a specific date
    private func generateRecommendation(
        date: Date,
        predictedReadiness: Double,
        muscleGroupRecovery: [SchedulingMuscleGroup: MuscleGroupRecoveryStatus],
        hasConflicts: Bool
    ) -> SchedulingSuggestion? {
        // Don't suggest if readiness is too low
        guard predictedReadiness >= 50 else {
            return nil
        }

        // Don't suggest if calendar is too busy
        if hasConflicts {
            return nil
        }

        // Find best recovered muscle groups
        let freshGroups = muscleGroupRecovery.filter { $0.value == .fresh || $0.value == .recovered }
            .map { $0.key }
            .sorted { $0.rawValue < $1.rawValue }

        guard let primaryGroup = freshGroups.first else {
            return nil
        }

        // Determine intensity based on readiness
        let intensity: WorkoutIntensity
        if predictedReadiness >= 80 {
            intensity = .high
        } else if predictedReadiness >= 65 {
            intensity = .moderate
        } else {
            intensity = .light
        }

        // Suggest time based on day of week
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7

        let suggestedTime = TimeOfDay(
            hour: isWeekend ? 9 : 17, // 9 AM weekend, 5 PM weekday
            minute: 0
        )

        let priority = calculatePriority(readiness: predictedReadiness, muscleGroupRecovery: muscleGroupRecovery)

        return SchedulingSuggestion(
            date: date,
            muscleGroup: primaryGroup,
            intensity: intensity,
            suggestedTime: suggestedTime,
            predictedReadiness: predictedReadiness,
            reason: "Your \(primaryGroup.displayName) is well-recovered and readiness is predicted at \(Int(predictedReadiness))%",
            priority: priority,
            hasCalendarConflicts: false
        )
    }

    /// Calculate priority score for a suggestion
    private func calculatePriority(readiness: Double, muscleGroupRecovery: [SchedulingMuscleGroup: MuscleGroupRecoveryStatus]) -> Double {
        let readinessFactor = readiness / 100.0
        let freshGroupsCount = Double(muscleGroupRecovery.filter { $0.value == .fresh }.count)
        let recoveryFactor = freshGroupsCount / Double(SchedulingMuscleGroup.allCases.count)

        return (readinessFactor * 0.6) + (recoveryFactor * 0.4)
    }

    /// Analyze calendar availability patterns
    private func analyzeCalendarAvailability() async -> [AvailableHour] {
        // Simplified: return typical availability windows
        return [
            AvailableHour(hour: 6), AvailableHour(hour: 7), AvailableHour(hour: 8),
            AvailableHour(hour: 12), AvailableHour(hour: 13),
            AvailableHour(hour: 17), AvailableHour(hour: 18), AvailableHour(hour: 19)
        ]
    }
}

// MARK: - Supporting Types

/// Scheduling suggestion with AI-powered recommendations
struct SchedulingSuggestion: Identifiable {
    let id = UUID()
    let date: Date
    let muscleGroup: SchedulingMuscleGroup
    let intensity: WorkoutIntensity
    let suggestedTime: TimeOfDay
    let predictedReadiness: Double
    let reason: String
    let priority: Double // 0.0 - 1.0, higher = better
    let hasCalendarConflicts: Bool

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// Muscle group categories for scheduling
enum SchedulingMuscleGroup: String, CaseIterable {
    case upper = "upper"
    case lower = "lower"
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case core = "core"
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        }
    }
}

/// Recovery status for muscle groups
enum MuscleGroupRecoveryStatus {
    case fresh      // 3+ days rest
    case recovered  // 2 days rest
    case adequate   // 1 day rest
    case fatigued   // < 1 day rest
}

/// Workout intensity levels
enum WorkoutIntensity: String {
    case light = "light"
    case moderate = "moderate"
    case high = "high"

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .light:
            return "Light session focusing on technique and movement"
        case .moderate:
            return "Standard training session with normal intensity"
        case .high:
            return "High intensity session - push your limits"
        }
    }
}

/// Time of day representation
struct TimeOfDay {
    let hour: Int
    let minute: Int

    var formatted: String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let minuteStr = String(format: "%02d", minute)
        return "\(displayHour):\(minuteStr) \(period)"
    }
}

/// Training time window recommendation
struct TrainingTimeWindow: Identifiable {
    let id = UUID()
    let timeOfDay: String
    let startHour: Int
    let endHour: Int
    let days: [SchedulingDayOfWeek]
    let reason: String
    let avgReadiness: Double
}

/// Day of week enum for scheduling
enum SchedulingDayOfWeek: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

/// Rescheduling proposal for missed workouts
struct ReschedulingProposal: Identifiable {
    let id = UUID()
    let originalSession: ScheduledSession
    let suggestedDate: Date
    let suggestedTime: TimeOfDay
    let reason: String
    let readinessScore: Double
}

/// Calendar conflict information
struct CalendarConflictInfo: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool

    var timeRange: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

/// Time slot analysis
private struct TimeSlotAnalysis {
    let hour: Int
    var completedCount: Int = 0
}

/// Available hour
private struct AvailableHour {
    let hour: Int
}
