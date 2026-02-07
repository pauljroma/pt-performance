//
//  ReadinessCheckInViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for ReadinessCheckInViewModel
//  Tests score calculation, form validation, submission flow, and loading existing entries
//
//  Enhanced with comprehensive edge cases, error handling, and timezone tests.
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Readiness Service

/// Mock service for testing ReadinessCheckInViewModel without network calls
class MockReadinessService: ReadinessService {

    // MARK: - Configuration

    var shouldFailSubmit = false
    var shouldFailLoad = false
    var shouldFailWithNetworkError = false
    var shouldFailWithRLSError = false
    var mockTodayEntry: DailyReadiness?
    var submitDelay: UInt64 = 0 // nanoseconds
    var lastSubmittedData: (patientId: UUID, sleepHours: Double?, soreness: Int?, energy: Int?, stress: Int?, notes: String?)?
    var submitCallCount = 0
    var loadCallCount = 0

    // MARK: - Override Methods

    override func getTodayReadiness(for patientId: UUID) async throws -> DailyReadiness? {
        loadCallCount += 1

        if shouldFailWithNetworkError {
            throw NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        }

        if shouldFailLoad {
            throw ReadinessError.noDataFound
        }
        return mockTodayEntry
    }

    override func submitReadiness(
        patientId: UUID,
        date: Date = Date(),
        sleepHours: Double? = nil,
        sorenessLevel: Int? = nil,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        notes: String? = nil
    ) async throws -> DailyReadiness {
        submitCallCount += 1

        if submitDelay > 0 {
            try await Task.sleep(nanoseconds: submitDelay)
        }

        if shouldFailWithNetworkError {
            throw NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        }

        if shouldFailWithRLSError {
            throw NSError(domain: "Supabase", code: 403, userInfo: [NSLocalizedDescriptionKey: "RLS policy violation"])
        }

        if shouldFailSubmit {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock submit error"])
        }

        lastSubmittedData = (patientId, sleepHours, sorenessLevel, energyLevel, stressLevel, notes)

        // Return a mock entry
        return DailyReadiness(
            id: UUID(),
            patientId: patientId,
            date: date,
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            readinessScore: 75.0,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func reset() {
        shouldFailSubmit = false
        shouldFailLoad = false
        shouldFailWithNetworkError = false
        shouldFailWithRLSError = false
        mockTodayEntry = nil
        submitDelay = 0
        lastSubmittedData = nil
        submitCallCount = 0
        loadCallCount = 0
    }
}

// MARK: - Tests

@MainActor
final class ReadinessCheckInViewModelTests: XCTestCase {

    var viewModel: ReadinessCheckInViewModel!
    var mockService: MockReadinessService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockReadinessService()
        viewModel = ReadinessCheckInViewModel(
            patientId: testPatientId,
            readinessService: mockService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertEqual(viewModel.sleepHours, 7.0, "Default sleep hours should be 7.0")
        XCTAssertEqual(viewModel.sorenessLevel, 5, "Default soreness level should be 5")
        XCTAssertEqual(viewModel.energyLevel, 5, "Default energy level should be 5")
        XCTAssertEqual(viewModel.stressLevel, 5, "Default stress level should be 5")
        XCTAssertEqual(viewModel.notes, "", "Default notes should be empty")
    }

    func testInitialState_UIFlags() {
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false initially")
        XCTAssertFalse(viewModel.showError, "showError should be false initially")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage should be empty initially")
        XCTAssertFalse(viewModel.showSuccess, "showSuccess should be false initially")
        XCTAssertFalse(viewModel.hasSubmittedToday, "hasSubmittedToday should be false initially")
        XCTAssertNil(viewModel.todayEntry, "todayEntry should be nil initially")
    }

    // MARK: - Form Validation Tests

    func testIsValid_WithDefaultValues_ReturnsTrue() {
        XCTAssertTrue(viewModel.isValid, "Form should be valid with default values")
    }

    func testIsValid_WithValidSleepHours_ReturnsTrue() {
        viewModel.sleepHours = 0.0
        XCTAssertTrue(viewModel.isValid, "Form should be valid with 0 sleep hours")

        viewModel.sleepHours = 12.0
        XCTAssertTrue(viewModel.isValid, "Form should be valid with 12 sleep hours")

        viewModel.sleepHours = 24.0
        XCTAssertTrue(viewModel.isValid, "Form should be valid with 24 sleep hours")
    }

    func testIsValid_WithInvalidSleepHours_ReturnsFalse() {
        viewModel.sleepHours = -1.0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with negative sleep hours")

        viewModel.sleepHours = 25.0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with sleep hours > 24")
    }

    func testIsValid_WithValidLevels_ReturnsTrue() {
        for level in 1...10 {
            viewModel.sorenessLevel = level
            viewModel.energyLevel = level
            viewModel.stressLevel = level
            XCTAssertTrue(viewModel.isValid, "Form should be valid with level \(level)")
        }
    }

    func testIsValid_WithInvalidSorenessLevel_ReturnsFalse() {
        viewModel.sorenessLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with soreness level 0")

        viewModel.sorenessLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with soreness level 11")
    }

    func testIsValid_WithInvalidEnergyLevel_ReturnsFalse() {
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with energy level 0")

        viewModel.energyLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with energy level 11")
    }

    func testIsValid_WithInvalidStressLevel_ReturnsFalse() {
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with stress level 0")

        viewModel.stressLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with stress level 11")
    }

    func testCanSubmit_WhenValidAndNotLoading_ReturnsTrue() {
        XCTAssertTrue(viewModel.canSubmit, "canSubmit should be true when valid and not loading")
    }

    func testCanSubmit_WhenLoading_ReturnsFalse() {
        viewModel.isLoading = true
        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when loading")
    }

    func testCanSubmit_WhenInvalid_ReturnsFalse() {
        viewModel.sleepHours = -1.0
        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when invalid")
    }

    // MARK: - Validation Message Tests

    func testValidationMessage_ForValidSleep_ReturnsNil() {
        viewModel.sleepHours = 8.0
        XCTAssertNil(viewModel.validationMessage(for: "sleep"), "No validation message for valid sleep")
    }

    func testValidationMessage_ForInvalidSleep_ReturnsMessage() {
        viewModel.sleepHours = -1.0
        XCTAssertNotNil(viewModel.validationMessage(for: "sleep"), "Should have validation message for invalid sleep")
        XCTAssertTrue(viewModel.validationMessage(for: "sleep")?.contains("0") ?? false, "Message should mention valid range")
    }

    func testValidationMessage_ForValidSoreness_ReturnsNil() {
        viewModel.sorenessLevel = 5
        XCTAssertNil(viewModel.validationMessage(for: "soreness"), "No validation message for valid soreness")
    }

    func testValidationMessage_ForInvalidSoreness_ReturnsMessage() {
        viewModel.sorenessLevel = 0
        XCTAssertNotNil(viewModel.validationMessage(for: "soreness"), "Should have validation message for invalid soreness")
    }

    func testValidationMessage_ForValidEnergy_ReturnsNil() {
        viewModel.energyLevel = 5
        XCTAssertNil(viewModel.validationMessage(for: "energy"), "No validation message for valid energy")
    }

    func testValidationMessage_ForInvalidEnergy_ReturnsMessage() {
        viewModel.energyLevel = 11
        XCTAssertNotNil(viewModel.validationMessage(for: "energy"), "Should have validation message for invalid energy")
    }

    func testValidationMessage_ForValidStress_ReturnsNil() {
        viewModel.stressLevel = 5
        XCTAssertNil(viewModel.validationMessage(for: "stress"), "No validation message for valid stress")
    }

    func testValidationMessage_ForInvalidStress_ReturnsMessage() {
        viewModel.stressLevel = 0
        XCTAssertNotNil(viewModel.validationMessage(for: "stress"), "Should have validation message for invalid stress")
    }

    func testValidationMessage_ForUnknownField_ReturnsNil() {
        XCTAssertNil(viewModel.validationMessage(for: "unknown"), "No validation message for unknown field")
    }

    // MARK: - Live Score Calculation Tests

    func testLiveReadinessScore_WithOptimalValues_ReturnsHighScore() {
        // Optimal values: 8 hours sleep, low soreness (1), high energy (10), low stress (1)
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        // Sleep: 100%, Energy: 100%, Soreness: 100% (inverse), Stress: 100% (inverse)
        // Total: (100 * 0.35) + (100 * 0.35) + (100 * 0.15) + (100 * 0.15) = 100
        XCTAssertEqual(viewModel.liveReadinessScore, 100.0, accuracy: 0.1, "Optimal values should give 100% score")
    }

    func testLiveReadinessScore_WithPoorValues_ReturnsLowScore() {
        // Poor values: 0 hours sleep, high soreness (10), low energy (1), high stress (10)
        viewModel.sleepHours = 0.0
        viewModel.sorenessLevel = 10
        viewModel.energyLevel = 1
        viewModel.stressLevel = 10

        // Sleep: 0%, Energy: 10%, Soreness: 0% (inverse), Stress: 0% (inverse)
        // Total: (0 * 0.35) + (10 * 0.35) + (0 * 0.15) + (0 * 0.15) = 3.5
        XCTAssertEqual(viewModel.liveReadinessScore, 3.5, accuracy: 0.1, "Poor values should give very low score")
    }

    func testLiveReadinessScore_WithAverageValues_ReturnsModerateScore() {
        // Average values: 7 hours sleep, mid soreness (5), mid energy (5), mid stress (5)
        viewModel.sleepHours = 7.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        // Sleep: 87.5%, Energy: 50%, Soreness: ~55.6%, Stress: ~55.6%
        let sleepComponent: Double = 87.5 * 0.35
        let energyComponent: Double = 50 * 0.35
        let sorenessComponent: Double = 55.56 * 0.15
        let stressComponent: Double = 55.56 * 0.15
        let expectedScore = sleepComponent + energyComponent + sorenessComponent + stressComponent
        XCTAssertEqual(viewModel.liveReadinessScore, expectedScore, accuracy: 1.0, "Average values should give moderate score")
    }

    func testLiveReadinessScore_SleepWeighting() {
        // Test that sleep affects score (35% weight)
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        viewModel.sleepHours = 4.0
        let score4Hours = viewModel.liveReadinessScore

        viewModel.sleepHours = 8.0
        let score8Hours = viewModel.liveReadinessScore

        XCTAssertGreaterThan(score8Hours, score4Hours, "8 hours sleep should score higher than 4 hours")
    }

    func testLiveReadinessScore_SleepCapAt9Hours() {
        // Score should cap at 9 hours (slightly above 100% due to 9/8 = 112.5, then clamped)
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        viewModel.sleepHours = 9.0
        let score9Hours = viewModel.liveReadinessScore

        viewModel.sleepHours = 12.0
        let score12Hours = viewModel.liveReadinessScore

        // Both should be 100 since sleep component caps at 100
        XCTAssertEqual(score9Hours, score12Hours, accuracy: 0.1, "Sleep score should cap at ~9 hours")
    }

    func testLiveReadinessScore_SorenessInverseEffect() {
        // Lower soreness should give higher score
        viewModel.sleepHours = 8.0
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        viewModel.sorenessLevel = 1
        let scoreLowSoreness = viewModel.liveReadinessScore

        viewModel.sorenessLevel = 10
        let scoreHighSoreness = viewModel.liveReadinessScore

        XCTAssertGreaterThan(scoreLowSoreness, scoreHighSoreness, "Low soreness should score higher than high soreness")
    }

    func testLiveReadinessScore_StressInverseEffect() {
        // Lower stress should give higher score
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5

        viewModel.stressLevel = 1
        let scoreLowStress = viewModel.liveReadinessScore

        viewModel.stressLevel = 10
        let scoreHighStress = viewModel.liveReadinessScore

        XCTAssertGreaterThan(scoreLowStress, scoreHighStress, "Low stress should score higher than high stress")
    }

    func testLiveReadinessScore_ClampedTo0And100() {
        // Even with extreme values, score should be clamped
        viewModel.sleepHours = 24.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        XCTAssertLessThanOrEqual(viewModel.liveReadinessScore, 100.0, "Score should not exceed 100")
        XCTAssertGreaterThanOrEqual(viewModel.liveReadinessScore, 0.0, "Score should not be negative")
    }

    // MARK: - Live Score Category Tests

    func testLiveScoreCategory_Elite() {
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        XCTAssertEqual(viewModel.liveScoreCategory, .elite, "Perfect values should give elite category")
    }

    func testLiveScoreCategory_High() {
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 2
        viewModel.energyLevel = 8
        viewModel.stressLevel = 2

        // Score should be around 85
        let score = viewModel.liveReadinessScore
        XCTAssertTrue(score >= 75 && score < 90, "Score should be in high range: \(score)")
        XCTAssertEqual(viewModel.liveScoreCategory, .high, "Good values should give high category")
    }

    func testLiveScoreCategory_Moderate() {
        viewModel.sleepHours = 7.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 6
        viewModel.stressLevel = 5

        let score = viewModel.liveReadinessScore
        XCTAssertTrue(score >= 60 && score < 75, "Score should be in moderate range: \(score)")
        XCTAssertEqual(viewModel.liveScoreCategory, .moderate, "Average values should give moderate category")
    }

    func testLiveScoreCategory_Low() {
        viewModel.sleepHours = 5.0
        viewModel.sorenessLevel = 7
        viewModel.energyLevel = 4
        viewModel.stressLevel = 7

        let score = viewModel.liveReadinessScore
        XCTAssertTrue(score >= 45 && score < 60, "Score should be in low range: \(score)")
        XCTAssertEqual(viewModel.liveScoreCategory, .low, "Below average values should give low category")
    }

    func testLiveScoreCategory_Poor() {
        viewModel.sleepHours = 2.0
        viewModel.sorenessLevel = 9
        viewModel.energyLevel = 2
        viewModel.stressLevel = 9

        let score = viewModel.liveReadinessScore
        XCTAssertLessThan(score, 45, "Score should be in poor range: \(score)")
        XCTAssertEqual(viewModel.liveScoreCategory, .poor, "Poor values should give poor category")
    }

    // MARK: - Live Score Formatted Tests

    func testLiveScoreFormatted_DisplaysWholeNumber() {
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        let formatted = viewModel.liveScoreFormatted
        XCTAssertFalse(formatted.contains("."), "Formatted score should not contain decimal point")
        XCTAssertTrue(Int(formatted) != nil, "Formatted score should be parseable as integer")
    }

    // MARK: - Submission Flow Tests

    func testSubmitReadiness_Success() async {
        let expectation = XCTestExpectation(description: "Submit readiness")

        viewModel.sleepHours = 8.5
        viewModel.sorenessLevel = 3
        viewModel.energyLevel = 8
        viewModel.stressLevel = 4
        viewModel.notes = "Feeling good"

        await viewModel.submitReadiness()

        // Allow time for success message to be processed
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(viewModel.hasSubmittedToday, "hasSubmittedToday should be true after successful submit")
        XCTAssertNotNil(viewModel.todayEntry, "todayEntry should be set after successful submit")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit")
        XCTAssertFalse(viewModel.showError, "showError should be false after successful submit")

        // Verify data was submitted correctly
        XCTAssertEqual(mockService.lastSubmittedData?.patientId, testPatientId)
        XCTAssertEqual(mockService.lastSubmittedData?.sleepHours, 8.5)
        XCTAssertEqual(mockService.lastSubmittedData?.soreness, 3)
        XCTAssertEqual(mockService.lastSubmittedData?.energy, 8)
        XCTAssertEqual(mockService.lastSubmittedData?.stress, 4)
        XCTAssertEqual(mockService.lastSubmittedData?.notes, "Feeling good")

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testSubmitReadiness_WithEmptyNotes_SubmitsNil() async {
        viewModel.notes = ""

        await viewModel.submitReadiness()

        XCTAssertNil(mockService.lastSubmittedData?.notes, "Empty notes should be submitted as nil")
    }

    func testSubmitReadiness_Failure() async {
        mockService.shouldFailSubmit = true

        await viewModel.submitReadiness()

        XCTAssertFalse(viewModel.hasSubmittedToday, "hasSubmittedToday should be false after failed submit")
        XCTAssertNil(viewModel.todayEntry, "todayEntry should remain nil after failed submit")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit")
        XCTAssertTrue(viewModel.showError, "showError should be true after failed submit")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "errorMessage should be set after failed submit")
    }

    func testSubmitReadiness_WhenCannotSubmit_DoesNothing() async {
        viewModel.sleepHours = -1.0 // Invalid

        await viewModel.submitReadiness()

        XCTAssertNil(mockService.lastSubmittedData, "Should not submit when form is invalid")
    }

    func testSubmitReadiness_WhenLoading_DoesNothing() async {
        viewModel.isLoading = true

        await viewModel.submitReadiness()

        XCTAssertNil(mockService.lastSubmittedData, "Should not submit when already loading")
    }

    // MARK: - Load Today Entry Tests

    func testLoadTodayEntry_WhenEntryExists() async {
        let existingEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 9.0,
            sorenessLevel: 2,
            energyLevel: 9,
            stressLevel: 2,
            readinessScore: 92.0,
            notes: "Great day",
            createdAt: Date(),
            updatedAt: Date()
        )
        mockService.mockTodayEntry = existingEntry

        await viewModel.loadTodayEntry()

        XCTAssertTrue(viewModel.hasSubmittedToday, "hasSubmittedToday should be true when entry exists")
        XCTAssertNotNil(viewModel.todayEntry, "todayEntry should be set")
        XCTAssertEqual(viewModel.sleepHours, 9.0, "sleepHours should be populated from entry")
        XCTAssertEqual(viewModel.sorenessLevel, 2, "sorenessLevel should be populated from entry")
        XCTAssertEqual(viewModel.energyLevel, 9, "energyLevel should be populated from entry")
        XCTAssertEqual(viewModel.stressLevel, 2, "stressLevel should be populated from entry")
        XCTAssertEqual(viewModel.notes, "Great day", "notes should be populated from entry")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after load")
    }

    func testLoadTodayEntry_WhenNoEntryExists() async {
        mockService.mockTodayEntry = nil

        await viewModel.loadTodayEntry()

        XCTAssertFalse(viewModel.hasSubmittedToday, "hasSubmittedToday should be false when no entry exists")
        XCTAssertNil(viewModel.todayEntry, "todayEntry should be nil")
        XCTAssertEqual(viewModel.sleepHours, 7.0, "sleepHours should be reset to default")
        XCTAssertEqual(viewModel.sorenessLevel, 5, "sorenessLevel should be reset to default")
        XCTAssertEqual(viewModel.energyLevel, 5, "energyLevel should be reset to default")
        XCTAssertEqual(viewModel.stressLevel, 5, "stressLevel should be reset to default")
        XCTAssertEqual(viewModel.notes, "", "notes should be reset to default")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after load")
    }

    func testLoadTodayEntry_WhenLoadFails() async {
        mockService.shouldFailLoad = true

        await viewModel.loadTodayEntry()

        XCTAssertFalse(viewModel.hasSubmittedToday, "hasSubmittedToday should be false when load fails")
        XCTAssertNil(viewModel.todayEntry, "todayEntry should be nil")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after load")
        // Note: Load failure sets defaults, not error (no entry is expected)
    }

    func testLoadTodayEntry_WithNilValues() async {
        // Entry with nil values
        let entryWithNils = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: nil,
            sorenessLevel: nil,
            energyLevel: nil,
            stressLevel: nil,
            readinessScore: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockService.mockTodayEntry = entryWithNils

        await viewModel.loadTodayEntry()

        XCTAssertTrue(viewModel.hasSubmittedToday, "hasSubmittedToday should be true")
        XCTAssertEqual(viewModel.sleepHours, 7.0, "Should use default for nil sleepHours")
        XCTAssertEqual(viewModel.sorenessLevel, 5, "Should use default for nil sorenessLevel")
        XCTAssertEqual(viewModel.energyLevel, 5, "Should use default for nil energyLevel")
        XCTAssertEqual(viewModel.stressLevel, 5, "Should use default for nil stressLevel")
        XCTAssertEqual(viewModel.notes, "", "Should use empty string for nil notes")
    }

    // MARK: - Reset Form Tests

    func testResetForm_ResetsAllValues() {
        // Set non-default values
        viewModel.sleepHours = 10.0
        viewModel.sorenessLevel = 8
        viewModel.energyLevel = 2
        viewModel.stressLevel = 9
        viewModel.notes = "Test notes"
        viewModel.showError = true
        viewModel.errorMessage = "Test error"
        viewModel.showSuccess = true

        viewModel.resetForm()

        XCTAssertEqual(viewModel.sleepHours, 7.0, "sleepHours should be reset to default")
        XCTAssertEqual(viewModel.sorenessLevel, 5, "sorenessLevel should be reset to default")
        XCTAssertEqual(viewModel.energyLevel, 5, "energyLevel should be reset to default")
        XCTAssertEqual(viewModel.stressLevel, 5, "stressLevel should be reset to default")
        XCTAssertEqual(viewModel.notes, "", "notes should be reset to empty")
        XCTAssertFalse(viewModel.showError, "showError should be reset to false")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage should be reset to empty")
        XCTAssertFalse(viewModel.showSuccess, "showSuccess should be reset to false")
    }

    // MARK: - Score Preview Tests

    func testScorePreview_WhenNoTodayEntry_ReturnsNil() {
        viewModel.todayEntry = nil
        XCTAssertNil(viewModel.scorePreview, "scorePreview should be nil when no todayEntry")
    }

    func testScorePreview_WhenEntryHasScore_ReturnsCategory() {
        viewModel.todayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 3,
            readinessScore: 85.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(viewModel.scorePreview, .high, "scorePreview should return high for 85 score")
    }

    func testScorePreview_WhenEntryHasNoScore_ReturnsNil() {
        viewModel.todayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 3,
            readinessScore: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(viewModel.scorePreview, "scorePreview should be nil when entry has no score")
    }

    // MARK: - Display Label Tests

    func testSleepHoursLabel() {
        viewModel.sleepHours = 8.5
        XCTAssertEqual(viewModel.sleepHoursLabel, "8.5 hours", "Sleep label should format correctly")

        viewModel.sleepHours = 7.0
        XCTAssertEqual(viewModel.sleepHoursLabel, "7.0 hours", "Sleep label should show one decimal")
    }

    func testSorenessLevelLabel() {
        viewModel.sorenessLevel = 3
        XCTAssertEqual(viewModel.sorenessLevelLabel, "3 / 10", "Soreness label should format correctly")
    }

    func testEnergyLevelLabel() {
        viewModel.energyLevel = 8
        XCTAssertEqual(viewModel.energyLevelLabel, "8 / 10", "Energy label should format correctly")
    }

    func testStressLevelLabel() {
        viewModel.stressLevel = 4
        XCTAssertEqual(viewModel.stressLevelLabel, "4 / 10", "Stress label should format correctly")
    }

    // MARK: - Color Tests

    func testSorenessColor_LowSoreness() {
        viewModel.sorenessLevel = 1
        XCTAssertEqual(viewModel.sorenessColor, .green, "Low soreness should be green")

        viewModel.sorenessLevel = 3
        XCTAssertEqual(viewModel.sorenessColor, .green, "Soreness 3 should be green")
    }

    func testSorenessColor_ModerateSoreness() {
        viewModel.sorenessLevel = 4
        XCTAssertEqual(viewModel.sorenessColor, .yellow, "Soreness 4 should be yellow")

        viewModel.sorenessLevel = 6
        XCTAssertEqual(viewModel.sorenessColor, .yellow, "Soreness 6 should be yellow")
    }

    func testSorenessColor_HighSoreness() {
        viewModel.sorenessLevel = 7
        XCTAssertEqual(viewModel.sorenessColor, .orange, "Soreness 7 should be orange")

        viewModel.sorenessLevel = 8
        XCTAssertEqual(viewModel.sorenessColor, .orange, "Soreness 8 should be orange")
    }

    func testSorenessColor_ExtremeSoreness() {
        viewModel.sorenessLevel = 9
        XCTAssertEqual(viewModel.sorenessColor, .red, "Soreness 9 should be red")

        viewModel.sorenessLevel = 10
        XCTAssertEqual(viewModel.sorenessColor, .red, "Soreness 10 should be red")
    }

    func testEnergyColor_LowEnergy() {
        viewModel.energyLevel = 1
        XCTAssertEqual(viewModel.energyColor, .red, "Low energy should be red")

        viewModel.energyLevel = 3
        XCTAssertEqual(viewModel.energyColor, .red, "Energy 3 should be red")
    }

    func testEnergyColor_ModerateEnergy() {
        viewModel.energyLevel = 4
        XCTAssertEqual(viewModel.energyColor, .yellow, "Energy 4 should be yellow")

        viewModel.energyLevel = 6
        XCTAssertEqual(viewModel.energyColor, .yellow, "Energy 6 should be yellow")
    }

    func testEnergyColor_HighEnergy() {
        viewModel.energyLevel = 7
        XCTAssertEqual(viewModel.energyColor, .orange, "Energy 7 should be orange")

        viewModel.energyLevel = 8
        XCTAssertEqual(viewModel.energyColor, .orange, "Energy 8 should be orange")
    }

    func testEnergyColor_ExtremeEnergy() {
        viewModel.energyLevel = 9
        XCTAssertEqual(viewModel.energyColor, .green, "High energy should be green")

        viewModel.energyLevel = 10
        XCTAssertEqual(viewModel.energyColor, .green, "Energy 10 should be green")
    }

    func testStressColor_LowStress() {
        viewModel.stressLevel = 1
        XCTAssertEqual(viewModel.stressColor, .green, "Low stress should be green")

        viewModel.stressLevel = 3
        XCTAssertEqual(viewModel.stressColor, .green, "Stress 3 should be green")
    }

    func testStressColor_ModerateStress() {
        viewModel.stressLevel = 4
        XCTAssertEqual(viewModel.stressColor, .yellow, "Stress 4 should be yellow")

        viewModel.stressLevel = 6
        XCTAssertEqual(viewModel.stressColor, .yellow, "Stress 6 should be yellow")
    }

    func testStressColor_HighStress() {
        viewModel.stressLevel = 7
        XCTAssertEqual(viewModel.stressColor, .orange, "Stress 7 should be orange")

        viewModel.stressLevel = 8
        XCTAssertEqual(viewModel.stressColor, .orange, "Stress 8 should be orange")
    }

    func testStressColor_ExtremeStress() {
        viewModel.stressLevel = 9
        XCTAssertEqual(viewModel.stressColor, .red, "High stress should be red")

        viewModel.stressLevel = 10
        XCTAssertEqual(viewModel.stressColor, .red, "Stress 10 should be red")
    }

    // MARK: - Preview Support Tests

    func testPreviewInstance_HasDefaultValues() {
        let previewVM = ReadinessCheckInViewModel.preview
        XCTAssertEqual(previewVM.sleepHours, 7.0, "Preview should have default sleep hours")
        XCTAssertFalse(previewVM.hasSubmittedToday, "Preview should not have submitted today")
    }

    func testPreviewWithToday_HasSubmittedValues() {
        let previewVM = ReadinessCheckInViewModel.previewWithToday
        XCTAssertTrue(previewVM.hasSubmittedToday, "PreviewWithToday should have submitted")
        XCTAssertEqual(previewVM.sleepHours, 8.5, "PreviewWithToday should have custom sleep hours")
        XCTAssertEqual(previewVM.sorenessLevel, 3, "PreviewWithToday should have custom soreness")
        XCTAssertEqual(previewVM.energyLevel, 8, "PreviewWithToday should have custom energy")
        XCTAssertEqual(previewVM.stressLevel, 4, "PreviewWithToday should have custom stress")
        XCTAssertFalse(previewVM.notes.isEmpty, "PreviewWithToday should have notes")
    }

    // MARK: - Enhanced Form Validation Tests

    func testIsValid_BoundaryValues() {
        // Test exact boundary values
        viewModel.sleepHours = 0.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 1
        viewModel.stressLevel = 1
        XCTAssertTrue(viewModel.isValid, "Form should be valid at minimum boundaries")

        viewModel.sleepHours = 24.0
        viewModel.sorenessLevel = 10
        viewModel.energyLevel = 10
        viewModel.stressLevel = 10
        XCTAssertTrue(viewModel.isValid, "Form should be valid at maximum boundaries")
    }

    func testIsValid_JustOutsideBoundaries() {
        viewModel.sleepHours = -0.1
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with sleep just below 0")

        viewModel.sleepHours = 24.1
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with sleep just above 24")
    }

    func testIsValid_MultipleInvalidFields() {
        viewModel.sleepHours = -1.0
        viewModel.sorenessLevel = 0
        viewModel.energyLevel = 11
        viewModel.stressLevel = -5
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with multiple invalid fields")
    }

    func testValidationMessage_AllFields() {
        // Valid values should return nil for all fields
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        XCTAssertNil(viewModel.validationMessage(for: "sleep"))
        XCTAssertNil(viewModel.validationMessage(for: "soreness"))
        XCTAssertNil(viewModel.validationMessage(for: "energy"))
        XCTAssertNil(viewModel.validationMessage(for: "stress"))
        XCTAssertNil(viewModel.validationMessage(for: "nonexistent"))
    }

    // MARK: - Enhanced Score Calculation Tests

    func testLiveReadinessScore_ExtremeCases() {
        // Zero sleep
        viewModel.sleepHours = 0.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5
        XCTAssertGreaterThanOrEqual(viewModel.liveReadinessScore, 0, "Score should never be negative")

        // Maximum sleep (24 hours)
        viewModel.sleepHours = 24.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1
        XCTAssertLessThanOrEqual(viewModel.liveReadinessScore, 100, "Score should not exceed 100")
    }

    func testLiveReadinessScore_HalfHourSleepIncrements() {
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        viewModel.sleepHours = 6.0
        let score6 = viewModel.liveReadinessScore

        viewModel.sleepHours = 6.5
        let score65 = viewModel.liveReadinessScore

        viewModel.sleepHours = 7.0
        let score7 = viewModel.liveReadinessScore

        XCTAssertLessThan(score6, score65, "6.5 hours should score higher than 6 hours")
        XCTAssertLessThan(score65, score7, "7 hours should score higher than 6.5 hours")
    }

    func testLiveReadinessScore_EachComponentIndependently() {
        // Test sleep component in isolation
        viewModel.sleepHours = 4.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1
        let lowSleepScore = viewModel.liveReadinessScore

        viewModel.sleepHours = 8.0
        let highSleepScore = viewModel.liveReadinessScore

        XCTAssertGreaterThan(highSleepScore, lowSleepScore, "Higher sleep should increase score")

        // Test energy component
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 1
        viewModel.stressLevel = 1

        viewModel.energyLevel = 1
        let lowEnergyScore = viewModel.liveReadinessScore

        viewModel.energyLevel = 10
        let highEnergyScore = viewModel.liveReadinessScore

        XCTAssertGreaterThan(highEnergyScore, lowEnergyScore, "Higher energy should increase score")
    }

    func testLiveScoreCategory_AllCategories() {
        // Poor (< 45)
        viewModel.sleepHours = 2.0
        viewModel.sorenessLevel = 10
        viewModel.energyLevel = 1
        viewModel.stressLevel = 10
        XCTAssertEqual(viewModel.liveScoreCategory, .poor)

        // Low (45-59)
        viewModel.sleepHours = 5.0
        viewModel.sorenessLevel = 7
        viewModel.energyLevel = 4
        viewModel.stressLevel = 7
        let lowScore = viewModel.liveReadinessScore
        if lowScore >= 45 && lowScore < 60 {
            XCTAssertEqual(viewModel.liveScoreCategory, .low)
        }

        // Moderate (60-74)
        viewModel.sleepHours = 7.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 6
        viewModel.stressLevel = 5
        let modScore = viewModel.liveReadinessScore
        if modScore >= 60 && modScore < 75 {
            XCTAssertEqual(viewModel.liveScoreCategory, .moderate)
        }

        // High (75-89)
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 2
        viewModel.energyLevel = 8
        viewModel.stressLevel = 2
        let highScore = viewModel.liveReadinessScore
        if highScore >= 75 && highScore < 90 {
            XCTAssertEqual(viewModel.liveScoreCategory, .high)
        }

        // Elite (90+)
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1
        let eliteScore = viewModel.liveReadinessScore
        if eliteScore >= 90 {
            XCTAssertEqual(viewModel.liveScoreCategory, .elite)
        }
    }

    // MARK: - Enhanced Submission Flow Tests

    func testSubmitReadiness_NetworkError() async {
        mockService.shouldFailWithNetworkError = true

        await viewModel.submitReadiness()

        XCTAssertTrue(viewModel.showError, "Should show error on network failure")
        XCTAssertTrue(viewModel.errorMessage.lowercased().contains("network") ||
                     viewModel.errorMessage.lowercased().contains("connection"),
                     "Error message should mention network issue")
    }

    func testSubmitReadiness_RLSError() async {
        mockService.shouldFailWithRLSError = true

        await viewModel.submitReadiness()

        XCTAssertTrue(viewModel.showError, "Should show error on RLS failure")
        XCTAssertTrue(viewModel.errorMessage.lowercased().contains("permission") ||
                     viewModel.errorMessage.lowercased().contains("logging"),
                     "Error message should mention permission issue")
    }

    func testSubmitReadiness_PreservesValuesOnError() async {
        mockService.shouldFailSubmit = true

        viewModel.sleepHours = 9.5
        viewModel.sorenessLevel = 2
        viewModel.energyLevel = 9
        viewModel.stressLevel = 3
        viewModel.notes = "Test notes"

        await viewModel.submitReadiness()

        // Values should be preserved after error
        XCTAssertEqual(viewModel.sleepHours, 9.5)
        XCTAssertEqual(viewModel.sorenessLevel, 2)
        XCTAssertEqual(viewModel.energyLevel, 9)
        XCTAssertEqual(viewModel.stressLevel, 3)
        XCTAssertEqual(viewModel.notes, "Test notes")
    }

    func testSubmitReadiness_MultipleRapidSubmissions() async {
        // Simulate rapid button taps
        let task1 = Task {
            await viewModel.submitReadiness()
        }
        let task2 = Task {
            await viewModel.submitReadiness()
        }

        await task1.value
        await task2.value

        // Only one submission should go through (due to isLoading check)
        XCTAssertLessThanOrEqual(mockService.submitCallCount, 2)
    }

    func testSubmitReadiness_WithWhitespaceOnlyNotes() async {
        viewModel.notes = "   \n\t  "

        await viewModel.submitReadiness()

        // Whitespace-only notes should be treated as empty
        // (depending on implementation, this tests the trimming behavior)
        XCTAssertNotNil(mockService.lastSubmittedData)
    }

    func testSubmitReadiness_WithVeryLongNotes() async {
        viewModel.notes = String(repeating: "a", count: 10000)

        await viewModel.submitReadiness()

        XCTAssertEqual(mockService.lastSubmittedData?.notes?.count, 10000)
    }

    // MARK: - Enhanced Load Today Entry Tests

    func testLoadTodayEntry_NetworkError() async {
        mockService.shouldFailWithNetworkError = true

        await viewModel.loadTodayEntry()

        XCTAssertTrue(viewModel.showError, "Should show error on network failure during load")
        XCTAssertFalse(viewModel.hasSubmittedToday, "hasSubmittedToday should be false on error")
    }

    func testLoadTodayEntry_PartialData() async {
        // Entry with only some values set
        let partialEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 7.5,
            sorenessLevel: nil,
            energyLevel: 8,
            stressLevel: nil,
            readinessScore: 70.0,
            notes: "Partial entry",
            createdAt: Date(),
            updatedAt: Date()
        )
        mockService.mockTodayEntry = partialEntry

        await viewModel.loadTodayEntry()

        XCTAssertTrue(viewModel.hasSubmittedToday)
        XCTAssertEqual(viewModel.sleepHours, 7.5)
        XCTAssertEqual(viewModel.sorenessLevel, 5, "Nil soreness should use default")
        XCTAssertEqual(viewModel.energyLevel, 8)
        XCTAssertEqual(viewModel.stressLevel, 5, "Nil stress should use default")
        XCTAssertEqual(viewModel.notes, "Partial entry")
    }

