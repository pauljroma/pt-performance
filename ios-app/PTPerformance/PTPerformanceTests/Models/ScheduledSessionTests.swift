//
//  ScheduledSessionTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for ScheduledSession model
//  Tests scheduling logic, conflict detection, and recurring sessions
//

import XCTest
@testable import PTPerformance

// MARK: - ScheduledSession Model Tests

final class ScheduledSessionModelTests: XCTestCase {

    // MARK: - Sample Data Tests

    func testSampleSession_IsValid() {
        // Given/When
        let sample = ScheduledSession.sample

        // Then
        XCTAssertNotNil(sample.id)
        XCTAssertNotNil(sample.patientId)
        XCTAssertNotNil(sample.sessionId)
        XCTAssertEqual(sample.status, .scheduled)
        XCTAssertNil(sample.completedAt)
        XCTAssertFalse(sample.reminderSent)
    }

    func testSampleCompletedSession_HasCompletionDetails() {
        // Given/When
        let sample = ScheduledSession.sampleCompleted

        // Then
        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.status, .completed)
        XCTAssertNotNil(sample.completedAt)
        XCTAssertTrue(sample.reminderSent)
        XCTAssertEqual(sample.notes, "Great workout!")
    }

    // MARK: - Scheduled DateTime Computation Tests

    func testScheduledDateTime_CombinesDateAndTime() {
        // Given
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 6
        dateComponents.day = 15
        let scheduledDate = calendar.date(from: dateComponents)!

        var timeComponents = DateComponents()
        timeComponents.hour = 14
        timeComponents.minute = 30
        let scheduledTime = calendar.date(from: timeComponents)!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let combinedDateTime = session.scheduledDateTime

        // Then
        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: combinedDateTime)
        XCTAssertEqual(resultComponents.year, 2024)
        XCTAssertEqual(resultComponents.month, 6)
        XCTAssertEqual(resultComponents.day, 15)
        XCTAssertEqual(resultComponents.hour, 14)
        XCTAssertEqual(resultComponents.minute, 30)
    }

    // MARK: - isUpcoming Tests

    func testIsUpcoming_FutureScheduledSession_ReturnsTrue() {
        // Given
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

        // Then
        XCTAssertTrue(session.isUpcoming, "Future scheduled session should be upcoming")
    }

    func testIsUpcoming_PastScheduledSession_ReturnsFalse() {
        // Given
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

        // Then
        XCTAssertFalse(session.isUpcoming, "Past session should not be upcoming")
    }

    func testIsUpcoming_CompletedSession_ReturnsFalse() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: futureDate,
            scheduledTime: Date(),
            status: .completed,
            completedAt: Date(),
            reminderSent: true,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(session.isUpcoming, "Completed session should not be upcoming")
    }

    func testIsUpcoming_CancelledSession_ReturnsFalse() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: futureDate,
            scheduledTime: Date(),
            status: .cancelled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(session.isUpcoming, "Cancelled session should not be upcoming")
    }

    // MARK: - isPastDue Tests

    func testIsPastDue_PastScheduledSession_ReturnsTrue() {
        // Given
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

        // Then
        XCTAssertTrue(session.isPastDue, "Past scheduled session should be past due")
    }

    func testIsPastDue_CompletedSession_ReturnsFalse() {
        // Given
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

        // Then
        XCTAssertFalse(session.isPastDue, "Completed session should not be past due")
    }

    func testIsPastDue_FutureSession_ReturnsFalse() {
        // Given
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

        // Then
        XCTAssertFalse(session.isPastDue, "Future session should not be past due")
    }

    // MARK: - Display Name Tests

    func testDisplayName_WithNotes_ReturnsNotes() {
        // Given
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

        // Then
        XCTAssertEqual(session.displayName, "Morning workout")
    }

    func testDisplayName_WithEmptyNotes_ReturnsDaySession() {
        // Given
        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: Date(),
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(session.displayName.contains("Session"),
                      "Display name should contain 'Session'")
    }

    func testDisplayName_WithoutNotes_ReturnsDaySession() {
        // Given
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

        // Then
        XCTAssertTrue(session.displayName.contains("Session"))
    }

    // MARK: - Formatted Date Tests

    func testFormattedDate_ReturnsNonEmptyString() {
        // Given
        let session = ScheduledSession.sample

        // When
        let formattedDate = session.formattedDate

        // Then
        XCTAssertFalse(formattedDate.isEmpty)
    }

    func testFormattedDate_ContainsExpectedComponents() {
        // Given
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        let date = calendar.date(from: components)!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: date,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let formattedDate = session.formattedDate

        // Then - Should contain month, day, and year in some format
        XCTAssertTrue(formattedDate.contains("Jun") || formattedDate.contains("June") || formattedDate.contains("6"),
                      "Formatted date should contain month")
        XCTAssertTrue(formattedDate.contains("15"),
                      "Formatted date should contain day")
    }

    // MARK: - Formatted Time Tests

    func testFormattedTime_ReturnsNonEmptyString() {
        // Given
        let session = ScheduledSession.sample

        // When
        let formattedTime = session.formattedTime

        // Then
        XCTAssertFalse(formattedTime.isEmpty)
    }

    // MARK: - Relative Time String Tests

    func testRelativeTimeString_Today_ContainsToday() {
        // Given
        let today = Calendar.current.startOfDay(for: Date())
        let laterToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: today)!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: laterToday,
            scheduledTime: laterToday,
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(session.relativeTimeString.contains("Today"),
                      "Should show 'Today' for today's sessions")
    }

    func testRelativeTimeString_Tomorrow_ContainsTomorrow() {
        // Given
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

        // Then
        XCTAssertTrue(session.relativeTimeString.contains("Tomorrow"),
                      "Should show 'Tomorrow' for tomorrow's sessions")
    }

    func testRelativeTimeString_ThisWeek_ContainsDayName() {
        // Given
        let inThreeDays = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let expectedDayName = formatter.string(from: inThreeDays)

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: inThreeDays,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(session.relativeTimeString.contains(expectedDayName),
                      "Should show day name for sessions within the week")
    }

    func testRelativeTimeString_FarFuture_ContainsFullDate() {
        // Given
        let inTwoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: Date())!

        let session = ScheduledSession.__createDirectly(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            scheduledDate: inTwoWeeks,
            scheduledTime: Date(),
            status: .scheduled,
            completedAt: nil,
            reminderSent: false,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then - Should contain the formatted date, not just day name
        let relativeString = session.relativeTimeString
        XCTAssertFalse(relativeString.contains("Today"))
        XCTAssertFalse(relativeString.contains("Tomorrow"))
        XCTAssertTrue(relativeString.contains("at"), "Should contain 'at' separator")
    }

    // MARK: - Hashable Tests

    func testScheduledSession_Hashable_DifferentSessionsDifferentHash() {
        // Given
        let session1 = ScheduledSession.sample
        let session2 = ScheduledSession.sample

        // Then
        XCTAssertNotEqual(session1.hashValue, session2.hashValue,
                          "Different sessions should have different hashes")
    }

    func testScheduledSession_Hashable_SameSessionSameHash() {
        // Given
        let session = ScheduledSession.sample

        // Then
        XCTAssertEqual(session.hashValue, session.hashValue,
                       "Same session should have consistent hash")
    }

    // MARK: - Equatable Tests

    func testScheduledSession_Equatable_DifferentSessions() {
        // Given
        let session1 = ScheduledSession.sample
        let session2 = ScheduledSession.sample

        // Then
        XCTAssertNotEqual(session1, session2,
                          "Different sessions should not be equal")
    }

    func testScheduledSession_Equatable_SameSession() {
        // Given
        let session = ScheduledSession.sample

        // Then
        XCTAssertEqual(session, session,
                       "Session should be equal to itself")
    }
}

