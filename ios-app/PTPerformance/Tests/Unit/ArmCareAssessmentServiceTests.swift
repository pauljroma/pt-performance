//
//  ArmCareAssessmentServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ArmCareAssessmentService
//  Tests score calculations, traffic light logic, validation, and input processing
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - ArmCareTrafficLight Tests

final class ArmCareTrafficLightTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testArmCareTrafficLight_RawValues() {
        XCTAssertEqual(ArmCareTrafficLight.green.rawValue, "green")
        XCTAssertEqual(ArmCareTrafficLight.yellow.rawValue, "yellow")
        XCTAssertEqual(ArmCareTrafficLight.red.rawValue, "red")
    }

    func testArmCareTrafficLight_InitFromRawValue() {
        XCTAssertEqual(ArmCareTrafficLight(rawValue: "green"), .green)
        XCTAssertEqual(ArmCareTrafficLight(rawValue: "yellow"), .yellow)
        XCTAssertEqual(ArmCareTrafficLight(rawValue: "red"), .red)
        XCTAssertNil(ArmCareTrafficLight(rawValue: "invalid"))
    }

    // MARK: - Score Classification Tests

    func testArmCareTrafficLight_FromScore_Green() {
        // Green: 8-10
        XCTAssertEqual(ArmCareTrafficLight.from(score: 8.0), .green)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 9.0), .green)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 10.0), .green)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 8.5), .green)
    }

    func testArmCareTrafficLight_FromScore_Yellow() {
        // Yellow: 5-7.99
        XCTAssertEqual(ArmCareTrafficLight.from(score: 5.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 6.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 7.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 7.9), .yellow)
    }

    func testArmCareTrafficLight_FromScore_Red() {
        // Red: 0-4.99
        XCTAssertEqual(ArmCareTrafficLight.from(score: 0.0), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 2.0), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 4.0), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 4.99), .red)
    }

    func testArmCareTrafficLight_FromScore_BoundaryValues() {
        // Test exact boundary values
        XCTAssertEqual(ArmCareTrafficLight.from(score: 4.9999), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 5.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 7.9999), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 8.0), .green)
    }

    // MARK: - Throwing Volume Multiplier Tests

    func testArmCareTrafficLight_ThrowingVolumeMultiplier() {
        XCTAssertEqual(ArmCareTrafficLight.green.throwingVolumeMultiplier, 1.0)
        XCTAssertEqual(ArmCareTrafficLight.yellow.throwingVolumeMultiplier, 0.5)
        XCTAssertEqual(ArmCareTrafficLight.red.throwingVolumeMultiplier, 0.0)
    }

    // MARK: - Requirements Tests

    func testArmCareTrafficLight_RequiresExtraArmCare() {
        XCTAssertFalse(ArmCareTrafficLight.green.requiresExtraArmCare)
        XCTAssertTrue(ArmCareTrafficLight.yellow.requiresExtraArmCare)
        XCTAssertTrue(ArmCareTrafficLight.red.requiresExtraArmCare)
    }

    func testArmCareTrafficLight_RequiresRecoveryProtocol() {
        XCTAssertFalse(ArmCareTrafficLight.green.requiresRecoveryProtocol)
        XCTAssertFalse(ArmCareTrafficLight.yellow.requiresRecoveryProtocol)
        XCTAssertTrue(ArmCareTrafficLight.red.requiresRecoveryProtocol)
    }

    // MARK: - Display Properties Tests

    func testArmCareTrafficLight_DisplayNames() {
        XCTAssertEqual(ArmCareTrafficLight.green.displayName, "Good to Go")
        XCTAssertEqual(ArmCareTrafficLight.yellow.displayName, "Proceed with Caution")
        XCTAssertEqual(ArmCareTrafficLight.red.displayName, "Recovery Mode")
    }

    func testArmCareTrafficLight_Colors() {
        XCTAssertEqual(ArmCareTrafficLight.green.color, .green)
        XCTAssertEqual(ArmCareTrafficLight.yellow.color, .yellow)
        XCTAssertEqual(ArmCareTrafficLight.red.color, .red)
    }

    func testArmCareTrafficLight_IconNames() {
        XCTAssertEqual(ArmCareTrafficLight.green.iconName, "checkmark.circle.fill")
        XCTAssertEqual(ArmCareTrafficLight.yellow.iconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(ArmCareTrafficLight.red.iconName, "xmark.octagon.fill")
    }
}

