//
//  AdaptiveTrainingService.swift
//  PTPerformance
//
//  Adaptive Training Engine - Generates workout modifications based on health data
//  Integrates readiness, fatigue, and health metrics to suggest training adjustments
//

import Foundation
import Supabase

/// Service for generating and managing adaptive workout modifications
/// based on athlete health and readiness data.
///
/// The Adaptive Training Engine analyzes:
/// - Daily readiness scores
/// - Fatigue accumulation (ACWR)
/// - HRV deviation from baseline
/// - Sleep quality and duration
/// - Reported pain/soreness
///
/// And generates actionable workout modifications that athletes can accept or decline.
@MainActor
class AdaptiveTrainingService: ObservableObject {

    // MARK: - Singleton

    static let shared = AdaptiveTrainingService()

    // MARK: - Dependencies

    private let client: PTSupabaseClient
    private let readinessService: ReadinessService
    private let healthKitService: HealthKitService

    // MARK: - Published State

    @Published var pendingModifications: [WorkoutModification] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Initialization

    init(
        client: PTSupabaseClient = .shared,
        readinessService: ReadinessService = ReadinessService(),
        healthKitService: HealthKitService = .shared
    ) {
        self.client = client
        self.readinessService = readinessService
        self.healthKitService = healthKitService
    }

    // MARK: - Generate Modifications

    /// Analyze today's health data and scheduled workout to generate modification suggestions
    /// Call this after the morning readiness check-in
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - scheduledSession: Today's scheduled workout session (optional)
    /// - Returns: Generated WorkoutModification if one is warranted, nil otherwise
    func analyzeAndGenerateModification(
        for patientId: UUID,
        scheduledSession: PatientScheduledSession? = nil
    ) async throws -> WorkoutModification? {
        isLoading = true
        defer { isLoading = false }

        // 1. Fetch today's readiness data
        guard let readiness = try await readinessService.getTodayReadiness(for: patientId) else {
            DebugLogger.shared.info("ADAPTIVE", "No readiness data for today - skipping modification check")
            return nil
        }

        guard let readinessScore = readiness.readinessScore else {
            DebugLogger.shared.info("ADAPTIVE", "Readiness has no score - skipping modification check")
            return nil
        }

        // 2. Fetch additional health context
        let healthContext = await fetchHealthContext(for: patientId)

        // 3. Determine if modification is needed
        let modificationDecision = evaluateModificationNeed(
            readinessScore: readinessScore,
            readiness: readiness,
            healthContext: healthContext
        )

        guard modificationDecision.shouldModify else {
            DebugLogger.shared.info("ADAPTIVE", "Readiness score \(readinessScore) - no modification needed")
            return nil
        }

        // 4. Generate the modification
        let modification = createModification(
            patientId: patientId,
            scheduledSession: scheduledSession,
            readinessScore: readinessScore,
            decision: modificationDecision,
            healthContext: healthContext
        )

        // 5. Save to database
        let savedModification = try await saveModification(modification)

        // 6. Update local state
        pendingModifications.append(savedModification)

        DebugLogger.shared.success("ADAPTIVE", """
            Generated modification for patient \(patientId):
            Type: \(savedModification.modificationType.displayName)
            Reason: \(savedModification.reason)
            Readiness: \(readinessScore)
            """)

        return savedModification
    }

    // MARK: - Fetch Pending Modifications

    /// Fetch all pending modifications for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Array of pending WorkoutModifications
    func fetchPendingModifications(for patientId: UUID) async throws -> [WorkoutModification] {
        isLoading = true
        defer { isLoading = false }

        // Use date-only format for the DATE column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        let response = try await client.client
            .from("workout_modifications")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: "pending")
            .gte("scheduled_date", value: todayString)
            .order("scheduled_date", ascending: true)
            .execute()

        let modifications = try flexibleDecoder.decode([WorkoutModification].self, from: response.data)