// MARK: - ScheduleStatus Tests

final class ScheduleStatusTests: XCTestCase {

    func testAllStatuses_Exist() {
        // Given/When
        let scheduled = ScheduledSession.ScheduleStatus.scheduled
        let completed = ScheduledSession.ScheduleStatus.completed
        let cancelled = ScheduledSession.ScheduleStatus.cancelled
        let rescheduled = ScheduledSession.ScheduleStatus.rescheduled

        // Then
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
        // Given
        let json = "\"scheduled\"".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let status = try decoder.decode(ScheduledSession.ScheduleStatus.self, from: json)

        // Then
        XCTAssertEqual(status, .scheduled)
    }

    func testStatusEncoding() throws {
        // Given
        let status = ScheduledSession.ScheduleStatus.completed
        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(status)
        let jsonString = String(data: data, encoding: .utf8)

        // Then
        XCTAssertEqual(jsonString, "\"completed\"")
    }

    func testAllStatusesDecoding() throws {
        let decoder = JSONDecoder()
        let statuses: [(String, ScheduledSession.ScheduleStatus)] = [
            ("\"scheduled\"", .scheduled),
            ("\"completed\"", .completed),
            ("\"cancelled\"", .cancelled),
            ("\"rescheduled\"", .rescheduled)
        ]

        for (json, expected) in statuses {
            let data = json.data(using: .utf8)!
            let decoded = try decoder.decode(ScheduledSession.ScheduleStatus.self, from: data)
            XCTAssertEqual(decoded, expected)
        }
    }
}

