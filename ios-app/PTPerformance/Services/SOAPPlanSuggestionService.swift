//
//  SOAPPlanSuggestionService.swift
//  PTPerformance
//
//  Service for AI-powered SOAP Plan suggestions based on Subjective, Objective, and Assessment data
//

import Foundation
import Supabase

/// Service for generating AI-powered treatment plan suggestions for SOAP notes
///
/// Calls the `ai-soap-plan-suggestions` edge function to generate intelligent
/// plan recommendations based on the subjective, objective, and assessment
/// sections of a SOAP note.
///
/// ## Usage Example
/// ```swift
/// let service = SOAPPlanSuggestionService()
/// let suggestions = try await service.getSuggestions(
///     subjective: "Patient reports knee pain...",
///     objective: "ROM: 90 degrees flexion...",
///     assessment: "Patellofemoral syndrome..."
/// )
/// ```
@MainActor
final class SOAPPlanSuggestionService: ObservableObject {

    // MARK: - Published State

    /// Indicates whether a request is in progress
    @Published private(set) var isLoading = false

    /// Array of suggested plan items
    @Published private(set) var suggestions: [PlanSuggestion] = []

    /// Error message from the last failed request
    @Published var error: String?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let edgeFunctionUrl = "ai-soap-plan-suggestions"

    // MARK: - Public Methods

    /// Gets AI-powered plan suggestions based on SOAP note content
    ///
    /// Analyzes the subjective, objective, and assessment sections to generate
    /// relevant treatment plan recommendations.
    ///
    /// - Parameters:
    ///   - subjective: The subjective section content (patient-reported symptoms, history)
    ///   - objective: The objective section content (measurements, findings)
    ///   - assessment: The assessment section content (clinical impression, diagnosis)
    ///   - patientId: Optional patient ID for context
    ///   - diagnosisCode: Optional ICD-10 code for more targeted suggestions
    ///
    /// - Returns: Array of `PlanSuggestion` items
    ///
    /// - Throws: Error if the edge function fails or returns invalid data
    func getSuggestions(
        subjective: String,
        objective: String,
        assessment: String,
        patientId: String? = nil,
        diagnosisCode: String? = nil
    ) async throws -> [PlanSuggestion] {
        isLoading = true
        error = nil
        suggestions = []

        defer { isLoading = false }

        // Validate input - need at least some content to generate suggestions
        guard !subjective.isEmpty || !objective.isEmpty || !assessment.isEmpty else {
            let errorMessage = "Please enter content in at least one section (Subjective, Objective, or Assessment) to generate suggestions."
            self.error = errorMessage
            throw SOAPPlanSuggestionError.insufficientInput
        }

        // Prepare request body
        var requestBody: [String: Any] = [
            "subjective": subjective,
            "objective": objective,
            "assessment": assessment
        ]

        if let patientId = patientId {
            requestBody["patient_id"] = patientId
        }

        if let diagnosisCode = diagnosisCode {
            requestBody["diagnosis_code"] = diagnosisCode
        }

        // Add therapist context if available
        if let therapistId = supabase.userId {
            requestBody["therapist_id"] = therapistId
        }

        #if DEBUG
        DebugLogger.shared.info("SOAPPlanSuggestion", "Calling \(edgeFunctionUrl) edge function")
        #endif

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let responseData: Data = try await supabase.client.functions.invoke(
                edgeFunctionUrl,
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            #if DEBUG
            DebugLogger.shared.success("SOAPPlanSuggestion", "Edge function returned successfully")
            if let responseString = String(data: responseData, encoding: .utf8) {
                DebugLogger.shared.info("SOAPPlanSuggestion", "Response: \(responseString.prefix(500))...")
            }
            #endif

            // Decode response
            let decoder = JSONDecoder()
            let response = try decoder.decode(SOAPPlanSuggestionResponse.self, from: responseData)

            suggestions = response.suggestions

            #if DEBUG
            DebugLogger.shared.success("SOAPPlanSuggestion", "Parsed \(suggestions.count) suggestions")
            #endif

            return suggestions

        } catch let decodingError as DecodingError {
            #if DEBUG
            DebugLogger.shared.error("SOAPPlanSuggestion", "Decoding error: \(decodingError)")
            #endif
            let errorMessage = "Unable to parse AI suggestions. Please try again."
            self.error = errorMessage
            throw SOAPPlanSuggestionError.decodingFailed(decodingError)

        } catch let functionsError as Supabase.FunctionsError {
            #if DEBUG
            DebugLogger.shared.error("SOAPPlanSuggestion", "Edge function error: \(functionsError)")
            #endif

            switch functionsError {
            case .httpError(let statusCode, _):
                if statusCode == 429 {
                    self.error = "Too many requests. Please wait a moment and try again."
                } else {
                    self.error = "Unable to generate suggestions right now. Please try again later."
                }
            case .relayError:
                self.error = "Connection error. Please check your internet and try again."
            }
            throw functionsError

        } catch {
            #if DEBUG
            DebugLogger.shared.error("SOAPPlanSuggestion", "Unexpected error: \(error)")
            #endif
            self.error = "Something went wrong. Please try again."
            throw error
        }
    }

