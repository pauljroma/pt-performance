//
//  DailyCheckInViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for DailyCheckInViewModel
//  Tests initial state, computed properties, step navigation, form updates,
//  readiness calculation, validation, and state transitions.
//

import XCTest
@testable import PTPerformance

@MainActor
final class DailyCheckInViewModelTests: XCTestCase {

    var sut: DailyCheckInViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = DailyCheckInViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_FlowStateIsNotStarted() {
        XCTAssertEqual(sut.flowState, .notStarted, "flowState should be .notStarted initially")
    }

    func testInitialState_CurrentStepIsSleep() {
        XCTAssertEqual(sut.currentStep, .sleep, "currentStep should be .sleep initially")
    }

    func testInitialState_SleepQualityIsThree() {
        XCTAssertEqual(sut.sleepQuality, 3, "sleepQuality should default to 3")
    }

    func testInitialState_SleepHoursIsSeven() {
        XCTAssertEqual(sut.sleepHours, 7.0, "sleepHours should default to 7.0")
    }

    func testInitialState_IncludeSleepHoursIsFalse() {
        XCTAssertFalse(sut.includeSleepHours, "includeSleepHours should be false initially")
    }

    func testInitialState_SorenessIsOne() {
        XCTAssertEqual(sut.soreness, 1, "soreness should default to 1")
    }

    func testInitialState_SorenessLocationsIsEmpty() {
        XCTAssertTrue(sut.sorenessLocations.isEmpty, "sorenessLocations should be empty initially")
    }

    func testInitialState_EnergyIsFive() {
        XCTAssertEqual(sut.energy, 5, "energy should default to 5")
    }

    func testInitialState_StressIsOne() {
        XCTAssertEqual(sut.stress, 1, "stress should default to 1")
    }

    func testInitialState_MoodIsThree() {
        XCTAssertEqual(sut.mood, 3, "mood should default to 3")
    }

    func testInitialState_PainScoreIsZero() {
        XCTAssertEqual(sut.painScore, 0, "painScore should default to 0")
    }

    func testInitialState_HasPainIsFalse() {
        XCTAssertFalse(sut.hasPain, "hasPain should be false initially")
    }

    func testInitialState_PainLocationsIsEmpty() {
        XCTAssertTrue(sut.painLocations.isEmpty, "painLocations should be empty initially")
    }

    func testInitialState_FreeTextIsEmpty() {
        XCTAssertEqual(sut.freeText, "", "freeText should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ShowErrorIsFalse() {
        XCTAssertFalse(sut.showError, "showError should be false initially")
    }

    func testInitialState_ErrorMessageIsEmpty() {
        XCTAssertEqual(sut.errorMessage, "", "errorMessage should be empty initially")
    }

    func testInitialState_ShowSuccessIsFalse() {
        XCTAssertFalse(sut.showSuccess, "showSuccess should be false initially")
    }

    func testInitialState_HasCheckedInTodayIsFalse() {
        XCTAssertFalse(sut.hasCheckedInToday, "hasCheckedInToday should be false initially")
    }

    func testInitialState_EstimatedReadinessIsDefault() {
        XCTAssertEqual(sut.estimatedReadiness, 50.0, "estimatedReadiness should start at 50.0")
    }

    func testInitialState_StreakIsNil() {
        XCTAssertNil(sut.streak, "streak should be nil initially")
    }

    func testInitialState_SavedCheckInIsNil() {
        XCTAssertNil(sut.savedCheckIn, "savedCheckIn should be nil initially")
    }

    func testInitialState_CompletionTimeSecondsIsZero() {
        XCTAssertEqual(sut.completionTimeSeconds, 0.0, "completionTimeSeconds should be 0 initially")
    }

    // MARK: - Computed Property Tests - currentStepIndex

    func testCurrentStepIndex_SleepIsZero() {
        sut.currentStep = .sleep
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func testCurrentStepIndex_SorenessIsOne() {
        sut.currentStep = .soreness
        XCTAssertEqual(sut.currentStepIndex, 1)
    }

    func testCurrentStepIndex_EnergyIsTwo() {
        sut.currentStep = .energy
        XCTAssertEqual(sut.currentStepIndex, 2)
    }

    func testCurrentStepIndex_StressIsThree() {
        sut.currentStep = .stress
        XCTAssertEqual(sut.currentStepIndex, 3)
    }

    func testCurrentStepIndex_PainIsFour() {
        sut.currentStep = .pain
        XCTAssertEqual(sut.currentStepIndex, 4)
    }

    func testCurrentStepIndex_NotesIsFive() {
        sut.currentStep = .notes
        XCTAssertEqual(sut.currentStepIndex, 5)
    }

    // MARK: - Computed Property Tests - totalSteps

    func testTotalSteps_EqualsCheckInStepCount() {
        XCTAssertEqual(sut.totalSteps, CheckInStep.allCases.count, "totalSteps should equal CheckInStep.allCases.count")
        XCTAssertEqual(sut.totalSteps, 6, "totalSteps should be 6")
    }

    // MARK: - Computed Property Tests - progress

    func testProgress_AtFirstStep_IsZero() {
        sut.currentStep = .sleep
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.001, "progress should be 0.0 at first step")
    }

    func testProgress_AtLastStep_IsOne() {
        sut.currentStep = .notes
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001, "progress should be 1.0 at last step")
    }

