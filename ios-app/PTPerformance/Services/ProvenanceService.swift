//
//  ProvenanceService.swift
//  PTPerformance
//
//  Evidence Provenance Service for X2Index
//  Manages creation, querying, and validation of evidence claims
//  Ensures >=95% AI citation coverage
//

import Foundation
import Supabase
import SwiftUI

// MARK: - Provenance Error Types

enum ProvenanceError: LocalizedError {
    case noEvidence
    case invalidConfidence
    case claimNotFound
    case validationFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noEvidence:
            return "Claims must have at least one evidence reference"
        case .invalidConfidence:
            return "Confidence score must be between 0.0 and 1.0"
        case .claimNotFound:
            return "The specified claim could not be found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Provenance Service

/// Service for creating and querying evidence claims
/// Validates that every claim has at least one evidence ref
/// Calculates confidence based on source reliability
@MainActor
class ProvenanceService: ObservableObject {
    nonisolated(unsafe) private let client: PTSupabaseClient
    @Published var isLoading: Bool = false
    @Published var error: Error?

    /// In-memory cache for claims (cleared on app restart)
    private var claimsCache: [UUID: EvidenceClaim] = [:]
    private var athleteClaimsCache: [UUID: [EvidenceClaim]] = [:]

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Create Claim

    /// Create a new evidence claim with validation
    /// - Parameters:
    ///   - text: The claim text
    ///   - type: Type of claim (readinessTrend, riskAlert, etc.)
    ///   - sources: Evidence references supporting the claim
    ///   - confidence: Optional explicit confidence (if nil, calculated from sources)
    ///   - summaryId: ID of the parent summary
    ///   - modelVersion: Version of the AI model generating the claim
    ///   - retrievalSetHash: Hash of the retrieval set used
    /// - Returns: Created EvidenceClaim
    /// - Throws: ProvenanceError if validation fails
    func createClaim(
        text: String,
        type: EvidenceClaim.ClaimType,
        sources: [EvidenceClaim.EvidenceRef],
        confidence: Double? = nil,
        summaryId: UUID,
        modelVersion: String = "x2index-v1.0",
        retrievalSetHash: String = ""
    ) throws -> EvidenceClaim {
        // Validate: every claim must have at least one evidence ref
        guard !sources.isEmpty else {
            throw ProvenanceError.noEvidence
        }

        // Validate text is not empty
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProvenanceError.validationFailed("Claim text cannot be empty")
        }

        // Calculate confidence if not provided
        let calculatedConfidence = confidence ?? calculateConfidence(from: sources)

        // Validate confidence range
        guard calculatedConfidence >= 0 && calculatedConfidence <= 1 else {
            throw ProvenanceError.invalidConfidence
        }

        // Determine if uncertainty flag should be set
        let uncertaintyFlag = calculatedConfidence < 0.5 || sources.count == 1

        // Determine if PT review is required based on claim type
        let ptReviewRequired = type.requiresPTReview || calculatedConfidence < 0.6

        let claim = EvidenceClaim(
            claimId: UUID(),
            summaryId: summaryId,
            claimText: text,
            claimType: type,
            confidenceScore: calculatedConfidence,
            uncertaintyFlag: uncertaintyFlag,
            evidenceRefs: sources,
            modelMetadata: EvidenceClaim.ModelMetadata(
                modelVersion: modelVersion,
                retrievalSetHash: retrievalSetHash
            ),
            reviewState: EvidenceClaim.ReviewState(
                ptReviewRequired: ptReviewRequired
            )
        )

        // Cache the claim
        claimsCache[claim.claimId] = claim

        DebugLogger.shared.log(
            "Created claim: \(claim.claimId) type=\(type.rawValue) confidence=\(calculatedConfidence)",
            level: .success
        )

        return claim
    }

    // MARK: - Get Claims for Athlete

