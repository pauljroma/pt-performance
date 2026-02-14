//
//  EvidenceCitationView.swift
//  PTPerformance
//
//  X2Index Command Center - M2: Evidence Citation System
//  Full citation list view with grouped sources
//
//  Features:
//  - Grouped by source type
//  - Confidence grade badges
//  - Tap to expand source details
//  - "View Original" links where applicable
//

import SwiftUI

// MARK: - Evidence Citation View

/// Full-screen view showing all citations for a claim
struct EvidenceCitationView: View {
    @StateObject private var viewModel: EvidenceCitationViewModel
    @Environment(\.dismiss) private var dismiss

    var onViewOriginal: ((EvidenceCitation) -> Void)?

    // MARK: - Initialization

    init(claimId: UUID, onViewOriginal: ((EvidenceCitation) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EvidenceCitationViewModel(claimId: claimId))
        self.onViewOriginal = onViewOriginal
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Evidence Sources")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(item: $viewModel.selectedCitation) { citation in
                    CitationDetailSheet(
                        citation: citation,
                        onViewOriginal: onViewOriginal
                    )
                }
        }
        .task {
            await viewModel.loadCitations()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingView

        case .loaded:
            loadedContent

        case .empty:
            emptyView

        case .error(let message):
            errorView(message: message)

        case .idle:
            Color.clear
                .task {
                    await viewModel.loadCitations()
                }
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading citations...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loaded Content

    @ViewBuilder
    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Summary header
                summaryHeader

                // Grouped citations
                ForEach(viewModel.groupedCitations) { group in
                    CitationGroupSection(
                        group: group,
                        isExpanded: viewModel.isExpanded(group.sourceType),
                        onToggle: { viewModel.toggleExpansion(for: group.sourceType) },
                        onSelectCitation: { viewModel.selectCitation($0) }
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Overall confidence
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Overall Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.xs) {
                        ConfidenceGradeBadge(
                            grade: viewModel.overallConfidence,
                            size: .large
                        )

                        Text(viewModel.overallConfidence.description)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text("Total Sources")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.citationCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                }
            }

            // Source type distribution
            HStack(spacing: Spacing.xs) {
                ForEach(viewModel.sourceTypes, id: \.self) { sourceType in
                    SourceTypePill(
                        sourceType: sourceType,
                        count: viewModel.citations(for: sourceType).count
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Empty View

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Citations Available")
                .font(.headline)

            Text("This claim doesn't have any linked evidence sources yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Citations")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Citation Group Section

/// Expandable section showing citations from a single source type
struct CitationGroupSection: View {
    let group: CitationGroup
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelectCitation: (EvidenceCitation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: Spacing.xs) {
                    // Source type icon
                    ZStack {
                        Circle()
                            .fill(group.sourceType.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: group.sourceType.iconName)
                            .font(.body)
                            .foregroundColor(group.sourceType.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.sourceType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(group.count) citation\(group.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Max confidence badge
                    ConfidenceGradeBadge(grade: group.maxConfidence, size: .small)

                    // Expansion indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(group.citations) { citation in
                        CitationRow(citation: citation) {
                            onSelectCitation(citation)
                        }

                        if citation.id != group.citations.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.tertiarySystemGroupedBackground))
            }
        }
        .cornerRadius(CornerRadius.md)
        .animation(.easeInOut(duration: DesignTokens.animationDurationNormal), value: isExpanded)
    }
}

// MARK: - Citation Row

/// Single citation row in the list
struct CitationRow: View {
    let citation: EvidenceCitation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Confidence grade
                ConfidenceGradeBadge(grade: citation.confidence, size: .small)

                // Content
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(citation.sourceTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let excerpt = citation.excerptPreview {
                        Text(excerpt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Text(citation.relativeTimeDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Source Type Pill

/// Small pill showing source type with count
struct SourceTypePill: View {
    let sourceType: CitationSourceType
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: sourceType.iconName)
                .font(.caption2)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(sourceType.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(sourceType.color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Confidence Grade Badge

/// Badge displaying A-D confidence grade
struct ConfidenceGradeBadge: View {
    let grade: ConfidenceGrade
    var size: BadgeSize = .medium

    /// Use the canonical top-level BadgeSize enum
    typealias BadgeSize = PTPerformance.BadgeSize

    var body: some View {
        Text(grade.rawValue)
            .font(size.labelFont)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(minWidth: size.minWidth)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(grade.color)
            .cornerRadius(CornerRadius.sm)
            .accessibilityLabel("Grade \(grade.rawValue): \(grade.displayLabel)")
    }
}

// MARK: - Citation Detail Sheet

/// Sheet showing full citation details
struct CitationDetailSheet: View {
    let citation: EvidenceCitation
    var onViewOriginal: ((EvidenceCitation) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header
                    headerSection

                    // Excerpt
                    if let excerpt = citation.excerpt, !excerpt.isEmpty {
                        excerptSection(excerpt)
                    }

                    // Metadata
                    metadataSection

                    // View original button
                    if citation.hasViewableURL || onViewOriginal != nil {
                        viewOriginalButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Citation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                // Source type icon
                ZStack {
                    Circle()
                        .fill(citation.sourceType.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: citation.sourceType.iconName)
                        .font(.title2)
                        .foregroundColor(citation.sourceType.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(citation.sourceTitle)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(citation.sourceType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ConfidenceGradeBadge(grade: citation.confidence, size: .large)
            }

            // Confidence description
            Text(citation.confidence.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(citation.confidence.color.opacity(0.1))
                .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private func excerptSection(_ excerpt: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Evidence Excerpt", systemImage: "quote.bubble.fill")
                .font(.headline)

            Text(excerpt)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Details", systemImage: "info.circle.fill")
                .font(.headline)

            VStack(spacing: Spacing.xs) {
                metadataRow(label: "Captured", value: citation.formattedTimestamp)
                metadataRow(label: "Source ID", value: String(citation.sourceId.prefix(12)) + "...")
                metadataRow(label: "Reliability", value: "\(Int(citation.sourceType.reliabilityWeight * 100))%")
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var viewOriginalButton: some View {
        Button {
            HapticService.medium()
            onViewOriginal?(citation)
        } label: {
            HStack {
                Image(systemName: "arrow.up.right.square.fill")
                Text("View Original Data")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - View Sources Button

/// Compact button for showing "View Sources (N)" on insight cards
struct ViewSourcesButton: View {
    let claimId: UUID
    @State private var citationCount: Int = 0
    @State private var isShowingCitations = false

    var onViewOriginal: ((EvidenceCitation) -> Void)?

    var body: some View {
        Button {
            HapticService.selection()
            isShowingCitations = true
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)

                Text("View Sources (\(citationCount))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.modusCyan)
        }
        .task {
            citationCount = await CitationService.shared.getCitationCount(for: claimId)
        }
        .sheet(isPresented: $isShowingCitations) {
            EvidenceCitationView(claimId: claimId, onViewOriginal: onViewOriginal)
        }
    }
}

// MARK: - Citation Count Badge

/// Badge showing citation count for PT Brief section headers
struct CitationCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "doc.text.fill")
                .font(.caption2)

            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.modusCyan)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.modusCyan.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(count) citations")
    }
}

// MARK: - Preview

#if DEBUG
struct EvidenceCitationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Loaded state
            EvidenceCitationView(claimId: CitationService.sampleClaimId)
                .previewDisplayName("Loaded")

            // Citation Detail Sheet
            CitationDetailSheet(citation: EvidenceCitation.sampleLabCitation)
                .previewDisplayName("Citation Detail")

            // View Sources Button
            VStack(spacing: 20) {
                ViewSourcesButton(claimId: CitationService.sampleClaimId)

                CitationCountBadge(count: 5)

                ConfidenceGradeBadge(grade: .high, size: .large)
                ConfidenceGradeBadge(grade: .good, size: .medium)
                ConfidenceGradeBadge(grade: .moderate, size: .small)
                ConfidenceGradeBadge(grade: .low, size: .small)
            }
            .padding()
            .previewDisplayName("Components")
        }
    }
}
#endif
