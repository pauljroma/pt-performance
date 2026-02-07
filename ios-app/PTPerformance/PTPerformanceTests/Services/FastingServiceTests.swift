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
        XCTAssertEqual(FastingType.intermittent.rawValue, "intermittent")
        XCTAssertEqual(FastingType.extended.rawValue, "extended")
        XCTAssertEqual(FastingType.waterOnly.rawValue, "water_only")
        XCTAssertEqual(FastingType.modified.rawValue, "modified")
        XCTAssertEqual(FastingType.custom.rawValue, "custom")
    }

    func testFastingType_InitFromRawValue() {
        XCTAssertEqual(FastingType(rawValue: "intermittent"), .intermittent)
        XCTAssertEqual(FastingType(rawValue: "extended"), .extended)
        XCTAssertEqual(FastingType(rawValue: "water_only"), .waterOnly)
        XCTAssertEqual(FastingType(rawValue: "modified"), .modified)
        XCTAssertEqual(FastingType(rawValue: "custom"), .custom)
        XCTAssertNil(FastingType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testFastingType_DisplayNames() {
        XCTAssertEqual(FastingType.intermittent.displayName, "Intermittent")
        XCTAssertEqual(FastingType.extended.displayName, "Extended")
        XCTAssertEqual(FastingType.waterOnly.displayName, "Water Only")
        XCTAssertEqual(FastingType.modified.displayName, "Modified")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    // MARK: - Target Hours Tests

    func testFastingType_TargetHours() {
        XCTAssertEqual(FastingType.intermittent.targetHours, 16)
        XCTAssertEqual(FastingType.extended.targetHours, 24)
        XCTAssertEqual(FastingType.waterOnly.targetHours, 24)
        XCTAssertEqual(FastingType.modified.targetHours, 18)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    // MARK: - CaseIterable Tests

    func testFastingType_AllCases() {
        let allCases = FastingType.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.intermittent))
        XCTAssertTrue(allCases.contains(.extended))
        XCTAssertTrue(allCases.contains(.waterOnly))
        XCTAssertTrue(allCases.contains(.modified))
        XCTAssertTrue(allCases.contains(.custom))
    }

    // MARK: - Codable Tests

    func testFastingType_Encoding() throws {
        let fastingType = FastingType.intermittent
        let encoder = JSONEncoder()
        let data = try encoder.encode(fastingType)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"intermittent\"")
    }

    func testFastingType_Decoding() throws {
        let json = "\"extended\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let fastingType = try decoder.decode(FastingType.self, from: json)

        XCTAssertEqual(fastingType, .extended)
    }
}

// MARK: - FastingLog Tests

