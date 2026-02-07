//
//  PhaseAdvancementTests.swift
//  PTPerformanceTests
//
//  Unit tests for PhaseAdvancement, AdvancementDecision, GateResult, and PhaseGateChecker.
//  Tests phase progression logic including gate evaluation and decision types.
//

import XCTest
@testable import PTPerformance

// MARK: - PhaseAdvancement Model Tests

final class PhaseAdvancementModelTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testPhaseAdvancement_Initialization() {
        let advancement = createMockPhaseAdvancement()

        XCTAssertNotNil(advancement.id)
        XCTAssertNotNil(advancement.patientId)
        XCTAssertNotNil(advancement.programId)
        XCTAssertEqual(advancement.decision, .advance)
        XCTAssertEqual(advancement.gatesPassed, 4)
        XCTAssertEqual(advancement.gatesTotal, 4)
        XCTAssertFalse(advancement.manualOverride)
    }

    func testPhaseAdvancement_WithFromAndToPhase() {
        let fromPhaseId = UUID().uuidString
        let toPhaseId = UUID().uuidString

        let advancement = PhaseAdvancement(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            programId: UUID().uuidString,
            fromPhaseId: fromPhaseId,
            toPhaseId: toPhaseId,
            decision: .advance,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 4,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: Date(),
            extensionWeeks: nil
        )

        XCTAssertEqual(advancement.fromPhaseId, fromPhaseId)
        XCTAssertEqual(advancement.toPhaseId, toPhaseId)
    }

    func testPhaseAdvancement_WithManualOverride() {
        let therapistId = UUID().uuidString

        let advancement = PhaseAdvancement(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            programId: UUID().uuidString,
            fromPhaseId: nil,
            toPhaseId: nil,
            decision: .manualOverride,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 2,
            gatesTotal: 4,
            manualOverride: true,
            overrideReason: "Patient demonstrated excellent progress",
            overrideBy: therapistId,
            nextPhaseStartDate: Date(),
            extensionWeeks: nil
        )

        XCTAssertTrue(advancement.manualOverride)
        XCTAssertEqual(advancement.overrideReason, "Patient demonstrated excellent progress")
        XCTAssertEqual(advancement.overrideBy, therapistId)
        XCTAssertEqual(advancement.decision, .manualOverride)
    }

    func testPhaseAdvancement_WithExtension() {
        let advancement = PhaseAdvancement(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            programId: UUID().uuidString,
            fromPhaseId: UUID().uuidString,
            toPhaseId: nil,
            decision: .extend,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 3,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: nil,
            extensionWeeks: 2
        )

        XCTAssertEqual(advancement.decision, .extend)
        XCTAssertEqual(advancement.extensionWeeks, 2)
        XCTAssertNil(advancement.toPhaseId)
    }

    // MARK: - Encoding/Decoding Tests

    func testPhaseAdvancement_Decoding() throws {
        let json = """
        {
            "id": "adv-001",
            "patient_id": "patient-001",
            "program_id": "program-001",
            "from_phase_id": "phase-001",
            "to_phase_id": "phase-002",
            "decision": "advance",
            "decision_date": "2024-01-15T12:00:00Z",
            "gates_checked": {},
            "gates_passed": 4,
            "gates_total": 4,
            "manual_override": false,
            "override_reason": null,
            "override_by": null,
            "next_phase_start_date": "2024-01-20T00:00:00Z",
            "extension_weeks": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // PhaseAdvancement has explicit CodingKeys that handle snake_case
        decoder.dateDecodingStrategy = .iso8601

        let advancement = try decoder.decode(PhaseAdvancement.self, from: json)

        XCTAssertEqual(advancement.id, "adv-001")
        XCTAssertEqual(advancement.patientId, "patient-001")
        XCTAssertEqual(advancement.decision, .advance)
        XCTAssertEqual(advancement.gatesPassed, 4)
        XCTAssertEqual(advancement.gatesTotal, 4)
        XCTAssertFalse(advancement.manualOverride)
    }

    func testPhaseAdvancement_Encoding() throws {
        let advancement = createMockPhaseAdvancement()
        // PhaseAdvancement has explicit CodingKeys that encode to snake_case
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(advancement)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("patient_id"))
        XCTAssertTrue(jsonString!.contains("program_id"))
        XCTAssertTrue(jsonString!.contains("gates_passed"))
        XCTAssertTrue(jsonString!.contains("manual_override"))
    }

    // MARK: - Identifiable Tests

    func testPhaseAdvancement_Identifiable() {
        let advancement = createMockPhaseAdvancement()
        XCTAssertNotNil(advancement.id)
    }

    // MARK: - Helper Methods

    private func createMockPhaseAdvancement(
        decision: AdvancementDecision = .advance,
        gatesPassed: Int = 4,
        gatesTotal: Int = 4,
        manualOverride: Bool = false
    ) -> PhaseAdvancement {
        PhaseAdvancement(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            programId: UUID().uuidString,
            fromPhaseId: UUID().uuidString,
            toPhaseId: UUID().uuidString,
            decision: decision,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: gatesPassed,
            gatesTotal: gatesTotal,
            manualOverride: manualOverride,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: Date(),
            extensionWeeks: nil
        )
    }
}

// MARK: - AdvancementDecision Tests

final class AdvancementDecisionTests: XCTestCase {

    func testAdvancementDecision_Advance() {
        let decision = AdvancementDecision.advance
        XCTAssertEqual(decision.rawValue, "advance")
        XCTAssertEqual(decision.description, "Advance to next phase")
    }

    func testAdvancementDecision_Extend() {
        let decision = AdvancementDecision.extend
        XCTAssertEqual(decision.rawValue, "extend")
        XCTAssertEqual(decision.description, "Extend current phase")
    }

    func testAdvancementDecision_DeloadRetry() {
        let decision = AdvancementDecision.deloadRetry
        XCTAssertEqual(decision.rawValue, "deload_retry")
        XCTAssertEqual(decision.description, "Deload and retry current phase")
    }

    func testAdvancementDecision_ManualOverride() {
        let decision = AdvancementDecision.manualOverride
        XCTAssertEqual(decision.rawValue, "manual_override")
        XCTAssertEqual(decision.description, "Manual override by therapist")
    }

    func testAdvancementDecision_Encoding() throws {
        let encoder = JSONEncoder()

        let advanceData = try encoder.encode(AdvancementDecision.advance)
        XCTAssertEqual(String(data: advanceData, encoding: .utf8), "\"advance\"")

        let deloadData = try encoder.encode(AdvancementDecision.deloadRetry)
        XCTAssertEqual(String(data: deloadData, encoding: .utf8), "\"deload_retry\"")
    }

    func testAdvancementDecision_Decoding() throws {
        let decoder = JSONDecoder()

        let advance = try decoder.decode(AdvancementDecision.self, from: "\"advance\"".data(using: .utf8)!)
        XCTAssertEqual(advance, .advance)

        let extend = try decoder.decode(AdvancementDecision.self, from: "\"extend\"".data(using: .utf8)!)
        XCTAssertEqual(extend, .extend)

        let deload = try decoder.decode(AdvancementDecision.self, from: "\"deload_retry\"".data(using: .utf8)!)
        XCTAssertEqual(deload, .deloadRetry)

        let manual = try decoder.decode(AdvancementDecision.self, from: "\"manual_override\"".data(using: .utf8)!)
        XCTAssertEqual(manual, .manualOverride)
    }
}

// MARK: - GateResult Tests

final class GateResultTests: XCTestCase {

    func testGateResult_Passed() {
        let result = GateResult(
            gateName: "Session Adherence",
            passed: true,
            actualValue: 0.95,
            targetValue: 0.90,
            reason: "Completed 95% of sessions"
        )

        XCTAssertEqual(result.gateName, "Session Adherence")
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.actualValue, 0.95)
        XCTAssertEqual(result.targetValue, 0.90)
        XCTAssertNotNil(result.reason)
    }

    func testGateResult_Failed() {
        let result = GateResult(
            gateName: "Pain Management",
            passed: false,
            actualValue: 5.0,
            targetValue: 3.0,
            reason: "Pain scores exceeded 3/10 (max: 5)"
        )

        XCTAssertEqual(result.gateName, "Pain Management")
        XCTAssertFalse(result.passed)
        XCTAssertEqual(result.actualValue, 5.0)
        XCTAssertEqual(result.targetValue, 3.0)
        XCTAssertTrue(result.reason!.contains("exceeded"))
    }

    func testGateResult_Encoding() throws {
        let result = GateResult(
            gateName: "RPE Control",
            passed: true,
            actualValue: 7.0,
            targetValue: 8.0,
            reason: "Average RPE within target range"
        )

        // GateResult has explicit CodingKeys that encode to snake_case
        let encoder = JSONEncoder()

        let data = try encoder.encode(result)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("gate_name"))
        XCTAssertTrue(jsonString!.contains("actual_value"))
        XCTAssertTrue(jsonString!.contains("target_value"))
    }

    func testGateResult_Decoding() throws {
        let json = """
        {
            "gate_name": "Technical Proficiency",
            "passed": true,
            "actual_value": 0.0,
            "target_value": 0.0,
            "reason": "No missed reps on primary lifts"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // GateResult has explicit CodingKeys that handle snake_case

        let result = try decoder.decode(GateResult.self, from: json)

        XCTAssertEqual(result.gateName, "Technical Proficiency")
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.actualValue, 0.0)
    }

    func testGateResult_Hashable() {
        let result1 = GateResult(
            gateName: "Gate 1",
            passed: true,
            actualValue: 1.0,
            targetValue: 1.0,
            reason: nil
        )

        let result2 = GateResult(
            gateName: "Gate 2",
            passed: false,
            actualValue: 0.5,
            targetValue: 1.0,
            reason: nil
        )

        var set = Set<GateResult>()
        set.insert(result1)
        set.insert(result2)

        XCTAssertEqual(set.count, 2)
    }

    func testGateResult_WithNilValues() {
        let result = GateResult(
            gateName: "Manual Check",
            passed: true,
            actualValue: nil,
            targetValue: nil,
            reason: nil
        )

        XCTAssertNil(result.actualValue)
        XCTAssertNil(result.targetValue)
        XCTAssertNil(result.reason)
    }
}

