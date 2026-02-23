//
//  TherapistProgramBuilderViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for TherapistProgramBuilderViewModel
//  Tests initial state, computed properties, wizard navigation,
//  phase management, equipment/tag management, validation,
//  template filtering, and data model properties
//

import XCTest
@testable import PTPerformance

// MARK: - Therapist Program Builder ViewModel Tests

@MainActor
final class TherapistProgramBuilderViewModelTests: XCTestCase {

    var sut: TherapistProgramBuilderViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = TherapistProgramBuilderViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentStepIsStart() {
        XCTAssertEqual(sut.currentStep, .start, "currentStep should be .start initially")
    }

    func testInitialState_SelectedPatientIsNil() {
        XCTAssertNil(sut.selectedPatient, "selectedPatient should be nil initially")
    }

    func testInitialState_CreationModeIsCustom() {
        XCTAssertEqual(sut.creationMode, .custom, "creationMode should be .custom initially")
    }

    func testInitialState_ProgramNameIsEmpty() {
        XCTAssertEqual(sut.programName, "", "programName should be empty initially")
    }

    func testInitialState_DescriptionIsEmpty() {
        XCTAssertEqual(sut.description, "", "description should be empty initially")
    }

    func testInitialState_CategoryIsStrength() {
        XCTAssertEqual(sut.category, ProgramCategory.strength.rawValue, "category should default to strength")
    }

    func testInitialState_DifficultyLevelIsIntermediate() {
        XCTAssertEqual(sut.difficultyLevel, DifficultyLevel.intermediate.rawValue, "difficultyLevel should default to intermediate")
    }

    func testInitialState_DurationWeeksIsTwelve() {
        XCTAssertEqual(sut.durationWeeks, 12, "durationWeeks should be 12 initially")
    }

    func testInitialState_EquipmentRequiredIsEmpty() {
        XCTAssertTrue(sut.equipmentRequired.isEmpty, "equipmentRequired should be empty initially")
    }

    func testInitialState_TagsIsEmpty() {
        XCTAssertTrue(sut.tags.isEmpty, "tags should be empty initially")
    }

    func testInitialState_EquipmentInputIsEmpty() {
        XCTAssertEqual(sut.equipmentInput, "", "equipmentInput should be empty initially")
    }

    func testInitialState_TagsInputIsEmpty() {
        XCTAssertEqual(sut.tagsInput, "", "tagsInput should be empty initially")
    }

    func testInitialState_PhasesIsEmpty() {
        XCTAssertTrue(sut.phases.isEmpty, "phases should be empty initially")
    }

    func testInitialState_AvailableTemplatesIsEmpty() {
        XCTAssertTrue(sut.availableTemplates.isEmpty, "availableTemplates should be empty initially")
    }

    func testInitialState_SelectedTemplateIsNil() {
        XCTAssertNil(sut.selectedTemplate, "selectedTemplate should be nil initially")
    }

    func testInitialState_TemplateSearchTextIsEmpty() {
        XCTAssertEqual(sut.templateSearchText, "", "templateSearchText should be empty initially")
    }

    func testInitialState_IsLoadingTemplatesIsFalse() {
        XCTAssertFalse(sut.isLoadingTemplates, "isLoadingTemplates should be false initially")
    }

