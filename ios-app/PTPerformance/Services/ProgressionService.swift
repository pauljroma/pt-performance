import Foundation
import Supabase

/// Service for managing exercise load progression and automatic deload scheduling.
///
/// This service implements the Auto-Regulation System's progression logic:
/// - Tracks load changes based on RPE feedback
/// - Monitors deload triggers (missed reps, RPE overshoot, joint pain, low readiness)
/// - Automatically schedules deload periods when multiple triggers accumulate
///
/// ## Progression Rules
/// - Load increases when actual RPE is below target
/// - Load holds when actual RPE matches target range
/// - Load decreases (5%) when actual RPE exceeds target
///
/// ## Deload Triggers
/// A deload is scheduled when 2 or more different trigger types occur
/// within a 7-day window.
@MainActor
class ProgressionService: ObservableObject {
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    /// Initialize with a Supabase client.
    /// - Parameter supabase: The Supabase client to use (defaults to shared instance)
    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Load Progression

    /// Record exercise progression and calculate the recommended load for the next session.
    ///
    /// This method is the core of the auto-regulation system. It:
    /// 1. Calculates the next recommended load based on RPE feedback
    /// 2. Records the progression decision to `load_progression_history`
    /// 3. Evaluates whether a deload should be triggered
    ///
    /// Load adjustments vary by exercise type and body region:
    /// - Primary lower body: +/- 10 lbs
    /// - Primary upper body or secondary lower: +/- 5 lbs
    /// - Accessory exercises: +/- 2.5 lbs
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - exerciseTemplateId: The exercise template UUID string
    ///   - sessionId: The current session UUID string (optional)
    ///   - currentLoad: The load used for this set in pounds
    ///   - actualRpe: The RPE reported by the patient (1-10 scale)
    ///   - targetRpeLow: Lower bound of target RPE range
    ///   - targetRpeHigh: Upper bound of target RPE range
    ///   - setsCompleted: Number of sets completed
    ///   - repsCompleted: Number of reps completed
    ///   - formQuality: Form quality rating (1-5, where 5 is perfect)
    ///   - exerciseType: Classification affecting load increments
    ///   - bodyRegion: Body region affecting load increments
    /// - Throws: Database errors if the insert fails
    func recordProgression(
        patientId: String,
        exerciseTemplateId: String,
        sessionId: String?,
        currentLoad: Double,
        actualRpe: Double,
        targetRpeLow: Double,
        targetRpeHigh: Double,
        setsCompleted: Int,
        repsCompleted: Int,
        formQuality: Int,
        exerciseType: ExerciseType = .primary,
        bodyRegion: BodyRegion = .lowerBody
    ) async throws {
        let logger = DebugLogger.shared

        logger.log("📊 Recording progression for exercise \(exerciseTemplateId)", level: .diagnostic)
        logger.log("  Current load: \(currentLoad), Actual RPE: \(actualRpe)", level: .diagnostic)
        logger.log("  Target RPE range: \(targetRpeLow)-\(targetRpeHigh)", level: .diagnostic)

        // Calculate next load using ProgressionCalculator
        let (action, nextLoad, reason) = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: exerciseType,
            bodyRegion: bodyRegion
        )

        logger.log("  Progression action: \(action.rawValue)", level: .diagnostic)
        logger.log("  Next load: \(nextLoad)", level: .diagnostic)
        logger.log("  Reason: \(reason)", level: .diagnostic)

