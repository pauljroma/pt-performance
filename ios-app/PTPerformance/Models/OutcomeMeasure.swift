import Foundation
import SwiftUI

// MARK: - Outcome Measure Model
// Standardized patient-reported outcome measures for tracking progress

/// Types of standardized outcome measures
enum OutcomeMeasureType: String, Codable, CaseIterable, Identifiable {
    case LEFS = "LEFS"          // Lower Extremity Functional Scale
    case DASH = "DASH"          // Disabilities of Arm, Shoulder and Hand
    case QuickDASH = "QuickDASH"
    case PSFS = "PSFS"          // Patient-Specific Functional Scale
    case OMAK = "OMAK"          // Outcome Measure for ACL Knowledge
    case VAS = "VAS"            // Visual Analog Scale
    case NDI = "NDI"            // Neck Disability Index
    case ODI = "ODI"            // Oswestry Disability Index
    case NPRS = "NPRS"          // Numeric Pain Rating Scale
    case KOOS = "KOOS"          // Knee Injury and Osteoarthritis Outcome Score
    case WOMAC = "WOMAC"        // Western Ontario and McMaster Universities Osteoarthritis Index
    case SF36 = "SF36"          // Short Form 36 Health Survey

    var id: String { rawValue }

    /// Full name of the outcome measure
    var displayName: String {
        switch self {
        case .LEFS: return "Lower Extremity Functional Scale"
        case .DASH: return "Disabilities of Arm, Shoulder and Hand"
        case .QuickDASH: return "Quick DASH"
        case .PSFS: return "Patient-Specific Functional Scale"
        case .OMAK: return "Outcome Measure for ACL Knowledge"
        case .VAS: return "Visual Analog Scale"
        case .NDI: return "Neck Disability Index"
        case .ODI: return "Oswestry Disability Index"
        case .NPRS: return "Numeric Pain Rating Scale"
        case .KOOS: return "Knee Injury and Osteoarthritis Outcome Score"
        case .WOMAC: return "WOMAC Osteoarthritis Index"
        case .SF36: return "SF-36 Health Survey"
        }
    }

    /// Number of questions in the measure
    var questionCount: Int {
        switch self {
        case .LEFS: return 20
        case .DASH: return 30
        case .QuickDASH: return 11
        case .PSFS: return 3
        case .OMAK: return 12
        case .VAS: return 1
        case .NDI: return 10
        case .ODI: return 10
        case .NPRS: return 1
        case .KOOS: return 42
        case .WOMAC: return 24
        case .SF36: return 36
        }
    }

    /// Maximum possible raw score
    var maxScore: Int {
        switch self {
        case .LEFS: return 80
        case .DASH: return 100
        case .QuickDASH: return 100
        case .PSFS: return 10
        case .OMAK: return 100
        case .VAS: return 100
        case .NDI: return 50
        case .ODI: return 50
        case .NPRS: return 10
        case .KOOS: return 100
        case .WOMAC: return 96
        case .SF36: return 100
        }
    }

    /// Minimal clinically important difference threshold
    var mcidThreshold: Double {
        switch self {
        case .LEFS: return 9.0
        case .DASH: return 10.8
        case .QuickDASH: return 8.0
        case .PSFS: return 2.0
        case .OMAK: return 10.0
        case .VAS: return 20.0
        case .NDI: return 7.5
        case .ODI: return 10.0
        case .NPRS: return 2.0
        case .KOOS: return 8.0
        case .WOMAC: return 9.0
        case .SF36: return 5.0
        }
    }

    /// Whether higher scores indicate better function
    var higherIsBetter: Bool {
        switch self {
        case .LEFS, .PSFS, .KOOS, .SF36:
            return true
        case .DASH, .QuickDASH, .OMAK, .VAS, .NDI, .ODI, .NPRS, .WOMAC:
            return false
        }
    }

    /// Body region this measure applies to
    var bodyRegion: String {
        switch self {
        case .LEFS, .KOOS, .WOMAC:
            return "Lower Extremity"
        case .DASH, .QuickDASH:
            return "Upper Extremity"
        case .NDI:
            return "Cervical Spine"
        case .ODI:
            return "Lumbar Spine"
        case .PSFS, .VAS, .NPRS, .SF36, .OMAK:
            return "General"
        }
    }

