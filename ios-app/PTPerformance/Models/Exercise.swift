import Foundation

/// Exercise model from Supabase session_exercises and exercise_templates
struct Exercise: Codable, Identifiable {
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
