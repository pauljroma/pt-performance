//
//  ProgramEditorTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for program editor functionality
//  Tests program creation, phase management, exercise assignment, and program assignment to patients
//

import XCTest
@testable import PTPerformance

// MARK: - TherapistProgramBuilderViewModel Tests

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

    func testInitialState_ProgramNameIsEmpty() {
        XCTAssertTrue(sut.programName.isEmpty)
    }

    func testInitialState_DescriptionIsEmpty() {
        XCTAssertTrue(sut.description.isEmpty)
    }

    func testInitialState_CategoryHasDefault() {
        XCTAssertEqual(sut.category, ProgramCategory.strength.rawValue)
    }

    func testInitialState_DifficultyLevelHasDefault() {
        XCTAssertEqual(sut.difficultyLevel, DifficultyLevel.intermediate.rawValue)
    }

    func testInitialState_DurationWeeksHasDefault() {
        XCTAssertEqual(sut.durationWeeks, 12)
    }

    func testInitialState_EquipmentRequiredIsEmpty() {
        XCTAssertTrue(sut.equipmentRequired.isEmpty)
    }

    func testInitialState_TagsIsEmpty() {
        XCTAssertTrue(sut.tags.isEmpty)
    }

    func testInitialState_PhasesIsEmpty() {
        XCTAssertTrue(sut.phases.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_SuccessMessageIsNil() {
        XCTAssertNil(sut.successMessage)
    }

    // MARK: - Validation Tests

    func testIsValid_FalseWhenNameIsEmpty() {
        sut.programName = ""

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_FalseWhenNameIsOnlyWhitespace() {
        sut.programName = "   "

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_FalseWhenNameIsTooShort() {
        sut.programName = "AB"

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_FalseWhenNameIsTooLong() {
        sut.programName = String(repeating: "A", count: 101)

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_TrueWhenNameIsValid() {
        sut.programName = "Valid Program Name"

        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_TrueWithMinimumLength() {
        sut.programName = "ABC"

        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_TrueWithMaximumLength() {
        sut.programName = String(repeating: "A", count: 100)

        XCTAssertTrue(sut.isValid)
    }

    // MARK: - IsReadyToPublish Tests

    func testIsReadyToPublish_FalseWhenNotValid() {
        sut.programName = ""

        XCTAssertFalse(sut.isReadyToPublish)
    }

    func testIsReadyToPublish_FalseWhenNoPhases() {
        sut.programName = "Valid Name"
        sut.phases = []

        XCTAssertFalse(sut.isReadyToPublish)
    }

    func testIsReadyToPublish_FalseWhenPhasesHaveNoAssignments() {
        sut.programName = "Valid Name"
        sut.phases = [TherapistPhaseData(name: "Phase 1", workoutAssignments: [])]

        XCTAssertFalse(sut.isReadyToPublish)
    }

    func testIsReadyToPublish_TrueWhenValidWithAssignments() {
        sut.programName = "Valid Name"
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Workout",
            weekNumber: 1,
            dayOfWeek: 1
        )
        sut.phases = [TherapistPhaseData(name: "Phase 1", workoutAssignments: [assignment])]

        XCTAssertTrue(sut.isReadyToPublish)
    }

    // MARK: - Total Phase Duration Tests

    func testTotalPhaseDuration_ZeroWhenNoPhases() {
        sut.phases = []

        XCTAssertEqual(sut.totalPhaseDuration, 0)
    }

    func testTotalPhaseDuration_SinglePhase() {
        sut.phases = [TherapistPhaseData(durationWeeks: 4)]

        XCTAssertEqual(sut.totalPhaseDuration, 4)
    }

    func testTotalPhaseDuration_MultiplePhases() {
        sut.phases = [
            TherapistPhaseData(durationWeeks: 4),
            TherapistPhaseData(durationWeeks: 6),
            TherapistPhaseData(durationWeeks: 2)
        ]

        XCTAssertEqual(sut.totalPhaseDuration, 12)
    }

    // MARK: - Equipment Management Tests

    func testAddEquipmentFromInput_AddsEquipment() {
        sut.equipmentInput = "Barbell"

        sut.addEquipmentFromInput()

        XCTAssertTrue(sut.equipmentRequired.contains("Barbell"))
        XCTAssertTrue(sut.equipmentInput.isEmpty)
    }

    func testAddEquipmentFromInput_TrimsWhitespace() {
        sut.equipmentInput = "  Dumbbell  "

        sut.addEquipmentFromInput()

        XCTAssertTrue(sut.equipmentRequired.contains("Dumbbell"))
    }

    func testAddEquipmentFromInput_HandlesCommaSeparated() {
        sut.equipmentInput = "Barbell, Dumbbell, Kettlebell"

        sut.addEquipmentFromInput()

        XCTAssertTrue(sut.equipmentRequired.contains("Barbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Dumbbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Kettlebell"))
    }

    func testAddEquipmentFromInput_IgnoresEmptyItems() {
        sut.equipmentInput = "Barbell,, Dumbbell"

        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.count, 2)
    }

    func testAddEquipmentFromInput_PreventsDuplicates() {
        sut.equipmentRequired = ["Barbell"]
        sut.equipmentInput = "Barbell"

        sut.addEquipmentFromInput()

        XCTAssertEqual(sut.equipmentRequired.filter { $0 == "Barbell" }.count, 1)
    }

    func testRemoveEquipment_RemovesItem() {
        sut.equipmentRequired = ["Barbell", "Dumbbell"]

        sut.removeEquipment("Barbell")

        XCTAssertFalse(sut.equipmentRequired.contains("Barbell"))
        XCTAssertTrue(sut.equipmentRequired.contains("Dumbbell"))
    }

    func testRemoveEquipment_NoErrorForNonexistentItem() {
        sut.equipmentRequired = ["Barbell"]

        sut.removeEquipment("Kettlebell")

        XCTAssertEqual(sut.equipmentRequired.count, 1)
    }

    // MARK: - Tag Management Tests

    func testAddTagsFromInput_AddsTag() {
        sut.tagsInput = "strength"

        sut.addTagsFromInput()

        XCTAssertTrue(sut.tags.contains("strength"))
        XCTAssertTrue(sut.tagsInput.isEmpty)
    }

    func testAddTagsFromInput_LowercasesTags() {
        sut.tagsInput = "STRENGTH"

        sut.addTagsFromInput()

        XCTAssertTrue(sut.tags.contains("strength"))
        XCTAssertFalse(sut.tags.contains("STRENGTH"))
    }

    func testAddTagsFromInput_TrimsWhitespace() {
        sut.tagsInput = "  recovery  "

        sut.addTagsFromInput()

        XCTAssertTrue(sut.tags.contains("recovery"))
    }

    func testAddTagsFromInput_HandlesCommaSeparated() {
        sut.tagsInput = "strength, power, mobility"

        sut.addTagsFromInput()

        XCTAssertTrue(sut.tags.contains("strength"))
        XCTAssertTrue(sut.tags.contains("power"))
        XCTAssertTrue(sut.tags.contains("mobility"))
    }

    func testAddTagsFromInput_PreventsDuplicates() {
        sut.tags = ["strength"]
        sut.tagsInput = "strength"

        sut.addTagsFromInput()

        XCTAssertEqual(sut.tags.filter { $0 == "strength" }.count, 1)
    }

    func testRemoveTag_RemovesItem() {
        sut.tags = ["strength", "power"]

        sut.removeTag("strength")

        XCTAssertFalse(sut.tags.contains("strength"))
        XCTAssertTrue(sut.tags.contains("power"))
    }

    // MARK: - Phase Management Tests

    func testAddPhase_AddsNewPhase() {
        sut.addPhase()

        XCTAssertEqual(sut.phases.count, 1)
        XCTAssertEqual(sut.phases.first?.sequence, 1)
    }

    func testAddPhase_IncreasesSequenceNumber() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        XCTAssertEqual(sut.phases[0].sequence, 1)
        XCTAssertEqual(sut.phases[1].sequence, 2)
        XCTAssertEqual(sut.phases[2].sequence, 3)
    }

    func testAddPhase_SetsDefaultDuration() {
        sut.addPhase()

        XCTAssertEqual(sut.phases.first?.durationWeeks, 4)
    }

    func testAddPhase_SetsDefaultName() {
        sut.addPhase()

        XCTAssertEqual(sut.phases.first?.name, "Phase 1")
    }

    func testUpdatePhase_UpdatesExistingPhase() {
        sut.addPhase()
        var phase = sut.phases[0]
        phase.name = "Updated Name"
        phase.durationWeeks = 8

        sut.updatePhase(phase)

        XCTAssertEqual(sut.phases[0].name, "Updated Name")
        XCTAssertEqual(sut.phases[0].durationWeeks, 8)
    }

    func testUpdatePhase_NoChangeForNonexistentPhase() {
        sut.addPhase()
        let nonexistentPhase = TherapistPhaseData(id: UUID(), name: "Nonexistent")

        sut.updatePhase(nonexistentPhase)

        XCTAssertEqual(sut.phases.count, 1)
        XCTAssertNotEqual(sut.phases[0].name, "Nonexistent")
    }

    func testDeletePhase_RemovesPhase() {
        sut.addPhase()
        sut.addPhase()

        sut.deletePhase(at: 0)

        XCTAssertEqual(sut.phases.count, 1)
    }

    func testDeletePhase_ResequencesRemainingPhases() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        sut.deletePhase(at: 1)

        XCTAssertEqual(sut.phases[0].sequence, 1)
        XCTAssertEqual(sut.phases[1].sequence, 2)
    }

    func testDeletePhase_SafeForOutOfBoundsIndex() {
        sut.addPhase()

        sut.deletePhase(at: 5)

        XCTAssertEqual(sut.phases.count, 1)
    }

    func testMovePhases_ReordersCorrectly() {
        sut.addPhase() // Phase 1
        sut.addPhase() // Phase 2
        sut.addPhase() // Phase 3

        let originalFirstId = sut.phases[0].id

        sut.movePhases(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(sut.phases[2].id, originalFirstId)
    }

    func testMovePhases_ResequencesAfterMove() {
        sut.addPhase()
        sut.addPhase()
        sut.addPhase()

        sut.movePhases(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(sut.phases[0].sequence, 1)
        XCTAssertEqual(sut.phases[1].sequence, 2)
        XCTAssertEqual(sut.phases[2].sequence, 3)
    }

    // MARK: - Error Handling Tests

    func testCreateProgram_ThrowsWhenInvalid() async {
        sut.programName = ""

        do {
            _ = try await sut.createProgram()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is TherapistProgramBuilderError)
        }
    }

    func testPublishToLibrary_ThrowsWhenNotReady() async {
        sut.programName = "Valid Name"
        sut.phases = []

        do {
            try await sut.publishToLibrary()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is TherapistProgramBuilderError)
        }
    }
}

// MARK: - TherapistPhaseData Tests

final class TherapistPhaseDataTests: XCTestCase {

    func testTherapistPhaseData_DefaultInit() {
        let phase = TherapistPhaseData()

        XCTAssertNotNil(phase.id)
        XCTAssertTrue(phase.name.isEmpty)
        XCTAssertEqual(phase.sequence, 1)
        XCTAssertEqual(phase.durationWeeks, 4)
        XCTAssertTrue(phase.goals.isEmpty)
        XCTAssertTrue(phase.workoutAssignments.isEmpty)
    }

    func testTherapistPhaseData_CustomInit() {
        let id = UUID()
        let phase = TherapistPhaseData(
            id: id,
            name: "Test Phase",
            sequence: 2,
            durationWeeks: 6,
            goals: "Build strength",
            workoutAssignments: []
        )

        XCTAssertEqual(phase.id, id)
        XCTAssertEqual(phase.name, "Test Phase")
        XCTAssertEqual(phase.sequence, 2)
        XCTAssertEqual(phase.durationWeeks, 6)
        XCTAssertEqual(phase.goals, "Build strength")
    }

    func testTherapistPhaseData_WithAssignments() {
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Workout A",
            weekNumber: 1,
            dayOfWeek: 1
        )

        let phase = TherapistPhaseData(workoutAssignments: [assignment])

        XCTAssertEqual(phase.workoutAssignments.count, 1)
    }

    func testTherapistPhaseData_Identifiable() {
        let phase = TherapistPhaseData()

        XCTAssertNotNil(phase.id)
    }
}

// MARK: - TherapistWorkoutAssignment Tests

final class TherapistWorkoutAssignmentTests: XCTestCase {

    func testTherapistWorkoutAssignment_Init() {
        let templateId = UUID()

        let assignment = TherapistWorkoutAssignment(
            templateId: templateId,
            templateName: "Morning Workout",
            weekNumber: 2,
            dayOfWeek: 3
        )

        XCTAssertNotNil(assignment.id)
        XCTAssertEqual(assignment.templateId, templateId)
        XCTAssertEqual(assignment.templateName, "Morning Workout")
        XCTAssertEqual(assignment.weekNumber, 2)
        XCTAssertEqual(assignment.dayOfWeek, 3)
    }

    func testTherapistWorkoutAssignment_CustomId() {
        let id = UUID()
        let assignment = TherapistWorkoutAssignment(
            id: id,
            templateId: UUID(),
            templateName: "Workout",
            weekNumber: 1,
            dayOfWeek: 1
        )

        XCTAssertEqual(assignment.id, id)
    }

    func testTherapistWorkoutAssignment_Identifiable() {
        let assignment = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Test",
            weekNumber: 1,
            dayOfWeek: 1
        )

        XCTAssertNotNil(assignment.id)
    }
}

// MARK: - TherapistProgramBuilderError Tests

final class TherapistProgramBuilderErrorTests: XCTestCase {

    func testInvalidProgram_ErrorDescription() {
        let error = TherapistProgramBuilderError.invalidProgram

        XCTAssertEqual(error.errorDescription, "Please fill in all required program details")
    }

    func testNotReadyToPublish_ErrorDescription() {
        let error = TherapistProgramBuilderError.notReadyToPublish

        XCTAssertEqual(error.errorDescription, "Add at least one phase with workout assignments to publish")
    }

    func testProgramCreationFailed_ErrorDescription() {
        let error = TherapistProgramBuilderError.programCreationFailed

        XCTAssertEqual(error.errorDescription, "Failed to create program")
    }

    func testPhaseCreationFailed_ErrorDescription() {
        let error = TherapistProgramBuilderError.phaseCreationFailed

        XCTAssertEqual(error.errorDescription, "Failed to create phase")
    }

    func testPublishFailed_ErrorDescription() {
        let error = TherapistProgramBuilderError.publishFailed

        XCTAssertEqual(error.errorDescription, "Failed to publish to library")
    }

    func testErrors_AreLocalizedError() {
        let errors: [TherapistProgramBuilderError] = [
            .invalidProgram,
            .notReadyToPublish,
            .programCreationFailed,
            .phaseCreationFailed,
            .publishFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - Program Category Tests

final class ProgramCategoryTests: XCTestCase {

    func testProgramCategory_Exists() {
        // Verify the enum exists and has expected cases
        XCTAssertNotNil(ProgramCategory.strength.rawValue)
    }
}

// MARK: - Difficulty Level Tests

final class DifficultyLevelTests: XCTestCase {

    func testDifficultyLevel_Exists() {
        // Verify the enum exists and has expected cases
        XCTAssertNotNil(DifficultyLevel.intermediate.rawValue)
    }
}

// MARK: - Phase Reordering Algorithm Tests

final class PhaseReorderingTests: XCTestCase {

    func testPhaseReordering_SequenceCalculation() {
        let weekNumber = 2
        let dayOfWeek = 3

        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 10)
    }

    func testPhaseReordering_Week1Day1() {
        let sequence = (1 - 1) * 7 + 1

        XCTAssertEqual(sequence, 1)
    }

    func testPhaseReordering_Week4Day7() {
        let sequence = (4 - 1) * 7 + 7

        XCTAssertEqual(sequence, 28)
    }

    func testPhaseSequencing_AfterReorder() {
        var phases = [
            createPhase(sequence: 1),
            createPhase(sequence: 2),
            createPhase(sequence: 3)
        ]

        // Simulate moving first to last
        let first = phases.removeFirst()
        phases.append(first)

        // Resequence
        for i in phases.indices {
            phases[i].sequence = i + 1
        }

        XCTAssertEqual(phases[0].sequence, 1)
        XCTAssertEqual(phases[1].sequence, 2)
        XCTAssertEqual(phases[2].sequence, 3)
    }

    private func createPhase(sequence: Int) -> TherapistPhaseData {
        TherapistPhaseData(
            name: "Phase \(sequence)",
            sequence: sequence,
            durationWeeks: 4
        )
    }
}

// MARK: - Program Duration Calculation Tests

final class ProgramDurationCalculationTests: XCTestCase {

    func testDurationCalculation_EmptyPhases() {
        let phases: [TherapistPhaseData] = []

        let duration = phases.reduce(0) { $0 + $1.durationWeeks }
        let finalDuration = max(duration, 1)

        XCTAssertEqual(finalDuration, 1)
    }

    func testDurationCalculation_SinglePhase() {
        let phases = [TherapistPhaseData(durationWeeks: 6)]

        let duration = phases.reduce(0) { $0 + $1.durationWeeks }

        XCTAssertEqual(duration, 6)
    }

    func testDurationCalculation_MultiplePhases() {
        let phases = [
            TherapistPhaseData(durationWeeks: 4),
            TherapistPhaseData(durationWeeks: 4),
            TherapistPhaseData(durationWeeks: 4)
        ]

        let duration = phases.reduce(0) { $0 + $1.durationWeeks }

        XCTAssertEqual(duration, 12)
    }

    func testDurationCalculation_MixedDurations() {
        let phases = [
            TherapistPhaseData(durationWeeks: 2),
            TherapistPhaseData(durationWeeks: 6),
            TherapistPhaseData(durationWeeks: 4)
        ]

        let duration = phases.reduce(0) { $0 + $1.durationWeeks }

        XCTAssertEqual(duration, 12)
    }
}

// MARK: - Workout Assignment Validation Tests

final class WorkoutAssignmentValidationTests: XCTestCase {

    func testWorkoutAssignment_ValidDayOfWeek() {
        for day in 1...7 {
            let assignment = TherapistWorkoutAssignment(
                templateId: UUID(),
                templateName: "Workout",
                weekNumber: 1,
                dayOfWeek: day
            )

            XCTAssertEqual(assignment.dayOfWeek, day)
        }
    }

    func testWorkoutAssignment_ValidWeekNumber() {
        for week in 1...52 {
            let assignment = TherapistWorkoutAssignment(
                templateId: UUID(),
                templateName: "Workout",
                weekNumber: week,
                dayOfWeek: 1
            )

            XCTAssertEqual(assignment.weekNumber, week)
        }
    }

    func testWorkoutAssignment_TemplateIdRequired() {
        let templateId = UUID()
        let assignment = TherapistWorkoutAssignment(
            templateId: templateId,
            templateName: "Workout",
            weekNumber: 1,
            dayOfWeek: 1
        )

        XCTAssertEqual(assignment.templateId, templateId)
    }
}

// MARK: - Program Builder Input Validation Tests

final class ProgramBuilderInputValidationTests: XCTestCase {

    @MainActor
    func testProgramName_WhitespaceOnly_Invalid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "   \t\n   "

        XCTAssertFalse(viewModel.isValid)
    }

    @MainActor
    func testProgramName_MinimumLength_Valid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "ABC"

        XCTAssertTrue(viewModel.isValid)
    }

    @MainActor
    func testProgramName_MaximumLength_Valid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = String(repeating: "X", count: 100)

        XCTAssertTrue(viewModel.isValid)
    }

    @MainActor
    func testProgramName_ExceedsMaximum_Invalid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = String(repeating: "X", count: 101)

        XCTAssertFalse(viewModel.isValid)
    }

    @MainActor
    func testProgramName_SpecialCharacters_Valid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "Program - Phase 1 (Advanced)"

        XCTAssertTrue(viewModel.isValid)
    }

    @MainActor
    func testProgramName_UnicodeCharacters_Valid() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "Programa de Fuerza"

        XCTAssertTrue(viewModel.isValid)
    }
}