        pendingModifications = modifications
        return modifications
    }

    /// Flexible decoder that handles both DATE (yyyy-MM-dd) and TIMESTAMPTZ formats
    private var flexibleDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first (TIMESTAMPTZ format)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try date-only format (DATE column returns yyyy-MM-dd)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }

    // MARK: - Accept Modification

    /// Accept a suggested workout modification
    /// - Parameters:
    ///   - modificationId: UUID of the modification to accept
    ///   - feedback: Optional athlete feedback
    /// - Returns: Updated WorkoutModification
    func acceptModification(
        _ modificationId: UUID,
        feedback: String? = nil
    ) async throws -> WorkoutModification {
        return try await resolveModification(
            modificationId,
            status: .accepted,
            feedback: feedback
        )
    }

    // MARK: - Decline Modification

    /// Decline a suggested workout modification
    /// - Parameters:
    ///   - modificationId: UUID of the modification to decline
    ///   - feedback: Optional reason for declining
    /// - Returns: Updated WorkoutModification
    func declineModification(
        _ modificationId: UUID,
        feedback: String? = nil
    ) async throws -> WorkoutModification {
        return try await resolveModification(
            modificationId,
            status: .declined,
            feedback: feedback
        )
    }

    // MARK: - Private: Health Context

    /// Additional health data for modification decisions
    private struct HealthContext {
        let hrvDeviation: Double?        // Percentage from baseline
        let sleepHours: Double?
        let sleepQuality: Double?        // 0-100
        let consecutiveLowDays: Int      // Days of low readiness in a row
        let acwr: Double?                // Acute:Chronic Workload Ratio
        let fatigueScore: Double?
        let painReported: Bool
        let painLocations: [String]
    }

    private func fetchHealthContext(for patientId: UUID) async -> HealthContext {
        // Fetch HRV data
        var hrvDeviation: Double?
        if let currentHRV = try? await healthKitService.fetchHRV(for: Date()),
           let baseline = try? await healthKitService.getHRVBaseline(days: 7),
           baseline > 0 {
            hrvDeviation = ((currentHRV - baseline) / baseline) * 100
        }

        // Fetch sleep data
        var sleepHours: Double?
        var sleepQuality: Double?
        if let sleepData = try? await healthKitService.fetchSleepData(for: Date()) {
            sleepHours = sleepData.totalHours
            sleepQuality = sleepData.sleepEfficiency
        }

        // Fetch consecutive low readiness days
        let consecutiveLowDays = await countConsecutiveLowReadinessDays(for: patientId)

        // Fetch fatigue/ACWR (simplified - would come from FatigueTrackingService)
        // For now, return nil - this would be enhanced later
        let acwr: Double? = nil
        let fatigueScore: Double? = nil

        // Check for pain from today's readiness
        var painReported = false
        var painLocations: [String] = []
        if let todayReadiness = try? await readinessService.getTodayReadiness(for: patientId) {
            if let notes = todayReadiness.notes, notes.contains("Joint pain:") {
                painReported = true
                // Parse pain locations from notes
                if let range = notes.range(of: "Joint pain: ") {
                    let locationsStr = String(notes[range.upperBound...])
                    painLocations = locationsStr
                        .components(separatedBy: "|")[0]
                        .components(separatedBy: ", ")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                }
            }
            // Check soreness level
            if let soreness = todayReadiness.sorenessLevel, soreness >= 7 {
                painReported = true
            }
        }

        return HealthContext(
            hrvDeviation: hrvDeviation,
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            consecutiveLowDays: consecutiveLowDays,
            acwr: acwr,
            fatigueScore: fatigueScore,
            painReported: painReported,
            painLocations: painLocations
        )
    }

    private func countConsecutiveLowReadinessDays(for patientId: UUID) async -> Int {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -14, to: Date()) else {
            return 0
        }

        guard let recentReadiness = try? await readinessService.fetchReadiness(
            for: patientId,
            from: startDate,
            to: Date()
        ) else {
            return 0
        }

        // Sort by date descending and count consecutive low days
        let sorted = recentReadiness.sorted { $0.date > $1.date }
        var count = 0

        for entry in sorted {
            if let score = entry.readinessScore, score < ReadinessThresholds.lowReadiness {
                count += 1
            } else {
                break
            }
        }

        return count
    }

    // MARK: - Private: Modification Decision

    private struct ModificationDecision {
        let shouldModify: Bool
        let modificationType: WorkoutModificationType
        let trigger: ModificationTrigger
        let loadAdjustment: Double?
        let volumeReduction: Int?
        let delayDays: Int?
        let deloadDays: Int?
        let reason: String
        let explanation: String
    }

    private func evaluateModificationNeed(
        readinessScore: Double,
        readiness: DailyReadiness,
        healthContext: HealthContext
    ) -> ModificationDecision {
        // Priority 1: Check for critical conditions requiring immediate action
        if healthContext.consecutiveLowDays >= ReadinessThresholds.consecutiveLowDaysForDeload {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .triggerDeload,
                trigger: .consecutiveLowDays,
                loadAdjustment: nil,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: 5,
                reason: "\(healthContext.consecutiveLowDays) consecutive days of low readiness",
                explanation: "Extended fatigue detected. A deload period will help you recover and come back stronger."
            )
        }

        // Priority 2: Check ACWR if available
        if let acwr = healthContext.acwr, acwr > ReadinessThresholds.highACWR {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .volumeReduction,
                trigger: .highACWR,
                loadAdjustment: nil,
                volumeReduction: 2,
                delayDays: nil,
                deloadDays: nil,
                reason: "Training load ratio is elevated (\(String(format: "%.2f", acwr)))",
                explanation: "Your acute training load is high relative to your chronic load. Reducing volume will help prevent overtraining."
            )
        }

        // Priority 3: Check HRV deviation
        if let hrvDev = healthContext.hrvDeviation,
           hrvDev < ReadinessThresholds.hrvDeviationThreshold {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .insertRecoveryDay,
                trigger: .lowHRV,
                loadAdjustment: nil,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "HRV is \(Int(abs(hrvDev)))% below your baseline",
                explanation: "Your heart rate variability indicates incomplete recovery. A recovery day will help restore your autonomic balance."
            )
        }

        // Priority 4: Check sleep
        if let sleepHours = healthContext.sleepHours,
           sleepHours < ReadinessThresholds.poorSleepThreshold {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .loadAdjustment,
                trigger: .poorSleep,
                loadAdjustment: -20.0,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "Only \(String(format: "%.1f", sleepHours)) hours of sleep last night",
                explanation: "Poor sleep affects performance and recovery. Reducing intensity today will help you train effectively while you're under-recovered."
            )
        }

        // Priority 5: Readiness score based decisions
        if readinessScore < 40 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .skipWorkout,
                trigger: .lowReadiness,
                loadAdjustment: nil,
                volumeReduction: nil,
                delayDays: 1,
                deloadDays: nil,
                reason: "Readiness score is very low (\(Int(readinessScore))/100)",
                explanation: "Your body is signaling it needs rest. Skipping today and moving the workout will lead to better long-term progress."
            )
        }

        if readinessScore < 50 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .insertRecoveryDay,
                trigger: .lowReadiness,
                loadAdjustment: nil,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "Readiness score indicates need for recovery (\(Int(readinessScore))/100)",
                explanation: "Consider an active recovery session instead of the planned workout. Light movement will aid recovery without adding fatigue."
            )
        }

        if readinessScore < 60 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .loadAdjustment,
                trigger: .lowReadiness,
                loadAdjustment: -25.0,
                volumeReduction: 1,
                delayDays: nil,
                deloadDays: nil,
                reason: "Readiness score is below optimal (\(Int(readinessScore))/100)",
                explanation: "Reducing intensity will help you complete a quality session while respecting your current recovery state."
            )
        }

        if readinessScore < 70 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .loadAdjustment,
                trigger: .lowReadiness,
                loadAdjustment: -15.0,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "Readiness score suggests moderate caution (\(Int(readinessScore))/100)",
                explanation: "A slight reduction in intensity will help you train effectively today."
            )
        }

        if readinessScore < 80 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .loadAdjustment,
                trigger: .lowReadiness,
                loadAdjustment: -10.0,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "Readiness is good but not optimal (\(Int(readinessScore))/100)",
                explanation: "A minor adjustment will help ensure quality work today."
            )
        }

        // Check for high readiness opportunity
        if readinessScore >= 90 {
            return ModificationDecision(
                shouldModify: true,
                modificationType: .loadAdjustment,
                trigger: .highReadiness,
                loadAdjustment: 5.0,
                volumeReduction: nil,
                delayDays: nil,
                deloadDays: nil,
                reason: "Readiness is excellent (\(Int(readinessScore))/100)",
                explanation: "You're well recovered! Consider pushing slightly harder today to maximize this opportunity."
            )
        }

        // No modification needed
        return ModificationDecision(
            shouldModify: false,
            modificationType: .loadAdjustment,
            trigger: .lowReadiness,
            loadAdjustment: nil,
            volumeReduction: nil,
            delayDays: nil,
            deloadDays: nil,
            reason: "",
            explanation: ""
        )
    }

    // MARK: - Private: Create Modification

    private func createModification(
        patientId: UUID,
        scheduledSession: PatientScheduledSession?,
        readinessScore: Double,
        decision: ModificationDecision,
        healthContext: HealthContext
    ) -> WorkoutModificationRequest {
        return WorkoutModificationRequest(
            patientId: patientId,
            scheduledSessionId: scheduledSession?.id,
            scheduledDate: Date(),
            modificationType: decision.modificationType,
            trigger: decision.trigger,
            readinessScore: readinessScore,
            fatigueScore: healthContext.fatigueScore,
            loadAdjustmentPercentage: decision.loadAdjustment,
            volumeReductionSets: decision.volumeReduction,
            delayDays: decision.delayDays,
            deloadDurationDays: decision.deloadDays,
            exerciseModifications: nil, // Would be populated with specific exercise changes
            reason: decision.reason,
            detailedExplanation: decision.explanation
        )
    }

    // MARK: - Private: Save Modification

    private func saveModification(_ request: WorkoutModificationRequest) async throws -> WorkoutModification {
        let response = try await client.client
            .from("workout_modifications")
            .insert(request)
            .select()
            .single()
            .execute()

        return try flexibleDecoder.decode(WorkoutModification.self, from: response.data)
    }

    // MARK: - Private: Resolve Modification

    /// Codable struct for modification resolution updates
    private struct ModificationResolutionUpdate: Codable {
        let status: String
        let resolvedAt: String
        let athleteFeedback: String?

        enum CodingKeys: String, CodingKey {
            case status
            case resolvedAt = "resolved_at"
            case athleteFeedback = "athlete_feedback"
        }
    }

    private func resolveModification(
        _ modificationId: UUID,
        status: ModificationStatus,
        feedback: String?
    ) async throws -> WorkoutModification {
        let updates = ModificationResolutionUpdate(
            status: status.rawValue,
            resolvedAt: ISO8601DateFormatter().string(from: Date()),
            athleteFeedback: feedback
        )

        let response = try await client.client
            .from("workout_modifications")
            .update(updates)
            .eq("id", value: modificationId.uuidString)
            .select()
            .single()
            .execute()

        let modification = try flexibleDecoder.decode(WorkoutModification.self, from: response.data)

        // Update local state
        if let index = pendingModifications.firstIndex(where: { $0.id == modificationId }) {
            pendingModifications.remove(at: index)
        }

        // If accepted, apply the modification to the workout
        if status == .accepted {
            try await applyModificationToWorkout(modification)
        }

        DebugLogger.shared.success("ADAPTIVE", """
            Modification \(status.rawValue):
            ID: \(modificationId)
            Type: \(modification.modificationType.displayName)
            Feedback: \(feedback ?? "none")
            """)

        return modification
    }

    // MARK: - Private: Apply Modification

    private func applyModificationToWorkout(_ modification: WorkoutModification) async throws {
        guard let sessionId = modification.scheduledSessionId else {
            DebugLogger.shared.warning("ADAPTIVE", "No session ID to apply modification to")
            return
        }

        switch modification.modificationType {
        case .loadAdjustment:
            // Update exercise logs with adjusted weights
            if let percentage = modification.loadAdjustmentPercentage {
                DebugLogger.shared.info("ADAPTIVE", "Applying \(percentage)% load adjustment to session \(sessionId)")
                // Implementation would update the scheduled session's target weights
            }

        case .volumeReduction:
            if let sets = modification.volumeReductionSets {
                DebugLogger.shared.info("ADAPTIVE", "Reducing volume by \(sets) sets for session \(sessionId)")
                // Implementation would update the scheduled session's target sets
            }

        case .workoutDelay:
            if let days = modification.delayDays {
                DebugLogger.shared.info("ADAPTIVE", "Delaying session \(sessionId) by \(days) days")
                // Implementation would reschedule the session
            }

        case .skipWorkout:
            DebugLogger.shared.info("ADAPTIVE", "Skipping session \(sessionId)")
            // Implementation would mark session as skipped/rescheduled

        case .insertRecoveryDay:
            DebugLogger.shared.info("ADAPTIVE", "Converting session \(sessionId) to recovery day")
            // Implementation would swap session for recovery template

        case .triggerDeload:
            if let days = modification.deloadDurationDays {
                DebugLogger.shared.info("ADAPTIVE", "Triggering \(days)-day deload starting with session \(sessionId)")
                // Implementation would modify the week's programming
            }

        case .exerciseSwap, .intensityZoneChange:
            DebugLogger.shared.info("ADAPTIVE", "Applying exercise-level modifications to session \(sessionId)")
            // Would apply specific exercise changes
        }
    }
}

// MARK: - Errors

enum AdaptiveTrainingError: LocalizedError {
    case encodingFailed
    case modificationNotFound
    case applyFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode modification request"
        case .modificationNotFound:
            return "Modification not found"
        case .applyFailed(let reason):
            return "Failed to apply modification: \(reason)"
        }
    }
}

// MARK: - PatientScheduledSession Reference

/// Minimal reference to scheduled session for modification context
/// The full model is defined elsewhere
extension AdaptiveTrainingService {
    struct PatientScheduledSession: Identifiable {
        let id: UUID
        let sessionName: String?
        let scheduledDate: Date
    }
}
