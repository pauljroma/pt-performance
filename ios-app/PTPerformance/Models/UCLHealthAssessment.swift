//
//  UCLHealthAssessment.swift
//  PTPerformance
//
//  ACP-544: UCL Health Assessment Model
//  Weekly elbow stress questionnaire focused on UCL injury prevention
//

import Foundation
import SwiftUI

// MARK: - UCL Health Assessment Model

/// Represents a weekly UCL health assessment
/// Maps to the `ucl_health_assessments` table in Supabase
struct UCLHealthAssessment: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let assessmentDate: Date

    // Medial Elbow Pain Questions
    let medialElbowPain: Bool
    let medialPainSeverity: Int?  // 1-10 scale
    let painDuringThrowing: Bool
    let painAfterThrowing: Bool
    let painAtRest: Bool

    // Valgus Stress Indicators
    let valgusStressDiscomfort: Bool
    let elbowInstabilityFelt: Bool
    let decreasedVelocity: Bool
    let decreasedControlAccuracy: Bool

    // Neurological Symptoms
    let numbnessOrTingling: Bool
    let ringFingerNumbness: Bool
    let pinkyFingerNumbness: Bool

    // Throwing Workload (past 7 days)
    let totalPitchCount: Int?
    let highIntensityThrows: Int?  // Throws at >80% effort
    let throwingDays: Int?  // Days with throwing activity
    let longestSession: Int?  // Longest single session pitch count

    // Recovery & Fatigue
    let armFatigue: Int  // 1-10 scale
    let recoveryQuality: Int  // 1-5 scale (1=poor, 5=excellent)
    let adequateRestDays: Bool

    // Calculated Scores
    let symptomScore: Double  // 0-100, lower is better
    let workloadScore: Double  // 0-100, risk from workload
    let riskScore: Double  // 0-100, combined risk
    let riskLevel: UCLRiskLevel

    // Metadata
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case assessmentDate = "assessment_date"
        case medialElbowPain = "medial_elbow_pain"
        case medialPainSeverity = "medial_pain_severity"
        case painDuringThrowing = "pain_during_throwing"
        case painAfterThrowing = "pain_after_throwing"
        case painAtRest = "pain_at_rest"
        case valgusStressDiscomfort = "valgus_stress_discomfort"
        case elbowInstabilityFelt = "elbow_instability_felt"
        case decreasedVelocity = "decreased_velocity"
        case decreasedControlAccuracy = "decreased_control_accuracy"
        case numbnessOrTingling = "numbness_or_tingling"
        case ringFingerNumbness = "ring_finger_numbness"
        case pinkyFingerNumbness = "pinky_finger_numbness"
        case totalPitchCount = "total_pitch_count"
        case highIntensityThrows = "high_intensity_throws"
        case throwingDays = "throwing_days"
        case longestSession = "longest_session"
        case armFatigue = "arm_fatigue"
        case recoveryQuality = "recovery_quality"
        case adequateRestDays = "adequate_rest_days"
        case symptomScore = "symptom_score"
        case workloadScore = "workload_score"
        case riskScore = "risk_score"
        case riskLevel = "risk_level"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - UCL Risk Level

/// Risk level classification for UCL health
enum UCLRiskLevel: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"

    /// Display name
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .critical: return "Critical"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    /// Icon for UI display
    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .moderate: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    /// Recommendation for this risk level
    var recommendation: String {
        switch self {
        case .low:
            return "Continue current training with standard recovery protocols."
        case .moderate:
            return "Consider reducing throwing intensity. Monitor symptoms closely."
        case .high:
            return "Reduce throwing workload significantly. Consider rest day."
        case .critical:
            return "Stop throwing immediately. Consult sports medicine professional."
        }
    }

    /// Score range for this risk level
    static func level(for score: Double) -> UCLRiskLevel {
        switch score {
        case 0..<25: return .low
        case 25..<50: return .moderate
        case 50..<75: return .high
        default: return .critical
        }
    }
}

// MARK: - UCL Assessment Input

/// Input model for creating a new UCL assessment
struct UCLAssessmentInput: Encodable {
    let patientId: String
    let assessmentDate: String

    // Pain indicators
    var medialElbowPain: Bool = false
    var medialPainSeverity: Int?
    var painDuringThrowing: Bool = false
    var painAfterThrowing: Bool = false
    var painAtRest: Bool = false

