import Foundation

/// Represents a load progression entry tracking session-to-session adjustments
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

/// Progression decision types based on RPE feedback
enum ProgressionAction: String, Codable {
    case increase
    case hold
    case decrease
    case deload

    var description: String {
        switch self {
        case .increase:
            return "Increase load"
        case .hold:
            return "Hold current load"
        case .decrease:
            return "Decrease load"
        case .deload:
            return "Deload required"
        }
    }
}

/// Exercise type classification for progression logic
enum ExerciseType: String, Codable {
    case primary
    case secondary
    case accessory
}

/// Body region classification for load increment sizing
enum BodyRegion: String, Codable {
    case upperBody = "upper"
    case lowerBody = "lower"

    var loadIncrement: Double {
        switch self {
        case .upperBody:
            return 5.0  // 5 lbs for upper body
        case .lowerBody:
            return 10.0  // 10 lbs for lower body
        }
    }
}

/// Calculator for RPE-based load progression
struct ProgressionCalculator {

    /// Calculates next load based on RPE feedback
    /// - Parameters:
    ///   - currentLoad: Current working load
    ///   - targetRpeHigh: Upper end of target RPE range
    ///   - actualRpe: Actual RPE reported by patient
    ///   - exerciseType: Type of exercise (primary, secondary, accessory)
    ///   - bodyRegion: Upper or lower body (affects increment size)
    /// - Returns: Tuple of (action, nextLoad, reason)
    static func calculateNextLoad(
        currentLoad: Double,
        targetRpeHigh: Double,
        actualRpe: Double,
        exerciseType: ExerciseType,
        bodyRegion: BodyRegion
    ) -> (action: ProgressionAction, nextLoad: Double, reason: String) {

        let rpeBuffer: Double = 0.5

        // Case 1: RPE too low - increase load
        if actualRpe <= (targetRpeHigh - rpeBuffer) {
            let increment = bodyRegion.loadIncrement
            let nextLoad = currentLoad + increment
            return (.increase, nextLoad, "RPE below target (\(actualRpe) vs \(targetRpeHigh)), increasing load by \(increment) lbs")
        }

        // Case 2: RPE within range - hold
        else if actualRpe >= (targetRpeHigh - rpeBuffer) && actualRpe <= (targetRpeHigh + rpeBuffer) {
            return (.hold, currentLoad, "RPE within target range (\(actualRpe) vs \(targetRpeHigh))")
        }

        // Case 3: RPE too high - reduce load
        else {
            let reductionPct = 0.05  // 5% reduction
            let nextLoad = currentLoad * (1 - reductionPct)
            return (.decrease, nextLoad, "RPE overshoot (\(actualRpe) vs \(targetRpeHigh)), reducing load by 5%")
        }
    }

    /// Alternative progression for accessory exercises (smaller increments)
    static func calculateAccessoryProgression(
        currentLoad: Double,
        targetRpeHigh: Double,
        actualRpe: Double
    ) -> (action: ProgressionAction, nextLoad: Double, reason: String) {

        let rpeBuffer: Double = 0.5
        let smallIncrement: Double = 2.5  // Smaller increment for accessories

        if actualRpe <= (targetRpeHigh - rpeBuffer) {
            let nextLoad = currentLoad + smallIncrement
            return (.increase, nextLoad, "RPE below target, increasing accessory load by \(smallIncrement) lbs")
        }
        else if actualRpe >= (targetRpeHigh - rpeBuffer) && actualRpe <= (targetRpeHigh + rpeBuffer) {
            return (.hold, currentLoad, "RPE within target range")
        }
        else {
            let reductionPct = 0.03  // 3% reduction for accessories
            let nextLoad = currentLoad * (1 - reductionPct)
            return (.decrease, nextLoad, "RPE overshoot, reducing accessory load by 3%")
        }
    }
}

/// Input model for creating a load progression record
struct CreateLoadProgressionInput: Codable {
    let patientId: String
    let exerciseTemplateId: String
    let sessionId: String?
    let currentLoad: Double
    let loadUnit: String
    let targetRpeLow: Double?
    let targetRpeHigh: Double?
    let actualRpe: Double
    let progressionAction: ProgressionAction
    let nextLoad: Double?
    let reason: String?
    let setsCompleted: Int?
    let repsCompleted: Int?
    let formQuality: Int?

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
