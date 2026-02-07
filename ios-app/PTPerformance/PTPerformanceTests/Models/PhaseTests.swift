//
//  PhaseTests.swift
//  PTPerformanceTests
//
//  Unit tests for Phase and ProgramPhasePreview models.
//  Tests phase sequencing, relationships, and advancement logic.
//

import XCTest
@testable import PTPerformance

// MARK: - Phase Model Tests

final class PhaseModelTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testPhase_Initialization() {
        let id = UUID()
        let programId = UUID()

        let phase = Phase(
            id: id,
            programId: programId,
            phaseNumber: 1,
            name: "Foundation Phase",
            durationWeeks: 4,
            goals: "Build base strength and movement patterns"
        )

        XCTAssertEqual(phase.id, id)
        XCTAssertEqual(phase.programId, programId)
        XCTAssertEqual(phase.phaseNumber, 1)
        XCTAssertEqual(phase.name, "Foundation Phase")
        XCTAssertEqual(phase.durationWeeks, 4)
        XCTAssertEqual(phase.goals, "Build base strength and movement patterns")
    }

    func testPhase_Identifiable() {
        let phase = createMockPhase()
        XCTAssertNotNil(phase.id, "Phase should have an id for Identifiable conformance")
    }

    func testPhase_Hashable() {
        let phase1 = createMockPhase(phaseNumber: 1)
        let phase2 = createMockPhase(phaseNumber: 2)

        var set = Set<Phase>()
        set.insert(phase1)
        set.insert(phase2)

        XCTAssertEqual(set.count, 2, "Different phases should have different hashes")
    }

    func testPhase_Equatable_SameValues() {
        let id = UUID()
        let programId = UUID()

        let phase1 = Phase(
            id: id,
            programId: programId,
            phaseNumber: 1,
            name: "Phase 1",
            durationWeeks: 4,
            goals: "Test goals"
        )

        let phase2 = Phase(
            id: id,
            programId: programId,
            phaseNumber: 1,
            name: "Phase 1",
            durationWeeks: 4,
            goals: "Test goals"
        )

        XCTAssertEqual(phase1, phase2, "Phases with same values should be equal")
    }

    func testPhase_Equatable_DifferentIds() {
        let phase1 = createMockPhase()
        let phase2 = createMockPhase()

        XCTAssertNotEqual(phase1, phase2, "Phases with different IDs should not be equal")
    }

    // MARK: - Sequencing Tests

    func testPhase_Sequencing_FirstPhase() {
        let phase = createMockPhase(phaseNumber: 1)
        XCTAssertEqual(phase.phaseNumber, 1, "First phase should have phaseNumber 1")
    }

    func testPhase_Sequencing_MiddlePhases() {
        let phase2 = createMockPhase(phaseNumber: 2)
        let phase3 = createMockPhase(phaseNumber: 3)

        XCTAssertEqual(phase2.phaseNumber, 2)
        XCTAssertEqual(phase3.phaseNumber, 3)
        XCTAssertTrue(phase2.phaseNumber < phase3.phaseNumber)
    }

    func testPhase_Sequencing_Sorting() {
        let phase1 = createMockPhase(phaseNumber: 1)
        let phase2 = createMockPhase(phaseNumber: 2)
        let phase3 = createMockPhase(phaseNumber: 3)
        let phase4 = createMockPhase(phaseNumber: 4)

        var phases = [phase3, phase1, phase4, phase2]
        phases.sort { $0.phaseNumber < $1.phaseNumber }

        XCTAssertEqual(phases[0].phaseNumber, 1)
        XCTAssertEqual(phases[1].phaseNumber, 2)
        XCTAssertEqual(phases[2].phaseNumber, 3)
        XCTAssertEqual(phases[3].phaseNumber, 4)
    }

    func testPhase_Sequencing_LargeNumber() {
        let phase = createMockPhase(phaseNumber: 52)
        XCTAssertEqual(phase.phaseNumber, 52, "Should support up to 52 weeks/phases")
    }

    // MARK: - Duration Tests

    func testPhase_Duration_Standard() {
        let phase = createMockPhase(durationWeeks: 4)
        XCTAssertEqual(phase.durationWeeks, 4)
    }

    func testPhase_Duration_Nil() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Test Phase",
            durationWeeks: nil,
            goals: nil
        )

        XCTAssertNil(phase.durationWeeks, "Duration can be nil in database")
    }

    func testPhase_Duration_SingleWeek() {
        let phase = createMockPhase(durationWeeks: 1)
        XCTAssertEqual(phase.durationWeeks, 1)
    }

    func testPhase_Duration_LongDuration() {
        let phase = createMockPhase(durationWeeks: 12)
        XCTAssertEqual(phase.durationWeeks, 12)
    }

    // MARK: - Goals Tests

    func testPhase_Goals_Present() {
        let goals = "Build foundational strength and establish proper movement patterns"
        let phase = createMockPhase(goals: goals)
        XCTAssertEqual(phase.goals, goals)
    }

    func testPhase_Goals_Nil() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Test Phase",
            durationWeeks: 4,
            goals: nil
        )

        XCTAssertNil(phase.goals)
    }

    func testPhase_Goals_Empty() {
        let phase = createMockPhase(goals: "")
        XCTAssertEqual(phase.goals, "")
    }

    func testPhase_Goals_Long() {
        let longGoals = String(repeating: "Goal description. ", count: 100)
        let phase = createMockPhase(goals: longGoals)
        XCTAssertEqual(phase.goals, longGoals)
    }

    // MARK: - Program Relationship Tests

    func testPhase_ProgramRelationship() {
        let programId = UUID()
        let phase1 = createMockPhase(programId: programId, phaseNumber: 1)
        let phase2 = createMockPhase(programId: programId, phaseNumber: 2)
        let phase3 = createMockPhase(programId: programId, phaseNumber: 3)

        XCTAssertEqual(phase1.programId, programId)
        XCTAssertEqual(phase2.programId, programId)
        XCTAssertEqual(phase3.programId, programId)
    }

    func testPhase_DifferentPrograms() {
        let program1Id = UUID()
        let program2Id = UUID()

        let phase1 = createMockPhase(programId: program1Id, phaseNumber: 1)
        let phase2 = createMockPhase(programId: program2Id, phaseNumber: 1)

        XCTAssertNotEqual(phase1.programId, phase2.programId)
    }

    // MARK: - Encoding/Decoding Tests

    func testPhase_Encoding() throws {
        let phase = createMockPhase()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let data = try encoder.encode(phase)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("program_id"), "Should use snake_case for program_id")
        XCTAssertTrue(jsonString!.contains("phase_number"), "Should use snake_case for phase_number")
        XCTAssertTrue(jsonString!.contains("duration_weeks"), "Should use snake_case for duration_weeks")
    }

    func testPhase_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "program_id": "550e8400-e29b-41d4-a716-446655440001",
            "phase_number": 2,
            "name": "Strength Building",
            "duration_weeks": 6,
            "goals": "Increase load progressively"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Note: Phase has explicit CodingKeys, no keyDecodingStrategy needed

        let phase = try decoder.decode(Phase.self, from: json)

        XCTAssertEqual(phase.phaseNumber, 2)
        XCTAssertEqual(phase.name, "Strength Building")
        XCTAssertEqual(phase.durationWeeks, 6)
        XCTAssertEqual(phase.goals, "Increase load progressively")
    }

    func testPhase_Decoding_WithOptionalFieldsNil() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "program_id": "550e8400-e29b-41d4-a716-446655440001",
            "phase_number": 1,
            "name": "Basic Phase"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Note: Phase has explicit CodingKeys, no keyDecodingStrategy needed

        let phase = try decoder.decode(Phase.self, from: json)

        XCTAssertNil(phase.durationWeeks)
        XCTAssertNil(phase.goals)
    }

    func testPhase_RoundTrip() throws {
        let original = createMockPhase(
            phaseNumber: 3,
            name: "Peak Performance",
            durationWeeks: 3,
            goals: "Maximize performance before taper"
        )

        // Phase has explicit CodingKeys that handle snake_case encoding/decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Phase.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.programId, decoded.programId)
        XCTAssertEqual(original.phaseNumber, decoded.phaseNumber)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.durationWeeks, decoded.durationWeeks)
        XCTAssertEqual(original.goals, decoded.goals)
    }

    // MARK: - Edge Cases

    func testPhase_EmptyName() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "",
            durationWeeks: 4,
            goals: nil
        )

        XCTAssertEqual(phase.name, "")
    }

    func testPhase_ZeroDuration() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Zero Duration Phase",
            durationWeeks: 0,
            goals: nil
        )

        XCTAssertEqual(phase.durationWeeks, 0)
    }

    func testPhase_ZeroPhaseNumber() {
        // Edge case: phase number should typically start at 1
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 0,
            name: "Pre-Phase",
            durationWeeks: 1,
            goals: nil
        )

        XCTAssertEqual(phase.phaseNumber, 0)
    }

    // MARK: - Helper Methods

    private func createMockPhase(
        id: UUID = UUID(),
        programId: UUID = UUID(),
        phaseNumber: Int = 1,
        name: String = "Test Phase",
        durationWeeks: Int? = 4,
        goals: String? = "Test goals"
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
}