    // Valgus stress indicators
    var valgusStressDiscomfort: Bool = false
    var elbowInstabilityFelt: Bool = false
    var decreasedVelocity: Bool = false
    var decreasedControlAccuracy: Bool = false

    // Neurological symptoms
    var numbnessOrTingling: Bool = false
    var ringFingerNumbness: Bool = false
    var pinkyFingerNumbness: Bool = false

    // Workload metrics
    var totalPitchCount: Int?
    var highIntensityThrows: Int?
    var throwingDays: Int?
    var longestSession: Int?

    // Recovery
    var armFatigue: Int = 5
    var recoveryQuality: Int = 3
    var adequateRestDays: Bool = true

    // Notes
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case assessmentDate = "assessment_date"
        case medialElbowPain = "medial_elbow_pain"
        case medialPainSeverity = "medial_pain_severity"
        case painDuringThrowing = "pain_during_throwing"
        case painAfterThrowing = "pain_after_throwing"
        case painAtRest = "pain_at_rest"
        case valgusStressDiscomfort = "valgus_stress_discomfort"
        case elbowInstabilityFelt = "elbow_instability_felt"
        case decreasedVelocity = "decreased_velocity"
        case decreasedControlAccuracy = "decreased_control_accuracy"
        case numbnessOrTingling = "numbness_or_tingling"
        case ringFingerNumbness = "ring_finger_numbness"
        case pinkyFingerNumbness = "pinky_finger_numbness"
        case totalPitchCount = "total_pitch_count"
        case highIntensityThrows = "high_intensity_throws"
        case throwingDays = "throwing_days"
        case longestSession = "longest_session"
        case armFatigue = "arm_fatigue"
        case recoveryQuality = "recovery_quality"
        case adequateRestDays = "adequate_rest_days"
        case notes
    }
}

// MARK: - UCL Risk Calculator

/// Research-backed UCL risk calculation
/// Based on literature on UCL injury risk factors
struct UCLRiskCalculator {

    /// Calculate symptom score (0-100, higher = more concerning)
    /// Based on presence and severity of symptoms
    static func calculateSymptomScore(
        medialElbowPain: Bool,
        medialPainSeverity: Int?,
        painDuringThrowing: Bool,
        painAfterThrowing: Bool,
        painAtRest: Bool,
        valgusStressDiscomfort: Bool,
        elbowInstabilityFelt: Bool,
        decreasedVelocity: Bool,
        decreasedControlAccuracy: Bool,
        numbnessOrTingling: Bool,
        ringFingerNumbness: Bool,
        pinkyFingerNumbness: Bool
    ) -> Double {
        var score: Double = 0

        // Medial elbow pain (most significant indicator)
        // Research shows medial pain is primary predictor of UCL issues
        if medialElbowPain {
            let severity = Double(medialPainSeverity ?? 5)
            score += severity * 3.0  // Max 30 points
        }

        // Pain patterns (15 points total)
        if painDuringThrowing { score += 8 }  // Most concerning
        if painAfterThrowing { score += 5 }
        if painAtRest { score += 2 }  // Indicates chronic issue

        // Valgus stress indicators (25 points total)
        // Direct assessment of UCL integrity
        if valgusStressDiscomfort { score += 15 }
        if elbowInstabilityFelt { score += 10 }  // Subjective instability is concerning

        // Performance indicators (15 points total)
        // Often first sign of developing UCL issues
        if decreasedVelocity { score += 8 }
        if decreasedControlAccuracy { score += 7 }

        // Neurological symptoms (15 points total)
        // Ulnar nerve involvement indicates UCL compromise
        if numbnessOrTingling { score += 5 }
        if ringFingerNumbness { score += 5 }
        if pinkyFingerNumbness { score += 5 }

        return min(100, score)
    }

