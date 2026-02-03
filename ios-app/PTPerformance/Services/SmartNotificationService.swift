//
//  SmartNotificationService.swift
//  PTPerformance
//
//  ACP-841: Smart Notification Timing Feature
//  Analyzes workout patterns and schedules intelligent reminders
//

import Foundation
import UserNotifications
import Supabase

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for analyzing training patterns
private struct AnalyzeTrainingPatternsParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

/// RPC parameters for getting optimal reminder time
private struct GetOptimalReminderTimeParams: Encodable {
    let pPatientId: String
    let pDayOfWeek: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDayOfWeek = "p_day_of_week"
    }
}

/// RPC parameters for recording workout completion time
private struct RecordWorkoutCompletionTimeParams: Encodable {
    let pPatientId: String
    let pCompletionTime: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pCompletionTime = "p_completion_time"
    }
}

/// Service for managing smart workout notification scheduling.
///
/// Thread-safe actor that handles:
/// - Learning user workout patterns
/// - Scheduling intelligent reminders
/// - Managing notification permissions
/// - Adaptive timing based on user behavior
///
/// ## Usage
/// ```swift
/// await SmartNotificationService.shared.analyzePatterns(for: patientId)
/// await SmartNotificationService.shared.scheduleSmartReminder(for: patientId)
/// ```
actor SmartNotificationService {

    // MARK: - Singleton

    static let shared = SmartNotificationService()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - Notification Identifiers

    private enum NotificationIdentifier {
        static let workoutReminder = "com.getmodus.workout.reminder"
        static let streakAlert = "com.getmodus.streak.alert"
        static let weeklySummary = "com.getmodus.weekly.summary"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Permission Management

    /// Check if notification permissions are granted.
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Request notification permission from the user.
    ///
    /// - Returns: `true` if permission was granted
    func requestPermission() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            DebugLogger.shared.log(
                "Notification permission \(granted ? "granted" : "denied")",
                level: granted ? .success : .warning
            )
            return granted
        } catch {
            errorLogger.logError(error, context: "SmartNotificationService.requestPermission")
            throw SmartNotificationError.permissionDenied
        }
    }

    // MARK: - Pattern Analysis

    /// Analyze workout patterns for a patient.
    ///
    /// Triggers server-side analysis of historical workout times and updates
    /// the training_time_patterns table for smart reminder scheduling.
    ///
    /// - Parameter patientId: The patient's UUID
    func analyzePatterns(for patientId: UUID) async throws {
        do {
            let params = AnalyzeTrainingPatternsParams(pPatientId: patientId.uuidString)
            try await supabase.rpc(
                "analyze_training_patterns",
                params: params
            ).execute()

            DebugLogger.shared.log(
                "Training patterns analyzed for patient \(patientId)",
                level: .success
            )
        } catch {
            errorLogger.logError(error, context: "SmartNotificationService.analyzePatterns(patient=\(patientId))")
            throw SmartNotificationError.analysisFailedError(error)
        }
    }

    /// Fetch training time patterns for a patient.
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of training patterns per day of week
    func fetchPatterns(for patientId: UUID) async throws -> [TrainingTimePattern] {
        do {
            let patterns: [TrainingTimePattern] = try await supabase
                .from("training_time_patterns")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("day_of_week", ascending: true)
                .execute()
                .value

            return patterns
        } catch {
            errorLogger.logError(error, context: "SmartNotificationService.fetchPatterns(patient=\(patientId))")
            throw SmartNotificationError.fetchFailed(error)
        }
    }

    // MARK: - Notification Settings

    /// Fetch notification settings for a patient.
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: NotificationSettings, or default settings if none exist
    func fetchSettings(for patientId: UUID) async throws -> NotificationSettings {
        do {
            let settings: [NotificationSettings] = try await supabase
                .from("notification_settings")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .limit(1)
                .execute()
                .value

            return settings.first ?? NotificationSettings.defaults(for: patientId)
        } catch {
            errorLogger.logError(error, context: "SmartNotificationService.fetchSettings(patient=\(patientId))")
            throw SmartNotificationError.fetchFailed(error)
        }
    }

    /// Update notification settings for a patient.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - settings: Updated notification settings
    func updateSettings(for patientId: UUID, settings: NotificationSettingsUpdate) async throws {
        do {
            // Check if settings exist
            let existing: [NotificationSettings] = try await supabase
                .from("notification_settings")
                .select("id")
                .eq("patient_id", value: patientId.uuidString)
                .limit(1)
                .execute()
                .value

            if existing.isEmpty {
                // Insert new settings
                try await supabase
                    .from("notification_settings")
                    .insert(settings.toInsert(patientId: patientId))
                    .execute()
            } else {
                // Update existing settings
                try await supabase
                    .from("notification_settings")
                    .update(settings)
                    .eq("patient_id", value: patientId.uuidString)
                    .execute()
            }

            DebugLogger.shared.log(
                "Notification settings updated for patient \(patientId)",
                level: .success
            )

            // Reschedule notifications with new settings
            try await rescheduleAllReminders(for: patientId)
        } catch {
            errorLogger.logError(error, context: "SmartNotificationService.updateSettings(patient=\(patientId))")
            throw SmartNotificationError.updateFailed(error)
        }
    }

    // MARK: - Smart Reminder Scheduling

    /// Get the optimal reminder time for a specific day.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - dayOfWeek: Day of week (0=Sunday, 6=Saturday)
    /// - Returns: Optimal reminder time information
    /// - Throws: SmartNotificationError.fetchFailed if the RPC call fails
    func getOptimalReminderTime(
        for patientId: UUID,
        dayOfWeek: Int
    ) async throws -> OptimalReminderTime {
        let params = GetOptimalReminderTimeParams(
            pPatientId: patientId.uuidString,
            pDayOfWeek: String(dayOfWeek)
        )

        do {
            let result: [OptimalReminderTimeResponse] = try await supabase
                .rpc(
                    "get_optimal_reminder_time",
                    params: params
                )
                .execute()
                .value

            guard let response = result.first else {
                // No pattern data yet - this is expected for new users, return default
                return OptimalReminderTime.default
            }

            return OptimalReminderTime(
                reminderTime: response.reminderTime,
                isSmart: response.isSmart,
                confidence: response.confidence,
                basedOnWorkouts: response.basedOnWorkouts
            )
        } catch {
            // Log the error for debugging/monitoring
            errorLogger.logError(error, context: "SmartNotificationService.getOptimalReminderTime(patient=\(patientId), day=\(dayOfWeek))")
            throw SmartNotificationError.fetchFailed(error)
        }
    }

    /// Get the optimal reminder time for a specific day, with fallback to default on error.
    ///
    /// Use this variant when you want to gracefully degrade to default timing
    /// rather than surfacing errors to the user (e.g., background scheduling).
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - dayOfWeek: Day of week (0=Sunday, 6=Saturday)
    /// - Returns: Optimal reminder time information, or default if fetch fails
    func getOptimalReminderTimeWithFallback(
        for patientId: UUID,
        dayOfWeek: Int
    ) async -> OptimalReminderTime {
        do {
            return try await getOptimalReminderTime(for: patientId, dayOfWeek: dayOfWeek)
        } catch {
            DebugLogger.shared.log(
                "Failed to get optimal reminder time, using default: \(error.localizedDescription)",
                level: .warning
            )
            return OptimalReminderTime.default
        }
    }

    /// Schedule a smart workout reminder.
    ///
    /// Uses learned patterns to schedule a reminder at the optimal time,
    /// falling back to the user's preferred time if no pattern exists.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - title: Optional custom notification title
    ///   - body: Optional custom notification body
    func scheduleSmartReminder(
        for patientId: UUID,
        title: String? = nil,
        body: String? = nil
    ) async throws {
        // Check permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else {
            throw SmartNotificationError.permissionDenied
        }

        // Get settings (for future features like custom notification preferences)
        _ = try await fetchSettings(for: patientId)

        // Get today's day of week
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date()) - 1 // Convert to 0-indexed

        // Get optimal time (use fallback variant since this is background scheduling)
        let optimalTime = await getOptimalReminderTimeWithFallback(for: patientId, dayOfWeek: today)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title ?? "Time to Train"
        content.body = body ?? (optimalTime.isSmart
            ? "Based on your schedule, now is a great time for your workout!"
            : "Stay consistent with your training!")
        content.sound = .default
        content.badge = 1

        // Calculate next trigger date
        let triggerDate = nextTriggerDate(for: optimalTime.reminderTime, from: today)

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.hour, .minute], from: triggerDate),
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifier.workoutReminder).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        // Schedule
        try await notificationCenter.add(request)

        // Record in history
        do {
            try await recordNotificationScheduled(
                patientId: patientId,
                type: "workout_reminder",
                title: content.title,
                body: content.body,
                scheduledFor: triggerDate
            )
        } catch {
            DebugLogger.shared.log("Failed to record notification scheduled in history: \(error.localizedDescription)", level: .warning)
        }

        DebugLogger.shared.log(
            "Smart reminder scheduled for \(triggerDate) (smart=\(optimalTime.isSmart), confidence=\(optimalTime.confidence))",
            level: .success
        )
    }

    /// Schedule reminders for the entire week.
    ///
    /// Creates reminders for each day based on learned patterns or fallback time.
    ///
    /// - Parameter patientId: The patient's UUID
    func scheduleWeeklyReminders(for patientId: UUID) async throws {
        let status = await checkPermissionStatus()
        guard status == .authorized else {
            throw SmartNotificationError.permissionDenied
        }

        // Fetch settings for future features (custom weekly schedule preferences)
        _ = try await fetchSettings(for: patientId)
        let calendar = Calendar.current

        // Clear existing reminders
        await clearAllReminders(matching: NotificationIdentifier.workoutReminder)

        // Schedule for each day of the week
        for dayOffset in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let dayOfWeek = calendar.component(.weekday, from: targetDate) - 1

            let optimalTime = await getOptimalReminderTimeWithFallback(for: patientId, dayOfWeek: dayOfWeek)

            let content = UNMutableNotificationContent()
            content.title = "Time to Train"
            content.body = optimalTime.isSmart
                ? "Your usual workout time is approaching!"
                : "Stay consistent with your training!"
            content.sound = .default

            let triggerDate = nextTriggerDate(for: optimalTime.reminderTime, from: dayOfWeek, daysOffset: dayOffset)

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(NotificationIdentifier.workoutReminder).\(dayOfWeek)",
                content: content,
                trigger: trigger
            )

            try await notificationCenter.add(request)
        }

        DebugLogger.shared.log(
            "Weekly reminders scheduled for patient \(patientId)",
            level: .success
        )
    }

    /// Reschedule all reminders after settings change.
    private func rescheduleAllReminders(for patientId: UUID) async throws {
        try await scheduleWeeklyReminders(for: patientId)
    }

    // MARK: - Streak Alerts

    /// Schedule a streak alert notification.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - currentStreak: Current workout streak count
    func scheduleStreakAlert(for patientId: UUID, currentStreak: Int) async throws {
        let settings = try await fetchSettings(for: patientId)

        guard settings.streakAlertsEnabled else { return }

        let status = await checkPermissionStatus()
        guard status == .authorized else { return }

        let content = UNMutableNotificationContent()

        if currentStreak > 0 && currentStreak % 7 == 0 {
            // Weekly milestone
            content.title = "Week Streak!"
            content.body = "You've trained for \(currentStreak / 7) week\(currentStreak >= 14 ? "s" : "") straight! Keep it up!"
        } else if currentStreak >= 3 {
            // Building momentum
            content.title = "Streak: \(currentStreak) Days"
            content.body = "You're on fire! Don't break your streak!"
        } else {
            return // No alert needed
        }

        content.sound = .default

        // Schedule for tomorrow morning
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(NotificationIdentifier.streakAlert).\(currentStreak)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Workout Completion Recording

    /// Record workout completion to improve pattern learning.
    ///
    /// Should be called after each workout to help the system learn optimal times.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - completionTime: When the workout was completed
    func recordWorkoutCompletion(for patientId: UUID, completionTime: Date = Date()) async throws {
        do {
            let params = RecordWorkoutCompletionTimeParams(
                pPatientId: patientId.uuidString,
                pCompletionTime: dateFormatter.string(from: completionTime)
            )
            try await supabase.rpc(
                "record_workout_completion_time",
                params: params
            ).execute()

            DebugLogger.shared.log(
                "Workout completion recorded for pattern learning",
                level: .info
            )

            // Re-analyze patterns with new data
            try await analyzePatterns(for: patientId)
        } catch {
            // Non-critical - log but don't throw
            errorLogger.logError(error, context: "SmartNotificationService.recordWorkoutCompletion")
        }
    }

    // MARK: - Notification Management

    /// Clear all pending workout reminders.
    func clearAllReminders(matching prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let toRemove = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)

        DebugLogger.shared.log(
            "Cleared \(toRemove.count) pending notifications",
            level: .info
        )
    }

    /// Clear all notifications for a patient.
    func clearAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Notification History

    /// Record a scheduled notification in history.
    private func recordNotificationScheduled(
        patientId: UUID,
        type: String,
        title: String,
        body: String?,
        scheduledFor: Date
    ) async throws {
        let record = NotificationHistoryInsert(
            patientId: patientId.uuidString,
            notificationType: type,
            title: title,
            body: body,
            scheduledFor: dateFormatter.string(from: scheduledFor)
        )

        try await supabase
            .from("notification_history")
            .insert(record)
            .execute()
    }

    // MARK: - Helper Methods

    /// Calculate the next trigger date for a given time.
    private func nextTriggerDate(for time: Date, from dayOfWeek: Int, daysOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        var targetDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()

        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        targetDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate) ?? targetDate

        // If the time has already passed today, schedule for tomorrow
        if daysOffset == 0 && targetDate <= Date() {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }

        return targetDate
    }
}

