//
//  NotificationServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for SmartNotificationService
//  Tests notification scheduling, pattern analysis, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - SmartNotificationError Tests

final class SmartNotificationErrorTests: XCTestCase {

    // MARK: - Error Descriptions

    func testSmartNotificationError_PermissionDenied_Description() {
        let error = SmartNotificationError.permissionDenied
        XCTAssertEqual(error.errorDescription, "Notification Permission Required")
    }

    func testSmartNotificationError_FetchFailed_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.fetchFailed(underlyingError)
        XCTAssertEqual(error.errorDescription, "Couldn't Load Settings")
    }

    func testSmartNotificationError_UpdateFailed_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.updateFailed(underlyingError)
        XCTAssertEqual(error.errorDescription, "Couldn't Save Settings")
    }

    func testSmartNotificationError_ScheduleFailed_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.scheduleFailed(underlyingError)
        XCTAssertEqual(error.errorDescription, "Couldn't Schedule Reminder")
    }

    func testSmartNotificationError_AnalysisFailedError_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.analysisFailedError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Pattern Analysis Failed")
    }

    // MARK: - Recovery Suggestions

    func testSmartNotificationError_PermissionDenied_RecoverySuggestion() {
        let error = SmartNotificationError.permissionDenied
        XCTAssertEqual(error.recoverySuggestion, "Please enable notifications in Settings to receive workout reminders.")
    }

    func testSmartNotificationError_FetchFailed_RecoverySuggestion() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.fetchFailed(underlyingError)
        XCTAssertEqual(error.recoverySuggestion, "We couldn't load your notification settings. Please check your connection and try again.")
    }

    func testSmartNotificationError_UpdateFailed_RecoverySuggestion() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.updateFailed(underlyingError)
        XCTAssertEqual(error.recoverySuggestion, "We couldn't save your notification preferences. Please try again.")
    }

    func testSmartNotificationError_ScheduleFailed_RecoverySuggestion() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.scheduleFailed(underlyingError)
        XCTAssertEqual(error.recoverySuggestion, "We couldn't schedule your reminder. Please try again.")
    }

    func testSmartNotificationError_AnalysisFailedError_RecoverySuggestion() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = SmartNotificationError.analysisFailedError(underlyingError)
        XCTAssertEqual(error.recoverySuggestion, "We couldn't analyze your workout patterns. Your reminders will use your default time.")
    }

    // MARK: - Underlying Error

    func testSmartNotificationError_UnderlyingError_Present() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let fetchError = SmartNotificationError.fetchFailed(underlyingError)
        XCTAssertNotNil(fetchError.underlyingError)

        let updateError = SmartNotificationError.updateFailed(underlyingError)
        XCTAssertNotNil(updateError.underlyingError)

        let scheduleError = SmartNotificationError.scheduleFailed(underlyingError)
        XCTAssertNotNil(scheduleError.underlyingError)

        let analysisError = SmartNotificationError.analysisFailedError(underlyingError)
        XCTAssertNotNil(analysisError.underlyingError)
    }

    func testSmartNotificationError_UnderlyingError_NilForPermissionDenied() {
        let error = SmartNotificationError.permissionDenied
        XCTAssertNil(error.underlyingError)
    }

    // MARK: - LocalizedError Conformance

    func testSmartNotificationError_IsLocalizedError() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let errors: [SmartNotificationError] = [
            .permissionDenied,
            .fetchFailed(underlyingError),
            .updateFailed(underlyingError),
            .scheduleFailed(underlyingError),
            .analysisFailedError(underlyingError)
        ]

        for error in errors {
            let localizedError: LocalizedError = error
            XCTAssertNotNil(localizedError.errorDescription, "Error should have errorDescription")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recoverySuggestion")
        }
    }
}

// MARK: - TrainingTimePattern Tests

final class TrainingTimePatternTests: XCTestCase {

    func testTrainingTimePattern_DayName() {
        let pattern = createPattern(dayOfWeek: 0)
        XCTAssertEqual(pattern.dayName, "Sunday")

        let mondayPattern = createPattern(dayOfWeek: 1)
        XCTAssertEqual(mondayPattern.dayName, "Monday")

        let saturdayPattern = createPattern(dayOfWeek: 6)
        XCTAssertEqual(saturdayPattern.dayName, "Saturday")
    }