        // Insert progression record to load_progression_history table
        struct ProgressionRecordInsert: Encodable {
            let patientId: String
            let exerciseTemplateId: String
            let sessionId: String?
            let currentLoad: Double
            let loadUnit: String
            let targetRpeLow: Double
            let targetRpeHigh: Double
            let actualRpe: Double
            let progressionAction: String
            let nextLoad: Double
            let reason: String
            let setsCompleted: Int
            let repsCompleted: Int
            let formQuality: Int

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case exerciseTemplateId = "exercise_template_id"
                case sessionId = "session_id"
                case currentLoad = "current_load"
                case loadUnit = "load_unit"
                case targetRpeLow = "target_rpe_low"
                case targetRpeHigh = "target_rpe_high"
                case actualRpe = "actual_rpe"
                case progressionAction = "progression_action"
                case nextLoad = "next_load"
                case reason
                case setsCompleted = "sets_completed"
                case repsCompleted = "reps_completed"
                case formQuality = "form_quality"
            }
        }

        let record = ProgressionRecordInsert(
            patientId: patientId,
            exerciseTemplateId: exerciseTemplateId,
            sessionId: sessionId,
            currentLoad: currentLoad,
            loadUnit: "lbs",
            targetRpeLow: targetRpeLow,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            progressionAction: action.rawValue,
            nextLoad: nextLoad,
            reason: reason,
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            formQuality: formQuality
        )

        do {
            logger.log("[ProgressionService] Inserting into load_progression_history table...", level: .diagnostic)

            try await supabase.client
                .from("load_progression_history")
                .insert(record)
                .execute()

            logger.log("[ProgressionService] Progression record created successfully", level: .success)

            // Check if deload should be triggered
            try await evaluateDeloadTriggers(patientId: patientId)
        } catch {
            errorLogger.logError(error, context: "ProgressionService.recordProgression", metadata: [
                "patient_id": patientId,
                "exercise_template_id": exerciseTemplateId,
                "current_load": String(currentLoad)
            ])
            throw error
        }
    }

    // MARK: - Deload Evaluation

    /// Evaluate whether a patient should enter a deload period.
    ///
    /// Checks for unresolved deload triggers within a rolling 7-day window.
    /// If 2 or more different trigger types are present, automatically
    /// schedules a deload period.
    ///
    /// Trigger types include:
    /// - `missedRepsPrimary`: Failed to complete prescribed reps on primary lifts
    /// - `rpeOvershoot`: Actual RPE significantly exceeded target
    /// - `jointPain`: Patient reported joint pain during exercise
    /// - `readinessLow`: Daily readiness score below threshold
    ///
    /// - Parameter patientId: The patient's UUID string to evaluate
    /// - Throws: Database errors if trigger fetch or deload scheduling fails
    func evaluateDeloadTriggers(patientId: String) async throws {
        let logger = DebugLogger.shared
        let windowDays = 7

        guard let windowStart = Calendar.current.date(byAdding: .day, value: -windowDays, to: Date()) else {
            logger.log("❌ Failed to calculate window start date", level: .error)
            return
        }

        logger.log("🔍 Evaluating deload triggers for patient \(patientId)", level: .diagnostic)
        logger.log("  Window: \(windowStart) to \(Date())", level: .diagnostic)

        do {
            // Fetch unresolved triggers in 7-day window
            let response = try await supabase.client
                .from("deload_triggers")
                .select()
                .eq("patient_id", value: patientId)
                .eq("resolved", value: false)
                .gte("occurred_at", value: windowStart.ISO8601Format())
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let triggers = try decoder.decode([DeloadTrigger].self, from: response.data)

            logger.log("  Found \(triggers.count) unresolved triggers", level: .diagnostic)

            // Count unique trigger types
            let uniqueTriggerTypes = Set(triggers.map { $0.triggerType })
            logger.log("  Unique trigger types: \(uniqueTriggerTypes.count)", level: .diagnostic)

            // Trigger deload if ≥2 different trigger types
            if uniqueTriggerTypes.count >= 2 {
                logger.log("[ProgressionService] Deload threshold met (\(uniqueTriggerTypes.count) trigger types)", level: .warning)
                try await scheduleDeload(
                    patientId: patientId,
                    triggers: triggers,
                    windowStart: windowStart,
                    windowEnd: Date()
                )
            } else {
                logger.log("[ProgressionService] Deload threshold not met", level: .diagnostic)
            }
        } catch {
            errorLogger.logError(error, context: "ProgressionService.evaluateDeloadTriggers", metadata: [
                "patient_id": patientId
            ])
            throw error
        }
    }

    /// Schedule a deload period for a patient with standard recovery parameters.
    ///
    /// Creates a `deload_history` record with the following defaults:
    /// - Load reduction: 12%
    /// - Volume reduction: 35%
    /// - Duration: 7 days
    ///
    /// All contributing triggers are marked as resolved to prevent
    /// re-triggering during the deload period.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - triggers: Array of triggers that caused this deload
    ///   - windowStart: Start date of the trigger evaluation window
    ///   - windowEnd: End date of the trigger evaluation window
    /// - Throws: Database errors if deload scheduling or trigger updates fail
    func scheduleDeload(
        patientId: String,
        triggers: [DeloadTrigger],
        windowStart: Date,
        windowEnd: Date
    ) async throws {
        let logger = DebugLogger.shared

        logger.log("🔄 Scheduling deload for patient \(patientId)", level: .diagnostic)
        logger.log("  Triggers: \(triggers.map { $0.triggerType.rawValue })", level: .diagnostic)

        let triggerNames = triggers.map { $0.triggerType.rawValue }

        // Create deload_history record with standard reductions
        struct DeloadHistoryInsert: Encodable {
            let patientId: String
            let triggerDate: String
            let triggersMet: [String]
            let triggerWindowStart: String
            let triggerWindowEnd: String
            let loadReductionPct: Double
            let volumeReductionPct: Double
            let durationDays: Int
            let status: String

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case triggerDate = "trigger_date"
                case triggersMet = "triggers_met"
                case triggerWindowStart = "trigger_window_start"
                case triggerWindowEnd = "trigger_window_end"
                case loadReductionPct = "load_reduction_pct"
                case volumeReductionPct = "volume_reduction_pct"
                case durationDays = "duration_days"
                case status
            }
        }

        let deloadRecord = DeloadHistoryInsert(
            patientId: patientId,
            triggerDate: Date().ISO8601Format(),
            triggersMet: triggerNames,
            triggerWindowStart: windowStart.ISO8601Format(),
            triggerWindowEnd: windowEnd.ISO8601Format(),
            loadReductionPct: 0.12,
            volumeReductionPct: 0.35,
            durationDays: 7,
            status: "scheduled"
        )

        struct TriggerUpdate: Encodable {
            let resolved: Bool
            let resolvedAt: String

            enum CodingKeys: String, CodingKey {
                case resolved
                case resolvedAt = "resolved_at"
            }
        }

        do {
            logger.log("🔄 Creating deload_history record...", level: .diagnostic)

            try await supabase.client
                .from("deload_history")
                .insert(deloadRecord)
                .execute()

            logger.log("✅ Deload scheduled successfully", level: .success)

            // Mark all triggers as resolved
            for trigger in triggers {
                logger.log("  Resolving trigger: \(trigger.id)", level: .diagnostic)

                let updateRecord = TriggerUpdate(
                    resolved: true,
                    resolvedAt: Date().ISO8601Format()
                )

                try await supabase.client
                    .from("deload_triggers")
                    .update(updateRecord)
                    .eq("id", value: trigger.id)
                    .execute()
            }

            logger.log("[ProgressionService] All triggers marked as resolved (\(triggers.count) triggers)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgressionService.scheduleDeload", metadata: [
                "patient_id": patientId,
                "trigger_count": String(triggers.count)
            ])
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Fetch the most recent progression record for a specific exercise.
    ///
    /// Use this to get the recommended load for a patient's next set
    /// based on their previous performance.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - exerciseTemplateId: The exercise template UUID string
    /// - Returns: The most recent progression record, or nil if no history exists
    /// - Throws: Database errors if the query fails
    func fetchLastProgression(
        patientId: String,
        exerciseTemplateId: String
    ) async throws -> LoadProgressionHistory? {
        logger.log("[ProgressionService] Fetching last progression for exercise: \(exerciseTemplateId)", level: .diagnostic)

        guard !patientId.isEmpty, !exerciseTemplateId.isEmpty else {
            logger.log("[ProgressionService] Empty patient or exercise ID provided", level: .warning)
            return nil
        }

        do {
            let response = try await supabase.client
                .from("load_progression_history")
                .select()
                .eq("patient_id", value: patientId)
                .eq("exercise_template_id", value: exerciseTemplateId)
                .order("logged_at", ascending: false)
                .limit(1)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([LoadProgressionHistory].self, from: response.data)

            if let record = records.first {
                logger.log("[ProgressionService] Found last progression: \(record.currentLoad) lbs", level: .success)
            } else {
                logger.log("[ProgressionService] No progression history found", level: .info)
            }
            return records.first
        } catch {
            errorLogger.logError(error, context: "ProgressionService.fetchLastProgression", metadata: [
                "patient_id": patientId,
                "exercise_template_id": exerciseTemplateId
            ])
            throw error
        }
    }

    /// Fetch progression history for an exercise over time.
    ///
    /// Returns a chronological history of load changes and RPE feedback
    /// for trend analysis and progress visualization.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID string
    ///   - exerciseTemplateId: The exercise template UUID string
    ///   - limit: Maximum records to return (default: 20)
    /// - Returns: Array of progression records, newest first
    /// - Throws: Database errors if the query fails
    func fetchProgressionHistory(
        patientId: String,
        exerciseTemplateId: String,
        limit: Int = 20
    ) async throws -> [LoadProgressionHistory] {
        logger.log("[ProgressionService] Fetching progression history for exercise: \(exerciseTemplateId)", level: .diagnostic)

        guard !patientId.isEmpty, !exerciseTemplateId.isEmpty else {
            logger.log("[ProgressionService] Empty patient or exercise ID provided", level: .warning)
            return []
        }

        do {
            let response = try await supabase.client
                .from("load_progression_history")
                .select()
                .eq("patient_id", value: patientId)
                .eq("exercise_template_id", value: exerciseTemplateId)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([LoadProgressionHistory].self, from: response.data)

            logger.log("[ProgressionService] Fetched \(records.count) progression records", level: .success)
            return records
        } catch {
            errorLogger.logError(error, context: "ProgressionService.fetchProgressionHistory", metadata: [
                "patient_id": patientId,
                "exercise_template_id": exerciseTemplateId,
                "limit": String(limit)
            ])
            throw error
        }
    }
}

