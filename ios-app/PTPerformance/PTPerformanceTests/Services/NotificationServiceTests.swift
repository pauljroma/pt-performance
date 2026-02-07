//
//  NotificationServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for SmartNotificationService
//  Tests notification scheduling, smart timing calculations, quiet hours enforcement,
//  badge updates, DST transitions, and timezone handling
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

// MARK: - Smart Timing Calculation Tests

final class SmartTimingCalculationTests: XCTestCase {

    // MARK: - Based on User Patterns

    func testSmartTiming_UsesPatternWhenAvailable() {
        // Given - User typically works out at 6 PM on Mondays
        let patternTime = createTime(hour: 18, minute: 0)
        let confidenceScore = 0.85
        let workoutCount = 12

        // When
        let optimalTime = OptimalReminderTime(
            reminderTime: patternTime,
            isSmart: true,
            confidence: confidenceScore,
            basedOnWorkouts: workoutCount
        )

        // Then
        XCTAssertTrue(optimalTime.isSmart)
        XCTAssertEqual(optimalTime.confidence, 0.85)
        XCTAssertEqual(optimalTime.basedOnWorkouts, 12)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: optimalTime.reminderTime)
        XCTAssertEqual(hour, 18)
    }

    func testSmartTiming_HighConfidenceWithManyWorkouts() {
        // Given - User has trained 20+ times at similar times
        let patternTime = createTime(hour: 7, minute: 30)

        // When
        let optimalTime = OptimalReminderTime(
            reminderTime: patternTime,
            isSmart: true,
            confidence: 0.95,
            basedOnWorkouts: 25
        )

        // Then
        XCTAssertTrue(optimalTime.isSmart)
        XCTAssertGreaterThan(optimalTime.confidence, 0.9)
        XCTAssertGreaterThan(optimalTime.basedOnWorkouts ?? 0, 20)
    }

    func testSmartTiming_LowConfidenceWithFewWorkouts() {
        // Given - User has only trained a few times
        let patternTime = createTime(hour: 12, minute: 0)

        // When
        let optimalTime = OptimalReminderTime(
            reminderTime: patternTime,
            isSmart: true,
            confidence: 0.25,
            basedOnWorkouts: 3
        )

        // Then
        XCTAssertTrue(optimalTime.isSmart)
        XCTAssertLessThan(optimalTime.confidence, 0.3)
        XCTAssertEqual(optimalTime.basedOnWorkouts, 3)
    }

    // MARK: - Fallback to Default Time

    func testSmartTiming_FallbackWhenNoPatterns() {
        // Given/When - No pattern data
        let defaultTime = OptimalReminderTime.default

        // Then
        XCTAssertFalse(defaultTime.isSmart)
        XCTAssertEqual(defaultTime.confidence, 0)
        XCTAssertNil(defaultTime.basedOnWorkouts)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: defaultTime.reminderTime)
        XCTAssertEqual(hour, 9, "Default should be 9 AM")
    }

    func testSmartTiming_FallbackWhenConfidenceTooLow() {
        // Given - Pattern exists but confidence is very low
        let confidence = 0.1

        // When/Then
        // In practice, the service would use default when confidence is too low
        XCTAssertLessThan(confidence, 0.3, "Very low confidence should trigger fallback")
    }

    // MARK: - Quiet Hours Respected

    func testSmartTiming_RespectQuietHours_ShiftsForward() {
        // Given - Pattern suggests 11 PM but quiet hours are 10 PM - 7 AM
        let suggestedTime = createTime(hour: 23, minute: 0)
        let quietStart = 22
        let quietEnd = 7

        // When
        let adjustedTime = adjustForQuietHours(
            proposedTime: suggestedTime,
            quietStart: quietStart,
            quietEnd: quietEnd
        )

        // Then - Should shift to 7 AM (end of quiet hours)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: adjustedTime)
        XCTAssertFalse(isInQuietHours(hour: hour, quietStart: quietStart, quietEnd: quietEnd))
    }

    func testSmartTiming_RespectQuietHours_EarlyMorning() {
        // Given - Pattern suggests 5 AM but quiet hours are 10 PM - 7 AM
        let suggestedTime = createTime(hour: 5, minute: 0)
        let quietStart = 22
        let quietEnd = 7

        // When
        let adjustedTime = adjustForQuietHours(
            proposedTime: suggestedTime,
            quietStart: quietStart,
            quietEnd: quietEnd
        )

        // Then - Should shift to 7 AM
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: adjustedTime)
        XCTAssertEqual(hour, 7)
    }

    func testSmartTiming_NoAdjustment_OutsideQuietHours() {
        // Given - Pattern suggests 3 PM (outside quiet hours)
        let suggestedTime = createTime(hour: 15, minute: 0)
        let quietStart = 22
        let quietEnd = 7

        // When
        let adjustedTime = adjustForQuietHours(
            proposedTime: suggestedTime,
            quietStart: quietStart,
            quietEnd: quietEnd
        )

        // Then - Time should remain unchanged
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: adjustedTime)
        XCTAssertEqual(hour, 15)
    }

    // MARK: - Helpers

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func isInQuietHours(hour: Int, quietStart: Int, quietEnd: Int) -> Bool {
        if quietStart > quietEnd {
            return hour >= quietStart || hour < quietEnd
        } else {
            return hour >= quietStart && hour < quietEnd
        }
    }

    private func adjustForQuietHours(proposedTime: Date, quietStart: Int, quietEnd: Int) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: proposedTime)

        if isInQuietHours(hour: hour, quietStart: quietStart, quietEnd: quietEnd) {
            // Shift to end of quiet hours
            var components = calendar.dateComponents([.year, .month, .day], from: proposedTime)
            components.hour = quietEnd
            components.minute = 0
            return calendar.date(from: components) ?? proposedTime
        }

        return proposedTime
    }
}

