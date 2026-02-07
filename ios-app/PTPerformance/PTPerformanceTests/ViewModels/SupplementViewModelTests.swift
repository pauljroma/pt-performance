//
//  SupplementViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for SupplementViewModel
//  Tests initial state, computed properties, form state, supplement management,
//  loading states, CRUD operations, recommendation handling, and adherence tracking.
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

    func testInitialState_CatalogIsEmpty() {
        XCTAssertTrue(sut.catalog.isEmpty, "catalog should be empty initially")
    }

    func testInitialState_StacksIsEmpty() {
        XCTAssertTrue(sut.stacks.isEmpty, "stacks should be empty initially")
    }

    func testInitialState_RoutinesIsEmpty() {
        XCTAssertTrue(sut.routines.isEmpty, "routines should be empty initially")
    }

    func testInitialState_TodayDosesIsEmpty() {
        XCTAssertTrue(sut.todayDoses.isEmpty, "todayDoses should be empty initially")
    }

    func testInitialState_TodayComplianceIsNil() {
        XCTAssertNil(sut.todayCompliance, "todayCompliance should be nil initially")
    }

    func testInitialState_WeeklyComplianceIsNil() {
        XCTAssertNil(sut.weeklyCompliance, "weeklyCompliance should be nil initially")
    }

    func testInitialState_AnalyticsIsNil() {
        XCTAssertNil(sut.analytics, "analytics should be nil initially")
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "", "searchText should be empty initially")
    }

    func testInitialState_SelectedCategoryIsNil() {
        XCTAssertNil(sut.selectedCategory, "selectedCategory should be nil initially")
    }

    func testInitialState_SelectedTimingIsNil() {
        XCTAssertNil(sut.selectedTiming, "selectedTiming should be nil initially")
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

    // MARK: - Add Routine Form Initial State

    func testInitialState_RoutineDosageIsEmpty() {
        XCTAssertEqual(sut.routineDosage, "", "routineDosage should be empty initially")
    }

    func testInitialState_RoutineTimingIsMorning() {
        XCTAssertEqual(sut.routineTiming, .morning, "routineTiming should be .morning initially")
    }

    func testInitialState_RoutineFrequencyIsDaily() {
        XCTAssertEqual(sut.routineFrequency, .daily, "routineFrequency should be .daily initially")
    }

    func testInitialState_RoutineWithFoodIsFalse() {
        XCTAssertFalse(sut.routineWithFood, "routineWithFood should be false initially")
    }

    func testInitialState_RoutineNotesIsEmpty() {
        XCTAssertEqual(sut.routineNotes, "", "routineNotes should be empty initially")
    }

    // MARK: - Sheet State Tests

    func testInitialState_ShowingCatalogSheetIsFalse() {
        XCTAssertFalse(sut.showingCatalogSheet, "showingCatalogSheet should be false initially")
    }

    func testInitialState_ShowingStackSheetIsFalse() {
        XCTAssertFalse(sut.showingStackSheet, "showingStackSheet should be false initially")
    }

    func testInitialState_ShowingHistorySheetIsFalse() {
        XCTAssertFalse(sut.showingHistorySheet, "showingHistorySheet should be false initially")
    }

    func testInitialState_SelectedSupplementIsNil() {
        XCTAssertNil(sut.selectedSupplement, "selectedSupplement should be nil initially")
    }

    func testInitialState_SelectedStackIsNil() {
        XCTAssertNil(sut.selectedStack, "selectedStack should be nil initially")
    }

    // MARK: - Computed Properties Tests - pendingToday (Legacy)

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

    // MARK: - Computed Properties Tests - takenToday (Legacy)

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

    // MARK: - Computed Properties Tests - completionRate (Legacy)

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

    // MARK: - Computed Properties Tests - Today's Progress

    func testTakenCount_WhenEmpty_ReturnsZero() {
        sut.todayDoses = []
        XCTAssertEqual(sut.takenCount, 0)
    }

    func testTakenCount_CountsOnlyTaken() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: false),
            createMockTodayDose(isTaken: true)
        ]
        XCTAssertEqual(sut.takenCount, 2)
    }

    func testPlannedCount_ReturnsTotal() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: false),
            createMockTodayDose(isTaken: false)
        ]
        XCTAssertEqual(sut.plannedCount, 3)
    }

    func testTodayProgress_WhenEmpty_ReturnsZero() {
        sut.todayDoses = []
        XCTAssertEqual(sut.todayProgress, 0)
    }

    func testTodayProgress_CalculatesCorrectly() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: false),
            createMockTodayDose(isTaken: false)
        ]
        XCTAssertEqual(sut.todayProgress, 0.5, accuracy: 0.01)
    }

    func testProgressText_FormatsCorrectly() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: false)
        ]
        XCTAssertEqual(sut.progressText, "2/3")
    }

    func testIsComplete_WhenAllTaken_ReturnsTrue() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: true)
        ]
        XCTAssertTrue(sut.isComplete)
    }

    func testIsComplete_WhenNotAllTaken_ReturnsFalse() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: false)
        ]
        XCTAssertFalse(sut.isComplete)
    }

    func testIsComplete_WhenEmpty_ReturnsFalse() {
        sut.todayDoses = []
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - Computed Properties Tests - Pending/Completed Doses

    func testPendingDoses_FiltersNotTaken() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true, name: "Taken1"),
            createMockTodayDose(isTaken: false, name: "Pending1"),
            createMockTodayDose(isTaken: false, name: "Pending2")
        ]
        XCTAssertEqual(sut.pendingDoses.count, 2)
    }

    func testCompletedDoses_FiltersTaken() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true, name: "Taken1"),
            createMockTodayDose(isTaken: true, name: "Taken2"),
            createMockTodayDose(isTaken: false, name: "Pending1")
        ]
        XCTAssertEqual(sut.completedDoses.count, 2)
    }

    func testOverdueDoses_FiltersOverdueOnly() {
        let calendar = Calendar.current
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: Date())!
        let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: Date())!

        sut.todayDoses = [
            createMockTodayDose(isTaken: false, scheduledTime: twoHoursAgo),
            createMockTodayDose(isTaken: false, scheduledTime: oneHourFromNow),
            createMockTodayDose(isTaken: true, scheduledTime: twoHoursAgo)
        ]

        // First one should be overdue (not taken and scheduled > 1 hour ago)
        XCTAssertEqual(sut.overdueDoses.count, 1)
    }

    // MARK: - Computed Properties Tests - supplementsByCategory (Legacy)

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

    // MARK: - Computed Properties Tests - Doses by Timing

    func testDosesByTiming_GroupsByTiming() {
        sut.todayDoses = [
            createMockTodayDose(timing: .morning),
            createMockTodayDose(timing: .morning),
            createMockTodayDose(timing: .evening),
            createMockTodayDose(timing: .beforeBed)
        ]

        let grouped = sut.dosesByTiming
        XCTAssertEqual(grouped.count, 3)

        let morningGroup = grouped.first { $0.0 == .morning }
        XCTAssertNotNil(morningGroup)
        XCTAssertEqual(morningGroup?.1.count, 2)
    }

    func testDosesByTiming_SortedBySortOrder() {
        sut.todayDoses = [
            createMockTodayDose(timing: .beforeBed),
            createMockTodayDose(timing: .morning),
            createMockTodayDose(timing: .postWorkout)
        ]

        let timings = sut.dosesByTiming.map { $0.0 }
        let sortOrders = timings.map { $0.sortOrder }

        for i in 0..<(sortOrders.count - 1) {
            XCTAssertLessThanOrEqual(sortOrders[i], sortOrders[i + 1])
        }
    }

    // MARK: - Computed Properties Tests - Next Dose

    func testNextDose_ReturnsFirstNonOverduePending() {
        let calendar = Calendar.current
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: Date())!
        let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: Date())!

        sut.todayDoses = [
            createMockTodayDose(isTaken: false, name: "Overdue", scheduledTime: twoHoursAgo),
            createMockTodayDose(isTaken: false, name: "Upcoming", scheduledTime: oneHourFromNow),
            createMockTodayDose(isTaken: true, name: "Taken", scheduledTime: oneHourFromNow)
        ]

        XCTAssertEqual(sut.nextDose?.supplementName, "Upcoming")
    }

    func testNextDose_WhenAllTaken_ReturnsNil() {
        sut.todayDoses = [
            createMockTodayDose(isTaken: true),
            createMockTodayDose(isTaken: true)
        ]
        XCTAssertNil(sut.nextDose)
    }

    // MARK: - Filtered Catalog Tests

    func testFilteredCatalog_NoFilters_ReturnsAll() {
        sut.catalog = CatalogSupplement.demoSupplements
        sut.searchText = ""
        sut.selectedCategory = nil

        XCTAssertEqual(sut.filteredCatalog.count, sut.catalog.count)
    }

    func testFilteredCatalog_FiltersBySearchText() {
        sut.catalog = CatalogSupplement.demoSupplements
        sut.searchText = "creatine"
        sut.selectedCategory = nil

        XCTAssertTrue(sut.filteredCatalog.allSatisfy {
            $0.name.lowercased().contains("creatine") ||
            ($0.brand?.lowercased().contains("creatine") ?? false) ||
            $0.benefits.contains { $0.lowercased().contains("creatine") }
        })
    }

    func testFilteredCatalog_FiltersByCategory() {
        sut.catalog = CatalogSupplement.demoSupplements
        sut.searchText = ""
        sut.selectedCategory = .performance

        XCTAssertTrue(sut.filteredCatalog.allSatisfy { $0.category == .performance })
    }

    func testFilteredCatalog_CombinesFilters() {
        sut.catalog = CatalogSupplement.demoSupplements
        sut.searchText = "strength"
        sut.selectedCategory = .performance

        XCTAssertTrue(sut.filteredCatalog.allSatisfy { $0.category == .performance })
        XCTAssertTrue(sut.filteredCatalog.allSatisfy { supplement in
            supplement.name.lowercased().contains("strength") ||
            supplement.benefits.contains { $0.lowercased().contains("strength") }
        })
    }

    // MARK: - Filtered Stacks Tests

    func testFilteredStacks_NoSearch_ReturnsAll() {
        sut.stacks = SupplementStack.demoStacks
        sut.searchText = ""

        XCTAssertEqual(sut.filteredStacks.count, sut.stacks.count)
    }

    func testFilteredStacks_FiltersBySearchText() {
        sut.stacks = SupplementStack.demoStacks
        sut.searchText = "athlete"

        XCTAssertTrue(sut.filteredStacks.allSatisfy {
            $0.name.lowercased().contains("athlete") ||
            $0.description.lowercased().contains("athlete")
        })
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

    func testShowingCatalogSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingCatalogSheet)
        sut.showingCatalogSheet = true
        XCTAssertTrue(sut.showingCatalogSheet)
    }

    func testShowingStackSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingStackSheet)
        sut.showingStackSheet = true
        XCTAssertTrue(sut.showingStackSheet)
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

    func testIsLoadingCatalog_CanBeSet() {
        XCTAssertFalse(sut.isLoadingCatalog)
        sut.isLoadingCatalog = true
        XCTAssertTrue(sut.isLoadingCatalog)
    }

    // MARK: - Clear Filters Tests

    func testClearFilters_ResetsAllFilters() {
        sut.searchText = "test"
        sut.selectedCategory = .performance
        sut.selectedTiming = .morning

        sut.clearFilters()

        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.selectedCategory)
        XCTAssertNil(sut.selectedTiming)
    }

    // MARK: - Prepare Add From Catalog Tests

    func testPrepareAddFromCatalog_SetsFormFields() {
        let catalog = CatalogSupplement.demoSupplements.first!

        sut.prepareAddFromCatalog(catalog)

        XCTAssertEqual(sut.selectedSupplement?.id, catalog.id)
        XCTAssertEqual(sut.routineDosage, catalog.dosageRange)
        XCTAssertNotNil(sut.routineTiming)
    }

    // MARK: - Summary Stats Tests

    func testCurrentStreak_FromCompliance() {
        sut.todayCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 5,
            skippedCount: 0,
            complianceRate: 1.0,
            streakDays: 7
        )

        XCTAssertEqual(sut.currentStreak, 7)
    }

    func testWeeklyComplianceRate_Calculation() {
        let dailyCompliance = (0..<7).map { _ in
            SupplementCompliance(
                id: UUID(),
                patientId: UUID(),
                date: Date(),
                plannedCount: 5,
                takenCount: 4,
                skippedCount: 0,
                complianceRate: 0.8,
                streakDays: 1
            )
        }

        sut.weeklyCompliance = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(sut.weeklyComplianceRate, 0.8, accuracy: 0.01)
    }

    func testFormattedWeeklyCompliance_FormatsAsPercentage() {
        let dailyCompliance = [
            SupplementCompliance(
                id: UUID(),
                patientId: UUID(),
                date: Date(),
                plannedCount: 5,
                takenCount: 4,
                skippedCount: 0,
                complianceRate: 0.8,
                streakDays: 1
            )
        ]

        sut.weeklyCompliance = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(sut.formattedWeeklyCompliance, "80%")
    }

    func testActiveSupplementCount_CountsActiveRoutines() {
        sut.routines = SupplementRoutine.demoRoutines
        XCTAssertEqual(sut.activeSupplementCount, sut.routines.filter { $0.isActive }.count)
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

    func testEmptySupplementList_HandledGracefully() {
        sut.supplements = []
        sut.todaySchedule = []
        sut.todayDoses = []

        XCTAssertEqual(sut.completionRate, 0)
        XCTAssertEqual(sut.todayProgress, 0)
        XCTAssertTrue(sut.pendingToday.isEmpty)
        XCTAssertTrue(sut.takenToday.isEmpty)
        XCTAssertTrue(sut.supplementsByCategory.isEmpty)
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

    // MARK: - Dose for Routine Tests

    func testDoseForRoutine_FindsMatchingDose() {
        let routineId = UUID()
        sut.todayDoses = [
            createMockTodayDose(routineId: UUID()),
            createMockTodayDose(routineId: routineId),
            createMockTodayDose(routineId: UUID())
        ]

        let dose = sut.dose(for: routineId)
        XCTAssertEqual(dose?.routineId, routineId)
    }

    func testDoseForRoutine_ReturnsNilIfNotFound() {
        sut.todayDoses = [
            createMockTodayDose(routineId: UUID())
        ]

        let dose = sut.dose(for: UUID())
        XCTAssertNil(dose)
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

    private func createMockTodayDose(
        isTaken: Bool = false,
        name: String = "Test Supplement",
        timing: SupplementTiming = .morning,
        scheduledTime: Date = Date(),
        routineId: UUID = UUID()
    ) -> TodaySupplementDose {
        return TodaySupplementDose(
            id: UUID(),
            routineId: routineId,
            supplementId: UUID(),
            supplementName: name,
            brand: nil,
            category: .vitamin,
            dosage: "500mg",
            timing: timing,
            scheduledTime: scheduledTime,
            withFood: false,
            isTaken: isTaken,
            takenAt: isTaken ? Date() : nil,
            logId: isTaken ? UUID() : nil
        )
    }
}

// MARK: - Adherence Tracking Tests

@MainActor
final class SupplementViewModelAdherenceTests: XCTestCase {

    var sut: SupplementViewModel!

    override func setUp() {
        super.setUp()
        sut = SupplementViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Daily Adherence Tests

    func testDailyAdherence_100Percent() {
        sut.todayDoses = (0..<5).map { _ in
            TodaySupplementDose(
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
                isTaken: true,
                takenAt: Date(),
                logId: UUID()
            )
        }

        XCTAssertEqual(sut.todayProgress, 1.0, accuracy: 0.01)
        XCTAssertTrue(sut.isComplete)
    }

    func testDailyAdherence_50Percent() {
        sut.todayDoses = [
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Taken",
                brand: nil,
                category: .vitamin,
                dosage: "1",
                timing: .morning,
                scheduledTime: Date(),
                withFood: false,
                isTaken: true,
                takenAt: Date(),
                logId: UUID()
            ),
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Pending",
                brand: nil,
                category: .vitamin,
                dosage: "1",
                timing: .evening,
                scheduledTime: Date(),
                withFood: false,
                isTaken: false,
                takenAt: nil,
                logId: nil
            )
        ]

        XCTAssertEqual(sut.todayProgress, 0.5, accuracy: 0.01)
        XCTAssertFalse(sut.isComplete)
    }

    func testDailyAdherence_ZeroPercent() {
        sut.todayDoses = (0..<3).map { _ in
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Pending",
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
        }

        XCTAssertEqual(sut.todayProgress, 0.0, accuracy: 0.01)
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - Weekly Adherence Tests

    func testWeeklyAdherence_AverageCalculation() {
        let dailyCompliance = [
            createCompliance(rate: 1.0),
            createCompliance(rate: 0.8),
            createCompliance(rate: 0.6),
            createCompliance(rate: 0.4),
            createCompliance(rate: 1.0),
            createCompliance(rate: 0.8),
            createCompliance(rate: 0.6)
        ]

        sut.weeklyCompliance = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        // Average of 1.0, 0.8, 0.6, 0.4, 1.0, 0.8, 0.6 = 5.2 / 7 = ~0.743
        let expectedAverage = (1.0 + 0.8 + 0.6 + 0.4 + 1.0 + 0.8 + 0.6) / 7.0
        XCTAssertEqual(sut.weeklyComplianceRate, expectedAverage, accuracy: 0.01)
    }

    func testWeeklyAdherence_CompleteDays() {
        let dailyCompliance = [
            createCompliance(rate: 1.0, takenCount: 5, plannedCount: 5),
            createCompliance(rate: 0.8, takenCount: 4, plannedCount: 5),
            createCompliance(rate: 1.0, takenCount: 5, plannedCount: 5),
            createCompliance(rate: 0.5, takenCount: 2, plannedCount: 4),
            createCompliance(rate: 1.0, takenCount: 3, plannedCount: 3),
            createCompliance(rate: 0.0, takenCount: 0, plannedCount: 5),
            createCompliance(rate: 1.0, takenCount: 5, plannedCount: 5)
        ]

        sut.weeklyCompliance = WeeklySupplementCompliance(
            weekStartDate: Date(),
            dailyCompliance: dailyCompliance
        )

        XCTAssertEqual(sut.weeklyCompliance?.completeDays, 4)
    }

    // MARK: - Streak Tracking Tests

    func testStreakTracking_FromCompliance() {
        sut.todayCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 5,
            skippedCount: 0,
            complianceRate: 1.0,
            streakDays: 14
        )

        XCTAssertEqual(sut.currentStreak, 14)
    }

    func testStreakTracking_FromAnalytics() {
        sut.analytics = SupplementAnalytics(
            totalSupplements: 5,
            activeRoutines: 3,
            weeklyComplianceRate: 0.85,
            monthlyComplianceRate: 0.80,
            currentStreak: 7,
            longestStreak: 30,
            topCategories: [],
            mostConsistent: [],
            leastConsistent: []
        )

        XCTAssertEqual(sut.currentStreak, 7)
    }

    func testStreakTracking_ComplianceTakesPrecedence() {
        sut.todayCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 5,
            takenCount: 5,
            skippedCount: 0,
            complianceRate: 1.0,
            streakDays: 10
        )

        sut.analytics = SupplementAnalytics(
            totalSupplements: 5,
            activeRoutines: 3,
            weeklyComplianceRate: 0.85,
            monthlyComplianceRate: 0.80,
            currentStreak: 7,
            longestStreak: 30,
            topCategories: [],
            mostConsistent: [],
            leastConsistent: []
        )

        // todayCompliance should take precedence
        XCTAssertEqual(sut.currentStreak, 10)
    }

    // MARK: - Helper Methods

    private func createCompliance(
        rate: Double,
        takenCount: Int = 5,
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
            streakDays: rate == 1.0 ? 1 : 0
        )
    }
}

