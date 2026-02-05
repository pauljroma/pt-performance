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
        let startedAt = Date()
        let createdAt = Date()

        let log = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: nil,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: createdAt
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.fastingType, .intermittent)
        XCTAssertEqual(log.startedAt, startedAt)
        XCTAssertNil(log.endedAt)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.wasBrokenEarly)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
        XCTAssertEqual(log.createdAt, createdAt)
    }

    func testFastingLogWithCompletedFast() {
        let startedAt = Date().addingTimeInterval(-16 * 3600) // 16 hours ago
        let endedAt = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 16.0,
            wasBrokenEarly: false,
            breakReason: nil,
            moodStart: 7,
            moodEnd: 8,
            hungerLevel: 5,
            energyLevel: 8,
            notes: "Felt great!",
            createdAt: Date()
        )

        XCTAssertNotNil(log.endedAt)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.wasBrokenEarly, false)
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great!")
    }

    // MARK: - Computed Property Tests

    func testIsActiveWhenEndedAtNil() {
        let log = createFastingLog(endedAt: nil)
        XCTAssertTrue(log.isActive)
    }

    func testIsActiveWhenEndedAtSet() {
        let log = createFastingLog(endedAt: Date())
        XCTAssertFalse(log.isActive)
    }

    func testProgressPercentWhenCompleted() {
        let startedAt = Date().addingTimeInterval(-16 * 3600) // 16 hours ago
        let endedAt = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 16.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testProgressPercentCapsAtOne() {
        // Test when fast exceeds target
        let startedAt = Date().addingTimeInterval(-20 * 3600) // 20 hours ago
        let endedAt = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 20.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testProgressPercentWhenHalfway() {
        let startedAt = Date().addingTimeInterval(-8 * 3600) // 8 hours ago
        let endedAt = Date()

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 8.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
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

        // Verify snake_case keys (using new column names)
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["fasting_type"])
        XCTAssertNotNil(jsonObject["started_at"])
        XCTAssertNotNil(jsonObject["target_hours"])
        XCTAssertNotNil(jsonObject["created_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["fastingType"])
        XCTAssertNil(jsonObject["startedAt"])
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
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.intermittent))
        XCTAssertTrue(allCases.contains(.extended))
        XCTAssertTrue(allCases.contains(.waterOnly))
        XCTAssertTrue(allCases.contains(.modified))
        XCTAssertTrue(allCases.contains(.custom))
    }

    func testFastingTypeRawValues() {
        XCTAssertEqual(FastingType.intermittent.rawValue, "intermittent")
        XCTAssertEqual(FastingType.extended.rawValue, "extended")
        XCTAssertEqual(FastingType.waterOnly.rawValue, "water_only")
        XCTAssertEqual(FastingType.modified.rawValue, "modified")
        XCTAssertEqual(FastingType.custom.rawValue, "custom")
    }

    func testFastingTypeDisplayNames() {
        XCTAssertEqual(FastingType.intermittent.displayName, "Intermittent")
        XCTAssertEqual(FastingType.extended.displayName, "Extended")
        XCTAssertEqual(FastingType.waterOnly.displayName, "Water Only")
        XCTAssertEqual(FastingType.modified.displayName, "Modified")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    func testFastingTypeTargetHours() {
        XCTAssertEqual(FastingType.intermittent.targetHours, 16)
        XCTAssertEqual(FastingType.extended.targetHours, 24)
        XCTAssertEqual(FastingType.waterOnly.targetHours, 24)
        XCTAssertEqual(FastingType.modified.targetHours, 18)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    func testFastingTypeTargetHoursIncreaseWithExtendedFasts() {
        // Extended fasts should have longer durations than intermittent
        XCTAssertLessThan(FastingType.intermittent.targetHours, FastingType.extended.targetHours)
    }

    func testFastingTypeInitFromRawValue() {
        XCTAssertEqual(FastingType(rawValue: "intermittent"), .intermittent)
        XCTAssertEqual(FastingType(rawValue: "extended"), .extended)
        XCTAssertEqual(FastingType(rawValue: "water_only"), .waterOnly)
        XCTAssertEqual(FastingType(rawValue: "modified"), .modified)
        XCTAssertEqual(FastingType(rawValue: "custom"), .custom)
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
            trainingTime: trainingTime,
            confidence: 0.9
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
            trainingTime: nil,
            confidence: 0.8
        )

        XCTAssertNil(recommendation.trainingTime)
    }

    func testEatingWindowRecommendationCodable() throws {
        let original = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date().addingTimeInterval(8 * 3600),
            reason: "Test reason",
            trainingTime: Date(),
            confidence: 0.85
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

    private func createFastingLog(endedAt: Date? = nil) -> FastingLog {
        FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date(),
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
