// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ReviewSummaryCard.swift
//  PTPerformance
//
//  ACP-395: PT Review Workflow - Review Summary Card
//  Compact summary card for the review queue and program detail view.
//
//  Features:
//  - Program name and patient name
//  - AI confidence score as circular progress indicator (color-coded)
//  - Review status badge (color-coded pill)
//  - Contraindication count with severity indicator
//  - Evidence citation count
//  - Relative time since submission
//  - Tap action for navigation
//

import SwiftUI

// MARK: - ProgramReviewStatus UI Extensions

/// View-layer computed properties for ProgramReviewStatus (defined in ProgramReview.swift).
extension ProgramReviewStatus {
    var color: Color {
        switch self {
        case .draft: return .secondary
        case .pendingReview: return DesignTokens.statusWarning
        case .inReview: return DesignTokens.statusInfo
        case .approved: return DesignTokens.statusSuccess
        case .rejected: return DesignTokens.statusError
        }
    }

    var iconName: String {
        switch self {
        case .draft: return "doc.fill"
        case .pendingReview: return "clock.fill"
        case .inReview: return "eye.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}

// MARK: - Review Summary Data

/// Data model for the review summary card.
/// Aggregates information from the program, patient, and AI review.
struct ReviewSummaryData {
    let programName: String
    let patientName: String
    let aiConfidenceScore: Double
    let reviewStatus: ProgramReviewStatus
    let contraindicationCount: Int
    let criticalContraindicationCount: Int
    let evidenceCitationCount: Int
    let submittedAt: Date
}

// MARK: - Review Summary Card

/// A compact summary card used in the review queue and program detail view.
///
/// Displays program and patient info, AI confidence as a circular indicator,
/// review status, contraindication and citation counts, and submission time.
/// Tapping the card triggers navigation to the full review detail.
struct ReviewSummaryCard: View {

    // MARK: - Properties

    let data: ReviewSummaryData
    let onTap: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap()
        } label: {
            HStack(spacing: Spacing.md) {
                // AI confidence circular indicator
                confidenceIndicator

                // Program and patient info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Program name
                    Text(data.programName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Patient name
                    Text(data.patientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Metadata row
                    metadataRow
                }

                Spacer()

                // Right column: status badge + chevron
                VStack(alignment: .trailing, spacing: Spacing.sm) {
                    reviewStatusBadge

                    // Submission time
                    Text(data.submittedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.md)
            .background(cardBackground)
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor, lineWidth: hasCriticalIssues ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to open program review")
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 4)
                .frame(width: 52, height: 52)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(data.aiConfidenceScore / 100.0, 1.0)))
                .stroke(
                    confidenceColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))

            // Score label
            VStack(spacing: 0) {
                Text("\(Int(data.aiConfidenceScore))")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor)

                Text("%")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(confidenceColor.opacity(0.8))
            }
        }
        .accessibilityLabel("AI confidence: \(Int(data.aiConfidenceScore)) percent")
    }

    private var confidenceColor: Color {
        switch data.aiConfidenceScore {
        case 80...:
            return DesignTokens.statusSuccess
        case 60..<80:
            return DesignTokens.statusWarning
        default:
            return DesignTokens.statusError
        }
    }

    // MARK: - Review Status Badge

    private var reviewStatusBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: data.reviewStatus.iconName)
                .font(.caption2)

            Text(data.reviewStatus.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(data.reviewStatus.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(data.reviewStatus.color.opacity(0.12))
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Spacing.sm) {
            // Evidence citations
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "book.fill")
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("\(data.evidenceCitationCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("\(data.evidenceCitationCount) evidence citations")

            // Contraindications (if any)
            if data.contraindicationCount > 0 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: contraindicationIcon)
                        .font(.caption2)
                        .foregroundColor(contraindicationColor)
                        .accessibilityHidden(true)

                    Text("\(data.contraindicationCount)")
                        .font(.caption)
                        .fontWeight(data.criticalContraindicationCount > 0 ? .semibold : .regular)
                        .foregroundColor(contraindicationColor)
                }
                .accessibilityLabel(contraindicationAccessibilityLabel)
            }
        }
    }

    // MARK: - Contraindication Helpers

    private var contraindicationIcon: String {
        if data.criticalContraindicationCount > 0 {
            return "exclamationmark.triangle.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }

    private var contraindicationColor: Color {
        if data.criticalContraindicationCount > 0 {
            return DesignTokens.statusError
        } else {
            return DesignTokens.statusWarning
        }
    }

    private var contraindicationAccessibilityLabel: String {
        if data.criticalContraindicationCount > 0 {
            return "\(data.contraindicationCount) contraindications, \(data.criticalContraindicationCount) critical"
        } else {
            return "\(data.contraindicationCount) contraindications"
        }
    }

    private var hasCriticalIssues: Bool {
        data.criticalContraindicationCount > 0 || data.aiConfidenceScore < 60
    }

    // MARK: - Card Styling

    private var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    private var borderColor: Color {
        if data.criticalContraindicationCount > 0 {
            return DesignTokens.statusError.opacity(0.4)
        } else if data.aiConfidenceScore < 60 {
            return DesignTokens.statusError.opacity(0.3)
        } else {
            return .clear
        }
    }

    // MARK: - Accessibility

    /// Cached formatter for relative date descriptions in accessibility labels.
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private var accessibilityDescription: String {
        var label = "\(data.programName) for \(data.patientName)"
        label += ". AI confidence \(Int(data.aiConfidenceScore)) percent"
        label += ". Status: \(data.reviewStatus.displayName)"
        if data.contraindicationCount > 0 {
            label += ". \(data.contraindicationCount) contraindication\(data.contraindicationCount == 1 ? "" : "s")"
            if data.criticalContraindicationCount > 0 {
                label += ", \(data.criticalContraindicationCount) critical"
            }
        }
        label += ". \(data.evidenceCitationCount) evidence citation\(data.evidenceCitationCount == 1 ? "" : "s")"
        let relativeTime = Self.relativeDateFormatter.localizedString(for: data.submittedAt, relativeTo: Date())
        label += ". Submitted \(relativeTime)"
        return label
    }
}

// MARK: - Preview

#if DEBUG

private extension ReviewSummaryData {
    static let sampleHighConfidence = ReviewSummaryData(
        programName: "ACL Return to Sport Phase 3",
        patientName: "John Brebbia",
        aiConfidenceScore: 92,
        reviewStatus: .pendingReview,
        contraindicationCount: 1,
        criticalContraindicationCount: 0,
        evidenceCitationCount: 8,
        submittedAt: Date().addingTimeInterval(-3600)
    )

    static let sampleMediumConfidence = ReviewSummaryData(
        programName: "Shoulder Impingement Rehab",
        patientName: "Sarah Johnson",
        aiConfidenceScore: 72,
        reviewStatus: .inReview,
        contraindicationCount: 3,
        criticalContraindicationCount: 1,
        evidenceCitationCount: 5,
        submittedAt: Date().addingTimeInterval(-7200)
    )

    static let sampleLowConfidence = ReviewSummaryData(
        programName: "Complex Multi-Joint Program",
        patientName: "Mike Williams",
        aiConfidenceScore: 48,
        reviewStatus: .inReview,
        contraindicationCount: 4,
        criticalContraindicationCount: 2,
        evidenceCitationCount: 3,
        submittedAt: Date().addingTimeInterval(-86400)
    )

    static let sampleApproved = ReviewSummaryData(
        programName: "Post-Op Knee Protocol",
        patientName: "Emily Davis",
        aiConfidenceScore: 95,
        reviewStatus: .approved,
        contraindicationCount: 0,
        criticalContraindicationCount: 0,
        evidenceCitationCount: 12,
        submittedAt: Date().addingTimeInterval(-172800)
    )

    static let sampleRejected = ReviewSummaryData(
        programName: "High-Intensity Plyometrics",
        patientName: "Tom Wilson",
        aiConfidenceScore: 35,
        reviewStatus: .rejected,
        contraindicationCount: 5,
        criticalContraindicationCount: 3,
        evidenceCitationCount: 2,
        submittedAt: Date().addingTimeInterval(-259200)
    )
}

#Preview("Review Summary Cards") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            Text("Review Queue")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)

            ReviewSummaryCard(
                data: .sampleHighConfidence,
                onTap: { print("Tapped high confidence") }
            )

            ReviewSummaryCard(
                data: .sampleMediumConfidence,
                onTap: { print("Tapped medium confidence") }
            )

            ReviewSummaryCard(
                data: .sampleLowConfidence,
                onTap: { print("Tapped low confidence") }
            )

            ReviewSummaryCard(
                data: .sampleApproved,
                onTap: { print("Tapped approved") }
            )

            ReviewSummaryCard(
                data: .sampleRejected,
                onTap: { print("Tapped rejected") }
            )
        }
        .padding(Spacing.md)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Card - Critical") {
    ReviewSummaryCard(
        data: .sampleLowConfidence,
        onTap: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
