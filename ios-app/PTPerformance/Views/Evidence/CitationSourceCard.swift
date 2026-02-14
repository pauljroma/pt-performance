//
//  CitationSourceCard.swift
//  PTPerformance
//
//  X2Index Command Center - M2: Evidence Citation System
//  Individual citation display card
//
//  Features:
//  - Source icon and type
//  - Confidence grade badge (A-D with color)
//  - Excerpt preview
//  - Timestamp
//  - Expandable detail
//

import SwiftUI

// MARK: - Citation Source Card

/// Card displaying a single evidence citation with expandable details
struct CitationSourceCard: View {
    let citation: EvidenceCitation
    var isExpanded: Bool = false
    var onTap: (() -> Void)?
    var onViewOriginal: (() -> Void)?

    @State private var showingDetail = false

    var body: some View {
        Button {
            HapticService.light()
            if let onTap = onTap {
                onTap()
            } else {
                showingDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header row
                headerRow

                // Excerpt preview
                if let excerpt = citation.excerptPreview {
                    excerptView(excerpt)
                }

                // Expanded content
                if isExpanded || showingDetail {
                    expandedContent
                }

                // Footer row
                footerRow
            }
            .padding()
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .sheet(isPresented: $showingDetail) {
            CitationDetailSheet(
                citation: citation,
                onViewOriginal: onViewOriginal != nil ? { _ in onViewOriginal?() } : nil
            )
        }
    }

    // MARK: - Header Row

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: Spacing.xs) {
            // Source type icon
            ZStack {
                Circle()
                    .fill(citation.sourceType.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: citation.sourceType.iconName)
                    .font(.caption)
                    .foregroundColor(citation.sourceType.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(citation.sourceTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(citation.sourceType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Confidence grade badge
            ConfidenceGradeBadge(grade: citation.confidence, size: .medium)
        }
    }

    // MARK: - Excerpt View

    @ViewBuilder
    private func excerptView(_ excerpt: String) -> some View {
        Text(excerpt)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(isExpanded ? nil : 2)
            .padding(Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()

            // Confidence explanation
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundColor(citation.confidence.color)

                Text(citation.confidence.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Reliability score
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.modusCyan)

                Text("Reliability: \(Int(citation.sourceType.reliabilityWeight * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // View original link
            if citation.hasViewableURL || onViewOriginal != nil {
                Button {
                    HapticService.medium()
                    onViewOriginal?()
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)

                        Text("View Original")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Footer Row

    @ViewBuilder
    private var footerRow: some View {
        HStack {
            // Timestamp
            Text(citation.relativeTimeDescription)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            // Expand indicator
            if !isExpanded && onTap == nil {
                HStack(spacing: 2) {
                    Text("Details")
                        .font(.caption2)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.modusCyan)
            }
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(citation.confidence.color.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(citation.sourceTitle) from \(citation.sourceType.displayName)"
        label += ". Confidence grade \(citation.confidence.rawValue): \(citation.confidence.displayLabel)"
        if let excerpt = citation.excerpt {
            label += ". \(excerpt)"
        }
        label += ". \(citation.relativeTimeDescription)"
        return label
    }
}

// MARK: - Compact Citation Card

/// Smaller version of citation card for inline display
struct CompactCitationCard: View {
    let citation: EvidenceCitation
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticService.light()
            onTap?()
        } label: {
            HStack(spacing: Spacing.xs) {
                // Source icon
                Image(systemName: citation.sourceType.iconName)
                    .font(.caption)
                    .foregroundColor(citation.sourceType.color)
                    .frame(width: 20)

                // Title
                Text(citation.sourceTitle)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Grade badge
                Text(citation.confidence.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(citation.confidence.color)
                    .cornerRadius(CornerRadius.xs)

                // Timestamp
                Text(citation.relativeTimeDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Citation Preview Card

/// Preview card showing top citations for a claim
struct CitationPreviewCard: View {
    let citations: [EvidenceCitation]
    let overallConfidence: ConfidenceGrade
    var onViewAll: (() -> Void)?

    private var topCitations: [EvidenceCitation] {
        Array(citations.prefix(3))
    }

    private var remainingCount: Int {
        max(0, citations.count - 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header
            HStack {
                Label("Evidence Sources", systemImage: "doc.text.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                ConfidenceGradeBadge(grade: overallConfidence, size: .small)
            }

            // Top citations
            ForEach(topCitations) { citation in
                CompactCitationCard(citation: citation)
            }

            // View all button
            if remainingCount > 0 || onViewAll != nil {
                Button {
                    HapticService.selection()
                    onViewAll?()
                } label: {
                    HStack {
                        if remainingCount > 0 {
                            Text("+ \(remainingCount) more source\(remainingCount == 1 ? "" : "s")")
                        } else {
                            Text("View All Sources")
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Inline Citation Badge

/// Minimal inline badge for showing citation in text
struct InlineCitationBadge: View {
    let sourceType: CitationSourceType
    let grade: ConfidenceGrade
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticService.light()
            onTap?()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: sourceType.iconName)
                    .font(.system(size: 8))
                    .foregroundColor(sourceType.color)

                Text(grade.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(grade.color)
            }
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, 2)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Citation Strength Indicator

/// Visual indicator of citation strength/quantity
struct CitationStrengthIndicator: View {
    let citationCount: Int
    let overallConfidence: ConfidenceGrade

    private var strengthLevel: StrengthLevel {
        switch citationCount {
        case 0:
            return .none
        case 1:
            return .low
        case 2...3:
            return .moderate
        case 4...5:
            return .good
        default:
            return .excellent
        }
    }

    private enum StrengthLevel {
        case none, low, moderate, good, excellent

        var barCount: Int {
            switch self {
            case .none: return 0
            case .low: return 1
            case .moderate: return 2
            case .good: return 3
            case .excellent: return 4
            }
        }

        var label: String {
            switch self {
            case .none: return "No sources"
            case .low: return "Limited"
            case .moderate: return "Moderate"
            case .good: return "Good"
            case .excellent: return "Excellent"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Strength bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(index < strengthLevel.barCount ? overallConfidence.color : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 6, height: 12)
                }
            }

            // Label
            Text("\(citationCount) sources")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(strengthLevel.label) evidence strength with \(citationCount) sources")
    }
}

// MARK: - Preview

#if DEBUG
struct CitationSourceCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Full card
                Text("Citation Source Card")
                    .font(.headline)

                CitationSourceCard(citation: EvidenceCitation.sampleLabCitation)

                CitationSourceCard(
                    citation: EvidenceCitation.sampleHealthKitCitation,
                    isExpanded: true
                )

                // Compact card
                Text("Compact Citation Card")
                    .font(.headline)

                CompactCitationCard(citation: EvidenceCitation.sampleWhoopCitation)
                CompactCitationCard(citation: EvidenceCitation.sampleCheckInCitation)

                // Preview card
                Text("Citation Preview Card")
                    .font(.headline)

                CitationPreviewCard(
                    citations: EvidenceCitation.sampleCitations,
                    overallConfidence: .good
                )

                // Inline badges
                Text("Inline Badges")
                    .font(.headline)

                HStack {
                    Text("Your HRV shows improvement")
                    InlineCitationBadge(sourceType: .healthKit, grade: .high)
                    Text("based on")
                    InlineCitationBadge(sourceType: .whoop, grade: .good)
                }
                .font(.subheadline)

                // Strength indicators
                Text("Strength Indicators")
                    .font(.headline)

                HStack(spacing: 20) {
                    CitationStrengthIndicator(citationCount: 0, overallConfidence: .low)
                    CitationStrengthIndicator(citationCount: 1, overallConfidence: .moderate)
                    CitationStrengthIndicator(citationCount: 3, overallConfidence: .good)
                    CitationStrengthIndicator(citationCount: 6, overallConfidence: .high)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
