//
//  StreakTrackingServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for StreakTrackingService
//  Tests badge calculations, streak formatting, display helpers,
//  and streak record computed properties
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - StreakBadge Tests

final class StreakBadgeTests: XCTestCase {

    // MARK: - Badge Classification Tests

    func testBadge_Starter_0To6Days() {
        XCTAssertEqual(StreakBadge.badge(for: 0), .starter)
        XCTAssertEqual(StreakBadge.badge(for: 3), .starter)
        XCTAssertEqual(StreakBadge.badge(for: 6), .starter)
    }

    func testBadge_Committed_7To13Days() {
        XCTAssertEqual(StreakBadge.badge(for: 7), .committed)
        XCTAssertEqual(StreakBadge.badge(for: 10), .committed)
        XCTAssertEqual(StreakBadge.badge(for: 13), .committed)
    }

    func testBadge_Dedicated_14To29Days() {
        XCTAssertEqual(StreakBadge.badge(for: 14), .dedicated)
        XCTAssertEqual(StreakBadge.badge(for: 20), .dedicated)
        XCTAssertEqual(StreakBadge.badge(for: 29), .dedicated)
    }

    func testBadge_Champion_30To59Days() {
        XCTAssertEqual(StreakBadge.badge(for: 30), .champion)
        XCTAssertEqual(StreakBadge.badge(for: 45), .champion)
        XCTAssertEqual(StreakBadge.badge(for: 59), .champion)
    }

    func testBadge_Elite_60To89Days() {
        XCTAssertEqual(StreakBadge.badge(for: 60), .elite)
        XCTAssertEqual(StreakBadge.badge(for: 75), .elite)
        XCTAssertEqual(StreakBadge.badge(for: 89), .elite)
    }

    func testBadge_Legend_90PlusDays() {
        XCTAssertEqual(StreakBadge.badge(for: 90), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 100), .legend)
        XCTAssertEqual(StreakBadge.badge(for: 365), .legend)
    }

    // MARK: - Raw Value Tests

    func testBadge_RawValues() {
        XCTAssertEqual(StreakBadge.starter.rawValue, 0)
        XCTAssertEqual(StreakBadge.committed.rawValue, 7)
        XCTAssertEqual(StreakBadge.dedicated.rawValue, 14)
        XCTAssertEqual(StreakBadge.champion.rawValue, 30)
        XCTAssertEqual(StreakBadge.elite.rawValue, 60)
        XCTAssertEqual(StreakBadge.legend.rawValue, 90)
    }

    func testBadge_MinDays() {
        XCTAssertEqual(StreakBadge.starter.minDays, 0)
        XCTAssertEqual(StreakBadge.committed.minDays, 7)
        XCTAssertEqual(StreakBadge.dedicated.minDays, 14)
        XCTAssertEqual(StreakBadge.champion.minDays, 30)
        XCTAssertEqual(StreakBadge.elite.minDays, 60)
        XCTAssertEqual(StreakBadge.legend.minDays, 90)
    }

    // MARK: - Display Properties Tests

    func testBadge_DisplayNames() {
        XCTAssertEqual(StreakBadge.starter.displayName, "Starter")
        XCTAssertEqual(StreakBadge.committed.displayName, "Committed")
        XCTAssertEqual(StreakBadge.dedicated.displayName, "Dedicated")
        XCTAssertEqual(StreakBadge.champion.displayName, "Champion")
        XCTAssertEqual(StreakBadge.elite.displayName, "Elite")
        XCTAssertEqual(StreakBadge.legend.displayName, "Legend")
    }

    func testBadge_IconNames() {
        XCTAssertEqual(StreakBadge.starter.iconName, "flame")
        XCTAssertEqual(StreakBadge.committed.iconName, "flame.fill")
        XCTAssertEqual(StreakBadge.dedicated.iconName, "star.fill")
        XCTAssertEqual(StreakBadge.champion.iconName, "crown.fill")
        XCTAssertEqual(StreakBadge.elite.iconName, "trophy.fill")
        XCTAssertEqual(StreakBadge.legend.iconName, "medal.fill")
    }

    func testBadge_Colors() {
        XCTAssertEqual(StreakBadge.starter.color, .gray)
        XCTAssertEqual(StreakBadge.committed.color, .blue)
        XCTAssertEqual(StreakBadge.dedicated.color, .green)
        XCTAssertEqual(StreakBadge.champion.color, .orange)
        XCTAssertEqual(StreakBadge.elite.color, .purple)
        XCTAssertEqual(StreakBadge.legend.color, .yellow)
    }

    func testBadge_Descriptions() {
        XCTAssertEqual(StreakBadge.starter.description, "Just getting started")
        XCTAssertEqual(StreakBadge.committed.description, "One week strong!")
        XCTAssertEqual(StreakBadge.dedicated.description, "Two weeks of dedication")
        XCTAssertEqual(StreakBadge.champion.description, "A full month!")
        XCTAssertEqual(StreakBadge.elite.description, "Two months of consistency")
        XCTAssertEqual(StreakBadge.legend.description, "Three months of excellence")
    }

    // MARK: - Next Badge Tests

    func testBadge_NextBadge() {
        XCTAssertEqual(StreakBadge.starter.nextBadge, .committed)
        XCTAssertEqual(StreakBadge.committed.nextBadge, .dedicated)
        XCTAssertEqual(StreakBadge.dedicated.nextBadge, .champion)
        XCTAssertEqual(StreakBadge.champion.nextBadge, .elite)
        XCTAssertEqual(StreakBadge.elite.nextBadge, .legend)
        XCTAssertNil(StreakBadge.legend.nextBadge)
    }

    func testBadge_AllCases() {
        let allCases = StreakBadge.allCases
        XCTAssertEqual(allCases.count, 6)
    }
}

