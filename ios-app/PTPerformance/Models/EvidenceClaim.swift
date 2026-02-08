//
//  EvidenceClaim.swift
//  PTPerformance
//
//  Evidence Provenance System for X2Index
//  Every AI-generated claim must have citation-linked evidence
//  Target: >=95% AI citation coverage
//

import Foundation

/// An AI-generated claim with full provenance
/// Ensures every meaningful claim has source citations (lab line, wearable metric, check-in, session note)
struct EvidenceClaim: Codable, Identifiable {
    let claimId: UUID
    let summaryId: UUID
    let claimText: String
    let claimType: ClaimType
    let confidenceScore: Double // 0.0-1.0
    let uncertaintyFlag: Bool
    let evidenceRefs: [EvidenceRef]
    let modelMetadata: ModelMetadata
    let reviewState: ReviewState

    var id: UUID { claimId }

    /// Types of AI-generated claims
    enum ClaimType: String, Codable, CaseIterable {
        case readinessTrend
        case riskAlert
        case recoveryInsight
        case nutritionInsight
        case trainingRecommendation
        case biomarkerChange
        case safetyWarning

        var displayName: String {
            switch self {
            case .readinessTrend: return "Readiness Trend"
            case .riskAlert: return "Risk Alert"
            case .recoveryInsight: return "Recovery Insight"
            case .nutritionInsight: return "Nutrition Insight"
            case .trainingRecommendation: return "Training Recommendation"
            case .biomarkerChange: return "Biomarker Change"
            case .safetyWarning: return "Safety Warning"
            }
        }

        var icon: String {
            switch self {
            case .readinessTrend: return "chart.line.uptrend.xyaxis"
            case .riskAlert: return "exclamationmark.triangle.fill"
            case .recoveryInsight: return "heart.fill"
            case .nutritionInsight: return "fork.knife"
            case .trainingRecommendation: return "figure.strengthtraining.traditional"
            case .biomarkerChange: return "waveform.path.ecg"
            case .safetyWarning: return "exclamationmark.octagon.fill"
            }
        }

        /// Whether this claim type requires PT review by default
        var requiresPTReview: Bool {
            switch self {
            case .safetyWarning, .riskAlert: return true
            default: return false
            }
        }
    }

    /// Reference to a piece of evidence supporting the claim
    struct EvidenceRef: Codable, Identifiable {
        let id: UUID
        let sourceType: SourceType
        let sourceId: String
        let timestamp: Date
        let snippet: String
        let dataValue: String?

        /// Types of evidence sources
        enum SourceType: String, Codable, CaseIterable {
            case labResult = "lab_result"
            case wearableMetric = "wearable_metric"
            case checkIn = "check_in"
            case sessionNote = "session_note"
            case exerciseLog = "exercise_log"
            case biomarker = "biomarker"
            case sleepData = "sleep_data"
            case hrvReading = "hrv_reading"
            case recoverySession = "recovery_session"

            var displayName: String {
                switch self {
                case .labResult: return "Lab Result"
                case .wearableMetric: return "Wearable Data"
                case .checkIn: return "Check-in"
                case .sessionNote: return "Session Note"
                case .exerciseLog: return "Exercise Log"
                case .biomarker: return "Biomarker"
                case .sleepData: return "Sleep Data"
                case .hrvReading: return "HRV Reading"
                case .recoverySession: return "Recovery Session"
                }
            }

            var icon: String {
                switch self {
                case .labResult: return "cross.case.fill"
                case .wearableMetric: return "applewatch"
                case .checkIn: return "checkmark.circle.fill"
                case .sessionNote: return "note.text"
                case .exerciseLog: return "dumbbell.fill"
                case .biomarker: return "waveform.path.ecg"
                case .sleepData: return "bed.double.fill"
                case .hrvReading: return "heart.fill"
                case .recoverySession: return "figure.cooldown"
                }
            }

            /// Reliability weight for confidence calculation (0.0-1.0)
            var reliabilityWeight: Double {
                switch self {
                case .labResult: return 1.0
                case .biomarker: return 0.95
                case .wearableMetric: return 0.85
                case .hrvReading: return 0.85
                case .sleepData: return 0.80
                case .exerciseLog: return 0.75
                case .recoverySession: return 0.75
                case .checkIn: return 0.65
                case .sessionNote: return 0.60
                }
            }
        }

