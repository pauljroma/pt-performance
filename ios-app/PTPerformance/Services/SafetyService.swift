//
//  SafetyService.swift
//  PTPerformance
//
//  Safety Monitoring Service for X2Index
//  M9: AI flags uncertainty, abstains on weak evidence, forces escalation when threshold crossed
//
//  Thresholds:
//  - Pain score >= 8 -> high severity
//  - HRV drop > 30% -> medium severity
//  - Contradictory check-in data -> flag for review
//  - AI confidence < 0.5 -> abstain and alert
//

import Foundation
import Supabase

// MARK: - Safety Service

/// Singleton service for safety monitoring and incident management
/// Monitors safety thresholds and creates/manages safety incidents
@MainActor
final class SafetyService: ObservableObject {

    // MARK: - Singleton

    static let shared = SafetyService()

    // MARK: - Published Properties

    @Published private(set) var openIncidents: [SafetyIncident] = []
    @Published private(set) var isLoading = false
    @Published var lastError: Error?

    // MARK: - Private Properties

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Safety Threshold Checks

    /// Check safety thresholds for athlete data
    /// Returns any incidents that should be created based on the data
    /// - Parameters:
    ///   - athleteId: The athlete's ID
    ///   - data: Dictionary containing safety-relevant data points
    /// - Returns: Array of safety incidents that should be created
    func checkSafetyThresholds(athleteId: UUID, data: SafetyCheckData) -> SafetyCheckResult {
        var incidents: [SafetyIncident] = []
        var warnings: [String] = []
        var shouldAbstain = false
        var requiresEscalation = false

        // Check pain score threshold
        if let painScore = data.painScore {
            if painScore >= SafetyThresholds.painScoreHigh {
                let incident = SafetyIncident(
                    athleteId: athleteId,
                    incidentType: .painThreshold,
                    severity: painScore >= 10 ? .critical : .high,
                    description: "Patient reported pain score of \(painScore)/10",
                    triggerData: [
                        "pain_score": .int(painScore),
                        "exercise": .string(data.exerciseName ?? "Unknown"),
                        "context": .string(data.context ?? "check-in")
                    ]
                )
                incidents.append(incident)
                requiresEscalation = true
            } else if painScore >= SafetyThresholds.painScoreMedium {
                warnings.append("Elevated pain score (\(painScore)/10) - monitor closely")
            }
        }

        // Check HRV drop threshold
        if let currentHRV = data.currentHRV, let baselineHRV = data.baselineHRV, baselineHRV > 0 {
            let dropPercentage = (Double(baselineHRV - currentHRV) / Double(baselineHRV))

            if dropPercentage >= SafetyThresholds.hrvDropPercentageHigh {
                let incident = SafetyIncident(
                    athleteId: athleteId,
                    incidentType: .vitalAnomaly,
                    severity: .high,
                    description: "HRV dropped \(Int(dropPercentage * 100))% from baseline",
                    triggerData: [
                        "current_hrv": .int(currentHRV),
                        "baseline_hrv": .int(baselineHRV),
                        "drop_percentage": .double(dropPercentage * 100)
                    ]
                )
                incidents.append(incident)
                requiresEscalation = true
            } else if dropPercentage >= SafetyThresholds.hrvDropPercentage {
                let incident = SafetyIncident(
                    athleteId: athleteId,
                    incidentType: .vitalAnomaly,
                    severity: .medium,
                    description: "HRV dropped \(Int(dropPercentage * 100))% from baseline",
                    triggerData: [
                        "current_hrv": .int(currentHRV),
                        "baseline_hrv": .int(baselineHRV),
                        "drop_percentage": .double(dropPercentage * 100)
                    ]
                )
                incidents.append(incident)
            }
        }

        // Check for contradictory data
        if let contradictions = data.contradictions, !contradictions.isEmpty {
            let incident = SafetyIncident(
                athleteId: athleteId,
                incidentType: .contradictoryData,
                severity: .low,
                description: "Check-in data contains contradictions: \(contradictions.joined(separator: "; "))",
                triggerData: [
                    "contradictions": .array(contradictions.map { .string($0) })
                ]
            )
            incidents.append(incident)
            warnings.append("Data inconsistencies detected - PT review recommended")
        }

        // Check AI confidence threshold
        if let confidence = data.aiConfidence {
            if confidence < SafetyThresholds.aiConfidenceAbstain {
                let incident = SafetyIncident(
                    athleteId: athleteId,
                    incidentType: .aiUncertainty,
                    severity: .medium,
                    description: "AI model confidence (\(Int(confidence * 100))%) below safety threshold",
                    triggerData: [
                        "confidence_score": .double(confidence),
                        "claim_type": .string(data.claimType ?? "unknown"),
                        "abstained": .bool(true)
                    ]
                )
                incidents.append(incident)
                shouldAbstain = true
            } else if confidence < SafetyThresholds.aiConfidenceUncertain {
                warnings.append("AI confidence is low (\(Int(confidence * 100))%) - showing uncertainty indicator")
            }
        }

        return SafetyCheckResult(
            incidents: incidents,
            shouldAbstain: shouldAbstain,
            requiresEscalation: requiresEscalation,
            warnings: warnings
        )
    }

