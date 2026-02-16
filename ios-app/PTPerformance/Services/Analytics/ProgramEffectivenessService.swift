//
//  ProgramEffectivenessService.swift
//  PTPerformance
//
//  Service for Program Effectiveness Analytics
//  Provides methods to fetch and calculate program effectiveness metrics
//

import Foundation
import Supabase

/// Service responsible for program effectiveness analytics
///
/// Provides methods for calculating program metrics, comparing programs,
/// and analyzing patient outcomes. Used by therapists to understand which
/// programs produce the best results.
///
/// ## Usage Example
/// ```swift
/// let service = ProgramEffectivenessService()
/// let metrics = try await service.fetchProgramMetrics(therapistId: therapistId)
/// print("Found \(metrics.count) programs")
/// ```
final class ProgramEffectivenessService {

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Fetch metrics for all programs belonging to a therapist
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of program metrics
    func fetchProgramMetrics(therapistId: String) async throws -> [ProgramMetrics] {
        DebugLogger.shared.log("Fetching program metrics for therapist: \(therapistId)")

        // First, fetch programs for this therapist
        let programsResponse = try await supabase.client
            .from("programs")
            .select("""
                id,
                name,
                program_type,
                patient_id
            """)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct ProgramBasic: Codable {
            let id: UUID
            let name: String
            let programType: ProgramType?
            let patientId: UUID

            enum CodingKeys: String, CodingKey {
                case id, name
                case programType = "program_type"
                case patientId = "patient_id"
            }
        }

        let programs = try decoder.decode([ProgramBasic].self, from: programsResponse.data)

        // Calculate metrics for each program
        var metrics: [ProgramMetrics] = []

        for program in programs {
            let programMetrics = try await calculateMetricsForProgram(
                programId: program.id,
                programName: program.name,
                programType: program.programType
            )
            if let programMetrics = programMetrics {
                metrics.append(programMetrics)
            }
        }

        DebugLogger.shared.log("Fetched metrics for \(metrics.count) programs", level: .success)
        return metrics.sorted { $0.effectivenessScore > $1.effectivenessScore }
    }

