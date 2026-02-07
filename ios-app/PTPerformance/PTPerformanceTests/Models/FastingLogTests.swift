//
//  FastingLogTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for FastingLog, FastingType, EatingWindowRecommendation, FastingStats,
//  FastingProtocol, FastingStreak, FastingGoal, FastingWeeklyStats, FastingPhase, and FastCompletionResult models
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

    func testFastingLogInitializationWithPlannedEndAt() {
        let startedAt = Date()
        let plannedEndAt = Calendar.current.date(byAdding: .hour, value: 16, to: startedAt)

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: nil,
            plannedEndAt: plannedEndAt,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: 7,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(log.plannedEndAt, plannedEndAt)
        XCTAssertEqual(log.moodStart, 7)
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

    // MARK: - State Transition Tests

    func testFastingLog_StateTransition_PlannedToActive() {
        // Given: A planned fast that hasn't started yet (in the future)
        let futureStart = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let plannedEnd = Calendar.current.date(byAdding: .hour, value: 17, to: Date())!

        let plannedLog = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: futureStart,
            endedAt: nil,
            plannedEndAt: plannedEnd,
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

        // Then: It should be active (no end date)
        XCTAssertTrue(plannedLog.isActive)
        XCTAssertNil(plannedLog.endedAt)
    }

    func testFastingLog_StateTransition_ActiveToCompleted() {
        // Given: An active fast that gets completed
        let startedAt = Date().addingTimeInterval(-16 * 3600)
        let endedAt = Date()

        let completedLog = FastingLog(
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
            moodStart: 6,
            moodEnd: 8,
            hungerLevel: 5,
            energyLevel: 7,
            notes: "Completed successfully",
            createdAt: startedAt
        )

        // Then: It should no longer be active
        XCTAssertFalse(completedLog.isActive)
        XCTAssertNotNil(completedLog.endedAt)
        XCTAssertEqual(completedLog.wasBrokenEarly, false)
        XCTAssertEqual(completedLog.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_StateTransition_ActiveToBrokenEarly() {
        // Given: An active fast that gets broken early
        let startedAt = Date().addingTimeInterval(-8 * 3600)
        let endedAt = Date()

        let brokenLog = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 8.0,
            wasBrokenEarly: true,
            breakReason: "Had to eat for social event",
            moodStart: 7,
            moodEnd: 5,
            hungerLevel: 8,
            energyLevel: 4,
            notes: "Broke fast early due to dinner plans",
            createdAt: startedAt
        )

        // Then: It should be marked as broken early
        XCTAssertFalse(brokenLog.isActive)
        XCTAssertEqual(brokenLog.wasBrokenEarly, true)
        XCTAssertEqual(brokenLog.breakReason, "Had to eat for social event")
        XCTAssertEqual(brokenLog.progressPercent, 0.5, accuracy: 0.01)
    }

    // MARK: - Extended FastingLog Property Tests

    func testFastingLog_ElapsedHours_ActiveFast() {
        let startedAt = Date().addingTimeInterval(-8 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertEqual(log.elapsedHours, 8.0, accuracy: 0.1)
    }

    func testFastingLog_ElapsedHours_CompletedFast() {
        let startedAt = Date().addingTimeInterval(-20 * 3600)
        let endedAt = Date().addingTimeInterval(-4 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: endedAt, targetHours: 16)

        XCTAssertEqual(log.elapsedHours, 16.0, accuracy: 0.1)
    }

    func testFastingLog_RemainingHours_ActiveFast() {
        let startedAt = Date().addingTimeInterval(-8 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertEqual(log.remainingHours, 8.0, accuracy: 0.1)
    }

    func testFastingLog_RemainingHours_ExceededTarget() {
        let startedAt = Date().addingTimeInterval(-20 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertEqual(log.remainingHours, 0.0)
    }

    func testFastingLog_FormattedElapsed() {
        let startedAt = Date().addingTimeInterval(-5.5 * 3600) // 5 hours 30 minutes
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        let formatted = log.formattedElapsed
        XCTAssertTrue(formatted.contains("h"))
        XCTAssertTrue(formatted.contains("m"))
    }

    func testFastingLog_ReachedTarget_True() {
        let startedAt = Date().addingTimeInterval(-18 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertTrue(log.reachedTarget)
    }

    func testFastingLog_ReachedTarget_False() {
        let startedAt = Date().addingTimeInterval(-8 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertFalse(log.reachedTarget)
    }

    func testFastingLog_CurrentPhase_FatBurning() {
        let startedAt = Date().addingTimeInterval(-8 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertEqual(log.currentPhase, .fatBurning)
    }

    func testFastingLog_CurrentPhase_Ketosis() {
        let startedAt = Date().addingTimeInterval(-18 * 3600)
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 24)

        XCTAssertEqual(log.currentPhase, .ketosis)
    }

    func testFastingLog_BackwardCompatibility_StartTime() {
        let startedAt = Date()
        let log = createFastingLog(startedAt: startedAt, endedAt: nil, targetHours: 16)

        XCTAssertEqual(log.startTime, startedAt)
        XCTAssertEqual(log.startTime, log.startedAt)
    }

    func testFastingLog_BackwardCompatibility_EndTime() {
        let endedAt = Date()
        let log = createFastingLog(startedAt: Date().addingTimeInterval(-16 * 3600), endedAt: endedAt, targetHours: 16)

        XCTAssertEqual(log.endTime, endedAt)
        XCTAssertEqual(log.endTime, log.endedAt)
    }

    // MARK: - FastingPhase Tests

    func testFastingPhase_FromHours_Fed() {
        XCTAssertEqual(FastingPhase.fromHours(0.3), .fed)
    }

    func testFastingPhase_FromHours_EarlyFast() {
        XCTAssertEqual(FastingPhase.fromHours(2), .earlyFast)
    }

    func testFastingPhase_FromHours_FatBurning() {
        XCTAssertEqual(FastingPhase.fromHours(10), .fatBurning)
    }

    func testFastingPhase_FromHours_Ketosis() {
        XCTAssertEqual(FastingPhase.fromHours(20), .ketosis)
    }

    func testFastingPhase_FromHours_DeepKetosis() {
        XCTAssertEqual(FastingPhase.fromHours(36), .deepKetosis)
    }

    func testFastingPhase_FromHours_Autophagy() {
        XCTAssertEqual(FastingPhase.fromHours(50), .autophagy)
    }

    func testFastingPhase_AllPhasesHaveDisplayNames() {
        let phases: [FastingPhase] = [.fed, .earlyFast, .fatBurning, .ketosis, .deepKetosis, .autophagy]
        for phase in phases {
            XCTAssertFalse(phase.displayName.isEmpty)
        }
    }

    func testFastingPhase_AllPhasesHaveDescriptions() {
        let phases: [FastingPhase] = [.fed, .earlyFast, .fatBurning, .ketosis, .deepKetosis, .autophagy]
        for phase in phases {
            XCTAssertFalse(phase.description.isEmpty)
        }
    }

    func testFastingPhase_AllPhasesHaveIcons() {
        let phases: [FastingPhase] = [.fed, .earlyFast, .fatBurning, .ketosis, .deepKetosis, .autophagy]
        for phase in phases {
            XCTAssertFalse(phase.icon.isEmpty)
        }
    }

    // MARK: - FastingProtocol Tests

    func testFastingProtocol_FormattedSchedule() {
        let proto = FastingProtocol(
            id: UUID(),
            name: "16:8 Intermittent",
            fastingType: .intermittent,
            fastingHours: 16,
            eatingHours: 8,
            description: "Standard IF protocol",
            benefits: ["Weight loss", "Improved insulin sensitivity"],
            difficulty: .beginner,
            isActive: true,
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertEqual(proto.formattedSchedule, "16:8")
    }

    // MARK: - FastingDifficulty Tests

    func testFastingDifficulty_AllCasesHaveDisplayNames() {
        for difficulty in FastingDifficulty.allCases {
            XCTAssertFalse(difficulty.displayName.isEmpty)
            XCTAssertEqual(difficulty.displayName, difficulty.rawValue.capitalized)
        }
    }

    func testFastingDifficulty_AllCasesHaveColors() {
        for difficulty in FastingDifficulty.allCases {
            XCTAssertFalse(difficulty.color.isEmpty)
        }
    }

    // MARK: - FastingStreak Tests

    func testFastingStreak_AverageFastDuration() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 5,
            longestStreak: 10,
            totalFasts: 20,
            totalHoursFasted: 320.0,
            lastFastDate: Date(),
            streakStartDate: Date().addingTimeInterval(-5 * 24 * 3600),
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertEqual(streak.averageFastDuration, 16.0, accuracy: 0.01)
    }

    func testFastingStreak_AverageFastDuration_NoFasts() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 0,
            longestStreak: 0,
            totalFasts: 0,
            totalHoursFasted: 0,
            lastFastDate: nil,
            streakStartDate: nil,
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertEqual(streak.averageFastDuration, 0.0)
    }

    func testFastingStreak_IsStreakAtRisk_NoLastDate() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 5,
            longestStreak: 10,
            totalFasts: 20,
            totalHoursFasted: 320.0,
            lastFastDate: nil,
            streakStartDate: nil,
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertTrue(streak.isStreakAtRisk)
    }

    func testFastingStreak_IsStreakAtRisk_RecentFast() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 5,
            longestStreak: 10,
            totalFasts: 20,
            totalHoursFasted: 320.0,
            lastFastDate: Date().addingTimeInterval(-12 * 3600), // 12 hours ago
            streakStartDate: Date().addingTimeInterval(-5 * 24 * 3600),
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertFalse(streak.isStreakAtRisk)
    }

    func testFastingStreak_IsStreakAtRisk_OldFast() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 5,
            longestStreak: 10,
            totalFasts: 20,
            totalHoursFasted: 320.0,
            lastFastDate: Date().addingTimeInterval(-40 * 3600), // 40 hours ago
            streakStartDate: Date().addingTimeInterval(-5 * 24 * 3600),
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertTrue(streak.isStreakAtRisk)
    }

    func testFastingStreak_DaysSinceLastFast() {
        let streak = FastingStreak(
            id: UUID(),
            patientId: UUID(),
            currentStreak: 5,
            longestStreak: 10,
            totalFasts: 20,
            totalHoursFasted: 320.0,
            lastFastDate: Date().addingTimeInterval(-2 * 24 * 3600), // 2 days ago
            streakStartDate: Date().addingTimeInterval(-5 * 24 * 3600),
            createdAt: Date(),
            updatedAt: nil
        )

        XCTAssertEqual(streak.daysSinceLastFast, 2)
    }

    // MARK: - FastingWeeklyStats Tests

    func testFastingWeeklyStats_FormattedCompliance() {
        let stats = FastingWeeklyStats(
            weekStartDate: Date(),
            totalFasts: 5,
            completedFasts: 4,
            totalHoursFasted: 64.0,
            averageFastDuration: 16.0,
            longestFast: 20.0,
            shortestFast: 14.0,
            complianceRate: 0.85,
            fastsPerDay: [:]
        )

        XCTAssertEqual(stats.formattedCompliance, "85%")
    }

    func testFastingWeeklyStats_IsOnTrack_True() {
        let stats = FastingWeeklyStats(
            weekStartDate: Date(),
            totalFasts: 5,
            completedFasts: 5,
            totalHoursFasted: 80.0,
            averageFastDuration: 16.0,
            longestFast: 20.0,
            shortestFast: 14.0,
            complianceRate: 0.90,
            fastsPerDay: [:]
        )

        XCTAssertTrue(stats.isOnTrack)
    }

    func testFastingWeeklyStats_IsOnTrack_False() {
        let stats = FastingWeeklyStats(
            weekStartDate: Date(),
            totalFasts: 3,
            completedFasts: 2,
            totalHoursFasted: 32.0,
            averageFastDuration: 16.0,
            longestFast: 18.0,
            shortestFast: 14.0,
            complianceRate: 0.50,
            fastsPerDay: [:]
        )

        XCTAssertFalse(stats.isOnTrack)
    }

    func testFastingWeeklyStats_Empty() {
        let empty = FastingWeeklyStats.empty()

        XCTAssertEqual(empty.totalFasts, 0)
        XCTAssertEqual(empty.completedFasts, 0)
        XCTAssertEqual(empty.totalHoursFasted, 0)
        XCTAssertEqual(empty.complianceRate, 0)
    }

    // MARK: - FastCompletionResult Tests

    func testFastCompletionResult_CompletionPercentage_Full() {
        let result = FastCompletionResult(
            fastId: UUID(),
            wasCompleted: true,
            actualHours: 16.0,
            targetHours: 16,
            streakUpdated: true,
            newStreakCount: 5,
            isPersonalBest: false
        )

        XCTAssertEqual(result.completionPercentage, 1.0, accuracy: 0.01)
    }

    func testFastCompletionResult_CompletionPercentage_Partial() {
        let result = FastCompletionResult(
            fastId: UUID(),
            wasCompleted: false,
            actualHours: 12.0,
            targetHours: 16,
            streakUpdated: false,
            newStreakCount: nil,
            isPersonalBest: false
        )

        XCTAssertEqual(result.completionPercentage, 0.75, accuracy: 0.01)
    }

    func testFastCompletionResult_CompletionPercentage_Exceeded() {
        let result = FastCompletionResult(
            fastId: UUID(),
            wasCompleted: true,
            actualHours: 20.0,
            targetHours: 16,
            streakUpdated: true,
            newStreakCount: 6,
            isPersonalBest: true
        )

        // Capped at 1.0
        XCTAssertEqual(result.completionPercentage, 1.0, accuracy: 0.01)
    }

    // MARK: - EatingWindowRecommendation Extended Tests

    func testEatingWindowRecommendation_WindowDuration() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .hour, value: 8, to: start)!

        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: start,
            suggestedEnd: end,
            reason: "Test",
            trainingTime: nil,
            confidence: 0.8
        )

        XCTAssertEqual(recommendation.windowDuration, 8.0, accuracy: 0.01)
    }

    func testEatingWindowRecommendation_FormattedWindow() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date().addingTimeInterval(8 * 3600),
            reason: "Test",
            trainingTime: nil,
            confidence: 0.8
        )

        XCTAssertTrue(recommendation.formattedWindow.contains(" - "))
    }

    // MARK: - FastingType Extended Tests

    func testFastingType_AllCasesHaveIcons() {
        for type in FastingType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testFastingType_AllCasesHaveProtocolDescriptions() {
        for type in FastingType.allCases {
            XCTAssertFalse(type.protocolDescription.isEmpty)
        }
    }

    func testFastingType_AllCasesHaveDifficulty() {
        for type in FastingType.allCases {
            XCTAssertNotNil(type.difficulty)
        }
    }

    func testFastingType_DifficultyProgression() {
        // Extended fasts should be more difficult than intermittent
        XCTAssertTrue(FastingType.extended.difficulty.rawValue > FastingType.intermittent.difficulty.rawValue ||
                      FastingType.extended.difficulty == .advanced)
    }

    // MARK: - Timezone Handling Tests

    func testFastingLog_TimezoneHandling_Encoding() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 20
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/New_York")

        let startedAt = calendar.date(from: components)!

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

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Should not throw
        let data = try encoder.encode(log)
        XCTAssertNotNil(data)
    }

    func testFastingLog_TimezoneHandling_Decoding() throws {
        // JSON with dates in different timezone format
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "fasting_type": "intermittent",
            "started_at": "2024-06-15T20:00:00-04:00",
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
            "created_at": "2024-06-15T20:00:00-04:00"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let log = try decoder.decode(FastingLog.self, from: json)
        XCTAssertNotNil(log.startedAt)
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

    private func createFastingLog(startedAt: Date, endedAt: Date?, targetHours: Int) -> FastingLog {
        FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedEndAt: nil,
            targetHours: targetHours,
            actualHours: endedAt != nil ? endedAt!.timeIntervalSince(startedAt) / 3600 : nil,
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
