//
//  StreakAlertService.swift
//  PTPerformance
//
//  ACP-842: Streak Protection Alerts
//  Service for monitoring streak status and scheduling protection alerts
//

import Foundation
import UserNotifications
import BackgroundTasks
import Combine

// MARK: - Streak Risk Level

/// Indicates how at-risk the current streak is
enum StreakRiskLevel: String, Codable {
    case safe           // Activity logged today, no risk
    case lowRisk        // No activity yet, but early in the day
    case mediumRisk     // No activity, afternoon (after 2pm)
    case highRisk       // No activity, evening (after 6pm)
    case critical       // No activity, close to midnight (after 9pm)

    var alertPriority: Int {
        switch self {
        case .safe: return 0
        case .lowRisk: return 1
        case .mediumRisk: return 2
        case .highRisk: return 3
        case .critical: return 4
        }
    }

    var shouldShowAlert: Bool {
        switch self {
        case .safe, .lowRisk: return false
        case .mediumRisk, .highRisk, .critical: return true
        }
    }

    var alertTitle: String {
        switch self {
        case .safe: return "Streak Protected!"
        case .lowRisk: return "Keep Your Streak Going"
        case .mediumRisk: return "Streak Reminder"
        case .highRisk: return "Streak at Risk!"
        case .critical: return "Last Chance for Your Streak!"
        }
    }

    var alertEmoji: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .lowRisk: return "flame"
        case .mediumRisk: return "exclamationmark.triangle"
        case .highRisk: return "flame.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Streak Alert Configuration

/// Configuration for streak alert timing
struct StreakAlertConfiguration: Codable {
    var reminderHour: Int           // Hour of day to check (24-hour format)
    var reminderMinute: Int         // Minute of hour
    var criticalHour: Int           // Hour for critical alert
    var enableNotifications: Bool   // Whether to send push notifications
    var enableInAppAlerts: Bool     // Whether to show in-app banners

    static var `default`: StreakAlertConfiguration {
        StreakAlertConfiguration(
            reminderHour: 18,       // 6 PM
            reminderMinute: 0,
            criticalHour: 21,       // 9 PM
            enableNotifications: true,
            enableInAppAlerts: true
        )
    }
}

// MARK: - Streak Status

/// Current streak status with risk assessment
struct StreakStatus: Codable {
    let currentStreak: Int
    let lastActivityDate: Date?
    let hasActivityToday: Bool
    let riskLevel: StreakRiskLevel
    let updatedAt: Date

    var isAtRisk: Bool {
        riskLevel.shouldShowAlert
    }

    var streakMessage: String {
        if currentStreak == 0 {
            return "Start a new streak today!"
        } else if currentStreak == 1 {
            return "1-day streak"
        } else {
            return "\(currentStreak)-day streak"
        }
    }

    var protectionMessage: String {
        if hasActivityToday {
            return "Your streak is safe for today"
        } else {
            return "Complete a workout to protect your \(streakMessage)"
        }
    }
}

// MARK: - Streak Alert Service

/// Service for managing streak protection alerts and quick workout recommendations
@MainActor
class StreakAlertService: ObservableObject {
    // MARK: - Singleton
    static let shared = StreakAlertService()

    // MARK: - Published Properties
    @Published var currentStatus: StreakStatus?
    @Published var showStreakAlert: Bool = false
    @Published var quickWorkoutOptions: [QuickWorkout] = []
    @Published var hasNotificationPermission: Bool = false
    @Published var configuration: StreakAlertConfiguration

    // MARK: - Private Properties
    private let notificationIdentifier = "com.ptperformance.streak.reminder"
    private let criticalNotificationIdentifier = "com.ptperformance.streak.critical"
    private let backgroundTaskIdentifier = "com.ptperformance.streak.check"
    private let userDefaultsKey = "streak_alert_configuration"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Load saved configuration
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let config = try? JSONDecoder().decode(StreakAlertConfiguration.self, from: data) {
            self.configuration = config
        } else {
            self.configuration = .default
        }

        // Generate quick workout options
        generateQuickWorkoutOptions()

        // Check notification permission
        Task {
            await checkNotificationPermission()
        }
    }

    // MARK: - Streak Risk Assessment

