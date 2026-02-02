//
//  WeeklySummaryTests.swift
//  PTPerformanceTests
//
//  Unit tests for WeeklySummary model
//  Tests computed properties, Codable encoding/decoding, and performance categories
//

import XCTest
@testable import PTPerformance

final class WeeklySummaryTests: XCTestCase {

    // MARK: - Helper Methods

    func makeWeeklySummary(
        workoutsCompleted: Int = 5,
        workoutsScheduled: Int = 5,
        adherencePercentage: Double = 100,
        totalVolume: Double = 45000,
        volumeChangePercent: Double = 8.5,
        streakMaintained: Bool = true,
        currentStreak: Int = 12,
        topExercise: String? = "Barbell Squat",
        improvementArea: String? = nil
    ) -> WeeklySummary {
        WeeklySummary(
            id: UUID(),
            weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            weekEndDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            workoutsCompleted: workoutsCompleted,
            workoutsScheduled: workoutsScheduled,
            adherencePercentage: adherencePercentage,
            totalVolume: totalVolume,
            volumeChangePercent: volumeChangePercent,
            streakMaintained: streakMaintained,
            currentStreak: currentStreak,
            topExercise: topExercise,
            improvementArea: improvementArea
        )
    }

    // MARK: - Wins Computed Property Tests

    func testWinsPerfectWeek() {
        let summary = makeWeeklySummary(
            workoutsCompleted: 5,
            workoutsScheduled: 5,
            adherencePercentage: 100
        )

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Perfect week") })
    }

    func testWinsStrongAdherence() {
        let summary = makeWeeklySummary(
            workoutsCompleted: 4,
            workoutsScheduled: 5,
            adherencePercentage: 85
        )

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Strong adherence") })
    }

    func testWinsPartialCompletion() {
        let summary = makeWeeklySummary(
            workoutsCompleted: 2,
            workoutsScheduled: 5,
            adherencePercentage: 40
        )

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Completed 2/5") })
    }

