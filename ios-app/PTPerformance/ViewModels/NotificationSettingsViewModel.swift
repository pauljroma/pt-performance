//
//  NotificationSettingsViewModel.swift
//  PTPerformance
//
//  X2Index Phase 2: Notification Settings ViewModel
//  Manages notification preferences for athletes and PTs
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Notification Settings ViewModel

/// ViewModel for managing notification settings
///
/// Handles:
/// - Loading/saving notification preferences
/// - Permission requests
/// - Check-in reminder time configuration
/// - Task reminder toggle
/// - PT alert toggle (for therapists)
///
/// ## Usage
/// ```swift
/// @StateObject private var viewModel = NotificationSettingsViewModel()
///
/// Toggle("Task Reminders", isOn: $viewModel.taskRemindersEnabled)
///     .onChange(of: viewModel.taskRemindersEnabled) { _ in
///         Task { await viewModel.saveSettings() }
///     }
/// ```
@MainActor
final class NotificationSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Master toggle for all notifications
    @Published var isEnabled: Bool = false {
        didSet {
            if oldValue != isEnabled {
                handleMasterToggleChange()
            }
        }
    }

    /// Time for daily check-in reminders
    @Published var checkInReminderTime: Date = defaultCheckInTime()

    /// Whether task reminders are enabled
    @Published var taskRemindersEnabled: Bool = true

    /// Whether PT alerts are enabled (for therapists only)
    @Published var ptAlertsEnabled: Bool = true

    /// Whether streak milestone notifications are enabled
    @Published var streakMilestonesEnabled: Bool = true

    /// Whether brief notifications are enabled
    @Published var briefNotificationsEnabled: Bool = true

    /// Current authorization status
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Loading state
    @Published var isLoading: Bool = false

    /// Saving state
    @Published var isSaving: Bool = false

    /// Error state
    @Published var error: NotificationSettingsError?

    /// Whether to show error alert
    @Published var showError: Bool = false

    /// Success message for test notification
    @Published var testNotificationSent: Bool = false

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let notificationManager = PushNotificationManager.shared
    private let errorLogger = ErrorLogger.shared
    private let debugLogger = DebugLogger.shared
    private var cancellables = Set<AnyCancellable>()

    /// Whether the current user is a therapist
    private var isTherapist: Bool = false

    // MARK: - Initialization

    init() {
        // Observe auth status changes via userId
        supabase.$userId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                if userId != nil {
                    Task {
                        await self?.loadSettings()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load notification settings from backend
    func loadSettings() async {
        guard supabase.userId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        // Check authorization status
        authorizationStatus = await notificationManager.getAuthorizationStatus()
        isEnabled = authorizationStatus == .authorized || authorizationStatus == .provisional

        // Determine if user is a therapist
        isTherapist = await checkIfTherapist()

        // Load settings from database
        do {
            guard let userId = supabase.userId else { return }

            let settings: [NotificationPreferencesRow] = try await supabase.client
                .from("user_notification_preferences")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            if let prefs = settings.first {
                checkInReminderTime = parseTimeString(prefs.checkInReminderTime) ?? Self.defaultCheckInTime()
                taskRemindersEnabled = prefs.taskRemindersEnabled
                ptAlertsEnabled = prefs.ptAlertsEnabled
                streakMilestonesEnabled = prefs.streakMilestonesEnabled
                briefNotificationsEnabled = prefs.briefNotificationsEnabled
            }

            debugLogger.log("Loaded notification settings", level: .success)
        } catch {
            errorLogger.logError(error, context: "NotificationSettingsViewModel.loadSettings")
            // Use defaults on error - don't surface to user
        }
    }

    /// Save current notification settings
    func saveSettings() async {
        guard supabase.userId != nil else { return }
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            guard let userId = supabase.userId else { return }

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let timeString = timeFormatter.string(from: checkInReminderTime)

            let payload = NotificationPreferencesRow(
                userId: userId,
                checkInReminderTime: timeString,
                taskRemindersEnabled: taskRemindersEnabled,
                ptAlertsEnabled: ptAlertsEnabled,
                streakMilestonesEnabled: streakMilestonesEnabled,
                briefNotificationsEnabled: briefNotificationsEnabled
            )

            try await supabase.client
                .from("user_notification_preferences")
                .upsert(payload, onConflict: "user_id")
                .execute()

            // Update local notification schedules
            await updateLocalSchedules()

            debugLogger.log("Saved notification settings", level: .success)
        } catch {
            errorLogger.logError(error, context: "NotificationSettingsViewModel.saveSettings")
            self.error = .saveFailed
            self.showError = true
        }
    }

    /// Request notification permission if needed
    func requestPermissionIfNeeded() async {
        guard authorizationStatus == .notDetermined || authorizationStatus == .denied else {
            return
        }

        let granted = await notificationManager.requestPermission()
        authorizationStatus = await notificationManager.getAuthorizationStatus()
        isEnabled = granted

        if granted {
            await saveSettings()
        }
    }

    /// Send a test notification to verify setup
    func sendTestNotification() async {
        guard await notificationManager.isAuthorized() else {
            error = .notAuthorized
            showError = true
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Notifications are working correctly!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "com.getmodus.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            testNotificationSent = true

            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.testNotificationSent = false
            }

            debugLogger.log("Test notification scheduled", level: .success)
        } catch {
            errorLogger.logError(error, context: "NotificationSettingsViewModel.sendTestNotification")
            self.error = .testFailed
            self.showError = true
        }
    }

    /// Open system notification settings
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Check if the user is a therapist
    var showPTAlertToggle: Bool {
        isTherapist
    }

    // MARK: - Private Methods

    /// Handle master toggle change
    private func handleMasterToggleChange() {
        if isEnabled {
            Task {
                await requestPermissionIfNeeded()
            }
        } else {
            Task {
                // Cancel all local notifications when disabled
                await notificationManager.cancelAllScheduled()
            }
        }
    }

    /// Update local notification schedules based on current settings
    private func updateLocalSchedules() async {
        // Update check-in reminder
        if isEnabled && taskRemindersEnabled {
            let components = Calendar.current.dateComponents(
                [.hour, .minute],
                from: checkInReminderTime
            )
            await notificationManager.scheduleCheckInReminder(at: components)
        } else {
            await notificationManager.cancelNotifications(
                withPrefix: "com.getmodus.checkin"
            )
        }
    }

    /// Check if current user is a therapist
    private func checkIfTherapist() async -> Bool {
        guard let userId = supabase.userId else { return false }

        do {
            let therapists: [TherapistCheckRow] = try await supabase.client
                .from("therapists")
                .select("id")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            return !therapists.isEmpty
        } catch {
            return false
        }
    }

    /// Parse time string in "HH:mm:ss" format
    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        if let date = formatter.date(from: timeString) {
            // Combine with today's date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return calendar.date(bySettingHour: components.hour ?? 8,
                                 minute: components.minute ?? 0,
                                 second: 0,
                                 of: Date())
        }
        return nil
    }

    /// Default check-in time (8:00 AM)
    static func defaultCheckInTime() -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Database Row Types