    /// Check if the current streak is at risk
    /// - Parameters:
    ///   - currentStreak: The current streak count
    ///   - lastActivityDate: Date of last recorded activity
    /// - Returns: StreakStatus with risk assessment
    func checkStreakRisk(currentStreak: Int, lastActivityDate: Date?) -> StreakStatus {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Check if activity was logged today
        let hasActivityToday: Bool
        if let lastActivity = lastActivityDate {
            hasActivityToday = calendar.isDateInToday(lastActivity)
        } else {
            hasActivityToday = false
        }

        // Determine risk level based on time of day and activity status
        let riskLevel: StreakRiskLevel
        if hasActivityToday {
            riskLevel = .safe
        } else if currentStreak == 0 {
            // No streak to protect
            riskLevel = .lowRisk
        } else if hour < 14 {
            // Before 2 PM
            riskLevel = .lowRisk
        } else if hour < 18 {
            // 2 PM - 6 PM
            riskLevel = .mediumRisk
        } else if hour < 21 {
            // 6 PM - 9 PM
            riskLevel = .highRisk
        } else {
            // After 9 PM
            riskLevel = .critical
        }

        let status = StreakStatus(
            currentStreak: currentStreak,
            lastActivityDate: lastActivityDate,
            hasActivityToday: hasActivityToday,
            riskLevel: riskLevel,
            updatedAt: now
        )

        // Update published status
        self.currentStatus = status

        // Show alert if needed
        if status.isAtRisk && configuration.enableInAppAlerts {
            showStreakAlert = true
        }

        DebugLogger.shared.log(
            "Streak risk check: \(riskLevel.rawValue) (streak: \(currentStreak), activity today: \(hasActivityToday))",
            level: .info
        )

        return status
    }

    // MARK: - Notification Scheduling

    /// Schedule streak protection notifications
    func scheduleStreakAlert() async throws {
        guard configuration.enableNotifications else {
            DebugLogger.shared.log("Streak notifications disabled", level: .info)
            return
        }

        guard hasNotificationPermission else {
            DebugLogger.shared.log("No notification permission for streak alerts", level: .warning)
            return
        }

        // Remove existing notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier, criticalNotificationIdentifier]
        )

        // Get streak info
        let streakCount = currentStatus?.currentStreak ?? 0

        // Schedule reminder notification
        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "Streak at Risk!"
        reminderContent.body = "You haven't trained today. Quick 10-min session to keep your \(streakCount)-day streak alive?"
        reminderContent.sound = .default
        reminderContent.categoryIdentifier = "STREAK_ALERT"

        // Add custom data for deep linking
        reminderContent.userInfo = [
            "type": "streak_alert",
            "streak_count": streakCount,
            "action": "quick_workout"
        ]

        // Create trigger for reminder time
        var reminderComponents = DateComponents()
        reminderComponents.hour = configuration.reminderHour
        reminderComponents.minute = configuration.reminderMinute

        let reminderTrigger = UNCalendarNotificationTrigger(
            dateMatching: reminderComponents,
            repeats: true
        )

