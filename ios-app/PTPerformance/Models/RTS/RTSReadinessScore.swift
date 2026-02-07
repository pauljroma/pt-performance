import Foundation
import SwiftUI

// MARK: - RTSReadinessScore Model
// Readiness scoring with multi-component assessment for Return-to-Sport

/// Represents a comprehensive readiness assessment for RTS progression
struct RTSReadinessScore: Identifiable, Codable, Hashable {
    let id: UUID
    let protocolId: UUID
    let phaseId: UUID
    let recordedBy: UUID
    let recordedAt: Date
    let physicalScore: Double
    let functionalScore: Double
    let psychologicalScore: Double
    let overallScore: Double
    let trafficLight: RTSTrafficLight
    let riskFactors: [RTSRiskFactor]
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case phaseId = "phase_id"
        case recordedBy = "recorded_by"
        case recordedAt = "recorded_at"
        case physicalScore = "physical_score"
        case functionalScore = "functional_score"
        case psychologicalScore = "psychological_score"
        case overallScore = "overall_score"
        case trafficLight = "traffic_light"
        case riskFactors = "risk_factors"
        case notes
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Formatted recorded date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: recordedAt)
    }

    /// Formatted short date string
    var formattedShortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: recordedAt)
    }

    /// Whether any high severity risk factors exist
    var hasHighRisk: Bool {
        riskFactors.contains { $0.severity == .high }
    }

    /// Whether any moderate or higher severity risk factors exist
    var hasModerateOrHigherRisk: Bool {
        riskFactors.contains { $0.severity == .moderate || $0.severity == .high }
    }

    /// Count of risk factors by severity
    var riskFactorCounts: (high: Int, moderate: Int, low: Int) {
        let high = riskFactors.filter { $0.severity == .high }.count
        let moderate = riskFactors.filter { $0.severity == .moderate }.count
        let low = riskFactors.filter { $0.severity == .low }.count
        return (high, moderate, low)
    }

    /// Physical score as percentage string
    var physicalPercentage: String {
        String(format: "%.0f%%", physicalScore)
    }

    /// Functional score as percentage string
    var functionalPercentage: String {
        String(format: "%.0f%%", functionalScore)
    }

    /// Psychological score as percentage string
    var psychologicalPercentage: String {
        String(format: "%.0f%%", psychologicalScore)
    }

    /// Overall score as percentage string
    var overallPercentage: String {
        String(format: "%.0f%%", overallScore)
    }

    // MARK: - Static Methods

    /// Calculate overall readiness score from component scores
    /// Weighted: Physical 40%, Functional 40%, Psychological 20%
    /// - Parameters:
    ///   - physical: Physical readiness score (0-100)
    ///   - functional: Functional readiness score (0-100)
    ///   - psychological: Psychological readiness score (0-100)
    /// - Returns: Weighted overall score (0-100)
    static func calculateOverall(physical: Double, functional: Double, psychological: Double) -> Double {
        return (physical * 0.4) + (functional * 0.4) + (psychological * 0.2)
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        protocolId: UUID,
        phaseId: UUID,
        recordedBy: UUID,
        recordedAt: Date = Date(),
        physicalScore: Double,
        functionalScore: Double,
        psychologicalScore: Double,
        overallScore: Double? = nil,
        trafficLight: RTSTrafficLight? = nil,
        riskFactors: [RTSRiskFactor] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.protocolId = protocolId
        self.phaseId = phaseId
        self.recordedBy = recordedBy
        self.recordedAt = recordedAt
        self.physicalScore = physicalScore
        self.functionalScore = functionalScore
        self.psychologicalScore = psychologicalScore

        // Calculate overall score if not provided
        let calculatedOverall = overallScore ?? RTSReadinessScore.calculateOverall(
            physical: physicalScore,
            functional: functionalScore,
            psychological: psychologicalScore
        )
        self.overallScore = calculatedOverall

        // Determine traffic light if not provided
        self.trafficLight = trafficLight ?? RTSTrafficLight.from(score: calculatedOverall)

        self.riskFactors = riskFactors
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Risk Factor

/// Represents a risk factor identified during readiness assessment
struct RTSRiskFactor: Codable, Hashable, Identifiable {
    var id: String { category + name }

    let category: String
    let name: String
    let severity: RTSRiskSeverity
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case category
        case name
        case severity
        case notes
    }

    // MARK: - Initializer

    init(
        category: String,
        name: String,
        severity: RTSRiskSeverity,
        notes: String? = nil
    ) {
        self.category = category
        self.name = name
        self.severity = severity
        self.notes = notes
    }
}

// MARK: - Risk Severity

/// Severity levels for RTS risk factors
enum RTSRiskSeverity: String, Codable, CaseIterable, Identifiable, Hashable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .low: return "exclamationmark.circle"
        case .moderate: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon.fill"
        }
    }

    /// Numeric weight for calculations
    var weight: Double {
        switch self {
        case .low: return 0.25
        case .moderate: return 0.5
        case .high: return 1.0
        }
    }
}

// MARK: - Input Model