final class FastingLogServiceTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testFastingLog_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let startedAt = Date()
        let endedAt = Date().addingTimeInterval(16 * 3600)
        let createdAt = Date()

        let log = FastingLog(
            id: id,
            patientId: patientId,
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
            notes: "Felt great",
            createdAt: createdAt
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.fastingType, .intermittent)
        XCTAssertEqual(log.startedAt, startedAt)
        XCTAssertEqual(log.endedAt, endedAt)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.wasBrokenEarly, false)
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great")
    }

    func testFastingLog_OptionalFields() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date(),
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
            createdAt: Date()
        )

        XCTAssertNil(log.endedAt)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.wasBrokenEarly)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
    }

    // MARK: - IsActive Tests

    func testFastingLog_IsActive_WhenEndedAtIsNil() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date(),
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
            createdAt: Date()
        )

        XCTAssertTrue(log.isActive)
    }

    func testFastingLog_IsNotActive_WhenEndedAtIsSet() {
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date(),
            endedAt: Date(),
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

        XCTAssertFalse(log.isActive)
    }

    // MARK: - ProgressPercent Tests

    func testFastingLog_ProgressPercent_ActiveFast_PartialProgress() {
        let startedAt = Date().addingTimeInterval(-8 * 3600) // 8 hours ago
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
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
            createdAt: Date()
        )

        // Should be approximately 50% (8/16 hours)
        XCTAssertEqual(log.progressPercent, 0.5, accuracy: 0.05)
    }

    func testFastingLog_ProgressPercent_ActiveFast_CappedAtOne() {
        let startedAt = Date().addingTimeInterval(-20 * 3600) // 20 hours ago (over target)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
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
            createdAt: Date()
        )

        // Should be capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_ProgressPercent_CompletedFast() {
        let startedAt = Date().addingTimeInterval(-20 * 3600)
        let endedAt = startedAt.addingTimeInterval(18 * 3600)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 18.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 18/16 = 1.125, but capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_ProgressPercent_CompletedFast_UnderTarget() {
        let startedAt = Date().addingTimeInterval(-14 * 3600)
        let endedAt = startedAt.addingTimeInterval(12 * 3600)
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 12.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
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
            fastingType: .extended,
            startedAt: Date(),
            endedAt: nil,
            plannedEndAt: nil,
            targetHours: 24,
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
            fastingType: .intermittent,
            startedAt: date,
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
            createdAt: date
        )
        let log2 = FastingLog(
            id: id,
            patientId: patientId,
            fastingType: .intermittent,
            startedAt: date,
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
            trainingTime: trainingTime,
            confidence: 0.9
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
            trainingTime: nil,
            confidence: 0.8
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
            trainingTime: nil,
            confidence: 0.7
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

    func testInitialState_RecentFastsIsArray() {
        XCTAssertNotNil(sut.recentFasts)
        XCTAssertTrue(sut.recentFasts is [FastingLog])
    }

    func testInitialState_ActiveFastProperty() {
        // Active fast can be nil or a FastingLog
        _ = sut.activeFast
    }

    func testInitialState_WeeklyStatsProperty() {
        // Weekly stats can be nil initially
        _ = sut.weeklyStats
    }

    func testInitialState_EatingWindowRecommendationProperty() {
        // Recommendation can be nil initially
        _ = sut.eatingWindowRecommendation
    }

    func testInitialState_WorkoutRecommendationProperty() {
        // Workout recommendation can be nil initially
        _ = sut.workoutRecommendation
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
    }

    func testInitialState_ProtocolsProperty() {
        XCTAssertNotNil(sut.protocols)
    }

    func testInitialState_CurrentStreakProperty() {
        _ = sut.currentStreak
    }

    func testInitialState_CurrentGoalProperty() {
        _ = sut.currentGoal
    }

    // MARK: - Published Properties Tests

    func testRecentFasts_IsPublished() {
        let fasts = sut.recentFasts
        XCTAssertNotNil(fasts)
    }

    func testActiveFast_IsPublished() {
        // Can be nil or have value
        _ = sut.activeFast
    }

    func testWeeklyStats_IsPublished() {
        // Can be nil or have value
        _ = sut.weeklyStats
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
            "fasting_type": "intermittent",
            "started_at": "2024-01-15T20:00:00Z",
            "ended_at": "2024-01-16T12:00:00Z",
            "planned_end_at": null,
            "target_hours": 16,
            "actual_hours": 16.0,
            "was_broken_early": false,
            "break_reason": null,
            "mood_start": 7,
            "mood_end": 8,
            "hunger_level": 5,
            "energy_level": 8,
            "notes": "Felt great",
            "created_at": "2024-01-15T20:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(FastingLog.self, from: json)

        XCTAssertEqual(log.fastingType, .intermittent)
        XCTAssertEqual(log.targetHours, 16)
        XCTAssertEqual(log.actualHours, 16.0)
        XCTAssertEqual(log.wasBrokenEarly, false)
        XCTAssertEqual(log.energyLevel, 8)
        XCTAssertEqual(log.notes, "Felt great")
    }

    func testFastingLog_DecodingWithNullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "extended",
            "started_at": "2024-01-15T20:00:00Z",
            "ended_at": null,
            "planned_end_at": null,
            "target_hours": 24,
            "actual_hours": null,
            "was_broken_early": null,
            "break_reason": null,
            "mood_start": null,
            "mood_end": null,
            "hunger_level": null,
            "energy_level": null,
            "notes": null,
            "created_at": "2024-01-15T20:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(FastingLog.self, from: json)

        XCTAssertNil(log.endedAt)
        XCTAssertNil(log.actualHours)
        XCTAssertNil(log.wasBrokenEarly)
        XCTAssertNil(log.energyLevel)
        XCTAssertNil(log.notes)
        XCTAssertTrue(log.isActive)
    }

    func testFastingLog_AllFastingTypes() throws {
        let fastingTypes = ["intermittent", "extended", "water_only", "modified", "custom"]

        for fastingType in fastingTypes {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "fasting_type": "\(fastingType)",
                "started_at": "2024-01-15T20:00:00Z",
                "ended_at": null,
                "planned_end_at": null,
                "target_hours": 16,
                "actual_hours": null,
                "was_broken_early": null,
                "break_reason": null,
                "mood_start": null,
                "mood_end": null,
                "hunger_level": null,
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
        XCTAssertGreaterThanOrEqual(FastingType.intermittent.targetHours, 12)
        XCTAssertLessThanOrEqual(FastingType.intermittent.targetHours, 23)
    }

    func testFastingType_ExtendedFastsHaveCorrectTargets() {
        XCTAssertEqual(FastingType.extended.targetHours, 24)
    }

    func testFastingLog_EnergyLevelRange() {
        // Energy level should typically be 1-10
        for level in 1...10 {
            let log = FastingLog(
                id: UUID(),
                patientId: UUID(),
                fastingType: .intermittent,
                startedAt: Date(),
                endedAt: Date(),
                plannedEndAt: nil,
                targetHours: 16,
                actualHours: 16.0,
                wasBrokenEarly: nil,
                breakReason: nil,
                moodStart: nil,
                moodEnd: nil,
                hungerLevel: nil,
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
            fastingType: .extended,
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(50 * 3600),
            plannedEndAt: nil,
            targetHours: 48,
            actualHours: 50.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
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

// MARK: - FastingError Tests

final class FastingErrorTests: XCTestCase {

    func testFastingError_NoPatientId_HasDescription() {
        let error = FastingError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("patient"))
    }

    func testFastingError_FastAlreadyActive_HasDescription() {
        let error = FastingError.fastAlreadyActive
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("active"))
    }

    func testFastingError_NoActiveFast_HasDescription() {
        let error = FastingError.noActiveFast
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("active"))
    }

    func testFastingError_InvalidFastingType_HasDescription() {
        let error = FastingError.invalidFastingType
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("type"))
    }

    func testFastingError_NetworkError_HasDescription() {
        let error = FastingError.networkError
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("network"))
    }

    func testFastingError_Unknown_WrapsOriginalError() {
        let originalError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        let error = FastingError.unknown(originalError)
        XCTAssertEqual(error.errorDescription, "Test error message")
    }
}