// MARK: - ArmCareAssessment Score Calculation Tests

final class ArmCareAssessmentScoreTests: XCTestCase {

    // MARK: - Shoulder Score Calculation Tests

    func testShoulderScore_CalculatedCorrectly() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        // Shoulder score = (8 + 7 + 9) / 3 = 8.0
        XCTAssertEqual(assessment.shoulderScore, 8.0, accuracy: 0.001)
    }

    func testShoulderScore_WithLowScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 2,
            shoulderStiffnessScore: 3,
            shoulderStrengthScore: 4,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        // Shoulder score = (2 + 3 + 4) / 3 = 3.0
        XCTAssertEqual(assessment.shoulderScore, 3.0, accuracy: 0.001)
    }

    // MARK: - Elbow Score Calculation Tests

    func testElbowScore_CalculatedCorrectly() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        // Elbow score = (9 + 8 + 10) / 3 = 9.0
        XCTAssertEqual(assessment.elbowScore, 9.0, accuracy: 0.001)
    }

    func testElbowScore_WithLowScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 2,
            elbowTightnessScore: 3,
            valgusStressScore: 4
        )

        // Elbow score = (2 + 3 + 4) / 3 = 3.0
        XCTAssertEqual(assessment.elbowScore, 3.0, accuracy: 0.001)
    }

    // MARK: - Overall Score Calculation Tests

    func testOverallScore_CalculatedFromShoulderAndElbow() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 8,
            shoulderStrengthScore: 8,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        // Shoulder score = 8.0, Elbow score = 10.0
        // Overall = (8.0 + 10.0) / 2 = 9.0
        XCTAssertEqual(assessment.overallScore, 9.0, accuracy: 0.001)
    }

    func testOverallScore_WithMixedScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 6,
            shoulderStiffnessScore: 5,
            shoulderStrengthScore: 7,
            elbowPainScore: 6,
            elbowTightnessScore: 6,
            valgusStressScore: 6
        )

        // Shoulder score = (6 + 5 + 7) / 3 = 6.0
        // Elbow score = (6 + 6 + 6) / 3 = 6.0
        // Overall = (6.0 + 6.0) / 2 = 6.0
        XCTAssertEqual(assessment.overallScore, 6.0, accuracy: 0.001)
        XCTAssertEqual(assessment.trafficLight, .yellow)
    }

    // MARK: - Traffic Light Assignment Tests

    func testTrafficLight_AssignedBasedOnOverallScore() {
        // Green case
        let greenAssessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 9,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )
        XCTAssertEqual(greenAssessment.trafficLight, .green)

        // Yellow case
        let yellowAssessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 6,
            shoulderStiffnessScore: 5,
            shoulderStrengthScore: 7,
            elbowPainScore: 6,
            elbowTightnessScore: 6,
            valgusStressScore: 7
        )
        XCTAssertEqual(yellowAssessment.trafficLight, .yellow)

        // Red case
        let redAssessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 3,
            shoulderStiffnessScore: 4,
            shoulderStrengthScore: 5,
            elbowPainScore: 2,
            elbowTightnessScore: 3,
            valgusStressScore: 4
        )
        XCTAssertEqual(redAssessment.trafficLight, .red)
    }
}

// MARK: - ArmCareAssessmentInput Validation Tests

final class ArmCareAssessmentInputTests: XCTestCase {

