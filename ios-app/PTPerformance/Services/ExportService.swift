import PDFKit
import SwiftUI
import UIKit

/// Service for exporting workout history to PDF and CSV formats
@MainActor
class ExportService {

    // MARK: - Export Options

    enum ExportFormat {
        case pdf
        case csv
    }

    enum ExportError: LocalizedError {
        case noData
        case pdfGenerationFailed
        case csvGenerationFailed
        case fileCreationFailed

        var errorDescription: String? {
            switch self {
            case .noData:
                return "No workout data available to export"
            case .pdfGenerationFailed:
                return "Failed to generate PDF document"
            case .csvGenerationFailed:
                return "Failed to generate CSV file"
            case .fileCreationFailed:
                return "Failed to create export file"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .noData:
                return "Complete some workouts first, then try exporting again."
            case .pdfGenerationFailed, .csvGenerationFailed:
                return "Please try again. If the problem persists, contact support."
            case .fileCreationFailed:
                return "Make sure you have enough storage space and try again."
            }
        }
    }

    // MARK: - PDF Export

    /// Export workout history to PDF for last 30 days
    /// - Parameters:
    ///   - sessions: Array of sessions with exercise logs
    ///   - patientName: Name of the patient
    /// - Returns: URL to the generated PDF file
    func exportToPDF(sessions: [SessionWithLogs], patientName: String) async throws -> URL {
        guard !sessions.isEmpty else {
            throw ExportError.noData
        }

        // ACP-1051: Log data export event
        Task {
            await AuditLogger.shared.logExport(
                resource: "workout_history",
                format: "pdf",
                details: "Exporting \(sessions.count) sessions for last 30 days"
            )
        }

        // Create PDF document
        let pdfMetadata = [
            kCGPDFContextTitle: "Korza Training History",
            kCGPDFContextAuthor: "Korza Training",
            kCGPDFContextCreator: "Korza Training iOS App"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]

        // Page dimensions (US Letter)
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        var pageCount = 0
        let data = renderer.pdfData { context in
            // Calculate date range
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            var currentY: CGFloat = 50

            context.beginPage()
            pageCount += 1

            // Header
            currentY = drawPDFHeader(
                context: context.cgContext,
                pageRect: pageRect,
                patientName: patientName,
                startDate: startDate,
                endDate: endDate,
                startY: currentY
            )

            currentY += 30

            // Sessions
            for (_, session) in sessions.enumerated() {
                // Check if we need a new page
                if currentY > pageHeight - 200 {
                    context.beginPage()
                    pageCount += 1
                    currentY = 50
                }

                currentY = drawSessionSection(
                    context: context.cgContext,
                    pageRect: pageRect,
                    session: session,
                    startY: currentY
                )

                currentY += 20
            }

            // Footer on last page
            drawPDFFooter(
                context: context.cgContext,
                pageRect: pageRect,
                pageNumber: pageCount
            )
        }

        // Save to temporary file
        let fileName = "PT_Performance_History_\(dateString(Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }

    // MARK: - CSV Export

    /// Export exercise logs to CSV
    /// - Parameters:
    ///   - sessions: Array of sessions with exercise logs
    ///   - startDate: Start date for filtering
    ///   - endDate: End date for filtering
    /// - Returns: URL to the generated CSV file
    func exportToCSV(sessions: [SessionWithLogs], startDate: Date, endDate: Date) async throws -> URL {
        guard !sessions.isEmpty else {
            throw ExportError.noData
        }

        // ACP-1051: Log CSV data export event
        Task {
            await AuditLogger.shared.logExport(
                resource: "exercise_logs",
                format: "csv",
                details: "Exporting \(sessions.count) sessions as CSV"
            )
        }

        var csvString = "Date,Exercise,Sets,Reps,Weight,Unit,RPE,Pain Score,Notes\n"

        for session in sessions {
            for log in session.exerciseLogs {
                let dateStr = dateString(log.loggedAt)
                let exercise = escapeCSV(log.exerciseName)
                let sets = "\(log.actualSets)"
                let reps = log.actualReps.map { String($0) }.joined(separator: ";")
                let weight = log.actualLoad.map { String(format: "%.1f", $0) } ?? ""
                let unit = escapeCSV(log.loadUnit ?? "")
                let rpe = "\(log.rpe)"
                let painScore = "\(log.painScore)"
                let notes = escapeCSV(log.notes ?? "")

                let row = "\(dateStr),\(exercise),\(sets),\"\(reps)\",\(weight),\(unit),\(rpe),\(painScore),\(notes)\n"
                csvString.append(row)
            }
        }

        // Save to temporary file
        let fileName = "PT_Performance_Logs_\(dateString(Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }

    // MARK: - PDF Drawing Helpers

    private func drawPDFHeader(
        context: CGContext,
        pageRect: CGRect,
        patientName: String,
        startDate: Date,
        endDate: Date,
        startY: CGFloat
    ) -> CGFloat {
        var currentY = startY
        let margin: CGFloat = 50

        // Title
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleText = "Modus History"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]

        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: margin,
            y: currentY,
            width: pageRect.width - 2 * margin,
            height: titleSize.height
        )
        titleText.draw(in: titleRect, withAttributes: titleAttributes)

        currentY += titleSize.height + 20

        // Patient name and date range
        let bodyFont = UIFont.systemFont(ofSize: 12)
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.secondaryLabel
        ]