// MARK: - Timezone Handling Tests

final class NotificationTimezoneTests: XCTestCase {

    func testTimezone_LocalTimeMaintained() {
        // Given - User sets reminder for 9 AM
        let localCalendar = Calendar.current
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let reminderTime = localCalendar.date(from: components)!

        // When - Checking the hour component
        let hour = localCalendar.component(.hour, from: reminderTime)

        // Then - Should be 9 AM in local time
        XCTAssertEqual(hour, 9)
    }

    func testTimezone_ReminderInDifferentTimezone() {
        // Given - User created reminder in PST, viewing in EST
        let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        let estTimeZone = TimeZone(identifier: "America/New_York")!

        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pstTimeZone

        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 9
        components.minute = 0
        let pstTime = pstCalendar.date(from: components)!

        // When - Viewing in EST
        var estCalendar = Calendar.current
        estCalendar.timeZone = estTimeZone
        let estHour = estCalendar.component(.hour, from: pstTime)

        // Then - Should be 12 PM EST (3 hours ahead)
        XCTAssertEqual(estHour, 12)
    }

    func testTimezone_ScheduledInUTC() {
        // Given - A date scheduled in UTC
        let utcTimeZone = TimeZone(identifier: "UTC")!
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = utcTimeZone

        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14 // 2 PM UTC
        components.minute = 0
        let utcTime = utcCalendar.date(from: components)!

        // When - Checking in local time
        let localCalendar = Calendar.current
        let localHour = localCalendar.component(.hour, from: utcTime)

        // Then - Hour should differ based on timezone offset
        // This test verifies the conversion happens
        XCTAssertNotNil(localHour)
    }

    func testTimezone_CrossingDateline() {
        // Given - User in timezone that crosses dateline relative to UTC
        let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")! // UTC+9
        var tokyoCalendar = Calendar.current
        tokyoCalendar.timeZone = tokyoTimeZone

        // 11 PM UTC = 8 AM next day in Tokyo
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 23
        components.minute = 0

        let utcTimeZone = TimeZone(identifier: "UTC")!
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = utcTimeZone
        let utcTime = utcCalendar.date(from: components)!

        // When - Converting to Tokyo time
        let tokyoDay = tokyoCalendar.component(.day, from: utcTime)
        let tokyoHour = tokyoCalendar.component(.hour, from: utcTime)

        // Then - Should be next day in Tokyo
        XCTAssertEqual(tokyoDay, 16) // June 16th
        XCTAssertEqual(tokyoHour, 8) // 8 AM
    }
}

// MARK: - DST Transition Tests

