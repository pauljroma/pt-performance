//
//  PDFGenerator.swift
//  PTPerformance
//
//  Core PDF generation utilities for therapist reports
//  Handles layout, rendering, and chart generation for clinical documentation
//

import PDFKit
import SwiftUI
import UIKit

// MARK: - PDF Generator

/// Utility class for generating PDF documents from report data
/// Uses UIGraphicsPDFRenderer for high-quality PDF output
final class PDFGenerator {

    // MARK: - Page Configuration

    enum PageSize {
        case letter  // 8.5 x 11 inches
        case a4      // 210 x 297 mm

        var dimensions: CGSize {
            switch self {
            case .letter:
                return CGSize(width: 8.5 * 72.0, height: 11.0 * 72.0)
            case .a4:
                return CGSize(width: 595.0, height: 842.0)
            }
        }
    }

    struct PageMargins {
        let top: CGFloat
        let bottom: CGFloat
        let left: CGFloat
        let right: CGFloat

        static let standard = PageMargins(top: 50, bottom: 50, left: 50, right: 50)
        static let narrow = PageMargins(top: 36, bottom: 36, left: 36, right: 36)
    }

    // MARK: - Properties

    private let pageSize: PageSize
    private let margins: PageMargins
    private var currentY: CGFloat = 0
    private var pageCount: Int = 0

    private var pageRect: CGRect {
        CGRect(origin: .zero, size: pageSize.dimensions)
    }

    private var contentWidth: CGFloat {
        pageSize.dimensions.width - margins.left - margins.right
    }

    private var contentStartX: CGFloat {
        margins.left
    }

    private var contentEndX: CGFloat {
        pageSize.dimensions.width - margins.right
    }

    private var maxContentY: CGFloat {
        pageSize.dimensions.height - margins.bottom
    }

    // MARK: - Fonts

    private let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    private let headerFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    private let subheaderFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
    private let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
    private let boldBodyFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
    private let captionFont = UIFont.systemFont(ofSize: 9, weight: .regular)
    private let footerFont = UIFont.systemFont(ofSize: 8, weight: .regular)

    // MARK: - Colors

    private let primaryColor = UIColor.systemBlue
    private let textColor = UIColor.label
    private let secondaryTextColor = UIColor.secondaryLabel
    private let separatorColor = UIColor.separator
    private let successColor = UIColor.systemGreen
    private let warningColor = UIColor.systemOrange
    private let errorColor = UIColor.systemRed

    // MARK: - Initialization

    init(pageSize: PageSize = .letter, margins: PageMargins = .standard) {
        self.pageSize = pageSize
        self.margins = margins
    }

    // MARK: - PDF Generation

