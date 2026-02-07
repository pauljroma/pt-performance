//
//  IntakeAssessmentViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for IntakeAssessmentViewModel
//  Tests form state management, ROM measurements, pain assessment,
//  functional tests, validation, and save/submit/sign workflow
//

import XCTest
@testable import PTPerformance

@MainActor
final class IntakeAssessmentViewModelTests: XCTestCase {

    var sut: IntakeAssessmentViewModel!
    var mockService: MockClinicalAssessmentService!

    override func setUp() {
        super.setUp()
        mockService = MockClinicalAssessmentService()
        sut = IntakeAssessmentViewModel(assessmentService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_PatientIdIsNil() {
        XCTAssertNil(sut.patientId, "patientId should be nil initially")
    }

    func testInitialState_TherapistIdIsNil() {
        XCTAssertNil(sut.therapistId, "therapistId should be nil initially")
    }

    func testInitialState_ChiefComplaintIsEmpty() {
        XCTAssertTrue(sut.chiefComplaint.isEmpty, "chiefComplaint should be empty initially")
    }

    func testInitialState_HistoryOfPresentIllnessIsEmpty() {
        XCTAssertTrue(sut.historyOfPresentIllness.isEmpty, "historyOfPresentIllness should be empty initially")
    }

    func testInitialState_PastMedicalHistoryIsEmpty() {
        XCTAssertTrue(sut.pastMedicalHistory.isEmpty, "pastMedicalHistory should be empty initially")
    }

    func testInitialState_FunctionalGoalsIsEmpty() {
        XCTAssertTrue(sut.functionalGoals.isEmpty, "functionalGoals should be empty initially")
    }

    func testInitialState_PainAtRestIsZero() {
        XCTAssertEqual(sut.painAtRest, 0, "painAtRest should be 0 initially")
    }

    func testInitialState_PainWithActivityIsFive() {
        XCTAssertEqual(sut.painWithActivity, 5, "painWithActivity should be 5 initially")
    }

    func testInitialState_PainWorstIsSeven() {
        XCTAssertEqual(sut.painWorst, 7, "painWorst should be 7 initially")
    }

    func testInitialState_PainLocationsIsEmpty() {
        XCTAssertTrue(sut.painLocations.isEmpty, "painLocations should be empty initially")
    }

    func testInitialState_ROMMeasurementsIsEmpty() {
        XCTAssertTrue(sut.romMeasurements.isEmpty, "romMeasurements should be empty initially")
    }

    func testInitialState_FunctionalTestsIsEmpty() {
        XCTAssertTrue(sut.functionalTests.isEmpty, "functionalTests should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_IsSavingIsFalse() {
        XCTAssertFalse(sut.isSaving, "isSaving should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SuccessMessageIsNil() {
        XCTAssertNil(sut.successMessage, "successMessage should be nil initially")
    }

    func testInitialState_ShowValidationErrorsIsFalse() {
        XCTAssertFalse(sut.showValidationErrors, "showValidationErrors should be false initially")
    }

    func testInitialState_CurrentAssessmentIsNil() {
        XCTAssertNil(sut.currentAssessment, "currentAssessment should be nil initially")
    }

    func testInitialState_SelectedJointIsShoulder() {
        XCTAssertEqual(sut.selectedJoint, .shoulder, "selectedJoint should be .shoulder initially")
    }

    func testInitialState_SelectedSideIsRight() {
        XCTAssertEqual(sut.selectedSide, .right, "selectedSide should be .right initially")
    }

    // MARK: - Section Status Initial State Tests

    func testInitialState_SectionStatus_SubjectiveCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.subjectiveComplete, "subjectiveComplete should be false initially")
    }

    func testInitialState_SectionStatus_ObjectiveCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.objectiveComplete, "objectiveComplete should be false initially")
    }

