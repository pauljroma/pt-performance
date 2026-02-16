//
//  EvidenceClaimCard.swift
//  PTPerformance
//
//  X2Index Phase 2 - M6: AI Provenance and Evidence Linking
//  Card component showing AI claim with confidence and source evidence
//
//  Features:
//  - Claim text with confidence badge
//  - "Based on X sources" expandable section
//  - Source list with timestamps
//  - Uncertainty indicator if confidence < 0.7
//  - "AI abstained" state for low confidence
//

import SwiftUI

// MARK: - Evidence Claim Card Component

/// Card showing AI claim with provenance, confidence, and expandable evidence
struct EvidenceClaimCardComponent: View {
    let claim: EvidenceClaim
    var onTap: (() -> Void)?
    var onEvidenceTap: ((EvidenceClaim.EvidenceRef) -> Void)?
    var onViewDetails: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @State private var sources: [EvidenceSource] = []
    @State private var isLoadingSources = false

    @StateObject private var provenanceService = ProvenanceService()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with type and confidence
            headerView

            // Claim text
            claimTextView

            // Confidence indicator with uncertainty
            confidenceSection

            // Sources expandable section
            if !claim.evidenceRefs.isEmpty {
                sourcesSection
            }

            // Expanded source list
            if isExpanded {
                expandedSourcesView
            }