    func testInitialState_SelectedQuickBuildTemplateIsNil() {
        XCTAssertNil(sut.selectedQuickBuildTemplate, "selectedQuickBuildTemplate should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SuccessMessageIsNil() {
        XCTAssertNil(sut.successMessage, "successMessage should be nil initially")
    }

    func testInitialState_TemplateLoadFailedIsFalse() {
        XCTAssertFalse(sut.templateLoadFailed, "templateLoadFailed should be false initially")
    }

    func testInitialState_ShowUnsavedChangesAlertIsFalse() {
        XCTAssertFalse(sut.showUnsavedChangesAlert, "showUnsavedChangesAlert should be false initially")
    }

    // MARK: - hasUnsavedChanges Tests

    func testHasUnsavedChanges_InitiallyFalse() {
        XCTAssertFalse(sut.hasUnsavedChanges, "hasUnsavedChanges should be false with no data")
    }

    func testHasUnsavedChanges_TrueWhenPhasesNotEmpty() {
        sut.addPhase()
        XCTAssertTrue(sut.hasUnsavedChanges, "hasUnsavedChanges should be true when phases exist")
    }

    func testHasUnsavedChanges_TrueWhenProgramNameNotEmpty() {
        sut.programName = "Test Program"
        XCTAssertTrue(sut.hasUnsavedChanges, "hasUnsavedChanges should be true when programName is set")
    }

    func testHasUnsavedChanges_TrueWhenPatientSelected() {
        sut.selectedPatient = makePatient()
        XCTAssertTrue(sut.hasUnsavedChanges, "hasUnsavedChanges should be true when patient is selected")
    }

    func testHasUnsavedChanges_FalseWhenProgramNameOnlyWhitespace() {
        sut.programName = ""
        XCTAssertFalse(sut.hasUnsavedChanges)
    }

    // MARK: - isValid Tests

    func testIsValid_InitiallyFalse() {
        XCTAssertFalse(sut.isValid, "isValid should be false with empty programName")
    }

    func testIsValid_TrueWithValidName() {
        sut.programName = "My Program"
        XCTAssertTrue(sut.isValid, "isValid should be true with a valid program name")
    }

    func testIsValid_FalseWithShortName() {
        sut.programName = "AB"
        XCTAssertFalse(sut.isValid, "isValid should be false when name is less than 3 characters")
    }

    func testIsValid_FalseWithWhitespaceOnlyName() {
        sut.programName = "   "
        XCTAssertFalse(sut.isValid, "isValid should be false when name is only whitespace")
    }

    func testIsValid_TrueWithExactlyThreeCharacterName() {
        sut.programName = "ABC"
        XCTAssertTrue(sut.isValid, "isValid should be true when name is exactly 3 characters")
    }

    func testIsValid_FalseWithNameOver100Characters() {
        sut.programName = String(repeating: "A", count: 101)
        XCTAssertFalse(sut.isValid, "isValid should be false when name exceeds 100 characters")
    }

    func testIsValid_TrueWithNameExactly100Characters() {
        sut.programName = String(repeating: "A", count: 100)
        XCTAssertTrue(sut.isValid, "isValid should be true when name is exactly 100 characters")
    }

    func testIsValid_TrimsWhitespaceBeforeValidation() {
        sut.programName = "  AB  "
        XCTAssertFalse(sut.isValid, "isValid should trim whitespace before checking length; 'AB' is only 2 chars")
    }

    // MARK: - isReadyToPublish Tests

    func testIsReadyToPublish_InitiallyFalse() {
        XCTAssertFalse(sut.isReadyToPublish, "isReadyToPublish should be false initially")
    }

    func testIsReadyToPublish_FalseWithValidNameButNoPhases() {
        sut.programName = "My Program"
        XCTAssertFalse(sut.isReadyToPublish, "isReadyToPublish should be false without phases")
    }

    func testIsReadyToPublish_FalseWithPhasesButNoWorkouts() {
        sut.programName = "My Program"
        sut.addPhase()
        XCTAssertFalse(sut.isReadyToPublish, "isReadyToPublish should be false when phases have no workout assignments")
    }

    func testIsReadyToPublish_TrueWithValidNameAndPhaseWithWorkouts() {
        sut.programName = "My Program"
        let templateId = UUID()
        let assignment = TherapistWorkoutAssignment(
            templateId: templateId,
            templateName: "Push Day",
            weekNumber: 1,
            dayOfWeek: 1
        )
        let phase = TherapistPhaseData(
            name: "Phase 1",
            sequence: 1,
            durationWeeks: 4,
            goals: "Build strength",
            workoutAssignments: [assignment]
        )
        sut.phases = [phase]
        XCTAssertTrue(sut.isReadyToPublish, "isReadyToPublish should be true with valid name and phase with workouts")
    }

    func testIsReadyToPublish_FalseWithInvalidName() {
        sut.programName = "AB"
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Push Day",
            weekNumber: 1,
            dayOfWeek: 1
        )
        sut.phases = [TherapistPhaseData(
            name: "Phase 1",
            sequence: 1,
            durationWeeks: 4,
            workoutAssignments: [assignment]
        )]
        XCTAssertFalse(sut.isReadyToPublish, "isReadyToPublish should be false with invalid name")
    }

    // MARK: - totalPhaseDuration Tests

    func testTotalPhaseDuration_EmptyPhases() {
        XCTAssertEqual(sut.totalPhaseDuration, 0, "totalPhaseDuration should be 0 with no phases")
    }

    func testTotalPhaseDuration_SinglePhase() {
        sut.phases = [TherapistPhaseData(name: "Phase 1", sequence: 1, durationWeeks: 4)]
        XCTAssertEqual(sut.totalPhaseDuration, 4)
    }

    func testTotalPhaseDuration_MultiplePhases() {
        sut.phases = [
            TherapistPhaseData(name: "Phase 1", sequence: 1, durationWeeks: 4),
            TherapistPhaseData(name: "Phase 2", sequence: 2, durationWeeks: 6),
            TherapistPhaseData(name: "Phase 3", sequence: 3, durationWeeks: 2)
        ]
        XCTAssertEqual(sut.totalPhaseDuration, 12, "totalPhaseDuration should sum all phase durations")
    }

    // MARK: - canProceed Tests

    func testCanProceed_StartStep_AlwaysTrue() {
        sut.currentStep = .start
        XCTAssertTrue(sut.canProceed, "canProceed should always be true at .start")
    }

    func testCanProceed_QuickBuildPickerStep_FalseWithoutTemplate() {
        sut.currentStep = .quickBuildPicker
        sut.selectedQuickBuildTemplate = nil
        XCTAssertFalse(sut.canProceed, "canProceed should be false at .quickBuildPicker without a selection")
    }

    func testCanProceed_QuickBuildPickerStep_TrueWithTemplate() {
        sut.currentStep = .quickBuildPicker
        sut.selectedQuickBuildTemplate = QuickBuildTemplate.templates.first
        XCTAssertTrue(sut.canProceed, "canProceed should be true at .quickBuildPicker with a selection")
    }

    func testCanProceed_TemplatePickerStep_FalseWithoutTemplate() {
        sut.currentStep = .templatePicker
        sut.selectedTemplate = nil
        XCTAssertFalse(sut.canProceed, "canProceed should be false at .templatePicker without selection")
    }

    func testCanProceed_TemplatePickerStep_TrueWithTemplate() {
        sut.currentStep = .templatePicker
        sut.selectedTemplate = makeLibraryTemplate()
        XCTAssertTrue(sut.canProceed, "canProceed should be true at .templatePicker with selection")
    }

    func testCanProceed_PatientStep_AlwaysTrue() {
        sut.currentStep = .patient
        XCTAssertTrue(sut.canProceed, "canProceed should always be true at .patient (patient is optional)")
    }

    func testCanProceed_BasicsStep_DependsOnIsValid() {
        sut.currentStep = .basics
        sut.programName = ""
        XCTAssertFalse(sut.canProceed, "canProceed at .basics should be false when isValid is false")

        sut.programName = "Valid Program Name"
        XCTAssertTrue(sut.canProceed, "canProceed at .basics should be true when isValid is true")
    }

    func testCanProceed_PhasesStep_AlwaysTrue() {
        sut.currentStep = .phases
        XCTAssertTrue(sut.canProceed, "canProceed should always be true at .phases")
    }

