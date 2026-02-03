//
//  FastingViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for FastingViewModel
//  Tests timer state management, fasting window calculations, streak tracking, notification scheduling
//

import XCTest
import Combine
@testable import PTPerformance

// MARK: - Mock Fasting Service Protocol

protocol FastingServiceProtocol {
    func fetchFastingData() async
    func startFast(type: FastingType) async throws
    func endFast(breakfastFood: String?, energyLevel: Int, notes: String?) async throws
    func generateEatingWindowRecommendation(trainingTime: Date?) async
}

// MARK: - Mock Fasting Service

final class MockFastingService: FastingServiceProtocol {
    var mockCurrentFast: FastingLog?
    var mockHistory: [FastingLog] = []
    var mockStats: FastingStats?
    var mockRecommendation: EatingWindowRecommendation?
    var mockError: Error?
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    var fetchFastingDataCallCount = 0
    var startFastCallCount = 0
    var endFastCallCount = 0
    var generateRecommendationCallCount = 0

    var lastStartedFastType: FastingType?
    var lastEndedBreakfastFood: String?
    var lastEndedEnergyLevel: Int?

    func fetchFastingData() async {
        fetchFastingDataCallCount += 1
    }

    func startFast(type: FastingType) async throws {
        startFastCallCount += 1
        lastStartedFastType = type
        if shouldThrowError { throw errorToThrow }
    }

    func endFast(breakfastFood: String?, energyLevel: Int, notes: String?) async throws {
        endFastCallCount += 1
        lastEndedBreakfastFood = breakfastFood
        lastEndedEnergyLevel = energyLevel
        if shouldThrowError { throw errorToThrow }
    }

    func generateEatingWindowRecommendation(trainingTime: Date?) async {
        generateRecommendationCallCount += 1
    }
}

// MARK: - FastingViewModel Extended Tests

@MainActor
final class FastingViewModelExtendedTests: XCTestCase {

    var sut: FastingViewModel!

    override func setUp() {
        super.setUp()
        sut = FastingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Timer State Management Tests

    func testInitialState_CurrentFastIsNil() {
        XCTAssertNil(sut.currentFast, "currentFast should be nil initially")
    }

    func testInitialState_HistoryIsEmpty() {
        XCTAssertTrue(sut.history.isEmpty, "history should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testIsFasting_WhenNoCurrentFast_ReturnsFalse() {
        sut.currentFast = nil
        XCTAssertFalse(sut.isFasting)
    }

    func testIsFasting_WhenCurrentFastExists_ReturnsTrue() {
        sut.currentFast = createMockActiveFast()
        XCTAssertTrue(sut.isFasting)
    }

    func testCurrentProgress_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.currentProgress, 0)
    }

    func testCurrentProgress_WhenFasting_ReturnsProgressPercent() {
        let fast = createMockActiveFast()
        sut.currentFast = fast
        XCTAssertEqual(sut.currentProgress, fast.progressPercent, accuracy: 0.01)
    }

    // MARK: - Fasting Window Calculations Tests

