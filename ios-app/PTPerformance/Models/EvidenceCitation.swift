//
//  EvidenceCitation.swift
//  PTPerformance
//
//  X2Index Command Center - M2: Evidence Citation System
//  Full citation support for AI-generated claims
//
//  Features:
//  - Citation linking to source data
//  - Confidence grading (A-D scale)
//  - Multiple source types support
//  - Excerpt and URL tracking
//

import Foundation
import SwiftUI

// MARK: - Evidence Citation Model

/// A citation linking an AI claim to its source evidence
struct EvidenceCitation: Identifiable, Codable, Hashable {
    let id: UUID
    let claimId: UUID
    let sourceType: CitationSourceType
    let sourceId: String
    let sourceTitle: String
    let confidence: ConfidenceGrade
    let excerpt: String?
    let timestamp: Date
    let url: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case claimId = "claim_id"
        case sourceType = "source_type"
        case sourceId = "source_id"
        case sourceTitle = "source_title"
        case confidence
        case excerpt
        case timestamp
        case url
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        claimId: UUID,
        sourceType: CitationSourceType,
        sourceId: String,
        sourceTitle: String,
        confidence: ConfidenceGrade,
        excerpt: String? = nil,
        timestamp: Date = Date(),
        url: String? = nil
    ) {
        self.id = id
        self.claimId = claimId
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.sourceTitle = sourceTitle
        self.confidence = confidence
        self.excerpt = excerpt
        self.timestamp = timestamp
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        claimId = try container.decode(UUID.self, forKey: .claimId)

        // Handle both enum and string decoding for sourceType
        if let typeString = try? container.decode(String.self, forKey: .sourceType) {
            sourceType = CitationSourceType(rawValue: typeString) ?? .manualEntry
        } else {
            sourceType = try container.decode(CitationSourceType.self, forKey: .sourceType)
        }

        sourceId = try container.decode(String.self, forKey: .sourceId)
        sourceTitle = try container.decode(String.self, forKey: .sourceTitle)

        // Handle both enum and string decoding for confidence
        if let gradeString = try? container.decode(String.self, forKey: .confidence) {
            confidence = ConfidenceGrade(rawValue: gradeString) ?? .moderate
        } else {
            confidence = try container.decode(ConfidenceGrade.self, forKey: .confidence)
        }

        excerpt = try container.decodeIfPresent(String.self, forKey: .excerpt)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        url = try container.decodeIfPresent(String.self, forKey: .url)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EvidenceCitation, rhs: EvidenceCitation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Citation Source Type

/// Types of sources that can be cited
enum CitationSourceType: String, Codable, CaseIterable {
    case healthKit = "health_kit"
    case whoop = "whoop"
    case manualEntry = "manual"
    case labResult = "lab"
    case checkIn = "check_in"
    case workout = "workout"
    case research = "research"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .healthKit:
            return "Apple Health"
        case .whoop:
            return "WHOOP"
        case .manualEntry:
            return "Manual Entry"
        case .labResult:
            return "Lab Result"
        case .checkIn:
            return "Daily Check-in"
        case .workout:
            return "Workout Log"
        case .research:
            return "Research"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .healthKit:
            return "heart.fill"
        case .whoop:
            return "waveform.path.ecg"
        case .manualEntry:
            return "square.and.pencil"
        case .labResult:
            return "cross.case.fill"
        case .checkIn:
            return "checkmark.circle.fill"
        case .workout:
            return "dumbbell.fill"
        case .research:
            return "book.fill"
        }
    }

    /// Color associated with this source type
    var color: Color {
        switch self {
        case .healthKit:
            return .red
        case .whoop:
            return .green
        case .manualEntry:
            return .gray
        case .labResult:
            return .purple
        case .checkIn:
            return .modusCyan
        case .workout:
            return .orange
        case .research:
            return .blue
        }
    }

    /// Reliability weight for confidence calculation (0.0-1.0)
    var reliabilityWeight: Double {
        switch self {
        case .labResult:
            return 1.0
        case .healthKit:
            return 0.90
        case .whoop:
            return 0.85
        case .workout:
            return 0.75
        case .checkIn:
            return 0.65
        case .research:
            return 0.80
        case .manualEntry:
            return 0.50
        }
    }
}

// MARK: - Confidence Grade

/// Confidence grading scale for citations
enum ConfidenceGrade: String, Codable, CaseIterable {
    case high = "A"       // Direct measurement
    case good = "B"       // Reliable source
    case moderate = "C"   // Inferred
    case low = "D"        // Estimated