    // MARK: - Valid Input Tests

    func testValidate_ValidInput_DoesNotThrow() throws {
        let input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 9
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_BoundaryValues_DoesNotThrow() throws {
        // Test minimum values (0)
        let minInput = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )
        XCTAssertNoThrow(try minInput.validate())

        // Test maximum values (10)
        let maxInput = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )
        XCTAssertNoThrow(try maxInput.validate())
    }

    // MARK: - Invalid Input Tests

    func testValidate_ShoulderPainScoreOutOfRange_Throws() {
        let input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 11, // Invalid
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 9
        )

        XCTAssertThrowsError(try input.validate()) { error in
            if case ArmCareError.invalidScore(let message) = error {
                XCTAssertTrue(message.contains("Shoulder pain"))
            } else {
                XCTFail("Expected ArmCareError.invalidScore")
            }
        }
    }

    func testValidate_NegativeScore_Throws() {
        let input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: -1, // Invalid
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 9
        )

        XCTAssertThrowsError(try input.validate())
    }

    func testValidate_ElbowTightnessScoreOutOfRange_Throws() {
        let input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 8,
            elbowTightnessScore: 15, // Invalid
            valgusStressScore: 9
        )

        XCTAssertThrowsError(try input.validate()) { error in
            if case ArmCareError.invalidScore(let message) = error {
                XCTAssertTrue(message.contains("Elbow tightness"))
            } else {
                XCTFail("Expected ArmCareError.invalidScore")
            }
        }
    }

    // MARK: - Calculate Scores Tests

    func testCalculateScores_SetsShoulderScore() {
        var input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 9
        )

        input.calculateScores()

        // (8 + 7 + 9) / 3 = 8.0
        XCTAssertEqual(input.shoulderScore, 8.0, accuracy: 0.001)
    }

    func testCalculateScores_SetsElbowScore() {
        var input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        input.calculateScores()

        // (9 + 8 + 10) / 3 = 9.0
        XCTAssertEqual(input.elbowScore, 9.0, accuracy: 0.001)
    }

    func testCalculateScores_SetsOverallScore() {
        var input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 6,
            shoulderStiffnessScore: 6,
            shoulderStrengthScore: 6,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 8
        )

        input.calculateScores()

        // Shoulder = 6.0, Elbow = 8.0
        // Overall = (6.0 + 8.0) / 2 = 7.0
        XCTAssertEqual(input.overallScore, 7.0, accuracy: 0.001)
    }

    func testCalculateScores_SetsTrafficLight() {
        var input = ArmCareAssessmentInput(
            patientId: UUID().uuidString,
            date: "2024-01-15",
            shoulderPainScore: 6,
            shoulderStiffnessScore: 6,
            shoulderStrengthScore: 6,
            elbowPainScore: 6,
            elbowTightnessScore: 6,
            valgusStressScore: 6
        )

        input.calculateScores()

        // Overall = 6.0 -> yellow
        XCTAssertEqual(input.trafficLight, "yellow")
    }
}

// MARK: - ArmPainLocation Tests

final class ArmPainLocationTests: XCTestCase {

    func testArmPainLocation_IsShoulder() {
        XCTAssertTrue(ArmPainLocation.anteriorShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.posteriorShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.lateralShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.rotatorCuff.isShoulder)
        XCTAssertFalse(ArmPainLocation.medialElbow.isShoulder)
        XCTAssertFalse(ArmPainLocation.lateralElbow.isShoulder)
        XCTAssertFalse(ArmPainLocation.forearm.isShoulder)
    }

    func testArmPainLocation_IsElbow() {
        XCTAssertTrue(ArmPainLocation.medialElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.lateralElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.posteriorElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.forearm.isElbow)
        XCTAssertFalse(ArmPainLocation.anteriorShoulder.isElbow)
        XCTAssertFalse(ArmPainLocation.rotatorCuff.isElbow)
    }

