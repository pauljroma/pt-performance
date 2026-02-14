//
//  SupplementInteractionService.swift
//  PTPerformance
//
//  ACP-441: Supplement Interaction Checker Service
//  Calls the supplement-interaction-checker Edge Function to analyze
//  supplement-supplement and supplement-medication interactions,
//  safety warnings, and timing recommendations.
//

import Foundation
import Supabase

// MARK: - Models

/// Severity level for supplement interactions
enum InteractionSeverity: String, Codable, CaseIterable, Comparable {
    case critical
    case major
    case moderate
    case minor

    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .major: return "Major"
        case .moderate: return "Moderate"
        case .minor: return "Minor"
        }
    }

    /// Ordering for severity comparison (critical > major > moderate > minor)
    private var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .major: return 1
        case .moderate: return 2
        case .minor: return 3
        }
    }

    static func < (lhs: InteractionSeverity, rhs: InteractionSeverity) -> Bool {
        lhs.sortOrder > rhs.sortOrder
    }
}

/// Type of interaction between supplements/medications
enum SupplementInteractionType: String, Codable {
    case absorption
    case efficacy
    case toxicity
    case bleeding
    case metabolic
    case other

    var displayName: String {
        switch self {
        case .absorption: return "Absorption"
        case .efficacy: return "Efficacy"
        case .toxicity: return "Toxicity"
        case .bleeding: return "Bleeding Risk"
        case .metabolic: return "Metabolic"
        case .other: return "Other"
        }
    }
}

/// Overall safety rating for a supplement stack
enum SafetyRating: String, Codable {
    case safe
    case caution
    case warning
    case danger

    var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .warning: return "Warning"
        case .danger: return "Danger"
        }
    }
}

/// A single interaction between two supplements or a supplement and a medication
struct SupplementInteraction: Identifiable, Codable, Equatable {

    /// Type alias so existing code can reference `SupplementInteraction.Severity`
    typealias Severity = InteractionSeverity

    let id: UUID
    let supplement1: String
    let supplement2: String
    let interactionType: SupplementInteractionType
    let severity: InteractionSeverity
    let description: String
    let recommendation: String

    enum CodingKeys: String, CodingKey {
        case item1, item2, type, severity, description, recommendation
    }

    init(
        id: UUID = UUID(),
        supplement1: String,
        supplement2: String,
        interactionType: SupplementInteractionType,
        severity: InteractionSeverity,
        description: String,
        recommendation: String
    ) {
        self.id = id
        self.supplement1 = supplement1
        self.supplement2 = supplement2
        self.interactionType = interactionType
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.supplement1 = try container.decode(String.self, forKey: .item1)
        self.supplement2 = try container.decode(String.self, forKey: .item2)
        self.interactionType = try container.decode(SupplementInteractionType.self, forKey: .type)
        self.severity = try container.decode(InteractionSeverity.self, forKey: .severity)
        self.description = try container.decode(String.self, forKey: .description)
        self.recommendation = try container.decode(String.self, forKey: .recommendation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(supplement1, forKey: .item1)
        try container.encode(supplement2, forKey: .item2)
        try container.encode(interactionType, forKey: .type)
        try container.encode(severity, forKey: .severity)
        try container.encode(description, forKey: .description)
        try container.encode(recommendation, forKey: .recommendation)
    }

    static func == (lhs: SupplementInteraction, rhs: SupplementInteraction) -> Bool {
        lhs.id == rhs.id
    }
}

/// A safety warning for an individual supplement
struct SafetyWarning: Identifiable, Codable, Equatable {
    let id: UUID
    let supplement: String
    let warningType: String
    let description: String
    let recommendation: String

    enum CodingKeys: String, CodingKey {
        case supplement
        case warningType = "warning_type"
        case description
        case recommendation
    }

    init(
        id: UUID = UUID(),
        supplement: String,
        warningType: String,
        description: String,
        recommendation: String
    ) {
        self.id = id
        self.supplement = supplement
        self.warningType = warningType
        self.description = description
        self.recommendation = recommendation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.supplement = try container.decode(String.self, forKey: .supplement)
        self.warningType = try container.decode(String.self, forKey: .warningType)
        self.description = try container.decode(String.self, forKey: .description)
        self.recommendation = try container.decode(String.self, forKey: .recommendation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(supplement, forKey: .supplement)
        try container.encode(warningType, forKey: .warningType)
        try container.encode(description, forKey: .description)
        try container.encode(recommendation, forKey: .recommendation)
    }

    static func == (lhs: SafetyWarning, rhs: SafetyWarning) -> Bool {
        lhs.id == rhs.id
    }
}

/// Complete result from an interaction check
struct InteractionCheckResult: Equatable {
    let interactions: [SupplementInteraction]
    let safetyWarnings: [SafetyWarning]
    let timingRecommendations: [String]
    let overallRating: SafetyRating
    let summary: String
    let disclaimer: String
}

// MARK: - Edge Function Request/Response Models

/// Request payload sent to the supplement-interaction-checker Edge Function
private struct InteractionCheckRequest: Encodable {
    let supplements: [SupplementItem]
    let medications: [MedicationItem]?