    func testWinsLongStreak() {
        let summary = makeWeeklySummary(currentStreak: 14)

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("14-day workout streak") })
    }

    func testWinsShortStreak() {
        let summary = makeWeeklySummary(
            streakMaintained: true,
            currentStreak: 5
        )

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("5-day streak") })
    }

    func testWinsVolumeIncrease() {
        let summary = makeWeeklySummary(volumeChangePercent: 15)

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Training volume up 15%") })
    }

    func testWinsModerateVolumeIncrease() {
        let summary = makeWeeklySummary(volumeChangePercent: 7)

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Volume increased 7%") })
    }

    func testWinsTopExercise() {
        let summary = makeWeeklySummary(topExercise: "Bench Press")

        let wins = summary.wins
        XCTAssertTrue(wins.contains { $0.contains("Top exercise: Bench Press") })
    }

    // MARK: - Improvement Areas Computed Property Tests

    func testImprovementAreasLowAdherence() {
        let summary = makeWeeklySummary(adherencePercentage: 40)

        let areas = summary.improvementAreas
        XCTAssertTrue(areas.contains { $0.contains("Focus on completing scheduled workouts") })
    }

    func testImprovementAreasVolumeDecline() {
        let summary = makeWeeklySummary(volumeChangePercent: -15)

        let areas = summary.improvementAreas
        XCTAssertTrue(areas.contains { $0.contains("Training volume decreased") })
    }

    func testImprovementAreasStreakBroken() {
        let summary = makeWeeklySummary(
            streakMaintained: false,
            currentStreak: 0
        )

        let areas = summary.improvementAreas
        XCTAssertTrue(areas.contains { $0.contains("Restart your workout streak") })
    }

    func testImprovementAreasExplicitArea() {
        let summary = makeWeeklySummary(
            adherencePercentage: 90,
            improvementArea: "Upper body strength"
        )

        let areas = summary.improvementAreas
        XCTAssertTrue(areas.contains { $0.contains("Upper body strength") })
    }

    func testImprovementAreasDefaultEncouragement() {
        let summary = makeWeeklySummary(
            adherencePercentage: 90,
            volumeChangePercent: 5,
            streakMaintained: true,
            currentStreak: 5,
            improvementArea: nil
        )

        let areas = summary.improvementAreas
        XCTAssertTrue(areas.contains { $0.contains("Keep up the momentum") })
    }

    // MARK: - Performance Category Tests

    func testPerformanceCategoryExcellent() {
        let summary = makeWeeklySummary(
            adherencePercentage: 100,
            volumeChangePercent: 10,
            streakMaintained: true,
            currentStreak: 15
        )

        XCTAssertEqual(summary.performanceCategory, .excellent)
    }

    func testPerformanceCategoryGood() {
        let summary = makeWeeklySummary(
            adherencePercentage: 80,
            volumeChangePercent: 5,
            streakMaintained: true,
            currentStreak: 7
        )

        XCTAssertEqual(summary.performanceCategory, .good)
    }

    func testPerformanceCategoryAverage() {
        let summary = makeWeeklySummary(
            adherencePercentage: 60,
            volumeChangePercent: -2,
            streakMaintained: false,
            currentStreak: 3
        )

        XCTAssertEqual(summary.performanceCategory, .average)
    }

    func testPerformanceCategoryNeedsWork() {
        let summary = makeWeeklySummary(
            adherencePercentage: 30,
            volumeChangePercent: -10,
            streakMaintained: false,
            currentStreak: 0
        )

        XCTAssertEqual(summary.performanceCategory, .needsWork)
    }

    // MARK: - Formatted Volume Tests

    func testFormattedVolumeSmall() {
        let summary = makeWeeklySummary(totalVolume: 500)
        XCTAssertEqual(summary.formattedVolume, "500 lbs")
    }

    func testFormattedVolumeThousands() {
        let summary = makeWeeklySummary(totalVolume: 45000)
        XCTAssertEqual(summary.formattedVolume, "45.0K lbs")
    }

    func testFormattedVolumeMillions() {
        let summary = makeWeeklySummary(totalVolume: 1500000)
        XCTAssertEqual(summary.formattedVolume, "1.5M lbs")
    }

    // MARK: - Volume Change Emoji Tests

    func testVolumeChangeEmojiUp() {
        let summary = makeWeeklySummary(volumeChangePercent: 10)
        XCTAssertEqual(summary.volumeChangeEmoji, "chart.line.uptrend.xyaxis")
    }

    func testVolumeChangeEmojiDown() {
        let summary = makeWeeklySummary(volumeChangePercent: -10)
        XCTAssertEqual(summary.volumeChangeEmoji, "chart.line.downtrend.xyaxis")
    }

    func testVolumeChangeEmojiFlat() {
        let summary = makeWeeklySummary(volumeChangePercent: 2)
        XCTAssertEqual(summary.volumeChangeEmoji, "chart.line.flattrend.xyaxis")
    }

    // MARK: - Date Range String Tests

    func testDateRangeString() {
        let summary = makeWeeklySummary()
        let dateRange = summary.dateRangeString

        // Should contain month abbreviation and day numbers
        XCTAssertTrue(dateRange.contains(" - "))
        XCTAssertFalse(dateRange.isEmpty)
    }

    // MARK: - Codable Tests

    func testWeeklySummaryCodable() throws {
        let original = makeWeeklySummary()

        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeeklySummary.self, from: data)

        // Verify key properties
        XCTAssertEqual(decoded.workoutsCompleted, original.workoutsCompleted)
        XCTAssertEqual(decoded.workoutsScheduled, original.workoutsScheduled)
        XCTAssertEqual(decoded.adherencePercentage, original.adherencePercentage)
        XCTAssertEqual(decoded.totalVolume, original.totalVolume)
        XCTAssertEqual(decoded.currentStreak, original.currentStreak)
    }

    func testWeeklySummaryDecodingFromStringDates() throws {
        let json = """
        {
            "week_start_date": "2024-01-01",
            "week_end_date": "2024-01-07",
            "workouts_completed": 5,
            "workouts_scheduled": 5,
            "adherence_percentage": "100.0",
            "total_volume": "45000.5",
            "volume_change_pct": "8.5",
            "streak_maintained": true,
            "current_streak": 12,
            "top_exercise": "Squat",
            "improvement_area": null
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(WeeklySummary.self, from: data)

        XCTAssertEqual(summary.workoutsCompleted, 5)
        XCTAssertEqual(summary.workoutsScheduled, 5)
        XCTAssertEqual(summary.adherencePercentage, 100.0)
        XCTAssertEqual(summary.totalVolume, 45000.5)
        XCTAssertEqual(summary.volumeChangePercent, 8.5)
        XCTAssertEqual(summary.currentStreak, 12)
        XCTAssertEqual(summary.topExercise, "Squat")
    }

    func testWeeklySummaryDecodingFromNumericValues() throws {
        let json = """
        {
            "week_start_date": "2024-01-01",
            "week_end_date": "2024-01-07",
            "workouts_completed": 3,
            "workouts_scheduled": 5,
            "adherence_percentage": 60.0,
            "total_volume": 30000,
            "volume_change_pct": -5.5,
            "streak_maintained": false,
            "current_streak": 0
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(WeeklySummary.self, from: data)

        XCTAssertEqual(summary.workoutsCompleted, 3)
        XCTAssertEqual(summary.adherencePercentage, 60.0)
        XCTAssertEqual(summary.volumeChangePercent, -5.5)
        XCTAssertFalse(summary.streakMaintained)
    }

    // MARK: - PerformanceCategory Tests

    func testPerformanceCategoryDisplayNames() {
        XCTAssertEqual(PerformanceCategory.excellent.displayName, "Excellent Week")
        XCTAssertEqual(PerformanceCategory.good.displayName, "Good Week")
        XCTAssertEqual(PerformanceCategory.average.displayName, "Solid Week")
        XCTAssertEqual(PerformanceCategory.needsWork.displayName, "Room to Grow")
    }

    func testPerformanceCategoryEmoji() {
        XCTAssertEqual(PerformanceCategory.excellent.emoji, "star.fill")
        XCTAssertEqual(PerformanceCategory.good.emoji, "hand.thumbsup.fill")
        XCTAssertEqual(PerformanceCategory.average.emoji, "checkmark.circle.fill")
        XCTAssertEqual(PerformanceCategory.needsWork.emoji, "arrow.up.circle.fill")
    }

    // MARK: - Sample Data Tests

    func testSampleWeeklySummary() {
        let sample = WeeklySummary.sample

        XCTAssertEqual(sample.workoutsCompleted, 5)
        XCTAssertEqual(sample.workoutsScheduled, 5)
        XCTAssertEqual(sample.adherencePercentage, 100)
        XCTAssertEqual(sample.currentStreak, 12)
        XCTAssertNotNil(sample.topExercise)
    }

    func testSampleNeedsWork() {
        let sample = WeeklySummary.sampleNeedsWork

        XCTAssertEqual(sample.workoutsCompleted, 2)
        XCTAssertEqual(sample.workoutsScheduled, 5)
        XCTAssertEqual(sample.adherencePercentage, 40)
        XCTAssertEqual(sample.currentStreak, 0)
        XCTAssertFalse(sample.streakMaintained)
    }
}
