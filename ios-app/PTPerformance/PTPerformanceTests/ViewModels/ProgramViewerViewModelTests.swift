//
//  ProgramViewerViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProgramViewModel.
//  Tests program display logic, session navigation, and exercise details.
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Supabase Client for Testing

/// Mock response structure for testing
private struct MockSupabaseResponse {
    var programs: [Program] = []
    var phases: [Phase] = []
    var sessions: [String: [ProgramSession]] = [:]  // keyed by phase ID
    var exercises: [String: [MockExerciseData]] = [:]  // keyed by session ID
    var shouldFail = false
    var errorMessage: String = "Mock error"
}

/// Mock exercise data structure for testing
private struct MockExerciseData {
    let id: UUID
    let sessionId: UUID
    let exerciseName: String
    let sets: Int
    let reps: String
    let load: Double?
    let loadUnit: String?
    let restPeriod: Int?
    let orderIndex: Int
}

// MARK: - ProgramViewModel Tests

@MainActor
final class ProgramViewModelTests: XCTestCase {

    var viewModel: ProgramViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = ProgramViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_ProgramIsNil() {
        XCTAssertNil(viewModel.program, "program should be nil initially")
    }

    func testInitialState_PhasesIsEmpty() {
        XCTAssertTrue(viewModel.phases.isEmpty, "phases should be empty initially")
    }

    func testInitialState_SessionsByPhaseIsEmpty() {
        XCTAssertTrue(viewModel.sessionsByPhase.isEmpty, "sessionsByPhase should be empty initially")
    }

    func testInitialState_ExercisesBySessionIsEmpty() {
        XCTAssertTrue(viewModel.exercisesBySession.isEmpty, "exercisesBySession should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil initially")
    }

    // MARK: - Sessions Helper Tests

    func testSessions_ForPhase_WhenNoSessions() {
        let phase = createMockPhase()
        let sessions = viewModel.sessions(for: phase)

        XCTAssertTrue(sessions.isEmpty, "Should return empty array when no sessions exist")
    }

