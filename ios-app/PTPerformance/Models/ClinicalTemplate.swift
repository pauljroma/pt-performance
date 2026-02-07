import Foundation
import SwiftUI

// MARK: - Clinical Template Model
// Reusable templates for clinical documentation

/// Type of clinical template
enum TemplateType: String, Codable, CaseIterable, Identifiable {
    case soap = "soap"
    case assessment = "assessment"
    case discharge = "discharge"
    case intake = "intake"
    case progress = "progress"
    case dailyNote = "daily_note"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .soap: return "SOAP Note"
        case .assessment: return "Assessment"
        case .discharge: return "Discharge Summary"
        case .intake: return "Initial Evaluation"
        case .progress: return "Progress Note"
        case .dailyNote: return "Daily Note"
        }
    }

    /// Description of template type
    var description: String {
        switch self {
        case .soap:
            return "Standard SOAP format documentation for clinical visits"
        case .assessment:
            return "Comprehensive evaluation template"
        case .discharge:
            return "Summary of care and discharge instructions"
        case .intake:
            return "New patient evaluation documentation"
        case .progress:
            return "Re-evaluation and progress documentation"
        case .dailyNote:
            return "Brief daily treatment documentation"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .soap: return "doc.text"
        case .assessment: return "clipboard"
        case .discharge: return "checkmark.seal"
        case .intake: return "person.badge.plus"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .dailyNote: return "calendar.badge.clock"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .soap: return .blue
        case .assessment: return .purple
        case .discharge: return .green
        case .intake: return .orange
        case .progress: return .teal
        case .dailyNote: return .gray
        }
    }
}

/// Content structure for clinical templates
struct TemplateContent: Codable, Equatable {
    var subjectivePrompt: String?
    var objectivePrompts: [String]?
    var assessmentPrompts: [String]?
    var planPrompts: [String]?

    // Additional template sections
    var historyPrompts: [String]?
    var examinationPrompts: [String]?
    var goalPrompts: [String]?
    var precautionsPrompts: [String]?
    var homeExercisePrompts: [String]?

    enum CodingKeys: String, CodingKey {
        case subjectivePrompt = "subjective_prompt"
        case objectivePrompts = "objective_prompts"
        case assessmentPrompts = "assessment_prompts"
        case planPrompts = "plan_prompts"
        case historyPrompts = "history_prompts"
        case examinationPrompts = "examination_prompts"
        case goalPrompts = "goal_prompts"
        case precautionsPrompts = "precautions_prompts"
        case homeExercisePrompts = "home_exercise_prompts"
    }

    /// Check if template has any content
    var hasContent: Bool {
        subjectivePrompt != nil ||
        objectivePrompts?.isEmpty == false ||
        assessmentPrompts?.isEmpty == false ||
        planPrompts?.isEmpty == false ||
        historyPrompts?.isEmpty == false ||
        examinationPrompts?.isEmpty == false ||
        goalPrompts?.isEmpty == false ||
        precautionsPrompts?.isEmpty == false ||
        homeExercisePrompts?.isEmpty == false
    }

    /// Total number of prompts in template
    var totalPromptCount: Int {
        var count = 0
        if subjectivePrompt != nil { count += 1 }
        count += objectivePrompts?.count ?? 0
        count += assessmentPrompts?.count ?? 0
        count += planPrompts?.count ?? 0
        count += historyPrompts?.count ?? 0
        count += examinationPrompts?.count ?? 0
        count += goalPrompts?.count ?? 0
        count += precautionsPrompts?.count ?? 0
        count += homeExercisePrompts?.count ?? 0
        return count
    }
}

/// Clinical documentation template
struct ClinicalTemplate: Codable, Identifiable {
    let id: UUID
    let therapistId: UUID?

    var name: String
    var description: String?
    var templateType: TemplateType
    var bodyRegion: String?

    var templateContent: TemplateContent
    var defaultValues: [String: String]?

    var isSystemTemplate: Bool
    var isActive: Bool