    // MARK: - Incident Management

    /// Create a new safety incident
    /// - Parameters:
    ///   - type: The type of incident
    ///   - severity: The severity level
    ///   - athleteId: The athlete's ID
    ///   - description: Description of the incident
    ///   - triggerData: Optional data that triggered the incident
    /// - Returns: The created incident
    func createIncident(
        type: SafetyIncident.IncidentType,
        severity: SafetyIncident.Severity,
        athleteId: UUID,
        description: String,
        triggerData: [String: AnyCodableValue]? = nil
    ) async throws -> SafetyIncident {
        let incident = SafetyIncident(
            athleteId: athleteId,
            incidentType: type,
            severity: severity,
            description: description,
            triggerData: triggerData
        )

        // Insert into database
        let insertData: [String: AnyEncodable] = [
            "id": AnyEncodable(incident.id.uuidString),
            "athlete_id": AnyEncodable(athleteId.uuidString),
            "incident_type": AnyEncodable(type.rawValue),
            "severity": AnyEncodable(severity.rawValue),
            "description": AnyEncodable(description),
            "trigger_data": AnyEncodable(triggerData),
            "status": AnyEncodable(SafetyIncident.IncidentStatus.open.rawValue)
        ]

        try await supabase.client
            .from("safety_incidents")
            .insert(insertData)
            .execute()

        // Refresh open incidents
        await loadOpenIncidents()

        // Log critical incidents
        if severity == .critical || severity == .high {
            errorLogger.logWarning("High-severity safety incident created: \(description)")
        }

        return incident
    }

    /// Create multiple incidents from a safety check result
    func createIncidents(from result: SafetyCheckResult) async throws {
        for incident in result.incidents {
            _ = try await createIncident(
                type: incident.incidentType,
                severity: incident.severity,
                athleteId: incident.athleteId,
                description: incident.description,
                triggerData: incident.triggerData
            )
        }
    }

    /// Resolve a safety incident
    /// - Parameters:
    ///   - incidentId: The incident ID
    ///   - resolution: Resolution details
    func resolveIncident(incidentId: UUID, resolution: IncidentResolution) async throws {
        let status: SafetyIncident.IncidentStatus = resolution.dismissed ? .dismissed : .resolved

        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "resolved_by": AnyEncodable(resolution.resolvedBy.uuidString),
            "resolved_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
            "resolution_notes": AnyEncodable(resolution.notes)
        ]

        try await supabase.client
            .from("safety_incidents")
            .update(updateData)
            .eq("id", value: incidentId.uuidString)
            .execute()

