//
//  DailyReadinessTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for DailyReadiness model
//  Tests encoding/decoding, score calculations, readiness_score computation, and date handling
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - DailyReadiness Model Tests

final class DailyReadinessTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDailyReadiness_Initialization() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()
        let createdAt = Date()
        let updatedAt = Date()

        let readiness = DailyReadiness(
            id: id,
            patientId: patientId,
            date: date,
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 4,
            readinessScore: 78.5,
            notes: "Feeling good",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(readiness.id, id)
        XCTAssertEqual(readiness.patientId, patientId)
        XCTAssertEqual(readiness.date, date)
        XCTAssertEqual(readiness.sleepHours, 7.5)
        XCTAssertEqual(readiness.sorenessLevel, 3)
        XCTAssertEqual(readiness.energyLevel, 8)
        XCTAssertEqual(readiness.stressLevel, 4)
        XCTAssertEqual(readiness.readinessScore, 78.5)
        XCTAssertEqual(readiness.notes, "Feeling good")
    }

    func testDailyReadiness_InitializationWithNilOptionals() {
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil,
            readinessScore: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(readiness.sleepHours)
        XCTAssertNil(readiness.sorenessLevel)
        XCTAssertNil(readiness.energyLevel)
        XCTAssertNil(readiness.stressLevel)
        XCTAssertNil(readiness.readinessScore)
        XCTAssertNil(readiness.notes)
    }

    // MARK: - Encoding Tests

    func testDailyReadiness_Encoding() throws {
        let readiness = createTestReadiness(score: 75.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(readiness)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["patient_id"])
        XCTAssertNotNil(json?["sleep_hours"])
        XCTAssertNotNil(json?["soreness_level"])
        XCTAssertNotNil(json?["energy_level"])
        XCTAssertNotNil(json?["stress_level"])
        XCTAssertNotNil(json?["readiness_score"])
    }

    func testDailyReadiness_EncodingWithNils() throws {
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil,
            readinessScore: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(readiness)

        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Decoding Tests

    func testDailyReadiness_DecodingStandardJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 7,
            "stress_level": 4,
            "readiness_score": 78.5,
            "notes": "Good day",
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertEqual(readiness.sleepHours, 7.5)
        XCTAssertEqual(readiness.sorenessLevel, 3)
        XCTAssertEqual(readiness.energyLevel, 7)
        XCTAssertEqual(readiness.stressLevel, 4)
        XCTAssertEqual(readiness.readinessScore, 78.5)
        XCTAssertEqual(readiness.notes, "Good day")
    }

    func testDailyReadiness_DecodingNumericAsString() throws {
        // PostgreSQL NUMERIC type sometimes returns as string
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": "7.5",
            "soreness_level": 3,
            "energy_level": 7,
            "stress_level": 4,
            "readiness_score": "78.5",
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertEqual(readiness.sleepHours, 7.5)
        XCTAssertEqual(readiness.readinessScore, 78.5)
    }

    func testDailyReadiness_DecodingNullOptionals() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": null,
            "soreness_level": null,
            "energy_level": null,
            "stress_level": null,
            "readiness_score": null,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertNil(readiness.sleepHours)
        XCTAssertNil(readiness.sorenessLevel)
        XCTAssertNil(readiness.energyLevel)
        XCTAssertNil(readiness.stressLevel)
        XCTAssertNil(readiness.readinessScore)
        XCTAssertNil(readiness.notes)
    }

    func testDailyReadiness_DecodingISO8601DateFormat() throws {
        // Test with full ISO8601 date format
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15T00:00:00Z",
            "sleep_hours": 8.0,
            "soreness_level": 2,
            "energy_level": 8,
            "stress_level": 3,
            "readiness_score": 85.0,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertNotNil(readiness.date)
    }

    // MARK: - Readiness Band Tests

    func testReadinessBand_GreenForHighScores() {
        let readiness = createTestReadiness(score: 85.0)
        XCTAssertEqual(readiness.readinessBand, .green)

        let readiness80 = createTestReadiness(score: 80.0)
        XCTAssertEqual(readiness80.readinessBand, .green)
    }

    func testReadinessBand_YellowForModerateScores() {
        let readiness = createTestReadiness(score: 70.0)
        XCTAssertEqual(readiness.readinessBand, .yellow)

        let readiness60 = createTestReadiness(score: 60.0)
        XCTAssertEqual(readiness60.readinessBand, .yellow)
    }

    func testReadinessBand_OrangeForLowScores() {
        let readiness = createTestReadiness(score: 50.0)
        XCTAssertEqual(readiness.readinessBand, .orange)

        let readiness40 = createTestReadiness(score: 40.0)
        XCTAssertEqual(readiness40.readinessBand, .orange)
    }

    func testReadinessBand_RedForVeryLowScores() {
        let readiness = createTestReadiness(score: 30.0)
        XCTAssertEqual(readiness.readinessBand, .red)

        let readiness0 = createTestReadiness(score: 0.0)
        XCTAssertEqual(readiness0.readinessBand, .red)
    }

    func testReadinessBand_YellowForNilScore() {
        let readiness = createTestReadiness(score: nil)
        XCTAssertEqual(readiness.readinessBand, .yellow, "Nil score should default to yellow band")
    }

    func testReadinessBand_BoundaryValues() {
        // Exact boundary at 80
        let readiness80 = createTestReadiness(score: 80.0)
        XCTAssertEqual(readiness80.readinessBand, .green)

        // Just below 80
        let readiness79 = createTestReadiness(score: 79.9)
        XCTAssertEqual(readiness79.readinessBand, .yellow)

        // Exact boundary at 60
        let readiness60 = createTestReadiness(score: 60.0)
        XCTAssertEqual(readiness60.readinessBand, .yellow)

        // Just below 60
        let readiness59 = createTestReadiness(score: 59.9)
        XCTAssertEqual(readiness59.readinessBand, .orange)

        // Exact boundary at 40
        let readiness40 = createTestReadiness(score: 40.0)
        XCTAssertEqual(readiness40.readinessBand, .orange)

        // Just below 40
        let readiness39 = createTestReadiness(score: 39.9)
        XCTAssertEqual(readiness39.readinessBand, .red)
    }

    // MARK: - Category Tests

    func testCategory_AllCategories() {
        // Elite (90+)
        let elite = createTestReadiness(score: 95.0)
        XCTAssertEqual(elite.category, .elite)

        // High (75-89)
        let high = createTestReadiness(score: 82.0)
        XCTAssertEqual(high.category, .high)

        // Moderate (60-74)
        let moderate = createTestReadiness(score: 67.0)
        XCTAssertEqual(moderate.category, .moderate)

        // Low (45-59)
        let low = createTestReadiness(score: 52.0)
        XCTAssertEqual(low.category, .low)

        // Poor (<45)
        let poor = createTestReadiness(score: 30.0)
        XCTAssertEqual(poor.category, .poor)
    }

    func testCategory_NilScore() {
        let readiness = createTestReadiness(score: nil)
        XCTAssertNil(readiness.category)
    }

    // MARK: - Score Color Tests

    func testScoreColor_AllCategories() {
        XCTAssertEqual(createTestReadiness(score: 95.0).scoreColor, Color.green)
        XCTAssertEqual(createTestReadiness(score: 82.0).scoreColor, Color.blue)
        XCTAssertEqual(createTestReadiness(score: 67.0).scoreColor, Color.yellow)
        XCTAssertEqual(createTestReadiness(score: 52.0).scoreColor, Color.orange)
        XCTAssertEqual(createTestReadiness(score: 30.0).scoreColor, Color.red)
        XCTAssertEqual(createTestReadiness(score: nil).scoreColor, Color.gray)
    }

    // MARK: - Score Text Tests

    func testScoreText_WithScore() {
        let readiness = createTestReadiness(score: 78.6)
        XCTAssertEqual(readiness.scoreText, "79")
    }

    func testScoreText_WholeNumber() {
        let readiness = createTestReadiness(score: 85.0)
        XCTAssertEqual(readiness.scoreText, "85")
    }

    func testScoreText_NilScore() {
        let readiness = createTestReadiness(score: nil)
        XCTAssertEqual(readiness.scoreText, "--")
    }

    func testScoreText_ZeroScore() {
        let readiness = createTestReadiness(score: 0.0)
        XCTAssertEqual(readiness.scoreText, "0")
    }

    func testScoreText_MaxScore() {
        let readiness = createTestReadiness(score: 100.0)
        XCTAssertEqual(readiness.scoreText, "100")
    }

    // MARK: - Formatted Date Tests

    func testFormattedDate_NotEmpty() {
        let readiness = createTestReadiness(score: 75.0)
        XCTAssertFalse(readiness.formattedDate.isEmpty)
    }

    func testFormattedDate_ContainsMonthAndDay() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        let date = calendar.date(from: components)!

        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: date,
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // The formatted date should contain the day (15)
        XCTAssertTrue(readiness.formattedDate.contains("15") || readiness.formattedDate.contains("Jun"),
                     "Formatted date should contain day or month")
    }

    // MARK: - Hashable and Equatable Tests

    func testDailyReadiness_Hashable() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()
        let createdAt = Date()
        let updatedAt = Date()

        let readiness1 = DailyReadiness(
            id: id,
            patientId: patientId,
            date: date,
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let readiness2 = DailyReadiness(
            id: id,
            patientId: patientId,
            date: date,
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        var set = Set<DailyReadiness>()
        set.insert(readiness1)
        set.insert(readiness2)

        // Identical objects should hash to same value and be treated as equal in Set
        XCTAssertEqual(readiness1.hashValue, readiness2.hashValue)
        XCTAssertEqual(set.count, 1, "Identical objects should only appear once in Set")
    }

    func testDailyReadiness_Equatable() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()
        let createdAt = Date()
        let updatedAt = Date()

        let readiness1 = DailyReadiness(
            id: id,
            patientId: patientId,
            date: date,
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: "Test",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let readiness2 = DailyReadiness(
            id: id,
            patientId: patientId,
            date: date,
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: "Test",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(readiness1, readiness2)
    }

    // MARK: - Edge Cases

    func testDailyReadiness_ExtremeSleepHours() {
        // Zero sleep
        let zeroSleep = createTestReadiness(sleepHours: 0.0)
        XCTAssertEqual(zeroSleep.sleepHours, 0.0)

        // Maximum reasonable sleep (24 hours)
        let maxSleep = createTestReadiness(sleepHours: 24.0)
        XCTAssertEqual(maxSleep.sleepHours, 24.0)
    }

    func testDailyReadiness_ExtremeLevels() {
        // Minimum levels (1)
        let minLevels = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 1,
            energyLevel: 1,
            stressLevel: 1,
            readinessScore: 50.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(minLevels.sorenessLevel, 1)
        XCTAssertEqual(minLevels.energyLevel, 1)
        XCTAssertEqual(minLevels.stressLevel, 1)

        // Maximum levels (10)
        let maxLevels = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 10,
            energyLevel: 10,
            stressLevel: 10,
            readinessScore: 50.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(maxLevels.sorenessLevel, 10)
        XCTAssertEqual(maxLevels.energyLevel, 10)
        XCTAssertEqual(maxLevels.stressLevel, 10)
    }

    func testDailyReadiness_ExtremeScores() {
        // Score of 0
        let zeroScore = createTestReadiness(score: 0.0)
        XCTAssertEqual(zeroScore.readinessScore, 0.0)
        XCTAssertEqual(zeroScore.category, .poor)
        XCTAssertEqual(zeroScore.readinessBand, .red)

        // Score of 100
        let maxScore = createTestReadiness(score: 100.0)
        XCTAssertEqual(maxScore.readinessScore, 100.0)
        XCTAssertEqual(maxScore.category, .elite)
        XCTAssertEqual(maxScore.readinessBand, .green)
    }

    func testDailyReadiness_LongNotes() {
        let longNotes = String(repeating: "a", count: 10000)
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: longNotes,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(readiness.notes?.count, 10000)
    }

    func testDailyReadiness_SpecialCharactersInNotes() {
        let specialNotes = "Test with emoji \u{1F4AA} and unicode: \\n\\t\\ special chars: <>&\"'"
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: specialNotes,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(readiness.notes, specialNotes)
    }

    // MARK: - Helper Methods

    private func createTestReadiness(score: Double?) -> DailyReadiness {
        return DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: score,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createTestReadiness(sleepHours: Double) -> DailyReadiness {
        return DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: sleepHours,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - ReadinessInput Tests

final class ReadinessInputTests: XCTestCase {

    // MARK: - Validation Tests

    func testValidate_ValidInput() throws {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            notes: "Test"
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_InvalidSleepHours_Negative() {
        let input = ReadinessInput(
            sleepHours: -1.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSleepHours)
        }
    }

    func testValidate_InvalidSleepHours_TooHigh() {
        let input = ReadinessInput(
            sleepHours: 25.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSleepHours)
        }
    }

    func testValidate_InvalidSorenessLevel_TooLow() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 0,
            energyLevel: 7,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSorenessLevel)
        }
    }

    func testValidate_InvalidSorenessLevel_TooHigh() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 11,
            energyLevel: 7,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidSorenessLevel)
        }
    }

    func testValidate_InvalidEnergyLevel_TooLow() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 0,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidEnergyLevel)
        }
    }

    func testValidate_InvalidEnergyLevel_TooHigh() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 11,
            stressLevel: 4,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidEnergyLevel)
        }
    }

    func testValidate_InvalidStressLevel_TooLow() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 0,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidStressLevel)
        }
    }

    func testValidate_InvalidStressLevel_TooHigh() {
        let input = ReadinessInput(
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 11,
            notes: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .invalidStressLevel)
        }
    }

    func testValidate_NoMetricsProvided() {
        let input = ReadinessInput(
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil,
            notes: "Just notes"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertEqual(error as? ReadinessError, .noMetricsProvided)
        }
    }

    func testValidate_PartialMetrics() throws {
        // Only sleep hours provided
        let input = ReadinessInput(
            sleepHours: 7.5,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil,
            notes: nil
        )

        XCTAssertNoThrow(try input.validate(), "Should be valid with at least one metric")
    }

    func testValidate_BoundaryValues() throws {
        // Minimum valid values
        let minInput = ReadinessInput(
            sleepHours: 0.0,
            sorenessLevel: 1,
            energyLevel: 1,
            stressLevel: 1,
            notes: nil
        )
        XCTAssertNoThrow(try minInput.validate())

        // Maximum valid values
        let maxInput = ReadinessInput(
            sleepHours: 24.0,
            sorenessLevel: 10,
            energyLevel: 10,
            stressLevel: 10,
            notes: nil
        )
        XCTAssertNoThrow(try maxInput.validate())
    }
}

