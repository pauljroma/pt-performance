import Foundation

// ============================================================================
// Parsed Lab Result Models
// Used for PDF parsing and manual entry before saving to database
// ============================================================================

/// Result from parsing a lab PDF
struct ParsedLabResult: Codable, Equatable {
    let provider: LabProvider
    let testDate: Date?
    let patientName: String?
    let orderingPhysician: String?
    var biomarkers: [ParsedBiomarker]
    let confidence: ParsingConfidence
    let parsingNotes: [String]?

    enum CodingKeys: String, CodingKey {
        case provider
        case testDate = "test_date"
        case patientName = "patient_name"
        case orderingPhysician = "ordering_physician"
        case biomarkers
        case confidence
        case parsingNotes = "parsing_notes"
    }

    init(
        provider: LabProvider,
        testDate: Date?,
        patientName: String? = nil,
        orderingPhysician: String? = nil,
        biomarkers: [ParsedBiomarker],
        confidence: ParsingConfidence,
        parsingNotes: [String]? = nil
    ) {
        self.provider = provider
        self.testDate = testDate
        self.patientName = patientName
        self.orderingPhysician = orderingPhysician
        self.biomarkers = biomarkers
        self.confidence = confidence
        self.parsingNotes = parsingNotes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode provider - handle both enum and string
        if let providerString = try? container.decode(String.self, forKey: .provider) {
            provider = LabProvider(rawValue: providerString) ?? .unknown
        } else {
            provider = try container.decode(LabProvider.self, forKey: .provider)
        }

        // Decode test date - handle string or Date
        if let dateString = try? container.decode(String.self, forKey: .testDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            testDate = formatter.date(from: dateString)
        } else {
            testDate = try? container.decode(Date.self, forKey: .testDate)
        }

        patientName = try container.decodeIfPresent(String.self, forKey: .patientName)
        orderingPhysician = try container.decodeIfPresent(String.self, forKey: .orderingPhysician)
        biomarkers = try container.decodeIfPresent([ParsedBiomarker].self, forKey: .biomarkers) ?? []

        // Decode confidence - handle string
        if let confidenceString = try? container.decode(String.self, forKey: .confidence) {
            confidence = ParsingConfidence(rawValue: confidenceString) ?? .medium
        } else {
            confidence = try container.decode(ParsingConfidence.self, forKey: .confidence)
        }

        parsingNotes = try container.decodeIfPresent([String].self, forKey: .parsingNotes)
    }
}

/// Known lab providers
enum LabProvider: String, Codable, CaseIterable {
    case quest = "quest"
    case labcorp = "labcorp"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .quest: return "Quest Diagnostics"
        case .labcorp: return "LabCorp"
        case .unknown: return "Unknown Provider"
        }
    }

    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "quest", "quest diagnostics":
            self = .quest
        case "labcorp", "laboratory corporation of america":
            self = .labcorp
        default:
            self = .unknown
        }
    }
}

/// Confidence level of parsing
enum ParsingConfidence: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Medium Confidence"
        case .low: return "Low Confidence"
        }
    }

    var iconName: String {
        switch self {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }
}

/// Individual biomarker extracted from PDF
struct ParsedBiomarker: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var value: Double
    var unit: String
    var referenceRange: String?
    var referenceLow: Double?
    var referenceHigh: Double?
    var flag: BiomarkerFlag?
    var category: String?
    var isSelected: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case value
        case unit
        case referenceRange = "reference_range"
        case referenceLow = "reference_low"
        case referenceHigh = "reference_high"
        case flag
        case category
        case isSelected = "is_selected"
    }

    init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        unit: String,
        referenceRange: String? = nil,
        referenceLow: Double? = nil,
        referenceHigh: Double? = nil,
        flag: BiomarkerFlag? = nil,
        category: String? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.referenceRange = referenceRange
        self.referenceLow = referenceLow
        self.referenceHigh = referenceHigh
        self.flag = flag
        self.category = category
        self.isSelected = isSelected
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate ID if not present
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Double.self, forKey: .value)
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
        referenceRange = try container.decodeIfPresent(String.self, forKey: .referenceRange)
        referenceLow = try container.decodeIfPresent(Double.self, forKey: .referenceLow)
        referenceHigh = try container.decodeIfPresent(Double.self, forKey: .referenceHigh)

        // Decode flag - handle string
        if let flagString = try? container.decode(String.self, forKey: .flag) {
            flag = BiomarkerFlag(rawValue: flagString)
        } else {
            flag = try container.decodeIfPresent(BiomarkerFlag.self, forKey: .flag)
        }

        category = try container.decodeIfPresent(String.self, forKey: .category)
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? true
    }

    /// Convert to LabMarker for saving
    func toLabMarker() -> LabMarker {
        let status: MarkerStatus
        if let flag = flag {
            switch flag {
            case .normal: status = .normal
            case .low: status = .low
            case .high: status = .high
            case .critical: status = .critical
            }
        } else {
            status = .normal
        }

        return LabMarker(
            id: id,
            name: name,
            value: value,
            unit: unit,
            referenceMin: referenceLow,
            referenceMax: referenceHigh,
            status: status
        )
    }
}

/// Flag indicating biomarker status
enum BiomarkerFlag: String, Codable, CaseIterable {
    case normal = "normal"
    case low = "low"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .low: return "Low"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var iconName: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// ============================================================================
// API Response Wrapper
// ============================================================================

/// Response from the parse-lab-pdf edge function
struct ParseLabPDFResponse: Codable {
    let success: Bool
    let provider: String?
    let testDate: String?
    let patientName: String?
    let orderingPhysician: String?
    let biomarkers: [ParsedBiomarker]
    let confidence: String
    let parsingNotes: [String]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case provider
        case testDate = "test_date"
        case patientName = "patient_name"
        case orderingPhysician = "ordering_physician"
        case biomarkers
        case confidence
        case parsingNotes = "parsing_notes"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        testDate = try container.decodeIfPresent(String.self, forKey: .testDate)
        patientName = try container.decodeIfPresent(String.self, forKey: .patientName)
        orderingPhysician = try container.decodeIfPresent(String.self, forKey: .orderingPhysician)
        biomarkers = try container.decodeIfPresent([ParsedBiomarker].self, forKey: .biomarkers) ?? []
        confidence = try container.decodeIfPresent(String.self, forKey: .confidence) ?? "medium"
        parsingNotes = try container.decodeIfPresent([String].self, forKey: .parsingNotes)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    /// Convert to ParsedLabResult
    func toParsedLabResult() -> ParsedLabResult? {
        guard success else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let date: Date? = testDate.flatMap { dateFormatter.date(from: $0) }

        return ParsedLabResult(
            provider: LabProvider(rawValue: provider ?? "unknown"),
            testDate: date,
            patientName: patientName,
            orderingPhysician: orderingPhysician,
            biomarkers: biomarkers,
            confidence: ParsingConfidence(rawValue: confidence) ?? .medium,
            parsingNotes: parsingNotes
        )
    }
}
