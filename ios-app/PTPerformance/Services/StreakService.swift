//
//  StreakService.swift
//  PTPerformance
//
//  ACP-1004: Streak & Habit Mechanics
//  Unified streak service that combines tracking, freeze management,
//  milestone detection, and notification scheduling into a single
//  observable service for the habit loop.
//

import SwiftUI
import Combine

// MARK: - Streak Service

/// Central service for streak and habit mechanics.
///
/// Combines data from `StreakTrackingService`, `StreakFreezeService`,
/// and `StreakAlertService` into a single `@Published` interface that
/// views can observe directly.
///
/// ## Habit Loop
/// 1. **Cue**: Streak-at-risk notification at 7 PM
/// 2. **Routine**: Quick workout or full session
/// 3. **Reward**: Streak increment, milestone celebration, freeze earned
///
/// ## Usage
/// ```swift
/// @StateObject private var streakService = StreakService.shared
///
/// // Record today's activity
/// await streakService.recordActivity()
///
/// // Check streak state
/// if streakService.streakAtRisk {
///     // Show streak protection UI
/// }
/// ```
@MainActor
class StreakService: ObservableObject {

    // MARK: - Singleton

    static let shared = StreakService()

    // MARK: - Published Properties

    /// Current consecutive-day streak count.
    @Published var currentStreak: Int = 0

    /// All-time longest streak.
    @Published var longestStreak: Int = 0

    /// Date the current streak began (nil if no active streak).
    @Published var streakStartDate: Date?

    /// Whether today has been marked as complete.
    @Published var todayCompleted: Bool = false

    /// True if no activity today and it is past 6 PM local time.
    @Published var streakAtRisk: Bool = false

    /// The most recent milestone that should be celebrated (nil = nothing pending).
    @Published var pendingMilestone: StreakMilestone?

    /// Number of streak freezes available this week.
    @Published var freezesAvailable: Int = 0

    /// Whether a freeze was used this week already.
    @Published var freezeUsedThisWeek: Bool = false

    /// Calendar heatmap data: date -> activity completed.
    @Published var calendarData: [Date: Bool] = [:]

    /// Last activity date for display purposes.
    @Published var lastActivityDate: Date?

    /// Whether the service is loading data.
    @Published var isLoading: Bool = false

    // MARK: - Milestone Constants

    /// Streak milestone thresholds that trigger celebrations.
    static let milestoneThresholds: [Int] = [7, 14, 30, 60, 90, 180, 365]

    // MARK: - Private Properties

    private let trackingService = StreakTrackingService.shared
    private let freezeService = StreakFreezeService.shared
    private let alertService = StreakAlertService.shared
    private let logger = DebugLogger.shared
    private let defaults = UserDefaults.standard

    private let lastActivityKey = "streak_last_activity_date"
    private let currentStreakKey = "streak_current_count"
    private let longestStreakKey = "streak_longest_count"
    private let streakStartKey = "streak_start_date"
    private let celebratedMilestonesKey = "streak_celebrated_milestones_v2"

    private var cancellables = Set<AnyCancellable>()
    private var riskCheckTimer: Timer?

    // MARK: - Initialization

    private init() {
        // Load cached data from UserDefaults for instant display
        loadCachedState()

        // Observe freeze service changes
        freezeService.$inventory
            .receive(on: RunLoop.main)
            .sink { [weak self] inventory in
                self?.freezesAvailable = inventory.availableCount
            }
            .store(in: &cancellables)

        freezeService.$lastFreezeUsedDate
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                guard let self = self, let date = date else { return }
                let calendar = Calendar.current
                self.freezeUsedThisWeek = calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
            }
            .store(in: &cancellables)

        // Start periodic risk assessment
        startRiskMonitoring()

