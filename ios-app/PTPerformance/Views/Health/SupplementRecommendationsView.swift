// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

struct SupplementRecommendationsView: View {
    @StateObject private var viewModel = SupplementRecommendationsViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let recommendations = viewModel.recommendations {
                    recommendationsContent(recommendations)
                } else if viewModel.selectedGoals.isEmpty {
                    goalSelectionView
                } else {
                    errorView
                }
            }
            .navigationTitle("AI Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                if viewModel.recommendations != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await viewModel.refreshRecommendations() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh recommendations")
                    }
                }
            }
        }
    }

    // MARK: - Goal Selection View

    private var goalSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("Personalized Supplement Stack")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select your goals and we'll analyze your health data to recommend an evidence-based supplement stack with Momentous products.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Goal Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(SupplementGoal.allCases) { goal in
                        GoalSelectionCard(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
                .padding(.horizontal)

                // Get Recommendations Button
                Button {
                    Task { await viewModel.getRecommendations() }
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("Get AI Recommendations")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedGoals.isEmpty ? Color.gray : Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .disabled(viewModel.selectedGoals.isEmpty)
                .padding(.horizontal)
                .padding(.top, Spacing.xs)
                .accessibilityLabel("Get AI recommendations")
                .accessibilityHint(viewModel.selectedGoals.isEmpty ? "Select at least one goal first" : "Analyzes your data and generates personalized supplement recommendations")

                // Disclaimer
                Text("Recommendations are based on your health data, goals, and current research. Always consult a healthcare provider before starting any supplement regimen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Analyzing Your Health Data")
                    .font(.headline)

                Text("Our AI is reviewing your goals, lab results, sleep patterns, and recovery data to create personalized recommendations...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing your health data to generate supplement recommendations")
    }

    // MARK: - Recommendations Content

    private func recommendationsContent(_ response: SupplementRecommendationResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stack Summary
                stackSummaryCard(response)

                // Timing Schedule
                if !response.timingSchedule.allTimings.isEmpty {
                    timingScheduleSection(response.timingSchedule)
                }

                // Recommendations by Priority
                recommendationsSection(response.recommendations)

                // Interaction Warnings
                if !response.interactionWarnings.isEmpty {
                    warningsSection(response.interactionWarnings)
                }

                // Cost Estimate
                costEstimateCard(response.totalDailyCostEstimate)

                // Disclaimer
                disclaimerSection(response.disclaimer)
            }
            .padding()
        }
    }

    private func stackSummaryCard(_ response: SupplementRecommendationResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Your Personalized Stack")
                    .font(.headline)
                Spacer()
                if response.cached {
                    Text("Cached")
                        .font(.caption2)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(CornerRadius.xs)
                }
            }

            Text(response.stackSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Goal Coverage
            if !response.goalCoverage.isEmpty {
                Divider()

                Text("Goal Coverage")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(Array(response.goalCoverage.keys.sorted()), id: \.self) { goal in
                    if let supplements = response.goalCoverage[goal] {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(supplements.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
    }

    private func timingScheduleSection(_ schedule: SupplementTimingSchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Daily Schedule")
                    .font(.headline)
            }

            ForEach(schedule.allTimings, id: \.0) { timing, items in
                VStack(alignment: .leading, spacing: 8) {
                    Text(timing)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)

                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                            Spacer()
                            Text(item.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func recommendationsSection(_ recommendations: [AISupplementRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Essential
            let essential = recommendations.filter { $0.priority == .essential }
            if !essential.isEmpty {
                priorityGroup(title: "Essential", icon: "star.fill", color: .red, recommendations: essential)
            }

            // Recommended
            let recommended = recommendations.filter { $0.priority == .recommended }
            if !recommended.isEmpty {
                priorityGroup(title: "Recommended", icon: "hand.thumbsup.fill", color: .orange, recommendations: recommended)
            }

            // Optional
            let optional = recommendations.filter { $0.priority == .optional }
            if !optional.isEmpty {
                priorityGroup(title: "Optional", icon: "plus.circle.fill", color: .modusCyan, recommendations: optional)
            }
        }
    }

    private func priorityGroup(title: String, icon: String, color: Color, recommendations: [AISupplementRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
            }

            ForEach(recommendations) { rec in
                SupplementRecommendationCard(
                    recommendation: rec,
                    onAddToStack: {
                        Task { await viewModel.addToStack(rec) }
                    },
                    onOpenLink: {
                        if let urlString = rec.purchaseUrl, let url = URL(string: urlString) {
                            openURL(url)
                        }
                    }
                )
            }
        }
    }

    private func warningsSection(_ warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
                Text("Interaction Warnings")
                    .font(.headline)
            }

            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Interaction warnings: \(warnings.joined(separator: ". "))")
    }

    private func costEstimateCard(_ cost: String) -> some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Daily Cost")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(cost)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated daily cost: \(cost)")
    }

    private func disclaimerSection(_ disclaimer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Disclaimer")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Text(disclaimer)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Unable to Load Recommendations")
                .font(.headline)

            if let error = viewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Try Again") {
                Task { await viewModel.getRecommendations() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Try loading recommendations again")
        }
    }
}

// MARK: - Goal Selection Card

struct GoalSelectionCard: View {
    let goal: SupplementGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .modusCyan)
                    .accessibilityHidden(true)

                Text(goal.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? Color.modusCyan : Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goal.displayName), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this goal")
    }
}

// MARK: - Supplement Recommendation Card

struct SupplementRecommendationCard: View {
    let recommendation: AISupplementRecommendation
    let onAddToStack: () -> Void
    let onOpenLink: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Text(recommendation.brand)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("-")
                            .foregroundColor(.secondary)

                        Text(recommendation.dosage)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                }

                Spacer()

                // Evidence Rating
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < recommendation.evidenceRating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(index < recommendation.evidenceRating ? .yellow : .gray)
                    }
                }
                .accessibilityLabel("Evidence rating: \(recommendation.evidenceRating) out of 5 stars")
            }

            // Timing
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Text(recommendation.timing)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Goal Alignment Tags
            if !recommendation.goalAlignment.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recommendation.goalAlignment, id: \.self) { goal in
                            Text(goal.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.modusCyan.opacity(0.2))
                                .foregroundColor(.modusCyan)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
                .accessibilityHidden(true)
            }

            // Expandable Rationale
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    Text("Why this supplement?")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(recommendation.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Warnings
                    if !recommendation.warnings.isEmpty {
                        ForEach(recommendation.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .accessibilityHidden(true)
                                Text(warning)
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Less" : "Details")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
                .accessibilityLabel(isExpanded ? "Show less details" : "Show more details")

                Spacer()

                if recommendation.purchaseUrl != nil {
                    Button(action: onOpenLink) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.fill")
                                .font(.caption)
                            Text("Buy")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .accessibilityLabel("Buy \(recommendation.name) from Momentous")
                }

                Button(action: onAddToStack) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.modusLightTeal)
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Add \(recommendation.name) to your supplement stack")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    SupplementRecommendationsView()
}
