//
//  ProgressiveOverloadCard.swift
//  PTPerformance
//
//  AI-powered progressive overload suggestion card for strength training.
//  Displays recommended load adjustments with confidence and trend indicators.
//

import SwiftUI

/// Card component displaying AI-powered progressive overload suggestions
/// Shows exercise name, current weight, recommended progression, and reasoning
struct ProgressiveOverloadCard: View {

    // MARK: - Properties

    let exerciseName: String
    let currentWeight: Double
    let suggestion: ProgressionSuggestion
    let onApply: () -> Void
    let onDismiss: (() -> Void)?

    @State private var isExpanded = false
    @State private var isApplying = false

    // MARK: - Initialization

    init(
        exerciseName: String,
        currentWeight: Double,
        suggestion: ProgressionSuggestion,
        onApply: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.exerciseName = exerciseName
        self.currentWeight = currentWeight
        self.suggestion = suggestion
        self.onApply = onApply
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with exercise name and progression badge
            headerSection

            // Current vs recommended weight
            weightComparisonSection

            // Confidence and trend indicators
            indicatorsRow

            // Reasoning section (expandable)
            reasoningSection

            // Apply suggestion button
            actionButtons
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .animation(.easeInOut(duration: AnimationDuration.standard), value: isExpanded)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(exerciseName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("AI Progression Suggestion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            progressionBadge
        }
    }

    private var progressionBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: suggestion.progressionType.icon)
                .font(.system(size: 14, weight: .semibold))

            Text(suggestion.progressionType.displayText)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(suggestion.progressionType.color)
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Weight Comparison Section

