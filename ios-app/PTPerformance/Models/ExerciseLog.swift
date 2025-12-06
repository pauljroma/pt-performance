import Foundation

/// Represents a completed exercise log submitted by a patient
struct ExerciseLog: Codable, Identifiable {
    let id: String
    let sessionExerciseId: String
    let patientId: String
    let loggedAt: Date
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int  // Rating of Perceived Exertion (0-10)
    let painScore: Int  // Pain level (0-10)
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionExerciseId = "session_exercise_id"
        case patientId = "patient_id"
        case loggedAt = "logged_at"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case completed
    }
}

/// Input model for creating a new exercise log
struct CreateExerciseLogInput: Codable {
    let sessionExerciseId: String
    let patientId: String
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case sessionExerciseId = "session_exercise_id"
        case patientId = "patient_id"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case completed
    }
}