        let reminderRequest = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: reminderContent,
            trigger: reminderTrigger
        )

        try await UNUserNotificationCenter.current().add(reminderRequest)

        // Schedule critical notification
        let criticalContent = UNMutableNotificationContent()
        criticalContent.title = "Last Chance for Your Streak!"
        criticalContent.body = "Don't lose your \(streakCount)-day streak! Just 5 minutes of arm care will keep it alive."
        criticalContent.sound = .default
        criticalContent.categoryIdentifier = "STREAK_CRITICAL"
        criticalContent.userInfo = [
            "type": "streak_critical",
            "streak_count": streakCount,
            "action": "quick_workout"
        ]

        var criticalComponents = DateComponents()
        criticalComponents.hour = configuration.criticalHour
        criticalComponents.minute = 0

        let criticalTrigger = UNCalendarNotificationTrigger(
            dateMatching: criticalComponents,
            repeats: true
        )

        let criticalRequest = UNNotificationRequest(
            identifier: criticalNotificationIdentifier,
            content: criticalContent,
            trigger: criticalTrigger
        )

        try await UNUserNotificationCenter.current().add(criticalRequest)

        DebugLogger.shared.log(
            "Scheduled streak alerts: reminder at \(configuration.reminderHour):00, critical at \(configuration.criticalHour):00",
            level: .success
        )
    }

    /// Cancel scheduled streak alerts (called when workout is completed)
    func cancelScheduledAlerts() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier, criticalNotificationIdentifier]
        )

        DebugLogger.shared.log("Cancelled streak alerts for today", level: .info)
    }

    /// Register notification categories and actions
    func registerNotificationCategories() {
        let startWorkoutAction = UNNotificationAction(
            identifier: "START_QUICK_WORKOUT",
            title: "Start Quick Workout",
            options: [.foreground]
        )

        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 Hour",
            options: []
        )

        let skipTodayAction = UNNotificationAction(
            identifier: "SKIP_TODAY",
            title: "Skip Today",
            options: [.destructive]
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_ALERT",
            actions: [startWorkoutAction, remindLaterAction, skipTodayAction],
            intentIdentifiers: [],
            options: []
        )

        let criticalCategory = UNNotificationCategory(
            identifier: "STREAK_CRITICAL",
            actions: [startWorkoutAction, skipTodayAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            streakCategory,
            criticalCategory
        ])

        DebugLogger.shared.log("Registered streak notification categories", level: .diagnostic)
    }

    // MARK: - Quick Workout Options

    /// Get quick workout options based on available time and preferences
    /// - Parameter duration: Optional preferred duration in minutes
    /// - Returns: Array of QuickWorkout options
    func getQuickWorkoutOptions(duration: QuickWorkoutDuration? = nil) -> [QuickWorkout] {
        if let duration = duration {
            return quickWorkoutOptions.filter { $0.durationMinutes == duration.rawValue }
        }
        return quickWorkoutOptions
    }

    /// Generate default quick workout options
    private func generateQuickWorkoutOptions() {
        quickWorkoutOptions = [
            // 5-minute options
            QuickWorkout(
                name: "5-Min Arm Care",
                description: "Quick arm care to protect your streak",
                durationMinutes: 5,
                exerciseCount: 4,
                type: .armCare,
                exercises: [
                    QuickWorkoutExercise(name: "Wrist Circles", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Band Pull-Aparts", reps: 15, sets: 2),
                    QuickWorkoutExercise(name: "External Rotations", reps: 10, sets: 2),
                    QuickWorkoutExercise(name: "Shoulder Stretch", durationSeconds: 30, sets: 2)
                ]
            ),
            QuickWorkout(
                name: "5-Min Stretch",
                description: "Quick full-body stretch",
                durationMinutes: 5,
                exerciseCount: 4,
                type: .stretching,
                exercises: [
                    QuickWorkoutExercise(name: "Standing Quad Stretch", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Standing Hamstring Stretch", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Cross-Body Shoulder Stretch", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Neck Rotations", durationSeconds: 30, sets: 1)
                ]
            ),

            // 10-minute options
            QuickWorkout(
                name: "10-Min Mobility Flow",
                description: "Don't break your streak! Quick mobility session",
                durationMinutes: 10,
                exerciseCount: 6,
                type: .mobility,
                exercises: [
                    QuickWorkoutExercise(name: "Cat-Cow", durationSeconds: 60, sets: 1),
                    QuickWorkoutExercise(name: "World's Greatest Stretch", reps: 5, sets: 2),
                    QuickWorkoutExercise(name: "Hip Circles", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Thoracic Rotations", reps: 10, sets: 2),
                    QuickWorkoutExercise(name: "90/90 Hip Stretch", durationSeconds: 45, sets: 2),
                    QuickWorkoutExercise(name: "Deep Squat Hold", durationSeconds: 60, sets: 1)
                ]
            ),
            QuickWorkout(
                name: "10-Min Arm Care Complete",
                description: "Full arm care routine",
                durationMinutes: 10,
                exerciseCount: 6,
                type: .armCare,
                exercises: [
                    QuickWorkoutExercise(name: "Wrist Flexion/Extension", reps: 15, sets: 2),
                    QuickWorkoutExercise(name: "Forearm Pronation/Supination", reps: 15, sets: 2),
                    QuickWorkoutExercise(name: "Band External Rotations", reps: 12, sets: 2),
                    QuickWorkoutExercise(name: "Band Internal Rotations", reps: 12, sets: 2),
                    QuickWorkoutExercise(name: "Scapular Retractions", reps: 15, sets: 2),
                    QuickWorkoutExercise(name: "Sleeper Stretch", durationSeconds: 45, sets: 2)
                ]
            ),

            // 15-minute options
            QuickWorkout(
                name: "15-Min Express Workout",
                description: "Quick full-body when time is tight",
                durationMinutes: 15,
                exerciseCount: 5,
                type: .express,
                exercises: [
                    QuickWorkoutExercise(name: "Jumping Jacks", durationSeconds: 60, sets: 1),
                    QuickWorkoutExercise(name: "Push-ups", reps: 10, sets: 3),
                    QuickWorkoutExercise(name: "Bodyweight Squats", reps: 15, sets: 3),
                    QuickWorkoutExercise(name: "Plank Hold", durationSeconds: 30, sets: 3),
                    QuickWorkoutExercise(name: "Walking Lunges", reps: 10, sets: 2)
                ]
            ),
            QuickWorkout(
                name: "15-Min Mobility & Stretch",
                description: "Comprehensive mobility session",
                durationMinutes: 15,
                exerciseCount: 8,
                type: .mobility,
                exercises: [
                    QuickWorkoutExercise(name: "Cat-Cow", durationSeconds: 60, sets: 1),
                    QuickWorkoutExercise(name: "Thread the Needle", reps: 8, sets: 2),
                    QuickWorkoutExercise(name: "Hip Flexor Stretch", durationSeconds: 45, sets: 2),
                    QuickWorkoutExercise(name: "Pigeon Pose", durationSeconds: 60, sets: 2),
                    QuickWorkoutExercise(name: "Thoracic Spine Extension", reps: 10, sets: 2),
                    QuickWorkoutExercise(name: "Ankle Mobility", reps: 15, sets: 2),
                    QuickWorkoutExercise(name: "Shoulder Circles", durationSeconds: 30, sets: 2),
                    QuickWorkoutExercise(name: "Full Body Stretch", durationSeconds: 60, sets: 1)
                ]
            )
        ]
    }

    // MARK: - Permission Management

    /// Request notification permission
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                self.hasNotificationPermission = granted
            }

            if granted {
                registerNotificationCategories()
            }

            DebugLogger.shared.log(
                "Notification permission \(granted ? "granted" : "denied") for streak alerts",
                level: .info
            )

            return granted
        } catch {
            DebugLogger.shared.log(
                "Failed to request notification permission: \(error.localizedDescription)",
                level: .error
            )
            return false
        }
    }

    /// Check current notification permission status
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let granted = settings.authorizationStatus == .authorized

        await MainActor.run {
            self.hasNotificationPermission = granted
        }
    }

    // MARK: - Configuration Management

    /// Update streak alert configuration
    func updateConfiguration(_ newConfig: StreakAlertConfiguration) {
        configuration = newConfig
        saveConfiguration()

        // Reschedule notifications with new timing
        Task {
            do {
                try await scheduleStreakAlert()
            } catch {
                DebugLogger.shared.log("Failed to reschedule streak alert after configuration update: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    /// Save configuration to UserDefaults
    private func saveConfiguration() {
        do {
            let data = try JSONEncoder().encode(configuration)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            ErrorLogger.shared.logError(error, context: "StreakAlertService.saveConfiguration")
        }
    }

    // MARK: - Alert Dismissal

    /// Dismiss the streak alert
    func dismissAlert() {
        showStreakAlert = false
    }

    /// Handle notification action
    func handleNotificationAction(_ action: String, userInfo: [AnyHashable: Any]) {
        switch action {
        case "START_QUICK_WORKOUT":
            // Will be handled by app delegate to navigate to quick workout
            DebugLogger.shared.log("User selected Start Quick Workout from notification", level: .info)

        case "REMIND_LATER":
            // Schedule another reminder in 1 hour
            Task {
                try? await scheduleOneHourReminder()
            }
            DebugLogger.shared.log("User selected Remind Later from notification", level: .info)

        case "SKIP_TODAY":
            // User consciously decided to skip
            DebugLogger.shared.log("User selected Skip Today from notification", level: .info)

        default:
            break
        }
    }

    /// Schedule a reminder for 1 hour from now
    private func scheduleOneHourReminder() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Streak Reminder"
        content.body = "Just checking in - have you completed a quick workout yet?"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3600, // 1 hour
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(notificationIdentifier)_reminder",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }
}