    /// Calculate workload risk score (0-100, higher = more risk)
    /// Based on pitch count and intensity research
    static func calculateWorkloadScore(
        totalPitchCount: Int?,
        highIntensityThrows: Int?,
        throwingDays: Int?,
        longestSession: Int?,
        armFatigue: Int,
        recoveryQuality: Int,
        adequateRestDays: Bool
    ) -> Double {
        var score: Double = 0

        // Pitch count risk (30 points max)
        // Based on ASMI guidelines for weekly pitch counts
        if let pitches = totalPitchCount {
            switch pitches {
            case 0..<150: score += 0
            case 150..<250: score += 10
            case 250..<350: score += 20
            default: score += 30
            }
        }

        // High intensity throws (20 points max)
        // Throws >80% effort increase UCL stress significantly
        if let highIntensity = highIntensityThrows {
            switch highIntensity {
            case 0..<50: score += 0
            case 50..<100: score += 7
            case 100..<150: score += 14
            default: score += 20
            }
        }

        // Throwing days without rest (15 points max)
        // Consecutive throwing days increase cumulative stress
        if let days = throwingDays {
            switch days {
            case 0...3: score += 0
            case 4...5: score += 8
            case 6: score += 12
            default: score += 15
            }
        }

        // Longest single session (10 points max)
        // Long sessions without rest increase risk
        if let longest = longestSession {
            switch longest {
            case 0..<75: score += 0
            case 75..<100: score += 5
            case 100..<125: score += 8
            default: score += 10
            }
        }

        // Arm fatigue (15 points max)
        // Fatigue rating 1-10, converted to risk score
        let fatigueScore = (Double(armFatigue) / 10.0) * 15.0
        score += fatigueScore

        // Recovery quality penalty (10 points max)
        // Poor recovery increases injury risk
        let recoveryPenalty = (5.0 - Double(recoveryQuality)) / 4.0 * 10.0
        score += max(0, recoveryPenalty)

        // Rest day penalty
        if !adequateRestDays {
            score += 5
        }

        return min(100, score)
    }

    /// Calculate combined risk score
    /// Weights symptoms more heavily as they indicate existing damage
    static func calculateRiskScore(symptomScore: Double, workloadScore: Double) -> Double {
        // Symptoms weighted 60%, workload 40%
        // Research shows symptoms are more predictive of injury
        let weightedScore = (symptomScore * 0.6) + (workloadScore * 0.4)

        // Apply ceiling for any critical symptoms
        return min(100, weightedScore)
    }

    /// Determine risk level from combined score
    static func determineRiskLevel(riskScore: Double) -> UCLRiskLevel {
        return UCLRiskLevel.level(for: riskScore)
    }
}

// MARK: - UCL Trend Data

/// Represents trend data for UCL health over time
struct UCLTrendData {
    let assessments: [UCLHealthAssessment]
    let averageRiskScore: Double
    let trendDirection: TrendDirection
    let riskElevationDays: Int
    let lastAssessmentDate: Date?

    enum TrendDirection {
        case improving
        case stable
        case worsening

        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .worsening: return "Worsening"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .yellow
            case .worsening: return .red
            }
        }

        var icon: String {
            switch self {
            case .improving: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .worsening: return "arrow.up.right"
            }
        }
    }

    /// Calculate trend from recent assessments
    static func calculate(from assessments: [UCLHealthAssessment]) -> UCLTrendData {
        guard !assessments.isEmpty else {
            return UCLTrendData(
                assessments: [],
                averageRiskScore: 0,
                trendDirection: .stable,
                riskElevationDays: 0,
                lastAssessmentDate: nil
            )
        }

        let sorted = assessments.sorted { $0.assessmentDate > $1.assessmentDate }
        let average = sorted.map { $0.riskScore }.reduce(0, +) / Double(sorted.count)

        // Determine trend direction
        let trendDirection: TrendDirection
        if sorted.count >= 2 {
            let recentAvg = sorted.prefix(2).map { $0.riskScore }.reduce(0, +) / 2.0
            let olderAvg = sorted.suffix(from: min(2, sorted.count)).map { $0.riskScore }.reduce(0, +) / Double(max(1, sorted.count - 2))

            if recentAvg < olderAvg - 5 {
                trendDirection = .improving
            } else if recentAvg > olderAvg + 5 {
                trendDirection = .worsening
            } else {
                trendDirection = .stable
            }
        } else {
            trendDirection = .stable
        }

        // Count elevated risk days
        let elevatedDays = sorted.filter { $0.riskLevel == .high || $0.riskLevel == .critical }.count

        return UCLTrendData(
            assessments: sorted,
            averageRiskScore: average,
            trendDirection: trendDirection,
            riskElevationDays: elevatedDays,
            lastAssessmentDate: sorted.first?.assessmentDate
        )
    }
}

// MARK: - Educational Content

/// UCL injury prevention educational content
struct UCLEducationalContent {