            // Footer with metadata
            footerView
        }
        .padding()
        .background(cardBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: Spacing.sm) {
            // Type indicator
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: claim.claimType.icon)
                    .font(.body)
                    .foregroundColor(typeColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.xs) {
                    Text(claim.claimType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(typeColor)

                    // AI badge
                    Text("AI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.xs)
                }

                // Review status
                if claim.reviewState.isPendingReview {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("Pending Review")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }

            Spacer()

            // Confidence badge
            ConfidenceBadge(
                confidence: claim.confidenceScore,
                size: .medium,
                showLabel: true,
                showTooltip: true
            )
        }
    }

    // MARK: - Claim Text

    @ViewBuilder
    private var claimTextView: some View {
        Text(claim.claimText)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(isExpanded ? nil : 3)
            .fixedSize(horizontal: false, vertical: isExpanded)
    }

    // MARK: - Confidence Section

    @ViewBuilder
    private var confidenceSection: some View {
        HStack(spacing: Spacing.sm) {
            // Confidence bar
            ConfidenceBar(confidence: claim.confidenceScore)

            // Uncertainty indicator if flagged
            if claim.uncertaintyFlag || claim.confidenceScore < 0.7 {
                UncertaintyIndicator(
                    tooltip: uncertaintyTooltip,
                    isCompact: true
                )
            }
        }
    }

    private var uncertaintyTooltip: String {
        if claim.confidenceScore < 0.5 {
            return "Low confidence - limited data supports this claim"
        } else if claim.confidenceScore < 0.7 {
            return "Moderate uncertainty - consider additional data"
        } else {
            return "Some uncertainty exists with this claim"
        }
    }

    // MARK: - Sources Section

    @ViewBuilder
    private var sourcesSection: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isExpanded.toggle()
                if isExpanded && sources.isEmpty {
                    loadSources()
                }
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.modusCyan)

                Text("Based on \(claim.sourceCount) source\(claim.sourceCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.modusCyan)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
            }
            .padding(.vertical, Spacing.xs)
        }
        .accessibilityLabel("\(claim.sourceCount) evidence sources. Tap to \(isExpanded ? "hide" : "show") details")
    }

    // MARK: - Expanded Sources

    @ViewBuilder
    private var expandedSourcesView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()

            if isLoadingSources {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading sources...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.sm)
            } else {
                ForEach(claim.evidenceRefs) { ref in
                    EvidenceSourceRow(evidenceRef: ref) {
                        onEvidenceTap?(ref)
                    }
                }

                // View full details button
                if let onViewDetails = onViewDetails {
                    Button {
                        HapticFeedback.medium()
                        onViewDetails()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                            Text("View Full Evidence Details")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.modusCyan)
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerView: some View {
        HStack {
            // Model version
            Text("v\(claim.modelMetadata.modelVersion)")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))

            Spacer()

            // Timestamp
            Text(claim.modelMetadata.generatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(borderColor.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private var typeColor: Color {
        switch claim.claimType {
        case .safetyWarning, .riskAlert: return .red
        case .readinessTrend, .recoveryInsight: return .modusTealAccent
        case .nutritionInsight: return .modusCyan
        case .trainingRecommendation: return .blue
        case .biomarkerChange: return .purple
        }
    }

    private var borderColor: Color {
        if claim.reviewState.isPendingReview {
            return .orange
        }
        if claim.confidenceScore < 0.5 {
            return .red.opacity(0.5)
        }
        return typeColor
    }

    private var accessibilityLabel: String {
        var label = "\(claim.claimType.displayName): \(claim.claimText)"
        label += ". Confidence: \(Int(claim.confidenceScore * 100)) percent"
        label += ". \(claim.sourceCount) evidence sources"
        if claim.uncertaintyFlag {
            label += ". Uncertainty flagged"
        }
        if claim.reviewState.isPendingReview {
            label += ". Pending PT review"
        }
        return label
    }

    private func loadSources() {
        isLoadingSources = true
        Task {
            sources = await provenanceService.getClaimSources(claimId: claim.claimId)
            isLoadingSources = false
        }
    }
}

// MARK: - Evidence Source Row

/// Row showing a single evidence source
struct EvidenceSourceRow: View {
    let evidenceRef: EvidenceClaim.EvidenceRef
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Source type icon
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.15))
                        .frame(width: 28, height: 28)

                    Image(systemName: evidenceRef.sourceType.icon)
                        .font(.caption2)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    // Source type and reliability
                    HStack(spacing: Spacing.xs) {
                        Text(evidenceRef.sourceType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text("\(Int(evidenceRef.sourceType.reliabilityWeight * 100))%")
                            .font(.caption2)
                            .foregroundColor(.modusTealAccent)
                    }

                    // Snippet
                    Text(evidenceRef.snippet)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Data value
                    if let value = evidenceRef.dataValue {
                        Text(value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusTealAccent)
                    }
                }

                Spacer()

                // Timestamp and chevron
                VStack(alignment: .trailing, spacing: 2) {
                    Text(evidenceRef.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.sm)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(evidenceRef.sourceType.displayName): \(evidenceRef.snippet)")
        .accessibilityHint("Tap to view original data")
    }
}

// MARK: - Abstained Claim Card

/// Card showing AI abstained from making a claim
struct AbstainedClaimCard: View {
    let claimType: EvidenceClaim.ClaimType
    let reason: String
    var onCollectData: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "hand.raised.fill")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Abstained")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(claimType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                AbstentionBadge(reason: "Insufficient data", isCompact: true)
            }

            // Reason
            Text(reason)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Action button
            if let onCollectData = onCollectData {
                Button {
                    HapticFeedback.medium()
                    onCollectData()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Data")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.modusCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan.opacity(0.15))
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.secondary.opacity(0.3))
                )
        )
        .accessibilityLabel("AI abstained from \(claimType.displayName): \(reason)")
    }
}

// MARK: - Preview

#if DEBUG
struct EvidenceClaimCardComponent_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Evidence Claim Cards")
                    .font(.headline)

                // High confidence
                EvidenceClaimCardComponent(
                    claim: EvidenceClaim.sampleBiomarkerClaim
                )
                .environmentObject(ProvenanceService.preview)

                // Medium confidence with uncertainty
                EvidenceClaimCardComponent(
                    claim: EvidenceClaim.sampleRiskAlert
                )
                .environmentObject(ProvenanceService.preview)

                // Readiness trend
                EvidenceClaimCardComponent(
                    claim: EvidenceClaim.sampleReadinessClaim
                )
                .environmentObject(ProvenanceService.preview)

                Divider()

                Text("Abstained State")
                    .font(.headline)

                AbstainedClaimCard(
                    claimType: .trainingRecommendation,
                    reason: "Not enough recent training data to make a reliable recommendation. Complete a few more workouts to enable this insight.",
                    onCollectData: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
