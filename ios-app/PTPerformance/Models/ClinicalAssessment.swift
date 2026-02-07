import Foundation
import SwiftUI

// MARK: - Clinical Assessment Model
// Comprehensive clinical evaluation for physical therapy patients

/// Assessment type for categorizing evaluations
enum AssessmentType: String, Codable, CaseIterable, Identifiable {
    case intake = "intake"
    case progress = "progress"
    case discharge = "discharge"
    case follow_up = "follow_up"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .intake: return "Initial Evaluation"
        case .progress: return "Progress Note"
        case .discharge: return "Discharge Summary"
        case .follow_up: return "Follow-Up"
        }
    }

    /// Description of assessment type
    var description: String {
        switch self {
        case .intake:
            return "Comprehensive initial evaluation including history, examination, and treatment plan"
        case .progress:
            return "Periodic re-evaluation to assess treatment effectiveness and modify plan"
        case .discharge:
            return "Final assessment summarizing outcomes and providing home program"
        case .follow_up:
            return "Brief check-in to monitor ongoing status"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .intake: return "doc.text.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .discharge: return "checkmark.seal.fill"
        case .follow_up: return "arrow.clockwise"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .intake: return .blue
        case .progress: return .orange
        case .discharge: return .green
        case .follow_up: return .purple
        }
    }
}

/// Status of the clinical assessment
enum AssessmentStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "draft"
    case complete = "complete"
    case signed = "signed"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .complete: return "Complete"
        case .signed: return "Signed"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .draft: return .gray
        case .complete: return .orange
        case .signed: return .green
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .complete: return "doc.badge.checkmark"
        case .signed: return "signature"
        }
    }

    /// Whether the assessment can be edited
    var isEditable: Bool {
        return self != .signed
    }
}

/// Comprehensive clinical assessment model
struct ClinicalAssessment: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let assessmentType: AssessmentType
    let assessmentDate: Date

    // Physical examination measurements
    var romMeasurements: [ROMeasurement]?
    var functionalTests: [FunctionalTest]?

    // Pain assessment (0-10 scale)
    var painAtRest: Int?
    var painWithActivity: Int?
    var painWorst: Int?
    var painLocations: [String]?

    // Subjective information
    var chiefComplaint: String?
    var historyOfPresentIllness: String?
    var pastMedicalHistory: String?
    var functionalGoals: [String]?

    // Clinical findings
    var objectiveFindings: String?
    var assessmentSummary: String?
    var treatmentPlan: String?

    // Status tracking
    var status: AssessmentStatus
    var signedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case assessmentType = "assessment_type"
        case assessmentDate = "assessment_date"
        case romMeasurements = "rom_measurements"
        case functionalTests = "functional_tests"
        case painAtRest = "pain_at_rest"
        case painWithActivity = "pain_with_activity"
        case painWorst = "pain_worst"
        case painLocations = "pain_locations"
        case chiefComplaint = "chief_complaint"
        case historyOfPresentIllness = "history_of_present_illness"
        case pastMedicalHistory = "past_medical_history"
        case functionalGoals = "functional_goals"
        case objectiveFindings = "objective_findings"
        case assessmentSummary = "assessment_summary"
        case treatmentPlan = "treatment_plan"
        case status
        case signedAt = "signed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Average pain score across all pain measurements
    var averagePainScore: Double? {
        let scores = [painAtRest, painWithActivity, painWorst].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    /// Whether pain levels indicate high concern
    var isPainConcerning: Bool {
        if let worst = painWorst, worst >= 7 { return true }
        if let activity = painWithActivity, activity >= 6 { return true }
        return false
    }

    /// Count of ROM limitations
    var romLimitationsCount: Int {
        romMeasurements?.filter { $0.isLimited }.count ?? 0
    }

    /// Whether the assessment is ready for signature
    var isReadyForSignature: Bool {
        guard status == .complete else { return false }
        return assessmentSummary != nil && treatmentPlan != nil
    }

    /// Formatted assessment date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: assessmentDate)
    }

    /// Display title combining type and date
    var displayTitle: String {
        "\(assessmentType.displayName) - \(formattedDate)"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID,
        assessmentType: AssessmentType,
        assessmentDate: Date = Date(),
        romMeasurements: [ROMeasurement]? = nil,
        functionalTests: [FunctionalTest]? = nil,
        painAtRest: Int? = nil,
        painWithActivity: Int? = nil,
        painWorst: Int? = nil,
        painLocations: [String]? = nil,
        chiefComplaint: String? = nil,
        historyOfPresentIllness: String? = nil,
        pastMedicalHistory: String? = nil,
        functionalGoals: [String]? = nil,
        objectiveFindings: String? = nil,
        assessmentSummary: String? = nil,
        treatmentPlan: String? = nil,
        status: AssessmentStatus = .draft,
        signedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.assessmentType = assessmentType
        self.assessmentDate = assessmentDate
        self.romMeasurements = romMeasurements
        self.functionalTests = functionalTests
        self.painAtRest = painAtRest
        self.painWithActivity = painWithActivity
        self.painWorst = painWorst
        self.painLocations = painLocations
        self.chiefComplaint = chiefComplaint
        self.historyOfPresentIllness = historyOfPresentIllness
        self.pastMedicalHistory = pastMedicalHistory
        self.functionalGoals = functionalGoals
        self.objectiveFindings = objectiveFindings
        self.assessmentSummary = assessmentSummary
        self.treatmentPlan = treatmentPlan
        self.status = status
        self.signedAt = signedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Functional Test

/// Functional test result for clinical assessment
struct FunctionalTest: Codable, Identifiable {
    var id: UUID
    var testName: String
    var result: String
    var score: Double?
    var normalValue: String?
    var interpretation: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case testName = "test_name"
        case result
        case score
        case normalValue = "normal_value"
        case interpretation
        case notes
    }

    init(
        id: UUID = UUID(),
        testName: String,
        result: String,
        score: Double? = nil,
        normalValue: String? = nil,
        interpretation: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.testName = testName
        self.result = result
        self.score = score
        self.normalValue = normalValue
        self.interpretation = interpretation
        self.notes = notes
    }

    /// Whether the result is abnormal based on interpretation
    var isAbnormal: Bool {
        guard let interpretation = interpretation?.lowercased() else { return false }
        return interpretation.contains("abnormal") ||
               interpretation.contains("limited") ||
               interpretation.contains("positive")
    }
}

