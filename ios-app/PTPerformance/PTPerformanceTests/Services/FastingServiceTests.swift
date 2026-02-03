//
//  FastingServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for FastingService
//  Tests fasting models, types, statistics, and service state management
//

import XCTest
@testable import PTPerformance

// MARK: - FastingType Tests

final class FastingTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testFastingType_RawValues() {
        XCTAssertEqual(FastingType.intermittent16_8.rawValue, "16_8")
        XCTAssertEqual(FastingType.intermittent18_6.rawValue, "18_6")
        XCTAssertEqual(FastingType.intermittent20_4.rawValue, "20_4")
        XCTAssertEqual(FastingType.omad.rawValue, "omad")
        XCTAssertEqual(FastingType.extended24.rawValue, "24")
        XCTAssertEqual(FastingType.extended36.rawValue, "36")
        XCTAssertEqual(FastingType.extended48.rawValue, "48")
        XCTAssertEqual(FastingType.custom.rawValue, "custom")
    }

    func testFastingType_InitFromRawValue() {
        XCTAssertEqual(FastingType(rawValue: "16_8"), .intermittent16_8)
        XCTAssertEqual(FastingType(rawValue: "18_6"), .intermittent18_6)
        XCTAssertEqual(FastingType(rawValue: "20_4"), .intermittent20_4)
        XCTAssertEqual(FastingType(rawValue: "omad"), .omad)
        XCTAssertEqual(FastingType(rawValue: "24"), .extended24)
        XCTAssertEqual(FastingType(rawValue: "36"), .extended36)
        XCTAssertEqual(FastingType(rawValue: "48"), .extended48)
        XCTAssertEqual(FastingType(rawValue: "custom"), .custom)
        XCTAssertNil(FastingType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testFastingType_DisplayNames() {
        XCTAssertEqual(FastingType.intermittent16_8.displayName, "16:8")
        XCTAssertEqual(FastingType.intermittent18_6.displayName, "18:6")
        XCTAssertEqual(FastingType.intermittent20_4.displayName, "20:4")
        XCTAssertEqual(FastingType.omad.displayName, "OMAD (23:1)")
        XCTAssertEqual(FastingType.extended24.displayName, "24 Hour")
        XCTAssertEqual(FastingType.extended36.displayName, "36 Hour")
        XCTAssertEqual(FastingType.extended48.displayName, "48 Hour")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    // MARK: - Target Hours Tests

    func testFastingType_TargetHours() {
        XCTAssertEqual(FastingType.intermittent16_8.targetHours, 16)
        XCTAssertEqual(FastingType.intermittent18_6.targetHours, 18)
        XCTAssertEqual(FastingType.intermittent20_4.targetHours, 20)
        XCTAssertEqual(FastingType.omad.targetHours, 23)
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    // MARK: - CaseIterable Tests

    func testFastingType_AllCases() {
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

    // MARK: - Codable Tests

    func testFastingType_Encoding() throws {
        let fastingType = FastingType.intermittent16_8
        let encoder = JSONEncoder()
        let data = try encoder.encode(fastingType)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"16_8\"")
    }

    func testFastingType_Decoding() throws {
        let json = "\"omad\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let fastingType = try decoder.decode(FastingType.self, from: json)

        XCTAssertEqual(fastingType, .omad)
    }
}

// MARK: - FastingLog Tests

final class FastingLogTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testFastingLog_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()
        let endTime = Date().addingTimeInterval(16 * 3600)
        let createdAt = Date()

        let log = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: "Eggs and avocado",
            energyLevel: 8,
            notes: "Felt great",
            createdAt: createdAt
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.fastingType, .intermittent16_8)
        XCTAssertEqual(log.startTime, startTime)
        XCTAssertEqual(log.endTime, endTime)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.breakfastFood, "Eggs and avocado")
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great")
    }

    func testFastingLog_OptionalFields() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertNil(log.endTime)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.breakfastFood)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
    }

    // MARK: - IsActive Tests

    func testFastingLog_IsActive_WhenEndTimeIsNil() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertTrue(log.isActive)
    }

    func testFastingLog_IsNotActive_WhenEndTimeIsSet() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: Date(),
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertFalse(log.isActive)
    }

    // MARK: - ProgressPercent Tests

    func testFastingLog_ProgressPercent_ActiveFast_PartialProgress() {
        let startTime = Date().addingTimeInterval(-8 * 3600) // 8 hours ago
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // Should be approximately 50% (8/16 hours)
        XCTAssertEqual(log.progressPercent, 0.5, accuracy: 0.05)
    }

    func testFastingLog_ProgressPercent_ActiveFast_CappedAtOne() {
        let startTime = Date().addingTimeInterval(-20 * 3600) // 20 hours ago (over target)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // Should be capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_ProgressPercent_CompletedFast() {
        let startTime = Date().addingTimeInterval(-20 * 3600)
        let endTime = startTime.addingTimeInterval(18 * 3600)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 18.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 18/16 = 1.125, but capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_ProgressPercent_CompletedFast_UnderTarget() {
        let startTime = Date().addingTimeInterval(-14 * 3600)
        let endTime = startTime.addingTimeInterval(12 * 3600)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 12.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 12/16 = 0.75
        XCTAssertEqual(log.progressPercent, 0.75, accuracy: 0.01)
    }

    // MARK: - Identifiable Tests

    func testFastingLog_Identifiable() {
        let id = UUID()
        let log = FastingLog(
            id: id,
            patientId: UUID(),
            fastingType: .omad,
            startTime: Date(),
            endTime: nil,
            targetHours: 23,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.id, id)
    }

    // MARK: - Hashable Tests

    func testFastingLog_Hashable() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let log1 = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent16_8,
            startTime: date,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: date
        )
        let log2 = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent16_8,
            startTime: date,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: date
        )

        XCTAssertEqual(log1, log2)
    }
}

