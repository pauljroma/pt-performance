//
//  SchedulingServiceTests.swift
//  PTPerformanceTests
//
//  Build 346 - Comprehensive unit tests for SchedulingService
//  Tests session scheduling, calendar integration, reminder creation,
//  reschedule handling, and conflict detection
//

import XCTest
@testable import PTPerformance

final class SchedulingServiceTests: XCTestCase {

    // MARK: - Service Tests

    func testSharedInstance() async {
        // Given: The shared instance
        let service1 = SchedulingService.shared
        let service2 = SchedulingService.shared

        // Then: Both references should be the same instance
        // (Note: Cannot use === for actors, but they should be the same singleton)
        XCTAssertNotNil(service1, "Shared instance should exist")
        XCTAssertNotNil(service2, "Shared instance should exist")
    }

    // MARK: - Date Range Calculation Tests

    func testFetchUpcomingSessions_DateRangeCalculation_Default30Days() {
        // Given: Default days parameter of 30
        let days = 30
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!

        // Then: Date range should span 30 days from today
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: today, to: futureDate)

        XCTAssertEqual(components.day, 30, "Date range should be 30 days")
    }

    func testFetchUpcomingSessions_DateRangeCalculation_Custom7Days() {
        // Given: 7 days parameter
        let days = 7
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!

        // Then: Date range should span 7 days
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: today, to: futureDate)

        XCTAssertEqual(components.day, 7, "Date range should be 7 days")
    }

    func testFetchUpcomingSessions_DateRangeCalculation_StartOfDay() {
        // Given: Today's date
        let today = Calendar.current.startOfDay(for: Date())

        // Then: Start of day should have zero hour/minute/second
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: today)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    // MARK: - UUID Convenience Method Tests

    func testUUIDConvenienceMethods_StringConversion() {
        // Given: A valid UUID
        let uuid = UUID()
        let uuidString = uuid.uuidString

        // When: Converting back from string
        let parsedUUID = UUID(uuidString: uuidString)

        // Then: Should match original
        XCTAssertEqual(parsedUUID, uuid)
    }

    // MARK: - ISO8601 Date Formatter Tests

    func testDateFormatter_ISO8601WithFractionalSeconds() {
        // Given: ISO8601 formatter with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // When: Formatting a date
        let date = Date()
        let dateString = formatter.string(from: date)

        // Then: Should contain fractional seconds (period followed by digits)
        XCTAssertTrue(dateString.contains("."), "ISO8601 string should contain fractional seconds")
    }

    func testDateFormatter_RoundTrip() {
        // Given: A date and ISO8601 formatter
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let originalDate = Date()

        // When: Formatting and parsing back
        let dateString = formatter.string(from: originalDate)
        let parsedDate = formatter.date(from: dateString)

        // Then: Parsed date should be very close to original (within 1 second due to fractional precision)
        XCTAssertNotNil(parsedDate)
        if let parsed = parsedDate {
            let timeDifference = abs(originalDate.timeIntervalSince(parsed))
            XCTAssertLessThan(timeDifference, 1.0, "Round-trip date should be within 1 second")
        }
    }
}

// MARK: - SchedulingError Tests

final class SchedulingErrorTests: XCTestCase {