    func testProgress_AtMiddleStep_IsCorrect() {
        sut.currentStep = .energy // index 2 out of 5 (0-based max)
        let expected = 2.0 / 5.0
        XCTAssertEqual(sut.progress, expected, accuracy: 0.001, "progress at energy step should be 2/5")
    }

    // MARK: - Computed Property Tests - isFirstStep / isLastStep

    func testIsFirstStep_WhenSleep_ReturnsTrue() {
        sut.currentStep = .sleep
        XCTAssertTrue(sut.isFirstStep, "isFirstStep should be true for .sleep")
    }

    func testIsFirstStep_WhenNotSleep_ReturnsFalse() {
        sut.currentStep = .soreness
        XCTAssertFalse(sut.isFirstStep, "isFirstStep should be false for .soreness")
    }

    func testIsLastStep_WhenNotes_ReturnsTrue() {
        sut.currentStep = .notes
        XCTAssertTrue(sut.isLastStep, "isLastStep should be true for .notes")
    }

    func testIsLastStep_WhenNotNotes_ReturnsFalse() {
        sut.currentStep = .pain
        XCTAssertFalse(sut.isLastStep, "isLastStep should be false for .pain")
    }

    // MARK: - Computed Property Tests - canProceed

    func testCanProceed_SleepStep_ValidQuality_ReturnsTrue() {
        sut.currentStep = .sleep
        sut.sleepQuality = 3
        XCTAssertTrue(sut.canProceed, "canProceed should be true with valid sleep quality")
    }

    func testCanProceed_SleepStep_QualityAtLowerBound() {
        sut.currentStep = .sleep
        sut.sleepQuality = 1
        XCTAssertTrue(sut.canProceed, "canProceed should be true with sleep quality = 1")
    }

    func testCanProceed_SleepStep_QualityAtUpperBound() {
        sut.currentStep = .sleep
        sut.sleepQuality = 5
        XCTAssertTrue(sut.canProceed, "canProceed should be true with sleep quality = 5")
    }

    func testCanProceed_SorenessStep_ValidValue_ReturnsTrue() {
        sut.currentStep = .soreness
        sut.soreness = 5
        XCTAssertTrue(sut.canProceed, "canProceed should be true with valid soreness")
    }

    func testCanProceed_EnergyStep_ValidValue_ReturnsTrue() {
        sut.currentStep = .energy
        sut.energy = 7
        XCTAssertTrue(sut.canProceed, "canProceed should be true with valid energy")
    }

    func testCanProceed_StressStep_ValidValue_ReturnsTrue() {
        sut.currentStep = .stress
        sut.stress = 3
        XCTAssertTrue(sut.canProceed, "canProceed should be true with valid stress")
    }

    func testCanProceed_PainStep_AlwaysReturnsTrue() {
        sut.currentStep = .pain
        XCTAssertTrue(sut.canProceed, "canProceed should always be true for pain (optional step)")
    }