// MARK: - FastingStats Tests

final class FastingStatsTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testFastingStats_MemberwiseInit() {
        let stats = FastingStats(
            totalFasts: 100,
            completedFasts: 95,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 7,
            bestStreak: 21
        )

        XCTAssertEqual(stats.totalFasts, 100)
        XCTAssertEqual(stats.completedFasts, 95)
        XCTAssertEqual(stats.averageHours, 16.5)
        XCTAssertEqual(stats.longestFast, 24.0)
        XCTAssertEqual(stats.currentStreak, 7)
        XCTAssertEqual(stats.bestStreak, 21)
    }

    func testFastingStats_ZeroValues() {
        let stats = FastingStats(
            totalFasts: 0,
            completedFasts: 0,
            averageHours: 0.0,
            longestFast: 0.0,
            currentStreak: 0,
            bestStreak: 0
        )

        XCTAssertEqual(stats.totalFasts, 0)
        XCTAssertEqual(stats.completedFasts, 0)
        XCTAssertEqual(stats.averageHours, 0.0)
        XCTAssertEqual(stats.longestFast, 0.0)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.bestStreak, 0)
    }
}

// MARK: - EatingWindowRecommendation Tests

final class EatingWindowRecommendationTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testEatingWindowRecommendation_MemberwiseInit() {
        let id = UUID()
        let suggestedStart = Date()
        let suggestedEnd = suggestedStart.addingTimeInterval(8 * 3600)
        let trainingTime = suggestedStart.addingTimeInterval(2 * 3600)

        let recommendation = EatingWindowRecommendation(
            id: id,
            suggestedStart: suggestedStart,
            suggestedEnd: suggestedEnd,
            reason: "Optimized around your training",
            trainingTime: trainingTime
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.suggestedStart, suggestedStart)
        XCTAssertEqual(recommendation.suggestedEnd, suggestedEnd)
        XCTAssertEqual(recommendation.reason, "Optimized around your training")
        XCTAssertEqual(recommendation.trainingTime, trainingTime)
    }

    func testEatingWindowRecommendation_NoTrainingTime() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date().addingTimeInterval(8 * 3600),
            reason: "Standard eating window",
            trainingTime: nil
        )

        XCTAssertNil(recommendation.trainingTime)
    }

    // MARK: - Identifiable Tests

    func testEatingWindowRecommendation_Identifiable() {
        let id = UUID()
        let recommendation = EatingWindowRecommendation(
            id: id,
            suggestedStart: Date(),
            suggestedEnd: Date(),
            reason: "Test",
            trainingTime: nil
        )

        XCTAssertEqual(recommendation.id, id)
    }
}