    /// Description of what the measure assesses
    var description: String {
        switch self {
        case .LEFS:
            return "Measures lower extremity functional status in patients with musculoskeletal conditions"
        case .DASH:
            return "Measures disability and symptoms in upper extremity musculoskeletal conditions"
        case .QuickDASH:
            return "Shortened version of DASH for quick assessment of upper extremity disability"
        case .PSFS:
            return "Patient identifies and rates difficulty with specific functional activities"
        case .OMAK:
            return "Measures patient knowledge about ACL injury and rehabilitation"
        case .VAS:
            return "Simple visual scale for measuring pain intensity"
        case .NDI:
            return "Measures neck pain and associated disability"
        case .ODI:
            return "Measures low back pain and associated disability"
        case .NPRS:
            return "Numeric scale for rating pain intensity from 0-10"
        case .KOOS:
            return "Measures knee-related quality of life in patients with knee injuries"
        case .WOMAC:
            return "Measures osteoarthritis-related pain, stiffness, and function"
        case .SF36:
            return "Generic health status measure covering physical and mental health"
        }
    }

    /// Color for UI display
    var color: Color {
        switch bodyRegion {
        case "Lower Extremity": return .blue
        case "Upper Extremity": return .orange
        case "Cervical Spine": return .purple
        case "Lumbar Spine": return .green
        default: return .gray
        }
    }
}

