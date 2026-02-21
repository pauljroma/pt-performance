//
//  TrainingOutcomesDashboardView.swift
//  PTPerformance
//
//  Dashboard showing training outcomes with strength gains, volume progression,
//  pain trends, and adherence charts using Swift Charts.
//

import SwiftUI
import Charts

// MARK: - Training Outcomes Dashboard View

struct TrainingOutcomesDashboardView: View {
    @StateObject private var viewModel = TrainingOutcomesDashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.outcomes == nil {
                    ProgressView("Loading training outcomes...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage, viewModel.outcomes == nil {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Training Outcomes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadAggregate()
            }
            .task {
                await viewModel.loadAggregate()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Summary cards
                if let summary = viewModel.summary {
                    summarySection(summary)
                }

                // Strength gains
                if !viewModel.sortedStrengthGains.isEmpty {
                    strengthGainsSection
                }

                // Volume progression chart
                if !viewModel.volumeProgression.isEmpty {
                    volumeChartSection
                }

                // Pain trend chart
                if !viewModel.painTrend.isEmpty {
                    painChartSection
                }

                // Adherence chart
                if !viewModel.adherenceData.isEmpty {
                    adherenceChartSection
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: TrainingOutcomeSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                summaryCard(
                    title: "Exercises",
                    value: "\(summary.totalExercisesTracked ?? 0)",
                    subtitle: "tracked",
                    color: .blue
                )
                summaryCard(
                    title: "With Gains",
                    value: "\(summary.exercisesWithGains ?? 0)",
                    subtitle: "exercises",
                    color: .green
                )
                summaryCard(
                    title: "Avg Gain",
                    value: String(format: "%.1f%%", summary.avgStrengthGainPct ?? 0),
                    subtitle: "strength",
                    color: .purple
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                summaryCard(
                    title: "Volume",
                    value: trendArrow(summary.volumeTrend),
                    subtitle: summary.volumeTrend ?? "N/A",
                    color: volumeTrendColor(summary.volumeTrend)
                )
                summaryCard(
                    title: "Pain",
                    value: trendArrow(summary.painTrend),
                    subtitle: summary.painTrend ?? "N/A",
                    color: painTrendColor(summary.painTrend)
                )
                summaryCard(
                    title: "Adherence",
                    value: String(format: "%.0f%%", summary.overallAdherencePct ?? 0),
                    subtitle: "compliance",
                    color: adherenceColor(summary.overallAdherencePct ?? 0)
                )
            }
        }
    }

    private func summaryCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
    }

    // MARK: - Strength Gains Section

    private var strengthGainsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Strength Gains")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.sortedStrengthGains) { gain in
                    strengthGainRow(gain)

                    if gain.id != viewModel.sortedStrengthGains.last?.id {
                        Divider()
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func strengthGainRow(_ gain: StrengthGain) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(gain.exerciseName ?? "Unknown Exercise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(String(format: "%.0f", gain.startLoad ?? 0))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.0f", gain.currentLoad ?? 0))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Percentage change badge
            let pct = gain.pctChange ?? 0
            Text(String(format: "%+.1f%%", pct))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(pct >= 0 ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((pct >= 0 ? Color.green : Color.red).opacity(0.12))
                .cornerRadius(CornerRadius.xs)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityLabel(
            "\(gain.exerciseName ?? "Exercise"): \(String(format: "%.0f", gain.startLoad ?? 0)) to \(String(format: "%.0f", gain.currentLoad ?? 0)), \(String(format: "%+.1f%%", gain.pctChange ?? 0))"
        )
    }

    // MARK: - Volume Chart Section

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Volume Progression")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Chart(viewModel.volumeProgression) { entry in
                BarMark(
                    x: .value("Week", shortWeekLabel(entry.weekStart)),
                    y: .value("Volume", entry.totalVolume ?? 0)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(CornerRadius.xs)
            }
            .chartYAxisLabel("Total Volume")
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Pain Trend Chart Section

    private var painChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Pain Trend")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("Lower is better")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Chart(viewModel.painTrend) { entry in
                LineMark(
                    x: .value("Week", shortWeekLabel(entry.weekStart)),
                    y: .value("Pain", entry.avgPain ?? 0)
                )
                .foregroundStyle(Color.red.gradient)
                .interpolationMethod(.catmullRom)
                .symbol(Circle())

                AreaMark(
                    x: .value("Week", shortWeekLabel(entry.weekStart)),
                    y: .value("Pain", entry.avgPain ?? 0)
                )
                .foregroundStyle(Color.red.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxisLabel("Avg Pain")
            .chartYScale(domain: 0...10)
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Adherence Chart Section

    private var adherenceChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Adherence")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Chart(viewModel.adherenceData) { entry in
                BarMark(
                    x: .value("Week", shortWeekLabel(entry.weekStart)),
                    y: .value("Scheduled", entry.sessionsScheduled ?? 0)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .cornerRadius(CornerRadius.xs)

                BarMark(
                    x: .value("Week", shortWeekLabel(entry.weekStart)),
                    y: .value("Completed", entry.sessionsCompleted ?? 0)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(CornerRadius.xs)
            }
            .chartForegroundStyleScale([
                "Scheduled": Color.gray.opacity(0.3),
                "Completed": Color.green
            ])
            .chartYAxisLabel("Sessions")
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            // Legend
            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                    Text("Scheduled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error Loading Outcomes")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await viewModel.loadAggregate() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helpers

    private func shortWeekLabel(_ weekStart: String?) -> String {
        guard let ws = weekStart else { return "?" }
        // Expects "YYYY-MM-DD" format; return "MM/DD"
        let parts = ws.split(separator: "-")
        if parts.count >= 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return String(ws.prefix(10))
    }

    private func trendArrow(_ trend: String?) -> String {
        switch trend?.lowercased() {
        case "increasing", "up": return "arrow.up"
        case "decreasing", "down": return "arrow.down"
        case "stable", "flat": return "arrow.right"
        default: return "minus"
        }
    }

    private func volumeTrendColor(_ trend: String?) -> Color {
        switch trend?.lowercased() {
        case "increasing", "up": return .green
        case "decreasing", "down": return .orange
        default: return .gray
        }
    }

    private func painTrendColor(_ trend: String?) -> Color {
        // For pain, decreasing is good
        switch trend?.lowercased() {
        case "increasing", "up": return .red
        case "decreasing", "down": return .green
        default: return .gray
        }
    }

    private func adherenceColor(_ pct: Double) -> Color {
        switch pct {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        default: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TrainingOutcomesDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingOutcomesDashboardView()
    }
}
#endif