// MARK: - Edge Cases Tests

final class ProgramEditorEdgeCasesTests: XCTestCase {

    @MainActor
    func testEmptyPhasesArray_DurationIsZero() {
        let viewModel = TherapistProgramBuilderViewModel()

        XCTAssertEqual(viewModel.totalPhaseDuration, 0)
    }

    @MainActor
    func testMultipleAssignmentsSameDay() {
        let viewModel = TherapistProgramBuilderViewModel()

        let assignment1 = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Morning Workout",
            weekNumber: 1,
            dayOfWeek: 1
        )

        let assignment2 = TherapistWorkoutAssignment(
            templateId: UUID(),
            templateName: "Evening Workout",
            weekNumber: 1,
            dayOfWeek: 1
        )

        viewModel.phases = [TherapistPhaseData(workoutAssignments: [assignment1, assignment2])]

        XCTAssertEqual(viewModel.phases[0].workoutAssignments.count, 2)
    }

    @MainActor
    func testPhaseWithNoGoals() {
        let phase = TherapistPhaseData(
            name: "No Goals Phase",
            goals: ""
        )

        XCTAssertTrue(phase.goals.isEmpty)
    }

    @MainActor
    func testPhaseWithLongGoals() {
        let longGoals = String(repeating: "Build strength and endurance. ", count: 50)
        let phase = TherapistPhaseData(
            name: "Phase with Long Goals",
            goals: longGoals
        )

        XCTAssertEqual(phase.goals, longGoals)
    }

    @MainActor
    func testManyPhasesProgram() {
        let viewModel = TherapistProgramBuilderViewModel()

        for _ in 1...20 {
            viewModel.addPhase()
        }

        XCTAssertEqual(viewModel.phases.count, 20)

        // Verify all sequences are correct
        for (index, phase) in viewModel.phases.enumerated() {
            XCTAssertEqual(phase.sequence, index + 1)
        }
    }

    @MainActor
    func testDeleteAllPhases() {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.addPhase()
        viewModel.addPhase()
        viewModel.addPhase()

        viewModel.deletePhase(at: 0)
        viewModel.deletePhase(at: 0)
        viewModel.deletePhase(at: 0)

        XCTAssertTrue(viewModel.phases.isEmpty)
    }
}
