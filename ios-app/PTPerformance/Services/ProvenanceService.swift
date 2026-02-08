//
//  ProvenanceService.swift
//  PTPerformance
//
//  Evidence Provenance Service for X2Index
//  Manages creation, querying, and validation of evidence claims
//  Ensures >=95% AI citation coverage
//
//  X2Index Phase 2 - M6: AI Provenance and Evidence Linking
//  - Links claims to daily_readiness records
//  - Links claims to exercise_logs
//  - Links claims to check-in responses
//  - Calculates confidence based on data quality/recency
//  - Tracks abstentions and uncertainty
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
    case sourceNotFound
    case insufficientData

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
        case .sourceNotFound:
            return "The evidence source could not be found"
        case .insufficientData:
            return "Insufficient data to generate this claim"
        }
    }
}

// MARK: - Evidence Source Model

/// Detailed evidence source with full data context
struct EvidenceSource: Identifiable, Equatable {
    let id: UUID
    let sourceType: EvidenceClaim.EvidenceRef.SourceType
    let sourceId: String
    let timestamp: Date
    let snippet: String
    let dataValue: String?
    let rawData: SourceData?
    let qualityScore: Double  // 0.0-1.0
    let recencyScore: Double  // 0.0-1.0 based on age

    /// Raw source data depending on type
    enum SourceData: Equatable {
        case dailyReadiness(DailyReadinessData)
        case exerciseLog(ExerciseLogData)
        case checkIn(CheckInData)
        case hrvReading(HRVData)
        case sleepData(SleepDataRecord)
        case labResult(LabResultData)
        case generic([String: String])

        static func == (lhs: SourceData, rhs: SourceData) -> Bool {
            switch (lhs, rhs) {
            case (.dailyReadiness(let l), .dailyReadiness(let r)): return l.id == r.id
            case (.exerciseLog(let l), .exerciseLog(let r)): return l.id == r.id
            case (.checkIn(let l), .checkIn(let r)): return l.id == r.id
            case (.hrvReading(let l), .hrvReading(let r)): return l.id == r.id
            case (.sleepData(let l), .sleepData(let r)): return l.id == r.id
            case (.labResult(let l), .labResult(let r)): return l.id == r.id
            case (.generic(let l), .generic(let r)): return l == r
            default: return false
            }
        }
    }

    /// Data structures for different source types
    struct DailyReadinessData: Identifiable {
        let id: UUID
        let date: Date
        let sleepHours: Double?
        let sorenessLevel: Int?
        let energyLevel: Int?
        let stressLevel: Int?
        let readinessScore: Double?
    }

    struct ExerciseLogData: Identifiable {
        let id: UUID
        let exerciseName: String
        let sets: Int
        let reps: Int?
        let weight: Double?
        let rpe: Int?
        let completedAt: Date
    }

    struct CheckInData: Identifiable {
        let id: UUID
        let date: Date
        let sleepQuality: Int
        let soreness: Int
        let stress: Int
        let energy: Int
        let mood: Int
        let painScore: Int?
        let freeText: String?
    }

    struct HRVData: Identifiable {
        let id: UUID
        let timestamp: Date
        let hrvValue: Double
        let restingHeartRate: Double?
        let source: String  // e.g., "whoop", "apple_watch"
    }

    struct SleepDataRecord: Identifiable {
        let id: UUID
        let date: Date
        let totalSleep: Double  // hours
        let deepSleep: Double?  // hours
        let remSleep: Double?   // hours
        let sleepEfficiency: Double?  // 0-100%
    }

    struct LabResultData: Identifiable {
        let id: UUID
        let testName: String
        let value: Double
        let unit: String
        let referenceRange: String?
        let collectedAt: Date
        let status: LabStatus

        enum LabStatus: String {
            case normal
            case low
            case high
            case critical
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

    // MARK: - Evidence Source Linking (M6)