// MARK: - Conflict Detection Tests

final class SchedulingConflictDetectionTests: XCTestCase {

    func testConflictDetection_SameTimeSlot_IsConflict() {
        // Given - Two sessions at the same time
        let date = Date()
        let session1Time = date
        let session2Time = date

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: session1Time,
            session1Duration: 60,
            session2Start: session2Time,
            session2Duration: 60
        )

        // Then
        XCTAssertTrue(hasConflict, "Sessions at same time should conflict")
    }

    func testConflictDetection_OverlappingSessions_IsConflict() {
        // Given - Session 1: 9:00-10:00, Session 2: 9:30-10:30
        let session1Start = createDateTime(hour: 9, minute: 0)
        let session2Start = createDateTime(hour: 9, minute: 30)

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: session1Start,
            session1Duration: 60,
            session2Start: session2Start,
            session2Duration: 60
        )

        // Then
        XCTAssertTrue(hasConflict, "Overlapping sessions should conflict")
    }

    func testConflictDetection_NonOverlappingSessions_NoConflict() {
        // Given - Session 1: 9:00-10:00, Session 2: 10:00-11:00
        let session1Start = createDateTime(hour: 9, minute: 0)
        let session2Start = createDateTime(hour: 10, minute: 0)

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: session1Start,
            session1Duration: 60,
            session2Start: session2Start,
            session2Duration: 60
        )

        // Then
        XCTAssertFalse(hasConflict, "Non-overlapping sessions should not conflict")
    }

    func testConflictDetection_AdjacentSessions_NoConflict() {
        // Given - Session 1: 9:00-10:00, Session 2: 10:01-11:01
        let session1Start = createDateTime(hour: 9, minute: 0)
        let session2Start = createDateTime(hour: 10, minute: 1)

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: session1Start,
            session1Duration: 60,
            session2Start: session2Start,
            session2Duration: 60
        )

        // Then
        XCTAssertFalse(hasConflict, "Adjacent sessions should not conflict")
    }

    func testConflictDetection_SessionContainedWithinAnother_IsConflict() {
        // Given - Session 1: 8:00-12:00, Session 2: 9:00-10:00
        let session1Start = createDateTime(hour: 8, minute: 0)
        let session2Start = createDateTime(hour: 9, minute: 0)

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: session1Start,
            session1Duration: 240, // 4 hours
            session2Start: session2Start,
            session2Duration: 60
        )

        // Then
        XCTAssertTrue(hasConflict, "Session contained within another should conflict")
    }

    func testConflictDetection_DifferentDays_NoConflict() {
        // Given - Same time but different days
        let today = createDateTime(hour: 9, minute: 0, daysOffset: 0)
        let tomorrow = createDateTime(hour: 9, minute: 0, daysOffset: 1)

        // When
        let hasConflict = timeSlotsOverlap(
            session1Start: today,
            session1Duration: 60,
            session2Start: tomorrow,
            session2Duration: 60
        )

        // Then
        XCTAssertFalse(hasConflict, "Sessions on different days should not conflict")
    }

    // MARK: - Helpers

    private func createDateTime(hour: Int, minute: Int, daysOffset: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15 + daysOffset
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func timeSlotsOverlap(
        session1Start: Date,
        session1Duration: Int,
        session2Start: Date,
        session2Duration: Int
    ) -> Bool {
        let session1End = Calendar.current.date(
            byAdding: .minute,
            value: session1Duration,
            to: session1Start
        )!
        let session2End = Calendar.current.date(
            byAdding: .minute,
            value: session2Duration,
            to: session2Start
        )!

        // Two intervals overlap if neither is completely before the other
        return session1Start < session2End && session2Start < session1End
    }
}

