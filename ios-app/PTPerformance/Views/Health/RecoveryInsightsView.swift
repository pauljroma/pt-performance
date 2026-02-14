// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// View displaying recovery impact insights and personalized recommendations
struct RecoveryInsightsView: View {
    let analysis: RecoveryImpactAnalysis
    var onLogSession: ((RecoveryProtocolType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Key Insights Section
            if !analysis.insights.isEmpty {
                insightsSection
            }

            // Personalized Recommendations Section
            if !analysis.personalizedRecommendations.isEmpty {
                recommendationsSection
            }

            // Insufficient Data Message
            if !analysis.hasSufficientData {
                insufficientDataView
            }
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.modusTealAccent)
                Text("Your Recovery Insights")
                    .font(.headline)
                Spacer()
            }

            ForEach(analysis.insights.prefix(4)) { insight in
                RecoveryInsightCard(insight: insight)
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.modusCyan)
                Text("Personalized Recommendations")
                    .font(.headline)
                Spacer()
            }

            ForEach(analysis.personalizedRecommendations.prefix(3)) { recommendation in
                PersonalizedRecommendationCard(
                    recommendation: recommendation,
                    onLogSession: onLogSession
                )
            }
        }
    }

    // MARK: - Insufficient Data View

    private var insufficientDataView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))

            Text("Building Your Insights")
                .font(.headline)

            Text("Log more recovery sessions and sync your Apple Watch data to see personalized insights about how recovery affects your HRV and sleep.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("\(analysis.dataPointsAnalyzed) data points collected")
                .font(.caption)
                .foregroundColor(.modusCyan)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Recovery Insight Card

struct RecoveryInsightCard: View {
    let insight: RecoveryInsight

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Impact Indicator
            impactIndicator

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: insight.protocolType.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(insight.protocolType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(insight.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(insight.confidenceLevel, systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(confidenceColor)

                    Text("\(insight.dataPoints) data points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(impactBackgroundColor.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.protocolType.displayName) insight: \(insight.description). Impact: \(insight.formattedImpact). Confidence: \(insight.confidenceLevel)")
    }

    // MARK: - Impact Indicator

    private var impactIndicator: some View {
        VStack(spacing: 2) {
            Text(insight.formattedImpact)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(impactColor)

            Image(systemName: impactArrow)
                .font(.caption)
                .foregroundColor(impactColor)
        }
        .frame(width: 50)
        .accessibilityHidden(true)
    }

    private var impactColor: Color {
        switch insight.impactCategory {
        case .strongPositive, .positive:
            return .modusTealAccent
        case .neutral:
            return .secondary
        case .negative, .strongNegative:
            return .orange
        }
    }

    private var impactBackgroundColor: Color {
        switch insight.impactCategory {
        case .strongPositive, .positive:
            return .modusTealAccent
        case .neutral:
            return .gray
        case .negative, .strongNegative:
            return .orange
        }
    }

    private var impactArrow: String {
        switch insight.impactCategory {
        case .strongPositive, .positive:
            return "arrow.up"
        case .neutral:
            return "arrow.left.arrow.right"
        case .negative, .strongNegative:
            return "arrow.down"
        }
    }

    private var confidenceColor: Color {
        switch insight.confidence {
        case 0.8...: return .modusTealAccent
        case 0.5..<0.8: return .modusCyan
        default: return .secondary
        }
    }
}

// MARK: - Personalized Recommendation Card

struct PersonalizedRecommendationCard: View {
    let recommendation: PersonalizedRecoveryRecommendation
    var onLogSession: ((RecoveryProtocolType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                Image(systemName: recommendation.protocolType.icon)
                    .font(.title2)
                    .foregroundColor(priorityColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(recommendation.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if recommendation.priority == .high {
                    Text("TOP PICK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.modusTealAccent)
                        .cornerRadius(CornerRadius.xs)
                }
            }

            // Details
            HStack(spacing: Spacing.md) {
                if let duration = recommendation.suggestedDuration {
                    DetailChip(icon: "clock", text: "\(duration) min")
                }

                if let frequency = recommendation.suggestedFrequency {
                    DetailChip(icon: "calendar", text: frequency)
                }

                if let timeOfDay = recommendation.suggestedTimeOfDay {
                    DetailChip(icon: timeOfDay.icon, text: timeOfDay.displayName)
                }
            }

            // Expected Benefit
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent)

                Text("Expected: \(recommendation.expectedBenefit)")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent)

                Spacer()

                if let onLogSession = onLogSession {
                    Button {
                        onLogSession(recommendation.protocolType)
                    } label: {
                        Text("Log")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .tint(.modusCyan)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .contain)
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .modusTealAccent
        case .medium: return .modusCyan
        case .low: return .secondary
        }
    }
}

// MARK: - Detail Chip

private struct DetailChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Compact Insight Row (for inline display)

struct CompactInsightRow: View {
    let insight: RecoveryInsight

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // Impact badge
            Text(insight.formattedImpact)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(impactColor)
                .cornerRadius(CornerRadius.sm)

            // Description
            Text(insight.description)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            // Protocol icon
            Image(systemName: insight.protocolType.icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.formattedImpact) - \(insight.description)")
    }

    private var impactColor: Color {
        insight.impactPercentage >= 0 ? .modusTealAccent : .orange
    }
}

// MARK: - Preview

#if DEBUG
struct RecoveryInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            RecoveryInsightsView(
                analysis: .sample,
                onLogSession: { _ in }
            )
            .padding()
        }
        .previewDisplayName("With Data")

        ScrollView {
            RecoveryInsightsView(
                analysis: .empty,
                onLogSession: { _ in }
            )
            .padding()
        }
        .previewDisplayName("Insufficient Data")
    }
}

struct RecoveryInsightCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            RecoveryInsightCard(insight: RecoveryInsight.sampleInsights[0])
            RecoveryInsightCard(insight: RecoveryInsight.sampleInsights[1])
            RecoveryInsightCard(insight: RecoveryInsight.sampleInsights[2])
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct PersonalizedRecommendationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PersonalizedRecommendationCard(
                recommendation: PersonalizedRecoveryRecommendation.sampleRecommendations[0],
                onLogSession: { _ in }
            )
            PersonalizedRecommendationCard(
                recommendation: PersonalizedRecoveryRecommendation.sampleRecommendations[1],
                onLogSession: { _ in }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
