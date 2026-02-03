//
//  SupplementViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for SupplementViewModel
//  Tests initial state, computed properties, form state, and supplement management
//

import XCTest
@testable import PTPerformance

@MainActor
final class SupplementViewModelTests: XCTestCase {

    var sut: SupplementViewModel!

    override func setUp() {
        super.setUp()
        sut = SupplementViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_SupplementsIsEmpty() {
        XCTAssertTrue(sut.supplements.isEmpty, "supplements should be empty initially")
    }

    func testInitialState_TodayScheduleIsEmpty() {
        XCTAssertTrue(sut.todaySchedule.isEmpty, "todaySchedule should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    // MARK: - Add Supplement Form Initial State

    func testInitialState_ShowingAddSheetIsFalse() {
        XCTAssertFalse(sut.showingAddSheet, "showingAddSheet should be false initially")
    }

    func testInitialState_NewNameIsEmpty() {
        XCTAssertEqual(sut.newName, "", "newName should be empty initially")
    }

    func testInitialState_NewBrandIsEmpty() {
        XCTAssertEqual(sut.newBrand, "", "newBrand should be empty initially")
    }

    func testInitialState_NewCategoryIsVitamins() {
        XCTAssertEqual(sut.newCategory, .vitamins, "newCategory should be .vitamins initially")
    }

    func testInitialState_NewDosageIsEmpty() {
        XCTAssertEqual(sut.newDosage, "", "newDosage should be empty initially")
    }

    func testInitialState_NewFrequencyIsDaily() {
        XCTAssertEqual(sut.newFrequency, .daily, "newFrequency should be .daily initially")
    }

    func testInitialState_NewTimeOfDayContainsMorning() {
        XCTAssertEqual(sut.newTimeOfDay, [.morning], "newTimeOfDay should contain only .morning initially")
    }

    func testInitialState_NewWithFoodIsFalse() {
        XCTAssertFalse(sut.newWithFood, "newWithFood should be false initially")
    }

    func testInitialState_NewNotesIsEmpty() {
        XCTAssertEqual(sut.newNotes, "", "newNotes should be empty initially")
    }

    // MARK: - Computed Properties Tests - pendingToday

    func testPendingToday_WhenEmpty_ReturnsEmpty() {
        sut.todaySchedule = []
        XCTAssertTrue(sut.pendingToday.isEmpty, "pendingToday should be empty when todaySchedule is empty")
    }

    func testPendingToday_FiltersNotTaken() {
        let pendingSupplement = createMockScheduledSupplement(taken: false)
        let takenSupplement = createMockScheduledSupplement(taken: true)

        sut.todaySchedule = [pendingSupplement, takenSupplement]

        XCTAssertEqual(sut.pendingToday.count, 1, "pendingToday should only include supplements not taken")
        XCTAssertEqual(sut.pendingToday.first?.id, pendingSupplement.id)
    }

    // MARK: - Computed Properties Tests - takenToday

    func testTakenToday_WhenEmpty_ReturnsEmpty() {
        sut.todaySchedule = []
        XCTAssertTrue(sut.takenToday.isEmpty, "takenToday should be empty when todaySchedule is empty")
    }

    func testTakenToday_FiltersTaken() {
        let pendingSupplement = createMockScheduledSupplement(taken: false)
        let takenSupplement = createMockScheduledSupplement(taken: true)

        sut.todaySchedule = [pendingSupplement, takenSupplement]

        XCTAssertEqual(sut.takenToday.count, 1, "takenToday should only include supplements that are taken")
        XCTAssertEqual(sut.takenToday.first?.id, takenSupplement.id)
    }

    // MARK: - Computed Properties Tests - completionRate

    func testCompletionRate_WhenEmpty_ReturnsZero() {
        sut.todaySchedule = []
        XCTAssertEqual(sut.completionRate, 0, "completionRate should be 0 when todaySchedule is empty")
    }

    func testCompletionRate_CalculatesCorrectly() {
        let taken1 = createMockScheduledSupplement(taken: true)
        let taken2 = createMockScheduledSupplement(taken: true)
        let pending = createMockScheduledSupplement(taken: false)

        sut.todaySchedule = [taken1, taken2, pending]

        // 2 out of 3 taken
        XCTAssertEqual(sut.completionRate, 2.0/3.0, accuracy: 0.01, "completionRate should be 2/3")
    }

    func testCompletionRate_WhenAllTaken_ReturnsOne() {
        let taken1 = createMockScheduledSupplement(taken: true)
        let taken2 = createMockScheduledSupplement(taken: true)

        sut.todaySchedule = [taken1, taken2]

        XCTAssertEqual(sut.completionRate, 1.0, "completionRate should be 1.0 when all are taken")
    }

    func testCompletionRate_WhenNoneTaken_ReturnsZero() {
        let pending1 = createMockScheduledSupplement(taken: false)
        let pending2 = createMockScheduledSupplement(taken: false)

        sut.todaySchedule = [pending1, pending2]

        XCTAssertEqual(sut.completionRate, 0, "completionRate should be 0 when none are taken")
    }

    // MARK: - Computed Properties Tests - supplementsByCategory

    func testSupplementsByCategory_WhenEmpty_ReturnsEmpty() {
        sut.supplements = []
        XCTAssertTrue(sut.supplementsByCategory.isEmpty, "supplementsByCategory should be empty when supplements is empty")
    }

    func testSupplementsByCategory_GroupsByCategory() {
        let vitamin1 = createMockSupplement(category: .vitamins, name: "Vitamin D")
        let vitamin2 = createMockSupplement(category: .vitamins, name: "Vitamin C")
        let protein = createMockSupplement(category: .protein, name: "Whey Protein")

        sut.supplements = [vitamin1, vitamin2, protein]

        XCTAssertEqual(sut.supplementsByCategory.count, 2, "Should have 2 categories")

        let vitaminGroup = sut.supplementsByCategory.first { $0.0 == .vitamins }
        XCTAssertNotNil(vitaminGroup, "Should have vitamins category")
        XCTAssertEqual(vitaminGroup?.1.count, 2, "Vitamins group should have 2 supplements")

        let proteinGroup = sut.supplementsByCategory.first { $0.0 == .protein }
        XCTAssertNotNil(proteinGroup, "Should have protein category")
        XCTAssertEqual(proteinGroup?.1.count, 1, "Protein group should have 1 supplement")
    }

    func testSupplementsByCategory_SortedByDisplayName() {
        let sleep = createMockSupplement(category: .sleep, name: "Melatonin")
        let creatine = createMockSupplement(category: .creatine, name: "Creatine")
        let vitamins = createMockSupplement(category: .vitamins, name: "Multi")

        sut.supplements = [sleep, creatine, vitamins]

        let categories = sut.supplementsByCategory.map { $0.0 }
        let sortedNames = categories.map { $0.displayName }

        XCTAssertEqual(sortedNames, sortedNames.sorted(), "Categories should be sorted by display name")
    }

    // MARK: - Form State Tests

    func testNewName_CanBeSet() {
        sut.newName = "Vitamin D3"
        XCTAssertEqual(sut.newName, "Vitamin D3", "newName should be settable")
    }

    func testNewBrand_CanBeSet() {
        sut.newBrand = "Thorne"
        XCTAssertEqual(sut.newBrand, "Thorne", "newBrand should be settable")
    }

    func testNewCategory_CanBeChanged() {
        sut.newCategory = .creatine
        XCTAssertEqual(sut.newCategory, .creatine, "newCategory should be changeable")
    }

    func testNewDosage_CanBeSet() {
        sut.newDosage = "5000 IU"
        XCTAssertEqual(sut.newDosage, "5000 IU", "newDosage should be settable")
    }

    func testNewFrequency_CanBeChanged() {
        sut.newFrequency = .twiceDaily
        XCTAssertEqual(sut.newFrequency, .twiceDaily, "newFrequency should be changeable")
    }

    func testNewTimeOfDay_CanBeModified() {
        sut.newTimeOfDay = [.morning, .evening]
        XCTAssertEqual(sut.newTimeOfDay, [.morning, .evening], "newTimeOfDay should be modifiable")

        sut.newTimeOfDay.insert(.beforeBed)
        XCTAssertTrue(sut.newTimeOfDay.contains(.beforeBed), "newTimeOfDay should allow inserting new values")
    }

    func testNewWithFood_CanBeToggled() {
        sut.newWithFood = true
        XCTAssertTrue(sut.newWithFood, "newWithFood should be toggleable to true")

        sut.newWithFood = false
        XCTAssertFalse(sut.newWithFood, "newWithFood should be toggleable to false")
    }

    func testNewNotes_CanBeSet() {
        sut.newNotes = "Take with food"
        XCTAssertEqual(sut.newNotes, "Take with food", "newNotes should be settable")
    }

    // MARK: - Sheet State Tests

    func testShowingAddSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingAddSheet)

        sut.showingAddSheet = true
        XCTAssertTrue(sut.showingAddSheet, "showingAddSheet should be togglable to true")

        sut.showingAddSheet = false
        XCTAssertFalse(sut.showingAddSheet, "showingAddSheet should be togglable to false")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Failed to add supplement"
        XCTAssertEqual(sut.error, "Failed to add supplement", "error should be settable")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading, "isLoading should be settable to false")
    }

