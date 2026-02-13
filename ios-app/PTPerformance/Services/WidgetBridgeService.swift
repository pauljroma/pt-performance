//
//  WidgetBridgeService.swift
//  PTPerformance
//
//  Service that bridges main app data to widgets via SharedDataStore.
//  Fetches data from existing services, converts to lightweight widget models,
//  and triggers widget refresh via WidgetCenter.
//

import Foundation
import WidgetKit

/// Service responsible for pushing app data to widgets via SharedDataStore.
///
/// This service runs in the main app and coordinates data flow to widget extensions.
/// It fetches data from existing services (ReadinessService, SchedulingService, etc.),
/// converts it to lightweight widget models, and persists via SharedDataStore.
///
/// ## Usage
/// ```swift
/// // Refresh all widgets on app active
/// await WidgetBridgeService.shared.refreshAllWidgetData()
///
/// // Refresh specific widget after user action
/// await WidgetBridgeService.shared.refreshReadinessWidget()
/// ```
@MainActor
final class WidgetBridgeService {

    // MARK: - Singleton

    static let shared = WidgetBridgeService()

    // MARK: - Dependencies

    private let sharedDataStore = SharedDataStore.shared
    private let readinessService: ReadinessService
    private let schedulingService: SchedulingService
    private let fatigueService: FatigueTrackingService
    private let supabaseClient: PTSupabaseClient

    // MARK: - Initialization

    private init() {
        self.readinessService = ReadinessService()
        self.schedulingService = SchedulingService.shared
        self.fatigueService = FatigueTrackingService.shared
        self.supabaseClient = PTSupabaseClient.shared
    }

    // MARK: - Public API

    /// Refresh all widget data at once.
    ///
    /// Call this method when the app becomes active or after significant data changes.
    /// Fetches all widget data in parallel and updates SharedDataStore.
    func refreshAllWidgetData() async {
        guard let patientId = currentPatientId else {
            DebugLogger.shared.log("[WidgetBridge] No patient ID available, skipping widget refresh", level: .diagnostic)
            return
        }

        // Save user ID for widgets to access
        sharedDataStore.saveUserId(patientId.uuidString)

        // Fetch all data in parallel
        async let readiness = fetchReadinessData(for: patientId)
        async let workout = fetchWorkoutData(for: patientId)
        async let adherence = fetchAdherenceData(for: patientId)
        async let streak = fetchStreakData(for: patientId)
        async let weekTrend = fetchWeekTrendData(for: patientId)

        // Update SharedDataStore with all fetched data
        let (readinessResult, workoutResult, adherenceResult, streakResult, weekTrendResult) = await (
            readiness, workout, adherence, streak, weekTrend
        )

        sharedDataStore.updateAllWidgetData(
            readiness: readinessResult,
            workout: workoutResult,
            adherence: adherenceResult,
            streak: streakResult,
            weekTrend: weekTrendResult
        )

        DebugLogger.shared.log("[WidgetBridge] All widget data refreshed successfully", level: .success)
    }

    /// Refresh readiness widget data.
    ///
    /// Call this method after a readiness check-in is completed.
    func refreshReadinessWidget() async {
        guard let patientId = currentPatientId else { return }

        if let readiness = await fetchReadinessData(for: patientId) {
            sharedDataStore.saveReadiness(readiness)
            sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.readiness)
        }

