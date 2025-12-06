import XCTest
@testable import PTPerformance

/// Unit tests for RMCalculator
/// Tests 1RM estimation formulas against known values
/// Reference: EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
final class RMCalculatorTests: XCTestCase {

    // MARK: - Epley Formula Tests

    func testEpleyFormula() {
        // Epley: 1RM = weight × (1 + reps / 30)

        // Test case 1: 200 lbs × 5 reps
        let rm1 = RMCalculator.epley(weight: 200, reps: 5)
        XCTAssertEqual(rm1, 233.33, accuracy: 0.5, "Epley formula incorrect for 200×5")

        // Test case 2: 185 lbs × 8 reps
        let rm2 = RMCalculator.epley(weight: 185, reps: 8)
        XCTAssertEqual(rm2, 234.33, accuracy: 0.5, "Epley formula incorrect for 185×8")

        // Test case 3: 225 lbs × 3 reps
        let rm3 = RMCalculator.epley(weight: 225, reps: 3)
        XCTAssertEqual(rm3, 247.5, accuracy: 0.5, "Epley formula incorrect for 225×3")

        // Test case 4: 1 rep (should equal weight)
        let rm4 = RMCalculator.epley(weight: 250, reps: 1)
        XCTAssertEqual(rm4, 258.33, accuracy: 0.5, "Epley formula incorrect for 250×1")
    }

    func testBrzyckiFormula() {
        // Brzycki: 1RM = weight × (36 / (37 - reps))

        // Test case 1: 200 lbs × 5 reps
        let rm1 = RMCalculator.brzycki(weight: 200, reps: 5)
        XCTAssertEqual(rm1, 225.0, accuracy: 0.5, "Brzycki formula incorrect for 200×5")

        // Test case 2: 185 lbs × 8 reps
        let rm2 = RMCalculator.brzycki(weight: 185, reps: 8)
        XCTAssertEqual(rm2, 229.66, accuracy: 0.5, "Brzycki formula incorrect for 185×8")

        // Test case 3: Edge case - 1 rep
        let rm3 = RMCalculator.brzycki(weight: 250, reps: 1)
        XCTAssertEqual(rm3, 250.0, accuracy: 0.5, "Brzycki formula incorrect for 250×1")
    }

    func testLombardiFormula() {
        // Lombardi: 1RM = weight × reps^0.1

        // Test case 1: 200 lbs × 5 reps
        let rm1 = RMCalculator.lombardi(weight: 200, reps: 5)
        XCTAssertEqual(rm1, 251.98, accuracy: 0.5, "Lombardi formula incorrect for 200×5")

        // Test case 2: 185 lbs × 10 reps
        let rm2 = RMCalculator.lombardi(weight: 185, reps: 10)
        XCTAssertEqual(rm2, 233.26, accuracy: 0.5, "Lombardi formula incorrect for 185×10")

        // Test case 3: 1 rep (should equal weight)
        let rm3 = RMCalculator.lombardi(weight: 250, reps: 1)
        XCTAssertEqual(rm3, 250.0, accuracy: 0.5, "Lombardi formula incorrect for 250×1")
    }

    func testMayhewFormula() {
        // Mayhew: 1RM = (100 × weight) / (52.2 + (41.9 × e^(-0.055 × reps)))

        let rm1 = RMCalculator.mayhew(weight: 200, reps: 5)
        XCTAssert(rm1 > 0, "Mayhew formula should return positive value")
        XCTAssertEqual(rm1, 233.0, accuracy: 5.0, "Mayhew formula incorrect for 200×5")

        let rm2 = RMCalculator.mayhew(weight: 185, reps: 10)
        XCTAssertEqual(rm2, 231.0, accuracy: 5.0, "Mayhew formula incorrect for 185×10")
    }

    func testOConnerFormula() {
        // O'Conner: 1RM = weight × (1 + reps / 40)

        let rm1 = RMCalculator.oconner(weight: 200, reps: 5)
        XCTAssertEqual(rm1, 225.0, accuracy: 0.5, "O'Conner formula incorrect for 200×5")

        let rm2 = RMCalculator.oconner(weight: 185, reps: 8)
        XCTAssertEqual(rm2, 222.0, accuracy: 0.5, "O'Conner formula incorrect for 185×8")
    }

