// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  InteractionResultCard.swift
//  PTPerformance
//
//  ACP-441: Reusable card component for displaying a single supplement interaction.
//  Shows severity, supplements involved, interaction type, description,
//  and expandable recommendation/mechanism details.
//

import SwiftUI

/// Reusable card for displaying a single supplement or medication interaction.
///
/// Features:
/// - Severity color band on left edge (red/orange/yellow/gray)
/// - Icon matching severity level
/// - Supplement names involved (bold)
/// - Interaction type pill badge
/// - Description text
/// - Expandable recommendation section
/// - Full accessibility support
struct InteractionResultCard: View {

    // MARK: - Properties

    let interaction: SupplementInteraction

    // MARK: - Private State

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Severity color band on left edge
            severityBand

            // Card content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header row: icon, supplements, severity badge
                headerRow

                // Interaction type pill
                interactionTypeBadge

                // Description
                Text(interaction.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Expandable recommendation section
                if isExpanded {
                    recommendationSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Expand/collapse button
                expandButton
            }
            .padding(Spacing.md)
        }
        .background(cardBackgroundColor)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(severityColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    /// Colored severity band on the left edge
    private var severityBand: some View {
        Rectangle()
            .fill(severityColor)
            .frame(width: 4)
            .accessibilityHidden(true)
    }

    /// Header row with severity icon, supplement names, and type
    private var headerRow: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Severity icon
            Image(systemName: severityIcon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(severityColor)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            // Supplement names
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("\(interaction.supplement1) + \(interaction.supplement2)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(interaction.severity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)
            }

            Spacer()
        }
    }

    /// Interaction type pill badge
    private var interactionTypeBadge: some View {
        Text(interaction.interactionType.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(interactionTypeColor.opacity(0.12))
            .foregroundColor(interactionTypeColor)
            .cornerRadius(CornerRadius.xs)
            .accessibilityLabel("Interaction type: \(interaction.interactionType.displayName)")
    }

    /// Expandable recommendation section
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()

            Label {
                Text("Recommendation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            .accessibilityAddTraits(.isHeader)

            Text(interaction.recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.xxs)
    }

    /// Expand/collapse toggle button
    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isExpanded.toggle()
            }
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(isExpanded ? "Show Less" : "Show Recommendation")
                    .font(.caption)
                    .fontWeight(.medium)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(severityColor)
        }
        .accessibilityLabel(isExpanded ? "Collapse recommendation" : "Expand recommendation")
        .accessibilityHint("Shows actionable advice for this interaction")
    }

    // MARK: - Computed Properties

    /// Color for the severity level
    private var severityColor: Color {
        switch interaction.severity {
        case .critical: return .red
        case .major: return .orange
        case .moderate: return .yellow
        case .minor: return .secondary
        }
    }

    /// SF Symbol icon for the severity level
    private var severityIcon: String {
        switch interaction.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .major: return "exclamationmark.circle.fill"
        case .moderate: return "info.circle.fill"
        case .minor: return "checkmark.circle.fill"
        }
    }

    /// Background color for the card based on severity
    private var cardBackgroundColor: Color {
        switch interaction.severity {
        case .critical:
            return Color.red.opacity(colorScheme == .dark ? 0.10 : 0.04)
        case .major:
            return Color.orange.opacity(colorScheme == .dark ? 0.10 : 0.04)
        case .moderate:
            return Color.yellow.opacity(colorScheme == .dark ? 0.08 : 0.03)
        case .minor:
            return Color(.secondarySystemGroupedBackground)
        }
    }

    /// Color for the interaction type badge
    private var interactionTypeColor: Color {
        switch interaction.interactionType {
        case .toxicity: return .red
        case .bleeding: return .orange
        case .absorption: return .blue
        case .efficacy: return .purple
        case .metabolic: return .teal
        case .other: return .secondary
        }
    }

    /// Accessibility description combining all card information
    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append("\(interaction.severity.displayName) severity interaction")
        parts.append("between \(interaction.supplement1) and \(interaction.supplement2)")
        parts.append("Type: \(interaction.interactionType.displayName)")
        parts.append(interaction.description)
        if isExpanded {
            parts.append("Recommendation: \(interaction.recommendation)")
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Safety Warning Card

/// Card for displaying a single safety warning for a supplement.
///
/// Used in the collapsible safety warnings section of the interaction checker view.
struct SafetyWarningCard: View {

    let warning: SafetyWarning

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: warningIcon)
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(warning.supplement)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(warningTypeDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(warning.description)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: Spacing.xxs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .accessibilityHidden(true)

                        Text(warning.recommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(warning.supplement) safety warning: \(warning.description)")
        .accessibilityHint(isExpanded ? "" : "Double tap to expand for details")
    }

    // MARK: - Computed Properties

    private var warningIcon: String {
        switch warning.warningType {
        case "dosage": return "scalemass"
        case "duration": return "clock.badge.exclamationmark"
        case "condition": return "heart.text.square"
        case "general": return "exclamationmark.shield"
        default: return "exclamationmark.triangle"
        }
    }

    private var warningTypeDisplay: String {
        switch warning.warningType {
        case "dosage": return "Dosage Warning"
        case "duration": return "Duration Warning"
        case "condition": return "Condition Warning"
        case "general": return "General Warning"
        default: return "Safety Warning"
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Critical Interaction") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            InteractionResultCard(
                interaction: SupplementInteraction(
                    supplement1: "Vitamin K",
                    supplement2: "Warfarin",
                    interactionType: .efficacy,
                    severity: .critical,
                    description: "Vitamin K directly counteracts warfarin anticoagulant effect.",
                    recommendation: "Maintain consistent Vitamin K intake. Any changes require INR monitoring and possible dose adjustment."
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Severity Levels") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            ForEach(SupplementInteraction.sampleInteractions) { interaction in
                InteractionResultCard(interaction: interaction)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Safety Warning") {
    ScrollView {
        VStack(spacing: Spacing.sm) {
            ForEach(SafetyWarning.sampleWarnings) { warning in
                SafetyWarningCard(warning: warning)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