    func testInitialState_SectionStatus_PainCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.painComplete, "painComplete should be false initially")
    }

    func testInitialState_SectionStatus_ROMCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.romComplete, "romComplete should be false initially")
    }

    func testInitialState_SectionStatus_FunctionalTestsCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.functionalTestsComplete, "functionalTestsComplete should be false initially")
    }

    func testInitialState_SectionStatus_AssessmentCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.assessmentComplete, "assessmentComplete should be false initially")
    }

    func testInitialState_SectionStatus_PlanCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.planComplete, "planComplete should be false initially")
    }

    func testInitialState_SectionStatus_AllRequiredCompleteIsFalse() {
        XCTAssertFalse(sut.sectionStatus.allRequiredComplete, "allRequiredComplete should be false initially")
    }

    func testInitialState_SectionStatus_CompletionPercentageIsZero() {
        XCTAssertEqual(sut.sectionStatus.completionPercentage, 0, accuracy: 0.01, "completionPercentage should be 0 initially")
    }

    // MARK: - Form State Management Tests

    func testInitializeNewAssessment_SetsPatientAndTherapistIds() {
        let patientId = UUID()
        let therapistId = UUID()

        sut.initializeNewAssessment(patientId: patientId, therapistId: therapistId)

        XCTAssertEqual(sut.patientId, patientId, "patientId should be set")
        XCTAssertEqual(sut.therapistId, therapistId, "therapistId should be set")
    }

    func testInitializeNewAssessment_ResetsForm() {
        sut.chiefComplaint = "Test complaint"
        sut.painAtRest = 5

        sut.initializeNewAssessment(patientId: UUID(), therapistId: UUID())

        XCTAssertTrue(sut.chiefComplaint.isEmpty, "chiefComplaint should be reset")
        XCTAssertEqual(sut.painAtRest, 0, "painAtRest should be reset")
    }

    func testResetForm_ClearsAllFields() {
        sut.patientId = UUID()
        sut.chiefComplaint = "Test complaint"
        sut.historyOfPresentIllness = "Test history"
        sut.painAtRest = 5
        sut.painLocations = ["Shoulder"]
        sut.romMeasurements = [createMockROMeasurement()]
        sut.functionalTests = [createMockFunctionalTest()]
        sut.objectiveFindings = "Test findings"
        sut.assessmentSummary = "Test summary"
        sut.treatmentPlan = "Test plan"
        sut.errorMessage = "Test error"
        sut.successMessage = "Test success"

        sut.resetForm()

        XCTAssertTrue(sut.chiefComplaint.isEmpty)
        XCTAssertTrue(sut.historyOfPresentIllness.isEmpty)
        XCTAssertEqual(sut.painAtRest, 0)
        XCTAssertTrue(sut.painLocations.isEmpty)
        XCTAssertTrue(sut.romMeasurements.isEmpty)
        XCTAssertTrue(sut.functionalTests.isEmpty)
        XCTAssertTrue(sut.objectiveFindings.isEmpty)
        XCTAssertTrue(sut.assessmentSummary.isEmpty)
        XCTAssertTrue(sut.treatmentPlan.isEmpty)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    func testLoadAssessment_PopulatesFormFields() {
        let assessment = createMockClinicalAssessment()

        sut.loadAssessment(assessment)

        XCTAssertEqual(sut.currentAssessment?.id, assessment.id)
        XCTAssertEqual(sut.patientId, assessment.patientId)
        XCTAssertEqual(sut.therapistId, assessment.therapistId)
        XCTAssertEqual(sut.chiefComplaint, assessment.chiefComplaint)
        XCTAssertEqual(sut.painAtRest, assessment.painAtRest)
        XCTAssertEqual(sut.painWithActivity, assessment.painWithActivity)
        XCTAssertEqual(sut.painWorst, assessment.painWorst)
    }

    // MARK: - Section Completion Tracking Tests

    func testSectionStatus_SubjectiveComplete_WhenComplaintAndHistoryFilled() async {
        sut.chiefComplaint = "Right shoulder pain"
        sut.historyOfPresentIllness = "Gradual onset over 3 weeks"

        // Wait for Combine to process the change
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.subjectiveComplete, "subjectiveComplete should be true when complaint and history are filled")
    }

    func testSectionStatus_ObjectiveComplete_WhenFindingsFilled() async {
        sut.objectiveFindings = "Decreased ROM in shoulder flexion"

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.objectiveComplete, "objectiveComplete should be true when findings are filled")
    }

    func testSectionStatus_PainComplete_WhenLocationsAdded() async {
        sut.painLocations = ["Right shoulder"]

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.painComplete, "painComplete should be true when locations are added")
    }

    func testSectionStatus_ROMComplete_WhenMeasurementsAdded() async {
        sut.romMeasurements = [createMockROMeasurement()]

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.romComplete, "romComplete should be true when measurements are added")
    }

    func testSectionStatus_FunctionalTestsComplete_WhenTestsAdded() async {
        sut.functionalTests = [createMockFunctionalTest()]

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.functionalTestsComplete, "functionalTestsComplete should be true when tests are added")
    }

    func testSectionStatus_AssessmentComplete_WhenSummaryFilled() async {
        sut.assessmentSummary = "Right shoulder impingement"

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.assessmentComplete, "assessmentComplete should be true when summary is filled")
    }

    func testSectionStatus_PlanComplete_WhenPlanFilled() async {
        sut.treatmentPlan = "Manual therapy 2x/week for 6 weeks"

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.planComplete, "planComplete should be true when plan is filled")
    }

    func testSectionStatus_AllRequiredComplete_WhenAllFilled() async {
        sut.chiefComplaint = "Right shoulder pain"
        sut.historyOfPresentIllness = "Gradual onset"
        sut.objectiveFindings = "Decreased ROM"
        sut.assessmentSummary = "Shoulder impingement"
        sut.treatmentPlan = "Physical therapy"

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.sectionStatus.allRequiredComplete, "allRequiredComplete should be true when all required sections are complete")
    }

    func testSectionStatus_CompletionPercentage_CalculatesCorrectly() async {
        // Fill 3 of 7 sections
        sut.chiefComplaint = "Pain"
        sut.historyOfPresentIllness = "History"
        sut.objectiveFindings = "Findings"
        sut.assessmentSummary = "Summary"

        try? await Task.sleep(nanoseconds: 100_000_000)

        // subjective + objective + assessment = 3/7 sections
        let expectedPercentage = (3.0 / 7.0) * 100.0
        XCTAssertEqual(sut.sectionStatus.completionPercentage, expectedPercentage, accuracy: 0.1)
    }

    // MARK: - ROM Measurement Management Tests

    func testAddROMMeasurement_AppendsToList() {
        XCTAssertTrue(sut.romMeasurements.isEmpty)

        sut.addROMMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            side: .right,
            painWithMovement: true
        )

        XCTAssertEqual(sut.romMeasurements.count, 1)
        XCTAssertEqual(sut.romMeasurements.first?.joint, "shoulder")
        XCTAssertEqual(sut.romMeasurements.first?.movement, "flexion")
        XCTAssertEqual(sut.romMeasurements.first?.degrees, 140)
        XCTAssertEqual(sut.romMeasurements.first?.side, .right)
        XCTAssertEqual(sut.romMeasurements.first?.painWithMovement, true)
    }

    func testAddROMMeasurement_WithUnknownJoint_SetsError() {
        sut.addROMMeasurement(
            joint: "unknown_joint",
            movement: "unknown_movement",
            degrees: 90,
            side: .left
        )

        XCTAssertNotNil(sut.romError, "romError should be set for unknown joint/movement")
        XCTAssertTrue(sut.romMeasurements.isEmpty, "measurement should not be added for unknown joint")
    }

    func testAddROMMeasurement_WithValidJoint_ClearsError() {
        sut.romError = "Previous error"

        sut.addROMMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            side: .right
        )

        XCTAssertNil(sut.romError, "romError should be cleared on successful add")
    }

    func testUpdateROMMeasurement_UpdatesExistingMeasurement() {
        let originalMeasurement = createMockROMeasurement()
        sut.romMeasurements = [originalMeasurement]

        var updatedMeasurement = originalMeasurement
        updatedMeasurement.degrees = 160

        sut.updateROMMeasurement(updatedMeasurement)

        XCTAssertEqual(sut.romMeasurements.first?.degrees, 160, "degrees should be updated")
    }

    func testUpdateROMMeasurement_DoesNothingForNonexistentId() {
        let measurement = createMockROMeasurement()
        sut.romMeasurements = [measurement]

        var nonexistentMeasurement = createMockROMeasurement()
        nonexistentMeasurement.degrees = 999

        sut.updateROMMeasurement(nonexistentMeasurement)

        XCTAssertEqual(sut.romMeasurements.first?.degrees, measurement.degrees, "original should be unchanged")
    }

    func testRemoveROMMeasurement_RemovesFromList() {
        let measurement1 = createMockROMeasurement()
        let measurement2 = createMockROMeasurement()
        sut.romMeasurements = [measurement1, measurement2]

        sut.removeROMMeasurement(measurement1)

        XCTAssertEqual(sut.romMeasurements.count, 1)
        XCTAssertEqual(sut.romMeasurements.first?.id, measurement2.id)
    }

    // MARK: - Pain Assessment Tests

    func testPainScores_CanBeSet() {
        sut.painAtRest = 3
        sut.painWithActivity = 6
        sut.painWorst = 9

        XCTAssertEqual(sut.painAtRest, 3)
        XCTAssertEqual(sut.painWithActivity, 6)
        XCTAssertEqual(sut.painWorst, 9)
    }

    func testAveragePainScore_CalculatesCorrectly() {
        sut.painAtRest = 2
        sut.painWithActivity = 5
        sut.painWorst = 8

        XCTAssertEqual(sut.averagePainScore, 5.0, accuracy: 0.01, "average should be (2+5+8)/3 = 5")
    }

    func testIsPainConcerning_WhenWorstPainHighOrEqualToSeven() {
        sut.painWorst = 7
        XCTAssertTrue(sut.isPainConcerning, "should be concerning when worst pain >= 7")

        sut.painWorst = 8
        XCTAssertTrue(sut.isPainConcerning, "should be concerning when worst pain > 7")
    }

    func testIsPainConcerning_WhenActivityPainHighOrEqualToSix() {
        sut.painWorst = 5
        sut.painWithActivity = 6
        XCTAssertTrue(sut.isPainConcerning, "should be concerning when activity pain >= 6")
    }

    func testIsPainConcerning_WhenPainLevelsLow() {
        sut.painAtRest = 2
        sut.painWithActivity = 4
        sut.painWorst = 5
        XCTAssertFalse(sut.isPainConcerning, "should not be concerning when pain levels are low")
    }

    func testAddPainLocation_AppendsToList() {
        XCTAssertTrue(sut.painLocations.isEmpty)

        sut.newPainLocation = "Right shoulder"
        sut.addPainLocation()

        XCTAssertEqual(sut.painLocations.count, 1)
        XCTAssertEqual(sut.painLocations.first, "Right shoulder")
        XCTAssertTrue(sut.newPainLocation.isEmpty, "newPainLocation should be cleared")
    }

    func testAddPainLocation_TrimsWhitespace() {
        sut.newPainLocation = "  Right shoulder  "
        sut.addPainLocation()

        XCTAssertEqual(sut.painLocations.first, "Right shoulder")
    }

    func testAddPainLocation_DoesNotAddEmpty() {
        sut.newPainLocation = "   "
        sut.addPainLocation()

        XCTAssertTrue(sut.painLocations.isEmpty)
    }

    func testRemovePainLocation_RemovesAtIndex() {
        sut.painLocations = ["Shoulder", "Back", "Neck"]

        sut.removePainLocation(at: 1)

        XCTAssertEqual(sut.painLocations, ["Shoulder", "Neck"])
    }

    func testRemovePainLocation_DoesNothingForInvalidIndex() {
        sut.painLocations = ["Shoulder"]

        sut.removePainLocation(at: 5)

        XCTAssertEqual(sut.painLocations.count, 1)
    }

    // MARK: - Functional Test Management Tests

    func testAddFunctionalTest_AppendsToList() {
        XCTAssertTrue(sut.functionalTests.isEmpty)

        sut.addFunctionalTest(
            testName: "Hawkins-Kennedy",
            result: "Positive",
            interpretation: "Indicates possible impingement"
        )

        XCTAssertEqual(sut.functionalTests.count, 1)
        XCTAssertEqual(sut.functionalTests.first?.testName, "Hawkins-Kennedy")
        XCTAssertEqual(sut.functionalTests.first?.result, "Positive")
    }

    func testUpdateFunctionalTest_UpdatesExistingTest() {
        let originalTest = createMockFunctionalTest()
        sut.functionalTests = [originalTest]

        var updatedTest = originalTest
        updatedTest.result = "Negative"

        sut.updateFunctionalTest(updatedTest)

        XCTAssertEqual(sut.functionalTests.first?.result, "Negative")
    }

    func testRemoveFunctionalTest_RemovesFromList() {
        let test1 = createMockFunctionalTest()
        let test2 = createMockFunctionalTest()
        sut.functionalTests = [test1, test2]

        sut.removeFunctionalTest(test1)

        XCTAssertEqual(sut.functionalTests.count, 1)
        XCTAssertEqual(sut.functionalTests.first?.id, test2.id)
    }

    func testAbnormalTestsCount_CountsAbnormalTests() {
        let normalTest = FunctionalTest(testName: "Test1", result: "Negative", interpretation: "Normal")
        let abnormalTest = FunctionalTest(testName: "Test2", result: "Positive", interpretation: "Abnormal finding")

        sut.functionalTests = [normalTest, abnormalTest]

        XCTAssertEqual(sut.abnormalTestsCount, 1)
    }

    // MARK: - Goal Management Tests

    func testAddGoal_AppendsToList() {
        XCTAssertTrue(sut.functionalGoals.isEmpty)

        sut.newGoal = "Return to overhead sports"
        sut.addGoal()

        XCTAssertEqual(sut.functionalGoals.count, 1)
        XCTAssertEqual(sut.functionalGoals.first, "Return to overhead sports")
        XCTAssertTrue(sut.newGoal.isEmpty, "newGoal should be cleared")
    }

    func testAddGoal_TrimsWhitespace() {
        sut.newGoal = "  Sleep without pain  "
        sut.addGoal()

        XCTAssertEqual(sut.functionalGoals.first, "Sleep without pain")
    }

    func testAddGoal_DoesNotAddEmpty() {
        sut.newGoal = "   "
        sut.addGoal()

        XCTAssertTrue(sut.functionalGoals.isEmpty)
    }

    func testRemoveGoal_RemovesAtIndex() {
        sut.functionalGoals = ["Goal 1", "Goal 2", "Goal 3"]

        sut.removeGoal(at: 1)

        XCTAssertEqual(sut.functionalGoals, ["Goal 1", "Goal 3"])
    }

    // MARK: - Validation Logic Tests

    func testCanSaveDraft_WhenPatientAndTherapistSet() {
        sut.patientId = UUID()
        sut.therapistId = UUID()
        sut.isSaving = false

        XCTAssertTrue(sut.canSaveDraft, "canSaveDraft should be true when IDs are set and not saving")
    }

    func testCanSaveDraft_FalseWhenPatientIdNil() {
        sut.patientId = nil
        sut.therapistId = UUID()

        XCTAssertFalse(sut.canSaveDraft, "canSaveDraft should be false when patientId is nil")
    }

    func testCanSaveDraft_FalseWhenTherapistIdNil() {
        sut.patientId = UUID()
        sut.therapistId = nil

        XCTAssertFalse(sut.canSaveDraft, "canSaveDraft should be false when therapistId is nil")
    }

    func testCanSaveDraft_FalseWhenSaving() {
        sut.patientId = UUID()
        sut.therapistId = UUID()
        sut.isSaving = true

        XCTAssertFalse(sut.canSaveDraft, "canSaveDraft should be false when saving")
    }

    func testCanSubmit_WhenAllRequiredComplete() async {
        sut.patientId = UUID()
        sut.therapistId = UUID()
        sut.chiefComplaint = "Pain"
        sut.historyOfPresentIllness = "History"
        sut.objectiveFindings = "Findings"
        sut.assessmentSummary = "Summary"
        sut.treatmentPlan = "Plan"

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.canSubmit, "canSubmit should be true when all required sections are complete")
    }

    func testCanSubmit_FalseWhenMissingRequired() {
        sut.patientId = UUID()
        sut.therapistId = UUID()
        sut.chiefComplaint = "Pain"
        // Missing other required fields

        XCTAssertFalse(sut.canSubmit, "canSubmit should be false when missing required sections")
    }

    func testCanSign_WhenAssessmentCompleteAndReady() {
        let assessment = createMockClinicalAssessment(status: .complete)
        sut.currentAssessment = assessment

        XCTAssertTrue(sut.canSign, "canSign should be true when assessment is complete and ready")
    }

    func testCanSign_FalseWhenAssessmentIsNil() {
        sut.currentAssessment = nil

        XCTAssertFalse(sut.canSign, "canSign should be false when no assessment exists")
    }

    func testCanSign_FalseWhenAssessmentIsDraft() {
        let assessment = createMockClinicalAssessment(status: .draft)
        sut.currentAssessment = assessment

        XCTAssertFalse(sut.canSign, "canSign should be false when assessment is draft")
    }

    // MARK: - Computed Properties Tests

    func testROMLimitationsCount_CountsLimitedMeasurements() {
        let limitedMeasurement = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 100,
            normalRange: 150...180,
            side: .right
        )
        let normalMeasurement = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 145,
            normalRange: 130...150,
            side: .left
        )

        sut.romMeasurements = [limitedMeasurement, normalMeasurement]

        XCTAssertEqual(sut.romLimitationsCount, 1)
    }

    func testFormattedDate_ReturnsFormattedString() {
        sut.assessmentDate = Date()

        XCTAssertFalse(sut.formattedDate.isEmpty, "formattedDate should return a non-empty string")
    }

    func testGetAvailableMovements_ReturnsMovementsForJoint() {
        sut.selectedJoint = .shoulder

        let movements = sut.getAvailableMovements()

        XCTAssertTrue(movements.contains(.flexion))
        XCTAssertTrue(movements.contains(.extension))
        XCTAssertTrue(movements.contains(.abduction))
        XCTAssertTrue(movements.contains(.externalRotation))
    }

    // MARK: - Save/Submit/Sign Workflow Tests

    func testCreateDraft_CallsService() async {
        sut.patientId = UUID()
        sut.therapistId = UUID()

        mockService.createAssessmentResult = createMockClinicalAssessment()

        await sut.createDraft()

        XCTAssertTrue(mockService.createAssessmentCalled)
    }

    func testCreateDraft_SetsErrorWhenNoPatientId() async {
        sut.patientId = nil
        sut.therapistId = UUID()

        await sut.createDraft()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("required") ?? false)
    }

    func testSaveDraft_UpdatesLastAutoSaveDate() async {
        let assessment = createMockClinicalAssessment()
        sut.currentAssessment = assessment
        mockService.updateAssessmentResult = assessment

        await sut.saveDraft()

        XCTAssertNotNil(sut.lastAutoSaveDate)
    }

    func testSaveDraft_SetsErrorForSignedAssessment() async {
        let signedAssessment = createMockClinicalAssessment(status: .signed)
        sut.currentAssessment = signedAssessment

        await sut.saveDraft()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("signed") ?? false)
    }

    func testSubmitAssessment_CallsCompleteOnService() async {
        let assessment = createMockClinicalAssessment()
        sut.currentAssessment = assessment
        sut.patientId = assessment.patientId
        sut.therapistId = assessment.therapistId
        sut.chiefComplaint = "Pain"
        sut.objectiveFindings = "Findings"
        sut.assessmentSummary = "Summary"
        sut.treatmentPlan = "Plan"

        let completedAssessment = createMockClinicalAssessment(status: .complete)
        mockService.updateAssessmentResult = assessment
        mockService.completeAssessmentResult = completedAssessment

        await sut.submitAssessment()

        XCTAssertTrue(mockService.completeAssessmentCalled)
    }

    func testSubmitAssessment_ShowsValidationErrorsWhenInvalid() async {
        let assessment = createMockClinicalAssessment()
        sut.currentAssessment = assessment
        // Don't set required fields

        await sut.submitAssessment()

        XCTAssertTrue(sut.showValidationErrors)
    }

    func testSignAssessment_CallsSignOnService() async {
        let assessment = createMockClinicalAssessment(status: .complete)
        sut.currentAssessment = assessment

        let signedAssessment = createMockClinicalAssessment(status: .signed)
        mockService.signAssessmentResult = signedAssessment

        await sut.signAssessment()

        XCTAssertTrue(mockService.signAssessmentCalled)
    }

    func testSignAssessment_SetsErrorWhenNotComplete() async {
        let draftAssessment = createMockClinicalAssessment(status: .draft)
        sut.currentAssessment = draftAssessment

        await sut.signAssessment()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("complete") ?? false)
    }

    // MARK: - Clear Messages Tests

    func testClearMessages_ClearsBothMessages() {
        sut.errorMessage = "Error"
        sut.successMessage = "Success"

        sut.clearMessages()

        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    // MARK: - AssessmentSectionStatus Tests

    func testAssessmentSectionStatus_AllRequiredComplete_WhenAllRequiredTrue() {
        var status = AssessmentSectionStatus()
        status.subjectiveComplete = true
        status.objectiveComplete = true
        status.assessmentComplete = true
        status.planComplete = true

        XCTAssertTrue(status.allRequiredComplete)
    }

    func testAssessmentSectionStatus_AllRequiredComplete_FalseWhenMissing() {
        var status = AssessmentSectionStatus()
        status.subjectiveComplete = true
        status.objectiveComplete = true
        status.assessmentComplete = false
        status.planComplete = true

        XCTAssertFalse(status.allRequiredComplete)
    }

    func testAssessmentSectionStatus_CompletionPercentage_AllComplete() {
        var status = AssessmentSectionStatus()
        status.subjectiveComplete = true
        status.objectiveComplete = true
        status.painComplete = true
        status.romComplete = true
        status.functionalTestsComplete = true
        status.assessmentComplete = true
        status.planComplete = true

        XCTAssertEqual(status.completionPercentage, 100.0, accuracy: 0.01)
    }

    // MARK: - Helper Methods

    private func createMockROMeasurement() -> ROMeasurement {
        return ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            normalRange: 150...180,
            side: .right,
            painWithMovement: true,
            notes: "Pain at end range"
        )
    }

    private func createMockFunctionalTest() -> FunctionalTest {
        return FunctionalTest(
            testName: "Hawkins-Kennedy Test",
            result: "Positive",
            interpretation: "Indicates possible subacromial impingement"
        )
    }

    private func createMockClinicalAssessment(status: AssessmentStatus = .draft) -> ClinicalAssessment {
        return ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 2,
            painWithActivity: 5,
            painWorst: 7,
            painLocations: ["Right shoulder"],
            chiefComplaint: "Right shoulder pain",
            historyOfPresentIllness: "Gradual onset",
            functionalGoals: ["Return to sports"],
            objectiveFindings: "Decreased ROM",
            assessmentSummary: "Shoulder impingement",
            treatmentPlan: "Physical therapy 2x/week",
            status: status
        )
    }
}