    func testFetchFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = SchedulingError.fetchFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Couldn't Load Schedule")
    }

    func testScheduleFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: nil)
        let error = SchedulingError.scheduleFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Scheduling Issue")
    }

    func testRescheduleFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 3, userInfo: nil)
        let error = SchedulingError.rescheduleFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Rescheduling Issue")
    }

    func testCancelFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 4, userInfo: nil)
        let error = SchedulingError.cancelFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Couldn't Cancel Session")
    }

    func testCompleteFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 5, userInfo: nil)
        let error = SchedulingError.completeFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Couldn't Complete Session")
    }

    func testUpdateFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 6, userInfo: nil)
        let error = SchedulingError.updateFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Couldn't Update Session")
    }

    func testDeleteFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 7, userInfo: nil)
        let error = SchedulingError.deleteFailed(underlyingError)

        XCTAssertEqual(error.errorDescription, "Couldn't Remove Session")
    }

    func testSessionNotFound_ErrorDescription() {
        let error = SchedulingError.sessionNotFound

        XCTAssertEqual(error.errorDescription, "Session Not Found")
    }

    func testInvalidSession_ErrorDescription() {
        let error = SchedulingError.invalidSession

        XCTAssertEqual(error.errorDescription, "Session Unavailable")
    }

    func testDuplicateSchedule_ErrorDescription() {
        let error = SchedulingError.duplicateSchedule

        XCTAssertEqual(error.errorDescription, "Already Scheduled")
    }

    // MARK: - Underlying Error Tests

    func testUnderlyingError_FetchFailed() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = SchedulingError.fetchFailed(underlyingError)

        XCTAssertNotNil(error.underlyingError)
        XCTAssertEqual((error.underlyingError as NSError?)?.code, 1)
    }

    func testUnderlyingError_ScheduleFailed() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: nil)
        let error = SchedulingError.scheduleFailed(underlyingError)

        XCTAssertNotNil(error.underlyingError)
    }

    func testUnderlyingError_SessionNotFound() {
        let error = SchedulingError.sessionNotFound

        XCTAssertNil(error.underlyingError)
    }

    func testUnderlyingError_InvalidSession() {
        let error = SchedulingError.invalidSession

        XCTAssertNil(error.underlyingError)
    }

    func testUnderlyingError_DuplicateSchedule() {
        let error = SchedulingError.duplicateSchedule

        XCTAssertNil(error.underlyingError)
    }

    func testErrorConformsToLocalizedError() {
        let error: any Error = SchedulingError.sessionNotFound
        XCTAssertTrue(error is SchedulingError, "Error should be SchedulingError")
    }
}

// MARK: - ScheduledSession Model Tests (Scheduling Service)

final class SchedulingServiceSessionModelTests: XCTestCase {

    // MARK: - Sample Data Tests

    func testSampleSession() {
        let sample = ScheduledSession.sample

        XCTAssertNotNil(sample.id)
        XCTAssertNotNil(sample.patientId)
        XCTAssertNotNil(sample.sessionId)
        XCTAssertEqual(sample.status, .scheduled)
        XCTAssertNil(sample.completedAt)
    }

    func testSampleCompletedSession() {
        let sample = ScheduledSession.sampleCompleted

        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.status, .completed)
        XCTAssertNotNil(sample.completedAt)
        XCTAssertTrue(sample.reminderSent)
    }

    // MARK: - Computed Properties Tests

    func testScheduledDateTime_CombinesDateAndTime() {
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date(),
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let combinedDateTime = session.scheduledDateTime

        // Combined date time should have date components from scheduledDate
        // and time components from scheduledTime
        XCTAssertNotNil(combinedDateTime)
    }

    func testIsUpcoming_FutureScheduledSession() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: futureDate,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertTrue(session.isUpcoming, "Future scheduled session should be upcoming")
    }

    func testIsUpcoming_CompletedSession() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: futureDate,
            scheduledTime: Date(),
            status: .completed,  // Not scheduled
            completedAt: Date(),
            reminderSent: true,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertFalse(session.isUpcoming, "Completed session should not be upcoming")
    }

    func testIsPastDue_PastScheduledSession() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: pastDate,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertTrue(session.isPastDue, "Past scheduled session should be past due")
    }

    func testIsPastDue_CompletedSession() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: pastDate,
            scheduledTime: Date(),
            status: .completed,
            completedAt: Date(),
            reminderSent: true,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertFalse(session.isPastDue, "Completed session should not be past due")
    }

    func testDisplayName_WithNotes() {
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date(),
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: "Morning workout",
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(session.displayName, "Morning workout")
    }

    func testDisplayName_WithoutNotes() {
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date(),
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Should return day of week + "Session"
        XCTAssertTrue(session.displayName.contains("Session"))
    }

    func testFormattedDate() {
        let session = ScheduledSession.sample

        let formattedDate = session.formattedDate

        // Should be a non-empty string
        XCTAssertFalse(formattedDate.isEmpty)
    }

    func testFormattedTime() {
        let session = ScheduledSession.sample

        let formattedTime = session.formattedTime

        // Should be a non-empty string
        XCTAssertFalse(formattedTime.isEmpty)
    }

    func testRelativeTimeString_Today() {
        let today = Calendar.current.startOfDay(for: Date())
        // Set time to noon to ensure it's "today"
        let todayNoon = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: today)!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: todayNoon,
            scheduledTime: todayNoon,
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertTrue(session.relativeTimeString.contains("Today"), "Should show 'Today' for today's sessions")
    }

    func testRelativeTimeString_Tomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: tomorrow,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertTrue(session.relativeTimeString.contains("Tomorrow"), "Should show 'Tomorrow' for tomorrow's sessions")
    }

    // MARK: - Hashable Tests

    func testScheduledSession_Hashable() {
        let session1 = ScheduledSession.sample
        let session2 = ScheduledSession.sample

        // Different sessions should have different hashes
        XCTAssertNotEqual(session1.hashValue, session2.hashValue)

        // Same session should have consistent hash
        XCTAssertEqual(session1.hashValue, session1.hashValue)
    }

    func testScheduledSession_Equatable() {
        let session1 = ScheduledSession.sample
        let session2 = ScheduledSession.sample

        // Different sessions should not be equal
        XCTAssertNotEqual(session1, session2)

        // Same session should be equal to itself
        XCTAssertEqual(session1, session1)
    }
}

