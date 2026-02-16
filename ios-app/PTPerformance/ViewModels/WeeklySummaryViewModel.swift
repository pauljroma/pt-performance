//
//  WeeklySummaryViewModel.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  ViewModel for managing weekly summary state and notifications
//

import SwiftUI
import Combine
import UserNotifications

/// ViewModel for the Weekly Summary feature
/// Manages data fetching, caching, and notification scheduling
@MainActor
class WeeklySummarySharedViewModel: ObservableObject {

    // MARK: - Singleton

    static let shared = WeeklySummarySharedViewModel()

    // MARK: - Published Properties

    @Published var currentSummary: WeeklySummary?
    @Published var previousSummary: WeeklySummary?
    @Published var preferences: WeeklySummaryPreferences?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastRefreshDate: Date?

    // MARK: - Private Properties

    private var patientId: UUID?
    private var refreshTask: Task<Void, Never>?
    private let cacheValidityDuration: TimeInterval = 300  // 5 minutes

    // MARK: - Init

    private init() {}

    // MARK: - Configuration

    /// Configure with patient ID (call on login)
    func configure(patientId: UUID) {
        self.patientId = patientId

        // Schedule notifications on configuration
        Task {
            await scheduleNotificationsIfNeeded()
        }
    }

    /// Clear data (call on logout)
    func clearData() {
        currentSummary = nil
        previousSummary = nil
        preferences = nil
        lastRefreshDate = nil
        patientId = nil
        refreshTask?.cancel()
    }

    // MARK: - Data Loading

    /// Load current week summary with caching
    func loadCurrentSummary(forceRefresh: Bool = false) async {
        guard let patientId = patientId else { return }

        // Check cache validity
        if !forceRefresh,
           let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < cacheValidityDuration,
           currentSummary != nil {
            return
        }

        isLoading = true
        error = nil

        do {
            let summary = try await WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            currentSummary = summary
            lastRefreshDate = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Load both current and previous week summaries
    func loadAllSummaries() async {
        guard let patientId = patientId else { return }

        isLoading = true
        error = nil

        do {
            async let currentTask = WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            async let previousTask = WeeklySummaryService.shared.fetchPreviousWeekSummary(for: patientId)
            async let prefsTask = WeeklySummaryService.shared.fetchPreferences(for: patientId)

            let (current, previous, prefs) = try await (currentTask, previousTask, prefsTask)
            currentSummary = current
            previousSummary = previous
            preferences = prefs
            lastRefreshDate = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refresh all data
    func refresh() async {
        refreshTask?.cancel()
        refreshTask = Task {
            await loadAllSummaries()
        }
    }

    // MARK: - Notification Scheduling

    /// Schedule weekly summary notification if enabled
    func scheduleNotificationsIfNeeded() async {
        guard let patientId = patientId else { return }

        // Fetch preferences if not loaded
        if preferences == nil {
            do {
                preferences = try await WeeklySummaryService.shared.fetchPreferences(for: patientId)
            } catch {
                ErrorLogger.shared.logError(error, context: "WeeklySummaryViewModel.scheduleNotificationsIfNeeded")
                return
            }
        }

        guard let prefs = preferences, prefs.notificationEnabled else { return }

        await WeeklySummaryService.shared.scheduleWeeklyNotification(for: patientId, preferences: prefs)
    }

    /// Update notification preferences
    func updatePreferences(_ newPrefs: WeeklySummaryPreferences) async throws {
        try await WeeklySummaryService.shared.updatePreferences(newPrefs)
        preferences = newPrefs
    }

    /// Handle notification action (when user taps notification)
    func handleNotificationAction(response: UNNotificationResponse) {
        guard let patientIdString = response.notification.request.content.userInfo["patient_id"] as? String,
              let notificationPatientId = UUID(uuidString: patientIdString),
              notificationPatientId == patientId else {
            return
        }

        // Trigger data refresh
        Task {
            await refresh()
        }

        // Post notification for UI to show full summary
        NotificationCenter.default.post(
            name: .showWeeklySummary,
            object: nil,
            userInfo: ["patient_id": patientIdString]
        )
    }

    // MARK: - Computed Properties

    /// Whether user should be prompted about weekly summary
    var shouldPromptForNotifications: Bool {
        guard let prefs = preferences else { return true }
        return !prefs.notificationEnabled
    }

    /// Summary for notification display
    var notificationSummaryText: String {
        guard let summary = currentSummary else {
            return "Tap to view your weekly progress"
        }

        var parts: [String] = []

        // Workouts
        parts.append("\(summary.workoutsCompleted)/\(summary.workoutsScheduled) workouts")

        // Streak
        if summary.currentStreak > 0 {
            parts.append("\(summary.currentStreak)-day streak")
        }

        // Volume
        if summary.volumeChangePercent != 0 {
            let direction = summary.volumeChangePercent > 0 ? "up" : "down"
            parts.append("Volume \(direction) \(Int(abs(summary.volumeChangePercent)))%")
        }

        return parts.joined(separator: " | ")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showWeeklySummary = Notification.Name("showWeeklySummary")
}

// MARK: - App Delegate Integration Helper

/// Helper for integrating weekly summary notifications with app lifecycle
class WeeklySummaryNotificationHandler: NSObject, UNUserNotificationCenterDelegate {

    static let shared = WeeklySummaryNotificationHandler()

    private override init() {
        super.init()
    }

    /// Setup notification handling (call in app initialization)
    func setup() {
        UNUserNotificationCenter.current().delegate = self
        WeeklySummaryService.registerNotificationCategories()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification presentation while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if this is a weekly summary notification
        if notification.request.content.categoryIdentifier == "WEEKLY_SUMMARY" {
            // Show banner even when app is in foreground
            completionHandler([.banner, .sound])
        } else {
            completionHandler([])
        }
    }

    /// Handle notification tap/action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Check if this is a weekly summary notification
        if response.notification.request.content.categoryIdentifier == "WEEKLY_SUMMARY" {
            Task { @MainActor in
                WeeklySummarySharedViewModel.shared.handleNotificationAction(response: response)
            }
        }

        completionHandler()
    }
}

// MARK: - Environment Key

private struct WeeklySummaryViewModelKey: EnvironmentKey {
    @MainActor static var defaultValue: WeeklySummarySharedViewModel {
        .shared
    }
}

extension EnvironmentValues {
    var weeklySummaryViewModel: WeeklySummarySharedViewModel {
        get { self[WeeklySummaryViewModelKey.self] }
        set { self[WeeklySummaryViewModelKey.self] = newValue }
    }
}