    /// Color associated with this grade
    var color: Color {
        switch self {
        case .high:
            return .modusTealAccent
        case .good:
            return .modusCyan
        case .moderate:
            return .orange
        case .low:
            return .red
        }
    }

    /// Human-readable description
    var description: String {
        switch self {
        case .high:
            return "Direct measurement from verified source"
        case .good:
            return "Reliable data from trusted source"
        case .moderate:
            return "Inferred from available data"
        case .low:
            return "Estimated based on limited data"
        }
    }

    /// Short display label
    var displayLabel: String {
        switch self {
        case .high:
            return "High"
        case .good:
            return "Good"
        case .moderate:
            return "Moderate"
        case .low:
            return "Low"
        }
    }

    /// Numeric value for calculations (0.0-1.0)
    var numericValue: Double {
        switch self {
        case .high:
            return 1.0
        case .good:
            return 0.75
        case .moderate:
            return 0.5
        case .low:
            return 0.25
        }
    }

    /// Initialize from a numeric score
    init(fromScore score: Double) {
        switch score {
        case 0.85...1.0:
            self = .high
        case 0.65..<0.85:
            self = .good
        case 0.4..<0.65:
            self = .moderate
        default:
            self = .low
        }
    }
}

// MARK: - Citation Extensions

extension EvidenceCitation {
    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Relative time description (e.g., "2 hours ago")
    var relativeTimeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Whether this citation has a viewable URL
    var hasViewableURL: Bool {
        guard let url = url, !url.isEmpty else { return false }
        return URL(string: url) != nil
    }

    /// Truncated excerpt for preview
    var excerptPreview: String? {
        guard let excerpt = excerpt, !excerpt.isEmpty else { return nil }
        if excerpt.count <= 100 {
            return excerpt
        }
        return String(excerpt.prefix(100)) + "..."
    }
}

// MARK: - Sample Data for Previews

#if DEBUG
extension EvidenceCitation {
    static let sampleHealthKitCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .healthKit,
        sourceId: "hk_hrv_001",
        sourceTitle: "Morning HRV Reading",
        confidence: .high,
        excerpt: "HRV: 62ms, measured at 6:45 AM during wake-up window",
        timestamp: Date().addingTimeInterval(-3600)
    )

    static let sampleWhoopCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .whoop,
        sourceId: "whoop_recovery_001",
        sourceTitle: "Recovery Score",
        confidence: .high,
        excerpt: "Recovery: 78%, Sleep Performance: 85%",
        timestamp: Date().addingTimeInterval(-7200)
    )

    static let sampleLabCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .labResult,
        sourceId: "lab_vitd_001",
        sourceTitle: "Vitamin D Panel",
        confidence: .high,
        excerpt: "25-OH Vitamin D: 45 ng/mL (optimal range: 30-100)",
        timestamp: Date().addingTimeInterval(-604800),
        url: "https://example.com/lab/results/12345"
    )

    static let sampleCheckInCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .checkIn,
        sourceId: "checkin_001",
        sourceTitle: "Daily Wellness Check-in",
        confidence: .good,
        excerpt: "Energy: 8/10, Sleep Quality: 4/5, Stress: Low",
        timestamp: Date().addingTimeInterval(-43200)
    )

    static let sampleWorkoutCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .workout,
        sourceId: "workout_001",
        sourceTitle: "Upper Body Strength Session",
        confidence: .good,
        excerpt: "Completed 5x5 bench press at 185 lbs, RPE 7",
        timestamp: Date().addingTimeInterval(-86400)
    )

    static let sampleManualCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .manualEntry,
        sourceId: "manual_001",
        sourceTitle: "Self-Reported Soreness",
        confidence: .moderate,
        excerpt: "Noted shoulder tightness after yesterday's session",
        timestamp: Date().addingTimeInterval(-21600)
    )

    static let sampleResearchCitation = EvidenceCitation(
        claimId: UUID(),
        sourceType: .research,
        sourceId: "research_001",
        sourceTitle: "Sleep and Recovery Study",
        confidence: .good,
        excerpt: "Research indicates 7-9 hours of sleep optimizes recovery markers",
        url: "https://pubmed.ncbi.nlm.nih.gov/12345678"
    )

    /// Collection of sample citations for testing
    static let sampleCitations: [EvidenceCitation] = [
        sampleHealthKitCitation,
        sampleWhoopCitation,
        sampleLabCitation,
        sampleCheckInCitation,
        sampleWorkoutCitation
    ]
}
#endif