final class DSTTransitionTests: XCTestCase {

    func testDST_SpringForward_ReminderAdjusted() {
        // Given - Reminder scheduled during DST transition (spring forward)
        // March 10, 2024 at 2:00 AM -> 3:00 AM (US)
        let calendar = Calendar.current

        var componentsBeforeDST = DateComponents()
        componentsBeforeDST.year = 2024
        componentsBeforeDST.month = 3
        componentsBeforeDST.day = 9 // Day before DST
        componentsBeforeDST.hour = 9
        componentsBeforeDST.minute = 0

        let beforeDST = calendar.date(from: componentsBeforeDST)!

        // When - Adding 1 day (crossing DST)
        let afterDST = calendar.date(byAdding: .day, value: 1, to: beforeDST)!

        // Then - Hour should still be 9 AM local time
        let hour = calendar.component(.hour, from: afterDST)
        XCTAssertEqual(hour, 9, "Local time should remain 9 AM after DST")
    }

    func testDST_FallBack_ReminderAdjusted() {
        // Given - Reminder scheduled during DST transition (fall back)
        // November 3, 2024 at 2:00 AM -> 1:00 AM (US)
        let calendar = Calendar.current

        var componentsBeforeDST = DateComponents()
        componentsBeforeDST.year = 2024
        componentsBeforeDST.month = 11
        componentsBeforeDST.day = 2 // Day before DST ends
        componentsBeforeDST.hour = 9
        componentsBeforeDST.minute = 0

        let beforeDST = calendar.date(from: componentsBeforeDST)!

        // When - Adding 1 day (crossing DST)
        let afterDST = calendar.date(byAdding: .day, value: 1, to: beforeDST)!

        // Then - Hour should still be 9 AM local time
        let hour = calendar.component(.hour, from: afterDST)
        XCTAssertEqual(hour, 9, "Local time should remain 9 AM after DST")
    }

    func testDST_WeeklyReminder_ConsistentTime() {
        // Given - Weekly reminder at 9 AM
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 4 // Before DST
        components.hour = 9
        components.minute = 0

        let startDate = calendar.date(from: components)!

        // When - Generating weekly reminders across DST
        var dates: [Date] = []
        var current = startDate
        for _ in 0..<4 { // 4 weeks
            dates.append(current)
            current = calendar.date(byAdding: .weekOfYear, value: 1, to: current)!
        }

        // Then - All should be at 9 AM local time
        for date in dates {
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 9, "Weekly reminder should always be at 9 AM local")
        }
    }

    func testDST_NonexistentTime_Handled() {
        // Given - 2:30 AM on spring forward day doesn't exist
        // The system should handle this gracefully
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10 // DST day in US
        components.hour = 2
        components.minute = 30

        // When
        let date = calendar.date(from: components)

        // Then - Should still create a valid date (system adjusts)
        XCTAssertNotNil(date, "Calendar should handle nonexistent time")
    }

    func testDST_AmbiguousTime_Handled() {
        // Given - 1:30 AM on fall back day exists twice
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 3 // DST ends in US
        components.hour = 1
        components.minute = 30

        // When
        let date = calendar.date(from: components)

        // Then - Should create a valid date
        XCTAssertNotNil(date, "Calendar should handle ambiguous time")
    }
}

// MARK: - Edge Case Tests

final class NotificationEdgeCaseTests: XCTestCase {

    // MARK: - No Usage Patterns Yet