    /// Clears the current suggestions and error state
    func clearSuggestions() {
        suggestions = []
        error = nil
    }
}

// MARK: - Response Models

/// Response from the ai-soap-plan-suggestions edge function
struct SOAPPlanSuggestionResponse: Codable {
    let success: Bool
    let suggestions: [PlanSuggestion]
    let tokensUsed: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case suggestions
        case tokensUsed = "tokens_used"
    }
}

/// A single plan suggestion with category and rationale
struct PlanSuggestion: Identifiable, Codable, Hashable {
    let id: String
    let category: PlanSuggestionCategory
    let content: String
    let rationale: String
    let priority: PlanSuggestionPriority

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case content
        case rationale
        case priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.category = try container.decode(PlanSuggestionCategory.self, forKey: .category)
        self.content = try container.decode(String.self, forKey: .content)
        self.rationale = try container.decodeIfPresent(String.self, forKey: .rationale) ?? ""
        self.priority = try container.decodeIfPresent(PlanSuggestionPriority.self, forKey: .priority) ?? .medium
    }

    init(id: String = UUID().uuidString, category: PlanSuggestionCategory, content: String, rationale: String, priority: PlanSuggestionPriority = .medium) {
        self.id = id
        self.category = category
        self.content = content
        self.rationale = rationale
        self.priority = priority
    }
}

/// Categories for plan suggestions
enum PlanSuggestionCategory: String, Codable, CaseIterable {
    case frequency = "frequency"
    case goals = "goals"
    case interventions = "interventions"
    case education = "education"
    case precautions = "precautions"
    case followUp = "follow_up"
    case referral = "referral"
    case homeProgram = "home_program"

    var displayName: String {
        switch self {
        case .frequency: return "Frequency"
        case .goals: return "Goals"
        case .interventions: return "Interventions"
        case .education: return "Patient Education"
        case .precautions: return "Precautions"
        case .followUp: return "Follow-up"
        case .referral: return "Referral"
        case .homeProgram: return "Home Program"
        }
    }

    var icon: String {
        switch self {
        case .frequency: return "calendar"
        case .goals: return "target"
        case .interventions: return "hand.raised"
        case .education: return "book"
        case .precautions: return "exclamationmark.triangle"
        case .followUp: return "arrow.clockwise"
        case .referral: return "arrow.right.circle"
        case .homeProgram: return "house"
        }
    }

    var color: String {
        switch self {
        case .frequency: return "blue"
        case .goals: return "green"
        case .interventions: return "purple"
        case .education: return "orange"
        case .precautions: return "red"
        case .followUp: return "teal"
        case .referral: return "indigo"
        case .homeProgram: return "brown"
        }
    }
}

/// Priority levels for plan suggestions
enum PlanSuggestionPriority: String, Codable {
    case high
    case medium
    case low

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Errors

/// Errors specific to SOAP plan suggestion service
enum SOAPPlanSuggestionError: LocalizedError {
    case insufficientInput
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .insufficientInput:
            return "Please enter content in at least one section to generate suggestions."
        case .decodingFailed:
            return "Unable to parse the AI response. Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