    func testArmPainLocation_DisplayNames() {
        XCTAssertEqual(ArmPainLocation.anteriorShoulder.displayName, "Front of Shoulder")
        XCTAssertEqual(ArmPainLocation.medialElbow.displayName, "Inside of Elbow (UCL)")
        XCTAssertEqual(ArmPainLocation.forearm.displayName, "Forearm")
    }
}

// MARK: - ArmCareWorkoutModification Tests

final class ArmCareWorkoutModificationTests: XCTestCase {

    func testWorkoutModification_GreenLight() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .green,
            shoulderScore: 9.0,
            elbowScore: 9.0
        )

        XCTAssertEqual(modification.trafficLight, .green)
        XCTAssertEqual(modification.throwingVolumeReduction, 0.0)
        XCTAssertFalse(modification.extraArmCareRequired)
        XCTAssertFalse(modification.recoveryProtocolRequired)
        XCTAssertTrue(modification.warnings.isEmpty)
    }

    func testWorkoutModification_YellowLight_ShoulderLower() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .yellow,
            shoulderScore: 5.0,
            elbowScore: 7.0
        )

        XCTAssertEqual(modification.trafficLight, .yellow)
        XCTAssertEqual(modification.throwingVolumeReduction, 0.5)
        XCTAssertTrue(modification.extraArmCareRequired)
        XCTAssertFalse(modification.recoveryProtocolRequired)
        XCTAssertTrue(modification.warnings.contains("Shoulder requires extra attention today"))
    }

    func testWorkoutModification_YellowLight_ElbowLower() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .yellow,
            shoulderScore: 7.0,
            elbowScore: 5.0
        )

        XCTAssertTrue(modification.warnings.contains("Elbow requires extra attention today"))
    }

    func testWorkoutModification_RedLight() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .red,
            shoulderScore: 3.0,
            elbowScore: 3.0
        )

        XCTAssertEqual(modification.trafficLight, .red)
        XCTAssertEqual(modification.throwingVolumeReduction, 1.0)
        XCTAssertTrue(modification.extraArmCareRequired)
        XCTAssertTrue(modification.recoveryProtocolRequired)
        XCTAssertFalse(modification.warnings.isEmpty)
    }

    func testWorkoutModification_RedLight_ShoulderPainElevated() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .red,
            shoulderScore: 3.0,
            elbowScore: 5.0
        )

        XCTAssertTrue(modification.warnings.contains("Shoulder pain is elevated - prioritize rest"))
    }

    func testWorkoutModification_RedLight_ElbowDiscomfort() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .red,
            shoulderScore: 5.0,
            elbowScore: 3.0
        )

        XCTAssertTrue(modification.warnings.contains("Elbow discomfort detected - no valgus stress"))
    }
}

// MARK: - ArmCareTrend Tests

final class ArmCareTrendDirectionTests: XCTestCase {

    func testTrendDirection_RawValues() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.rawValue, "improving")
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.rawValue, "stable")
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.rawValue, "declining")
    }

    func testTrendDirection_DisplayNames() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.displayName, "Improving")
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.displayName, "Stable")
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.displayName, "Declining")
    }

    func testTrendDirection_Colors() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.color, .green)
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.color, .yellow)
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.color, .red)
    }

    func testTrendDirection_IconNames() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.iconName, "arrow.up.right")
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.iconName, "arrow.right")
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.iconName, "arrow.down.right")
    }
}

// MARK: - ArmCareError Tests

final class ArmCareErrorTests: XCTestCase {

    func testArmCareError_InvalidScore_ErrorDescription() {
        let error = ArmCareError.invalidScore("Test message")
        XCTAssertEqual(error.errorDescription, "Test message")
    }

    func testArmCareError_NoDataFound_ErrorDescription() {
        let error = ArmCareError.noDataFound
        XCTAssertEqual(error.errorDescription, "No arm care assessment data found")
    }