        logger.info("StreakService", "Initialized with cached streak: \(currentStreak)")
    }

    deinit {
        riskCheckTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Record today's activity (marks the day as complete).
    ///
    /// Call this when a workout is finished, arm care is done, or any
    /// qualifying activity is completed.
    func recordActivity() async {
        guard let patientId = currentPatientId else {
            logger.warning("StreakService", "Cannot record activity: no patient ID")
            return
        }

        logger.info("StreakService", "Recording activity for today")
        isLoading = true

        do {
            try await trackingService.recordWorkoutCompletion(for: patientId)

            // Update local state immediately for responsive UI
            let alreadyCompletedToday = todayCompleted
            todayCompleted = true
            streakAtRisk = false
            if !alreadyCompletedToday { currentStreak += 1 }
            lastActivityDate = Date()

            // Persist to UserDefaults
            persistState()

            // Cancel any pending streak-at-risk notifications
            await PushNotificationService.shared.cancelNotifications(ofType: .streakAtRisk)
            alertService.cancelScheduledAlerts()

            // Check for milestone achievements
            checkAndCelebrateMilestone()

            // Check for freeze rewards
            freezeService.checkAndAwardFreezes(for: currentStreak)

            // Haptic feedback for completing the day
            HapticFeedback.success()

            logger.success("StreakService", "Activity recorded. Streak: \(currentStreak)")

            // Refresh from server for authoritative data
            await checkStreak()
        } catch {
            logger.error("StreakService", "Failed to record activity: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Fetch and recalculate the current streak from activity history.
    ///
    /// Called on app launch and after recording activity to sync with server.
    func checkStreak() async {
        guard let patientId = currentPatientId else { return }

        logger.info("StreakService", "Checking streak from server")

        do {
            let records = try await trackingService.fetchCurrentStreaks(for: patientId)

            // Use the combined streak record (most comprehensive)
            if let combined = records.first(where: { $0.streakType == .combined }) {
                currentStreak = combined.currentStreak
                longestStreak = combined.longestStreak
                streakStartDate = combined.streakStartDate
                lastActivityDate = combined.lastActivityDate

                // Check if today is completed
                if let lastDate = combined.lastActivityDate {
                    todayCompleted = Calendar.current.isDateInToday(lastDate)
                } else {
                    todayCompleted = false
                }

                // Persist authoritative server data
                persistState()

                logger.success("StreakService", "Streak synced: \(currentStreak) days (longest: \(longestStreak))")
            } else if let workout = records.first(where: { $0.streakType == .workout }) {
                // Fall back to workout streak if no combined
                currentStreak = workout.currentStreak
                longestStreak = workout.longestStreak
                streakStartDate = workout.streakStartDate
                lastActivityDate = workout.lastActivityDate
                todayCompleted = workout.lastActivityDate.map { Calendar.current.isDateInToday($0) } ?? false

                persistState()
            }

            // Update risk assessment
            evaluateRisk()

            // Schedule streak-at-risk notification if needed
            if !todayCompleted && currentStreak > 0 {
                await scheduleStreakAtRiskNotification()
            }
        } catch {
            logger.error("StreakService", "Failed to check streak: \(error.localizedDescription)")
        }
    }

    /// Get the activity heatmap for a given month.
    ///
    /// - Parameter month: Any date within the target month.
    /// - Returns: Dictionary mapping dates to activity status.
    func getStreakCalendar(month: Date) -> [Date: Bool] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return [:]
        }

        var result: [Date: Bool] = [:]
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                let startOfDay = calendar.startOfDay(for: date)
                result[startOfDay] = calendarData[startOfDay] ?? false
            }
        }
        return result
    }

    /// Load the full calendar heatmap data from the server.
    ///
    /// - Parameter days: Number of past days to fetch (default 90).
    func loadCalendarData(days: Int = 90) async {
        guard let patientId = currentPatientId else { return }

        do {
            let history = try await trackingService.getStreakHistory(for: patientId, days: days)
            let calendar = Calendar.current

            var newData: [Date: Bool] = [:]
            for entry in history {
                let startOfDay = calendar.startOfDay(for: entry.activityDate)
                newData[startOfDay] = entry.hasAnyActivity
            }
            calendarData = newData

            logger.success("StreakService", "Loaded \(history.count) calendar entries for last \(days) days")
        } catch {
            logger.error("StreakService", "Failed to load calendar data: \(error.localizedDescription)")
        }
    }

    /// Use a streak freeze to protect today's streak.
    ///
    /// - Returns: True if the freeze was successfully applied.
    func useStreakFreeze() -> Bool {
        guard streakAtRisk && !todayCompleted else {
            logger.warning("StreakService", "Cannot use freeze: streak not at risk or already completed")
            return false
        }

        let success = freezeService.useFreeze()
        if success {
            streakAtRisk = false
            freezeUsedThisWeek = true
            HapticFeedback.success()
            logger.success("StreakService", "Streak freeze activated")
        }
        return success
    }

    /// Compute the next milestone and progress towards it.
    ///
    /// - Returns: Tuple of (nextMilestone, progressFraction) or nil if at max.
    func nextMilestoneProgress() -> (milestone: Int, progress: Double)? {
        guard let next = Self.milestoneThresholds.first(where: { $0 > currentStreak }) else {
            return nil
        }

        let previous = Self.milestoneThresholds.last(where: { $0 <= currentStreak }) ?? 0
        let range = Double(next - previous)
        let progress = range > 0 ? Double(currentStreak - previous) / range : 0
        return (next, progress)
    }

    /// Clear the pending milestone celebration after the user dismisses it.
    func clearPendingMilestone() {
        pendingMilestone = nil
    }

    // MARK: - Private Helpers

    /// The current patient UUID (derived from the authenticated user).
    private var currentPatientId: UUID? {
        guard let userId = PTSupabaseClient.shared.userId else { return nil }
        return UUID(uuidString: userId)
    }

    /// Evaluate whether the streak is at risk based on time of day.
    private func evaluateRisk() {
        guard !todayCompleted else {
            streakAtRisk = false
            return
        }

        let hour = Calendar.current.component(.hour, from: Date())
        streakAtRisk = currentStreak > 0 && hour >= 18
    }

    /// Start a timer that re-evaluates streak risk periodically.
    private func startRiskMonitoring() {
        // Check every 30 minutes
        riskCheckTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateRisk()
            }
        }
    }

    /// Schedule a local notification for 7 PM if the streak is at risk.
    private func scheduleStreakAtRiskNotification() async {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Only schedule if it is before 7 PM
        guard hour < 19 else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 19
        components.minute = 0

        guard let fireDate = calendar.date(from: components) else { return }

        let notification = ScheduledNotification(
            id: "streak_at_risk_\(calendar.component(.day, from: now))",
            type: .streakAtRisk,
            title: "Your Streak is at Risk!",
            body: "You haven't trained today. A quick 5-min session keeps your \(currentStreak)-day streak alive.",
            scheduledDate: fireDate,
            repeats: false,
            data: [
                "streak_count": String(currentStreak),
                "deep_link": "modus://streak"
            ]
        )

        await PushNotificationService.shared.scheduleLocalNotification(notification)
        logger.info("StreakService", "Scheduled streak-at-risk notification for 7 PM")
    }

    /// Check if the current streak matches a milestone and trigger celebration.
    private func checkAndCelebrateMilestone() {
        guard Self.milestoneThresholds.contains(currentStreak) else { return }

        // Check if already celebrated
        let celebrated = Set(defaults.array(forKey: celebratedMilestonesKey) as? [Int] ?? [])
        guard !celebrated.contains(currentStreak) else { return }

        // Mark as celebrated
        var updatedCelebrated = celebrated
        updatedCelebrated.insert(currentStreak)
        defaults.set(Array(updatedCelebrated), forKey: celebratedMilestonesKey)

        // Set the pending milestone for UI display
        if let milestone = StreakMilestone.milestone(for: currentStreak) {
            pendingMilestone = milestone
        }

        // Trigger milestone haptic: heavy impact for bigger milestones
        if currentStreak >= 90 {
            HapticFeedback.heavy()
        } else if currentStreak >= 30 {
            HapticFeedback.heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticFeedback.success()
            }
        } else {
            HapticFeedback.success()
        }

        logger.success("StreakService", "Milestone celebration triggered for \(currentStreak) days")

        // Schedule a celebration notification (immediate)
        Task {
            let notification = ScheduledNotification(
                type: .streakAchieved,
                title: "\(currentStreak)-Day Streak!",
                body: milestoneMessage(for: currentStreak),
                scheduledDate: Date().addingTimeInterval(1),
                data: [
                    "streak_count": String(currentStreak),
                    "deep_link": "modus://streak"
                ]
            )
            await PushNotificationService.shared.scheduleLocalNotification(notification)
        }
    }

    /// Generate a milestone celebration message.
    private func milestoneMessage(for streak: Int) -> String {
        switch streak {
        case 7: return "One week of consistency! You're building great habits."
        case 14: return "Two weeks strong! Your dedication is showing."
        case 30: return "A full month! You've made training a habit."
        case 60: return "Two months of excellence! Truly inspiring."
        case 90: return "Three months! You've transformed your routine."
        case 180: return "Half a year! Your commitment is legendary."
        case 365: return "ONE YEAR! You are an absolute champion."
        default: return "Amazing! \(streak) days of consistent training."
        }
    }

    // MARK: - Persistence

    /// Load cached streak state from UserDefaults for instant display.
    private func loadCachedState() {
        currentStreak = defaults.integer(forKey: currentStreakKey)
        longestStreak = defaults.integer(forKey: longestStreakKey)
        freezesAvailable = freezeService.inventory.availableCount

        if let startInterval = defaults.object(forKey: streakStartKey) as? TimeInterval {
            streakStartDate = Date(timeIntervalSince1970: startInterval)
        }

        if let lastInterval = defaults.object(forKey: lastActivityKey) as? TimeInterval {
            let lastDate = Date(timeIntervalSince1970: lastInterval)
            lastActivityDate = lastDate
            todayCompleted = Calendar.current.isDateInToday(lastDate)
        }

        evaluateRisk()
    }

    /// Persist current streak state to UserDefaults for quick reload.
    private func persistState() {
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(longestStreak, forKey: longestStreakKey)

        if let start = streakStartDate {
            defaults.set(start.timeIntervalSince1970, forKey: streakStartKey)
        }

        if let last = lastActivityDate {
            defaults.set(last.timeIntervalSince1970, forKey: lastActivityKey)
        }
    }
}

// MARK: - Streak Display Helpers

extension StreakService {

    /// Formatted streak text for display.
    var streakDisplayText: String {
        switch currentStreak {
        case 0: return "0 days"
        case 1: return "1 day"
        default: return "\(currentStreak) days"
        }
    }

    /// The current flame level for visual representation.
    var flameLevel: StreakFlameLevel {
        StreakFlameLevel.level(for: currentStreak)
    }

    /// Motivational message based on current streak.
    var motivationalMessage: String {
        if todayCompleted {
            return "Great work today! Your streak is safe."
        }
        if streakAtRisk {
            return "Your streak is at risk! Complete a quick session."
        }
        if currentStreak == 0 {
            return "Start a new streak today!"
        }
        return "Keep it going! Train today to extend your streak."
    }
}