// MARK: - FastingService Tests

@MainActor
final class FastingServiceTests: XCTestCase {

    var sut: FastingService!

    override func setUp() async throws {
        try await super.setUp()
        sut = FastingService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(FastingService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = FastingService.shared
        let instance2 = FastingService.shared
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_FastingHistoryIsArray() {
        XCTAssertNotNil(sut.fastingHistory)
        XCTAssertTrue(sut.fastingHistory is [FastingLog])
    }

    func testInitialState_CurrentFastProperty() {
        // Current fast can be nil or a FastingLog
        _ = sut.currentFast
    }

    func testInitialState_StatsProperty() {
        // Stats can be nil initially
        _ = sut.stats
    }

    func testInitialState_EatingWindowRecommendationProperty() {
        // Recommendation can be nil initially
        _ = sut.eatingWindowRecommendation
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
    }

    // MARK: - Published Properties Tests

    func testFastingHistory_IsPublished() {
        let history = sut.fastingHistory
        XCTAssertNotNil(history)
    }

    func testCurrentFast_IsPublished() {
        // Can be nil or have value
        _ = sut.currentFast
    }

    func testStats_IsPublished() {
        // Can be nil or have value
        _ = sut.stats
    }

    // MARK: - Generate Eating Window Recommendation Tests

    func testGenerateEatingWindowRecommendation_WithoutTrainingTime() async {
        // When
        await sut.generateEatingWindowRecommendation(trainingTime: nil)

        // Then
        XCTAssertNotNil(sut.eatingWindowRecommendation)
        XCTAssertNil(sut.eatingWindowRecommendation?.trainingTime)
        XCTAssertEqual(sut.eatingWindowRecommendation?.reason, "Standard 8-hour eating window for your schedule")
    }

    func testGenerateEatingWindowRecommendation_WithTrainingTime() async {
        // Given
        let trainingTime = Date()

        // When
        await sut.generateEatingWindowRecommendation(trainingTime: trainingTime)

        // Then
        XCTAssertNotNil(sut.eatingWindowRecommendation)
        XCTAssertNotNil(sut.eatingWindowRecommendation?.trainingTime)
        XCTAssertTrue(sut.eatingWindowRecommendation?.reason.contains("Optimized") ?? false)
    }

    func testGenerateEatingWindowRecommendation_EatingWindowDuration() async {
        // When
        await sut.generateEatingWindowRecommendation(trainingTime: nil)

        // Then
        guard let recommendation = sut.eatingWindowRecommendation else {
            XCTFail("Recommendation should be generated")
            return
        }

        let duration = recommendation.suggestedEnd.timeIntervalSince(recommendation.suggestedStart)
        let hours = duration / 3600

        // Standard eating window should be 8 hours
        XCTAssertEqual(hours, 8.0, accuracy: 0.1)
    }
}

// MARK: - Codable Decoding Tests

final class FastingLogDecodingTests: XCTestCase {

    func testFastingLog_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "16_8",
            "start_time": "2024-01-15T20:00:00Z",
            "end_time": "2024-01-16T12:00:00Z",
            "target_hours": 16,
            "actual_hours": 16.0,
            "breakfast_food": "Eggs and avocado",
            "energy_level": 8,
            "notes": "Felt great",
            "created_at": "2024-01-15T20:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(FastingLog.self, from: json)

        XCTAssertEqual(log.fastingType, .intermittent16_8)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.breakfastFood, "Eggs and avocado")
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great")
    }

    func testFastingLog_DecodingWithNullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "18_6",
            "start_time": "2024-01-15T20:00:00Z",
            "end_time": null,
            "target_hours": 18,
            "actual_hours": null,
            "breakfast_food": null,
            "energy_level": null,
            "notes": null,
            "created_at": "2024-01-15T20:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(FastingLog.self, from: json)

