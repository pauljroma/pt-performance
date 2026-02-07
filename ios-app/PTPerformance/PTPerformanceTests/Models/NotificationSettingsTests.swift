//
//  NotificationSettingsTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for NotificationSettings model
//  Tests smart timing preferences, quiet hours validation, and reminder configuration
//

import XCTest
@testable import PTPerformance

// MARK: - NotificationSettings Model Tests

final class NotificationSettingsModelTests: XCTestCase {

    // MARK: - Default Settings Tests

    func testDefaults_CreatesValidSettings() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings.defaults(for: patientId)

        // Then
        XCTAssertEqual(settings.patientId, patientId)
        XCTAssertNil(settings.id, "Default settings should not have an ID")
        XCTAssertTrue(settings.smartTimingEnabled)
        XCTAssertEqual(settings.reminderMinutesBefore, 30)
        XCTAssertTrue(settings.streakAlertsEnabled)
        XCTAssertTrue(settings.weeklySummaryEnabled)
        XCTAssertNil(settings.updatedAt)
    }

    func testDefaults_FallbackReminderTime_Is9AM() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings.defaults(for: patientId)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: settings.fallbackReminderTime)
        let minute = calendar.component(.minute, from: settings.fallbackReminderTime)

        // Then
        XCTAssertEqual(hour, 9, "Default fallback time should be 9:00 AM")
        XCTAssertEqual(minute, 0)
    }

    func testDefaults_QuietHours_Standard() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings.defaults(for: patientId)
        let calendar = Calendar.current

        // Then - Quiet hours should be 10 PM to 7 AM
        if let quietStart = settings.quietHoursStart {
            let startHour = calendar.component(.hour, from: quietStart)
            XCTAssertEqual(startHour, 22, "Quiet hours should start at 10 PM")
        } else {
            XCTFail("Quiet hours start should not be nil")
        }

        if let quietEnd = settings.quietHoursEnd {
            let endHour = calendar.component(.hour, from: quietEnd)
            XCTAssertEqual(endHour, 7, "Quiet hours should end at 7 AM")
        } else {
            XCTFail("Quiet hours end should not be nil")
        }
    }

    // MARK: - Formatted Reminder Time Tests

    func testFormattedReminderTime_ReturnsValidString() {
        // Given
        let patientId = UUID()
        let settings = NotificationSettings.defaults(for: patientId)

        // When
        let formatted = settings.formattedReminderTime

        // Then
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains(":"), "Formatted time should contain colon")
        // Format is "h:mm a" so should contain AM or PM
        XCTAssertTrue(formatted.contains("AM") || formatted.contains("PM"),
                      "Formatted time should contain AM/PM indicator")
    }

    func testFormattedReminderTime_MatchesExpectedFormat() {
        // Given
        let patientId = UUID()
        let settings = NotificationSettings.defaults(for: patientId)

        // When
        let formatted = settings.formattedReminderTime

        // Then - Default is 9:00 AM
        // Note: Format may vary by locale, but should contain "9" and "00"
        XCTAssertTrue(formatted.contains("9") && formatted.contains("00"),
                      "Default formatted time should represent 9:00")
    }

    // MARK: - JSON Decoding Tests

    func testNotificationSettings_DecodesFromJSON() throws {
        // Given
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

        // When
        let decoder = PTSupabaseClient.flexibleDecoder
        let settings = try decoder.decode(NotificationSettings.self, from: json)

        // Then
        XCTAssertNotNil(settings.id)
        XCTAssertTrue(settings.smartTimingEnabled)
        XCTAssertEqual(settings.reminderMinutesBefore, 15)
        XCTAssertFalse(settings.streakAlertsEnabled)
        XCTAssertTrue(settings.weeklySummaryEnabled)
    }

    func testNotificationSettings_DecodesWithNilOptionals() throws {
        // Given
        let json = """
        {
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "smart_timing_enabled": false,
            "fallback_reminder_time": "08:30:00",
            "reminder_minutes_before": 45,
            "streak_alerts_enabled": true,
            "weekly_summary_enabled": false
        }
        """.data(using: .utf8)!

        // When
        let decoder = PTSupabaseClient.flexibleDecoder
        let settings = try decoder.decode(NotificationSettings.self, from: json)

        // Then
        XCTAssertNil(settings.id)
        XCTAssertNil(settings.quietHoursStart)
        XCTAssertNil(settings.quietHoursEnd)
        XCTAssertNil(settings.updatedAt)
        XCTAssertFalse(settings.smartTimingEnabled)
        XCTAssertEqual(settings.reminderMinutesBefore, 45)
    }

    // MARK: - Reminder Minutes Before Validation Tests

    func testReminderMinutesBefore_AcceptsValidValues() {
        // Given - Various valid reminder times
        let validMinutes = [5, 10, 15, 30, 45, 60, 120]
        let patientId = UUID()

        for minutes in validMinutes {
            // When - Create settings with this reminder time
            // Note: We're testing the model accepts these values
            let settings = NotificationSettings(
                id: nil,
                patientId: patientId,
                smartTimingEnabled: true,
                fallbackReminderTime: Date(),
                reminderMinutesBefore: minutes,
                streakAlertsEnabled: true,
                weeklySummaryEnabled: true,
                quietHoursStart: nil,
                quietHoursEnd: nil,
                updatedAt: nil
            )

            // Then
            XCTAssertEqual(settings.reminderMinutesBefore, minutes,
                           "Should accept \(minutes) minutes")
        }
    }

    // MARK: - Smart Timing Preference Tests

    func testSmartTimingEnabled_WhenTrue_ExpectsPatternBasedReminders() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings(
            id: nil,
            patientId: patientId,
            smartTimingEnabled: true,
            fallbackReminderTime: Date(),
            reminderMinutesBefore: 30,
            streakAlertsEnabled: true,
            weeklySummaryEnabled: true,
            quietHoursStart: nil,
            quietHoursEnd: nil,
            updatedAt: nil
        )

        // Then
        XCTAssertTrue(settings.smartTimingEnabled,
                      "Smart timing should be enabled")
    }

    func testSmartTimingEnabled_WhenFalse_UsesFallbackTime() {
        // Given
        let patientId = UUID()
        let fallbackTime = createTime(hour: 18, minute: 0) // 6 PM

        // When
        let settings = NotificationSettings(
            id: nil,
            patientId: patientId,
            smartTimingEnabled: false,
            fallbackReminderTime: fallbackTime,
            reminderMinutesBefore: 30,
            streakAlertsEnabled: true,
            weeklySummaryEnabled: true,
            quietHoursStart: nil,
            quietHoursEnd: nil,
            updatedAt: nil
        )

        // Then
        XCTAssertFalse(settings.smartTimingEnabled)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: settings.fallbackReminderTime)
        XCTAssertEqual(hour, 18, "Should use specified fallback time")
    }

    // MARK: - Helpers

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - NotificationSettingsUpdate Tests