// MARK: - Supporting Types

/// Training time pattern for a specific day of week.
struct TrainingTimePattern: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let dayOfWeek: Int
    let preferredHour: Int?
    let workoutCount: Int
    let avgStartTime: Date?
    let confidenceScore: Double?
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case dayOfWeek = "day_of_week"
        case preferredHour = "preferred_hour"
        case workoutCount = "workout_count"
        case avgStartTime = "avg_start_time"
        case confidenceScore = "confidence_score"
        case lastUpdated = "last_updated"
    }

    /// Display name for the day of week.
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard dayOfWeek >= 0 && dayOfWeek < days.count else { return "Unknown" }
        return days[dayOfWeek]
    }

    /// Short day name.
    var shortDayName: String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard dayOfWeek >= 0 && dayOfWeek < days.count else { return "?" }
        return days[dayOfWeek]
    }

    /// Formatted average start time.
    var formattedTime: String? {
        guard let time = avgStartTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    /// Confidence level description.
    var confidenceLevel: String {
        guard let confidence = confidenceScore else { return "No data" }
        switch confidence {
        case 0..<0.3: return "Learning"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "Good"
        default: return "High"
        }
    }
}

/// Notification settings for a patient.
struct NotificationSettings: Codable, Identifiable {
    let id: UUID?
    let patientId: UUID
    let smartTimingEnabled: Bool
    let fallbackReminderTime: Date
    let reminderMinutesBefore: Int
    let streakAlertsEnabled: Bool
    let weeklySummaryEnabled: Bool
    let quietHoursStart: Date?
    let quietHoursEnd: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case smartTimingEnabled = "smart_timing_enabled"
        case fallbackReminderTime = "fallback_reminder_time"
        case reminderMinutesBefore = "reminder_minutes_before"
        case streakAlertsEnabled = "streak_alerts_enabled"
        case weeklySummaryEnabled = "weekly_summary_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
        case updatedAt = "updated_at"
    }

    /// Default settings for a new patient.
    static func defaults(for patientId: UUID) -> NotificationSettings {
        let calendar = Calendar.current
        var defaultTime = DateComponents()
        defaultTime.hour = 9
        defaultTime.minute = 0

        var quietStart = DateComponents()
        quietStart.hour = 22
        quietStart.minute = 0

        var quietEnd = DateComponents()
        quietEnd.hour = 7
        quietEnd.minute = 0

        return NotificationSettings(
            id: nil,
            patientId: patientId,
            smartTimingEnabled: true,
            fallbackReminderTime: calendar.date(from: defaultTime) ?? Date(),
            reminderMinutesBefore: 30,
            streakAlertsEnabled: true,
            weeklySummaryEnabled: true,
            quietHoursStart: calendar.date(from: quietStart),
            quietHoursEnd: calendar.date(from: quietEnd),
            updatedAt: nil
        )
    }

    /// Formatted fallback reminder time.
    var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: fallbackReminderTime)
    }
}

