//
//  ReportGenerationService.swift
//  PTPerformance
//
//  Service for generating PDF reports from patient data
//  Supports multiple report types with HIPAA-compliant data handling
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Report Generation Service

/// Service responsible for generating PDF reports from patient data
/// Coordinates data fetching, validation, and PDF generation
@MainActor
final class ReportGenerationService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReportGenerationService()

    // MARK: - Published Properties

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var currentStep: String = ""
    @Published var errorMessage: String?
    @Published var lastGeneratedReport: GeneratedReport?

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let analyticsService: AnalyticsService
    private let pdfGenerator: PDFGenerator
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        analyticsService: AnalyticsService = .shared
    ) {
        self.supabase = supabase
        self.analyticsService = analyticsService
        self.pdfGenerator = PDFGenerator()
    }

    // MARK: - Report Generation

    /// Generate a PDF report based on the provided configuration
    /// - Parameters:
    ///   - configuration: Report configuration specifying type, date range, and sections
    ///   - patient: Patient data for the report
    ///   - branding: Optional clinic/therapist branding information
    /// - Returns: Generated report with PDF data and metadata
    func generateReport(
        configuration: ReportConfiguration,
        patient: Patient,
        branding: ClinicBranding? = nil
    ) async throws -> GeneratedReport {
        isGenerating = true
        generationProgress = 0
        currentStep = "Initializing..."
        errorMessage = nil

        defer {
            isGenerating = false
            generationProgress = 1.0
            currentStep = ""
        }

        do {
            // Validate configuration
            try validateConfiguration(configuration)
            generationProgress = 0.1
            currentStep = "Validating configuration..."

            // Fetch report data
            var reportData = ReportData(
                patient: patient,
                configuration: configuration,
                branding: branding
            )

            // Fetch section-specific data
            reportData = try await fetchReportData(reportData: reportData)
            generationProgress = 0.6
            currentStep = "Processing data..."

            // Generate PDF
            currentStep = "Generating PDF..."
            let pdfData = pdfGenerator.generatePDF(from: reportData)
            generationProgress = 0.9

            // Save to temporary file
            currentStep = "Saving report..."
            let fileURL = try saveReportToTemporaryFile(pdfData: pdfData, configuration: configuration, patientName: patient.fullName)

            let report = GeneratedReport(
                id: UUID(),
                configuration: configuration,
                patientName: patient.fullName,
                generatedAt: Date(),
                pdfData: pdfData,
                fileURL: fileURL
            )

            lastGeneratedReport = report
            generationProgress = 1.0
            currentStep = "Complete"

            // Log successful generation (without PHI)
            logReportGeneration(reportType: configuration.reportType, success: true)

            return report

        } catch {
            errorMessage = error.localizedDescription
            logReportGeneration(reportType: configuration.reportType, success: false, error: error)
            throw error
        }
    }

    /// Generate a quick report using a preset configuration
    func generateQuickReport(
        preset: ReportPreset,
        patient: Patient,
        branding: ClinicBranding? = nil
    ) async throws -> GeneratedReport {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -preset.period.rawValue, to: endDate) ?? endDate

        let configuration = ReportConfiguration(
            reportType: preset.reportType,
            patientId: patient.id,
            startDate: startDate,
            endDate: endDate,
            includedSections: preset.sections
        )

        return try await generateReport(configuration: configuration, patient: patient, branding: branding)
    }

    // MARK: - Data Fetching

    private func fetchReportData(reportData: ReportData) async throws -> ReportData {
        var data = reportData
        let patientId = reportData.patient.id.uuidString
        let days = reportData.configuration.dayCount

        currentStep = "Fetching patient data..."

        // Fetch data based on included sections
        await withTaskGroup(of: Void.self) { group in
            let sections = reportData.configuration.includedSections

            // Pain trend
            if sections.contains(.painTrend) {
                group.addTask { @MainActor in
                    do {
                        data.painTrend = try await self.analyticsService.fetchPainTrend(patientId: patientId, days: days)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchPainTrend")
                    }
                }
            }

            // Adherence
            if sections.contains(.adherence) {
                group.addTask { @MainActor in
                    do {
                        data.adherence = try await self.analyticsService.fetchAdherence(patientId: patientId, days: days)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchAdherence")
                    }
                }
            }

            // Recent sessions
            if sections.contains(.exerciseLogs) || sections.contains(.strengthProgression) {
                group.addTask { @MainActor in
                    do {
                        data.sessions = try await self.analyticsService.fetchRecentSessions(patientId: patientId, limit: 50)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchSessions")
                    }
                }
            }

            // Volume data
            if sections.contains(.strengthProgression) {
                group.addTask { @MainActor in
                    do {
                        let period: TimePeriod = days <= 7 ? .week : days <= 30 ? .month : .threeMonths
                        data.volumeData = try await self.analyticsService.calculateVolumeData(for: patientId, period: period)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchVolumeData")
                    }
                }
            }

            // Goals
            if sections.contains(.goals) || sections.contains(.outcomes) {
                group.addTask { @MainActor in
                    do {
                        data.goals = try await self.fetchPatientGoals(patientId: patientId)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchGoals")
                    }
                }
            }

            // Therapist notes
            if sections.contains(.therapistNotes) {
                group.addTask { @MainActor in
                    do {
                        data.notes = try await self.fetchPatientNotes(patientId: patientId, days: days)
                    } catch {
                        self.errorLogger.logError(error, context: "ReportGenerationService.fetchNotes")
                    }
                }
            }
        }

        generationProgress = 0.5
        currentStep = "Fetching exercise logs..."

        // Fetch exercise logs if needed (after sessions are fetched)
        if reportData.configuration.includedSections.contains(.exerciseLogs) && !data.sessions.isEmpty {
            var allLogs: [ExerciseLogDetail] = []
            for session in data.sessions.prefix(20) {
                do {
                    let logs = try await analyticsService.fetchSessionExerciseLogs(sessionId: session.id, patientId: patientId)
                    allLogs.append(contentsOf: logs)
                } catch {
                    // Continue with other sessions if one fails
                    errorLogger.logError(error, context: "ReportGenerationService.fetchExerciseLogs")
                }
            }
            data.exerciseLogs = allLogs
        }

        return data
    }

    private func fetchPatientGoals(patientId: String) async throws -> [PatientGoal] {
        let response = try await supabase.client
            .from("patient_goals")
            .select()
            .eq("patient_id", value: patientId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = PTSupabaseClient.flexibleDecoder.dateDecodingStrategy
        return try decoder.decode([PatientGoal].self, from: response.data)
    }

    private func fetchPatientNotes(patientId: String, days: Int) async throws -> [SessionNote] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let startDateStr = formatter.string(from: startDate)

        let response = try await supabase.client
            .from("session_notes")
            .select()
            .eq("patient_id", value: patientId)
            .gte("created_at", value: startDateStr)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = PTSupabaseClient.flexibleDecoder.dateDecodingStrategy
        return try decoder.decode([SessionNote].self, from: response.data)
    }

    // MARK: - Validation

    private func validateConfiguration(_ configuration: ReportConfiguration) throws {
        // Validate date range
        guard configuration.startDate < configuration.endDate else {
            throw ReportGenerationError.invalidDateRange
        }

        // Validate date range is reasonable (not more than 1 year)
        let daysDiff = Calendar.current.dateComponents([.day], from: configuration.startDate, to: configuration.endDate).day ?? 0
        guard daysDiff <= 365 else {
            throw ReportGenerationError.dateRangeTooLarge
        }

        // Validate sections are not empty
        guard !configuration.includedSections.isEmpty else {
            throw ReportGenerationError.noSectionsSelected
        }
    }

    // MARK: - File Management

    private func saveReportToTemporaryFile(pdfData: Data, configuration: ReportConfiguration, patientName: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateStr = formatter.string(from: Date())

        // Sanitize patient name for filename (HIPAA consideration: use initials for filename)
        let sanitizedName = patientName.split(separator: " ").map { String($0.prefix(1)) }.joined()

        let fileName = "\(configuration.reportType.rawValue)_\(sanitizedName)_\(dateStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try pdfData.write(to: tempURL)
        return tempURL
    }

    /// Clean up old temporary report files
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let reportFiles = files.filter { $0.pathExtension == "pdf" }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        for file in reportFiles {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < cutoffDate else {
                continue
            }

            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Logging

    private func logReportGeneration(reportType: ReportType, success: Bool, error: Error? = nil) {
        // Log without PHI
        var logMessage = "Report generation: type=\(reportType.rawValue), success=\(success)"
        if let error = error {
            logMessage += ", error=\(error.localizedDescription)"
        }

        DebugLogger.shared.log("[ReportGenerationService] \(logMessage)", level: success ? .success : .error)

        // Track analytics
        AnalyticsTracker.shared.track(
            event: "report_generated",
            properties: [
                "report_type": reportType.rawValue,
                "success": success
            ]
        )
    }
}

