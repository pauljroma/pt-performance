import Foundation

/// Lab result from blood work or other medical tests
struct LabResult: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let testDate: Date
    let testType: LabTestType
    let results: [LabMarker]
    let pdfUrl: String?
    let aiAnalysis: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case testDate = "test_date"
        case testType = "test_type"
        case results
        case pdfUrl = "pdf_url"
        case aiAnalysis = "ai_analysis"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum LabTestType: String, Codable, CaseIterable {
    case bloodPanel = "blood_panel"
    case metabolicPanel = "metabolic_panel"
    case hormonePanel = "hormone_panel"
    case lipidPanel = "lipid_panel"
    case thyroid = "thyroid"
    case vitaminD = "vitamin_d"
    case iron = "iron"
    case cbc = "cbc"
    case other = "other"

    var displayName: String {
        switch self {
        case .bloodPanel: return "Blood Panel"
        case .metabolicPanel: return "Metabolic Panel"
        case .hormonePanel: return "Hormone Panel"
        case .lipidPanel: return "Lipid Panel"
        case .thyroid: return "Thyroid"
        case .vitaminD: return "Vitamin D"
        case .iron: return "Iron Studies"
        case .cbc: return "Complete Blood Count"
        case .other: return "Other"
        }
    }
}

struct LabMarker: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let value: Double
    let unit: String
    let referenceMin: Double?
    let referenceMax: Double?
    let status: MarkerStatus

    enum CodingKeys: String, CodingKey {
        case id, name, value, unit
        case referenceMin = "reference_min"
        case referenceMax = "reference_max"
        case status
    }
}

enum MarkerStatus: String, Codable {
    case normal
    case low
    case high
    case critical

    var color: String {
        switch self {
        case .normal: return "green"
        case .low: return "orange"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}
