import SwiftUI

// MARK: - ACP-522: Arm Care Daily Assessment Model
// 30-second shoulder/elbow check with traffic light system

/// Traffic light status for arm care assessment
/// Determines workout modifications based on arm health
enum ArmCareTrafficLight: String, Codable, CaseIterable {
    case green = "green"   // Full workout OK (score 8-10)
    case yellow = "yellow" // Reduce throwing volume 50%, extra arm care (score 5-7)
    case red = "red"       // No throwing, recovery protocol only (score 0-4)

    /// Display name for UI
    var displayName: String {
        switch self {
        case .green: return "Good to Go"
        case .yellow: return "Proceed with Caution"
        case .red: return "Recovery Mode"
        }
    }

    /// Detailed description for users
    var description: String {
        switch self {
        case .green:
            return "Your arm is feeling great! Full throwing program approved."
        case .yellow:
            return "Some concerns detected. Reduce throwing volume by 50% and add extra arm care exercises."
        case .red:
            return "Rest your arm today. Focus on recovery protocols only - no throwing."
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .green: return "checkmark.circle.fill"
        case .yellow: return "exclamationmark.triangle.fill"
        case .red: return "xmark.octagon.fill"
        }
    }

    /// Throwing volume multiplier (1.0 = 100%, 0.5 = 50%, 0.0 = none)
    var throwingVolumeMultiplier: Double {
        switch self {
        case .green: return 1.0
        case .yellow: return 0.5
        case .red: return 0.0
        }
    }

    /// Whether extra arm care exercises are recommended
    var requiresExtraArmCare: Bool {
        switch self {
        case .green: return false
        case .yellow: return true
        case .red: return true
        }
    }

    /// Whether recovery protocol is required
    var requiresRecoveryProtocol: Bool {
        return self == .red
    }

    /// Determine traffic light from score
    /// - Parameter score: Combined arm care score (0-10)
    /// - Returns: Appropriate traffic light status
    static func from(score: Double) -> ArmCareTrafficLight {
        switch score {
        case 8...10:
            return .green
        case 5..<8:
            return .yellow
        default:
            return .red
        }
    }
}

// MARK: - Pain Location for Arm Care

/// Specific arm locations for pain assessment
enum ArmPainLocation: String, Codable, CaseIterable, Identifiable {
    case anteriorShoulder = "anterior_shoulder"
    case posteriorShoulder = "posterior_shoulder"
    case lateralShoulder = "lateral_shoulder"
    case rotatorCuff = "rotator_cuff"
    case medialElbow = "medial_elbow"   // UCL area
    case lateralElbow = "lateral_elbow"
    case posteriorElbow = "posterior_elbow"
    case forearm = "forearm"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anteriorShoulder: return "Front of Shoulder"
        case .posteriorShoulder: return "Back of Shoulder"
        case .lateralShoulder: return "Side of Shoulder"
        case .rotatorCuff: return "Rotator Cuff Area"
        case .medialElbow: return "Inside of Elbow (UCL)"
        case .lateralElbow: return "Outside of Elbow"
        case .posteriorElbow: return "Back of Elbow"
        case .forearm: return "Forearm"
        }
    }

    /// Whether this location is shoulder-related
    var isShoulder: Bool {
        switch self {
        case .anteriorShoulder, .posteriorShoulder, .lateralShoulder, .rotatorCuff:
            return true
        default:
            return false
        }
    }

    /// Whether this location is elbow-related
    var isElbow: Bool {
        switch self {
        case .medialElbow, .lateralElbow, .posteriorElbow, .forearm:
            return true
        default:
            return false
        }
    }
}

// MARK: - Arm Care Assessment Model

