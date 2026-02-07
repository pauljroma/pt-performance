//
//  RTSTestingViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for RTSTestingViewModel
//  Tests criteria management, test recording, readiness scoring, and phase advancement
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - RTSTestingViewModel Tests

@MainActor
final class RTSTestingViewModelTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_CriteriaIsEmpty() {
        XCTAssertTrue(sut.criteria.isEmpty)
    }

    func testInitialState_TestResultsIsEmpty() {
        XCTAssertTrue(sut.testResults.isEmpty)
    }

    func testInitialState_AdvancementsIsEmpty() {
        XCTAssertTrue(sut.advancements.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsSavingIsFalse() {
        XCTAssertFalse(sut.isSaving)
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_SuccessMessageIsNil() {
        XCTAssertNil(sut.successMessage)
    }

    func testInitialState_SelectedCriterionIsNil() {
        XCTAssertNil(sut.selectedCriterion)
    }

    func testInitialState_TestValueIsEmpty() {
        XCTAssertEqual(sut.testValue, "")
    }

    func testInitialState_TestNotesIsEmpty() {
        XCTAssertEqual(sut.testNotes, "")
    }

    func testInitialState_ReadinessScoresAreZero() {
        XCTAssertEqual(sut.physicalScore, 0)
        XCTAssertEqual(sut.functionalScore, 0)
        XCTAssertEqual(sut.psychologicalScore, 0)
    }

    func testInitialState_RiskFactorsIsEmpty() {
        XCTAssertTrue(sut.riskFactors.isEmpty)
    }

    func testInitialState_ReadinessNotesIsEmpty() {
        XCTAssertEqual(sut.readinessNotes, "")
    }
}

// MARK: - Computed Properties Tests - Criteria Status

@MainActor
final class RTSTestingViewModelCriteriaStatusTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - passedCriteria Tests

    func testPassedCriteria_WhenNoCriteria_ReturnsEmpty() {
        XCTAssertTrue(sut.passedCriteria.isEmpty)
    }

    func testPassedCriteria_WhenNoTestResults_ReturnsEmpty() {
        sut.criteria = createSampleCriteria(count: 3)
        XCTAssertTrue(sut.passedCriteria.isEmpty)
    }

    func testPassedCriteria_WhenSomePassed_ReturnsOnlyPassed() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        // Mark first criterion as passed
        sut.testResults[criteria[0].id] = createTestResult(
            criterionId: criteria[0].id,
            passed: true
        )
        // Mark second criterion as failed
        sut.testResults[criteria[1].id] = createTestResult(
            criterionId: criteria[1].id,
            passed: false
        )

        XCTAssertEqual(sut.passedCriteria.count, 1)
        XCTAssertEqual(sut.passedCriteria.first?.id, criteria[0].id)
    }

    func testPassedCriteria_WhenAllPassed_ReturnsAll() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        for criterion in criteria {
            sut.testResults[criterion.id] = createTestResult(
                criterionId: criterion.id,
                passed: true
            )
        }

        XCTAssertEqual(sut.passedCriteria.count, 3)
    }

    // MARK: - failedCriteria Tests

    func testFailedCriteria_WhenNoCriteria_ReturnsEmpty() {
        XCTAssertTrue(sut.failedCriteria.isEmpty)
    }

    func testFailedCriteria_WhenNoTestResults_ReturnsEmpty() {
        sut.criteria = createSampleCriteria(count: 3)
        XCTAssertTrue(sut.failedCriteria.isEmpty)
    }

    func testFailedCriteria_WhenSomeFailed_ReturnsOnlyFailed() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        // Mark first criterion as passed
        sut.testResults[criteria[0].id] = createTestResult(
            criterionId: criteria[0].id,
            passed: true
        )
        // Mark second criterion as failed
        sut.testResults[criteria[1].id] = createTestResult(
            criterionId: criteria[1].id,
            passed: false
        )

        XCTAssertEqual(sut.failedCriteria.count, 1)
        XCTAssertEqual(sut.failedCriteria.first?.id, criteria[1].id)
    }

    // MARK: - untestedCriteria Tests

    func testUntestedCriteria_WhenNoCriteria_ReturnsEmpty() {
        XCTAssertTrue(sut.untestedCriteria.isEmpty)
    }

    func testUntestedCriteria_WhenNoTestResults_ReturnsAll() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        XCTAssertEqual(sut.untestedCriteria.count, 3)
    }

    func testUntestedCriteria_WhenSomeTested_ReturnsOnlyUntested() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        // Mark first criterion as tested
        sut.testResults[criteria[0].id] = createTestResult(
            criterionId: criteria[0].id,
            passed: true
        )

        XCTAssertEqual(sut.untestedCriteria.count, 2)
        XCTAssertFalse(sut.untestedCriteria.contains(where: { $0.id == criteria[0].id }))
    }

    func testUntestedCriteria_WhenAllTested_ReturnsEmpty() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        for criterion in criteria {
            sut.testResults[criterion.id] = createTestResult(
                criterionId: criterion.id,
                passed: true
            )
        }

        XCTAssertTrue(sut.untestedCriteria.isEmpty)
    }

    // MARK: - progressPercentage Tests

    func testProgressPercentage_WhenNoCriteria_ReturnsZero() {
        XCTAssertEqual(sut.progressPercentage, 0)
    }

    func testProgressPercentage_WhenNonePassed_ReturnsZero() {
        sut.criteria = createSampleCriteria(count: 4)
        XCTAssertEqual(sut.progressPercentage, 0)
    }

    func testProgressPercentage_WhenHalfPassed_ReturnsFifty() {
        let criteria = createSampleCriteria(count: 4)
        sut.criteria = criteria

        sut.testResults[criteria[0].id] = createTestResult(criterionId: criteria[0].id, passed: true)
        sut.testResults[criteria[1].id] = createTestResult(criterionId: criteria[1].id, passed: true)

        XCTAssertEqual(sut.progressPercentage, 50)
    }

    func testProgressPercentage_WhenAllPassed_ReturnsHundred() {
        let criteria = createSampleCriteria(count: 4)
        sut.criteria = criteria

        for criterion in criteria {
            sut.testResults[criterion.id] = createTestResult(criterionId: criterion.id, passed: true)
        }

        XCTAssertEqual(sut.progressPercentage, 100)
    }

    func testProgressPercentage_RoundsDown() {
        let criteria = createSampleCriteria(count: 3)
        sut.criteria = criteria

        sut.testResults[criteria[0].id] = createTestResult(criterionId: criteria[0].id, passed: true)

        // 1/3 = 33.33%, should round to 33
        XCTAssertEqual(sut.progressPercentage, 33)
    }

    // MARK: - progressFraction Tests

    func testProgressFraction_WhenNoCriteria_ReturnsZero() {
        XCTAssertEqual(sut.progressFraction, 0)
    }

    func testProgressFraction_WhenHalfPassed_ReturnsPointFive() {
        let criteria = createSampleCriteria(count: 2)
        sut.criteria = criteria

        sut.testResults[criteria[0].id] = createTestResult(criterionId: criteria[0].id, passed: true)

        XCTAssertEqual(sut.progressFraction, 0.5, accuracy: 0.001)
    }

    // MARK: - progressColor Tests

    func testProgressColor_WhenBelow50Percent_ReturnsOrange() {
        let criteria = createSampleCriteria(count: 4)
        sut.criteria = criteria

        sut.testResults[criteria[0].id] = createTestResult(criterionId: criteria[0].id, passed: true)

        // 25% progress
        XCTAssertEqual(sut.progressColor, .orange)
    }

    func testProgressColor_WhenBetween50And80Percent_ReturnsYellow() {
        let criteria = createSampleCriteria(count: 4)
        sut.criteria = criteria

        sut.testResults[criteria[0].id] = createTestResult(criterionId: criteria[0].id, passed: true)
        sut.testResults[criteria[1].id] = createTestResult(criterionId: criteria[1].id, passed: true)
        sut.testResults[criteria[2].id] = createTestResult(criterionId: criteria[2].id, passed: true)

        // 75% progress
        XCTAssertEqual(sut.progressColor, .yellow)
    }

    func testProgressColor_WhenAbove80Percent_ReturnsGreen() {
        let criteria = createSampleCriteria(count: 5)
        sut.criteria = criteria

        for i in 0..<4 {
            sut.testResults[criteria[i].id] = createTestResult(criterionId: criteria[i].id, passed: true)
        }

        // 80% progress
        XCTAssertEqual(sut.progressColor, .green)
    }

    // MARK: - Helper Methods

    private func createSampleCriteria(count: Int) -> [RTSMilestoneCriterion] {
        (0..<count).map { index in
            RTSMilestoneCriterion(
                id: UUID(),
                phaseId: UUID(),
                category: .strength,
                name: "Criterion \(index)",
                description: "Description \(index)",
                targetValue: 85,
                targetUnit: "%",
                comparisonOperator: .greaterThanOrEqual,
                isRequired: index < 2, // First two are required
                sortOrder: index
            )
        }
    }

    private func createTestResult(criterionId: UUID, passed: Bool) -> RTSTestResult {
        RTSTestResult(
            criterionId: criterionId,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: passed ? 90 : 70,
            unit: "%",
            passed: passed
        )
    }
}