    func testCanProceed_NotesStep_AlwaysReturnsTrue() {
        sut.currentStep = .notes
        XCTAssertTrue(sut.canProceed, "canProceed should always be true for notes (optional step)")
    }

    // MARK: - Computed Property Tests - canSubmit

    func testCanSubmit_WithDefaultValues_ReturnsTrue() {
        // Default: sleepQuality=3, soreness=1, energy=5, stress=1, mood=3
        XCTAssertTrue(sut.canSubmit, "canSubmit should be true with default values")
    }

    func testCanSubmit_WithAllMaxValues_ReturnsTrue() {
        sut.sleepQuality = 5
        sut.soreness = 10
        sut.energy = 10
        sut.stress = 10
        sut.mood = 5
        XCTAssertTrue(sut.canSubmit, "canSubmit should be true with all max values")
    }

    func testCanSubmit_WithAllMinValues_ReturnsTrue() {
        sut.sleepQuality = 1
        sut.soreness = 1
        sut.energy = 1
        sut.stress = 1
        sut.mood = 1
        XCTAssertTrue(sut.canSubmit, "canSubmit should be true with all min values")
    }

    func testCanSubmit_WithInvalidSleepQuality_ReturnsFalse() {
        sut.sleepQuality = 0
        XCTAssertFalse(sut.canSubmit, "canSubmit should be false with sleep quality = 0")
    }

    func testCanSubmit_WithInvalidSoreness_ReturnsFalse() {
        sut.soreness = 0
        XCTAssertFalse(sut.canSubmit, "canSubmit should be false with soreness = 0")
    }

    func testCanSubmit_WithInvalidEnergy_ReturnsFalse() {
        sut.energy = 0
        XCTAssertFalse(sut.canSubmit, "canSubmit should be false with energy = 0")
    }

    func testCanSubmit_WithInvalidStress_ReturnsFalse() {
        sut.stress = 0
        XCTAssertFalse(sut.canSubmit, "canSubmit should be false with stress = 0")
    }

    func testCanSubmit_WithInvalidMood_ReturnsFalse() {
        sut.mood = 0
        XCTAssertFalse(sut.canSubmit, "canSubmit should be false with mood = 0")
    }

    // MARK: - Computed Property Tests - readinessBand

    func testReadinessBand_HighReadiness_ReturnsGreen() {
        sut.estimatedReadiness = 85.0
        XCTAssertEqual(sut.readinessBand, .green, "readinessBand should be .green at 85")
    }

    func testReadinessBand_AtEightyThreshold_ReturnsGreen() {
        sut.estimatedReadiness = 80.0
        XCTAssertEqual(sut.readinessBand, .green, "readinessBand should be .green at exactly 80")
    }

    func testReadinessBand_MediumHighReadiness_ReturnsYellow() {
        sut.estimatedReadiness = 70.0
        XCTAssertEqual(sut.readinessBand, .yellow, "readinessBand should be .yellow at 70")
    }

    func testReadinessBand_AtSixtyThreshold_ReturnsYellow() {
        sut.estimatedReadiness = 60.0
        XCTAssertEqual(sut.readinessBand, .yellow, "readinessBand should be .yellow at exactly 60")
    }

    func testReadinessBand_MediumReadiness_ReturnsOrange() {
        sut.estimatedReadiness = 50.0
        XCTAssertEqual(sut.readinessBand, .orange, "readinessBand should be .orange at 50")
    }

    func testReadinessBand_AtFortyThreshold_ReturnsOrange() {
        sut.estimatedReadiness = 40.0
        XCTAssertEqual(sut.readinessBand, .orange, "readinessBand should be .orange at exactly 40")
    }

    func testReadinessBand_LowReadiness_ReturnsRed() {
        sut.estimatedReadiness = 30.0
        XCTAssertEqual(sut.readinessBand, .red, "readinessBand should be .red at 30")
    }

    func testReadinessBand_ZeroReadiness_ReturnsRed() {
        sut.estimatedReadiness = 0.0
        XCTAssertEqual(sut.readinessBand, .red, "readinessBand should be .red at 0")
    }