    // Usage tracking
    var useCount: Int?
    var lastUsedAt: Date?

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case name
        case description
        case templateType = "template_type"
        case bodyRegion = "body_region"
        case templateContent = "template_content"
        case defaultValues = "default_values"
        case isSystemTemplate = "is_system_template"
        case isActive = "is_active"
        case useCount = "use_count"
        case lastUsedAt = "last_used_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Whether this is a user-created template
    var isUserTemplate: Bool {
        !isSystemTemplate && therapistId != nil
    }

    /// Display subtitle combining type and region
    var subtitle: String {
        if let region = bodyRegion {
            return "\(templateType.displayName) - \(region)"
        }
        return templateType.displayName
    }

    /// Formatted last used date
    var formattedLastUsed: String? {
        guard let date = lastUsedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Badge text for use count
    var usageText: String? {
        guard let count = useCount, count > 0 else { return nil }
        return "Used \(count) time\(count == 1 ? "" : "s")"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        therapistId: UUID? = nil,
        name: String,
        description: String? = nil,
        templateType: TemplateType,
        bodyRegion: String? = nil,
        templateContent: TemplateContent = TemplateContent(),
        defaultValues: [String: String]? = nil,
        isSystemTemplate: Bool = false,
        isActive: Bool = true,
        useCount: Int? = nil,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.therapistId = therapistId
        self.name = name
        self.description = description
        self.templateType = templateType
        self.bodyRegion = bodyRegion
        self.templateContent = templateContent
        self.defaultValues = defaultValues
        self.isSystemTemplate = isSystemTemplate
        self.isActive = isActive
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Clinical Body Region Options

/// Common body regions for clinical template categorization
enum ClinicalBodyRegion: String, CaseIterable, Identifiable {
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case wrist = "Wrist/Hand"
    case hip = "Hip"
    case knee = "Knee"
    case ankle = "Ankle/Foot"
    case cervical = "Cervical Spine"
    case thoracic = "Thoracic Spine"
    case lumbar = "Lumbar Spine"
    case general = "General"

    var id: String { rawValue }
}

// MARK: - Template Input Model

/// Input model for creating/updating templates
struct ClinicalTemplateInput: Codable {
    var therapistId: String?
    var name: String
    var description: String?
    var templateType: String
    var bodyRegion: String?
    var templateContent: TemplateContent
    var defaultValues: [String: String]?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case therapistId = "therapist_id"
        case name
        case description
        case templateType = "template_type"
        case bodyRegion = "body_region"
        case templateContent = "template_content"
        case defaultValues = "default_values"
        case isActive = "is_active"
    }

    /// Validate template input
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClinicalTemplateError.invalidName("Template name is required")
        }
        guard name.count <= 100 else {
            throw ClinicalTemplateError.invalidName("Template name must be 100 characters or less")
        }
    }
}

// MARK: - System Templates

/// Pre-built system templates for common documentation needs
struct SystemTemplates {

    static let shoulderSOAP = ClinicalTemplate(
        name: "Shoulder SOAP Note",
        description: "Standard SOAP documentation for shoulder conditions",
        templateType: .soap,
        bodyRegion: "Shoulder",
        templateContent: TemplateContent(
            subjectivePrompt: "Document patient's reported symptoms, pain levels, functional limitations, and response to treatment",
            objectivePrompts: [
                "Range of motion measurements (AROM/PROM)",
                "Strength testing (rotator cuff, scapular stabilizers)",
                "Special tests performed and results",
                "Palpation findings",
                "Posture and movement quality observations"
            ],
            assessmentPrompts: [
                "Clinical impression and diagnosis",
                "Progress toward goals",
                "Factors affecting progress"
            ],
            planPrompts: [
                "Treatment interventions performed",
                "Home exercise program modifications",
                "Goals and plan for next visit",
                "Frequency and duration of care"
            ]
        ),
        isSystemTemplate: true
    )

    static let kneeSOAP = ClinicalTemplate(
        name: "Knee SOAP Note",
        description: "Standard SOAP documentation for knee conditions",
        templateType: .soap,
        bodyRegion: "Knee",
        templateContent: TemplateContent(
            subjectivePrompt: "Document patient's reported symptoms, pain with specific activities, swelling, instability, and functional status",
            objectivePrompts: [
                "Range of motion measurements",
                "Strength testing (quadriceps, hamstrings)",
                "Ligament stability tests",
                "Effusion assessment",
                "Gait analysis findings"
            ],
            assessmentPrompts: [
                "Clinical impression",
                "Progress toward functional goals",
                "Barriers to recovery"
            ],
            planPrompts: [
                "Treatment interventions",
                "Progression criteria",
                "Return to activity planning"
            ]
        ),
        isSystemTemplate: true
    )