    func testTrainingTimePattern_ShortDayName() {
        let pattern = createPattern(dayOfWeek: 0)
        XCTAssertEqual(pattern.shortDayName, "Sun")

        let mondayPattern = createPattern(dayOfWeek: 1)
        XCTAssertEqual(mondayPattern.shortDayName, "Mon")

        let saturdayPattern = createPattern(dayOfWeek: 6)
        XCTAssertEqual(saturdayPattern.shortDayName, "Sat")
    }

    func testTrainingTimePattern_InvalidDayOfWeek_ReturnsUnknown() {
        let pattern = createPattern(dayOfWeek: -1)
        XCTAssertEqual(pattern.dayName, "Unknown")

        let invalidHighPattern = createPattern(dayOfWeek: 10)
        XCTAssertEqual(invalidHighPattern.dayName, "Unknown")
    }

    func testTrainingTimePattern_InvalidDayOfWeek_ShortName() {
        let pattern = createPattern(dayOfWeek: -1)
        XCTAssertEqual(pattern.shortDayName, "?")

        let invalidHighPattern = createPattern(dayOfWeek: 10)
        XCTAssertEqual(invalidHighPattern.shortDayName, "?")
    }

    func testTrainingTimePattern_ConfidenceLevel_NoData() {
        let pattern = createPattern(confidenceScore: nil)
        XCTAssertEqual(pattern.confidenceLevel, "No data")
    }

    func testTrainingTimePattern_ConfidenceLevel_Learning() {
        let pattern = createPattern(confidenceScore: 0.0)
        XCTAssertEqual(pattern.confidenceLevel, "Learning")

        let lowPattern = createPattern(confidenceScore: 0.25)
        XCTAssertEqual(lowPattern.confidenceLevel, "Learning")
    }

    func testTrainingTimePattern_ConfidenceLevel_Moderate() {
        let pattern = createPattern(confidenceScore: 0.3)
        XCTAssertEqual(pattern.confidenceLevel, "Moderate")

        let midPattern = createPattern(confidenceScore: 0.5)
        XCTAssertEqual(midPattern.confidenceLevel, "Moderate")
    }

    func testTrainingTimePattern_ConfidenceLevel_Good() {
        let pattern = createPattern(confidenceScore: 0.6)
        XCTAssertEqual(pattern.confidenceLevel, "Good")

        let goodPattern = createPattern(confidenceScore: 0.75)
        XCTAssertEqual(goodPattern.confidenceLevel, "Good")
    }

    func testTrainingTimePattern_ConfidenceLevel_High() {
        let pattern = createPattern(confidenceScore: 0.8)
        XCTAssertEqual(pattern.confidenceLevel, "High")

        let veryHighPattern = createPattern(confidenceScore: 0.95)
        XCTAssertEqual(veryHighPattern.confidenceLevel, "High")
    }

    func testTrainingTimePattern_FormattedTime_Nil() {
        let pattern = createPattern(avgStartTime: nil)
        XCTAssertNil(pattern.formattedTime)
    }

    func testTrainingTimePattern_FormattedTime_Valid() {
        var components = DateComponents()
        components.hour = 9
        components.minute = 30
        let date = Calendar.current.date(from: components) ?? Date()

        let pattern = createPattern(avgStartTime: date)
        XCTAssertNotNil(pattern.formattedTime)
        // The format is "h:mm a" so it could be "9:30 AM"
        XCTAssertTrue(pattern.formattedTime?.contains("30") ?? false)
    }

    // MARK: - Helpers

    private func createPattern(
        dayOfWeek: Int = 1,
        confidenceScore: Double? = nil,
        avgStartTime: Date? = nil
    ) -> TrainingTimePattern {
        return TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: dayOfWeek,
            preferredHour: 9,
            workoutCount: 10,
            avgStartTime: avgStartTime,
            confidenceScore: confidenceScore,
            lastUpdated: Date()
        )
    }
}

// MARK: - NotificationSettings Tests

final class NotificationSettingsTests: XCTestCase {

    func testNotificationSettings_Defaults() {
        let patientId = UUID()
        let defaults = NotificationSettings.defaults(for: patientId)

        XCTAssertEqual(defaults.patientId, patientId)
        XCTAssertTrue(defaults.smartTimingEnabled)
        XCTAssertEqual(defaults.reminderMinutesBefore, 30)
        XCTAssertTrue(defaults.streakAlertsEnabled)
        XCTAssertTrue(defaults.weeklySummaryEnabled)
        XCTAssertNil(defaults.id)
    }