// MARK: - Required/Optional Criteria Tests

@MainActor
final class RTSTestingViewModelRequiredCriteriaTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRequiredCriteria_FiltersCorrectly() {
        let required1 = createCriterion(isRequired: true)
        let required2 = createCriterion(isRequired: true)
        let optional1 = createCriterion(isRequired: false)

        sut.criteria = [required1, optional1, required2]

        XCTAssertEqual(sut.requiredCriteria.count, 2)
        XCTAssertTrue(sut.requiredCriteria.allSatisfy { $0.isRequired })
    }

    func testOptionalCriteria_FiltersCorrectly() {
        let required1 = createCriterion(isRequired: true)
        let optional1 = createCriterion(isRequired: false)
        let optional2 = createCriterion(isRequired: false)

        sut.criteria = [required1, optional1, optional2]

        XCTAssertEqual(sut.optionalCriteria.count, 2)
        XCTAssertTrue(sut.optionalCriteria.allSatisfy { !$0.isRequired })
    }

    func testAllRequiredPassed_WhenNoRequired_ReturnsTrue() {
        let optional = createCriterion(isRequired: false)
        sut.criteria = [optional]

        XCTAssertTrue(sut.allRequiredPassed)
    }

    func testAllRequiredPassed_WhenRequiredNotPassed_ReturnsFalse() {
        let required = createCriterion(isRequired: true)
        sut.criteria = [required]

        XCTAssertFalse(sut.allRequiredPassed)
    }

    func testAllRequiredPassed_WhenSomeRequiredFailed_ReturnsFalse() {
        let required1 = createCriterion(isRequired: true)
        let required2 = createCriterion(isRequired: true)
        sut.criteria = [required1, required2]

        sut.testResults[required1.id] = RTSTestResult(
            criterionId: required1.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )
        sut.testResults[required2.id] = RTSTestResult(
            criterionId: required2.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 70,
            unit: "%",
            passed: false
        )

        XCTAssertFalse(sut.allRequiredPassed)
    }

    func testAllRequiredPassed_WhenAllRequiredPassed_ReturnsTrue() {
        let required1 = createCriterion(isRequired: true)
        let required2 = createCriterion(isRequired: true)
        let optional = createCriterion(isRequired: false)
        sut.criteria = [required1, required2, optional]

        sut.testResults[required1.id] = RTSTestResult(
            criterionId: required1.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )
        sut.testResults[required2.id] = RTSTestResult(
            criterionId: required2.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 95,
            unit: "%",
            passed: true
        )
        // Optional not tested - should still pass

        XCTAssertTrue(sut.allRequiredPassed)
    }

    // MARK: - Helper Methods

    private func createCriterion(isRequired: Bool) -> RTSMilestoneCriterion {
        RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test Criterion",
            description: "Description",
            targetValue: 85,
            targetUnit: "%",
            isRequired: isRequired
        )
    }
}

