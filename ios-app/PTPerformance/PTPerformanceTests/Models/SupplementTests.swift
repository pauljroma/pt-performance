//
//  SupplementTests.swift
//  PTPerformanceTests
//
//  Unit tests for Supplement, SupplementCategory, SupplementFrequency, TimeOfDay,
//  ScheduledSupplement, and SupplementLog models
//

import XCTest
@testable import PTPerformance

final class SupplementTests: XCTestCase {

    // MARK: - Supplement Initialization Tests

    func testSupplementInitialization() {
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
            momentousProductId: "creatine-001",
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
        XCTAssertEqual(supplement.timeOfDay.count, 2)
        XCTAssertTrue(supplement.timeOfDay.contains(.morning))
        XCTAssertTrue(supplement.timeOfDay.contains(.postWorkout))
        XCTAssertFalse(supplement.withFood)
        XCTAssertEqual(supplement.notes, "Take with water")
        XCTAssertEqual(supplement.momentousProductId, "creatine-001")
        XCTAssertTrue(supplement.isActive)
        XCTAssertEqual(supplement.createdAt, createdAt)
    }

    func testSupplementWithNilOptionals() {
        let supplement = Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Vitamin D3",
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

    // MARK: - Supplement Codable Tests

    func testSupplementEncodeDecode() throws {
        let original = createSupplement()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Supplement.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.brand, decoded.brand)
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.dosage, decoded.dosage)
        XCTAssertEqual(original.frequency, decoded.frequency)
        XCTAssertEqual(original.timeOfDay, decoded.timeOfDay)
        XCTAssertEqual(original.withFood, decoded.withFood)
        XCTAssertEqual(original.isActive, decoded.isActive)
    }

    func testSupplementCodingKeysMapping() throws {
        let supplement = createSupplement()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(supplement)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["time_of_day"])
        XCTAssertNotNil(jsonObject["with_food"])
        XCTAssertNotNil(jsonObject["momentous_product_id"])
        XCTAssertNotNil(jsonObject["is_active"])
        XCTAssertNotNil(jsonObject["created_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["timeOfDay"])
        XCTAssertNil(jsonObject["withFood"])
        XCTAssertNil(jsonObject["momentousProductId"])
        XCTAssertNil(jsonObject["isActive"])
    }

    func testSupplementHashable() {
        let supplement1 = createSupplement()
        let supplement2 = createSupplement()

        var set = Set<Supplement>()
        set.insert(supplement1)
        set.insert(supplement2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - SupplementCategory Tests

    func testSupplementCategoryAllCases() {
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

    func testSupplementCategoryRawValues() {
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

    func testSupplementCategoryDisplayNames() {
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

    func testSupplementCategoryDisplayNamesNotEmpty() {
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertTrue(category.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(category.displayName)")
        }
    }

    func testSupplementCategoryIcons() {
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

    func testSupplementCategoryIconsNotEmpty() {
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testSupplementCategoryInitFromRawValue() {
        XCTAssertEqual(SupplementCategory(rawValue: "protein"), .protein)
        XCTAssertEqual(SupplementCategory(rawValue: "omega3"), .omega3)
        XCTAssertNil(SupplementCategory(rawValue: "invalid"))
        XCTAssertNil(SupplementCategory(rawValue: ""))
    }

    func testSupplementCategoryCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in SupplementCategory.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(SupplementCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - SupplementFrequency Tests

    func testSupplementFrequencyAllCases() {
        let allCases = SupplementFrequency.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.daily))
        XCTAssertTrue(allCases.contains(.twiceDaily))
        XCTAssertTrue(allCases.contains(.threeTimesDaily))
        XCTAssertTrue(allCases.contains(.weekly))
        XCTAssertTrue(allCases.contains(.asNeeded))
        XCTAssertTrue(allCases.contains(.trainingDaysOnly))
    }

    func testSupplementFrequencyRawValues() {
        XCTAssertEqual(SupplementFrequency.daily.rawValue, "daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.rawValue, "twice_daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.rawValue, "three_times_daily")
        XCTAssertEqual(SupplementFrequency.weekly.rawValue, "weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.rawValue, "as_needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.rawValue, "training_days_only")
    }

    func testSupplementFrequencyDisplayNames() {
        XCTAssertEqual(SupplementFrequency.daily.displayName, "Daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.displayName, "Twice Daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.displayName, "Three Times Daily")
        XCTAssertEqual(SupplementFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.displayName, "As Needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.displayName, "Training Days Only")
    }

    func testSupplementFrequencyDisplayNamesNotEmpty() {
        for frequency in SupplementFrequency.allCases {
            XCTAssertFalse(frequency.displayName.isEmpty)
            XCTAssertTrue(frequency.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(frequency.displayName)")
        }
    }

    func testSupplementFrequencyInitFromRawValue() {
        XCTAssertEqual(SupplementFrequency(rawValue: "daily"), .daily)
        XCTAssertEqual(SupplementFrequency(rawValue: "twice_daily"), .twiceDaily)
        XCTAssertEqual(SupplementFrequency(rawValue: "training_days_only"), .trainingDaysOnly)
        XCTAssertNil(SupplementFrequency(rawValue: "invalid"))
    }

    func testSupplementFrequencyCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for frequency in SupplementFrequency.allCases {
            let data = try encoder.encode(frequency)
            let decoded = try decoder.decode(SupplementFrequency.self, from: data)
            XCTAssertEqual(decoded, frequency)
        }
    }

    // MARK: - TimeOfDay Tests

    func testTimeOfDayAllCases() {
        let allCases = TimeOfDay.allCases
        XCTAssertEqual(allCases.count, 7)
        XCTAssertTrue(allCases.contains(.morning))
        XCTAssertTrue(allCases.contains(.afternoon))
        XCTAssertTrue(allCases.contains(.evening))
        XCTAssertTrue(allCases.contains(.beforeBed))
        XCTAssertTrue(allCases.contains(.preWorkout))
        XCTAssertTrue(allCases.contains(.postWorkout))
        XCTAssertTrue(allCases.contains(.withMeals))
    }

    func testTimeOfDayRawValues() {
        XCTAssertEqual(TimeOfDay.morning.rawValue, "morning")
        XCTAssertEqual(TimeOfDay.afternoon.rawValue, "afternoon")
        XCTAssertEqual(TimeOfDay.evening.rawValue, "evening")
        XCTAssertEqual(TimeOfDay.beforeBed.rawValue, "before_bed")
        XCTAssertEqual(TimeOfDay.preWorkout.rawValue, "pre_workout")
        XCTAssertEqual(TimeOfDay.postWorkout.rawValue, "post_workout")
        XCTAssertEqual(TimeOfDay.withMeals.rawValue, "with_meals")
    }

    func testTimeOfDayDisplayNames() {
        XCTAssertEqual(TimeOfDay.morning.displayName, "Morning")
        XCTAssertEqual(TimeOfDay.afternoon.displayName, "Afternoon")
        XCTAssertEqual(TimeOfDay.evening.displayName, "Evening")
        XCTAssertEqual(TimeOfDay.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(TimeOfDay.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(TimeOfDay.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(TimeOfDay.withMeals.displayName, "With Meals")
    }

    func testTimeOfDayDisplayNamesNotEmpty() {
        for timeOfDay in TimeOfDay.allCases {
            XCTAssertFalse(timeOfDay.displayName.isEmpty)
            XCTAssertTrue(timeOfDay.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(timeOfDay.displayName)")
        }
    }

    func testTimeOfDayInitFromRawValue() {
        XCTAssertEqual(TimeOfDay(rawValue: "morning"), .morning)
        XCTAssertEqual(TimeOfDay(rawValue: "before_bed"), .beforeBed)
        XCTAssertEqual(TimeOfDay(rawValue: "post_workout"), .postWorkout)
        XCTAssertNil(TimeOfDay(rawValue: "invalid"))
    }

    func testTimeOfDayCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for timeOfDay in TimeOfDay.allCases {
            let data = try encoder.encode(timeOfDay)
            let decoded = try decoder.decode(TimeOfDay.self, from: data)
            XCTAssertEqual(decoded, timeOfDay)
        }
    }

    // MARK: - ScheduledSupplement Tests

    func testScheduledSupplementInitialization() {
        let id = UUID()
        let supplement = createSupplement()
        let scheduledTime = Date()
        let takenAt = Date()

        let scheduled = ScheduledSupplement(
            id: id,
            supplement: supplement,
            scheduledTime: scheduledTime,
            taken: true,
            takenAt: takenAt
        )

        XCTAssertEqual(scheduled.id, id)
        XCTAssertEqual(scheduled.supplement.id, supplement.id)
        XCTAssertEqual(scheduled.scheduledTime, scheduledTime)
        XCTAssertTrue(scheduled.taken)
        XCTAssertEqual(scheduled.takenAt, takenAt)
    }

    func testScheduledSupplementNotTaken() {
        let scheduled = ScheduledSupplement(
            id: UUID(),
            supplement: createSupplement(),
            scheduledTime: Date(),
            taken: false,
            takenAt: nil
        )

        XCTAssertFalse(scheduled.taken)
        XCTAssertNil(scheduled.takenAt)
    }

    func testScheduledSupplementCodable() throws {
        let original = ScheduledSupplement(
            id: UUID(),
            supplement: createSupplement(),
            scheduledTime: Date(),
            taken: true,
            takenAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ScheduledSupplement.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.taken, decoded.taken)
    }

    func testScheduledSupplementCodingKeysMapping() throws {
        let scheduled = ScheduledSupplement(
            id: UUID(),
            supplement: createSupplement(),
            scheduledTime: Date(),
            taken: true,
            takenAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(scheduled)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["scheduled_time"])
        XCTAssertNotNil(jsonObject["taken_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["scheduledTime"])
        XCTAssertNil(jsonObject["takenAt"])
    }

    // MARK: - SupplementLog Tests

    func testSupplementLogInitialization() {
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
            notes: "Taken with breakfast"
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.supplementId, supplementId)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.takenAt, takenAt)
        XCTAssertEqual(log.dosage, "5g")
        XCTAssertEqual(log.notes, "Taken with breakfast")
    }

    func testSupplementLogWithNilNotes() {
        let log = SupplementLog(
            id: UUID(),
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "1000mg",
            notes: nil
        )

        XCTAssertNil(log.notes)
    }

    func testSupplementLogCodable() throws {
        let original = SupplementLog(
            id: UUID(),
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "5g",
            notes: "Test notes"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SupplementLog.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.supplementId, decoded.supplementId)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.dosage, decoded.dosage)
        XCTAssertEqual(original.notes, decoded.notes)
    }

    func testSupplementLogCodingKeysMapping() throws {
        let log = SupplementLog(
            id: UUID(),
            supplementId: UUID(),
            patientId: UUID(),
            takenAt: Date(),
            dosage: "5g",
            notes: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(log)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["supplement_id"])
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["taken_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["supplementId"])
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["takenAt"])
    }

    // MARK: - Helpers

    private func createSupplement() -> Supplement {
        Supplement(
            id: UUID(),
            patientId: UUID(),
            name: "Creatine Monohydrate",
            brand: "Momentous",
            category: .creatine,
            dosage: "5g",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: "Take with water",
            momentousProductId: "creatine-001",
            isActive: true,
            createdAt: Date()
        )
    }
}
