//
//  FastingLogTests.swift
//  PTPerformanceTests
//
//  Unit tests for FastingLog, FastingType, EatingWindowRecommendation, and FastingStats models
//

import XCTest
@testable import PTPerformance

final class FastingLogTests: XCTestCase {

    // MARK: - FastingLog Initialization Tests

    func testFastingLogInitialization() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()
        let createdAt = Date()

        let log = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: createdAt
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.fastingType, .intermittent16_8)
        XCTAssertEqual(log.startTime, startTime)
        XCTAssertNil(log.endTime)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.breakfastFood)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
        XCTAssertEqual(log.createdAt, createdAt)
    }

    func testFastingLogWithCompletedFast() {
        let startTime = Date().addingTimeInterval(-16 * 3600) // 16 hours ago
        let endTime = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: "Eggs and avocado",
            energyLevel: 8,
            notes: "Felt great!",
            createdAt: Date()
        )

        XCTAssertNotNil(log.endTime)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.breakfastFood, "Eggs and avocado")
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great!")
    }

    // MARK: - Computed Property Tests

    func testIsActiveWhenEndTimeNil() {
        let log = createFastingLog(endTime: nil)
        XCTAssertTrue(log.isActive)
    }

    func testIsActiveWhenEndTimeSet() {
        let log = createFastingLog(endTime: Date())
        XCTAssertFalse(log.isActive)
    }

    func testProgressPercentWhenCompleted() {
        let startTime = Date().addingTimeInterval(-16 * 3600) // 16 hours ago
        let endTime = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testProgressPercentCapsAtOne() {
        // Test when fast exceeds target
        let startTime = Date().addingTimeInterval(-20 * 3600) // 20 hours ago
        let endTime = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 20.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testProgressPercentWhenHalfway() {
        let startTime = Date().addingTimeInterval(-8 * 3600) // 8 hours ago
        let endTime = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 8.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.progressPercent, 0.5, accuracy: 0.01)
    }

    // MARK: - FastingLog Codable Tests

    func testFastingLogEncodeDecode() throws {
        let original = createFastingLog()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FastingLog.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.fastingType, decoded.fastingType)
        XCTAssertEqual(original.targetHours, decoded.targetHours)
    }

    func testFastingLogCodingKeysMapping() throws {
        let log = createFastingLog()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(log)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["fasting_type"])
        XCTAssertNotNil(jsonObject["start_time"])
        XCTAssertNotNil(jsonObject["target_hours"])
        XCTAssertNotNil(jsonObject["created_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["fastingType"])
        XCTAssertNil(jsonObject["startTime"])
        XCTAssertNil(jsonObject["targetHours"])
    }

    func testFastingLogHashable() {
        let log1 = createFastingLog()
        let log2 = createFastingLog()

        var set = Set<FastingLog>()
        set.insert(log1)
        set.insert(log2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - FastingType Tests

    func testFastingTypeAllCases() {
        let allCases = FastingType.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.intermittent16_8))
        XCTAssertTrue(allCases.contains(.intermittent18_6))
        XCTAssertTrue(allCases.contains(.intermittent20_4))
        XCTAssertTrue(allCases.contains(.omad))
        XCTAssertTrue(allCases.contains(.extended24))
        XCTAssertTrue(allCases.contains(.extended36))
        XCTAssertTrue(allCases.contains(.extended48))
        XCTAssertTrue(allCases.contains(.custom))
    }

    func testFastingTypeRawValues() {
        XCTAssertEqual(FastingType.intermittent16_8.rawValue, "16_8")
        XCTAssertEqual(FastingType.intermittent18_6.rawValue, "18_6")
        XCTAssertEqual(FastingType.intermittent20_4.rawValue, "20_4")
        XCTAssertEqual(FastingType.omad.rawValue, "omad")
        XCTAssertEqual(FastingType.extended24.rawValue, "24")
        XCTAssertEqual(FastingType.extended36.rawValue, "36")
        XCTAssertEqual(FastingType.extended48.rawValue, "48")
        XCTAssertEqual(FastingType.custom.rawValue, "custom")
    }

    func testFastingTypeDisplayNames() {
        XCTAssertEqual(FastingType.intermittent16_8.displayName, "16:8")
        XCTAssertEqual(FastingType.intermittent18_6.displayName, "18:6")
        XCTAssertEqual(FastingType.intermittent20_4.displayName, "20:4")
        XCTAssertEqual(FastingType.omad.displayName, "OMAD (23:1)")
        XCTAssertEqual(FastingType.extended24.displayName, "24 Hour")
        XCTAssertEqual(FastingType.extended36.displayName, "36 Hour")
        XCTAssertEqual(FastingType.extended48.displayName, "48 Hour")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    func testFastingTypeTargetHours() {
        XCTAssertEqual(FastingType.intermittent16_8.targetHours, 16)
        XCTAssertEqual(FastingType.intermittent18_6.targetHours, 18)
        XCTAssertEqual(FastingType.intermittent20_4.targetHours, 20)
        XCTAssertEqual(FastingType.omad.targetHours, 23)
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    func testFastingTypeTargetHoursIncreaseWithExtendedFasts() {
        // Extended fasts should have longer durations
        XCTAssertLessThan(FastingType.intermittent16_8.targetHours, FastingType.extended24.targetHours)
        XCTAssertLessThan(FastingType.extended24.targetHours, FastingType.extended36.targetHours)
        XCTAssertLessThan(FastingType.extended36.targetHours, FastingType.extended48.targetHours)
    }

    func testFastingTypeInitFromRawValue() {
        XCTAssertEqual(FastingType(rawValue: "16_8"), .intermittent16_8)
        XCTAssertEqual(FastingType(rawValue: "omad"), .omad)
        XCTAssertEqual(FastingType(rawValue: "24"), .extended24)
        XCTAssertNil(FastingType(rawValue: "invalid"))
        XCTAssertNil(FastingType(rawValue: ""))
    }

    func testFastingTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for fastingType in FastingType.allCases {
            let data = try encoder.encode(fastingType)
            let decoded = try decoder.decode(FastingType.self, from: data)
            XCTAssertEqual(decoded, fastingType)
        }
    }

    // MARK: - EatingWindowRecommendation Tests

    func testEatingWindowRecommendationInitialization() {
        let id = UUID()
        let suggestedStart = Date()
        let suggestedEnd = Date().addingTimeInterval(8 * 3600)
        let trainingTime = Date().addingTimeInterval(4 * 3600)

        let recommendation = EatingWindowRecommendation(
            id: id,
            suggestedStart: suggestedStart,
            suggestedEnd: suggestedEnd,
            reason: "Aligns with your morning workout",
            trainingTime: trainingTime
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.suggestedStart, suggestedStart)
        XCTAssertEqual(recommendation.suggestedEnd, suggestedEnd)
        XCTAssertEqual(recommendation.reason, "Aligns with your morning workout")
        XCTAssertEqual(recommendation.trainingTime, trainingTime)
    }

    func testEatingWindowRecommendationWithNilTrainingTime() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date().addingTimeInterval(8 * 3600),
            reason: "Rest day recommendation",
            trainingTime: nil
        )

        XCTAssertNil(recommendation.trainingTime)
    }

    func testEatingWindowRecommendationCodable() throws {
        let original = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date().addingTimeInterval(8 * 3600),
            reason: "Test reason",
            trainingTime: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(EatingWindowRecommendation.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.reason, decoded.reason)
    }

    // MARK: - FastingStats Tests

    func testFastingStatsInitialization() {
        let stats = FastingStats(
            totalFasts: 100,
            completedFasts: 95,
            averageHours: 16.5,
            longestFast: 36.0,
            currentStreak: 7,
            bestStreak: 21
        )

        XCTAssertEqual(stats.totalFasts, 100)
        XCTAssertEqual(stats.completedFasts, 95)
        XCTAssertEqual(stats.averageHours, 16.5)
        XCTAssertEqual(stats.longestFast, 36.0)
        XCTAssertEqual(stats.currentStreak, 7)
        XCTAssertEqual(stats.bestStreak, 21)
    }

    func testFastingStatsCodable() throws {
        let original = FastingStats(
            totalFasts: 50,
            completedFasts: 48,
            averageHours: 17.0,
            longestFast: 24.0,
            currentStreak: 5,
            bestStreak: 14
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FastingStats.self, from: data)

        XCTAssertEqual(original.totalFasts, decoded.totalFasts)
        XCTAssertEqual(original.completedFasts, decoded.completedFasts)
        XCTAssertEqual(original.averageHours, decoded.averageHours)
        XCTAssertEqual(original.longestFast, decoded.longestFast)
        XCTAssertEqual(original.currentStreak, decoded.currentStreak)
        XCTAssertEqual(original.bestStreak, decoded.bestStreak)
    }

    func testFastingStatsCodingKeysMapping() throws {
        let stats = FastingStats(
            totalFasts: 10,
            completedFasts: 9,
            averageHours: 16.0,
            longestFast: 18.0,
            currentStreak: 3,
            bestStreak: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["total_fasts"])
        XCTAssertNotNil(jsonObject["completed_fasts"])
        XCTAssertNotNil(jsonObject["average_hours"])
        XCTAssertNotNil(jsonObject["longest_fast"])
        XCTAssertNotNil(jsonObject["current_streak"])
        XCTAssertNotNil(jsonObject["best_streak"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["totalFasts"])
        XCTAssertNil(jsonObject["completedFasts"])
        XCTAssertNil(jsonObject["averageHours"])
    }

    // MARK: - Helpers

    private func createFastingLog(endTime: Date? = nil) -> FastingLog {
        FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: endTime,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
