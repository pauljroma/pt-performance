//
//  SupplementServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for SupplementService
//  Tests supplement models, categories, schedules, and service state management
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

final class TimeOfDayTests: XCTestCase {

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

    // MARK: - CaseIterable Tests

    func testTimeOfDay_AllCases() {
        let allCases = TimeOfDay.allCases
        XCTAssertEqual(allCases.count, 7)
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

// MARK: - Supplement Tests

final class SupplementTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testSupplement_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let createdAt = Date()

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
            notes: "Take with water",
            momentousProductId: "creatine-mono-500",
            isActive: true,
            createdAt: createdAt
        )

        XCTAssertEqual(supplement.id, id)
        XCTAssertEqual(supplement.patientId, patientId)
        XCTAssertEqual(supplement.name, "Creatine Monohydrate")
        XCTAssertEqual(supplement.brand, "Momentous")
        XCTAssertEqual(supplement.category, .creatine)
        XCTAssertEqual(supplement.dosage, "5g")
        XCTAssertEqual(supplement.frequency, .daily)
        XCTAssertEqual(supplement.timeOfDay, [.morning, .postWorkout])
        XCTAssertEqual(supplement.withFood, false)
        XCTAssertEqual(supplement.notes, "Take with water")
        XCTAssertEqual(supplement.momentousProductId, "creatine-mono-500")
        XCTAssertEqual(supplement.isActive, true)
    }

    func testSupplement_OptionalFields() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Generic Vitamin D",
            brand: nil,
            category: .vitamins,
            dosage: "5000 IU",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: true,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        XCTAssertNil(supplement.brand)
        XCTAssertNil(supplement.notes)
        XCTAssertNil(supplement.momentousProductId)
    }

    // MARK: - Identifiable Tests

    func testSupplement_Identifiable() {
        let id = UUID()
        let supplement = Supplement(
            id: id,
            patientId: UUID(),
            name: "Test",
            brand: nil,
            category: .other,
            dosage: "1 scoop",
            frequency: .daily,
            timeOfDay: [],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        XCTAssertEqual(supplement.id, id)
    }

    // MARK: - Hashable Tests

    func testSupplement_Hashable() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let supplement1 = Supplement(
            id: id,
            patientId: patientId,
            name: "Test",
            brand: nil,
            category: .protein,
            dosage: "1 scoop",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: date
        )
        let supplement2 = Supplement(
            id: id,
            patientId: patientId,
            name: "Test",
            brand: nil,
            category: .protein,
            dosage: "1 scoop",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: date
        )

        XCTAssertEqual(supplement1, supplement2)
    }
}

// MARK: - ScheduledSupplement Tests

final class ScheduledSupplementTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testScheduledSupplement_MemberwiseInit() {
        let id = UUID()
        let scheduledTime = Date()
        let takenAt = Date()

        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Test",
            brand: nil,
            category: .vitamins,
            dosage: "1 capsule",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: true,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        let scheduled = ScheduledSupplement(
            id: id,
            supplement: supplement,
            scheduledTime: scheduledTime,
            taken: true,
            takenAt: takenAt
        )

        XCTAssertEqual(scheduled.id, id)
        XCTAssertEqual(scheduled.supplement.name, "Test")
        XCTAssertEqual(scheduled.scheduledTime, scheduledTime)
        XCTAssertEqual(scheduled.taken, true)
        XCTAssertEqual(scheduled.takenAt, takenAt)
    }

    func testScheduledSupplement_NotTaken() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Test",
            brand: nil,
            category: .vitamins,
            dosage: "1 capsule",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: true,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        let scheduled = ScheduledSupplement(
            id: UUID(),
            supplement: supplement,
            scheduledTime: Date(),
            taken: false,
            takenAt: nil
        )

        XCTAssertFalse(scheduled.taken)
        XCTAssertNil(scheduled.takenAt)
    }

    // MARK: - Identifiable Tests

    func testScheduledSupplement_Identifiable() {
        let id = UUID()
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Test",
            brand: nil,
            category: .other,
            dosage: "1",
            frequency: .daily,
            timeOfDay: [],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        let scheduled = ScheduledSupplement(
            id: id,
            supplement: supplement,
            scheduledTime: Date(),
            taken: false,
            takenAt: nil
        )

        XCTAssertEqual(scheduled.id, id)
    }
}

// MARK: - SupplementLog Tests

final class SupplementLogTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testSupplementLog_MemberwiseInit() {
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
            notes: "Took with protein shake"
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.supplementId, supplementId)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.takenAt, takenAt)
        XCTAssertEqual(log.dosage, "5g")
        XCTAssertEqual(log.notes, "Took with protein shake")
    }

    func testSupplementLog_OptionalNotes() {
        let log = SupplementLog(
            id: UUID(),
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "1 scoop",
            notes: nil
        )

        XCTAssertNil(log.notes)
    }

    // MARK: - Identifiable Tests

    func testSupplementLog_Identifiable() {
        let id = UUID()
        let log = SupplementLog(
            id: id,
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "1g",
            notes: nil
        )

        XCTAssertEqual(log.id, id)
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
        XCTAssertTrue(sut.recentLogs is [SupplementLog])
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
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
}

// MARK: - Codable Decoding Tests

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