    // MARK: - SupplementCategory Tests

    func testSupplementCategory_AllCasesHaveDisplayName() {
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }

    func testSupplementCategory_AllCasesHaveIcon() {
        for category in SupplementCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

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

    // MARK: - SupplementFrequency Tests

    func testSupplementFrequency_AllCasesHaveDisplayName() {
        for frequency in SupplementFrequency.allCases {
            XCTAssertFalse(frequency.displayName.isEmpty, "Frequency \(frequency) should have a display name")
        }
    }

    func testSupplementFrequency_DisplayNames() {
        XCTAssertEqual(SupplementFrequency.daily.displayName, "Daily")
        XCTAssertEqual(SupplementFrequency.twiceDaily.displayName, "Twice Daily")
        XCTAssertEqual(SupplementFrequency.threeTimesDaily.displayName, "Three Times Daily")
        XCTAssertEqual(SupplementFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(SupplementFrequency.asNeeded.displayName, "As Needed")
        XCTAssertEqual(SupplementFrequency.trainingDaysOnly.displayName, "Training Days Only")
    }

    // MARK: - TimeOfDay Tests

    func testTimeOfDay_AllCasesHaveDisplayName() {
        for timeOfDay in TimeOfDay.allCases {
            XCTAssertFalse(timeOfDay.displayName.isEmpty, "TimeOfDay \(timeOfDay) should have a display name")
        }
    }

    func testTimeOfDay_DisplayNames() {
        XCTAssertEqual(TimeOfDay.morning.displayName, "Morning")
        XCTAssertEqual(TimeOfDay.afternoon.displayName, "Afternoon")
        XCTAssertEqual(TimeOfDay.evening.displayName, "Evening")
        XCTAssertEqual(TimeOfDay.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(TimeOfDay.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(TimeOfDay.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(TimeOfDay.withMeals.displayName, "With Meals")
    }

    // MARK: - Edge Cases

    func testSupplements_CanBeCleared() {
        let supplement = createMockSupplement(category: .vitamins, name: "Test")
        sut.supplements = [supplement]

        XCTAssertFalse(sut.supplements.isEmpty)

        sut.supplements = []
        XCTAssertTrue(sut.supplements.isEmpty, "supplements should be clearable")
    }

    func testTodaySchedule_CanBeSet() {
        let scheduled = createMockScheduledSupplement(taken: false)
        sut.todaySchedule = [scheduled]

        XCTAssertEqual(sut.todaySchedule.count, 1, "todaySchedule should be settable")
    }

    func testMultipleTimeOfDay_CanBeSet() {
        sut.newTimeOfDay = [.morning, .evening, .beforeBed]
        XCTAssertEqual(sut.newTimeOfDay.count, 3, "Multiple times of day should be settable")
    }

    // MARK: - Helper Methods

    private func createMockSupplement(category: SupplementCategory, name: String) -> Supplement {
        return Supplement(
            id: UUID(),
            patientId: UUID(),
            name: name,
            brand: nil,
            category: category,
            dosage: "500mg",
            frequency: .daily,
            timeOfDay: [.morning],
            withFood: false,
            notes: nil,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )
    }

    private func createMockScheduledSupplement(taken: Bool) -> ScheduledSupplement {
        let supplement = createMockSupplement(category: .vitamins, name: "Test Supplement")
        return ScheduledSupplement(
            id: UUID(),
            supplement: supplement,
            scheduledTime: Date(),
            taken: taken,
            takenAt: taken ? Date() : nil
        )
    }
}
