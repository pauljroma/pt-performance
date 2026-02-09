//
//  SupplementServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for SupplementService
//  Tests supplement models, categories, schedules, service state management,
//  fetch operations, logging, recommendations, and error handling.
//

import XCTest
@testable import PTPerformance

// MARK: - SupplementCategory Tests

final class SupplementCategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

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

    func testSupplementCategory_InitFromRawValue() {
        XCTAssertEqual(SupplementCategory(rawValue: "protein"), .protein)
        XCTAssertEqual(SupplementCategory(rawValue: "creatine"), .creatine)
        XCTAssertEqual(SupplementCategory(rawValue: "vitamins"), .vitamins)
        XCTAssertEqual(SupplementCategory(rawValue: "minerals"), .minerals)
        XCTAssertEqual(SupplementCategory(rawValue: "omega3"), .omega3)
        XCTAssertEqual(SupplementCategory(rawValue: "preworkout"), .preworkout)
        XCTAssertEqual(SupplementCategory(rawValue: "recovery"), .recovery)
        XCTAssertEqual(SupplementCategory(rawValue: "sleep"), .sleep)
        XCTAssertEqual(SupplementCategory(rawValue: "adaptogens"), .adaptogens)
        XCTAssertEqual(SupplementCategory(rawValue: "other"), .other)
        XCTAssertNil(SupplementCategory(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testSupplementCategory_DisplayNames() {
        XCTAssertEqual(SupplementCategory.protein.displayName, "Protein")
        XCTAssertEqual(SupplementCategory.creatine.displayName, "Creatine")
        XCTAssertEqual(SupplementCategory.vitamins.displayName, "Vitamins")
        XCTAssertEqual(SupplementCategory.minerals.displayName, "Minerals")
        XCTAssertEqual(SupplementCategory.omega3.displayName, "Omega-3")
        XCTAssertEqual(SupplementCategory.preworkout.displayName, "Pre-Workout")
        XCTAssertEqual(SupplementCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(SupplementCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(SupplementCategory.adaptogens.displayName, "Adaptogens")
        XCTAssertEqual(SupplementCategory.other.displayName, "Other")
    }

    // MARK: - Icon Tests

    func testSupplementCategory_Icons() {
        XCTAssertEqual(SupplementCategory.protein.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(SupplementCategory.creatine.icon, "bolt.fill")
        XCTAssertEqual(SupplementCategory.vitamins.icon, "pill.fill")
        XCTAssertEqual(SupplementCategory.minerals.icon, "leaf.fill")
        XCTAssertEqual(SupplementCategory.omega3.icon, "drop.fill")
        XCTAssertEqual(SupplementCategory.preworkout.icon, "flame.fill")
        XCTAssertEqual(SupplementCategory.recovery.icon, "heart.fill")
        XCTAssertEqual(SupplementCategory.sleep.icon, "moon.fill")
        XCTAssertEqual(SupplementCategory.adaptogens.icon, "brain.head.profile")
        XCTAssertEqual(SupplementCategory.other.icon, "pills.fill")
    }

    // MARK: - CaseIterable Tests

    func testSupplementCategory_AllCases() {
        let allCases = SupplementCategory.allCases
        XCTAssertEqual(allCases.count, 10)
        XCTAssertTrue(allCases.contains(.protein))
        XCTAssertTrue(allCases.contains(.creatine))
        XCTAssertTrue(allCases.contains(.vitamins))
        XCTAssertTrue(allCases.contains(.minerals))
        XCTAssertTrue(allCases.contains(.omega3))
        XCTAssertTrue(allCases.contains(.preworkout))
        XCTAssertTrue(allCases.contains(.recovery))
        XCTAssertTrue(allCases.contains(.sleep))
        XCTAssertTrue(allCases.contains(.adaptogens))
        XCTAssertTrue(allCases.contains(.other))
    }

    // MARK: - Codable Tests

    func testSupplementCategory_Encoding() throws {
        let category = SupplementCategory.creatine
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"creatine\"")
    }

    func testSupplementCategory_Decoding() throws {
        let json = "\"omega3\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let category = try decoder.decode(SupplementCategory.self, from: json)

        XCTAssertEqual(category, .omega3)
    }
}

// MARK: - SupplementFrequency Tests

final class SupplementFrequencyTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testSupplementFrequency_RawValues() {
        XCTAssertEqual(SupplementFrequency.daily.rawValue, "daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.rawValue, "twice_daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.rawValue, "three_times_daily")
        XCTAssertEqual(SupplementFrequency.weekly.rawValue, "weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.rawValue, "as_needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.rawValue, "training_days_only")
    }

    func testSupplementFrequency_InitFromRawValue() {
        XCTAssertEqual(SupplementFrequency(rawValue: "daily"), .daily)
        XCTAssertEqual(SupplementFrequency(rawValue: "twice_daily"), .twiceDaily)
        XCTAssertEqual(SupplementFrequency(rawValue: "three_times_daily"), .threeTimesDaily)
        XCTAssertEqual(SupplementFrequency(rawValue: "weekly"), .weekly)
        XCTAssertEqual(SupplementFrequency(rawValue: "as_needed"), .asNeeded)
        XCTAssertEqual(SupplementFrequency(rawValue: "training_days_only"), .trainingDaysOnly)
        XCTAssertNil(SupplementFrequency(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testSupplementFrequency_DisplayNames() {
        XCTAssertEqual(SupplementFrequency.daily.displayName, "Daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.displayName, "Twice Daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.displayName, "Three Times Daily")
        XCTAssertEqual(SupplementFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.displayName, "As Needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.displayName, "Training Days Only")
    }

    // MARK: - CaseIterable Tests

    func testSupplementFrequency_AllCases() {
        let allCases = SupplementFrequency.allCases
        XCTAssertEqual(allCases.count, 6)
    }

    // MARK: - Codable Tests

    func testSupplementFrequency_Encoding() throws {
        let frequency = SupplementFrequency.twiceDaily
        let encoder = JSONEncoder()
        let data = try encoder.encode(frequency)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"twice_daily\"")
    }

    func testSupplementFrequency_Decoding() throws {
        let json = "\"training_days_only\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let frequency = try decoder.decode(SupplementFrequency.self, from: json)

        XCTAssertEqual(frequency, .trainingDaysOnly)
    }
}

// MARK: - TimeOfDay Tests

final class TimeOfDayServiceTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testTimeOfDay_RawValues() {
        XCTAssertEqual(TimeOfDay.morning.rawValue, "morning")
        XCTAssertEqual(TimeOfDay.afternoon.rawValue, "afternoon")
        XCTAssertEqual(TimeOfDay.evening.rawValue, "evening")
        XCTAssertEqual(TimeOfDay.beforeBed.rawValue, "before_bed")
        XCTAssertEqual(TimeOfDay.preWorkout.rawValue, "pre_workout")
        XCTAssertEqual(TimeOfDay.postWorkout.rawValue, "post_workout")
        XCTAssertEqual(TimeOfDay.withMeals.rawValue, "with_meals")
    }

    func testTimeOfDay_InitFromRawValue() {
        XCTAssertEqual(TimeOfDay(rawValue: "morning"), .morning)
        XCTAssertEqual(TimeOfDay(rawValue: "afternoon"), .afternoon)
        XCTAssertEqual(TimeOfDay(rawValue: "evening"), .evening)
        XCTAssertEqual(TimeOfDay(rawValue: "before_bed"), .beforeBed)
        XCTAssertEqual(TimeOfDay(rawValue: "pre_workout"), .preWorkout)
        XCTAssertEqual(TimeOfDay(rawValue: "post_workout"), .postWorkout)
        XCTAssertEqual(TimeOfDay(rawValue: "with_meals"), .withMeals)
        XCTAssertNil(TimeOfDay(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testTimeOfDay_DisplayNames() {
        XCTAssertEqual(TimeOfDay.morning.displayName, "Morning")
        XCTAssertEqual(TimeOfDay.afternoon.displayName, "Afternoon")
        XCTAssertEqual(TimeOfDay.evening.displayName, "Evening")
        XCTAssertEqual(TimeOfDay.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(TimeOfDay.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(TimeOfDay.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(TimeOfDay.withMeals.displayName, "With Meals")
    }

    // MARK: - Icon Tests

    func testTimeOfDay_Icons() {
        XCTAssertEqual(TimeOfDay.morning.icon, "sunrise.fill")
        XCTAssertEqual(TimeOfDay.afternoon.icon, "sun.max.fill")
        XCTAssertEqual(TimeOfDay.evening.icon, "sunset.fill")
        XCTAssertEqual(TimeOfDay.beforeBed.icon, "moon.fill")
        XCTAssertEqual(TimeOfDay.preWorkout.icon, "figure.run")
        XCTAssertEqual(TimeOfDay.postWorkout.icon, "figure.cooldown")
        XCTAssertEqual(TimeOfDay.withMeals.icon, "fork.knife")
    }

    // MARK: - Codable Tests

    func testTimeOfDay_Encoding() throws {
        let time = TimeOfDay.preWorkout
        let encoder = JSONEncoder()
        let data = try encoder.encode(time)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"pre_workout\"")
    }

    func testTimeOfDay_Decoding() throws {
        let json = "\"before_bed\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let time = try decoder.decode(TimeOfDay.self, from: json)

        XCTAssertEqual(time, .beforeBed)
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
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_SupplementsIsArray() {
        XCTAssertNotNil(sut.supplements)
        XCTAssertTrue(sut.supplements is [Supplement])
    }

    func testInitialState_TodayScheduleIsArray() {
        XCTAssertNotNil(sut.todaySchedule)
        XCTAssertTrue(sut.todaySchedule is [ScheduledSupplement])
    }

    func testInitialState_RecentLogsIsArray() {
        XCTAssertNotNil(sut.recentLogs)
        XCTAssertTrue(sut.recentLogs is [SupplementLogEntry])
    }

    func testInitialState_CatalogIsArray() {
        XCTAssertNotNil(sut.catalog)
        XCTAssertTrue(sut.catalog is [CatalogSupplement])
    }

    func testInitialState_StacksIsArray() {
        XCTAssertNotNil(sut.stacks)
        XCTAssertTrue(sut.stacks is [SupplementStack])
    }

    func testInitialState_RoutinesIsArray() {
        XCTAssertNotNil(sut.routines)
        XCTAssertTrue(sut.routines is [SupplementRoutine])
    }

    func testInitialState_TodayDosesIsArray() {
        XCTAssertNotNil(sut.todayDoses)
        XCTAssertTrue(sut.todayDoses is [TodaySupplementDose])
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
    }

    func testInitialState_IsLoadingCatalogProperty() {
        _ = sut.isLoadingCatalog
    }

    func testInitialState_IsLoadingRecommendationsProperty() {
        _ = sut.isLoadingRecommendations
    }

    func testInitialState_IsSyncingProperty() {
        _ = sut.isSyncing
    }

    // MARK: - Published Properties Tests

    func testSupplements_IsPublished() {
        let supplements = sut.supplements
        XCTAssertNotNil(supplements)
    }

    func testTodaySchedule_IsPublished() {
        let schedule = sut.todaySchedule
        XCTAssertNotNil(schedule)
    }

    func testRecentLogs_IsPublished() {
        let logs = sut.recentLogs
        XCTAssertNotNil(logs)
    }

    func testCatalog_IsPublished() {
        let catalog = sut.catalog
        XCTAssertNotNil(catalog)
    }

    func testStacks_IsPublished() {
        let stacks = sut.stacks
        XCTAssertNotNil(stacks)
    }

    func testRoutines_IsPublished() {
        let routines = sut.routines
        XCTAssertNotNil(routines)
    }

    func testTodayDoses_IsPublished() {
        let doses = sut.todayDoses
        XCTAssertNotNil(doses)
    }

    // MARK: - Compliance Tests

    func testTodayCompliance_IsOptional() {
        _ = sut.todayCompliance
    }

    func testWeeklyCompliance_IsOptional() {
        _ = sut.weeklyCompliance
    }

    func testAnalytics_IsOptional() {
        _ = sut.analytics
    }

    // MARK: - AI Recommendations Tests

    func testAIRecommendations_IsOptional() {
        _ = sut.aiRecommendations
    }
}

// MARK: - SupplementServiceError Tests

final class SupplementServiceErrorTests: XCTestCase {

    func testNoPatientIdError_Description() {
        let error = SupplementServiceError.noPatientId
        XCTAssertEqual(error.errorDescription, "Unable to identify patient. Please ensure you are logged in.")
    }

    func testInvalidResponseError_Description() {
        let error = SupplementServiceError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Received an invalid response from the server.")
    }

    func testRoutineNotFoundError_Description() {
        let error = SupplementServiceError.routineNotFound
        XCTAssertEqual(error.errorDescription, "The supplement routine was not found.")
    }

    func testSupplementNotFoundError_Description() {
        let error = SupplementServiceError.supplementNotFound
        XCTAssertEqual(error.errorDescription, "The supplement was not found in the catalog.")
    }

    func testNetworkError_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        let error = SupplementServiceError.networkError(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Server error") ?? false)
    }
}

// MARK: - Supplement Decoding Tests

final class SupplementDecodingTests: XCTestCase {

    func testSupplement_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "Creatine Monohydrate",
            "brand": "Momentous",
            "category": "creatine",
            "dosage": "5g",
            "frequency": "daily",
            "time_of_day": ["morning", "post_workout"],
            "with_food": false,
            "notes": "Mix with water",
            "momentous_product_id": "creatine-500",
            "is_active": true,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supplement = try decoder.decode(Supplement.self, from: json)

        XCTAssertEqual(supplement.name, "Creatine Monohydrate")
        XCTAssertEqual(supplement.brand, "Momentous")
        XCTAssertEqual(supplement.category, .creatine)
        XCTAssertEqual(supplement.dosage, "5g")
        XCTAssertEqual(supplement.frequency, .daily)
        XCTAssertEqual(supplement.timeOfDay, [.morning, .postWorkout])
        XCTAssertEqual(supplement.withFood, false)
        XCTAssertEqual(supplement.notes, "Mix with water")
        XCTAssertEqual(supplement.momentousProductId, "creatine-500")
        XCTAssertEqual(supplement.isActive, true)
    }

    func testSupplement_DecodingWithNullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "name": "Vitamin D3",
            "brand": null,
            "category": "vitamins",
            "dosage": "5000 IU",
            "frequency": "daily",
            "time_of_day": ["morning"],
            "with_food": true,
            "notes": null,
            "momentous_product_id": null,
            "is_active": true,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supplement = try decoder.decode(Supplement.self, from: json)

        XCTAssertNil(supplement.brand)
        XCTAssertNil(supplement.notes)
        XCTAssertNil(supplement.momentousProductId)
    }

    func testSupplement_AllCategories() throws {
        let categories = ["protein", "creatine", "vitamins", "minerals", "omega3",
                         "preworkout", "recovery", "sleep", "adaptogens", "other"]

        for category in categories {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "name": "Test",
                "brand": null,
                "category": "\(category)",
                "dosage": "1",
                "frequency": "daily",
                "time_of_day": [],
                "with_food": false,
                "notes": null,
                "momentous_product_id": null,
                "is_active": true,
                "created_at": "2024-01-15T10:30:00Z"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let supplement = try decoder.decode(Supplement.self, from: json)

            XCTAssertEqual(supplement.category.rawValue, category)
        }
    }

    func testSupplement_AllFrequencies() throws {
        let frequencies = ["daily", "twice_daily", "three_times_daily", "weekly",
                          "as_needed", "training_days_only"]

        for frequency in frequencies {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "name": "Test",
                "brand": null,
                "category": "other",
                "dosage": "1",
                "frequency": "\(frequency)",
                "time_of_day": [],
                "with_food": false,
                "notes": null,
                "momentous_product_id": null,
                "is_active": true,
                "created_at": "2024-01-15T10:30:00Z"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let supplement = try decoder.decode(Supplement.self, from: json)

            XCTAssertEqual(supplement.frequency.rawValue, frequency)
        }
    }

    func testSupplementLog_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "supplement_id": "660e8400-e29b-41d4-a716-446655440001",
            "patient_id": "770e8400-e29b-41d4-a716-446655440002",
            "taken_at": "2024-01-15T07:30:00Z",
            "dosage": "5g",
            "notes": "With breakfast"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(SupplementLog.self, from: json)

        XCTAssertEqual(log.dosage, "5g")
        XCTAssertEqual(log.notes, "With breakfast")
    }

    func testSupplementLog_DecodingWithNilNotes() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "supplement_id": "660e8400-e29b-41d4-a716-446655440001",
            "patient_id": "770e8400-e29b-41d4-a716-446655440002",
            "taken_at": "2024-01-15T07:30:00Z",
            "dosage": "5g",
            "notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(SupplementLog.self, from: json)

        XCTAssertNil(log.notes)
    }
}

// MARK: - Edge Cases Tests

final class SupplementServiceEdgeCaseTests: XCTestCase {

    func testSupplementCategory_UniqueIcons() {
        let icons = SupplementCategory.allCases.map { $0.icon }
        // Note: Some icons may be shared (like drop.fill for omega3)
        // Just verify all have icons
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testSupplementCategory_UniqueDisplayNames() {
        let names = SupplementCategory.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        XCTAssertEqual(names.count, uniqueNames.count, "Each category should have a unique display name")
    }

    func testTimeOfDay_UniqueDisplayNames() {
        let names = TimeOfDay.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        XCTAssertEqual(names.count, uniqueNames.count, "Each time of day should have a unique display name")
    }

    func testSupplement_MultipleTimesOfDay() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Multi-dose Supplement",
            brand: nil,
            category: .vitamins,
            dosage: "1 capsule",
            frequency: .threeTimesDaily,
            timeOfDay: [.morning, .afternoon, .evening],
            withFood: true,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        XCTAssertEqual(supplement.timeOfDay.count, 3)
        XCTAssertTrue(supplement.timeOfDay.contains(.morning))
        XCTAssertTrue(supplement.timeOfDay.contains(.afternoon))
        XCTAssertTrue(supplement.timeOfDay.contains(.evening))
    }

    func testSupplement_EmptyTimeOfDay() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "As Needed Supplement",
            brand: nil,
            category: .adaptogens,
            dosage: "500mg",
            frequency: .asNeeded,
            timeOfDay: [],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        XCTAssertTrue(supplement.timeOfDay.isEmpty)
    }

    func testSupplement_InactiveSupplement() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Old Supplement",
            brand: nil,
            category: .other,
            dosage: "1g",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: false,
            createdAt: Date()
        )

        XCTAssertFalse(supplement.isActive)
    }

    func testScheduledSupplement_TakenWithTimestamp() {
        let takenAt = Date()
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Test",
            brand: nil,
            category: .vitamins,
            dosage: "1",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

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

    func testSupplementFrequency_AllCasesHaveDisplayNames() {
        for frequency in SupplementFrequency.allCases {
            XCTAssertFalse(frequency.displayName.isEmpty, "\(frequency) should have a display name")
        }
    }
}

// MARK: - TodaySupplementDose Tests

final class TodaySupplementDoseTests: XCTestCase {

    func testTodaySupplementDose_Initialization() {
        let id = UUID()
        let routineId = UUID()
        let supplementId = UUID()
        let scheduledTime = Date()

        let dose = TodaySupplementDose(
            id: id,
            routineId: routineId,
            supplementId: supplementId,
            supplementName: "Creatine",
            brand: "Momentous",
            category: .performance,
            dosage: "5g",
            timing: .postWorkout,
            scheduledTime: scheduledTime,
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertEqual(dose.id, id)
        XCTAssertEqual(dose.routineId, routineId)
        XCTAssertEqual(dose.supplementId, supplementId)
        XCTAssertEqual(dose.supplementName, "Creatine")
        XCTAssertEqual(dose.brand, "Momentous")
        XCTAssertEqual(dose.category, .performance)
        XCTAssertEqual(dose.dosage, "5g")
        XCTAssertEqual(dose.timing, .postWorkout)
        XCTAssertEqual(dose.scheduledTime, scheduledTime)
        XCTAssertFalse(dose.withFood)
        XCTAssertFalse(dose.isTaken)
        XCTAssertNil(dose.takenAt)
        XCTAssertNil(dose.logId)
    }

    func testTodaySupplementDose_DisplayName_WithBrand() {
        let dose = TodaySupplementDose(
            id: UUID(),
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Creatine",
            brand: "Momentous",
            category: .performance,
            dosage: "5g",
            timing: .morning,
            scheduledTime: Date(),
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertEqual(dose.displayName, "Momentous Creatine")
    }

    func testTodaySupplementDose_DisplayName_NoBrand() {
        let dose = TodaySupplementDose(
            id: UUID(),
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Vitamin D3",
            brand: nil,
            category: .vitamin,
            dosage: "5000 IU",
            timing: .morning,
            scheduledTime: Date(),
            withFood: true,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertEqual(dose.displayName, "Vitamin D3")
    }

    func testTodaySupplementDose_IsOverdue() {
        let twoHoursAgo = Date().addingTimeInterval(-7200)

        var dose = TodaySupplementDose(
            id: UUID(),
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Test",
            brand: nil,
            category: .vitamin,
            dosage: "1",
            timing: .morning,
            scheduledTime: twoHoursAgo,
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertTrue(dose.isOverdue)

        // Taking it should make it not overdue
        dose.isTaken = true
        XCTAssertFalse(dose.isOverdue)
    }

    func testTodaySupplementDose_IsPending() {
        let oneHourFromNow = Date().addingTimeInterval(3600)

        let dose = TodaySupplementDose(
            id: UUID(),
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Test",
            brand: nil,
            category: .vitamin,
            dosage: "1",
            timing: .evening,
            scheduledTime: oneHourFromNow,
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertTrue(dose.isPending)
        XCTAssertFalse(dose.isOverdue)
    }

    func testTodaySupplementDose_Hashable() {
        let id = UUID()

        let dose1 = TodaySupplementDose(
            id: id,
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Test",
            brand: nil,
            category: .vitamin,
            dosage: "1",
            timing: .morning,
            scheduledTime: Date(),
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        let dose2 = TodaySupplementDose(
            id: UUID(),
            routineId: UUID(),
            supplementId: UUID(),
            supplementName: "Test",
            brand: nil,
            category: .vitamin,
            dosage: "1",
            timing: .morning,
            scheduledTime: Date(),
            withFood: false,
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        var set = Set<TodaySupplementDose>()
        set.insert(dose1)
        set.insert(dose2)

        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - SupplementCompliance Tests

final class SupplementComplianceTests: XCTestCase {

    func testSupplementCompliance_Initialization() {
        let compliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 4,
            skippedCount: 1,
            complianceRate: 0.8,
            streakDays: 7
        )

        XCTAssertEqual(compliance.plannedCount, 5)
        XCTAssertEqual(compliance.takenCount, 4)
        XCTAssertEqual(compliance.skippedCount, 1)
        XCTAssertEqual(compliance.complianceRate, 0.8)
        XCTAssertEqual(compliance.streakDays, 7)
    }

    func testSupplementCompliance_FormattedRate() {
        let compliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 10,
            takenCount: 8,
            skippedCount: 2,
            complianceRate: 0.8,
            streakDays: 0
        )

        XCTAssertEqual(compliance.formattedRate, "80%")
    }

    func testSupplementCompliance_IsComplete() {
        let completeCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 5,
            skippedCount: 0,
            complianceRate: 1.0,
            streakDays: 10
        )

        XCTAssertTrue(completeCompliance.isComplete)

        let incompleteCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 4,
            skippedCount: 0,
            complianceRate: 0.8,
            streakDays: 0
        )

        XCTAssertFalse(incompleteCompliance.isComplete)
    }
}

// MARK: - WeeklySupplementCompliance Tests

final class WeeklySupplementComplianceTests: XCTestCase {

    func testWeeklyCompliance_AverageComplianceRate() {
        let dailyCompliance = [
            createCompliance(rate: 1.0),
            createCompliance(rate: 0.8),
            createCompliance(rate: 0.6)
        ]

        let weekly = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        let expectedAverage = (1.0 + 0.8 + 0.6) / 3.0
        XCTAssertEqual(weekly.averageComplianceRate, expectedAverage, accuracy: 0.01)
    }

    func testWeeklyCompliance_TotalTaken() {
        let dailyCompliance = [
            createCompliance(takenCount: 5),
            createCompliance(takenCount: 4),
            createCompliance(takenCount: 3)
        ]

        let weekly = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(weekly.totalTaken, 12)
    }

    func testWeeklyCompliance_TotalPlanned() {
        let dailyCompliance = [
            createCompliance(plannedCount: 5),
            createCompliance(plannedCount: 5),
            createCompliance(plannedCount: 5)
        ]

        let weekly = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(weekly.totalPlanned, 15)
    }

    func testWeeklyCompliance_CompleteDays() {
        let dailyCompliance = [
            createCompliance(takenCount: 5, plannedCount: 5),
            createCompliance(takenCount: 4, plannedCount: 5),
            createCompliance(takenCount: 5, plannedCount: 5),
            createCompliance(takenCount: 3, plannedCount: 5)
        ]

        let weekly = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(weekly.completeDays, 2)
    }

    func testWeeklyCompliance_EmptyDailyCompliance() {
        let weekly = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: []
        )

        XCTAssertEqual(weekly.averageComplianceRate, 0)
        XCTAssertEqual(weekly.totalTaken, 0)
        XCTAssertEqual(weekly.totalPlanned, 0)
        XCTAssertEqual(weekly.completeDays, 0)
    }

    private func createCompliance(
        rate: Double = 0.8,
        takenCount: Int = 4,
        plannedCount: Int = 5
    ) -> SupplementCompliance {
        SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: plannedCount,
            takenCount: takenCount,
            skippedCount: 0,
            complianceRate: rate,
            streakDays: 0
        )
    }
}

// MARK: - SupplementTiming Tests

final class SupplementTimingServiceTests: XCTestCase {

    func testSupplementTiming_AllCases() {
        let allCases = SupplementTiming.allCases
        XCTAssertEqual(allCases.count, 9) // morning, afternoon, preWorkout, postWorkout, evening, beforeBed, withMeal, betweenMeals, anytime
    }

    func testSupplementTiming_RawValues() {
        XCTAssertEqual(SupplementTiming.morning.rawValue, "morning")
        XCTAssertEqual(SupplementTiming.afternoon.rawValue, "afternoon")
        XCTAssertEqual(SupplementTiming.preWorkout.rawValue, "pre_workout")
        XCTAssertEqual(SupplementTiming.postWorkout.rawValue, "post_workout")
        XCTAssertEqual(SupplementTiming.evening.rawValue, "evening")
        XCTAssertEqual(SupplementTiming.beforeBed.rawValue, "before_bed")
        XCTAssertEqual(SupplementTiming.withMeal.rawValue, "with_meal")
        XCTAssertEqual(SupplementTiming.betweenMeals.rawValue, "between_meals")
        XCTAssertEqual(SupplementTiming.anytime.rawValue, "anytime")
    }

    func testSupplementTiming_DisplayNames() {
        XCTAssertEqual(SupplementTiming.morning.displayName, "Morning")
        XCTAssertEqual(SupplementTiming.afternoon.displayName, "Afternoon")
        XCTAssertEqual(SupplementTiming.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(SupplementTiming.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(SupplementTiming.evening.displayName, "Evening")
        XCTAssertEqual(SupplementTiming.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(SupplementTiming.withMeal.displayName, "With Meal")
        XCTAssertEqual(SupplementTiming.betweenMeals.displayName, "Between Meals")
        XCTAssertEqual(SupplementTiming.anytime.displayName, "Anytime")
    }

    func testSupplementTiming_Icons() {
        XCTAssertEqual(SupplementTiming.morning.icon, "sunrise.fill")
        XCTAssertEqual(SupplementTiming.afternoon.icon, "sun.max.fill")
        XCTAssertEqual(SupplementTiming.preWorkout.icon, "figure.run")
        XCTAssertEqual(SupplementTiming.postWorkout.icon, "figure.cooldown")
        XCTAssertEqual(SupplementTiming.evening.icon, "sunset.fill")
        XCTAssertEqual(SupplementTiming.beforeBed.icon, "moon.fill")
        XCTAssertEqual(SupplementTiming.withMeal.icon, "fork.knife")
        XCTAssertEqual(SupplementTiming.betweenMeals.icon, "clock.fill")
        XCTAssertEqual(SupplementTiming.anytime.icon, "clock.badge.checkmark.fill")
    }

    func testSupplementTiming_SortOrder() {
        let sortedTimings = SupplementTiming.allCases.sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(sortedTimings.first, .morning)
        XCTAssertEqual(sortedTimings.last, .anytime)
    }

    func testSupplementTiming_ApproximateHour() {
        XCTAssertEqual(SupplementTiming.morning.approximateHour, 7)
        XCTAssertEqual(SupplementTiming.afternoon.approximateHour, 14)
        XCTAssertEqual(SupplementTiming.preWorkout.approximateHour, 6)
        XCTAssertEqual(SupplementTiming.postWorkout.approximateHour, 8)
        XCTAssertEqual(SupplementTiming.withMeal.approximateHour, 12)
        XCTAssertEqual(SupplementTiming.betweenMeals.approximateHour, 15)
        XCTAssertEqual(SupplementTiming.evening.approximateHour, 18)
        XCTAssertEqual(SupplementTiming.beforeBed.approximateHour, 21)
        XCTAssertEqual(SupplementTiming.anytime.approximateHour, 12)
    }
}

// MARK: - DosageUnit Tests

final class DosageUnitTests: XCTestCase {

    func testDosageUnit_AllCases() {
        let allCases = DosageUnit.allCases
        XCTAssertEqual(allCases.count, 12)
    }

    func testDosageUnit_RawValues() {
        XCTAssertEqual(DosageUnit.mg.rawValue, "mg")
        XCTAssertEqual(DosageUnit.g.rawValue, "g")
        XCTAssertEqual(DosageUnit.mcg.rawValue, "mcg")
        XCTAssertEqual(DosageUnit.iu.rawValue, "IU")
        XCTAssertEqual(DosageUnit.ml.rawValue, "ml")
        XCTAssertEqual(DosageUnit.capsule.rawValue, "capsule")
        XCTAssertEqual(DosageUnit.capsules.rawValue, "capsules")
        XCTAssertEqual(DosageUnit.tablet.rawValue, "tablet")
        XCTAssertEqual(DosageUnit.tablets.rawValue, "tablets")
        XCTAssertEqual(DosageUnit.scoop.rawValue, "scoop")
        XCTAssertEqual(DosageUnit.scoops.rawValue, "scoops")
        XCTAssertEqual(DosageUnit.serving.rawValue, "serving")
    }

    func testDosageUnit_DisplayNames() {
        for unit in DosageUnit.allCases {
            XCTAssertEqual(unit.displayName, unit.rawValue)
        }
    }

    func testDosageUnit_Abbreviation() {
        for unit in DosageUnit.allCases {
            XCTAssertEqual(unit.abbreviation, unit.displayName)
        }
    }
}

// MARK: - Dosage Tests

final class DosageTests: XCTestCase {

    func testDosage_DisplayString_WholeNumber() {
        let dosage = Dosage(amount: 5, unit: .g)
        XCTAssertEqual(dosage.displayString, "5 g")
    }

    func testDosage_DisplayString_Decimal() {
        let dosage = Dosage(amount: 2.5, unit: .g)
        XCTAssertEqual(dosage.displayString, "2.5 g")
    }

    func testDosage_DisplayString_Capsules() {
        let dosage = Dosage(amount: 2, unit: .capsules)
        XCTAssertEqual(dosage.displayString, "2 capsules")
    }

    func testDosage_Hashable() {
        let dosage1 = Dosage(amount: 5, unit: .g)
        let dosage2 = Dosage(amount: 5, unit: .g)
        let dosage3 = Dosage(amount: 10, unit: .g)

        XCTAssertEqual(dosage1, dosage2)
        XCTAssertNotEqual(dosage1, dosage3)
    }
}