    private var weightComparisonSection: some View {
        HStack(spacing: Spacing.md) {
            // Current weight
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Current")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(formatWeight(currentWeight)) \(WeightUnit.defaultUnit)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            // Arrow indicator
            Image(systemName: weightChangeArrow)
                .font(.title2)
                .foregroundColor(suggestion.progressionType.color)

            // Recommended weight
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Recommended")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(formatWeight(suggestion.nextLoad)) \(WeightUnit.defaultUnit)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(suggestion.progressionType.color)
            }

            Spacer()

            // Change amount
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("Change")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(suggestion.loadChangeDescription(from: currentWeight))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(suggestion.progressionType.color)
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var weightChangeArrow: String {
        let diff = suggestion.nextLoad - currentWeight
        if abs(diff) < 0.1 {
            return "equal"
        } else if diff > 0 {
            return "arrow.up.right"
        } else {
            return "arrow.down.right"
        }
    }

    // MARK: - Indicators Row

    private var indicatorsRow: some View {
        HStack(spacing: Spacing.sm) {
            // Confidence indicator
            confidenceIndicator

            Divider()
                .frame(height: 32)

            // Trend indicator
            trendIndicator

            Spacer()

            // Sessions analyzed
            if suggestion.analysis.recentSessions > 0 {
                sessionsIndicator
            }
        }
    }

    private var confidenceIndicator: some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(suggestion.confidenceColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(suggestion.confidenceLevel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(suggestion.confidenceColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confidence level: \(suggestion.confidenceLevel)")
    }

    private var trendIndicator: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: suggestion.analysis.trend.icon)
                .font(.system(size: 12))
                .foregroundColor(suggestion.analysis.trend.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("Trend")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(suggestion.analysis.trend.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(suggestion.analysis.trend.color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Performance trend: \(suggestion.analysis.trend.displayText)")
    }

    private var sessionsIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Based on")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(suggestion.analysis.recentSessions) sessions")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Reasoning Section

    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
                HapticFeedback.light()
            }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)

                    Text("Why this suggestion?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Tap to collapse reasoning" : "Tap to expand reasoning")

            if isExpanded {
                Text(suggestion.reasoning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxs)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                // Additional analysis details
                if let estimated1RM = suggestion.analysis.estimated1RM {
                    HStack {
                        Text("Est. 1RM:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(formatWeight(estimated1RM)) \(WeightUnit.defaultUnit)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, Spacing.xxs)
                }

                if let fatigueImpact = suggestion.analysis.fatigueImpact {
                    HStack {
                        Text("Fatigue:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(fatigueImpact.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            if let dismiss = onDismiss {
                Button(action: {
                    HapticFeedback.light()
                    dismiss()
                }) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss suggestion")
            }

            Button(action: {
                HapticFeedback.medium()
                Task {
                    isApplying = true
                    onApply()
                    // Small delay to show the applying state visually
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    isApplying = false
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    if isApplying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                    }

                    Text("Apply Suggestion")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(suggestion.progressionType.color)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isApplying)
            .accessibilityLabel("Apply suggestion to set weight to \(formatWeight(suggestion.nextLoad)) \(WeightUnit.defaultUnit)")
        }
    }

    // MARK: - Helpers

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        } else {
            return String(format: "%.1f", weight)
        }
    }
}

// MARK: - Compact Variant

/// Compact version of the progressive overload card for list displays
struct ProgressiveOverloadCardCompact: View {

    let exerciseName: String
    let currentWeight: Double
    let suggestion: ProgressionSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Progression type icon
                ZStack {
                    Circle()
                        .fill(suggestion.progressionType.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: suggestion.progressionType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(suggestion.progressionType.color)
                }

                // Exercise info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xxs) {
                        Text(suggestion.progressionType.displayText)
                            .font(.caption)
                            .foregroundColor(suggestion.progressionType.color)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(suggestion.loadChangeDescription(from: currentWeight))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Confidence badge
                confidenceBadge

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.sm)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exerciseName), \(suggestion.progressionType.displayText), \(suggestion.loadChangeDescription(from: currentWeight))")
        .accessibilityHint("Double tap to view details")
    }

    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(suggestion.confidenceColor)
                .frame(width: 6, height: 6)

            Text(suggestion.confidenceLevel)
                .font(.caption2)
                .foregroundColor(suggestion.confidenceColor)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(suggestion.confidenceColor.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressiveOverloadCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Increase suggestion
                ProgressiveOverloadCard(
                    exerciseName: "Barbell Back Squat",
                    currentWeight: 185,
                    suggestion: ProgressionSuggestion(
                        id: UUID(),
                        nextLoad: 190,
                        nextReps: 8,
                        confidence: 85,
                        reasoning: "Based on consistent RPE of 7 across 4 sessions at 185 lbs with all target reps completed, a 5 lb increase is appropriate for continued progressive overload.",
                        progressionType: .increase,
                        analysis: PerformanceAnalysis(
                            trend: .improving,
                            estimated1RM: 225,
                            velocityTrend: "stable",
                            fatigueImpact: "low - good for progression",
                            recentSessions: 4
                        )
                    ),
                    onApply: {},
                    onDismiss: {}
                )

                // Hold suggestion
                ProgressiveOverloadCard(
                    exerciseName: "Romanian Deadlift",
                    currentWeight: 135,
                    suggestion: ProgressionSuggestion(
                        id: UUID(),
                        nextLoad: 135,
                        nextReps: 10,
                        confidence: 72,
                        reasoning: "RPE of 8 indicates optimal training stimulus. Maintain current load to solidify technique before increasing.",
                        progressionType: .hold,
                        analysis: PerformanceAnalysis(
                            trend: .plateaued,
                            estimated1RM: 175,
                            velocityTrend: "stable",
                            fatigueImpact: "moderate - good training stimulus",
                            recentSessions: 3
                        )
                    ),
                    onApply: {}
                )

                // Decrease suggestion
                ProgressiveOverloadCard(
                    exerciseName: "Bench Press",
                    currentWeight: 165,
                    suggestion: ProgressionSuggestion(
                        id: UUID(),
                        nextLoad: 155,
                        nextReps: 8,
                        confidence: 78,
                        reasoning: "RPE of 9.5 and missed reps in recent sessions indicate load is too high. Reducing by 10 lbs to maintain quality reps.",
                        progressionType: .decrease,
                        analysis: PerformanceAnalysis(
                            trend: .declining,
                            estimated1RM: 185,
                            velocityTrend: "decreasing",
                            fatigueImpact: "high - monitor recovery",
                            recentSessions: 3
                        )
                    ),
                    onApply: {},
                    onDismiss: {}
                )

                // Deload suggestion
                ProgressiveOverloadCard(
                    exerciseName: "Overhead Press",
                    currentWeight: 95,
                    suggestion: ProgressionSuggestion(
                        id: UUID(),
                        nextLoad: 80,
                        nextReps: 6,
                        confidence: 88,
                        reasoning: "High accumulated fatigue detected over 5 sessions with declining velocity. A 15% deload is recommended to support recovery.",
                        progressionType: .deload,
                        analysis: PerformanceAnalysis(
                            trend: .declining,
                            estimated1RM: 115,
                            velocityTrend: "decreasing",
                            fatigueImpact: "high - consider deload",
                            recentSessions: 5
                        )
                    ),
                    onApply: {},
                    onDismiss: {}
                )

                Divider()
                    .padding(.vertical)

                Text("Compact Variants")
                    .font(.headline)

                // Compact cards
                ProgressiveOverloadCardCompact(
                    exerciseName: "Barbell Back Squat",
                    currentWeight: 185,
                    suggestion: ProgressionSuggestion.sample,
                    onTap: {}
                )

                ProgressiveOverloadCardCompact(
                    exerciseName: "Bench Press",
                    currentWeight: 165,
                    suggestion: ProgressionSuggestion(
                        id: UUID(),
                        nextLoad: 155,
                        nextReps: 8,
                        confidence: 55,
                        reasoning: "Test",
                        progressionType: .decrease,
                        analysis: PerformanceAnalysis.sample
                    ),
                    onTap: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
