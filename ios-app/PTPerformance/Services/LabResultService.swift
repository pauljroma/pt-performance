import Foundation
import Supabase

/// Service for managing lab results
@MainActor
final class LabResultService: ObservableObject {
    static let shared = LabResultService()

    @Published private(set) var labResults: [LabResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isAnalyzing = false
    @Published private(set) var currentAnalysis: LabAnalysis?
    @Published private(set) var uploadProgress: Double = 0
    @Published private(set) var isUploading = false

    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - CRUD Operations

    func fetchLabResults() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let results: [LabResult] = try await supabase.client
                .from("lab_results")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("test_date", ascending: false)
                .execute()
                .value

            self.labResults = results
        } catch {
            self.error = error
            DebugLogger.shared.error("LabResultService", "Failed to fetch lab results: \(error)")
        }

        isLoading = false
    }

    func addLabResult(_ result: LabResult) async throws {
        try await supabase.client
            .from("lab_results")
            .insert(result)
            .execute()

        await fetchLabResults()
    }

    func deleteLabResult(_ id: UUID) async throws {
        try await supabase.client
            .from("lab_results")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        await fetchLabResults()
    }

    // MARK: - AI Analysis

    /// Analyzes a lab result using the AI edge function
    ///
    /// Calls the `ai-lab-analysis` edge function to generate comprehensive
    /// analysis of biomarkers including interpretations, recommendations,
    /// and correlations with training/sleep data.
    ///
    /// - Parameter result: The lab result to analyze
    /// - Returns: LabAnalysis containing AI-generated insights
    /// - Throws: Error if the edge function call fails
    func analyzeLabResult(_ result: LabResult) async throws -> LabAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        guard let patientId = try await getPatientId() else {
            throw LabAnalysisError.noPatientId
        }

        // Prepare request for edge function
        let request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "lab_result_id": result.id.uuidString
        ]

        DebugLogger.shared.info("LabResultService", "Calling ai-lab-analysis edge function")
        DebugLogger.shared.info("LabResultService", "Request: \(request)")

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let responseData: Data = try await supabase.client.functions.invoke(
                "ai-lab-analysis",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("LabResultService", "Edge function returned successfully")

            // Log raw response for debugging
            if let responseString = String(data: responseData, encoding: .utf8) {
                DebugLogger.shared.info("LabResultService", "Response: \(responseString.prefix(500))...")
            }

            // First check for error response
            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(LabAnalysisErrorResponse.self, from: responseData),
               !errorResponse.error.isEmpty {
                DebugLogger.shared.warning("LabResultService", "Analysis error: \(errorResponse.error)")
                throw LabAnalysisError.analysisError(errorResponse.error)
            }

            // Decode successful response
            let analysis = try decoder.decode(LabAnalysis.self, from: responseData)

            DebugLogger.shared.success("LabResultService", "Parsed analysis with \(analysis.biomarkerAnalyses.count) biomarkers")
            DebugLogger.shared.info("LabResultService", "Health score: \(analysis.overallHealthScore)")
            DebugLogger.shared.info("LabResultService", "Recommendations: \(analysis.recommendations.count)")
            DebugLogger.shared.info("LabResultService", "Cached: \(analysis.cached)")

            currentAnalysis = analysis
            return analysis

        } catch let functionsError as Supabase.FunctionsError {
            switch functionsError {
            case .httpError(let statusCode, let data):
                DebugLogger.shared.error("LabResultService", "Edge function HTTP error: \(statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    DebugLogger.shared.error("LabResultService", "Error body: \(errorString)")
                }
                throw LabAnalysisError.httpError(statusCode: statusCode)
            case .relayError:
                DebugLogger.shared.error("LabResultService", "Edge function relay error")
                throw LabAnalysisError.networkError
            }
        } catch let error as LabAnalysisError {
            throw error
        } catch {
            DebugLogger.shared.error("LabResultService", "Unexpected error: \(error)")
            throw LabAnalysisError.decodingError(error.localizedDescription)
        }
    }

    /// Fetches historical biomarker data for trend visualization
    ///
    /// - Parameters:
    ///   - biomarkerType: The type of biomarker to fetch history for
    ///   - limit: Maximum number of data points to return
    /// - Returns: Array of BiomarkerTrendPoint for charting
    func fetchBiomarkerHistory(biomarkerType: String, limit: Int = 10) async throws -> [BiomarkerTrendPoint] {
        guard let patientId = try await getPatientId() else {
            return []
        }

        struct BiomarkerValueRow: Decodable {
            let id: UUID
            let value: Double
            let unit: String
            let labResult: LabResultRow

            enum CodingKeys: String, CodingKey {
                case id, value, unit
                case labResult = "lab_results"
            }
        }

        struct LabResultRow: Decodable {
            let testDate: Date

            enum CodingKeys: String, CodingKey {
                case testDate = "test_date"
            }
        }

        // Fetch biomarker values with their lab result dates
        let values: [BiomarkerValueRow] = try await supabase.client
            .from("biomarker_values")
            .select("id, value, unit, lab_results!inner(test_date)")
            .eq("biomarker_type", value: biomarkerType)
            .eq("lab_results.patient_id", value: patientId.uuidString)
            .order("lab_results.test_date", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Fetch reference ranges for this biomarker
        struct ReferenceRange: Decodable {
            let optimalLow: Double?
            let optimalHigh: Double?
            let normalLow: Double?
            let normalHigh: Double?

            enum CodingKeys: String, CodingKey {
                case optimalLow = "optimal_low"
                case optimalHigh = "optimal_high"
                case normalLow = "normal_low"
                case normalHigh = "normal_high"
            }
        }

        let references: [ReferenceRange] = try await supabase.client
            .from("biomarker_reference_ranges")
            .select("optimal_low, optimal_high, normal_low, normal_high")
            .eq("biomarker_type", value: biomarkerType)
            .limit(1)
            .execute()
            .value

        let reference = references.first

        // Convert to trend points
        return values.map { bv in
            BiomarkerTrendPoint(
                id: bv.id,
                date: bv.labResult.testDate,
                value: bv.value,
                biomarkerType: biomarkerType,
                unit: bv.unit,
                optimalLow: reference?.optimalLow,
                optimalHigh: reference?.optimalHigh,
                normalLow: reference?.normalLow,
                normalHigh: reference?.normalHigh
            )
        }.reversed() // Oldest first for charting
    }

    /// Clears the current analysis
    func clearAnalysis() {
        currentAnalysis = nil
    }

    // MARK: - PDF Upload & Parsing

    /// Upload and parse a lab PDF using Claude Vision
    /// - Parameter pdfData: The PDF file data
    /// - Returns: ParsedLabResult containing extracted biomarkers
    func uploadLabPDF(_ pdfData: Data) async throws -> ParsedLabResult {
        isUploading = true
        uploadProgress = 0.1
        error = nil

        defer {
            isUploading = false
            uploadProgress = 0
        }

        // Convert PDF to base64
        let base64String = pdfData.base64EncodedString()
        uploadProgress = 0.3

        DebugLogger.shared.info("LabResultService", "Uploading PDF for parsing, size: \(pdfData.count) bytes")

        // Call edge function
        let requestBody: [String: Any] = [
            "pdf_base64": base64String
        ]

        uploadProgress = 0.5

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let responseData: Data = try await supabase.client.functions.invoke(
                "parse-lab-pdf",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            uploadProgress = 0.9

            let decoder = JSONDecoder()
            let response = try decoder.decode(ParseLabPDFResponse.self, from: responseData)

            guard response.success else {
                let errorMessage = response.error ?? "Failed to parse PDF"
                DebugLogger.shared.error("LabResultService", "PDF parsing failed: \(errorMessage)")
                throw LabResultError.parsingFailed(errorMessage)
            }

            guard let parsedResult = response.toParsedLabResult() else {
                throw LabResultError.parsingFailed("Could not convert response to parsed result")
            }

            DebugLogger.shared.info("LabResultService", "Successfully parsed \(parsedResult.biomarkers.count) biomarkers")
            uploadProgress = 1.0

            return parsedResult

        } catch let decodingError as DecodingError {
            DebugLogger.shared.error("LabResultService", "Decoding error: \(decodingError)")
            throw LabResultError.parsingFailed("Failed to decode response: \(decodingError.localizedDescription)")
        } catch let labError as LabResultError {
            throw labError
        } catch {
            DebugLogger.shared.error("LabResultService", "Upload error: \(error)")
            throw LabResultError.uploadFailed(error.localizedDescription)
        }
    }

    /// Save parsed lab result to database
    /// - Parameters:
    ///   - parsedResult: The parsed lab result with biomarkers
    ///   - testType: The type of lab test
    ///   - testDate: The date of the test
    /// - Returns: The saved LabResult
    func saveParsedLabResult(
        _ parsedResult: ParsedLabResult,
        testType: LabTestType,
        testDate: Date
    ) async throws -> LabResult {
        guard let patientId = try await getPatientId() else {
            throw LabResultError.noPatientFound
        }

        // Filter to only selected biomarkers and convert to LabMarkers
        let selectedMarkers = parsedResult.biomarkers
            .filter { $0.isSelected }
            .map { $0.toLabMarker() }

        guard !selectedMarkers.isEmpty else {
            throw LabResultError.noBiomarkersSelected
        }

        let labResult = LabResult(
            id: UUID(),
            patientId: patientId,
            testDate: testDate,
            testType: testType,
            results: selectedMarkers,
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await supabase.client
            .from("lab_results")
            .insert(labResult)
            .execute()

        DebugLogger.shared.info("LabResultService", "Saved lab result with \(selectedMarkers.count) biomarkers")

        await fetchLabResults()
        return labResult
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

        struct PatientRow: Decodable {
            let id: UUID
        }

        let patients: [PatientRow] = try await supabase.client
            .from("patients")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return patients.first?.id
    }
}

// MARK: - Lab Analysis Errors

/// Errors that can occur during lab analysis
enum LabAnalysisError: LocalizedError {
    case noPatientId
    case analysisError(String)
    case httpError(statusCode: Int)
    case networkError
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "Unable to identify patient. Please ensure you're logged in."
        case .analysisError(let message):
            return message
        case .httpError(let code):
            return "Server error (code \(code)). Please try again later."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .decodingError(let message):
            return "Failed to process analysis response: \(message)"
        }
    }
}

// MARK: - Lab Result Errors

/// Errors that can occur during lab result operations
enum LabResultError: LocalizedError {
    case parsingFailed(String)
    case uploadFailed(String)
    case noPatientFound
    case noBiomarkersSelected
    case invalidPDFData

    var errorDescription: String? {
        switch self {
        case .parsingFailed(let message):
            return "Failed to parse PDF: \(message)"
        case .uploadFailed(let message):
            return "Failed to upload PDF: \(message)"
        case .noPatientFound:
            return "Unable to identify patient. Please ensure you're logged in."
        case .noBiomarkersSelected:
            return "Please select at least one biomarker to save."
        case .invalidPDFData:
            return "The selected file is not a valid PDF."
        }
    }
}