// MARK: - Test Recording Tests

@MainActor
final class RTSTestingViewModelTestRecordingTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - evaluateTest Tests

    func testEvaluateTest_GreaterThanOrEqual_WhenValueMeetsTarget_ReturnsTrue() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Quad LSI",
            description: "Quadriceps strength",
            targetValue: 85,
            targetUnit: "%",
            comparisonOperator: .greaterThanOrEqual
        )

        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 85))
        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 90))
    }

    func testEvaluateTest_GreaterThanOrEqual_WhenValueBelowTarget_ReturnsFalse() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Quad LSI",
            description: "Quadriceps strength",
            targetValue: 85,
            targetUnit: "%",
            comparisonOperator: .greaterThanOrEqual
        )

        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 84))
        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 50))
    }

    func testEvaluateTest_LessThanOrEqual_WhenValueMeetsTarget_ReturnsTrue() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .pain,
            name: "Pain Level",
            description: "Pain during activity",
            targetValue: 2,
            targetUnit: "/10",
            comparisonOperator: .lessThanOrEqual
        )

        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 2))
        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 0))
        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 1))
    }

    func testEvaluateTest_LessThanOrEqual_WhenValueAboveTarget_ReturnsFalse() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .pain,
            name: "Pain Level",
            description: "Pain during activity",
            targetValue: 2,
            targetUnit: "/10",
            comparisonOperator: .lessThanOrEqual
        )

        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 3))
        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 5))
    }

    func testEvaluateTest_Equal_WhenValueMatchesTarget_ReturnsTrue() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .functional,
            name: "Single Leg Hops",
            description: "Equal hops",
            targetValue: 10,
            targetUnit: "reps",
            comparisonOperator: .equal
        )

        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 10))
    }

    func testEvaluateTest_Equal_WhenValueDoesNotMatchTarget_ReturnsFalse() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .functional,
            name: "Single Leg Hops",
            description: "Equal hops",
            targetValue: 10,
            targetUnit: "reps",
            comparisonOperator: .equal
        )

        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 9))
        XCTAssertFalse(sut.evaluateTest(criterion: criterion, value: 11))
    }

    func testEvaluateTest_WhenNoTargetValue_ReturnsTrue() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .psychological,
            name: "Confidence Assessment",
            description: "Subjective assessment",
            targetValue: nil,
            targetUnit: nil
        )

        XCTAssertTrue(sut.evaluateTest(criterion: criterion, value: 50))
    }

    // MARK: - prepareTest Tests

    func testPrepareTest_SetsSelectedCriterion() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )

        sut.testValue = "some value"
        sut.testNotes = "some notes"

        sut.prepareTest(for: criterion)

        XCTAssertEqual(sut.selectedCriterion?.id, criterion.id)
        XCTAssertEqual(sut.testValue, "")
        XCTAssertEqual(sut.testNotes, "")
    }
}