    static let spineIntake = ClinicalTemplate(
        name: "Spine Initial Evaluation",
        description: "Comprehensive intake template for spine conditions",
        templateType: .intake,
        bodyRegion: "Lumbar Spine",
        templateContent: TemplateContent(
            subjectivePrompt: "Chief complaint, mechanism of injury, pain location and characteristics, aggravating/easing factors",
            objectivePrompts: [
                "Posture assessment",
                "Range of motion (lumbar, hip)",
                "Neurological screening",
                "Special tests (SLR, slump, etc.)",
                "Palpation findings"
            ],
            assessmentPrompts: [
                "Clinical diagnosis",
                "Impairments identified",
                "Functional limitations",
                "Prognosis"
            ],
            planPrompts: [
                "Short and long-term goals",
                "Treatment plan",
                "Frequency and duration",
                "Patient education provided"
            ],
            historyPrompts: [
                "History of present illness",
                "Past medical history",
                "Surgical history",
                "Medications",
                "Imaging results"
            ],
            precautionsPrompts: [
                "Red flags screening",
                "Contraindications",
                "Activity restrictions"
            ]
        ),
        isSystemTemplate: true
    )

    static let dischargeTemplate = ClinicalTemplate(
        name: "Discharge Summary",
        description: "Comprehensive discharge documentation",
        templateType: .discharge,
        templateContent: TemplateContent(
            subjectivePrompt: "Patient's current status, satisfaction with outcomes, remaining concerns",
            objectivePrompts: [
                "Final outcome measures",
                "Functional status comparison (initial vs discharge)",
                "ROM and strength comparison"
            ],
            assessmentPrompts: [
                "Goals achieved",
                "Goals not achieved and reasons",
                "Overall progress summary"
            ],
            planPrompts: [
                "Home exercise program",
                "Activity recommendations",
                "Follow-up instructions",
                "Referrals if needed"
            ],
            homeExercisePrompts: [
                "Exercises to continue independently",
                "Frequency and duration recommendations",
                "Progression guidelines"
            ]
        ),
        isSystemTemplate: true
    )

    static let allTemplates: [ClinicalTemplate] = [
        shoulderSOAP,
        kneeSOAP,
        spineIntake,
        dischargeTemplate
    ]
}

// MARK: - Errors

enum ClinicalTemplateError: LocalizedError {
    case invalidName(String)
    case templateNotFound
    case saveFailed
    case fetchFailed
    case cannotDeleteSystemTemplate
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .invalidName(let message):
            return message
        case .templateNotFound:
            return "Template not found"
        case .saveFailed:
            return "Failed to save template"
        case .fetchFailed:
            return "Failed to fetch templates"
        case .cannotDeleteSystemTemplate:
            return "Cannot delete system templates"
        case .duplicateName:
            return "A template with this name already exists"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension ClinicalTemplate {
    static let sample = ClinicalTemplate(
        therapistId: UUID(),
        name: "My Custom Shoulder Template",
        description: "Custom template for rotator cuff patients",
        templateType: .soap,
        bodyRegion: "Shoulder",
        templateContent: TemplateContent(
            subjectivePrompt: "Document pain, function, and sleep quality",
            objectivePrompts: ["ROM", "Strength", "Special tests"],
            assessmentPrompts: ["Clinical impression"],
            planPrompts: ["Treatment plan", "HEP modifications"]
        ),
        useCount: 15,
        lastUsedAt: Date().addingTimeInterval(-86400)
    )

    static let systemSample = SystemTemplates.shoulderSOAP
}

extension TemplateContent {
    static let sample = TemplateContent(
        subjectivePrompt: "Document patient symptoms and concerns",
        objectivePrompts: ["ROM", "Strength", "Special tests"],
        assessmentPrompts: ["Clinical impression", "Progress"],
        planPrompts: ["Treatment plan", "Home program"]
    )
}
#endif