    struct SupplementItem: Encodable {
        let name: String
        let dosage: String?
    }

    struct MedicationItem: Encodable {
        let name: String
        let dosage: String?
        let category: String?
    }
}

/// Response from the supplement-interaction-checker Edge Function
private struct InteractionCheckResponse: Decodable {
    let success: Bool
    let overallSafety: String
    let interactions: [SupplementInteraction]
    let safetyWarnings: [SafetyWarning]
    let timingRecommendations: [String]
    let summary: String
    let disclaimer: String
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case overallSafety = "overall_safety"
        case interactions
        case safetyWarnings = "safety_warnings"
        case timingRecommendations = "timing_recommendations"
        case summary
        case disclaimer
        case error
    }
}

// MARK: - Cache Entry

/// Cached interaction check result with expiration
private struct CachedResult {
    let result: InteractionCheckResult
    let timestamp: Date

    /// Cache duration: 5 minutes
    static let cacheDuration: TimeInterval = 300

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > Self.cacheDuration
    }
}

// MARK: - SupplementInteractionService

/// Service for checking supplement and medication interactions via the
/// supplement-interaction-checker Edge Function.
///
/// Analyzes user supplement stacks for:
/// - Supplement-supplement interactions (e.g., iron + calcium absorption conflict)
/// - Supplement-medication interactions (e.g., blood thinners + omega-3)
/// - Individual supplement safety warnings (dosage, duration, condition)
/// - Optimal timing recommendations
///
/// ## Usage
/// ```swift
/// let service = SupplementInteractionService.shared
/// let result = try await service.checkInteractions(
///     supplements: ["Iron", "Calcium", "Vitamin D"],
///     medications: ["Warfarin"]
/// )
/// print(result.overallRating) // .danger
/// ```
///
/// ## Thread Safety
/// Marked `@MainActor` for safe UI state updates. All network operations are async.
@MainActor
final class SupplementInteractionService: ObservableObject {

    // MARK: - Singleton

    static let shared = SupplementInteractionService()

    // MARK: - Published Properties

    /// Detected interactions between supplements/medications
    @Published private(set) var interactions: [SupplementInteraction] = []

    /// Safety warnings for individual supplements
    @Published private(set) var safetyWarnings: [SafetyWarning] = []

    /// Overall safety rating for the checked combination
    @Published private(set) var overallSafetyRating: SafetyRating?

    /// Whether an interaction check is currently in progress
    @Published private(set) var isChecking = false

    /// Error message from the last failed check
    @Published var error: String?

    // MARK: - Private Properties

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    /// Cache keyed by a hash of the supplement + medication names
    private var resultCache: [String: CachedResult] = [:]

    // MARK: - Initialization

    private init() {
        self.supabase = PTSupabaseClient.shared
    }