    // MARK: - Computed Property Tests - readinessDescription

    func testReadinessDescription_Green() {
        sut.estimatedReadiness = 90.0
        XCTAssertEqual(sut.readinessDescription, "Ready to Train")
    }

    func testReadinessDescription_Yellow() {
        sut.estimatedReadiness = 65.0
        XCTAssertEqual(sut.readinessDescription, "Train with Caution")
    }

    func testReadinessDescription_Orange() {
        sut.estimatedReadiness = 45.0
        XCTAssertEqual(sut.readinessDescription, "Reduced Intensity")
    }

    func testReadinessDescription_Red() {
        sut.estimatedReadiness = 20.0
        XCTAssertEqual(sut.readinessDescription, "Recovery Day")
    }

    // MARK: - Flow Control Tests - startCheckIn

    func testStartCheckIn_SetsFlowStateToInProgress() {
        sut.startCheckIn()
        XCTAssertEqual(sut.flowState, .inProgress(step: .sleep), "flowState should be .inProgress(.sleep) after start")
    }

    func testStartCheckIn_SetsCurrentStepToSleep() {
        sut.currentStep = .energy // change from default
        sut.startCheckIn()
        XCTAssertEqual(sut.currentStep, .sleep, "currentStep should be reset to .sleep after start")
    }

    // MARK: - Flow Control Tests - nextStep