/// Outcome measure record with scoring and interpretation
struct OutcomeMeasure: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let clinicalAssessmentId: UUID?

    let measureType: OutcomeMeasureType
    let assessmentDate: Date

    // Response data (question ID to answer value)
    let responses: [String: Int]
    var rawScore: Double?
    var normalizedScore: Double?
    var interpretation: String?

    // Progress tracking
    var previousScore: Double?
    var changeFromPrevious: Double?
    var meetsMcid: Bool?

    var notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case clinicalAssessmentId = "clinical_assessment_id"
        case measureType = "measure_type"
        case assessmentDate = "assessment_date"
        case responses
        case rawScore = "raw_score"
        case normalizedScore = "normalized_score"
        case interpretation
        case previousScore = "previous_score"
        case changeFromPrevious = "change_from_previous"
        case meetsMcid = "meets_mcid"
        case notes
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Formatted assessment date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: assessmentDate)
    }

    /// Display score with appropriate formatting
    var formattedScore: String {
        guard let score = normalizedScore ?? rawScore else { return "N/A" }
        return String(format: "%.1f", score)
    }

    /// Whether the score indicates clinically meaningful improvement
    var showsImprovement: Bool {
        guard let change = changeFromPrevious else { return false }
        let threshold = measureType.mcidThreshold

        if measureType.higherIsBetter {
            return change >= threshold
        } else {
            return change <= -threshold
        }
    }

    /// Whether the score indicates clinically meaningful decline
    var showsDecline: Bool {
        guard let change = changeFromPrevious else { return false }
        let threshold = measureType.mcidThreshold

        if measureType.higherIsBetter {
            return change <= -threshold
        } else {
            return change >= threshold
        }
    }

    /// Progress status based on change
    var progressStatus: ProgressStatus {
        if showsImprovement { return .improving }
        if showsDecline { return .declining }
        return .stable
    }

    /// Status color for UI
    var statusColor: Color {
        progressStatus.color
    }

    /// Severity interpretation based on score
    var severityLevel: SeverityLevel {
        guard let score = normalizedScore ?? rawScore else { return .unknown }
        let maxScore = Double(measureType.maxScore)
        let percentage = measureType.higherIsBetter ?
            (score / maxScore) * 100 :
            ((maxScore - score) / maxScore) * 100

        switch percentage {
        case 80...100: return .minimal
        case 60..<80: return .mild
        case 40..<60: return .moderate
        case 20..<40: return .severe
        default: return .complete
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID,
        clinicalAssessmentId: UUID? = nil,
        measureType: OutcomeMeasureType,
        assessmentDate: Date = Date(),
        responses: [String: Int],
        rawScore: Double? = nil,
        normalizedScore: Double? = nil,
        interpretation: String? = nil,
        previousScore: Double? = nil,
        changeFromPrevious: Double? = nil,
        meetsMcid: Bool? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.clinicalAssessmentId = clinicalAssessmentId
        self.measureType = measureType
        self.assessmentDate = assessmentDate
        self.responses = responses
        self.rawScore = rawScore
        self.normalizedScore = normalizedScore
        self.interpretation = interpretation
        self.previousScore = previousScore
        self.changeFromPrevious = changeFromPrevious
        self.meetsMcid = meetsMcid
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Progress Status

enum ProgressStatus: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"

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

    var iconName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Severity Level

enum SeverityLevel: String, Codable {
    case minimal = "minimal"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    case complete = "complete"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .minimal: return "Minimal Disability"
        case .mild: return "Mild Disability"
        case .moderate: return "Moderate Disability"
        case .severe: return "Severe Disability"
        case .complete: return "Complete Disability"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .minimal: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .complete: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Outcome Measure Trend

/// Trend data for outcome measures over time
struct OutcomeMeasureTrend: Codable {
    let patientId: UUID
    let measureType: OutcomeMeasureType
    let measurements: [OutcomeMeasureSummary]
    let overallChange: Double?
    let trendDirection: ProgressStatus
    let achievedMcid: Bool

    struct OutcomeMeasureSummary: Codable, Identifiable {
        let id: UUID
        let date: Date
        let score: Double
        let changeFromPrevious: Double?

        enum CodingKeys: String, CodingKey {
            case id
            case date
            case score
            case changeFromPrevious = "change_from_previous"
        }
    }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case measureType = "measure_type"
        case measurements
        case overallChange = "overall_change"
        case trendDirection = "trend_direction"
        case achievedMcid = "achieved_mcid"
    }
}

// MARK: - Input Model

/// Input model for submitting outcome measure responses
struct OutcomeMeasureInput: Codable {
    var patientId: String?
    var therapistId: String?
    var clinicalAssessmentId: String?
    var measureType: String
    var assessmentDate: String?
    var responses: [String: Int]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case clinicalAssessmentId = "clinical_assessment_id"
        case measureType = "measure_type"
        case assessmentDate = "assessment_date"
        case responses
        case notes
    }

    /// Validate that all required questions are answered
    func validate(for measureType: OutcomeMeasureType) throws {
        let requiredCount = measureType.questionCount
        if responses.count < requiredCount {
            throw OutcomeMeasureError.incompleteResponses(
                "Please answer all \(requiredCount) questions"
            )
        }
    }
}

// MARK: - Errors

enum OutcomeMeasureError: LocalizedError {
    case incompleteResponses(String)
    case measureNotFound
    case saveFailed
    case fetchFailed
    case invalidMeasureType

    var errorDescription: String? {
        switch self {
        case .incompleteResponses(let message):
            return message
        case .measureNotFound:
            return "Outcome measure not found"
        case .saveFailed:
            return "Failed to save outcome measure"
        case .fetchFailed:
            return "Failed to fetch outcome measure"
        case .invalidMeasureType:
            return "Invalid outcome measure type"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension OutcomeMeasure {
    static let sample = OutcomeMeasure(
        patientId: UUID(),
        therapistId: UUID(),
        measureType: .LEFS,
        responses: [
            "q1": 3, "q2": 4, "q3": 3, "q4": 4, "q5": 3,
            "q6": 4, "q7": 3, "q8": 4, "q9": 3, "q10": 4,
            "q11": 3, "q12": 4, "q13": 3, "q14": 4, "q15": 3,
            "q16": 4, "q17": 3, "q18": 4, "q19": 3, "q20": 4
        ],
        rawScore: 68,
        normalizedScore: 85,
        interpretation: "Moderate functional limitation",
        previousScore: 54,
        changeFromPrevious: 14,
        meetsMcid: true
    )

    static let dashSample = OutcomeMeasure(
        patientId: UUID(),
        therapistId: UUID(),
        measureType: .DASH,
        responses: [:],
        rawScore: 35,
        normalizedScore: 35,
        interpretation: "Mild to moderate disability"
    )
}
#endif