/// Input model for creating readiness scores
struct RTSReadinessScoreInput: Codable {
    var protocolId: String?
    var phaseId: String?
    var recordedBy: String?
    var recordedAt: String?
    var physicalScore: Double?
    var functionalScore: Double?
    var psychologicalScore: Double?
    var overallScore: Double?
    var trafficLight: String?
    var riskFactors: [RTSRiskFactorInput]?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case phaseId = "phase_id"
        case recordedBy = "recorded_by"
        case recordedAt = "recorded_at"
        case physicalScore = "physical_score"
        case functionalScore = "functional_score"
        case psychologicalScore = "psychological_score"
        case overallScore = "overall_score"
        case trafficLight = "traffic_light"
        case riskFactors = "risk_factors"
        case notes
    }

    /// Validate input before submission
    func validate() throws {
        guard protocolId != nil else {
            throw RTSReadinessError.invalidInput("Protocol ID is required")
        }
        guard phaseId != nil else {
            throw RTSReadinessError.invalidInput("Phase ID is required")
        }
        guard recordedBy != nil else {
            throw RTSReadinessError.invalidInput("Recorder ID is required")
        }

        if let physical = physicalScore, !(0...100).contains(physical) {
            throw RTSReadinessError.invalidInput("Physical score must be 0-100")
        }
        if let functional = functionalScore, !(0...100).contains(functional) {
            throw RTSReadinessError.invalidInput("Functional score must be 0-100")
        }
        if let psychological = psychologicalScore, !(0...100).contains(psychological) {
            throw RTSReadinessError.invalidInput("Psychological score must be 0-100")
        }
    }

    /// Calculate overall score and traffic light from component scores
    mutating func calculateDerivedFields() {
        guard let physical = physicalScore,
              let functional = functionalScore,
              let psychological = psychologicalScore else {
            return
        }

        let overall = RTSReadinessScore.calculateOverall(
            physical: physical,
            functional: functional,
            psychological: psychological
        )
        self.overallScore = overall
        self.trafficLight = RTSTrafficLight.from(score: overall).rawValue
    }
}

/// Input model for risk factors
struct RTSRiskFactorInput: Codable {
    var category: String?
    var name: String?
    var severity: String?
    var notes: String?
}

// MARK: - Errors

enum RTSReadinessError: LocalizedError {
    case invalidInput(String)
    case scoreNotFound
    case saveFailed
    case fetchFailed
    case invalidScoreRange

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .scoreNotFound:
            return "Readiness score not found"
        case .saveFailed:
            return "Failed to save readiness score"
        case .fetchFailed:
            return "Failed to fetch readiness scores"
        case .invalidScoreRange:
            return "Score must be between 0 and 100"
        }
    }
}

// MARK: - Trend Data

/// Trend data for readiness scores over time
struct RTSReadinessTrend: Codable {
    let protocolId: UUID
    let scores: [RTSReadinessScore]
    let averageOverall: Double?
    let averagePhysical: Double?
    let averageFunctional: Double?
    let averagePsychological: Double?
    let trendDirection: RTSReadinessTrendDirection

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case scores
        case averageOverall = "average_overall"
        case averagePhysical = "average_physical"
        case averageFunctional = "average_functional"
        case averagePsychological = "average_psychological"
        case trendDirection = "trend_direction"
    }
}

/// Direction of readiness trend
enum RTSReadinessTrendDirection: String, Codable {
    case improving
    case stable
    case declining

    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .yellow
        case .declining: return .red
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSReadinessScore {
    static let greenSample = RTSReadinessScore(
        protocolId: UUID(),
        phaseId: UUID(),
        recordedBy: UUID(),
        physicalScore: 88,
        functionalScore: 85,
        psychologicalScore: 82,
        riskFactors: [
            RTSRiskFactor(
                category: "Psychological",
                name: "Mild apprehension with cutting",
                severity: .low,
                notes: "Improving with progressive exposure"
            )
        ],
        notes: "Patient progressing well. Ready for phase advancement consideration."
    )

    static let yellowSample = RTSReadinessScore(
        protocolId: UUID(),
        phaseId: UUID(),
        recordedBy: UUID(),
        physicalScore: 75,
        functionalScore: 70,
        psychologicalScore: 65,
        riskFactors: [
            RTSRiskFactor(
                category: "Strength",
                name: "Quad LSI below threshold",
                severity: .moderate,
                notes: "Currently at 78%, target is 85%"
            ),
            RTSRiskFactor(
                category: "Psychological",
                name: "Low confidence with sport-specific movements",
                severity: .moderate
            )
        ],
        notes: "Continue strengthening and confidence building exercises."
    )

    static let redSample = RTSReadinessScore(
        protocolId: UUID(),
        phaseId: UUID(),
        recordedBy: UUID(),
        physicalScore: 55,
        functionalScore: 50,
        psychologicalScore: 45,
        riskFactors: [
            RTSRiskFactor(
                category: "Pain",
                name: "Persistent anterior knee pain",
                severity: .high,
                notes: "Pain 5/10 with stairs and squatting"
            ),
            RTSRiskFactor(
                category: "Function",
                name: "Single leg hop LSI <70%",
                severity: .high
            ),
            RTSRiskFactor(
                category: "Psychological",
                name: "Fear of reinjury",
                severity: .moderate,
                notes: "ACL-RSI score 42%"
            )
        ],
        notes: "Not ready for progression. Address pain and continue rehabilitation."
    )
}

extension RTSRiskFactor {
    static let strengthSample = RTSRiskFactor(
        category: "Strength",
        name: "Hamstring weakness",
        severity: .moderate,
        notes: "LSI at 75%, target 85%"
    )

    static let psychologicalSample = RTSRiskFactor(
        category: "Psychological",
        name: "Fear of reinjury",
        severity: .high,
        notes: "ACL-RSI score below threshold at 55%"
    )
}
#endif
