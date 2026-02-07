//
//  StreakTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for Streak models including StreakRecord, StreakHistory,
//  StreakStatistics, CalendarHistoryEntry, and StreakBadge.
//  Tests streak types, current vs longest streak logic, and edge cases.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Test Date Helpers

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

// MARK: - StreakRecord Tests

final class StreakRecordTests: XCTestCase {

    // MARK: - Factory Helpers

    private func createStreakRecord(
        id: UUID = UUID(),
        patientId: UUID = UUID(),
        streakType: String = "combined",
        currentStreak: Int = 5,
        longestStreak: Int = 10,
        lastActivityDate: String? = nil,
        streakStartDate: String? = nil
    ) -> StreakRecord {
        let lastActivity = lastActivityDate ?? TestDates.dateString(Date())
        let startDate = streakStartDate ?? TestDates.dateString(TestDates.daysFromNow(-currentStreak + 1))

        let json = """
        {
            "id": "\(id.uuidString)",
            "patient_id": "\(patientId.uuidString)",
            "streak_type": "\(streakType)",
            "current_streak": \(currentStreak),
            "longest_streak": \(longestStreak),
            "last_activity_date": "\(lastActivity)",
            "streak_start_date": "\(startDate)",
            "created_at": 1705320000,
            "updated_at": 1705327200
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakRecord.self, from: json)
    }

    private func createStreakRecordWithNullDates() -> StreakRecord {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "streak_type": "combined",
            "current_streak": 0,
            "longest_streak": 0,
            "last_activity_date": null,
            "streak_start_date": null,
            "created_at": 1705320000,
            "updated_at": 1705327200
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakRecord.self, from: json)
    }

    // MARK: - Initialization Tests

    func testStreakRecord_DecodesFromJSON() {
        let record = createStreakRecord(currentStreak: 7, longestStreak: 14)

        XCTAssertEqual(record.currentStreak, 7)
        XCTAssertEqual(record.longestStreak, 14)
        XCTAssertEqual(record.streakType, .combined)
    }

    func testStreakRecord_DecodesWorkoutType() {
        let record = createStreakRecord(streakType: "workout")
        XCTAssertEqual(record.streakType, .workout)
    }

    func testStreakRecord_DecodesArmCareType() {
        let record = createStreakRecord(streakType: "arm_care")
        XCTAssertEqual(record.streakType, .armCare)
    }

    func testStreakRecord_DecodesCombinedType() {
        let record = createStreakRecord(streakType: "combined")
        XCTAssertEqual(record.streakType, .combined)
    }

    func testStreakRecord_InvalidTypeDefaultsToCombined() {
        let record = createStreakRecord(streakType: "invalid_type")
        XCTAssertEqual(record.streakType, .combined)
    }

    func testStreakRecord_HandlesNullDates() {
        let record = createStreakRecordWithNullDates()

        XCTAssertNil(record.lastActivityDate)
        XCTAssertNil(record.streakStartDate)
        XCTAssertEqual(record.currentStreak, 0)
    }

    // MARK: - Current vs Longest Streak Logic Tests

    func testStreakRecord_CurrentCanEqualLongest() {
        let record = createStreakRecord(currentStreak: 30, longestStreak: 30)

        XCTAssertEqual(record.currentStreak, 30)
        XCTAssertEqual(record.longestStreak, 30)
    }

    func testStreakRecord_CurrentCanBeLessThanLongest() {
        let record = createStreakRecord(currentStreak: 5, longestStreak: 45)

        XCTAssertEqual(record.currentStreak, 5)
        XCTAssertEqual(record.longestStreak, 45)
        XCTAssertLessThan(record.currentStreak, record.longestStreak)
    }

    func testStreakRecord_LongestStreakNeverDecreasesLogically() {
        // In practice, longest should always be >= current
        let record = createStreakRecord(currentStreak: 10, longestStreak: 50)

        XCTAssertGreaterThanOrEqual(record.longestStreak, record.currentStreak)
    }

    // MARK: - IsAtRisk Tests

    func testIsAtRisk_TrueWhenLastActivityIsNull() {
        let record = createStreakRecordWithNullDates()
        XCTAssertTrue(record.isAtRisk, "Streak should be at risk when no activity recorded")
    }

    func testIsAtRisk_FalseWhenActivityToday() {
        let todayString = TestDates.dateString(Date())
        let record = createStreakRecord(lastActivityDate: todayString)

        XCTAssertFalse(record.isAtRisk, "Streak should not be at risk when activity logged today")
    }

    func testIsAtRisk_TrueWhenActivityYesterday() {
        let yesterdayString = TestDates.dateString(TestDates.daysFromNow(-1))
        let record = createStreakRecord(lastActivityDate: yesterdayString)

        XCTAssertTrue(record.isAtRisk, "Streak should be at risk when last activity was yesterday")
    }

    func testIsAtRisk_TrueWhenActivityTwoDaysAgo() {
        let twoDaysAgoString = TestDates.dateString(TestDates.daysFromNow(-2))
        let record = createStreakRecord(lastActivityDate: twoDaysAgoString)

        XCTAssertTrue(record.isAtRisk)
    }

    // MARK: - Motivational Message Tests

    func testMotivationalMessage_ZeroStreak() {
        let record = createStreakRecord(currentStreak: 0, longestStreak: 0)
        XCTAssertEqual(record.motivationalMessage, "Start your streak today!")
    }

    func testMotivationalMessage_FirstDay() {
        let record = createStreakRecord(currentStreak: 1, longestStreak: 1)
        XCTAssertEqual(record.motivationalMessage, "Great start! Keep going!")
    }

    func testMotivationalMessage_BuildingMomentum() {
        for day in 2...6 {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "Building momentum!", "Day \(day) should show building momentum")
        }
    }

    func testMotivationalMessage_OneWeekStrong() {
        for day in 7...13 {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "One week strong!", "Day \(day) should show one week strong")
        }
    }

    func testMotivationalMessage_TwoWeeks() {
        for day in 14...29 {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "Two weeks! Amazing!", "Day \(day) should show two weeks")
        }
    }

    func testMotivationalMessage_OneMonth() {
        for day in [30, 45, 59] {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "One month! Incredible!", "Day \(day) should show one month")
        }
    }

    func testMotivationalMessage_TwoMonths() {
        for day in [60, 75, 89] {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "Two months! Unstoppable!", "Day \(day) should show two months")
        }
    }

    func testMotivationalMessage_LegendaryConsistency() {
        for day in [90, 100, 365, 1000] {
            let record = createStreakRecord(currentStreak: day, longestStreak: day)
            XCTAssertEqual(record.motivationalMessage, "Legendary consistency!", "Day \(day) should show legendary")
        }
    }

    // MARK: - Badge Level Tests

    func testBadgeLevel_BasedOnLongestStreak() {
        let record = createStreakRecord(currentStreak: 5, longestStreak: 35)
        XCTAssertEqual(record.badgeLevel, .champion, "Badge should be based on longest streak (35 days = champion)")
    }

    func testBadgeLevel_StarterForShortStreak() {
        let record = createStreakRecord(currentStreak: 3, longestStreak: 5)
        XCTAssertEqual(record.badgeLevel, .starter)
    }

    func testBadgeLevel_LegendForLongStreak() {
        let record = createStreakRecord(currentStreak: 50, longestStreak: 150)
        XCTAssertEqual(record.badgeLevel, .legend)
    }

    // MARK: - Equatable & Hashable Tests

    func testStreakRecord_Equatable() {
        let id = UUID()
        let patientId = UUID()
        let record1 = createStreakRecord(id: id, patientId: patientId)
        let record2 = createStreakRecord(id: id, patientId: patientId)

        XCTAssertEqual(record1, record2)
    }

    func testStreakRecord_Hashable() {
        let record = createStreakRecord()
        var set: Set<StreakRecord> = []
        set.insert(record)

        XCTAssertEqual(set.count, 1)
        XCTAssertTrue(set.contains(record))
    }

    // MARK: - Edge Cases

    func testStreakRecord_VeryLongStreak() {
        let record = createStreakRecord(currentStreak: 500, longestStreak: 500)

        XCTAssertEqual(record.currentStreak, 500)
        XCTAssertEqual(record.badgeLevel, .legend)
        XCTAssertEqual(record.motivationalMessage, "Legendary consistency!")
    }

    func testStreakRecord_ZeroCurrentWithLongHistory() {
        // User broke streak but had a long one before
        let record = createStreakRecord(currentStreak: 0, longestStreak: 100)

        XCTAssertEqual(record.currentStreak, 0)
        XCTAssertEqual(record.longestStreak, 100)
        XCTAssertEqual(record.badgeLevel, .legend)
        XCTAssertEqual(record.motivationalMessage, "Start your streak today!")
    }
}

// MARK: - StreakHistory Tests

final class StreakHistoryModelTests: XCTestCase {

    private func createStreakHistory(
        workoutCompleted: Bool = false,
        armCareCompleted: Bool = false,
        activityDate: String = "2024-01-15",
        sessionId: UUID? = nil,
        manualSessionId: UUID? = nil,
        notes: String? = nil
    ) -> StreakHistory {
        let sessionIdJson = sessionId != nil ? "\"\(sessionId!.uuidString)\"" : "null"
        let manualSessionIdJson = manualSessionId != nil ? "\"\(manualSessionId!.uuidString)\"" : "null"
        let notesJson = notes != nil ? "\"\(notes!)\"" : "null"

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "activity_date": "\(activityDate)",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "session_id": \(sessionIdJson),
            "manual_session_id": \(manualSessionIdJson),
            "notes": \(notesJson),
            "created_at": 1705320000
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakHistory.self, from: json)
    }

    // MARK: - hasAnyActivity Tests

    func testHasAnyActivity_WorkoutOnly() {
        let history = createStreakHistory(workoutCompleted: true, armCareCompleted: false)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_ArmCareOnly() {
        let history = createStreakHistory(workoutCompleted: false, armCareCompleted: true)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_BothActivities() {
        let history = createStreakHistory(workoutCompleted: true, armCareCompleted: true)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_NoActivities() {
        let history = createStreakHistory(workoutCompleted: false, armCareCompleted: false)
        XCTAssertFalse(history.hasAnyActivity)
    }

    // MARK: - Multiple Activities Same Day Tests

    func testStreakHistory_CanHaveBothWorkoutAndArmCare() {
        let history = createStreakHistory(
            workoutCompleted: true,
            armCareCompleted: true
        )

        XCTAssertTrue(history.workoutCompleted)
        XCTAssertTrue(history.armCareCompleted)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testStreakHistory_SessionAndManualSession() {
        let sessionId = UUID()
        let manualSessionId = UUID()
        let history = createStreakHistory(
            workoutCompleted: true,
            sessionId: sessionId,
            manualSessionId: manualSessionId
        )

        XCTAssertEqual(history.sessionId, sessionId)
        XCTAssertEqual(history.manualSessionId, manualSessionId)
    }

    // MARK: - Date Parsing Tests

    func testStreakHistory_ParsesDateFormat() {
        let history = createStreakHistory(activityDate: "2024-06-15")

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: history.activityDate)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    // MARK: - Notes Tests

    func testStreakHistory_WithNotes() {
        let history = createStreakHistory(notes: "Great workout today!")
        XCTAssertEqual(history.notes, "Great workout today!")
    }

    func testStreakHistory_WithNullNotes() {
        let history = createStreakHistory(notes: nil)
        XCTAssertNil(history.notes)
    }

    // MARK: - Identifiable Tests

    func testStreakHistory_Identifiable() {
        let history = createStreakHistory()
        XCTAssertNotNil(history.id)
    }
}

// MARK: - StreakType Tests

final class StreakTypeModelTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testStreakType_WorkoutRawValue() {
        XCTAssertEqual(StreakType.workout.rawValue, "workout")
    }

    func testStreakType_ArmCareRawValue() {
        XCTAssertEqual(StreakType.armCare.rawValue, "arm_care")
    }

    func testStreakType_CombinedRawValue() {
        XCTAssertEqual(StreakType.combined.rawValue, "combined")
    }

    // MARK: - Init From Raw Value Tests

    func testStreakType_InitFromWorkout() {
        XCTAssertEqual(StreakType(rawValue: "workout"), .workout)
    }

    func testStreakType_InitFromArmCare() {
        XCTAssertEqual(StreakType(rawValue: "arm_care"), .armCare)
    }

    func testStreakType_InitFromCombined() {
        XCTAssertEqual(StreakType(rawValue: "combined"), .combined)
    }

    func testStreakType_InitFromInvalid() {
        XCTAssertNil(StreakType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testStreakType_WorkoutDisplayName() {
        XCTAssertEqual(StreakType.workout.displayName, "Workout")
    }

    func testStreakType_ArmCareDisplayName() {
        XCTAssertEqual(StreakType.armCare.displayName, "Arm Care")
    }

    func testStreakType_CombinedDisplayName() {
        XCTAssertEqual(StreakType.combined.displayName, "Training")
    }

    // MARK: - Icon Name Tests

    func testStreakType_WorkoutIcon() {
        XCTAssertEqual(StreakType.workout.iconName, "figure.strengthtraining.traditional")
    }

    func testStreakType_ArmCareIcon() {
        XCTAssertEqual(StreakType.armCare.iconName, "arm.flexed.fill")
    }

    func testStreakType_CombinedIcon() {
        XCTAssertEqual(StreakType.combined.iconName, "flame.fill")
    }

    // MARK: - Color Tests

    func testStreakType_WorkoutColor() {
        XCTAssertEqual(StreakType.workout.color, .blue)
    }

    func testStreakType_ArmCareColor() {
        XCTAssertEqual(StreakType.armCare.color, .orange)
    }

    func testStreakType_CombinedColor() {
        XCTAssertEqual(StreakType.combined.color, .red)
    }

    // MARK: - Identifiable Tests

    func testStreakType_IdMatchesRawValue() {
        XCTAssertEqual(StreakType.workout.id, "workout")
        XCTAssertEqual(StreakType.armCare.id, "arm_care")
        XCTAssertEqual(StreakType.combined.id, "combined")
    }

    // MARK: - CaseIterable Tests

    func testStreakType_AllCases() {
        let allCases = StreakType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.workout))
        XCTAssertTrue(allCases.contains(.armCare))
        XCTAssertTrue(allCases.contains(.combined))
    }

    // MARK: - Independent Tracking Tests

    func testStreakType_TypesAreDistinct() {
        // Ensure each type is unique and can be tracked independently
        XCTAssertNotEqual(StreakType.workout, StreakType.armCare)
        XCTAssertNotEqual(StreakType.workout, StreakType.combined)
        XCTAssertNotEqual(StreakType.armCare, StreakType.combined)
    }
}

// MARK: - StreakBadge Extended Tests

final class StreakBadgeExtendedTests: XCTestCase {

    // MARK: - Badge Classification Boundary Tests

    func testBadge_BoundaryAt7Days() {
        XCTAssertEqual(StreakBadge.badge(for: 6), .starter)
        XCTAssertEqual(StreakBadge.badge(for: 7), .committed)
    }

    func testBadge_BoundaryAt14Days() {
        XCTAssertEqual(StreakBadge.badge(for: 13), .committed)
        XCTAssertEqual(StreakBadge.badge(for: 14), .dedicated)
    }

    func testBadge_BoundaryAt30Days() {
        XCTAssertEqual(StreakBadge.badge(for: 29), .dedicated)
        XCTAssertEqual(StreakBadge.badge(for: 30), .champion)
    }

    func testBadge_BoundaryAt60Days() {
        XCTAssertEqual(StreakBadge.badge(for: 59), .champion)
        XCTAssertEqual(StreakBadge.badge(for: 60), .elite)
    }

    func testBadge_BoundaryAt90Days() {
        XCTAssertEqual(StreakBadge.badge(for: 89), .elite)
        XCTAssertEqual(StreakBadge.badge(for: 90), .legend)
    }

    // MARK: - Very Long Streak Tests (100+ days)

    func testBadge_100PlusDays() {
        XCTAssertEqual(StreakBadge.badge(for: 100), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 150), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 365), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 1000), .legend)
    }

    // MARK: - Next Badge Progression Tests

    func testNextBadge_ProgressionChain() {
        var badge: StreakBadge = .starter
        let expectedProgression: [StreakBadge] = [.committed, .dedicated, .champion, .elite, .legend]

        for expected in expectedProgression {
            let next = badge.nextBadge
            XCTAssertEqual(next, expected)
            badge = next!
        }

        // Legend has no next
        XCTAssertNil(StreakBadge.legend.nextBadge)
    }

    // MARK: - Display Property Completeness

    func testBadge_AllCasesHaveDisplayName() {
        for badge in StreakBadge.allCases {
            XCTAssertFalse(badge.displayName.isEmpty, "\(badge) should have display name")
        }
    }

    func testBadge_AllCasesHaveIcon() {
        for badge in StreakBadge.allCases {
            XCTAssertFalse(badge.iconName.isEmpty, "\(badge) should have icon")
        }
    }

    func testBadge_AllCasesHaveDescription() {
        for badge in StreakBadge.allCases {
            XCTAssertFalse(badge.description.isEmpty, "\(badge) should have description")
        }
    }
}

// MARK: - StreakStatistics Tests

final class StreakStatisticsModelTests: XCTestCase {

    private func createStreakStatistics(
        streakType: String = "combined",
        currentStreak: Int = 10,
        longestStreak: Int = 15,
        lastActivityDate: String? = "2024-01-15",
        streakStartDate: String? = "2024-01-05",
        totalActivityDays: Int = 50,
        thisWeekDays: Int = 5,
        thisMonthDays: Int = 20
    ) -> StreakStatistics {
        let lastActivityJson = lastActivityDate != nil ? "\"\(lastActivityDate!)\"" : "null"
        let startDateJson = streakStartDate != nil ? "\"\(streakStartDate!)\"" : "null"

        let json = """
        {
            "streak_type": "\(streakType)",
            "current_streak": \(currentStreak),
            "longest_streak": \(longestStreak),
            "last_activity_date": \(lastActivityJson),
            "streak_start_date": \(startDateJson),
            "total_activity_days": \(totalActivityDays),
            "this_week_days": \(thisWeekDays),
            "this_month_days": \(thisMonthDays)
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(StreakStatistics.self, from: json)
    }

    // MARK: - Type Parsing Tests

    func testType_ParsesWorkout() {
        let stats = createStreakStatistics(streakType: "workout")
        XCTAssertEqual(stats.type, .workout)
    }

    func testType_ParsesArmCare() {
        let stats = createStreakStatistics(streakType: "arm_care")
        XCTAssertEqual(stats.type, .armCare)
    }

    func testType_ParsesCombined() {
        let stats = createStreakStatistics(streakType: "combined")
        XCTAssertEqual(stats.type, .combined)
    }

    func testType_InvalidDefaultsToCombined() {
        let stats = createStreakStatistics(streakType: "unknown")
        XCTAssertEqual(stats.type, .combined)
    }

    // MARK: - Statistics Values Tests

    func testStatistics_StoresValues() {
        let stats = createStreakStatistics(
            currentStreak: 25,
            longestStreak: 50,
            totalActivityDays: 200,
            thisWeekDays: 6,
            thisMonthDays: 28
        )

        XCTAssertEqual(stats.currentStreak, 25)
        XCTAssertEqual(stats.longestStreak, 50)
        XCTAssertEqual(stats.totalActivityDays, 200)
        XCTAssertEqual(stats.thisWeekDays, 6)
        XCTAssertEqual(stats.thisMonthDays, 28)
    }

    // MARK: - Date Handling Tests

    func testStatistics_HandlesDates() {
        let stats = createStreakStatistics(
            lastActivityDate: "2024-06-15",
            streakStartDate: "2024-06-01"
        )

        XCTAssertNotNil(stats.lastActivityDate)
        XCTAssertNotNil(stats.streakStartDate)
    }

    func testStatistics_HandlesNullDates() {
        let stats = createStreakStatistics(
            lastActivityDate: nil,
            streakStartDate: nil
        )

        XCTAssertNil(stats.lastActivityDate)
        XCTAssertNil(stats.streakStartDate)
    }
}

// MARK: - CalendarHistoryEntry Tests

final class CalendarHistoryEntryModelTests: XCTestCase {