// MARK: - Recurring Session Tests

final class RecurringSessionTests: XCTestCase {

    func testRecurringSession_WeeklyOccurrences() {
        // Given
        let startDate = createDate(year: 2024, month: 6, day: 3) // Monday
        let occurrences = 4

        // When
        let sessions = generateWeeklyRecurringSessions(
            startingFrom: startDate,
            occurrences: occurrences
        )

        // Then
        XCTAssertEqual(sessions.count, occurrences)

        // Verify each is 7 days apart
        for i in 1..<sessions.count {
            let daysBetween = Calendar.current.dateComponents(
                [.day],
                from: sessions[i-1],
                to: sessions[i]
            ).day!
            XCTAssertEqual(daysBetween, 7, "Weekly sessions should be 7 days apart")
        }
    }

    func testRecurringSession_DailyOccurrences() {
        // Given
        let startDate = createDate(year: 2024, month: 6, day: 1)
        let occurrences = 7

        // When
        let sessions = generateDailyRecurringSessions(
            startingFrom: startDate,
            occurrences: occurrences
        )

        // Then
        XCTAssertEqual(sessions.count, occurrences)

        // Verify each is 1 day apart
        for i in 1..<sessions.count {
            let daysBetween = Calendar.current.dateComponents(
                [.day],
                from: sessions[i-1],
                to: sessions[i]
            ).day!
            XCTAssertEqual(daysBetween, 1, "Daily sessions should be 1 day apart")
        }
    }

    func testRecurringSession_SpecificDaysOfWeek() {
        // Given - MWF schedule
        let startDate = createDate(year: 2024, month: 6, day: 3) // Monday
        let targetDays = [2, 4, 6] // Mon, Wed, Fri (weekday 1=Sun)
        let weeksCount = 2

        // When
        let sessions = generateRecurringSessionsForDays(
            startingFrom: startDate,
            daysOfWeek: targetDays,
            weeks: weeksCount
        )

        // Then
        XCTAssertEqual(sessions.count, targetDays.count * weeksCount)

        // Verify all sessions are on correct days
        for session in sessions {
            let weekday = Calendar.current.component(.weekday, from: session)
            XCTAssertTrue(targetDays.contains(weekday),
                          "Session should be on Mon, Wed, or Fri")
        }
    }

    func testRecurringSession_ExcludesSpecificDates() {
        // Given
        let startDate = createDate(year: 2024, month: 6, day: 1)
        let excludeDate = createDate(year: 2024, month: 6, day: 3)
        let occurrences = 5

        // When
        let sessions = generateDailyRecurringSessions(
            startingFrom: startDate,
            occurrences: occurrences,
            excluding: [excludeDate]
        )

        // Then - Should have occurrences + 1 to make up for excluded date
        XCTAssertEqual(sessions.count, occurrences)

        // Verify excluded date is not in list
        for session in sessions {
            XCTAssertFalse(Calendar.current.isDate(session, inSameDayAs: excludeDate),
                           "Excluded date should not be in recurring sessions")
        }
    }

