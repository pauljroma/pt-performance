import Foundation
import SwiftUI

// MARK: - SOAP Note Model
// Structured clinical documentation for physical therapy visits

/// Status of a clinical note
enum NoteStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "draft"
    case complete = "complete"
    case signed = "signed"
    case addendum = "addendum"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .complete: return "Complete"
        case .signed: return "Signed"
        case .addendum: return "Addendum"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .draft: return .gray
        case .complete: return .orange
        case .signed: return .green
        case .addendum: return .blue
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .complete: return "doc.badge.checkmark"
        case .signed: return "signature"
        case .addendum: return "doc.badge.plus"
        }
    }

    /// Whether the note can be edited
    var isEditable: Bool {
        return self == .draft || self == .addendum
    }
}

/// Functional status trend for patient
enum FunctionalStatus: String, Codable, CaseIterable, Identifiable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .yellow
        case .declining: return .red
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

/// Vital signs measurement
struct Vitals: Codable, Equatable {
    var bloodPressure: String?      // e.g., "120/80"
    var heartRate: Int?             // beats per minute
    var temperature: Double?        // degrees Fahrenheit
    var respiratoryRate: Int?       // breaths per minute
    var oxygenSaturation: Int?      // percentage
    var weight: Double?             // pounds

    enum CodingKeys: String, CodingKey {
        case bloodPressure = "blood_pressure"
        case heartRate = "heart_rate"
        case temperature
        case respiratoryRate = "respiratory_rate"
        case oxygenSaturation = "oxygen_saturation"
        case weight
    }

    /// Check if any vitals are recorded
    var hasData: Bool {
        bloodPressure != nil || heartRate != nil || temperature != nil ||
        respiratoryRate != nil || oxygenSaturation != nil || weight != nil
    }

    /// Formatted vital signs summary
    var summary: String {
        var parts: [String] = []
        if let bp = bloodPressure { parts.append("BP: \(bp)") }
        if let hr = heartRate { parts.append("HR: \(hr)") }
        if let temp = temperature { parts.append("Temp: \(String(format: "%.1f", temp))\u{00B0}F") }
        if let rr = respiratoryRate { parts.append("RR: \(rr)") }
        if let o2 = oxygenSaturation { parts.append("O2: \(o2)%") }
        return parts.joined(separator: " | ")
    }
}

/// SOAP note documentation for a clinical visit
struct SOAPNote: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let sessionId: UUID?

    let noteDate: Date

    // SOAP components
    var subjective: String?         // Patient's reported symptoms, concerns, progress
    var objective: String?          // Measurable findings, observations, test results
    var assessment: String?         // Clinical impression, interpretation of findings
    var plan: String?               // Treatment plan, goals, next steps

    // Clinical measurements
    var vitals: Vitals?
    var painLevel: Int?             // 0-10 scale
    var functionalStatus: FunctionalStatus?

    // Billing information
    var timeSpentMinutes: Int?
    var cptCodes: [String]?

    // Status tracking
    var status: NoteStatus
    var signedAt: Date?
    var signedBy: String?

    // Related notes
    var parentNoteId: UUID?         // For addendums

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case sessionId = "session_id"
        case noteDate = "note_date"
        case subjective
        case objective
        case assessment
        case plan
        case vitals
        case painLevel = "pain_level"
        case functionalStatus = "functional_status"
        case timeSpentMinutes = "time_spent_minutes"
        case cptCodes = "cpt_codes"
        case status
        case signedAt = "signed_at"
        case signedBy = "signed_by"
        case parentNoteId = "parent_note_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Formatted note date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: noteDate)
    }

    /// Formatted time stamp
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: noteDate)
    }

    /// Whether the note is ready for signature
    var isReadyForSignature: Bool {
        guard status == .complete else { return false }
        return subjective != nil && objective != nil &&
               assessment != nil && plan != nil
    }

    /// Whether this is an addendum to another note
    var isAddendum: Bool {
        return parentNoteId != nil || status == .addendum
    }

    /// Formatted time spent
    var formattedTimeSpent: String? {
        guard let minutes = timeSpentMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes) min"
    }

    /// CPT codes as formatted string
    var formattedCptCodes: String? {
        guard let codes = cptCodes, !codes.isEmpty else { return nil }
        return codes.joined(separator: ", ")
    }

    /// Preview text for list display
    var previewText: String {
        if let subjective = subjective, !subjective.isEmpty {
            let preview = subjective.prefix(100)
            return preview.count < subjective.count ? "\(preview)..." : String(preview)
        }
        return "No content"
    }

    /// Completeness percentage for draft notes
    var completenessPercentage: Double {
        var filled = 0
        let total = 4

        if subjective != nil && !subjective!.isEmpty { filled += 1 }
        if objective != nil && !objective!.isEmpty { filled += 1 }
        if assessment != nil && !assessment!.isEmpty { filled += 1 }
        if plan != nil && !plan!.isEmpty { filled += 1 }

        return Double(filled) / Double(total) * 100
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID,
        sessionId: UUID? = nil,
        noteDate: Date = Date(),
        subjective: String? = nil,
        objective: String? = nil,
        assessment: String? = nil,
        plan: String? = nil,
        vitals: Vitals? = nil,
        painLevel: Int? = nil,
        functionalStatus: FunctionalStatus? = nil,
        timeSpentMinutes: Int? = nil,
        cptCodes: [String]? = nil,
        status: NoteStatus = .draft,
        signedAt: Date? = nil,
        signedBy: String? = nil,
        parentNoteId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.sessionId = sessionId
        self.noteDate = noteDate
        self.subjective = subjective
        self.objective = objective
        self.assessment = assessment
        self.plan = plan
        self.vitals = vitals
        self.painLevel = painLevel
        self.functionalStatus = functionalStatus
        self.timeSpentMinutes = timeSpentMinutes
        self.cptCodes = cptCodes
        self.status = status
        self.signedAt = signedAt
        self.signedBy = signedBy
        self.parentNoteId = parentNoteId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Input Model

/// Input model for creating/updating SOAP notes
struct SOAPNoteInput: Codable {
    var patientId: String?
    var therapistId: String?
    var sessionId: String?
    var noteDate: String?

    var subjective: String?
    var objective: String?
    var assessment: String?
    var plan: String?

    var vitals: Vitals?
    var painLevel: Int?
    var functionalStatus: String?

    var timeSpentMinutes: Int?
    var cptCodes: [String]?

    var status: String?
    var parentNoteId: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case sessionId = "session_id"
        case noteDate = "note_date"
        case subjective
        case objective
        case assessment
        case plan
        case vitals
        case painLevel = "pain_level"
        case functionalStatus = "functional_status"
        case timeSpentMinutes = "time_spent_minutes"
        case cptCodes = "cpt_codes"
        case status
        case parentNoteId = "parent_note_id"
    }

    /// Validate pain level is within valid range
    func validate() throws {
        if let pain = painLevel, !(0...10).contains(pain) {
            throw SOAPNoteError.invalidPainLevel("Pain level must be 0-10")
        }
        if let minutes = timeSpentMinutes, minutes < 0 {
            throw SOAPNoteError.invalidTimeSpent("Time spent cannot be negative")
        }
    }
}

