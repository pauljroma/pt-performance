//
//  RehabModeDashboardView.swift
//  PTPerformance
//
//  Full dashboard view for Rehab Mode
//  ACP-MODE: Comprehensive rehab-focused dashboard with pain tracking, deload recommendations,
//  and recovery monitoring
//

import SwiftUI

/// Rehab Mode Dashboard View - Comprehensive rehabilitation monitoring
/// Displays pain tracking history, deload recommendations, and recovery progress
struct RehabModeDashboardView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel = RehabModeDashboardViewModel()
    @State private var showPainLogger = false
    @State private var showDeloadDetails = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header section
                headerSection

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    // Pain overview card
                    painOverviewCard

                    // Deload recommendation card
                    if let deload = viewModel.deloadRecommendation {
                        deloadRecommendationCard(deload)
                    }

                    // Pain history section
                    painHistorySection

                    // Active pain regions
                    if !viewModel.activePainRegions.isEmpty {
                        activePainRegionsSection
                    }

                    // Recovery tips
                    recoveryTipsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rehab Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .sheetWithHaptic(isPresented: $showPainLogger) {
            PainLoggerSheet(onComplete: {
                showPainLogger = false
                Task { await viewModel.refresh() }
            })
        }
        .sheetWithHaptic(isPresented: $showDeloadDetails) {
            if let deload = viewModel.deloadRecommendation {
                DeloadDetailsSheet(recommendation: deload)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery Focus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusDeepTeal)

                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Log pain button
                Button(action: {
                    HapticFeedback.medium()
                    showPainLogger = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Pain")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading rehab data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load data")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                HapticFeedback.light()
                Task { await viewModel.refresh() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xl)
        }
        .padding()
    }

    // MARK: - Pain Overview Card

    private var painOverviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Pain Overview")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            HStack(spacing: Spacing.lg) {
                // Today's pain score
                VStack(spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let score = viewModel.todayPainScore {
                        Text("\(score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(painScoreColor(score))
                    } else {
                        Text("--")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }

                    Text("/10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 60)

                // Week average
                VStack(spacing: 4) {
                    Text("Week Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let avg = viewModel.weeklyAveragePain {
                        Text(String(format: "%.1f", avg))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(painScoreColor(Int(avg)))
                    } else {
                        Text("--")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }

                    Text("/10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 60)

                // Trend
                VStack(spacing: 4) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: viewModel.painTrendIcon)
                        .font(.title)
                        .foregroundColor(viewModel.painTrendColor)

                    Text(viewModel.painTrendLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pain overview")
            .accessibilityValue("Today: \(viewModel.todayPainScore.map { "\($0) out of 10" } ?? "not recorded"). Weekly average: \(viewModel.weeklyAveragePain.map { String(format: "%.1f out of 10", $0) } ?? "not available"). Trend: \(viewModel.painTrendLabel)")
        }
    }

    // MARK: - Deload Recommendation Card

    private func deloadRecommendationCard(_ recommendation: DeloadRecommendation) -> some View {
        Button(action: {
            HapticFeedback.light()
            showDeloadDetails = true
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: recommendation.urgency.icon)
                        .font(.title2)
                        .foregroundColor(recommendation.urgency.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.urgency.title)
                            .font(.headline)
                            .foregroundColor(recommendation.urgency.color)

                        Text(recommendation.urgency.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(recommendation.reasoning)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .padding()
            .background(recommendation.urgency.color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Pain History Section

    private var painHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Pain History")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if viewModel.painHistory.isEmpty {
                emptyHistoryCard
            } else {
                painHistoryChart
            }
        }
    }

    private var emptyHistoryCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Log your first pain entry to see trends")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Pain tracking helps monitor recovery progress over time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Log First Entry") {
                HapticFeedback.light()
                showPainLogger = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.pink)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var painHistoryChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(viewModel.painHistory.suffix(7))) { entry in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(painScoreColor(entry.score))
                            .frame(width: 30, height: CGFloat(entry.score) * 10)
                            .cornerRadius(CornerRadius.xs)

                        Text(entry.date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Active Pain Regions Section

    private var activePainRegionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Active Pain Regions")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(viewModel.activePainRegions) { location in
                    painRegionCard(location)
                }
            }
        }
    }

    private func painRegionCard(_ location: PainLocation) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(location.intensityColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.region.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(location.intensity)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(location.region.shortName) pain")
        .accessibilityValue("\(location.intensity) out of 10")
    }

    // MARK: - Recovery Tips Section

    private var recoveryTipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recovery Tips")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            if !viewModel.isDeloadContextual {
                Text("General wellness tips")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            VStack(spacing: Spacing.xs) {
                ForEach(Array(viewModel.recoveryTips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(Spacing.sm)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

}

// MARK: - Placeholder Sheets

private struct PainLoggerSheet: View {
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 64))
                    .foregroundColor(.pink)

                Text("Pain Logger")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Log your current pain levels")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Done") {
                    onComplete()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .navigationTitle("Log Pain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DeloadDetailsSheet: View {
    let recommendation: DeloadRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: recommendation.urgency.icon)
                    .font(.system(size: 64))
                    .foregroundColor(recommendation.urgency.color)

                Text(recommendation.urgency.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(recommendation.urgency.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(recommendation.reasoning)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)

                Spacer()
            }
            .padding()
            .navigationTitle("Deload Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RehabModeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RehabModeDashboardView()
        }
    }
}
#endif
