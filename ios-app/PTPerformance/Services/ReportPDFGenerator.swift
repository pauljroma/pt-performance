//
//  ReportPDFGenerator.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  PDF generation for weekly therapist reports
//

import Foundation
import UIKit
import PDFKit

// MARK: - Report PDF Generator

/// Generates PDF documents from weekly reports
/// Uses UIGraphicsPDFRenderer for professional-quality output
final class ReportPDFGenerator {

    // MARK: - Constants

    private let pageWidth: CGFloat = 612 // Letter size (8.5 x 11 inches at 72 dpi)
    private let pageHeight: CGFloat = 792
    private let marginLeft: CGFloat = 50
    private let marginRight: CGFloat = 50
    private let marginTop: CGFloat = 50
    private let marginBottom: CGFloat = 50

    private var contentWidth: CGFloat {
        pageWidth - marginLeft - marginRight
    }

    // MARK: - Colors

    private let primaryColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
    private let successColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
    private let warningColor = UIColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0)
    private let dangerColor = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    private let textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let subtextColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    private let backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)

    // MARK: - Fonts

    private let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    private let headingFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    private let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    private let labelFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    private let valueFont = UIFont.systemFont(ofSize: 14, weight: .bold)

    // MARK: - Public Methods

    /// Generate a PDF from a weekly report
    /// - Parameters:
    ///   - report: The WeeklyReport to render
    ///   - patientName: Patient's full name
    /// - Returns: PDF data
    func generatePDF(from report: WeeklyReport, patientName: String) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = marginTop

            // Header
            yPosition = drawHeader(report: report, patientName: patientName, yPosition: yPosition, context: context)

            // Overall Status Card
            yPosition = drawStatusCard(report: report, yPosition: yPosition, context: context)

            // Key Metrics Section
            yPosition = drawMetricsSection(report: report, yPosition: yPosition, context: context)

            // Check if we need a new page
            if yPosition > pageHeight - marginBottom - 200 {
                context.beginPage()
                yPosition = marginTop
            }

            // Goals Progress Section
            yPosition = drawGoalsSection(report: report, yPosition: yPosition, context: context)

            // Check if we need a new page
            if yPosition > pageHeight - marginBottom - 200 {
                context.beginPage()
                yPosition = marginTop
            }

            // AI Recommendations Section
            yPosition = drawAISection(report: report, yPosition: yPosition, context: context)

            // Check if we need a new page
            if yPosition > pageHeight - marginBottom - 150 {
                context.beginPage()
                yPosition = marginTop
            }

            // Highlights Section (Achievements, Concerns, Recommendations)
            yPosition = drawHighlightsSection(report: report, yPosition: yPosition, context: context)

            // Footer
            drawFooter(report: report, context: context)
        }

        return data
    }

    // MARK: - Drawing Methods

    private func drawHeader(report: WeeklyReport, patientName: String, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Logo placeholder (app name)
        let logoText = "Modus"
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: primaryColor
        ]
        logoText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: logoAttributes)

        // Generated date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let generatedText = "Generated: \(dateFormatter.string(from: report.generatedAt))"
        let generatedAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: subtextColor
        ]
        let generatedSize = (generatedText as NSString).size(withAttributes: generatedAttributes)
        generatedText.draw(at: CGPoint(x: pageWidth - marginRight - generatedSize.width, y: y), withAttributes: generatedAttributes)

        y += 30

        // Title
        let titleText = "Weekly Progress Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: textColor
        ]
        titleText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: titleAttributes)

        y += 35

        // Patient Name and Week Range
        let patientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: textColor
        ]
        patientName.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: patientAttributes)

        y += 25

        let weekText = "Week of \(report.dateRangeString)"
        let weekAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: subtextColor
        ]
        weekText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: weekAttributes)

        y += 20

        // Divider line
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: marginLeft, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - marginRight, y: y))
        context.cgContext.strokePath()

        return y + 20
    }

    private func drawStatusCard(report: WeeklyReport, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        let status = report.overallStatus
        let statusColor: UIColor
        switch status {
        case .excellent: statusColor = successColor
        case .good: statusColor = primaryColor
        case .fair: statusColor = warningColor
        case .needsAttention: statusColor = dangerColor
        }

        // Status card background
        let cardRect = CGRect(x: marginLeft, y: y, width: contentWidth, height: 50)
        context.cgContext.setFillColor(statusColor.withAlphaComponent(0.1).cgColor)
        context.cgContext.fill(cardRect)

        // Status indicator circle
        let circleRect = CGRect(x: marginLeft + 15, y: y + 15, width: 20, height: 20)
        context.cgContext.setFillColor(statusColor.cgColor)
        context.cgContext.fillEllipse(in: circleRect)

        // Status text
        let statusText = status.displayName
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: statusColor
        ]
        statusText.draw(at: CGPoint(x: marginLeft + 45, y: y + 15), withAttributes: statusAttributes)

        return y + 70
    }

    private func drawMetricsSection(report: WeeklyReport, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Section Title
        let sectionTitle = "Key Metrics"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: textColor
        ]
        sectionTitle.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: sectionAttributes)

        y += 25

        // Metrics Grid (2x2)
        let cardWidth = (contentWidth - 20) / 2
        let cardHeight: CGFloat = 70

        // Session Completion
        drawMetricCard(
            title: "Session Completion",
            value: report.completionRateDisplay,
            subtitle: "\(report.totalSessionsCompleted)/\(report.totalSessionsScheduled) sessions",
            trend: nil,
            rect: CGRect(x: marginLeft, y: y, width: cardWidth, height: cardHeight),
            context: context
        )

        // Adherence
        drawMetricCard(
            title: "Adherence Score",
            value: report.adherenceDisplay,
            subtitle: "Overall compliance",
            trend: nil,
            rect: CGRect(x: marginLeft + cardWidth + 20, y: y, width: cardWidth, height: cardHeight),
            context: context
        )

        y += cardHeight + 10

        // Pain Level
        let painValue = report.averagePainLevel.map { String(format: "%.1f", $0) } ?? "N/A"
        drawMetricCard(
            title: "Average Pain",
            value: painValue,
            subtitle: report.painTrend.displayName,
            trend: report.painTrend,
            rect: CGRect(x: marginLeft, y: y, width: cardWidth, height: cardHeight),
            context: context
        )

        // Recovery
        let recoveryValue = report.averageRecoveryScore.map { String(format: "%.0f", $0) } ?? "N/A"
        drawMetricCard(
            title: "Recovery Score",
            value: recoveryValue,
            subtitle: report.recoveryTrend.displayName,
            trend: report.recoveryTrend,
            rect: CGRect(x: marginLeft + cardWidth + 20, y: y, width: cardWidth, height: cardHeight),
            context: context
        )

        return y + cardHeight + 20
    }

    private func drawMetricCard(title: String, value: String, subtitle: String, trend: TrendDirection?, rect: CGRect, context: UIGraphicsPDFRendererContext) {
        // Card background
        context.cgContext.setFillColor(backgroundColor.cgColor)
        context.cgContext.fill(rect)

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: subtextColor
        ]
        title.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 10), withAttributes: titleAttributes)

        // Value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: textColor
        ]
        value.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 25), withAttributes: valueAttributes)

        // Subtitle with trend indicator
        var subtitleText = subtitle
        if let trend = trend {
            let arrow: String
            switch trend {
            case .improving: arrow = " ↑"
            case .stable: arrow = " →"
            case .declining: arrow = " ↓"
            case .fluctuating: arrow = " ~"
            }
            subtitleText += arrow
        }

        let subtitleColor: UIColor
        if let trend = trend {
            switch trend {
            case .improving: subtitleColor = successColor
            case .stable: subtitleColor = primaryColor
            case .declining: subtitleColor = dangerColor
            case .fluctuating: subtitleColor = UIColor.orange
            }
        } else {
            subtitleColor = subtextColor
        }

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: subtitleColor
        ]
        subtitleText.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 52), withAttributes: subtitleAttributes)
    }

    private func drawGoalsSection(report: WeeklyReport, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Section Title
        let sectionTitle = "Goals Progress"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: textColor
        ]
        sectionTitle.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: sectionAttributes)

        y += 25

        guard !report.goalsProgress.isEmpty else {
            let noGoalsText = "No goals tracked this week"
            let noGoalsAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: subtextColor
            ]
            noGoalsText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: noGoalsAttributes)
            return y + 30
        }

        for goal in report.goalsProgress {
            // Goal name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: textColor
            ]
            goal.goalName.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: nameAttributes)

            // Percentage
            let percentAttributes: [NSAttributedString.Key: Any] = [
                .font: valueFont,
                .foregroundColor: textColor
            ]
            let percentText = goal.percentDisplay
            let percentSize = (percentText as NSString).size(withAttributes: percentAttributes)
            percentText.draw(at: CGPoint(x: pageWidth - marginRight - percentSize.width, y: y), withAttributes: percentAttributes)

            y += 18

            // Progress bar background
            let barHeight: CGFloat = 8
            let barRect = CGRect(x: marginLeft, y: y, width: contentWidth, height: barHeight)
            context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
            context.cgContext.fill(barRect)

            // Progress bar fill
            let progressWidth = contentWidth * CGFloat(goal.progressFraction)
            let progressRect = CGRect(x: marginLeft, y: y, width: progressWidth, height: barHeight)

            let progressColor: UIColor
            if goal.percentComplete >= 100 {
                progressColor = successColor
            } else if goal.percentComplete >= 75 {
                progressColor = primaryColor
            } else if goal.percentComplete >= 50 {
                progressColor = warningColor
            } else {
                progressColor = dangerColor
            }

            context.cgContext.setFillColor(progressColor.cgColor)
            context.cgContext.fill(progressRect)

            y += barHeight + 15
        }

        return y + 10
    }

    private func drawAISection(report: WeeklyReport, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Section Title
        let sectionTitle = "AI Recommendations"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: textColor
        ]
        sectionTitle.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: sectionAttributes)

        y += 25

        // AI adoption stats
        let adoptionText = "\(report.aiRecommendationsAdopted) of \(report.aiRecommendationsTotal) recommendations adopted"
        let adoptionAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]
        adoptionText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: adoptionAttributes)

        y += 20

        // Adoption rate bar
        let barHeight: CGFloat = 10
        let barRect = CGRect(x: marginLeft, y: y, width: contentWidth, height: barHeight)
        context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
        context.cgContext.fill(barRect)

        if report.aiRecommendationsTotal > 0 {
            let adoptionRate = Double(report.aiRecommendationsAdopted) / Double(report.aiRecommendationsTotal)
            let progressWidth = contentWidth * CGFloat(adoptionRate)
            let progressRect = CGRect(x: marginLeft, y: y, width: progressWidth, height: barHeight)
            context.cgContext.setFillColor(primaryColor.cgColor)
            context.cgContext.fill(progressRect)
        }

        y += barHeight + 10

        // Adoption percentage
        let percentText = String(format: "%.0f%% adoption rate", report.aiAdoptionRate)
        let percentAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: subtextColor
        ]
        percentText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: percentAttributes)

        return y + 30
    }

    private func drawHighlightsSection(report: WeeklyReport, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Achievements
        if !report.achievements.isEmpty {
            y = drawBulletList(title: "Achievements", items: report.achievements, color: successColor, yPosition: y, context: context)
        }

        // Concerns
        if !report.concerns.isEmpty {
            y = drawBulletList(title: "Concerns", items: report.concerns, color: warningColor, yPosition: y, context: context)
        }

        // Recommendations
        if !report.recommendations.isEmpty {
            y = drawBulletList(title: "Recommendations", items: report.recommendations, color: primaryColor, yPosition: y, context: context)
        }

        return y
    }

    private func drawBulletList(title: String, items: [String], color: UIColor, yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Section Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: color
        ]
        title.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: titleAttributes)

        y += 25

        for item in items {
            // Bullet point
            let bulletRect = CGRect(x: marginLeft + 5, y: y + 4, width: 6, height: 6)
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: bulletRect)

            // Item text
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: textColor
            ]

            let itemRect = CGRect(x: marginLeft + 20, y: y, width: contentWidth - 20, height: 40)
            let attributedText = NSAttributedString(string: item, attributes: itemAttributes)

            let textStorage = NSTextStorage(attributedString: attributedText)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: itemRect.size)
            textContainer.lineFragmentPadding = 0
            layoutManager.addTextContainer(textContainer)

            let textBounds = layoutManager.usedRect(for: textContainer)
            attributedText.draw(in: itemRect)

            y += max(textBounds.height + 8, 20)
        }

        return y + 10
    }

    private func drawFooter(report: WeeklyReport, context: UIGraphicsPDFRendererContext) {
        let y = pageHeight - marginBottom + 10

        // Divider
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: marginLeft, y: y - 10))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - marginRight, y: y - 10))
        context.cgContext.strokePath()

        // Footer text
        let footerText = "Generated by Modus | Report ID: \(report.id.uuidString.prefix(8))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: subtextColor
        ]
        footerText.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: footerAttributes)

        // Confidentiality notice
        let confidentialText = "CONFIDENTIAL - Protected Health Information"
        let confidentialSize = (confidentialText as NSString).size(withAttributes: footerAttributes)
        confidentialText.draw(at: CGPoint(x: pageWidth - marginRight - confidentialSize.width, y: y), withAttributes: footerAttributes)
    }
}