    func testRecurringSession_EndDateRespected() {
        // Given
        let startDate = createDate(year: 2024, month: 6, day: 1)
        let endDate = createDate(year: 2024, month: 6, day: 10)

        // When
        let sessions = generateDailyRecurringSessions(
            startingFrom: startDate,
            until: endDate
        )

        // Then
        XCTAssertEqual(sessions.count, 10) // June 1-10

        // Verify all sessions are within date range
        for session in sessions {
            XCTAssertTrue(session >= startDate)
            XCTAssertTrue(session <= endDate)
        }
    }

    // MARK: - Helpers

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func generateWeeklyRecurringSessions(
        startingFrom start: Date,
        occurrences: Int
    ) -> [Date] {
        var sessions: [Date] = []
        var currentDate = start

        for _ in 0..<occurrences {
            sessions.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate)!
        }

        return sessions
    }

    private func generateDailyRecurringSessions(
        startingFrom start: Date,
        occurrences: Int,
        excluding: [Date] = []
    ) -> [Date] {
        var sessions: [Date] = []
        var currentDate = start
        var added = 0

        while added < occurrences {
            let isExcluded = excluding.contains { Calendar.current.isDate($0, inSameDayAs: currentDate) }

            if !isExcluded {
                sessions.append(currentDate)
                added += 1
            }

            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return sessions
    }

    private func generateDailyRecurringSessions(
        startingFrom start: Date,
        until end: Date
    ) -> [Date] {
        var sessions: [Date] = []
        var currentDate = start

        while currentDate <= end {
            sessions.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return sessions
    }

    private func generateRecurringSessionsForDays(
        startingFrom start: Date,
        daysOfWeek: [Int],
        weeks: Int
    ) -> [Date] {
        var sessions: [Date] = []
        var currentDate = start

        let endDate = Calendar.current.date(byAdding: .day, value: weeks * 7, to: start)!

        while currentDate < endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate)
            if daysOfWeek.contains(weekday) {
                sessions.append(currentDate)
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return sessions
    }
}

// MARK: - Time Parsing Tests

final class ScheduledSessionTimeParsingTests: XCTestCase {

    func testTimeParsing_ValidTimeString() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "session_id": "123e4567-e89b-12d3-a456-426614174002",
            "scheduled_date": "2024-06-15T00:00:00Z",
            "scheduled_time": "14:30:00",
            "status": "scheduled",
            "reminder_sent": false,
            "created_at": "2024-06-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let session = try decoder.decode(ScheduledSession.self, from: json)

        // Then
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: session.scheduledTime)
        let minute = calendar.component(.minute, from: session.scheduledTime)
        XCTAssertEqual(hour, 14)
        XCTAssertEqual(minute, 30)
    }

    func testTimeParsing_MidnightTime() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "session_id": "123e4567-e89b-12d3-a456-426614174002",
            "scheduled_date": "2024-06-15T00:00:00Z",
            "scheduled_time": "00:00:00",
            "status": "scheduled",
            "reminder_sent": false,
            "created_at": "2024-06-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let session = try decoder.decode(ScheduledSession.self, from: json)

        // Then
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: session.scheduledTime)
        XCTAssertEqual(hour, 0)
    }

    func testTimeParsing_EndOfDayTime() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "session_id": "123e4567-e89b-12d3-a456-426614174002",
            "scheduled_date": "2024-06-15T00:00:00Z",
            "scheduled_time": "23:59:00",
            "status": "scheduled",
            "reminder_sent": false,
            "created_at": "2024-06-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let session = try decoder.decode(ScheduledSession.self, from: json)

        // Then
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: session.scheduledTime)
        let minute = calendar.component(.minute, from: session.scheduledTime)
        XCTAssertEqual(hour, 23)
        XCTAssertEqual(minute, 59)
    }
}
