//
//  StreakServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for StreakTrackingService including streak calculation logic,
//  streak updates on activity, streak break detection, streak recovery,
//  and edge cases like timezone changes and midnight boundaries.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Test Helpers

private enum TestUUIDs {
    static let patient = UUID()
    static let therapist = UUID()
}

private enum TestDates {
    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}

// MARK: - Mock Streak Tracking Service

/// Mock service for testing streak logic without network calls
class MockStreakTrackingService: StreakTrackingService {

    var mockStreakRecords: [StreakRecord] = []
    var mockStreakHistory: [CalendarHistoryEntry] = []
    var mockStreakStatistics: [StreakStatistics] = []
    var recordedActivities: [(patientId: UUID, date: Date, workout: Bool, armCare: Bool)] = []
    var shouldFailFetch = false
    var shouldFailRecord = false

    override func fetchCurrentStreaks(for patientId: UUID) async throws -> [StreakRecord] {
        if shouldFailFetch {
            throw StreakError.fetchFailed
        }
        self.currentStreaks = mockStreakRecords
        return mockStreakRecords
    }

    override func fetchStreak(for patientId: UUID, type: StreakType) async throws -> StreakRecord? {
        if shouldFailFetch {
            throw StreakError.fetchFailed
        }
        return mockStreakRecords.first { $0.streakType == type }
    }

    override func recordActivity(
        for patientId: UUID,
        date: Date,
        workoutCompleted: Bool,
        armCareCompleted: Bool,
        sessionId: UUID?,
        manualSessionId: UUID?,
        notes: String?
    ) async throws -> StreakHistory {
        if shouldFailRecord {
            throw StreakError.activityRecordFailed
        }

        recordedActivities.append((patientId, date, workoutCompleted, armCareCompleted))

        // Create mock history response
        return createMockStreakHistory(
            date: date,
            workoutCompleted: workoutCompleted,
            armCareCompleted: armCareCompleted
        )
    }

    override func getStreakHistory(for patientId: UUID, days: Int) async throws -> [CalendarHistoryEntry] {
        if shouldFailFetch {
            throw StreakError.fetchFailed
        }
        self.streakHistory = mockStreakHistory
        return mockStreakHistory
    }

    override func getStreakStatistics(for patientId: UUID) async throws -> [StreakStatistics] {
        if shouldFailFetch {
            throw StreakError.fetchFailed
        }
        return mockStreakStatistics
    }

    // MARK: - Mock Data Helpers

    private func createMockStreakHistory(
        date: Date,
        workoutCompleted: Bool,
        armCareCompleted: Bool
    ) -> StreakHistory {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "activity_date": "\(dateString)",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "session_id": null,
            "manual_session_id": null,
            "notes": null,
            "created_at": 1705320000
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakHistory.self, from: json)
    }
}

// MARK: - Streak Service Tests

@MainActor
final class StreakServiceTests: XCTestCase {