// MARK: - ReadinessError Tests

final class ReadinessErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(ReadinessError.invalidSleepHours.errorDescription, "Sleep hours must be between 0 and 24")
        XCTAssertEqual(ReadinessError.invalidSorenessLevel.errorDescription, "Soreness level must be between 1 and 10")
        XCTAssertEqual(ReadinessError.invalidEnergyLevel.errorDescription, "Energy level must be between 1 and 10")
        XCTAssertEqual(ReadinessError.invalidStressLevel.errorDescription, "Stress level must be between 1 and 10")
        XCTAssertEqual(ReadinessError.noMetricsProvided.errorDescription, "At least one metric must be provided")
        XCTAssertEqual(ReadinessError.scoreCalculationFailed.errorDescription, "Failed to calculate readiness score")
        XCTAssertEqual(ReadinessError.noDataFound.errorDescription, "No readiness data found")
        XCTAssertEqual(ReadinessError.trendCalculationFailed.errorDescription, "Failed to calculate readiness trend")
        XCTAssertEqual(ReadinessError.fetchFailed(NSError()).errorDescription, "Failed to load readiness data")
    }

    func testFetchFailed_RecoverySuggestion() {
        let error = ReadinessError.fetchFailed(NSError(domain: "test", code: 500))
        XCTAssertEqual(error.recoverySuggestion, "Please check your internet connection and try again.")
    }

    func testFetchFailed_UnderlyingError() {
        let underlying = NSError(domain: "test", code: 500)
        let error = ReadinessError.fetchFailed(underlying)

        XCTAssertNotNil(error.underlyingError)
        XCTAssertEqual((error.underlyingError as NSError?)?.domain, "test")
    }

    func testOtherErrors_NoUnderlyingError() {
        XCTAssertNil(ReadinessError.invalidSleepHours.underlyingError)
        XCTAssertNil(ReadinessError.noDataFound.underlyingError)
        XCTAssertNil(ReadinessError.trendCalculationFailed.underlyingError)
    }

    func testOtherErrors_NoRecoverySuggestion() {
        XCTAssertNil(ReadinessError.invalidSleepHours.recoverySuggestion)
        XCTAssertNil(ReadinessError.noDataFound.recoverySuggestion)
        XCTAssertNil(ReadinessError.scoreCalculationFailed.recoverySuggestion)
    }
}