/// Settings update payload.
struct NotificationSettingsUpdate: Encodable {
    var smartTimingEnabled: Bool?
    var fallbackReminderTime: String?
    var reminderMinutesBefore: Int?
    var streakAlertsEnabled: Bool?
    var weeklySummaryEnabled: Bool?
    var quietHoursStart: String?
    var quietHoursEnd: String?
    var updatedAt: String = ISO8601DateFormatter().string(from: Date())

    enum CodingKeys: String, CodingKey {
        case smartTimingEnabled = "smart_timing_enabled"
        case fallbackReminderTime = "fallback_reminder_time"
        case reminderMinutesBefore = "reminder_minutes_before"
        case streakAlertsEnabled = "streak_alerts_enabled"
        case weeklySummaryEnabled = "weekly_summary_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
        case updatedAt = "updated_at"
    }

    /// Convert to insert payload for new settings.
    func toInsert(patientId: UUID) -> NotificationSettingsInsert {
        NotificationSettingsInsert(
            patientId: patientId.uuidString,
            smartTimingEnabled: smartTimingEnabled ?? true,
            fallbackReminderTime: fallbackReminderTime ?? "09:00:00",
            reminderMinutesBefore: reminderMinutesBefore ?? 30,
            streakAlertsEnabled: streakAlertsEnabled ?? true,
            weeklySummaryEnabled: weeklySummaryEnabled ?? true,
            quietHoursStart: quietHoursStart ?? "22:00:00",
            quietHoursEnd: quietHoursEnd ?? "07:00:00"
        )
    }
}