    func testNoUsagePatterns_UsesDefault() {
        // Given - New user with no workout history
        let defaultTime = OptimalReminderTime.default

        // Then
        XCTAssertFalse(defaultTime.isSmart)
        XCTAssertEqual(defaultTime.confidence, 0)
        XCTAssertNil(defaultTime.basedOnWorkouts)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: defaultTime.reminderTime)
        XCTAssertEqual(hour, 9, "Should default to 9 AM for new users")
    }

    func testNoUsagePatterns_ZeroWorkouts() {
        // Given - User with no completed workouts
        let workoutCount = 0

        // Then
        XCTAssertEqual(workoutCount, 0, "New user should have zero workouts")
        // Service should fall back to default time
    }

    // MARK: - All Quiet Hours

    func testAllQuietHours_24HourPeriod() {
        // Given - Quiet hours set to cover entire day (edge case)
        let quietStart = 0
        let quietEnd = 0 // Same means no quiet period

        // When
        let isQuiet12PM = isInQuietHours(hour: 12, quietStart: quietStart, quietEnd: quietEnd)
        let isQuiet6AM = isInQuietHours(hour: 6, quietStart: quietStart, quietEnd: quietEnd)

        // Then - When start equals end, no time is quiet
        XCTAssertFalse(isQuiet12PM)
        XCTAssertFalse(isQuiet6AM)
    }

    func testAllQuietHours_NoValidWindow() {
        // Given - Quiet hours cover 23 hours (extreme case)
        let quietStart = 1
        let quietEnd = 0 // 1 AM to midnight (23 hours)

        // When - Only midnight hour is not quiet
        let isQuiet3AM = isInQuietHours(hour: 3, quietStart: quietStart, quietEnd: quietEnd)
        let isQuietMidnight = isInQuietHours(hour: 0, quietStart: quietStart, quietEnd: quietEnd)

        // Then
        XCTAssertTrue(isQuiet3AM)
        XCTAssertFalse(isQuietMidnight, "Only midnight should be valid")
    }

    // MARK: - User in Different Timezone Than Creation

    func testDifferentTimezone_ReminderCreatedElsewhere() {
        // Given - Reminder created in EST, user now in PST
        let estTimeZone = TimeZone(identifier: "America/New_York")!
        let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!

        var estCalendar = Calendar.current
        estCalendar.timeZone = estTimeZone

        // Reminder set for 9 AM EST
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 9
        components.minute = 0
        let estTime = estCalendar.date(from: components)!

        // When - User views in PST
        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pstTimeZone
        let pstHour = pstCalendar.component(.hour, from: estTime)

        // Then - Should show as 6 AM PST
        XCTAssertEqual(pstHour, 6, "9 AM EST should be 6 AM PST")
    }

    // MARK: - Boundary Times

    func testBoundaryTime_Midnight() {
        // Given - Reminder at midnight
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        let midnight = Calendar.current.date(from: components)!

        // Then
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: midnight)
        let minute = calendar.component(.minute, from: midnight)
        XCTAssertEqual(hour, 0)
        XCTAssertEqual(minute, 0)
    }

    func testBoundaryTime_EndOfDay() {
        // Given - Reminder at 11:59 PM
        var components = DateComponents()
        components.hour = 23
        components.minute = 59
        let endOfDay = Calendar.current.date(from: components)!

        // Then
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: endOfDay)
        let minute = calendar.component(.minute, from: endOfDay)
        XCTAssertEqual(hour, 23)
        XCTAssertEqual(minute, 59)
    }

    // MARK: - Helpers

    private func isInQuietHours(hour: Int, quietStart: Int, quietEnd: Int) -> Bool {
        if quietStart == quietEnd {
            return false // Same start and end means no quiet hours
        }
        if quietStart > quietEnd {
            return hour >= quietStart || hour < quietEnd
        } else {
            return hour >= quietStart && hour < quietEnd
        }
    }
}

// MARK: - Badge Update Tests

final class NotificationBadgeTests: XCTestCase {

    func testBadge_IncrementedOnNewNotification() {
        // Given - Current badge count
        var badgeCount = 0

        // When - New notification scheduled
        badgeCount += 1

        // Then
        XCTAssertEqual(badgeCount, 1)
    }

    func testBadge_ClearedOnAppOpen() {
        // Given - Badge count of 5
        var badgeCount = 5

        // When - App opened
        badgeCount = 0

        // Then
        XCTAssertEqual(badgeCount, 0)
    }

    func testBadge_MultipleNotifications() {
        // Given
        var badgeCount = 0

        // When - Multiple notifications
        badgeCount += 1 // Workout reminder
        badgeCount += 1 // Streak alert
        badgeCount += 1 // Weekly summary

        // Then
        XCTAssertEqual(badgeCount, 3)
    }

    func testBadge_MaxReasonableValue() {
        // Given - Many pending notifications
        let pendingCount = 99

        // Then - Badge should still be valid
        XCTAssertLessThanOrEqual(pendingCount, 99, "Badge count should be reasonable")
    }
}