// MARK: - PhaseGateChecker Tests

final class PhaseGateCheckerTests: XCTestCase {

    // MARK: - Gate Evaluation Tests

    func testEvaluateGates_AllPassed() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )

        XCTAssertEqual(results.count, 4)
        XCTAssertTrue(results["adherence"]!.passed, "Adherence should pass at 95%")
        XCTAssertTrue(results["rpe_control"]!.passed, "RPE should pass at 7.0 within 6-8")
        XCTAssertTrue(results["pain_management"]!.passed, "Pain should pass at 2/10")
        XCTAssertTrue(results["technical_proficiency"]!.passed, "Technical should pass with 0 missed reps")
    }

    func testEvaluateGates_AdherenceFailed() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.85,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )

        XCTAssertFalse(results["adherence"]!.passed, "Adherence should fail at 85% (need >=90%)")
        XCTAssertEqual(results["adherence"]!.actualValue, 0.85)
        XCTAssertEqual(results["adherence"]!.targetValue, 0.90)
    }

    func testEvaluateGates_RpeOutOfRange_TooHigh() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 9.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )

        XCTAssertFalse(results["rpe_control"]!.passed, "RPE should fail at 9.0 (range 6-8)")
        XCTAssertEqual(results["rpe_control"]!.actualValue, 9.0)
    }

    func testEvaluateGates_RpeOutOfRange_TooLow() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 4.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )

        XCTAssertFalse(results["rpe_control"]!.passed, "RPE should fail at 4.0 (range 6-8)")
    }

    func testEvaluateGates_PainExceedsThreshold() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 5,
            missedRepCount: 0
        )

        XCTAssertFalse(results["pain_management"]!.passed, "Pain should fail at 5/10 (max 3)")
        XCTAssertEqual(results["pain_management"]!.actualValue, 5.0)
        XCTAssertEqual(results["pain_management"]!.targetValue, 3.0)
    }

    func testEvaluateGates_MissedReps() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 3
        )

        XCTAssertFalse(results["technical_proficiency"]!.passed, "Technical should fail with 3 missed reps")
        XCTAssertEqual(results["technical_proficiency"]!.actualValue, 3.0)
        XCTAssertEqual(results["technical_proficiency"]!.targetValue, 0.0)
    }

    func testEvaluateGates_MultipleFailed() {
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.80,
            avgRpe: 9.5,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 6,
            missedRepCount: 5
        )

        let passedCount = results.values.filter { $0.passed }.count
        XCTAssertEqual(passedCount, 0, "All gates should fail")
    }

    func testEvaluateGates_BoundaryValues_Adherence() {
        // Exactly at threshold
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.90,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )

        XCTAssertTrue(results["adherence"]!.passed, "Adherence should pass at exactly 90%")
    }

    func testEvaluateGates_BoundaryValues_Pain() {
        // Exactly at threshold
        let results = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 7.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 3,
            missedRepCount: 0
        )

        XCTAssertTrue(results["pain_management"]!.passed, "Pain should pass at exactly 3/10")
    }

    func testEvaluateGates_BoundaryValues_RpeAtEdge() {
        // At lower boundary
        let resultsLower = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 6.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )
        XCTAssertTrue(resultsLower["rpe_control"]!.passed, "RPE should pass at lower bound 6.0")

        // At upper boundary
        let resultsUpper = PhaseGateChecker.evaluateGates(
            adherenceRate: 0.95,
            avgRpe: 8.0,
            targetRpeRange: 6.0...8.0,
            maxPainScore: 2,
            missedRepCount: 0
        )
        XCTAssertTrue(resultsUpper["rpe_control"]!.passed, "RPE should pass at upper bound 8.0")
    }

    // MARK: - Decision Making Tests

    func testMakeDecision_AllGatesPassed_Advance() {
        let gateResults = createAllPassedGates()

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        XCTAssertEqual(decision, .advance, "Should advance when all gates pass")
    }

    func testMakeDecision_75PercentPassed_Extend() {
        // 3 of 4 gates passed (75%)
        var gateResults = createAllPassedGates()
        gateResults["technical_proficiency"] = GateResult(
            gateName: "Technical Proficiency",
            passed: false,
            actualValue: 2.0,
            targetValue: 0.0,
            reason: "Missed reps"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 3,
            plannedPhaseWeeks: 4
        )

        XCTAssertEqual(decision, .extend, "Should extend when 75% gates pass and within planned duration")
    }

    func testMakeDecision_AdherenceFailed_DeloadRetry() {
        var gateResults = createAllPassedGates()
        gateResults["adherence"] = GateResult(
            gateName: "Session Adherence",
            passed: false,
            actualValue: 0.80,
            targetValue: 0.90,
            reason: "Low adherence"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        XCTAssertEqual(decision, .deloadRetry, "Should deload retry when adherence fails (critical gate)")
    }

    func testMakeDecision_PainFailed_DeloadRetry() {
        var gateResults = createAllPassedGates()
        gateResults["pain_management"] = GateResult(
            gateName: "Pain Management",
            passed: false,
            actualValue: 6.0,
            targetValue: 3.0,
            reason: "High pain"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        XCTAssertEqual(decision, .deloadRetry, "Should deload retry when pain management fails (critical gate)")
    }

    func testMakeDecision_BothCriticalGatesFailed_DeloadRetry() {
        var gateResults = createAllPassedGates()
        gateResults["adherence"] = GateResult(
            gateName: "Session Adherence",
            passed: false,
            actualValue: 0.70,
            targetValue: 0.90,
            reason: "Very low adherence"
        )
        gateResults["pain_management"] = GateResult(
            gateName: "Pain Management",
            passed: false,
            actualValue: 7.0,
            targetValue: 3.0,
            reason: "Very high pain"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        XCTAssertEqual(decision, .deloadRetry, "Should deload retry when critical gates fail")
    }

    func testMakeDecision_LessThan75Percent_NotCritical_Extend() {
        // 2 of 4 gates passed (50%) - but neither adherence nor pain failed
        var gateResults: [String: GateResult] = [:]
        gateResults["adherence"] = GateResult(
            gateName: "Session Adherence",
            passed: true,
            actualValue: 0.95,
            targetValue: 0.90,
            reason: "Good adherence"
        )
        gateResults["pain_management"] = GateResult(
            gateName: "Pain Management",
            passed: true,
            actualValue: 2.0,
            targetValue: 3.0,
            reason: "Low pain"
        )
        gateResults["rpe_control"] = GateResult(
            gateName: "RPE Control",
            passed: false,
            actualValue: 9.5,
            targetValue: 8.0,
            reason: "RPE too high"
        )
        gateResults["technical_proficiency"] = GateResult(
            gateName: "Technical Proficiency",
            passed: false,
            actualValue: 5.0,
            targetValue: 0.0,
            reason: "Many missed reps"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 3,
            plannedPhaseWeeks: 4
        )

        // 50% passed, not past planned duration - should extend
        XCTAssertEqual(decision, .extend, "Should extend when non-critical gates fail")
    }

    func testMakeDecision_PastPlannedDuration_StillExtends() {
        // More than 75% passed but past planned duration
        var gateResults = createAllPassedGates()
        gateResults["technical_proficiency"] = GateResult(
            gateName: "Technical Proficiency",
            passed: false,
            actualValue: 1.0,
            targetValue: 0.0,
            reason: "Missed reps"
        )

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 6,  // Past planned 4 weeks
            plannedPhaseWeeks: 4
        )

        // 75% passed but past planned duration - still extends since critical gates pass
        XCTAssertEqual(decision, .extend)
    }

    // MARK: - Helper Methods

    private func createAllPassedGates() -> [String: GateResult] {
        var gateResults: [String: GateResult] = [:]

        gateResults["adherence"] = GateResult(
            gateName: "Session Adherence",
            passed: true,
            actualValue: 0.95,
            targetValue: 0.90,
            reason: "Completed 95% of sessions"
        )

        gateResults["rpe_control"] = GateResult(
            gateName: "RPE Control",
            passed: true,
            actualValue: 7.0,
            targetValue: 8.0,
            reason: "Average RPE within target range"
        )

        gateResults["pain_management"] = GateResult(
            gateName: "Pain Management",
            passed: true,
            actualValue: 2.0,
            targetValue: 3.0,
            reason: "Pain scores below threshold"
        )

        gateResults["technical_proficiency"] = GateResult(
            gateName: "Technical Proficiency",
            passed: true,
            actualValue: 0.0,
            targetValue: 0.0,
            reason: "No missed reps"
        )

        return gateResults
    }
}

// MARK: - CreatePhaseAdvancementInput Tests

final class CreatePhaseAdvancementInputTests: XCTestCase {

    func testCreatePhaseAdvancementInput_Initialization() {
        let input = CreatePhaseAdvancementInput(
            patientId: "patient-001",
            programId: "program-001",
            fromPhaseId: "phase-001",
            toPhaseId: "phase-002",
            decision: .advance,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 4,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: Date(),
            extensionWeeks: nil
        )

        XCTAssertEqual(input.patientId, "patient-001")
        XCTAssertEqual(input.programId, "program-001")
        XCTAssertEqual(input.decision, .advance)
        XCTAssertFalse(input.manualOverride)
    }

    func testCreatePhaseAdvancementInput_Encoding() throws {
        let input = CreatePhaseAdvancementInput(
            patientId: "patient-001",
            programId: "program-001",
            fromPhaseId: nil,
            toPhaseId: nil,
            decision: .extend,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 3,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: nil,
            extensionWeeks: 2
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("patient_id"))
        XCTAssertTrue(jsonString!.contains("extension_weeks"))
    }

    func testCreatePhaseAdvancementInput_Equatable() {
        let date = Date()

        let input1 = CreatePhaseAdvancementInput(
            patientId: "patient-001",
            programId: "program-001",
            fromPhaseId: nil,
            toPhaseId: nil,
            decision: .advance,
            decisionDate: date,
            gatesChecked: [:],
            gatesPassed: 4,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: nil,
            extensionWeeks: nil
        )

        let input2 = CreatePhaseAdvancementInput(
            patientId: "patient-001",
            programId: "program-001",
            fromPhaseId: nil,
            toPhaseId: nil,
            decision: .advance,
            decisionDate: date,
            gatesChecked: [:],
            gatesPassed: 4,
            gatesTotal: 4,
            manualOverride: false,
            overrideReason: nil,
            overrideBy: nil,
            nextPhaseStartDate: nil,
            extensionWeeks: nil
        )

        XCTAssertEqual(input1, input2)
    }
}

// MARK: - PhaseReadinessSummary Tests

final class PhaseReadinessSummaryTests: XCTestCase {

    func testPhaseReadinessSummary_CanAdvance() {
        let summary = PhaseReadinessSummary(
            currentPhaseId: "phase-001",
            nextPhaseId: "phase-002",
            gateResults: [:],
            recommendedDecision: .advance,
            canAdvance: true,
            blockers: []
        )

        XCTAssertTrue(summary.canAdvance)
        XCTAssertTrue(summary.blockers.isEmpty)
        XCTAssertEqual(summary.summary, "Ready to advance to next phase")
    }

    func testPhaseReadinessSummary_CannotAdvance() {
        let summary = PhaseReadinessSummary(
            currentPhaseId: "phase-001",
            nextPhaseId: "phase-002",
            gateResults: [:],
            recommendedDecision: .extend,
            canAdvance: false,
            blockers: ["Low adherence", "High pain scores"]
        )

        XCTAssertFalse(summary.canAdvance)
        XCTAssertEqual(summary.blockers.count, 2)
        XCTAssertTrue(summary.summary.contains("Not ready to advance"))
        XCTAssertTrue(summary.summary.contains("Low adherence"))
        XCTAssertTrue(summary.summary.contains("High pain scores"))
    }

    func testPhaseReadinessSummary_SingleBlocker() {
        let summary = PhaseReadinessSummary(
            currentPhaseId: "phase-001",
            nextPhaseId: nil,
            gateResults: [:],
            recommendedDecision: .deloadRetry,
            canAdvance: false,
            blockers: ["Critical pain reported"]
        )

        XCTAssertFalse(summary.canAdvance)
        XCTAssertNil(summary.nextPhaseId)
        XCTAssertTrue(summary.summary.contains("Critical pain reported"))
    }

    func testPhaseReadinessSummary_WithGateResults() {
        var gateResults: [String: GateResult] = [:]
        gateResults["adherence"] = GateResult(
            gateName: "Adherence",
            passed: true,
            actualValue: 0.95,
            targetValue: 0.90,
            reason: nil
        )
        gateResults["pain"] = GateResult(
            gateName: "Pain",
            passed: false,
            actualValue: 5.0,
            targetValue: 3.0,
            reason: nil
        )

        let summary = PhaseReadinessSummary(
            currentPhaseId: "phase-001",
            nextPhaseId: "phase-002",
            gateResults: gateResults,
            recommendedDecision: .deloadRetry,
            canAdvance: false,
            blockers: ["Pain exceeds threshold"]
        )

        XCTAssertEqual(summary.gateResults.count, 2)
        XCTAssertTrue(summary.gateResults["adherence"]!.passed)
        XCTAssertFalse(summary.gateResults["pain"]!.passed)
    }
}

// MARK: - Phase Progression Edge Cases

final class PhaseProgressionEdgeCaseTests: XCTestCase {

    func testEmptyProgram_NoPhases() {
        // Simulating empty program with no phases
        let phases: [Phase] = []
        XCTAssertTrue(phases.isEmpty)
    }

    func testSinglePhaseProgram() {
        let programId = UUID()
        let phase = Phase(
            id: UUID(),
            programId: programId,
            phaseNumber: 1,
            name: "Only Phase",
            durationWeeks: 12,
            goals: "Complete program"
        )

        // Single phase means no next phase to advance to
        XCTAssertEqual(phase.phaseNumber, 1)
        XCTAssertEqual(phase.durationWeeks, 12)
    }

    func testPhaseWithNoExercises() {
        let phase = Phase(
            id: UUID(),
            programId: UUID(),
            phaseNumber: 1,
            name: "Rest Phase",
            durationWeeks: 1,
            goals: "Active recovery - no structured exercises"
        )

        // Phase can exist without exercises (e.g., deload/rest phase)
        XCTAssertNotNil(phase.id)
    }

    func testCircularDependencyPrevention() {
        // In a well-formed program, phases should have sequential numbers
        // preventing circular dependencies
        let programId = UUID()

        let phase1 = Phase(id: UUID(), programId: programId, phaseNumber: 1, name: "P1", durationWeeks: 4, goals: nil)
        let phase2 = Phase(id: UUID(), programId: programId, phaseNumber: 2, name: "P2", durationWeeks: 4, goals: nil)
        let phase3 = Phase(id: UUID(), programId: programId, phaseNumber: 3, name: "P3", durationWeeks: 4, goals: nil)

        let phases = [phase1, phase2, phase3]

        // Verify no phase points back to an earlier phase
        for i in 1..<phases.count {
            XCTAssertGreaterThan(phases[i].phaseNumber, phases[i - 1].phaseNumber,
                "Phase \(i) should have higher phase number than phase \(i - 1)")
        }
    }

    func testZeroGatesChecked() {
        // Edge case: decision with no gates
        let decision = PhaseGateChecker.makeDecision(
            gateResults: [:],
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        // With 0/0 gates, all gates technically "pass"
        XCTAssertEqual(decision, .advance)
    }

    func testAllGatesFailed_NoCriticalGates() {
        // Construct gates without adherence or pain
        var gateResults: [String: GateResult] = [:]
        gateResults["rpe_control"] = GateResult(gateName: "RPE", passed: false, actualValue: 10.0, targetValue: 8.0, reason: nil)
        gateResults["technical_proficiency"] = GateResult(gateName: "Tech", passed: false, actualValue: 5.0, targetValue: 0.0, reason: nil)

        let decision = PhaseGateChecker.makeDecision(
            gateResults: gateResults,
            currentPhaseWeeks: 4,
            plannedPhaseWeeks: 4
        )

        // 0% passed, no critical gates failed -> extend
        XCTAssertEqual(decision, .extend)
    }

    func testManualOverrideWithReason() {
        let advancement = PhaseAdvancement(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            programId: UUID().uuidString,
            fromPhaseId: UUID().uuidString,
            toPhaseId: UUID().uuidString,
            decision: .manualOverride,
            decisionDate: Date(),
            gatesChecked: [:],
            gatesPassed: 1,
            gatesTotal: 4,
            manualOverride: true,
            overrideReason: "Patient showing excellent functional progress despite gate failures",
            overrideBy: "therapist-001",
            nextPhaseStartDate: Date(),
            extensionWeeks: nil
        )

        XCTAssertTrue(advancement.manualOverride)
        XCTAssertNotNil(advancement.overrideReason)
        XCTAssertNotNil(advancement.overrideBy)
        XCTAssertEqual(advancement.decision, .manualOverride)
    }
}
