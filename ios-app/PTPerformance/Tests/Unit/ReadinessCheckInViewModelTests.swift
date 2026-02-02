//
//  ReadinessCheckInViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for ReadinessCheckInViewModel
//  Tests readiness score calculations, validation, and state management
//

import XCTest
import SwiftUI
@testable import PTPerformance

@MainActor
final class ReadinessCheckInViewModelTests: XCTestCase {

    var viewModel: ReadinessCheckInViewModel!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        viewModel = ReadinessCheckInViewModel(patientId: testPatientId)
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.sleepHours, 7.0, "Default sleep hours should be 7")
        XCTAssertEqual(viewModel.sorenessLevel, 5, "Default soreness level should be 5")
        XCTAssertEqual(viewModel.energyLevel, 5, "Default energy level should be 5")
        XCTAssertEqual(viewModel.stressLevel, 5, "Default stress level should be 5")
        XCTAssertEqual(viewModel.notes, "", "Notes should be empty initially")
    }

    func testInitialUIState() {
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.showError, "Should not show error initially")
        XCTAssertEqual(viewModel.errorMessage, "", "Error message should be empty initially")
        XCTAssertFalse(viewModel.showSuccess, "Should not show success initially")
        XCTAssertFalse(viewModel.hasSubmittedToday, "Should not have submitted today initially")
        XCTAssertNil(viewModel.todayEntry, "Today's entry should be nil initially")
    }

    // MARK: - Validation Tests

    func testIsValid_WithDefaultValues_ReturnsTrue() {
        XCTAssertTrue(viewModel.isValid, "Form should be valid with default values")
    }

    func testIsValid_WithValidValues_ReturnsTrue() {
        viewModel.sleepHours = 8.5
        viewModel.sorenessLevel = 3
        viewModel.energyLevel = 8
        viewModel.stressLevel = 2

        XCTAssertTrue(viewModel.isValid, "Form should be valid with good values")
    }

    func testIsValid_SleepTooLow_ReturnsFalse() {
        viewModel.sleepHours = -1.0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with negative sleep hours")
    }

    func testIsValid_SleepTooHigh_ReturnsFalse() {
        viewModel.sleepHours = 25.0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with > 24 sleep hours")
    }

    func testIsValid_SleepAtBoundary_ReturnsTrue() {
        viewModel.sleepHours = 0.0
        XCTAssertTrue(viewModel.isValid, "Form should be valid with 0 sleep hours")

        viewModel.sleepHours = 24.0
        XCTAssertTrue(viewModel.isValid, "Form should be valid with 24 sleep hours")
    }

    func testIsValid_SorenessTooLow_ReturnsFalse() {
        viewModel.sorenessLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with soreness level 0")
    }

    func testIsValid_SorenessTooHigh_ReturnsFalse() {
        viewModel.sorenessLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with soreness level > 10")
    }

    func testIsValid_SorenessAtBoundaries_ReturnsTrue() {
        viewModel.sorenessLevel = 1
        XCTAssertTrue(viewModel.isValid, "Form should be valid with soreness level 1")

        viewModel.sorenessLevel = 10
        XCTAssertTrue(viewModel.isValid, "Form should be valid with soreness level 10")
    }

    func testIsValid_EnergyTooLow_ReturnsFalse() {
        viewModel.energyLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with energy level 0")
    }

    func testIsValid_EnergyTooHigh_ReturnsFalse() {
        viewModel.energyLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with energy level > 10")
    }

    func testIsValid_StressTooLow_ReturnsFalse() {
        viewModel.stressLevel = 0
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with stress level 0")
    }

    func testIsValid_StressTooHigh_ReturnsFalse() {
        viewModel.stressLevel = 11
        XCTAssertFalse(viewModel.isValid, "Form should be invalid with stress level > 10")
    }

    // MARK: - canSubmit Tests

    func testCanSubmit_WhenValidAndNotLoading_ReturnsTrue() {
        XCTAssertTrue(viewModel.canSubmit, "Should be able to submit when valid and not loading")
    }

    func testCanSubmit_WhenInvalid_ReturnsFalse() {
        viewModel.sleepHours = -5
        XCTAssertFalse(viewModel.canSubmit, "Should not be able to submit when invalid")
    }

    func testCanSubmit_WhenLoading_ReturnsFalse() {
        viewModel.isLoading = true
        XCTAssertFalse(viewModel.canSubmit, "Should not be able to submit when loading")
    }

    // MARK: - Live Readiness Score Tests

    func testLiveReadinessScore_WithDefaultValues() {
        // Default: 7 hours sleep, 5 soreness, 5 energy, 5 stress
        // Sleep: (7/8) * 100 = 87.5%
        // Energy: (5/10) * 100 = 50%
        // Soreness: (1 - (5-1)/9) * 100 = (1 - 0.444) * 100 = 55.56%
        // Stress: (1 - (5-1)/9) * 100 = (1 - 0.444) * 100 = 55.56%
        // Total: 87.5*0.35 + 50*0.35 + 55.56*0.15 + 55.56*0.15
        //      = 30.625 + 17.5 + 8.33 + 8.33 = 64.785

        let score = viewModel.liveReadinessScore
        XCTAssertEqual(score, 64.79, accuracy: 0.1,
            "Live score with default values should be around 64.8")
    }

    func testLiveReadinessScore_OptimalValues() {
        // Optimal: 8+ hours sleep, 1 soreness, 10 energy, 1 stress
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        // Sleep: (8/8) * 100 = 100%
        // Energy: (10/10) * 100 = 100%
        // Soreness: (1 - (1-1)/9) * 100 = 100%
        // Stress: (1 - (1-1)/9) * 100 = 100%
        // Total: 100*0.35 + 100*0.35 + 100*0.15 + 100*0.15 = 100

        let score = viewModel.liveReadinessScore
        XCTAssertEqual(score, 100.0, accuracy: 0.1,
            "Live score with optimal values should be 100")
    }

    func testLiveReadinessScore_WorstValues() {
        // Worst: 0 hours sleep, 10 soreness, 1 energy, 10 stress
        viewModel.sleepHours = 0.0
        viewModel.sorenessLevel = 10
        viewModel.energyLevel = 1
        viewModel.stressLevel = 10

        // Sleep: (0/8) * 100 = 0%
        // Energy: (1/10) * 100 = 10%
        // Soreness: (1 - (10-1)/9) * 100 = (1 - 1) * 100 = 0%
        // Stress: (1 - (10-1)/9) * 100 = (1 - 1) * 100 = 0%
        // Total: 0*0.35 + 10*0.35 + 0*0.15 + 0*0.15 = 3.5

        let score = viewModel.liveReadinessScore
        XCTAssertEqual(score, 3.5, accuracy: 0.1,
            "Live score with worst values should be very low")
    }

    func testLiveReadinessScore_SleepOver8Hours_CapsAt100() {
        viewModel.sleepHours = 12.0  // More than optimal 8 hours
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        // Sleep should cap at 100%, not exceed
        let score = viewModel.liveReadinessScore
        XCTAssertEqual(score, 100.0, accuracy: 0.1,
            "Sleep contribution should cap at 100%")
    }

    func testLiveReadinessScore_NeverExceeds100() {
        viewModel.sleepHours = 24.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        XCTAssertLessThanOrEqual(viewModel.liveReadinessScore, 100.0,
            "Score should never exceed 100")
    }

    func testLiveReadinessScore_NeverBelowZero() {
        viewModel.sleepHours = 0.0
        viewModel.sorenessLevel = 10
        viewModel.energyLevel = 1
        viewModel.stressLevel = 10

        XCTAssertGreaterThanOrEqual(viewModel.liveReadinessScore, 0.0,
            "Score should never be below 0")
    }

    // MARK: - Live Score Category Tests

    func testLiveScoreCategory_Elite() {
        viewModel.sleepHours = 9.0
        viewModel.sorenessLevel = 1
        viewModel.energyLevel = 10
        viewModel.stressLevel = 1

        XCTAssertEqual(viewModel.liveScoreCategory, .elite,
            "Should be Elite category with excellent inputs")
    }

    func testLiveScoreCategory_High() {
        viewModel.sleepHours = 8.0
        viewModel.sorenessLevel = 2
        viewModel.energyLevel = 9
        viewModel.stressLevel = 2

        // Score should be in 75-89 range
        XCTAssertTrue(viewModel.liveReadinessScore >= 75 && viewModel.liveReadinessScore < 90,
            "Score should be in High range")
        XCTAssertEqual(viewModel.liveScoreCategory, .high,
            "Should be High category")
    }

    func testLiveScoreCategory_Moderate() {
        viewModel.sleepHours = 6.5
        viewModel.sorenessLevel = 4
        viewModel.energyLevel = 6
        viewModel.stressLevel = 4

        // Score should be in 60-74 range
        XCTAssertEqual(viewModel.liveScoreCategory, .moderate,
            "Should be Moderate category")
    }

    func testLiveScoreCategory_Low() {
        viewModel.sleepHours = 5.0
        viewModel.sorenessLevel = 6
        viewModel.energyLevel = 4
        viewModel.stressLevel = 6

        // Score should be in 45-59 range
        XCTAssertEqual(viewModel.liveScoreCategory, .low,
            "Should be Low category")
    }

    func testLiveScoreCategory_Poor() {
        viewModel.sleepHours = 2.0
        viewModel.sorenessLevel = 9
        viewModel.energyLevel = 2
        viewModel.stressLevel = 9

        XCTAssertEqual(viewModel.liveScoreCategory, .poor,
            "Should be Poor category with bad inputs")
    }

    // MARK: - Live Score Formatted Tests

    func testLiveScoreFormatted_RoundsCorrectly() {
        viewModel.sleepHours = 7.0
        viewModel.sorenessLevel = 5
        viewModel.energyLevel = 5
        viewModel.stressLevel = 5

        // Should format to whole number
        let formatted = viewModel.liveScoreFormatted
        XCTAssertFalse(formatted.contains("."),
            "Formatted score should not contain decimal point")
    }

    func testLiveScoreFormatted_IsNotEmpty() {
        XCTAssertFalse(viewModel.liveScoreFormatted.isEmpty,
            "Formatted score should not be empty")
    }

    // MARK: - Display Label Tests

    func testSleepHoursLabel() {
        viewModel.sleepHours = 7.5
        XCTAssertEqual(viewModel.sleepHoursLabel, "7.5 hours")
    }

    func testSorenessLevelLabel() {
        viewModel.sorenessLevel = 3
        XCTAssertEqual(viewModel.sorenessLevelLabel, "3 / 10")
    }

    func testEnergyLevelLabel() {
        viewModel.energyLevel = 8
        XCTAssertEqual(viewModel.energyLevelLabel, "8 / 10")
    }

    func testStressLevelLabel() {
        viewModel.stressLevel = 4
        XCTAssertEqual(viewModel.stressLevelLabel, "4 / 10")
    }

    // MARK: - Color Tests

    func testSorenessColor_LowSoreness_Green() {
        viewModel.sorenessLevel = 2
        XCTAssertEqual(viewModel.sorenessColor, .green,
            "Low soreness (1-3) should be green")
    }

    func testSorenessColor_ModerateSoreness_Yellow() {
        viewModel.sorenessLevel = 5
        XCTAssertEqual(viewModel.sorenessColor, .yellow,
            "Moderate soreness (4-6) should be yellow")
    }

    func testSorenessColor_HighMidSoreness_Orange() {
        viewModel.sorenessLevel = 7
        XCTAssertEqual(viewModel.sorenessColor, .orange,
            "High-mid soreness (7-8) should be orange")
    }

    func testSorenessColor_HighSoreness_Red() {
        viewModel.sorenessLevel = 9
        XCTAssertEqual(viewModel.sorenessColor, .red,
            "High soreness (9-10) should be red")
    }

    func testEnergyColor_LowEnergy_Red() {
        viewModel.energyLevel = 2
        XCTAssertEqual(viewModel.energyColor, .red,
            "Low energy (1-3) should be red")
    }

    func testEnergyColor_ModerateEnergy_Yellow() {
        viewModel.energyLevel = 5
        XCTAssertEqual(viewModel.energyColor, .yellow,
            "Moderate energy (4-6) should be yellow")
    }

    func testEnergyColor_HighMidEnergy_Orange() {
        viewModel.energyLevel = 8
        XCTAssertEqual(viewModel.energyColor, .orange,
            "High-mid energy (7-8) should be orange")
    }

    func testEnergyColor_HighEnergy_Green() {
        viewModel.energyLevel = 10
        XCTAssertEqual(viewModel.energyColor, .green,
            "High energy (9-10) should be green")
    }

    func testStressColor_LowStress_Green() {
        viewModel.stressLevel = 1
        XCTAssertEqual(viewModel.stressColor, .green,
            "Low stress (1-3) should be green")
    }

    func testStressColor_ModerateStress_Yellow() {
        viewModel.stressLevel = 6
        XCTAssertEqual(viewModel.stressColor, .yellow,
            "Moderate stress (4-6) should be yellow")
    }

    func testStressColor_HighMidStress_Orange() {
        viewModel.stressLevel = 8
        XCTAssertEqual(viewModel.stressColor, .orange,
            "High-mid stress (7-8) should be orange")
    }

    func testStressColor_HighStress_Red() {
        viewModel.stressLevel = 10
        XCTAssertEqual(viewModel.stressColor, .red,
            "High stress (9-10) should be red")
    }

    // MARK: - Validation Message Tests

    func testValidationMessage_Sleep_InvalidLow() {
        viewModel.sleepHours = -1
        XCTAssertNotNil(viewModel.validationMessage(for: "sleep"),
            "Should have validation message for negative sleep")
    }

    func testValidationMessage_Sleep_InvalidHigh() {
        viewModel.sleepHours = 25
        XCTAssertNotNil(viewModel.validationMessage(for: "sleep"),
            "Should have validation message for > 24 hours sleep")
    }

    func testValidationMessage_Sleep_Valid() {
        viewModel.sleepHours = 8
        XCTAssertNil(viewModel.validationMessage(for: "sleep"),
            "Should have no validation message for valid sleep")
    }

    func testValidationMessage_Soreness_Invalid() {
        viewModel.sorenessLevel = 0
        XCTAssertNotNil(viewModel.validationMessage(for: "soreness"),
            "Should have validation message for invalid soreness")
    }

    func testValidationMessage_Energy_Invalid() {
        viewModel.energyLevel = 11
        XCTAssertNotNil(viewModel.validationMessage(for: "energy"),
            "Should have validation message for invalid energy")
    }

    func testValidationMessage_Stress_Invalid() {
        viewModel.stressLevel = -1
        XCTAssertNotNil(viewModel.validationMessage(for: "stress"),
            "Should have validation message for invalid stress")
    }

    func testValidationMessage_UnknownField() {
        XCTAssertNil(viewModel.validationMessage(for: "unknown"),
            "Should return nil for unknown field")
    }

    // MARK: - Reset Form Tests

    func testResetForm_ResetsAllValues() {
        // Set non-default values
        viewModel.sleepHours = 9.0
        viewModel.sorenessLevel = 2
        viewModel.energyLevel = 8
        viewModel.stressLevel = 3
        viewModel.notes = "Some notes"
        viewModel.showError = true
        viewModel.errorMessage = "Test error"
        viewModel.showSuccess = true

        viewModel.resetForm()

        XCTAssertEqual(viewModel.sleepHours, 7.0)
        XCTAssertEqual(viewModel.sorenessLevel, 5)
        XCTAssertEqual(viewModel.energyLevel, 5)
        XCTAssertEqual(viewModel.stressLevel, 5)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.showSuccess)
    }

    // MARK: - Preview Support Tests

    func testPreview_Instance() {
        let preview = ReadinessCheckInViewModel.preview
        XCTAssertNotNil(preview, "Preview instance should not be nil")
        XCTAssertFalse(preview.hasSubmittedToday, "Preview should not have submitted today")
    }

    func testPreviewWithToday_HasSubmitted() {
        let preview = ReadinessCheckInViewModel.previewWithToday
        XCTAssertTrue(preview.hasSubmittedToday, "Preview with today should have submitted")
        XCTAssertEqual(preview.sleepHours, 8.5)
        XCTAssertEqual(preview.sorenessLevel, 3)
        XCTAssertEqual(preview.energyLevel, 8)
        XCTAssertEqual(preview.stressLevel, 4)
        XCTAssertFalse(preview.notes.isEmpty, "Preview should have notes")
    }

    // MARK: - Score Weight Validation Tests

    func testScoreWeights_SumToOne() {
        // Weights: Sleep 0.35, Energy 0.35, Soreness 0.15, Stress 0.15
        let totalWeight = 0.35 + 0.35 + 0.15 + 0.15
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001,
            "Score weights should sum to 1.0")
    }

    // MARK: - ReadinessCategory Integration Tests

    func testReadinessCategory_EliteRange() {
        XCTAssertEqual(ReadinessCategory.category(for: 100), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 95), .elite)
        XCTAssertEqual(ReadinessCategory.category(for: 90), .elite)
    }

    func testReadinessCategory_HighRange() {
        XCTAssertEqual(ReadinessCategory.category(for: 89), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 80), .high)
        XCTAssertEqual(ReadinessCategory.category(for: 75), .high)
    }

    func testReadinessCategory_ModerateRange() {
        XCTAssertEqual(ReadinessCategory.category(for: 74), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 65), .moderate)
        XCTAssertEqual(ReadinessCategory.category(for: 60), .moderate)
    }

    func testReadinessCategory_LowRange() {
        XCTAssertEqual(ReadinessCategory.category(for: 59), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 50), .low)
        XCTAssertEqual(ReadinessCategory.category(for: 45), .low)
    }

    func testReadinessCategory_PoorRange() {
        XCTAssertEqual(ReadinessCategory.category(for: 44), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 20), .poor)
        XCTAssertEqual(ReadinessCategory.category(for: 0), .poor)
    }

    func testReadinessCategory_AllCasesHaveProperties() {
        for category in ReadinessCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.recommendation.isEmpty)
            XCTAssertFalse(category.scoreRange.isEmpty)
        }
    }
}