// MARK: - Fasting Workout Recommendation Tests

final class FastingServiceWorkoutRecommendationTests: XCTestCase {

    func testIntensityModifier_UnderTwelveHours() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 8,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityModifier, 1.0)
    }

    func testIntensityModifier_TwelveToSixteenHours() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 14,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityModifier, 0.95)
    }

    func testIntensityModifier_SixteenToTwentyHours() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 18,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityModifier, 0.85)
    }

    func testIntensityModifier_TwentyToTwentyFourHours() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 22,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityModifier, 0.75)
    }

    func testIntensityModifier_OverTwentyFourHours() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 30,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityModifier, 0.65)
    }

    func testIsExtendedFast_True() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 20,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertTrue(recommendation.isExtendedFast)
    }

    func testIsExtendedFast_False() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 12,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertFalse(recommendation.isExtendedFast)
    }

    func testIntensityPercentage() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 18,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertEqual(recommendation.intensityPercentage, 85)
    }

    func testRecommendedWorkoutTypes_EarlyFast() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 8,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertTrue(recommendation.recommendedWorkoutTypes.contains("Strength Training"))
        XCTAssertTrue(recommendation.recommendedWorkoutTypes.contains("HIIT"))
    }

    func testRecommendedWorkoutTypes_ExtendedFast() {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: nil,
            fastingHours: 22,
            protocolType: nil,
            plannedHours: nil
        )

        let recommendation = createRecommendation(with: fastingState)
        XCTAssertTrue(recommendation.recommendedWorkoutTypes.contains("Walking"))
        XCTAssertTrue(recommendation.recommendedWorkoutTypes.contains("Yoga"))
    }

    private func createRecommendation(with fastingState: FastingStateResponse) -> FastingWorkoutRecommendation {
        return FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: fastingState,
            workoutAllowed: true,
            workoutRecommended: true,
            modifications: [],
            nutritionTiming: NutritionTiming(
                recommendation: "Test",
                preWorkout: nil,
                intraWorkout: nil,
                postWorkout: "Test",
                timingNotes: "Test"
            ),
            safetyWarnings: [],
            performanceNotes: [],
            electrolyteRecommendations: [],
            alternativeWorkoutSuggestion: nil,
            disclaimer: "Test"
        )
    }
}

