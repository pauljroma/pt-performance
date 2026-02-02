//
//  RMCalculatorTests.swift
//  PTPerformanceTests
//
//  Unit tests for RMCalculator utility
//  Tests 1RM formula calculations, strength targets, and edge cases
//

import XCTest
@testable import PTPerformance

final class RMCalculatorTests: XCTestCase {

    // MARK: - Epley Formula Tests

    func testEpleyFormulaBasicCalculation() {
        // Epley: 1RM = weight * (1 + reps / 30)
        // 200 lbs @ 10 reps = 200 * (1 + 10/30) = 200 * 1.333 = 266.67
        let result = RMCalculator.epley(weight: 200, reps: 10)
        XCTAssertEqual(result, 266.67, accuracy: 0.01)
    }

    func testEpleyFormulaWithOneRep() {
        // 1 rep should approximate actual weight
        // 200 * (1 + 1/30) = 200 * 1.033 = 206.67
        let result = RMCalculator.epley(weight: 200, reps: 1)
        XCTAssertEqual(result, 206.67, accuracy: 0.01)
    }

    func testEpleyFormulaWithHighReps() {
        // 100 lbs @ 15 reps = 100 * (1 + 15/30) = 100 * 1.5 = 150
        let result = RMCalculator.epley(weight: 100, reps: 15)
        XCTAssertEqual(result, 150.0, accuracy: 0.01)
    }