// MARK: - Readiness Assessment Tests

@MainActor
final class RTSTestingViewModelReadinessTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - calculatedOverallScore Tests

    func testCalculatedOverallScore_CalculatesWeightedAverage() {
        sut.physicalScore = 80
        sut.functionalScore = 80
        sut.psychologicalScore = 80

        // All equal = 80 overall
        XCTAssertEqual(sut.calculatedOverallScore, 80, accuracy: 0.01)
    }

    func testCalculatedOverallScore_PhysicalHas40PercentWeight() {
        sut.physicalScore = 100
        sut.functionalScore = 0
        sut.psychologicalScore = 0

        // 100 * 0.4 = 40
        XCTAssertEqual(sut.calculatedOverallScore, 40, accuracy: 0.01)
    }

    func testCalculatedOverallScore_FunctionalHas40PercentWeight() {
        sut.physicalScore = 0
        sut.functionalScore = 100
        sut.psychologicalScore = 0

        // 100 * 0.4 = 40
        XCTAssertEqual(sut.calculatedOverallScore, 40, accuracy: 0.01)
    }

    func testCalculatedOverallScore_PsychologicalHas20PercentWeight() {
        sut.physicalScore = 0
        sut.functionalScore = 0
        sut.psychologicalScore = 100

        // 100 * 0.2 = 20
        XCTAssertEqual(sut.calculatedOverallScore, 20, accuracy: 0.01)
    }

    func testCalculatedOverallScore_ComplexCalculation() {
        sut.physicalScore = 90   // 90 * 0.4 = 36
        sut.functionalScore = 85  // 85 * 0.4 = 34
        sut.psychologicalScore = 70 // 70 * 0.2 = 14
        // Total = 84

        XCTAssertEqual(sut.calculatedOverallScore, 84, accuracy: 0.01)
    }

    // MARK: - calculatedTrafficLight Tests

    func testCalculatedTrafficLight_WhenScoreAbove80_ReturnsGreen() {
        sut.physicalScore = 90
        sut.functionalScore = 90
        sut.psychologicalScore = 90

        XCTAssertEqual(sut.calculatedTrafficLight, .green)
    }

    func testCalculatedTrafficLight_WhenScoreBetween60And80_ReturnsYellow() {
        sut.physicalScore = 70
        sut.functionalScore = 70
        sut.psychologicalScore = 70

        XCTAssertEqual(sut.calculatedTrafficLight, .yellow)
    }

    func testCalculatedTrafficLight_WhenScoreBelow60_ReturnsRed() {
        sut.physicalScore = 50
        sut.functionalScore = 50
        sut.psychologicalScore = 50

        XCTAssertEqual(sut.calculatedTrafficLight, .red)
    }

    // MARK: - formattedOverallScore Tests

    func testFormattedOverallScore_ReturnsPercentageString() {
        sut.physicalScore = 80
        sut.functionalScore = 80
        sut.psychologicalScore = 80

        XCTAssertEqual(sut.formattedOverallScore, "80%")
    }

    // MARK: - isReadinessFormValid Tests

    func testIsReadinessFormValid_WhenAllScoresInRange_ReturnsTrue() {
        sut.physicalScore = 50
        sut.functionalScore = 50
        sut.psychologicalScore = 50

        XCTAssertTrue(sut.isReadinessFormValid)
    }

    func testIsReadinessFormValid_WhenScoresAtBoundaries_ReturnsTrue() {
        sut.physicalScore = 0
        sut.functionalScore = 100
        sut.psychologicalScore = 50

        XCTAssertTrue(sut.isReadinessFormValid)
    }

    func testIsReadinessFormValid_WhenPhysicalScoreNegative_ReturnsFalse() {
        sut.physicalScore = -1
        sut.functionalScore = 50
        sut.psychologicalScore = 50

        XCTAssertFalse(sut.isReadinessFormValid)
    }

    func testIsReadinessFormValid_WhenFunctionalScoreAbove100_ReturnsFalse() {
        sut.physicalScore = 50
        sut.functionalScore = 101
        sut.psychologicalScore = 50

        XCTAssertFalse(sut.isReadinessFormValid)
    }
}