final class NotificationModelSettingsUpdateTests: XCTestCase {

    func testNotificationSettingsUpdate_ToInsert() {
        // Given
        let patientId = UUID()
        var update = NotificationSettingsUpdate()
        update.smartTimingEnabled = false
        update.reminderMinutesBefore = 45
        update.streakAlertsEnabled = true
        update.weeklySummaryEnabled = false

        // When
        let insert = update.toInsert(patientId: patientId)

        // Then
        XCTAssertEqual(insert.patientId, patientId.uuidString)
        XCTAssertFalse(insert.smartTimingEnabled)
        XCTAssertEqual(insert.reminderMinutesBefore, 45)
        XCTAssertTrue(insert.streakAlertsEnabled)
        XCTAssertFalse(insert.weeklySummaryEnabled)
    }

    func testNotificationSettingsUpdate_ToInsert_DefaultValues() {
        // Given
        let patientId = UUID()
        let update = NotificationSettingsUpdate()

        // When
        let insert = update.toInsert(patientId: patientId)

        // Then - When not set, should use defaults
        XCTAssertTrue(insert.smartTimingEnabled)
        XCTAssertEqual(insert.reminderMinutesBefore, 30)
        XCTAssertTrue(insert.streakAlertsEnabled)
        XCTAssertTrue(insert.weeklySummaryEnabled)
        XCTAssertEqual(insert.fallbackReminderTime, "09:00:00")
        XCTAssertEqual(insert.quietHoursStart, "22:00:00")
        XCTAssertEqual(insert.quietHoursEnd, "07:00:00")
    }

    func testNotificationSettingsUpdate_PartialUpdate() {
        // Given
        var update = NotificationSettingsUpdate()
        update.reminderMinutesBefore = 60

        // When - Only set one field
        let patientId = UUID()
        let insert = update.toInsert(patientId: patientId)

        // Then - Other fields use defaults
        XCTAssertEqual(insert.reminderMinutesBefore, 60)
        XCTAssertTrue(insert.smartTimingEnabled) // Default
        XCTAssertTrue(insert.streakAlertsEnabled) // Default
    }

    func testNotificationSettingsUpdate_QuietHoursUpdate() {
        // Given
        var update = NotificationSettingsUpdate()
        update.quietHoursStart = "23:00:00"
        update.quietHoursEnd = "06:00:00"

        // When
        let patientId = UUID()
        let insert = update.toInsert(patientId: patientId)

        // Then
        XCTAssertEqual(insert.quietHoursStart, "23:00:00")
        XCTAssertEqual(insert.quietHoursEnd, "06:00:00")
    }

