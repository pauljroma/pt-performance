//
//  BodyCompositionViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for BodyCompositionViewModel
//  Tests computed statistics, form validation, and state management
//

import XCTest
@testable import PTPerformance

@MainActor
final class BodyCompositionViewModelTests: XCTestCase {

    var viewModel: BodyCompositionViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = BodyCompositionViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.entries.isEmpty, "Entries should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isSaving, "Should not be saving initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
        XCTAssertFalse(viewModel.showingSuccessAlert, "Should not show success alert initially")
    }

    func testInitialFormState() {
        XCTAssertEqual(viewModel.weightLb, "", "Weight should be empty initially")
        XCTAssertEqual(viewModel.bodyFatPercent, "", "Body fat should be empty initially")
        XCTAssertEqual(viewModel.muscleMassLb, "", "Muscle mass should be empty initially")
        XCTAssertEqual(viewModel.waistIn, "", "Waist should be empty initially")
        XCTAssertEqual(viewModel.chestIn, "", "Chest should be empty initially")
        XCTAssertEqual(viewModel.armIn, "", "Arm should be empty initially")
        XCTAssertEqual(viewModel.legIn, "", "Leg should be empty initially")
        XCTAssertEqual(viewModel.notes, "", "Notes should be empty initially")
    }

    // MARK: - hasValidInput Tests

    func testHasValidInput_WhenAllEmpty_ReturnsFalse() {
        XCTAssertFalse(viewModel.hasValidInput,
            "hasValidInput should be false when all fields are empty")
    }

    func testHasValidInput_WhenWeightFilled_ReturnsTrue() {
        viewModel.weightLb = "150"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when weight is filled")
    }

    func testHasValidInput_WhenBodyFatFilled_ReturnsTrue() {
        viewModel.bodyFatPercent = "15"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when body fat is filled")
    }

    func testHasValidInput_WhenMuscleMassFilled_ReturnsTrue() {
        viewModel.muscleMassLb = "120"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when muscle mass is filled")
    }

    func testHasValidInput_WhenWaistFilled_ReturnsTrue() {
        viewModel.waistIn = "32"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when waist is filled")
    }

    func testHasValidInput_WhenChestFilled_ReturnsTrue() {
        viewModel.chestIn = "40"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when chest is filled")
    }

    func testHasValidInput_WhenArmFilled_ReturnsTrue() {
        viewModel.armIn = "14"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when arm is filled")
    }

    func testHasValidInput_WhenLegFilled_ReturnsTrue() {
        viewModel.legIn = "22"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when leg is filled")
    }

    func testHasValidInput_WhenOnlyNotesFilled_ReturnsFalse() {
        viewModel.notes = "Some notes"
        XCTAssertFalse(viewModel.hasValidInput,
            "hasValidInput should be false when only notes are filled")
    }

    func testHasValidInput_WhenMultipleFilled_ReturnsTrue() {
        viewModel.weightLb = "150"
        viewModel.bodyFatPercent = "15"
        viewModel.muscleMassLb = "120"
        XCTAssertTrue(viewModel.hasValidInput,
            "hasValidInput should be true when multiple fields are filled")
    }

    // MARK: - Computed Statistics Tests - With Sample Data

    /// Helper method to create sample entries
    private func createSampleEntries() -> [BodyComposition] {
        let patientId = UUID()
        let calendar = Calendar.current

        return [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: 180.0,
                bodyFatPercent: 15.0,
                muscleMassLb: 145.0,
                bmi: 24.5,
                waistIn: 32.0,
                chestIn: 42.0,
                armIn: 15.0,
                legIn: 24.0,
                notes: "Latest entry",
                createdAt: Date()
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: calendar.date(byAdding: .day, value: -7, to: Date())!,
                weightLb: 182.0,
                bodyFatPercent: 16.0,
                muscleMassLb: 143.0,
                bmi: 24.8,
                waistIn: 33.0,
                chestIn: 41.5,
                armIn: 14.5,
                legIn: 23.5,
                notes: nil,
                createdAt: calendar.date(byAdding: .day, value: -7, to: Date())!
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: calendar.date(byAdding: .day, value: -14, to: Date())!,
                weightLb: 185.0,
                bodyFatPercent: 17.0,
                muscleMassLb: 140.0,
                bmi: 25.2,
                waistIn: 34.0,
                chestIn: 41.0,
                armIn: 14.0,
                legIn: 23.0,
                notes: nil,
                createdAt: calendar.date(byAdding: .day, value: -14, to: Date())!
            )
        ]
    }

    // MARK: - Latest Weight Tests

    func testLatestWeight_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.latestWeight, "latestWeight should be nil when entries are empty")
    }

    func testLatestWeight_WhenEntriesExist_ReturnsFirstEntry() {
        viewModel.entries = createSampleEntries()
        XCTAssertEqual(viewModel.latestWeight, 180.0,
            "latestWeight should return the first entry's weight")
    }

    func testLatestWeight_SkipsNilWeights() {
        let patientId = UUID()
        viewModel.entries = [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: nil,  // First entry has nil weight
                bodyFatPercent: 15.0,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: 32.0,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date()
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date().addingTimeInterval(-86400),
                weightLb: 175.0,  // Second entry has weight
                bodyFatPercent: 16.0,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]

        XCTAssertEqual(viewModel.latestWeight, 175.0,
            "latestWeight should skip entries with nil weight")
    }

    // MARK: - Average Weight Tests

    func testAverageWeight_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.averageWeight, "averageWeight should be nil when entries are empty")
    }

    func testAverageWeight_WhenEntriesExist_ReturnsCorrectAverage() {
        viewModel.entries = createSampleEntries()
        // (180 + 182 + 185) / 3 = 182.33...
        let expectedAvg = (180.0 + 182.0 + 185.0) / 3.0
        XCTAssertEqual(viewModel.averageWeight!, expectedAvg, accuracy: 0.01,
            "averageWeight should calculate correct average")
    }

    func testAverageWeight_SingleEntry() {
        let patientId = UUID()
        viewModel.entries = [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: 175.0,
                bodyFatPercent: nil,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date()
            )
        ]

        XCTAssertEqual(viewModel.averageWeight, 175.0,
            "averageWeight should return single entry's weight")
    }

    func testAverageWeight_SkipsNilWeights() {
        let patientId = UUID()
        viewModel.entries = [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: 180.0,
                bodyFatPercent: nil,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date()
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date().addingTimeInterval(-86400),
                weightLb: nil,  // Nil weight
                bodyFatPercent: 15.0,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date().addingTimeInterval(-172800),
                weightLb: 170.0,
                bodyFatPercent: nil,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date().addingTimeInterval(-172800)
            )
        ]

        // (180 + 170) / 2 = 175
        XCTAssertEqual(viewModel.averageWeight, 175.0,
            "averageWeight should skip nil weights in calculation")
    }

    // MARK: - Min/Max Weight Tests

    func testMinWeight_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.minWeight, "minWeight should be nil when entries are empty")
    }

    func testMinWeight_WhenEntriesExist_ReturnsMinimum() {
        viewModel.entries = createSampleEntries()
        XCTAssertEqual(viewModel.minWeight, 180.0,
            "minWeight should return the minimum weight")
    }

    func testMaxWeight_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.maxWeight, "maxWeight should be nil when entries are empty")
    }

    func testMaxWeight_WhenEntriesExist_ReturnsMaximum() {
        viewModel.entries = createSampleEntries()
        XCTAssertEqual(viewModel.maxWeight, 185.0,
            "maxWeight should return the maximum weight")
    }

    // MARK: - Latest Body Fat Tests

    func testLatestBodyFat_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.latestBodyFat, "latestBodyFat should be nil when entries are empty")
    }

    func testLatestBodyFat_WhenEntriesExist_ReturnsFirstEntry() {
        viewModel.entries = createSampleEntries()
        XCTAssertEqual(viewModel.latestBodyFat, 15.0,
            "latestBodyFat should return the first entry's body fat")
    }

    // MARK: - Average Body Fat Tests

    func testAverageBodyFat_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.averageBodyFat, "averageBodyFat should be nil when entries are empty")
    }

    func testAverageBodyFat_WhenEntriesExist_ReturnsCorrectAverage() {
        viewModel.entries = createSampleEntries()
        // (15 + 16 + 17) / 3 = 16
        XCTAssertEqual(viewModel.averageBodyFat, 16.0,
            "averageBodyFat should calculate correct average")
    }

    // MARK: - Latest Muscle Mass Tests

    func testLatestMuscleMass_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.latestMuscleMass, "latestMuscleMass should be nil when entries are empty")
    }

    func testLatestMuscleMass_WhenEntriesExist_ReturnsFirstEntry() {
        viewModel.entries = createSampleEntries()
        XCTAssertEqual(viewModel.latestMuscleMass, 145.0,
            "latestMuscleMass should return the first entry's muscle mass")
    }

    // MARK: - Average Muscle Mass Tests

    func testAverageMuscleMass_WhenEntriesEmpty_ReturnsNil() {
        XCTAssertNil(viewModel.averageMuscleMass, "averageMuscleMass should be nil when entries are empty")
    }

    func testAverageMuscleMass_WhenEntriesExist_ReturnsCorrectAverage() {
        viewModel.entries = createSampleEntries()
        // (145 + 143 + 140) / 3 = 142.67
        let expectedAvg = (145.0 + 143.0 + 140.0) / 3.0
        XCTAssertEqual(viewModel.averageMuscleMass!, expectedAvg, accuracy: 0.01,
            "averageMuscleMass should calculate correct average")
    }

    // MARK: - Reset Form Tests

    func testResetForm_ClearsAllFields() {
        // Populate form fields
        viewModel.weightLb = "150"
        viewModel.bodyFatPercent = "15"
        viewModel.muscleMassLb = "120"
        viewModel.waistIn = "32"
        viewModel.chestIn = "40"
        viewModel.armIn = "14"
        viewModel.legIn = "22"
        viewModel.notes = "Some notes"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.weightLb, "")
        XCTAssertEqual(viewModel.bodyFatPercent, "")
        XCTAssertEqual(viewModel.muscleMassLb, "")
        XCTAssertEqual(viewModel.waistIn, "")
        XCTAssertEqual(viewModel.chestIn, "")
        XCTAssertEqual(viewModel.armIn, "")
        XCTAssertEqual(viewModel.legIn, "")
        XCTAssertEqual(viewModel.notes, "")
    }

    // MARK: - Edge Cases

    func testStatistics_AllNilValues() {
        let patientId = UUID()
        viewModel.entries = [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: nil,
                bodyFatPercent: nil,
                muscleMassLb: nil,
                bmi: nil,
                waistIn: 32.0,  // Only measurement
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date()
            )
        ]

        XCTAssertNil(viewModel.latestWeight)
        XCTAssertNil(viewModel.averageWeight)
        XCTAssertNil(viewModel.minWeight)
        XCTAssertNil(viewModel.maxWeight)
        XCTAssertNil(viewModel.latestBodyFat)
        XCTAssertNil(viewModel.averageBodyFat)
        XCTAssertNil(viewModel.latestMuscleMass)
        XCTAssertNil(viewModel.averageMuscleMass)
    }

    func testStatistics_MixedNilAndValues() {
        let patientId = UUID()
        viewModel.entries = [
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date(),
                weightLb: 180.0,
                bodyFatPercent: nil,  // No body fat
                muscleMassLb: 145.0,
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date()
            ),
            BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date().addingTimeInterval(-86400),
                weightLb: nil,  // No weight
                bodyFatPercent: 15.0,
                muscleMassLb: nil,  // No muscle mass
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]

        XCTAssertEqual(viewModel.latestWeight, 180.0)
        XCTAssertEqual(viewModel.averageWeight, 180.0)  // Only one weight
        XCTAssertEqual(viewModel.latestBodyFat, 15.0)  // From second entry
        XCTAssertEqual(viewModel.averageBodyFat, 15.0)  // Only one body fat
        XCTAssertEqual(viewModel.latestMuscleMass, 145.0)
        XCTAssertEqual(viewModel.averageMuscleMass, 145.0)  // Only one muscle mass
    }

    func testStatistics_LargeDataset() {
        let patientId = UUID()
        var entries: [BodyComposition] = []

        for i in 0..<100 {
            entries.append(BodyComposition(
                id: UUID(),
                patientId: patientId,
                recordedAt: Date().addingTimeInterval(Double(-i * 86400)),
                weightLb: 150.0 + Double(i),  // 150-249
                bodyFatPercent: 10.0 + Double(i) * 0.1,  // 10-19.9
                muscleMassLb: 120.0 + Double(i) * 0.5,  // 120-169.5
                bmi: nil,
                waistIn: nil,
                chestIn: nil,
                armIn: nil,
                legIn: nil,
                notes: nil,
                createdAt: Date().addingTimeInterval(Double(-i * 86400))
            ))
        }

        viewModel.entries = entries

        XCTAssertEqual(viewModel.latestWeight, 150.0)
        XCTAssertEqual(viewModel.minWeight, 150.0)
        XCTAssertEqual(viewModel.maxWeight, 249.0)

        // Average: sum of 150 to 249 = 100 * (150 + 249) / 2 = 19950 / 100 = 199.5
        XCTAssertEqual(viewModel.averageWeight!, 199.5, accuracy: 0.01)
    }
}