// MARK: - ProgramPhasePreview Tests

final class ProgramPhasePreviewTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testProgramPhasePreview_Initialization() {
        let id = UUID()

        let preview = ProgramPhasePreview(
            id: id,
            phaseName: "Foundation",
            phaseNumber: 1,
            weekStart: 1,
            weekEnd: 4,
            workoutCount: 12,
            description: "Build foundational strength"
        )

        XCTAssertEqual(preview.id, id)
        XCTAssertEqual(preview.phaseName, "Foundation")
        XCTAssertEqual(preview.phaseNumber, 1)
        XCTAssertEqual(preview.weekStart, 1)
        XCTAssertEqual(preview.weekEnd, 4)
        XCTAssertEqual(preview.workoutCount, 12)
        XCTAssertEqual(preview.description, "Build foundational strength")
    }

    // MARK: - Computed Properties Tests

    func testProgramPhasePreview_FormattedWeekRange_MultipleWeeks() {
        let preview = createMockPhasePreview(weekStart: 1, weekEnd: 4)
        XCTAssertEqual(preview.formattedWeekRange, "Weeks 1-4")
    }

    func testProgramPhasePreview_FormattedWeekRange_SingleWeek() {
        let preview = createMockPhasePreview(weekStart: 5, weekEnd: 5)
        XCTAssertEqual(preview.formattedWeekRange, "Week 5")
    }

    func testProgramPhasePreview_FormattedWeekRange_TwoWeeks() {
        let preview = createMockPhasePreview(weekStart: 3, weekEnd: 4)
        XCTAssertEqual(preview.formattedWeekRange, "Weeks 3-4")
    }

    func testProgramPhasePreview_DurationWeeks_CalculatesCorrectly() {
        let preview = createMockPhasePreview(weekStart: 1, weekEnd: 4)
        XCTAssertEqual(preview.durationWeeks, 4, "Weeks 1-4 should be 4 weeks duration")
    }

    func testProgramPhasePreview_DurationWeeks_SingleWeek() {
        let preview = createMockPhasePreview(weekStart: 5, weekEnd: 5)
        XCTAssertEqual(preview.durationWeeks, 1, "Week 5-5 should be 1 week duration")
    }

    func testProgramPhasePreview_DurationWeeks_LongPhase() {
        let preview = createMockPhasePreview(weekStart: 1, weekEnd: 12)
        XCTAssertEqual(preview.durationWeeks, 12, "Weeks 1-12 should be 12 weeks duration")
    }

    func testProgramPhasePreview_DurationWeeks_MidProgram() {
        let preview = createMockPhasePreview(weekStart: 5, weekEnd: 8)
        XCTAssertEqual(preview.durationWeeks, 4, "Weeks 5-8 should be 4 weeks duration")
    }

    // MARK: - Encoding/Decoding Tests

    func testProgramPhasePreview_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "phase_name": "Strength Building",
            "phase_number": 2,
            "week_start": 5,
            "week_end": 8,
            "workout_count": 16,
            "description": "Progressive overload phase"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Note: ProgramPhasePreview has explicit CodingKeys, no keyDecodingStrategy needed

        let preview = try decoder.decode(ProgramPhasePreview.self, from: json)

        XCTAssertEqual(preview.phaseName, "Strength Building")
        XCTAssertEqual(preview.phaseNumber, 2)
        XCTAssertEqual(preview.weekStart, 5)
        XCTAssertEqual(preview.weekEnd, 8)
        XCTAssertEqual(preview.workoutCount, 16)
        XCTAssertEqual(preview.formattedWeekRange, "Weeks 5-8")
        XCTAssertEqual(preview.durationWeeks, 4)
    }

    func testProgramPhasePreview_Decoding_WithNilDescription() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "phase_name": "Basic Phase",
            "phase_number": 1,
            "week_start": 1,
            "week_end": 4,
            "workout_count": 12
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Note: ProgramPhasePreview has explicit CodingKeys, no keyDecodingStrategy needed

        let preview = try decoder.decode(ProgramPhasePreview.self, from: json)

        XCTAssertNil(preview.description)
    }

    func testProgramPhasePreview_Encoding() throws {
        let preview = createMockPhasePreview()
        // ProgramPhasePreview has explicit CodingKeys that encode to snake_case
        let encoder = JSONEncoder()

        let data = try encoder.encode(preview)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("phase_name"))
        XCTAssertTrue(jsonString!.contains("phase_number"))
        XCTAssertTrue(jsonString!.contains("week_start"))
        XCTAssertTrue(jsonString!.contains("week_end"))
        XCTAssertTrue(jsonString!.contains("workout_count"))
    }

    // MARK: - Identifiable/Hashable/Equatable Tests

    func testProgramPhasePreview_Identifiable() {
        let preview = createMockPhasePreview()
        XCTAssertNotNil(preview.id)
    }

    func testProgramPhasePreview_Hashable() {
        let preview1 = createMockPhasePreview(phaseNumber: 1)
        let preview2 = createMockPhasePreview(phaseNumber: 2)

        var set = Set<ProgramPhasePreview>()
        set.insert(preview1)
        set.insert(preview2)

        XCTAssertEqual(set.count, 2)
    }

    func testProgramPhasePreview_Equatable() {
        let id = UUID()

        let preview1 = ProgramPhasePreview(
            id: id,
            phaseName: "Test",
            phaseNumber: 1,
            weekStart: 1,
            weekEnd: 4,
            workoutCount: 12,
            description: nil
        )

        let preview2 = ProgramPhasePreview(
            id: id,
            phaseName: "Test",
            phaseNumber: 1,
            weekStart: 1,
            weekEnd: 4,
            workoutCount: 12,
            description: nil
        )

        XCTAssertEqual(preview1, preview2)
    }

    // MARK: - Phase Sequence Tests

    func testProgramPhasePreview_MultiplePhases_InSequence() {
        let phase1 = createMockPhasePreview(phaseNumber: 1, weekStart: 1, weekEnd: 4)
        let phase2 = createMockPhasePreview(phaseNumber: 2, weekStart: 5, weekEnd: 8)
        let phase3 = createMockPhasePreview(phaseNumber: 3, weekStart: 9, weekEnd: 12)

        // Verify phases are sequential
        XCTAssertEqual(phase1.weekEnd + 1, phase2.weekStart)
        XCTAssertEqual(phase2.weekEnd + 1, phase3.weekStart)

        // Verify total duration
        let totalDuration = phase1.durationWeeks + phase2.durationWeeks + phase3.durationWeeks
        XCTAssertEqual(totalDuration, 12)
    }

    func testProgramPhasePreview_Sorting() {
        let phase1 = createMockPhasePreview(phaseNumber: 1, weekStart: 1, weekEnd: 4)
        let phase2 = createMockPhasePreview(phaseNumber: 2, weekStart: 5, weekEnd: 8)
        let phase3 = createMockPhasePreview(phaseNumber: 3, weekStart: 9, weekEnd: 12)

        var phases = [phase3, phase1, phase2]
        phases.sort { $0.phaseNumber < $1.phaseNumber }

        XCTAssertEqual(phases[0].phaseNumber, 1)
        XCTAssertEqual(phases[1].phaseNumber, 2)
        XCTAssertEqual(phases[2].phaseNumber, 3)
    }

    // MARK: - Helper Methods

    private func createMockPhasePreview(
        id: UUID = UUID(),
        phaseName: String = "Test Phase",
        phaseNumber: Int = 1,
        weekStart: Int = 1,
        weekEnd: Int = 4,
        workoutCount: Int = 12,
        description: String? = "Test description"
    ) -> ProgramPhasePreview {
        ProgramPhasePreview(
            id: id,
            phaseName: phaseName,
            phaseNumber: phaseNumber,
            weekStart: weekStart,
            weekEnd: weekEnd,
            workoutCount: workoutCount,
            description: description
        )
    }
}

