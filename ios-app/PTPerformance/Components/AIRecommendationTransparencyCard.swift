//
//  AIRecommendationTransparencyCard.swift
//  PTPerformance
//
//  ACP-1025: AI Recommendations Transparency
//  Reusable card component showing AI reasoning, driving factors,
//  data confidence indicator, and feedback buttons.
//

import SwiftUI

// MARK: - AI Recommendation Transparency Card

/// Expandable card that explains why the AI made a specific recommendation.
/// Shows driving data points, confidence level, and allows user feedback.
///
/// Usage:
/// ```swift
/// AIRecommendationTransparencyCard(
///     recommendationId: "abc-123",
///     recommendationType: .deload,
///     reasoningSummary: "Suggesting deload because HRV down 15% this week",
///     drivingFactors: [.hrv(changePercent: -15), .sleepQuality(poorNights: 3, totalNights: 5)],
///     confidenceLevel: .high
/// )
/// ```
struct AIRecommendationTransparencyCard: View {

    // MARK: - Properties

    let recommendationId: String
    let recommendationType: RecommendationFeedbackType
    let reasoningSummary: String
    let drivingFactors: [RecommendationDrivingFactor]
    let confidenceLevel: DataConfidenceLevel

    @State private var isExpanded = false
    @State private var feedbackState: FeedbackState = .none
    @State private var showFeedbackConfirmation = false
    @StateObject private var feedbackStore = RecommendationFeedbackStore.shared
    @Environment(\.colorScheme) private var colorScheme

    private enum FeedbackState {
        case none
        case positive
        case negative
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Expandable header
            whyThisRecommendationButton

            // Expanded reasoning content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.modusLightTeal)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.modusCyan.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
        .onAppear {
            feedbackStore.loadFeedback()
            if let existing = feedbackStore.getFeedback(for: recommendationId) {
                feedbackState = existing.isPositive ? .positive : .negative
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("aiRecommendationTransparencyCard")
    }

    // MARK: - Why This Recommendation Button

    private var whyThisRecommendationButton: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isExpanded.toggle()
            }
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: Spacing.sm) {
                // AI sparkle icon
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)