// MARK: - Report Generation Error

enum ReportGenerationError: LocalizedError {
    case invalidDateRange
    case dateRangeTooLarge
    case noSectionsSelected
    case dataFetchFailed
    case pdfGenerationFailed
    case fileSaveFailed

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Invalid date range: start date must be before end date"
        case .dateRangeTooLarge:
            return "Date range too large: reports cannot span more than one year"
        case .noSectionsSelected:
            return "No sections selected: please select at least one section to include in the report"
        case .dataFetchFailed:
            return "Failed to fetch patient data for the report"
        case .pdfGenerationFailed:
            return "Failed to generate PDF document"
        case .fileSaveFailed:
            return "Failed to save report file"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidDateRange, .dateRangeTooLarge:
            return "Please select a valid date range within one year"
        case .noSectionsSelected:
            return "Select at least one section to include in your report"
        case .dataFetchFailed:
            return "Please check your connection and try again"
        case .pdfGenerationFailed, .fileSaveFailed:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Therapist Branding Service

/// Service for managing therapist/clinic branding information
@MainActor
class TherapistBrandingService: ObservableObject {

    // MARK: - Published Properties

    @Published var branding: ClinicBranding?
    @Published var isLoading = false

    // MARK: - Singleton

    static let shared = TherapistBrandingService()

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared

    // MARK: - Load Branding

    func loadBranding(therapistId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("therapist_profiles")
                .select()
                .eq("user_id", value: therapistId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let profile = try decoder.decode(TherapistProfile.self, from: response.data)

            branding = ClinicBranding(
                clinicName: profile.clinicName ?? "Physical Therapy Clinic",
                therapistName: "\(profile.firstName) \(profile.lastName)",
                therapistCredentials: profile.credentials,
                clinicAddress: profile.clinicAddress,
                clinicPhone: profile.clinicPhone,
                clinicEmail: profile.email
            )
        } catch {
            // Use default branding if fetch fails
            branding = ClinicBranding()
            DebugLogger.shared.log("[TherapistBrandingService] Failed to load branding: \(error.localizedDescription)", level: .error)
        }
    }

    /// Update clinic branding
    func updateBranding(_ newBranding: ClinicBranding) {
        branding = newBranding
    }
}

// MARK: - Therapist Profile Model

private struct TherapistProfile: Codable {
    let userId: String
    let firstName: String
    let lastName: String
    let email: String?
    let credentials: String?
    let clinicName: String?
    let clinicAddress: String?
    let clinicPhone: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case credentials
        case clinicName = "clinic_name"
        case clinicAddress = "clinic_address"
        case clinicPhone = "clinic_phone"
    }
}