// MARK: - Phase Sequencing Integration Tests

final class PhaseSequencingTests: XCTestCase {

    func testPhaseSequencing_StandardProgram() {
        // Typical 12-week program with 3 phases
        let programId = UUID()

        let phase1 = Phase(
            id: UUID(),
            programId: programId,
            phaseNumber: 1,
            name: "Foundation",
            durationWeeks: 4,
            goals: "Build base"
        )

        let phase2 = Phase(
            id: UUID(),
            programId: programId,
            phaseNumber: 2,
            name: "Build",
            durationWeeks: 4,
            goals: "Progressive overload"
        )

        let phase3 = Phase(
            id: UUID(),
            programId: programId,
            phaseNumber: 3,
            name: "Peak",
            durationWeeks: 4,
            goals: "Maximum performance"
        )

        let phases = [phase1, phase2, phase3]
        let totalDuration = phases.compactMap { $0.durationWeeks }.reduce(0, +)

        XCTAssertEqual(phases.count, 3)
        XCTAssertEqual(totalDuration, 12)
    }

    func testPhaseSequencing_SinglePhaseProgram() {
        let programId = UUID()

        let phase = Phase(
            id: UUID(),
            programId: programId,
            phaseNumber: 1,
            name: "Complete Program",
            durationWeeks: 8,
            goals: "Full body conditioning"
        )

        XCTAssertEqual(phase.phaseNumber, 1)
        XCTAssertEqual(phase.durationWeeks, 8)
    }

