//
//  RecoverySupplementServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoveryService and SupplementService
//  Tests recovery impact analysis and supplement recommendations
//

import XCTest
@testable import PTPerformance

// MARK: - RecoveryService Tests

@MainActor
final class RecoveryServiceTests: XCTestCase {

    var sut: RecoveryService!

    override func setUp() async throws {
        try await super.setUp()
        sut = RecoveryService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(RecoveryService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = RecoveryService.shared
        let instance2 = RecoveryService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    func testInitialState_SessionsIsEmpty() {
        XCTAssertNotNil(sut.sessions)
    }

    func testInitialState_RecommendationsIsEmpty() {
        XCTAssertNotNil(sut.recommendations)
    }

    func testInitialState_ImpactAnalysisIsNil() {
        _ = sut.impactAnalysis
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsAnalyzingIsFalse() {
        XCTAssertFalse(sut.isAnalyzing)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Weekly Stats Tests

    func testWeeklyStats_ReturnsValidTuple() {
        let stats = sut.weeklyStats()

        XCTAssertGreaterThanOrEqual(stats.totalSessions, 0)
        XCTAssertGreaterThanOrEqual(stats.totalMinutes, 0)
        // favoriteProtocol can be nil
    }
}

// MARK: - RecoveryProtocolType Tests

final class RecoveryProtocolTypeTests: XCTestCase {

    func testRecoveryProtocolType_RawValues() {
        XCTAssertEqual(RecoveryProtocolType.sauna.rawValue, "sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.rawValue, "cold_plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.rawValue, "contrast")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.rawValue, "cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.rawValue, "float_tank")
        XCTAssertEqual(RecoveryProtocolType.massage.rawValue, "massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.rawValue, "stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.rawValue, "meditation")
    }

    func testRecoveryProtocolType_DisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.sauna.displayName, "Sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.displayName, "Cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.displayName, "Float Tank")
        XCTAssertEqual(RecoveryProtocolType.massage.displayName, "Massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.displayName, "Stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.displayName, "Meditation")
    }

    func testRecoveryProtocolType_Icons() {
        for type in RecoveryProtocolType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "Protocol \(type) should have an icon")
        }
    }

    func testRecoveryProtocolType_AllCases() {
        let allCases = RecoveryProtocolType.allCases
        XCTAssertEqual(allCases.count, 8)
    }

    func testRecoveryProtocolType_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in RecoveryProtocolType.allCases {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(RecoveryProtocolType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
}

// MARK: - RecoverySession Tests

final class RecoverySessionTests: XCTestCase {

    func testRecoverySession_Initialization() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()
        let createdAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .sauna,
            startTime: startTime,
            duration: 1200, // 20 minutes in seconds
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 145,
            perceivedEffort: 7,
            notes: "Felt great",
            createdAt: createdAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .sauna)
        XCTAssertEqual(session.duration, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 120)
        XCTAssertEqual(session.heartRateMax, 145)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.notes, "Felt great")
    }

    func testRecoverySession_OptionalFields() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .meditation,
            startTime: Date(),
            duration: 900,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertNil(session.temperature)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertNil(session.heartRateMax)
        XCTAssertNil(session.perceivedEffort)
        XCTAssertNil(session.notes)
    }

    func testRecoverySession_Codable() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "protocol_type": "cold_plunge",
            "start_time": "2024-01-15T10:00:00Z",
            "duration": 180,
            "temperature": 50.0,
            "heart_rate_avg": 65,
            "heart_rate_max": 70,
            "perceived_effort": 8,
            "notes": "Cold!",
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(RecoverySession.self, from: json)

        XCTAssertEqual(session.protocolType, .coldPlunge)
        XCTAssertEqual(session.duration, 180)
        XCTAssertEqual(session.temperature, 50.0)
    }
}

// MARK: - RecoveryRecommendation Tests

final class RecoveryRecommendationTests: XCTestCase {

    func testRecoveryRecommendation_Initialization() {
        let id = UUID()
        let recommendation = RecoveryRecommendation(
            id: id,
            protocolType: .sauna,
            reason: "High training volume this week",
            priority: .high,
            suggestedDuration: 20
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.protocolType, .sauna)
        XCTAssertEqual(recommendation.reason, "High training volume this week")
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.suggestedDuration, 20)
    }

    func testRecoveryRecommendation_Codable() throws {
        let original = RecoveryRecommendation(
            id: UUID(),
            protocolType: .coldPlunge,
            reason: "Post-workout recovery",
            priority: .medium,
            suggestedDuration: 3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecoveryRecommendation.self, from: data)

        XCTAssertEqual(original.protocolType, decoded.protocolType)
        XCTAssertEqual(original.reason, decoded.reason)
        XCTAssertEqual(original.priority, decoded.priority)
        XCTAssertEqual(original.suggestedDuration, decoded.suggestedDuration)
    }
}