    private func createCalendarHistoryEntry(
        activityDate: String = "2024-01-15",
        workoutCompleted: Bool = true,
        armCareCompleted: Bool = false,
        hasAnyActivity: Bool = true,
        sessionId: UUID? = nil,
        notes: String? = nil
    ) -> CalendarHistoryEntry {
        let sessionIdJson = sessionId != nil ? "\"\(sessionId!.uuidString)\"" : "null"
        let notesJson = notes != nil ? "\"\(notes!)\"" : "null"

        let json = """
        {
            "activity_date": "\(activityDate)",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "has_any_activity": \(hasAnyActivity),
            "session_id": \(sessionIdJson),
            "manual_session_id": null,
            "notes": \(notesJson)
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(CalendarHistoryEntry.self, from: json)
    }

    // MARK: - Identifiable Tests

    func testCalendarHistoryEntry_IdIsActivityDate() {
        let entry = createCalendarHistoryEntry(activityDate: "2024-01-15")
        XCTAssertEqual(entry.id, entry.activityDate)
    }

    // MARK: - Activity Flags Tests

    func testCalendarHistoryEntry_ActivityFlags() {
        let entry = createCalendarHistoryEntry(
            workoutCompleted: true,
            armCareCompleted: true,
            hasAnyActivity: true
        )

        XCTAssertTrue(entry.workoutCompleted)
        XCTAssertTrue(entry.armCareCompleted)
        XCTAssertTrue(entry.hasAnyActivity)
    }

    func testCalendarHistoryEntry_NoActivity() {
        let entry = createCalendarHistoryEntry(
            workoutCompleted: false,
            armCareCompleted: false,
            hasAnyActivity: false
        )

        XCTAssertFalse(entry.workoutCompleted)
        XCTAssertFalse(entry.armCareCompleted)
        XCTAssertFalse(entry.hasAnyActivity)
    }
}

// MARK: - StreakActivityInput Tests

final class StreakActivityInputTests: XCTestCase {

    func testStreakActivityInput_EncodesCorrectly() throws {
        let input = StreakActivityInput(
            patientId: "test-patient-id",
            activityDate: "2024-01-15",
            workoutCompleted: true,
            armCareCompleted: false,
            sessionId: "session-id",
            manualSessionId: nil,
            notes: "Test notes"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["p_patient_id"] as? String, "test-patient-id")
        XCTAssertEqual(json["p_activity_date"] as? String, "2024-01-15")
        XCTAssertEqual(json["p_workout_completed"] as? Bool, true)
        XCTAssertEqual(json["p_arm_care_completed"] as? Bool, false)
        XCTAssertEqual(json["p_session_id"] as? String, "session-id")
        XCTAssertEqual(json["p_notes"] as? String, "Test notes")
    }
}