// MARK: - Progression Calculator

/// Pure function calculator for load progression decisions.
///
/// Implements the RPE-based auto-regulation algorithm without side effects.
/// Used by `ProgressionService` for consistent load calculations.
struct ProgressionCalculator {
    /// Calculate the recommended next load based on RPE feedback.
    ///
    /// Uses a 0.5 RPE buffer to determine the appropriate action:
    /// - RPE <= target - 0.5: Increase load
    /// - RPE within target +/- 0.5: Maintain load
    /// - RPE > target + 0.5: Decrease load by 5%
    ///
    /// - Parameters:
    ///   - currentLoad: Current load in pounds
    ///   - targetRpeHigh: Upper bound of the target RPE range
    ///   - actualRpe: Actual RPE reported by patient
    ///   - exerciseType: Exercise classification (primary/secondary/accessory)
    ///   - bodyRegion: Body region (upper/lower) for increment sizing
    /// - Returns: Tuple containing:
    ///   - action: The progression action (increase/hold/decrease)
    ///   - nextLoad: Recommended load for next session
    ///   - reason: Human-readable explanation of the decision
    static func calculateNextLoad(
        currentLoad: Double,
        targetRpeHigh: Double,
        actualRpe: Double,
        exerciseType: ExerciseType,
        bodyRegion: BodyRegion
    ) -> (action: ProgressionAction, nextLoad: Double, reason: String) {

        let rpeBuffer: Double = 0.5

        // Case 1: RPE too low (≤ target_high - 0.5) → increase load
        if actualRpe <= (targetRpeHigh - rpeBuffer) {
            // Use larger increments for lower body and primary lifts
            let increment: Double
            if bodyRegion == .lowerBody && exerciseType == .primary {
                increment = 10.0  // 10 lbs for primary lower body
            } else if bodyRegion == .lowerBody {
                increment = 5.0   // 5 lbs for lower body accessories
            } else if exerciseType == .primary {
                increment = 5.0   // 5 lbs for primary upper body
            } else {
                increment = 2.5   // 2.5 lbs for upper body accessories
            }

            return (
                .increase,
                currentLoad + increment,
                "RPE below target (\(actualRpe) vs \(targetRpeHigh)), increasing load by \(increment) lbs"
            )
        }

        // Case 2: RPE within range → hold load
        else if actualRpe >= (targetRpeHigh - rpeBuffer) && actualRpe <= (targetRpeHigh + rpeBuffer) {
            return (
                .hold,
                currentLoad,
                "RPE within target range (\(actualRpe) vs \(targetRpeHigh)), maintaining load"
            )
        }

        // Case 3: RPE too high (> target_high + 0.5) → decrease load
        else {
            let reductionPct = 0.05  // 5% reduction
            let nextLoad = currentLoad * (1 - reductionPct)
            return (
                .decrease,
                nextLoad,
                "RPE overshoot (\(actualRpe) vs \(targetRpeHigh)), reducing load by 5%"
            )
        }
    }
}