/// Row type for notification preferences
private struct NotificationPreferencesRow: Codable {
    let userId: String
    let checkInReminderTime: String
    let taskRemindersEnabled: Bool
    let ptAlertsEnabled: Bool
    let streakMilestonesEnabled: Bool
    let briefNotificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case checkInReminderTime = "check_in_reminder_time"
        case taskRemindersEnabled = "task_reminders_enabled"
        case ptAlertsEnabled = "pt_alerts_enabled"
        case streakMilestonesEnabled = "streak_milestones_enabled"
        case briefNotificationsEnabled = "brief_notifications_enabled"
    }
}

/// Row type for therapist check
private struct TherapistCheckRow: Codable {
    let id: UUID
}

// MARK: - Errors

/// Errors for notification settings operations
enum NotificationSettingsError: LocalizedError, Identifiable {
    case loadFailed
    case saveFailed
    case notAuthorized
    case testFailed

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Couldn't Load Settings"
        case .saveFailed:
            return "Couldn't Save Settings"
        case .notAuthorized:
            return "Notifications Not Enabled"
        case .testFailed:
            return "Test Failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .loadFailed:
            return "Please try again later."
        case .saveFailed:
            return "Your settings couldn't be saved. Please try again."
        case .notAuthorized:
            return "Please enable notifications in Settings to send a test."
        case .testFailed:
            return "We couldn't send the test notification. Please try again."
        }
    }
}