    /// Get detailed evidence sources for a claim
    /// Links to daily_readiness, exercise_logs, check-in responses
    /// - Parameter claimId: The claim's UUID
    /// - Returns: Array of EvidenceSource with full data context
    func getClaimSources(claimId: UUID) async -> [EvidenceSource] {
        // Get evidence refs from claim
        guard let claim = claimsCache[claimId] else {
            // Try to fetch from network
            if let refs = try? await getEvidenceForClaim(claimId: claimId) {
                return await fetchSourceData(for: refs)
            }
            return []
        }

        return await fetchSourceData(for: claim.evidenceRefs)
    }

    /// Fetch full source data for evidence references
    private func fetchSourceData(for refs: [EvidenceClaim.EvidenceRef]) async -> [EvidenceSource] {
        var sources: [EvidenceSource] = []

        for ref in refs {
            let recencyScore = calculateRecencyScore(for: ref.timestamp)
            let qualityScore = ref.sourceType.reliabilityWeight

            var rawData: EvidenceSource.SourceData? = nil

            // Fetch source-specific data based on type
            switch ref.sourceType {
            case .checkIn:
                if let checkInData = await fetchCheckInData(sourceId: ref.sourceId) {
                    rawData = .checkIn(checkInData)
                }
            case .exerciseLog:
                if let exerciseData = await fetchExerciseLogData(sourceId: ref.sourceId) {
                    rawData = .exerciseLog(exerciseData)
                }
            case .hrvReading:
                if let hrvData = await fetchHRVData(sourceId: ref.sourceId) {
                    rawData = .hrvReading(hrvData)
                }
            case .sleepData:
                if let sleepData = await fetchSleepData(sourceId: ref.sourceId) {
                    rawData = .sleepData(sleepData)
                }
            case .labResult, .biomarker:
                if let labData = await fetchLabData(sourceId: ref.sourceId) {
                    rawData = .labResult(labData)
                }
            default:
                // For other types, use generic data
                rawData = .generic(["snippet": ref.snippet, "value": ref.dataValue ?? ""])
            }

            let source = EvidenceSource(
                id: ref.id,
                sourceType: ref.sourceType,
                sourceId: ref.sourceId,
                timestamp: ref.timestamp,
                snippet: ref.snippet,
                dataValue: ref.dataValue,
                rawData: rawData,
                qualityScore: qualityScore,
                recencyScore: recencyScore
            )
            sources.append(source)
        }

        return sources.sorted { $0.timestamp > $1.timestamp }
    }

    /// Fetch check-in data from database
    private func fetchCheckInData(sourceId: String) async -> EvidenceSource.CheckInData? {
        guard let uuid = UUID(uuidString: sourceId) else { return nil }

        do {
            let response = try await client.client
                .from("daily_check_ins")
                .select()
                .eq("id", value: sourceId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let checkIn = try decoder.decode(DailyCheckIn.self, from: response.data)

            return EvidenceSource.CheckInData(
                id: checkIn.id,
                date: checkIn.date,
                sleepQuality: checkIn.sleepQuality,
                soreness: checkIn.soreness,
                stress: checkIn.stress,
                energy: checkIn.energy,
                mood: checkIn.mood,
                painScore: checkIn.painScore,
                freeText: checkIn.freeText
            )
        } catch {
            DebugLogger.shared.log("Failed to fetch check-in data: \(error)", level: .warning)
            return nil
        }
    }

    /// Fetch exercise log data from database
    private func fetchExerciseLogData(sourceId: String) async -> EvidenceSource.ExerciseLogData? {
        do {
            let response = try await client.client
                .from("exercise_logs")
                .select()
                .eq("id", value: sourceId)
                .single()
                .execute()

            // Parse basic exercise log structure
            if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                let id = UUID(uuidString: json["id"] as? String ?? "") ?? UUID()
                let exerciseName = json["exercise_name"] as? String ?? "Unknown Exercise"
                let sets = json["sets"] as? Int ?? 0
                let reps = json["reps"] as? Int
                let weight = json["weight"] as? Double
                let rpe = json["rpe"] as? Int
                let completedAt = Date() // Parse from json if available

                return EvidenceSource.ExerciseLogData(
                    id: id,
                    exerciseName: exerciseName,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    rpe: rpe,
                    completedAt: completedAt
                )
            }
        } catch {
            DebugLogger.shared.log("Failed to fetch exercise log: \(error)", level: .warning)
        }
        return nil
    }

