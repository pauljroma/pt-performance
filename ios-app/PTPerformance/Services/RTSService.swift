//
//  RTSService.swift
//  PTPerformance
//
//  Service for managing Return-to-Sport database operations with Supabase
//

import Foundation
import Supabase

// MARK: - RTSService Error Types

/// Errors that can occur during RTS service operations
enum RTSServiceError: LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case protocolNotFound
    case phaseNotFound
    case criterionNotFound
    case clearanceNotFound
    case cannotSignClearance
    case cannotCoSignClearance
    case invalidInput(String)
    case insufficientData
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let msg):
            return "Failed to fetch: \(msg)"
        case .saveFailed(let msg):
            return "Failed to save: \(msg)"
        case .protocolNotFound:
            return "RTS protocol not found"
        case .phaseNotFound:
            return "Phase not found"
        case .criterionNotFound:
            return "Milestone criterion not found"
        case .clearanceNotFound:
            return "Clearance document not found"
        case .cannotSignClearance:
            return "Cannot sign clearance - document must be marked complete first"
        case .cannotCoSignClearance:
            return "Cannot co-sign clearance - document must be signed first"
        case .invalidInput(let msg):
            return msg
        case .insufficientData:
            return "Insufficient data to complete operation"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .saveFailed:
            return "Your changes couldn't be saved. Please try again."
        case .protocolNotFound, .phaseNotFound, .criterionNotFound, .clearanceNotFound:
            return "The requested item may have been deleted. Please refresh."
        case .cannotSignClearance:
            return "Mark the clearance as complete before signing."
        case .cannotCoSignClearance:
            return "The primary signature must be completed first."
        case .invalidInput:
            return "Please correct the input and try again."
        case .insufficientData:
            return "Please ensure all required data is provided."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

// MARK: - RTSAdvancementDecision

/// Decision type for phase advancement
enum RTSAdvancementDecision: String, Codable, CaseIterable {
    case advance        // All gates passed
    case extend         // Some gates passed, extend phase
    case hold           // Required gates failed
    case manualOverride // Therapist override with reason

    var displayName: String {
        switch self {
        case .advance: return "Advance"
        case .extend: return "Extend"
        case .hold: return "Hold"
        case .manualOverride: return "Manual Override"
        }
    }
}

// MARK: - RTSPhaseAdvancement

/// Represents a phase advancement decision record
struct RTSPhaseAdvancement: Identifiable, Codable {
    let id: UUID
    let protocolId: UUID
    let fromPhaseId: UUID?
    let toPhaseId: UUID
    let decision: RTSAdvancementDecision
    let decisionReason: String
    let criteriaSummary: RTSCriteriaSummary
    let decidedBy: UUID
    let decidedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case fromPhaseId = "from_phase_id"
        case toPhaseId = "to_phase_id"
        case decision
        case decisionReason = "decision_reason"
        case criteriaSummary = "criteria_summary"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
        case createdAt = "created_at"
    }
}

/// Summary of criteria status at time of advancement decision
struct RTSCriteriaSummary: Codable, Hashable {
    let totalCriteria: Int
    let passedCriteria: Int
    let requiredPassed: Int
    let requiredTotal: Int
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case totalCriteria = "total_criteria"
        case passedCriteria = "passed_criteria"
        case requiredPassed = "required_passed"
        case requiredTotal = "required_total"
        case notes
    }

    init(totalCriteria: Int = 0, passedCriteria: Int = 0, requiredPassed: Int = 0, requiredTotal: Int = 0, notes: String? = nil) {
        self.totalCriteria = totalCriteria
        self.passedCriteria = passedCriteria
        self.requiredPassed = requiredPassed
        self.requiredTotal = requiredTotal
        self.notes = notes
    }
}

// MARK: - RTSService

/// Service for managing Return-to-Sport database operations with Supabase
///
/// Provides comprehensive CRUD operations for RTS protocols, phases, milestone criteria,
/// test results, phase advancements, clearances, and readiness scores.
@MainActor
class RTSService: ObservableObject {

    // MARK: - Singleton

