//
//  EvidenceClaimCard.swift
//  PTPerformance
//
//  Card displaying an AI-generated claim with tap-to-evidence
//  Shows confidence indicator and source count badge
//  Expandable to show full evidence list
//

import SwiftUI

/// Card displaying an AI-generated claim with full provenance
struct EvidenceClaimCard: View {
    let claim: EvidenceClaim
    var onTap: (() -> Void)?
    var onEvidenceTap: ((EvidenceClaim.EvidenceRef) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            headerView

            // Claim text
            claimTextView

            // Confidence indicator
            confidenceIndicator

            // Expand/collapse for evidence
            if !claim.evidenceRefs.isEmpty {
                expandToggle
            }

            // Expanded evidence list
            if isExpanded {
                evidenceListView
            }

            // Footer with timestamp
            footerView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(borderColor.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: Spacing.sm) {
            // Type indicator
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: claim.claimType.icon)
                    .font(.body)
                    .foregroundColor(typeColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(claim.claimType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(typeColor)

                    // AI badge
                    Text("AI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.xs)

                    // Uncertainty flag
                    if claim.uncertaintyFlag {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .accessibilityLabel("Uncertainty flagged")
                    }
                }

                // Review status badge
                if claim.reviewState.isPendingReview {
                    Text("Pending Review")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(CornerRadius.xs)
                }
            }

            Spacer()

            // Source count badge
            sourceCountBadge
        }
    }

    // MARK: - Source Count Badge

    @ViewBuilder
    private var sourceCountBadge: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isExpanded.toggle()
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.caption2)
                Text("\(claim.sourceCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(confidenceColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel("\(claim.sourceCount) evidence sources. Tap to \(isExpanded ? "hide" : "show") details")
    }

    // MARK: - Claim Text

    @ViewBuilder
    private var claimTextView: some View {
        Text(claim.claimText)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineLimit(isExpanded ? nil : 3)
            .fixedSize(horizontal: false, vertical: isExpanded)
    }

    // MARK: - Confidence Indicator

    @ViewBuilder
    private var confidenceIndicator: some View {
        HStack(spacing: Spacing.sm) {
            // Confidence bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 4)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * claim.confidenceScore, height: 4)
                }
            }
            .frame(height: 4)

            // Confidence label
            Text(claim.confidenceLevel.displayName)
                .font(.caption2)
                .foregroundColor(confidenceColor)
                .fixedSize()
        }
        .accessibilityLabel("Confidence: \(Int(claim.confidenceScore * 100)) percent, \(claim.confidenceLevel.displayName)")
    }

    // MARK: - Expand Toggle

    @ViewBuilder
    private var expandToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isExpanded.toggle()
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(isExpanded ? "Hide Evidence" : "View Evidence")
                    .font(.caption)
                    .foregroundColor(.modusCyan)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
            }
        }
        .accessibilityLabel(isExpanded ? "Hide evidence details" : "Show evidence details")
    }

    // MARK: - Evidence List

    @ViewBuilder
    private var evidenceListView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
                .padding(.vertical, Spacing.xxs)

            ForEach(claim.evidenceRefs) { ref in
                EvidenceRefRow(evidenceRef: ref) {
                    onEvidenceTap?(ref)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerView: some View {
        HStack {
            // Model version (subtle)
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

    // MARK: - Computed Properties

    private var confidenceColor: Color {
        switch claim.confidenceLevel {
        case .high: return .modusTealAccent
        case .medium: return .modusCyan
        case .low: return .orange
        }
    }

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
        return typeColor
    }

    private var accessibilityLabel: String {
        var label = "\(claim.claimType.displayName): \(claim.claimText)"
        label += ". Confidence: \(claim.confidenceLevel.displayName)"
        label += ". \(claim.sourceCount) evidence sources"
        if claim.uncertaintyFlag {
            label += ". Uncertainty flagged"
        }
        if claim.reviewState.isPendingReview {
            label += ". Pending PT review"
        }
        return label
    }
}

// MARK: - Evidence Reference Row

/// Compact row showing a single evidence reference
struct EvidenceRefRow: View {
    let evidenceRef: EvidenceClaim.EvidenceRef
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Source type icon
                Image(systemName: evidenceRef.sourceType.icon)
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    // Source type
                    Text(evidenceRef.sourceType.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Snippet
                    Text(evidenceRef.snippet)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // Data value if present
                    if let value = evidenceRef.dataValue {
                        Text(value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusTealAccent)
                    }
                }

                Spacer()

                // Timestamp
                VStack(alignment: .trailing, spacing: 2) {
                    Text(evidenceRef.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.xs)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(evidenceRef.sourceType.displayName): \(evidenceRef.snippet)")
        .accessibilityHint("Tap to view original data")
    }
}

// MARK: - Claims List View

/// List of evidence claims with expandable details
struct EvidenceClaimsList: View {
    let claims: [EvidenceClaim]
    var onClaimTap: ((EvidenceClaim) -> Void)?
    var onEvidenceTap: ((EvidenceClaim.EvidenceRef) -> Void)?

    var body: some View {
        if claims.isEmpty {
            emptyStateView
        } else {
            LazyVStack(spacing: Spacing.md) {
                ForEach(claims) { claim in
                    EvidenceClaimCard(
                        claim: claim,
                        onTap: { onClaimTap?(claim) },
                        onEvidenceTap: onEvidenceTap
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No Claims Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("AI-generated insights with evidence will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Claim Row

/// Compact row for showing claims in a list
struct EvidenceClaimRow: View {
    let claim: EvidenceClaim
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Type icon
                Image(systemName: claim.claimType.icon)
                    .font(.body)
                    .foregroundColor(typeColor)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(claim.claimType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(claim.claimText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                // Confidence and source count
                VStack(alignment: .trailing, spacing: 4) {
                    // Confidence badge
                    Text("\(Int(claim.confidenceScore * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(confidenceColor)

                    // Source count
                    HStack(spacing: 2) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption2)
                        Text("\(claim.sourceCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(claim.claimType.displayName): \(claim.claimText)")
        .accessibilityHint("Tap to view evidence details")
    }

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

// MARK: - Preview

#if DEBUG
struct EvidenceClaimCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Evidence Claim Cards")
                    .font(.headline)

                // High confidence claim
                EvidenceClaimCard(
                    claim: EvidenceClaim.sampleBiomarkerClaim
                )

                // Medium confidence with uncertainty
                EvidenceClaimCard(
                    claim: EvidenceClaim.sampleRiskAlert
                )

                // Readiness trend
                EvidenceClaimCard(
                    claim: EvidenceClaim.sampleReadinessClaim
                )

                Text("Compact Row")
                    .font(.headline)
                    .padding(.top)

                EvidenceClaimRow(
                    claim: EvidenceClaim.sampleReadinessClaim
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
