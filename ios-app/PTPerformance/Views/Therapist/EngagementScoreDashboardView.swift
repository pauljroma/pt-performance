//
//  EngagementScoreDashboardView.swift
//  PTPerformance
//
//  Dashboard showing patient engagement scores with risk-level breakdown,
//  component detail, and batch recalculation support.
//

import SwiftUI

// MARK: - Engagement Score Dashboard View

struct EngagementScoreDashboardView: View {
    @StateObject private var viewModel = EngagementScoreDashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var expandedRowId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.scores.isEmpty {
                    ProgressView("Loading engagement scores...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage, viewModel.scores.isEmpty {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Engagement Scores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadScores()
            }
            .task {
                await viewModel.loadScores()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Summary badges
                if let summary = viewModel.summary {
                    summarySection(summary)
                }

                // Average score gauge
                if let avgScore = viewModel.summary?.avgScore {
                    averageScoreCard(avgScore)
                }

                // Patient list sorted by score (lowest first)
                patientListSection

                // Recalculate button
                recalculateButton
            }
            .padding()
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: EngagementSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Risk Distribution")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    riskBadge(
                        label: "Highly Engaged",
                        count: summary.highlyEngaged ?? 0,
                        color: .green
                    )
                    riskBadge(
                        label: "Engaged",
                        count: summary.engaged ?? 0,
                        color: .blue
                    )
                    riskBadge(
                        label: "Moderate",
                        count: summary.moderate ?? 0,
                        color: .yellow
                    )
                    riskBadge(
                        label: "At Risk",
                        count: summary.atRisk ?? 0,
                        color: .orange
                    )
                    riskBadge(
                        label: "High Risk",
                        count: summary.highRisk ?? 0,
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func riskBadge(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 80)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.xs)
        .background(color.opacity(0.12))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(label): \(count)")
    }

    // MARK: - Average Score Card

    private func averageScoreCard(_ avgScore: Double) -> some View {
        VStack(spacing: Spacing.sm) {
            Text("Average Score")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: min(avgScore / 100.0, 1.0))
                    .stroke(
                        scoreGradient(for: avgScore),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(avgScore))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(riskLabel(for: avgScore))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(for: avgScore))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(scoreColor(for: avgScore).opacity(0.12))
                .cornerRadius(CornerRadius.sm)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Patient List Section

    private var patientListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Patients")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(viewModel.scores.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.scores.isEmpty {
                Text("No engagement scores available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.scores) { row in
                        patientRow(row)

                        if row.id != viewModel.scores.last?.id {
                            Divider()
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
    }

    private func patientRow(_ row: EngagementScoreRow) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedRowId == row.id {
                        expandedRowId = nil
                    } else {
                        expandedRowId = row.id
                    }
                }
            } label: {
                HStack(spacing: Spacing.md) {
                    // Truncated patient ID
                    Text(truncatedId(row.patientId))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Score with color
                    Text("\(Int(row.score ?? 0))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(for: row.score ?? 0))
                        .frame(minWidth: 36)

                    // Risk level badge
                    riskLevelBadge(row.riskLevel ?? "unknown")

                    Image(systemName: expandedRowId == row.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Patient \(truncatedId(row.patientId)), score \(Int(row.score ?? 0)), \(row.riskLevel ?? "unknown")")
            .accessibilityHint("Double tap to expand component details")

            // Expanded component breakdown
            if expandedRowId == row.id, let components = row.components {
                componentBreakdown(components)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func componentBreakdown(_ components: EngagementComponents) -> some View {
        VStack(spacing: Spacing.xs) {
            componentRow(
                label: "Workout Frequency",
                icon: "figure.strengthtraining.traditional",
                component: components.workoutFrequency
            )
            componentRow(
                label: "Streak Consistency",
                icon: "flame.fill",
                component: components.streakConsistency
            )
            componentRow(
                label: "Feature Breadth",
                icon: "square.grid.2x2.fill",
                component: components.featureBreadth
            )
            componentRow(
                label: "Recency",
                icon: "clock.fill",
                component: components.recency
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
    }

    private func componentRow(label: String, icon: String, component: EngagementComponent?) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let comp = component {
                Text(String(format: "%.0f", comp.weightedValue ?? 0))
                    .font(.caption)
                    .fontWeight(.semibold)

                // Weight indicator
                Text("(w: \(String(format: "%.0f%%", (comp.weight ?? 0) * 100)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Recalculate Button

    private var recalculateButton: some View {
        Button {
            Task {
                HapticFeedback.medium()
                await viewModel.recalculate()
            }
        } label: {
            HStack {
                if viewModel.isRecalculating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(viewModel.isRecalculating ? "Recalculating..." : "Recalculate Scores")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isRecalculating ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(viewModel.isRecalculating)
        .accessibilityLabel("Recalculate engagement scores")
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error Loading Scores")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await viewModel.loadScores() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helpers

    private func truncatedId(_ patientId: String?) -> String {
        guard let pid = patientId else { return "Unknown" }
        if pid.count > 8 {
            return String(pid.prefix(8)) + "..."
        }
        return pid
    }

    private func riskLevelBadge(_ level: String) -> some View {
        let display = level.replacingOccurrences(of: "_", with: " ").capitalized
        let color = riskLevelColor(level)

        return Text(display)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(CornerRadius.xs)
    }

    private func riskLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "highly_engaged": return .green
        case "engaged": return .blue
        case "moderate": return .yellow
        case "at_risk": return .orange
        case "high_risk": return .red
        default: return .gray
        }
    }

    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private func scoreGradient(for score: Double) -> LinearGradient {
        let color = scoreColor(for: score)
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func riskLabel(for score: Double) -> String {
        switch score {
        case 80...100: return "Highly Engaged"
        case 60..<80: return "Engaged"
        case 40..<60: return "Moderate"
        case 20..<40: return "At Risk"
        default: return "High Risk"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EngagementScoreDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        EngagementScoreDashboardView()
    }
}
#endif