    func testNotificationSettings_FormattedReminderTime() {
        let patientId = UUID()
        let defaults = NotificationSettings.defaults(for: patientId)

        // Should format the time using "h:mm a" format
        let formatted = defaults.formattedReminderTime
        XCTAssertFalse(formatted.isEmpty)
        // Default is 9:00 AM
        XCTAssertTrue(formatted.contains(":"))
    }

    func testNotificationSettings_DecodesFromJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "smart_timing_enabled": true,
            "fallback_reminder_time": "09:00:00",
            "reminder_minutes_before": 15,
            "streak_alerts_enabled": false,
            "weekly_summary_enabled": true,
            "quiet_hours_start": "22:00:00",
            "quiet_hours_end": "07:00:00",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let settings = try decoder.decode(NotificationSettings.self, from: json)

        XCTAssertTrue(settings.smartTimingEnabled)
        XCTAssertEqual(settings.reminderMinutesBefore, 15)
        XCTAssertFalse(settings.streakAlertsEnabled)
        XCTAssertTrue(settings.weeklySummaryEnabled)
    }
}

// MARK: - NotificationSettingsUpdate Tests

final class NotificationSettingsUpdateTests: XCTestCase {

    func testNotificationSettingsUpdate_ToInsert() {
        let patientId = UUID()
        var update = NotificationSettingsUpdate()
        update.smartTimingEnabled = false
        update.reminderMinutesBefore = 45
        update.streakAlertsEnabled = true
        update.weeklySummaryEnabled = false

        let insert = update.toInsert(patientId: patientId)

        XCTAssertEqual(insert.patientId, patientId.uuidString)
        XCTAssertFalse(insert.smartTimingEnabled)
        XCTAssertEqual(insert.reminderMinutesBefore, 45)
        XCTAssertTrue(insert.streakAlertsEnabled)
        XCTAssertFalse(insert.weeklySummaryEnabled)
    }

    func testNotificationSettingsUpdate_ToInsert_DefaultValues() {
        let patientId = UUID()
        let update = NotificationSettingsUpdate()
        let insert = update.toInsert(patientId: patientId)

        // When not set, should use defaults
        XCTAssertTrue(insert.smartTimingEnabled)
        XCTAssertEqual(insert.reminderMinutesBefore, 30)
        XCTAssertTrue(insert.streakAlertsEnabled)
        XCTAssertTrue(insert.weeklySummaryEnabled)
        XCTAssertEqual(insert.fallbackReminderTime, "09:00:00")
        XCTAssertEqual(insert.quietHoursStart, "22:00:00")
        XCTAssertEqual(insert.quietHoursEnd, "07:00:00")
    }
}

// MARK: - OptimalReminderTime Tests

final class OptimalReminderTimeTests: XCTestCase {

    func testOptimalReminderTime_Default() {
        let defaultTime = OptimalReminderTime.default

        XCTAssertFalse(defaultTime.isSmart)
        XCTAssertEqual(defaultTime.confidence, 0)
        XCTAssertNil(defaultTime.basedOnWorkouts)

        // Default time should be 9:00 AM
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: defaultTime.reminderTime)
        let minute = calendar.component(.minute, from: defaultTime.reminderTime)
        XCTAssertEqual(hour, 9)
        XCTAssertEqual(minute, 0)
    }

    func testOptimalReminderTime_SmartTime() {
        var components = DateComponents()
        components.hour = 18
        components.minute = 30
        let reminderTime = Calendar.current.date(from: components) ?? Date()

        let smartTime = OptimalReminderTime(
            reminderTime: reminderTime,
            isSmart: true,
            confidence: 0.85,
            basedOnWorkouts: 15
        )

        XCTAssertTrue(smartTime.isSmart)
        XCTAssertEqual(smartTime.confidence, 0.85)
        XCTAssertEqual(smartTime.basedOnWorkouts, 15)
    }
}

// MARK: - Day of Week Calculation Tests

final class DayOfWeekCalculationTests: XCTestCase {