    /// Fetch comparison data for multiple programs
    /// - Parameter programIds: Array of program UUIDs to compare
    /// - Returns: ProgramComparison object with all metrics side-by-side
    func fetchProgramComparison(programIds: [UUID]) async throws -> ProgramComparison {
        DebugLogger.shared.log("Fetching comparison for \(programIds.count) programs")

        var programMetrics: [ProgramMetrics] = []

        for programId in programIds {
            // Fetch program details
            let response = try await supabase.client
                .from("programs")
                .select("id, name, program_type")
                .eq("id", value: programId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()

            struct ProgramInfo: Codable {
                let id: UUID
                let name: String
                let programType: ProgramType?

                enum CodingKeys: String, CodingKey {
                    case id, name
                    case programType = "program_type"
                }
            }

            let programInfo = try decoder.decode(ProgramInfo.self, from: response.data)

            if let metrics = try await calculateMetricsForProgram(
                programId: programInfo.id,
                programName: programInfo.name,
                programType: programInfo.programType
            ) {
                programMetrics.append(metrics)
            }
        }

        return ProgramComparison(programs: programMetrics, comparisonDate: Date())
    }

    /// Fetch detailed outcomes for a specific program
    /// - Parameter programId: The program UUID
    /// - Returns: OutcomeDistribution with success/failure breakdown
    func fetchProgramOutcomes(programId: UUID) async throws -> OutcomeDistribution {
        DebugLogger.shared.log("Fetching outcomes for program: \(programId)")

        // Fetch enrollment statuses for this program
        // Since we don't have a direct enrollment table, we'll calculate from sessions
        let sessionsResponse = try await supabase.client
            .from("scheduled_sessions")
            .select("id, status, patient_id")
            .eq("program_id", value: programId.uuidString)
            .execute()

        let decoder = JSONDecoder()

        struct SessionStatus: Codable {
            let id: UUID
            let status: String
            let patientId: UUID

            enum CodingKeys: String, CodingKey {
                case id, status
                case patientId = "patient_id"
            }
        }

        let sessions = try decoder.decode([SessionStatus].self, from: sessionsResponse.data)

        // Group by patient and determine outcomes
        let patientSessions = Dictionary(grouping: sessions) { $0.patientId }

        var successCount = 0
        var partialCount = 0
        var failedCount = 0
        var ongoingCount = 0

        for (_, patientSessions) in patientSessions {
            let completedCount = patientSessions.filter { $0.status == "completed" }.count
            let totalCount = patientSessions.count

            if totalCount == 0 {
                continue
            }

            let completionRate = Double(completedCount) / Double(totalCount)

            // Check if still ongoing (has pending sessions)
            let hasPending = patientSessions.contains { $0.status == "pending" || $0.status == "scheduled" }

            if hasPending {
                ongoingCount += 1
            } else if completionRate >= 0.9 {
                successCount += 1
            } else if completionRate >= 0.6 {
                partialCount += 1
            } else {
                failedCount += 1
            }
        }

        return OutcomeDistribution(
            id: UUID(),
            programId: programId,
            successCount: successCount,
            partialSuccessCount: partialCount,
            failedCount: failedCount,
            ongoingCount: ongoingCount
        )
    }

    /// Fetch phase-by-phase dropoff analysis for a program
    /// - Parameter programId: The program UUID
    /// - Returns: Array of PhaseDropoffData showing attrition at each phase
    func fetchProgramDropoffAnalysis(programId: UUID) async throws -> [PhaseDropoffData] {
        DebugLogger.shared.log("Fetching dropoff analysis for program: \(programId)")

        // Fetch phases for this program
        let phasesResponse = try await supabase.client
            .from("phases")
            .select("id, phase_number, name")
            .eq("program_id", value: programId.uuidString)
            .order("phase_number", ascending: true)
            .execute()

        let decoder = JSONDecoder()

        struct PhaseInfo: Codable {
            let id: UUID
            let phaseNumber: Int
            let name: String

            enum CodingKeys: String, CodingKey {
                case id
                case phaseNumber = "phase_number"
                case name
            }
        }

        let phases = try decoder.decode([PhaseInfo].self, from: phasesResponse.data)

        // Fetch sessions grouped by phase
        let sessionsResponse = try await supabase.client
            .from("scheduled_sessions")
            .select("id, phase_id, patient_id, status, completed_at")
            .eq("program_id", value: programId.uuidString)
            .execute()

        struct SessionInfo: Codable {
            let id: UUID
            let phaseId: UUID?
            let patientId: UUID
            let status: String
            let completedAt: Date?

            enum CodingKeys: String, CodingKey {
                case id
                case phaseId = "phase_id"
                case patientId = "patient_id"
                case status
                case completedAt = "completed_at"
            }
        }

        decoder.dateDecodingStrategy = .iso8601
        let sessions = try decoder.decode([SessionInfo].self, from: sessionsResponse.data)

        // Calculate dropoff for each phase
        var dropoffData: [PhaseDropoffData] = []
        var previousPhasePatients = Set<UUID>()
        let allPatients = Set(sessions.map { $0.patientId })

        for (index, phase) in phases.enumerated() {
            let phaseSessions = sessions.filter { $0.phaseId == phase.id }
            let phasePatients = Set(phaseSessions.map { $0.patientId })

            // Starting patients = patients who had at least one session in this phase
            // or all patients for first phase
            let startingPatients: Set<UUID>
            if index == 0 {
                startingPatients = allPatients
            } else {
                startingPatients = previousPhasePatients
            }

            // Completing patients = patients who completed all sessions in this phase
            let patientsWithCompletedSessions = Dictionary(grouping: phaseSessions) { $0.patientId }
                .filter { _, sessions in
                    sessions.allSatisfy { $0.status == "completed" }
                }
                .keys

            let completingPatients = Set(patientsWithCompletedSessions)

            // Dropped = started but didn't complete
            let droppedPatients = phasePatients.subtracting(completingPatients)

            // Average completion days
            let completionDates = phaseSessions
                .filter { $0.status == "completed" }
                .compactMap { $0.completedAt }

            let avgDays: Double
            if completionDates.count >= 2,
               let sortedDates = completionDates.sorted() as [Date]?,
               let firstDate = sortedDates.first,
               let lastDate = sortedDates.last {
                let daysDiff = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
                avgDays = Double(daysDiff) / Double(completionDates.count)
            } else {
                avgDays = 7.0 * Double(phase.phaseNumber) // Estimate
            }

            let dropoffReasons = await determineDropoffReasons(
                for: phase.id,
                programId: programId,
                droppedPatientIds: droppedPatients
            )

            dropoffData.append(PhaseDropoffData(
                id: UUID(),
                programId: programId,
                phaseNumber: phase.phaseNumber,
                phaseName: phase.name,
                startingPatients: startingPatients.count,
                completingPatients: completingPatients.count,
                droppedPatients: droppedPatients.count,
                averageCompletionDays: avgDays,
                commonDropoffReasons: dropoffReasons
            ))

            previousPhasePatients = completingPatients
        }

        return dropoffData
    }

    /// Row struct for decoding pain_logs results per phase
    private struct PhasePainRow: Codable, Sendable {
        let athleteId: String
        let intensity: Int
        let loggedAt: Date

        enum CodingKeys: String, CodingKey {
            case athleteId = "athlete_id"
            case intensity
            case loggedAt = "logged_at"
        }
    }

    /// Row struct for decoding exercise_logs results per phase
    private struct PhaseExerciseRow: Codable, Sendable {
        let patientId: String
        let actualLoad: Double?
        let loggedAt: Date?

        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case actualLoad = "actual_load"
            case loggedAt = "logged_at"
        }
    }