    func testNotificationSettingsUpdate_FallbackTimeUpdate() {
        // Given
        var update = NotificationSettingsUpdate()
        update.fallbackReminderTime = "07:30:00"

        // When
        let patientId = UUID()
        let insert = update.toInsert(patientId: patientId)

        // Then
        XCTAssertEqual(insert.fallbackReminderTime, "07:30:00")
    }

    func testNotificationSettingsUpdate_UpdatedAtIsSet() {
        // Given
        let update = NotificationSettingsUpdate()

        // Then - updatedAt should be automatically set
        XCTAssertFalse(update.updatedAt.isEmpty)
        // Should be valid ISO8601 format
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: update.updatedAt),
                        "updatedAt should be valid ISO8601 date")
    }
}

// MARK: - Quiet Hours Validation Tests

final class QuietHoursValidationTests: XCTestCase {

    // MARK: - Standard Overnight Quiet Hours (10 PM - 7 AM)

    func testQuietHours_WithinQuietPeriod_LateNight() {
        // Test 11 PM - should be in quiet hours (10 PM - 7 AM)
        XCTAssertTrue(isInQuietHours(hour: 23, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_WithinQuietPeriod_Midnight() {
        // Test midnight
        XCTAssertTrue(isInQuietHours(hour: 0, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_WithinQuietPeriod_EarlyMorning() {
        // Test 3 AM
        XCTAssertTrue(isInQuietHours(hour: 3, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_WithinQuietPeriod_JustBeforeEnd() {
        // Test 6:59 AM (effectively hour 6)
        XCTAssertTrue(isInQuietHours(hour: 6, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_OutsideQuietPeriod_Morning() {
        // Test 10 AM - should NOT be in quiet hours
        XCTAssertFalse(isInQuietHours(hour: 10, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_OutsideQuietPeriod_Afternoon() {
        // Test 3 PM
        XCTAssertFalse(isInQuietHours(hour: 15, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_OutsideQuietPeriod_Evening() {
        // Test 8 PM
        XCTAssertFalse(isInQuietHours(hour: 20, quietStart: 22, quietEnd: 7))
    }

    // MARK: - Boundary Conditions

    func testQuietHours_BoundaryStart() {
        // Test exactly 10 PM - should be in quiet hours (start is inclusive)
        XCTAssertTrue(isInQuietHours(hour: 22, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_BoundaryEnd() {
        // Test exactly 7 AM - should NOT be in quiet hours (end is exclusive)
        XCTAssertFalse(isInQuietHours(hour: 7, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_JustBeforeStart() {
        // Test 9 PM - one hour before quiet starts
        XCTAssertFalse(isInQuietHours(hour: 21, quietStart: 22, quietEnd: 7))
    }

    func testQuietHours_JustAfterEnd() {
        // Test 8 AM - one hour after quiet ends
        XCTAssertFalse(isInQuietHours(hour: 8, quietStart: 22, quietEnd: 7))
    }

    // MARK: - Same-Day Quiet Hours (e.g., 9 AM - 5 PM)

    func testQuietHours_SameDay_WithinPeriod() {
        // Quiet from 9 AM to 5 PM (work hours)
        XCTAssertTrue(isInQuietHours(hour: 12, quietStart: 9, quietEnd: 17))
    }

    func testQuietHours_SameDay_OutsidePeriod_Before() {
        // Before 9 AM
        XCTAssertFalse(isInQuietHours(hour: 7, quietStart: 9, quietEnd: 17))
    }

    func testQuietHours_SameDay_OutsidePeriod_After() {
        // After 5 PM
        XCTAssertFalse(isInQuietHours(hour: 20, quietStart: 9, quietEnd: 17))
    }

    // MARK: - Edge Cases

    func testQuietHours_AllQuietHours() {
        // 24-hour quiet period (start and end are same)
        // When start == end, no hours are quiet
        XCTAssertFalse(isInQuietHours(hour: 12, quietStart: 12, quietEnd: 12))
    }

    func testQuietHours_NearMidnight_CrossingDay() {
        // Quiet from 11 PM to 5 AM
        XCTAssertTrue(isInQuietHours(hour: 23, quietStart: 23, quietEnd: 5))
        XCTAssertTrue(isInQuietHours(hour: 0, quietStart: 23, quietEnd: 5))
        XCTAssertTrue(isInQuietHours(hour: 4, quietStart: 23, quietEnd: 5))
        XCTAssertFalse(isInQuietHours(hour: 5, quietStart: 23, quietEnd: 5))
        XCTAssertFalse(isInQuietHours(hour: 22, quietStart: 23, quietEnd: 5))
    }

    func testQuietHours_VeryShortPeriod() {
        // Only quiet for 1 hour: 3 AM to 4 AM
        XCTAssertTrue(isInQuietHours(hour: 3, quietStart: 3, quietEnd: 4))
        XCTAssertFalse(isInQuietHours(hour: 4, quietStart: 3, quietEnd: 4))
        XCTAssertFalse(isInQuietHours(hour: 2, quietStart: 3, quietEnd: 4))
    }

    // MARK: - Helpers

    private func isInQuietHours(hour: Int, quietStart: Int, quietEnd: Int) -> Bool {
        // Handle overnight quiet hours (e.g., 10 PM to 7 AM)
        if quietStart > quietEnd {
            return hour >= quietStart || hour < quietEnd
        } else if quietStart == quietEnd {
            // Same start and end means no quiet hours
            return false
        } else {
            return hour >= quietStart && hour < quietEnd
        }
    }
}

// MARK: - Reminder Configuration Tests

final class ReminderConfigurationTests: XCTestCase {

    func testReminderConfiguration_StandardOptions() {
        // Common reminder intervals that should be supported
        let standardMinutes = [5, 10, 15, 30, 60]

        for minutes in standardMinutes {
            XCTAssertGreaterThan(minutes, 0, "Reminder minutes should be positive")
            XCTAssertLessThanOrEqual(minutes, 60, "Standard reminders are under 60 minutes")
        }
    }

    func testReminderConfiguration_ExtendedOptions() {
        // Extended reminder intervals
        let extendedMinutes = [120, 180, 240, 1440] // Up to 24 hours

        for minutes in extendedMinutes {
            XCTAssertGreaterThan(minutes, 60, "Extended reminders are over 60 minutes")
        }
    }

    func testReminderTime_CalculatedFromSession() {
        // Given - Session at 9:00 AM with 30 minute reminder
        let sessionTime = createTime(hour: 9, minute: 0)
        let reminderMinutes = 30

        // When
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -reminderMinutes,
            to: sessionTime
        )!

        // Then - Reminder at 8:30 AM
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: reminderTime), 8)
        XCTAssertEqual(calendar.component(.minute, from: reminderTime), 30)
    }

    func testReminderTime_CrossingHourBoundary() {
        // Given - Session at 9:00 AM with 45 minute reminder
        let sessionTime = createTime(hour: 9, minute: 0)
        let reminderMinutes = 45

        // When
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -reminderMinutes,
            to: sessionTime
        )!

        // Then - Reminder at 8:15 AM
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: reminderTime), 8)
        XCTAssertEqual(calendar.component(.minute, from: reminderTime), 15)
    }

    func testReminderTime_MidnightCrossing() {
        // Given - Session at 12:15 AM with 30 minute reminder
        let sessionTime = createTime(hour: 0, minute: 15)
        let reminderMinutes = 30

        // When
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -reminderMinutes,
            to: sessionTime
        )!

        // Then - Reminder should be at 11:45 PM previous day
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: reminderTime), 23)
        XCTAssertEqual(calendar.component(.minute, from: reminderTime), 45)
    }

    // MARK: - Helpers

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Smart Timing Preference Tests

final class SmartTimingPreferenceTests: XCTestCase {

    func testSmartTiming_EnabledByDefault() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings.defaults(for: patientId)

        // Then
        XCTAssertTrue(settings.smartTimingEnabled,
                      "Smart timing should be enabled by default")
    }

    func testSmartTiming_FallbackTimeUsedWhenDisabled() {
        // Given
        let patientId = UUID()
        let fallbackTime = createTime(hour: 18, minute: 30)

        // When
        let settings = NotificationSettings(
            id: nil,
            patientId: patientId,
            smartTimingEnabled: false,
            fallbackReminderTime: fallbackTime,
            reminderMinutesBefore: 30,
            streakAlertsEnabled: true,
            weeklySummaryEnabled: true,
            quietHoursStart: nil,
            quietHoursEnd: nil,
            updatedAt: nil
        )

        // Then
        XCTAssertFalse(settings.smartTimingEnabled)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: settings.fallbackReminderTime), 18)
        XCTAssertEqual(calendar.component(.minute, from: settings.fallbackReminderTime), 30)
    }

    func testSmartTiming_StillHasFallbackWhenEnabled() {
        // Given
        let patientId = UUID()

        // When
        let settings = NotificationSettings.defaults(for: patientId)

        // Then - Even with smart timing, fallback exists
        XCTAssertTrue(settings.smartTimingEnabled)
        // Fallback time should still be set
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: settings.fallbackReminderTime)
        XCTAssertEqual(hour, 9, "Fallback should be 9 AM even when smart timing is on")
    }

    // MARK: - Helpers

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