        // Custom coding keys for sourceType
        enum CodingKeys: String, CodingKey {
            case id
            case sourceType = "source_type"
            case sourceId = "source_id"
            case timestamp
            case snippet
            case dataValue = "data_value"
        }

        init(
            id: UUID = UUID(),
            sourceType: SourceType,
            sourceId: String,
            timestamp: Date,
            snippet: String,
            dataValue: String? = nil
        ) {
            self.id = id
            self.sourceType = sourceType
            self.sourceId = sourceId
            self.timestamp = timestamp
            self.snippet = snippet
            self.dataValue = dataValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)

            // Handle both enum and string decoding for sourceType
            if let typeString = try? container.decode(String.self, forKey: .sourceType) {
                sourceType = SourceType(rawValue: typeString) ?? .checkIn
            } else {
                sourceType = try container.decode(SourceType.self, forKey: .sourceType)
            }

            sourceId = try container.decode(String.self, forKey: .sourceId)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            snippet = try container.decode(String.self, forKey: .snippet)
            dataValue = try container.decodeIfPresent(String.self, forKey: .dataValue)
        }
    }

    /// Metadata about the AI model that generated the claim
    struct ModelMetadata: Codable {
        let modelVersion: String
        let retrievalSetHash: String
        let generatedAt: Date

        enum CodingKeys: String, CodingKey {
            case modelVersion = "model_version"
            case retrievalSetHash = "retrieval_set_hash"
            case generatedAt = "generated_at"
        }

        init(modelVersion: String, retrievalSetHash: String, generatedAt: Date = Date()) {
            self.modelVersion = modelVersion
            self.retrievalSetHash = retrievalSetHash
            self.generatedAt = generatedAt
        }
    }

    /// Review state for PT oversight
    struct ReviewState: Codable {
        let ptReviewRequired: Bool
        let reviewedBy: UUID?
        let reviewedAt: Date?
        let reviewNotes: String?

        enum CodingKeys: String, CodingKey {
            case ptReviewRequired = "pt_review_required"
            case reviewedBy = "reviewed_by"
            case reviewedAt = "reviewed_at"
            case reviewNotes = "review_notes"
        }

        init(
            ptReviewRequired: Bool,
            reviewedBy: UUID? = nil,
            reviewedAt: Date? = nil,
            reviewNotes: String? = nil
        ) {
            self.ptReviewRequired = ptReviewRequired
            self.reviewedBy = reviewedBy
            self.reviewedAt = reviewedAt
            self.reviewNotes = reviewNotes
        }

        /// Whether the claim has been reviewed
        var isReviewed: Bool {
            reviewedBy != nil && reviewedAt != nil
        }

        /// Whether the claim is pending review
        var isPendingReview: Bool {
            ptReviewRequired && !isReviewed
        }
    }

    enum CodingKeys: String, CodingKey {
        case claimId = "claim_id"
        case summaryId = "summary_id"
        case claimText = "claim_text"
        case claimType = "claim_type"
        case confidenceScore = "confidence_score"
        case uncertaintyFlag = "uncertainty_flag"
        case evidenceRefs = "evidence_refs"
        case modelMetadata = "model_metadata"
        case reviewState = "review_state"
    }

    init(
        claimId: UUID = UUID(),
        summaryId: UUID,
        claimText: String,
        claimType: ClaimType,
        confidenceScore: Double,
        uncertaintyFlag: Bool = false,
        evidenceRefs: [EvidenceRef],
        modelMetadata: ModelMetadata,
        reviewState: ReviewState
    ) {
        self.claimId = claimId
        self.summaryId = summaryId
        self.claimText = claimText
        self.claimType = claimType
        self.confidenceScore = max(0, min(1, confidenceScore))
        self.uncertaintyFlag = uncertaintyFlag
        self.evidenceRefs = evidenceRefs
        self.modelMetadata = modelMetadata
        self.reviewState = reviewState
    }
}

// MARK: - Convenience Extensions

extension EvidenceClaim {
    /// Number of evidence sources
    var sourceCount: Int {
        evidenceRefs.count
    }

    /// Whether the claim has sufficient evidence (at least 1 source)
    var hasSufficientEvidence: Bool {
        !evidenceRefs.isEmpty
    }

