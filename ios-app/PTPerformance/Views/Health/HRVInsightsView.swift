import SwiftUI
import Charts

/// ACP-1021: HRV Insights Enhancement View
/// Provides comprehensive HRV visualization with trend analysis, baseline comparison,
/// training load correlation, and plain-language explanations
struct HRVInsightsView: View {
    @StateObject private var viewModel: HRVInsightsViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: HRVInsightsViewModel(patientId: patientId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Current HRV with trend indicator
                currentHRVCard

                // HRV Trend Chart with 7-day rolling average
                trendChartCard

                // Baseline comparison
                baselineComparisonCard

                // Training load correlation
                trainingLoadCorrelationCard

                // Plain language explanation
                insightsExplanationCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("HRV Insights")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Current HRV Card

    private var currentHRVCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("Today's HRV")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                if let currentHRV = viewModel.currentHRV {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text("\(Int(currentHRV))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.modusCyan)

                        Text("ms")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current HRV: \(Int(currentHRV)) milliseconds")

                    // Trend indicator vs baseline
                    if let baseline = viewModel.baseline, let deviation = viewModel.baselineDeviation {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: deviation > 5 ? "arrow.up.circle.fill" : deviation < -5 ? "arrow.down.circle.fill" : "minus.circle.fill")
                                .foregroundColor(deviationColor(deviation))

                            Text("\(deviation > 0 ? "+" : "")\(String(format: "%.1f", deviation))% vs baseline")
                                .font(.subheadline)
                                .foregroundColor(deviationColor(deviation))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(deviation > 5 ? "Above" : deviation < -5 ? "Below" : "Near") baseline by \(abs(Int(deviation))) percent")

                        Text("7-day baseline: \(Int(baseline)) ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No HRV data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Trend Chart Card

    private var hrvTrendChart: some View {
        Chart {
            ForEach(viewModel.hrvHistory) { reading in
                PointMark(
                    x: .value("Date", reading.date, unit: .day),
                    y: .value("HRV", reading.hrvSDNN)
                )
                .foregroundStyle(Color.modusCyan.opacity(0.6))
                .symbolSize(40)

                LineMark(
                    x: .value("Date", reading.date, unit: .day),
                    y: .value("HRV", reading.hrvSDNN)
                )
                .foregroundStyle(Color.modusCyan.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }

            ForEach(viewModel.rollingAverageData) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Average", point.value)
                )
                .foregroundStyle(Color.modusTealAccent)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }

            ForEach(viewModel.significantChanges) { change in
                PointMark(
                    x: .value("Date", change.date, unit: .day),
                    y: .value("HRV", change.value)
                )
                .foregroundStyle(Color.orange)
                .symbol(.diamond)
                .symbolSize(60)
                .annotation(position: .top) {
                    Text(change.label)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(4)
                        .background(Color(.systemBackground))
                        .cornerRadius(4)
                }
            }
        }
        .frame(height: 200)
    }

    private var trendChartCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("30-Day Trend")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    // Legend
                    HStack(spacing: Spacing.sm) {
                        Label("Daily", systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.modusCyan)

                        Label("7-Day Avg", systemImage: "line.diagonal")
                            .font(.caption)
                            .foregroundColor(.modusTealAccent)
                    }
                    .labelStyle(.titleAndIcon)
                }
                .accessibilityElement(children: .contain)

                if !viewModel.hrvHistory.isEmpty {
                    hrvTrendChart
                } else {
                    EmptyStateView(
                        title: "No Trend Data",
                        message: "Connect your Apple Watch to track HRV trends",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    .frame(height: 200)
                }
            }
        }
    }

    // MARK: - Baseline Comparison Card