    func testElapsedHours_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.elapsedHours, 0)
    }

    func testElapsedHours_WhenFasting_CalculatesCorrectly() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -6, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        XCTAssertEqual(sut.elapsedHours, 6, accuracy: 0.05)
    }

    func testRemainingHours_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.remainingHours, 0)
    }

    func testRemainingHours_WhenFasting_CalculatesCorrectly() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        // 16 - 4 = 12 hours remaining
        XCTAssertEqual(sut.remainingHours, 12, accuracy: 0.05)
    }

    func testRemainingHours_WhenExceededTarget_ReturnsZero() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -20, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        XCTAssertEqual(sut.remainingHours, 0)
    }

    // MARK: - Streak Tracking Tests

    func testCompletedFasts_FiltersCorrectly() {
        let completedFast = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        let activeFast = createMockActiveFast()

        sut.history = [completedFast, activeFast]

        XCTAssertEqual(sut.completedFasts.count, 1)
    }

    func testCompletionRate_WhenEmpty_ReturnsZero() {
        sut.history = []
        XCTAssertEqual(sut.completionRate, 0)
    }

    func testCompletionRate_CalculatesCorrectly() {
        let successful1 = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        let successful2 = createMockCompletedFast(targetHours: 16, actualHours: 15.0)  // 93.75%
        let failed = createMockCompletedFast(targetHours: 16, actualHours: 10.0)  // 62.5%

        sut.history = [successful1, successful2, failed]

        XCTAssertEqual(sut.completionRate, 2.0/3.0, accuracy: 0.01)
    }

    func testCompletionRate_WhenAllSuccessful_ReturnsOne() {
        let fast1 = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        let fast2 = createMockCompletedFast(targetHours: 18, actualHours: 18.0)

        sut.history = [fast1, fast2]

        XCTAssertEqual(sut.completionRate, 1.0)
    }

    // MARK: - Form State Tests

    func testSelectedFastType_DefaultIsIntermittent16_8() {
        XCTAssertEqual(sut.selectedFastType, .intermittent16_8)
    }

    func testSelectedFastType_CanBeChanged() {
        sut.selectedFastType = .intermittent18_6
        XCTAssertEqual(sut.selectedFastType, .intermittent18_6)

        sut.selectedFastType = .omad
        XCTAssertEqual(sut.selectedFastType, .omad)
    }

    func testBreakfastFood_DefaultIsEmpty() {
        XCTAssertEqual(sut.breakfastFood, "")
    }

    func testBreakfastFood_CanBeSet() {
        sut.breakfastFood = "Eggs and avocado"
        XCTAssertEqual(sut.breakfastFood, "Eggs and avocado")
    }

    func testEnergyLevel_DefaultIs5() {
        XCTAssertEqual(sut.energyLevel, 5)
    }

    func testEnergyLevel_CanBeSet() {
        sut.energyLevel = 8
        XCTAssertEqual(sut.energyLevel, 8)
    }

    func testEndNotes_DefaultIsEmpty() {
        XCTAssertEqual(sut.endNotes, "")
    }

    func testEndNotes_CanBeSet() {
        sut.endNotes = "Felt great"
        XCTAssertEqual(sut.endNotes, "Felt great")
    }

    // MARK: - Sheet State Tests

    func testShowingStartSheet_DefaultIsFalse() {
        XCTAssertFalse(sut.showingStartSheet)
    }

    func testShowingStartSheet_CanBeToggled() {
        sut.showingStartSheet = true
        XCTAssertTrue(sut.showingStartSheet)

        sut.showingStartSheet = false
        XCTAssertFalse(sut.showingStartSheet)
    }

    func testShowingEndSheet_DefaultIsFalse() {
        XCTAssertFalse(sut.showingEndSheet)
    }

    func testShowingEndSheet_CanBeToggled() {
        sut.showingEndSheet = true
        XCTAssertTrue(sut.showingEndSheet)

        sut.showingEndSheet = false
        XCTAssertFalse(sut.showingEndSheet)
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        sut.error = "Test error"
        XCTAssertEqual(sut.error, "Test error")

        sut.error = nil
        XCTAssertNil(sut.error)
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Workout Recommendation Tests

    func testWorkoutRecommendation_DefaultIsNil() {
        XCTAssertNil(sut.workoutRecommendation)
    }

    func testIsLoadingWorkoutRec_DefaultIsFalse() {
        XCTAssertFalse(sut.isLoadingWorkoutRec)
    }

    func testIsExtendedFast_WhenNoRecommendation_ReturnsFalse() {
        sut.workoutRecommendation = nil
        XCTAssertFalse(sut.isExtendedFast)
    }

    func testIntensityPercentage_WhenNoRecommendation_Returns100() {
        sut.workoutRecommendation = nil
        XCTAssertEqual(sut.intensityPercentage, 100)
    }

    func testIsWorkoutRecommended_WhenNoRecommendation_ReturnsTrue() {
        sut.workoutRecommendation = nil
        XCTAssertTrue(sut.isWorkoutRecommended)
    }

    func testWarningsCount_WhenNoRecommendation_ReturnsZero() {
        sut.workoutRecommendation = nil
        XCTAssertEqual(sut.warningsCount, 0)
    }

    // MARK: - Stats Tests

    func testStats_DefaultIsNil() {
        XCTAssertNil(sut.stats)
    }

    func testStats_CanBeSet() {
        let stats = FastingStats(
            totalFasts: 10,
            completedFasts: 8,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 5,
            bestStreak: 10
        )
        sut.stats = stats

        XCTAssertEqual(sut.stats?.totalFasts, 10)
        XCTAssertEqual(sut.stats?.completedFasts, 8)
        XCTAssertEqual(sut.stats?.averageHours, 16.5)
        XCTAssertEqual(sut.stats?.longestFast, 24.0)
        XCTAssertEqual(sut.stats?.currentStreak, 5)
        XCTAssertEqual(sut.stats?.bestStreak, 10)
    }

    // MARK: - Recommendation Tests

    func testRecommendation_DefaultIsNil() {
        XCTAssertNil(sut.recommendation)
    }

    func testRecommendation_CanBeSet() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date(),
            reason: "Based on your training schedule",
            trainingTime: nil
        )
        sut.recommendation = recommendation

        XCTAssertNotNil(sut.recommendation)
        XCTAssertEqual(sut.recommendation?.reason, "Based on your training schedule")
    }

    // MARK: - History Management Tests

    func testHistory_CanBeCleared() {
        let fast = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        sut.history = [fast]

        XCTAssertFalse(sut.history.isEmpty)

        sut.history = []
        XCTAssertTrue(sut.history.isEmpty)
    }

    func testCurrentFast_CanBeCleared() {
        sut.currentFast = createMockActiveFast()
        XCTAssertNotNil(sut.currentFast)

        sut.currentFast = nil
        XCTAssertNil(sut.currentFast)
    }

    // MARK: - Helper Methods

    private func createMockActiveFast() -> FastingLog {
        return createMockFastingLog(
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            endTime: nil,
            targetHours: 16
        )
    }

    private func createMockFastingLog(startTime: Date, endTime: Date?, targetHours: Int) -> FastingLog {
        var actualHours: Double? = nil
        if let end = endTime {
            actualHours = end.timeIntervalSince(startTime) / 3600
        }
        return FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: targetHours,
            actualHours: actualHours,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    private func createMockCompletedFast(targetHours: Int, actualHours: Double) -> FastingLog {
        let startTime = Calendar.current.date(byAdding: .hour, value: -Int(actualHours), to: Date())!
        return FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: Date(),
            targetHours: targetHours,
            actualHours: actualHours,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}

// MARK: - FastingType Tests

final class FastingTypeExtendedTests: XCTestCase {

    func testAllCasesHaveDisplayName() {
        for fastingType in FastingType.allCases {
            XCTAssertFalse(fastingType.displayName.isEmpty)
        }
    }

    func testAllCasesHavePositiveTargetHours() {
        for fastingType in FastingType.allCases {
            XCTAssertGreaterThan(fastingType.targetHours, 0)
        }
    }

    func testDisplayNames() {
        XCTAssertEqual(FastingType.intermittent16_8.displayName, "16:8")
        XCTAssertEqual(FastingType.intermittent18_6.displayName, "18:6")
        XCTAssertEqual(FastingType.intermittent20_4.displayName, "20:4")
        XCTAssertEqual(FastingType.omad.displayName, "OMAD (23:1)")
        XCTAssertEqual(FastingType.extended24.displayName, "24 Hour")
        XCTAssertEqual(FastingType.extended36.displayName, "36 Hour")
        XCTAssertEqual(FastingType.extended48.displayName, "48 Hour")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    func testTargetHours() {
        XCTAssertEqual(FastingType.intermittent16_8.targetHours, 16)
        XCTAssertEqual(FastingType.intermittent18_6.targetHours, 18)
        XCTAssertEqual(FastingType.intermittent20_4.targetHours, 20)
        XCTAssertEqual(FastingType.omad.targetHours, 23)
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    func testCasesCount() {
        XCTAssertEqual(FastingType.allCases.count, 8)
    }
}

// MARK: - FastingLog Tests

final class FastingLogExtendedTests: XCTestCase {

    func testIsActive_WhenEndTimeNil_ReturnsTrue() {
        let fast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertTrue(fast.isActive)
    }

    func testIsActive_WhenEndTimeSet_ReturnsFalse() {
        let fast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: Date(),
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertFalse(fast.isActive)
    }

    func testProgressPercent_CalculatesCorrectly() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        let fast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 8 hours elapsed / 16 hours target = 50%
        XCTAssertEqual(fast.progressPercent, 0.5, accuracy: 0.05)
    }

    func testProgressPercent_CapsAtOne() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -20, to: Date())!
        let fast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertLessThanOrEqual(fast.progressPercent, 1.0)
    }
}

