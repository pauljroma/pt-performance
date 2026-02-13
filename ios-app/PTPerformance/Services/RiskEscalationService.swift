//
//  RiskEscalationService.swift
//  PTPerformance
//
//  Service for Risk Escalation System (M4) - X2Index Command Center
//  Detects and manages safety alerts for therapist intervention
//

import Foundation
import Supabase
import SwiftUI
import Combine

// MARK: - Risk Escalation Service

/// Service for detecting and managing patient risk escalations.
///
/// Thread-safe actor that handles:
/// - Detection of concerning patient patterns
/// - Creating and managing escalations
/// - Real-time updates for therapist dashboard
/// - Push notification triggers
///
/// ## Detection Thresholds
/// - Recovery: <40% for 3+ consecutive days
/// - Pain spike: 3+ point increase
/// - Missed sessions: 3+ consecutive misses
/// - No check-in: 5+ days without activity
/// - Adherence drop: 30%+ decline
///
/// ## Usage
/// ```swift
/// // Fetch active escalations
/// await RiskEscalationService.shared.fetchActiveEscalations(for: therapistId)
///
/// // Check for pain spike
/// if let escalation = try await RiskEscalationService.shared.checkPainSpike(
///     patientId: patientId,
///     newPainLevel: 8,
///     previousPainLevel: 3
/// ) {
///     // Handle new escalation
/// }
/// ```
@MainActor
final class RiskEscalationService: ObservableObject {

    // MARK: - Singleton

    static let shared = RiskEscalationService()

    // MARK: - Published Properties

    /// Currently active escalations for the therapist
    @Published private(set) var activeEscalations: [RiskEscalation] = []

    /// Count of unacknowledged escalations
    @Published private(set) var unacknowledgedCount: Int = 0

    /// Summary of escalation counts
    @Published private(set) var summary: EscalationSummary = .empty

    /// Loading state
    @Published private(set) var isLoading: Bool = false

    /// Error message if any
    @Published var error: Error?

    // MARK: - Thresholds (Static Configuration)

    /// Recovery score threshold (percentage)
    static let recoveryThreshold = 40

    /// Number of consecutive days below recovery threshold
    static let recoveryDaysThreshold = 3

    /// Pain level increase threshold (points)
    static let painSpikeThreshold = 3

    /// Consecutive missed sessions threshold
    static let missedSessionsThreshold = 3

    /// Days without check-in threshold
    static let noCheckInThreshold = 5

    /// Adherence drop threshold (percentage points)
    static let adherenceDropThreshold = 30

    /// Heart rate variability low threshold (ms)
    static let hrvLowThreshold = 20

    /// Heart rate high threshold (bpm)
    static let hrHighThreshold = 100

    /// Acute:chronic workload ratio spike threshold
    static let workloadRatioThreshold = 1.5

    /// Sleep hours minimum threshold
    static let sleepMinThreshold = 5.0

