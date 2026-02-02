//
//  JaegerBandProtocol.swift
//  PTPerformance
//
//  ACP-521: Jaeger Band Protocol Integration
//  Complete J-Band routine model with exercises, video references, and coaching cues
//

import Foundation

// MARK: - Protocol Variation

/// Different variations of the J-Band protocol based on time and context
enum JaegerBandVariation: String, Codable, CaseIterable, Identifiable, Hashable {
    case full = "full"
    case quick = "quick"
    case travel = "travel"
    case preThrow = "pre_throw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full: return "Full J-Band Routine"
        case .quick: return "Quick J-Band (5 min)"
        case .travel: return "Travel J-Band"
        case .preThrow: return "Pre-Throwing Warm-up"
        }
    }

    var description: String {
        switch self {
        case .full: return "Complete 15-exercise Jaeger Band routine for comprehensive arm care"
        case .quick: return "Abbreviated 5-minute routine for time-constrained days"
        case .travel: return "Modified routine suitable for travel with limited space"
        case .preThrow: return "Pre-throwing warm-up protocol to prepare the arm for activity"
        }
    }

    var estimatedDuration: Int {
        switch self {
        case .full: return 15
        case .quick: return 5
        case .travel: return 8
        case .preThrow: return 10
        }
    }

    var iconName: String {
        switch self {
        case .full: return "figure.strengthtraining.traditional"
        case .quick: return "bolt.fill"
        case .travel: return "airplane"
        case .preThrow: return "baseball.fill"
        }
    }
}

// MARK: - Exercise Category

/// Categories of J-Band exercises
enum JaegerBandExerciseCategory: String, Codable, CaseIterable, Hashable {
    case warmup = "warmup"
    case wristFlexion = "wrist_flexion"
    case wristExtension = "wrist_extension"
    case internalRotation = "internal_rotation"
    case externalRotation = "external_rotation"
    case shoulderFlexion = "shoulder_flexion"
    case shoulderExtension = "shoulder_extension"
    case scapularStability = "scapular_stability"
    case throwingPattern = "throwing_pattern"

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .wristFlexion: return "Wrist Flexion"
        case .wristExtension: return "Wrist Extension"
        case .internalRotation: return "Internal Rotation"
        case .externalRotation: return "External Rotation"
        case .shoulderFlexion: return "Shoulder Flexion"
        case .shoulderExtension: return "Shoulder Extension"
        case .scapularStability: return "Scapular Stability"
        case .throwingPattern: return "Throwing Pattern"
        }
    }
}

// MARK: - J-Band Exercise

/// Represents a single J-Band exercise with all associated data
struct JaegerBandExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: JaegerBandExerciseCategory
    let sequence: Int
    let reps: Int
    let sets: Int
    let holdSeconds: Int?
    let tempo: String?
    let description: String
    let coachingCues: [String]
    let commonMistakes: [String]
    let videoUrl: String?
    let thumbnailUrl: String?
    let targetMuscles: [String]
    let isRequired: Bool
    let variations: [JaegerBandVariation]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case sequence
        case reps
        case sets
        case holdSeconds = "hold_seconds"
        case tempo
        case description
        case coachingCues = "coaching_cues"
        case commonMistakes = "common_mistakes"
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case targetMuscles = "target_muscles"
        case isRequired = "is_required"
        case variations
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: JaegerBandExerciseCategory,
        sequence: Int,
        reps: Int,
        sets: Int = 1,
        holdSeconds: Int? = nil,
        tempo: String? = nil,
        description: String,
        coachingCues: [String],
        commonMistakes: [String] = [],
        videoUrl: String? = nil,
        thumbnailUrl: String? = nil,
        targetMuscles: [String],
        isRequired: Bool = true,
        variations: [JaegerBandVariation] = [.full]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.sequence = sequence
        self.reps = reps
        self.sets = sets
        self.holdSeconds = holdSeconds
        self.tempo = tempo
        self.description = description
        self.coachingCues = coachingCues
        self.commonMistakes = commonMistakes
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.targetMuscles = targetMuscles
        self.isRequired = isRequired
        self.variations = variations
    }

    // MARK: - Computed Properties

    var prescriptionDisplay: String {
        if let hold = holdSeconds {
            return sets > 1 ? "\(sets) x \(hold)s hold" : "\(hold)s hold"
        }
        return sets > 1 ? "\(sets) x \(reps) reps" : "\(reps) reps"
    }

    var hasVideo: Bool {
        videoUrl != nil
    }

    var tempoDisplay: String? {
        guard let tempo = tempo else { return nil }
        return "Tempo: \(tempo)"
    }
}