    /// Initializer for dependency injection (testing)
    init(supabase: PTSupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Check interactions for a given set of supplements and optional medications.
    ///
    /// Calls the `supplement-interaction-checker` Edge Function and returns
    /// a complete interaction analysis including severity ratings, safety
    /// warnings, and timing recommendations.
    ///
    /// Results are cached for 5 minutes to avoid repeated network calls
    /// for the same combination.
    ///
    /// - Parameters:
    ///   - supplements: Array of supplement names to check (e.g., ["Iron", "Calcium"])
    ///   - medications: Optional array of medication names (e.g., ["Warfarin", "Lisinopril"])
    /// - Returns: Complete interaction check result
    /// - Throws: Network or decoding errors
    @discardableResult
    func checkInteractions(
        supplements: [String],
        medications: [String]? = nil
    ) async throws -> InteractionCheckResult {
        guard !supplements.isEmpty else {
            throw InteractionServiceError.noSupplements
        }

        // Check cache
        let cacheKey = generateCacheKey(supplements: supplements, medications: medications ?? [])
        if let cached = resultCache[cacheKey], !cached.isExpired {
            logger.info("InteractionService", "Returning cached result for \(supplements.count) supplements")
            applyResult(cached.result)
            return cached.result
        }

        guard !isChecking else {
            logger.warning("InteractionService", "Check already in progress, skipping")
            throw InteractionServiceError.checkInProgress
        }

        isChecking = true
        error = nil
        defer { isChecking = false }

        logger.info("InteractionService", "Checking interactions for \(supplements.count) supplements, \(medications?.count ?? 0) medications")

        // Build request payload
        let request = InteractionCheckRequest(
            supplements: supplements.map { InteractionCheckRequest.SupplementItem(name: $0, dosage: nil) },
            medications: medications?.map { InteractionCheckRequest.MedicationItem(name: $0, dosage: nil, category: nil) }
        )

        // Encode request body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)

        #if DEBUG
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.log("[InteractionService] Edge function request: \(bodyString)", level: .diagnostic)
        }
        #endif

        // Call Edge Function
        let responseDataRaw: Data = try await supabase.client.functions.invoke(
            "supplement-interaction-checker",
            options: FunctionInvokeOptions(body: bodyData)
        ) { data, _ in
            data
        }

        #if DEBUG
        if let responseString = String(data: responseDataRaw, encoding: .utf8) {
            logger.log("[InteractionService] Edge function response: \(responseString)", level: .diagnostic)
        }
        #endif

        // Decode response
        let decoder = JSONDecoder()
        let response = try decoder.decode(InteractionCheckResponse.self, from: responseDataRaw)

        guard response.success else {
            let message = response.error ?? "Unknown interaction check error"
            self.error = message
            errorLogger.logError(
                InteractionServiceError.serverError(message),
                context: "SupplementInteractionService.checkInteractions"
            )
            throw InteractionServiceError.serverError(message)
        }

        // Map response to result
        let safetyRating = SafetyRating(rawValue: response.overallSafety) ?? .safe

        let result = InteractionCheckResult(
            interactions: response.interactions,
            safetyWarnings: response.safetyWarnings,
            timingRecommendations: response.timingRecommendations,
            overallRating: safetyRating,
            summary: response.summary,
            disclaimer: response.disclaimer
        )

        // Cache the result
        resultCache[cacheKey] = CachedResult(result: result, timestamp: Date())

        // Update published properties
        applyResult(result)

        logger.success("InteractionService", "Found \(result.interactions.count) interactions, \(result.safetyWarnings.count) warnings. Rating: \(safetyRating.displayName)")

        return result
    }

    /// Check interactions for a patient's current supplement routine.
    ///
    /// Fetches the patient's active supplements from SupplementService,
    /// then runs an interaction check against the Edge Function.
    ///
    /// - Parameter patientId: The patient UUID whose routine to check
    /// - Returns: Complete interaction check result
    /// - Throws: Network or service errors
    @discardableResult
    func checkCurrentRoutine(patientId: UUID) async throws -> InteractionCheckResult {
        logger.info("InteractionService", "Checking current routine for patient \(patientId.uuidString.prefix(8))...")

        let supplementService = SupplementService.shared

        // Ensure routines are loaded
        if supplementService.routines.isEmpty {
            await supplementService.fetchRoutines()
        }

        // Extract supplement names from active routines
        let supplementNames = supplementService.routines
            .filter { $0.isActive }
            .compactMap { $0.supplement?.name }

        guard !supplementNames.isEmpty else {
            logger.warning("InteractionService", "No active supplements found in routine")
            throw InteractionServiceError.noSupplements
        }

        logger.info("InteractionService", "Found \(supplementNames.count) active supplements in routine")

        return try await checkInteractions(supplements: supplementNames)
    }

    /// Clear all results and reset state
    func clearResults() {
        interactions = []
        safetyWarnings = []
        overallSafetyRating = nil
        error = nil
        logger.info("InteractionService", "Results cleared")
    }

    /// Invalidate the cache, forcing fresh results on next check
    func invalidateCache() {
        resultCache.removeAll()
        logger.info("InteractionService", "Cache invalidated")
    }

    // MARK: - Private Methods

    /// Apply a result to published properties
    private func applyResult(_ result: InteractionCheckResult) {
        interactions = result.interactions
        safetyWarnings = result.safetyWarnings
        overallSafetyRating = result.overallRating
    }

    /// Generate a stable cache key from supplement and medication names
    private func generateCacheKey(supplements: [String], medications: [String]) -> String {
        let sortedSupplements = supplements.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }.sorted()
        let sortedMedications = medications.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }.sorted()
        return "supps:\(sortedSupplements.joined(separator: ","))|meds:\(sortedMedications.joined(separator: ","))"
    }
}