    /// Stress level high threshold (1-10 scale)
    static let stressHighThreshold = 8

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger: ErrorLogger
    private let debugLogger: DebugLogger

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    private enum Tables {
        static let riskEscalations = "risk_escalations"
        static let dailyReadiness = "daily_readiness"
        static let sessions = "sessions"
        static let scheduledSessions = "scheduled_sessions"
        static let patients = "patients"
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        errorLogger: ErrorLogger = .shared,
        debugLogger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.errorLogger = errorLogger
        self.debugLogger = debugLogger
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Fetch Active Escalations

    /// Fetch all active escalations for a therapist.
    ///
    /// Returns escalations that have not been resolved, sorted by severity
    /// (critical first) then by creation date (newest first).
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Throws: Database errors if the query fails
    func fetchActiveEscalations(for therapistId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        debugLogger.log("[RiskEscalationService] Fetching active escalations for therapist: \(therapistId)")

        do {
            let response = try await supabase.client
                .from(Tables.riskEscalations)
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .is("resolved_at", value: nil)
                .order("severity", ascending: false)
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let escalations = try decoder.decode([RiskEscalation].self, from: response.data)

            activeEscalations = escalations
            unacknowledgedCount = escalations.filter { $0.acknowledgedAt == nil }.count

            // Update summary
            summary = EscalationSummary(
                totalActive: escalations.count,
                criticalCount: escalations.filter { $0.severity == .critical }.count,
                highCount: escalations.filter { $0.severity == .high }.count,
                mediumCount: escalations.filter { $0.severity == .medium }.count,
                lowCount: escalations.filter { $0.severity == .low }.count,
                unacknowledgedCount: unacknowledgedCount,
                patientsAffected: Set(escalations.map { $0.patientId }).count,
                oldestUnacknowledgedDate: escalations.filter { $0.acknowledgedAt == nil }.map { $0.createdAt }.min()
            )

            debugLogger.log("[RiskEscalationService] Found \(escalations.count) active escalations", level: .success)

            // Update badge manager
            TabBarBadgeManager.shared.setIntelligenceBadge(unacknowledgedCount)

        } catch {
            errorLogger.logError(error, context: "RiskEscalationService.fetchActiveEscalations(therapist=\(therapistId))")
            self.error = error
            throw RiskEscalationError.fetchFailed(error)
        }
    }

    /// Fetch escalations for a specific patient
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - includeResolved: Whether to include resolved escalations
    /// - Returns: Array of escalations
    func fetchPatientEscalations(patientId: UUID, includeResolved: Bool = false) async throws -> [RiskEscalation] {
        debugLogger.log("[RiskEscalationService] Fetching escalations for patient: \(patientId)")

        do {
            var query = supabase.client
                .from(Tables.riskEscalations)
                .select()
                .eq("patient_id", value: patientId.uuidString)

            if !includeResolved {
                query = query.is("resolved_at", value: nil)
            }

            let response = try await query
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let escalations = try decoder.decode([RiskEscalation].self, from: response.data)

            debugLogger.log("[RiskEscalationService] Found \(escalations.count) escalations for patient", level: .success)
            return escalations

        } catch {
            errorLogger.logError(error, context: "RiskEscalationService.fetchPatientEscalations(patient=\(patientId))")
            throw RiskEscalationError.fetchFailed(error)
        }
    }

    // MARK: - Detection Methods

    /// Check for low recovery pattern (recovery <40% for 3+ days)
    /// - Parameter patientId: Patient UUID
    /// - Returns: New escalation if pattern detected, nil otherwise
    func checkRecoveryPattern(patientId: UUID) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking recovery pattern for patient: \(patientId)")

        // Get last N days of readiness data
        let daysToCheck = Self.recoveryDaysThreshold + 1
        let startDate = Calendar.current.date(byAdding: .day, value: -daysToCheck, to: Date()) ?? Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)

        do {
            let response = try await supabase.client
                .from(Tables.dailyReadiness)
                .select("date,readiness_score")
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: startDateString)
                .order("date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            struct ReadinessEntry: Codable {
                let date: String
                let readinessScore: Double?

                enum CodingKeys: String, CodingKey {
                    case date
                    case readinessScore = "readiness_score"
                }
            }

            let entries = try decoder.decode([ReadinessEntry].self, from: response.data)

            // Check for consecutive low scores
            let lowScoreEntries = entries.filter { ($0.readinessScore ?? 100) < Double(Self.recoveryThreshold) }