        // Also update week trend for recovery dashboard
        if let weekTrend = await fetchWeekTrendData(for: patientId) {
            sharedDataStore.saveWeekTrend(weekTrend)
            sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.recoveryDashboard)
        }
    }

    /// Refresh workout widget data.
    ///
    /// Call this method after session state changes (scheduled, started, completed).
    func refreshWorkoutWidget() async {
        guard let patientId = currentPatientId else { return }

        if let workout = await fetchWorkoutData(for: patientId) {
            sharedDataStore.saveWorkout(workout)
            sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.todayWorkout)
        }
    }

    /// Refresh adherence widget data.
    ///
    /// Call this method after a session is completed or skipped.
    func refreshAdherenceWidget() async {
        guard let patientId = currentPatientId else { return }

        if let adherence = await fetchAdherenceData(for: patientId) {
            sharedDataStore.saveAdherence(adherence)
            sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.weekOverview)
        }
    }

    /// Refresh streak widget data.
    ///
    /// Call this method after a session is completed.
    func refreshStreakWidget() async {
        guard let patientId = currentPatientId else { return }

        if let streak = await fetchStreakData(for: patientId) {
            sharedDataStore.saveStreak(streak)
            sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.streak)
        }
    }

    /// Clear all widget data on logout.
    ///
    /// Call this method when the user logs out to clear sensitive data from widgets.
    func clearWidgetData() {
        sharedDataStore.clearAllData()

        DebugLogger.shared.log("[WidgetBridge] Widget data cleared", level: .diagnostic)
    }

    // MARK: - Private Helpers

    /// Current patient ID from Supabase client.
    private var currentPatientId: UUID? {
        guard let userIdString = supabaseClient.userId else { return nil }
        return UUID(uuidString: userIdString)
    }

    // MARK: - Data Fetching

    /// Fetch and convert readiness data to widget model.
    private func fetchReadinessData(for patientId: UUID) async -> WidgetReadiness? {
        do {
            // Fetch today's readiness and recent readiness in parallel
            async let todayTask = readinessService.getTodayReadiness(for: patientId)
            async let recentTask = readinessService.fetchRecentReadiness(for: patientId, limit: 1)

            // Try to get today's readiness first
            if let todayReadiness = try await todayTask {
                return convertToWidgetReadiness(todayReadiness)
            }

            // If no readiness today, try to get the most recent one
            let recent = try await recentTask
            if let latest = recent.first {
                return convertToWidgetReadiness(latest)
            }

            return nil
        } catch {
            DebugLogger.shared.log("[WidgetBridge] Error fetching readiness: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Convert DailyReadiness to WidgetReadiness.
    private func convertToWidgetReadiness(_ readiness: DailyReadiness) -> WidgetReadiness {
        let score = Int(readiness.readinessScore ?? 50)
        let band = readiness.readinessBand.rawValue

        return WidgetReadiness(
            score: score,
            band: band,
            hrv: nil, // HRV not stored in DailyReadiness
            sleepHours: readiness.sleepHours,
            restingHR: nil, // Resting HR not stored in DailyReadiness
            date: readiness.date,
            lastUpdated: Date()
        )
    }

    /// Fetch and convert workout data to widget model.
    private func fetchWorkoutData(for patientId: UUID) async -> WidgetWorkout? {
        do {
            // Fetch today's scheduled sessions
            let sessions = try await schedulingService.fetchUpcomingSessions(for: patientId, days: 1)

            // Filter for today's sessions
            let calendar = Calendar.current
            let todaySessions = sessions.filter { session in
                calendar.isDateInToday(session.scheduledDate)
            }

            // If no session today, check if it's a rest day
            if todaySessions.isEmpty {
                return WidgetWorkout.restDay
            }

            // Find the most relevant session (in progress > scheduled > completed)
            let sortedSessions = todaySessions.sorted { session1, session2 in
                // Prioritize by status
                let priority1 = statusPriority(session1.status)
                let priority2 = statusPriority(session2.status)
                if priority1 != priority2 {
                    return priority1 > priority2
                }
                // Then by time
                return session1.scheduledTime < session2.scheduledTime
            }

            guard let primarySession = sortedSessions.first else {
                return WidgetWorkout.restDay
            }

            return convertToWidgetWorkout(primarySession)
        } catch {
            DebugLogger.shared.log("[WidgetBridge] Error fetching workout: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Priority for session status (higher = more important to show).
    private func statusPriority(_ status: ScheduledSession.ScheduleStatus) -> Int {
        switch status {
        case .scheduled: return 2
        case .rescheduled: return 1
        case .completed: return 0
        case .cancelled: return -1
        }
    }

    /// Convert ScheduledSession to WidgetWorkout.
    private func convertToWidgetWorkout(_ session: ScheduledSession) -> WidgetWorkout {
        let status: WidgetWorkout.WorkoutStatus
        switch session.status {
        case .scheduled, .rescheduled:
            status = .scheduled
        case .completed:
            status = .completed
        case .cancelled:
            status = .skipped
        }

        return WidgetWorkout(
            sessionId: session.id,
            name: session.displayName,
            sessionType: "strength", // Default type since ScheduledSession doesn't have type
            scheduledTime: session.scheduledDateTime,
            status: status,
            estimatedMinutes: nil, // Would require joining with Session model
            exerciseCount: nil, // Would require joining with exercises
            lastUpdated: Date()
        )
    }

    /// Fetch and convert adherence data to widget model.
    private func fetchAdherenceData(for patientId: UUID) async -> WidgetAdherence? {
        do {
            // Get this week's sessions
            let calendar = Calendar.current
            let today = Date()

            // Find start of week (Monday)
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = 2 // Monday
            guard let startOfWeek = calendar.date(from: components) else { return nil }

            // Fetch sessions for the week (7 days from start of week)
            let allSessions = try await schedulingService.fetchScheduledSessions(for: patientId)

            // Filter to this week's sessions
            let weekSessions = allSessions.filter { session in
                let daysDiff = calendar.dateComponents([.day], from: startOfWeek, to: session.scheduledDate).day ?? 0
                return daysDiff >= 0 && daysDiff < 7
            }

            // Calculate adherence
            let completedCount = weekSessions.filter { $0.status == .completed }.count
            let scheduledCount = weekSessions.filter { $0.status != .cancelled }.count
            let adherencePercent = scheduledCount > 0 ? Double(completedCount) / Double(scheduledCount) * 100 : 100

            // Build week days status
            let weekDays: [WidgetAdherence.DayStatus] = (0..<7).map { offset in
                guard let dayDate = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                    return WidgetAdherence.DayStatus(date: today, status: .future)
                }

                let daySessions = weekSessions.filter { calendar.isDate($0.scheduledDate, inSameDayAs: dayDate) }

                // Determine day status
                let status: WidgetAdherence.DayStatus.Status
                if dayDate > today {
                    status = daySessions.isEmpty ? .restDay : .scheduled
                } else if daySessions.isEmpty {
                    status = .restDay
                } else if daySessions.allSatisfy({ $0.status == .completed }) {
                    status = .completed
                } else if daySessions.contains(where: { $0.status == .cancelled }) {
                    status = .skipped
                } else {
                    status = calendar.isDateInToday(dayDate) ? .scheduled : .skipped
                }

                return WidgetAdherence.DayStatus(date: dayDate, status: status)
            }

            return WidgetAdherence(
                adherencePercent: adherencePercent,
                completedSessions: completedCount,
                totalSessions: scheduledCount,
                weekDays: weekDays,
                lastUpdated: Date()
            )
        } catch {
            DebugLogger.shared.log("[WidgetBridge] Error fetching adherence: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Fetch and convert streak data to widget model.
    /// ACP-836: Uses StreakTrackingService for accurate streak data from database
    private func fetchStreakData(for patientId: UUID) async -> WidgetStreak? {
        do {
            // Fetch streak and sessions in parallel
            let streakService = StreakTrackingService.shared
            async let streakTask = streakService.getCombinedStreak(for: patientId)
            async let sessionsTask = schedulingService.fetchScheduledSessions(for: patientId)

            // Use StreakTrackingService for accurate streak data
            if let combinedStreak = try await streakTask {
                return streakService.createWidgetStreak(from: combinedStreak)
            }

            // Fallback to calculated streak from sessions if no streak record exists
            let allSessions = try await sessionsTask
            let completedSessions = allSessions
                .filter { $0.status == .completed }
                .sorted { $0.scheduledDate > $1.scheduledDate }

            guard !completedSessions.isEmpty else {
                return WidgetStreak(
                    currentStreak: 0,
                    longestStreak: 0,
                    streakType: .combined,
                    lastActivityDate: nil,
                    lastUpdated: Date()
                )
            }

            let lastActivityDate = completedSessions.first?.scheduledDate

            // Calculate current streak (consecutive days with completed sessions)
            let currentStreak = calculateCurrentStreak(from: completedSessions)

            // Calculate longest streak
            let longestStreak = calculateLongestStreak(from: completedSessions)

            return WidgetStreak(
                currentStreak: currentStreak,
                longestStreak: max(currentStreak, longestStreak),
                streakType: .combined,
                lastActivityDate: lastActivityDate,
                lastUpdated: Date()
            )
        } catch {
            DebugLogger.shared.log("[WidgetBridge] Error fetching streak: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Calculate current streak from completed sessions.
    private func calculateCurrentStreak(from sessions: [ScheduledSession]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        // Start from today and count backwards
        for session in sessions {
            let sessionDay = calendar.startOfDay(for: session.scheduledDate)
            let targetDay = calendar.startOfDay(for: currentDate)

            if calendar.isDate(sessionDay, inSameDayAs: targetDay) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if sessionDay < targetDay {
                // Check if this is the previous day
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: targetDay)
                if let dayBefore = dayBefore, calendar.isDate(sessionDay, inSameDayAs: dayBefore) {
                    streak += 1
                    currentDate = sessionDay
                } else {
                    // Streak broken
                    break
                }
            }
        }

        return streak
    }

    /// Calculate longest streak from completed sessions.
    private func calculateLongestStreak(from sessions: [ScheduledSession]) -> Int {
        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?

        // Sort by date ascending for this calculation
        let sortedSessions = sessions.sorted { $0.scheduledDate < $1.scheduledDate }

        for session in sortedSessions {
            let sessionDay = calendar.startOfDay(for: session.scheduledDate)

            if let prevDate = previousDate {
                let prevDay = calendar.startOfDay(for: prevDate)
                let nextExpectedDay = calendar.date(byAdding: .day, value: 1, to: prevDay)

                if let nextDay = nextExpectedDay, calendar.isDate(sessionDay, inSameDayAs: nextDay) {
                    currentStreak += 1
                } else if calendar.isDate(sessionDay, inSameDayAs: prevDay) {
                    // Same day, don't increment
                } else {
                    // Streak broken, start new
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            previousDate = session.scheduledDate
        }

        return max(longestStreak, currentStreak)
    }

    /// Fetch week trend data for recovery dashboard widget.
    private func fetchWeekTrendData(for patientId: UUID) async -> [WidgetReadiness]? {
        do {
            let recentReadiness = try await readinessService.fetchRecentReadiness(for: patientId, limit: 7)

            guard !recentReadiness.isEmpty else { return nil }

            return recentReadiness.map { convertToWidgetReadiness($0) }
        } catch {
            DebugLogger.shared.log("[WidgetBridge] Error fetching week trend: \(error.localizedDescription)", level: .error)
            return nil
        }
    }
}

// MARK: - Convenience Extension for App Lifecycle

extension WidgetBridgeService {

    /// Called when the app becomes active.
    ///
    /// Refreshes all widget data if the last refresh was more than 15 minutes ago.
    func onAppBecomeActive() async {
        let lastRefresh = sharedDataStore.getLastRefresh()
        let refreshThreshold: TimeInterval = 15 * 60 // 15 minutes

        if let lastRefresh = lastRefresh {
            let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
            if timeSinceRefresh < refreshThreshold {
                DebugLogger.shared.log("[WidgetBridge] Skipping refresh, last refresh was \(Int(timeSinceRefresh))s ago", level: .diagnostic)
                return
            }
        }

        await refreshAllWidgetData()
    }

    /// Called when user completes a readiness check-in.
    func onReadinessCheckInCompleted() async {
        await refreshReadinessWidget()
        // Also refresh daily summary which shows readiness
        sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.dailySummary)
    }

    /// Called when user starts, completes, or skips a workout.
    func onWorkoutStateChanged() async {
        await refreshWorkoutWidget()
        await refreshAdherenceWidget()
        await refreshStreakWidget()
        // Refresh daily summary as it shows workout status
        sharedDataStore.reloadWidget(kind: SharedDataStore.WidgetKind.dailySummary)
    }
}