// MARK: - Risk Factor Management Tests

@MainActor
final class RTSTestingViewModelRiskFactorTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAddRiskFactor_AddsToRiskFactors() {
        XCTAssertTrue(sut.riskFactors.isEmpty)

        sut.addRiskFactor(
            category: "Strength",
            name: "Quad weakness",
            severity: .moderate,
            notes: "LSI at 75%"
        )

        XCTAssertEqual(sut.riskFactors.count, 1)
        XCTAssertEqual(sut.riskFactors.first?.category, "Strength")
        XCTAssertEqual(sut.riskFactors.first?.name, "Quad weakness")
        XCTAssertEqual(sut.riskFactors.first?.severity, .moderate)
        XCTAssertEqual(sut.riskFactors.first?.notes, "LSI at 75%")
    }

    func testAddRiskFactor_MultipleFactors() {
        sut.addRiskFactor(category: "Strength", name: "Factor 1", severity: .low, notes: nil)
        sut.addRiskFactor(category: "Psychological", name: "Factor 2", severity: .high, notes: "Important")

        XCTAssertEqual(sut.riskFactors.count, 2)
    }

    func testRemoveRiskFactor_RemovesFromRiskFactors() {
        sut.addRiskFactor(category: "Strength", name: "Factor 1", severity: .low, notes: nil)
        sut.addRiskFactor(category: "Psychological", name: "Factor 2", severity: .high, notes: nil)

        let factorToRemove = sut.riskFactors[0]
        sut.removeRiskFactor(factorToRemove)

        XCTAssertEqual(sut.riskFactors.count, 1)
        XCTAssertEqual(sut.riskFactors.first?.name, "Factor 2")
    }

    func testClearRiskFactors_RemovesAll() {
        sut.addRiskFactor(category: "Strength", name: "Factor 1", severity: .low, notes: nil)
        sut.addRiskFactor(category: "Psychological", name: "Factor 2", severity: .high, notes: nil)

        sut.clearRiskFactors()

        XCTAssertTrue(sut.riskFactors.isEmpty)
    }

    // MARK: - Risk Factor Counts Tests

    func testHighRiskCount_CountsHighSeverityOnly() {
        sut.addRiskFactor(category: "A", name: "High 1", severity: .high, notes: nil)
        sut.addRiskFactor(category: "B", name: "High 2", severity: .high, notes: nil)
        sut.addRiskFactor(category: "C", name: "Moderate", severity: .moderate, notes: nil)
        sut.addRiskFactor(category: "D", name: "Low", severity: .low, notes: nil)

        XCTAssertEqual(sut.highRiskCount, 2)
    }

    func testModerateRiskCount_CountsModerateSeverityOnly() {
        sut.addRiskFactor(category: "A", name: "High", severity: .high, notes: nil)
        sut.addRiskFactor(category: "B", name: "Moderate 1", severity: .moderate, notes: nil)
        sut.addRiskFactor(category: "C", name: "Moderate 2", severity: .moderate, notes: nil)
        sut.addRiskFactor(category: "D", name: "Low", severity: .low, notes: nil)

        XCTAssertEqual(sut.moderateRiskCount, 2)
    }

    func testHasHighRisk_WhenHighRiskPresent_ReturnsTrue() {
        sut.addRiskFactor(category: "A", name: "High Risk", severity: .high, notes: nil)

        XCTAssertTrue(sut.hasHighRisk)
    }

    func testHasHighRisk_WhenNoHighRisk_ReturnsFalse() {
        sut.addRiskFactor(category: "A", name: "Moderate", severity: .moderate, notes: nil)
        sut.addRiskFactor(category: "B", name: "Low", severity: .low, notes: nil)

        XCTAssertFalse(sut.hasHighRisk)
    }

    func testHasHighRisk_WhenEmpty_ReturnsFalse() {
        XCTAssertFalse(sut.hasHighRisk)
    }
}