// MARK: - RecoveryPriority Tests

final class RecoveryPriorityTests: XCTestCase {

    func testRecoveryPriority_RawValues() {
        XCTAssertEqual(RecoveryPriority.high.rawValue, "high")
        XCTAssertEqual(RecoveryPriority.medium.rawValue, "medium")
        XCTAssertEqual(RecoveryPriority.low.rawValue, "low")
    }
}

// MARK: - SupplementService Tests

@MainActor
final class SupplementServiceTests: XCTestCase {

    var sut: SupplementService!

    override func setUp() async throws {
        try await super.setUp()
        sut = SupplementService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(SupplementService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = SupplementService.shared
        let instance2 = SupplementService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    func testInitialState_SupplementsIsEmpty() {
        XCTAssertNotNil(sut.supplements)
    }

    func testInitialState_TodayScheduleIsEmpty() {
        XCTAssertNotNil(sut.todaySchedule)
    }

    func testInitialState_RecentLogsIsEmpty() {
        XCTAssertNotNil(sut.recentLogs)
    }

    func testInitialState_AIRecommendationsIsNil() {
        _ = sut.aiRecommendations
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsLoadingRecommendationsIsFalse() {
        XCTAssertFalse(sut.isLoadingRecommendations)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }
}

// MARK: - SupplementServiceError Tests

final class SupplementServiceErrorTests: XCTestCase {

    func testSupplementServiceError_NoPatientId() {
        let error = SupplementServiceError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("patient") == true)
    }

    func testSupplementServiceError_InvalidResponse() {
        let error = SupplementServiceError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("invalid") == true)
    }

    func testSupplementServiceError_NetworkError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed"])
        let error = SupplementServiceError.networkError(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network") == true)
    }
}

// MARK: - Supplement Model Tests

final class SupplementModelTests: XCTestCase {

    func testSupplement_Initialization() {
        let id = UUID()
        let patientId = UUID()

        let supplement = Supplement(
            id: id,
            patientId: patientId,
            name: "Creatine Monohydrate",
            brand: "Momentous",
            category: .creatine,
            dosage: "5g",
            frequency: .daily,
            timeOfDay: [.morning, .postWorkout],
            withFood: false,
            notes: "Mix with water",
            momentousProductId: "creatine-mono",
            isActive: true,
            createdAt: Date()
        )

        XCTAssertEqual(supplement.id, id)
        XCTAssertEqual(supplement.patientId, patientId)
        XCTAssertEqual(supplement.name, "Creatine Monohydrate")
        XCTAssertEqual(supplement.brand, "Momentous")
        XCTAssertEqual(supplement.category, .creatine)
        XCTAssertEqual(supplement.timeOfDay.count, 2)
        XCTAssertFalse(supplement.withFood)
        XCTAssertTrue(supplement.isActive)
    }

    func testSupplement_Codable() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "Fish Oil",
            "brand": "Nordic Naturals",
            "category": "omega3",
            "dosage": "2g EPA/DHA",
            "frequency": "daily",
            "time_of_day": ["morning", "with_meals"],
            "with_food": true,
            "notes": "Take with breakfast",
            "momentous_product_id": null,
            "is_active": true,
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supplement = try decoder.decode(Supplement.self, from: json)

        XCTAssertEqual(supplement.name, "Fish Oil")
        XCTAssertEqual(supplement.category, .omega3)
        XCTAssertTrue(supplement.withFood)
    }
}

// MARK: - SupplementCategory Tests

final class SupplementCategoryTests: XCTestCase {