    /// Generate PDF data from report data
    func generatePDF(from reportData: ReportData) -> Data {
        let metadata = [
            kCGPDFContextTitle: reportData.reportTitle,
            kCGPDFContextAuthor: reportData.branding?.therapistName ?? "Modus",
            kCGPDFContextCreator: "Modus iOS App",
            kCGPDFContextSubject: reportData.configuration.reportType.displayName
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = metadata as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            pageCount = 0
            currentY = margins.top

            // Start first page
            beginPage(context: context)

            // Draw header with branding
            drawReportHeader(context: context.cgContext, reportData: reportData)

            // Draw patient info section
            if reportData.configuration.includedSections.contains(.patientInfo) {
                drawPatientInfoSection(context: context.cgContext, reportData: reportData)
            }

            // Draw diagnosis section
            if reportData.configuration.includedSections.contains(.diagnosis),
               let diagnosis = reportData.diagnosis ?? reportData.patient.injuryType {
                drawDiagnosisSection(context: context.cgContext, diagnosis: diagnosis, patient: reportData.patient)
            }

            // Draw pain trend section
            if reportData.configuration.includedSections.contains(.painTrend),
               !reportData.painTrend.isEmpty {
                checkPageBreak(context: context, requiredHeight: 180)
                drawPainTrendSection(context: context.cgContext, painTrend: reportData.painTrend, reportData: reportData)
            }

            // Draw adherence section
            if reportData.configuration.includedSections.contains(.adherence),
               let adherence = reportData.adherence {
                checkPageBreak(context: context, requiredHeight: 120)
                drawAdherenceSection(context: context.cgContext, adherence: adherence)
            }

            // Draw exercise logs section
            if reportData.configuration.includedSections.contains(.exerciseLogs),
               !reportData.exerciseLogs.isEmpty {
                checkPageBreak(context: context, requiredHeight: 150)
                drawExerciseLogsSection(context: context.cgContext, logs: reportData.exerciseLogs, context: context)
            }

            // Draw strength progression section
            if reportData.configuration.includedSections.contains(.strengthProgression),
               let strengthData = reportData.strengthData {
                checkPageBreak(context: context, requiredHeight: 180)
                drawStrengthProgressionSection(context: context.cgContext, strengthData: strengthData)
            }

            // Draw goals section
            if reportData.configuration.includedSections.contains(.goals),
               !reportData.goals.isEmpty {
                checkPageBreak(context: context, requiredHeight: 100)
                drawGoalsSection(context: context.cgContext, goals: reportData.goals, context: context)
            }

            // Draw therapist notes section
            if reportData.configuration.includedSections.contains(.therapistNotes),
               !reportData.notes.isEmpty {
                checkPageBreak(context: context, requiredHeight: 100)
                drawNotesSection(context: context.cgContext, notes: reportData.notes, context: context)
            }

            // Draw outcomes section (for discharge reports)
            if reportData.configuration.includedSections.contains(.outcomes) {
                checkPageBreak(context: context, requiredHeight: 100)
                drawOutcomesSection(context: context.cgContext, reportData: reportData)
            }

            // Draw footer on last page
            drawFooter(context: context.cgContext, reportData: reportData)
        }

        return data
    }

    // MARK: - Page Management

    private func beginPage(context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        pageCount += 1
        currentY = margins.top
    }

    private func checkPageBreak(context: UIGraphicsPDFRendererContext, requiredHeight: CGFloat) {
        if currentY + requiredHeight > maxContentY {
            drawFooter(context: context.cgContext, reportData: nil, isIntermediate: true)
            beginPage(context: context)
        }
    }

    // MARK: - Header Drawing

    private func drawReportHeader(context: CGContext, reportData: ReportData) {
        let branding = reportData.branding

        // Draw clinic logo if available
        if let logoData = branding?.logoData,
           let logoImage = UIImage(data: logoData) {
            let logoSize: CGFloat = 50
            let logoRect = CGRect(x: contentStartX, y: currentY, width: logoSize, height: logoSize)
            logoImage.draw(in: logoRect)
        }

        // Report title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primaryColor
        ]