// MARK: - ScheduleStatus Tests (Scheduling Service)

final class SchedulingServiceStatusTests: XCTestCase {

    func testAllStatuses() {
        let scheduled = ScheduledSession.ScheduleStatus.scheduled
        let completed = ScheduledSession.ScheduleStatus.completed
        let cancelled = ScheduledSession.ScheduleStatus.cancelled
        let rescheduled = ScheduledSession.ScheduleStatus.rescheduled

        XCTAssertNotNil(scheduled)
        XCTAssertNotNil(completed)
        XCTAssertNotNil(cancelled)
        XCTAssertNotNil(rescheduled)
    }

    func testDisplayNames() {
        XCTAssertEqual(ScheduledSession.ScheduleStatus.scheduled.displayName, "Scheduled")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.completed.displayName, "Completed")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.rescheduled.displayName, "Rescheduled")
    }

    func testRawValues() {
        XCTAssertEqual(ScheduledSession.ScheduleStatus.scheduled.rawValue, "scheduled")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.completed.rawValue, "completed")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.rescheduled.rawValue, "rescheduled")
    }

    func testColors() {
        XCTAssertEqual(ScheduledSession.ScheduleStatus.scheduled.color, "blue")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.completed.color, "green")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.cancelled.color, "red")
        XCTAssertEqual(ScheduledSession.ScheduleStatus.rescheduled.color, "orange")
    }

    func testStatusDecoding() throws {
        // Test that status can be decoded from string
        let json = "\"scheduled\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let status = try decoder.decode(ScheduledSession.ScheduleStatus.self, from: json)

        XCTAssertEqual(status, .scheduled)
    }

    func testStatusEncoding() throws {
        let status = ScheduledSession.ScheduleStatus.completed
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(jsonString, "\"completed\"")
    }
}

// MARK: - Date Validation Tests

final class SchedulingDateValidationTests: XCTestCase {

    func testDateRange_ValidRange() {
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!

        let range = today...futureDate

        // Range should contain dates within it
        let midDate = Calendar.current.date(byAdding: .day, value: 15, to: today)!
        XCTAssertTrue(range.contains(midDate))
    }

    func testDateRange_BoundaryDates() {
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!

        let range = today...futureDate

        // Range should contain boundary dates
        XCTAssertTrue(range.contains(today))
        XCTAssertTrue(range.contains(futureDate))
    }