// MARK: - Mock Service

@MainActor
class MockClinicalAssessmentService: ClinicalAssessmentService {

    var createAssessmentCalled = false
    var updateAssessmentCalled = false
    var completeAssessmentCalled = false
    var signAssessmentCalled = false

    var createAssessmentResult: ClinicalAssessment?
    var updateAssessmentResult: ClinicalAssessment?
    var completeAssessmentResult: ClinicalAssessment?
    var signAssessmentResult: ClinicalAssessment?

    var shouldThrowError = false

    override func createAssessment(
        patientId: UUID,
        therapistId: UUID,
        assessmentType: AssessmentType,
        assessmentDate: Date = Date()
    ) async throws -> ClinicalAssessment {
        createAssessmentCalled = true
        if shouldThrowError {
            throw ClinicalAssessmentError.saveFailed
        }
        return createAssessmentResult ?? ClinicalAssessment(
            patientId: patientId,
            therapistId: therapistId,
            assessmentType: assessmentType
        )
    }

    override func updateAssessment(_ assessment: ClinicalAssessment) async throws -> ClinicalAssessment {
        updateAssessmentCalled = true
        if shouldThrowError {
            throw ClinicalAssessmentError.saveFailed
        }
        return updateAssessmentResult ?? assessment
    }

    override func completeAssessment(_ assessmentId: UUID) async throws -> ClinicalAssessment {
        completeAssessmentCalled = true
        if shouldThrowError {
            throw ClinicalAssessmentError.saveFailed
        }
        guard let result = completeAssessmentResult else {
            throw ClinicalAssessmentError.assessmentNotFound
        }
        return result
    }

    override func signAssessment(_ assessmentId: UUID) async throws -> ClinicalAssessment {
        signAssessmentCalled = true
        if shouldThrowError {
            throw ClinicalAssessmentError.saveFailed
        }
        guard let result = signAssessmentResult else {
            throw ClinicalAssessmentError.assessmentNotFound
        }
        return result
    }
}