// MARK: - Common CPT Codes

/// Common CPT codes for physical therapy billing
struct CommonCPTCodes {
    static let evaluations = [
        CPTCode(code: "97161", description: "PT Evaluation - Low Complexity"),
        CPTCode(code: "97162", description: "PT Evaluation - Moderate Complexity"),
        CPTCode(code: "97163", description: "PT Evaluation - High Complexity"),
        CPTCode(code: "97164", description: "PT Re-evaluation")
    ]

    static let therapeuticExercise = [
        CPTCode(code: "97110", description: "Therapeutic Exercise"),
        CPTCode(code: "97112", description: "Neuromuscular Re-education"),
        CPTCode(code: "97530", description: "Therapeutic Activities"),
        CPTCode(code: "97535", description: "Self-Care/Home Management Training")
    ]

    static let manualTherapy = [
        CPTCode(code: "97140", description: "Manual Therapy"),
        CPTCode(code: "97150", description: "Group Therapeutic Procedures")
    ]

    static let modalities = [
        CPTCode(code: "97010", description: "Hot/Cold Pack"),
        CPTCode(code: "97012", description: "Mechanical Traction"),
        CPTCode(code: "97014", description: "Electrical Stimulation (Unattended)"),
        CPTCode(code: "97032", description: "Electrical Stimulation (Attended)"),
        CPTCode(code: "97035", description: "Ultrasound")
    ]

    struct CPTCode: Identifiable {
        let id = UUID()
        let code: String
        let description: String
    }
}

// MARK: - Errors

enum SOAPNoteError: LocalizedError {
    case invalidPainLevel(String)
    case invalidTimeSpent(String)
    case noteNotFound
    case saveFailed
    case fetchFailed
    case cannotEditSigned
    case incompleteNote

    var errorDescription: String? {
        switch self {
        case .invalidPainLevel(let message):
            return message
        case .invalidTimeSpent(let message):
            return message
        case .noteNotFound:
            return "SOAP note not found"
        case .saveFailed:
            return "Failed to save SOAP note"
        case .fetchFailed:
            return "Failed to fetch SOAP note"
        case .cannotEditSigned:
            return "Cannot edit a signed note"
        case .incompleteNote:
            return "Please complete all SOAP sections before signing"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension SOAPNote {
    static let sample = SOAPNote(
        patientId: UUID(),
        therapistId: UUID(),
        subjective: "Patient reports decreased shoulder pain since last visit. Pain is now 4/10 with overhead activities, down from 6/10. Sleeping better at night with less discomfort.",
        objective: "AROM: Shoulder flexion 160 degrees (improved from 140). Strength: 4/5 rotator cuff. Special tests: Hawkins-Kennedy negative. Palpation: decreased tenderness over supraspinatus.",
        assessment: "Patient demonstrating good progress with decreased pain and improved ROM. Strength improving but still below functional level for return to sport.",
        plan: "Continue therapeutic exercise program with progressive strengthening. Begin sport-specific exercises next visit. Continue 2x/week for 4 more weeks.",
        vitals: Vitals(bloodPressure: "118/76", heartRate: 72),
        painLevel: 4,
        functionalStatus: .improving,
        timeSpentMinutes: 45,
        cptCodes: ["97110", "97140", "97530"],
        status: .complete
    )

    static let draftSample = SOAPNote(
        patientId: UUID(),
        therapistId: UUID(),
        subjective: "Patient reports ongoing knee pain with stairs.",
        status: .draft
    )
}

extension Vitals {
    static let sample = Vitals(
        bloodPressure: "120/80",
        heartRate: 72,
        temperature: 98.6,
        respiratoryRate: 14,
        oxygenSaturation: 98
    )
}
#endif