    func testArmCareError_SaveFailed_ErrorDescription() {
        let error = ArmCareError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save arm care assessment")
    }

    func testArmCareError_FetchFailed_ErrorDescription() {
        let error = ArmCareError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch arm care assessment")
    }

    func testArmCareError_TrendCalculationFailed_ErrorDescription() {
        let error = ArmCareError.trendCalculationFailed
        XCTAssertEqual(error.errorDescription, "Failed to calculate arm care trend")
    }
}

// MARK: - ArmCareSummary Tests

final class ArmCareSummaryTests: XCTestCase {

    func testArmCareSummary_CanThrowToday_GreenLight() {
        let summary = createSummary(trafficLight: .green)
        XCTAssertTrue(summary.canThrowToday)
        XCTAssertEqual(summary.throwingVolumeMultiplier, 1.0)
    }

    func testArmCareSummary_CanThrowToday_YellowLight() {
        let summary = createSummary(trafficLight: .yellow)
        XCTAssertTrue(summary.canThrowToday)
        XCTAssertEqual(summary.throwingVolumeMultiplier, 0.5)
    }

    func testArmCareSummary_CannotThrowToday_RedLight() {
        let summary = createSummary(trafficLight: .red)
        XCTAssertFalse(summary.canThrowToday)
        XCTAssertEqual(summary.throwingVolumeMultiplier, 0.0)
    }

    func testArmCareSummary_NoAssessment_DefaultMultiplier() {
        let trend = createEmptyTrend()
        let summary = ArmCareSummary(today: nil, recent: [], trend: trend)

        XCTAssertTrue(summary.canThrowToday)
        XCTAssertEqual(summary.throwingVolumeMultiplier, 0.75)
    }

    func testArmCareSummary_HasLoggedToday() {
        let summaryWithToday = createSummary(trafficLight: .green)
        XCTAssertTrue(summaryWithToday.hasLoggedToday)

        let trend = createEmptyTrend()
        let summaryWithoutToday = ArmCareSummary(today: nil, recent: [], trend: trend)
        XCTAssertFalse(summaryWithoutToday.hasLoggedToday)
    }

    // MARK: - Helper Methods

    private func createSummary(trafficLight: ArmCareTrafficLight) -> ArmCareSummary {
        let assessment: ArmCareAssessment
        switch trafficLight {
        case .green:
            assessment = ArmCareAssessment(
                patientId: UUID(),
                shoulderPainScore: 9,
                shoulderStiffnessScore: 9,
                shoulderStrengthScore: 9,
                elbowPainScore: 9,
                elbowTightnessScore: 9,
                valgusStressScore: 9
            )
        case .yellow:
            assessment = ArmCareAssessment(
                patientId: UUID(),
                shoulderPainScore: 6,
                shoulderStiffnessScore: 6,
                shoulderStrengthScore: 6,
                elbowPainScore: 6,
                elbowTightnessScore: 6,
                valgusStressScore: 6
            )
        case .red, .unknown:
            assessment = ArmCareAssessment(
                patientId: UUID(),
                shoulderPainScore: 3,
                shoulderStiffnessScore: 3,
                shoulderStrengthScore: 3,
                elbowPainScore: 3,
                elbowTightnessScore: 3,
                valgusStressScore: 3
            )
        }

        let trend = createEmptyTrend()
        return ArmCareSummary(today: assessment, recent: [assessment], trend: trend)
    }

    private func createEmptyTrend() -> ArmCareTrend {
        return ArmCareTrend(
            patientId: UUID(),
            daysAnalyzed: 7,
            assessments: [],
            statistics: ArmCareTrend.ArmCareTrendStatistics(
                avgOverallScore: nil,
                avgShoulderScore: nil,
                avgElbowScore: nil,
                greenDays: 0,
                yellowDays: 0,
                redDays: 0,
                totalAssessments: 0,
                trendDirection: .stable
            )
        )
    }
}
