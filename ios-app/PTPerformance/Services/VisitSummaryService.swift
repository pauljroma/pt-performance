//
//  VisitSummaryService.swift
//  PTPerformance
//
//  Service for managing visit summaries
//  Handles generation, retrieval, approval, and PDF export of visit summaries
//

import Foundation
import PDFKit
import SwiftUI
import UIKit

// MARK: - Visit Summary Service

/// Service responsible for managing visit summaries
/// Coordinates summary generation, approval workflow, and PDF export
@MainActor
final class VisitSummaryService: ObservableObject {

    // MARK: - Singleton

    static let shared = VisitSummaryService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var isExporting = false
    @Published var generationProgress: Double = 0
    @Published var currentStep: String = ""
    @Published var errorMessage: String?
    @Published var lastGeneratedSummary: VisitSummary?
    @Published var patientSummaries: [VisitSummary] = []

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Summary Generation

    /// Generate a visit summary from session data
    /// - Parameters:
    ///   - sessionId: The session ID to generate summary for
    ///   - patientId: The patient ID
    ///   - therapistId: The therapist ID
    /// - Returns: Generated visit summary
    func generateSummary(
        sessionId: UUID,
        patientId: UUID,
        therapistId: UUID
    ) async throws -> VisitSummary {
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
            // Fetch session data
            currentStep = "Fetching session data..."
            generationProgress = 0.1
            let sessionData = try await fetchSessionData(sessionId: sessionId)

            // Fetch exercise logs for the session
            currentStep = "Fetching exercise logs..."
            generationProgress = 0.3
            let exerciseLogs = try await fetchExerciseLogs(sessionId: sessionId)

            // Calculate metrics
            currentStep = "Calculating metrics..."
            generationProgress = 0.5
            let metrics = calculateVSSessionMetrics(exerciseLogs: exerciseLogs)

            // Build exercises performed list
            currentStep = "Building exercise summary..."
            generationProgress = 0.6
            let exercisesPerformed = buildExercisesPerformed(from: exerciseLogs)

            // Create visit summary
            currentStep = "Creating summary..."
            generationProgress = 0.7
            let summary = VisitSummary(
                patientId: patientId,
                sessionId: sessionId,
                therapistId: therapistId,
                visitDate: sessionData.sessionDate ?? Date(),
                exercisesPerformed: exercisesPerformed,
                totalExercises: exercisesPerformed.count,
                durationMinutes: sessionData.durationMinutes,
                avgPainScore: metrics.avgPainScore,
                avgRpe: metrics.avgRpe,
                peakPainScore: metrics.peakPainScore,
                endPainScore: metrics.endPainScore,
                clinicalNotes: sessionData.notes,
                patientResponse: sessionData.patientResponse,
                modificationsMade: sessionData.modifications
            )

            // Save to database
            currentStep = "Saving summary..."
            generationProgress = 0.9
            let savedSummary = try await saveSummary(summary)

            lastGeneratedSummary = savedSummary
            generationProgress = 1.0
            currentStep = "Complete"

            logSummaryGeneration(sessionId: sessionId, success: true)

            return savedSummary

        } catch {
            errorMessage = error.localizedDescription
            logSummaryGeneration(sessionId: sessionId, success: false, error: error)
            throw error
        }
    }

    /// Generate summary with custom input data
    /// - Parameter input: Custom visit summary input
    /// - Returns: Generated visit summary
    func generateSummary(from input: VisitSummaryInput) async throws -> VisitSummary {
        isGenerating = true
        generationProgress = 0
        currentStep = "Validating input..."
        errorMessage = nil

        defer {
            isGenerating = false
            generationProgress = 1.0
            currentStep = ""
        }

        do {
            // Validate input
            try input.validate()
            generationProgress = 0.2

            guard let patientIdStr = input.patientId,
                  let patientId = UUID(uuidString: patientIdStr),
                  let sessionIdStr = input.sessionId,
                  let sessionId = UUID(uuidString: sessionIdStr),
                  let therapistIdStr = input.therapistId,
                  let therapistId = UUID(uuidString: therapistIdStr) else {
                throw VisitSummaryServiceError.invalidInput("Missing required IDs")
            }

            // Parse visit date
            currentStep = "Processing data..."
            generationProgress = 0.4
            var visitDate = Date()
            if let dateStr = input.visitDate {
                let formatter = ISO8601DateFormatter()
                if let parsedDate = formatter.date(from: dateStr) {
                    visitDate = parsedDate
                }
            }

            // Create summary from input
            currentStep = "Creating summary..."
            generationProgress = 0.6
            let summary = VisitSummary(
                patientId: patientId,
                sessionId: sessionId,
                therapistId: therapistId,
                visitDate: visitDate,
                exercisesPerformed: input.exercisesPerformed,
                totalExercises: input.totalExercises ?? input.exercisesPerformed?.count,
                durationMinutes: input.durationMinutes,
                avgPainScore: input.avgPainScore,
                avgRpe: input.avgRpe,
                peakPainScore: input.peakPainScore,
                endPainScore: input.endPainScore,
                clinicalNotes: input.clinicalNotes,
                patientResponse: input.patientResponse,
                modificationsMade: input.modificationsMade,
                nextVisitFocus: input.nextVisitFocus,
                homeProgramChanges: input.homeProgramChanges,
                goalsAddressed: input.goalsAddressed,
                treatmentInterventions: input.treatmentInterventions,
                patientEducation: input.patientEducation
            )

            // Save to database
            currentStep = "Saving summary..."
            generationProgress = 0.8
            let savedSummary = try await saveSummary(summary)

            lastGeneratedSummary = savedSummary
            generationProgress = 1.0
            currentStep = "Complete"

            return savedSummary

        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Patient Summaries

    /// Get all visit summaries for a patient
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - limit: Maximum number of summaries to fetch (default 50)
    /// - Returns: Array of visit summaries
    func getPatientSummaries(patientId: UUID, limit: Int = 50) async throws -> [VisitSummary] {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("visit_summaries")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("visit_date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summaries = try decoder.decode([VisitSummary].self, from: response.data)

            patientSummaries = summaries
            return summaries

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.getPatientSummaries", "\(error)")
            throw VisitSummaryServiceError.fetchFailed(error.localizedDescription)
        }
    }

    /// Get a single visit summary by ID
    /// - Parameter summaryId: The summary ID
    /// - Returns: The visit summary
    func getSummary(summaryId: UUID) async throws -> VisitSummary {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("visit_summaries")
                .select()
                .eq("id", value: summaryId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summary = try decoder.decode(VisitSummary.self, from: response.data)

            return summary

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.getSummary", "\(error)")
            throw VisitSummaryServiceError.summaryNotFound
        }
    }

    /// Get summaries within a date range
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of visit summaries within the range
    func getSummaries(
        patientId: UUID,
        startDate: Date,
        endDate: Date
    ) async throws -> [VisitSummary] {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let formatter = ISO8601DateFormatter()
            let startDateStr = formatter.string(from: startDate)
            let endDateStr = formatter.string(from: endDate)

            let response = try await supabase.client
                .from("visit_summaries")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("visit_date", value: startDateStr)
                .lte("visit_date", value: endDateStr)
                .order("visit_date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summaries = try decoder.decode([VisitSummary].self, from: response.data)

            return summaries

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.getSummaries", "\(error)")
            throw VisitSummaryServiceError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Approval

    /// Approve a visit summary
    /// - Parameters:
    ///   - summaryId: The summary ID to approve
    ///   - therapistId: The therapist approving the summary
    /// - Returns: The approved summary
    @discardableResult
    func approveSummary(summaryId: UUID, therapistId: UUID) async throws -> VisitSummary {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let now = Date()
            let formatter = ISO8601DateFormatter()
            let approvedAtStr = formatter.string(from: now)

            let response = try await supabase.client
                .from("visit_summaries")
                .update([
                    "approved_at": approvedAtStr,
                    "approved_by": therapistId.uuidString
                ])
                .eq("id", value: summaryId.uuidString)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summary = try decoder.decode(VisitSummary.self, from: response.data)

            // Update local cache if present
            if let index = patientSummaries.firstIndex(where: { $0.id == summaryId }) {
                patientSummaries[index] = summary
            }

            logApproval(summaryId: summaryId, success: true)

            return summary

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.approveSummary", "\(error)")
            logApproval(summaryId: summaryId, success: false, error: error)
            throw VisitSummaryServiceError.approvalFailed(error.localizedDescription)
        }
    }

    /// Revoke approval for a visit summary
    /// - Parameter summaryId: The summary ID to revoke approval
    /// - Returns: The updated summary
    @discardableResult
    func revokeApproval(summaryId: UUID) async throws -> VisitSummary {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let revokeUpdate = ApprovalRevokeUpdate(approvedAt: nil, approvedBy: nil)
            let response = try await supabase.client
                .from("visit_summaries")
                .update(revokeUpdate)
                .eq("id", value: summaryId.uuidString)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summary = try decoder.decode(VisitSummary.self, from: response.data)

            // Update local cache if present
            if let index = patientSummaries.firstIndex(where: { $0.id == summaryId }) {
                patientSummaries[index] = summary
            }

            return summary

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.revokeApproval", "\(error)")
            throw VisitSummaryServiceError.approvalFailed(error.localizedDescription)
        }
    }

    // MARK: - PDF Export

    /// Export a visit summary to PDF
    /// - Parameters:
    ///   - summary: The visit summary to export
    ///   - patientName: Patient name for the report
    ///   - branding: Optional clinic branding
    /// - Returns: URL to the generated PDF file
    func exportToPDF(
        summary: VisitSummary,
        patientName: String,
        branding: ClinicBranding? = nil
    ) async throws -> URL {
        isExporting = true
        currentStep = "Generating PDF..."
        errorMessage = nil

        defer {
            isExporting = false
            currentStep = ""
        }

        do {
            // Generate PDF data
            let pdfData = generatePDFData(summary: summary, patientName: patientName, branding: branding)

            // Save to temporary file
            currentStep = "Saving PDF..."
            let fileURL = try savePDFToTemporaryFile(
                pdfData: pdfData,
                patientName: patientName,
                visitDate: summary.visitDate
            )

            logExport(summaryId: summary.id, success: true)

            return fileURL

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.exportToPDF", "\(error)")
            logExport(summaryId: summary.id, success: false, error: error)
            throw VisitSummaryServiceError.exportFailed(error.localizedDescription)
        }
    }

    /// Export multiple summaries to a single PDF
    /// - Parameters:
    ///   - summaries: Array of visit summaries to export
    ///   - patientName: Patient name for the report
    ///   - branding: Optional clinic branding
    /// - Returns: URL to the generated PDF file
    func exportMultipleToPDF(
        summaries: [VisitSummary],
        patientName: String,
        branding: ClinicBranding? = nil
    ) async throws -> URL {
        isExporting = true
        currentStep = "Generating PDF..."
        errorMessage = nil

        defer {
            isExporting = false
            currentStep = ""
        }

        guard !summaries.isEmpty else {
            throw VisitSummaryServiceError.invalidInput("No summaries to export")
        }

        do {
            // Generate PDF data for all summaries
            let pdfData = generateMultiPagePDFData(
                summaries: summaries,
                patientName: patientName,
                branding: branding
            )

            // Save to temporary file
            currentStep = "Saving PDF..."
            let fileURL = try savePDFToTemporaryFile(
                pdfData: pdfData,
                patientName: patientName,
                visitDate: summaries.first?.visitDate ?? Date(),
                isMultiple: true
            )

            return fileURL

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.exportMultipleToPDF", "\(error)")
            throw VisitSummaryServiceError.exportFailed(error.localizedDescription)
        }
    }

    // MARK: - Update Summary

    /// Update an existing visit summary
    /// - Parameters:
    ///   - summaryId: The summary ID to update
    ///   - input: Updated summary data
    /// - Returns: The updated summary
    func updateSummary(summaryId: UUID, input: VisitSummaryInput) async throws -> VisitSummary {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try input.validate()

            let response = try await supabase.client
                .from("visit_summaries")
                .update(input)
                .eq("id", value: summaryId.uuidString)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summary = try decoder.decode(VisitSummary.self, from: response.data)

            // Update local cache if present
            if let index = patientSummaries.firstIndex(where: { $0.id == summaryId }) {
                patientSummaries[index] = summary
            }

            return summary

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.updateSummary", "\(error)")
            throw VisitSummaryServiceError.saveFailed(error.localizedDescription)
        }
    }

    /// Delete a visit summary
    /// - Parameter summaryId: The summary ID to delete
    func deleteSummary(summaryId: UUID) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await supabase.client
                .from("visit_summaries")
                .delete()
                .eq("id", value: summaryId.uuidString)
                .execute()

            // Remove from local cache
            patientSummaries.removeAll { $0.id == summaryId }

        } catch {
            errorMessage = error.localizedDescription
            logger.error("VisitSummaryService.deleteSummary", "\(error)")
            throw VisitSummaryServiceError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    private func fetchSessionData(sessionId: UUID) async throws -> SessionData {
        let response = try await supabase.client
            .from("sessions")
            .select()
            .eq("id", value: sessionId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SessionData.self, from: response.data)
    }

    private func fetchExerciseLogs(sessionId: UUID) async throws -> [VSExerciseLog] {
        let response = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("session_id", value: sessionId.uuidString)
            .order("created_at", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([VSExerciseLog].self, from: response.data)
    }

    private func calculateVSSessionMetrics(exerciseLogs: [VSExerciseLog]) -> VSSessionMetrics {
        var painScores: [Double] = []
        var rpeScores: [Double] = []

        for log in exerciseLogs {
            if let pain = log.painScore {
                painScores.append(Double(pain))
            }
            if let rpe = log.rpe {
                rpeScores.append(Double(rpe))
            }
        }

        let avgPain = painScores.isEmpty ? nil : painScores.reduce(0, +) / Double(painScores.count)
        let avgRpe = rpeScores.isEmpty ? nil : rpeScores.reduce(0, +) / Double(rpeScores.count)
        let peakPain = painScores.isEmpty ? nil : Int(painScores.max() ?? 0)
        let endPain = painScores.isEmpty ? nil : Int(painScores.last ?? 0)

        return VSSessionMetrics(
            avgPainScore: avgPain,
            avgRpe: avgRpe,
            peakPainScore: peakPain,
            endPainScore: endPain
        )
    }

    private func buildExercisesPerformed(from logs: [VSExerciseLog]) -> [ExercisePerformed] {
        return logs.map { log in
            ExercisePerformed(
                name: log.exerciseName,
                sets: log.setsCompleted ?? log.sets,
                reps: log.repsCompleted ?? log.reps,
                load: log.load,
                duration: log.duration,
                intensity: log.rpe.map { "RPE \($0)" },
                notes: log.notes
            )
        }
    }

    private func saveSummary(_ summary: VisitSummary) async throws -> VisitSummary {
        let response = try await supabase.client
            .from("visit_summaries")
            .insert(summary)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VisitSummary.self, from: response.data)
    }

    private func generatePDFData(
        summary: VisitSummary,
        patientName: String,
        branding: ClinicBranding?
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let margin: CGFloat = 50
            var yOffset: CGFloat = margin

            // Header with branding
            if let branding = branding {
                let clinicNameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
                let clinicName = branding.clinicName ?? "Physical Therapy Clinic"
                clinicName.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: clinicNameAttributes)
                yOffset += 25
            }

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            "Visit Summary".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += 30

            // Patient info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            "Patient: \(patientName)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: infoAttributes)
            yOffset += 20

            "Date: \(summary.formattedDate)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: infoAttributes)
            yOffset += 20

            if let duration = summary.formattedDuration {
                "Duration: \(duration)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: infoAttributes)
                yOffset += 20
            }

            yOffset += 10

            // Exercises section
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            "Exercises Performed".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
            yOffset += 20

            let exerciseAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]

            if let exercises = summary.exercisesPerformed {
                for exercise in exercises {
                    let exerciseText = "\(exercise.name): \(exercise.summary)"
                    exerciseText.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
                    yOffset += 18

                    if yOffset > pageRect.height - margin {
                        context.beginPage()
                        yOffset = margin
                    }
                }
            } else {
                "No exercises recorded".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
                yOffset += 18
            }

            yOffset += 15

            // Metrics section
            "Session Metrics".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
            yOffset += 20

            if let avgPain = summary.formattedAvgPain {
                "Average Pain: \(avgPain)".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
                yOffset += 18
            }

            if let avgRpe = summary.formattedAvgRpe {
                "Average RPE: \(avgRpe)".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
                yOffset += 18
            }

            "Pain Response: \(summary.painResponse.displayName)".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
            yOffset += 18

            "Intensity Level: \(summary.intensityLevel.displayName)".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
            yOffset += 25

            // Clinical notes
            if let notes = summary.clinicalNotes, !notes.isEmpty {
                "Clinical Notes".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                yOffset += 20

                let notesRect = CGRect(x: margin + 10, y: yOffset, width: pageRect.width - 2 * margin - 10, height: 100)
                notes.draw(in: notesRect, withAttributes: exerciseAttributes)
                yOffset += 80
            }

            // Patient response
            if let response = summary.patientResponse, !response.isEmpty {
                if yOffset > pageRect.height - 100 {
                    context.beginPage()
                    yOffset = margin
                }

                "Patient Response".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                yOffset += 20

                let responseRect = CGRect(x: margin + 10, y: yOffset, width: pageRect.width - 2 * margin - 10, height: 60)
                response.draw(in: responseRect, withAttributes: exerciseAttributes)
                yOffset += 50
            }

            // Next visit focus
            if let nextFocus = summary.nextVisitFocus, !nextFocus.isEmpty {
                if yOffset > pageRect.height - 80 {
                    context.beginPage()
                    yOffset = margin
                }

                "Next Visit Focus".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                yOffset += 20

                nextFocus.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
            }

            // Footer with generation timestamp
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.lightGray
            ]
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let footerText = "Generated: \(formatter.string(from: Date()))"
            footerText.draw(at: CGPoint(x: margin, y: pageRect.height - 30), withAttributes: footerAttributes)
        }
    }

    private func generateMultiPagePDFData(
        summaries: [VisitSummary],
        patientName: String,
        branding: ClinicBranding?
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            for (index, summary) in summaries.enumerated() {
                context.beginPage()

                let margin: CGFloat = 50
                var yOffset: CGFloat = margin

                // Header
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                "Visit Summary - \(summary.formattedDate)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
                yOffset += 25

                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                "Page \(index + 1) of \(summaries.count)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttributes)
                yOffset += 25

                // Patient info
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray
                ]
                "Patient: \(patientName)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: infoAttributes)
                yOffset += 20

                // Quick summary
                summary.quickSummary.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: infoAttributes)
                yOffset += 30

                // Exercises
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                "Exercises".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                yOffset += 18

                let exerciseAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]

                if let exercises = summary.exercisesPerformed {
                    for exercise in exercises.prefix(15) {
                        let text = "\(exercise.name): \(exercise.summary)"
                        text.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: exerciseAttributes)
                        yOffset += 16
                    }
                }

                yOffset += 15

                // Notes
                if let notes = summary.clinicalNotes, !notes.isEmpty {
                    "Notes".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                    yOffset += 18

                    let notesRect = CGRect(x: margin + 10, y: yOffset, width: pageRect.width - 2 * margin - 10, height: 100)
                    notes.draw(in: notesRect, withAttributes: exerciseAttributes)
                }
            }
        }
    }

    private func savePDFToTemporaryFile(
        pdfData: Data,
        patientName: String,
        visitDate: Date,
        isMultiple: Bool = false
    ) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateStr = formatter.string(from: Date())

        // Use initials for HIPAA compliance
        let initials = patientName.split(separator: " ").map { String($0.prefix(1)) }.joined()

        let suffix = isMultiple ? "_combined" : ""
        let fileName = "VisitSummary_\(initials)_\(dateStr)\(suffix).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try pdfData.write(to: tempURL)
        return tempURL
    }

    // MARK: - Logging

    private func logSummaryGeneration(sessionId: UUID, success: Bool, error: Error? = nil) {
        #if DEBUG
        var message = "[VisitSummaryService] Summary generation: success=\(success)"
        if let error = error {
            message += ", error=\(error.localizedDescription)"
        }
        print(message)
        #endif

        AnalyticsTracker.shared.track(
            event: "visit_summary_generated",
            properties: [
                "success": success
            ]
        )
    }

    private func logApproval(summaryId: UUID, success: Bool, error: Error? = nil) {
        #if DEBUG
        var message = "[VisitSummaryService] Summary approval: success=\(success)"
        if let error = error {
            message += ", error=\(error.localizedDescription)"
        }
        print(message)
        #endif

        AnalyticsTracker.shared.track(
            event: "visit_summary_approved",
            properties: [
                "success": success
            ]
        )
    }

    private func logExport(summaryId: UUID, success: Bool, error: Error? = nil) {
        #if DEBUG
        var message = "[VisitSummaryService] Summary export: success=\(success)"
        if let error = error {
            message += ", error=\(error.localizedDescription)"
        }
        print(message)
        #endif

        AnalyticsTracker.shared.track(
            event: "visit_summary_exported",
            properties: [
                "success": success
            ]
        )
    }

    /// Clean up old temporary PDF files
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let pdfFiles = files.filter { $0.lastPathComponent.hasPrefix("VisitSummary_") && $0.pathExtension == "pdf" }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        for file in pdfFiles {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < cutoffDate else {
                continue
            }

            try? FileManager.default.removeItem(at: file)
        }
    }
}