// MARK: - StreakType Tests

final class StreakTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testStreakType_RawValues() {
        XCTAssertEqual(StreakType.workout.rawValue, "workout")
        XCTAssertEqual(StreakType.armCare.rawValue, "arm_care")
        XCTAssertEqual(StreakType.combined.rawValue, "combined")
    }

    func testStreakType_InitFromRawValue() {
        XCTAssertEqual(StreakType(rawValue: "workout"), .workout)
        XCTAssertEqual(StreakType(rawValue: "arm_care"), .armCare)
        XCTAssertEqual(StreakType(rawValue: "combined"), .combined)
        XCTAssertNil(StreakType(rawValue: "invalid"))
    }

    // MARK: - Display Properties Tests

    func testStreakType_DisplayNames() {
        XCTAssertEqual(StreakType.workout.displayName, "Workout")
        XCTAssertEqual(StreakType.armCare.displayName, "Arm Care")
        XCTAssertEqual(StreakType.combined.displayName, "Training")
    }

    func testStreakType_IconNames() {
        XCTAssertEqual(StreakType.workout.iconName, "figure.strengthtraining.traditional")
        XCTAssertEqual(StreakType.armCare.iconName, "arm.flexed.fill")
        XCTAssertEqual(StreakType.combined.iconName, "flame.fill")
    }

    func testStreakType_Colors() {
        XCTAssertEqual(StreakType.workout.color, .blue)
        XCTAssertEqual(StreakType.armCare.color, .orange)
        XCTAssertEqual(StreakType.combined.color, .red)
    }

    func testStreakType_Identifiable() {
        XCTAssertEqual(StreakType.workout.id, "workout")
        XCTAssertEqual(StreakType.armCare.id, "arm_care")
        XCTAssertEqual(StreakType.combined.id, "combined")
    }

    func testStreakType_AllCases() {
        let allCases = StreakType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.workout))
        XCTAssertTrue(allCases.contains(.armCare))
        XCTAssertTrue(allCases.contains(.combined))
    }
}

// MARK: - StreakRecord Computed Properties Tests

final class StreakRecordComputedPropertiesTests: XCTestCase {

    // MARK: - Motivational Message Tests

    func testMotivationalMessage_ZeroStreak() {
        let record = createStreakRecord(currentStreak: 0)
        XCTAssertEqual(record.motivationalMessage, "Start your streak today!")
    }

    func testMotivationalMessage_OneDay() {
        let record = createStreakRecord(currentStreak: 1)
        XCTAssertEqual(record.motivationalMessage, "Great start! Keep going!")
    }

    func testMotivationalMessage_TwoToSixDays() {
        let record2 = createStreakRecord(currentStreak: 2)
        XCTAssertEqual(record2.motivationalMessage, "Building momentum!")

        let record6 = createStreakRecord(currentStreak: 6)
        XCTAssertEqual(record6.motivationalMessage, "Building momentum!")
    }

    func testMotivationalMessage_OneWeek() {
        let record7 = createStreakRecord(currentStreak: 7)
        XCTAssertEqual(record7.motivationalMessage, "One week strong!")

        let record13 = createStreakRecord(currentStreak: 13)
        XCTAssertEqual(record13.motivationalMessage, "One week strong!")
    }

    func testMotivationalMessage_TwoWeeks() {
        let record14 = createStreakRecord(currentStreak: 14)
        XCTAssertEqual(record14.motivationalMessage, "Two weeks! Amazing!")

        let record29 = createStreakRecord(currentStreak: 29)
        XCTAssertEqual(record29.motivationalMessage, "Two weeks! Amazing!")
    }