// MARK: - Errors

enum InteractionServiceError: LocalizedError {
    case noSupplements
    case checkInProgress
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noSupplements:
            return "Please add at least one supplement to check for interactions."
        case .checkInProgress:
            return "An interaction check is already in progress."
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Received an invalid response from the interaction checker."
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension SupplementInteractionService {
    /// Create a mock service with sample interaction data for previews
    static var preview: SupplementInteractionService {
        let service = SupplementInteractionService()
        service.interactions = SupplementInteraction.sampleInteractions
        service.safetyWarnings = SafetyWarning.sampleWarnings
        service.overallSafetyRating = .warning
        service.isChecking = false
        return service
    }

    /// Create a mock service in checking state for previews
    static var previewLoading: SupplementInteractionService {
        let service = SupplementInteractionService()
        service.isChecking = true
        return service
    }

    /// Create a mock service with no interactions for previews
    static var previewSafe: SupplementInteractionService {
        let service = SupplementInteractionService()
        service.interactions = []
        service.safetyWarnings = []
        service.overallSafetyRating = .safe
        return service
    }
}

extension SupplementInteraction {
    static let sampleInteractions: [SupplementInteraction] = [
        SupplementInteraction(
            supplement1: "Vitamin K",
            supplement2: "Warfarin",
            interactionType: .efficacy,
            severity: .critical,
            description: "Vitamin K directly counteracts warfarin anticoagulant effect.",
            recommendation: "Maintain consistent Vitamin K intake. Any changes require INR monitoring and possible dose adjustment."
        ),
        SupplementInteraction(
            supplement1: "Zinc",
            supplement2: "Copper",
            interactionType: .absorption,
            severity: .major,
            description: "High zinc intake (>40mg/day) can cause copper deficiency over time.",
            recommendation: "If taking zinc long-term, supplement with copper at 10:1 ratio (e.g., 30mg zinc : 3mg copper)."
        ),
        SupplementInteraction(
            supplement1: "Iron",
            supplement2: "Calcium",
            interactionType: .absorption,
            severity: .moderate,
            description: "Calcium significantly reduces iron absorption by up to 50%.",
            recommendation: "Separate by at least 2 hours. Take iron in the morning, calcium in the evening."
        ),
        SupplementInteraction(
            supplement1: "Vitamin C",
            supplement2: "Iron",
            interactionType: .absorption,
            severity: .minor,
            description: "Vitamin C enhances iron absorption - beneficial combination.",
            recommendation: "Take together for improved iron absorption."
        )
    ]
}

extension SafetyWarning {
    static let sampleWarnings: [SafetyWarning] = [
        SafetyWarning(
            supplement: "Iron",
            warningType: "condition",
            description: "Iron supplementation without deficiency can cause iron overload, oxidative stress, and organ damage.",
            recommendation: "Only supplement if lab tests confirm deficiency. Test ferritin levels regularly."
        ),
        SafetyWarning(
            supplement: "Zinc",
            warningType: "duration",
            description: "Long-term zinc supplementation (>40mg daily) can cause copper deficiency.",
            recommendation: "If taking zinc long-term, add copper at 10:1 ratio or take breaks."
        ),
        SafetyWarning(
            supplement: "Vitamin D",
            warningType: "dosage",
            description: "Vitamin D toxicity can occur at very high doses (>50,000 IU daily for extended periods).",
            recommendation: "Test blood levels every 3-6 months. Target 40-60 ng/mL. Most people need 2000-5000 IU daily."
        )
    ]
}

extension InteractionCheckResult {
    static let sampleResult = InteractionCheckResult(
        interactions: SupplementInteraction.sampleInteractions,
        safetyWarnings: SafetyWarning.sampleWarnings,
        timingRecommendations: [
            "Separate the following supplements by at least 2 hours for optimal absorption:",
            "  - Iron and Calcium",
            "Take fat-soluble vitamins (D, A, E, K) and fish oil with meals containing healthy fats.",
            "Take iron on an empty stomach with Vitamin C for best absorption. Separate from calcium, zinc, and coffee by 2+ hours."
        ],
        overallRating: .warning,
        summary: "1 dangerous interaction(s) found that require immediate attention. 1 major interaction(s) require medical consultation. 1 moderate interaction(s) may need timing adjustments. 3 general safety consideration(s) noted.",
        disclaimer: "This information is for educational purposes only and is not a substitute for professional medical advice."
    )
}
#endif