// MARK: - Phase Advancement Tests

@MainActor
final class RTSTestingViewModelAdvancementTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - canAdvancePhase Tests

    func testCanAdvancePhase_WhenNoCriteria_ReturnsTrue() {
        let result = sut.canAdvancePhase()

        XCTAssertTrue(result.canAdvance)
    }

    func testCanAdvancePhase_WhenRequiredNotPassed_ReturnsFalse() {
        let requiredCriterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Required Test",
            description: "Must pass",
            targetValue: 85,
            targetUnit: "%",
            isRequired: true
        )
        sut.criteria = [requiredCriterion]

        let result = sut.canAdvancePhase()

        XCTAssertFalse(result.canAdvance)
        XCTAssertTrue(result.reason.contains("Required criteria not met"))
    }

    func testCanAdvancePhase_WhenRequiredFailed_ReturnsFalse() {
        let requiredCriterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Required Test",
            description: "Must pass",
            targetValue: 85,
            targetUnit: "%",
            isRequired: true
        )
        sut.criteria = [requiredCriterion]
        sut.testResults[requiredCriterion.id] = RTSTestResult(
            criterionId: requiredCriterion.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 70,
            unit: "%",
            passed: false
        )

        let result = sut.canAdvancePhase()

        XCTAssertFalse(result.canAdvance)
    }

    func testCanAdvancePhase_WhenHighRiskPresent_ReturnsFalse() {
        // All required passed
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Required Test",
            description: "Must pass",
            isRequired: true
        )
        sut.criteria = [criterion]
        sut.testResults[criterion.id] = RTSTestResult(
            criterionId: criterion.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )

        // But high risk factor present
        sut.addRiskFactor(category: "Pain", name: "High Pain", severity: .high, notes: nil)

        let result = sut.canAdvancePhase()

        XCTAssertFalse(result.canAdvance)
        XCTAssertTrue(result.reason.contains("High severity risk factors"))
    }

    func testCanAdvancePhase_WhenAllConditionsMet_ReturnsTrue() {
        let required1 = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Required 1",
            description: "Must pass",
            isRequired: true
        )
        let required2 = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .functional,
            name: "Required 2",
            description: "Must pass",
            isRequired: true
        )
        let optional = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .psychological,
            name: "Optional",
            description: "Optional test",
            isRequired: false
        )

        sut.criteria = [required1, required2, optional]

        // Pass all required
        sut.testResults[required1.id] = RTSTestResult(
            criterionId: required1.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )
        sut.testResults[required2.id] = RTSTestResult(
            criterionId: required2.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 95,
            unit: "%",
            passed: true
        )

        // Add only low/moderate risk factors
        sut.addRiskFactor(category: "Strength", name: "Minor", severity: .low, notes: nil)

        let result = sut.canAdvancePhase()

        XCTAssertTrue(result.canAdvance)
        XCTAssertTrue(result.reason.contains("All required criteria met"))
    }
}

// MARK: - Criteria Summary Tests

@MainActor
final class RTSTestingViewModelCriteriaSummaryTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGetCriteriaSummary_WhenEmpty_ReturnsZeroCounts() {
        let summary = sut.getCriteriaSummary()

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
        XCTAssertEqual(summary.requiredPassed, 0)
    }

    func testGetCriteriaSummary_CalculatesCorrectCounts() {
        let required1 = createCriterion(isRequired: true)
        let required2 = createCriterion(isRequired: true)
        let optional1 = createCriterion(isRequired: false)
        let optional2 = createCriterion(isRequired: false)

        sut.criteria = [required1, required2, optional1, optional2]

        // Pass one required, one optional
        sut.testResults[required1.id] = createTestResult(criterionId: required1.id, passed: true)
        sut.testResults[optional1.id] = createTestResult(criterionId: optional1.id, passed: true)

        let summary = sut.getCriteriaSummary()

        XCTAssertEqual(summary.totalCriteria, 4)
        XCTAssertEqual(summary.passedCriteria, 2)
        XCTAssertEqual(summary.requiredTotal, 2)
        XCTAssertEqual(summary.requiredPassed, 1)
    }

    func testGetCriteriaSummary_IncludesNotesForPassedCriteria() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Quad LSI",
            description: "Test",
            isRequired: true
        )
        sut.criteria = [criterion]
        sut.testResults[criterion.id] = RTSTestResult(
            criterionId: criterion.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 87.5,
            unit: "%",
            passed: true
        )

        let summary = sut.getCriteriaSummary()

        XCTAssertNotNil(summary.notes)
        XCTAssertTrue(summary.notes?.contains("Quad LSI") ?? false)
    }

    // MARK: - Helper Methods

    private func createCriterion(isRequired: Bool) -> RTSMilestoneCriterion {
        RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test Criterion",
            description: "Description",
            isRequired: isRequired
        )
    }

    private func createTestResult(criterionId: UUID, passed: Bool) -> RTSTestResult {
        RTSTestResult(
            criterionId: criterionId,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: passed ? 90 : 70,
            unit: "%",
            passed: passed
        )
    }
}