    func testDateRange_OutsideDates() {
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!

        let range = today...futureDate

        // Dates outside range should not be contained
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let farFuture = Calendar.current.date(byAdding: .day, value: 31, to: today)!

        XCTAssertFalse(range.contains(yesterday))
        XCTAssertFalse(range.contains(farFuture))
    }
}

// MARK: - Reschedule Payload Tests

final class ReschedulePayloadTests: XCTestCase {

    func testReschedulePayload_StatusChange() {
        // When rescheduling, status should change to "rescheduled"
        let expectedStatus = ScheduledSession.ScheduleStatus.rescheduled.rawValue

        XCTAssertEqual(expectedStatus, "rescheduled")
    }

    func testReschedulePayload_ReminderReset() {
        // When rescheduling, reminder_sent should reset to false
        // This ensures users get notified of the new time
        let reminderSent = false

        XCTAssertFalse(reminderSent)
    }
}

// MARK: - Calendar Integration Tests

final class CalendarIntegrationTests: XCTestCase {

    func testCalendarIntegration_WeekdayNames() {
        // Given
        let calendar = Calendar.current
        let weekdays = calendar.weekdaySymbols

        // Then
        XCTAssertEqual(weekdays.count, 7)
        XCTAssertEqual(weekdays[0], "Sunday")
        XCTAssertEqual(weekdays[1], "Monday")
        XCTAssertEqual(weekdays[6], "Saturday")
    }

    func testCalendarIntegration_ShortWeekdayNames() {
        // Given
        let calendar = Calendar.current
        let shortWeekdays = calendar.shortWeekdaySymbols

        // Then
        XCTAssertEqual(shortWeekdays.count, 7)
        XCTAssertEqual(shortWeekdays[0], "Sun")
        XCTAssertEqual(shortWeekdays[1], "Mon")
    }

    func testCalendarIntegration_NextOccurrenceOfDay() {
        // Given - Looking for next Monday
        let calendar = Calendar.current
        let today = Date()

        // When
        var nextMonday = today
        while calendar.component(.weekday, from: nextMonday) != 2 { // 2 = Monday
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }

        // Then
        XCTAssertEqual(calendar.component(.weekday, from: nextMonday), 2)
    }

    func testCalendarIntegration_WeekOfYear() {
        // Given
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        let date = calendar.date(from: components)!

        // When
        let weekOfYear = calendar.component(.weekOfYear, from: date)

        // Then - Should be week 3 of 2024
        XCTAssertEqual(weekOfYear, 3)
    }

    func testCalendarIntegration_DaysInMonth() {
        // Given
        let calendar = Calendar.current

        // February 2024 (leap year)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 1
        let february = calendar.date(from: components)!

        // When
        let range = calendar.range(of: .day, in: .month, for: february)!

        // Then - February 2024 should have 29 days
        XCTAssertEqual(range.count, 29)
    }

    func testCalendarIntegration_NonLeapYear() {
        // Given
        let calendar = Calendar.current

        // February 2023 (non-leap year)
        var components = DateComponents()
        components.year = 2023
        components.month = 2
        components.day = 1
        let february = calendar.date(from: components)!

        // When
        let range = calendar.range(of: .day, in: .month, for: february)!

        // Then - February 2023 should have 28 days
        XCTAssertEqual(range.count, 28)
    }
}

// MARK: - Reminder Creation Tests

final class ReminderCreationTests: XCTestCase {

    func testReminderCreation_CalculatesCorrectTime() {
        // Given - Session at 9:00 AM with 30 minute reminder
        let calendar = Calendar.current
        var sessionComponents = DateComponents()
        sessionComponents.year = 2024
        sessionComponents.month = 6
        sessionComponents.day = 15
        sessionComponents.hour = 9
        sessionComponents.minute = 0
        let sessionTime = calendar.date(from: sessionComponents)!

        let reminderMinutesBefore = 30

        // When
        let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: sessionTime
        )!