// MARK: - Recommendation Handling Tests

@MainActor
final class SupplementViewModelRecommendationTests: XCTestCase {

    var sut: SupplementViewModel!

    override func setUp() {
        super.setUp()
        sut = SupplementViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCatalogByCategory_GroupsCorrectly() {
        sut.catalog = CatalogSupplement.demoSupplements
        sut.searchText = ""
        sut.selectedCategory = nil

        let grouped = sut.catalogByCategory
        XCTAssertFalse(grouped.isEmpty)

        // Verify each group contains only supplements of that category
        for (category, supplements) in grouped {
            XCTAssertTrue(supplements.allSatisfy { $0.category == category })
        }
    }

    func testCatalogByCategory_SortedByDisplayName() {
        sut.catalog = CatalogSupplement.demoSupplements

        let categories = sut.catalogByCategory.map { $0.0.displayName }
        let sortedCategories = categories.sorted()

        XCTAssertEqual(categories, sortedCategories)
    }

    func testRoutineCategories_UniqueAndSorted() {
        sut.routines = SupplementRoutine.demoRoutines

        let categories = sut.routineCategories
        let uniqueCategories = Array(Set(categories))

        // Should be unique
        XCTAssertEqual(categories.count, uniqueCategories.count)

        // Should be sorted by display name
        let names = categories.map { $0.displayName }
        XCTAssertEqual(names, names.sorted())
    }
}