    func testPhaseSequencing_ManyPhases() {
        let programId = UUID()
        var phases: [Phase] = []

        for i in 1...6 {
            let phase = Phase(
                id: UUID(),
                programId: programId,
                phaseNumber: i,
                name: "Phase \(i)",
                durationWeeks: 2,
                goals: "Phase \(i) goals"
            )
            phases.append(phase)
        }

        XCTAssertEqual(phases.count, 6)
        XCTAssertEqual(phases.first?.phaseNumber, 1)
        XCTAssertEqual(phases.last?.phaseNumber, 6)

        let totalDuration = phases.compactMap { $0.durationWeeks }.reduce(0, +)
        XCTAssertEqual(totalDuration, 12)
    }

    func testPhaseSequencing_VariableDurations() {
        let programId = UUID()

        let phases = [
            Phase(id: UUID(), programId: programId, phaseNumber: 1, name: "Intro", durationWeeks: 2, goals: nil),
            Phase(id: UUID(), programId: programId, phaseNumber: 2, name: "Build", durationWeeks: 6, goals: nil),
            Phase(id: UUID(), programId: programId, phaseNumber: 3, name: "Peak", durationWeeks: 3, goals: nil),
            Phase(id: UUID(), programId: programId, phaseNumber: 4, name: "Taper", durationWeeks: 1, goals: nil)
        ]

        let totalDuration = phases.compactMap { $0.durationWeeks }.reduce(0, +)
        XCTAssertEqual(totalDuration, 12)

        // Verify increasing phase numbers
        for i in 0..<phases.count - 1 {
            XCTAssertLessThan(phases[i].phaseNumber, phases[i + 1].phaseNumber)
        }
    }
}