    /// Key facts about UCL injuries
    static let keyFacts: [String] = [
        "The UCL is the primary stabilizer against valgus stress during throwing",
        "UCL injuries are most common in baseball pitchers aged 15-19",
        "Fatigue is a major contributor to UCL injuries - never throw while fatigued",
        "Proper mechanics can reduce UCL stress by up to 50%",
        "Tommy John surgery success rate is approximately 80-90%",
        "Recovery from UCL reconstruction takes 12-18 months",
        "Pitch count limits exist to protect developing elbows"
    ]

    /// Warning signs to watch for
    static let warningSigns: [String] = [
        "Pain on the inside of the elbow during or after throwing",
        "Popping or snapping sensation in the elbow",
        "Numbness or tingling in the ring and pinky fingers",
        "Decreased throwing velocity or accuracy",
        "Feeling of elbow instability or giving way",
        "Swelling on the medial side of the elbow",
        "Inability to fully extend the elbow"
    ]

    /// Prevention strategies
    static let preventionStrategies: [String] = [
        "Follow age-appropriate pitch count guidelines",
        "Take at least 2-3 rest days per week from throwing",
        "Maintain year-round arm conditioning program",
        "Focus on proper throwing mechanics",
        "Stop throwing at first sign of elbow pain",
        "Avoid throwing through fatigue",
        "Strengthen shoulder and core muscles",
        "Warm up properly before throwing activities",
        "Cool down and stretch after throwing"
    ]

    /// ASMI Pitch Count Guidelines by Age
    static let pitchCountGuidelines: [(age: String, maxPitches: Int, restDays: String)] = [
        ("9-10", 75, "1 day: 21-35 pitches, 2 days: 36-50, 3 days: 51-65, 4 days: 66+"),
        ("11-12", 85, "1 day: 21-35 pitches, 2 days: 36-50, 3 days: 51-65, 4 days: 66+"),
        ("13-14", 95, "1 day: 21-35 pitches, 2 days: 36-50, 3 days: 51-65, 4 days: 66+"),
        ("15-16", 95, "1 day: 31-45 pitches, 2 days: 46-60, 3 days: 61-75, 4 days: 76+"),
        ("17-18", 105, "1 day: 31-45 pitches, 2 days: 46-60, 3 days: 61-80, 4 days: 81+"),
        ("19+", 120, "No specific guidelines, follow team/professional protocols")
    ]
}

// MARK: - Sample Data

extension UCLHealthAssessment {

    /// Sample assessment for previews and testing
    static var sample: UCLHealthAssessment {
        UCLHealthAssessment(
            id: UUID(),
            patientId: UUID(),
            assessmentDate: Date(),
            medialElbowPain: false,
            medialPainSeverity: nil,
            painDuringThrowing: false,
            painAfterThrowing: false,
            painAtRest: false,
            valgusStressDiscomfort: false,
            elbowInstabilityFelt: false,
            decreasedVelocity: false,
            decreasedControlAccuracy: false,
            numbnessOrTingling: false,
            ringFingerNumbness: false,
            pinkyFingerNumbness: false,
            totalPitchCount: 180,
            highIntensityThrows: 60,
            throwingDays: 4,
            longestSession: 75,
            armFatigue: 4,
            recoveryQuality: 4,
            adequateRestDays: true,
            symptomScore: 0,
            workloadScore: 22,
            riskScore: 9,
            riskLevel: .low,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Sample elevated risk assessment
    static var sampleElevated: UCLHealthAssessment {
        UCLHealthAssessment(
            id: UUID(),
            patientId: UUID(),
            assessmentDate: Date(),
            medialElbowPain: true,
            medialPainSeverity: 5,
            painDuringThrowing: true,
            painAfterThrowing: true,
            painAtRest: false,
            valgusStressDiscomfort: true,
            elbowInstabilityFelt: false,
            decreasedVelocity: true,
            decreasedControlAccuracy: false,
            numbnessOrTingling: false,
            ringFingerNumbness: false,
            pinkyFingerNumbness: false,
            totalPitchCount: 320,
            highIntensityThrows: 140,
            throwingDays: 6,
            longestSession: 110,
            armFatigue: 7,
            recoveryQuality: 2,
            adequateRestDays: false,
            symptomScore: 54,
            workloadScore: 62,
            riskScore: 57,
            riskLevel: .high,
            notes: "Feeling tightness on inside of elbow after long toss",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