    func testNextStep_FromSleep_MovesToSoreness() {
        sut.startCheckIn()
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .soreness, "nextStep from sleep should go to soreness")
    }

    func testNextStep_FromSoreness_MovesToEnergy() {
        sut.startCheckIn()
        sut.currentStep = .soreness
        sut.flowState = .inProgress(step: .soreness)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .energy, "nextStep from soreness should go to energy")
    }

    func testNextStep_FromEnergy_MovesToStress() {
        sut.startCheckIn()
        sut.currentStep = .energy
        sut.flowState = .inProgress(step: .energy)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .stress, "nextStep from energy should go to stress")
    }

    func testNextStep_FromStress_MovesToPain() {
        sut.startCheckIn()
        sut.currentStep = .stress
        sut.flowState = .inProgress(step: .stress)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .pain, "nextStep from stress should go to pain")
    }

    func testNextStep_FromPain_MovesToNotes() {
        sut.startCheckIn()
        sut.currentStep = .pain
        sut.flowState = .inProgress(step: .pain)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .notes, "nextStep from pain should go to notes")
    }

    func testNextStep_FromNotes_GoesToReviewing() {
        sut.startCheckIn()
        sut.currentStep = .notes
        sut.flowState = .inProgress(step: .notes)
        sut.nextStep()
        XCTAssertEqual(sut.flowState, .reviewing, "nextStep from notes (last) should go to .reviewing")
    }

    func testNextStep_UpdatesFlowState() {
        sut.startCheckIn()
        sut.nextStep()
        XCTAssertEqual(sut.flowState, .inProgress(step: .soreness), "flowState should update to .inProgress(.soreness)")
    }

    // MARK: - Flow Control Tests - previousStep

    func testPreviousStep_FromSoreness_MovesToSleep() {
        sut.startCheckIn()
        sut.currentStep = .soreness
        sut.flowState = .inProgress(step: .soreness)
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .sleep, "previousStep from soreness should go to sleep")
    }

    func testPreviousStep_FromSleep_StaysAtSleep() {
        sut.startCheckIn()
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .sleep, "previousStep from sleep should stay at sleep")
    }

    func testPreviousStep_FromNotes_MovesToPain() {
        sut.startCheckIn()
        sut.currentStep = .notes
        sut.flowState = .inProgress(step: .notes)
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .pain, "previousStep from notes should go to pain")
    }

    // MARK: - Flow Control Tests - skipStep

    func testSkipStep_OnOptionalStep_Proceeds() {
        sut.startCheckIn()
        sut.currentStep = .pain
        sut.flowState = .inProgress(step: .pain)
        sut.skipStep()
        XCTAssertEqual(sut.currentStep, .notes, "skipStep on pain (optional) should advance to notes")
    }

    func testSkipStep_OnRequiredStep_DoesNothing() {
        sut.startCheckIn()
        sut.currentStep = .sleep
        sut.flowState = .inProgress(step: .sleep)
        sut.skipStep()
        XCTAssertEqual(sut.currentStep, .sleep, "skipStep on sleep (required) should not advance")
    }

    // MARK: - Flow Control Tests - goToStep

    func testGoToStep_JumpsToSpecifiedStep() {
        sut.startCheckIn()
        sut.goToStep(.stress)
        XCTAssertEqual(sut.currentStep, .stress, "goToStep should jump to the specified step")
        XCTAssertEqual(sut.flowState, .inProgress(step: .stress), "flowState should update to the specified step")
    }

    // MARK: - Form Update Tests - updateSleepQuality

    func testUpdateSleepQuality_ClampsToMinimum() {
        sut.updateSleepQuality(0)
        XCTAssertEqual(sut.sleepQuality, 1, "sleepQuality should clamp to 1 minimum")
    }

    func testUpdateSleepQuality_ClampsToMaximum() {
        sut.updateSleepQuality(10)
        XCTAssertEqual(sut.sleepQuality, 5, "sleepQuality should clamp to 5 maximum")
    }

    func testUpdateSleepQuality_AcceptsValidValue() {
        sut.updateSleepQuality(4)
        XCTAssertEqual(sut.sleepQuality, 4, "sleepQuality should accept valid value 4")
    }

    func testUpdateSleepQuality_UpdatesReadiness() {
        let initialReadiness = sut.estimatedReadiness
        sut.updateSleepQuality(5)
        XCTAssertNotEqual(sut.estimatedReadiness, initialReadiness, "updating sleep quality should change readiness")
    }

    // MARK: - Form Update Tests - updateSoreness

    func testUpdateSoreness_ClampsToMinimum() {
        sut.updateSoreness(0)
        XCTAssertEqual(sut.soreness, 1, "soreness should clamp to 1 minimum")
    }

    func testUpdateSoreness_ClampsToMaximum() {
        sut.updateSoreness(15)
        XCTAssertEqual(sut.soreness, 10, "soreness should clamp to 10 maximum")
    }

    func testUpdateSoreness_AcceptsValidValue() {
        sut.updateSoreness(7)
        XCTAssertEqual(sut.soreness, 7, "soreness should accept valid value 7")
    }

    // MARK: - Form Update Tests - updateEnergy

    func testUpdateEnergy_ClampsToMinimum() {
        sut.updateEnergy(0)
        XCTAssertEqual(sut.energy, 1, "energy should clamp to 1 minimum")
    }

    func testUpdateEnergy_ClampsToMaximum() {
        sut.updateEnergy(15)
        XCTAssertEqual(sut.energy, 10, "energy should clamp to 10 maximum")
    }

    func testUpdateEnergy_AcceptsValidValue() {
        sut.updateEnergy(8)
        XCTAssertEqual(sut.energy, 8, "energy should accept valid value 8")
    }

    // MARK: - Form Update Tests - updateStress

    func testUpdateStress_ClampsToMinimum() {
        sut.updateStress(0)
        XCTAssertEqual(sut.stress, 1, "stress should clamp to 1 minimum")
    }

    func testUpdateStress_ClampsToMaximum() {
        sut.updateStress(15)
        XCTAssertEqual(sut.stress, 10, "stress should clamp to 10 maximum")
    }

    func testUpdateStress_AcceptsValidValue() {
        sut.updateStress(6)
        XCTAssertEqual(sut.stress, 6, "stress should accept valid value 6")
    }

    // MARK: - Form Update Tests - updateMood

    func testUpdateMood_ClampsToMinimum() {
        sut.updateMood(0)
        XCTAssertEqual(sut.mood, 1, "mood should clamp to 1 minimum")
    }

    func testUpdateMood_ClampsToMaximum() {
        sut.updateMood(10)
        XCTAssertEqual(sut.mood, 5, "mood should clamp to 5 maximum")
    }

    func testUpdateMood_AcceptsValidValue() {
        sut.updateMood(4)
        XCTAssertEqual(sut.mood, 4, "mood should accept valid value 4")
    }

    // MARK: - Form Update Tests - updatePainScore

    func testUpdatePainScore_ClampsToMinimum() {
        sut.updatePainScore(-1)
        XCTAssertEqual(sut.painScore, 0, "painScore should clamp to 0 minimum")
    }

    func testUpdatePainScore_ClampsToMaximum() {
        sut.updatePainScore(15)
        XCTAssertEqual(sut.painScore, 10, "painScore should clamp to 10 maximum")
    }

    func testUpdatePainScore_SetsHasPainTrue_WhenPositive() {
        sut.updatePainScore(5)
        XCTAssertTrue(sut.hasPain, "hasPain should be true when painScore > 0")
    }

    func testUpdatePainScore_SetsHasPainFalse_WhenZero() {
        sut.updatePainScore(5)
        sut.updatePainScore(0)
        XCTAssertFalse(sut.hasPain, "hasPain should be false when painScore = 0")
    }

    // MARK: - Form Update Tests - toggleSorenessLocation

    func testToggleSorenessLocation_AddsLocation() {
        sut.toggleSorenessLocation(.shoulder)
        XCTAssertTrue(sut.sorenessLocations.contains(.shoulder), "should add shoulder to soreness locations")
    }

    func testToggleSorenessLocation_RemovesExistingLocation() {
        sut.toggleSorenessLocation(.shoulder)
        sut.toggleSorenessLocation(.shoulder)
        XCTAssertFalse(sut.sorenessLocations.contains(.shoulder), "should remove shoulder from soreness locations")
    }

    func testToggleSorenessLocation_MultipleLocations() {
        sut.toggleSorenessLocation(.shoulder)
        sut.toggleSorenessLocation(.knee)
        sut.toggleSorenessLocation(.lowerBack)
        XCTAssertEqual(sut.sorenessLocations.count, 3, "should have 3 soreness locations")
    }

    // MARK: - Form Update Tests - togglePainLocation

    func testTogglePainLocation_AddsLocation() {
        sut.togglePainLocation(.knee)
        XCTAssertTrue(sut.painLocations.contains(.knee), "should add knee to pain locations")
    }

    func testTogglePainLocation_RemovesExistingLocation() {
        sut.togglePainLocation(.knee)
        sut.togglePainLocation(.knee)
        XCTAssertFalse(sut.painLocations.contains(.knee), "should remove knee from pain locations")
    }

    // MARK: - Readiness Calculation Tests

    func testReadiness_HighSleepHighEnergy_HighScore() {
        sut.updateSleepQuality(5)
        sut.updateEnergy(10)
        sut.updateSoreness(1) // low soreness = good
        sut.updateStress(1)   // low stress = good
        sut.updateMood(5)
        // Expected: (5/5)*30 + (10/10)*25 + (10/10)*20 + (10/10)*15 + (5/5)*10 = 30+25+20+15+10 = 100
        XCTAssertEqual(sut.estimatedReadiness, 100.0, accuracy: 0.1, "perfect inputs should yield 100")
    }

    func testReadiness_LowSleepLowEnergy_LowScore() {
        sut.updateSleepQuality(1)
        sut.updateEnergy(1)
        sut.updateSoreness(10) // extreme soreness
        sut.updateStress(10)   // extreme stress
        sut.updateMood(1)
        // Expected: (1/5)*30 + (1/10)*25 + (1/10)*20 + (1/10)*15 + (1/5)*10 = 6+2.5+2+1.5+2 = 14
        XCTAssertEqual(sut.estimatedReadiness, 14.0, accuracy: 0.1, "worst inputs should yield 14")
    }

    func testReadiness_PainPenalty_ReducesScore() {
        sut.updateSleepQuality(5)
        sut.updateEnergy(10)
        sut.updateSoreness(1)
        sut.updateStress(1)
        sut.updateMood(5)
        let scoreWithoutPain = sut.estimatedReadiness

        sut.updatePainScore(5)
        let scoreWithPain = sut.estimatedReadiness

        XCTAssertLessThan(scoreWithPain, scoreWithoutPain, "pain should reduce readiness score")
        XCTAssertEqual(scoreWithPain, scoreWithoutPain - 10.0, accuracy: 0.1, "pain 5 should reduce score by 10")
    }

    func testReadiness_MaxPainPenalty_ClampsToZero() {
        sut.updateSleepQuality(1)
        sut.updateEnergy(1)
        sut.updateSoreness(10)
        sut.updateStress(10)
        sut.updateMood(1)
        sut.updatePainScore(10) // -20 penalty
        // base score = 14, minus 20 = -6, clamped to 0
        XCTAssertEqual(sut.estimatedReadiness, 0.0, accuracy: 0.1, "readiness should not go below 0")
    }

    func testReadiness_ClampedAtHundred() {
        sut.estimatedReadiness = 150.0
        // readinessBand should still work with overflows
        XCTAssertEqual(sut.readinessBand, .green, "readinessBand should handle values above 100")
    }

    // MARK: - Reset Tests

    func testReset_RestoresAllDefaults() {
        // Change everything
        sut.startCheckIn()
        sut.updateSleepQuality(5)
        sut.updateSoreness(8)
        sut.updateEnergy(9)
        sut.updateStress(7)
        sut.updateMood(5)
        sut.updatePainScore(3)
        sut.toggleSorenessLocation(.shoulder)
        sut.togglePainLocation(.knee)
        sut.freeText = "Test note"
        sut.showError = true
        sut.showSuccess = true
        sut.errorMessage = "Some error"

        // Reset
        sut.reset()

        // Verify all defaults
        XCTAssertEqual(sut.flowState, .notStarted)
        XCTAssertEqual(sut.currentStep, .sleep)
        XCTAssertEqual(sut.sleepQuality, 3)
        XCTAssertEqual(sut.sleepHours, 7.0)
        XCTAssertFalse(sut.includeSleepHours)
        XCTAssertEqual(sut.soreness, 1)
        XCTAssertTrue(sut.sorenessLocations.isEmpty)
        XCTAssertEqual(sut.energy, 5)
        XCTAssertEqual(sut.stress, 1)
        XCTAssertEqual(sut.mood, 3)
        XCTAssertEqual(sut.painScore, 0)
        XCTAssertFalse(sut.hasPain)
        XCTAssertTrue(sut.painLocations.isEmpty)
        XCTAssertEqual(sut.freeText, "")
        XCTAssertFalse(sut.showError)
        XCTAssertFalse(sut.showSuccess)
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertNil(sut.savedCheckIn)
        XCTAssertEqual(sut.completionTimeSeconds, 0)
    }

    func testReset_RecalculatesReadiness() {
        sut.updateSleepQuality(5)
        sut.updateEnergy(10)
        sut.reset()
        // After reset with defaults (sleep=3, energy=5, soreness=1, stress=1, mood=3):
        // (3/5)*30 + (5/10)*25 + (10/10)*20 + (10/10)*15 + (3/5)*10 = 18+12.5+20+15+6 = 71.5
        XCTAssertEqual(sut.estimatedReadiness, 71.5, accuracy: 0.1, "readiness should be recalculated after reset")
    }

    // MARK: - CheckInStep Tests

    func testCheckInStep_Next_ReturnsCorrectStep() {
        XCTAssertEqual(CheckInStep.sleep.next, .soreness)
        XCTAssertEqual(CheckInStep.soreness.next, .energy)
        XCTAssertEqual(CheckInStep.energy.next, .stress)
        XCTAssertEqual(CheckInStep.stress.next, .pain)
        XCTAssertEqual(CheckInStep.pain.next, .notes)
        XCTAssertNil(CheckInStep.notes.next, "last step should return nil for next")
    }

    func testCheckInStep_Previous_ReturnsCorrectStep() {
        XCTAssertNil(CheckInStep.sleep.previous, "first step should return nil for previous")
        XCTAssertEqual(CheckInStep.soreness.previous, .sleep)
        XCTAssertEqual(CheckInStep.energy.previous, .soreness)
        XCTAssertEqual(CheckInStep.stress.previous, .energy)
        XCTAssertEqual(CheckInStep.pain.previous, .stress)
        XCTAssertEqual(CheckInStep.notes.previous, .pain)
    }

    func testCheckInStep_IsOptional() {
        XCTAssertFalse(CheckInStep.sleep.isOptional, "sleep should not be optional")
        XCTAssertFalse(CheckInStep.soreness.isOptional, "soreness should not be optional")
        XCTAssertFalse(CheckInStep.energy.isOptional, "energy should not be optional")
        XCTAssertFalse(CheckInStep.stress.isOptional, "stress should not be optional")
        XCTAssertTrue(CheckInStep.pain.isOptional, "pain should be optional")
        XCTAssertTrue(CheckInStep.notes.isOptional, "notes should be optional")
    }

    func testCheckInStep_Titles() {
        XCTAssertEqual(CheckInStep.sleep.title, "Sleep")
        XCTAssertEqual(CheckInStep.soreness.title, "Soreness")
        XCTAssertEqual(CheckInStep.energy.title, "Energy")
        XCTAssertEqual(CheckInStep.stress.title, "Stress")
        XCTAssertEqual(CheckInStep.pain.title, "Pain")
        XCTAssertEqual(CheckInStep.notes.title, "Notes")
    }

    func testCheckInStep_Icons() {
        XCTAssertEqual(CheckInStep.sleep.icon, "bed.double.fill")
        XCTAssertEqual(CheckInStep.soreness.icon, "figure.walk")
        XCTAssertEqual(CheckInStep.energy.icon, "bolt.fill")
        XCTAssertEqual(CheckInStep.stress.icon, "brain.head.profile")
        XCTAssertEqual(CheckInStep.pain.icon, "bandage.fill")
        XCTAssertEqual(CheckInStep.notes.icon, "note.text")
    }

    // MARK: - CheckInFlowState Equality Tests

    func testCheckInFlowState_Equality() {
        XCTAssertEqual(CheckInFlowState.notStarted, CheckInFlowState.notStarted)
        XCTAssertEqual(CheckInFlowState.reviewing, CheckInFlowState.reviewing)
        XCTAssertEqual(CheckInFlowState.submitting, CheckInFlowState.submitting)
        XCTAssertEqual(CheckInFlowState.completed, CheckInFlowState.completed)
        XCTAssertEqual(CheckInFlowState.inProgress(step: .sleep), CheckInFlowState.inProgress(step: .sleep))
        XCTAssertNotEqual(CheckInFlowState.inProgress(step: .sleep), CheckInFlowState.inProgress(step: .energy))
        XCTAssertEqual(CheckInFlowState.error("test"), CheckInFlowState.error("test"))
        XCTAssertNotEqual(CheckInFlowState.error("a"), CheckInFlowState.error("b"))
    }

    // MARK: - Edge Case Tests

    func testUpdateSameValue_DoesNotTriggerChange() {
        // Set sleep to 3 (same as default)
        sut.sleepQuality = 3
        let readinessBefore = sut.estimatedReadiness
        sut.updateSleepQuality(3) // same value
        XCTAssertEqual(sut.estimatedReadiness, readinessBefore, "same value should not trigger readiness change")
    }

    func testCompleteFlowNavigation_FromStartToReview() {
        sut.startCheckIn()
        XCTAssertEqual(sut.currentStep, .sleep)

        sut.nextStep() // sleep -> soreness
        XCTAssertEqual(sut.currentStep, .soreness)

        sut.nextStep() // soreness -> energy
        XCTAssertEqual(sut.currentStep, .energy)

        sut.nextStep() // energy -> stress
        XCTAssertEqual(sut.currentStep, .stress)

        sut.nextStep() // stress -> pain
        XCTAssertEqual(sut.currentStep, .pain)

        sut.nextStep() // pain -> notes
        XCTAssertEqual(sut.currentStep, .notes)

        sut.nextStep() // notes -> reviewing
        XCTAssertEqual(sut.flowState, .reviewing)
    }
}