    /// Fetch HRV data
    private func fetchHRVData(sourceId: String) async -> EvidenceSource.HRVData? {
        do {
            let response = try await client.client
                .from("hrv_readings")
                .select()
                .eq("id", value: sourceId)
                .single()
                .execute()

            if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                let id = UUID(uuidString: json["id"] as? String ?? "") ?? UUID()
                let hrvValue = json["hrv_value"] as? Double ?? 0
                let restingHR = json["resting_heart_rate"] as? Double
                let source = json["source"] as? String ?? "unknown"

                return EvidenceSource.HRVData(
                    id: id,
                    timestamp: Date(),
                    hrvValue: hrvValue,
                    restingHeartRate: restingHR,
                    source: source
                )
            }
        } catch {
            DebugLogger.shared.log("Failed to fetch HRV data: \(error)", level: .warning)
        }
        return nil
    }

    /// Fetch sleep data
    private func fetchSleepData(sourceId: String) async -> EvidenceSource.SleepDataRecord? {
        do {
            let response = try await client.client
                .from("sleep_data")
                .select()
                .eq("id", value: sourceId)
                .single()
                .execute()

            if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                let id = UUID(uuidString: json["id"] as? String ?? "") ?? UUID()
                let totalSleep = json["total_sleep_hours"] as? Double ?? 0
                let deepSleep = json["deep_sleep_hours"] as? Double
                let remSleep = json["rem_sleep_hours"] as? Double
                let efficiency = json["sleep_efficiency"] as? Double

                return EvidenceSource.SleepDataRecord(
                    id: id,
                    date: Date(),
                    totalSleep: totalSleep,
                    deepSleep: deepSleep,
                    remSleep: remSleep,
                    sleepEfficiency: efficiency
                )
            }
        } catch {
            DebugLogger.shared.log("Failed to fetch sleep data: \(error)", level: .warning)
        }
        return nil
    }