        let title = reportData.configuration.reportType.displayName
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: contentStartX,
            y: currentY,
            width: contentWidth,
            height: titleSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)
        currentY += titleSize.height + 8

        // Clinic name and therapist info
        if let branding = branding {
            let clinicAttributes: [NSAttributedString.Key: Any] = [
                .font: subheaderFont,
                .foregroundColor: textColor
            ]

            var clinicInfo = branding.clinicName
            if let credentials = branding.therapistCredentials {
                clinicInfo += "\n\(branding.therapistName), \(credentials)"
            } else {
                clinicInfo += "\n\(branding.therapistName)"
            }

            let clinicSize = clinicInfo.size(withAttributes: clinicAttributes)
            let clinicRect = CGRect(x: contentStartX, y: currentY, width: contentWidth, height: clinicSize.height * 2)
            clinicInfo.draw(in: clinicRect, withAttributes: clinicAttributes)
            currentY += clinicSize.height * 2 + 8
        }

        // Date range
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryTextColor
        ]

        let dateText = "Report Period: \(reportData.dateRangeDisplay)"
        let dateSize = dateText.size(withAttributes: dateAttributes)
        let dateRect = CGRect(x: contentStartX, y: currentY, width: contentWidth, height: dateSize.height)
        dateText.draw(in: dateRect, withAttributes: dateAttributes)
        currentY += dateSize.height + 4

        // Generated date
        let generatedText = "Generated: \(formatDate(Date()))"
        let generatedRect = CGRect(x: contentStartX, y: currentY, width: contentWidth, height: dateSize.height)
        generatedText.draw(in: generatedRect, withAttributes: dateAttributes)
        currentY += dateSize.height + 16

        // Separator line
        drawSeparatorLine(context: context)
        currentY += 20
    }

    // MARK: - Patient Info Section

    private func drawPatientInfoSection(context: CGContext, reportData: ReportData) {
        let patient = reportData.patient

        drawSectionHeader(context: context, title: "Patient Information", icon: "person.fill")

        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: boldBodyFont,
            .foregroundColor: textColor
        ]

        let infoItems: [(String, String)] = [
            ("Name:", patient.fullName),
            ("Email:", patient.email),
            ("Sport:", patient.sport ?? "N/A"),
            ("Position:", patient.position ?? "N/A"),
            ("Target Level:", patient.targetLevel ?? "N/A")
        ]

        for (label, value) in infoItems {
            let labelText = NSAttributedString(string: label, attributes: labelAttributes)
            let valueText = NSAttributedString(string: " \(value)", attributes: infoAttributes)

            let combined = NSMutableAttributedString()
            combined.append(labelText)
            combined.append(valueText)

            let textRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            combined.draw(in: textRect)
            currentY += 18
        }

        currentY += 16
    }

    // MARK: - Diagnosis Section

    private func drawDiagnosisSection(context: CGContext, diagnosis: String, patient: Patient) {
        drawSectionHeader(context: context, title: "Diagnosis & Clinical History", icon: "cross.case.fill")

        let diagnosisAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: boldBodyFont,
            .foregroundColor: textColor
        ]

        // Primary diagnosis
        let primaryLabel = NSAttributedString(string: "Primary Diagnosis: ", attributes: labelAttributes)
        let primaryValue = NSAttributedString(string: diagnosis, attributes: diagnosisAttributes)
        let primaryCombined = NSMutableAttributedString()
        primaryCombined.append(primaryLabel)
        primaryCombined.append(primaryValue)

        let primaryRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
        primaryCombined.draw(in: primaryRect)
        currentY += 24

        currentY += 16
    }

    // MARK: - Pain Trend Section

    private func drawPainTrendSection(context: CGContext, painTrend: [PainDataPoint], reportData: ReportData) {
        drawSectionHeader(context: context, title: "Pain Score Trend", icon: "heart.fill")

        // Summary stats
        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        if let avgPain = reportData.avgPainScore {
            let avgText = String(format: "Average Pain Score: %.1f/10", avgPain)
            let avgRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            avgText.draw(in: avgRect, withAttributes: statsAttributes)
            currentY += 18
        }

        if let painChange = reportData.painChange {
            let changeText = String(format: "Pain Change: %@%.1f", painChange >= 0 ? "+" : "", painChange)
            let changeColor = painChange <= 0 ? successColor : errorColor
            let changeAttributes: [NSAttributedString.Key: Any] = [
                .font: boldBodyFont,
                .foregroundColor: changeColor
            ]
            let changeRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            changeText.draw(in: changeRect, withAttributes: changeAttributes)
            currentY += 18
        }

        // Draw chart if enabled
        if reportData.configuration.includeCharts && painTrend.count >= 2 {
            currentY += 10
            drawPainChart(context: context, painTrend: painTrend)
        }

        currentY += 16
    }

    private func drawPainChart(context: CGContext, painTrend: [PainDataPoint]) {
        let chartRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 40, height: 100)

        // Background
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.fill(chartRect)

        // Draw grid lines
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)

        for i in 0...10 {
            let y = chartRect.minY + chartRect.height * CGFloat(i) / 10
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
        }
        context.strokePath()

        // Draw pain line
        guard painTrend.count >= 2 else { return }

        context.setStrokeColor(errorColor.cgColor)
        context.setLineWidth(2)

        let points = painTrend.enumerated().map { index, point -> CGPoint in
            let x = chartRect.minX + chartRect.width * CGFloat(index) / CGFloat(painTrend.count - 1)
            let y = chartRect.maxY - chartRect.height * CGFloat(point.painScore) / 10
            return CGPoint(x: x, y: y)
        }

        context.move(to: points[0])
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()

        // Draw data points
        context.setFillColor(errorColor.cgColor)
        for point in points {
            let dotRect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
            context.fillEllipse(in: dotRect)
        }

        currentY += chartRect.height + 10
    }

    // MARK: - Adherence Section

    private func drawAdherenceSection(context: CGContext, adherence: AdherenceData) {
        drawSectionHeader(context: context, title: "Prescription Adherence", icon: "checkmark.circle.fill")

        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: boldBodyFont,
            .foregroundColor: textColor
        ]

        // Adherence percentage with color coding
        let adherenceColor: UIColor
        switch adherence.adherencePercentage {
        case 80...: adherenceColor = successColor
        case 60..<80: adherenceColor = warningColor
        default: adherenceColor = errorColor
        }

        let adherenceLabel = NSAttributedString(string: "Overall Adherence: ", attributes: labelAttributes)
        let adherenceValue = NSAttributedString(
            string: String(format: "%.0f%%", adherence.adherencePercentage),
            attributes: [.font: boldBodyFont, .foregroundColor: adherenceColor]
        )

        let adherenceCombined = NSMutableAttributedString()
        adherenceCombined.append(adherenceLabel)
        adherenceCombined.append(adherenceValue)

        let adherenceRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
        adherenceCombined.draw(in: adherenceRect)
        currentY += 20

        // Sessions completed
        let sessionsText = "Sessions Completed: \(adherence.completedSessions) of \(adherence.totalSessions)"
        let sessionsRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
        sessionsText.draw(in: sessionsRect, withAttributes: statsAttributes)
        currentY += 18

        // Draw adherence bar
        let barRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 40, height: 20)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.fill(barRect)

        let filledWidth = barRect.width * CGFloat(adherence.adherencePercentage / 100)
        let filledRect = CGRect(x: barRect.minX, y: barRect.minY, width: filledWidth, height: barRect.height)
        context.setFillColor(adherenceColor.cgColor)
        context.fill(filledRect)

        currentY += barRect.height + 20
    }

    // MARK: - Exercise Logs Section

    private func drawExerciseLogsSection(context: CGContext, logs: [ExerciseLogDetail], context pdfContext: UIGraphicsPDFRendererContext) {
        drawSectionHeader(context: context, title: "Exercise Logs", icon: "list.bullet.clipboard")

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: boldBodyFont,
            .foregroundColor: textColor
        ]

        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: textColor
        ]

        // Table header
        let columns = ["Exercise", "Sets", "Reps", "Load", "RPE", "Pain"]
        let columnWidths: [CGFloat] = [0.35, 0.1, 0.15, 0.15, 0.1, 0.1]

        var xOffset = contentStartX + 20
        for (index, header) in columns.enumerated() {
            let width = (contentWidth - 40) * columnWidths[index]
            let rect = CGRect(x: xOffset, y: currentY, width: width, height: 16)
            header.draw(in: rect, withAttributes: headerAttributes)
            xOffset += width
        }
        currentY += 20

        // Draw separator
        context.setStrokeColor(separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: contentStartX + 20, y: currentY))
        context.addLine(to: CGPoint(x: contentEndX - 20, y: currentY))
        context.strokePath()
        currentY += 4

        // Table rows (limit to avoid overflow)
        for log in logs.prefix(20) {
            checkPageBreak(context: pdfContext, requiredHeight: 20)

            let rowData = [
                log.exerciseName,
                "\(log.actualSets)",
                log.repsDisplay,
                log.loadDisplay,
                "\(log.rpe)/10",
                "\(log.painScore)/10"
            ]

            xOffset = contentStartX + 20
            for (index, cell) in rowData.enumerated() {
                let width = (contentWidth - 40) * columnWidths[index]
                let rect = CGRect(x: xOffset, y: currentY, width: width, height: 14)
                cell.draw(in: rect, withAttributes: cellAttributes)
                xOffset += width
            }
            currentY += 16
        }

        if logs.count > 20 {
            let moreText = "... and \(logs.count - 20) more exercises"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: secondaryTextColor
            ]
            let moreRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 40, height: 14)
            moreText.draw(in: moreRect, withAttributes: moreAttributes)
            currentY += 16
        }

        currentY += 16
    }

    // MARK: - Strength Progression Section

    private func drawStrengthProgressionSection(context: CGContext, strengthData: StrengthChartData) {
        drawSectionHeader(context: context, title: "Strength Progression", icon: "dumbbell.fill")

        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        // Exercise name
        if !strengthData.exerciseName.isEmpty {
            let exerciseText = "Exercise: \(strengthData.exerciseName)"
            let exerciseRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            exerciseText.draw(in: exerciseRect, withAttributes: statsAttributes)
            currentY += 18
        }

        // Max weight achieved
        if strengthData.maxWeight > 0 {
            let maxText = String(format: "Max Weight: %.0f lbs", strengthData.maxWeight)
            let maxRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            maxText.draw(in: maxRect, withAttributes: statsAttributes)
            currentY += 18
        }

        // Weight increase
        if strengthData.weightIncrease != 0 {
            let increaseText = String(format: "Weight Change: %@%.0f lbs", strengthData.weightIncrease >= 0 ? "+" : "", strengthData.weightIncrease)
            let increaseColor = strengthData.weightIncrease >= 0 ? successColor : warningColor
            let increaseAttributes: [NSAttributedString.Key: Any] = [
                .font: boldBodyFont,
                .foregroundColor: increaseColor
            ]
            let increaseRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            increaseText.draw(in: increaseRect, withAttributes: increaseAttributes)
            currentY += 18
        }

        currentY += 16
    }

    // MARK: - Goals Section

    private func drawGoalsSection(context: CGContext, goals: [PatientGoal], context pdfContext: UIGraphicsPDFRendererContext) {
        drawSectionHeader(context: context, title: "Treatment Goals", icon: "target")

        let goalAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        for goal in goals.prefix(10) {
            checkPageBreak(context: pdfContext, requiredHeight: 40)

            // Status indicator
            let statusColor: UIColor
            let statusIcon: String
            switch goal.status {
            case .completed:
                statusColor = successColor
                statusIcon = "[ACHIEVED]"
            case .active:
                statusColor = primaryColor
                statusIcon = "[ACTIVE]"
            case .paused:
                statusColor = warningColor
                statusIcon = "[PAUSED]"
            case .cancelled:
                statusColor = secondaryTextColor
                statusIcon = "[CANCELLED]"
            }

            let statusAttributes: [NSAttributedString.Key: Any] = [
                .font: boldBodyFont,
                .foregroundColor: statusColor
            ]

            // Goal title with status
            let titleText = "\(statusIcon) \(goal.title)"
            let titleRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            titleText.draw(in: titleRect, withAttributes: statusAttributes)
            currentY += 18

            // Progress if available
            if let target = goal.targetValue, target > 0 {
                let progressText = String(format: "Progress: %.0f%%", goal.progress * 100)
                let progressRect = CGRect(x: contentStartX + 40, y: currentY, width: contentWidth - 40, height: 14)
                progressText.draw(in: progressRect, withAttributes: goalAttributes)
                currentY += 16
            }

            currentY += 8
        }

        currentY += 8
    }

    // MARK: - Notes Section

    private func drawNotesSection(context: CGContext, notes: [SessionNote], context pdfContext: UIGraphicsPDFRendererContext) {
        drawSectionHeader(context: context, title: "Therapist Notes", icon: "note.text")

        let noteAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]

        for note in notes.prefix(10) {
            checkPageBreak(context: pdfContext, requiredHeight: 50)

            // Date and type
            let dateText = "[\(formatDate(note.createdAt))] - \(note.noteType.capitalized)"
            let dateRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 12)
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
            currentY += 14

            // Note text (wrap to multiple lines if needed)
            let noteText = note.noteText
            let maxWidth = contentWidth - 40
            let noteSize = noteText.boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: noteAttributes,
                context: nil
            )

            let noteRect = CGRect(x: contentStartX + 20, y: currentY, width: maxWidth, height: min(noteSize.height, 60))
            noteText.draw(in: noteRect, withAttributes: noteAttributes)
            currentY += noteRect.height + 12
        }

        currentY += 8
    }

    // MARK: - Outcomes Section

    private func drawOutcomesSection(context: CGContext, reportData: ReportData) {
        drawSectionHeader(context: context, title: "Functional Outcomes", icon: "star.fill")

        let outcomeAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        // Goals summary
        let goalsText = "Goals Achieved: \(reportData.completedGoalsCount) of \(reportData.goals.count)"
        let goalsRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
        goalsText.draw(in: goalsRect, withAttributes: outcomeAttributes)
        currentY += 18

        // Sessions summary
        let sessionsText = "Total Sessions Completed: \(reportData.completedSessionCount)"
        let sessionsRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
        sessionsText.draw(in: sessionsRect, withAttributes: outcomeAttributes)
        currentY += 18

        // Pain improvement
        if let painChange = reportData.painChange {
            let painText: String
            if painChange <= 0 {
                painText = String(format: "Pain Reduction: %.1f points", abs(painChange))
            } else {
                painText = String(format: "Pain Increase: %.1f points", painChange)
            }
            let painRect = CGRect(x: contentStartX + 20, y: currentY, width: contentWidth - 20, height: 16)
            painText.draw(in: painRect, withAttributes: outcomeAttributes)
            currentY += 18
        }

        currentY += 16
    }

    // MARK: - Footer Drawing

    private func drawFooter(context: CGContext, reportData: ReportData?, isIntermediate: Bool = false) {
        let footerY = pageSize.dimensions.height - margins.bottom + 20

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: secondaryTextColor
        ]

        // Page number
        let pageText = "Page \(pageCount)"
        let pageSize = pageText.size(withAttributes: footerAttributes)
        let pageRect = CGRect(
            x: contentEndX - pageSize.width,
            y: footerY,
            width: pageSize.width,
            height: pageSize.height
        )
        pageText.draw(in: pageRect, withAttributes: footerAttributes)

        // App attribution
        let footerText = "Generated by Modus | \(formatDate(Date()))"
        let footerTextSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(
            x: contentStartX,
            y: footerY,
            width: footerTextSize.width,
            height: footerTextSize.height
        )
        footerText.draw(in: footerRect, withAttributes: footerAttributes)

        // HIPAA notice
        if !isIntermediate {
            let hipaaText = "CONFIDENTIAL: This document contains Protected Health Information (PHI)"
            let hipaaAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: warningColor
            ]
            let hipaaSize = hipaaText.size(withAttributes: hipaaAttributes)
            let hipaaRect = CGRect(
                x: (pageRect.width - hipaaSize.width) / 2 + contentStartX,
                y: footerY + footerTextSize.height + 4,
                width: hipaaSize.width,
                height: hipaaSize.height
            )
            hipaaText.draw(in: hipaaRect, withAttributes: hipaaAttributes)
        }
    }

    // MARK: - Helper Methods

    private func drawSectionHeader(context: CGContext, title: String, icon: String) {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: primaryColor
        ]

        let titleText = title
        let titleSize = titleText.size(withAttributes: headerAttributes)
        let titleRect = CGRect(x: contentStartX, y: currentY, width: contentWidth, height: titleSize.height)
        titleText.draw(in: titleRect, withAttributes: headerAttributes)
        currentY += titleSize.height + 12
    }

    private func drawSeparatorLine(context: CGContext) {
        context.setStrokeColor(separatorColor.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: contentStartX, y: currentY))
        context.addLine(to: CGPoint(x: contentEndX, y: currentY))
        context.strokePath()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Chart Data Extensions for PDF Generation

extension StrengthChartData {
    /// Maximum weight achieved in the dataset for PDF reports
    var maxWeight: Double {
        dataPoints.map { $0.weight }.max() ?? currentMax
    }

    /// Weight change from first to last data point
    var weightIncrease: Double {
        guard dataPoints.count >= 2,
              let first = dataPoints.first?.weight,
              let last = dataPoints.last?.weight else {
            return currentMax - startingMax
        }
        return last - first
    }
}