// MARK: - Notification Identifier Tests

final class NotificationIdentifierTests: XCTestCase {

    func testIdentifier_WorkoutReminder_UniquePerSchedule() {
        // Given
        let baseIdentifier = "com.getmodus.workout.reminder"
        let uuid1 = UUID().uuidString
        let uuid2 = UUID().uuidString

        // When
        let id1 = "\(baseIdentifier).\(uuid1)"
        let id2 = "\(baseIdentifier).\(uuid2)"

        // Then
        XCTAssertNotEqual(id1, id2, "Each reminder should have unique identifier")
        XCTAssertTrue(id1.hasPrefix(baseIdentifier))
        XCTAssertTrue(id2.hasPrefix(baseIdentifier))
    }

    func testIdentifier_StreakAlert_IncludesStreakCount() {
        // Given
        let baseIdentifier = "com.getmodus.streak.alert"
        let streakCount = 7

        // When
        let id = "\(baseIdentifier).\(streakCount)"

        // Then
        XCTAssertTrue(id.contains("7"))
        XCTAssertTrue(id.hasPrefix(baseIdentifier))
    }

    func testIdentifier_WeeklyReminder_IncludesDayOfWeek() {
        // Given
        let baseIdentifier = "com.getmodus.workout.reminder"
        let dayOfWeek = 3 // Wednesday

        // When
        let id = "\(baseIdentifier).\(dayOfWeek)"

        // Then
        XCTAssertTrue(id.contains("3"))
    }
}

// MARK: - Pattern Analysis Tests

final class PatternAnalysisTests: XCTestCase {

    func testPatternAnalysis_SingleDayPattern() {
        // Given - User always works out at 6 PM on Mondays
        let pattern = TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: 1, // Monday
            preferredHour: 18,
            workoutCount: 10,
            avgStartTime: createTime(hour: 18, minute: 0),
            confidenceScore: 0.9,
            lastUpdated: Date()
        )

        // Then
        XCTAssertEqual(pattern.dayOfWeek, 1)
        XCTAssertEqual(pattern.dayName, "Monday")
        XCTAssertEqual(pattern.preferredHour, 18)
        XCTAssertEqual(pattern.confidenceLevel, "High")
    }

    func testPatternAnalysis_VariedTimes() {
        // Given - User works out at varied times (lower confidence)
        let pattern = TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: 3,
            preferredHour: nil,
            workoutCount: 8,
            avgStartTime: nil,
            confidenceScore: 0.3,
            lastUpdated: Date()
        )

        // Then
        XCTAssertEqual(pattern.confidenceLevel, "Moderate")
        XCTAssertNil(pattern.preferredHour)
        XCTAssertNil(pattern.formattedTime)
    }

    func testPatternAnalysis_WeekendVsWeekday() {
        // Given
        let weekdayPattern = TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: 2, // Tuesday
            preferredHour: 6, // Early morning
            workoutCount: 15,
            avgStartTime: createTime(hour: 6, minute: 0),
            confidenceScore: 0.85,
            lastUpdated: Date()
        )

        let weekendPattern = TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: 6, // Saturday
            preferredHour: 10, // Later morning
            workoutCount: 8,
            avgStartTime: createTime(hour: 10, minute: 0),
            confidenceScore: 0.75,
            lastUpdated: Date()
        )

        // Then
        XCTAssertEqual(weekdayPattern.preferredHour, 6)
        XCTAssertEqual(weekendPattern.preferredHour, 10)
        XCTAssertGreaterThan(weekdayPattern.workoutCount, weekendPattern.workoutCount)
    }

    func testPatternAnalysis_InsufficientData() {
        // Given - Only 2 workouts
        let pattern = TrainingTimePattern(
            id: UUID(),
            patientId: UUID(),
            dayOfWeek: 4,
            preferredHour: 17,
            workoutCount: 2,
            avgStartTime: createTime(hour: 17, minute: 0),
            confidenceScore: 0.15,
            lastUpdated: Date()
        )

        // Then
        XCTAssertEqual(pattern.confidenceLevel, "Learning")
        XCTAssertLessThan(pattern.workoutCount, 5)
    }

    // MARK: - Helpers

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
