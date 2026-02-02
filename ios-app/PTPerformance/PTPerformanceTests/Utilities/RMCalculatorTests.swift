//
//  RMCalculatorTests.swift
//  PTPerformanceTests
//
//  Unit tests for RMCalculator (One-Rep Max Calculator)
//  Tests 1RM formulas and strength target calculations
//

import XCTest
@testable import PTPerformance

final class RMCalculatorTests: XCTestCase {

    // MARK: - Test Constants
    private let accuracy: Double = 0.01

    // MARK: - Epley Formula Tests

    func testEpley_ValidInput() {
        // Epley: 1RM = weight * (1 + reps / 30)
        // 100 * (1 + 10/30) = 100 * 1.333 = 133.33
        let result = RMCalculator.epley(weight: 100, reps: 10)
        XCTAssertEqual(result, 133.33, accuracy: accuracy)
    }

    func testEpley_SingleRep() {
        // 1 rep should return slightly more than weight
        // 100 * (1 + 1/30) = 100 * 1.033 = 103.33
        let result = RMCalculator.epley(weight: 100, reps: 1)
        XCTAssertEqual(result, 103.33, accuracy: accuracy)
    }

    func testEpley_ZeroWeight() {
        let result = RMCalculator.epley(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testEpley_ZeroReps() {
        let result = RMCalculator.epley(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    func testEpley_NegativeWeight() {
        let result = RMCalculator.epley(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testEpley_NegativeReps() {
        let result = RMCalculator.epley(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Brzycki Formula Tests

    func testBrzycki_ValidInput() {
        // Brzycki: 1RM = weight * (36 / (37 - reps))
        // 100 * (36 / (37 - 10)) = 100 * (36 / 27) = 133.33
        let result = RMCalculator.brzycki(weight: 100, reps: 10)
        XCTAssertEqual(result, 133.33, accuracy: accuracy)
    }

    func testBrzycki_SingleRep() {
        // 100 * (36 / 36) = 100
        let result = RMCalculator.brzycki(weight: 100, reps: 1)
        XCTAssertEqual(result, 100.0, accuracy: accuracy)
    }

    func testBrzycki_ZeroWeight() {
        let result = RMCalculator.brzycki(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testBrzycki_ZeroReps() {
        let result = RMCalculator.brzycki(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    func testBrzycki_TooManyReps() {
        // Formula breaks down at 37+ reps (division by zero or negative)
        let result = RMCalculator.brzycki(weight: 100, reps: 37)
        XCTAssertEqual(result, 0)
    }

    func testBrzycki_NegativeWeight() {
        let result = RMCalculator.brzycki(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Lombardi Formula Tests

    func testLombardi_ValidInput() {
        // Lombardi: 1RM = weight * reps^0.1
        // 100 * 10^0.1 = 100 * 1.2589 = 125.89
        let result = RMCalculator.lombardi(weight: 100, reps: 10)
        XCTAssertEqual(result, 125.89, accuracy: accuracy)
    }

    func testLombardi_SingleRep() {
        // 100 * 1^0.1 = 100 * 1 = 100
        let result = RMCalculator.lombardi(weight: 100, reps: 1)
        XCTAssertEqual(result, 100.0, accuracy: accuracy)
    }

    func testLombardi_ZeroWeight() {
        let result = RMCalculator.lombardi(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testLombardi_ZeroReps() {
        let result = RMCalculator.lombardi(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Mayhew Formula Tests

    func testMayhew_ValidInput() {
        // Mayhew: 1RM = (100 * weight) / (52.2 + (41.9 * e^(-0.055 * reps)))
        let result = RMCalculator.mayhew(weight: 100, reps: 10)
        XCTAssertGreaterThan(result, 100) // Should be higher than weight
    }

    func testMayhew_ZeroWeight() {
        let result = RMCalculator.mayhew(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testMayhew_ZeroReps() {
        let result = RMCalculator.mayhew(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - O'Conner Formula Tests

    func testOconner_ValidInput() {
        // O'Conner: 1RM = weight * (1 + reps / 40)
        // 100 * (1 + 10/40) = 100 * 1.25 = 125
        let result = RMCalculator.oconner(weight: 100, reps: 10)
        XCTAssertEqual(result, 125.0, accuracy: accuracy)
    }

    func testOconner_ZeroWeight() {
        let result = RMCalculator.oconner(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testOconner_ZeroReps() {
        let result = RMCalculator.oconner(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Wathan Formula Tests

    func testWathan_ValidInput() {
        // Wathan: 1RM = (100 * weight) / (48.8 + (53.8 * e^(-0.075 * reps)))
        let result = RMCalculator.wathan(weight: 100, reps: 10)
        XCTAssertGreaterThan(result, 100) // Should be higher than weight
    }

    func testWathan_ZeroWeight() {
        let result = RMCalculator.wathan(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testWathan_ZeroReps() {
        let result = RMCalculator.wathan(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Average Formula Tests

    func testAverage_ValidInput() {
        let result = RMCalculator.average(weight: 100, reps: 10)

        // Should be average of Epley, Brzycki, and Lombardi
        let epley = RMCalculator.epley(weight: 100, reps: 10)
        let brzycki = RMCalculator.brzycki(weight: 100, reps: 10)
        let lombardi = RMCalculator.lombardi(weight: 100, reps: 10)
        let expected = (epley + brzycki + lombardi) / 3.0

        XCTAssertEqual(result, expected, accuracy: accuracy)
    }

    func testAverage_ZeroWeight() {
        let result = RMCalculator.average(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testAverage_ZeroReps() {
        let result = RMCalculator.average(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Average All Formula Tests

    func testAverageAll_ValidInput() {
        let result = RMCalculator.averageAll(weight: 100, reps: 10)

        // Should be average of all 6 formulas
        let formulas = [
            RMCalculator.epley(weight: 100, reps: 10),
            RMCalculator.brzycki(weight: 100, reps: 10),
            RMCalculator.lombardi(weight: 100, reps: 10),
            RMCalculator.mayhew(weight: 100, reps: 10),
            RMCalculator.oconner(weight: 100, reps: 10),
            RMCalculator.wathan(weight: 100, reps: 10)
        ]
        let expected = formulas.reduce(0, +) / 6.0

        XCTAssertEqual(result, expected, accuracy: accuracy)
    }

    func testAverageAll_ZeroWeight() {
        let result = RMCalculator.averageAll(weight: 0, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testAverageAll_ZeroReps() {
        let result = RMCalculator.averageAll(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Formula Comparison Tests

    func testFormulas_AllReturnSimilarResults() {
        // All formulas should return similar results for typical use case
        let weight = 100.0
        let reps = 5

        let results = [
            RMCalculator.epley(weight: weight, reps: reps),
            RMCalculator.brzycki(weight: weight, reps: reps),
            RMCalculator.lombardi(weight: weight, reps: reps),
            RMCalculator.mayhew(weight: weight, reps: reps),
            RMCalculator.oconner(weight: weight, reps: reps),
            RMCalculator.wathan(weight: weight, reps: reps)
        ]

        // All results should be within 20% of each other
        let minResult = results.min()!
        let maxResult = results.max()!
        let variance = (maxResult - minResult) / minResult

        XCTAssertLessThan(variance, 0.2, "Formula results should be within 20% of each other")
    }

    func testFormulas_SingleRep_ReturnsApproximatelyWeight() {
        // With 1 rep, most formulas should return approximately the weight
        let weight = 100.0

        let epley = RMCalculator.epley(weight: weight, reps: 1)
        let brzycki = RMCalculator.brzycki(weight: weight, reps: 1)
        let lombardi = RMCalculator.lombardi(weight: weight, reps: 1)

        XCTAssertEqual(brzycki, weight, accuracy: 0.01) // Brzycki returns exact weight at 1 rep
        XCTAssertEqual(lombardi, weight, accuracy: 0.01) // Lombardi also returns exact weight
        XCTAssertEqual(epley, 103.33, accuracy: 0.01) // Epley adds a small amount
    }

    // MARK: - Strength Targets Tests

    func testStrengthTargets_Strength_Week1() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.60, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 60.0, accuracy: accuracy)
        XCTAssertEqual(targets.percentage1RM, 60)
    }

    func testStrengthTargets_Strength_Week5() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.80, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 80.0, accuracy: accuracy)
        XCTAssertEqual(targets.percentage1RM, 80)
    }

    func testStrengthTargets_Hypertrophy() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .hypertrophy)

        XCTAssertEqual(targets.intensity, 0.65, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 12)
        XCTAssertEqual(targets.targetSets, 4)
    }

    func testStrengthTargets_Power() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .power)

        XCTAssertEqual(targets.intensity, 0.55, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 5)
        XCTAssertEqual(targets.targetSets, 5)
    }

    func testStrengthTargets_Endurance() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .endurance)

        XCTAssertEqual(targets.intensity, 0.45, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 15)
        XCTAssertEqual(targets.targetSets, 3)
    }

    func testStrengthTargets_ProgressiveIntensity() {
        // Intensity should increase over weeks
        let week1 = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .strength)
        let week3 = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .strength)
        let week5 = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .strength)
        let week7 = RMCalculator.strengthTargets(oneRM: 100, week: 7, programType: .strength)

        XCTAssertLessThan(week1.intensity, week3.intensity)
        XCTAssertLessThan(week3.intensity, week5.intensity)
        XCTAssertLessThan(week5.intensity, week7.intensity)
    }

    // MARK: - StrengthTarget Tests

    func testStrengthTarget_FormattedLoad() {
        let target = StrengthTarget(
            targetLoad: 97.3,
            targetReps: 8,
            targetSets: 3,
            intensity: 0.80,
            percentage1RM: 80
        )

        // Should round to nearest 0.5
        XCTAssertEqual(target.formattedLoad, 97.5, accuracy: accuracy)
    }

    func testStrengthTarget_FormattedLoad_RoundsCorrectly() {
        // Test rounding to nearest 0.5
        let target1 = StrengthTarget(targetLoad: 97.2, targetReps: 8, targetSets: 3, intensity: 0.80, percentage1RM: 80)
        XCTAssertEqual(target1.formattedLoad, 97.0, accuracy: accuracy) // Rounds down

        let target2 = StrengthTarget(targetLoad: 97.3, targetReps: 8, targetSets: 3, intensity: 0.80, percentage1RM: 80)
        XCTAssertEqual(target2.formattedLoad, 97.5, accuracy: accuracy) // Rounds up

        let target3 = StrengthTarget(targetLoad: 97.75, targetReps: 8, targetSets: 3, intensity: 0.80, percentage1RM: 80)
        XCTAssertEqual(target3.formattedLoad, 98.0, accuracy: accuracy) // Rounds up
    }

    func testStrengthTarget_Description() {
        let target = StrengthTarget(
            targetLoad: 100.0,
            targetReps: 8,
            targetSets: 3,
            intensity: 0.80,
            percentage1RM: 80
        )

        XCTAssertTrue(target.description.contains("3 sets"))
        XCTAssertTrue(target.description.contains("8 reps"))
        XCTAssertTrue(target.description.contains("80%"))
        XCTAssertTrue(target.description.contains("1RM"))
    }

    // MARK: - TrainingFocus Tests

    func testTrainingFocus_AllCasesExist() {
        // Verify all expected training focus types exist
        let _: TrainingFocus = .strength
        let _: TrainingFocus = .hypertrophy
        let _: TrainingFocus = .power
        let _: TrainingFocus = .endurance
    }

    // MARK: - Edge Cases

    func testCalculator_VeryHighWeight() {
        let result = RMCalculator.epley(weight: 1000, reps: 5)
        XCTAssertGreaterThan(result, 1000)
    }

    func testCalculator_VeryHighReps() {
        // High reps should still produce reasonable results for most formulas
        let epley = RMCalculator.epley(weight: 100, reps: 30)
        XCTAssertEqual(epley, 200.0, accuracy: accuracy) // 100 * (1 + 30/30) = 200

        // Brzycki should return 0 for reps >= 37
        let brzycki = RMCalculator.brzycki(weight: 100, reps: 30)
        XCTAssertGreaterThan(brzycki, 0)
    }

    func testCalculator_DecimalWeight() {
        let result = RMCalculator.epley(weight: 102.5, reps: 8)
        XCTAssertGreaterThan(result, 102.5)
    }
}
