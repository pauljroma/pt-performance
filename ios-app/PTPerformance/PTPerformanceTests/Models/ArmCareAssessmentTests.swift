//
//  ArmCareAssessmentTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for ArmCareAssessment model
//  Tests shoulder/elbow score calculations, traffic light determination, and component validation
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - ArmCareAssessment Model Tests

final class ArmCareAssessmentTests: XCTestCase {

    // MARK: - Initialization Tests

    func testArmCareAssessment_Initialization() {
        let patientId = UUID()
        let assessment = ArmCareAssessment(
            patientId: patientId,
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        XCTAssertEqual(assessment.patientId, patientId)
        XCTAssertEqual(assessment.shoulderPainScore, 8)
        XCTAssertEqual(assessment.shoulderStiffnessScore, 7)
        XCTAssertEqual(assessment.shoulderStrengthScore, 9)
        XCTAssertEqual(assessment.elbowPainScore, 9)
        XCTAssertEqual(assessment.elbowTightnessScore, 8)
        XCTAssertEqual(assessment.valgusStressScore, 10)
    }

    func testArmCareAssessment_InitializationWithOptionals() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10,
            painLocations: [.anteriorShoulder, .medialElbow],
            notes: "Some shoulder tightness"
        )

        XCTAssertNotNil(assessment.painLocations)
        XCTAssertEqual(assessment.painLocations?.count, 2)
        XCTAssertEqual(assessment.notes, "Some shoulder tightness")
    }

    // MARK: - Shoulder Score Calculation Tests

    func testShoulderScore_Calculation() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        // Shoulder score = (8 + 7 + 9) / 3 = 24 / 3 = 8.0
        XCTAssertEqual(assessment.shoulderScore, 8.0, accuracy: 0.01)
    }

    func testShoulderScore_AllPerfectScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        XCTAssertEqual(assessment.shoulderScore, 10.0, accuracy: 0.01)
    }

    func testShoulderScore_AllMinimumScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )

        XCTAssertEqual(assessment.shoulderScore, 0.0, accuracy: 0.01)
    }

    func testShoulderScore_MixedValues() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,  // No pain
            shoulderStiffnessScore: 0,  // Very stiff
            shoulderStrengthScore: 5,   // Moderate strength
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        // (10 + 0 + 5) / 3 = 5.0
        XCTAssertEqual(assessment.shoulderScore, 5.0, accuracy: 0.01)
    }

    // MARK: - Elbow Score Calculation Tests

    func testElbowScore_Calculation() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        // Elbow score = (9 + 8 + 10) / 3 = 27 / 3 = 9.0
        XCTAssertEqual(assessment.elbowScore, 9.0, accuracy: 0.01)
    }

    func testElbowScore_AllPerfectScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        XCTAssertEqual(assessment.elbowScore, 10.0, accuracy: 0.01)
    }

    func testElbowScore_AllMinimumScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )

        XCTAssertEqual(assessment.elbowScore, 0.0, accuracy: 0.01)
    }

    func testElbowScore_UCLConcern() {
        // Low valgus stress score indicates UCL concern
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 2  // UCL discomfort
        )

        // (10 + 10 + 2) / 3 = 7.33
        XCTAssertEqual(assessment.elbowScore, 7.33, accuracy: 0.01)
    }

    // MARK: - Overall Score Calculation Tests

    func testOverallScore_Calculation() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        // Shoulder: 8.0, Elbow: 9.0
        // Overall = (8.0 + 9.0) / 2 = 8.5
        XCTAssertEqual(assessment.overallScore, 8.5, accuracy: 0.01)
    }

    func testOverallScore_PerfectScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )

        XCTAssertEqual(assessment.overallScore, 10.0, accuracy: 0.01)
    }

    func testOverallScore_LowestScores() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )

        XCTAssertEqual(assessment.overallScore, 0.0, accuracy: 0.01)
    }

    func testOverallScore_ShoulderWorseThanElbow() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 2,  // Shoulder issues
            shoulderStiffnessScore: 3,
            shoulderStrengthScore: 4,
            elbowPainScore: 9,    // Elbow fine
            elbowTightnessScore: 9,
            valgusStressScore: 9
        )

        // Shoulder: 3.0, Elbow: 9.0
        // Overall = (3.0 + 9.0) / 2 = 6.0
        XCTAssertEqual(assessment.overallScore, 6.0, accuracy: 0.01)
        XCTAssertLessThan(assessment.shoulderScore, assessment.elbowScore)
    }

    func testOverallScore_ElbowWorseThanShoulder() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 9,
            shoulderStiffnessScore: 9,
            shoulderStrengthScore: 9,
            elbowPainScore: 2,    // Elbow issues
            elbowTightnessScore: 3,
            valgusStressScore: 4
        )

        // Shoulder: 9.0, Elbow: 3.0
        // Overall = (9.0 + 3.0) / 2 = 6.0
        XCTAssertEqual(assessment.overallScore, 6.0, accuracy: 0.01)
        XCTAssertLessThan(assessment.elbowScore, assessment.shoulderScore)
    }

    // MARK: - Traffic Light Determination Tests

    func testTrafficLight_Green() {
        // Score 8-10 should be green
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 9,
            shoulderStiffnessScore: 9,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 9,
            valgusStressScore: 9
        )

        XCTAssertEqual(assessment.trafficLight, .green)
    }

    func testTrafficLight_GreenAtBoundary() {
        // Exactly at 8 should be green
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 8,
            shoulderStiffnessScore: 8,
            shoulderStrengthScore: 8,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 8
        )

        XCTAssertEqual(assessment.trafficLight, .green)
    }

    func testTrafficLight_Yellow() {
        // Score 5-7 should be yellow
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 6,
            shoulderStiffnessScore: 6,
            shoulderStrengthScore: 6,
            elbowPainScore: 6,
            elbowTightnessScore: 6,
            valgusStressScore: 6
        )

        XCTAssertEqual(assessment.trafficLight, .yellow)
    }

    func testTrafficLight_YellowAtUpperBoundary() {
        // Just below 8 should be yellow
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 7,
            shoulderStiffnessScore: 8,
            shoulderStrengthScore: 8,
            elbowPainScore: 8,
            elbowTightnessScore: 8,
            valgusStressScore: 8
        )

        // Overall: (7.67 + 8.0) / 2 = 7.83 -> Yellow
        XCTAssertEqual(assessment.trafficLight, .yellow)
    }

    func testTrafficLight_YellowAtLowerBoundary() {
        // Score of exactly 5
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 5,
            shoulderStiffnessScore: 5,
            shoulderStrengthScore: 5,
            elbowPainScore: 5,
            elbowTightnessScore: 5,
            valgusStressScore: 5
        )

        XCTAssertEqual(assessment.trafficLight, .yellow)
    }

    func testTrafficLight_Red() {
        // Score 0-4 should be red
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 3,
            shoulderStiffnessScore: 3,
            shoulderStrengthScore: 3,
            elbowPainScore: 3,
            elbowTightnessScore: 3,
            valgusStressScore: 3
        )

        XCTAssertEqual(assessment.trafficLight, .red)
    }

    func testTrafficLight_RedAtBoundary() {
        // Just below 5 should be red
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 4,
            shoulderStiffnessScore: 5,
            shoulderStrengthScore: 5,
            elbowPainScore: 5,
            elbowTightnessScore: 5,
            valgusStressScore: 5
        )

        // Overall: (4.67 + 5.0) / 2 = 4.83 -> Red
        XCTAssertEqual(assessment.trafficLight, .red)
    }

    func testTrafficLight_RedAllZeros() {
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )

        XCTAssertEqual(assessment.trafficLight, .red)
    }

    // MARK: - ArmCareTrafficLight Static Method Tests

    func testTrafficLight_FromScore_Green() {
        XCTAssertEqual(ArmCareTrafficLight.from(score: 10.0), .green)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 9.0), .green)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 8.0), .green)
    }

    func testTrafficLight_FromScore_Yellow() {
        XCTAssertEqual(ArmCareTrafficLight.from(score: 7.99), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 7.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 6.0), .yellow)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 5.0), .yellow)
    }

    func testTrafficLight_FromScore_Red() {
        XCTAssertEqual(ArmCareTrafficLight.from(score: 4.99), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 4.0), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 2.0), .red)
        XCTAssertEqual(ArmCareTrafficLight.from(score: 0.0), .red)
    }

    // MARK: - ArmCareTrafficLight Properties Tests

    func testTrafficLight_DisplayNames() {
        XCTAssertEqual(ArmCareTrafficLight.green.displayName, "Good to Go")
        XCTAssertEqual(ArmCareTrafficLight.yellow.displayName, "Proceed with Caution")
        XCTAssertEqual(ArmCareTrafficLight.red.displayName, "Recovery Mode")
    }

    func testTrafficLight_Colors() {
        XCTAssertEqual(ArmCareTrafficLight.green.color, Color.green)
        XCTAssertEqual(ArmCareTrafficLight.yellow.color, Color.yellow)
        XCTAssertEqual(ArmCareTrafficLight.red.color, Color.red)
    }

    func testTrafficLight_IconNames() {
        XCTAssertEqual(ArmCareTrafficLight.green.iconName, "checkmark.circle.fill")
        XCTAssertEqual(ArmCareTrafficLight.yellow.iconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(ArmCareTrafficLight.red.iconName, "xmark.octagon.fill")
    }

    func testTrafficLight_ThrowingVolumeMultiplier() {
        XCTAssertEqual(ArmCareTrafficLight.green.throwingVolumeMultiplier, 1.0)
        XCTAssertEqual(ArmCareTrafficLight.yellow.throwingVolumeMultiplier, 0.5)
        XCTAssertEqual(ArmCareTrafficLight.red.throwingVolumeMultiplier, 0.0)
    }

    func testTrafficLight_RequiresExtraArmCare() {
        XCTAssertFalse(ArmCareTrafficLight.green.requiresExtraArmCare)
        XCTAssertTrue(ArmCareTrafficLight.yellow.requiresExtraArmCare)
        XCTAssertTrue(ArmCareTrafficLight.red.requiresExtraArmCare)
    }

    func testTrafficLight_RequiresRecoveryProtocol() {
        XCTAssertFalse(ArmCareTrafficLight.green.requiresRecoveryProtocol)
        XCTAssertFalse(ArmCareTrafficLight.yellow.requiresRecoveryProtocol)
        XCTAssertTrue(ArmCareTrafficLight.red.requiresRecoveryProtocol)
    }

    // MARK: - ArmPainLocation Tests

    func testArmPainLocation_IsShoulder() {
        XCTAssertTrue(ArmPainLocation.anteriorShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.posteriorShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.lateralShoulder.isShoulder)
        XCTAssertTrue(ArmPainLocation.rotatorCuff.isShoulder)

        XCTAssertFalse(ArmPainLocation.medialElbow.isShoulder)
        XCTAssertFalse(ArmPainLocation.lateralElbow.isShoulder)
        XCTAssertFalse(ArmPainLocation.posteriorElbow.isShoulder)
        XCTAssertFalse(ArmPainLocation.forearm.isShoulder)
    }

    func testArmPainLocation_IsElbow() {
        XCTAssertFalse(ArmPainLocation.anteriorShoulder.isElbow)
        XCTAssertFalse(ArmPainLocation.posteriorShoulder.isElbow)
        XCTAssertFalse(ArmPainLocation.lateralShoulder.isElbow)
        XCTAssertFalse(ArmPainLocation.rotatorCuff.isElbow)

        XCTAssertTrue(ArmPainLocation.medialElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.lateralElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.posteriorElbow.isElbow)
        XCTAssertTrue(ArmPainLocation.forearm.isElbow)
    }

    func testArmPainLocation_DisplayNames() {
        XCTAssertEqual(ArmPainLocation.anteriorShoulder.displayName, "Front of Shoulder")
        XCTAssertEqual(ArmPainLocation.posteriorShoulder.displayName, "Back of Shoulder")
        XCTAssertEqual(ArmPainLocation.lateralShoulder.displayName, "Side of Shoulder")
        XCTAssertEqual(ArmPainLocation.rotatorCuff.displayName, "Rotator Cuff Area")
        XCTAssertEqual(ArmPainLocation.medialElbow.displayName, "Inside of Elbow (UCL)")
        XCTAssertEqual(ArmPainLocation.lateralElbow.displayName, "Outside of Elbow")
        XCTAssertEqual(ArmPainLocation.posteriorElbow.displayName, "Back of Elbow")
        XCTAssertEqual(ArmPainLocation.forearm.displayName, "Forearm")
    }

    func testArmPainLocation_RawValues() {
        XCTAssertEqual(ArmPainLocation.anteriorShoulder.rawValue, "anterior_shoulder")
        XCTAssertEqual(ArmPainLocation.medialElbow.rawValue, "medial_elbow")
    }

    func testArmPainLocation_Identifiable() {
        XCTAssertEqual(ArmPainLocation.anteriorShoulder.id, "anterior_shoulder")
    }

    func testArmPainLocation_AllCases() {
        XCTAssertEqual(ArmPainLocation.allCases.count, 8)
    }

    // MARK: - ArmCareAssessmentInput Validation Tests

    func testArmCareAssessmentInput_ValidInput() throws {
        var input = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testArmCareAssessmentInput_InvalidShoulderPain_Negative() {
        var input = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: -1,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertTrue((error as? ArmCareError) != nil)
        }
    }

    func testArmCareAssessmentInput_InvalidShoulderPain_TooHigh() {
        var input = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: 11,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        XCTAssertThrowsError(try input.validate())
    }

    func testArmCareAssessmentInput_BoundaryValues() throws {
        // Test minimum (0)
        var minInput = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: 0,
            shoulderStiffnessScore: 0,
            shoulderStrengthScore: 0,
            elbowPainScore: 0,
            elbowTightnessScore: 0,
            valgusStressScore: 0
        )
        XCTAssertNoThrow(try minInput.validate())

        // Test maximum (10)
        var maxInput = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: 10,
            shoulderStiffnessScore: 10,
            shoulderStrengthScore: 10,
            elbowPainScore: 10,
            elbowTightnessScore: 10,
            valgusStressScore: 10
        )
        XCTAssertNoThrow(try maxInput.validate())
    }

    func testArmCareAssessmentInput_CalculateScores() {
        var input = ArmCareAssessmentInput(
            patientId: nil,
            date: nil,
            shoulderPainScore: 8,
            shoulderStiffnessScore: 7,
            shoulderStrengthScore: 9,
            elbowPainScore: 9,
            elbowTightnessScore: 8,
            valgusStressScore: 10
        )

        input.calculateScores()

        XCTAssertEqual(input.shoulderScore, 8.0, accuracy: 0.01)
        XCTAssertEqual(input.elbowScore, 9.0, accuracy: 0.01)
        XCTAssertEqual(input.overallScore, 8.5, accuracy: 0.01)
        XCTAssertEqual(input.trafficLight, "green")
    }

    // MARK: - ArmCareError Tests

    func testArmCareError_Descriptions() {
        XCTAssertEqual(ArmCareError.invalidScore("Test").errorDescription, "Test")
        XCTAssertEqual(ArmCareError.noDataFound.errorDescription, "No arm care assessment data found")
        XCTAssertEqual(ArmCareError.saveFailed.errorDescription, "Failed to save arm care assessment")
        XCTAssertEqual(ArmCareError.fetchFailed.errorDescription, "Failed to fetch arm care assessment")
        XCTAssertEqual(ArmCareError.trendCalculationFailed.errorDescription, "Failed to calculate arm care trend")
    }

    // MARK: - ArmCareWorkoutModification Tests

    func testArmCareWorkoutModification_GreenLight() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .green,
            shoulderScore: 9.0,
            elbowScore: 9.0
        )

        XCTAssertEqual(modification.trafficLight, .green)
        XCTAssertEqual(modification.throwingVolumeReduction, 0.0)
        XCTAssertFalse(modification.extraArmCareRequired)
        XCTAssertFalse(modification.recoveryProtocolRequired)
        XCTAssertFalse(modification.recommendations.isEmpty)
        XCTAssertTrue(modification.warnings.isEmpty)
    }

    func testArmCareWorkoutModification_YellowLight_ShoulderWorse() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .yellow,
            shoulderScore: 5.0,
            elbowScore: 7.0
        )

        XCTAssertEqual(modification.trafficLight, .yellow)
        XCTAssertEqual(modification.throwingVolumeReduction, 0.5)
        XCTAssertTrue(modification.extraArmCareRequired)
        XCTAssertFalse(modification.recoveryProtocolRequired)
        XCTAssertTrue(modification.warnings.contains { $0.contains("Shoulder") })
    }

    func testArmCareWorkoutModification_YellowLight_ElbowWorse() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .yellow,
            shoulderScore: 7.0,
            elbowScore: 5.0
        )

        XCTAssertEqual(modification.trafficLight, .yellow)
        XCTAssertTrue(modification.warnings.contains { $0.contains("Elbow") })
    }

    func testArmCareWorkoutModification_RedLight() {
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

    func testArmCareWorkoutModification_RedLight_LowShoulderScore() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .red,
            shoulderScore: 2.0,
            elbowScore: 5.0
        )

        XCTAssertTrue(modification.warnings.contains { $0.contains("Shoulder") && $0.contains("pain") })
    }

    func testArmCareWorkoutModification_RedLight_LowElbowScore() {
        let modification = ArmCareWorkoutModification.from(
            trafficLight: .red,
            shoulderScore: 5.0,
            elbowScore: 2.0
        )

        XCTAssertTrue(modification.warnings.contains { $0.contains("Elbow") })
    }

    // MARK: - Sample Data Tests (DEBUG only)

    #if DEBUG
    func testArmCareAssessment_SampleData() {
        let sample = ArmCareAssessment.sample
        XCTAssertEqual(sample.trafficLight, .green)
        XCTAssertGreaterThanOrEqual(sample.overallScore, 8.0)
    }

    func testArmCareAssessment_YellowSample() {
        let sample = ArmCareAssessment.yellowSample
        XCTAssertEqual(sample.trafficLight, .yellow)
        XCTAssertGreaterThanOrEqual(sample.overallScore, 5.0)
        XCTAssertLessThan(sample.overallScore, 8.0)
    }

    func testArmCareAssessment_RedSample() {
        let sample = ArmCareAssessment.redSample
        XCTAssertEqual(sample.trafficLight, .red)
        XCTAssertLessThan(sample.overallScore, 5.0)
    }
    #endif

    // MARK: - ArmCareTrend Tests

    func testArmCareTrend_TrendDirection() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.displayName, "Improving")
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.displayName, "Stable")
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.displayName, "Declining")
    }

    func testArmCareTrend_TrendDirectionColors() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.color, Color.green)
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.color, Color.yellow)
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.color, Color.red)
    }

    func testArmCareTrend_TrendDirectionIcons() {
        XCTAssertEqual(ArmCareTrend.TrendDirection.improving.iconName, "arrow.up.right")
        XCTAssertEqual(ArmCareTrend.TrendDirection.stable.iconName, "arrow.right")
        XCTAssertEqual(ArmCareTrend.TrendDirection.declining.iconName, "arrow.down.right")
    }

    // MARK: - Edge Cases

    func testArmCareAssessment_DecimalScoreHandling() {
        // When individual components result in non-integer averages
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 7,
            shoulderStiffnessScore: 8,
            shoulderStrengthScore: 9,
            elbowPainScore: 10,
            elbowTightnessScore: 7,
            valgusStressScore: 8
        )

        // Shoulder: (7 + 8 + 9) / 3 = 8.0
        // Elbow: (10 + 7 + 8) / 3 = 8.33...
        // Overall: (8.0 + 8.33...) / 2 = 8.16...
        XCTAssertEqual(assessment.shoulderScore, 8.0, accuracy: 0.01)
        XCTAssertEqual(assessment.elbowScore, 8.33, accuracy: 0.01)
        XCTAssertEqual(assessment.overallScore, 8.17, accuracy: 0.01)
        XCTAssertEqual(assessment.trafficLight, .green)  // 8.17 >= 8
    }

    func testArmCareAssessment_ScorePrecision() {
        // Test that score calculation maintains precision
        let assessment = ArmCareAssessment(
            patientId: UUID(),
            shoulderPainScore: 1,
            shoulderStiffnessScore: 2,
            shoulderStrengthScore: 3,
            elbowPainScore: 4,
            elbowTightnessScore: 5,
            valgusStressScore: 6
        )

        // Shoulder: (1 + 2 + 3) / 3 = 2.0
        // Elbow: (4 + 5 + 6) / 3 = 5.0
        // Overall: (2.0 + 5.0) / 2 = 3.5
        XCTAssertEqual(assessment.shoulderScore, 2.0, accuracy: 0.001)
        XCTAssertEqual(assessment.elbowScore, 5.0, accuracy: 0.001)
        XCTAssertEqual(assessment.overallScore, 3.5, accuracy: 0.001)
    }
}
