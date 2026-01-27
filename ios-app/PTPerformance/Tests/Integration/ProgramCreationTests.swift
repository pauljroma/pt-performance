//
//  ProgramCreationTests.swift
//  PTPerformance
//
//  Build 60: Integration tests for ACP-113 program creation flow
//

import XCTest
@testable import PTPerformance

@MainActor
class ProgramCreationTests: XCTestCase {

    var viewModel: ProgramBuilderViewModel!
    var supabase: PTSupabaseClient!

    override func setUp() async throws {
        try await super.setUp()
        supabase = PTSupabaseClient.shared
        viewModel = ProgramBuilderViewModel(supabase: supabase)
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Validation Tests

    func testValidation_EmptyProgramName_ThrowsError() async throws {
        // Given
        viewModel.programName = ""

        // When/Then
        do {
            _ = try await viewModel.createProgram(patientId: nil)
            XCTFail("Should have thrown error for empty program name")
        } catch let error as ProgramBuilderError {
            XCTAssertEqual(error, .emptyProgramName)
        }
    }

    func testValidation_ProgramNameTooShort_ThrowsError() async throws {
        // Given
        viewModel.programName = "AB"

        // When/Then
        do {
            _ = try await viewModel.createProgram(patientId: nil)
            XCTFail("Should have thrown error for short program name")
        } catch let error as ProgramBuilderError {
            XCTAssertEqual(error, .programNameTooShort)
        }
    }

    func testValidation_NoPhases_ThrowsError() async throws {
        // Given
        viewModel.programName = "Test Program"
        viewModel.phases = []

        // When/Then
        do {
            _ = try await viewModel.createProgram(patientId: nil)
            XCTFail("Should have thrown error for no phases")
        } catch let error as ProgramBuilderError {
            XCTAssertEqual(error, .noPhases)
        }
    }

    func testValidation_ValidProgram_PassesValidation() {
        // Given
        viewModel.programName = "Test Program"
        viewModel.phases = [
            ProgramPhase(
                name: "Phase 1",
                durationWeeks: 4,
                sessions: [],
                order: 1
            )
        ]

        // When
        let isValid = viewModel.isValid

        // Then
        XCTAssertTrue(isValid)
        XCTAssertNil(viewModel.validationError)
    }

    // MARK: - Program Creation Tests

    func testCreateProgram_MinimalProgram_CreatesSuccessfully() async throws {
        // Given
        viewModel.programName = "Build 60 Test Program"
        viewModel.phases = [
            ProgramPhase(
                name: "Foundation Phase",
                durationWeeks: 4,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil, targetLevel: "Beginner")

        // Then
        XCTAssertFalse(programId.isEmpty)
        XCTAssertNotNil(viewModel.successMessage)
        XCTAssertNil(viewModel.createError)

        // Verify program was created in database
        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.name, "Build 60 Test Program")
        XCTAssertEqual(program.durationWeeks, 4)
        XCTAssertEqual(program.targetLevel, "Beginner")
    }

    func testCreateProgram_WithPatient_AssociatesCorrectly() async throws {
        // Given: Get a test patient ID
        let patientId = "27d60616-8cb9-4434-b2b9-e84476788e08" // Nic Roma from seed data

        viewModel.programName = "Patient-Specific Program"
        viewModel.phases = [
            ProgramPhase(
                name: "Initial Phase",
                durationWeeks: 2,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: patientId)

        // Then
        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.patientId, patientId)
    }

    func testCreateProgram_WithMultiplePhases_CreatesAllPhases() async throws {
        // Given
        viewModel.programName = "Multi-Phase Program"
        viewModel.phases = [
            ProgramPhase(
                name: "Phase 1: Foundation",
                durationWeeks: 3,
                sessions: [],
                order: 1
            ),
            ProgramPhase(
                name: "Phase 2: Build",
                durationWeeks: 4,
                sessions: [],
                order: 2
            ),
            ProgramPhase(
                name: "Phase 3: Peak",
                durationWeeks: 2,
                sessions: [],
                order: 3
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then
        let phasesResponse = try await supabase.client
            .from("phases")
            .select()
            .eq("program_id", value: programId)
            .order("phase_number")
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let phases = try decoder.decode([Phase].self, from: phasesResponse.data)

        XCTAssertEqual(phases.count, 3)
        XCTAssertEqual(phases[0].name, "Phase 1: Foundation")
        XCTAssertEqual(phases[1].name, "Phase 2: Build")
        XCTAssertEqual(phases[2].name, "Phase 3: Peak")
        XCTAssertEqual(phases[0].phaseNumber, 1)
        XCTAssertEqual(phases[1].phaseNumber, 2)
        XCTAssertEqual(phases[2].phaseNumber, 3)
    }

    func testCreateProgram_WithSessions_CreatesAllSessions() async throws {
        // Given
        viewModel.programName = "Program with Sessions"

        // Create sample exercises for sessions
        let sampleExercise1 = Exercise(
            id: UUID().uuidString,
            session_id: "",
            exercise_template_id: "550e8400-e29b-41d4-a716-446655440000", // Bench Press from seed
            sequence: 1,
            prescribed_sets: 3,
            prescribed_reps: "8-10",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: nil
        )

        let sampleExercise2 = Exercise(
            id: UUID().uuidString,
            session_id: "",
            exercise_template_id: "550e8400-e29b-41d4-a716-446655440001", // Squat from seed
            sequence: 2,
            prescribed_sets: 4,
            prescribed_reps: "6-8",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: nil
        )

        viewModel.phases = [
            ProgramPhase(
                name: "Training Phase",
                durationWeeks: 4,
                sessions: [
                    ProgramPhase.Session(
                        id: UUID(),
                        name: "Day 1: Upper Body",
                        exercises: [sampleExercise1]
                    ),
                    ProgramPhase.Session(
                        id: UUID(),
                        name: "Day 2: Lower Body",
                        exercises: [sampleExercise2]
                    )
                ],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then - Verify phases
        let phasesResponse = try await supabase.client
            .from("phases")
            .select()
            .eq("program_id", value: programId)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let phases = try decoder.decode([Phase].self, from: phasesResponse.data)
        XCTAssertEqual(phases.count, 1)

        // Verify sessions
        let sessionsResponse = try await supabase.client
            .from("sessions")
            .select()
            .eq("phase_id", value: phases[0].id)
            .order("sequence")
            .execute()

        let sessions = try decoder.decode([Session].self, from: sessionsResponse.data)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].name, "Day 1: Upper Body")
        XCTAssertEqual(sessions[1].name, "Day 2: Lower Body")

        // Verify exercises
        let exercisesResponse = try await supabase.client
            .from("session_exercises")
            .select()
            .eq("session_id", value: sessions[0].id)
            .execute()

        let exercises = try decoder.decode([Exercise].self, from: exercisesResponse.data)
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].prescribed_sets, 3)
        XCTAssertEqual(exercises[0].prescribed_reps, "8-10")
    }

    // MARK: - Protocol Tests

    func testLoadProtocols_LoadsSuccessfully() async throws {
        // When
        await viewModel.loadProtocols()

        // Then
        XCTAssertFalse(viewModel.isLoadingProtocols)
        XCTAssertFalse(viewModel.availableProtocols.isEmpty)
        XCTAssertNil(viewModel.createError)

        // Verify sample protocols are loaded
        let protocolNames = viewModel.availableProtocols.map { $0.name }
        XCTAssertTrue(protocolNames.contains("8-Week Throwing On-Ramp"))
        XCTAssertTrue(protocolNames.contains("Post-Op Shoulder Rehab"))
        XCTAssertTrue(protocolNames.contains("General Strength Foundation"))
        XCTAssertTrue(protocolNames.contains("Winter Lift 3x/week"))
    }

    func testSelectProtocol_LoadsProtocolPhases() async throws {
        // Given
        await viewModel.loadProtocols()
        let winterLift = viewModel.availableProtocols.first { $0.name == "Winter Lift 3x/week" }
        XCTAssertNotNil(winterLift)

        // When
        viewModel.selectedProtocol = winterLift

        // Then
        XCTAssertEqual(viewModel.phases.count, 3)
        XCTAssertEqual(viewModel.phases[0].name, "Phase 1: Foundation")
        XCTAssertEqual(viewModel.phases[1].name, "Phase 2: Build")
        XCTAssertEqual(viewModel.phases[2].name, "Phase 3: Intensify")
        XCTAssertEqual(viewModel.phases[0].durationWeeks, 4)
    }

    // MARK: - UI Integration Tests

    func testAddPhase_AddsPhaseToList() {
        // Given
        viewModel.phases = []

        // When
        viewModel.addPhase()

        // Then
        XCTAssertEqual(viewModel.phases.count, 1)
        XCTAssertEqual(viewModel.phases[0].name, "Phase 1")
        XCTAssertEqual(viewModel.phases[0].durationWeeks, 2)
        XCTAssertEqual(viewModel.phases[0].order, 1)
    }

    func testDeletePhase_RemovesPhaseAndReorders() {
        // Given
        viewModel.phases = [
            ProgramPhase(name: "Phase 1", durationWeeks: 2, sessions: [], order: 1),
            ProgramPhase(name: "Phase 2", durationWeeks: 3, sessions: [], order: 2),
            ProgramPhase(name: "Phase 3", durationWeeks: 4, sessions: [], order: 3)
        ]

        // When
        viewModel.deletePhase(at: IndexSet(integer: 1))

        // Then
        XCTAssertEqual(viewModel.phases.count, 2)
        XCTAssertEqual(viewModel.phases[0].name, "Phase 1")
        XCTAssertEqual(viewModel.phases[1].name, "Phase 3")
        XCTAssertEqual(viewModel.phases[0].order, 1)
        XCTAssertEqual(viewModel.phases[1].order, 2) // Reordered
    }

    // MARK: - Error Handling Tests

    func testCreateProgram_DoubleSubmission_ThrowsError() async throws {
        // Given
        viewModel.programName = "Test Program"
        viewModel.phases = [
            ProgramPhase(name: "Phase 1", durationWeeks: 4, sessions: [], order: 1)
        ]

        // When - Start first creation
        let task1 = Task {
            try await viewModel.createProgram(patientId: nil)
        }

        // Immediately try second creation
        do {
            _ = try await viewModel.createProgram(patientId: nil)
            XCTFail("Should have thrown operation in progress error")
        } catch let error as ProgramBuilderError {
            XCTAssertEqual(error, .operationInProgress)
        }

        // Clean up
        _ = try? await task1.value
    }

    // MARK: - Program Type Tests (BUILD 294)

    func testCreateProgramWithRehabType() async throws {
        // Given
        viewModel.programName = "Rehab Type Test Program"
        viewModel.programType = "rehab"
        viewModel.phases = [
            ProgramPhase(
                name: "Rehab Phase 1",
                durationWeeks: 4,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then
        XCTAssertFalse(programId.isEmpty)

        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.name, "Rehab Type Test Program")
        XCTAssertEqual(program.programType, "rehab")
    }

    func testCreateProgramWithPerformanceType() async throws {
        // Given
        viewModel.programName = "Performance Type Test Program"
        viewModel.programType = "performance"
        viewModel.phases = [
            ProgramPhase(
                name: "Performance Phase 1",
                durationWeeks: 6,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then
        XCTAssertFalse(programId.isEmpty)

        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.name, "Performance Type Test Program")
        XCTAssertEqual(program.programType, "performance")
    }

    func testCreateProgramWithLifestyleType() async throws {
        // Given
        viewModel.programName = "Lifestyle Type Test Program"
        viewModel.programType = "lifestyle"
        viewModel.phases = [
            ProgramPhase(
                name: "Lifestyle Phase 1",
                durationWeeks: 8,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then
        XCTAssertFalse(programId.isEmpty)

        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.name, "Lifestyle Type Test Program")
        XCTAssertEqual(program.programType, "lifestyle")
    }

    func testProgramTypeDefaultsToRehabWhenOmitted() async throws {
        // Given: Create program without explicitly setting programType
        viewModel.programName = "Default Type Test Program"
        viewModel.phases = [
            ProgramPhase(
                name: "Default Phase",
                durationWeeks: 4,
                sessions: [],
                order: 1
            )
        ]

        // When
        let programId = try await viewModel.createProgram(patientId: nil)

        // Then: Verify it defaults to rehab
        XCTAssertFalse(programId.isEmpty)

        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        XCTAssertEqual(program.name, "Default Type Test Program")
        XCTAssertEqual(program.programType, "rehab", "Program type should default to 'rehab' when not specified")
    }

    func testFilterProgramsByType() async throws {
        // Given: Create programs of different types
        viewModel.programName = "Filter Test Rehab"
        viewModel.programType = "rehab"
        viewModel.phases = [
            ProgramPhase(name: "Phase 1", durationWeeks: 2, sessions: [], order: 1)
        ]
        let rehabId = try await viewModel.createProgram(patientId: nil)
        XCTAssertFalse(rehabId.isEmpty)

        // Reset view model for next creation
        viewModel = ProgramBuilderViewModel(supabase: supabase)
        viewModel.programName = "Filter Test Performance"
        viewModel.programType = "performance"
        viewModel.phases = [
            ProgramPhase(name: "Phase 1", durationWeeks: 2, sessions: [], order: 1)
        ]
        let performanceId = try await viewModel.createProgram(patientId: nil)
        XCTAssertFalse(performanceId.isEmpty)

        // When: Query programs filtered by program_type = "rehab"
        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("program_type", value: "rehab")
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let programs = try decoder.decode([Program].self, from: response.data)

        // Then: All returned programs should have rehab type
        XCTAssertFalse(programs.isEmpty, "Should return at least one rehab program")
        for program in programs {
            XCTAssertEqual(program.programType, "rehab", "Filtered programs should all be rehab type")
        }
    }

    func testProgramTypePersistedInSupabase() async throws {
        // Given: Create a program with a specific type
        viewModel.programName = "Persistence Test Program"
        viewModel.programType = "performance"
        viewModel.phases = [
            ProgramPhase(
                name: "Persistence Phase",
                durationWeeks: 3,
                sessions: [],
                order: 1
            )
        ]

        // When: Create and then re-fetch
        let programId = try await viewModel.createProgram(patientId: nil)
        XCTAssertFalse(programId.isEmpty)

        // Re-fetch from Supabase to verify persistence
        let response = try await supabase.client
            .from("programs")
            .select()
            .eq("id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let program = try decoder.decode(Program.self, from: response.data)

        // Then: Type should be persisted correctly
        XCTAssertEqual(program.id, programId)
        XCTAssertEqual(program.name, "Persistence Test Program")
        XCTAssertEqual(program.programType, "performance", "Program type 'performance' should persist in Supabase")
    }

    // MARK: - Cleanup

    override func tearDownWithError() throws {
        // Clean up test data
        // Note: In production, implement proper cleanup of test programs
        try super.tearDownWithError()
    }
}