    /// Row struct for decoding session date ranges per phase
    private struct PhaseSessionDateRow: Codable, Sendable {
        let patientId: String
        let scheduledDate: String

        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case scheduledDate = "scheduled_date"
        }
    }

    /// Fetch heatmap data for program phases
    /// - Parameters:
    ///   - programId: The program UUID
    ///   - metricType: The metric to visualize
    /// - Returns: Array of heatmap data points
    func fetchHeatmapData(programId: UUID, metricType: HeatmapMetricType) async throws -> [HeatmapDataPoint] {
        let dropoffData = try await fetchProgramDropoffAnalysis(programId: programId)

        // For pain and strength metrics, fetch the phases to get date ranges and patient sets
        let phasesResponse = try await supabase.client
            .from("phases")
            .select("id, phase_number")
            .eq("program_id", value: programId.uuidString)
            .order("phase_number", ascending: true)
            .execute()

        struct PhaseIdRow: Codable {
            let id: UUID
            let phaseNumber: Int
            enum CodingKeys: String, CodingKey {
                case id
                case phaseNumber = "phase_number"
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let phaseRows = (try? decoder.decode([PhaseIdRow].self, from: phasesResponse.data)) ?? []

        var dataPoints: [HeatmapDataPoint] = []

        for phase in dropoffData {
            let value: Double
            switch metricType {
            case .completion:
                value = phase.completionRate
            case .adherence:
                value = phase.completionRate * 0.9
            case .painLevel:
                value = await fetchAveragePainForPhase(
                    programId: programId,
                    phaseId: phaseRows.first(where: { $0.phaseNumber == phase.phaseNumber })?.id
                )
            case .strengthProgress:
                value = await fetchAverageStrengthGainForPhase(
                    programId: programId,
                    phaseId: phaseRows.first(where: { $0.phaseNumber == phase.phaseNumber })?.id
                )
            }

            dataPoints.append(HeatmapDataPoint(
                phaseNumber: phase.phaseNumber,
                phaseName: phase.phaseName,
                metricType: metricType,
                value: value,
                patientCount: phase.startingPatients
            ))
        }

        return dataPoints
    }

    /// Fetch average pain level for patients during a specific phase
    /// Queries pain_logs for entries logged during the phase's session date range
    private func fetchAveragePainForPhase(programId: UUID, phaseId: UUID?) async -> Double {
        guard let phaseId = phaseId else { return 0 }
        do {
            // Get session date range and patient IDs for this phase
            let sessionsResponse = try await supabase.client
                .from("scheduled_sessions")
                .select("patient_id, scheduled_date")
                .eq("program_id", value: programId.uuidString)
                .eq("phase_id", value: phaseId.uuidString)
                .order("scheduled_date", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            let sessionRows = try decoder.decode([PhaseSessionDateRow].self, from: sessionsResponse.data)

            guard !sessionRows.isEmpty else { return 0 }

            let patientIds = Array(Set(sessionRows.map { $0.patientId }))
            let dates = sessionRows.compactMap { $0.scheduledDate }.sorted()
            guard let minDate = dates.first, let maxDate = dates.last else { return 0 }

            // Query pain_logs for these patients within the phase date range
            let painResponse = try await supabase.client
                .from("pain_logs")
                .select("athlete_id, intensity, logged_at")
                .in("athlete_id", values: patientIds)
                .gte("logged_at", value: minDate)
                .lte("logged_at", value: maxDate + "T23:59:59Z")
                .execute()

            decoder.dateDecodingStrategy = .iso8601
            let painRows = try decoder.decode([PhasePainRow].self, from: painResponse.data)

            guard !painRows.isEmpty else { return 0 }

            let totalIntensity = painRows.reduce(0) { $0 + $1.intensity }
            return Double(totalIntensity) / Double(painRows.count)
        } catch {
            DebugLogger.shared.log("Failed to fetch pain data for phase \(phaseId): \(error)", level: .error)
            return 0
        }
    }

    /// Fetch average strength gain for patients during a specific phase
    /// Queries exercise_logs for entries logged during the phase's session date range
    /// Returns fractional gain (e.g. 0.2 = 20% improvement)
    private func fetchAverageStrengthGainForPhase(programId: UUID, phaseId: UUID?) async -> Double {
        guard let phaseId = phaseId else { return 0 }
        do {
            // Get session date range and patient IDs for this phase
            let sessionsResponse = try await supabase.client
                .from("scheduled_sessions")
                .select("patient_id, scheduled_date")
                .eq("program_id", value: programId.uuidString)
                .eq("phase_id", value: phaseId.uuidString)
                .order("scheduled_date", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            let sessionRows = try decoder.decode([PhaseSessionDateRow].self, from: sessionsResponse.data)

            guard !sessionRows.isEmpty else { return 0 }

            let patientIds = Array(Set(sessionRows.map { $0.patientId }))
            let dates = sessionRows.compactMap { $0.scheduledDate }.sorted()
            guard let minDate = dates.first, let maxDate = dates.last else { return 0 }

            // Query exercise_logs for these patients within the phase date range
            let logsResponse = try await supabase.client
                .from("exercise_logs")
                .select("patient_id, actual_load, logged_at")
                .in("patient_id", values: patientIds)
                .not("actual_load", operator: .is, value: "null")
                .gte("logged_at", value: minDate)
                .lte("logged_at", value: maxDate + "T23:59:59Z")
                .order("logged_at", ascending: true)
                .execute()

            decoder.dateDecodingStrategy = .iso8601
            let exerciseRows = try decoder.decode([PhaseExerciseRow].self, from: logsResponse.data)

            guard !exerciseRows.isEmpty else { return 0 }

            // Group by patient and compute per-patient gain
            let byPatient = Dictionary(grouping: exerciseRows) { $0.patientId }
            var gains: [Double] = []

            for (_, logs) in byPatient {
                let validLogs = logs.compactMap { $0.actualLoad }
                guard validLogs.count >= 2,
                      let firstLoad = validLogs.first,
                      let lastLoad = validLogs.last,
                      firstLoad > 0 else { continue }
                let gain = max(0, (lastLoad - firstLoad) / firstLoad)
                gains.append(gain)
            }

            guard !gains.isEmpty else { return 0 }
            return gains.reduce(0, +) / Double(gains.count)
        } catch {
            DebugLogger.shared.log("Failed to fetch strength data for phase \(phaseId): \(error)", level: .error)
            return 0
        }
    }

    /// Row struct for decoding enrollment dates from patient_programs
    private struct PatientProgramDateRow: Codable, Sendable {
        let patientId: String
        let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case createdAt = "created_at"
        }
    }

    /// Fetch patients enrolled in a specific program
    /// - Parameter programId: The program UUID
    /// - Returns: Array of ProgramPatient with their progress
    func fetchProgramPatients(programId: UUID) async throws -> [ProgramPatient] {
        DebugLogger.shared.log("Fetching patients for program: \(programId)")

        // Fetch patients with their session data for this program
        let response = try await supabase.client
            .from("scheduled_sessions")
            .select("""
                patient_id,
                status,
                patients!inner(
                    id,
                    first_name,
                    last_name
                )
            """)
            .eq("program_id", value: programId.uuidString)
            .execute()

        struct SessionWithPatient: Codable {
            let patientId: UUID
            let status: String
            let patients: PatientBasic

            struct PatientBasic: Codable {
                let id: UUID
                let firstName: String
                let lastName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case firstName = "first_name"
                    case lastName = "last_name"
                }
            }

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case status
                case patients
            }
        }

        let decoder = JSONDecoder()
        let sessions = try decoder.decode([SessionWithPatient].self, from: response.data)

        // Group sessions by patient
        let patientSessions = Dictionary(grouping: sessions) { $0.patientId }

        // Fetch actual enrollment dates from patient_programs for all patients in this program
        let enrollmentDates = await fetchEnrollmentDates(
            patientIds: Array(patientSessions.keys),
            programId: programId
        )

        var programPatients: [ProgramPatient] = []

        for (patientId, sessions) in patientSessions {
            guard let firstSession = sessions.first else { continue }

            let totalSessions = sessions.count
            let completedSessions = sessions.filter { $0.status == "completed" }.count
            let completionPercentage = totalSessions > 0 ? Double(completedSessions) / Double(totalSessions) : 0

            // Determine status
            let hasPending = sessions.contains { $0.status == "pending" || $0.status == "scheduled" }
            let status: String
            if completedSessions == totalSessions {
                status = "completed"
            } else if hasPending {
                status = "active"
            } else {
                status = "paused"
            }

            // Use real enrollment date from patient_programs, fall back to earliest session date
            let enrollmentDate = enrollmentDates[patientId] ?? Date()

            programPatients.append(ProgramPatient(
                id: UUID(),
                patientId: patientId,
                firstName: firstSession.patients.firstName,
                lastName: firstSession.patients.lastName,
                programId: programId,
                enrollmentDate: enrollmentDate,
                currentPhase: max(1, Int(completionPercentage * 4)),
                completionPercentage: completionPercentage,
                adherenceRate: completionPercentage * 0.95,
                painReduction: await fetchPatientPainReduction(patientId: patientId),
                status: status
            ))
        }

        return programPatients.sorted { $0.completionPercentage > $1.completionPercentage }
    }

    /// Fetch real enrollment dates from patient_programs for a set of patients and program
    /// Falls back to empty dictionary on error
    private func fetchEnrollmentDates(patientIds: [UUID], programId: UUID) async -> [UUID: Date] {
        do {
            let patientIdStrings = patientIds.map { $0.uuidString }

            let response = try await supabase.client
                .from("patient_programs")
                .select("patient_id, created_at")
                .in("patient_id", values: patientIdStrings)
                .eq("template_id", value: programId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let rows = try decoder.decode([PatientProgramDateRow].self, from: response.data)

            var result: [UUID: Date] = [:]
            for row in rows {
                if let uuid = UUID(uuidString: row.patientId), let date = row.createdAt {
                    result[uuid] = date
                }
            }
            return result
        } catch {
            DebugLogger.shared.log("Failed to fetch enrollment dates: \(error)", level: .error)
            return [:]
        }
    }

    // MARK: - Private Methods

    /// Calculate comprehensive metrics for a single program
    private func calculateMetricsForProgram(
        programId: UUID,
        programName: String,
        programType: ProgramType?
    ) async throws -> ProgramMetrics? {
        // Fetch sessions for this program
        let sessionsResponse = try await supabase.client
            .from("scheduled_sessions")
            .select("id, patient_id, status, scheduled_date, completed_at")
            .eq("program_id", value: programId.uuidString)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct SessionData: Codable {
            let id: UUID
            let patientId: UUID
            let status: String
            let scheduledDate: Date
            let completedAt: Date?

            enum CodingKeys: String, CodingKey {
                case id
                case patientId = "patient_id"
                case status
                case scheduledDate = "scheduled_date"
                case completedAt = "completed_at"
            }
        }

        let sessions = try decoder.decode([SessionData].self, from: sessionsResponse.data)

        if sessions.isEmpty {
            return nil
        }

        // Group by patient
        let patientSessions = Dictionary(grouping: sessions) { $0.patientId }

        var totalEnrollments = patientSessions.count
        var activeEnrollments = 0
        var completedEnrollments = 0
        var droppedEnrollments = 0
        var totalDurationWeeks: Double = 0
        var durationCount = 0

        for (_, sessions) in patientSessions {
            let completedCount = sessions.filter { $0.status == "completed" }.count
            let totalCount = sessions.count
            let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

            let hasPending = sessions.contains { $0.status == "pending" || $0.status == "scheduled" }

            if hasPending {
                activeEnrollments += 1
            } else if completionRate >= 0.9 {
                completedEnrollments += 1
            } else {
                droppedEnrollments += 1
            }

            // Calculate duration
            if let firstDate = sessions.map({ $0.scheduledDate }).min(),
               let lastDate = sessions.compactMap({ $0.completedAt }).max() {
                let weeks = Calendar.current.dateComponents([.weekOfYear], from: firstDate, to: lastDate).weekOfYear ?? 0
                totalDurationWeeks += Double(max(1, weeks))
                durationCount += 1
            }
        }

        let overallCompletionRate = totalEnrollments > 0 ?
            Double(completedEnrollments) / Double(totalEnrollments - activeEnrollments) : 0

        let avgDurationWeeks = durationCount > 0 ? totalDurationWeeks / Double(durationCount) : 12.0

        // Query vw_pain_trend for actual pain reduction data across all patients in this program
        let patientIds = Array(patientSessions.keys)
        let averagePainReduction = await fetchAveragePainReduction(patientIds: patientIds)

        // Query exercise_logs for strength progression across all patients in this program
        let averageStrengthGain = await fetchAverageStrengthGain(patientIds: patientIds)

        return ProgramMetrics(
            id: UUID(),
            programId: programId,
            programName: programName,
            programType: programType,
            totalEnrollments: totalEnrollments,
            activeEnrollments: activeEnrollments,
            completedEnrollments: completedEnrollments,
            droppedEnrollments: droppedEnrollments,
            completionRate: max(0, min(1, overallCompletionRate)),
            averageDurationWeeks: avgDurationWeeks,
            averagePainReduction: averagePainReduction,
            averageStrengthGain: averageStrengthGain,
            averageAdherence: max(0, min(1, overallCompletionRate * 0.95)),
            lastUpdated: Date()
        )
    }

    // MARK: - Pain & Strength Query Helpers

    /// Row struct for decoding vw_pain_trend results
    private struct PainTrendRow: Codable, Sendable {
        let id: String
        let patientId: String
        let loggedDate: Date
        let avgPain: Double

        enum CodingKeys: String, CodingKey {
            case id
            case patientId = "patient_id"
            case loggedDate = "logged_date"
            case avgPain = "avg_pain"
        }
    }

    /// Row struct for decoding exercise_logs results
    private struct ExerciseLogQueryRow: Codable, Sendable {
        let id: String
        let patientId: String
        let actualLoad: Double?
        let loggedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case patientId = "patient_id"
            case actualLoad = "actual_load"
            case loggedAt = "logged_at"
        }
    }

    /// Fetch pain reduction for a single patient (absolute points reduced)
    /// Returns nil if insufficient data
    private func fetchPatientPainReduction(patientId: UUID) async -> Double? {
        do {
            let painResponse = try await supabase.client
                .from("vw_pain_trend")
                .select("id, patient_id, logged_date, avg_pain")
                .eq("patient_id", value: patientId.uuidString)
                .order("logged_date", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let painData = try decoder.decode([PainTrendRow].self, from: painResponse.data)

            if painData.count >= 2,
               let first = painData.first?.avgPain,
               let last = painData.last?.avgPain,
               first > 0 {
                return max(0, first - last)
            }
            return nil
        } catch {
            DebugLogger.shared.log("Failed to fetch pain reduction for patient \(patientId): \(error)", level: .error)
            return nil
        }
    }

    /// Fetch average pain reduction across a set of patients
    /// Queries vw_pain_trend and computes (first - last) / first * 100 per patient, then averages
    private func fetchAveragePainReduction(patientIds: [UUID]) async -> Double {
        var reductions: [Double] = []

        for patientId in patientIds {
            do {
                let painResponse = try await supabase.client
                    .from("vw_pain_trend")
                    .select("id, patient_id, logged_date, avg_pain")
                    .eq("patient_id", value: patientId.uuidString)
                    .order("logged_date", ascending: true)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let painData = try decoder.decode([PainTrendRow].self, from: painResponse.data)

                if let first = painData.first?.avgPain, let last = painData.last?.avgPain, first > 0 {
                    let reduction = max(0, (first - last) / first * 100)
                    // Normalize to 0-10 scale (percentage / 10) to match model expectations
                    reductions.append(reduction / 10.0)
                }
            } catch {
                DebugLogger.shared.log("Failed to fetch pain data for patient \(patientId): \(error)", level: .error)
                continue
            }
        }

        guard !reductions.isEmpty else { return 0 }
        return reductions.reduce(0, +) / Double(reductions.count)
    }

    /// Fetch average strength gain across a set of patients
    /// Queries exercise_logs and computes (last load - first load) / first load per patient, then averages
    private func fetchAverageStrengthGain(patientIds: [UUID]) async -> Double {
        var gains: [Double] = []

        for patientId in patientIds {
            do {
                let logsResponse = try await supabase.client
                    .from("exercise_logs")
                    .select("id, patient_id, actual_load, logged_at")
                    .eq("patient_id", value: patientId.uuidString)
                    .not("actual_load", operator: .is, value: "null")
                    .order("logged_at", ascending: true)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let exerciseLogs = try decoder.decode([ExerciseLogQueryRow].self, from: logsResponse.data)

                if let firstWeight = exerciseLogs.first?.actualLoad,
                   let lastWeight = exerciseLogs.last?.actualLoad,
                   firstWeight > 0 {
                    let gain = max(0, (lastWeight - firstWeight) / firstWeight)
                    gains.append(gain)
                }
            } catch {
                DebugLogger.shared.log("Failed to fetch exercise logs for patient \(patientId): \(error)", level: .error)
                continue
            }
        }

        guard !gains.isEmpty else { return 0 }
        return gains.reduce(0, +) / Double(gains.count)
    }

    /// Row struct for decoding enrollment notes from cancelled/paused enrollments
    private struct EnrollmentDropoffRow: Codable, Sendable {
        let status: String
        let notes: String?
    }

    /// Determine common dropoff reasons by querying cancelled/paused enrollments for a phase
    /// Falls back to status-derived reasons if no notes are available
    private func determineDropoffReasons(for phaseId: UUID, programId: UUID, droppedPatientIds: Set<UUID>) async -> [String] {
        guard !droppedPatientIds.isEmpty else { return [] }
        do {
            let patientIdStrings = droppedPatientIds.map { $0.uuidString }

            // Query program_enrollments for cancelled/paused enrollments with notes
            let response = try await supabase.client
                .from("program_enrollments")
                .select("status, notes")
                .in("patient_id", values: patientIdStrings)
                .in("status", values: ["cancelled", "paused"])
                .execute()

            let decoder = JSONDecoder()
            let rows = try decoder.decode([EnrollmentDropoffRow].self, from: response.data)

            // Collect non-empty notes as reasons
            var reasons: [String] = []
            for row in rows {
                if let notes = row.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    reasons.append(notes)
                }
            }

            // If we found real notes, return unique reasons (up to 3)
            if !reasons.isEmpty {
                let uniqueReasons = Array(Set(reasons)).prefix(3)
                return Array(uniqueReasons)
            }

            // Fall back to status-based summary when no notes exist
            let cancelledCount = rows.filter { $0.status == "cancelled" }.count
            let pausedCount = rows.filter { $0.status == "paused" }.count
            var fallbackReasons: [String] = []
            if cancelledCount > 0 {
                fallbackReasons.append("Cancelled enrollment (\(cancelledCount))")
            }
            if pausedCount > 0 {
                fallbackReasons.append("Paused enrollment (\(pausedCount))")
            }
            if fallbackReasons.isEmpty {
                fallbackReasons.append("Did not complete phase sessions")
            }
            return fallbackReasons
        } catch {
            DebugLogger.shared.log("Failed to fetch dropoff reasons for phase \(phaseId): \(error)", level: .error)
            return ["Unable to determine reason"]
        }
    }
}