    func testEpleyFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.epley(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.epley(weight: 200, reps: 0), 0)
        XCTAssertEqual(RMCalculator.epley(weight: -100, reps: 10), 0)
        XCTAssertEqual(RMCalculator.epley(weight: 100, reps: -5), 0)
    }

    // MARK: - Brzycki Formula Tests

    func testBrzyckiFormulaBasicCalculation() {
        // Brzycki: 1RM = weight * (36 / (37 - reps))
        // 200 lbs @ 10 reps = 200 * (36 / 27) = 200 * 1.333 = 266.67
        let result = RMCalculator.brzycki(weight: 200, reps: 10)
        XCTAssertEqual(result, 266.67, accuracy: 0.01)
    }

    func testBrzyckiFormulaWithOneRep() {
        // 200 * (36 / 36) = 200 * 1.0 = 200
        let result = RMCalculator.brzycki(weight: 200, reps: 1)
        XCTAssertEqual(result, 200.0, accuracy: 0.01)
    }

    func testBrzyckiFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.brzycki(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.brzycki(weight: 200, reps: 0), 0)
        XCTAssertEqual(RMCalculator.brzycki(weight: 200, reps: 37), 0) // Division by zero protection
    }

    // MARK: - Lombardi Formula Tests

    func testLombardiFormulaBasicCalculation() {
        // Lombardi: 1RM = weight * reps^0.1
        // 200 lbs @ 10 reps = 200 * 10^0.1 = 200 * 1.259 = 251.8
        let result = RMCalculator.lombardi(weight: 200, reps: 10)
        XCTAssertEqual(result, 251.8, accuracy: 0.1)
    }

    func testLombardiFormulaWithOneRep() {
        // 200 * 1^0.1 = 200 * 1.0 = 200
        let result = RMCalculator.lombardi(weight: 200, reps: 1)
        XCTAssertEqual(result, 200.0, accuracy: 0.01)
    }

    func testLombardiFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.lombardi(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.lombardi(weight: 200, reps: 0), 0)
    }

    // MARK: - Mayhew Formula Tests

    func testMayhewFormulaBasicCalculation() {
        // Mayhew: 1RM = (100 * weight) / (52.2 + (41.9 * e^(-0.055 * reps)))
        let result = RMCalculator.mayhew(weight: 200, reps: 10)
        // Expected approximately 252 lbs
        XCTAssertGreaterThan(result, 240)
        XCTAssertLessThan(result, 270)
    }

    func testMayhewFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.mayhew(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.mayhew(weight: 200, reps: 0), 0)
    }

    // MARK: - O'Conner Formula Tests

    func testOconnerFormulaBasicCalculation() {
        // O'Conner: 1RM = weight * (1 + reps / 40)
        // 200 lbs @ 10 reps = 200 * (1 + 10/40) = 200 * 1.25 = 250
        let result = RMCalculator.oconner(weight: 200, reps: 10)
        XCTAssertEqual(result, 250.0, accuracy: 0.01)
    }

    func testOconnerFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.oconner(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.oconner(weight: 200, reps: 0), 0)
    }

    // MARK: - Wathan Formula Tests

    func testWathanFormulaBasicCalculation() {
        // Wathan: 1RM = (100 * weight) / (48.8 + (53.8 * e^(-0.075 * reps)))
        let result = RMCalculator.wathan(weight: 200, reps: 10)
        // Expected approximately 254 lbs
        XCTAssertGreaterThan(result, 240)
        XCTAssertLessThan(result, 270)
    }

    func testWathanFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.wathan(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.wathan(weight: 200, reps: 0), 0)
    }

    // MARK: - Average Formula Tests

    func testAverageFormulaCalculation() {
        let result = RMCalculator.average(weight: 200, reps: 10)

        // Average of Epley, Brzycki, and Lombardi
        let epley = RMCalculator.epley(weight: 200, reps: 10)
        let brzycki = RMCalculator.brzycki(weight: 200, reps: 10)
        let lombardi = RMCalculator.lombardi(weight: 200, reps: 10)
        let expected = (epley + brzycki + lombardi) / 3.0

        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    func testAverageFormulaInvalidInput() {
        XCTAssertEqual(RMCalculator.average(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.average(weight: 200, reps: 0), 0)
    }

    // MARK: - Average All Formulas Tests

    func testAverageAllFormulasCalculation() {
        let result = RMCalculator.averageAll(weight: 200, reps: 10)

        // Should be average of all 6 formulas
        let formulas = [
            RMCalculator.epley(weight: 200, reps: 10),
            RMCalculator.brzycki(weight: 200, reps: 10),
            RMCalculator.lombardi(weight: 200, reps: 10),
            RMCalculator.mayhew(weight: 200, reps: 10),
            RMCalculator.oconner(weight: 200, reps: 10),
            RMCalculator.wathan(weight: 200, reps: 10)
        ]
        let expected = formulas.reduce(0, +) / 6.0

        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    func testAverageAllFormulasInvalidInput() {
        XCTAssertEqual(RMCalculator.averageAll(weight: 0, reps: 10), 0)
        XCTAssertEqual(RMCalculator.averageAll(weight: 200, reps: 0), 0)
    }

    // MARK: - Strength Targets Tests

    func testStrengthTargetsWeek1Strength() {
        let targets = RMCalculator.strengthTargets(oneRM: 250, week: 1, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.60)
        XCTAssertEqual(targets.percentage1RM, 60)
        XCTAssertEqual(targets.targetLoad, 150, accuracy: 0.1)
        XCTAssertEqual(targets.targetReps, 12)
        XCTAssertEqual(targets.targetSets, 3)
    }

    func testStrengthTargetsWeek5Strength() {
        let targets = RMCalculator.strengthTargets(oneRM: 250, week: 5, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.80)
        XCTAssertEqual(targets.percentage1RM, 80)
        XCTAssertEqual(targets.targetLoad, 200, accuracy: 0.1)
        XCTAssertEqual(targets.targetReps, 8)
    }

    func testStrengthTargetsWeek8Strength() {
        let targets = RMCalculator.strengthTargets(oneRM: 250, week: 8, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.85)
        XCTAssertEqual(targets.percentage1RM, 85)
    }

    func testStrengthTargetsHypertrophy() {
        let targets = RMCalculator.strengthTargets(oneRM: 200, week: 4, programType: .hypertrophy)

        XCTAssertEqual(targets.intensity, 0.65)
        XCTAssertEqual(targets.targetReps, 12)
        XCTAssertEqual(targets.targetSets, 4)
    }

    func testStrengthTargetsPower() {
        let targets = RMCalculator.strengthTargets(oneRM: 200, week: 4, programType: .power)

        XCTAssertEqual(targets.intensity, 0.55)
        XCTAssertEqual(targets.targetReps, 5)
        XCTAssertEqual(targets.targetSets, 5)
    }

    func testStrengthTargetsEndurance() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 4, programType: .endurance)

        XCTAssertEqual(targets.intensity, 0.45)
        XCTAssertEqual(targets.targetReps, 15)
        XCTAssertEqual(targets.targetSets, 3)
    }

    // MARK: - StrengthTarget Model Tests

    func testStrengthTargetFormattedLoad() {
        let target = StrengthTarget(
            targetLoad: 187.3,
            targetReps: 8,
            targetSets: 3,
            intensity: 0.75,
            percentage1RM: 75
        )

        // Should round to nearest 0.5
        XCTAssertEqual(target.formattedLoad, 187.5)
    }

    func testStrengthTargetDescription() {
        let target = StrengthTarget(
            targetLoad: 200.0,
            targetReps: 8,
            targetSets: 3,
            intensity: 0.80,
            percentage1RM: 80
        )

        let description = target.description
        XCTAssertTrue(description.contains("3 sets"))
        XCTAssertTrue(description.contains("8 reps"))
        XCTAssertTrue(description.contains("80%"))
        XCTAssertTrue(description.contains("200"))
    }

    // MARK: - Formula Comparison Tests

    func testAllFormulasReturnReasonableValues() {
        // All formulas should return values within a reasonable range of each other
        let weight = 185.0
        let reps = 8

        let epley = RMCalculator.epley(weight: weight, reps: reps)
        let brzycki = RMCalculator.brzycki(weight: weight, reps: reps)
        let lombardi = RMCalculator.lombardi(weight: weight, reps: reps)
        let mayhew = RMCalculator.mayhew(weight: weight, reps: reps)
        let oconner = RMCalculator.oconner(weight: weight, reps: reps)
        let wathan = RMCalculator.wathan(weight: weight, reps: reps)

        // All results should be greater than the lifted weight
        XCTAssertGreaterThan(epley, weight)
        XCTAssertGreaterThan(brzycki, weight)
        XCTAssertGreaterThan(lombardi, weight)
        XCTAssertGreaterThan(mayhew, weight)
        XCTAssertGreaterThan(oconner, weight)
        XCTAssertGreaterThan(wathan, weight)

        // All results should be within 30% of each other
        let allResults = [epley, brzycki, lombardi, mayhew, oconner, wathan]
        let minResult = allResults.min()!
        let maxResult = allResults.max()!

        XCTAssertLessThan(maxResult / minResult, 1.30, "Formulas should not differ by more than 30%")
    }

    // MARK: - Edge Cases Tests

    func testVeryHighReps() {
        // Formulas should still work with high reps
        let result = RMCalculator.epley(weight: 50, reps: 30)
        XCTAssertGreaterThan(result, 50)
    }

    func testVeryHeavyWeight() {
        // Should handle heavy weights correctly
        let result = RMCalculator.average(weight: 500, reps: 5)
        XCTAssertGreaterThan(result, 500)
        XCTAssertLessThan(result, 700)
    }

    func testDecimalWeight() {
        // Should handle decimal weights
        let result = RMCalculator.epley(weight: 185.5, reps: 8)
        XCTAssertGreaterThan(result, 185.5)
    }

    // MARK: - Progressive Week Tests

    func testProgressiveIntensityAcrossWeeks() {
        // Intensity should increase across weeks for strength program
        var previousIntensity = 0.0

        for week in 1...8 {
            let targets = RMCalculator.strengthTargets(oneRM: 200, week: week, programType: .strength)

            // Intensity should be at least as high as previous week
            XCTAssertGreaterThanOrEqual(targets.intensity, previousIntensity)
            previousIntensity = targets.intensity
        }
    }
}