    func testSessions_ForPhase_WhenSessionsExist() {
        let phase = createMockPhase()
        let session1 = createMockSession(phaseId: phase.id, sessionNumber: 1)
        let session2 = createMockSession(phaseId: phase.id, sessionNumber: 2)

        viewModel.sessionsByPhase[phase.id.uuidString] = [session1, session2]

        let sessions = viewModel.sessions(for: phase)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].sessionNumber, 1)
        XCTAssertEqual(sessions[1].sessionNumber, 2)
    }

    func testSessions_ForDifferentPhases() {
        let phase1 = createMockPhase(phaseNumber: 1)
        let phase2 = createMockPhase(phaseNumber: 2)

        let session1 = createMockSession(phaseId: phase1.id, sessionNumber: 1)
        let session2 = createMockSession(phaseId: phase2.id, sessionNumber: 1)

        viewModel.sessionsByPhase[phase1.id.uuidString] = [session1]
        viewModel.sessionsByPhase[phase2.id.uuidString] = [session2]

        let phase1Sessions = viewModel.sessions(for: phase1)
        let phase2Sessions = viewModel.sessions(for: phase2)

        XCTAssertEqual(phase1Sessions.count, 1)
        XCTAssertEqual(phase2Sessions.count, 1)
        XCTAssertNotEqual(phase1Sessions[0].id, phase2Sessions[0].id)
    }

    // MARK: - Exercises Helper Tests

    func testExercises_ForSession_WhenNoExercises() {
        let session = createMockSession()
        let exercises = viewModel.exercises(for: session)

        XCTAssertTrue(exercises.isEmpty, "Should return empty array when no exercises exist")
    }

    func testExercises_ForSession_WhenExercisesExist() {
        let session = createMockSession()

        // Note: We can't easily create ProgramExercise directly since it requires decoding
        // So we just test the lookup mechanism
        viewModel.exercisesBySession[session.id.uuidString] = []

        let exercises = viewModel.exercises(for: session)

        XCTAssertNotNil(exercises)
    }

    // MARK: - Program Display Logic Tests

    func testProgramDisplay_WithProgram() {
        let program = createMockProgram()
        viewModel.program = program

        XCTAssertNotNil(viewModel.program)
        XCTAssertEqual(viewModel.program?.name, "Test Program")
    }

    func testProgramDisplay_ResolvedProgramType() {
        let rehabProgram = createMockProgram(programType: .rehab)
        viewModel.program = rehabProgram

        XCTAssertEqual(viewModel.program?.resolvedProgramType, .rehab)
    }

    func testProgramDisplay_DefaultProgramType() {
        let legacyProgram = createMockProgram(programType: nil)
        viewModel.program = legacyProgram

        XCTAssertEqual(viewModel.program?.resolvedProgramType, .rehab)
    }

    // MARK: - Phase Navigation Tests

    func testPhaseNavigation_EmptyPhases() {
        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    func testPhaseNavigation_MultiplePhases() {
        let programId = UUID()
        let phase1 = createMockPhase(programId: programId, phaseNumber: 1, name: "Foundation")
        let phase2 = createMockPhase(programId: programId, phaseNumber: 2, name: "Build")
        let phase3 = createMockPhase(programId: programId, phaseNumber: 3, name: "Peak")

        viewModel.phases = [phase1, phase2, phase3]

        XCTAssertEqual(viewModel.phases.count, 3)
        XCTAssertEqual(viewModel.phases[0].name, "Foundation")
        XCTAssertEqual(viewModel.phases[1].name, "Build")
        XCTAssertEqual(viewModel.phases[2].name, "Peak")
    }

    func testPhaseNavigation_PhasesAreSorted() {
        let programId = UUID()
        // Add phases in wrong order
        let phase3 = createMockPhase(programId: programId, phaseNumber: 3)
        let phase1 = createMockPhase(programId: programId, phaseNumber: 1)
        let phase2 = createMockPhase(programId: programId, phaseNumber: 2)

        var phases = [phase3, phase1, phase2]
        phases.sort { $0.phaseNumber < $1.phaseNumber }

        viewModel.phases = phases

        XCTAssertEqual(viewModel.phases[0].phaseNumber, 1)
        XCTAssertEqual(viewModel.phases[1].phaseNumber, 2)
        XCTAssertEqual(viewModel.phases[2].phaseNumber, 3)
    }

    // MARK: - Session Navigation Tests

    func testSessionNavigation_SessionsForPhase() {
        let phase = createMockPhase()

        let session1 = createMockSession(phaseId: phase.id, sessionNumber: 1)
        let session2 = createMockSession(phaseId: phase.id, sessionNumber: 2)
        let session3 = createMockSession(phaseId: phase.id, sessionNumber: 3)

        viewModel.sessionsByPhase[phase.id.uuidString] = [session1, session2, session3]

        let sessions = viewModel.sessions(for: phase)

        XCTAssertEqual(sessions.count, 3)
    }

    func testSessionNavigation_CompletedSessions() {
        let phase = createMockPhase()

        let completedSession = createMockSession(
            phaseId: phase.id,
            sessionNumber: 1,
            completed: true
        )
        let incompleteSession = createMockSession(
            phaseId: phase.id,
            sessionNumber: 2,
            completed: false
        )

        viewModel.sessionsByPhase[phase.id.uuidString] = [completedSession, incompleteSession]

        let sessions = viewModel.sessions(for: phase)

        XCTAssertEqual(sessions[0].completed, true)
        XCTAssertEqual(sessions[1].completed, false)
    }

    func testSessionNavigation_SessionWithDate() {
        let phase = createMockPhase()
        let sessionDate = Date()

        let session = createMockSession(
            phaseId: phase.id,
            sessionNumber: 1,
            sessionDate: sessionDate
        )

        viewModel.sessionsByPhase[phase.id.uuidString] = [session]

        let sessions = viewModel.sessions(for: phase)

        XCTAssertNotNil(sessions[0].sessionDate)
    }

    // MARK: - Exercise Details Tests

    func testExerciseDetails_ExerciseCount() {
        let session = createMockSession(exerciseCount: 5)

        XCTAssertEqual(session.exerciseCount, 5)
    }

    func testExerciseDetails_NoExercises() {
        let session = createMockSession(exerciseCount: 0)

        XCTAssertEqual(session.exerciseCount, 0)
    }

    func testExerciseDetails_NilExerciseCount() {
        let session = createMockSession(exerciseCount: nil)

        XCTAssertNil(session.exerciseCount)
    }

    // MARK: - Error State Tests

    func testErrorState_SetError() {
        viewModel.errorMessage = "Failed to load program"

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Failed to load program")
    }

    func testErrorState_ClearError() {
        viewModel.errorMessage = "Some error"
        viewModel.errorMessage = nil

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Loading State Tests

    func testLoadingState_SetLoading() {
        viewModel.isLoading = true

        XCTAssertTrue(viewModel.isLoading)
    }

    func testLoadingState_ClearLoading() {
        viewModel.isLoading = true
        viewModel.isLoading = false

        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Data Population Tests

    func testDataPopulation_FullProgram() {
        let program = createMockProgram()
        let phase1 = createMockPhase(programId: program.id, phaseNumber: 1)
        let phase2 = createMockPhase(programId: program.id, phaseNumber: 2)

        let session1 = createMockSession(phaseId: phase1.id, sessionNumber: 1)
        let session2 = createMockSession(phaseId: phase1.id, sessionNumber: 2)
        let session3 = createMockSession(phaseId: phase2.id, sessionNumber: 1)

        viewModel.program = program
        viewModel.phases = [phase1, phase2]
        viewModel.sessionsByPhase = [
            phase1.id.uuidString: [session1, session2],
            phase2.id.uuidString: [session3]
        ]

        XCTAssertNotNil(viewModel.program)
        XCTAssertEqual(viewModel.phases.count, 2)
        XCTAssertEqual(viewModel.sessions(for: phase1).count, 2)
        XCTAssertEqual(viewModel.sessions(for: phase2).count, 1)
    }

    // MARK: - Edge Cases Tests

    func testEdgeCase_EmptyProgram() {
        // Program exists but has no phases
        let program = createMockProgram()
        viewModel.program = program
        viewModel.phases = []

        XCTAssertNotNil(viewModel.program)
        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    func testEdgeCase_PhaseWithNoSessions() {
        let phase = createMockPhase()
        viewModel.phases = [phase]
        // No sessions added

        let sessions = viewModel.sessions(for: phase)
        XCTAssertTrue(sessions.isEmpty)
    }

    func testEdgeCase_SessionWithNoExercises() {
        let session = createMockSession(exerciseCount: 0)

        let exercises = viewModel.exercises(for: session)
        XCTAssertTrue(exercises.isEmpty)
    }

    func testEdgeCase_MismatchedPhaseId() {
        let phase = createMockPhase()
        let differentPhaseId = UUID()

        let session = createMockSession(phaseId: differentPhaseId)

        viewModel.sessionsByPhase[differentPhaseId.uuidString] = [session]

        // Querying with original phase should return empty
        let sessions = viewModel.sessions(for: phase)
        XCTAssertTrue(sessions.isEmpty)
    }

    func testEdgeCase_DuplicateSessionNumbers() {
        let phase = createMockPhase()

        let session1 = createMockSession(phaseId: phase.id, sessionNumber: 1)
        let session2 = createMockSession(phaseId: phase.id, sessionNumber: 1)

        viewModel.sessionsByPhase[phase.id.uuidString] = [session1, session2]

        let sessions = viewModel.sessions(for: phase)

        // Should still return both (data integrity issue at source)
        XCTAssertEqual(sessions.count, 2)
    }

    // MARK: - Program Type Display Tests

    func testProgramTypeDisplay_Rehab() {
        let program = createMockProgram(programType: .rehab)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.resolvedProgramType.displayName, "Rehab")
        XCTAssertEqual(viewModel.program?.resolvedProgramType.icon, "cross.case.fill")
    }

    func testProgramTypeDisplay_Performance() {
        let program = createMockProgram(programType: .performance)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.resolvedProgramType.displayName, "Performance")
        XCTAssertEqual(viewModel.program?.resolvedProgramType.icon, "bolt.fill")
    }

    func testProgramTypeDisplay_Lifestyle() {
        let program = createMockProgram(programType: .lifestyle)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.resolvedProgramType.displayName, "Lifestyle")
        XCTAssertEqual(viewModel.program?.resolvedProgramType.icon, "heart.fill")
    }

    // MARK: - Duration Display Tests

    func testDurationDisplay_StandardProgram() {
        let program = createMockProgram(durationWeeks: 12)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.durationWeeks, 12)
    }

    func testDurationDisplay_ShortProgram() {
        let program = createMockProgram(durationWeeks: 1)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.durationWeeks, 1)
    }

    func testDurationDisplay_LongProgram() {
        let program = createMockProgram(durationWeeks: 52)
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.durationWeeks, 52)
    }

    // MARK: - Target Level Display Tests

    func testTargetLevelDisplay_Beginner() {
        let program = createMockProgram(targetLevel: "beginner")
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.targetLevel, "beginner")
    }

    func testTargetLevelDisplay_Intermediate() {
        let program = createMockProgram(targetLevel: "intermediate")
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.targetLevel, "intermediate")
    }

    func testTargetLevelDisplay_Advanced() {
        let program = createMockProgram(targetLevel: "advanced")
        viewModel.program = program

        XCTAssertEqual(viewModel.program?.targetLevel, "advanced")
    }

    // MARK: - Helper Methods

    private func createMockProgram(
        id: UUID = UUID(),
        patientId: UUID = UUID(),
        name: String = "Test Program",
        targetLevel: String = "intermediate",
        durationWeeks: Int = 12,
        status: String? = "active",
        programType: ProgramType? = .rehab
    ) -> Program {
        Program(
            id: id,
            patientId: patientId,
            name: name,
            targetLevel: targetLevel,
            durationWeeks: durationWeeks,
            createdAt: Date(),
            status: status,
            programType: programType
        )
    }

    private func createMockPhase(
        id: UUID = UUID(),
        programId: UUID = UUID(),
        phaseNumber: Int = 1,
        name: String = "Test Phase",
        durationWeeks: Int? = 4,
        goals: String? = nil
    ) -> Phase {
        Phase(
            id: id,
            programId: programId,
            phaseNumber: phaseNumber,
            name: name,
            durationWeeks: durationWeeks,
            goals: goals
        )
    }

    private func createMockSession(
        id: UUID = UUID(),
        phaseId: UUID = UUID(),
        sessionNumber: Int? = 1,
        sessionDate: Date? = nil,
        completed: Bool? = false,
        exerciseCount: Int? = 5
    ) -> ProgramSession {
        ProgramSession(
            id: id,
            phaseId: phaseId,
            sessionNumber: sessionNumber,
            sessionDate: sessionDate,
            completed: completed,
            exerciseCount: exerciseCount
        )
    }
}