    /// Confidence level category
    var confidenceLevel: ConfidenceLevel {
        switch confidenceScore {
        case 0.8...1.0: return .high
        case 0.5..<0.8: return .medium
        default: return .low
        }
    }

    enum ConfidenceLevel {
        case high
        case medium
        case low

        var displayName: String {
            switch self {
            case .high: return "High Confidence"
            case .medium: return "Medium Confidence"
            case .low: return "Low Confidence"
            }
        }
    }

    /// Unique source types in the evidence
    var uniqueSourceTypes: Set<EvidenceRef.SourceType> {
        Set(evidenceRefs.map { $0.sourceType })
    }

    /// Most recent evidence timestamp
    var mostRecentEvidence: Date? {
        evidenceRefs.max(by: { $0.timestamp < $1.timestamp })?.timestamp
    }

    /// Whether claim requires attention (low confidence, needs review, or flagged)
    var requiresAttention: Bool {
        confidenceLevel == .low || reviewState.isPendingReview || uncertaintyFlag
    }
}

// MARK: - Sample Data for Previews

#if DEBUG
extension EvidenceClaim {
    static let sampleReadinessClaim = EvidenceClaim(
        summaryId: UUID(),
        claimText: "Your readiness has improved 12% over the past week, driven by better sleep consistency.",
        claimType: .readinessTrend,
        confidenceScore: 0.87,
        evidenceRefs: [
            EvidenceRef(
                sourceType: .sleepData,
                sourceId: "sleep_001",
                timestamp: Date().addingTimeInterval(-86400),
                snippet: "Average sleep: 7.5h (up from 6.8h)",
                dataValue: "7.5"
            ),
            EvidenceRef(
                sourceType: .checkIn,
                sourceId: "checkin_001",
                timestamp: Date().addingTimeInterval(-43200),
                snippet: "Reported feeling well-rested",
                dataValue: nil
            )
        ],
        modelMetadata: ModelMetadata(
            modelVersion: "x2index-v1.2",
            retrievalSetHash: "abc123"
        ),
        reviewState: ReviewState(ptReviewRequired: false)
    )

    static let sampleRiskAlert = EvidenceClaim(
        summaryId: UUID(),
        claimText: "Elevated shoulder strain detected. Consider reducing overhead volume this week.",
        claimType: .riskAlert,
        confidenceScore: 0.72,
        uncertaintyFlag: true,
        evidenceRefs: [
            EvidenceRef(
                sourceType: .exerciseLog,
                sourceId: "log_001",
                timestamp: Date().addingTimeInterval(-172800),
                snippet: "3 consecutive high-volume overhead sessions",
                dataValue: "12 sets"
            ),
            EvidenceRef(
                sourceType: .sessionNote,
                sourceId: "note_001",
                timestamp: Date().addingTimeInterval(-86400),
                snippet: "Patient mentioned mild shoulder discomfort",
                dataValue: nil
            )
        ],
        modelMetadata: ModelMetadata(
            modelVersion: "x2index-v1.2",
            retrievalSetHash: "def456"
        ),
        reviewState: ReviewState(ptReviewRequired: true)
    )

    static let sampleBiomarkerClaim = EvidenceClaim(
        summaryId: UUID(),
        claimText: "Vitamin D levels have normalized after 8 weeks of supplementation.",
        claimType: .biomarkerChange,
        confidenceScore: 0.95,
        evidenceRefs: [
            EvidenceRef(
                sourceType: .labResult,
                sourceId: "lab_001",
                timestamp: Date().addingTimeInterval(-604800),
                snippet: "Vitamin D: 45 ng/mL (optimal range)",
                dataValue: "45"
            ),
            EvidenceRef(
                sourceType: .labResult,
                sourceId: "lab_000",
                timestamp: Date().addingTimeInterval(-5184000),
                snippet: "Vitamin D: 18 ng/mL (below optimal)",
                dataValue: "18"
            )
        ],
        modelMetadata: ModelMetadata(
            modelVersion: "x2index-v1.2",
            retrievalSetHash: "ghi789"
        ),
        reviewState: ReviewState(
            ptReviewRequired: false,
            reviewedBy: UUID(),
            reviewedAt: Date().addingTimeInterval(-3600)
        )
    )
}
#endif