    static let shared = RTSService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let client = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared

    // MARK: - Table Names

    private enum Tables {
        static let sports = "rts_sports"
        static let protocols = "rts_protocols"
        static let phases = "rts_phases"
        static let milestoneCriteria = "rts_milestone_criteria"
        static let testResults = "rts_test_results"
        static let phaseAdvancements = "rts_phase_advancements"
        static let clearances = "rts_clearances"
        static let readinessScores = "rts_readiness_scores"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Sports

    /// Fetch all available sports for RTS protocols
    /// - Returns: Array of RTSSport objects ordered by name
    func fetchSports() async throws -> [RTSSport] {
        isLoading = true
        defer { isLoading = false }

        do {
            let sports: [RTSSport] = try await client
                .from(Tables.sports)
                .select()
                .order("name", ascending: true)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(sports.count) sports")
            #endif

            return sports
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchSports")
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("sports")
        }
    }

    /// Fetch sport by ID
    /// - Parameter id: Sport UUID
    /// - Returns: RTSSport object
    func fetchSport(id: UUID) async throws -> RTSSport {
        isLoading = true
        defer { isLoading = false }

        do {
            let sport: RTSSport = try await client
                .from(Tables.sports)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            return sport
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchSport", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("sport")
        }
    }

    // MARK: - Protocols

    /// Create a new RTS protocol for a patient
    /// - Parameter input: RTSProtocolInput with required fields
    /// - Returns: Created RTSProtocol
    func createProtocol(input: RTSProtocolInput) async throws -> RTSProtocol {
        isLoading = true
        defer { isLoading = false }

        do {
            try input.validate()

            let createdProtocol: RTSProtocol = try await client
                .from(Tables.protocols)
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Created protocol: \(createdProtocol.id)")
            #endif

            return createdProtocol
        } catch let validationError as RTSProtocolError {
            errorMessage = validationError.localizedDescription
            throw validationError
        } catch {
            errorLogger.logError(error, context: "RTSService.createProtocol")
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("protocol")
        }
    }

    /// Fetch all protocols for a therapist
    /// - Parameter therapistId: Therapist UUID
    /// - Returns: Array of RTSProtocol objects ordered by creation date descending
    func fetchProtocols(therapistId: UUID) async throws -> [RTSProtocol] {
        isLoading = true
        defer { isLoading = false }

        do {
            let protocols: [RTSProtocol] = try await client
                .from(Tables.protocols)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(protocols.count) protocols for therapist")
            #endif

            return protocols
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchProtocols", metadata: ["therapistId": therapistId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("protocols")
        }
    }

    /// Fetch all protocols for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Array of RTSProtocol objects ordered by creation date descending
    func fetchProtocolsForPatient(patientId: UUID) async throws -> [RTSProtocol] {
        isLoading = true
        defer { isLoading = false }

        do {
            let protocols: [RTSProtocol] = try await client
                .from(Tables.protocols)
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(protocols.count) protocols for patient")
            #endif

            return protocols
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchProtocolsForPatient", metadata: ["patientId": patientId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("protocols")
        }
    }

    /// Fetch a specific protocol by ID
    /// - Parameter id: Protocol UUID
    /// - Returns: RTSProtocol object
    func fetchProtocol(id: UUID) async throws -> RTSProtocol {
        isLoading = true
        defer { isLoading = false }

        do {
            let rtsProtocol: RTSProtocol = try await client
                .from(Tables.protocols)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            return rtsProtocol
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchProtocol", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.protocolNotFound
        }
    }

    /// Update protocol status
    /// - Parameters:
    ///   - id: Protocol UUID
    ///   - status: New RTSProtocolStatus
    func updateProtocolStatus(id: UUID, status: RTSProtocolStatus) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let update = ProtocolStatusUpdate(
                status: status.rawValue,
                updatedAt: Date().iso8601String
            )

            try await client
                .from(Tables.protocols)
                .update(update)
                .eq("id", value: id.uuidString)
                .execute()