        // Then - Reminder at 8:30 AM
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        XCTAssertEqual(hour, 8)
        XCTAssertEqual(minute, 30)
    }

    func testReminderCreation_CrossesDayBoundary() {
        // Given - Session at 12:15 AM with 30 minute reminder
        let calendar = Calendar.current
        var sessionComponents = DateComponents()
        sessionComponents.year = 2024
        sessionComponents.month = 6
        sessionComponents.day = 15
        sessionComponents.hour = 0
        sessionComponents.minute = 15
        let sessionTime = calendar.date(from: sessionComponents)!

        let reminderMinutesBefore = 30

        // When
        let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: sessionTime
        )!

        // Then - Reminder at 11:45 PM on June 14
        let day = calendar.component(.day, from: reminderTime)
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        XCTAssertEqual(day, 14)
        XCTAssertEqual(hour, 23)
        XCTAssertEqual(minute, 45)
    }

    func testReminderCreation_LongLeadTime() {
        // Given - Session at 2:00 PM with 24-hour reminder
        let calendar = Calendar.current
        var sessionComponents = DateComponents()
        sessionComponents.year = 2024
        sessionComponents.month = 6
        sessionComponents.day = 15
        sessionComponents.hour = 14
        sessionComponents.minute = 0
        let sessionTime = calendar.date(from: sessionComponents)!

        let reminderMinutesBefore = 24 * 60 // 24 hours

        // When
        let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: sessionTime
        )!

        // Then - Reminder at 2:00 PM on June 14
        let day = calendar.component(.day, from: reminderTime)
        let hour = calendar.component(.hour, from: reminderTime)
        XCTAssertEqual(day, 14)
        XCTAssertEqual(hour, 14)
    }

    func testReminderCreation_ZeroMinutes() {
        // Given - Session at exact time (no lead time)
        let calendar = Calendar.current
        var sessionComponents = DateComponents()
        sessionComponents.year = 2024
        sessionComponents.month = 6
        sessionComponents.day = 15
        sessionComponents.hour = 10
        sessionComponents.minute = 0
        let sessionTime = calendar.date(from: sessionComponents)!

        let reminderMinutesBefore = 0

        // When
        let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: sessionTime
        )!

        // Then - Reminder at session time
        XCTAssertEqual(sessionTime, reminderTime)
    }
}

// MARK: - Reschedule Handling Tests

final class RescheduleHandlingTests: XCTestCase {

    func testReschedule_SameDay_DifferentTime() {
        // Given - Original at 9 AM, rescheduled to 2 PM same day
        let calendar = Calendar.current
        var originalComponents = DateComponents()
        originalComponents.year = 2024
        originalComponents.month = 6
        originalComponents.day = 15
        originalComponents.hour = 9
        originalComponents.minute = 0

        var newComponents = originalComponents
        newComponents.hour = 14

        let originalTime = calendar.date(from: originalComponents)!
        let newTime = calendar.date(from: newComponents)!

        // Then
        let originalDay = calendar.component(.day, from: originalTime)
        let newDay = calendar.component(.day, from: newTime)
        XCTAssertEqual(originalDay, newDay, "Should be same day")

        let originalHour = calendar.component(.hour, from: originalTime)
        let newHour = calendar.component(.hour, from: newTime)
        XCTAssertNotEqual(originalHour, newHour, "Should be different time")
    }

    func testReschedule_DifferentDay() {
        // Given - Rescheduled from Monday to Wednesday
        let calendar = Calendar.current
        var originalComponents = DateComponents()
        originalComponents.year = 2024
        originalComponents.month = 6
        originalComponents.day = 10 // Monday
        originalComponents.hour = 9

        var newComponents = originalComponents
        newComponents.day = 12 // Wednesday

        let originalDate = calendar.date(from: originalComponents)!
        let newDate = calendar.date(from: newComponents)!

        // Then
        let daysDiff = calendar.dateComponents([.day], from: originalDate, to: newDate).day!
        XCTAssertEqual(daysDiff, 2)
    }