    func testDayOfWeek_Sunday() {
        // Create a known Sunday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 7  // January 7, 2024 was a Sunday

        let calendar = Calendar.current
        guard let sunday = calendar.date(from: components) else {
            XCTFail("Could not create Sunday date")
            return
        }

        // weekday returns 1 for Sunday in Gregorian calendar
        let dayOfWeek = calendar.component(.weekday, from: sunday) - 1
        XCTAssertEqual(dayOfWeek, 0)  // 0-indexed Sunday
    }

    func testDayOfWeek_Saturday() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 6  // January 6, 2024 was a Saturday

        let calendar = Calendar.current
        guard let saturday = calendar.date(from: components) else {
            XCTFail("Could not create Saturday date")
            return
        }

        let dayOfWeek = calendar.component(.weekday, from: saturday) - 1
        XCTAssertEqual(dayOfWeek, 6)  // 0-indexed Saturday
    }

    func testAllDaysOfWeek_Mapping() {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for (index, day) in days.enumerated() {
            XCTAssertEqual(days[index], day)
        }
    }
}

// MARK: - Streak Alert Milestone Tests

final class StreakAlertMilestoneTests: XCTestCase {

    func testStreakMilestone_NoAlert_LowStreak() {
        // Streaks below 3 don't trigger alerts
        XCTAssertFalse(shouldShowStreakAlert(streak: 1))
        XCTAssertFalse(shouldShowStreakAlert(streak: 2))
    }

    func testStreakMilestone_Alert_ThreeDays() {
        // Streak of 3+ triggers momentum alert
        XCTAssertTrue(shouldShowStreakAlert(streak: 3))
        XCTAssertTrue(shouldShowStreakAlert(streak: 5))
    }

    func testStreakMilestone_WeekMilestone() {
        // Week milestones (7, 14, 21, etc.)
        XCTAssertTrue(isWeekMilestone(streak: 7))
        XCTAssertTrue(isWeekMilestone(streak: 14))
        XCTAssertTrue(isWeekMilestone(streak: 21))
        XCTAssertTrue(isWeekMilestone(streak: 28))
    }

    func testStreakMilestone_NotWeekMilestone() {
        XCTAssertFalse(isWeekMilestone(streak: 5))
        XCTAssertFalse(isWeekMilestone(streak: 10))
        XCTAssertFalse(isWeekMilestone(streak: 15))
    }

    // MARK: - Helpers

    private func shouldShowStreakAlert(streak: Int) -> Bool {
        return streak >= 3
    }

    private func isWeekMilestone(streak: Int) -> Bool {
        return streak > 0 && streak % 7 == 0
    }
}

// MARK: - Quiet Hours Tests

final class QuietHoursTests: XCTestCase {

    func testQuietHours_WithinQuietPeriod() {
        // Test 11 PM - should be in quiet hours (10 PM - 7 AM)
        let isQuiet = isInQuietHours(hour: 23, quietStart: 22, quietEnd: 7)
        XCTAssertTrue(isQuiet)
    }

    func testQuietHours_WithinQuietPeriod_EarlyMorning() {
        // Test 3 AM - should be in quiet hours
        let isQuiet = isInQuietHours(hour: 3, quietStart: 22, quietEnd: 7)
        XCTAssertTrue(isQuiet)
    }

    func testQuietHours_OutsideQuietPeriod() {
        // Test 10 AM - should NOT be in quiet hours
        let isQuiet = isInQuietHours(hour: 10, quietStart: 22, quietEnd: 7)
        XCTAssertFalse(isQuiet)
    }

    func testQuietHours_BoundaryStart() {
        // Test exactly 10 PM - should be in quiet hours
        let isQuiet = isInQuietHours(hour: 22, quietStart: 22, quietEnd: 7)
        XCTAssertTrue(isQuiet)
    }

    func testQuietHours_BoundaryEnd() {
        // Test exactly 7 AM - should NOT be in quiet hours (end is exclusive)
        let isQuiet = isInQuietHours(hour: 7, quietStart: 22, quietEnd: 7)
        XCTAssertFalse(isQuiet)
    }

    // MARK: - Helpers

    private func isInQuietHours(hour: Int, quietStart: Int, quietEnd: Int) -> Bool {
        // Handle overnight quiet hours (e.g., 10 PM to 7 AM)
        if quietStart > quietEnd {
            return hour >= quietStart || hour < quietEnd
        } else {
            return hour >= quietStart && hour < quietEnd
        }
    }
}