            #if DEBUG
            print("[RTSService] Updated protocol \(id) status to \(status.rawValue)")
            #endif
        } catch {
            errorLogger.logError(error, context: "RTSService.updateProtocolStatus", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("protocol status")
        }
    }

    /// Set actual return date (completion)
    /// - Parameters:
    ///   - id: Protocol UUID
    ///   - returnDate: Actual return date
    func completeProtocol(id: UUID, returnDate: Date) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let update = ProtocolCompletionUpdate(
                status: RTSProtocolStatus.completed.rawValue,
                actualReturnDate: returnDate.iso8601DateString,
                updatedAt: Date().iso8601String
            )

            try await client
                .from(Tables.protocols)
                .update(update)
                .eq("id", value: id.uuidString)
                .execute()

            #if DEBUG
            print("[RTSService] Completed protocol \(id) with return date \(returnDate)")
            #endif
        } catch {
            errorLogger.logError(error, context: "RTSService.completeProtocol", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("protocol completion")
        }
    }

    // MARK: - Phases

    /// Fetch phases for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Array of RTSPhase objects ordered by phase number
    func fetchPhases(protocolId: UUID) async throws -> [RTSPhase] {
        isLoading = true
        defer { isLoading = false }

        do {
            let phases: [RTSPhase] = try await client
                .from(Tables.phases)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("phase_number", ascending: true)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(phases.count) phases for protocol")
            #endif

            return phases
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchPhases", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("phases")
        }
    }

    /// Start a phase (set startedAt)
    /// - Parameter id: Phase UUID
    /// - Returns: Updated RTSPhase
    func startPhase(id: UUID) async throws -> RTSPhase {
        isLoading = true
        defer { isLoading = false }

        do {
            let now = Date()
            let update = PhaseStartUpdate(
                startedAt: now.iso8601String,
                updatedAt: now.iso8601String
            )

            let phase: RTSPhase = try await client
                .from(Tables.phases)
                .update(update)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Started phase \(id)")
            #endif

            return phase
        } catch {
            errorLogger.logError(error, context: "RTSService.startPhase", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.phaseNotFound
        }
    }

    /// Complete a phase (set completedAt)
    /// - Parameter id: Phase UUID
    /// - Returns: Updated RTSPhase
    func completePhase(id: UUID) async throws -> RTSPhase {
        isLoading = true
        defer { isLoading = false }

        do {
            let now = Date()
            let update = PhaseCompleteUpdate(
                completedAt: now.iso8601String,
                updatedAt: now.iso8601String
            )

            let phase: RTSPhase = try await client
                .from(Tables.phases)
                .update(update)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Completed phase \(id)")
            #endif

            return phase
        } catch {
            errorLogger.logError(error, context: "RTSService.completePhase", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.phaseNotFound
        }
    }

    /// Create phases from sport template when protocol is created
    /// - Parameters:
    ///   - protocolId: Protocol UUID
    ///   - templates: Array of RTSPhaseTemplate from sport definition
    func createPhasesFromTemplate(protocolId: UUID, templates: [RTSPhaseTemplate]) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let phaseInputs = templates.map { template -> RTSPhaseInput in
                RTSPhaseInput(
                    protocolId: protocolId.uuidString,
                    phaseNumber: template.phaseNumber,
                    phaseName: template.phaseName,
                    activityLevel: template.activityLevel.rawValue,
                    description: template.description,
                    entryCriteria: [],
                    exitCriteria: [],
                    targetDurationDays: template.targetDurationWeeks.map { $0 * 7 }
                )
            }

            try await client
                .from(Tables.phases)
                .insert(phaseInputs)
                .execute()

            #if DEBUG
            print("[RTSService] Created \(phaseInputs.count) phases from template for protocol \(protocolId)")
            #endif
        } catch {
            errorLogger.logError(error, context: "RTSService.createPhasesFromTemplate", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("phases from template")
        }
    }

    // MARK: - Milestone Criteria

    /// Fetch criteria for a phase
    /// - Parameter phaseId: Phase UUID
    /// - Returns: Array of RTSMilestoneCriterion objects ordered by sort order
    func fetchCriteria(phaseId: UUID) async throws -> [RTSMilestoneCriterion] {
        isLoading = true
        defer { isLoading = false }

        do {
            let criteria: [RTSMilestoneCriterion] = try await client
                .from(Tables.milestoneCriteria)
                .select()
                .eq("phase_id", value: phaseId.uuidString)
                .order("sort_order", ascending: true)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(criteria.count) criteria for phase")
            #endif

            return criteria
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchCriteria", metadata: ["phaseId": phaseId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("criteria")
        }
    }

    /// Add criteria to a phase
    /// - Parameter input: RTSMilestoneCriterionInput with required fields
    /// - Returns: Created RTSMilestoneCriterion
    func addCriterion(input: RTSMilestoneCriterionInput) async throws -> RTSMilestoneCriterion {
        isLoading = true
        defer { isLoading = false }

        do {
            let criterion: RTSMilestoneCriterion = try await client
                .from(Tables.milestoneCriteria)
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Added criterion: \(criterion.id)")
            #endif

            return criterion
        } catch {
            errorLogger.logError(error, context: "RTSService.addCriterion")
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("criterion")
        }
    }

    /// Record a test result for a criterion
    /// - Parameters:
    ///   - criterionId: Criterion UUID
    ///   - protocolId: Protocol UUID
    ///   - value: Measured value
    ///   - unit: Unit of measurement
    ///   - recordedBy: UUID of user recording the result
    ///   - notes: Optional notes
    /// - Returns: Created RTSTestResult
    func recordTestResult(
        criterionId: UUID,
        protocolId: UUID,
        value: Double,
        unit: String,
        recordedBy: UUID,
        notes: String?
    ) async throws -> RTSTestResult {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch criterion to determine if passed
            let criterion: RTSMilestoneCriterion = try await client
                .from(Tables.milestoneCriteria)
                .select()
                .eq("id", value: criterionId.uuidString)
                .single()
                .execute()
                .value

            let passed = criterion.comparisonOperator.evaluate(
                value: value,
                target: criterion.targetValue ?? 0
            )

            let input = RTSTestResultInput(
                criterionId: criterionId.uuidString,
                protocolId: protocolId.uuidString,
                recordedBy: recordedBy.uuidString,
                recordedAt: Date().iso8601String,
                value: value,
                unit: unit,
                passed: passed,
                notes: notes
            )

            let result: RTSTestResult = try await client
                .from(Tables.testResults)
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Recorded test result: \(result.id), passed: \(passed)")
            #endif

            return result
        } catch {
            errorLogger.logError(error, context: "RTSService.recordTestResult", metadata: ["criterionId": criterionId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("test result")
        }
    }

    /// Fetch test results for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Array of RTSTestResult objects ordered by recorded date descending
    func fetchTestResults(protocolId: UUID) async throws -> [RTSTestResult] {
        isLoading = true
        defer { isLoading = false }

        do {
            let results: [RTSTestResult] = try await client
                .from(Tables.testResults)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("recorded_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(results.count) test results for protocol")
            #endif

            return results
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchTestResults", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("test results")
        }
    }

    /// Fetch latest test result for each criterion in a phase
    /// - Parameters:
    ///   - phaseId: Phase UUID
    ///   - protocolId: Protocol UUID
    /// - Returns: Dictionary mapping criterion ID to latest test result
    func fetchLatestResults(phaseId: UUID, protocolId: UUID) async throws -> [UUID: RTSTestResult] {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch criteria for the phase
            let criteria = try await fetchCriteria(phaseId: phaseId)
            let criteriaIds = criteria.map { $0.id.uuidString }

            guard !criteriaIds.isEmpty else {
                return [:]
            }

            // Fetch all results for these criteria in this protocol
            let allResults: [RTSTestResult] = try await client
                .from(Tables.testResults)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .in("criterion_id", values: criteriaIds)
                .order("recorded_at", ascending: false)
                .execute()
                .value

            // Group by criterion and take latest
            var latestResults: [UUID: RTSTestResult] = [:]
            for result in allResults {
                if latestResults[result.criterionId] == nil {
                    latestResults[result.criterionId] = result
                }
            }

            #if DEBUG
            print("[RTSService] Fetched latest results for \(latestResults.count) criteria")
            #endif

            return latestResults
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchLatestResults", metadata: ["phaseId": phaseId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("latest results")
        }
    }

    // MARK: - Phase Advancement

    /// Record a phase advancement decision
    /// - Parameters:
    ///   - protocolId: Protocol UUID
    ///   - fromPhaseId: Previous phase UUID (nil if starting)
    ///   - toPhaseId: Target phase UUID
    ///   - decision: RTSAdvancementDecision
    ///   - reason: Reason for the decision
    ///   - criteriaSummary: Dictionary of criteria results
    ///   - decidedBy: UUID of user making decision
    /// - Returns: Created RTSPhaseAdvancement
    func recordAdvancement(
        protocolId: UUID,
        fromPhaseId: UUID?,
        toPhaseId: UUID,
        decision: RTSAdvancementDecision,
        reason: String,
        criteriaSummary: RTSCriteriaSummary,
        decidedBy: UUID
    ) async throws -> RTSPhaseAdvancement {
        isLoading = true
        defer { isLoading = false }

        do {
            let now = Date()
            let input = PhaseAdvancementInput(
                protocolId: protocolId.uuidString,
                fromPhaseId: fromPhaseId?.uuidString,
                toPhaseId: toPhaseId.uuidString,
                decision: decision.rawValue,
                decisionReason: reason,
                criteriaSummary: criteriaSummary,
                decidedBy: decidedBy.uuidString,
                decidedAt: now.iso8601String
            )

            let advancement: RTSPhaseAdvancement = try await client
                .from(Tables.phaseAdvancements)
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            // Update protocol's current phase
            if decision == .advance {
                let protocolUpdate = ProtocolPhaseUpdate(
                    currentPhaseId: toPhaseId.uuidString,
                    updatedAt: now.iso8601String
                )
                try await client
                    .from(Tables.protocols)
                    .update(protocolUpdate)
                    .eq("id", value: protocolId.uuidString)
                    .execute()
            }

            #if DEBUG
            print("[RTSService] Recorded advancement: \(advancement.id), decision: \(decision.rawValue)")
            #endif

            return advancement
        } catch {
            errorLogger.logError(error, context: "RTSService.recordAdvancement", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("phase advancement")
        }
    }

    /// Fetch advancement history for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Array of RTSPhaseAdvancement objects ordered by date descending
    func fetchAdvancements(protocolId: UUID) async throws -> [RTSPhaseAdvancement] {
        isLoading = true
        defer { isLoading = false }

        do {
            let advancements: [RTSPhaseAdvancement] = try await client
                .from(Tables.phaseAdvancements)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("decided_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(advancements.count) advancements for protocol")
            #endif

            return advancements
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchAdvancements", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("advancements")
        }
    }

    // MARK: - Clearances

    /// Create a clearance document
    /// - Parameter input: RTSClearanceInput with required fields
    /// - Returns: Created RTSClearance
    func createClearance(input: RTSClearanceInput) async throws -> RTSClearance {
        isLoading = true
        defer { isLoading = false }

        do {
            try input.validate()

            let clearance: RTSClearance = try await client
                .from(Tables.clearances)
                .insert(input)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Created clearance: \(clearance.id)")
            #endif

            return clearance
        } catch let validationError as RTSClearanceError {
            errorMessage = validationError.localizedDescription
            throw validationError
        } catch {
            errorLogger.logError(error, context: "RTSService.createClearance")
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("clearance")
        }
    }

    /// Fetch clearances for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Array of RTSClearance objects ordered by creation date descending
    func fetchClearances(protocolId: UUID) async throws -> [RTSClearance] {
        isLoading = true
        defer { isLoading = false }

        do {
            let clearances: [RTSClearance] = try await client
                .from(Tables.clearances)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(clearances.count) clearances for protocol")
            #endif

            return clearances
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchClearances", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("clearances")
        }
    }

    /// Update clearance content (draft only)
    /// - Parameters:
    ///   - id: Clearance UUID
    ///   - input: RTSClearanceInput with updated fields
    /// - Returns: Updated RTSClearance
    func updateClearance(id: UUID, input: RTSClearanceInput) async throws -> RTSClearance {
        isLoading = true
        defer { isLoading = false }

        do {
            // Verify clearance is still a draft
            let existing: RTSClearance = try await client
                .from(Tables.clearances)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            guard existing.status == .draft else {
                throw RTSClearanceError.cannotEditSigned
            }

            let clearance: RTSClearance = try await client
                .from(Tables.clearances)
                .update(input)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Updated clearance: \(clearance.id)")
            #endif

            return clearance
        } catch let clearanceError as RTSClearanceError {
            errorMessage = clearanceError.localizedDescription
            throw clearanceError
        } catch {
            errorLogger.logError(error, context: "RTSService.updateClearance", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("clearance update")
        }
    }

    /// Mark clearance as complete (ready for signature)
    /// - Parameter id: Clearance UUID
    /// - Returns: Updated RTSClearance
    func completeClearance(id: UUID) async throws -> RTSClearance {
        isLoading = true
        defer { isLoading = false }

        do {
            let update = ClearanceStatusUpdate(
                status: RTSClearanceStatus.complete.rawValue,
                updatedAt: Date().iso8601String
            )

            let clearance: RTSClearance = try await client
                .from(Tables.clearances)
                .update(update)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Marked clearance \(id) as complete")
            #endif

            return clearance
        } catch {
            errorLogger.logError(error, context: "RTSService.completeClearance", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("clearance completion")
        }
    }

    /// Sign a clearance (locks it)
    /// - Parameters:
    ///   - id: Clearance UUID
    ///   - signedBy: UUID of signer
    /// - Returns: Updated RTSClearance
    func signClearance(id: UUID, signedBy: UUID) async throws -> RTSClearance {
        isLoading = true
        defer { isLoading = false }

        do {
            // Verify clearance is complete and ready for signature
            let existing: RTSClearance = try await client
                .from(Tables.clearances)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            guard existing.status == .complete else {
                throw RTSServiceError.cannotSignClearance
            }

            let now = Date()
            let update = ClearanceSignatureUpdate(
                status: RTSClearanceStatus.signed.rawValue,
                signedBy: signedBy.uuidString,
                signedAt: now.iso8601String,
                updatedAt: now.iso8601String
            )

            let clearance: RTSClearance = try await client
                .from(Tables.clearances)
                .update(update)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Signed clearance \(id)")
            #endif

            return clearance
        } catch let serviceError as RTSServiceError {
            errorMessage = serviceError.localizedDescription
            throw serviceError
        } catch {
            errorLogger.logError(error, context: "RTSService.signClearance", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("clearance signature")
        }
    }

    /// Co-sign a clearance (physician signature)
    /// - Parameters:
    ///   - id: Clearance UUID
    ///   - coSignedBy: UUID of co-signer (physician)
    /// - Returns: Updated RTSClearance
    func coSignClearance(id: UUID, coSignedBy: UUID) async throws -> RTSClearance {
        isLoading = true
        defer { isLoading = false }

        do {
            // Verify clearance is signed and requires co-signature
            let existing: RTSClearance = try await client
                .from(Tables.clearances)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            guard existing.status == .signed, existing.requiresPhysicianSignature else {
                throw RTSServiceError.cannotCoSignClearance
            }

            let now = Date()
            let update = ClearanceCoSignatureUpdate(
                status: RTSClearanceStatus.coSigned.rawValue,
                coSignedBy: coSignedBy.uuidString,
                coSignedAt: now.iso8601String,
                updatedAt: now.iso8601String
            )

            let clearance: RTSClearance = try await client
                .from(Tables.clearances)
                .update(update)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Co-signed clearance \(id)")
            #endif

            return clearance
        } catch let serviceError as RTSServiceError {
            errorMessage = serviceError.localizedDescription
            throw serviceError
        } catch {
            errorLogger.logError(error, context: "RTSService.coSignClearance", metadata: ["id": id.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("clearance co-signature")
        }
    }

    // MARK: - Readiness Scores

    /// Record a readiness score assessment
    /// - Parameter input: RTSReadinessScoreInput with required fields
    /// - Returns: Created RTSReadinessScore
    func recordReadinessScore(input: RTSReadinessScoreInput) async throws -> RTSReadinessScore {
        isLoading = true
        defer { isLoading = false }

        do {
            var mutableInput = input
            mutableInput.calculateDerivedFields()
            try mutableInput.validate()

            let score: RTSReadinessScore = try await client
                .from(Tables.readinessScores)
                .insert(mutableInput)
                .select()
                .single()
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Recorded readiness score: \(score.id), overall: \(score.overallScore)")
            #endif

            return score
        } catch let validationError as RTSReadinessError {
            errorMessage = validationError.localizedDescription
            throw validationError
        } catch {
            errorLogger.logError(error, context: "RTSService.recordReadinessScore")
            errorMessage = error.localizedDescription
            throw RTSServiceError.saveFailed("readiness score")
        }
    }

    /// Fetch readiness scores for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Array of RTSReadinessScore objects ordered by recorded date descending
    func fetchReadinessScores(protocolId: UUID) async throws -> [RTSReadinessScore] {
        isLoading = true
        defer { isLoading = false }

        do {
            let scores: [RTSReadinessScore] = try await client
                .from(Tables.readinessScores)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("recorded_at", ascending: false)
                .execute()
                .value

            #if DEBUG
            print("[RTSService] Fetched \(scores.count) readiness scores for protocol")
            #endif

            return scores
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchReadinessScores", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("readiness scores")
        }
    }

    /// Fetch latest readiness score for a protocol
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: Most recent RTSReadinessScore or nil if none exist
    func fetchLatestReadinessScore(protocolId: UUID) async throws -> RTSReadinessScore? {
        isLoading = true
        defer { isLoading = false }

        do {
            let scores: [RTSReadinessScore] = try await client
                .from(Tables.readinessScores)
                .select()
                .eq("protocol_id", value: protocolId.uuidString)
                .order("recorded_at", ascending: false)
                .limit(1)
                .execute()
                .value

            #if DEBUG
            if let score = scores.first {
                print("[RTSService] Latest readiness score: \(score.overallScore)")
            } else {
                print("[RTSService] No readiness scores found for protocol")
            }
            #endif

            return scores.first
        } catch {
            errorLogger.logError(error, context: "RTSService.fetchLatestReadinessScore", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("latest readiness score")
        }
    }

    /// Calculate readiness trend
    /// - Parameter protocolId: Protocol UUID
    /// - Returns: RTSReadinessTrend or nil if insufficient data
    func calculateReadinessTrend(protocolId: UUID) async throws -> RTSReadinessTrend? {
        isLoading = true
        defer { isLoading = false }

        do {
            let scores = try await fetchReadinessScores(protocolId: protocolId)

            guard scores.count >= 2 else {
                #if DEBUG
                print("[RTSService] Insufficient data for trend calculation")
                #endif
                return nil
            }

            // Calculate averages
            let avgOverall = scores.map { $0.overallScore }.reduce(0, +) / Double(scores.count)
            let avgPhysical = scores.map { $0.physicalScore }.reduce(0, +) / Double(scores.count)
            let avgFunctional = scores.map { $0.functionalScore }.reduce(0, +) / Double(scores.count)
            let avgPsychological = scores.map { $0.psychologicalScore }.reduce(0, +) / Double(scores.count)

            // Determine trend direction (compare latest 2 scores)
            let latest = scores[0].overallScore
            let previous = scores[1].overallScore
            let diff = latest - previous

            let direction: RTSReadinessTrendDirection
            if diff > 5 {
                direction = .improving
            } else if diff < -5 {
                direction = .declining
            } else {
                direction = .stable
            }

            let trend = RTSReadinessTrend(
                protocolId: protocolId,
                scores: scores,
                averageOverall: avgOverall,
                averagePhysical: avgPhysical,
                averageFunctional: avgFunctional,
                averagePsychological: avgPsychological,
                trendDirection: direction
            )

            #if DEBUG
            print("[RTSService] Calculated trend: \(direction.rawValue), avg overall: \(avgOverall)")
            #endif

            return trend
        } catch {
            errorLogger.logError(error, context: "RTSService.calculateReadinessTrend", metadata: ["protocolId": protocolId.uuidString])
            errorMessage = error.localizedDescription
            throw RTSServiceError.fetchFailed("readiness trend")
        }
    }

    // MARK: - Helper Methods

    /// Clear any error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Private Update Models

/// Update model for protocol status
private struct ProtocolStatusUpdate: Encodable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

/// Update model for protocol completion
private struct ProtocolCompletionUpdate: Encodable {
    let status: String
    let actualReturnDate: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case actualReturnDate = "actual_return_date"
        case updatedAt = "updated_at"
    }
}

/// Update model for protocol current phase
private struct ProtocolPhaseUpdate: Encodable {
    let currentPhaseId: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case currentPhaseId = "current_phase_id"
        case updatedAt = "updated_at"
    }
}

/// Update model for phase start
private struct PhaseStartUpdate: Encodable {
    let startedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
        case updatedAt = "updated_at"
    }
}

/// Update model for phase completion
private struct PhaseCompleteUpdate: Encodable {
    let completedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }
}

/// Input model for phase advancement
private struct PhaseAdvancementInput: Encodable {
    let protocolId: String
    let fromPhaseId: String?
    let toPhaseId: String
    let decision: String
    let decisionReason: String
    let criteriaSummary: RTSCriteriaSummary
    let decidedBy: String
    let decidedAt: String

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case fromPhaseId = "from_phase_id"
        case toPhaseId = "to_phase_id"
        case decision
        case decisionReason = "decision_reason"
        case criteriaSummary = "criteria_summary"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
    }
}

/// Update model for clearance status
private struct ClearanceStatusUpdate: Encodable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

/// Update model for clearance signature
private struct ClearanceSignatureUpdate: Encodable {
    let status: String
    let signedBy: String
    let signedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case signedBy = "signed_by"
        case signedAt = "signed_at"
        case updatedAt = "updated_at"
    }
}

/// Update model for clearance co-signature
private struct ClearanceCoSignatureUpdate: Encodable {
    let status: String
    let coSignedBy: String
    let coSignedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case coSignedBy = "co_signed_by"
        case coSignedAt = "co_signed_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Date Extension

private extension Date {
    /// ISO8601 string with fractional seconds for timestamps
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    /// ISO8601 date-only string (yyyy-MM-dd) for date columns
    var iso8601DateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension RTSService {
    /// Sample protocol for previews
    static var sampleProtocol: RTSProtocol {
        RTSProtocol.sample
    }

    /// Sample phase for previews
    static var samplePhase: RTSPhase {
        RTSPhase.activeSample
    }

    /// Sample criterion for previews
    static var sampleCriterion: RTSMilestoneCriterion {
        RTSMilestoneCriterion.strengthSample
    }

    /// Sample clearance for previews
    static var sampleClearance: RTSClearance {
        RTSClearance.draftSample
    }

    /// Sample readiness score for previews
    static var sampleReadinessScore: RTSReadinessScore {
        RTSReadinessScore.greenSample
    }

    /// Sample advancement for previews
    static var sampleAdvancement: RTSPhaseAdvancement {
        RTSPhaseAdvancement(
            id: UUID(),
            protocolId: UUID(),
            fromPhaseId: UUID(),
            toPhaseId: UUID(),
            decision: .advance,
            decisionReason: "All criteria met. Patient cleared to progress.",
            criteriaSummary: RTSCriteriaSummary(
                totalCriteria: 5,
                passedCriteria: 5,
                requiredPassed: 3,
                requiredTotal: 3,
                notes: "Quad LSI: 87.5%, Hop Test: 92.0%, Pain: 1/10"
            ),
            decidedBy: UUID(),
            decidedAt: Date(),
            createdAt: Date()
        )
    }
}
#endif