    /// Fetch lab result data
    private func fetchLabData(sourceId: String) async -> EvidenceSource.LabResultData? {
        do {
            let response = try await client.client
                .from("lab_results")
                .select()
                .eq("id", value: sourceId)
                .single()
                .execute()

            if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                let id = UUID(uuidString: json["id"] as? String ?? "") ?? UUID()
                let testName = json["test_name"] as? String ?? "Unknown Test"
                let value = json["value"] as? Double ?? 0
                let unit = json["unit"] as? String ?? ""
                let refRange = json["reference_range"] as? String
                let statusStr = json["status"] as? String ?? "normal"

                let status: EvidenceSource.LabResultData.LabStatus
                switch statusStr {
                case "low": status = .low
                case "high": status = .high
                case "critical": status = .critical
                default: status = .normal
                }

                return EvidenceSource.LabResultData(
                    id: id,
                    testName: testName,
                    value: value,
                    unit: unit,
                    referenceRange: refRange,
                    collectedAt: Date(),
                    status: status
                )
            }
        } catch {
            DebugLogger.shared.log("Failed to fetch lab data: \(error)", level: .warning)
        }
        return nil
    }

    // MARK: - Confidence and Abstention (M6)

    /// Calculate recency score based on data age
    /// More recent data gets higher scores
    func calculateRecencyScore(for timestamp: Date) -> Double {
        let now = Date()
        let ageInDays = now.timeIntervalSince(timestamp) / (24 * 3600)

        switch ageInDays {
        case 0..<1:
            return 1.0       // Today: full score
        case 1..<3:
            return 0.9       // 1-2 days: very recent
        case 3..<7:
            return 0.75      // 3-6 days: recent
        case 7..<14:
            return 0.5       // 1-2 weeks: moderate
        case 14..<30:
            return 0.3       // 2-4 weeks: older
        default:
            return 0.1       // 30+ days: stale
        }
    }

    /// Calculate comprehensive confidence score including data quality and recency
    func calculateDetailedConfidence(from sources: [EvidenceSource]) -> ConfidenceBreakdown {
        guard !sources.isEmpty else {
            return ConfidenceBreakdown(
                overallScore: 0.0,
                qualityScore: 0.0,
                recencyScore: 0.0,
                diversityScore: 0.0,
                sourceCount: 0,
                recommendation: .abstain
            )
        }

        // Quality score: average of source quality scores
        let qualityScore = sources.reduce(0.0) { $0 + $1.qualityScore } / Double(sources.count)

        // Recency score: average of source recency scores
        let recencyScore = sources.reduce(0.0) { $0 + $1.recencyScore } / Double(sources.count)

        // Diversity score: bonus for multiple source types
        let uniqueTypes = Set(sources.map { $0.sourceType })
        let diversityScore = min(1.0, Double(uniqueTypes.count) * 0.25)

        // Calculate overall confidence
        let baseScore = qualityScore * 0.4 + recencyScore * 0.4 + diversityScore * 0.2

        // Apply source count multiplier
        let countMultiplier: Double
        switch sources.count {
        case 1: countMultiplier = 0.8
        case 2: countMultiplier = 0.9
        case 3: countMultiplier = 1.0
        default: countMultiplier = 1.0 + min(0.1, Double(sources.count - 3) * 0.02)
        }

        let overallScore = min(1.0, baseScore * countMultiplier)

        // Determine recommendation
        let recommendation: ConfidenceRecommendation
        if overallScore >= 0.85 {
            recommendation = .highConfidence
        } else if overallScore >= 0.7 {
            recommendation = .proceed
        } else if overallScore >= 0.5 {
            recommendation = .proceedWithCaution
        } else {
            recommendation = .abstain
        }

        return ConfidenceBreakdown(
            overallScore: overallScore,
            qualityScore: qualityScore,
            recencyScore: recencyScore,
            diversityScore: diversityScore,
            sourceCount: sources.count,
            recommendation: recommendation
        )
    }

    /// Determine if AI should abstain from making a claim
    /// Based on confidence level and claim type requirements
    /// - Parameters:
    ///   - confidence: The calculated confidence score
    ///   - claimType: The type of claim being generated
    /// - Returns: True if AI should abstain (not make the claim)
    func shouldAbstain(confidence: Double, claimType: EvidenceClaim.ClaimType) -> Bool {
        // Different claim types have different confidence thresholds
        let threshold: Double
        switch claimType {
        case .safetyWarning:
            // Safety warnings need high confidence - abstain below 0.8
            threshold = 0.8
        case .riskAlert:
            // Risk alerts need high confidence - abstain below 0.75
            threshold = 0.75
        case .biomarkerChange:
            // Biomarker claims need moderate-high confidence - abstain below 0.7
            threshold = 0.7
        case .trainingRecommendation:
            // Training recommendations need moderate confidence - abstain below 0.6
            threshold = 0.6
        case .readinessTrend, .recoveryInsight:
            // Trends and insights can proceed with lower confidence - abstain below 0.5
            threshold = 0.5
        case .nutritionInsight:
            // Nutrition insights can be more speculative - abstain below 0.45
            threshold = 0.45
        }

        return confidence < threshold
    }

    /// Get abstention reason for display
    func getAbstentionReason(confidence: Double, claimType: EvidenceClaim.ClaimType) -> String {
        if confidence < 0.3 {
            return "Insufficient data available to make this assessment"
        } else if confidence < 0.5 {
            return "Not enough recent data to make a reliable claim"
        } else {
            return "Additional data needed for a \(claimType.displayName.lowercased()) claim"
        }
    }

    // MARK: - Claim Linking Helpers

    /// Create evidence ref from daily readiness data
    func createEvidenceRef(from readiness: DailyReadiness) -> EvidenceClaim.EvidenceRef {
        var snippet = "Readiness: \(readiness.scoreText)"
        if let sleep = readiness.sleepHours {
            snippet += ", Sleep: \(String(format: "%.1f", sleep))h"
        }
        if let energy = readiness.energyLevel {
            snippet += ", Energy: \(energy)/10"
        }

        return EvidenceClaim.EvidenceRef(
            sourceType: .wearableMetric,
            sourceId: readiness.id.uuidString,
            timestamp: readiness.date,
            snippet: snippet,
            dataValue: readiness.readinessScore.map { String(format: "%.0f", $0) }
        )
    }

    /// Create evidence ref from check-in data
    func createEvidenceRef(from checkIn: DailyCheckIn) -> EvidenceClaim.EvidenceRef {
        var snippet = "Check-in: Energy \(checkIn.energy)/10, Stress \(checkIn.stress)/10"
        if let pain = checkIn.painScore, pain > 0 {
            snippet += ", Pain \(pain)/10"
        }
        if let note = checkIn.freeText, !note.isEmpty {
            snippet += " - \"\(note.prefix(50))...\""
        }

        return EvidenceClaim.EvidenceRef(
            sourceType: .checkIn,
            sourceId: checkIn.id.uuidString,
            timestamp: checkIn.date,
            snippet: snippet,
            dataValue: String(format: "%.0f", checkIn.estimatedReadiness)
        )
    }

    // MARK: - Feedback Tracking

    /// Record user feedback on a claim's helpfulness
    func recordFeedback(
        claimId: UUID,
        isHelpful: Bool,
        feedbackText: String? = nil
    ) async throws {
        let feedbackData: [String: AnyEncodable] = [
            "claim_id": AnyEncodable(claimId.uuidString),
            "is_helpful": AnyEncodable(isHelpful),
            "feedback_text": AnyEncodable(feedbackText as Any),
            "submitted_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        do {
            try await client.client
                .from("claim_feedback")
                .insert(feedbackData)
                .execute()

            DebugLogger.shared.log(
                "Recorded feedback for claim \(claimId): helpful=\(isHelpful)",
                level: .success
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "ProvenanceService.recordFeedback")
            throw ProvenanceError.networkError(error)
        }
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

/// Confidence breakdown with detailed scoring
struct ConfidenceBreakdown {
    let overallScore: Double
    let qualityScore: Double
    let recencyScore: Double
    let diversityScore: Double
    let sourceCount: Int
    let recommendation: ConfidenceRecommendation

    /// Formatted overall score as percentage
    var overallPercentage: String {
        String(format: "%.0f%%", overallScore * 100)
    }

    /// Human-readable confidence level
    var confidenceLevel: String {
        switch overallScore {
        case 0.85...1.0: return "High"
        case 0.7..<0.85: return "Good"
        case 0.5..<0.7: return "Moderate"
        case 0.3..<0.5: return "Low"
        default: return "Insufficient"
        }
    }
}

/// Recommendation based on confidence analysis
enum ConfidenceRecommendation: String {
    case highConfidence = "high_confidence"
    case proceed = "proceed"
    case proceedWithCaution = "proceed_with_caution"
    case abstain = "abstain"

    var displayMessage: String {
        switch self {
        case .highConfidence:
            return "Sufficient evidence supports this claim"
        case .proceed:
            return "Evidence supports this claim with minor uncertainty"
        case .proceedWithCaution:
            return "Limited evidence - claim may need verification"
        case .abstain:
            return "Insufficient evidence to make this claim"
        }
    }

    var shouldShowClaim: Bool {
        self != .abstain
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