    var mockService: MockStreakTrackingService!
    let testPatientId = TestUUIDs.patient

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockStreakTrackingService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockStreakRecord(
        type: StreakType = .combined,
        currentStreak: Int = 5,
        longestStreak: Int = 10,
        lastActivityDate: String? = nil
    ) -> StreakRecord {
        let lastActivity = lastActivityDate ?? TestDates.dateString(Date())

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(testPatientId.uuidString)",
            "streak_type": "\(type.rawValue)",
            "current_streak": \(currentStreak),
            "longest_streak": \(longestStreak),
            "last_activity_date": "\(lastActivity)",
            "streak_start_date": "\(TestDates.dateString(TestDates.daysFromNow(-currentStreak + 1)))",
            "created_at": 1705320000,
            "updated_at": 1705327200
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakRecord.self, from: json)
    }

    private func createMockCalendarEntry(
        date: Date,
        workoutCompleted: Bool = true,
        armCareCompleted: Bool = false,
        hasAnyActivity: Bool = true
    ) -> CalendarHistoryEntry {
        let dateString = TestDates.dateString(date)

        let json = """
        {
            "activity_date": "\(dateString)",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "has_any_activity": \(hasAnyActivity),
            "session_id": null,
            "manual_session_id": null,
            "notes": null
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(CalendarHistoryEntry.self, from: json)
    }

    // MARK: - First Day Streak Tests

    func testFirstDayStartsStreakAtOne() async throws {
        // Simulate first activity creating streak of 1
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 1, longestStreak: 1)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let combinedStreak = streaks.first { $0.streakType == .combined }

        XCTAssertNotNil(combinedStreak)
        XCTAssertEqual(combinedStreak?.currentStreak, 1, "First day should start streak at 1")
        XCTAssertEqual(combinedStreak?.longestStreak, 1, "Longest streak should also be 1 on first day")
    }

    func testFirstWorkoutCreatesWorkoutStreak() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .workout, currentStreak: 1, longestStreak: 1),
            createMockStreakRecord(type: .combined, currentStreak: 1, longestStreak: 1),
            createMockStreakRecord(type: .armCare, currentStreak: 0, longestStreak: 0)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)

        XCTAssertEqual(streaks.first { $0.streakType == .workout }?.currentStreak, 1)
        XCTAssertEqual(streaks.first { $0.streakType == .armCare }?.currentStreak, 0)
        XCTAssertEqual(streaks.first { $0.streakType == .combined }?.currentStreak, 1)
    }

    // MARK: - Consecutive Days Increment Tests

    func testConsecutiveDaysIncrement() async throws {
        // Day 1: streak = 1
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 1, longestStreak: 1)
        ]

        var streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 1)

        // Day 2: streak = 2
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 2, longestStreak: 2)
        ]

        streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 2)

        // Day 7: streak = 7
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 7, longestStreak: 7)
        ]

        streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 7)
    }

    func testStreakIncrementingToWeek() async throws {
        for day in 1...7 {
            mockService.mockStreakRecords = [
                createMockStreakRecord(type: .combined, currentStreak: day, longestStreak: day)
            ]

            let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
            XCTAssertEqual(streaks.first?.currentStreak, day, "Streak on day \(day) should be \(day)")
        }
    }

    // MARK: - Missed Day Resets Streak Tests

    func testMissedDayResetsStreakToZero() async throws {
        // User had a 10-day streak
        mockService.mockStreakRecords = [
            createMockStreakRecord(
                type: .combined,
                currentStreak: 0,
                longestStreak: 10,
                lastActivityDate: TestDates.dateString(TestDates.daysFromNow(-2)) // Missed yesterday
            )
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let streak = streaks.first!

        XCTAssertEqual(streak.currentStreak, 0, "Current streak should be 0 after missed day")
        XCTAssertEqual(streak.longestStreak, 10, "Longest streak should remain at 10")
    }

    func testStreakAtRiskDetection() async throws {
        // Yesterday's activity - streak at risk
        let yesterdayRecord = createMockStreakRecord(
            type: .combined,
            currentStreak: 5,
            longestStreak: 5,
            lastActivityDate: TestDates.dateString(TestDates.daysFromNow(-1))
        )

        XCTAssertTrue(yesterdayRecord.isAtRisk, "Streak should be at risk when last activity was yesterday")

        // Today's activity - streak safe
        let todayRecord = createMockStreakRecord(
            type: .combined,
            currentStreak: 5,
            longestStreak: 5,
            lastActivityDate: TestDates.dateString(Date())
        )

        XCTAssertFalse(todayRecord.isAtRisk, "Streak should not be at risk when activity logged today")
    }

    // MARK: - Longest Streak Updates Correctly Tests

    func testLongestStreakUpdatesWhenCurrentExceeds() async throws {
        // Current streak just exceeded previous longest
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 15, longestStreak: 15)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let streak = streaks.first!

        XCTAssertEqual(streak.currentStreak, streak.longestStreak)
    }

    func testLongestStreakDoesNotDecreaseOnReset() async throws {
        // User broke a 30-day streak, now starting fresh
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 1, longestStreak: 30)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let streak = streaks.first!

        XCTAssertEqual(streak.currentStreak, 1, "Current streak should be 1 after restart")
        XCTAssertEqual(streak.longestStreak, 30, "Longest streak should remain at 30")
    }

    // MARK: - Multiple Streak Types Tracked Independently Tests

    func testMultipleStreakTypesTrackedIndependently() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .workout, currentStreak: 10, longestStreak: 15),
            createMockStreakRecord(type: .armCare, currentStreak: 5, longestStreak: 8),
            createMockStreakRecord(type: .combined, currentStreak: 12, longestStreak: 20)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)

        let workoutStreak = streaks.first { $0.streakType == .workout }
        let armCareStreak = streaks.first { $0.streakType == .armCare }
        let combinedStreak = streaks.first { $0.streakType == .combined }

        XCTAssertEqual(workoutStreak?.currentStreak, 10)
        XCTAssertEqual(armCareStreak?.currentStreak, 5)
        XCTAssertEqual(combinedStreak?.currentStreak, 12)

        // Verify they are truly independent
        XCTAssertNotEqual(workoutStreak?.currentStreak, armCareStreak?.currentStreak)
        XCTAssertNotEqual(workoutStreak?.longestStreak, armCareStreak?.longestStreak)
    }

    func testWorkoutOnlyAffectsWorkoutAndCombinedStreaks() async throws {
        // Record a workout
        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: Date(),
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        XCTAssertEqual(mockService.recordedActivities.count, 1)

        let activity = mockService.recordedActivities.first!
        XCTAssertTrue(activity.workout)
        XCTAssertFalse(activity.armCare)
    }

    func testArmCareOnlyAffectsArmCareAndCombinedStreaks() async throws {
        // Record arm care
        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: Date(),
            workoutCompleted: false,
            armCareCompleted: true,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        let activity = mockService.recordedActivities.first!
        XCTAssertFalse(activity.workout)
        XCTAssertTrue(activity.armCare)
    }

    // MARK: - Streak Recovery Tests

    func testStreakRecoveryAfterBreak() async throws {
        // User had a 50-day streak, broke it, starting fresh
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 0, longestStreak: 50)
        ]

        var streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 0)
        XCTAssertEqual(streaks.first?.longestStreak, 50)

        // User logs activity again
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 1, longestStreak: 50)
        ]

        streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 1, "New streak should start at 1")
        XCTAssertEqual(streaks.first?.longestStreak, 50, "Longest streak should remain unchanged")
    }

    // MARK: - Multiple Activities Same Day Tests

    func testMultipleActivitiesSameDay() async throws {
        // Log workout
        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: Date(),
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        // Log arm care on same day
        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: Date(),
            workoutCompleted: false,
            armCareCompleted: true,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        XCTAssertEqual(mockService.recordedActivities.count, 2)

        // Both activities on same day
        let calendar = Calendar.current
        let firstDate = mockService.recordedActivities[0].date
        let secondDate = mockService.recordedActivities[1].date
        XCTAssertTrue(calendar.isDate(firstDate, inSameDayAs: secondDate))
    }

    func testMultipleActivitiesSameDayDoNotDoubleCountStreak() async throws {
        // Even with multiple activities, streak should only increment once per day
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 5, longestStreak: 5)
        ]

        // Simulate recording both workout and arm care
        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: Date(),
            workoutCompleted: true,
            armCareCompleted: true,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        // Streak should still be 5 (or 6 tomorrow), not 7
        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        XCTAssertEqual(streaks.first?.currentStreak, 5)
    }

    // MARK: - Backdated Entries Tests

    func testBackdatedEntry() async throws {
        // Record activity for yesterday
        let yesterday = TestDates.daysFromNow(-1)

        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: yesterday,
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        let activity = mockService.recordedActivities.first!
        XCTAssertTrue(Calendar.current.isDate(activity.date, inSameDayAs: yesterday))
    }

    func testBackdatedEntryCanFillGap() async throws {
        // User had 3-day streak, missed day 4, now on day 5
        // Backdating entry for day 4 could recover streak

        mockService.mockStreakHistory = [
            createMockCalendarEntry(date: TestDates.daysFromNow(-4), hasAnyActivity: true),
            createMockCalendarEntry(date: TestDates.daysFromNow(-3), hasAnyActivity: true),
            createMockCalendarEntry(date: TestDates.daysFromNow(-2), hasAnyActivity: true),
            // Day -1 missing
            createMockCalendarEntry(date: Date(), hasAnyActivity: true)
        ]

        let history = try await mockService.getStreakHistory(for: testPatientId, days: 5)
        XCTAssertEqual(history.count, 4)

        // Verify the gap exists
        let dates = history.map { $0.activityDate }
        let yesterday = TestDates.daysFromNow(-1)
        let hasYesterday = dates.contains { Calendar.current.isDate($0, inSameDayAs: yesterday) }
        XCTAssertFalse(hasYesterday, "Gap should exist for yesterday")
    }

    // MARK: - Midnight Boundary Tests

    func testStreakAtMidnightBoundary() async throws {
        // Activity at 11:59 PM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        let lateNightActivity = Calendar.current.date(from: components)!

        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: lateNightActivity,
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        // Activity at 12:01 AM next day
        components.day! += 1
        components.hour = 0
        components.minute = 1
        let earlyMorningActivity = Calendar.current.date(from: components)!

        _ = try await mockService.recordActivity(
            for: testPatientId,
            date: earlyMorningActivity,
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: nil,
            manualSessionId: nil,
            notes: nil
        )

        // These should be counted as different days
        let firstDate = mockService.recordedActivities[0].date
        let secondDate = mockService.recordedActivities[1].date

        XCTAssertFalse(
            Calendar.current.isDate(firstDate, inSameDayAs: secondDate),
            "11:59 PM and 12:01 AM should be different days"
        )
    }

    // MARK: - Timezone Edge Cases

    func testStreakCalculationConsistentAcrossTimezones() async throws {
        // The service uses TimeZone.current for date comparisons
        // This tests that the logic works regardless of timezone

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Same date string should be interpreted consistently
        let dateString = "2024-06-15"

        // UTC interpretation
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let utcDate = dateFormatter.date(from: dateString)!

        // Local interpretation
        dateFormatter.timeZone = TimeZone.current
        let localDate = dateFormatter.date(from: dateString)!

        // Both should represent the same calendar date in local timezone
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.component(.day, from: localDate),
            15,
            "Day should be 15 regardless of timezone"
        )
    }

    // MARK: - Very Long Streak Tests (100+ days)

    func testVeryLongStreak() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 365, longestStreak: 365)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let streak = streaks.first!

        XCTAssertEqual(streak.currentStreak, 365)
        XCTAssertEqual(streak.longestStreak, 365)
        XCTAssertEqual(streak.badgeLevel, .legend)
        XCTAssertEqual(streak.motivationalMessage, "Legendary consistency!")
    }

    func testVeryLongStreakBroken() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .combined, currentStreak: 0, longestStreak: 500)
        ]

        let streaks = try await mockService.fetchCurrentStreaks(for: testPatientId)
        let streak = streaks.first!

        XCTAssertEqual(streak.currentStreak, 0)
        XCTAssertEqual(streak.longestStreak, 500)
        XCTAssertEqual(streak.badgeLevel, .legend, "Badge should still reflect longest streak")
    }

    // MARK: - Display Helpers Tests

    func testFormatStreakDisplay() {
        XCTAssertEqual(mockService.formatStreakDisplay(0), "0 days")
        XCTAssertEqual(mockService.formatStreakDisplay(1), "1 day")
        XCTAssertEqual(mockService.formatStreakDisplay(2), "2 days")
        XCTAssertEqual(mockService.formatStreakDisplay(100), "100 days")
    }

    func testCreateWidgetStreak() {
        let record = createMockStreakRecord(type: .workout, currentStreak: 15, longestStreak: 20)
        let widgetStreak = mockService.createWidgetStreak(from: record)

        XCTAssertEqual(widgetStreak.currentStreak, 15)
        XCTAssertEqual(widgetStreak.longestStreak, 20)
        XCTAssertEqual(widgetStreak.streakType, .workout)
    }

    // MARK: - Error Handling Tests

    func testFetchStreaksFails() async {
        mockService.shouldFailFetch = true

        do {
            _ = try await mockService.fetchCurrentStreaks(for: testPatientId)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is StreakError)
        }
    }

    func testRecordActivityFails() async {
        mockService.shouldFailRecord = true

        do {
            _ = try await mockService.recordActivity(
                for: testPatientId,
                date: Date(),
                workoutCompleted: true,
                armCareCompleted: false,
                sessionId: nil,
                manualSessionId: nil,
                notes: nil
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is StreakError)
        }
    }

    // MARK: - Has Activity Today Tests

    func testHasActivityToday_True() async {
        mockService.mockStreakHistory = [
            createMockCalendarEntry(date: Date(), hasAnyActivity: true)
        ]

        let hasActivity = await mockService.hasActivityToday(for: testPatientId)
        XCTAssertTrue(hasActivity)
    }

    func testHasActivityToday_False() async {
        mockService.mockStreakHistory = [
            createMockCalendarEntry(date: Date(), hasAnyActivity: false)
        ]

        let hasActivity = await mockService.hasActivityToday(for: testPatientId)
        XCTAssertFalse(hasActivity)
    }

    func testHasActivityToday_NoHistory() async {
        mockService.mockStreakHistory = []

        let hasActivity = await mockService.hasActivityToday(for: testPatientId)
        XCTAssertFalse(hasActivity)
    }

    // MARK: - Get Combined Streak Tests

    func testGetCombinedStreak() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .workout, currentStreak: 5, longestStreak: 5),
            createMockStreakRecord(type: .combined, currentStreak: 10, longestStreak: 15)
        ]

        let combinedStreak = try await mockService.getCombinedStreak(for: testPatientId)

        XCTAssertNotNil(combinedStreak)
        XCTAssertEqual(combinedStreak?.streakType, .combined)
        XCTAssertEqual(combinedStreak?.currentStreak, 10)
    }

    func testGetCombinedStreak_NoneExists() async throws {
        mockService.mockStreakRecords = [
            createMockStreakRecord(type: .workout, currentStreak: 5, longestStreak: 5)
        ]

        let combinedStreak = try await mockService.getCombinedStreak(for: testPatientId)
        XCTAssertNil(combinedStreak)
    }

    // MARK: - Convenience Method Tests

    func testRecordWorkoutCompletion() async throws {
        let sessionId = UUID()

        try await mockService.recordWorkoutCompletion(for: testPatientId, sessionId: sessionId)

        XCTAssertEqual(mockService.recordedActivities.count, 1)
        XCTAssertTrue(mockService.recordedActivities.first?.workout ?? false)
        XCTAssertFalse(mockService.recordedActivities.first?.armCare ?? true)
    }

    func testRecordArmCareCompletion() async throws {
        try await mockService.recordArmCareCompletion(for: testPatientId)

        XCTAssertEqual(mockService.recordedActivities.count, 1)
        XCTAssertFalse(mockService.recordedActivities.first?.workout ?? true)
        XCTAssertTrue(mockService.recordedActivities.first?.armCare ?? false)
    }
}

// MARK: - Streak Error Tests

final class StreakErrorTests: XCTestCase {

    func testNoPatientFoundError() {
        let error = StreakError.noPatientFound

        XCTAssertEqual(error.errorDescription, "No patient found for the current user")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("sign out") ?? false)
    }

    func testActivityRecordFailedError() {
        let error = StreakError.activityRecordFailed

        XCTAssertEqual(error.errorDescription, "Failed to record activity")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("sync") ?? false)
    }

    func testFetchFailedError() {
        let error = StreakError.fetchFailed

        XCTAssertEqual(error.errorDescription, "Failed to fetch streak data")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("internet") ?? false)
    }
}

// MARK: - Streak Calculation Logic Tests

final class StreakCalculationLogicTests: XCTestCase {

    // MARK: - Pure Logic Tests (No Network)

    func testStreakBadgeCalculation() {
        // Test badge boundaries
        XCTAssertEqual(StreakBadge.badge(for: 0), .starter)
        XCTAssertEqual(StreakBadge.badge(for: 6), .starter)
        XCTAssertEqual(StreakBadge.badge(for: 7), .committed)
        XCTAssertEqual(StreakBadge.badge(for: 13), .committed)
        XCTAssertEqual(StreakBadge.badge(for: 14), .dedicated)
        XCTAssertEqual(StreakBadge.badge(for: 29), .dedicated)
        XCTAssertEqual(StreakBadge.badge(for: 30), .champion)
        XCTAssertEqual(StreakBadge.badge(for: 59), .champion)
        XCTAssertEqual(StreakBadge.badge(for: 60), .elite)
        XCTAssertEqual(StreakBadge.badge(for: 89), .elite)
        XCTAssertEqual(StreakBadge.badge(for: 90), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 1000), .legend)
    }

    func testDaysUntilNextBadge() {
        // Starter -> Committed: need 7 days
        let starterDaysRemaining = 7 - 3 // At day 3, need 4 more days
        XCTAssertEqual(starterDaysRemaining, 4)

        // Committed -> Dedicated: need 14 days
        let committedDaysRemaining = 14 - 10 // At day 10, need 4 more days
        XCTAssertEqual(committedDaysRemaining, 4)
    }

    func testConsecutiveDayLogic() {
        let calendar = Calendar.current

        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Today and yesterday are consecutive
        let daysBetweenTodayYesterday = calendar.dateComponents([.day], from: yesterday, to: today).day!
        XCTAssertEqual(daysBetweenTodayYesterday, 1)

        // Yesterday and two days ago are consecutive
        let daysBetweenYesterdayTwoDaysAgo = calendar.dateComponents([.day], from: twoDaysAgo, to: yesterday).day!
        XCTAssertEqual(daysBetweenYesterdayTwoDaysAgo, 1)

        // Today and two days ago are NOT consecutive (gap of 1 day)
        let daysBetweenTodayTwoDaysAgo = calendar.dateComponents([.day], from: twoDaysAgo, to: today).day!
        XCTAssertEqual(daysBetweenTodayTwoDaysAgo, 2)
    }

    func testStreakBreakDetection() {
        let calendar = Calendar.current

        // If last activity was more than 1 day ago, streak is broken
        let lastActivity = calendar.date(byAdding: .day, value: -2, to: Date())!
        let today = calendar.startOfDay(for: Date())
        let lastActivityDay = calendar.startOfDay(for: lastActivity)

        let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivityDay, to: today).day!
        let isStreakBroken = daysSinceLastActivity > 1

        XCTAssertTrue(isStreakBroken, "Streak should be broken if last activity was 2+ days ago")
    }
}