    func testMotivationalMessage_OneMonth() {
        let record30 = createStreakRecord(currentStreak: 30)
        XCTAssertEqual(record30.motivationalMessage, "One month! Incredible!")

        let record59 = createStreakRecord(currentStreak: 59)
        XCTAssertEqual(record59.motivationalMessage, "One month! Incredible!")
    }

    func testMotivationalMessage_TwoMonths() {
        let record60 = createStreakRecord(currentStreak: 60)
        XCTAssertEqual(record60.motivationalMessage, "Two months! Unstoppable!")

        let record89 = createStreakRecord(currentStreak: 89)
        XCTAssertEqual(record89.motivationalMessage, "Two months! Unstoppable!")
    }

    func testMotivationalMessage_Legendary() {
        let record90 = createStreakRecord(currentStreak: 90)
        XCTAssertEqual(record90.motivationalMessage, "Legendary consistency!")

        let record365 = createStreakRecord(currentStreak: 365)
        XCTAssertEqual(record365.motivationalMessage, "Legendary consistency!")
    }

    // MARK: - Badge Level Tests

    func testBadgeLevel_BasedOnLongestStreak() {
        let starterRecord = createStreakRecord(currentStreak: 5, longestStreak: 5)
        XCTAssertEqual(starterRecord.badgeLevel, .starter)

        let committedRecord = createStreakRecord(currentStreak: 3, longestStreak: 10)
        XCTAssertEqual(committedRecord.badgeLevel, .committed)

        let legendRecord = createStreakRecord(currentStreak: 50, longestStreak: 100)
        XCTAssertEqual(legendRecord.badgeLevel, .legend)
    }

    // MARK: - Is At Risk Tests

    func testIsAtRisk_NoLastActivityDate() {
        let record = createStreakRecord(lastActivityDate: nil)
        XCTAssertTrue(record.isAtRisk)
    }

    func testIsAtRisk_TodayActivity() {
        let record = createStreakRecord(lastActivityDate: Date())
        XCTAssertFalse(record.isAtRisk)
    }

