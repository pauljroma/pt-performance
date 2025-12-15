//
//  SchedulingTests.swift
//  PTPerformanceTests
//
//  Created by Build 46 Swarm Agent 1
//  Integration tests for scheduling workflows
//

import XCTest
@testable import PTPerformance

final class SchedulingTests: IntegrationTestBase {

    var schedulingService: SchedulingService!
    var testPatientId: String!
    var testSessionId: String!

    override func setUp() async throws {
        try await super.setUp()
        schedulingService = SchedulingService.shared

        // Login as patient
        let session = try await loginAsPatient()
        testPatientId = session.user.id.uuidString

        // Get a session from patient's active program
        testSessionId = try await getFirstSessionFromActiveProgram()
    }

    // MARK: - Schedule Session Tests

    func testScheduleSession_Success() async throws {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduledTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

        let scheduledSession = try await schedulingService.scheduleSession(
            patientId: testPatientId,
            sessionId: testSessionId,
            date: tomorrow,
            time: scheduledTime,
            notes: "Test session"
        )

        // Verify created session
        XCTAssertNotNil(scheduledSession.id, "Scheduled session should have an ID")
        XCTAssertEqual(scheduledSession.patientId, testPatientId)
        XCTAssertEqual(scheduledSession.sessionId, testSessionId)
        XCTAssertEqual(scheduledSession.status, .scheduled)
        XCTAssertEqual(scheduledSession.notes, "Test session")
        XCTAssertFalse(scheduledSession.reminderSent)
        XCTAssertNil(scheduledSession.completedAt)

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: scheduledSession.id)
    }

    func testScheduleSession_DuplicateDate_Fails() async throws {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduledTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        // Schedule first session
        let firstSession = try await schedulingService.scheduleSession(
            patientId: testPatientId,
            sessionId: testSessionId,
            date: tomorrow,
            time: scheduledTime
        )

        // Try to schedule same session on same date
        do {
            _ = try await schedulingService.scheduleSession(
                patientId: testPatientId,
                sessionId: testSessionId,
                date: tomorrow,
                time: scheduledTime
            )
            XCTFail("Should not allow duplicate schedule on same date")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is SchedulingError)
        }

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: firstSession.id)
    }

    func testScheduleSession_InvalidSession_Fails() async throws {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduledTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
        let invalidSessionId = UUID().uuidString

        do {
            _ = try await schedulingService.scheduleSession(
                patientId: testPatientId,
                sessionId: invalidSessionId,
                date: tomorrow,
                time: scheduledTime
            )
            XCTFail("Should not allow scheduling invalid session")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is SchedulingError)
        }
    }

    // MARK: - Fetch Sessions Tests

    func testFetchScheduledSessions_Success() async throws {
        // Schedule multiple sessions
        let session1 = try await scheduleTestSession(daysFromNow: 1, hour: 10)
        let session2 = try await scheduleTestSession(daysFromNow: 2, hour: 14)
        let session3 = try await scheduleTestSession(daysFromNow: 7, hour: 9)

        // Fetch all scheduled sessions
        let sessions = try await schedulingService.fetchScheduledSessions(for: testPatientId)

        // Verify at least our 3 sessions are returned
        XCTAssertGreaterThanOrEqual(sessions.count, 3)

        // Verify sessions are ordered by date and time
        let sortedSessions = sessions.sorted { $0.scheduledDateTime < $1.scheduledDateTime }
        XCTAssertEqual(sessions.map { $0.id }, sortedSessions.map { $0.id })

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: session1.id)
        try await schedulingService.deleteSession(scheduledSessionId: session2.id)
        try await schedulingService.deleteSession(scheduledSessionId: session3.id)
    }

    func testFetchUpcomingSessions_FiltersCorrectly() async throws {
        // Schedule sessions at different times
        let upcoming1 = try await scheduleTestSession(daysFromNow: 1, hour: 10)
        let upcoming2 = try await scheduleTestSession(daysFromNow: 5, hour: 14)
        let farFuture = try await scheduleTestSession(daysFromNow: 45, hour: 9)

        // Fetch upcoming sessions (next 30 days)
        let upcomingSessions = try await schedulingService.fetchUpcomingSessions(
            for: testPatientId,
            days: 30
        )

        // Verify only sessions within 30 days are returned
        let upcomingIds = upcomingSessions.map { $0.id }
        XCTAssertTrue(upcomingIds.contains(upcoming1.id))
        XCTAssertTrue(upcomingIds.contains(upcoming2.id))
        XCTAssertFalse(upcomingIds.contains(farFuture.id), "Should not include sessions beyond 30 days")

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: upcoming1.id)
        try await schedulingService.deleteSession(scheduledSessionId: upcoming2.id)
        try await schedulingService.deleteSession(scheduledSessionId: farFuture.id)
    }

    // MARK: - Reschedule Tests

    func testRescheduleSession_Success() async throws {
        let originalDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let originalTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        // Schedule session
        let scheduledSession = try await schedulingService.scheduleSession(
            patientId: testPatientId,
            sessionId: testSessionId,
            date: originalDate,
            time: originalTime
        )

        // Reschedule to new date/time
        let newDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let newTime = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        let rescheduled = try await schedulingService.rescheduleSession(
            scheduledSessionId: scheduledSession.id,
            newDate: newDate,
            newTime: newTime
        )

        // Verify rescheduled session
        XCTAssertEqual(rescheduled.id, scheduledSession.id)
        XCTAssertEqual(rescheduled.status, .rescheduled)
        XCTAssertFalse(rescheduled.reminderSent, "Reminder flag should be reset")

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: rescheduled.id)
    }

    // MARK: - Cancel Tests

    func testCancelSession_Success() async throws {
        // Schedule session
        let scheduledSession = try await scheduleTestSession(daysFromNow: 2, hour: 10)

        // Cancel session
        try await schedulingService.cancelSession(scheduledSessionId: scheduledSession.id)

        // Fetch and verify status
        let sessions = try await schedulingService.fetchScheduledSessions(for: testPatientId)
        let cancelled = sessions.first { $0.id == scheduledSession.id }

        XCTAssertNotNil(cancelled)
        XCTAssertEqual(cancelled?.status, .cancelled)

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: scheduledSession.id)
    }

    // MARK: - Complete Tests

    func testCompleteSession_Success() async throws {
        // Schedule session
        let scheduledSession = try await scheduleTestSession(daysFromNow: 0, hour: 10)

        // Complete session
        let completed = try await schedulingService.completeSession(
            scheduledSessionId: scheduledSession.id
        )

        // Verify completed session
        XCTAssertEqual(completed.id, scheduledSession.id)
        XCTAssertEqual(completed.status, .completed)
        XCTAssertNotNil(completed.completedAt)

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: completed.id)
    }

    // MARK: - Update Notes Tests

    func testUpdateNotes_Success() async throws {
        // Schedule session
        let scheduledSession = try await scheduleTestSession(daysFromNow: 1, hour: 10)

        // Update notes
        let newNotes = "Updated test notes"
        try await schedulingService.updateNotes(
            scheduledSessionId: scheduledSession.id,
            notes: newNotes
        )

        // Fetch and verify notes
        let sessions = try await schedulingService.fetchScheduledSessions(for: testPatientId)
        let updated = sessions.first { $0.id == scheduledSession.id }

        XCTAssertEqual(updated?.notes, newNotes)

        // Cleanup
        try await schedulingService.deleteSession(scheduledSessionId: scheduledSession.id)
    }

    // MARK: - Performance Tests

    func testScheduleSession_Performance() async throws {
        let date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let time = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        measure {
            let expectation = self.expectation(description: "Schedule session")

            Task {
                do {
                    let session = try await schedulingService.scheduleSession(
                        patientId: testPatientId,
                        sessionId: testSessionId,
                        date: date,
                        time: time
                    )

                    // Cleanup
                    try await schedulingService.deleteSession(scheduledSessionId: session.id)

                    expectation.fulfill()
                } catch {
                    XCTFail("Schedule failed: \(error)")
                    expectation.fulfill()
                }
            }

            waitForExpectations(timeout: 5.0)
        }
    }

    func testFetchScheduledSessions_Performance() async throws {
        // Schedule multiple sessions for testing
        let sessions = try await (1...10).asyncMap { day in
            try await scheduleTestSession(daysFromNow: day, hour: 10)
        }

        measure {
            let expectation = self.expectation(description: "Fetch sessions")

            Task {
                do {
                    _ = try await schedulingService.fetchScheduledSessions(for: testPatientId)
                    expectation.fulfill()
                } catch {
                    XCTFail("Fetch failed: \(error)")
                    expectation.fulfill()
                }
            }

            waitForExpectations(timeout: 5.0)
        }

        // Cleanup
        for session in sessions {
            try await schedulingService.deleteSession(scheduledSessionId: session.id)
        }
    }

    // MARK: - RLS Policy Tests

    func testPatientCannotAccessOtherPatientSchedules() async throws {
        // Schedule session as current patient
        let mySession = try await scheduleTestSession(daysFromNow: 1, hour: 10)

        // Login as different patient
        try await loginAsPatient(email: "patient2@test.com") // Assume different patient exists

        // Try to fetch sessions - should only see own sessions
        let sessions = try await schedulingService.fetchScheduledSessions(for: testPatientId)

        // Should not see the first patient's session
        let foundMySession = sessions.contains { $0.id == mySession.id }
        XCTAssertFalse(foundMySession, "RLS VIOLATION: Patient can see other patient's schedules!")

        // Cleanup (switch back to original patient)
        try await loginAsPatient()
        try await schedulingService.deleteSession(scheduledSessionId: mySession.id)
    }

    // MARK: - Helper Methods

    private func scheduleTestSession(daysFromNow: Int, hour: Int) async throws -> ScheduledSession {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        let time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!

        return try await schedulingService.scheduleSession(
            patientId: testPatientId,
            sessionId: testSessionId,
            date: date,
            time: time
        )
    }

    private func getFirstSessionFromActiveProgram() async throws -> String {
        // Query first session from patient's active program
        let sessions: [Session] = try await supabase.client
            .from("sessions")
            .select("""
                *,
                phases!inner (
                    *,
                    programs!inner (
                        id,
                        patient_id,
                        status
                    )
                )
            """)
            .eq("programs.patient_id", value: testPatientId)
            .eq("programs.status", value: "active")
            .limit(1)
            .execute()
            .value

        guard let firstSession = sessions.first else {
            throw NSError(
                domain: "TestError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No active program sessions found"]
            )
        }

        return firstSession.id
    }
}

// MARK: - Array Extension for Async Map

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}
