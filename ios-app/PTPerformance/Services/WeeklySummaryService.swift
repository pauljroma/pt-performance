//
//  WeeklySummaryService.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Service for fetching and managing weekly summaries with notifications
//

import Foundation
import UserNotifications
import Supabase

/// Service for managing weekly progress summaries
/// Handles data fetching, notification scheduling, and preferences
actor WeeklySummaryService {

    // MARK: - Singleton

    static let shared = WeeklySummaryService()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let notificationIdentifierPrefix = "weekly_summary_"

    // MARK: - Fetch Methods

    /// Fetch the current week's summary for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: WeeklySummary with current week data
    func fetchCurrentWeekSummary(for patientId: UUID) async throws -> WeeklySummary {
        let weekStart = getLastSundayDate()
        return try await fetchWeeklySummary(for: patientId, weekStart: weekStart)
    }

    /// Fetch the previous week's summary for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: WeeklySummary with previous week data
    func fetchPreviousWeekSummary(for patientId: UUID) async throws -> WeeklySummary {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: getLastSundayDate()) ?? Date()
        return try await fetchWeeklySummary(for: patientId, weekStart: weekStart)
    }

    /// Fetch weekly summary for a specific week
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - weekStart: The start date of the week
    /// - Returns: WeeklySummary for the specified week
    func fetchWeeklySummary(for patientId: UUID, weekStart: Date) async throws -> WeeklySummary {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let weekStartString = dateFormatter.string(from: weekStart)

        do {
            // Call the database function
            let response = try await supabase
                .rpc("get_weekly_summary", params: [
                    "p_patient_id": patientId.uuidString,
                    "p_week_start": weekStartString
                ])
                .execute()

            // Decode the response
            let summaries = try PTSupabaseClient.flexibleDecoder.decode([WeeklySummary].self, from: response.data)

            guard let summary = summaries.first else {
                throw WeeklySummaryError.noDataAvailable
            }

            return summary
        } catch let error as WeeklySummaryError {
            throw error
        } catch {
            errorLogger.logError(error, context: "fetchWeeklySummary(patient=\(patientId))")
            throw WeeklySummaryError.fetchFailed(error)
        }
    }

    /// Fetch summary history for a patient
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - limit: Maximum number of weeks to fetch (default: 12)
    /// - Returns: Array of historical weekly summaries
    func fetchSummaryHistory(for patientId: UUID, limit: Int = 12) async throws -> [WeeklySummary] {
        do {
            let response: [WeeklySummary] = try await supabase
                .from("weekly_summary_history")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("week_start_date", ascending: false)
                .limit(limit)
                .execute()
                .value

            return response
        } catch {
            errorLogger.logError(error, context: "fetchSummaryHistory(patient=\(patientId))")
            throw WeeklySummaryError.fetchFailed(error)
        }
    }

    /// Save a weekly summary to history
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - weekStart: Optional week start date (defaults to last week)
    /// - Returns: The saved history record ID
    @discardableResult
    func saveSummaryToHistory(for patientId: UUID, weekStart: Date? = nil) async throws -> UUID {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let weekStartString = weekStart.map { dateFormatter.string(from: $0) }

        do {
            struct SaveResult: Codable {
                let result: UUID

                enum CodingKeys: String, CodingKey {
                    case result = "save_weekly_summary"
                }
            }

            let params: [String: AnyEncodable]
            if let weekStartString = weekStartString {
                params = [
                    "p_patient_id": AnyEncodable(patientId.uuidString),
                    "p_week_start": AnyEncodable(weekStartString)
                ]
            } else {
                params = [
                    "p_patient_id": AnyEncodable(patientId.uuidString)
                ]
            }

            let response = try await supabase
                .rpc("save_weekly_summary", params: params)
                .execute()

            // Parse the UUID from response
            if let uuidString = String(data: response.data, encoding: .utf8)?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"")) {
                if let uuid = UUID(uuidString: uuidString) {
                    return uuid
                }
            }

            throw WeeklySummaryError.saveFailed
        } catch let error as WeeklySummaryError {
            throw error
        } catch {
            errorLogger.logError(error, context: "saveSummaryToHistory(patient=\(patientId))")
            throw WeeklySummaryError.saveFailed
        }
    }

    // MARK: - Preferences Methods

    /// Fetch notification preferences for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: WeeklySummaryPreferences or default if not set
    func fetchPreferences(for patientId: UUID) async throws -> WeeklySummaryPreferences {
        do {
            let preferences: [WeeklySummaryPreferences] = try await supabase
                .from("weekly_summary_preferences")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .limit(1)
                .execute()
                .value

            return preferences.first ?? WeeklySummaryPreferences.defaultPreferences(for: patientId)
        } catch {
            errorLogger.logError(error, context: "fetchPreferences(patient=\(patientId))")
            // Return defaults on error
            return WeeklySummaryPreferences.defaultPreferences(for: patientId)
        }
    }

    /// Update notification preferences
    /// - Parameter preferences: The updated preferences
    func updatePreferences(_ preferences: WeeklySummaryPreferences) async throws {
        do {
            try await supabase
                .from("weekly_summary_preferences")
                .upsert([
                    "patient_id": preferences.patientId.uuidString,
                    "notification_enabled": String(preferences.notificationEnabled),
                    "notification_day": preferences.notificationDay.rawValue,
                    "notification_hour": String(preferences.notificationHour)
                ])
                .execute()

            // Reschedule notification with new preferences
            if preferences.notificationEnabled {
                await scheduleWeeklyNotification(for: preferences.patientId, preferences: preferences)
            } else {
                await cancelWeeklyNotification(for: preferences.patientId)
            }
        } catch {
            errorLogger.logError(error, context: "updatePreferences(patient=\(preferences.patientId))")
            throw WeeklySummaryError.updateFailed(error)
        }
    }

    // MARK: - Notification Methods

    /// Generate notification content from a weekly summary
    /// - Parameter summary: The weekly summary to generate content for
    /// - Returns: UNMutableNotificationContent with title and body
    func generateNotificationContent(from summary: WeeklySummary) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // Title with emoji based on performance
        content.title = "Your Week in Review"

        // Build body with key highlights
        var bodyParts: [String] = []

        // Workouts completed
        if summary.workoutsCompleted == summary.workoutsScheduled && summary.workoutsScheduled > 0 {
            bodyParts.append("\(summary.workoutsCompleted)/\(summary.workoutsScheduled) workouts")
        } else {
            bodyParts.append("\(summary.workoutsCompleted)/\(summary.workoutsScheduled) workouts")
        }

        // Streak
        if summary.currentStreak > 0 {
            bodyParts.append("\(summary.currentStreak)-day streak")
        }

        // Volume change
        if summary.volumeChangePercent != 0 {
            let direction = summary.volumeChangePercent > 0 ? "up" : "down"
            bodyParts.append("Volume \(direction) \(Int(abs(summary.volumeChangePercent)))%")
        }

        content.body = bodyParts.joined(separator: " | ")

        // Add sound and badge
        content.sound = .default
        content.badge = 1

        // Add deep link to summary view
        content.userInfo = [
            "type": "weekly_summary",
            "week_start": ISO8601DateFormatter().string(from: summary.weekStartDate)
        ]

        // Category for actionable notifications
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        return content
    }

    /// Schedule the weekly summary notification
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - preferences: Optional preferences (will fetch if not provided)
    func scheduleWeeklyNotification(for patientId: UUID, preferences: WeeklySummaryPreferences? = nil) async {
        // Get preferences
        let prefs: WeeklySummaryPreferences
        if let preferences = preferences {
            prefs = preferences
        } else {
            do {
                prefs = try await fetchPreferences(for: patientId)
            } catch {
                errorLogger.logError(error, context: "scheduleWeeklyNotification - fetch preferences failed")
                return
            }
        }

        guard prefs.notificationEnabled else {
            await cancelWeeklyNotification(for: patientId)
            return
        }

        // Request notification permission if needed
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                DebugLogger.shared.info("WeeklySummary", "Notification permission not granted")
                return
            }
        } catch {
            errorLogger.logError(error, context: "scheduleWeeklyNotification - permission request failed")
            return
        }

        // Cancel existing notification
        await cancelWeeklyNotification(for: patientId)

        // Create trigger for weekly notification
        var dateComponents = DateComponents()
        dateComponents.weekday = prefs.notificationDay.weekday
        dateComponents.hour = prefs.notificationHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create placeholder content (will be updated when notification fires)
        let content = UNMutableNotificationContent()
        content.title = "Your Week in Review"
        content.body = "Tap to see your weekly progress summary"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        content.userInfo = [
            "type": "weekly_summary",
            "patient_id": patientId.uuidString
        ]

        let identifier = "\(notificationIdentifierPrefix)\(patientId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            DebugLogger.shared.info("WeeklySummary",
                "Scheduled weekly notification for \(prefs.notificationDay.rawValue) at \(prefs.notificationHour):00"
            )
        } catch {
            errorLogger.logError(error, context: "scheduleWeeklyNotification - add request failed")
        }
    }

    /// Cancel weekly summary notification
    /// - Parameter patientId: The patient's UUID
    func cancelWeeklyNotification(for patientId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "\(notificationIdentifierPrefix)\(patientId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        DebugLogger.shared.info("WeeklySummary", "Cancelled weekly notification for patient \(patientId)")
    }

    /// Update notification content with actual summary data
    /// Called when the app launches or becomes active near notification time
    func updateScheduledNotificationContent(for patientId: UUID) async {
        do {
            let summary = try await fetchPreviousWeekSummary(for: patientId)
            let content = generateNotificationContent(from: summary)

            // Get existing notification and update
            let center = UNUserNotificationCenter.current()
            let identifier = "\(notificationIdentifierPrefix)\(patientId.uuidString)"

            let pending = await center.pendingNotificationRequests()
            guard let existing = pending.first(where: { $0.identifier == identifier }),
                  let trigger = existing.trigger else {
                return
            }

            // Remove old and add updated
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try await center.add(request)

        } catch {
            errorLogger.logError(error, context: "updateScheduledNotificationContent(patient=\(patientId))")
        }
    }

    // MARK: - Notification Categories Setup

    /// Register notification categories and actions
    /// Call this during app initialization
    nonisolated static func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SUMMARY",
            title: "View Full Summary",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "WEEKLY_SUMMARY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Helper Methods

    /// Get the date of last Sunday (or today if Sunday)
    private func getLastSundayDate() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 0 : weekday - 1
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }
}