        let patientText = "Patient: \(patientName)"
        let patientSize = patientText.size(withAttributes: bodyAttributes)
        let patientRect = CGRect(
            x: margin,
            y: currentY,
            width: pageRect.width - 2 * margin,
            height: patientSize.height
        )
        patientText.draw(in: patientRect, withAttributes: bodyAttributes)

        currentY += patientSize.height + 5

        let dateRangeText = "Period: \(dateString(startDate)) - \(dateString(endDate))"
        let dateSize = dateRangeText.size(withAttributes: bodyAttributes)
        let dateRect = CGRect(
            x: margin,
            y: currentY,
            width: pageRect.width - 2 * margin,
            height: dateSize.height
        )
        dateRangeText.draw(in: dateRect, withAttributes: bodyAttributes)

        currentY += dateSize.height + 10

        // Divider line
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: pageRect.width - margin, y: currentY))
        context.strokePath()

        return currentY
    }

    private func drawSessionSection(
        context: CGContext,
        pageRect: CGRect,
        session: SessionWithLogs,
        startY: CGFloat
    ) -> CGFloat {
        var currentY = startY
        let margin: CGFloat = 50
        let indent: CGFloat = 20

        // Session header
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.label
        ]

        let headerText = "Session \(session.sessionNumber ?? 0) - \(dateString(session.sessionDate))"
        let headerSize = headerText.size(withAttributes: headerAttributes)
        let headerRect = CGRect(
            x: margin,
            y: currentY,
            width: pageRect.width - 2 * margin,
            height: headerSize.height
        )
        headerText.draw(in: headerRect, withAttributes: headerAttributes)

        currentY += headerSize.height + 5

        // Session summary
        let summaryFont = UIFont.systemFont(ofSize: 11)
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: summaryFont,
            .foregroundColor: UIColor.secondaryLabel
        ]

        let summaryText = String(format: "Avg RPE: %.1f | Avg Pain: %.1f | Exercises: %d",
                                 session.avgRpe ?? 0.0, session.avgPainScore ?? 0.0, session.exerciseLogs.count)
        let summarySize = summaryText.size(withAttributes: summaryAttributes)
        let summaryRect = CGRect(
            x: margin,
            y: currentY,
            width: pageRect.width - 2 * margin,
            height: summarySize.height
        )
        summaryText.draw(in: summaryRect, withAttributes: summaryAttributes)

        currentY += summarySize.height + 10

        // Exercise logs
        let exerciseFont = UIFont.systemFont(ofSize: 10)
        let exerciseAttributes: [NSAttributedString.Key: Any] = [
            .font: exerciseFont,
            .foregroundColor: UIColor.label
        ]

        for log in session.exerciseLogs {
            let exerciseText = "\(log.exerciseName) - \(log.actualSets) sets x \(log.repsDisplay) reps @ \(log.loadDisplay) | RPE: \(log.rpe)/10 | Pain: \(log.painScore)/10"

            let exerciseSize = exerciseText.size(withAttributes: exerciseAttributes)
            let exerciseRect = CGRect(
                x: margin + indent,
                y: currentY,
                width: pageRect.width - 2 * margin - indent,
                height: exerciseSize.height
            )
            exerciseText.draw(in: exerciseRect, withAttributes: exerciseAttributes)

            currentY += exerciseSize.height + 3

            // Notes if present
            if let notes = log.notes, !notes.isEmpty {
                let notesText = "  Notes: \(notes)"
                let notesSize = notesText.size(withAttributes: exerciseAttributes)
                let notesRect = CGRect(
                    x: margin + indent,
                    y: currentY,
                    width: pageRect.width - 2 * margin - indent,
                    height: notesSize.height
                )
                notesText.draw(in: notesRect, withAttributes: exerciseAttributes)
                currentY += notesSize.height + 3
            }
        }

        // Session notes if present
        if let notes = session.notes, !notes.isEmpty {
            currentY += 5
            let sessionNotesText = "Session Notes: \(notes)"
            let notesSize = sessionNotesText.size(withAttributes: summaryAttributes)
            let notesRect = CGRect(
                x: margin + indent,
                y: currentY,
                width: pageRect.width - 2 * margin - indent,
                height: notesSize.height
            )
            sessionNotesText.draw(in: notesRect, withAttributes: summaryAttributes)
            currentY += notesSize.height + 5
        }

        return currentY
    }

    private func drawPDFFooter(
        context: CGContext,
        pageRect: CGRect,
        pageNumber: Int
    ) {
        let footerY = pageRect.height - 30

        let footerFont = UIFont.systemFont(ofSize: 9)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.tertiaryLabel
        ]

        let footerText = "Generated by Modus on \(dateString(Date())) | Page \(pageNumber)"
        let footerSize = footerText.size(withAttributes: footerAttributes)

        let footerRect = CGRect(
            x: (pageRect.width - footerSize.width) / 2,
            y: footerY,
            width: footerSize.width,
            height: footerSize.height
        )
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    // MARK: - Helpers

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Escape CSV special characters (quotes, commas, newlines)
    private func escapeCSV(_ string: String) -> String {
        // If string contains comma, quote, or newline, wrap in quotes and escape internal quotes
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}