// MARK: - ReadinessBand Tests

final class ReadinessBandTests: XCTestCase {

    func testReadinessBand_DisplayNames() {
        XCTAssertEqual(ReadinessBand.green.displayName, "Ready to Train")
        XCTAssertEqual(ReadinessBand.yellow.displayName, "Train with Caution")
        XCTAssertEqual(ReadinessBand.orange.displayName, "Reduced Intensity")
        XCTAssertEqual(ReadinessBand.red.displayName, "Recovery Day")
    }

    func testReadinessBand_Colors() {
        XCTAssertEqual(ReadinessBand.green.color, Color.green)
        XCTAssertEqual(ReadinessBand.yellow.color, Color.yellow)
        XCTAssertEqual(ReadinessBand.orange.color, Color.orange)
        XCTAssertEqual(ReadinessBand.red.color, Color.red)
    }

    func testReadinessBand_LoadAdjustments() {
        XCTAssertEqual(ReadinessBand.green.loadAdjustment, 0.0)
        XCTAssertEqual(ReadinessBand.yellow.loadAdjustment, -0.10)
        XCTAssertEqual(ReadinessBand.orange.loadAdjustment, -0.25)
        XCTAssertEqual(ReadinessBand.red.loadAdjustment, -0.50)
    }

    func testReadinessBand_VolumeAdjustments() {
        XCTAssertEqual(ReadinessBand.green.volumeAdjustment, 0.0)
        XCTAssertEqual(ReadinessBand.yellow.volumeAdjustment, -0.10)
        XCTAssertEqual(ReadinessBand.orange.volumeAdjustment, -0.30)
        XCTAssertEqual(ReadinessBand.red.volumeAdjustment, -0.50)
    }

    func testReadinessBand_RawValues() {
        XCTAssertEqual(ReadinessBand.green.rawValue, "green")
        XCTAssertEqual(ReadinessBand.yellow.rawValue, "yellow")
        XCTAssertEqual(ReadinessBand.orange.rawValue, "orange")
        XCTAssertEqual(ReadinessBand.red.rawValue, "red")
    }

    func testReadinessBand_CaseIterable() {
        XCTAssertEqual(ReadinessBand.allCases.count, 4)
        XCTAssertTrue(ReadinessBand.allCases.contains(.green))
        XCTAssertTrue(ReadinessBand.allCases.contains(.yellow))
        XCTAssertTrue(ReadinessBand.allCases.contains(.orange))
        XCTAssertTrue(ReadinessBand.allCases.contains(.red))
    }
}
