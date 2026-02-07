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

    func testEpley_VariousRepRanges() {
        // Test rep ranges 1-20
        let weight = 100.0

        // 1 rep: 100 * (1 + 1/30) = 103.33
        XCTAssertEqual(RMCalculator.epley(weight: weight, reps: 1), 103.33, accuracy: accuracy)

        // 5 reps: 100 * (1 + 5/30) = 116.67
        XCTAssertEqual(RMCalculator.epley(weight: weight, reps: 5), 116.67, accuracy: accuracy)

        // 10 reps: 100 * (1 + 10/30) = 133.33
        XCTAssertEqual(RMCalculator.epley(weight: weight, reps: 10), 133.33, accuracy: accuracy)

        // 15 reps: 100 * (1 + 15/30) = 150.00
        XCTAssertEqual(RMCalculator.epley(weight: weight, reps: 15), 150.00, accuracy: accuracy)

        // 20 reps: 100 * (1 + 20/30) = 166.67
        XCTAssertEqual(RMCalculator.epley(weight: weight, reps: 20), 166.67, accuracy: accuracy)
    }

    func testEpley_CommonTrainingWeights() {
        // Test common barbell weights
        XCTAssertGreaterThan(RMCalculator.epley(weight: 135, reps: 5), 135)
        XCTAssertGreaterThan(RMCalculator.epley(weight: 225, reps: 3), 225)
        XCTAssertGreaterThan(RMCalculator.epley(weight: 315, reps: 2), 315)
        XCTAssertGreaterThan(RMCalculator.epley(weight: 405, reps: 1), 405)
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

    func testBrzycki_VariousRepRanges() {
        let weight = 100.0

        // Test various rep ranges (valid range: 1-36)
        XCTAssertEqual(RMCalculator.brzycki(weight: weight, reps: 1), 100.0, accuracy: accuracy)
        XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: 5), weight)
        XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: 10), weight)
        XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: 12), weight)

        // At 36 reps, should return a very high value (36 / (37-36) = 36)
        let at36 = RMCalculator.brzycki(weight: weight, reps: 36)
        XCTAssertGreaterThan(at36, weight * 30)
    }

    func testBrzycki_EdgeAtLimit() {
        // Test at the limit of the formula
        let at36 = RMCalculator.brzycki(weight: 100, reps: 36)
        XCTAssertGreaterThan(at36, 0)

        let at37 = RMCalculator.brzycki(weight: 100, reps: 37)
        XCTAssertEqual(at37, 0)

        let at38 = RMCalculator.brzycki(weight: 100, reps: 38)
        XCTAssertEqual(at38, 0)
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

    func testLombardi_NegativeWeight() {
        let result = RMCalculator.lombardi(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testLombardi_NegativeReps() {
        let result = RMCalculator.lombardi(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    func testLombardi_VariousRepRanges() {
        let weight = 100.0

        // Test various rep ranges
        for reps in 1...20 {
            let result = RMCalculator.lombardi(weight: weight, reps: reps)
            XCTAssertGreaterThanOrEqual(result, weight)
        }
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

    func testMayhew_NegativeWeight() {
        let result = RMCalculator.mayhew(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testMayhew_NegativeReps() {
        let result = RMCalculator.mayhew(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    func testMayhew_SingleRep() {
        let result = RMCalculator.mayhew(weight: 100, reps: 1)
        // At 1 rep, should be close to weight but formula still applies
        XCTAssertGreaterThan(result, 90)
        XCTAssertLessThan(result, 120)
    }

    func testMayhew_HighReps() {
        // Mayhew formula should still work for higher rep ranges
        let result = RMCalculator.mayhew(weight: 100, reps: 20)
        XCTAssertGreaterThan(result, 100)
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

    func testOconner_NegativeWeight() {
        let result = RMCalculator.oconner(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testOconner_NegativeReps() {
        let result = RMCalculator.oconner(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    func testOconner_SingleRep() {
        // 100 * (1 + 1/40) = 102.5
        let result = RMCalculator.oconner(weight: 100, reps: 1)
        XCTAssertEqual(result, 102.5, accuracy: accuracy)
    }

    func testOconner_VariousRepRanges() {
        let weight = 100.0

        // 5 reps: 100 * (1 + 5/40) = 112.5
        XCTAssertEqual(RMCalculator.oconner(weight: weight, reps: 5), 112.5, accuracy: accuracy)

        // 20 reps: 100 * (1 + 20/40) = 150
        XCTAssertEqual(RMCalculator.oconner(weight: weight, reps: 20), 150.0, accuracy: accuracy)
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

    func testWathan_NegativeWeight() {
        let result = RMCalculator.wathan(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testWathan_NegativeReps() {
        let result = RMCalculator.wathan(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    func testWathan_SingleRep() {
        let result = RMCalculator.wathan(weight: 100, reps: 1)
        XCTAssertGreaterThan(result, 90)
        XCTAssertLessThan(result, 110)
    }

    func testWathan_HighReps() {
        let result = RMCalculator.wathan(weight: 100, reps: 20)
        XCTAssertGreaterThan(result, 100)
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

    func testAverage_NegativeWeight() {
        let result = RMCalculator.average(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testAverage_NegativeReps() {
        let result = RMCalculator.average(weight: 100, reps: -5)
        XCTAssertEqual(result, 0)
    }

    func testAverage_VariousRepRanges() {
        let weight = 100.0

        for reps in 1...12 {
            let result = RMCalculator.average(weight: weight, reps: reps)
            XCTAssertGreaterThanOrEqual(result, weight)
        }
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

    func testAverageAll_NegativeWeight() {
        let result = RMCalculator.averageAll(weight: -100, reps: 10)
        XCTAssertEqual(result, 0)
    }

    func testAverageAll_NegativeReps() {
        let result = RMCalculator.averageAll(weight: 100, reps: -5)
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

    func testFormulas_ConsistentOrdering() {
        // Test that formula ordering is consistent across rep ranges
        let weight = 100.0

        for reps in [3, 5, 8, 10, 12] {
            let epley = RMCalculator.epley(weight: weight, reps: reps)
            let brzycki = RMCalculator.brzycki(weight: weight, reps: reps)
            let oconner = RMCalculator.oconner(weight: weight, reps: reps)

            // Epley typically gives higher estimates than O'Conner
            XCTAssertGreaterThanOrEqual(epley, oconner)

            // All formulas should give results greater than weight
            XCTAssertGreaterThan(epley, weight)
            XCTAssertGreaterThan(brzycki, weight)
            XCTAssertGreaterThan(oconner, weight)
        }
    }

    // MARK: - Rep Range Tests (1-20)

    func testFormulas_RepRange1To5() {
        let weight = 100.0

        for reps in 1...5 {
            XCTAssertGreaterThan(RMCalculator.epley(weight: weight, reps: reps), 0)
            XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: reps), 0)
            XCTAssertGreaterThan(RMCalculator.lombardi(weight: weight, reps: reps), 0)
            XCTAssertGreaterThan(RMCalculator.average(weight: weight, reps: reps), 0)
        }
    }

    func testFormulas_RepRange6To10() {
        let weight = 100.0

        for reps in 6...10 {
            XCTAssertGreaterThan(RMCalculator.epley(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.lombardi(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.mayhew(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.oconner(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.wathan(weight: weight, reps: reps), weight)
        }
    }

    func testFormulas_RepRange11To20() {
        let weight = 100.0

        for reps in 11...20 {
            XCTAssertGreaterThan(RMCalculator.epley(weight: weight, reps: reps), weight * 1.2)
            XCTAssertGreaterThan(RMCalculator.brzycki(weight: weight, reps: reps), weight * 1.2)
            XCTAssertGreaterThan(RMCalculator.lombardi(weight: weight, reps: reps), weight)
            XCTAssertGreaterThan(RMCalculator.average(weight: weight, reps: reps), weight * 1.2)
        }
    }

    // MARK: - Percentage Calculations Tests

    func testPercentageCalculation_FromEstimated1RM() {
        let estimated1RM = RMCalculator.epley(weight: 200, reps: 5)

        // Calculate what weight to use for 80% of 1RM
        let eighty_percent = estimated1RM * 0.80
        XCTAssertGreaterThan(eighty_percent, 0)

        // Calculate what weight to use for 70% of 1RM
        let seventy_percent = estimated1RM * 0.70
        XCTAssertGreaterThan(seventy_percent, 0)
        XCTAssertLessThan(seventy_percent, eighty_percent)

        // 90% should be higher than 80%
        let ninety_percent = estimated1RM * 0.90
        XCTAssertGreaterThan(ninety_percent, eighty_percent)
    }

    // MARK: - Strength Targets Tests

    func testStrengthTargets_Strength_Week1() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.60, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 60.0, accuracy: accuracy)
        XCTAssertEqual(targets.percentage1RM, 60)
    }

    func testStrengthTargets_Strength_Week2() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 2, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.60, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 60.0, accuracy: accuracy)
    }

    func testStrengthTargets_Strength_Week3() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.70, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 70.0, accuracy: accuracy)
    }

    func testStrengthTargets_Strength_Week4() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 4, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.70, accuracy: accuracy)
    }

    func testStrengthTargets_Strength_Week5() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.80, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 80.0, accuracy: accuracy)
        XCTAssertEqual(targets.percentage1RM, 80)
    }

    func testStrengthTargets_Strength_Week6() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 6, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.80, accuracy: accuracy)
    }

    func testStrengthTargets_Strength_Week7() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 7, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.85, accuracy: accuracy)
        XCTAssertEqual(targets.targetLoad, 85.0, accuracy: accuracy)
    }

    func testStrengthTargets_Strength_Week8() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 8, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.85, accuracy: accuracy)
    }

    func testStrengthTargets_Hypertrophy() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .hypertrophy)

        XCTAssertEqual(targets.intensity, 0.65, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 12)
        XCTAssertEqual(targets.targetSets, 4)
    }

    func testStrengthTargets_Hypertrophy_AllWeeks() {
        let week1 = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .hypertrophy)
        let week3 = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .hypertrophy)
        let week5 = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .hypertrophy)
        let week7 = RMCalculator.strengthTargets(oneRM: 100, week: 7, programType: .hypertrophy)

        XCTAssertEqual(week1.intensity, 0.60, accuracy: accuracy)
        XCTAssertEqual(week3.intensity, 0.65, accuracy: accuracy)
        XCTAssertEqual(week5.intensity, 0.70, accuracy: accuracy)
        XCTAssertEqual(week7.intensity, 0.75, accuracy: accuracy)
    }

    func testStrengthTargets_Power() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .power)

        XCTAssertEqual(targets.intensity, 0.55, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 5)
        XCTAssertEqual(targets.targetSets, 5)
    }

    func testStrengthTargets_Power_AllWeeks() {
        let week1 = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .power)
        let week3 = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .power)
        let week5 = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .power)
        let week7 = RMCalculator.strengthTargets(oneRM: 100, week: 7, programType: .power)

        XCTAssertEqual(week1.intensity, 0.50, accuracy: accuracy)
        XCTAssertEqual(week3.intensity, 0.55, accuracy: accuracy)
        XCTAssertEqual(week5.intensity, 0.60, accuracy: accuracy)
        XCTAssertEqual(week7.intensity, 0.65, accuracy: accuracy)
    }

    func testStrengthTargets_Endurance() {
        let targets = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .endurance)

        XCTAssertEqual(targets.intensity, 0.45, accuracy: accuracy)
        XCTAssertEqual(targets.targetReps, 15)
        XCTAssertEqual(targets.targetSets, 3)
    }

    func testStrengthTargets_Endurance_AllWeeks() {
        let week1 = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .endurance)
        let week3 = RMCalculator.strengthTargets(oneRM: 100, week: 3, programType: .endurance)
        let week5 = RMCalculator.strengthTargets(oneRM: 100, week: 5, programType: .endurance)
        let week7 = RMCalculator.strengthTargets(oneRM: 100, week: 7, programType: .endurance)

        XCTAssertEqual(week1.intensity, 0.40, accuracy: accuracy)
        XCTAssertEqual(week3.intensity, 0.45, accuracy: accuracy)
        XCTAssertEqual(week5.intensity, 0.50, accuracy: accuracy)
        XCTAssertEqual(week7.intensity, 0.55, accuracy: accuracy)
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

    func testStrengthTargets_DefaultWeek() {
        // Test week outside normal range uses default
        let defaultWeek = RMCalculator.strengthTargets(oneRM: 100, week: 10, programType: .strength)
        XCTAssertEqual(defaultWeek.intensity, 0.70, accuracy: accuracy)
    }

    func testStrengthTargets_Various1RMs() {
        // Test with various 1RM values
        let oneRMs: [Double] = [100, 150, 200, 250, 300, 405]

        for oneRM in oneRMs {
            let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 5, programType: .strength)
            XCTAssertEqual(targets.targetLoad, oneRM * 0.80, accuracy: accuracy)
        }
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

    func testStrengthTarget_FormattedLoad_VariousValues() {
        // Test various load values
        let loads: [(Double, Double)] = [
            (100.0, 100.0),
            (100.25, 100.5),
            (100.24, 100.0),
            (100.5, 100.5),
            (100.75, 101.0),
            (100.74, 100.5)
        ]

        for (input, expected) in loads {
            let target = StrengthTarget(targetLoad: input, targetReps: 8, targetSets: 3, intensity: 0.80, percentage1RM: 80)
            XCTAssertEqual(target.formattedLoad, expected, accuracy: accuracy)
        }
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

    func testStrengthTarget_DescriptionFormat() {
        let target = StrengthTarget(
            targetLoad: 200.0,
            targetReps: 5,
            targetSets: 5,
            intensity: 0.85,
            percentage1RM: 85
        )

        let description = target.description
        XCTAssertTrue(description.contains("5 sets"))
        XCTAssertTrue(description.contains("5 reps"))
        XCTAssertTrue(description.contains("85%"))
    }

    // MARK: - TrainingFocus Tests

    func testTrainingFocus_AllCasesExist() {
        // Verify all expected training focus types exist
        let _: TrainingFocus = .strength
        let _: TrainingFocus = .hypertrophy
        let _: TrainingFocus = .power
        let _: TrainingFocus = .endurance
    }

    func testTrainingFocus_CorrectSetsPerType() {
        let strengthTargets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .strength)
        let hypertrophyTargets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .hypertrophy)
        let powerTargets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .power)
        let enduranceTargets = RMCalculator.strengthTargets(oneRM: 100, week: 1, programType: .endurance)

        XCTAssertEqual(strengthTargets.targetSets, 3)
        XCTAssertEqual(hypertrophyTargets.targetSets, 4)
        XCTAssertEqual(powerTargets.targetSets, 5)
        XCTAssertEqual(enduranceTargets.targetSets, 3)
    }

    // MARK: - Edge Cases

    func testCalculator_VeryHighWeight() {
        let result = RMCalculator.epley(weight: 1000, reps: 5)
        XCTAssertGreaterThan(result, 1000)
    }

    func testCalculator_VeryLowWeight() {
        let result = RMCalculator.epley(weight: 0.5, reps: 10)
        XCTAssertGreaterThan(result, 0.5)
    }

    func testCalculator_VeryHighReps() {
        // High reps should still produce reasonable results for most formulas
        let epley = RMCalculator.epley(weight: 100, reps: 30)
        XCTAssertEqual(epley, 200.0, accuracy: accuracy) // 100 * (1 + 30/30) = 200

        // Brzycki should return 0 for reps >= 37
        let brzycki = RMCalculator.brzycki(weight: 100, reps: 30)
        XCTAssertGreaterThan(brzycki, 0)

        let brzycki37 = RMCalculator.brzycki(weight: 100, reps: 37)
        XCTAssertEqual(brzycki37, 0)
    }

    func testCalculator_DecimalWeight() {
        let result = RMCalculator.epley(weight: 102.5, reps: 8)
        XCTAssertGreaterThan(result, 102.5)
    }

    func testCalculator_BothZero() {
        XCTAssertEqual(RMCalculator.epley(weight: 0, reps: 0), 0)
        XCTAssertEqual(RMCalculator.brzycki(weight: 0, reps: 0), 0)
        XCTAssertEqual(RMCalculator.lombardi(weight: 0, reps: 0), 0)
        XCTAssertEqual(RMCalculator.average(weight: 0, reps: 0), 0)
        XCTAssertEqual(RMCalculator.averageAll(weight: 0, reps: 0), 0)
    }

    func testCalculator_BothNegative() {
        XCTAssertEqual(RMCalculator.epley(weight: -100, reps: -5), 0)
        XCTAssertEqual(RMCalculator.brzycki(weight: -100, reps: -5), 0)
        XCTAssertEqual(RMCalculator.lombardi(weight: -100, reps: -5), 0)
        XCTAssertEqual(RMCalculator.average(weight: -100, reps: -5), 0)
    }

    func testCalculator_VerySmallWeight() {
        // Test with very small weights (accessory work)
        let result = RMCalculator.epley(weight: 5, reps: 15)
        XCTAssertGreaterThan(result, 5)
    }

    func testCalculator_CommonBarbellWeights() {
        // Test with common barbell configurations
        let weights: [Double] = [45, 95, 135, 185, 225, 275, 315, 365, 405, 455, 495, 545, 585]

        for weight in weights {
            for reps in [1, 3, 5, 8, 10] {
                let result = RMCalculator.average(weight: weight, reps: reps)
                XCTAssertGreaterThanOrEqual(result, weight)
            }
        }
    }
}