    /// Fetch all claims for an athlete since a given date
    /// - Parameters:
    ///   - athleteId: The athlete's UUID
    ///   - since: Optional date filter (defaults to 30 days ago)
    /// - Returns: Array of EvidenceClaims
    func getClaimsForAthlete(
        athleteId: UUID,
        since: Date? = nil
    ) async throws -> [EvidenceClaim] {
        isLoading = true
        defer { isLoading = false }

        let sinceDate = since ?? Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // Check cache first
        if let cached = athleteClaimsCache[athleteId] {
            let filtered = cached.filter { $0.modelMetadata.generatedAt >= sinceDate }
            if !filtered.isEmpty {
                return filtered
            }
        }

        do {
            let dateFormatter = ISO8601DateFormatter()
            let dateString = dateFormatter.string(from: sinceDate)

            let response = try await client.client
                .from("evidence_claims")
                .select()
                .eq("athlete_id", value: athleteId.uuidString)
                .gte("created_at", value: dateString)
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let claims = try decoder.decode([EvidenceClaim].self, from: response.data)

            // Update cache
            athleteClaimsCache[athleteId] = claims

            // Also update individual claim cache
            for claim in claims {
                claimsCache[claim.claimId] = claim
            }

            return claims
        } catch {
            ErrorLogger.shared.logError(error, context: "ProvenanceService.getClaimsForAthlete")

            // If network fails, return cached data if available
            if let cached = athleteClaimsCache[athleteId] {
                self.error = error
                return cached.filter { $0.modelMetadata.generatedAt >= sinceDate }
            }

            throw ProvenanceError.networkError(error)
        }
    }

    // MARK: - Get Evidence for Claim

    /// Get all evidence references for a specific claim
    /// - Parameter claimId: The claim's UUID
    /// - Returns: Array of EvidenceRefs
    func getEvidenceForClaim(claimId: UUID) async throws -> [EvidenceClaim.EvidenceRef] {
        // Check cache first
        if let cached = claimsCache[claimId] {
            return cached.evidenceRefs
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("evidence_claims")
                .select("evidence_refs")
                .eq("claim_id", value: claimId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode just the evidence_refs field
            struct EvidenceWrapper: Codable {
                let evidenceRefs: [EvidenceClaim.EvidenceRef]

                enum CodingKeys: String, CodingKey {
                    case evidenceRefs = "evidence_refs"
                }
            }

            let wrapper = try decoder.decode(EvidenceWrapper.self, from: response.data)
            return wrapper.evidenceRefs
        } catch {
            ErrorLogger.shared.logError(error, context: "ProvenanceService.getEvidenceForClaim")
            throw ProvenanceError.claimNotFound
        }
    }

    // MARK: - Mark Claim Reviewed

    /// Mark a claim as reviewed by a PT
    /// - Parameters:
    ///   - claimId: The claim's UUID
    ///   - reviewedBy: UUID of the reviewing PT
    ///   - notes: Optional review notes
    func markClaimReviewed(
        claimId: UUID,
        reviewedBy: UUID,
        notes: String? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let now = Date()

        do {
            let updateData: [String: AnyEncodable] = [
                "review_state": AnyEncodable([
                    "pt_review_required": true,
                    "reviewed_by": reviewedBy.uuidString,
                    "reviewed_at": ISO8601DateFormatter().string(from: now),
                    "review_notes": notes as Any
                ])
            ]

            try await client.client
                .from("evidence_claims")
                .update(updateData)
                .eq("claim_id", value: claimId.uuidString)
                .execute()

            // Update cache
            if var cached = claimsCache[claimId] {
                let updatedReviewState = EvidenceClaim.ReviewState(
                    ptReviewRequired: cached.reviewState.ptReviewRequired,
                    reviewedBy: reviewedBy,
                    reviewedAt: now,
                    reviewNotes: notes
                )

                // Create updated claim (struct is immutable)
                let updatedClaim = EvidenceClaim(
                    claimId: cached.claimId,
                    summaryId: cached.summaryId,
                    claimText: cached.claimText,
                    claimType: cached.claimType,
                    confidenceScore: cached.confidenceScore,
                    uncertaintyFlag: cached.uncertaintyFlag,
                    evidenceRefs: cached.evidenceRefs,
                    modelMetadata: cached.modelMetadata,
                    reviewState: updatedReviewState
                )

                claimsCache[claimId] = updatedClaim
            }

            DebugLogger.shared.log("Marked claim \(claimId) as reviewed by \(reviewedBy)", level: .success)
        } catch {
            ErrorLogger.shared.logError(error, context: "ProvenanceService.markClaimReviewed")
            throw ProvenanceError.networkError(error)
        }
    }

    // MARK: - Confidence Calculation

    /// Calculate confidence score based on source reliability
    /// Uses weighted average of source reliability weights
    /// - Parameter sources: Array of evidence references
    /// - Returns: Confidence score between 0.0 and 1.0
    func calculateConfidence(from sources: [EvidenceClaim.EvidenceRef]) -> Double {
        guard !sources.isEmpty else { return 0.0 }

        // Calculate weighted average of source reliability
        let totalWeight = sources.reduce(0.0) { $0 + $1.sourceType.reliabilityWeight }
        let averageReliability = totalWeight / Double(sources.count)

        // Boost confidence for multiple diverse sources
        let uniqueTypes = Set(sources.map { $0.sourceType })
        let diversityBonus = min(0.15, Double(uniqueTypes.count - 1) * 0.05)

        // Boost confidence for recent evidence
        let now = Date()
        let recentSources = sources.filter {
            now.timeIntervalSince($0.timestamp) < 7 * 24 * 3600 // Within 7 days
        }
        let recencyBonus = recentSources.count == sources.count ? 0.05 : 0.0

        // Calculate final confidence
        let confidence = min(1.0, averageReliability + diversityBonus + recencyBonus)

        return confidence
    }

    // MARK: - Validation

    /// Validate a claim before creation
    /// - Parameter claim: The claim to validate
    /// - Throws: ProvenanceError if validation fails
    func validateClaim(_ claim: EvidenceClaim) throws {
        // Must have at least one evidence reference
        guard !claim.evidenceRefs.isEmpty else {
            throw ProvenanceError.noEvidence
        }

        // Confidence must be in valid range
        guard claim.confidenceScore >= 0 && claim.confidenceScore <= 1 else {
            throw ProvenanceError.invalidConfidence
        }

        // Claim text must not be empty
        guard !claim.claimText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProvenanceError.validationFailed("Claim text cannot be empty")
        }

        // All evidence refs must have snippets
        for ref in claim.evidenceRefs {
            guard !ref.snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ProvenanceError.validationFailed("Evidence snippet cannot be empty")
            }
        }
    }

    // MARK: - Statistics

    /// Get citation coverage statistics for an athlete
    /// - Parameter athleteId: The athlete's UUID
    /// - Returns: Coverage statistics
    func getCitationCoverage(for athleteId: UUID) async throws -> CitationCoverage {
        let claims = try await getClaimsForAthlete(athleteId: athleteId)

        let totalClaims = claims.count
        let claimsWithEvidence = claims.filter { !$0.evidenceRefs.isEmpty }.count
        let coverageRate = totalClaims > 0 ? Double(claimsWithEvidence) / Double(totalClaims) : 1.0

        let averageConfidence = totalClaims > 0
            ? claims.reduce(0.0) { $0 + $1.confidenceScore } / Double(totalClaims)
            : 0.0

        let pendingReviews = claims.filter { $0.reviewState.isPendingReview }.count

        return CitationCoverage(
            totalClaims: totalClaims,
            claimsWithEvidence: claimsWithEvidence,
            coverageRate: coverageRate,
            averageConfidence: averageConfidence,
            pendingReviews: pendingReviews,
            meetsTarget: coverageRate >= 0.95
        )
    }

    // MARK: - Cache Management

    /// Clear all cached data
    func clearCache() {
        claimsCache.removeAll()
        athleteClaimsCache.removeAll()
    }

    /// Get a cached claim by ID
    func getCachedClaim(_ claimId: UUID) -> EvidenceClaim? {
        claimsCache[claimId]
    }
}