            if lowScoreEntries.count >= Self.recoveryDaysThreshold {
                let avgScore = lowScoreEntries.compactMap { $0.readinessScore }.reduce(0, +) / Double(lowScoreEntries.count)

                // Determine severity based on how low and how long
                let severity: EscalationSeverity
                if avgScore < 25 {
                    severity = .critical
                } else if avgScore < 35 || lowScoreEntries.count >= 5 {
                    severity = .high
                } else {
                    severity = .medium
                }

                return try await createEscalation(
                    patientId: patientId,
                    type: .lowRecovery,
                    severity: severity,
                    triggerData: [
                        "average_score": .double(avgScore),
                        "consecutive_days": .int(lowScoreEntries.count),
                        "threshold": .int(Self.recoveryThreshold)
                    ],
                    message: "Recovery score has been below \(Self.recoveryThreshold)% for \(lowScoreEntries.count) consecutive days (avg: \(Int(avgScore))%)",
                    recommendation: "Consider reducing training intensity. Schedule a check-in call to assess overall wellbeing and identify recovery barriers."
                )
            }

            return nil

        } catch let error as RiskEscalationError {
            throw error
        } catch {
            errorLogger.logError(error, context: "RiskEscalationService.checkRecoveryPattern")
            throw RiskEscalationError.detectionFailed(error)
        }
    }

    /// Check for pain spike (pain increases by 3+ points)
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - newPainLevel: Current pain level (1-10)
    ///   - previousPainLevel: Previous pain level (1-10)
    /// - Returns: New escalation if spike detected, nil otherwise
    func checkPainSpike(patientId: UUID, newPainLevel: Int, previousPainLevel: Int) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking pain spike: \(previousPainLevel) -> \(newPainLevel)")

        let painIncrease = newPainLevel - previousPainLevel

        guard painIncrease >= Self.painSpikeThreshold else {
            return nil
        }

        // Determine severity based on absolute pain and increase
        let severity: EscalationSeverity
        if newPainLevel >= 9 || painIncrease >= 5 {
            severity = .critical
        } else if newPainLevel >= 7 || painIncrease >= 4 {
            severity = .high
        } else {
            severity = .medium
        }

        return try await createEscalation(
            patientId: patientId,
            type: .painSpike,
            severity: severity,
            triggerData: [
                "new_pain_level": .int(newPainLevel),
                "previous_pain_level": .int(previousPainLevel),
                "increase": .int(painIncrease)
            ],
            message: "Pain level spiked from \(previousPainLevel) to \(newPainLevel) (+\(painIncrease) points)",
            recommendation: "Immediate follow-up recommended. Review recent activities for potential injury or overuse. Consider modifying program intensity."
        )
    }

    /// Check for missed sessions (3+ consecutive misses)
    /// - Parameter patientId: Patient UUID
    /// - Returns: New escalation if pattern detected, nil otherwise
    func checkMissedSessions(patientId: UUID) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking missed sessions for patient: \(patientId)")

        // Get scheduled sessions from the past 2 weeks
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let startDateString = dateFormatter.string(from: startDate)

        do {
            let response = try await supabase.client
                .from(Tables.scheduledSessions)
                .select("id,scheduled_date,completed_at")
                .eq("patient_id", value: patientId.uuidString)
                .gte("scheduled_date", value: startDateString)
                .lte("scheduled_date", value: dateFormatter.string(from: Date()))
                .order("scheduled_date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            struct ScheduledSession: Codable {
                let id: UUID
                let scheduledDate: Date
                let completedAt: Date?

                enum CodingKeys: String, CodingKey {
                    case id
                    case scheduledDate = "scheduled_date"
                    case completedAt = "completed_at"
                }
            }

            let sessions = try decoder.decode([ScheduledSession].self, from: response.data)

            // Count consecutive missed sessions
            var consecutiveMisses = 0
            for session in sessions where session.completedAt == nil {
                consecutiveMisses += 1
            }

            guard consecutiveMisses >= Self.missedSessionsThreshold else {
                return nil
            }

            let severity: EscalationSeverity
            if consecutiveMisses >= 5 {
                severity = .high
            } else {
                severity = .medium
            }

            return try await createEscalation(
                patientId: patientId,
                type: .missedSessions,
                severity: severity,
                triggerData: [
                    "consecutive_misses": .int(consecutiveMisses),
                    "threshold": .int(Self.missedSessionsThreshold)
                ],
                message: "Patient has missed \(consecutiveMisses) consecutive scheduled sessions",
                recommendation: "Reach out to understand barriers to adherence. Consider schedule adjustments or program modifications."
            )

        } catch let error as RiskEscalationError {
            throw error
        } catch {
            errorLogger.logError(error, context: "RiskEscalationService.checkMissedSessions")
            throw RiskEscalationError.detectionFailed(error)
        }
    }

    /// Check for abnormal vitals (HR/HRV out of range)
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - hr: Resting heart rate (bpm)
    ///   - hrv: Heart rate variability (ms)
    /// - Returns: New escalation if abnormal, nil otherwise
    func checkVitals(patientId: UUID, hr: Int, hrv: Int) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking vitals: HR=\(hr), HRV=\(hrv)")

        var concerns: [String] = []
        var severity: EscalationSeverity = .low

        if hrv < Self.hrvLowThreshold {
            concerns.append("HRV critically low (\(hrv)ms)")
            severity = .high
        }

        if hr > Self.hrHighThreshold {
            concerns.append("Resting HR elevated (\(hr) bpm)")
            if severity < .high {
                severity = .medium
            }
        }

        guard !concerns.isEmpty else {
            return nil
        }

        // Upgrade to critical if both are abnormal
        if hrv < Self.hrvLowThreshold && hr > Self.hrHighThreshold {
            severity = .critical
        }

        return try await createEscalation(
            patientId: patientId,
            type: .abnormalVitals,
            severity: severity,
            triggerData: [
                "heart_rate": .int(hr),
                "hrv": .int(hrv),
                "hr_threshold": .int(Self.hrHighThreshold),
                "hrv_threshold": .int(Self.hrvLowThreshold)
            ],
            message: concerns.joined(separator: ". "),
            recommendation: "Abnormal vital signs may indicate overtraining, illness, or stress. Consider rest day and follow up to assess overall health status."
        )
    }

    /// Check for no check-in (5+ days without activity)
    /// - Parameter patientId: Patient UUID
    /// - Returns: New escalation if detected, nil otherwise
    func checkNoCheckIn(patientId: UUID) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking no check-in for patient: \(patientId)")

        let thresholdDate = Calendar.current.date(byAdding: .day, value: -Self.noCheckInThreshold, to: Date()) ?? Date()
        let thresholdDateString = dateFormatter.string(from: thresholdDate)

        do {
            // Check for any recent readiness entries
            let response = try await supabase.client
                .from(Tables.dailyReadiness)
                .select("date")
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: thresholdDateString)
                .limit(1)
                .execute()

            let decoder = JSONDecoder()
            struct DateEntry: Codable {
                let date: String
            }

            let entries = try decoder.decode([DateEntry].self, from: response.data)

            if entries.isEmpty {
                // No check-in found in the threshold period
                return try await createEscalation(
                    patientId: patientId,
                    type: .noCheckIn,
                    severity: .medium,
                    triggerData: [
                        "days_since_checkin": .int(Self.noCheckInThreshold),
                        "threshold": .int(Self.noCheckInThreshold)
                    ],
                    message: "No daily check-in recorded for \(Self.noCheckInThreshold)+ days",
                    recommendation: "Patient may be disengaged or facing barriers. Send a check-in message or call to reconnect."
                )
            }

            return nil

        } catch let error as RiskEscalationError {
            throw error
        } catch {
            errorLogger.logError(error, context: "RiskEscalationService.checkNoCheckIn")
            throw RiskEscalationError.detectionFailed(error)
        }
    }

    /// Check for adherence dropoff
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - currentAdherence: Current adherence percentage
    ///   - previousAdherence: Previous adherence percentage
    /// - Returns: New escalation if drop detected, nil otherwise
    func checkAdherenceDropoff(patientId: UUID, currentAdherence: Double, previousAdherence: Double) async throws -> RiskEscalation? {
        debugLogger.log("[RiskEscalationService] Checking adherence dropoff: \(previousAdherence)% -> \(currentAdherence)%")

        let drop = previousAdherence - currentAdherence

        guard drop >= Double(Self.adherenceDropThreshold) else {
            return nil
        }

        let severity: EscalationSeverity
        if currentAdherence < 30 || drop >= 50 {
            severity = .high
        } else {
            severity = .medium
        }

        return try await createEscalation(
            patientId: patientId,
            type: .adherenceDropoff,
            severity: severity,
            triggerData: [
                "current_adherence": .double(currentAdherence),
                "previous_adherence": .double(previousAdherence),
                "drop": .double(drop),
                "threshold": .int(Self.adherenceDropThreshold)
            ],
            message: "Adherence dropped from \(Int(previousAdherence))% to \(Int(currentAdherence))% (-\(Int(drop)) points)",
            recommendation: "Significant engagement decline detected. Schedule a call to understand barriers and adjust program if needed."
        )
    }

    // MARK: - Management Methods

    /// Create a new risk escalation
    private func createEscalation(
        patientId: UUID,
        type: EscalationType,
        severity: EscalationSeverity,
        triggerData: [String: AnyCodableValue],
        message: String,
        recommendation: String
    ) async throws -> RiskEscalation {
        debugLogger.log("[RiskEscalationService] Creating escalation: \(type.rawValue) - \(severity.rawValue)")

        // Get therapist ID from patient
        let therapistId = try await getTherapistId(for: patientId)

        // Check for duplicate (same type, patient, not resolved)
        let existingEscalations = try await supabase.client
            .from(Tables.riskEscalations)
            .select("id")
            .eq("patient_id", value: patientId.uuidString)
            .eq("escalation_type", value: type.rawValue)
            .is("resolved_at", value: nil)
            .execute()

        let decoder = JSONDecoder()
        struct IdOnly: Codable { let id: UUID }
        let existing = try decoder.decode([IdOnly].self, from: existingEscalations.data)

        if !existing.isEmpty {
            debugLogger.log("[RiskEscalationService] Duplicate escalation exists, skipping creation", level: .warning)
            throw RiskEscalationError.duplicateExists
        }

        // Create the escalation
        let insertData = RiskEscalationInsert(
            patientId: patientId.uuidString,
            therapistId: therapistId.uuidString,
            escalationType: type.rawValue,
            severity: severity.rawValue,
            triggerData: triggerData,
            message: message,
            recommendation: recommendation,
            status: EscalationStatus.pending.rawValue,
            createdAt: dateFormatter.string(from: Date())
        )

        let response = try await supabase.client
            .from(Tables.riskEscalations)
            .insert(insertData)
            .select()
            .single()
            .execute()

        decoder.dateDecodingStrategy = .iso8601
        let escalation = try decoder.decode(RiskEscalation.self, from: response.data)

        debugLogger.log("[RiskEscalationService] Created escalation: \(escalation.id)", level: .success)

        // Trigger push notification for critical/high
        if severity >= .high {
            await sendPushNotification(for: escalation, therapistId: therapistId)
        }

        // Update local state
        activeEscalations.insert(escalation, at: 0)
        unacknowledgedCount += 1
        TabBarBadgeManager.shared.setIntelligenceBadge(unacknowledgedCount)

        return escalation
    }

    /// Acknowledge an escalation
    /// - Parameter id: Escalation UUID
    /// - Returns: Updated escalation
    func acknowledgeEscalation(_ id: UUID) async throws -> RiskEscalation {
        debugLogger.log("[RiskEscalationService] Acknowledging escalation: \(id)")

        guard let userId = UUID(uuidString: supabase.userId ?? "") else {
            throw RiskEscalationError.notAuthenticated
        }

        let payload = AcknowledgePayload(
            acknowledgedAt: dateFormatter.string(from: Date()),
            acknowledgedBy: userId.uuidString,
            status: EscalationStatus.acknowledged.rawValue
        )

        let response = try await supabase.client
            .from(Tables.riskEscalations)
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let escalation = try decoder.decode(RiskEscalation.self, from: response.data)

        // Update local state
        if let index = activeEscalations.firstIndex(where: { $0.id == id }) {
            activeEscalations[index] = escalation
        }
        unacknowledgedCount = activeEscalations.filter { $0.acknowledgedAt == nil }.count
        TabBarBadgeManager.shared.setIntelligenceBadge(unacknowledgedCount)

        debugLogger.log("[RiskEscalationService] Escalation acknowledged", level: .success)
        return escalation
    }

    /// Resolve an escalation
    /// - Parameters:
    ///   - id: Escalation UUID
    ///   - notes: Resolution notes
    /// - Returns: Updated escalation
    func resolveEscalation(_ id: UUID, notes: String) async throws -> RiskEscalation {
        debugLogger.log("[RiskEscalationService] Resolving escalation: \(id)")

        let payload = ResolvePayload(
            resolvedAt: dateFormatter.string(from: Date()),
            resolutionNotes: notes,
            status: EscalationStatus.resolved.rawValue
        )

        let response = try await supabase.client
            .from(Tables.riskEscalations)
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let escalation = try decoder.decode(RiskEscalation.self, from: response.data)

        // Remove from active list
        activeEscalations.removeAll { $0.id == id }
        unacknowledgedCount = activeEscalations.filter { $0.acknowledgedAt == nil }.count
        TabBarBadgeManager.shared.setIntelligenceBadge(unacknowledgedCount)

        debugLogger.log("[RiskEscalationService] Escalation resolved", level: .success)
        return escalation
    }

    /// Dismiss an escalation as false positive
    /// - Parameters:
    ///   - id: Escalation UUID
    ///   - reason: Reason for dismissal
    /// - Returns: Updated escalation
    func dismissEscalation(_ id: UUID, reason: String) async throws -> RiskEscalation {
        debugLogger.log("[RiskEscalationService] Dismissing escalation: \(id)")

        let now = dateFormatter.string(from: Date())
        let payload = DismissPayload(
            resolvedAt: now,
            resolutionNotes: "Dismissed: \(reason)",
            status: EscalationStatus.dismissed.rawValue
        )

        let response = try await supabase.client
            .from(Tables.riskEscalations)
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let escalation = try decoder.decode(RiskEscalation.self, from: response.data)

        // Remove from active list
        activeEscalations.removeAll { $0.id == id }
        unacknowledgedCount = activeEscalations.filter { $0.acknowledgedAt == nil }.count
        TabBarBadgeManager.shared.setIntelligenceBadge(unacknowledgedCount)

        debugLogger.log("[RiskEscalationService] Escalation dismissed", level: .success)
        return escalation
    }

    /// Bulk acknowledge multiple escalations
    /// - Parameter ids: Array of escalation UUIDs
    func bulkAcknowledge(ids: [UUID]) async throws {
        debugLogger.log("[RiskEscalationService] Bulk acknowledging \(ids.count) escalations")

        for id in ids {
            _ = try await acknowledgeEscalation(id)
        }

        debugLogger.log("[RiskEscalationService] Bulk acknowledge complete", level: .success)
    }

    // MARK: - Helper Methods

    private func getTherapistId(for patientId: UUID) async throws -> UUID {
        let response = try await supabase.client
            .from(Tables.patients)
            .select("therapist_id")
            .eq("id", value: patientId.uuidString)
            .single()
            .execute()

        struct TherapistIdResponse: Codable {
            let therapistId: UUID

            enum CodingKeys: String, CodingKey {
                case therapistId = "therapist_id"
            }
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(TherapistIdResponse.self, from: response.data)
        return result.therapistId
    }

    private func sendPushNotification(for escalation: RiskEscalation, therapistId: UUID) async {
        // Integrate with PushNotificationService
        debugLogger.log("[RiskEscalationService] Sending push notification for \(escalation.severity.rawValue) escalation")

        // This would call the push notification service
        // For now, just log it
        DebugLogger.shared.log("[RiskEscalation] Would send push: \(escalation.escalationType.displayName) - \(escalation.message)", level: .diagnostic)
    }
}

