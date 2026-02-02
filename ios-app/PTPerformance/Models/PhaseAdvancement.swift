import Foundation

/// Represents a phase advancement decision in a training program
struct PhaseAdvancement: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let patientId: String
    let programId: String
    let fromPhaseId: String?
    let toPhaseId: String?

    // Advancement decision
    let decision: AdvancementDecision
    let decisionDate: Date

    // Gate checks
    let gatesChecked: [String: GateResult]
    let gatesPassed: Int
    let gatesTotal: Int

    // Override
    let manualOverride: Bool
    let overrideReason: String?
    let overrideBy: String?  // therapist_id

    // Next actions
    let nextPhaseStartDate: Date?
    let extensionWeeks: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programId = "program_id"
        case fromPhaseId = "from_phase_id"
        case toPhaseId = "to_phase_id"
        case decision
        case decisionDate = "decision_date"
        case gatesChecked = "gates_checked"
        case gatesPassed = "gates_passed"
        case gatesTotal = "gates_total"
        case manualOverride = "manual_override"
        case overrideReason = "override_reason"
        case overrideBy = "override_by"
        case nextPhaseStartDate = "next_phase_start_date"
        case extensionWeeks = "extension_weeks"
    }
}

/// Phase advancement decision types
enum AdvancementDecision: String, Codable {
    case advance
    case extend
    case deloadRetry = "deload_retry"
    case manualOverride = "manual_override"

    var description: String {
        switch self {
        case .advance:
            return "Advance to next phase"
        case .extend:
            return "Extend current phase"
        case .deloadRetry:
            return "Deload and retry current phase"
        case .manualOverride:
            return "Manual override by therapist"
        }
    }
}

/// Result of a single phase gate check
struct GateResult: Codable, Hashable, Equatable {
    let gateName: String
    let passed: Bool
    let actualValue: Double?
    let targetValue: Double?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case gateName = "gate_name"
        case passed
        case actualValue = "actual_value"
        case targetValue = "target_value"
        case reason
    }
}

/// Phase gate checker for advancement criteria
struct PhaseGateChecker {

    /// Evaluates all gates for phase advancement
    /// - Parameters:
    ///   - adherenceRate: Session completion rate (0.0-1.0)
    ///   - avgRpe: Average RPE across phase
    ///   - targetRpeRange: Target RPE range for phase
    ///   - maxPainScore: Maximum pain score reported
    ///   - missedRepCount: Number of times reps were missed
    /// - Returns: Dictionary of gate results
    static func evaluateGates(
        adherenceRate: Double,
        avgRpe: Double,
        targetRpeRange: ClosedRange<Double>,
        maxPainScore: Int,
        missedRepCount: Int
    ) -> [String: GateResult] {

        var results: [String: GateResult] = [:]

        // Gate 1: Adherence
        let adherenceThreshold = 0.90
        results["adherence"] = GateResult(
            gateName: "Session Adherence",
            passed: adherenceRate >= adherenceThreshold,
            actualValue: adherenceRate,
            targetValue: adherenceThreshold,
            reason: adherenceRate >= adherenceThreshold
                ? "Completed \(Int(adherenceRate * 100))% of sessions"
                : "Only completed \(Int(adherenceRate * 100))% of sessions (need ≥90%)"
        )

        // Gate 2: RPE Control
        let rpeInRange = targetRpeRange.contains(avgRpe)
        results["rpe_control"] = GateResult(
            gateName: "RPE Control",
            passed: rpeInRange,
            actualValue: avgRpe,
            targetValue: targetRpeRange.upperBound,
            reason: rpeInRange
                ? "Average RPE \(avgRpe) within target range \(targetRpeRange)"
                : "Average RPE \(avgRpe) outside target range \(targetRpeRange)"
        )

        // Gate 3: Pain Management
        let painThreshold = 3
        results["pain_management"] = GateResult(
            gateName: "Pain Management",
            passed: maxPainScore <= painThreshold,
            actualValue: Double(maxPainScore),
            targetValue: Double(painThreshold),
            reason: maxPainScore <= painThreshold
                ? "Pain scores ≤\(painThreshold)/10"
                : "Pain scores exceeded \(painThreshold)/10 (max: \(maxPainScore))"
        )

        // Gate 4: Technical Proficiency (no missed reps)
        results["technical_proficiency"] = GateResult(
            gateName: "Technical Proficiency",
            passed: missedRepCount == 0,
            actualValue: Double(missedRepCount),
            targetValue: 0,
            reason: missedRepCount == 0
                ? "No missed reps on primary lifts"
                : "Missed reps \(missedRepCount) times on primary lifts"
        )

        return results
    }

    /// Determines advancement decision based on gate results
    static func makeDecision(
        gateResults: [String: GateResult],
        currentPhaseWeeks: Int,
        plannedPhaseWeeks: Int
    ) -> AdvancementDecision {

        let passedCount = gateResults.values.filter { $0.passed }.count
        let totalCount = gateResults.count
        let passRate = Double(passedCount) / Double(totalCount)

        // All gates passed - advance
        if passedCount == totalCount {
            return .advance
        }

        // ≥75% gates passed and not past planned duration - extend
        if passRate >= 0.75 && currentPhaseWeeks <= plannedPhaseWeeks {
            return .extend
        }

        // Failed critical gates (adherence or pain) - deload and retry
        if let adherenceGate = gateResults["adherence"], !adherenceGate.passed {
            return .deloadRetry
        }
        if let painGate = gateResults["pain_management"], !painGate.passed {
            return .deloadRetry
        }

        // Default: extend current phase
        return .extend
    }
}

/// Input model for creating a phase advancement log
struct CreatePhaseAdvancementInput: Codable, Equatable {
    let patientId: String
    let programId: String
    let fromPhaseId: String?
    let toPhaseId: String?
    let decision: AdvancementDecision
    let decisionDate: Date
    let gatesChecked: [String: GateResult]
    let gatesPassed: Int
    let gatesTotal: Int
    let manualOverride: Bool
    let overrideReason: String?
    let overrideBy: String?
    let nextPhaseStartDate: Date?
    let extensionWeeks: Int?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case programId = "program_id"
        case fromPhaseId = "from_phase_id"
        case toPhaseId = "to_phase_id"
        case decision
        case decisionDate = "decision_date"
        case gatesChecked = "gates_checked"
        case gatesPassed = "gates_passed"
        case gatesTotal = "gates_total"
        case manualOverride = "manual_override"
        case overrideReason = "override_reason"
        case overrideBy = "override_by"
        case nextPhaseStartDate = "next_phase_start_date"
        case extensionWeeks = "extension_weeks"
    }
}

/// Summary of phase completion readiness
struct PhaseReadinessSummary {
    let currentPhaseId: String
    let nextPhaseId: String?
    let gateResults: [String: GateResult]
    let recommendedDecision: AdvancementDecision
    let canAdvance: Bool
    let blockers: [String]

    var summary: String {
        if canAdvance {
            return "Ready to advance to next phase"
        } else {
            let blockerList = blockers.joined(separator: ", ")
            return "Not ready to advance. Blockers: \(blockerList)"
        }
    }
}