    private var baselineComparisonCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.modusTealAccent)
                        .accessibilityHidden(true)

                    Text("Baseline Comparison")
                        .font(.headline)
                        .accessibleHeader()
                }

                if let baseline = viewModel.baseline, let current = viewModel.currentHRV {
                    VStack(spacing: Spacing.sm) {
                        // Visual comparison bars
                        comparisonBar(
                            label: "Current",
                            value: current,
                            color: .modusCyan,
                            maxValue: max(baseline * 1.2, current)
                        )

                        comparisonBar(
                            label: "7-Day Avg",
                            value: baseline,
                            color: .modusTealAccent,
                            maxValue: max(baseline * 1.2, current)
                        )

                        Divider()

                        // Interpretation
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: interpretationIcon)
                                .foregroundColor(interpretationColor)

                            Text(interpretationText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, Spacing.xs)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(interpretationText)
                    }
                } else {
                    Text("Collecting baseline data (need 3+ days)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Training Load Correlation Card

    private var trainingLoadCorrelationCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.modusDeepTeal)
                        .accessibilityHidden(true)

                    Text("Training Load Impact")
                        .font(.headline)
                        .accessibleHeader()
                }

                if let correlation = viewModel.trainingLoadCorrelation {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        // Correlation strength indicator
                        HStack {
                            Text("Correlation:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(correlationStrength(correlation))
                                .font(.subheadline.bold())
                                .foregroundColor(correlationColor(correlation))
                        }

                        // Visual representation
                        ProgressView(value: abs(correlation), total: 1.0)
                            .tint(correlationColor(correlation))
                            .accessibilityLabel("Correlation strength: \(Int(abs(correlation) * 100)) percent")

                        Text(correlationExplanation(correlation))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Analyzing training patterns...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Insights Explanation Card

    private var insightsExplanationCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)

                    Text("What This Means")
                        .font(.headline)
                        .accessibleHeader()
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(viewModel.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.modusCyan)
                                .padding(.top, 6)
                                .accessibilityHidden(true)

                            Text(insight)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Insights: " + viewModel.insights.joined(separator: ". "))
            }
        }
    }

    // MARK: - Helper Views

    private func comparisonBar(label: String, value: Double, color: Color, maxValue: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 24)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / maxValue), height: 24)
                        .cornerRadius(4)
                }
            }
            .frame(height: 24)

            Text("\(Int(value))")
                .font(.caption.bold())
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Int(value)) milliseconds")
    }

    // MARK: - Helper Methods

    private func deviationColor(_ deviation: Double) -> Color {
        if deviation > 5 {
            return .green
        } else if deviation < -5 {
            return .red
        } else {
            return .secondary
        }
    }

    private var interpretationIcon: String {
        guard let deviation = viewModel.baselineDeviation else { return "minus.circle" }
        if deviation > 10 {
            return "checkmark.circle.fill"
        } else if deviation < -10 {
            return "exclamationmark.triangle.fill"
        } else {
            return "minus.circle"
        }
    }

    private var interpretationColor: Color {
        guard let deviation = viewModel.baselineDeviation else { return .secondary }
        if deviation > 10 {
            return .green
        } else if deviation < -10 {
            return .orange
        } else {
            return .secondary
        }
    }

    private var interpretationText: String {
        guard let deviation = viewModel.baselineDeviation else {
            return "Building your baseline..."
        }

        if deviation > 10 {
            return "Excellent recovery - your body is well-rested and ready for training"
        } else if deviation > 5 {
            return "Good recovery - suitable for moderate to high intensity training"
        } else if deviation > -5 {
            return "Normal range - proceed with planned training"
        } else if deviation > -10 {
            return "Slightly fatigued - consider lighter training or active recovery"
        } else {
            return "Elevated stress or fatigue - prioritize rest and recovery"
        }
    }

    private func correlationStrength(_ correlation: Double) -> String {
        let abs = abs(correlation)
        if abs > 0.7 {
            return "Strong"
        } else if abs > 0.4 {
            return "Moderate"
        } else {
            return "Weak"
        }
    }

    private func correlationColor(_ correlation: Double) -> Color {
        let abs = abs(correlation)
        if abs > 0.7 {
            return .modusCyan
        } else if abs > 0.4 {
            return .modusTealAccent
        } else {
            return .secondary
        }
    }

    private func correlationExplanation(_ correlation: Double) -> String {
        if correlation < -0.4 {
            return "Higher training load tends to decrease your HRV. This is normal - ensure adequate recovery between intense sessions."
        } else if correlation > 0.4 {
            return "Your HRV increases with training. This suggests good adaptation and recovery capacity."
        } else {
            return "No strong correlation detected. HRV is influenced by many factors including sleep, stress, and nutrition."
        }
    }
}

// MARK: - Supporting Models

struct HRVChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct SignificantHRVChange: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

// MARK: - Preview

#if DEBUG
struct HRVInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HRVInsightsView(patientId: UUID())
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")

        NavigationStack {
            HRVInsightsView(patientId: UUID())
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