// MARK: - Input Model

/// Input model for creating/updating clinical assessments
struct ClinicalAssessmentInput: Codable {
    var patientId: String?
    var therapistId: String?
    var assessmentType: String
    var assessmentDate: String?

    var romMeasurements: [ROMeasurement]?
    var functionalTests: [FunctionalTest]?

    var painAtRest: Int?
    var painWithActivity: Int?
    var painWorst: Int?
    var painLocations: [String]?

    var chiefComplaint: String?
    var historyOfPresentIllness: String?
    var pastMedicalHistory: String?
    var functionalGoals: [String]?

    var objectiveFindings: String?
    var assessmentSummary: String?
    var treatmentPlan: String?

    var status: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case assessmentType = "assessment_type"
        case assessmentDate = "assessment_date"
        case romMeasurements = "rom_measurements"
        case functionalTests = "functional_tests"
        case painAtRest = "pain_at_rest"
        case painWithActivity = "pain_with_activity"
        case painWorst = "pain_worst"
        case painLocations = "pain_locations"
        case chiefComplaint = "chief_complaint"
        case historyOfPresentIllness = "history_of_present_illness"
        case pastMedicalHistory = "past_medical_history"
        case functionalGoals = "functional_goals"
        case objectiveFindings = "objective_findings"
        case assessmentSummary = "assessment_summary"
        case treatmentPlan = "treatment_plan"
        case status
    }

    /// Validate pain scores are within valid range
    func validate() throws {
        if let pain = painAtRest, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Pain at rest must be 0-10")
        }
        if let pain = painWithActivity, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Pain with activity must be 0-10")
        }
        if let pain = painWorst, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Worst pain must be 0-10")
        }
    }
}

// MARK: - Errors

enum ClinicalAssessmentError: LocalizedError {
    case invalidPainScore(String)
    case assessmentNotFound
    case saveFailed
    case fetchFailed
    case cannotEditSigned
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .invalidPainScore(let message):
            return message
        case .assessmentNotFound:
            return "Clinical assessment not found"
        case .saveFailed:
            return "Failed to save clinical assessment"
        case .fetchFailed:
            return "Failed to fetch clinical assessment"
        case .cannotEditSigned:
            return "Cannot edit a signed assessment"
        case .missingRequiredFields:
            return "Missing required fields for assessment"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension ClinicalAssessment {
    static let sample = ClinicalAssessment(
        patientId: UUID(),
        therapistId: UUID(),
        assessmentType: .intake,
        painAtRest: 2,
        painWithActivity: 5,
        painWorst: 7,
        painLocations: ["Right shoulder", "Upper back"],
        chiefComplaint: "Right shoulder pain with overhead activities",
        historyOfPresentIllness: "Patient reports gradual onset of right shoulder pain over the past 3 weeks, worse with reaching overhead.",
        functionalGoals: ["Return to overhead sports", "Sleep without pain"],
        objectiveFindings: "Decreased ROM in shoulder flexion and abduction. Positive impingement signs.",
        assessmentSummary: "Right shoulder impingement with associated rotator cuff weakness",
        treatmentPlan: "Manual therapy, therapeutic exercise, patient education. 2x/week for 6 weeks.",
        status: .complete
    )

    static let draftSample = ClinicalAssessment(
        patientId: UUID(),
        therapistId: UUID(),
        assessmentType: .progress,
        status: .draft
    )
}

extension FunctionalTest {
    static let sample = FunctionalTest(
        testName: "Hawkins-Kennedy Test",
        result: "Positive",
        interpretation: "Indicates possible subacromial impingement"
    )
}
#endif