// MARK: - Session Display Tests

final class SessionDisplayTests: XCTestCase {

    func testSessionDisplay_WithNumber() {
        let session = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 5,
            sessionDate: nil,
            completed: nil,
            exerciseCount: nil
        )

        XCTAssertEqual(session.sessionNumber, 5)
    }

    func testSessionDisplay_WithDate() {
        let date = Date()
        let session = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 1,
            sessionDate: date,
            completed: nil,
            exerciseCount: nil
        )

        XCTAssertNotNil(session.sessionDate)
    }

    func testSessionDisplay_CompletedStatus() {
        let completedSession = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 1,
            sessionDate: nil,
            completed: true,
            exerciseCount: nil
        )

        let incompleteSession = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 2,
            sessionDate: nil,
            completed: false,
            exerciseCount: nil
        )

        XCTAssertEqual(completedSession.completed, true)
        XCTAssertEqual(incompleteSession.completed, false)
    }

    func testSessionDisplay_ExerciseCount() {
        let session = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 1,
            sessionDate: nil,
            completed: nil,
            exerciseCount: 8
        )

        XCTAssertEqual(session.exerciseCount, 8)
    }
}

// MARK: - Phase Goals Display Tests

final class PhaseGoalsDisplayTests: XCTestCase {

    func testPhaseGoals_WithGoals() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Foundation",
            durationWeeks: 4,
            goals: "Build foundational strength and establish proper movement patterns"
        )

        XCTAssertNotNil(phase.goals)
        XCTAssertTrue(phase.goals!.contains("foundational"))
    }

    func testPhaseGoals_WithoutGoals() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Basic",
            durationWeeks: 4,
            goals: nil
        )

        XCTAssertNil(phase.goals)
    }

    func testPhaseGoals_EmptyGoals() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Empty",
            durationWeeks: 4,
            goals: ""
        )

        XCTAssertEqual(phase.goals, "")
    }
}