// MARK: - String Convenience Methods

extension RiskEscalationService {
    func fetchActiveEscalations(for therapistId: String) async throws {
        guard let uuid = UUID(uuidString: therapistId) else {
            throw RiskEscalationError.invalidUUID(therapistId)
        }
        try await fetchActiveEscalations(for: uuid)
    }

    func acknowledgeEscalation(_ id: String) async throws -> RiskEscalation {
        guard let uuid = UUID(uuidString: id) else {
            throw RiskEscalationError.invalidUUID(id)
        }
        return try await acknowledgeEscalation(uuid)
    }

    func resolveEscalation(_ id: String, notes: String) async throws -> RiskEscalation {
        guard let uuid = UUID(uuidString: id) else {
            throw RiskEscalationError.invalidUUID(id)
        }
        return try await resolveEscalation(uuid, notes: notes)
    }

    func dismissEscalation(_ id: String, reason: String) async throws -> RiskEscalation {
        guard let uuid = UUID(uuidString: id) else {
            throw RiskEscalationError.invalidUUID(id)
        }
        return try await dismissEscalation(uuid, reason: reason)
    }
}

// MARK: - Insert/Update Payloads

private struct RiskEscalationInsert: Encodable {
    let patientId: String
    let therapistId: String
    let escalationType: String
    let severity: String
    let triggerData: [String: AnyCodableValue]
    let message: String
    let recommendation: String
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case escalationType = "escalation_type"
        case severity
        case triggerData = "trigger_data"
        case message
        case recommendation
        case status
        case createdAt = "created_at"
    }
}