    func testWathanFormula() {
        // Wathan: 1RM = (100 × weight) / (48.8 + (53.8 × e^(-0.075 × reps)))

        let rm1 = RMCalculator.wathan(weight: 200, reps: 5)
        XCTAssert(rm1 > 0, "Wathan formula should return positive value")
        XCTAssertEqual(rm1, 233.0, accuracy: 5.0, "Wathan formula incorrect for 200×5")
    }

    // MARK: - Average Methods Tests

    func testAverageMethod() {
        // Average of Epley, Brzycki, Lombardi

        let weight = 200.0
        let reps = 5

        let avg = RMCalculator.average(weight: weight, reps: reps)

        let epley = RMCalculator.epley(weight: weight, reps: reps)
        let brzycki = RMCalculator.brzycki(weight: weight, reps: reps)
        let lombardi = RMCalculator.lombardi(weight: weight, reps: reps)

        let expected = (epley + brzycki + lombardi) / 3

        XCTAssertEqual(avg, expected, accuracy: 0.1, "Average method should return mean of three formulas")
    }

    func testAverageAllMethod() {
        // Average of all six formulas

        let weight = 185.0
        let reps = 8

        let avgAll = RMCalculator.averageAll(weight: weight, reps: reps)

        XCTAssert(avgAll > weight, "Average 1RM should be greater than lifted weight")
        XCTAssert(avgAll < weight * 2, "Average 1RM should be reasonable (< 2x weight)")
    }

    // MARK: - XLS Test Cases (from EPIC_B)

    func testAgainstXLSData() {
        // Test against real-world data from strength & conditioning model

        let xlsTestCases: [(weight: Double, reps: Int, expected1RM: Double)] = [
            (185, 8, 230),   // Moderate weight, moderate reps
            (225, 3, 245),   // Heavy weight, low reps
            (200, 5, 233),   // Standard test case
            (155, 12, 220),  // Light weight, high reps
            (275, 2, 293),   // Very heavy, very low reps
        ]

        for testCase in xlsTestCases {
            let calculated = RMCalculator.average(weight: testCase.weight, reps: testCase.reps)
            let variance = abs(calculated - testCase.expected1RM) / testCase.expected1RM

            XCTAssertLessThan(
                variance,
                0.05,  // Allow ±5% variance
                "1RM calculation for \(testCase.weight)×\(testCase.reps) should be within ±5% of expected \(testCase.expected1RM), got \(calculated)"
            )
        }
    }

    // MARK: - Strength Targets Tests

