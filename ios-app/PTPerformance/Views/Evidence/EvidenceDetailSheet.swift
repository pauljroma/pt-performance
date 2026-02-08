//
//  EvidenceDetailSheet.swift
//  PTPerformance
//
//  Sheet showing full evidence for an AI-generated claim
//  Lists all sources with timestamps
//  Navigates to original data (lab result, check-in, etc.)
//

import SwiftUI

/// Sheet showing full evidence for a claim
struct EvidenceDetailSheet: View {
    let claim: EvidenceClaim
    var onNavigateToSource: ((EvidenceClaim.EvidenceRef) -> Void)?
    var onMarkReviewed: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedEvidence: EvidenceClaim.EvidenceRef?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Claim summary section
                    claimSummarySection

                    // Confidence breakdown
                    confidenceSection

                    // Evidence list
                    evidenceSection

                    // Model metadata
                    metadataSection

                    // Review section
                    if claim.reviewState.ptReviewRequired {
                        reviewSection
                    }
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
        }
    }

    // MARK: - Claim Summary Section

    @ViewBuilder
    private var claimSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: claim.claimType.icon)
                        .font(.title3)
                        .foregroundColor(typeColor)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.claimType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xs) {
                        Text("AI Generated")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if claim.uncertaintyFlag {
                            Label("Uncertainty", systemImage: "questionmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()
            }

            // Claim text
            Text(claim.claimText)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Confidence Section

    @ViewBuilder
    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Confidence Analysis", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: Spacing.lg) {
                // Confidence score
                VStack(spacing: 4) {
                    Text("\(Int(claim.confidenceScore * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(confidenceColor)

                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // Source count
                VStack(spacing: 4) {
                    Text("\(claim.sourceCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)

                    Text("Sources")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // Source diversity
                VStack(spacing: 4) {
                    Text("\(claim.uniqueSourceTypes.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.modusTealAccent)

                    Text("Types")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            // Confidence bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(confidenceColor)
                            .frame(width: geometry.size.width * claim.confidenceScore, height: 8)
                    }
                }
                .frame(height: 8)

                Text(claim.confidenceLevel.displayName)
                    .font(.caption)
                    .foregroundColor(confidenceColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Evidence Section

    @ViewBuilder
    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Evidence Sources", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundColor(.primary)

            if claim.evidenceRefs.isEmpty {
                Text("No evidence sources available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(claim.evidenceRefs) { ref in
                    EvidenceSourceCard(
                        evidenceRef: ref,
                        isSelected: selectedEvidence?.id == ref.id
                    ) {
                        selectedEvidence = ref
                        onNavigateToSource?(ref)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Metadata Section

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Model Information", systemImage: "cpu")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: Spacing.xs) {
                metadataRow(label: "Model Version", value: claim.modelMetadata.modelVersion)
                metadataRow(label: "Generated", value: claim.modelMetadata.generatedAt.formatted(date: .abbreviated, time: .shortened))
                if !claim.modelMetadata.retrievalSetHash.isEmpty {
                    metadataRow(label: "Retrieval Hash", value: String(claim.modelMetadata.retrievalSetHash.prefix(8)) + "...")
                }
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
                .foregroundColor(.primary)
                .fontDesign(.monospaced)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Review Section

    @ViewBuilder
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("PT Review", systemImage: "person.badge.shield.checkmark")
                .font(.headline)
                .foregroundColor(.primary)

            if claim.reviewState.isReviewed {
                // Reviewed state
                VStack(alignment: .leading, spacing: 4) {
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
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.modusTealAccent.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            } else {
                // Pending review state
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
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
                            .padding(.vertical, Spacing.sm)
                            .background(Color.modusCyan)
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Computed Properties

    private var typeColor: Color {
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

// MARK: - Evidence Source Card

/// Card showing detailed information about an evidence source
struct EvidenceSourceCard: View {
    let evidenceRef: EvidenceClaim.EvidenceRef
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    // Source type icon
                    ZStack {
                        Circle()
                            .fill(Color.modusCyan.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: evidenceRef.sourceType.icon)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(evidenceRef.sourceType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(evidenceRef.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Reliability indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(evidenceRef.sourceType.reliabilityWeight * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusTealAccent)

                        Text("Reliability")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Snippet
                Text(evidenceRef.snippet)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                // Data value if present
                if let value = evidenceRef.dataValue {
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

                // Navigate to source
                HStack {
                    Spacer()
                    Label("View Original", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(evidenceRef.sourceType.displayName): \(evidenceRef.snippet)")
        .accessibilityHint("Tap to view the original data source")
    }
}

// MARK: - Evidence Timeline View

/// Timeline view showing evidence chronologically
struct EvidenceTimelineView: View {
    let evidenceRefs: [EvidenceClaim.EvidenceRef]
    var onEvidenceTap: ((EvidenceClaim.EvidenceRef) -> Void)?

    private var sortedRefs: [EvidenceClaim.EvidenceRef] {
        evidenceRefs.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sortedRefs.enumerated()), id: \.element.id) { index, ref in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    // Timeline
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.modusCyan)
                            .frame(width: 12, height: 12)

                        if index < sortedRefs.count - 1 {
                            Rectangle()
                                .fill(Color.modusCyan.opacity(0.3))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 12)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ref.sourceType.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.modusCyan)

                            Spacer()

                            Text(ref.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text(ref.snippet)
                            .font(.caption)
                            .foregroundColor(.primary)

                        if let value = ref.dataValue {
                            Text(value)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.modusTealAccent)
                        }
                    }
                    .padding(.bottom, Spacing.md)
                    .onTapGesture {
                        HapticFeedback.light()
                        onEvidenceTap?(ref)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EvidenceDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        EvidenceDetailSheet(
            claim: EvidenceClaim.sampleRiskAlert,
            onNavigateToSource: { _ in },
            onMarkReviewed: {}
        )

        EvidenceDetailSheet(
            claim: EvidenceClaim.sampleBiomarkerClaim,
            onNavigateToSource: { _ in }
        )
        .previewDisplayName("Reviewed Claim")
    }
}
#endif