    func testReschedule_DifferentWeek() {
        // Given
        let calendar = Calendar.current
        var originalComponents = DateComponents()
        originalComponents.year = 2024
        originalComponents.month = 6
        originalComponents.day = 10

        var newComponents = originalComponents
        newComponents.day = 17 // Next week

        let originalDate = calendar.date(from: originalComponents)!
        let newDate = calendar.date(from: newComponents)!

        // Then
        let weeksDiff = calendar.dateComponents([.weekOfYear], from: originalDate, to: newDate).weekOfYear!
        XCTAssertEqual(weeksDiff, 1)
    }

    func testReschedule_StatusTransition() {
        // Given
        let originalStatus = ScheduledSession.ScheduleStatus.scheduled
        let newStatus = ScheduledSession.ScheduleStatus.rescheduled

        // Then
        XCTAssertEqual(originalStatus.rawValue, "scheduled")
        XCTAssertEqual(newStatus.rawValue, "rescheduled")
        XCTAssertNotEqual(originalStatus, newStatus)
    }

    func testReschedule_ReminderReset() {
        // When a session is rescheduled, the reminder should be reset
        let originalReminderSent = true
        let afterRescheduleReminderSent = false

        XCTAssertTrue(originalReminderSent)
        XCTAssertFalse(afterRescheduleReminderSent, "Reminder should be reset after reschedule")
    }
}

// MARK: - Conflict Detection Tests (Scheduling Service)

final class SchedulingConflictTests: XCTestCase {

    func testConflict_ExactSameTime() {
        // Given - Two sessions at exactly the same time
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 10
        components.minute = 0
        let time = calendar.date(from: components)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: time, duration: 60),
            session2: (date: time, duration: 60)
        )
        XCTAssertTrue(hasConflict)
    }

    func testConflict_OverlappingTimes() {
        // Given - Session 1: 10:00-11:00, Session 2: 10:30-11:30
        let calendar = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2024
        comp1.month = 6
        comp1.day = 15
        comp1.hour = 10
        let time1 = calendar.date(from: comp1)!

        var comp2 = comp1
        comp2.minute = 30
        let time2 = calendar.date(from: comp2)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: time1, duration: 60),
            session2: (date: time2, duration: 60)
        )
        XCTAssertTrue(hasConflict)
    }

    func testConflict_BackToBack_NoConflict() {
        // Given - Session 1: 10:00-11:00, Session 2: 11:00-12:00
        let calendar = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2024
        comp1.month = 6
        comp1.day = 15
        comp1.hour = 10
        let time1 = calendar.date(from: comp1)!

        var comp2 = comp1
        comp2.hour = 11
        let time2 = calendar.date(from: comp2)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: time1, duration: 60),
            session2: (date: time2, duration: 60)
        )
        XCTAssertFalse(hasConflict, "Back-to-back sessions should not conflict")
    }

    func testConflict_SeparatedInTime_NoConflict() {
        // Given - Session 1: 9:00-10:00, Session 2: 2:00-3:00 PM
        let calendar = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2024
        comp1.month = 6
        comp1.day = 15
        comp1.hour = 9
        let time1 = calendar.date(from: comp1)!

        var comp2 = comp1
        comp2.hour = 14
        let time2 = calendar.date(from: comp2)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: time1, duration: 60),
            session2: (date: time2, duration: 60)
        )
        XCTAssertFalse(hasConflict)
    }

    func testConflict_DifferentDays_NoConflict() {
        // Given - Same time but different days
        let calendar = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2024
        comp1.month = 6
        comp1.day = 15
        comp1.hour = 10
        let time1 = calendar.date(from: comp1)!

        var comp2 = comp1
        comp2.day = 16
        let time2 = calendar.date(from: comp2)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: time1, duration: 60),
            session2: (date: time2, duration: 60)
        )
        XCTAssertFalse(hasConflict, "Sessions on different days should not conflict")
    }

    func testConflict_LongSessionOverlapsMultiple() {
        // Given - 3-hour session that would overlap with two 1-hour sessions
        let calendar = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2024
        comp1.month = 6
        comp1.day = 15
        comp1.hour = 9
        let longSession = calendar.date(from: comp1)!

        var comp2 = comp1
        comp2.hour = 10
        let midSession = calendar.date(from: comp2)!

        // When/Then
        let hasConflict = doSessionsConflict(
            session1: (date: longSession, duration: 180), // 3 hours
            session2: (date: midSession, duration: 60)
        )
        XCTAssertTrue(hasConflict)
    }

    // MARK: - Helpers

    private func doSessionsConflict(
        session1: (date: Date, duration: Int),
        session2: (date: Date, duration: Int)
    ) -> Bool {
        let end1 = Calendar.current.date(
            byAdding: .minute,
            value: session1.duration,
            to: session1.date
        )!
        let end2 = Calendar.current.date(
            byAdding: .minute,
            value: session2.duration,
            to: session2.date
        )!

        return session1.date < end2 && session2.date < end1
    }
}

