import Foundation
import Supabase
import PDFKit
import UIKit

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

        DebugLogger.shared.info("LabResultService", "Processing PDF for parsing, size: \(pdfData.count) bytes")

        // Convert PDF pages to images (Claude Vision doesn't support PDFs directly)
        let pageImages = try convertPDFToImages(pdfData: pdfData)
        uploadProgress = 0.3

        guard !pageImages.isEmpty else {
            throw LabResultError.invalidPDFData
        }

        DebugLogger.shared.info("LabResultService", "Converted PDF to \(pageImages.count) page image(s)")

        // Convert images to base64
        var imagesBase64: [String] = []
        for (index, image) in pageImages.enumerated() {
            // Use JPEG for smaller size (0.8 quality)
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                DebugLogger.shared.warning("LabResultService", "Failed to convert page \(index + 1) to JPEG")
                continue
            }
            imagesBase64.append(imageData.base64EncodedString())
            DebugLogger.shared.info("LabResultService", "Page \(index + 1) converted: \(imageData.count) bytes")
        }

        guard !imagesBase64.isEmpty else {
            throw LabResultError.parsingFailed("Failed to convert PDF pages to images")
        }

        // Call edge function with images
        let requestBody: [String: Any] = [
            "images_base64": imagesBase64
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

        } catch let functionsError as Supabase.FunctionsError {
            switch functionsError {
            case .httpError(let statusCode, let data):
                DebugLogger.shared.error("LabResultService", "Edge function HTTP error: \(statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    DebugLogger.shared.error("LabResultService", "Error body: \(errorString)")
                    // Try to parse the error response
                    if let errorData = errorString.data(using: .utf8),
                       let errorResponse = try? JSONDecoder().decode(ParseLabPDFResponse.self, from: errorData) {
                        throw LabResultError.parsingFailed(errorResponse.error ?? "Unknown parsing error")
                    }
                }
                throw LabResultError.uploadFailed("Server error (code \(statusCode))")
            case .relayError:
                DebugLogger.shared.error("LabResultService", "Edge function relay error")
                throw LabResultError.uploadFailed("Network connection error")
            }
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

        // Filter to only selected biomarkers
        let selectedBiomarkers = parsedResult.biomarkers.filter { $0.isSelected }

        guard !selectedBiomarkers.isEmpty else {
            throw LabResultError.noBiomarkersSelected
        }

        let labResultId = UUID()

        // 1. Insert into lab_results table (matches database schema)
        struct LabResultInsert: Encodable {
            let id: UUID
            let patient_id: UUID
            let test_date: String  // Date as yyyy-MM-dd string
            let provider: String
            let pdf_url: String?
            let notes: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let labResultInsert = LabResultInsert(
            id: labResultId,
            patient_id: patientId,
            test_date: dateFormatter.string(from: testDate),
            provider: parsedResult.provider.rawValue,
            pdf_url: nil,
            notes: "Parsed from PDF with \(selectedBiomarkers.count) biomarkers. Confidence: \(parsedResult.confidence.rawValue)"
        )

        DebugLogger.shared.info("LabResultService", "Inserting lab result: \(labResultId)")

        try await supabase.client
            .from("lab_results")
            .insert(labResultInsert)
            .execute()

        DebugLogger.shared.info("LabResultService", "Lab result inserted, now inserting biomarkers...")

        // 2. Insert biomarkers into biomarker_values table
        struct BiomarkerValueInsert: Encodable {
            let id: UUID
            let lab_result_id: UUID
            let biomarker_type: String
            let value: Double
            let unit: String
            let reference_low: Double?
            let reference_high: Double?
            let flag: String?
        }

        let biomarkerInserts = selectedBiomarkers.map { biomarker in
            BiomarkerValueInsert(
                id: UUID(),
                lab_result_id: labResultId,
                biomarker_type: biomarker.name.lowercased().replacingOccurrences(of: " ", with: "_"),
                value: biomarker.value,
                unit: biomarker.unit,
                reference_low: biomarker.referenceLow,
                reference_high: biomarker.referenceHigh,
                flag: biomarker.flag?.rawValue
            )
        }

        try await supabase.client
            .from("biomarker_values")
            .insert(biomarkerInserts)
            .execute()

        DebugLogger.shared.success("LabResultService", "Saved lab result with \(selectedBiomarkers.count) biomarkers")

        // Return a LabResult object for the UI
        let labResult = LabResult(
            id: labResultId,
            patientId: patientId,
            testDate: testDate,
            testType: testType,
            results: selectedBiomarkers.map { $0.toLabMarker() },
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date(),
            provider: nil,
            notes: nil,
            parsedData: nil
        )

        await fetchLabResults()
        return labResult
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        // Check for authenticated user first
        if let userId = supabase.client.auth.currentUser?.id {
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

            if let patientId = patients.first?.id {
                return patientId
            }
        }

        // Fallback to demo patient for unauthenticated users (demo mode)
        // This allows testing without login - demo_mode_enabled must be true in database
        DebugLogger.shared.warning("LabResultService", "No authenticated user, using demo patient")
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }

    // MARK: - PDF Conversion

    /// Converts PDF pages to UIImages for Claude Vision processing
    /// - Parameter pdfData: The PDF file data
    /// - Returns: Array of UIImage, one per page
    /// - Throws: LabResultError if PDF cannot be loaded
    private func convertPDFToImages(pdfData: Data) throws -> [UIImage] {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            DebugLogger.shared.error("LabResultService", "Failed to create PDFDocument from data")
            throw LabResultError.invalidPDFData
        }

        let pageCount = pdfDocument.pageCount
        DebugLogger.shared.info("LabResultService", "PDF has \(pageCount) page(s)")

        // Limit to 20 pages max
        let maxPages = min(pageCount, 20)
        var images: [UIImage] = []

        for pageIndex in 0..<maxPages {
            guard let page = pdfDocument.page(at: pageIndex) else {
                DebugLogger.shared.warning("LabResultService", "Failed to get page \(pageIndex + 1)")
                continue
            }

            // Get page bounds
            let pageRect = page.bounds(for: .mediaBox)

            // Render at 2x scale for good quality (300 DPI equivalent for typical lab results)
            let scale: CGFloat = 2.0
            let renderSize = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )

            // Create image context and render
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            let image = renderer.image { context in
                // White background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: renderSize))

                // Transform for PDF coordinate system
                context.cgContext.translateBy(x: 0, y: renderSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)

                // Render the PDF page
                page.draw(with: .mediaBox, to: context.cgContext)
            }

            images.append(image)
            DebugLogger.shared.info("LabResultService", "Rendered page \(pageIndex + 1): \(Int(renderSize.width))x\(Int(renderSize.height))")
        }

        if pageCount > maxPages {
            DebugLogger.shared.warning("LabResultService", "PDF has \(pageCount) pages, only processing first \(maxPages)")
        }

        return images
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