// MARK: - Supporting Types

/// Progression action taken after a set
enum ProgressionAction: String, Codable {
    case increase
    case hold
    case decrease
    case deload
}

/// Type of exercise (affects progression increments)
enum ExerciseType: String, Codable {
    case primary
    case secondary
    case accessory
}

/// Body region (affects progression increments)
enum BodyRegion: String, Codable {
    case upperBody = "upper"
    case lowerBody = "lower"
}

// MARK: - Data Models

/// Represents a load progression history record
struct LoadProgressionHistory: Codable, Identifiable {
    let id: String
    let patientId: String
    let exerciseTemplateId: String
    let sessionId: String?
    let loggedAt: Date

    // Load tracking
    let currentLoad: Double
    let loadUnit: String

    // RPE feedback
    let targetRpeLow: Double?
    let targetRpeHigh: Double?
    let actualRpe: Double

    // Progression decision
    let progressionAction: ProgressionAction
    let nextLoad: Double?
    let reason: String?

    // Metadata
    let setsCompleted: Int?
    let repsCompleted: Int?
    let formQuality: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case exerciseTemplateId = "exercise_template_id"
        case sessionId = "session_id"
        case loggedAt = "logged_at"
        case currentLoad = "current_load"
        case loadUnit = "load_unit"
        case targetRpeLow = "target_rpe_low"
        case targetRpeHigh = "target_rpe_high"
        case actualRpe = "actual_rpe"
        case progressionAction = "progression_action"
        case nextLoad = "next_load"
        case reason
        case setsCompleted = "sets_completed"
        case repsCompleted = "reps_completed"
        case formQuality = "form_quality"
    }
}