/// Daily arm care assessment for baseball/throwing athletes
/// Captures shoulder and elbow health metrics for workout modification
struct ArmCareAssessment: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let date: Date

    // Shoulder metrics (0-10 scale, higher is better)
    let shoulderPainScore: Int       // 0 = severe pain, 10 = no pain
    let shoulderStiffnessScore: Int  // 0 = very stiff, 10 = no stiffness
    let shoulderStrengthScore: Int   // 0 = very weak, 10 = full strength

    // Elbow metrics (0-10 scale, higher is better)
    let elbowPainScore: Int          // 0 = severe pain, 10 = no pain
    let elbowTightnessScore: Int     // 0 = very tight, 10 = no tightness
    let valgusStressScore: Int       // 0 = significant discomfort, 10 = no discomfort

    // Computed scores
    let shoulderScore: Double        // Average of shoulder metrics
    let elbowScore: Double           // Average of elbow metrics
    let overallScore: Double         // Combined score for traffic light

    // Traffic light status
    let trafficLight: ArmCareTrafficLight

    // Optional pain locations
    let painLocations: [ArmPainLocation]?

    // Optional notes
    let notes: String?

    // Metadata
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case date
        case shoulderPainScore = "shoulder_pain_score"
        case shoulderStiffnessScore = "shoulder_stiffness_score"
        case shoulderStrengthScore = "shoulder_strength_score"
        case elbowPainScore = "elbow_pain_score"
        case elbowTightnessScore = "elbow_tightness_score"
        case valgusStressScore = "valgus_stress_score"
        case shoulderScore = "shoulder_score"
        case elbowScore = "elbow_score"
        case overallScore = "overall_score"
        case trafficLight = "traffic_light"
        case painLocations = "pain_locations"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        date: Date = Date(),
        shoulderPainScore: Int,
        shoulderStiffnessScore: Int,
        shoulderStrengthScore: Int,
        elbowPainScore: Int,
        elbowTightnessScore: Int,
        valgusStressScore: Int,
        painLocations: [ArmPainLocation]? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.date = date
        self.shoulderPainScore = shoulderPainScore
        self.shoulderStiffnessScore = shoulderStiffnessScore
        self.shoulderStrengthScore = shoulderStrengthScore
        self.elbowPainScore = elbowPainScore
        self.elbowTightnessScore = elbowTightnessScore
        self.valgusStressScore = valgusStressScore
        self.painLocations = painLocations
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        // Calculate computed scores
        self.shoulderScore = Double(shoulderPainScore + shoulderStiffnessScore + shoulderStrengthScore) / 3.0
        self.elbowScore = Double(elbowPainScore + elbowTightnessScore + valgusStressScore) / 3.0
        self.overallScore = (self.shoulderScore + self.elbowScore) / 2.0
        self.trafficLight = ArmCareTrafficLight.from(score: self.overallScore)
    }

    // MARK: - Custom Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // Handle date format
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            if let parsedDate = dateFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                date = try container.decode(Date.self, forKey: .date)
            }
        } else {
            date = try container.decode(Date.self, forKey: .date)
        }

        shoulderPainScore = try container.decode(Int.self, forKey: .shoulderPainScore)
        shoulderStiffnessScore = try container.decode(Int.self, forKey: .shoulderStiffnessScore)
        shoulderStrengthScore = try container.decode(Int.self, forKey: .shoulderStrengthScore)
        elbowPainScore = try container.decode(Int.self, forKey: .elbowPainScore)
        elbowTightnessScore = try container.decode(Int.self, forKey: .elbowTightnessScore)
        valgusStressScore = try container.decode(Int.self, forKey: .valgusStressScore)

        // Handle numeric fields that might come as strings
        if let scoreString = try? container.decode(String.self, forKey: .shoulderScore) {
            shoulderScore = Double(scoreString) ?? 0.0
        } else {
            shoulderScore = try container.decode(Double.self, forKey: .shoulderScore)
        }

        if let scoreString = try? container.decode(String.self, forKey: .elbowScore) {
            elbowScore = Double(scoreString) ?? 0.0
        } else {
            elbowScore = try container.decode(Double.self, forKey: .elbowScore)
        }

        if let scoreString = try? container.decode(String.self, forKey: .overallScore) {
            overallScore = Double(scoreString) ?? 0.0
        } else {
            overallScore = try container.decode(Double.self, forKey: .overallScore)
        }

        trafficLight = try container.decode(ArmCareTrafficLight.self, forKey: .trafficLight)
        painLocations = try container.decodeIfPresent([ArmPainLocation].self, forKey: .painLocations)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// MARK: - Input Model for Creating Assessment