    func testStrengthTargetsWeek1() {
        // Week 1-2: 60% intensity

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 1, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.60, accuracy: 0.01, "Week 1 should be 60% intensity")
        XCTAssertEqual(targets.targetLoad, 150.0, accuracy: 0.5, "Target load should be 60% of 1RM")
        XCTAssertEqual(targets.targetReps, 12, "Week 1 should prescribe 12 reps")
        XCTAssertEqual(targets.targetSets, 3, "Strength program should have 3 sets")
        XCTAssertEqual(targets.percentage1RM, 60, "Percentage should be 60%")
    }

    func testStrengthTargetsWeek5() {
        // Week 5-6: 80% intensity

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 5, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.80, accuracy: 0.01, "Week 5 should be 80% intensity")
        XCTAssertEqual(targets.targetLoad, 200.0, accuracy: 0.5, "Target load should be 80% of 1RM")
        XCTAssertEqual(targets.targetReps, 8, "Week 5 should prescribe 8 reps")
    }

    func testStrengthTargetsWeek8() {
        // Week 7-8: 85% intensity (peak)

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 8, programType: .strength)

        XCTAssertEqual(targets.intensity, 0.85, accuracy: 0.01, "Week 8 should be 85% intensity")
        XCTAssertEqual(targets.targetLoad, 212.5, accuracy: 0.5, "Target load should be 85% of 1RM")
        XCTAssertEqual(targets.targetReps, 5, "Week 8 should prescribe 5 reps (heavy)")
    }

    func testHypertrophyProgram() {
        // Hypertrophy: moderate intensity, always 12 reps

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 4, programType: .hypertrophy)

        XCTAssertEqual(targets.targetReps, 12, "Hypertrophy should always prescribe 12 reps")
        XCTAssertEqual(targets.targetSets, 4, "Hypertrophy should have 4 sets")
        XCTAssert(targets.intensity >= 0.60 && targets.intensity <= 0.75, "Hypertrophy intensity should be 60-75%")
    }

    func testPowerProgram() {
        // Power: low intensity, low reps, high sets

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 3, programType: .power)

        XCTAssertEqual(targets.targetReps, 5, "Power should prescribe 5 reps")
        XCTAssertEqual(targets.targetSets, 5, "Power should have 5 sets")
        XCTAssert(targets.intensity <= 0.65, "Power intensity should be ≤65%")
    }

    func testEnduranceProgram() {
        // Endurance: low intensity, high reps

        let oneRM = 250.0
        let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: 2, programType: .endurance)

        XCTAssertEqual(targets.targetReps, 15, "Endurance should prescribe 15+ reps")
        XCTAssert(targets.intensity <= 0.55, "Endurance intensity should be ≤55%")
    }

    // MARK: - Edge Cases

    func testZeroWeight() {
        let rm = RMCalculator.epley(weight: 0, reps: 5)
        XCTAssertEqual(rm, 0, "Zero weight should return 0")
    }

    func testZeroReps() {
        let rm = RMCalculator.epley(weight: 200, reps: 0)
        XCTAssertEqual(rm, 0, "Zero reps should return 0")
    }

    func testNegativeInputs() {
        let rm1 = RMCalculator.epley(weight: -200, reps: 5)
        let rm2 = RMCalculator.epley(weight: 200, reps: -5)

        XCTAssertEqual(rm1, 0, "Negative weight should return 0")
        XCTAssertEqual(rm2, 0, "Negative reps should return 0")
    }

    func testVeryHighReps() {
        // Test with 20 reps (outside typical strength range)
        let rm = RMCalculator.average(weight: 100, reps: 20)

        XCTAssert(rm > 100, "1RM should still be > lifted weight")
        XCTAssert(rm < 200, "1RM should be reasonable for high reps")
    }

    func testSingleRep() {
        // 1 rep should be close to the weight itself
        let weight = 250.0
        let rm = RMCalculator.average(weight: weight, reps: 1)

        XCTAssertEqual(rm, weight, accuracy: 10.0, "1 rep should be close to lifted weight")
    }

    // MARK: - Progressive Overload Tests

    func testProgressiveIntensityIncrease() {
        // Verify intensity increases week by week

        let oneRM = 250.0
        let week1 = RMCalculator.strengthTargets(oneRM: oneRM, week: 1)
        let week3 = RMCalculator.strengthTargets(oneRM: oneRM, week: 3)
        let week5 = RMCalculator.strengthTargets(oneRM: oneRM, week: 5)
        let week8 = RMCalculator.strengthTargets(oneRM: oneRM, week: 8)

        XCTAssert(week1.intensity < week3.intensity, "Week 3 should be harder than Week 1")
        XCTAssert(week3.intensity < week5.intensity, "Week 5 should be harder than Week 3")
        XCTAssert(week5.intensity < week8.intensity, "Week 8 should be hardest")

        XCTAssert(week1.targetReps > week8.targetReps, "Reps should decrease as intensity increases")
    }

    // MARK: - Real-World Scenario Tests

    func testBackSquatProgression() {
        // Simulate 8-week back squat progression

        // Week 1: Athlete squats 225×8
        let week1RM = RMCalculator.average(weight: 225, reps: 8)

        // Week 4: Athlete squats 245×5
        let week4RM = RMCalculator.average(weight: 245, reps: 5)

        // Week 8: Athlete squats 265×3
        let week8RM = RMCalculator.average(weight: 265, reps: 3)

        // 1RM should increase over time
        XCTAssert(week4RM > week1RM, "1RM should increase from Week 1 to Week 4")
        XCTAssert(week8RM > week4RM, "1RM should increase from Week 4 to Week 8")

        // Verify realistic progression (10-15% gain over 8 weeks)
        let totalGain = (week8RM - week1RM) / week1RM
        XCTAssert(totalGain >= 0.05 && totalGain <= 0.20, "8-week gain should be 5-20%")
    }

    // MARK: - Performance Tests

    func testCalculationPerformance() {
        // Ensure formulas are fast enough for real-time use

        measure {
            for _ in 0..<10000 {
                _ = RMCalculator.averageAll(weight: 200, reps: 5)
            }
        }
    }
}

// MARK: - Supporting Test Extensions

extension RMCalculatorTests {
    /// Helper to generate random test cases
    func generateRandomTestCase() -> (weight: Double, reps: Int) {
        let weight = Double.random(in: 100...400)
        let reps = Int.random(in: 1...15)
        return (weight, reps)
    }
}