    func testIsAtRisk_YesterdayActivity() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let record = createStreakRecord(lastActivityDate: yesterday)
        XCTAssertTrue(record.isAtRisk)
    }

    // MARK: - Helper Methods

    private func createStreakRecord(
        currentStreak: Int,
        longestStreak: Int? = nil,
        lastActivityDate: Date? = Date()
    ) -> StreakRecord {
        // Use Encodable to create StreakRecord since it has custom init(from:)
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "streak_type": "combined",
            "current_streak": \(currentStreak),
            "longest_streak": \(longestStreak ?? currentStreak),
            "last_activity_date": \(lastActivityDate != nil ? "\"\(formatDate(lastActivityDate!))\"" : "null"),
            "streak_start_date": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(StreakRecord.self, from: json)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - StreakHistory Tests

final class StreakHistoryTests: XCTestCase {

    func testHasAnyActivity_WorkoutOnly() {
        let history = createStreakHistory(workoutCompleted: true, armCareCompleted: false)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_ArmCareOnly() {
        let history = createStreakHistory(workoutCompleted: false, armCareCompleted: true)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_Both() {
        let history = createStreakHistory(workoutCompleted: true, armCareCompleted: true)
        XCTAssertTrue(history.hasAnyActivity)
    }

    func testHasAnyActivity_None() {
        let history = createStreakHistory(workoutCompleted: false, armCareCompleted: false)
        XCTAssertFalse(history.hasAnyActivity)
    }

    // MARK: - Helper Methods

    private func createStreakHistory(workoutCompleted: Bool, armCareCompleted: Bool) -> StreakHistory {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "activity_date": "2024-01-15",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "session_id": null,
            "manual_session_id": null,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(StreakHistory.self, from: json)
    }
}

// MARK: - StreakStatistics Tests

final class StreakStatisticsTests: XCTestCase {

    func testType_ParsesFromStreakType() {
        let workoutStats = createStreakStatistics(streakType: "workout")
        XCTAssertEqual(workoutStats.type, .workout)

        let armCareStats = createStreakStatistics(streakType: "arm_care")
        XCTAssertEqual(armCareStats.type, .armCare)

        let combinedStats = createStreakStatistics(streakType: "combined")
        XCTAssertEqual(combinedStats.type, .combined)
    }

    func testType_UnknownDefaultsToCombined() {
        let unknownStats = createStreakStatistics(streakType: "unknown")
        XCTAssertEqual(unknownStats.type, .combined)
    }

    // MARK: - Helper Methods

    private func createStreakStatistics(streakType: String) -> StreakStatistics {
        let json = """
        {
            "streak_type": "\(streakType)",
            "current_streak": 10,
            "longest_streak": 15,
            "last_activity_date": "2024-01-15",
            "streak_start_date": "2024-01-05",
            "total_activity_days": 50,
            "this_week_days": 5,
            "this_month_days": 20
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        return try! decoder.decode(StreakStatistics.self, from: json)
    }
}

// MARK: - StreakError Tests

final class StreakErrorTests: XCTestCase {

    func testError_NoPatientFound() {
        let error = StreakError.noPatientFound
        XCTAssertEqual(error.errorDescription, "No patient found for the current user")
        XCTAssertEqual(error.recoverySuggestion, "Please sign out and sign back in to refresh your account.")
    }

    func testError_ActivityRecordFailed() {
        let error = StreakError.activityRecordFailed
        XCTAssertEqual(error.errorDescription, "Failed to record activity")
        XCTAssertTrue(error.recoverySuggestion?.contains("sync automatically") ?? false)
    }

    func testError_FetchFailed() {
        let error = StreakError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch streak data")
        XCTAssertTrue(error.recoverySuggestion?.contains("internet connection") ?? false)
    }
}

// MARK: - StreakTrackingService Display Helpers Tests

final class StreakTrackingServiceDisplayTests: XCTestCase {

    @MainActor
    func testFormatStreakDisplay_ZeroDays() {
        let service = StreakTrackingService()
        XCTAssertEqual(service.formatStreakDisplay(0), "0 days")
    }

    @MainActor
    func testFormatStreakDisplay_OneDay() {
        let service = StreakTrackingService()
        XCTAssertEqual(service.formatStreakDisplay(1), "1 day")
    }

    @MainActor
    func testFormatStreakDisplay_MultipleDays() {
        let service = StreakTrackingService()
        XCTAssertEqual(service.formatStreakDisplay(2), "2 days")
        XCTAssertEqual(service.formatStreakDisplay(7), "7 days")
        XCTAssertEqual(service.formatStreakDisplay(30), "30 days")
        XCTAssertEqual(service.formatStreakDisplay(100), "100 days")
    }
}

// MARK: - CalendarHistoryEntry Tests

final class CalendarHistoryEntryTests: XCTestCase {

    func testCalendarHistoryEntry_Identifiable() {
        let entry = createCalendarHistoryEntry()
        XCTAssertEqual(entry.id, entry.activityDate)
    }

    func testCalendarHistoryEntry_HasAnyActivity() {
        let entryWithActivity = createCalendarHistoryEntry(hasAnyActivity: true)
        XCTAssertTrue(entryWithActivity.hasAnyActivity)

        let entryWithoutActivity = createCalendarHistoryEntry(hasAnyActivity: false)
        XCTAssertFalse(entryWithoutActivity.hasAnyActivity)
    }

    // MARK: - Helper Methods

    private func createCalendarHistoryEntry(
        workoutCompleted: Bool = true,
        armCareCompleted: Bool = true,
        hasAnyActivity: Bool = true
    ) -> CalendarHistoryEntry {
        let json = """
        {
            "activity_date": "2024-01-15",
            "workout_completed": \(workoutCompleted),
            "arm_care_completed": \(armCareCompleted),
            "has_any_activity": \(hasAnyActivity),
            "session_id": null,
            "manual_session_id": null,
            "notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        return try! decoder.decode(CalendarHistoryEntry.self, from: json)
    }
}

// MARK: - WidgetStreak Type Mapping Tests

final class WidgetStreakTypeMappingTests: XCTestCase {

    @MainActor
    func testCreateWidgetStreak_WorkoutType() {
        let service = StreakTrackingService()
        let record = createStreakRecordWithType(.workout)
        let widgetStreak = service.createWidgetStreak(from: record)

        XCTAssertEqual(widgetStreak.streakType, .workout)
        XCTAssertEqual(widgetStreak.currentStreak, record.currentStreak)
        XCTAssertEqual(widgetStreak.longestStreak, record.longestStreak)
    }

    @MainActor
    func testCreateWidgetStreak_ArmCareType() {
        let service = StreakTrackingService()
        let record = createStreakRecordWithType(.armCare)
        let widgetStreak = service.createWidgetStreak(from: record)

        XCTAssertEqual(widgetStreak.streakType, .armCare)
    }

    @MainActor
    func testCreateWidgetStreak_CombinedType() {
        let service = StreakTrackingService()
        let record = createStreakRecordWithType(.combined)
        let widgetStreak = service.createWidgetStreak(from: record)

        XCTAssertEqual(widgetStreak.streakType, .combined)
    }

    // MARK: - Helper Methods

    private func createStreakRecordWithType(_ type: StreakType) -> StreakRecord {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "patient_id": "\(UUID().uuidString)",
            "streak_type": "\(type.rawValue)",
            "current_streak": 15,
            "longest_streak": 20,
            "last_activity_date": "2024-01-15",
            "streak_start_date": "2024-01-01",
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(StreakRecord.self, from: json)
    }
}