                Text("Why this recommendation?")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.modusCyan)

                Spacer()

                // Confidence indicator mini badge
                confidenceMiniIndicator

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }
            .padding(Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Why this recommendation? Tap to \(isExpanded ? "collapse" : "expand") reasoning")
        .accessibilityHint(isExpanded ? "Showing AI reasoning details" : "Double tap to see what data drove this recommendation")
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()
                .padding(.horizontal, Spacing.sm)

            // Reasoning summary
            reasoningSummarySection

            // Driving factors with bullet points and icons
            if !drivingFactors.isEmpty {
                drivingFactorsSection
            }

            // Data confidence indicator
            dataConfidenceSection

            // Feedback buttons
            feedbackSection
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Reasoning Summary

    private var reasoningSummarySection: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "brain.head.profile")
                .font(.caption)
                .foregroundColor(.modusDeepTeal)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            Text(reasoningSummary)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.modusDeepTeal.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
        .accessibilityLabel("AI reasoning: \(reasoningSummary)")
    }

    // MARK: - Driving Factors Section

    private var drivingFactorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Key Data Points")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(drivingFactors) { factor in
                    drivingFactorRow(factor)
                }
            }
        }
    }

    private func drivingFactorRow(_ factor: RecommendationDrivingFactor) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            // Category icon
            Image(systemName: factor.icon)
                .font(.caption)
                .foregroundColor(factor.iconColor)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.metric)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(factor.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Category tag
            Text(factor.category.displayName)
                .font(.caption2)
                .foregroundColor(.modusCyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.modusCyan.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(factor.category.displayName): \(factor.metric). \(factor.detail)")
    }

    // MARK: - Data Confidence Section

    private var dataConfidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Data Confidence")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: Spacing.sm) {
                // Bar chart indicator
                dataConfidenceBars

                VStack(alignment: .leading, spacing: 2) {
                    Text(confidenceLevel.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(confidenceLevel.color)

                    Text(confidenceLevel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(confidenceLevel.color.opacity(colorScheme == .dark ? 0.12 : 0.08))
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Data confidence: \(confidenceLevel.displayName). \(confidenceLevel.description)")
    }

    /// Visual bar indicator for data confidence (1-4 filled bars)
    private var dataConfidenceBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < confidenceLevel.filledBars
                        ? confidenceLevel.color
                        : Color.secondary.opacity(0.2))
                    .frame(width: 6, height: CGFloat(10 + (index * 4)))
            }
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }

    /// Mini confidence indicator for the collapsed header
    private var confidenceMiniIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < confidenceLevel.filledBars
                        ? confidenceLevel.color
                        : Color.secondary.opacity(0.2))
                    .frame(width: 3, height: CGFloat(6 + (index * 2)))
            }
        }
        .frame(height: 12)
        .accessibilityLabel("Data confidence: \(confidenceLevel.displayName)")
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Was this helpful?")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: Spacing.sm) {
                // Thumbs up
                Button {
                    submitFeedback(isPositive: true)
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: feedbackState == .positive
                            ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.subheadline)

                        Text("Helpful")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(feedbackState == .positive ? .white : .modusTealAccent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(feedbackState == .positive
                                ? Color.modusTealAccent
                                : Color.modusTealAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark as helpful")
                .accessibilityAddTraits(feedbackState == .positive ? .isSelected : [])

                // Thumbs down
                Button {
                    submitFeedback(isPositive: false)
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: feedbackState == .negative
                            ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.subheadline)

                        Text("Not helpful")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(feedbackState == .negative ? .white : .secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(feedbackState == .negative
                                ? Color.secondary
                                : Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark as not helpful")
                .accessibilityAddTraits(feedbackState == .negative ? .isSelected : [])

                Spacer()

                // Feedback confirmation
                if showFeedbackConfirmation {
                    Text("Thanks!")
                        .font(.caption)
                        .foregroundColor(.modusTealAccent)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }

    // MARK: - Actions

    private func submitFeedback(isPositive: Bool) {
        let newState: FeedbackState = isPositive ? .positive : .negative

        // Toggle off if tapping the same button
        if feedbackState == newState {
            feedbackState = .none
            feedbackStore.removeFeedback(for: recommendationId)
            return
        }

        feedbackState = newState
        feedbackStore.submitFeedback(
            recommendationId: recommendationId,
            type: recommendationType,
            isPositive: isPositive
        )

        HapticFeedback.light()

        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
            showFeedbackConfirmation = true
        }

        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                showFeedbackConfirmation = false
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Expanded - High Confidence") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            AIRecommendationTransparencyCard(
                recommendationId: "preview-1",
                recommendationType: .deload,
                reasoningSummary: "Suggesting deload because your HRV has dropped 15% this week and sleep quality has been poor. Your body needs recovery time to prevent overtraining.",
                drivingFactors: [
                    .hrv(changePercent: -15),
                    .sleepQuality(poorNights: 3, totalNights: 5),
                    .volumeChange(changePercent: 20),
                    .acuteChronicRatio(ratio: 1.45),
                    .consecutiveLowDays(days: 4)
                ],
                confidenceLevel: .high
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Collapsed") {
    VStack(spacing: Spacing.md) {
        AIRecommendationTransparencyCard(
            recommendationId: "preview-2",
            recommendationType: .workoutAdaptation,
            reasoningSummary: "Reducing intensity today based on your readiness score of 45% and elevated fatigue.",
            drivingFactors: [
                .readinessScore(score: 45),
                .fatigueScore(score: 72)
            ],
            confidenceLevel: .moderate
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Low Confidence") {
    VStack(spacing: Spacing.md) {
        AIRecommendationTransparencyCard(
            recommendationId: "preview-3",
            recommendationType: .workoutSuggestion,
            reasoningSummary: "Based on limited data, we suggest a moderate intensity session today.",
            drivingFactors: [
                .readinessScore(score: 65)
            ],
            confidenceLevel: .low
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.md) {
        AIRecommendationTransparencyCard(
            recommendationId: "preview-dark",
            recommendationType: .deload,
            reasoningSummary: "Suggesting deload because HRV down 15% this week and fatigue score is elevated.",
            drivingFactors: [
                .hrv(changePercent: -15),
                .fatigueScore(score: 78),
                .consecutiveLowDays(days: 3)
            ],
            confidenceLevel: .high
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
#endif