// MARK: - J-Band Protocol

/// Complete Jaeger Band Protocol with all exercises and metadata
struct JaegerBandProtocol: Identifiable, Codable, Hashable {
    let id: UUID
    let variation: JaegerBandVariation
    let exercises: [JaegerBandExercise]
    let estimatedDurationMinutes: Int
    let description: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case variation
        case exercises
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case description
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        variation: JaegerBandVariation,
        exercises: [JaegerBandExercise],
        description: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.variation = variation
        self.exercises = exercises
        self.estimatedDurationMinutes = variation.estimatedDuration
        self.description = description
        self.createdAt = createdAt
    }

    var exerciseCount: Int {
        exercises.count
    }

    var totalReps: Int {
        exercises.reduce(0) { $0 + ($1.reps * $1.sets) }
    }
}

// MARK: - Session Progress

/// Tracks progress through a J-Band session
struct JaegerBandSessionProgress: Codable, Hashable, Equatable {
    var currentExerciseIndex: Int
    var completedExercises: Set<UUID>
    var startTime: Date?
    var endTime: Date?
    var skippedExercises: Set<UUID>
    var notes: String?

    init() {
        self.currentExerciseIndex = 0
        self.completedExercises = []
        self.startTime = nil
        self.endTime = nil
        self.skippedExercises = []
        self.notes = nil
    }

    var isComplete: Bool {
        endTime != nil
    }

    var durationMinutes: Int? {
        guard let start = startTime, let end = endTime else { return nil }
        return Int(end.timeIntervalSince(start) / 60)
    }

    var completionPercentage: Double {
        guard !completedExercises.isEmpty else { return 0 }
        let total = completedExercises.count + skippedExercises.count
        return Double(completedExercises.count) / Double(max(1, total))
    }
}

// MARK: - Session Log

/// Log entry for a completed J-Band session
struct JaegerBandSessionLog: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let variation: JaegerBandVariation
    let completedAt: Date
    let durationMinutes: Int
    let exercisesCompleted: Int
    let exercisesSkipped: Int
    let notes: String?
    let armSorenessBefore: Int?
    let armSorenessAfter: Int?
    let wasPreThrowingWarmup: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case variation
        case completedAt = "completed_at"
        case durationMinutes = "duration_minutes"
        case exercisesCompleted = "exercises_completed"
        case exercisesSkipped = "exercises_skipped"
        case notes
        case armSorenessBefore = "arm_soreness_before"
        case armSorenessAfter = "arm_soreness_after"
        case wasPreThrowingWarmup = "was_pre_throwing_warmup"
    }

    init(
        id: UUID = UUID(),
        patientId: UUID,
        variation: JaegerBandVariation,
        completedAt: Date = Date(),
        durationMinutes: Int,
        exercisesCompleted: Int,
        exercisesSkipped: Int = 0,
        notes: String? = nil,
        armSorenessBefore: Int? = nil,
        armSorenessAfter: Int? = nil,
        wasPreThrowingWarmup: Bool = false
    ) {
        self.id = id
        self.patientId = patientId
        self.variation = variation
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.exercisesCompleted = exercisesCompleted
        self.exercisesSkipped = exercisesSkipped
        self.notes = notes
        self.armSorenessBefore = armSorenessBefore
        self.armSorenessAfter = armSorenessAfter
        self.wasPreThrowingWarmup = wasPreThrowingWarmup
    }
}

// MARK: - Static Protocol Definitions

extension JaegerBandProtocol {
    /// Video base URL for J-Band exercise videos
    private static let videoBaseUrl = "https://ptperformance.com/videos/jband"