// MARK: - Supporting Types

/// Citation coverage statistics
struct CitationCoverage {
    let totalClaims: Int
    let claimsWithEvidence: Int
    let coverageRate: Double
    let averageConfidence: Double
    let pendingReviews: Int
    let meetsTarget: Bool

    var coveragePercentage: String {
        String(format: "%.1f%%", coverageRate * 100)
    }

    var confidencePercentage: String {
        String(format: "%.0f%%", averageConfidence * 100)
    }
}

/// Type-erased encodable wrapper for Supabase updates
private struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: Any] {
            let encodableDict = dict.mapValues { AnyEncodable($0) }
            try container.encode(encodableDict)
        } else if let array = value as? [Any] {
            let encodableArray = array.map { AnyEncodable($0) }
            try container.encode(encodableArray)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension ProvenanceService {
    /// Create a mock service with sample data for previews
    static var preview: ProvenanceService {
        let service = ProvenanceService()
        // Pre-populate with sample claims
        service.claimsCache[EvidenceClaim.sampleReadinessClaim.claimId] = EvidenceClaim.sampleReadinessClaim
        service.claimsCache[EvidenceClaim.sampleRiskAlert.claimId] = EvidenceClaim.sampleRiskAlert
        service.claimsCache[EvidenceClaim.sampleBiomarkerClaim.claimId] = EvidenceClaim.sampleBiomarkerClaim
        return service
    }
}
#endif