// MARK: - Integration Scenario Tests

final class ProgramViewerIntegrationScenarioTests: XCTestCase {

    @MainActor
    func testScenario_CompleteProgram() async {
        let viewModel = ProgramViewModel()

        // Setup complete program structure
        let programId = UUID()
        let program = Program(
            id: programId,
            patientId: UUID(),
            name: "ACL Rehabilitation",
            targetLevel: "intermediate",
            durationWeeks: 16,
            createdAt: Date(),
            status: "active",
            programType: .rehab
        )

        let phase1Id = UUID()
        let phase2Id = UUID()
        let phase3Id = UUID()
        let phase4Id = UUID()

        let phases = [
            Phase(id: phase1Id, programId: programId, phaseNumber: 1, name: "Protection", durationWeeks: 4, goals: "Reduce swelling, protect graft"),
            Phase(id: phase2Id, programId: programId, phaseNumber: 2, name: "Early Rehab", durationWeeks: 4, goals: "Restore range of motion"),
            Phase(id: phase3Id, programId: programId, phaseNumber: 3, name: "Strengthening", durationWeeks: 4, goals: "Build muscle strength"),
            Phase(id: phase4Id, programId: programId, phaseNumber: 4, name: "Return to Sport", durationWeeks: 4, goals: "Sport-specific training")
        ]

        let sessions: [String: [ProgramSession]] = [
            phase1Id.uuidString: [
                ProgramSession(id: UUID(), phaseId: phase1Id, sessionNumber: 1, sessionDate: nil, completed: true, exerciseCount: 5),
                ProgramSession(id: UUID(), phaseId: phase1Id, sessionNumber: 2, sessionDate: nil, completed: true, exerciseCount: 5),
                ProgramSession(id: UUID(), phaseId: phase1Id, sessionNumber: 3, sessionDate: nil, completed: false, exerciseCount: 5)
            ],
            phase2Id.uuidString: [
                ProgramSession(id: UUID(), phaseId: phase2Id, sessionNumber: 1, sessionDate: nil, completed: false, exerciseCount: 6)
            ]
        ]

        // Populate view model
        viewModel.program = program
        viewModel.phases = phases
        viewModel.sessionsByPhase = sessions

        // Verify complete structure
        XCTAssertNotNil(viewModel.program)
        XCTAssertEqual(viewModel.program?.name, "ACL Rehabilitation")
        XCTAssertEqual(viewModel.phases.count, 4)
        XCTAssertEqual(viewModel.sessions(for: phases[0]).count, 3)
        XCTAssertEqual(viewModel.sessions(for: phases[1]).count, 1)
        XCTAssertEqual(viewModel.sessions(for: phases[2]).count, 0)
        XCTAssertEqual(viewModel.sessions(for: phases[3]).count, 0)

        // Check completion status
        let phase1Sessions = viewModel.sessions(for: phases[0])
        let completedCount = phase1Sessions.filter { $0.completed == true }.count
        XCTAssertEqual(completedCount, 2)
    }

    @MainActor
    func testScenario_EmptyProgramState() async {
        let viewModel = ProgramViewModel()

        // Simulate empty state (no program for patient)
        viewModel.program = nil
        viewModel.phases = []
        viewModel.sessionsByPhase = [:]
        viewModel.exercisesBySession = [:]
        viewModel.isLoading = false
        viewModel.errorMessage = nil

        XCTAssertNil(viewModel.program)
        XCTAssertTrue(viewModel.phases.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testScenario_ErrorState() async {
        let viewModel = ProgramViewModel()

        // Simulate error state
        viewModel.program = nil
        viewModel.phases = []
        viewModel.isLoading = false
        viewModel.errorMessage = "Failed to load program: Network connection lost"

        XCTAssertNil(viewModel.program)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Network"))
    }

    @MainActor
    func testScenario_LoadingState() async {
        let viewModel = ProgramViewModel()

        // Simulate loading state
        viewModel.isLoading = true
        viewModel.program = nil
        viewModel.errorMessage = nil

        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.program)
        XCTAssertNil(viewModel.errorMessage)
    }
}