/// Insert payload for new notification settings.
struct NotificationSettingsInsert: Encodable {
    let patientId: String
    let smartTimingEnabled: Bool
    let fallbackReminderTime: String
    let reminderMinutesBefore: Int
    let streakAlertsEnabled: Bool
    let weeklySummaryEnabled: Bool
    let quietHoursStart: String
    let quietHoursEnd: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case smartTimingEnabled = "smart_timing_enabled"
        case fallbackReminderTime = "fallback_reminder_time"
        case reminderMinutesBefore = "reminder_minutes_before"
        case streakAlertsEnabled = "streak_alerts_enabled"
        case weeklySummaryEnabled = "weekly_summary_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }
}

/// Optimal reminder time information.
struct OptimalReminderTime {
    let reminderTime: Date
    let isSmart: Bool
    let confidence: Double
    let basedOnWorkouts: Int?

    /// Default reminder time (9:00 AM).
    static var `default`: OptimalReminderTime {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let time = Calendar.current.date(from: components) ?? Date()

        return OptimalReminderTime(
            reminderTime: time,
            isSmart: false,
            confidence: 0,
            basedOnWorkouts: nil
        )
    }
}

/// Response from get_optimal_reminder_time RPC.
private struct OptimalReminderTimeResponse: Codable {
    let reminderTime: Date
    let isSmart: Bool
    let confidence: Double
    let basedOnWorkouts: Int?