// MARK: - Service Error

enum VisitSummaryServiceError: LocalizedError {
    case invalidInput(String)
    case fetchFailed(String)
    case saveFailed(String)
    case summaryNotFound
    case approvalFailed(String)
    case exportFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch summaries: \(message)"
        case .saveFailed(let message):
            return "Failed to save summary: \(message)"
        case .summaryNotFound:
            return "Visit summary not found"
        case .approvalFailed(let message):
            return "Failed to approve summary: \(message)"
        case .exportFailed(let message):
            return "Failed to export PDF: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete summary: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please check the input values and try again"
        case .fetchFailed, .saveFailed, .approvalFailed, .exportFailed, .deleteFailed:
            return "Please check your connection and try again"
        case .summaryNotFound:
            return "The requested summary may have been deleted"
        }
    }
}

// MARK: - Supporting Models

private struct SessionData: Codable {
    let id: UUID
    let sessionDate: Date?
    let durationMinutes: Int?
    let notes: String?
    let patientResponse: String?
    let modifications: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionDate = "session_date"
        case durationMinutes = "duration_minutes"
        case notes
        case patientResponse = "patient_response"
        case modifications
    }
}

private struct VSExerciseLog: Codable {
    let id: UUID
    let exerciseName: String
    let sets: Int
    let reps: String
    let setsCompleted: Int?
    let repsCompleted: String?
    let load: String?
    let duration: String?
    let painScore: Int?
    let rpe: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseName = "exercise_name"
        case sets
        case reps
        case setsCompleted = "sets_completed"
        case repsCompleted = "reps_completed"
        case load
        case duration
        case painScore = "pain_score"
        case rpe
        case notes
    }
}

private struct VSSessionMetrics {
    let avgPainScore: Double?
    let avgRpe: Double?
    let peakPainScore: Int?
    let endPainScore: Int?
}

private struct ApprovalRevokeUpdate: Codable {
    let approvedAt: String?
    let approvedBy: String?

    enum CodingKeys: String, CodingKey {
        case approvedAt = "approved_at"
        case approvedBy = "approved_by"
    }
}