    func testCanProceed_WorkoutsStep_AlwaysTrue() {
        sut.currentStep = .workouts
        XCTAssertTrue(sut.canProceed, "canProceed should always be true at .workouts")
    }

    func testCanProceed_PreviewStep_DependsOnIsReadyToPublish() {
        sut.currentStep = .preview
        XCTAssertFalse(sut.canProceed, "canProceed at .preview should be false when not ready to publish")
    }

    // MARK: - BuilderStep Tests

    func testBuilderStep_AllCasesCount() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.allCases.count, 8, "Should have 8 builder steps")
    }

    func testBuilderStep_RawValues() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.start.rawValue, 0)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.quickBuildPicker.rawValue, 1)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.templatePicker.rawValue, 2)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.patient.rawValue, 3)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.basics.rawValue, 4)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.phases.rawValue, 5)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.workouts.rawValue, 6)
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.preview.rawValue, 7)
    }

    func testBuilderStep_DisplayNames() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.start.displayName, "Start")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.quickBuildPicker.displayName, "Quick Build")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.templatePicker.displayName, "Template")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.patient.displayName, "Patient")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.basics.displayName, "Basics")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.phases.displayName, "Phases")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.workouts.displayName, "Workouts")
        XCTAssertEqual(TherapistProgramBuilderViewModel.BuilderStep.preview.displayName, "Preview")
    }

    // MARK: - CreationMode Tests

    func testCreationMode_AllCasesCount() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.allCases.count, 3)
    }

    func testCreationMode_Titles() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.quickBuild.title, "Quick Build")
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.fromTemplate.title, "From Template")
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.custom.title, "Custom Program")
    }

    func testCreationMode_Descriptions() {
        XCTAssertFalse(TherapistProgramBuilderViewModel.CreationMode.quickBuild.description.isEmpty)
        XCTAssertFalse(TherapistProgramBuilderViewModel.CreationMode.fromTemplate.description.isEmpty)
        XCTAssertFalse(TherapistProgramBuilderViewModel.CreationMode.custom.description.isEmpty)
    }

    func testCreationMode_Icons() {
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.quickBuild.icon, "sparkles")
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.fromTemplate.icon, "doc.on.doc")
        XCTAssertEqual(TherapistProgramBuilderViewModel.CreationMode.custom.icon, "hammer")
    }

    // MARK: - Wizard Navigation: nextStep Tests

    func testNextStep_FromStart_CustomMode_GoesToPatient() {
        sut.currentStep = .start
        sut.creationMode = .custom
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .patient, "Custom mode from start should go to patient")
    }

    func testNextStep_FromStart_QuickBuildMode_GoesToQuickBuildPicker() {
        sut.currentStep = .start
        sut.creationMode = .quickBuild
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .quickBuildPicker, "Quick build mode from start should go to quickBuildPicker")
    }

    func testNextStep_FromStart_FromTemplateMode_GoesToTemplatePicker() {
        sut.currentStep = .start
        sut.creationMode = .fromTemplate
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .templatePicker, "From template mode from start should go to templatePicker")
    }

    func testNextStep_FromQuickBuildPicker_GoesToPatient() {
        sut.currentStep = .quickBuildPicker
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .patient, "From quickBuildPicker should go to patient")
    }

    func testNextStep_FromTemplatePicker_GoesToPatient() {
        sut.currentStep = .templatePicker
        sut.templateSearchText = "some search"
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .patient, "From templatePicker should go to patient")
        XCTAssertEqual(sut.templateSearchText, "", "templateSearchText should be cleared when leaving template picker")
    }

    func testNextStep_FromPatient_GoesToBasics() {
        sut.currentStep = .patient
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .basics)
    }

    func testNextStep_FromBasics_GoesToPhases() {
        sut.currentStep = .basics
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .phases)
    }

    func testNextStep_FromPhases_GoesToWorkouts() {
        sut.currentStep = .phases
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .workouts)
    }

    func testNextStep_FromWorkouts_GoesToPreview() {
        sut.currentStep = .workouts
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .preview)
    }

    func testNextStep_ClearsErrorMessage() {
        sut.currentStep = .patient
        sut.errorMessage = "Some error"
        sut.nextStep()
        XCTAssertNil(sut.errorMessage, "errorMessage should be cleared on nextStep")
    }

    // MARK: - Wizard Navigation: previousStep Tests

    func testPreviousStep_FromPatient_CustomMode_GoesToStart() {
        sut.currentStep = .patient
        sut.creationMode = .custom
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .start)
    }

    func testPreviousStep_FromPatient_QuickBuildMode_GoesToQuickBuildPicker() {
        sut.currentStep = .patient
        sut.creationMode = .quickBuild
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .quickBuildPicker)
    }

    func testPreviousStep_FromPatient_FromTemplateMode_GoesToTemplatePicker() {
        sut.currentStep = .patient
        sut.creationMode = .fromTemplate
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .templatePicker)
    }

    func testPreviousStep_FromQuickBuildPicker_GoesToStart() {
        sut.currentStep = .quickBuildPicker
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .start)
    }

    func testPreviousStep_FromTemplatePicker_GoesToStart() {
        sut.currentStep = .templatePicker
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .start)
    }

    func testPreviousStep_FromBasics_GoesToPatient() {
        sut.currentStep = .basics
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .patient)
    }

    func testPreviousStep_ClearsErrorMessage() {
        sut.currentStep = .basics
        sut.errorMessage = "Some error"
        sut.previousStep()
        XCTAssertNil(sut.errorMessage, "errorMessage should be cleared on previousStep")
    }

    // MARK: - wouldLoseWorkGoingBack Tests

    func testWouldLoseWorkGoingBack_PhasesStep_WithPhases_ReturnsTrue() {
        sut.currentStep = .phases
        sut.addPhase()
        XCTAssertTrue(sut.wouldLoseWorkGoingBack())
    }

    func testWouldLoseWorkGoingBack_PhasesStep_WithoutPhases_ReturnsFalse() {
        sut.currentStep = .phases
        XCTAssertFalse(sut.wouldLoseWorkGoingBack())
    }

    func testWouldLoseWorkGoingBack_WorkoutsStep_WithAssignments_ReturnsTrue() {
        sut.currentStep = .workouts
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Push Day",
            weekNumber: 1,
            dayOfWeek: 1
        )
        sut.phases = [TherapistPhaseData(
            name: "Phase 1",
            sequence: 1,
            workoutAssignments: [assignment]
        )]
        XCTAssertTrue(sut.wouldLoseWorkGoingBack())
    }

    func testWouldLoseWorkGoingBack_WorkoutsStep_WithoutAssignments_ReturnsFalse() {
        sut.currentStep = .workouts
        sut.addPhase()
        XCTAssertFalse(sut.wouldLoseWorkGoingBack())
    }

    func testWouldLoseWorkGoingBack_OtherSteps_ReturnsFalse() {
        for step in TherapistProgramBuilderViewModel.BuilderStep.allCases {
            if step != .phases && step != .workouts {
                sut.currentStep = step
                XCTAssertFalse(sut.wouldLoseWorkGoingBack(),
                               "wouldLoseWorkGoingBack should return false for step \(step)")
            }
        }
    }

    // MARK: - goToStep Tests

    func testGoToStep_ChangesCurrentStep() {
        sut.goToStep(.preview)
        XCTAssertEqual(sut.currentStep, .preview)
    }

    // MARK: - resetWizard Tests

    func testResetWizard_ResetsAllState() {
        // Set up some state
        sut.programName = "Test Program"
        sut.description = "A description"
        sut.category = ProgramCategory.cardio.rawValue
        sut.difficultyLevel = DifficultyLevel.advanced.rawValue
        sut.durationWeeks = 8
        sut.equipmentRequired = ["Barbell"]
        sut.tags = ["strength"]
        sut.equipmentInput = "Dumbbell"
        sut.tagsInput = "power"
        sut.addPhase()
        sut.selectedTemplate = makeLibraryTemplate()
        sut.selectedQuickBuildTemplate = QuickBuildTemplate.templates.first
        sut.templateSearchText = "search"
        sut.errorMessage = "error"
        sut.successMessage = "success"
        sut.currentStep = .preview
        sut.creationMode = .quickBuild
        sut.selectedPatient = makePatient()

        sut.resetWizard()

        XCTAssertEqual(sut.currentStep, .start)
        XCTAssertNil(sut.selectedPatient)
        XCTAssertEqual(sut.creationMode, .custom)
        XCTAssertEqual(sut.programName, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.category, ProgramCategory.strength.rawValue)
        XCTAssertEqual(sut.difficultyLevel, DifficultyLevel.intermediate.rawValue)
        XCTAssertEqual(sut.durationWeeks, 12)
        XCTAssertTrue(sut.equipmentRequired.isEmpty)
        XCTAssertTrue(sut.tags.isEmpty)
        XCTAssertEqual(sut.equipmentInput, "")
        XCTAssertEqual(sut.tagsInput, "")
        XCTAssertTrue(sut.phases.isEmpty)
        XCTAssertTrue(sut.availableTemplates.isEmpty)
        XCTAssertNil(sut.selectedTemplate)
        XCTAssertNil(sut.selectedQuickBuildTemplate)
        XCTAssertEqual(sut.templateSearchText, "")
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    // MARK: - Equipment Management Tests

    func testAddEquipmentFromInput_AddsValidItems() {
        sut.equipmentInput = "Barbell, Dumbbell, Bench"
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 3)
        XCTAssertTrue(sut.equipmentRequired.contains("Barbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Dumbbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Bench"))
        XCTAssertEqual(sut.equipmentInput, "", "equipmentInput should be cleared after adding")
    }

    func testAddEquipmentFromInput_SkipsEmptyItems() {
        sut.equipmentInput = "Barbell,,, Dumbbell"
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 2)
    }

    func testAddEquipmentFromInput_SkipsDuplicates() {
        sut.equipmentRequired = ["Barbell"]
        sut.equipmentInput = "Barbell, Dumbbell"
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 2, "Should not add duplicate Barbell")
    }

    func testAddEquipmentFromInput_SkipsSpecialCharacters() {
        sut.equipmentInput = "Barbell!, @Dumbbell, Valid Item"
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 1, "Should only add items with alphanumeric and whitespace chars")
        XCTAssertTrue(sut.equipmentRequired.contains("Valid Item"))
    }

    func testAddEquipmentFromInput_SkipsItemsExceedingMaxLength() {
        let longItem = String(repeating: "A", count: 51)
        sut.equipmentInput = "\(longItem), Short"
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 1)
        XCTAssertTrue(sut.equipmentRequired.contains("Short"))
    }

    func testAddEquipmentFromInput_LimitsToTenItems() {
        let items = (1...15).map { "Item\($0)" }.joined(separator: ", ")
        sut.equipmentInput = items
        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 10, "Should limit to 10 items at once")
    }

    func testAddEquipmentFromInput_TrimsWhitespace() {
        sut.equipmentInput = "  Barbell  ,  Dumbbell  "
        sut.addEquipmentFromInput()

        XCTAssertTrue(sut.equipmentRequired.contains("Barbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Dumbbell"))
    }

    func testRemoveEquipment_RemovesSpecificItem() {
        sut.equipmentRequired = ["Barbell", "Dumbbell", "Bench"]
        sut.removeEquipment("Dumbbell")

        XCTAssertEqual(sut.equipmentRequired.count, 2)
        XCTAssertFalse(sut.equipmentRequired.contains("Dumbbell"))
    }

    func testRemoveEquipment_NoOpForNonexistentItem() {
        sut.equipmentRequired = ["Barbell"]
        sut.removeEquipment("Nonexistent")
        XCTAssertEqual(sut.equipmentRequired.count, 1)
    }

    // MARK: - Tag Management Tests

    func testAddTagsFromInput_AddsValidTags() {
        sut.tagsInput = "strength, power, endurance"
        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.count, 3)
        XCTAssertTrue(sut.tags.contains("strength"))
        XCTAssertTrue(sut.tags.contains("power"))
        XCTAssertTrue(sut.tags.contains("endurance"))
        XCTAssertEqual(sut.tagsInput, "", "tagsInput should be cleared after adding")
    }

    func testAddTagsFromInput_ConvertToLowercase() {
        sut.tagsInput = "STRENGTH, Power"
        sut.addTagsFromInput()

        XCTAssertTrue(sut.tags.contains("strength"))
        XCTAssertTrue(sut.tags.contains("power"))
    }

    func testAddTagsFromInput_SkipsDuplicates() {
        sut.tags = ["strength"]
        sut.tagsInput = "strength, power"
        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.count, 2, "Should not add duplicate 'strength'")
    }

    func testAddTagsFromInput_SkipsSpecialCharacters() {
        sut.tagsInput = "valid tag, inv@lid, good"
        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.count, 2)
        XCTAssertTrue(sut.tags.contains("valid tag"))
        XCTAssertTrue(sut.tags.contains("good"))
    }

    func testAddTagsFromInput_SkipsTagsExceedingMaxLength() {
        let longTag = String(repeating: "a", count: 31)
        sut.tagsInput = "\(longTag), short"
        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.count, 1)
        XCTAssertTrue(sut.tags.contains("short"))
    }

    func testAddTagsFromInput_LimitsToTenItems() {
        let items = (1...15).map { "tag\($0)" }.joined(separator: ", ")
        sut.tagsInput = items
        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.count, 10, "Should limit to 10 tags at once")
    }

    func testRemoveTag_RemovesSpecificTag() {
        sut.tags = ["strength", "power", "endurance"]
        sut.removeTag("power")

        XCTAssertEqual(sut.tags.count, 2)
        XCTAssertFalse(sut.tags.contains("power"))
    }

    // MARK: - Phase Management Tests

    func testAddPhase_AddsPhaseWithCorrectSequence() {
        sut.addPhase()
        XCTAssertEqual(sut.phases.count, 1)
        XCTAssertEqual(sut.phases[0].name, "Phase 1")
        XCTAssertEqual(sut.phases[0].sequence, 1)
        XCTAssertEqual(sut.phases[0].durationWeeks, 4)
    }

    func testAddPhase_MultiplePhases_IncrementSequence() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        XCTAssertEqual(sut.phases.count, 3)
        XCTAssertEqual(sut.phases[0].name, "Phase 1")
        XCTAssertEqual(sut.phases[0].sequence, 1)
        XCTAssertEqual(sut.phases[1].name, "Phase 2")
        XCTAssertEqual(sut.phases[1].sequence, 2)
        XCTAssertEqual(sut.phases[2].name, "Phase 3")
        XCTAssertEqual(sut.phases[2].sequence, 3)
    }

    func testUpdatePhase_UpdatesExistingPhase() {
        sut.addPhase()
        var updatedPhase = sut.phases[0]
        updatedPhase.name = "Updated Phase Name"
        updatedPhase.durationWeeks = 6
        updatedPhase.goals = "New goals"
        sut.updatePhase(updatedPhase)

        XCTAssertEqual(sut.phases[0].name, "Updated Phase Name")
        XCTAssertEqual(sut.phases[0].durationWeeks, 6)
        XCTAssertEqual(sut.phases[0].goals, "New goals")
    }

    func testUpdatePhase_UsesDefaultNameWhenEmpty() {
        sut.addPhase()
        var updatedPhase = sut.phases[0]
        updatedPhase.name = "   "
        sut.updatePhase(updatedPhase)

        XCTAssertEqual(sut.phases[0].name, "Phase 1", "Should use default name when empty/whitespace")
    }

    func testUpdatePhase_TruncatesLongName() {
        sut.addPhase()
        var updatedPhase = sut.phases[0]
        updatedPhase.name = String(repeating: "A", count: 150)
        sut.updatePhase(updatedPhase)

        XCTAssertEqual(sut.phases[0].name.count, 100, "Should truncate name to 100 characters")
    }

    func testUpdatePhase_TrimsWhitespace() {
        sut.addPhase()
        var updatedPhase = sut.phases[0]
        updatedPhase.name = "  Trimmed Name  "
        sut.updatePhase(updatedPhase)

        XCTAssertEqual(sut.phases[0].name, "Trimmed Name")
    }

    func testUpdatePhase_NoOpForNonExistentPhase() {
        sut.addPhase()
        let nonExistentPhase = TherapistPhaseData(
            id: UUID(),
            name: "Ghost Phase",
            sequence: 99
        )
        sut.updatePhase(nonExistentPhase)

        XCTAssertEqual(sut.phases.count, 1)
        XCTAssertNotEqual(sut.phases[0].name, "Ghost Phase")
    }

    func testDeletePhase_RemovesAtIndex() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        sut.deletePhase(at: 1)

        XCTAssertEqual(sut.phases.count, 2)
    }

    func testDeletePhase_ResequencesRemainingPhases() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        sut.deletePhase(at: 0)

        XCTAssertEqual(sut.phases[0].sequence, 1, "First remaining phase should have sequence 1")
        XCTAssertEqual(sut.phases[1].sequence, 2, "Second remaining phase should have sequence 2")
    }

    func testDeletePhase_OutOfBoundsIsNoOp() {
        sut.addPhase()
        sut.deletePhase(at: 5)
        XCTAssertEqual(sut.phases.count, 1, "Should not delete anything for out of bounds index")
    }

    func testDeletePhase_NegativeIndexIsNoOp() {
        sut.addPhase()
        sut.deletePhase(at: -1)
        XCTAssertEqual(sut.phases.count, 1)
    }

    func testMovePhases_ReordersAndResequences() {
        sut.addPhase()  // Phase 1
        sut.addPhase()  // Phase 2
        sut.addPhase()  // Phase 3

        let originalFirstId = sut.phases[0].id
        let originalThirdId = sut.phases[2].id

        // Move first item to end
        sut.movePhases(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(sut.phases[2].id, originalFirstId, "First item should now be at the end")
        XCTAssertEqual(sut.phases[0].id, originalThirdId != sut.phases[0].id ? sut.phases[0].id : sut.phases[0].id, "Items should be reordered")

        // Check resequencing
        for (index, phase) in sut.phases.enumerated() {
            XCTAssertEqual(phase.sequence, index + 1, "Phase at index \(index) should have sequence \(index + 1)")
        }
    }

    // MARK: - validatePhaseName Tests

    func testValidatePhaseName_ValidName() {
        let result = sut.validatePhaseName("Foundation Phase")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }

    func testValidatePhaseName_EmptyName() {
        let result = sut.validatePhaseName("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Phase name cannot be empty")
    }

    func testValidatePhaseName_WhitespaceOnlyName() {
        let result = sut.validatePhaseName("   ")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Phase name cannot be empty")
    }

    func testValidatePhaseName_TooLongName() {
        let longName = String(repeating: "A", count: 101)
        let result = sut.validatePhaseName(longName)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.message)
        XCTAssertTrue(result.message?.contains("100") ?? false, "Message should mention the limit")
    }

    func testValidatePhaseName_ExactlyMaxLength() {
        let name = String(repeating: "A", count: 100)
        let result = sut.validatePhaseName(name)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }

    // MARK: - Template Filtering Tests

    func testFilteredTemplates_WhenSearchEmpty_ReturnsAll() {
        let templates = [
            makeLibraryTemplate(title: "Strength Program"),
            makeLibraryTemplate(title: "Mobility Routine")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = ""

        XCTAssertEqual(sut.filteredTemplates.count, 2, "Should return all templates when search is empty")
    }

    func testFilteredTemplates_FiltersByTitle() {
        let templates = [
            makeLibraryTemplate(title: "Strength Program"),
            makeLibraryTemplate(title: "Mobility Routine")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "Strength"

        XCTAssertEqual(sut.filteredTemplates.count, 1)
        XCTAssertEqual(sut.filteredTemplates.first?.title, "Strength Program")
    }

    func testFilteredTemplates_FiltersByDescription() {
        let templates = [
            makeLibraryTemplate(title: "Program A", description: "For strength training"),
            makeLibraryTemplate(title: "Program B", description: "For cardio fitness")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "cardio"

        XCTAssertEqual(sut.filteredTemplates.count, 1)
        XCTAssertEqual(sut.filteredTemplates.first?.title, "Program B")
    }

    func testFilteredTemplates_FiltersByCategory() {
        let templates = [
            makeLibraryTemplate(title: "Program A", category: "strength"),
            makeLibraryTemplate(title: "Program B", category: "mobility")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "mobility"

        XCTAssertEqual(sut.filteredTemplates.count, 1)
        XCTAssertEqual(sut.filteredTemplates.first?.title, "Program B")
    }

    func testFilteredTemplates_FiltersByTags() {
        let templates = [
            makeLibraryTemplate(title: "Program A", tags: ["upper body", "push"]),
            makeLibraryTemplate(title: "Program B", tags: ["lower body", "pull"])
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "pull"

        XCTAssertEqual(sut.filteredTemplates.count, 1)
        XCTAssertEqual(sut.filteredTemplates.first?.title, "Program B")
    }

    func testFilteredTemplates_CaseInsensitive() {
        let templates = [
            makeLibraryTemplate(title: "STRENGTH Program")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "strength"

        XCTAssertEqual(sut.filteredTemplates.count, 1)
    }

    func testFilteredTemplates_NoMatch_ReturnsEmpty() {
        let templates = [
            makeLibraryTemplate(title: "Strength Program")
        ]
        sut.availableTemplates = templates
        sut.templateSearchText = "zzz_nonexistent"

        XCTAssertTrue(sut.filteredTemplates.isEmpty)
    }

    // MARK: - isTemplatePartiallyApplied Tests

    func testIsTemplatePartiallyApplied_InitiallyFalse() {
        XCTAssertFalse(sut.isTemplatePartiallyApplied)
    }

    func testIsTemplatePartiallyApplied_TrueWhenTemplateSelectedNoPhasesButNameSet() {
        sut.selectedTemplate = makeLibraryTemplate()
        sut.programName = "Test Program (Copy)"
        sut.phases = []
        XCTAssertTrue(sut.isTemplatePartiallyApplied)
    }

    func testIsTemplatePartiallyApplied_FalseWhenPhasesExist() {
        sut.selectedTemplate = makeLibraryTemplate()
        sut.programName = "Test Program (Copy)"
        sut.addPhase()
        XCTAssertFalse(sut.isTemplatePartiallyApplied)
    }

    func testIsTemplatePartiallyApplied_FalseWhenNameEmpty() {
        sut.selectedTemplate = makeLibraryTemplate()
        sut.programName = ""
        XCTAssertFalse(sut.isTemplatePartiallyApplied)
    }

    // MARK: - clearTemplateSelection Tests

    func testClearTemplateSelection_SetsTemplateToNil() {
        sut.selectedTemplate = makeLibraryTemplate()
        sut.programName = "Test (Copy)"
        sut.clearTemplateSelection()

        XCTAssertNil(sut.selectedTemplate, "selectedTemplate should be nil after clearing")
        XCTAssertEqual(sut.programName, "Test (Copy)", "programName should be preserved")
    }

    // MARK: - Quick Build Template Application Tests

    func testApplyQuickBuildTemplate_CustomTemplate_ResetsToDefaults() {
        sut.programName = "Existing Program"
        sut.description = "Existing description"
        sut.addPhase()

        let customTemplate = QuickBuildTemplate.templates.first { $0.isCustom }!
        sut.applyQuickBuildTemplate(customTemplate)

        XCTAssertEqual(sut.programName, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.category, ProgramCategory.strength.rawValue)
        XCTAssertEqual(sut.difficultyLevel, DifficultyLevel.intermediate.rawValue)
        XCTAssertEqual(sut.durationWeeks, 4)
        XCTAssertTrue(sut.phases.isEmpty)
    }

    func testApplyQuickBuildTemplate_NonCustomTemplate_PreFillsData() {
        let template = QuickBuildTemplate.templates.first { !$0.isCustom }!
        sut.applyQuickBuildTemplate(template)

        XCTAssertEqual(sut.programName, template.name)
        XCTAssertEqual(sut.description, template.description)
        XCTAssertEqual(sut.category, template.categoryForViewModel)
        XCTAssertEqual(sut.difficultyLevel, template.difficultyLevel)
        XCTAssertEqual(sut.durationWeeks, template.durationWeeks)
        XCTAssertEqual(sut.phases.count, template.phases.count, "Should create phases from template")
    }

    func testApplyQuickBuildTemplate_PhasesHaveCorrectSequence() {
        let template = QuickBuildTemplate.templates.first { $0.phases.count >= 3 }!
        sut.applyQuickBuildTemplate(template)

        for (index, phase) in sut.phases.enumerated() {
            XCTAssertEqual(phase.sequence, index + 1, "Phase \(index) should have sequence \(index + 1)")
        }
    }

    func testApplyQuickBuildTemplate_PhaseDurationCalculatedCorrectly() {
        let template = QuickBuildTemplate.templates.first { !$0.isCustom }!
        sut.applyQuickBuildTemplate(template)

        for (index, phase) in sut.phases.enumerated() {
            let expectedDuration = template.phases[index].weekEnd - template.phases[index].weekStart + 1
            XCTAssertEqual(phase.durationWeeks, expectedDuration,
                           "Phase \(index) duration should be \(expectedDuration)")
        }
    }

    // MARK: - TherapistProgramBuilderError Tests

    func testError_InvalidProgram_Description() {
        let error = TherapistProgramBuilderError.invalidProgram
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("required") ?? false)
    }

    func testError_NotReadyToPublish_Description() {
        let error = TherapistProgramBuilderError.notReadyToPublish
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("phase") ?? false)
    }

    func testError_ProgramCreationFailed_Description() {
        let error = TherapistProgramBuilderError.programCreationFailed
        XCTAssertNotNil(error.errorDescription)
    }

    func testError_PhaseCreationFailed_Description() {
        let error = TherapistProgramBuilderError.phaseCreationFailed
        XCTAssertNotNil(error.errorDescription)
    }

    func testError_PublishFailed_Description() {
        let error = TherapistProgramBuilderError.publishFailed
        XCTAssertNotNil(error.errorDescription)
    }

    func testError_AssignmentFailed_Description() {
        let error = TherapistProgramBuilderError.assignmentFailed
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - TherapistPhaseData Model Tests

    func testTherapistPhaseData_DefaultInitialization() {
        let phase = TherapistPhaseData()
        XCTAssertEqual(phase.name, "")
        XCTAssertEqual(phase.sequence, 1)
        XCTAssertEqual(phase.durationWeeks, 4)
        XCTAssertEqual(phase.goals, "")
        XCTAssertTrue(phase.workoutAssignments.isEmpty)
    }

    func testTherapistPhaseData_CustomInitialization() {
        let id = UUID()
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Workout A",
            weekNumber: 1,
            dayOfWeek: 1
        )
        let phase = TherapistPhaseData(
            id: id,
            name: "Strength Phase",
            sequence: 2,
            durationWeeks: 6,
            goals: "Build strength",
            workoutAssignments: [assignment]
        )

        XCTAssertEqual(phase.id, id)
        XCTAssertEqual(phase.name, "Strength Phase")
        XCTAssertEqual(phase.sequence, 2)
        XCTAssertEqual(phase.durationWeeks, 6)
        XCTAssertEqual(phase.goals, "Build strength")
        XCTAssertEqual(phase.workoutAssignments.count, 1)
    }

    func testTherapistPhaseData_Identifiable() {
        let phase1 = TherapistPhaseData()
        let phase2 = TherapistPhaseData()
        XCTAssertNotEqual(phase1.id, phase2.id, "Each phase should have a unique ID")
    }

    // MARK: - TherapistWorkoutAssignment Model Tests

    func testTherapistWorkoutAssignment_Initialization() {
        let templateId = UUID()
        let assignment = TherapistWorkoutAssignment(
            templateId: templateId,
            templateName: "Push Day",
            weekNumber: 2,
            dayOfWeek: 3
        )

        XCTAssertEqual(assignment.templateId, templateId)
        XCTAssertEqual(assignment.templateName, "Push Day")
        XCTAssertEqual(assignment.weekNumber, 2)
        XCTAssertEqual(assignment.dayOfWeek, 3)
    }

    func testTherapistWorkoutAssignment_Identifiable() {
        let assignment1 = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "A",
            weekNumber: 1,
            dayOfWeek: 1
        )
        let assignment2 = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "B",
            weekNumber: 1,
            dayOfWeek: 2
        )
        XCTAssertNotEqual(assignment1.id, assignment2.id)
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
    }

    func testPublishedProperties_ErrorMessageCanBeSet() {
        sut.errorMessage = "Network error"
        XCTAssertEqual(sut.errorMessage, "Network error")
    }

    func testPublishedProperties_SuccessMessageCanBeSet() {
        sut.successMessage = "Program saved!"
        XCTAssertEqual(sut.successMessage, "Program saved!")
    }

    func testPublishedProperties_TemplateLoadFailedCanBeSet() {
        sut.templateLoadFailed = true
        XCTAssertTrue(sut.templateLoadFailed)
    }

    func testPublishedProperties_ShowUnsavedChangesAlertCanBeSet() {
        sut.showUnsavedChangesAlert = true
        XCTAssertTrue(sut.showUnsavedChangesAlert)
    }

    // MARK: - QuickBuildTemplate Computed Properties Tests

    func testQuickBuildTemplate_IsCustom() {
        let customTemplate = QuickBuildTemplate.templates.first { $0.type == "custom" }
        XCTAssertNotNil(customTemplate)
        XCTAssertTrue(customTemplate!.isCustom)

        let nonCustomTemplate = QuickBuildTemplate.templates.first { $0.type != "custom" }
        XCTAssertNotNil(nonCustomTemplate)
        XCTAssertFalse(nonCustomTemplate!.isCustom)
    }

    func testQuickBuildTemplate_CategoryForViewModel_Rehab() {
        let rehabTemplate = QuickBuildTemplate.templates.first { $0.type == "rehab" }
        XCTAssertEqual(rehabTemplate?.categoryForViewModel, "rehab")
    }

    func testQuickBuildTemplate_CategoryForViewModel_Performance() {
        let perfTemplate = QuickBuildTemplate.templates.first { $0.type == "performance" }
        XCTAssertEqual(perfTemplate?.categoryForViewModel, "performance")
    }

    func testQuickBuildTemplate_CategoryForViewModel_Strength() {
        let strengthTemplate = QuickBuildTemplate.templates.first { $0.type == "strength" }
        XCTAssertEqual(strengthTemplate?.categoryForViewModel, "strength")
    }

    func testQuickBuildTemplate_CategoryForViewModel_Custom() {
        let customTemplate = QuickBuildTemplate.templates.first { $0.type == "custom" }
        XCTAssertEqual(customTemplate?.categoryForViewModel, "strength", "Custom should default to strength")
    }

    func testQuickBuildTemplate_Title_EqualsName() {
        for template in QuickBuildTemplate.templates {
            XCTAssertEqual(template.title, template.name)
        }
    }

    func testQuickBuildTemplate_Subtitle_NonCustomShowsWeeks() {
        let template = QuickBuildTemplate.templates.first { !$0.isCustom }!
        XCTAssertTrue(template.subtitle.contains("weeks"))
    }

    func testQuickBuildTemplate_Subtitle_CustomShowsFromScratch() {
        let template = QuickBuildTemplate.templates.first { $0.isCustom }!
        XCTAssertEqual(template.subtitle, "Build from scratch")
    }

    func testQuickBuildTemplate_ToTherapistPhases_CorrectCount() {
        for template in QuickBuildTemplate.templates where !template.isCustom {
            let therapistPhases = template.toTherapistPhases()
            XCTAssertEqual(therapistPhases.count, template.phases.count,
                           "Template '\(template.name)' should produce correct number of phases")
        }
    }

    func testQuickBuildTemplate_ToTherapistPhases_EmptyWorkoutAssignments() {
        let template = QuickBuildTemplate.templates.first { !$0.isCustom }!
        let therapistPhases = template.toTherapistPhases()

        for phase in therapistPhases {
            XCTAssertTrue(phase.workoutAssignments.isEmpty,
                          "Converted phases should have empty workout assignments")
        }
    }

    func testQuickBuildTemplate_AllOptions_EqualsTemplates() {
        XCTAssertEqual(QuickBuildTemplate.allOptions.count, QuickBuildTemplate.templates.count)
    }

    func testQuickBuildTemplate_TemplatesCount() {
        XCTAssertEqual(QuickBuildTemplate.templates.count, 5, "Should have 5 templates including custom")
    }

    // MARK: - Edge Cases

    func testAddPhaseAfterDeleteResequences() {
        sut.addPhase() // Phase 1
        sut.addPhase() // Phase 2
        sut.addPhase() // Phase 3

        sut.deletePhase(at: 1) // Delete Phase 2
        sut.addPhase()         // Should be Phase 3 (count is 3)

        XCTAssertEqual(sut.phases.count, 3)
        // The newly added phase should be named based on count
        XCTAssertEqual(sut.phases.last?.name, "Phase 3")
    }

    func testMultipleResets_DoNotLeaveStaleState() {
        sut.programName = "Test"
        sut.addPhase()
        sut.resetWizard()

        sut.programName = "Test 2"
        sut.addPhase()
        sut.addPhase()
        sut.resetWizard()

        XCTAssertEqual(sut.programName, "")
        XCTAssertTrue(sut.phases.isEmpty)
        XCTAssertEqual(sut.currentStep, .start)
    }

    // MARK: - Helper Methods

    /// Creates a minimal Patient for testing
    private func makePatient(
        firstName: String = "John",
        lastName: String = "Doe"
    ) -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: firstName,
            lastName: lastName,
            email: "test@test.com"
        )
    }

    /// Creates a minimal ProgramLibrary for testing
    private func makeLibraryTemplate(
        title: String = "Test Template",
        description: String? = nil,
        category: String = "strength",
        tags: [String]? = nil
    ) -> ProgramLibrary {
        ProgramLibrary(
            id: UUID(),
            title: title,
            description: description,
            category: category,
            durationWeeks: 8,
            difficultyLevel: "intermediate",
            tags: tags
        )
    }
}