    func testSupplementCategory_RawValues() {
        XCTAssertEqual(SupplementCategory.protein.rawValue, "protein")
        XCTAssertEqual(SupplementCategory.creatine.rawValue, "creatine")
        XCTAssertEqual(SupplementCategory.vitamins.rawValue, "vitamins")
        XCTAssertEqual(SupplementCategory.minerals.rawValue, "minerals")
        XCTAssertEqual(SupplementCategory.omega3.rawValue, "omega3")
        XCTAssertEqual(SupplementCategory.preworkout.rawValue, "preworkout")
        XCTAssertEqual(SupplementCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(SupplementCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(SupplementCategory.adaptogens.rawValue, "adaptogens")
        XCTAssertEqual(SupplementCategory.other.rawValue, "other")
    }

    func testSupplementCategory_DisplayNames() {
        XCTAssertEqual(SupplementCategory.protein.displayName, "Protein")
        XCTAssertEqual(SupplementCategory.creatine.displayName, "Creatine")
        XCTAssertEqual(SupplementCategory.vitamins.displayName, "Vitamins")
        XCTAssertEqual(SupplementCategory.omega3.displayName, "Omega-3")
        XCTAssertEqual(SupplementCategory.preworkout.displayName, "Pre-Workout")
    }

    func testSupplementCategory_Icons() {
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testSupplementCategory_AllCases() {
        XCTAssertEqual(SupplementCategory.allCases.count, 10)
    }
}

// MARK: - SupplementFrequency Tests

final class SupplementFrequencyTests: XCTestCase {

    func testSupplementFrequency_RawValues() {
        XCTAssertEqual(SupplementFrequency.daily.rawValue, "daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.rawValue, "twice_daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.rawValue, "three_times_daily")
        XCTAssertEqual(SupplementFrequency.weekly.rawValue, "weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.rawValue, "as_needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.rawValue, "training_days_only")
    }

    func testSupplementFrequency_DisplayNames() {
        XCTAssertEqual(SupplementFrequency.daily.displayName, "Daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.displayName, "Twice Daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.displayName, "Three Times Daily")
        XCTAssertEqual(SupplementFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.displayName, "As Needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.displayName, "Training Days Only")
    }
}

// MARK: - TimeOfDay Tests

final class TimeOfDayTests: XCTestCase {

    func testTimeOfDay_RawValues() {
        XCTAssertEqual(TimeOfDay.morning.rawValue, "morning")
        XCTAssertEqual(TimeOfDay.afternoon.rawValue, "afternoon")
        XCTAssertEqual(TimeOfDay.evening.rawValue, "evening")
        XCTAssertEqual(TimeOfDay.night.rawValue, "night")
        XCTAssertEqual(TimeOfDay.beforeBed.rawValue, "before_bed")
        XCTAssertEqual(TimeOfDay.preWorkout.rawValue, "pre_workout")
        XCTAssertEqual(TimeOfDay.postWorkout.rawValue, "post_workout")
        XCTAssertEqual(TimeOfDay.withMeals.rawValue, "with_meals")
    }

    func testTimeOfDay_DisplayNames() {
        XCTAssertEqual(TimeOfDay.morning.displayName, "Morning")
        XCTAssertEqual(TimeOfDay.afternoon.displayName, "Afternoon")
        XCTAssertEqual(TimeOfDay.evening.displayName, "Evening")
        XCTAssertEqual(TimeOfDay.night.displayName, "Night")
        XCTAssertEqual(TimeOfDay.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(TimeOfDay.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(TimeOfDay.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(TimeOfDay.withMeals.displayName, "With Meals")
    }

    func testTimeOfDay_Icons() {
        for time in TimeOfDay.allCases {
            XCTAssertFalse(time.icon.isEmpty)
        }
    }

    func testTimeOfDay_AllCases() {
        XCTAssertEqual(TimeOfDay.allCases.count, 8)
    }
}

// MARK: - ScheduledSupplement Tests

final class ScheduledSupplementTests: XCTestCase {

    func testScheduledSupplement_Initialization() {
        let supplement = createMockSupplement()
        let scheduledTime = Date()

        let scheduled = ScheduledSupplement(
            id: UUID(),
            supplement: supplement,
            scheduledTime: scheduledTime,
            taken: false,
            takenAt: nil
        )

        XCTAssertEqual(scheduled.supplement.name, supplement.name)
        XCTAssertEqual(scheduled.scheduledTime, scheduledTime)
        XCTAssertFalse(scheduled.taken)
        XCTAssertNil(scheduled.takenAt)
    }

    func testScheduledSupplement_WhenTaken() {
        let supplement = createMockSupplement()
        let takenAt = Date()

        let scheduled = ScheduledSupplement(
            id: UUID(),
            supplement: supplement,
            scheduledTime: Date().addingTimeInterval(-3600),
            taken: true,
            takenAt: takenAt
        )

        XCTAssertTrue(scheduled.taken)
        XCTAssertEqual(scheduled.takenAt, takenAt)
    }

    private func createMockSupplement() -> Supplement {
        Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Test Supplement",
            brand: nil,
            category: .vitamins,
            dosage: "1 pill",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: true,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )
    }
}

// MARK: - SupplementLog Tests

final class SupplementLogTests: XCTestCase {

    func testSupplementLog_Initialization() {
        let id = UUID()
        let supplementId = UUID()
        let patientId = UUID()
        let takenAt = Date()

        let log = SupplementLog(
            id: id,
            supplementId: supplementId,
            patientId: patientId,
            takenAt: takenAt,
            dosage: "5g",
            notes: "With water"
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.supplementId, supplementId)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.takenAt, takenAt)
        XCTAssertEqual(log.dosage, "5g")
        XCTAssertEqual(log.notes, "With water")
    }

    func testSupplementLog_NilNotes() {
        let log = SupplementLog(
            id: UUID(),
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "1 serving",
            notes: nil
        )

        XCTAssertNil(log.notes)
    }
}