// MARK: - UUID Convenience

extension WeeklySummaryService {
    /// Fetch current week summary using string ID
    func fetchCurrentWeekSummary(for patientIdString: String) async throws -> WeeklySummary {
        guard let patientId = UUID(uuidString: patientIdString) else {
            throw WeeklySummaryError.invalidPatientId
        }
        return try await fetchCurrentWeekSummary(for: patientId)
    }

    /// Fetch summary history using string ID
    func fetchSummaryHistory(for patientIdString: String, limit: Int = 12) async throws -> [WeeklySummary] {
        guard let patientId = UUID(uuidString: patientIdString) else {
            throw WeeklySummaryError.invalidPatientId
        }
        return try await fetchSummaryHistory(for: patientId, limit: limit)
    }
}

// MARK: - Error Types

enum WeeklySummaryError: LocalizedError {
    case fetchFailed(Error)
    case noDataAvailable
    case saveFailed
    case updateFailed(Error)
    case invalidPatientId
    case notificationPermissionDenied

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Couldn't Load Summary"
        case .noDataAvailable:
            return "No Data Available"
        case .saveFailed:
            return "Couldn't Save Summary"
        case .updateFailed:
            return "Couldn't Update Preferences"
        case .invalidPatientId:
            return "Invalid Patient ID"
        case .notificationPermissionDenied:
            return "Notifications Disabled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .noDataAvailable:
            return "Complete some workouts to see your weekly summary."
        case .saveFailed:
            return "Please try again in a moment."
        case .updateFailed:
            return "Please try updating your preferences again."
        case .invalidPatientId:
            return "Please sign out and sign back in."
        case .notificationPermissionDenied:
            return "Enable notifications in Settings to receive weekly summaries."
        }
    }
}

// MARK: - AnyEncodable Helper

/// Type-erased Encodable for RPC params
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
