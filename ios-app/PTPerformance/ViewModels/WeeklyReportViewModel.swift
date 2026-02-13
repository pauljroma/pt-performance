//
//  WeeklyReportViewModel.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  ViewModel for weekly report generation and management
//

import Foundation
import SwiftUI
import Combine

// MARK: - Weekly Report View Model

/// ViewModel for managing weekly report generation, caching, and export
@MainActor
final class WeeklyReportViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var report: WeeklyReport?
    @Published var reports: [WeeklyReport] = []
    @Published var isLoading = false
    @Published var isExporting = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var generationProgress: Double = 0
    @Published var currentStep: String = ""

    // Schedule management
    @Published var schedule: ReportSchedule?
    @Published var scheduleEnabled = true
    @Published var scheduleDayOfWeek = 2 // Monday
    @Published var scheduleHour = 8 // 8 AM

    // MARK: - Private Properties

    private let reportService = WeeklyReportService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        observeServiceUpdates()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Service Observation

    private func observeServiceUpdates() {
        // Observe generation progress from service
        reportService.$isGenerating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGenerating in
                self?.isGenerating = isGenerating
            }
            .store(in: &cancellables)

        reportService.$generationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.generationProgress = progress
            }
            .store(in: &cancellables)

        reportService.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.currentStep = step
            }
            .store(in: &cancellables)

        reportService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Report Generation

    /// Generate a new weekly report for a patient
    /// - Parameters:
    ///   - patientId: Patient's UUID
    ///   - weekOf: Date within the target week
    func generateReport(patientId: UUID, weekOf: Date = Date()) async {
        errorMessage = nil
        successMessage = nil

        do {
            let generatedReport = try await reportService.generateReport(patientId: patientId, weekOf: weekOf)
            report = generatedReport

            // Insert at beginning of reports list
            if !reports.contains(where: { $0.id == generatedReport.id }) {
                reports.insert(generatedReport, at: 0)
            }

            successMessage = "Report generated successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Generate report using string patient ID
    func generateReport(patientId: String, weekOf: Date = Date()) async {
        guard let uuid = UUID(uuidString: patientId) else {
            errorMessage = "Invalid patient ID"
            return
        }
        await generateReport(patientId: uuid, weekOf: weekOf)
    }

    // MARK: - Report Fetching

    /// Fetch historical reports for a patient
    /// - Parameters:
    ///   - patientId: Patient's UUID
    ///   - limit: Maximum number of reports
    func fetchReports(patientId: UUID, limit: Int = 12) async {
        isLoading = true
        errorMessage = nil

        do {
            reports = try await reportService.fetchReports(patientId: patientId, limit: limit)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Fetch a single report by ID
    /// - Parameter reportId: Report's UUID
    func fetchReport(reportId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            report = try await reportService.fetchReport(reportId: reportId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Refresh reports (bypasses cache)
    /// - Parameter patientId: Patient's UUID
    func refreshReports(patientId: UUID) async {
        reportService.clearCache(patientId: patientId)
        await fetchReports(patientId: patientId)
    }

    // MARK: - PDF Export

    /// Export a report to PDF
    /// - Parameters:
    ///   - report: The report to export
    ///   - patientName: Patient's full name
    /// - Returns: URL to the temporary PDF file
    func exportToPDF(report: WeeklyReport, patientName: String) async -> URL? {
        isExporting = true
        errorMessage = nil

        do {
            let pdfData = try await reportService.exportToPDF(report, patientName: patientName)
            let fileURL = try reportService.savePDFToTempFile(pdfData, report: report, patientName: patientName)
            isExporting = false
            successMessage = "PDF exported successfully"
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            isExporting = false
            return nil
        }
    }

    /// Export current report to PDF
    /// - Parameter patientName: Patient's full name
    /// - Returns: URL to the temporary PDF file
    func exportCurrentReport(patientName: String) async -> URL? {
        guard let currentReport = report else {
            errorMessage = "No report to export"
            return nil
        }
        return await exportToPDF(report: currentReport, patientName: patientName)
    }

    // MARK: - Scheduling

    /// Fetch the current schedule for a therapist
    /// - Parameter therapistId: Therapist's UUID
    func fetchSchedule(therapistId: UUID) async {
        do {
            schedule = try await reportService.fetchSchedule(therapistId: therapistId)

            if let existingSchedule = schedule {
                scheduleEnabled = existingSchedule.isEnabled
                scheduleDayOfWeek = existingSchedule.dayOfWeek
                scheduleHour = existingSchedule.hour
            }
        } catch {
            // Schedule may not exist yet, which is fine
            schedule = nil
        }
    }

    /// Save or update the report schedule
    /// - Parameter therapistId: Therapist's UUID
    func saveSchedule(therapistId: UUID) async {
        errorMessage = nil

        do {
            if let existingSchedule = schedule {
                try await reportService.updateSchedule(
                    scheduleId: existingSchedule.id,
                    isEnabled: scheduleEnabled,
                    dayOfWeek: scheduleDayOfWeek,
                    hour: scheduleHour
                )
            } else {
                try await reportService.scheduleWeeklyGeneration(
                    therapistId: therapistId,
                    dayOfWeek: scheduleDayOfWeek,
                    hour: scheduleHour
                )
            }

            successMessage = "Schedule saved successfully"

            // Refresh schedule
            await fetchSchedule(therapistId: therapistId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Disable the report schedule
    /// - Parameter therapistId: Therapist's UUID
    func disableSchedule(therapistId: UUID) async {
        guard let existingSchedule = schedule else { return }

        do {
            try await reportService.updateSchedule(
                scheduleId: existingSchedule.id,
                isEnabled: false
            )
            scheduleEnabled = false
            successMessage = "Schedule disabled"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Utility

    /// Clear all error and success messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// Clear cached data
    func clearCache(patientId: UUID? = nil) {
        if let patientId = patientId {
            reportService.clearCache(patientId: patientId)
        } else {
            reportService.clearAllCaches()
        }
    }

    // MARK: - Computed Properties

    /// Whether a report is currently loaded
    var hasReport: Bool {
        report != nil
    }

    /// Whether any reports are loaded
    var hasReports: Bool {
        !reports.isEmpty
    }

    /// Latest report from the list
    var latestReport: WeeklyReport? {
        reports.first
    }

    /// Schedule description for display
    var scheduleDescription: String? {
        schedule?.scheduleDescription
    }

    /// Day names for picker
    static let dayNames = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    /// Hour options for picker (formatted as 12-hour time)
    static let hourOptions: [(Int, String)] = (0...23).map { hour in
        let formatted: String
        if hour == 0 {
            formatted = "12:00 AM"
        } else if hour < 12 {
            formatted = "\(hour):00 AM"
        } else if hour == 12 {
            formatted = "12:00 PM"
        } else {
            formatted = "\(hour - 12):00 PM"
        }
        return (hour, formatted)
    }
}

// MARK: - Equatable Support for State Changes

extension WeeklyReportViewModel {
    /// Compare two reports for changes
    func hasReportChanged(from oldReport: WeeklyReport?, to newReport: WeeklyReport?) -> Bool {
        guard let old = oldReport, let new = newReport else {
            return oldReport != nil || newReport != nil
        }
        return old.id != new.id || old.generatedAt != new.generatedAt
    }
}
