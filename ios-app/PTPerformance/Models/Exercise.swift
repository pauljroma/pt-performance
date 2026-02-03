import Foundation

/// Exercise model from Supabase session_exercises and exercise_templates
struct Exercise: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let session_id: UUID
    let exercise_template_id: UUID
    let sequence: Int?
    let prescribed_sets: Int
    let prescribed_reps: String?  // Database has this as string (e.g., "15" or "8-10")
    let prescribed_load: Double?
    let load_unit: String?  // Database field name
    let rest_period_seconds: Int?  // Database field name
    let notes: String?

    // From exercise_templates (joined data)
    struct ExerciseTemplate: Codable, Hashable, Identifiable, Sendable {
        let id: UUID
        let name: String
        let category: String?
        let body_region: String?

        // Build 46: Video support
        let videoUrl: String?
        let videoThumbnailUrl: String?
        let videoDuration: Int? // Duration in seconds
        let formCues: [FormCue]?

        // Build 61: Technique guide support
        let techniqueCues: TechniqueCues?
        let commonMistakes: String?
        let safetyNotes: String?

        enum CodingKeys: String, CodingKey {
            case id, name, category
            case body_region
            case videoUrl = "video_url"
            case videoThumbnailUrl = "video_thumbnail_url"
            case videoDuration = "video_duration"
            case formCues = "form_cues"
            case techniqueCues = "technique_cues"
            case commonMistakes = "common_mistakes"
            case safetyNotes = "safety_notes"
        }

        struct FormCue: Codable, Hashable, Sendable {
            let cue: String
            let timestamp: Int? // Seconds into video

            var displayTime: String? {
                guard let ts = timestamp else { return nil }
                let minutes = ts / 60
                let seconds = ts % 60
                return String(format: "%d:%02d", minutes, seconds)
            }
        }

        var hasVideo: Bool {
            videoUrl != nil
        }

        var videoDurationDisplay: String? {
            guard let duration = videoDuration else { return nil }
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return String(format: "%d:%02d", minutes, seconds)
            } else {
                return "\(seconds)s"
            }
        }
    }

    // Build 61: Technique cues structure
    struct TechniqueCues: Codable, Hashable, Sendable {
        let setup: [String]
        let execution: [String]
        let breathing: [String]

        init(setup: [String] = [], execution: [String] = [], breathing: [String] = []) {
            self.setup = setup
            self.execution = execution
            self.breathing = breathing
        }
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
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
            sequence: 1,
            prescribed_sets: 3,
            prescribed_reps: "8-10",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
                name: "Bench Press",
                category: "push",
                body_region: "upper",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        ),
        Exercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
            sequence: 2,
            prescribed_sets: 3,
            prescribed_reps: "10-12",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
                name: "Squat",
                category: "squat",
                body_region: "lower",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    ]
}

/// Session model from Supabase sessions table
/// Matches actual database schema: id, phase_id, name, sequence, weekday, notes, created_at
/// Build 33: Added completion tracking fields
struct Session: Codable, Identifiable, Hashable, Sendable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    let phase_id: UUID
    let name: String
    let sequence: Int
    let weekday: Int?
    let notes: String?
    let created_at: Date?

    // Completion tracking
    // Added started_at for accurate workout duration tracking
    let completed: Bool?
    let started_at: Date? // When workout actually began
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
        case started_at
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
            return (day >= 0 && day < days.count) ? days[day] : "Day \(sequence)"
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
struct TodaySessionResponse: Codable, Sendable {
    let session: Session?
    let exercises: [Exercise]
    let patient_name: String
    let message: String?
}
