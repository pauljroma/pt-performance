import Foundation

/// Exercise model from Supabase session_exercises and exercise_templates
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let session_id: String
    let exercise_template_id: String
    let exercise_order: Int
    let prescribed_sets: Int
    let prescribed_reps_min: Int
    let prescribed_reps_max: Int
    let prescribed_load: Double?
    let prescribed_load_unit: String?
    let rest_seconds: Int?
    let notes: String?

    // From exercise_templates (joined data)
    let exercise_name: String?
    let movement_pattern: String?
    let equipment: String?

    // Computed properties
    var repsDisplay: String {
        if prescribed_reps_min == prescribed_reps_max {
            return "\(prescribed_reps_min)"
        } else {
            return "\(prescribed_reps_min)-\(prescribed_reps_max)"
        }
    }

    var loadDisplay: String {
        if let load = prescribed_load, let unit = prescribed_load_unit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        return "\(prescribed_sets) sets"
    }

    static let sampleExercises: [Exercise] = [
        Exercise(
            id: "ex-1",
            session_id: "session-1",
            exercise_template_id: "template-1",
            exercise_order: 1,
            prescribed_sets: 3,
            prescribed_reps_min: 8,
            prescribed_reps_max: 10,
            prescribed_load: 135,
            prescribed_load_unit: "lbs",
            rest_seconds: 90,
            notes: nil,
            exercise_name: "Bench Press",
            movement_pattern: "push",
            equipment: "barbell"
        ),
        Exercise(
            id: "ex-2",
            session_id: "session-1",
            exercise_template_id: "template-2",
            exercise_order: 2,
            prescribed_sets: 3,
            prescribed_reps_min: 10,
            prescribed_reps_max: 12,
            prescribed_load: 185,
            prescribed_load_unit: "lbs",
            rest_seconds: 120,
            notes: nil,
            exercise_name: "Squat",
            movement_pattern: "squat",
            equipment: "barbell"
        )
    ]
}

/// Session model from Supabase sessions table
struct Session: Codable, Identifiable {
    let id: String
    let program_id: String
    let phase_id: String
    let session_number: Int
    let session_date: String?
    let is_completed: Bool
    let intensity_rating: Int?

    // Exercises for this session (loaded separately or joined)
    var exercises: [Exercise] = []

    var dateDisplay: String {
        guard let dateStr = session_date,
              let date = ISO8601DateFormatter().date(from: dateStr) else {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var completionStatus: String {
        return is_completed ? "Completed" : "In Progress"
    }
}

/// Today's session response from backend /today-session endpoint
struct TodaySessionResponse: Codable {
    let session: Session?
    let exercises: [Exercise]
    let patient_name: String
    let message: String?
}
