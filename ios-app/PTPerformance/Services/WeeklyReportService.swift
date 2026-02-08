//
//  WeeklyReportService.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  Service for generating, fetching, and managing weekly therapist reports
//

import Foundation
import Supabase

// MARK: - Weekly Report Service

/// Service responsible for weekly report generation and management
/// Coordinates with backend for data aggregation and PDF generation
@MainActor
final class WeeklyReportService: ObservableObject {

    // MARK: - Singleton

    static let shared = WeeklyReportService()

    // MARK: - Published Properties

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var currentStep: String = ""
    @Published var errorMessage: String?
    @Published var cachedReports: [UUID: [WeeklyReport]] = [:] // patientId -> reports

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared
    private let pdfGenerator = ReportPDFGenerator()
    private let cacheExpiration: TimeInterval = 15 * 60 // 15 minutes
    private var cacheTimestamps: [UUID: Date] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Report Generation

    /// Generate a weekly report for a specific patient and week
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - weekOf: A date within the target week
    /// - Returns: Generated WeeklyReport
    func generateReport(patientId: UUID, weekOf: Date) async throws -> WeeklyReport {
        isGenerating = true
        generationProgress = 0
        currentStep = "Preparing report..."
        errorMessage = nil

        defer {
            isGenerating = false
            generationProgress = 1.0
            currentStep = ""
        }

        do {
            // Calculate week boundaries
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: weekOf)?.start ?? weekOf
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekOf

            currentStep = "Fetching session data..."
            generationProgress = 0.1

            // Call the edge function to generate report
            let params = GenerateReportParams(
                patientId: patientId.uuidString,
                weekStartDate: formatDate(weekStart),
                weekEndDate: formatDate(weekEnd)
            )

            generationProgress = 0.3
            currentStep = "Aggregating metrics..."

            let paramsData = try JSONSerialization.data(withJSONObject: params)
            let responseData: Data = try await supabase.functions.invoke(
                "generate-weekly-report",
                options: FunctionInvokeOptions(body: paramsData)
            ) { data, _ in
                data
            }

            generationProgress = 0.7
            currentStep = "Processing report..."

            // Decode the response
            let report = try PTSupabaseClient.flexibleDecoder.decode(WeeklyReport.self, from: responseData)

            generationProgress = 0.9
            currentStep = "Finalizing..."

            // Cache the report
            var reports = cachedReports[patientId] ?? []
            if let existingIndex = reports.firstIndex(where: { $0.id == report.id }) {
                reports[existingIndex] = report
            } else {
                reports.insert(report, at: 0)
            }
            cachedReports[patientId] = reports
            cacheTimestamps[patientId] = Date()

            generationProgress = 1.0

            // Log successful generation
            DebugLogger.shared.info("WeeklyReport", "Generated report for patient \(patientId) week of \(weekStart)")

            return report

        } catch let error as WeeklyReportError {
            errorMessage = error.localizedDescription
            errorLogger.logError(error, context: "WeeklyReportService.generateReport")
            throw error
        } catch {
            let wrappedError = WeeklyReportError.generationFailed(error.localizedDescription)
            errorMessage = wrappedError.localizedDescription
            errorLogger.logError(error, context: "WeeklyReportService.generateReport")
            throw wrappedError
        }
    }

    /// Fetch recent reports for a therapist (across all their patients)
    /// - Parameters:
    ///   - therapistId: The therapist's ID string
    ///   - limit: Maximum number of reports to fetch
    /// - Returns: Array of WeeklyReport sorted by date descending
    func getRecentReports(for therapistId: String, limit: Int = 5) async throws -> [WeeklyReport] {
        guard let therapistUUID = UUID(uuidString: therapistId) else {
            throw WeeklyReportError.fetchFailed("Invalid therapist ID")
        }

        do {
            let response: [WeeklyReport] = try await supabase
                .from("weekly_reports")
                .select()
                .eq("therapist_id", value: therapistUUID.uuidString)
                .order("week_start_date", ascending: false)
                .limit(limit)
                .execute()
                .value

            DebugLogger.shared.info("WeeklyReport", "Fetched \(response.count) recent reports for therapist")
            return response

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.getRecentReports")
            throw WeeklyReportError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch historical reports for a patient
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - limit: Maximum number of reports to fetch
    /// - Returns: Array of WeeklyReport sorted by date descending
    func fetchReports(patientId: UUID, limit: Int = 12) async throws -> [WeeklyReport] {
        // Check cache first
        if let cachedTimestamp = cacheTimestamps[patientId],
           Date().timeIntervalSince(cachedTimestamp) < cacheExpiration,
           let cached = cachedReports[patientId] {
            return Array(cached.prefix(limit))
        }

        do {
            let response: [WeeklyReport] = try await supabase
                .from("weekly_reports")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("week_start_date", ascending: false)
                .limit(limit)
                .execute()
                .value

            // Update cache
            cachedReports[patientId] = response
            cacheTimestamps[patientId] = Date()

            return response

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.fetchReports")
            throw WeeklyReportError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch a single report by ID
    /// - Parameter reportId: The report's UUID
    /// - Returns: WeeklyReport if found
    func fetchReport(reportId: UUID) async throws -> WeeklyReport {
        do {
            let response: WeeklyReport = try await supabase
                .from("weekly_reports")
                .select()
                .eq("id", value: reportId.uuidString)
                .single()
                .execute()
                .value

            return response

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.fetchReport")
            throw WeeklyReportError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - PDF Export

    /// Export a weekly report to PDF format
    /// - Parameters:
    ///   - report: The WeeklyReport to export
    ///   - patientName: Patient's full name for the PDF
    /// - Returns: PDF data
    func exportToPDF(_ report: WeeklyReport, patientName: String) async throws -> Data {
        currentStep = "Generating PDF..."

        do {
            let pdfData = pdfGenerator.generatePDF(from: report, patientName: patientName)
            currentStep = ""

            DebugLogger.shared.info("WeeklyReport", "Generated PDF for report \(report.id)")

            return pdfData

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.exportToPDF")
            throw WeeklyReportError.pdfExportFailed(error.localizedDescription)
        }
    }

    /// Save PDF to temporary file for sharing
    /// - Parameters:
    ///   - pdfData: The PDF data to save
    ///   - report: The report for filename generation
    ///   - patientName: Patient name for filename
    /// - Returns: URL to the temporary PDF file
    func savePDFToTempFile(_ pdfData: Data, report: WeeklyReport, patientName: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: report.weekStartDate)

        let sanitizedName = patientName
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }

        let fileName = "WeeklyReport_\(sanitizedName)_\(dateStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try pdfData.write(to: tempURL)

        return tempURL
    }

    // MARK: - Scheduling

    /// Schedule automatic weekly report generation
    /// - Parameters:
    ///   - therapistId: Therapist's UUID
    ///   - dayOfWeek: Day of week (1 = Sunday, 7 = Saturday)
    ///   - hour: Hour of day (0-23)
    func scheduleWeeklyGeneration(therapistId: UUID, dayOfWeek: Int, hour: Int) async throws {
        let params = ScheduleParams(
            therapistId: therapistId.uuidString,
            dayOfWeek: dayOfWeek,
            hour: hour,
            isEnabled: true
        )

        do {
            try await supabase
                .from("report_schedules")
                .upsert(params)
                .execute()

            DebugLogger.shared.info("WeeklyReport", "Scheduled weekly reports for therapist \(therapistId)")

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.scheduleWeeklyGeneration")
            throw WeeklyReportError.schedulingFailed(error.localizedDescription)
        }
    }

    /// Fetch the current report schedule for a therapist
    /// - Parameter therapistId: Therapist's UUID
    /// - Returns: ReportSchedule if exists
    func fetchSchedule(therapistId: UUID) async throws -> ReportSchedule? {
        do {
            let response: [ReportSchedule] = try await supabase
                .from("report_schedules")
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .limit(1)
                .execute()
                .value

            return response.first

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.fetchSchedule")
            return nil
        }
    }

    /// Update or disable report schedule
    /// - Parameters:
    ///   - scheduleId: The schedule's UUID
    ///   - isEnabled: Whether the schedule is enabled
    ///   - dayOfWeek: Optional new day of week
    ///   - hour: Optional new hour
    func updateSchedule(scheduleId: UUID, isEnabled: Bool, dayOfWeek: Int? = nil, hour: Int? = nil) async throws {
        var updates: [String: AnyEncodable] = [
            "is_enabled": AnyEncodable(isEnabled),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if let dayOfWeek = dayOfWeek {
            updates["day_of_week"] = AnyEncodable(dayOfWeek)
        }

        if let hour = hour {
            updates["hour"] = AnyEncodable(hour)
        }

        do {
            try await supabase
                .from("report_schedules")
                .update(updates)
                .eq("id", value: scheduleId.uuidString)
                .execute()

            DebugLogger.shared.info("WeeklyReport", "Updated schedule \(scheduleId)")

        } catch {
            errorLogger.logError(error, context: "WeeklyReportService.updateSchedule")
            throw WeeklyReportError.schedulingFailed(error.localizedDescription)
        }
    }

    // MARK: - Cache Management

    /// Clear cached reports for a patient
    func clearCache(patientId: UUID) {
        cachedReports.removeValue(forKey: patientId)
        cacheTimestamps.removeValue(forKey: patientId)
    }

    /// Clear all cached reports
    func clearAllCaches() {
        cachedReports.removeAll()
        cacheTimestamps.removeAll()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Request/Response Models

private struct GenerateReportParams: Encodable {
    let patientId: String
    let weekStartDate: String
    let weekEndDate: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
    }
}

private struct ScheduleParams: Encodable {
    let therapistId: String
    let dayOfWeek: Int
    let hour: Int
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case therapistId = "therapist_id"
        case dayOfWeek = "day_of_week"
        case hour
        case isEnabled = "is_enabled"
    }
}

// MARK: - AnyEncodable Helper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Error Types

enum WeeklyReportError: LocalizedError {
    case generationFailed(String)
    case fetchFailed(String)
    case pdfExportFailed(String)
    case schedulingFailed(String)
    case invalidDateRange
    case reportNotFound

    var errorDescription: String? {
        switch self {
        case .generationFailed(let message):
            return "Failed to generate report: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch reports: \(message)"
        case .pdfExportFailed(let message):
            return "Failed to export PDF: \(message)"
        case .schedulingFailed(let message):
            return "Failed to schedule reports: \(message)"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .reportNotFound:
            return "Report not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .generationFailed:
            return "Please check your connection and try again."
        case .fetchFailed:
            return "Please check your connection and try again."
        case .pdfExportFailed:
            return "Please try exporting again."
        case .schedulingFailed:
            return "Please try scheduling again later."
        case .invalidDateRange:
            return "Please select a valid date range."
        case .reportNotFound:
            return "The report may have been deleted."
        }
    }
}

// MARK: - String UUID Extension

extension WeeklyReportService {
    /// Fetch reports using string patient ID
    func fetchReports(patientId: String, limit: Int = 12) async throws -> [WeeklyReport] {
        guard let uuid = UUID(uuidString: patientId) else {
            throw WeeklyReportError.fetchFailed("Invalid patient ID")
        }
        return try await fetchReports(patientId: uuid, limit: limit)
    }

    /// Generate report using string patient ID
    func generateReport(patientId: String, weekOf: Date) async throws -> WeeklyReport {
        guard let uuid = UUID(uuidString: patientId) else {
            throw WeeklyReportError.generationFailed("Invalid patient ID")
        }
        return try await generateReport(patientId: uuid, weekOf: weekOf)
    }
}