    enum CodingKeys: String, CodingKey {
        case reminderTime = "reminder_time"
        case isSmart = "is_smart"
        case confidence
        case basedOnWorkouts = "based_on_workouts"
    }
}

/// Notification history insert payload.
private struct NotificationHistoryInsert: Encodable {
    let patientId: String
    let notificationType: String
    let title: String
    let body: String?
    let scheduledFor: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case notificationType = "notification_type"
        case title
        case body
        case scheduledFor = "scheduled_for"
    }
}

// MARK: - Errors

/// Errors that can occur during smart notification operations.
enum SmartNotificationError: LocalizedError {
    case permissionDenied
    case fetchFailed(Error)
    case updateFailed(Error)
    case scheduleFailed(Error)
    case analysisFailedError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification Permission Required"
        case .fetchFailed:
            return "Couldn't Load Settings"
        case .updateFailed:
            return "Couldn't Save Settings"
        case .scheduleFailed:
            return "Couldn't Schedule Reminder"
        case .analysisFailedError:
            return "Pattern Analysis Failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable notifications in Settings to receive workout reminders."
        case .fetchFailed:
            return "We couldn't load your notification settings. Please check your connection and try again."
        case .updateFailed:
            return "We couldn't save your notification preferences. Please try again."
        case .scheduleFailed:
            return "We couldn't schedule your reminder. Please try again."
        case .analysisFailedError:
            return "We couldn't analyze your workout patterns. Your reminders will use your default time."
        }
    }

    var underlyingError: Error? {
        switch self {
        case .fetchFailed(let error),
             .updateFailed(let error),
             .scheduleFailed(let error),
             .analysisFailedError(let error):
            return error
        case .permissionDenied:
            return nil
        }
    }
}