/// Represents a deload event in the system
struct DeloadEvent: Codable, Identifiable {
    let id: String
    let patientId: String
    let programId: String?
    let phaseId: String?

    // Trigger information
    let triggerDate: Date
    let triggersMet: [String]
    let triggerWindowStart: Date?
    let triggerWindowEnd: Date?

    // Deload prescription
    let loadReductionPct: Double
    let volumeReductionPct: Double
    let durationDays: Int

    // Status
    let status: DeloadStatus
    let startedAt: Date?
    let completedAt: Date?

    // Outcome
    let recoveryNotes: String?
    let effectivenessRating: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programId = "program_id"
        case phaseId = "phase_id"
        case triggerDate = "trigger_date"
        case triggersMet = "triggers_met"
        case triggerWindowStart = "trigger_window_start"
        case triggerWindowEnd = "trigger_window_end"
        case loadReductionPct = "load_reduction_pct"
        case volumeReductionPct = "volume_reduction_pct"
        case durationDays = "duration_days"
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case recoveryNotes = "recovery_notes"
        case effectivenessRating = "effectiveness_rating"
    }
}

/// Status of a deload period
enum DeloadStatus: String, Codable {
    case scheduled
    case active
    case completed
    case cancelled
}

/// Represents a deload trigger
struct DeloadTrigger: Codable, Identifiable {
    let id: String
    let patientId: String
    let triggerType: DeloadTriggerType
    let occurredAt: Date
    let severity: Int  // 1-3
    let details: [String: String]?
    let resolved: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case triggerType = "trigger_type"
        case occurredAt = "occurred_at"
        case severity
        case details
        case resolved
    }
}

/// Type of deload trigger
enum DeloadTriggerType: String, Codable {
    case missedRepsPrimary = "missed_reps_primary"
    case rpeOvershoot = "rpe_overshoot"
    case jointPain = "joint_pain"
    case readinessLow = "readiness_low"
}