/// Input model for submitting arm care assessment
struct ArmCareAssessmentInput: Codable {
    var patientId: String?
    var date: String?

    // Shoulder metrics (0-10)
    var shoulderPainScore: Int
    var shoulderStiffnessScore: Int
    var shoulderStrengthScore: Int

    // Elbow metrics (0-10)
    var elbowPainScore: Int
    var elbowTightnessScore: Int
    var valgusStressScore: Int

    // Computed by database trigger
    var shoulderScore: Double?
    var elbowScore: Double?
    var overallScore: Double?
    var trafficLight: String?

    // Optional
    var painLocations: [String]?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case date
        case shoulderPainScore = "shoulder_pain_score"
        case shoulderStiffnessScore = "shoulder_stiffness_score"
        case shoulderStrengthScore = "shoulder_strength_score"
        case elbowPainScore = "elbow_pain_score"
        case elbowTightnessScore = "elbow_tightness_score"
        case valgusStressScore = "valgus_stress_score"
        case shoulderScore = "shoulder_score"
        case elbowScore = "elbow_score"
        case overallScore = "overall_score"
        case trafficLight = "traffic_light"
        case painLocations = "pain_locations"
        case notes
    }

    /// Validate input before submission
    func validate() throws {
        // Validate shoulder scores (0-10)
        guard (0...10).contains(shoulderPainScore) else {
            throw ArmCareError.invalidScore("Shoulder pain score must be 0-10")
        }
        guard (0...10).contains(shoulderStiffnessScore) else {
            throw ArmCareError.invalidScore("Shoulder stiffness score must be 0-10")
        }
        guard (0...10).contains(shoulderStrengthScore) else {
            throw ArmCareError.invalidScore("Shoulder strength score must be 0-10")
        }

        // Validate elbow scores (0-10)
        guard (0...10).contains(elbowPainScore) else {
            throw ArmCareError.invalidScore("Elbow pain score must be 0-10")
        }
        guard (0...10).contains(elbowTightnessScore) else {
            throw ArmCareError.invalidScore("Elbow tightness score must be 0-10")
        }
        guard (0...10).contains(valgusStressScore) else {
            throw ArmCareError.invalidScore("Valgus stress score must be 0-10")
        }
    }

    /// Create input with pre-calculated scores
    mutating func calculateScores() {
        shoulderScore = Double(shoulderPainScore + shoulderStiffnessScore + shoulderStrengthScore) / 3.0
        elbowScore = Double(elbowPainScore + elbowTightnessScore + valgusStressScore) / 3.0
        let overall = ((shoulderScore ?? 0) + (elbowScore ?? 0)) / 2.0
        overallScore = overall
        trafficLight = ArmCareTrafficLight.from(score: overall).rawValue
    }
}

// MARK: - Workout Modification Recommendation

/// Workout modification based on arm care assessment
struct ArmCareWorkoutModification: Codable {
    let trafficLight: ArmCareTrafficLight
    let throwingVolumeReduction: Double  // Percentage to reduce (0.0 - 1.0)
    let extraArmCareRequired: Bool
    let recoveryProtocolRequired: Bool
    let recommendations: [String]
    let warnings: [String]