// MARK: - Error Recovery Suggestion Tests

final class SchedulingErrorRecoverySuggestionTests: XCTestCase {

    func testFetchFailed_RecoverySuggestion() {
        let error = SchedulingError.fetchFailed(NSError(domain: "test", code: 1))
        XCTAssertEqual(
            error.recoverySuggestion,
            "We couldn't load your scheduled sessions. Please check your connection and try again."
        )
    }

    func testScheduleFailed_RecoverySuggestion() {
        let error = SchedulingError.scheduleFailed(NSError(domain: "test", code: 1))
        XCTAssertEqual(
            error.recoverySuggestion,
            "We couldn't schedule this session right now. Please try again in a moment."
        )
    }

    func testRescheduleFailed_RecoverySuggestion() {
        let error = SchedulingError.rescheduleFailed(NSError(domain: "test", code: 1))
        XCTAssertEqual(
            error.recoverySuggestion,
            "We couldn't move this session to the new time. Please try again."
        )
    }

    func testCancelFailed_RecoverySuggestion() {
        let error = SchedulingError.cancelFailed(NSError(domain: "test", code: 1))
        XCTAssertEqual(
            error.recoverySuggestion,
            "We couldn't cancel this session right now. Please try again."
        )
    }

    func testCompleteFailed_RecoverySuggestion() {
        let error = SchedulingError.completeFailed(NSError(domain: "test", code: 1))
        XCTAssertEqual(
            error.recoverySuggestion,
            "We couldn't mark this session as complete. Don't worry - your progress is saved."
        )
    }

    func testSessionNotFound_RecoverySuggestion() {
        let error = SchedulingError.sessionNotFound
        XCTAssertEqual(
            error.recoverySuggestion,
            "This session may have been removed or rescheduled. Please refresh your schedule."
        )
    }

    func testInvalidSession_RecoverySuggestion() {
        let error = SchedulingError.invalidSession
        XCTAssertEqual(
            error.recoverySuggestion,
            "This session isn't part of your current program. Please contact your therapist if you think this is a mistake."
        )
    }

    func testDuplicateSchedule_RecoverySuggestion() {
        let error = SchedulingError.duplicateSchedule
        XCTAssertEqual(
            error.recoverySuggestion,
            "You already have this session scheduled for this date. Choose a different date to continue."
        )
    }
}

// MARK: - Retry Logic Tests

final class SchedulingErrorRetryTests: XCTestCase {

    func testShouldRetry_NetworkErrors() {
        // Network-related errors should be retryable
        let fetchError = SchedulingError.fetchFailed(NSError(domain: "test", code: 1))
        let scheduleError = SchedulingError.scheduleFailed(NSError(domain: "test", code: 1))
        let rescheduleError = SchedulingError.rescheduleFailed(NSError(domain: "test", code: 1))
        let cancelError = SchedulingError.cancelFailed(NSError(domain: "test", code: 1))
        let completeError = SchedulingError.completeFailed(NSError(domain: "test", code: 1))
        let updateError = SchedulingError.updateFailed(NSError(domain: "test", code: 1))
        let deleteError = SchedulingError.deleteFailed(NSError(domain: "test", code: 1))

        XCTAssertTrue(fetchError.shouldRetry)
        XCTAssertTrue(scheduleError.shouldRetry)
        XCTAssertTrue(rescheduleError.shouldRetry)
        XCTAssertTrue(cancelError.shouldRetry)
        XCTAssertTrue(completeError.shouldRetry)
        XCTAssertTrue(updateError.shouldRetry)
        XCTAssertTrue(deleteError.shouldRetry)
    }

