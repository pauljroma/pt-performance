import Foundation

/// ACP-1075: Breathing Session Model
/// Configurable breathing pattern for guided breathing exercises
struct BreathingSession: Codable, Identifiable {
    let id: UUID
    var name: String
    var inhaleDuration: Double // seconds
    var holdDuration: Double // seconds
    var exhaleDuration: Double // seconds
    var targetDuration: Int // total session duration in seconds
    var ambientSound: AmbientSound?
    var enableNarration: Bool
    var timestamp: Date

    init(
        id: UUID = UUID(),
        name: String = "4-7-8 Breathing",
        inhaleDuration: Double = 4.0,
        holdDuration: Double = 7.0,
        exhaleDuration: Double = 8.0,
        targetDuration: Int = 600, // 10 minutes default
        ambientSound: AmbientSound? = nil,
        enableNarration: Bool = true,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.inhaleDuration = inhaleDuration
        self.holdDuration = holdDuration
        self.exhaleDuration = exhaleDuration
        self.targetDuration = targetDuration
        self.ambientSound = ambientSound
        self.enableNarration = enableNarration
        self.timestamp = timestamp
    }

    /// Total duration of one breath cycle
    var cycleDuration: Double {
        inhaleDuration + holdDuration + exhaleDuration
    }

    /// Estimated number of breath cycles in the session
    var estimatedCycles: Int {
        Int(Double(targetDuration) / cycleDuration)
    }
}

/// Ambient sound options for breathing sessions
enum AmbientSound: String, CaseIterable, Codable, Identifiable {
    case rain = "rain"
    case ocean = "ocean"
    case whiteNoise = "white_noise"
    case forest = "forest"
    case none = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .ocean: return "Ocean Waves"
        case .whiteNoise: return "White Noise"
        case .forest: return "Forest"
        case .none: return "None"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .whiteNoise: return "waveform"
        case .forest: return "leaf.fill"
        case .none: return "speaker.slash.fill"
        }
    }
}

/// Breathing phase during a cycle
enum BreathingPhase {
    case inhale
    case hold
    case exhale
    case transition

    var displayText: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        case .transition: return "Prepare"
        }
    }

    var icon: String {
        switch self {
        case .inhale: return "arrow.up.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.down.circle.fill"
        case .transition: return "circle.fill"
        }
    }
}
