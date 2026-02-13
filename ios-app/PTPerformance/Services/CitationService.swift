//
//  CitationService.swift
//  PTPerformance
//
//  X2Index Command Center - M2: Evidence Citation System
//  Service for managing evidence citations
//
//  Features:
//  - Fetch citations for claims
//  - Calculate aggregate confidence
//  - Group citations by source type
//  - Cache management
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Citation Error Types

enum CitationError: LocalizedError {
    case citationNotFound
    case invalidClaimId
    case networkError(Error)
    case decodingError(Error)
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .citationNotFound:
            return "The specified citation could not be found"
        case .invalidClaimId:
            return "Invalid claim ID provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode citation data: \(error.localizedDescription)"
        case .insufficientData:
            return "Insufficient data to generate citations"
        }
    }
}

// MARK: - Citation Service

/// Service for fetching and managing evidence citations
@MainActor
final class CitationService: ObservableObject {

    // MARK: - Singleton

    static let shared = CitationService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: CitationError?

    // MARK: - Private Properties

    private let client: PTSupabaseClient
    private var citationsCache: [UUID: [EvidenceCitation]] = [:]
    private var countCache: [UUID: Int] = [:]

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Fetch all citations for a specific claim
    /// - Parameter claimId: The UUID of the claim
    /// - Returns: Array of EvidenceCitation objects
    func fetchCitations(for claimId: UUID) async throws -> [EvidenceCitation] {
        // Check cache first
        if let cached = citationsCache[claimId] {
            return cached
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("evidence_citations")
                .select()
                .eq("claim_id", value: claimId.uuidString)
                .order("timestamp", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let citations = try decoder.decode([EvidenceCitation].self, from: response.data)

            // Update cache
            citationsCache[claimId] = citations
            countCache[claimId] = citations.count

            DebugLogger.shared.log(
                "Fetched \(citations.count) citations for claim \(claimId)",
                level: .success
            )

            return citations
        } catch let decodingError as DecodingError {
            let citationError = CitationError.decodingError(decodingError)
            self.error = citationError
            ErrorLogger.shared.logError(decodingError, context: "CitationService.fetchCitations")
            throw citationError
        } catch {
            // If network fails, try to return any cached data
            if let cached = citationsCache[claimId] {
                self.error = CitationError.networkError(error)
                return cached
            }

            let citationError = CitationError.networkError(error)
            self.error = citationError
            ErrorLogger.shared.logError(error, context: "CitationService.fetchCitations")
            throw citationError
        }
    }

    /// Get the count of citations for a claim without fetching full data
    /// - Parameter claimId: The UUID of the claim
    /// - Returns: Number of citations
    func getCitationCount(for claimId: UUID) async -> Int {
        // Check cache first
        if let cached = countCache[claimId] {
            return cached
        }

        // Try to fetch count from database
        do {
            let response = try await client.client
                .from("evidence_citations")
                .select("id", head: true, count: .exact)
                .eq("claim_id", value: claimId.uuidString)
                .execute()

            let count = response.count ?? 0
            countCache[claimId] = count
            return count
        } catch {
            DebugLogger.shared.log(
                "Failed to get citation count: \(error.localizedDescription)",
                level: .warning
            )
            return 0
        }
    }

    /// Calculate the overall confidence grade from a set of citations
    /// - Parameter citations: Array of citations to evaluate
    /// - Returns: Aggregate ConfidenceGrade
    func getOverallConfidence(for citations: [EvidenceCitation]) -> ConfidenceGrade {
        guard !citations.isEmpty else {
            return .low
        }

        // Calculate weighted average based on source reliability
        var totalWeight = 0.0
        var weightedSum = 0.0

        for citation in citations {
            let weight = citation.sourceType.reliabilityWeight
            let value = citation.confidence.numericValue
            weightedSum += weight * value
            totalWeight += weight
        }

        let averageScore = totalWeight > 0 ? weightedSum / totalWeight : 0

        // Apply diversity bonus for multiple source types
        let uniqueTypes = Set(citations.map { $0.sourceType })
        let diversityBonus = min(0.1, Double(uniqueTypes.count - 1) * 0.03)

        // Apply recency bonus for recent citations
        let recentCitations = citations.filter {
            Date().timeIntervalSince($0.timestamp) < 7 * 24 * 3600 // Within 7 days
        }
        let recencyBonus = recentCitations.count == citations.count ? 0.05 : 0.0

        let finalScore = min(1.0, averageScore + diversityBonus + recencyBonus)

        return ConfidenceGrade(fromScore: finalScore)
    }

    /// Group citations by source type
    /// - Parameter citations: Array of citations to group
    /// - Returns: Dictionary mapping source types to citations
    func groupBySourceType(_ citations: [EvidenceCitation]) -> [CitationSourceType: [EvidenceCitation]] {
        Dictionary(grouping: citations) { $0.sourceType }
    }

    /// Get citations grouped and sorted for display
    /// - Parameter claimId: The UUID of the claim
    /// - Returns: Array of grouped citation sections
    func getGroupedCitations(for claimId: UUID) async throws -> [CitationGroup] {
        let citations = try await fetchCitations(for: claimId)
        let grouped = groupBySourceType(citations)

        return grouped.map { sourceType, citations in
            CitationGroup(
                sourceType: sourceType,
                citations: citations.sorted { $0.timestamp > $1.timestamp }
            )
        }
        .sorted { $0.sourceType.reliabilityWeight > $1.sourceType.reliabilityWeight }
    }

    // MARK: - Cache Management

    /// Clear all cached data
    func clearCache() {
        citationsCache.removeAll()
        countCache.removeAll()
    }

    /// Clear cache for a specific claim
    func clearCache(for claimId: UUID) {
        citationsCache.removeValue(forKey: claimId)
        countCache.removeValue(forKey: claimId)
    }

    /// Get cached citations if available
    func getCachedCitations(for claimId: UUID) -> [EvidenceCitation]? {
        citationsCache[claimId]
    }

    // MARK: - Citation Creation (for testing/mock data)

    /// Create a citation from an evidence reference
    /// Used to bridge EvidenceClaim.EvidenceRef to EvidenceCitation
    func createCitation(
        from evidenceRef: EvidenceClaim.EvidenceRef,
        for claimId: UUID
    ) -> EvidenceCitation {
        let sourceType = mapEvidenceRefType(evidenceRef.sourceType)
        let confidence = ConfidenceGrade(fromScore: evidenceRef.sourceType.reliabilityWeight)

        return EvidenceCitation(
            claimId: claimId,
            sourceType: sourceType,
            sourceId: evidenceRef.sourceId,
            sourceTitle: evidenceRef.sourceType.displayName,
            confidence: confidence,
            excerpt: evidenceRef.snippet,
            timestamp: evidenceRef.timestamp
        )
    }

    /// Map EvidenceRef.SourceType to CitationSourceType
    private func mapEvidenceRefType(_ refType: EvidenceClaim.EvidenceRef.SourceType) -> CitationSourceType {
        switch refType {
        case .labResult, .biomarker:
            return .labResult
        case .wearableMetric, .hrvReading:
            return .healthKit
        case .checkIn:
            return .checkIn
        case .exerciseLog, .recoverySession:
            return .workout
        case .sessionNote:
            return .manualEntry
        case .sleepData:
            return .whoop
        }
    }
}

// MARK: - Citation Group

/// A group of citations from the same source type
struct CitationGroup: Identifiable {
    var id: String { "\(sourceType)" }
    let sourceType: CitationSourceType
    let citations: [EvidenceCitation]

    var count: Int { citations.count }

    /// Highest confidence in the group
    var maxConfidence: ConfidenceGrade {
        citations.max { $0.confidence.numericValue < $1.confidence.numericValue }?.confidence ?? .low
    }

    /// Most recent citation timestamp
    var mostRecent: Date? {
        citations.max { $0.timestamp < $1.timestamp }?.timestamp
    }
}

// MARK: - Preview Support

#if DEBUG
extension CitationService {
    /// Create a mock service with sample data for previews
    static var preview: CitationService {
        let service = CitationService()

        // Pre-populate with sample citations
        let sampleClaimId = UUID()
        service.citationsCache[sampleClaimId] = EvidenceCitation.sampleCitations.map { citation in
            EvidenceCitation(
                id: citation.id,
                claimId: sampleClaimId,
                sourceType: citation.sourceType,
                sourceId: citation.sourceId,
                sourceTitle: citation.sourceTitle,
                confidence: citation.confidence,
                excerpt: citation.excerpt,
                timestamp: citation.timestamp,
                url: citation.url
            )
        }
        service.countCache[sampleClaimId] = EvidenceCitation.sampleCitations.count

        return service
    }

    /// Sample claim ID for testing
    static let sampleClaimId = UUID()
}
#endif