        XCTAssertNil(log.endTime)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.breakfastFood)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
        XCTAssertTrue(log.isActive)
    }

    func testFastingLog_AllFastingTypes() throws {
        let fastingTypes = ["16_8", "18_6", "20_4", "omad", "24", "36", "48", "custom"]

        for fastingType in fastingTypes {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "fasting_type": "\(fastingType)",
                "start_time": "2024-01-15T20:00:00Z",
                "end_time": null,
                "target_hours": 16,
                "actual_hours": null,
                "breakfast_food": null,
                "energy_level": null,
                "notes": null,
                "created_at": "2024-01-15T20:00:00Z"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let log = try decoder.decode(FastingLog.self, from: json)

            XCTAssertEqual(log.fastingType.rawValue, fastingType)
        }
    }

    func testFastingStats_Decoding() throws {
        let json = """
        {
            "total_fasts": 50,
            "completed_fasts": 48,
            "average_hours": 16.5,
            "longest_fast": 24.0,
            "current_streak": 7,
            "best_streak": 14
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let stats = try decoder.decode(FastingStats.self, from: json)

        XCTAssertEqual(stats.totalFasts, 50)
        XCTAssertEqual(stats.completedFasts, 48)
        XCTAssertEqual(stats.averageHours, 16.5)
        XCTAssertEqual(stats.longestFast, 24.0)
        XCTAssertEqual(stats.currentStreak, 7)
        XCTAssertEqual(stats.bestStreak, 14)
    }
}

// MARK: - Edge Cases Tests

final class FastingServiceEdgeCaseTests: XCTestCase {

    func testFastingType_TargetHoursAreReasonable() {
        for fastingType in FastingType.allCases {
            let targetHours = fastingType.targetHours

            // All target hours should be between 1 and 48
            XCTAssertGreaterThan(targetHours, 0)
            XCTAssertLessThanOrEqual(targetHours, 48)
        }
    }

    func testFastingType_IntermittentFastsHaveReasonableTargets() {
        // Intermittent fasts should be between 12-23 hours
        XCTAssertGreaterThanOrEqual(FastingType.intermittent16_8.targetHours, 12)
        XCTAssertLessThanOrEqual(FastingType.intermittent16_8.targetHours, 23)

        XCTAssertGreaterThanOrEqual(FastingType.intermittent18_6.targetHours, 12)
        XCTAssertLessThanOrEqual(FastingType.intermittent18_6.targetHours, 23)

        XCTAssertGreaterThanOrEqual(FastingType.intermittent20_4.targetHours, 12)
        XCTAssertLessThanOrEqual(FastingType.intermittent20_4.targetHours, 23)
    }

    func testFastingType_ExtendedFastsHaveCorrectTargets() {
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
    }

    func testFastingLog_EnergyLevelRange() {
        // Energy level should typically be 1-10
        for level in 1...10 {
            let log = FastingLog(
                id: UUID(),
                patientId: UUID(),
                fastingType: .intermittent16_8,
                startTime: Date(),
                endTime: Date(),
                targetHours: 16,
                actualHours: 16.0,
                breakfastFood: nil,
                energyLevel: level,
                notes: nil,
                createdAt: Date()
            )

            XCTAssertEqual(log.energyLevel, level)
        }
    }

    func testFastingLog_VeryLongFast() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .extended48,
            startTime: Date(),
            endTime: Date().addingTimeInterval(50 * 3600),
            targetHours: 48,
            actualHours: 50.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.actualHours, 50.0)
        XCTAssertFalse(log.isActive)
    }

    func testFastingStats_CompletionRate() {
        let stats = FastingStats(
            totalFasts: 100,
            completedFasts: 95,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 7,
            bestStreak: 21
        )

        // Completion rate = 95/100 = 95%
        let completionRate = Double(stats.completedFasts) / Double(stats.totalFasts) * 100
        XCTAssertEqual(completionRate, 95.0, accuracy: 0.01)
    }

    func testFastingStats_StreaksAreReasonable() {
        let stats = FastingStats(
            totalFasts: 100,
            completedFasts: 95,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 7,
            bestStreak: 21
        )

        // Current streak should not exceed best streak
        XCTAssertLessThanOrEqual(stats.currentStreak, stats.bestStreak)

        // Best streak should not exceed total fasts
        XCTAssertLessThanOrEqual(stats.bestStreak, stats.totalFasts)
    }

    func testFastingType_UniqueDisplayNames() {
        let names = FastingType.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        // All display names should be unique
        XCTAssertEqual(names.count, uniqueNames.count, "Each fasting type should have a unique display name")
    }
}