        // Refresh open incidents
        await loadOpenIncidents()
    }

    /// Escalate an incident to a specific user
    /// - Parameters:
    ///   - incidentId: The incident ID
    ///   - escalateTo: The user ID to escalate to
    func escalateIncident(incidentId: UUID, escalateTo: UUID) async throws {
        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(SafetyIncident.IncidentStatus.investigating.rawValue),
            "escalated_to": AnyEncodable(escalateTo.uuidString)
        ]

        try await supabase.client
            .from("safety_incidents")
            .update(updateData)
            .eq("id", value: incidentId.uuidString)
            .execute()

        // Refresh open incidents
        await loadOpenIncidents()
    }

    /// Get all open (unresolved) incidents
    /// - Returns: Array of open safety incidents
    func getOpenIncidents() async -> [SafetyIncident] {
        await loadOpenIncidents()
        return openIncidents
    }

    /// Get open incidents for a specific athlete
    /// - Parameter athleteId: The athlete's ID
    /// - Returns: Array of open safety incidents for the athlete
    func getOpenIncidents(for athleteId: UUID) async -> [SafetyIncident] {
        do {
            let response = try await supabase.client
                .from("safety_incidents")
                .select()
                .eq("athlete_id", value: athleteId.uuidString)
                .in("status", values: ["open", "investigating"])
                .order("created_at", ascending: false)
                .execute()

            return try PTSupabaseClient.flexibleDecoder.decode([SafetyIncident].self, from: response.data)
        } catch {
            errorLogger.logError(error, context: "SafetyService.getOpenIncidents(for:)")
            return []
        }
    }

    /// Get high-severity unresolved incidents count
    /// - Returns: Count of unresolved high/critical severity incidents
    func getUnresolvedHighSeverityCount() async -> Int {
        do {
            let response = try await supabase.client
                .from("safety_incidents")
                .select("id", head: false, count: .exact)
                .in("severity", values: ["high", "critical"])
                .in("status", values: ["open", "investigating"])
                .execute()

            return response.count ?? 0
        } catch {
            errorLogger.logError(error, context: "SafetyService.getUnresolvedHighSeverityCount")
            return 0
        }
    }

    /// Load all open incidents
    private func loadOpenIncidents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("safety_incidents")
                .select()
                .in("status", values: ["open", "investigating"])
                .order("severity", ascending: true) // Critical first
                .order("created_at", ascending: false)
                .execute()

            openIncidents = try PTSupabaseClient.flexibleDecoder.decode([SafetyIncident].self, from: response.data)
        } catch {
            errorLogger.logError(error, context: "SafetyService.loadOpenIncidents")
            lastError = error
        }
    }

    // MARK: - AI Safety Controls

    /// Check if AI should abstain from making a claim based on confidence
    /// - Parameter confidence: The AI confidence score (0.0-1.0)
    /// - Returns: Whether AI should abstain
    func shouldAbstain(confidence: Double) -> Bool {
        confidence < SafetyThresholds.aiConfidenceAbstain
    }

    /// Check if uncertainty indicator should be shown
    /// - Parameter confidence: The AI confidence score (0.0-1.0)
    /// - Returns: Whether to show uncertainty indicator
    func shouldShowUncertainty(confidence: Double) -> Bool {
        confidence < SafetyThresholds.aiConfidenceUncertain
    }

    /// Check if escalation should be forced based on incident
    /// - Parameter incident: The safety incident
    /// - Returns: Whether escalation should be forced
    func shouldForceEscalation(incident: SafetyIncident) -> Bool {
        // Force escalation for high/critical severity open incidents
        guard incident.status == .open else { return false }
        guard incident.severity == .high || incident.severity == .critical else { return false }
        guard incident.escalatedTo == nil else { return false }

        // Also force escalation if incident is older than timeout
        let hoursSinceCreation = incident.age / 3600
        return hoursSinceCreation >= Double(SafetyThresholds.escalationTimeoutHours)
    }

    /// Get all incidents requiring forced escalation
    func getIncidentsRequiringEscalation() async -> [SafetyIncident] {
        let incidents = await getOpenIncidents()
        return incidents.filter { shouldForceEscalation(incident: $0) }
    }
}

// MARK: - Safety Check Data

/// Data structure for safety threshold checks
struct SafetyCheckData: Sendable {
    let painScore: Int?
    let currentHRV: Int?
    let baselineHRV: Int?
    let contradictions: [String]?
    let aiConfidence: Double?
    let claimType: String?
    let exerciseName: String?
    let context: String?

    init(
        painScore: Int? = nil,
        currentHRV: Int? = nil,
        baselineHRV: Int? = nil,
        contradictions: [String]? = nil,
        aiConfidence: Double? = nil,
        claimType: String? = nil,
        exerciseName: String? = nil,
        context: String? = nil
    ) {
        self.painScore = painScore
        self.currentHRV = currentHRV
        self.baselineHRV = baselineHRV
        self.contradictions = contradictions
        self.aiConfidence = aiConfidence
        self.claimType = claimType
        self.exerciseName = exerciseName
        self.context = context
    }
}

// MARK: - AnyEncodable Helper

/// Helper for encoding mixed types to Supabase
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