private struct AcknowledgePayload: Encodable {
    let acknowledgedAt: String
    let acknowledgedBy: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case acknowledgedAt = "acknowledged_at"
        case acknowledgedBy = "acknowledged_by"
        case status
    }
}

private struct ResolvePayload: Encodable {
    let resolvedAt: String
    let resolutionNotes: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case resolvedAt = "resolved_at"
        case resolutionNotes = "resolution_notes"
        case status
    }
}

private struct DismissPayload: Encodable {
    let resolvedAt: String
    let resolutionNotes: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case resolvedAt = "resolved_at"
        case resolutionNotes = "resolution_notes"
        case status
    }
}

// MARK: - Errors

/// Errors specific to risk escalation operations
enum RiskEscalationError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case detectionFailed(Error)
    case notAuthenticated
    case invalidUUID(String)
    case duplicateExists
    case escalationNotFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Couldn't Load Escalations"
        case .createFailed:
            return "Couldn't Create Escalation"
        case .updateFailed:
            return "Couldn't Update Escalation"
        case .detectionFailed:
            return "Detection Failed"
        case .notAuthenticated:
            return "Not Signed In"
        case .invalidUUID:
            return "Invalid Identifier"
        case .duplicateExists:
            return "Escalation Already Exists"
        case .escalationNotFound:
            return "Escalation Not Found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .createFailed:
            return "We couldn't create the escalation. Please try again."
        case .updateFailed:
            return "We couldn't update the escalation. Please try again."
        case .detectionFailed:
            return "We couldn't check for risk patterns. Please try again."
        case .notAuthenticated:
            return "Please sign in to manage escalations."
        case .invalidUUID:
            return "An internal error occurred. Please try again."
        case .duplicateExists:
            return "An escalation for this issue already exists."
        case .escalationNotFound:
            return "This escalation may have been removed. Please refresh."
        }
    }
}
