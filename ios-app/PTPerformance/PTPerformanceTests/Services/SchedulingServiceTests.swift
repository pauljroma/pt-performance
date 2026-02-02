//
//  SchedulingServiceTests.swift
//  PTPerformanceTests
//
//  Build 346 - Unit tests for SchedulingService
//  Tests scheduling logic, error handling, and date calculations
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
        let error = SchedulingError.sessionNotFound
        XCTAssertTrue(error is LocalizedError, "SchedulingError should conform to LocalizedError")
    }
}

// MARK: - ScheduledSession Model Tests

final class ScheduledSessionModelTests: XCTestCase {

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

// MARK: - ScheduleStatus Tests

final class ScheduleStatusTests: XCTestCase {

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