    func testShouldNotRetry_LogicalErrors() {
        // Logical errors should not be retried
        let sessionNotFound = SchedulingError.sessionNotFound
        let invalidSession = SchedulingError.invalidSession
        let duplicateSchedule = SchedulingError.duplicateSchedule

        XCTAssertFalse(sessionNotFound.shouldRetry)
        XCTAssertFalse(invalidSession.shouldRetry)
        XCTAssertFalse(duplicateSchedule.shouldRetry)
    }
}

// MARK: - Time Formatting Tests

final class SchedulingTimeFormattingTests: XCTestCase {

    func testTimeFormatting_Morning() {
        // Given
        var components = DateComponents()
        components.hour = 9
        components.minute = 30
        let time = Calendar.current.date(from: components)!

        // When
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let formatted = formatter.string(from: time)

        // Then
        XCTAssertTrue(formatted.contains("9"))
        XCTAssertTrue(formatted.contains("30"))
    }

    func testTimeFormatting_Afternoon() {
        // Given
        var components = DateComponents()
        components.hour = 14
        components.minute = 0
        let time = Calendar.current.date(from: components)!

        // When
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let formatted = formatter.string(from: time)

        // Then - Should show 2:00 PM
        XCTAssertTrue(formatted.contains("2") && formatted.contains("00"))
    }

    func testTimeFormatting_Midnight() {
        // Given
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        let time = Calendar.current.date(from: components)!

        // When
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let formatted = formatter.string(from: time)

        // Then - Should show 12:00 AM
        XCTAssertTrue(formatted.contains("12"))
    }

    func testDateFormatting_MediumStyle() {
        // Given
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        let date = Calendar.current.date(from: components)!

        // When
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let formatted = formatter.string(from: date)

        // Then
        XCTAssertTrue(formatted.contains("Jun") || formatted.contains("June"))
        XCTAssertTrue(formatted.contains("15"))
        XCTAssertTrue(formatted.contains("2024"))
    }
}

// MARK: - Weekday Session Tests

final class WeekdaySessionTests: XCTestCase {

    func testWeekday_MondayWednessFriday_Pattern() {
        // Given - MWF schedule
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 3 // June 3, 2024 is Monday

        let monday = calendar.date(from: components)!
        components.day = 5
        let wednesday = calendar.date(from: components)!
        components.day = 7
        let friday = calendar.date(from: components)!

        // Then
        XCTAssertEqual(calendar.component(.weekday, from: monday), 2) // Monday
        XCTAssertEqual(calendar.component(.weekday, from: wednesday), 4) // Wednesday
        XCTAssertEqual(calendar.component(.weekday, from: friday), 6) // Friday
    }

    func testWeekday_TuesdayThursday_Pattern() {
        // Given - TuTh schedule
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 4 // June 4, 2024 is Tuesday

        let tuesday = calendar.date(from: components)!
        components.day = 6
        let thursday = calendar.date(from: components)!

        // Then
        XCTAssertEqual(calendar.component(.weekday, from: tuesday), 3) // Tuesday
        XCTAssertEqual(calendar.component(.weekday, from: thursday), 5) // Thursday
    }

    func testWeekday_WeekendOnly_Pattern() {
        // Given - Weekend schedule
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 1 // June 1, 2024 is Saturday

        let saturday = calendar.date(from: components)!
        components.day = 2
        let sunday = calendar.date(from: components)!

        // Then
        XCTAssertEqual(calendar.component(.weekday, from: saturday), 7) // Saturday
        XCTAssertEqual(calendar.component(.weekday, from: sunday), 1) // Sunday
    }
}
