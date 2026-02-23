//
//  SupplementDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for SupplementDashboardViewModel
//  Tests initial state, computed properties, timing groups,
//  evidence grades, user goals, checklist operations,
//  error handling, streak celebration, and data models
//

import XCTest
@testable import PTPerformance

// MARK: - Supplement Dashboard ViewModel Tests

@MainActor
final class SupplementDashboardViewModelTests: XCTestCase {

    var sut: SupplementDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = SupplementDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_TodayChecklistIsEmpty() {
        XCTAssertTrue(sut.todayChecklist.isEmpty, "todayChecklist should be empty initially")
    }

    func testInitialState_MyStackIsEmpty() {
        XCTAssertTrue(sut.myStack.isEmpty, "myStack should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_SelectedSupplementForLogIsNil() {
        XCTAssertNil(sut.selectedSupplementForLog, "selectedSupplementForLog should be nil initially")
    }

    func testInitialState_GroupedChecklistIsEmpty() {
        XCTAssertTrue(sut.groupedChecklist.isEmpty, "groupedChecklist should be empty initially")
    }

    func testInitialState_RecommendationsIsEmpty() {
        XCTAssertTrue(sut.recommendations.isEmpty, "recommendations should be empty initially")
    }

    func testInitialState_EssentialRecommendationsIsEmpty() {
        XCTAssertTrue(sut.essentialRecommendations.isEmpty, "essentialRecommendations should be empty initially")
    }

    func testInitialState_HelpfulRecommendationsIsEmpty() {
        XCTAssertTrue(sut.helpfulRecommendations.isEmpty, "helpfulRecommendations should be empty initially")
    }

    func testInitialState_UserGoalIsBuildStrength() {
        XCTAssertEqual(sut.userGoal, .buildStrength, "userGoal should default to buildStrength")
    }

    func testInitialState_IsGeneratingRecommendationsIsFalse() {
        XCTAssertFalse(sut.isGeneratingRecommendations, "isGeneratingRecommendations should be false initially")
    }

    func testInitialState_IsLoggingItemIsNil() {
        XCTAssertNil(sut.isLoggingItem, "isLoggingItem should be nil initially")
    }

    func testInitialState_ShowErrorIsFalse() {
        XCTAssertFalse(sut.showError, "showError should be false initially")
    }

    func testInitialState_ErrorMessageIsEmpty() {
        XCTAssertEqual(sut.errorMessage, "", "errorMessage should be empty initially")
    }

    func testInitialState_CanRetryLastActionIsFalse() {
        XCTAssertFalse(sut.canRetryLastAction, "canRetryLastAction should be false initially")
    }

    func testInitialState_ShowStreakCelebrationIsFalse() {
        XCTAssertFalse(sut.showStreakCelebration, "showStreakCelebration should be false initially")
    }

    func testInitialState_StreakCelebrationMessageIsEmpty() {
        XCTAssertEqual(sut.streakCelebrationMessage, "", "streakCelebrationMessage should be empty initially")
    }

    // MARK: - Computed Properties Tests

    func testCompletedCount_WhenEmpty_ReturnsZero() {
        XCTAssertEqual(sut.completedCount, 0)
    }

    func testCompletedCount_CountsTakenItems() {
        sut.todayChecklist = [
            makeChecklistItem(isTaken: true),
            makeChecklistItem(isTaken: false),
            makeChecklistItem(isTaken: true)
        ]
        XCTAssertEqual(sut.completedCount, 2)
    }

    func testTotalCount_WhenEmpty_ReturnsZero() {
        XCTAssertEqual(sut.totalCount, 0)
    }

    func testTotalCount_ReturnsChecklistCount() {
        sut.todayChecklist = [
            makeChecklistItem(),
            makeChecklistItem(),
            makeChecklistItem()
        ]
        XCTAssertEqual(sut.totalCount, 3)
    }

    func testComplianceProgress_WhenEmpty_ReturnsZero() {
        XCTAssertEqual(sut.complianceProgress, 0)
    }

    func testComplianceProgress_AllCompleted_ReturnsOne() {
        sut.todayChecklist = [
            makeChecklistItem(isTaken: true),
            makeChecklistItem(isTaken: true)
        ]
        XCTAssertEqual(sut.complianceProgress, 1.0, accuracy: 0.01)
    }

    func testComplianceProgress_HalfCompleted() {
        sut.todayChecklist = [
            makeChecklistItem(isTaken: true),
            makeChecklistItem(isTaken: false)
        ]
        XCTAssertEqual(sut.complianceProgress, 0.5, accuracy: 0.01)
    }

    func testComplianceProgress_NoneCompleted_ReturnsZero() {
        sut.todayChecklist = [
            makeChecklistItem(isTaken: false),
            makeChecklistItem(isTaken: false),
            makeChecklistItem(isTaken: false)
        ]
        XCTAssertEqual(sut.complianceProgress, 0.0, accuracy: 0.01)
    }

    func testComplianceProgress_OneOfThree() {
        sut.todayChecklist = [
            makeChecklistItem(isTaken: true),
            makeChecklistItem(isTaken: false),
            makeChecklistItem(isTaken: false)
        ]
        XCTAssertEqual(sut.complianceProgress, 1.0 / 3.0, accuracy: 0.01)
    }

    // MARK: - Sorted Timing Groups Tests

    func testSortedTimingGroups_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.sortedTimingGroups.isEmpty)
    }

    func testSortedTimingGroups_SortsBySortOrder() {
        sut.groupedChecklist = [
            .evening: [makeChecklistItem(timing: .evening)],
            .morning: [makeChecklistItem(timing: .morning)],
            .preWorkout: [makeChecklistItem(timing: .preWorkout)]
        ]

        let sorted = sut.sortedTimingGroups
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0], .morning)
        XCTAssertEqual(sorted[1], .preWorkout)
        XCTAssertEqual(sorted[2], .evening)
    }

    // MARK: - Items for Group Tests

    func testItemsForGroup_ReturnsCorrectItems() {
        let morningItem = makeChecklistItem(timing: .morning)
        sut.groupedChecklist = [
            .morning: [morningItem]
        ]

        let items = sut.items(for: .morning)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, morningItem.id)
    }

    func testItemsForGroup_ReturnsEmptyForMissingGroup() {
        let items = sut.items(for: .morning)
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Group Completion Tests

    func testIsGroupComplete_WhenAllTaken_ReturnsTrue() {
        sut.groupedChecklist = [
            .morning: [
                makeChecklistItem(timing: .morning, isTaken: true),
                makeChecklistItem(timing: .morning, isTaken: true)
            ]
        ]
        XCTAssertTrue(sut.isGroupComplete(.morning))
    }

    func testIsGroupComplete_WhenNotAllTaken_ReturnsFalse() {
        sut.groupedChecklist = [
            .morning: [
                makeChecklistItem(timing: .morning, isTaken: true),
                makeChecklistItem(timing: .morning, isTaken: false)
            ]
        ]
        XCTAssertFalse(sut.isGroupComplete(.morning))
    }

    func testIsGroupComplete_WhenEmpty_ReturnsFalse() {
        XCTAssertFalse(sut.isGroupComplete(.morning))
    }

    func testCompletedCountForGroup_ReturnsCorrectCount() {
        sut.groupedChecklist = [
            .morning: [
                makeChecklistItem(timing: .morning, isTaken: true),
                makeChecklistItem(timing: .morning, isTaken: false),
                makeChecklistItem(timing: .morning, isTaken: true)
            ]
        ]
        XCTAssertEqual(sut.completedCount(for: .morning), 2)
    }

    func testTotalCountForGroup_ReturnsCorrectCount() {
        sut.groupedChecklist = [
            .evening: [
                makeChecklistItem(timing: .evening),
                makeChecklistItem(timing: .evening),
                makeChecklistItem(timing: .evening)
            ]
        ]
        XCTAssertEqual(sut.totalCount(for: .evening), 3)
    }

    func testTotalCountForGroup_EmptyGroup_ReturnsZero() {
        XCTAssertEqual(sut.totalCount(for: .evening), 0)
    }

    // MARK: - Error Handling Tests

    func testDismissError_ResetsAllErrorState() {
        sut.showError = true
        sut.errorMessage = "Something went wrong"
        sut.canRetryLastAction = true

        sut.dismissError()

        XCTAssertFalse(sut.showError)
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.canRetryLastAction)
    }

    // MARK: - Streak Celebration Tests

    func testDismissStreakCelebration_ResetsState() {
        sut.showStreakCelebration = true
        sut.streakCelebrationMessage = "7-day streak!"

        sut.dismissStreakCelebration()

        XCTAssertFalse(sut.showStreakCelebration)
        XCTAssertEqual(sut.streakCelebrationMessage, "")
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
    }

    func testPublishedProperties_ErrorCanBeSet() {
        sut.error = "Network error"
        XCTAssertEqual(sut.error, "Network error")
    }

    func testPublishedProperties_UserGoalCanBeSet() {
        sut.userGoal = .betterSleep
        XCTAssertEqual(sut.userGoal, .betterSleep)
    }

    func testPublishedProperties_IsGeneratingRecommendationsCanBeSet() {
        sut.isGeneratingRecommendations = true
        XCTAssertTrue(sut.isGeneratingRecommendations)
    }

    func testPublishedProperties_ShowErrorCanBeSet() {
        sut.showError = true
        XCTAssertTrue(sut.showError)
    }

    // MARK: - EvidenceGrade Tests

    func testEvidenceGrade_AllCasesCount() {
        XCTAssertEqual(EvidenceGrade.allCases.count, 4)
    }

    func testEvidenceGrade_RawValues() {
        XCTAssertEqual(EvidenceGrade.A.rawValue, "A")
        XCTAssertEqual(EvidenceGrade.B.rawValue, "B")
        XCTAssertEqual(EvidenceGrade.C.rawValue, "C")
        XCTAssertEqual(EvidenceGrade.D.rawValue, "D")
    }

    func testEvidenceGrade_DisplayNames() {
        XCTAssertEqual(EvidenceGrade.A.displayName, "Strong")
        XCTAssertEqual(EvidenceGrade.B.displayName, "Moderate")
        XCTAssertEqual(EvidenceGrade.C.displayName, "Preliminary")
        XCTAssertEqual(EvidenceGrade.D.displayName, "Weak")
    }

    func testEvidenceGrade_FullDescriptions() {
        for grade in EvidenceGrade.allCases {
            XCTAssertFalse(grade.fullDescription.isEmpty, "fullDescription should not be empty for \(grade)")
        }
    }

    func testEvidenceGrade_StarCounts() {
        XCTAssertEqual(EvidenceGrade.A.starCount, 5)
        XCTAssertEqual(EvidenceGrade.B.starCount, 4)
        XCTAssertEqual(EvidenceGrade.C.starCount, 3)
        XCTAssertEqual(EvidenceGrade.D.starCount, 2)
    }

    func testEvidenceGrade_Icons() {
        XCTAssertEqual(EvidenceGrade.A.icon, "checkmark.seal.fill")
        XCTAssertEqual(EvidenceGrade.B.icon, "checkmark.circle.fill")
        XCTAssertEqual(EvidenceGrade.C.icon, "arrow.up.right.circle.fill")
        XCTAssertEqual(EvidenceGrade.D.icon, "questionmark.circle.fill")
    }

    func testEvidenceGrade_Comparable_AIsLessThanB() {
        XCTAssertTrue(EvidenceGrade.A < EvidenceGrade.B, "A should sort before B")
    }

    func testEvidenceGrade_Comparable_BIsLessThanC() {
        XCTAssertTrue(EvidenceGrade.B < EvidenceGrade.C, "B should sort before C")
    }

    func testEvidenceGrade_Comparable_CIsLessThanD() {
        XCTAssertTrue(EvidenceGrade.C < EvidenceGrade.D, "C should sort before D")
    }

    func testEvidenceGrade_Identifiable() {
        for grade in EvidenceGrade.allCases {
            XCTAssertEqual(grade.id, grade.rawValue)
        }
    }

    func testEvidenceGrade_FromEvidenceRating_Strong() {
        XCTAssertEqual(EvidenceGrade.from(.strong), .A)
    }

    func testEvidenceGrade_FromEvidenceRating_Moderate() {
        XCTAssertEqual(EvidenceGrade.from(.moderate), .B)
    }

    func testEvidenceGrade_FromEvidenceRating_Emerging() {
        XCTAssertEqual(EvidenceGrade.from(.emerging), .C)
    }

    func testEvidenceGrade_FromEvidenceRating_Limited() {
        XCTAssertEqual(EvidenceGrade.from(.limited), .D)
    }

    // MARK: - SupplementTimingGroup Tests

    func testSupplementTimingGroup_AllCasesCount() {
        XCTAssertEqual(SupplementTimingGroup.allCases.count, 7)
    }

    func testSupplementTimingGroup_RawValues() {
        XCTAssertEqual(SupplementTimingGroup.morning.rawValue, "morning")
        XCTAssertEqual(SupplementTimingGroup.preWorkout.rawValue, "pre_workout")
        XCTAssertEqual(SupplementTimingGroup.postWorkout.rawValue, "post_workout")
        XCTAssertEqual(SupplementTimingGroup.withMeals.rawValue, "with_meals")
        XCTAssertEqual(SupplementTimingGroup.evening.rawValue, "evening")
        XCTAssertEqual(SupplementTimingGroup.beforeBed.rawValue, "before_bed")
        XCTAssertEqual(SupplementTimingGroup.anytime.rawValue, "anytime")
    }

    func testSupplementTimingGroup_DisplayNames() {
        XCTAssertEqual(SupplementTimingGroup.morning.displayName, "MORNING")
        XCTAssertEqual(SupplementTimingGroup.preWorkout.displayName, "PRE-WORKOUT")
        XCTAssertEqual(SupplementTimingGroup.postWorkout.displayName, "POST-WORKOUT")
        XCTAssertEqual(SupplementTimingGroup.withMeals.displayName, "WITH MEALS")
        XCTAssertEqual(SupplementTimingGroup.evening.displayName, "EVENING")
        XCTAssertEqual(SupplementTimingGroup.beforeBed.displayName, "BEFORE BED")
        XCTAssertEqual(SupplementTimingGroup.anytime.displayName, "ANYTIME")
    }

    func testSupplementTimingGroup_Subtitles() {
        XCTAssertEqual(SupplementTimingGroup.morning.subtitle, "with breakfast")
        XCTAssertEqual(SupplementTimingGroup.preWorkout.subtitle, "30min before")
        XCTAssertEqual(SupplementTimingGroup.postWorkout.subtitle, "within 1 hour")
        XCTAssertEqual(SupplementTimingGroup.withMeals.subtitle, "with any meal")
        XCTAssertEqual(SupplementTimingGroup.evening.subtitle, "with dinner")
        XCTAssertEqual(SupplementTimingGroup.beforeBed.subtitle, "30-60min before sleep")
        XCTAssertEqual(SupplementTimingGroup.anytime.subtitle, "when convenient")
    }

    func testSupplementTimingGroup_Icons() {
        XCTAssertEqual(SupplementTimingGroup.morning.icon, "sunrise.fill")
        XCTAssertEqual(SupplementTimingGroup.preWorkout.icon, "figure.run")
        XCTAssertEqual(SupplementTimingGroup.postWorkout.icon, "figure.cooldown")
        XCTAssertEqual(SupplementTimingGroup.withMeals.icon, "fork.knife")
        XCTAssertEqual(SupplementTimingGroup.evening.icon, "sunset.fill")
        XCTAssertEqual(SupplementTimingGroup.beforeBed.icon, "moon.fill")
        XCTAssertEqual(SupplementTimingGroup.anytime.icon, "clock.badge.checkmark.fill")
    }

    func testSupplementTimingGroup_SortOrder() {
        XCTAssertEqual(SupplementTimingGroup.morning.sortOrder, 0)
        XCTAssertEqual(SupplementTimingGroup.preWorkout.sortOrder, 1)
        XCTAssertEqual(SupplementTimingGroup.postWorkout.sortOrder, 2)
        XCTAssertEqual(SupplementTimingGroup.withMeals.sortOrder, 3)
        XCTAssertEqual(SupplementTimingGroup.evening.sortOrder, 4)
        XCTAssertEqual(SupplementTimingGroup.beforeBed.sortOrder, 5)
        XCTAssertEqual(SupplementTimingGroup.anytime.sortOrder, 6)
    }

    func testSupplementTimingGroup_SortOrderIsMonotonicallyIncreasing() {
        let allSortOrders = SupplementTimingGroup.allCases.map { $0.sortOrder }
        for i in 0..<(allSortOrders.count - 1) {
            XCTAssertLessThan(allSortOrders[i], allSortOrders[i + 1],
                              "Sort orders should be monotonically increasing")
        }
    }

    func testSupplementTimingGroup_Identifiable() {
        for group in SupplementTimingGroup.allCases {
            XCTAssertEqual(group.id, group.rawValue)
        }
    }

    // MARK: - SupplementTimingGroup.from() Mapping Tests

    func testTimingGroupFrom_Morning() {
        XCTAssertEqual(SupplementTimingGroup.from(.morning), .morning)
    }

    func testTimingGroupFrom_Afternoon() {
        XCTAssertEqual(SupplementTimingGroup.from(.afternoon), .withMeals)
    }

    func testTimingGroupFrom_PreWorkout() {
        XCTAssertEqual(SupplementTimingGroup.from(.preWorkout), .preWorkout)
    }

    func testTimingGroupFrom_PostWorkout() {
        XCTAssertEqual(SupplementTimingGroup.from(.postWorkout), .postWorkout)
    }

    func testTimingGroupFrom_WithMeal() {
        XCTAssertEqual(SupplementTimingGroup.from(.withMeal), .withMeals)
    }

    func testTimingGroupFrom_EmptyStomach() {
        XCTAssertEqual(SupplementTimingGroup.from(.emptyStomach), .withMeals)
    }

    func testTimingGroupFrom_Evening() {
        XCTAssertEqual(SupplementTimingGroup.from(.evening), .evening)
    }

    func testTimingGroupFrom_BeforeBed() {
        XCTAssertEqual(SupplementTimingGroup.from(.beforeBed), .beforeBed)
    }

    func testTimingGroupFrom_Anytime() {
        XCTAssertEqual(SupplementTimingGroup.from(.anytime), .anytime)
    }

    // MARK: - UserGoal Tests

    func testUserGoal_AllCasesCount() {
        XCTAssertEqual(UserGoal.allCases.count, 8)
    }

    func testUserGoal_RawValues() {
        XCTAssertEqual(UserGoal.buildStrength.rawValue, "build_strength")
        XCTAssertEqual(UserGoal.buildMuscle.rawValue, "build_muscle")
        XCTAssertEqual(UserGoal.improveRecovery.rawValue, "improve_recovery")
        XCTAssertEqual(UserGoal.betterSleep.rawValue, "better_sleep")
        XCTAssertEqual(UserGoal.moreEnergy.rawValue, "more_energy")
        XCTAssertEqual(UserGoal.fatLoss.rawValue, "fat_loss")
        XCTAssertEqual(UserGoal.generalHealth.rawValue, "general_health")
        XCTAssertEqual(UserGoal.cognition.rawValue, "cognition")
    }

    func testUserGoal_DisplayNames() {
        XCTAssertEqual(UserGoal.buildStrength.displayName, "Build Strength")
        XCTAssertEqual(UserGoal.buildMuscle.displayName, "Build Muscle")
        XCTAssertEqual(UserGoal.improveRecovery.displayName, "Improve Recovery")
        XCTAssertEqual(UserGoal.betterSleep.displayName, "Better Sleep")
        XCTAssertEqual(UserGoal.moreEnergy.displayName, "More Energy")
        XCTAssertEqual(UserGoal.fatLoss.displayName, "Fat Loss")
        XCTAssertEqual(UserGoal.generalHealth.displayName, "General Health")
        XCTAssertEqual(UserGoal.cognition.displayName, "Cognitive Performance")
    }

    func testUserGoal_Icons() {
        XCTAssertEqual(UserGoal.buildStrength.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(UserGoal.buildMuscle.icon, "figure.arms.open")
        XCTAssertEqual(UserGoal.improveRecovery.icon, "heart.fill")
        XCTAssertEqual(UserGoal.betterSleep.icon, "moon.fill")
        XCTAssertEqual(UserGoal.moreEnergy.icon, "bolt.fill")
        XCTAssertEqual(UserGoal.fatLoss.icon, "flame.fill")
        XCTAssertEqual(UserGoal.generalHealth.icon, "cross.case.fill")
        XCTAssertEqual(UserGoal.cognition.icon, "brain.head.profile")
    }

    func testUserGoal_Identifiable() {
        for goal in UserGoal.allCases {
            XCTAssertEqual(goal.id, goal.rawValue)
        }
    }

    func testUserGoal_DisplayNamesNotEmpty() {
        for goal in UserGoal.allCases {
            XCTAssertFalse(goal.displayName.isEmpty, "displayName should not be empty for \(goal)")
        }
    }

    func testUserGoal_IconsNotEmpty() {
        for goal in UserGoal.allCases {
            XCTAssertFalse(goal.icon.isEmpty, "icon should not be empty for \(goal)")
        }
    }

    // MARK: - GoalBasedRecommendation Model Tests

    func testGoalBasedRecommendation_Initialization() {
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "+12-20% strength gains",
            dosage: "5g daily",
            timing: .postWorkout
        )

        XCTAssertEqual(rec.supplementName, "Creatine")
        XCTAssertEqual(rec.category, .performance)
        XCTAssertEqual(rec.evidenceGrade, .A)
        XCTAssertEqual(rec.benefit, "+12-20% strength gains")
        XCTAssertEqual(rec.dosage, "5g daily")
        XCTAssertEqual(rec.timing, .postWorkout)
        XCTAssertFalse(rec.isInStack)
        XCTAssertNil(rec.catalogSupplementId)
    }

    func testGoalBasedRecommendation_WithIsInStack() {
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout,
            isInStack: true
        )
        XCTAssertTrue(rec.isInStack)
    }

    func testGoalBasedRecommendation_WithCatalogId() {
        let catalogId = UUID()
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout,
            catalogSupplementId: catalogId
        )
        XCTAssertEqual(rec.catalogSupplementId, catalogId)
    }

    func testGoalBasedRecommendation_Hashable() {
        let id = UUID()
        let rec1 = GoalBasedRecommendation(
            id: id,
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout
        )
        let rec2 = GoalBasedRecommendation(
            id: id,
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout
        )
        XCTAssertEqual(rec1, rec2)
    }

    func testGoalBasedRecommendation_Identifiable() {
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout
        )
        XCTAssertNotNil(rec.id)
    }

    // MARK: - SupplementChecklistItem Model Tests

    func testSupplementChecklistItem_Initialization() {
        let supplement = makeRoutineSupplement()
        let item = SupplementChecklistItem(
            id: UUID(),
            supplement: supplement,
            timing: .morning,
            dosage: "5g",
            isTaken: false,
            takenAt: nil,
            logId: nil
        )

        XCTAssertEqual(item.timing, .morning)
        XCTAssertEqual(item.dosage, "5g")
        XCTAssertFalse(item.isTaken)
        XCTAssertNil(item.takenAt)
        XCTAssertNil(item.logId)
    }

    func testSupplementChecklistItem_Equatable_ById() {
        let id = UUID()
        let item1 = SupplementChecklistItem(
            id: id,
            supplement: makeRoutineSupplement(name: "A"),
            timing: .morning,
            dosage: "5g",
            isTaken: false
        )
        let item2 = SupplementChecklistItem(
            id: id,
            supplement: makeRoutineSupplement(name: "B"),
            timing: .evening,
            dosage: "10g",
            isTaken: true
        )
        XCTAssertEqual(item1, item2, "Items with same ID should be equal")
    }

    func testSupplementChecklistItem_NotEqual_DifferentId() {
        let item1 = SupplementChecklistItem(
            id: UUID(),
            supplement: makeRoutineSupplement(),
            timing: .morning,
            dosage: "5g",
            isTaken: false
        )
        let item2 = SupplementChecklistItem(
            id: UUID(),
            supplement: makeRoutineSupplement(),
            timing: .morning,
            dosage: "5g",
            isTaken: false
        )
        XCTAssertNotEqual(item1, item2, "Items with different IDs should not be equal")
    }

    func testSupplementChecklistItem_Hashable() {
        let id = UUID()
        let item1 = SupplementChecklistItem(
            id: id,
            supplement: makeRoutineSupplement(),
            timing: .morning,
            dosage: "5g",
            isTaken: false
        )
        let item2 = SupplementChecklistItem(
            id: id,
            supplement: makeRoutineSupplement(),
            timing: .morning,
            dosage: "5g",
            isTaken: false
        )

        var set = Set<SupplementChecklistItem>()
        set.insert(item1)
        set.insert(item2)
        XCTAssertEqual(set.count, 1, "Items with same ID should hash to same value")
    }

    // MARK: - RoutineSupplement Model Tests

    func testRoutineSupplement_DisplayName_WithBrand() {
        let supplement = RoutineSupplement(
            name: "Creatine",
            brand: "Momentous",
            category: .performance
        )
        XCTAssertEqual(supplement.displayName, "Momentous Creatine")
    }

    func testRoutineSupplement_DisplayName_WithoutBrand() {
        let supplement = RoutineSupplement(
            name: "Creatine",
            brand: nil,
            category: .performance
        )
        XCTAssertEqual(supplement.displayName, "Creatine")
    }

    func testRoutineSupplement_DefaultValues() {
        let supplement = RoutineSupplement(
            name: "Test",
            category: .health
        )
        XCTAssertNil(supplement.brand)
        XCTAssertNil(supplement.dosage)
        XCTAssertNil(supplement.timing)
        XCTAssertNil(supplement.days)
        XCTAssertFalse(supplement.withFood)
        XCTAssertFalse(supplement.reminderEnabled)
    }

    // MARK: - EvidenceRating Tests

    func testEvidenceRating_AllCasesCount() {
        XCTAssertEqual(EvidenceRating.allCases.count, 4)
    }

    func testEvidenceRating_RawValues() {
        XCTAssertEqual(EvidenceRating.strong.rawValue, "strong")
        XCTAssertEqual(EvidenceRating.moderate.rawValue, "moderate")
        XCTAssertEqual(EvidenceRating.emerging.rawValue, "emerging")
        XCTAssertEqual(EvidenceRating.limited.rawValue, "limited")
    }

    func testEvidenceRating_DisplayNames() {
        XCTAssertEqual(EvidenceRating.strong.displayName, "Strong Evidence")
        XCTAssertEqual(EvidenceRating.moderate.displayName, "Moderate Evidence")
        XCTAssertEqual(EvidenceRating.emerging.displayName, "Emerging Research")
        XCTAssertEqual(EvidenceRating.limited.displayName, "Limited Evidence")
    }

    func testEvidenceRating_ShortNames() {
        XCTAssertEqual(EvidenceRating.strong.shortName, "Strong")
        XCTAssertEqual(EvidenceRating.moderate.shortName, "Moderate")
        XCTAssertEqual(EvidenceRating.emerging.shortName, "Emerging")
        XCTAssertEqual(EvidenceRating.limited.shortName, "Limited")
    }

    func testEvidenceRating_Comparable() {
        XCTAssertTrue(EvidenceRating.strong < EvidenceRating.moderate)
        XCTAssertTrue(EvidenceRating.moderate < EvidenceRating.emerging)
        XCTAssertTrue(EvidenceRating.emerging < EvidenceRating.limited)
    }

    func testEvidenceRating_SortOrders() {
        XCTAssertEqual(EvidenceRating.strong.sortOrder, 0)
        XCTAssertEqual(EvidenceRating.moderate.sortOrder, 1)
        XCTAssertEqual(EvidenceRating.emerging.sortOrder, 2)
        XCTAssertEqual(EvidenceRating.limited.sortOrder, 3)
    }

    // MARK: - SupplementTiming Tests

    func testSupplementTiming_AllCasesCount() {
        XCTAssertEqual(SupplementTiming.allCases.count, 9)
    }

    func testSupplementTiming_DisplayNames() {
        XCTAssertEqual(SupplementTiming.morning.displayName, "Morning")
        XCTAssertEqual(SupplementTiming.afternoon.displayName, "Afternoon")
        XCTAssertEqual(SupplementTiming.preWorkout.displayName, "Pre-Workout")
        XCTAssertEqual(SupplementTiming.postWorkout.displayName, "Post-Workout")
        XCTAssertEqual(SupplementTiming.evening.displayName, "Evening")
        XCTAssertEqual(SupplementTiming.beforeBed.displayName, "Before Bed")
        XCTAssertEqual(SupplementTiming.withMeal.displayName, "With Meal")
        XCTAssertEqual(SupplementTiming.emptyStomach.displayName, "Empty Stomach")
        XCTAssertEqual(SupplementTiming.anytime.displayName, "Anytime")
    }

    func testSupplementTiming_SortOrders() {
        let timings = SupplementTiming.allCases.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(timings.first, .morning)
        XCTAssertEqual(timings.last, .anytime)
    }

    func testSupplementTiming_ApproximateHours() {
        XCTAssertEqual(SupplementTiming.morning.approximateHour, 7)
        XCTAssertEqual(SupplementTiming.preWorkout.approximateHour, 6)
        XCTAssertEqual(SupplementTiming.postWorkout.approximateHour, 8)
        XCTAssertEqual(SupplementTiming.beforeBed.approximateHour, 21)
    }

    // MARK: - SupplementCatalogCategory Tests

    func testSupplementCatalogCategory_AllCasesCount() {
        XCTAssertEqual(SupplementCatalogCategory.allCases.count, 13)
    }

    func testSupplementCatalogCategory_DisplayNames() {
        XCTAssertEqual(SupplementCatalogCategory.performance.displayName, "Performance")
        XCTAssertEqual(SupplementCatalogCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(SupplementCatalogCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(SupplementCatalogCategory.health.displayName, "General Health")
        XCTAssertEqual(SupplementCatalogCategory.vitamin.displayName, "Vitamins")
        XCTAssertEqual(SupplementCatalogCategory.mineral.displayName, "Minerals")
        XCTAssertEqual(SupplementCatalogCategory.protein.displayName, "Protein")
        XCTAssertEqual(SupplementCatalogCategory.preworkout.displayName, "Pre-Workout")
        XCTAssertEqual(SupplementCatalogCategory.cognitive.displayName, "Cognitive")
        XCTAssertEqual(SupplementCatalogCategory.hormonal.displayName, "Hormonal Support")
        XCTAssertEqual(SupplementCatalogCategory.joint.displayName, "Joint Health")
        XCTAssertEqual(SupplementCatalogCategory.digestive.displayName, "Digestive")
        XCTAssertEqual(SupplementCatalogCategory.other.displayName, "Other")
    }

    func testSupplementCatalogCategory_IconsNotEmpty() {
        for category in SupplementCatalogCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "icon should not be empty for \(category)")
        }
    }

    func testSupplementCatalogCategory_Identifiable() {
        for category in SupplementCatalogCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: - DosageUnit Tests

    func testDosageUnit_AllCasesCount() {
        XCTAssertEqual(DosageUnit.allCases.count, 11)
    }

    func testDosageUnit_DisplayNames() {
        XCTAssertEqual(DosageUnit.mg.displayName, "mg")
        XCTAssertEqual(DosageUnit.g.displayName, "g")
        XCTAssertEqual(DosageUnit.mcg.displayName, "mcg")
        XCTAssertEqual(DosageUnit.iu.displayName, "IU")
        XCTAssertEqual(DosageUnit.ml.displayName, "ml")
        XCTAssertEqual(DosageUnit.capsule.displayName, "capsule")
        XCTAssertEqual(DosageUnit.tablet.displayName, "tablet")
        XCTAssertEqual(DosageUnit.scoop.displayName, "scoop")
    }

    func testDosageUnit_AbbreviationEqualsDisplayName() {
        for unit in DosageUnit.allCases {
            XCTAssertEqual(unit.abbreviation, unit.displayName)
        }
    }

    // MARK: - Dosage Model Tests

    func testDosage_DisplayString_WholeNumber() {
        let dosage = Dosage(amount: 500, unit: .mg)
        XCTAssertEqual(dosage.displayString, "500 mg")
    }

    func testDosage_DisplayString_DecimalNumber() {
        let dosage = Dosage(amount: 2.5, unit: .g)
        XCTAssertEqual(dosage.displayString, "2.5 g")
    }

    func testDosage_DisplayString_ZeroAmount() {
        let dosage = Dosage(amount: 0, unit: .mg)
        XCTAssertEqual(dosage.displayString, "0 mg")
    }

    func testDosage_DisplayString_LargeNumber() {
        let dosage = Dosage(amount: 5000, unit: .iu)
        XCTAssertEqual(dosage.displayString, "5000 IU")
    }

    func testDosage_Hashable() {
        let dosage1 = Dosage(amount: 500, unit: .mg)
        let dosage2 = Dosage(amount: 500, unit: .mg)
        XCTAssertEqual(dosage1, dosage2)
    }

    func testDosage_NotEqual() {
        let dosage1 = Dosage(amount: 500, unit: .mg)
        let dosage2 = Dosage(amount: 1000, unit: .mg)
        XCTAssertNotEqual(dosage1, dosage2)
    }

    func testDosage_DifferentUnitsNotEqual() {
        let dosage1 = Dosage(amount: 500, unit: .mg)
        let dosage2 = Dosage(amount: 500, unit: .mcg)
        XCTAssertNotEqual(dosage1, dosage2)
    }

    // MARK: - Compliance Progress Edge Cases

    func testComplianceProgress_SingleItemCompleted() {
        sut.todayChecklist = [makeChecklistItem(isTaken: true)]
        XCTAssertEqual(sut.complianceProgress, 1.0, accuracy: 0.01)
    }

    func testComplianceProgress_SingleItemNotCompleted() {
        sut.todayChecklist = [makeChecklistItem(isTaken: false)]
        XCTAssertEqual(sut.complianceProgress, 0.0, accuracy: 0.01)
    }

    func testComplianceProgress_LargeChecklist() {
        var items = [SupplementChecklistItem]()
        for i in 0..<100 {
            items.append(makeChecklistItem(isTaken: i < 75))
        }
        sut.todayChecklist = items
        XCTAssertEqual(sut.complianceProgress, 0.75, accuracy: 0.01)
    }

    // MARK: - Grouped Checklist State Tests

    func testGroupedChecklist_CanBeSetDirectly() {
        let item = makeChecklistItem(timing: .morning)
        sut.groupedChecklist = [.morning: [item]]

        XCTAssertEqual(sut.groupedChecklist.count, 1)
        XCTAssertEqual(sut.groupedChecklist[.morning]?.count, 1)
    }

    func testGroupedChecklist_MultipleGroups() {
        let morningItem = makeChecklistItem(timing: .morning)
        let eveningItem = makeChecklistItem(timing: .evening)
        let bedItem = makeChecklistItem(timing: .beforeBed)

        sut.groupedChecklist = [
            .morning: [morningItem],
            .evening: [eveningItem],
            .beforeBed: [bedItem]
        ]

        XCTAssertEqual(sut.groupedChecklist.count, 3)
        XCTAssertEqual(sut.sortedTimingGroups, [.morning, .evening, .beforeBed])
    }

    // MARK: - Recommendations State Tests

    func testRecommendations_CanBeSet() {
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout
        )
        sut.recommendations = [rec]
        XCTAssertEqual(sut.recommendations.count, 1)
    }

    func testEssentialRecommendations_CanBeSet() {
        let rec = GoalBasedRecommendation(
            supplementName: "Creatine",
            category: .performance,
            evidenceGrade: .A,
            benefit: "Strength",
            dosage: "5g",
            timing: .postWorkout
        )
        sut.essentialRecommendations = [rec]
        XCTAssertEqual(sut.essentialRecommendations.count, 1)
    }

    func testHelpfulRecommendations_CanBeSet() {
        let rec = GoalBasedRecommendation(
            supplementName: "Ashwagandha",
            category: .cognitive,
            evidenceGrade: .C,
            benefit: "Stress reduction",
            dosage: "600mg",
            timing: .evening
        )
        sut.helpfulRecommendations = [rec]
        XCTAssertEqual(sut.helpfulRecommendations.count, 1)
    }

    // MARK: - MyStack Tests

    func testMyStack_CanBePopulated() {
        let supplement1 = makeRoutineSupplement(name: "Creatine")
        let supplement2 = makeRoutineSupplement(name: "Vitamin D")

        sut.myStack = [supplement1, supplement2]
        XCTAssertEqual(sut.myStack.count, 2)
        XCTAssertEqual(sut.myStack[0].name, "Creatine")
        XCTAssertEqual(sut.myStack[1].name, "Vitamin D")
    }

    // MARK: - Helper Methods

    /// Creates a minimal RoutineSupplement for testing
    private func makeRoutineSupplement(
        name: String = "Test Supplement",
        brand: String? = nil,
        category: SupplementCatalogCategory = .performance,
        dosage: Dosage? = nil,
        timing: SupplementTiming? = nil
    ) -> RoutineSupplement {
        RoutineSupplement(
            id: UUID(),
            name: name,
            brand: brand,
            category: category,
            dosage: dosage,
            timing: timing
        )
    }

    /// Creates a minimal SupplementChecklistItem for testing
    private func makeChecklistItem(
        timing: SupplementTiming = .morning,
        dosage: String = "500mg",
        isTaken: Bool = false,
        takenAt: Date? = nil,
        logId: UUID? = nil
    ) -> SupplementChecklistItem {
        SupplementChecklistItem(
            id: UUID(),
            supplement: makeRoutineSupplement(timing: timing),
            timing: timing,
            dosage: dosage,
            isTaken: isTaken,
            takenAt: takenAt,
            logId: logId
        )
    }
}
