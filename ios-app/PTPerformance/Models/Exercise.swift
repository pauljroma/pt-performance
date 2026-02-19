import Foundation

/// Exercise model from Supabase session_exercises and exercise_templates
struct Exercise: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let session_id: UUID
    let exercise_template_id: UUID
    let sequence: Int?
    let target_sets: Int?        // Database uses target_sets
    let target_reps: Int?        // Database uses target_reps
    let prescribed_sets: Int?    // Legacy field, may be null
    let prescribed_reps: String? // Database has this as string (e.g., "15" or "8-10")
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

        // Custom decoder to handle null/malformed values gracefully
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unknown Exercise"
            category = try? container.decodeIfPresent(String.self, forKey: .category)
            body_region = try? container.decodeIfPresent(String.self, forKey: .body_region)
            videoUrl = try? container.decodeIfPresent(String.self, forKey: .videoUrl)
            videoThumbnailUrl = try? container.decodeIfPresent(String.self, forKey: .videoThumbnailUrl)
            videoDuration = try? container.decodeIfPresent(Int.self, forKey: .videoDuration)
            formCues = try? container.decodeIfPresent([FormCue].self, forKey: .formCues)
            techniqueCues = try? container.decodeIfPresent(TechniqueCues.self, forKey: .techniqueCues)
            commonMistakes = try? container.decodeIfPresent(String.self, forKey: .commonMistakes)
            safetyNotes = try? container.decodeIfPresent(String.self, forKey: .safetyNotes)
        }

        init(
            id: UUID,
            name: String,
            category: String? = nil,
            body_region: String? = nil,
            videoUrl: String? = nil,
            videoThumbnailUrl: String? = nil,
            videoDuration: Int? = nil,
            formCues: [FormCue]? = nil,
            techniqueCues: TechniqueCues? = nil,
            commonMistakes: String? = nil,
            safetyNotes: String? = nil
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.body_region = body_region
            self.videoUrl = videoUrl
            self.videoThumbnailUrl = videoThumbnailUrl
            self.videoDuration = videoDuration
            self.formCues = formCues
            self.techniqueCues = techniqueCues
            self.commonMistakes = commonMistakes
            self.safetyNotes = safetyNotes
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

            // Custom decoder to handle malformed data from database
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                cue = (try? container.decodeIfPresent(String.self, forKey: .cue)) ?? ""
                timestamp = try? container.decodeIfPresent(Int.self, forKey: .timestamp)
            }

            enum CodingKeys: String, CodingKey {
                case cue, timestamp
            }

            init(cue: String, timestamp: Int? = nil) {
                self.cue = cue
                self.timestamp = timestamp
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
    // Build 441: Made arrays optional to handle null values from database
    struct TechniqueCues: Codable, Hashable, Sendable {
        let setup: [String]
        let execution: [String]
        let breathing: [String]

        init(setup: [String] = [], execution: [String] = [], breathing: [String] = []) {
            self.setup = setup
            self.execution = execution
            self.breathing = breathing
        }

        // Custom decoder to handle null arrays from database
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            setup = (try? container.decodeIfPresent([String].self, forKey: .setup)) ?? []
            execution = (try? container.decodeIfPresent([String].self, forKey: .execution)) ?? []
            breathing = (try? container.decodeIfPresent([String].self, forKey: .breathing)) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case setup, execution, breathing
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

    // Computed property for sets (prefer target_sets, fallback to prescribed_sets)
    var sets: Int {
        return target_sets ?? prescribed_sets ?? 0
    }

    // Computed properties
    var repsDisplay: String {
        if let reps = target_reps {
            return "\(reps)"
        }
        return prescribed_reps ?? "0"
    }

    var loadDisplay: String {
        if let load = prescribed_load, let unit = load_unit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        return "\(sets) sets"
    }

    // For backwards compatibility when prescribed_sets is expected
    var prescribedSetsCompat: Int {
        return sets
    }

    var rest_seconds: Int? {
        return rest_period_seconds
    }

    var prescribed_load_unit: String? {
        return load_unit
    }

    static let sampleExercises: [Exercise] = [
        Exercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010") ?? UUID(),
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000020") ?? UUID(),
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000030") ?? UUID(),
            sequence: 1,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "8-10",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000030") ?? UUID(),
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
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011") ?? UUID(),
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000020") ?? UUID(),
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000031") ?? UUID(),
            sequence: 2,
            target_sets: 3,
            target_reps: 12,
            prescribed_sets: nil,
            prescribed_reps: "10-12",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000031") ?? UUID(),
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

    init(
        id: UUID,
        phase_id: UUID,
        name: String,
        sequence: Int,
        weekday: Int? = nil,
        notes: String? = nil,
        created_at: Date? = nil,
        completed: Bool? = nil,
        started_at: Date? = nil,
        completed_at: Date? = nil,
        total_volume: Double? = nil,
        avg_rpe: Double? = nil,
        avg_pain: Double? = nil,
        duration_minutes: Int? = nil,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.phase_id = phase_id
        self.name = name
        self.sequence = sequence
        self.weekday = weekday
        self.notes = notes
        self.created_at = created_at
        self.completed = completed
        self.started_at = started_at
        self.completed_at = completed_at
        self.total_volume = total_volume
        self.avg_rpe = avg_rpe
        self.avg_pain = avg_pain
        self.duration_minutes = duration_minutes
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        phase_id = try container.decode(UUID.self, forKey: .phase_id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Session"
        sequence = try container.decodeIfPresent(Int.self, forKey: .sequence) ?? 0
        weekday = try container.decodeIfPresent(Int.self, forKey: .weekday)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed)
        started_at = try container.decodeIfPresent(Date.self, forKey: .started_at)
        completed_at = try container.decodeIfPresent(Date.self, forKey: .completed_at)
        total_volume = try container.decodeIfPresent(Double.self, forKey: .total_volume)
        avg_rpe = try container.decodeIfPresent(Double.self, forKey: .avg_rpe)
        avg_pain = try container.decodeIfPresent(Double.self, forKey: .avg_pain)
        duration_minutes = try container.decodeIfPresent(Int.self, forKey: .duration_minutes)
        exercises = []
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

    enum CodingKeys: String, CodingKey {
        case session
        case exercises
        case patient_name
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        session = try container.decodeIfPresent(Session.self, forKey: .session)
        exercises = try container.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
        patient_name = try container.decodeIfPresent(String.self, forKey: .patient_name) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}
