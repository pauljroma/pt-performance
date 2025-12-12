import Foundation

/// Exercise model from Supabase session_exercises and exercise_templates
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let session_id: String
    let exercise_template_id: String
    let sequence: Int?
    let prescribed_sets: Int
    let prescribed_reps: String?  // Database has this as string (e.g., "15" or "8-10")
    let prescribed_load: Double?
    let load_unit: String?  // Database field name
    let rest_period_seconds: Int?  // Database field name
    let notes: String?

    // From exercise_templates (joined data)
    struct ExerciseTemplate: Codable, Hashable {
        let id: String
        let name: String
        let category: String?
        let body_region: String?
    }
    let exercise_templates: ExerciseTemplate?

    // Computed property for exercise order (fallback to 0 if sequence is missing)
    var exercise_order: Int {
        return sequence ?? 0
    }

    // Computed property for exercise name (from joined exercise_templates)
    var exercise_name: String? {
        return exercise_templates?.name
    }

    var movement_pattern: String? {
        return exercise_templates?.category
    }

    var equipment: String? {
        return exercise_templates?.body_region
    }

    // Computed properties
    var repsDisplay: String {
        return prescribed_reps ?? "0"
    }

    var loadDisplay: String {
        if let load = prescribed_load, let unit = load_unit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        return "\(prescribed_sets) sets"
    }

    var rest_seconds: Int? {
        return rest_period_seconds
    }

    var prescribed_load_unit: String? {
        return load_unit
    }

    static let sampleExercises: [Exercise] = [
        Exercise(
            id: "ex-1",
            session_id: "session-1",
            exercise_template_id: "template-1",
            sequence: 1,
            prescribed_sets: 3,
            prescribed_reps: "8-10",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: "template-1",
                name: "Bench Press",
                category: "push",
                body_region: "upper"
            )
        ),
        Exercise(
            id: "ex-2",
            session_id: "session-1",
            exercise_template_id: "template-2",
            sequence: 2,
            prescribed_sets: 3,
            prescribed_reps: "10-12",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: "template-2",
                name: "Squat",
                category: "squat",
                body_region: "lower"
            )
        )
    ]
}

/// Session model from Supabase sessions table
/// Matches actual database schema: id, phase_id, name, sequence, weekday, notes, created_at
/// Build 33: Added completion tracking fields
struct Session: Codable, Identifiable {
    let id: String
    let phase_id: String
    let name: String
    let sequence: Int
    let weekday: Int?
    let notes: String?
    let created_at: Date?

    // Build 33: Completion tracking
    let completed: Bool?
    let completed_at: Date?
    let total_volume: Double?
    let avg_rpe: Double?
    let avg_pain: Double?
    let duration_minutes: Int?

    // Exercises for this session (loaded separately or joined)
    var exercises: [Exercise] = []

    enum CodingKeys: String, CodingKey {
        case id
        case phase_id
        case name
        case sequence
        case weekday
        case notes
        case created_at
        case completed
        case completed_at
        case total_volume
        case avg_rpe
        case avg_pain
        case duration_minutes
        // exercises is NOT in CodingKeys - will use default value
    }

    var dateDisplay: String {
        // Use weekday to display day of week
        if let day = weekday {
            let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            return days[safe: day] ?? "Day \(sequence)"
        }
        return "Session \(sequence)"
    }

    var completionStatus: String {
        if completed == true {
            return "Completed"
        }
        return "In Progress"
    }

    var isCompleted: Bool {
        return completed == true
    }
}

/// Today's session response from backend /today-session endpoint
struct TodaySessionResponse: Codable {
    let session: Session?
    let exercises: [Exercise]
    let patient_name: String
    let message: String?
}