// MARK: - Status Helper Tests

@MainActor
final class RTSTestingViewModelStatusHelperTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGetStatusForCriterion_WhenNotTested_ReturnsGray() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )
        sut.criteria = [criterion]

        let status = sut.getStatusForCriterion(criterion)

        XCTAssertEqual(status.text, "Not Tested")
        XCTAssertEqual(status.color, .gray)
    }

    func testGetStatusForCriterion_WhenPassed_ReturnsGreen() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )
        sut.criteria = [criterion]
        sut.testResults[criterion.id] = RTSTestResult(
            criterionId: criterion.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )

        let status = sut.getStatusForCriterion(criterion)

        XCTAssertEqual(status.text, "Passed")
        XCTAssertEqual(status.color, .green)
    }

    func testGetStatusForCriterion_WhenFailed_ReturnsRed() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )
        sut.criteria = [criterion]
        sut.testResults[criterion.id] = RTSTestResult(
            criterionId: criterion.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 70,
            unit: "%",
            passed: false
        )

        let status = sut.getStatusForCriterion(criterion)

        XCTAssertEqual(status.text, "Not Passed")
        XCTAssertEqual(status.color, .red)
    }
}

// MARK: - Reset Tests

@MainActor
final class RTSTestingViewModelResetTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testReset_ClearsAllState() {
        // Set up state
        sut.criteria = [RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )]
        sut.testResults[UUID()] = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )
        sut.selectedCriterion = sut.criteria.first
        sut.testValue = "85"
        sut.testNotes = "Some notes"
        sut.physicalScore = 80
        sut.functionalScore = 75
        sut.psychologicalScore = 70
        sut.addRiskFactor(category: "Test", name: "Test", severity: .high, notes: nil)
        sut.readinessNotes = "Notes"
        sut.errorMessage = "Error"
        sut.successMessage = "Success"

        // Reset
        sut.reset()

        // Verify
        XCTAssertTrue(sut.criteria.isEmpty)
        XCTAssertTrue(sut.testResults.isEmpty)
        XCTAssertTrue(sut.advancements.isEmpty)
        XCTAssertNil(sut.selectedCriterion)
        XCTAssertEqual(sut.testValue, "")
        XCTAssertEqual(sut.testNotes, "")
        XCTAssertEqual(sut.physicalScore, 0)
        XCTAssertEqual(sut.functionalScore, 0)
        XCTAssertEqual(sut.psychologicalScore, 0)
        XCTAssertTrue(sut.riskFactors.isEmpty)
        XCTAssertEqual(sut.readinessNotes, "")
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    func testResetReadinessForm_ClearsOnlyReadinessState() {
        // Set up test recording state
        sut.selectedCriterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )
        sut.testValue = "85"
        sut.testNotes = "Notes"

        // Set up readiness state
        sut.physicalScore = 80
        sut.functionalScore = 75
        sut.psychologicalScore = 70
        sut.addRiskFactor(category: "Test", name: "Test", severity: .high, notes: nil)
        sut.readinessNotes = "Notes"

        // Reset readiness form only
        sut.resetReadinessForm()

        // Verify readiness cleared
        XCTAssertEqual(sut.physicalScore, 0)
        XCTAssertEqual(sut.functionalScore, 0)
        XCTAssertEqual(sut.psychologicalScore, 0)
        XCTAssertTrue(sut.riskFactors.isEmpty)
        XCTAssertEqual(sut.readinessNotes, "")

        // Verify test recording state preserved
        XCTAssertNotNil(sut.selectedCriterion)
        XCTAssertEqual(sut.testValue, "85")
        XCTAssertEqual(sut.testNotes, "Notes")
    }

    func testClearMessages_ClearsErrorAndSuccess() {
        sut.errorMessage = "Error"
        sut.successMessage = "Success"

        sut.clearMessages()

        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }
}