    /// Full J-Band Protocol with all 15 standard exercises
    static let fullProtocol: JaegerBandProtocol = {
        let exercises: [JaegerBandExercise] = [
            // 1. Arm Circles (Warm-up)
            JaegerBandExercise(
                name: "Arm Circles (Forward)",
                category: .warmup,
                sequence: 1,
                reps: 10,
                sets: 1,
                description: "Large controlled arm circles to warm up the shoulder joint and increase blood flow.",
                coachingCues: [
                    "Stand tall with feet shoulder-width apart",
                    "Keep arms straight and relaxed",
                    "Make large, controlled circles",
                    "Gradually increase the size of circles"
                ],
                commonMistakes: [
                    "Circles too small",
                    "Moving too fast",
                    "Shrugging shoulders"
                ],
                videoUrl: "\(videoBaseUrl)/arm-circles-forward.mp4",
                targetMuscles: ["Deltoids", "Rotator Cuff", "Trapezius"],
                variations: [.full, .quick, .travel, .preThrow]
            ),

            // 2. Arm Circles (Backward)
            JaegerBandExercise(
                name: "Arm Circles (Backward)",
                category: .warmup,
                sequence: 2,
                reps: 10,
                sets: 1,
                description: "Reverse arm circles to warm up the posterior shoulder structures.",
                coachingCues: [
                    "Maintain upright posture",
                    "Lead with thumbs pointing backward",
                    "Control the movement throughout",
                    "Keep core engaged"
                ],
                commonMistakes: [
                    "Arching the lower back",
                    "Circles too small",
                    "Loss of posture"
                ],
                videoUrl: "\(videoBaseUrl)/arm-circles-backward.mp4",
                targetMuscles: ["Posterior Deltoids", "Rhomboids", "Rotator Cuff"],
                variations: [.full, .quick, .travel, .preThrow]
            ),

            // 3. Wrist Flexion
            JaegerBandExercise(
                name: "Wrist Flexion with Band",
                category: .wristFlexion,
                sequence: 3,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Strengthen the wrist flexors important for grip and throwing mechanics.",
                coachingCues: [
                    "Anchor band under foot",
                    "Keep forearm parallel to ground",
                    "Curl wrist up against resistance",
                    "Control the eccentric (lowering) phase"
                ],
                commonMistakes: [
                    "Moving the forearm",
                    "Going too fast",
                    "Not controlling the negative"
                ],
                videoUrl: "\(videoBaseUrl)/wrist-flexion.mp4",
                targetMuscles: ["Wrist Flexors", "Forearm"],
                variations: [.full, .travel]
            ),

            // 4. Wrist Extension
            JaegerBandExercise(
                name: "Wrist Extension with Band",
                category: .wristExtension,
                sequence: 4,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Strengthen the wrist extensors for balanced forearm development.",
                coachingCues: [
                    "Anchor band under foot",
                    "Palm faces down",
                    "Extend wrist up against resistance",
                    "Full range of motion"
                ],
                commonMistakes: [
                    "Limited range of motion",
                    "Moving the elbow",
                    "Using momentum"
                ],
                videoUrl: "\(videoBaseUrl)/wrist-extension.mp4",
                targetMuscles: ["Wrist Extensors", "Forearm"],
                variations: [.full, .travel]
            ),

            // 5. Pronation/Supination
            JaegerBandExercise(
                name: "Pronation/Supination",
                category: .wristFlexion,
                sequence: 5,
                reps: 15,
                sets: 1,
                description: "Rotate the forearm to strengthen pronators and supinators.",
                coachingCues: [
                    "Keep elbow at 90 degrees",
                    "Rotate forearm fully in each direction",
                    "Control the movement",
                    "Keep upper arm stable"
                ],
                commonMistakes: [
                    "Moving at the shoulder",
                    "Incomplete rotation",
                    "Rushing the movement"
                ],
                videoUrl: "\(videoBaseUrl)/pronation-supination.mp4",
                targetMuscles: ["Pronators", "Supinators", "Forearm"],
                variations: [.full]
            ),

            // 6. Internal Rotation at 90/90
            JaegerBandExercise(
                name: "Internal Rotation at 90/90",
                category: .internalRotation,
                sequence: 6,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Strengthen internal rotators in the throwing position.",
                coachingCues: [
                    "Arm at 90 degrees abduction",
                    "Elbow at 90 degrees",
                    "Rotate hand down toward ground",
                    "Keep elbow position fixed"
                ],
                commonMistakes: [
                    "Dropping the elbow",
                    "Moving at the shoulder blade",
                    "Leaning torso"
                ],
                videoUrl: "\(videoBaseUrl)/internal-rotation-90.mp4",
                targetMuscles: ["Subscapularis", "Pectoralis Major", "Latissimus Dorsi"],
                variations: [.full, .preThrow]
            ),

            // 7. External Rotation at 90/90
            JaegerBandExercise(
                name: "External Rotation at 90/90",
                category: .externalRotation,
                sequence: 7,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Essential exercise for rotator cuff strength and deceleration capacity.",
                coachingCues: [
                    "Arm at 90 degrees abduction",
                    "Elbow at 90 degrees",
                    "Rotate hand back and up",
                    "Squeeze shoulder blade back"
                ],
                commonMistakes: [
                    "Arching the back",
                    "Shrugging the shoulder",
                    "Incomplete range of motion"
                ],
                videoUrl: "\(videoBaseUrl)/external-rotation-90.mp4",
                targetMuscles: ["Infraspinatus", "Teres Minor", "Posterior Deltoid"],
                variations: [.full, .quick, .preThrow]
            ),

            // 8. External Rotation at Side
            JaegerBandExercise(
                name: "External Rotation at Side",
                category: .externalRotation,
                sequence: 8,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "External rotation with arm at side for rotator cuff strengthening.",
                coachingCues: [
                    "Elbow tucked at side",
                    "Towel roll between elbow and body",
                    "Rotate forearm outward",
                    "Keep wrist neutral"
                ],
                commonMistakes: [
                    "Elbow moving away from body",
                    "Wrist deviation",
                    "Using body momentum"
                ],
                videoUrl: "\(videoBaseUrl)/external-rotation-side.mp4",
                targetMuscles: ["Infraspinatus", "Teres Minor"],
                variations: [.full, .quick, .travel, .preThrow]
            ),

            // 9. Internal Rotation at Side
            JaegerBandExercise(
                name: "Internal Rotation at Side",
                category: .internalRotation,
                sequence: 9,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Internal rotation with arm at side for subscapularis strengthening.",
                coachingCues: [
                    "Elbow tucked at side",
                    "Rotate forearm across body",
                    "Keep elbow at 90 degrees",
                    "Control the return"
                ],
                commonMistakes: [
                    "Elbow moving forward",
                    "Trunk rotation",
                    "Going too fast"
                ],
                videoUrl: "\(videoBaseUrl)/internal-rotation-side.mp4",
                targetMuscles: ["Subscapularis", "Pectoralis Major"],
                variations: [.full, .travel]
            ),

            // 10. Shoulder Flexion
            JaegerBandExercise(
                name: "Shoulder Flexion",
                category: .shoulderFlexion,
                sequence: 10,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Strengthen the anterior deltoid and shoulder flexors.",
                coachingCues: [
                    "Band anchored under foot",
                    "Arm straight, thumb up",
                    "Raise arm to shoulder height",
                    "Control the lowering phase"
                ],
                commonMistakes: [
                    "Shrugging shoulders",
                    "Arching back",
                    "Going above shoulder level"
                ],
                videoUrl: "\(videoBaseUrl)/shoulder-flexion.mp4",
                targetMuscles: ["Anterior Deltoid", "Biceps"],
                variations: [.full]
            ),

            // 11. Shoulder Extension
            JaegerBandExercise(
                name: "Shoulder Extension",
                category: .shoulderExtension,
                sequence: 11,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Strengthen the posterior shoulder and lat muscles.",
                coachingCues: [
                    "Band anchored at shoulder height",
                    "Pull arm straight back",
                    "Keep arm close to body",
                    "Squeeze shoulder blade"
                ],
                commonMistakes: [
                    "Bending the elbow",
                    "Leaning forward",
                    "Shrugging"
                ],
                videoUrl: "\(videoBaseUrl)/shoulder-extension.mp4",
                targetMuscles: ["Posterior Deltoid", "Latissimus Dorsi", "Triceps"],
                variations: [.full]
            ),

            // 12. Scapular Retraction (Pull-Aparts)
            JaegerBandExercise(
                name: "Band Pull-Aparts",
                category: .scapularStability,
                sequence: 12,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Essential exercise for scapular stability and posture.",
                coachingCues: [
                    "Arms straight in front",
                    "Pull band apart by squeezing shoulder blades",
                    "Keep arms at shoulder height",
                    "Control the return"
                ],
                commonMistakes: [
                    "Bending elbows",
                    "Shrugging shoulders",
                    "Not fully squeezing scapulae"
                ],
                videoUrl: "\(videoBaseUrl)/band-pull-aparts.mp4",
                targetMuscles: ["Rhomboids", "Middle Trapezius", "Posterior Deltoid"],
                variations: [.full, .quick, .travel, .preThrow]
            ),

            // 13. Low Rows
            JaegerBandExercise(
                name: "Low Rows",
                category: .scapularStability,
                sequence: 13,
                reps: 15,
                sets: 1,
                tempo: "2-1-2",
                description: "Row pattern to strengthen the mid-back and scapular stabilizers.",
                coachingCues: [
                    "Band anchored low",
                    "Pull elbows back and down",
                    "Squeeze shoulder blades together",
                    "Keep chest up"
                ],
                commonMistakes: [
                    "Rounding upper back",
                    "Using momentum",
                    "Not engaging scapulae"
                ],
                videoUrl: "\(videoBaseUrl)/low-rows.mp4",
                targetMuscles: ["Rhomboids", "Middle Trapezius", "Latissimus Dorsi"],
                variations: [.full, .travel]
            ),

            // 14. Throwing Motion (Deceleration)
            JaegerBandExercise(
                name: "Throwing Deceleration",
                category: .throwingPattern,
                sequence: 14,
                reps: 10,
                sets: 1,
                tempo: "Controlled",
                description: "Mimic the deceleration phase of throwing to strengthen posterior shoulder.",
                coachingCues: [
                    "Band anchored at shoulder height behind you",
                    "Start in cocked position",
                    "Slowly move through throwing motion",
                    "Focus on controlling the deceleration"
                ],
                commonMistakes: [
                    "Going too fast",
                    "Not controlling the eccentric",
                    "Poor throwing mechanics"
                ],
                videoUrl: "\(videoBaseUrl)/throwing-deceleration.mp4",
                targetMuscles: ["Posterior Rotator Cuff", "Posterior Deltoid", "Rhomboids"],
                variations: [.full, .preThrow]
            ),

            // 15. Figure 8s
            JaegerBandExercise(
                name: "Figure 8s",
                category: .throwingPattern,
                sequence: 15,
                reps: 10,
                sets: 1,
                description: "Dynamic shoulder movement pattern for coordination and blood flow.",
                coachingCues: [
                    "Hold band in throwing hand",
                    "Draw figure 8 pattern in front of body",
                    "Keep movement controlled and smooth",
                    "Incorporate slight trunk rotation"
                ],
                commonMistakes: [
                    "Jerky movements",
                    "Too small pattern",
                    "Not engaging core"
                ],
                videoUrl: "\(videoBaseUrl)/figure-8s.mp4",
                targetMuscles: ["Deltoids", "Rotator Cuff", "Core"],
                variations: [.full, .preThrow]
            )
        ]

        return JaegerBandProtocol(
            variation: .full,
            exercises: exercises,
            description: "Complete 15-exercise Jaeger Band protocol for comprehensive arm care and injury prevention"
        )
    }()

