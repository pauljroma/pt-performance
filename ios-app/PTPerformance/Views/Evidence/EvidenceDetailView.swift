//
//  EvidenceDetailView.swift
//  PTPerformance
//
//  X2Index Phase 2 - M6: AI Provenance and Evidence Linking
//  Full-screen evidence view with comprehensive claim details
//
//  Features:
//  - The claim at top
//  - All contributing sources
//  - Confidence calculation breakdown
//  - Related claims
//  - Feedback mechanism ("Was this helpful?")
//

import SwiftUI

// MARK: - Evidence Detail View

/// Full-screen view showing complete evidence for an AI claim
struct EvidenceDetailView: View {
    let claim: EvidenceClaim
    var onNavigateToSource: ((EvidenceClaim.EvidenceRef) -> Void)?
    var onMarkReviewed: (() -> Void)?
    var onRelatedClaimTap: ((EvidenceClaim) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var provenanceService: ProvenanceService

    @State private var sources: [EvidenceSource] = []
    @State private var confidenceBreakdown: ConfidenceBreakdown?
    @State private var relatedClaims: [EvidenceClaim] = []
    @State private var isLoadingSources = true
    @State private var selectedSource: EvidenceSource?
    @State private var showSourceDrilldown = false
    @State private var feedbackSubmitted = false
    @State private var feedbackIsHelpful: Bool?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Claim summary
                    claimSummarySection

                    // Confidence breakdown
                    confidenceBreakdownSection

                    // Evidence sources
                    evidenceSourcesSection

                    // Related claims
                    if !relatedClaims.isEmpty {
                        relatedClaimsSection
                    }

                    // Model metadata
                    modelMetadataSection

                    // PT Review section
                    if claim.reviewState.ptReviewRequired {
                        reviewSection
                    }

                    // Feedback section
                    feedbackSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Evidence Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSourceDrilldown) {
                if let source = selectedSource {
                    SourceDrilldown(source: source) {
                        // Navigate to original record
                        if let ref = claim.evidenceRefs.first(where: { $0.id == source.id }) {
                            onNavigateToSource?(ref)
                        }
                    }
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Load sources
        sources = await provenanceService.getClaimSources(claimId: claim.claimId)

        // Calculate confidence breakdown
        confidenceBreakdown = provenanceService.calculateDetailedConfidence(from: sources)

        // Load related claims (claims with overlapping sources)
        await loadRelatedClaims()

        isLoadingSources = false
    }

    private func loadRelatedClaims() async {
        // In a real implementation, this would query for claims with overlapping evidence
        // For now, we'll leave it empty as this requires additional backend support
        relatedClaims = []
    }

    // MARK: - Claim Summary Section

    @ViewBuilder
    private var claimSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with type
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: claim.claimType.icon)
                        .font(.title2)
                        .foregroundColor(typeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.claimType.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: Spacing.xs) {
                        Text("AI Generated")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if claim.uncertaintyFlag {
                            UncertaintyIndicator(isCompact: true)
                        }
                    }
                }

                Spacer()

                ConfidenceBadge(
                    confidence: claim.confidenceScore,
                    size: .large,
                    showLabel: true,
                    showTooltip: true
                )
            }

            // Claim text
            Text(claim.claimText)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)

            // Abstention warning if low confidence
            if provenanceService.shouldAbstain(confidence: claim.confidenceScore, claimType: claim.claimType) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("This claim has limited supporting evidence and should be verified.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Confidence Breakdown Section

    @ViewBuilder
    private var confidenceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Confidence Analysis", systemImage: "chart.bar.fill")
                .font(.headline)

            if let breakdown = confidenceBreakdown {
                // Overall score
                HStack(spacing: Spacing.lg) {
                    VStack(spacing: 4) {
                        Text(breakdown.overallPercentage)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(confidenceColor)

                        Text("Overall")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 60)

                    VStack(spacing: 4) {
                        Text("\(breakdown.sourceCount)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.modusCyan)

                        Text("Sources")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)

                // Component breakdown
                VStack(spacing: Spacing.sm) {
                    confidenceRow(
                        label: "Data Quality",
                        value: breakdown.qualityScore,
                        icon: "checkmark.shield.fill"
                    )
                    confidenceRow(
                        label: "Data Recency",
                        value: breakdown.recencyScore,
                        icon: "clock.fill"
                    )
                    confidenceRow(
                        label: "Source Diversity",
                        value: breakdown.diversityScore,
                        icon: "square.grid.2x2.fill"
                    )
                }

                // Recommendation
                HStack(spacing: Spacing.sm) {
                    Image(systemName: recommendationIcon(breakdown.recommendation))
                        .foregroundColor(recommendationColor(breakdown.recommendation))

                    Text(breakdown.recommendation.displayMessage)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(recommendationColor(breakdown.recommendation).opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private func confidenceRow(label: String, value: Double, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.modusCyan)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor(value))
                        .frame(width: geometry.size.width * value, height: 6)
                }
            }
            .frame(width: 80, height: 6)

            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(value))
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func scoreColor(_ value: Double) -> Color {
        switch value {
        case 0.8...1.0: return .modusTealAccent
        case 0.5..<0.8: return .modusCyan
        case 0.3..<0.5: return .orange
        default: return .red
        }
    }

    private func recommendationIcon(_ rec: ConfidenceRecommendation) -> String {
        switch rec {
        case .highConfidence: return "checkmark.circle.fill"
        case .proceed: return "checkmark.circle"
        case .proceedWithCaution: return "exclamationmark.triangle.fill"
        case .abstain: return "xmark.circle.fill"
        }
    }

    private func recommendationColor(_ rec: ConfidenceRecommendation) -> Color {
        switch rec {
        case .highConfidence: return .modusTealAccent
        case .proceed: return .modusCyan
        case .proceedWithCaution: return .orange
        case .abstain: return .red
        }
    }

    // MARK: - Evidence Sources Section

    @ViewBuilder
    private var evidenceSourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Evidence Sources", systemImage: "doc.text.fill")
                .font(.headline)

            if isLoadingSources {
                HStack {
                    ProgressView()
                    Text("Loading sources...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if sources.isEmpty {
                Text("No detailed source data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(sources, id: \.id) { source in
                    EvidenceSourceDetailCard(source: source) {
                        selectedSource = source
                        showSourceDrilldown = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Related Claims Section

    @ViewBuilder
    private var relatedClaimsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Related Insights", systemImage: "link")
                .font(.headline)

            ForEach(relatedClaims) { relatedClaim in
                Button {
                    onRelatedClaimTap?(relatedClaim)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: relatedClaim.claimType.icon)
                            .font(.body)
                            .foregroundColor(typeColor(for: relatedClaim))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(relatedClaim.claimType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(relatedClaim.claimText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }

                        Spacer()

                        ConfidenceScoreBadge(confidence: relatedClaim.confidenceScore, size: .small)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Model Metadata Section

    @ViewBuilder
    private var modelMetadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Model Information", systemImage: "cpu")
                .font(.headline)

            VStack(spacing: Spacing.xs) {
                metadataRow(label: "Model Version", value: claim.modelMetadata.modelVersion)
                metadataRow(label: "Generated", value: claim.modelMetadata.generatedAt.formatted(date: .abbreviated, time: .shortened))
                if !claim.modelMetadata.retrievalSetHash.isEmpty {
                    metadataRow(label: "Retrieval Hash", value: String(claim.modelMetadata.retrievalSetHash.prefix(12)) + "...")
                }
                metadataRow(label: "Claim ID", value: String(claim.claimId.uuidString.prefix(8)) + "...")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundColor(.primary)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Review Section

    @ViewBuilder
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("PT Review", systemImage: "person.badge.shield.checkmark")
                .font(.headline)

            if claim.reviewState.isReviewed {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.modusTealAccent)
                        Text("Reviewed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let reviewedAt = claim.reviewState.reviewedAt {
                        Text("Reviewed on \(reviewedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let notes = claim.reviewState.reviewNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.top, Spacing.xxs)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.modusTealAccent.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Pending Review")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }

                    Text("This claim requires PT review before being shown to the athlete.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let onMarkReviewed = onMarkReviewed {
                        Button {
                            HapticFeedback.medium()
                            onMarkReviewed()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Mark as Reviewed")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.modusCyan)
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Feedback Section

    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Feedback", systemImage: "hand.thumbsup")
                .font(.headline)

            if feedbackSubmitted {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                    Text("Thank you for your feedback!")
                        .font(.subheadline)
                        .foregroundColor(.modusTealAccent)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.modusTealAccent.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    Text("Was this insight helpful?")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.md) {
                        // Helpful button
                        Button {
                            submitFeedback(isHelpful: true)
                        } label: {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                Text("Yes")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.modusTealAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.modusTealAccent.opacity(0.15))
                            .cornerRadius(CornerRadius.md)
                        }

                        // Not helpful button
                        Button {
                            submitFeedback(isHelpful: false)
                        } label: {
                            HStack {
                                Image(systemName: "hand.thumbsdown.fill")
                                Text("No")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func submitFeedback(isHelpful: Bool) {
        HapticFeedback.success()
        feedbackIsHelpful = isHelpful
        feedbackSubmitted = true

        Task {
            try? await provenanceService.recordFeedback(
                claimId: claim.claimId,
                isHelpful: isHelpful
            )
        }
    }

    // MARK: - Helpers

    private var typeColor: Color {
        typeColor(for: claim)
    }

    private func typeColor(for claim: EvidenceClaim) -> Color {
        switch claim.claimType {
        case .safetyWarning, .riskAlert: return .red
        case .readinessTrend, .recoveryInsight: return .modusTealAccent
        case .nutritionInsight: return .modusCyan
        case .trainingRecommendation: return .blue
        case .biomarkerChange: return .purple
        }
    }

    private var confidenceColor: Color {
        switch claim.confidenceLevel {
        case .high: return .modusTealAccent
        case .medium: return .modusCyan
        case .low: return .orange
        }
    }
}

// MARK: - Evidence Source Detail Card

/// Detailed card for a single evidence source
struct EvidenceSourceDetailCard: View {
    let source: EvidenceSource
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.modusCyan.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: source.sourceType.icon)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.sourceType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(source.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Quality indicators
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.caption2)
                            Text("\(Int(source.qualityScore * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.modusTealAccent)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("\(Int(source.recencyScore * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.modusCyan)
                    }
                }

                // Snippet
                Text(source.snippet)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Data value
                if let value = source.dataValue {
                    HStack {
                        Text("Value:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusTealAccent)
                    }
                }

                // Tap to drill down
                HStack {
                    Spacer()
                    Label("View Details", systemImage: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct EvidenceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EvidenceDetailView(
            claim: EvidenceClaim.sampleRiskAlert,
            onNavigateToSource: { _ in },
            onMarkReviewed: {}
        )
        .environmentObject(ProvenanceService.preview)
        .previewDisplayName("Risk Alert")

        EvidenceDetailView(
            claim: EvidenceClaim.sampleBiomarkerClaim,
            onNavigateToSource: { _ in }
        )
        .environmentObject(ProvenanceService.preview)
        .previewDisplayName("Biomarker Claim")
    }
}
#endif