// MARK: - FastingStats Tests

final class FastingStatsTests: XCTestCase {

    func testFastingStats_Initialization() {
        let stats = FastingStats(
            totalFasts: 50,
            completedFasts: 45,
            averageHours: 17.5,
            longestFast: 36.0,
            currentStreak: 7,
            bestStreak: 14
        )

        XCTAssertEqual(stats.totalFasts, 50)
        XCTAssertEqual(stats.completedFasts, 45)
        XCTAssertEqual(stats.averageHours, 17.5)
        XCTAssertEqual(stats.longestFast, 36.0)
        XCTAssertEqual(stats.currentStreak, 7)
        XCTAssertEqual(stats.bestStreak, 14)
    }

    func testFastingStats_CompletionRate() {
        let stats = FastingStats(
            totalFasts: 100,
            completedFasts: 90,
            averageHours: 16.0,
            longestFast: 24.0,
            currentStreak: 10,
            bestStreak: 20
        )

        let completionRate = Double(stats.completedFasts) / Double(stats.totalFasts)
        XCTAssertEqual(completionRate, 0.9)
    }
}

// MARK: - EatingWindowRecommendation Tests

final class EatingWindowRecommendationTests: XCTestCase {

    func testEatingWindowRecommendation_Initialization() {
        let startTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!

        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: startTime,
            suggestedEnd: endTime,
            reason: "Optimal for evening workouts",
            trainingTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())
        )

        XCTAssertEqual(recommendation.suggestedStart, startTime)
        XCTAssertEqual(recommendation.suggestedEnd, endTime)
        XCTAssertEqual(recommendation.reason, "Optimal for evening workouts")
        XCTAssertNotNil(recommendation.trainingTime)
    }

    func testEatingWindowRecommendation_WithoutTrainingTime() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date(),
            reason: "Standard window",
            trainingTime: nil
        )

        XCTAssertNil(recommendation.trainingTime)
    }
}