    /// Quick 5-minute J-Band routine
    static let quickProtocol: JaegerBandProtocol = {
        let fullExercises = fullProtocol.exercises
        let quickExercises = fullExercises.filter { exercise in
            exercise.variations.contains(.quick)
        }

        return JaegerBandProtocol(
            variation: .quick,
            exercises: quickExercises,
            description: "Abbreviated 5-minute J-Band routine for time-constrained days"
        )
    }()

    /// Travel J-Band routine
    static let travelProtocol: JaegerBandProtocol = {
        let fullExercises = fullProtocol.exercises
        let travelExercises = fullExercises.filter { exercise in
            exercise.variations.contains(.travel)
        }

        return JaegerBandProtocol(
            variation: .travel,
            exercises: travelExercises,
            description: "Modified J-Band routine for travel with limited space"
        )
    }()

    /// Pre-throwing warm-up protocol
    static let preThrowProtocol: JaegerBandProtocol = {
        let fullExercises = fullProtocol.exercises
        let preThrowExercises = fullExercises.filter { exercise in
            exercise.variations.contains(.preThrow)
        }

        return JaegerBandProtocol(
            variation: .preThrow,
            exercises: preThrowExercises,
            description: "Pre-throwing warm-up protocol to prepare the arm for throwing activity"
        )
    }()

    /// Get protocol for a specific variation
    static func protocolFor(variation: JaegerBandVariation) -> JaegerBandProtocol {
        switch variation {
        case .full: return fullProtocol
        case .quick: return quickProtocol
        case .travel: return travelProtocol
        case .preThrow: return preThrowProtocol
        }
    }

    /// All available protocols
    static let allProtocols: [JaegerBandProtocol] = [
        fullProtocol,
        quickProtocol,
        travelProtocol,
        preThrowProtocol
    ]
}