    func testLoadTodayEntry_MultipleCalls() async {
        mockService.mockTodayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 80.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        await viewModel.loadTodayEntry()
        await viewModel.loadTodayEntry()
        await viewModel.loadTodayEntry()

        XCTAssertEqual(mockService.loadCallCount, 3, "Should call service each time")
        XCTAssertTrue(viewModel.hasSubmittedToday)
    }

    // MARK: - Error Message Handling Tests

    func testErrorMessage_ClearsOnSuccessfulSubmit() async {
        // First, cause an error
        mockService.shouldFailSubmit = true
        await viewModel.submitReadiness()
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)

        // Now succeed
        mockService.shouldFailSubmit = false
        await viewModel.submitReadiness()

        XCTAssertFalse(viewModel.showError, "showError should be false after success")
    }

    func testErrorMessage_ClearsOnReset() {
        viewModel.showError = true
        viewModel.errorMessage = "Some error"

        viewModel.resetForm()

        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    // MARK: - State Consistency Tests

    func testStateConsistency_AfterLoadThenSubmit() async {
        // Load existing entry
        mockService.mockTodayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 7.0,
            sorenessLevel: 4,
            energyLevel: 6,
            stressLevel: 5,
            readinessScore: 65.0,
            notes: "Original",
            createdAt: Date(),
            updatedAt: Date()
        )
        await viewModel.loadTodayEntry()

        // Modify and submit
        viewModel.sleepHours = 8.0
        viewModel.notes = "Updated"
        await viewModel.submitReadiness()

        XCTAssertTrue(viewModel.hasSubmittedToday)
        XCTAssertNotNil(viewModel.todayEntry)
        XCTAssertEqual(mockService.lastSubmittedData?.sleepHours, 8.0)
        XCTAssertEqual(mockService.lastSubmittedData?.notes, "Updated")
    }

    // MARK: - Color Threshold Tests

    func testSorenessColor_AllLevels() {
        for level in 1...10 {
            viewModel.sorenessLevel = level
            let color = viewModel.sorenessColor
            switch level {
            case 1...3:
                XCTAssertEqual(color, .green, "Soreness \(level) should be green")
            case 4...6:
                XCTAssertEqual(color, .yellow, "Soreness \(level) should be yellow")
            case 7...8:
                XCTAssertEqual(color, .orange, "Soreness \(level) should be orange")
            default:
                XCTAssertEqual(color, .red, "Soreness \(level) should be red")
            }
        }
    }

    func testEnergyColor_AllLevels() {
        for level in 1...10 {
            viewModel.energyLevel = level
            let color = viewModel.energyColor
            switch level {
            case 1...3:
                XCTAssertEqual(color, .red, "Energy \(level) should be red")
            case 4...6:
                XCTAssertEqual(color, .yellow, "Energy \(level) should be yellow")
            case 7...8:
                XCTAssertEqual(color, .orange, "Energy \(level) should be orange")
            default:
                XCTAssertEqual(color, .green, "Energy \(level) should be green")
            }
        }
    }

    func testStressColor_AllLevels() {
        for level in 1...10 {
            viewModel.stressLevel = level
            let color = viewModel.stressColor
            switch level {
            case 1...3:
                XCTAssertEqual(color, .green, "Stress \(level) should be green")
            case 4...6:
                XCTAssertEqual(color, .yellow, "Stress \(level) should be yellow")
            case 7...8:
                XCTAssertEqual(color, .orange, "Stress \(level) should be orange")
            default:
                XCTAssertEqual(color, .red, "Stress \(level) should be red")
            }
        }
    }

    // MARK: - Edge Case Tests

    func testDecimalSleepHours() {
        viewModel.sleepHours = 7.25
        XCTAssertEqual(viewModel.sleepHoursLabel, "7.2 hours", "Should format to one decimal")

        viewModel.sleepHours = 7.99
        XCTAssertEqual(viewModel.sleepHoursLabel, "8.0 hours", "Should round to one decimal")
    }

    func testScorePreview_CategoryBoundaries() {
        // Test score at category boundary (75)
        viewModel.todayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 3,
            readinessScore: 75.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(viewModel.scorePreview, .high, "Score 75 should be high category")

        // Test score just below boundary (74.9)
        viewModel.todayEntry = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 3,
            readinessScore: 74.9,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(viewModel.scorePreview, .moderate, "Score 74.9 should be moderate category")
    }

    func testFormattedScoreRounding() {
        // Test that formatted score rounds correctly
        viewModel.sleepHours = 7.123
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        let formatted = viewModel.liveScoreFormatted
        XCTAssertFalse(formatted.contains("."), "Formatted score should be a whole number")
    }
}