    /// Create modification from traffic light status
    static func from(trafficLight: ArmCareTrafficLight, shoulderScore: Double, elbowScore: Double) -> ArmCareWorkoutModification {
        var recommendations: [String] = []
        var warnings: [String] = []

        switch trafficLight {
        case .green:
            recommendations = [
                "Full throwing program approved",
                "Continue normal arm care routine",
                "Monitor any changes during activity"
            ]

        case .yellow:
            recommendations = [
                "Reduce throwing volume by 50%",
                "Add 10-15 minutes of extra arm care",
                "Focus on controlled movements",
                "Use lighter intensity throws"
            ]

            if shoulderScore < elbowScore {
                warnings.append("Shoulder requires extra attention today")
                recommendations.append("Prioritize shoulder mobility work")
            } else if elbowScore < shoulderScore {
                warnings.append("Elbow requires extra attention today")
                recommendations.append("Add forearm and wrist stretches")
            }

        case .red:
            recommendations = [
                "No throwing today - rest the arm",
                "Complete recovery protocol exercises",
                "Apply ice/heat as needed",
                "Consider light range of motion work only"
            ]
            warnings = [
                "Arm needs recovery - avoid high-stress movements",
                "If pain persists, consult your therapist"
            ]

            if shoulderScore <= 4 {
                warnings.append("Shoulder pain is elevated - prioritize rest")
            }
            if elbowScore <= 4 {
                warnings.append("Elbow discomfort detected - no valgus stress")
            }
        }

        return ArmCareWorkoutModification(
            trafficLight: trafficLight,
            throwingVolumeReduction: 1.0 - trafficLight.throwingVolumeMultiplier,
            extraArmCareRequired: trafficLight.requiresExtraArmCare,
            recoveryProtocolRequired: trafficLight.requiresRecoveryProtocol,
            recommendations: recommendations,
            warnings: warnings
        )
    }
}

// MARK: - Arm Care Trend Data

/// Trend data for arm care assessments over time
struct ArmCareTrend: Codable {
    let patientId: UUID
    let daysAnalyzed: Int
    let assessments: [ArmCareAssessmentSummary]
    let statistics: ArmCareTrendStatistics

    struct ArmCareAssessmentSummary: Codable {
        let date: Date
        let overallScore: Double
        let shoulderScore: Double
        let elbowScore: Double
        let trafficLight: ArmCareTrafficLight
    }

    struct ArmCareTrendStatistics: Codable {
        let avgOverallScore: Double?
        let avgShoulderScore: Double?
        let avgElbowScore: Double?
        let greenDays: Int
        let yellowDays: Int
        let redDays: Int
        let totalAssessments: Int
        let trendDirection: TrendDirection

        enum CodingKeys: String, CodingKey {
            case avgOverallScore = "avg_overall_score"
            case avgShoulderScore = "avg_shoulder_score"
            case avgElbowScore = "avg_elbow_score"
            case greenDays = "green_days"
            case yellowDays = "yellow_days"
            case redDays = "red_days"
            case totalAssessments = "total_assessments"
            case trendDirection = "trend_direction"
        }
    }

    /// Use the canonical top-level TrendDirection enum
    typealias TrendDirection = PTPerformance.TrendDirection
}

// MARK: - Errors

enum ArmCareError: LocalizedError {
    case invalidScore(String)
    case noDataFound
    case saveFailed
    case fetchFailed
    case trendCalculationFailed

    var errorDescription: String? {
        switch self {
        case .invalidScore(let message):
            return message
        case .noDataFound:
            return "No arm care assessment data found"
        case .saveFailed:
            return "Failed to save arm care assessment"
        case .fetchFailed:
            return "Failed to fetch arm care assessment"
        case .trendCalculationFailed:
            return "Failed to calculate arm care trend"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension ArmCareAssessment {
    static let sample = ArmCareAssessment(
        patientId: UUID(),
        shoulderPainScore: 8,
        shoulderStiffnessScore: 7,
        shoulderStrengthScore: 9,
        elbowPainScore: 9,
        elbowTightnessScore: 8,
        valgusStressScore: 10
    )

    static let yellowSample = ArmCareAssessment(
        patientId: UUID(),
        shoulderPainScore: 6,
        shoulderStiffnessScore: 5,
        shoulderStrengthScore: 7,
        elbowPainScore: 6,
        elbowTightnessScore: 6,
        valgusStressScore: 7
    )

    static let redSample = ArmCareAssessment(
        patientId: UUID(),
        shoulderPainScore: 3,
        shoulderStiffnessScore: 4,
        shoulderStrengthScore: 5,
        elbowPainScore: 2,
        elbowTightnessScore: 3,
        valgusStressScore: 4
    )
}
#endif