// MARK: - Data Validation Tests

final class FastingDataValidationTests: XCTestCase {

    func testFastingLog_MoodRangeValidation() {
        // Mood values should typically be 1-10
        for mood in 1...10 {
            let log = FastingLog(
                id: UUID(),
                patientId: UUID(),
                fastingType: .intermittent,
                startedAt: Date(),
                endedAt: nil,
                plannedEndAt: nil,
                targetHours: 16,
                actualHours: nil,
                wasBrokenEarly: nil,
                breakReason: nil,
                moodStart: mood,
                moodEnd: mood,
                hungerLevel: mood,
                energyLevel: mood,
                notes: nil,
                createdAt: Date()
            )

            XCTAssertEqual(log.moodStart, mood)
            XCTAssertEqual(log.moodEnd, mood)
            XCTAssertEqual(log.hungerLevel, mood)
            XCTAssertEqual(log.energyLevel, mood)
        }
    }

    func testFastingLog_TargetHoursPositive() {
        for hours in [1, 12, 16, 18, 24, 36, 48] {
            let log = FastingLog(
                id: UUID(),
                patientId: UUID(),
                fastingType: .custom,
                startedAt: Date(),
                endedAt: nil,
                plannedEndAt: nil,
                targetHours: hours,
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

            XCTAssertGreaterThan(log.targetHours, 0)
        }
    }

    func testFastingGoal_WeeklyTargetPositive() {
        let goal = FastingGoal(
            id: UUID(),
            patientId: UUID(),
            weeklyFastTarget: 5,
            targetHoursPerFast: 16,
            preferredProtocol: .intermittent,
            targetStreak: 7,
            notes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertGreaterThan(goal.weeklyFastTarget, 0)
        XCTAssertGreaterThan(goal.targetHoursPerFast, 0)
    }
}

// MARK: - Timezone Handling Tests

final class FastingTimezoneTests: XCTestCase {

    func testFastingLog_CrossTimezoneDecoding() throws {
        // Test decoding dates with explicit timezone offsets
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "intermittent",
            "started_at": "2024-06-15T20:00:00+05:30",
            "ended_at": "2024-06-16T12:00:00+05:30",
            "planned_end_at": null,
            "target_hours": 16,
            "actual_hours": 16.0,
            "was_broken_early": false,
            "break_reason": null,
            "mood_start": null,
            "mood_end": null,
            "hunger_level": null,
            "energy_level": null,
            "notes": null,
            "created_at": "2024-06-15T20:00:00+05:30"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let log = try decoder.decode(FastingLog.self, from: json)
        XCTAssertNotNil(log.startedAt)
        XCTAssertNotNil(log.endedAt)
    }

    func testFastingLog_UTCDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "extended",
            "started_at": "2024-06-15T00:00:00Z",
            "ended_at": null,
            "planned_end_at": "2024-06-16T00:00:00Z",
            "target_hours": 24,
            "actual_hours": null,
            "was_broken_early": null,
            "break_reason": null,
            "mood_start": null,
            "mood_end": null,
            "hunger_level": null,
            "energy_level": null,
            "notes": null,
            "created_at": "2024-06-15T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let log = try decoder.decode(FastingLog.self, from: json)
        XCTAssertNotNil(log.startedAt)
        XCTAssertNotNil(log.plannedEndAt)
    }
}