// MARK: - Criteria by Category Tests

@MainActor
final class RTSTestingViewModelCategoryTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCriteriaByCategory_GroupsCorrectly() {
        let strength1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "Strength 1", description: "")
        let strength2 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "Strength 2", description: "")
        let functional = RTSMilestoneCriterion(phaseId: UUID(), category: .functional, name: "Functional", description: "")
        let pain = RTSMilestoneCriterion(phaseId: UUID(), category: .pain, name: "Pain", description: "")

        sut.criteria = [strength1, functional, strength2, pain]

        let grouped = sut.criteriaByCategory

        XCTAssertEqual(grouped[.strength]?.count, 2)
        XCTAssertEqual(grouped[.functional]?.count, 1)
        XCTAssertEqual(grouped[.pain]?.count, 1)
        XCTAssertNil(grouped[.psychological])
        XCTAssertNil(grouped[.rom])
    }

    func testActiveCategories_ReturnsSortedCategories() {
        let strength = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "Strength", description: "")
        let pain = RTSMilestoneCriterion(phaseId: UUID(), category: .pain, name: "Pain", description: "")

        sut.criteria = [strength, pain]

        let categories = sut.activeCategories

        XCTAssertEqual(categories.count, 2)
        // Categories should be sorted by rawValue
        XCTAssertTrue(categories.contains(.strength))
        XCTAssertTrue(categories.contains(.pain))
    }

    func testActiveCategories_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.activeCategories.isEmpty)
    }
}

// MARK: - Count Properties Tests

@MainActor
final class RTSTestingViewModelCountTests: XCTestCase {

    var sut: RTSTestingViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSTestingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testTotalCount_ReturnsCorrectCount() {
        sut.criteria = [
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "1", description: ""),
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "2", description: ""),
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "3", description: "")
        ]

        XCTAssertEqual(sut.totalCount, 3)
    }

    func testPassedCount_ReturnsCorrectCount() {
        let c1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "1", description: "")
        let c2 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "2", description: "")

        sut.criteria = [c1, c2]
        sut.testResults[c1.id] = RTSTestResult(
            criterionId: c1.id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )

        XCTAssertEqual(sut.passedCount, 1)
    }

    func testRequiredCount_ReturnsCorrectCount() {
        sut.criteria = [
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "1", description: "", isRequired: true),
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "2", description: "", isRequired: true),
            RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "3", description: "", isRequired: false)
        ]

        XCTAssertEqual(sut.requiredCount, 2)
    }

    func testRequiredPassedCount_ReturnsCorrectCount() {
        let required1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "R1", description: "", isRequired: true)
        let required2 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "R2", description: "", isRequired: true)
        let optional = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "O1", description: "", isRequired: false)

        sut.criteria = [required1, required2, optional]

        // Pass one required and the optional
        sut.testResults[required1.id] = RTSTestResult(criterionId: required1.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)
        sut.testResults[optional.id] = RTSTestResult(criterionId: optional.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)

        XCTAssertEqual(sut.requiredPassedCount, 1)
    }

    func testCriteriaProgress_CalculatesCorrectly() {
        let c1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "1", description: "")
        let c2 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "2", description: "")
        let c3 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "3", description: "")
        let c4 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "4", description: "")

        sut.criteria = [c1, c2, c3, c4]

        // Pass 2 of 4
        sut.testResults[c1.id] = RTSTestResult(criterionId: c1.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)
        sut.testResults[c2.id] = RTSTestResult(criterionId: c2.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)

        XCTAssertEqual(sut.criteriaProgress, 0.5, accuracy: 0.001)
    }

    func testRequiredCriteriaProgress_CalculatesCorrectly() {
        let r1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "R1", description: "", isRequired: true)
        let r2 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "R2", description: "", isRequired: true)
        let r3 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "R3", description: "", isRequired: true)
        let o1 = RTSMilestoneCriterion(phaseId: UUID(), category: .strength, name: "O1", description: "", isRequired: false)

        sut.criteria = [r1, r2, r3, o1]

        // Pass 2 of 3 required
        sut.testResults[r1.id] = RTSTestResult(criterionId: r1.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)
        sut.testResults[r2.id] = RTSTestResult(criterionId: r2.id, protocolId: UUID(), recordedBy: UUID(), value: 90, unit: "%", passed: true)

        XCTAssertEqual(sut.requiredCriteriaProgress, 2.0/3.0, accuracy: 0.001)
    }
}
