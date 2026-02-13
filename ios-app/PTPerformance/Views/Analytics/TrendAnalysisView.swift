//
//  TrendAnalysisView.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  Main trend visualization with Swift Charts
//

import SwiftUI
import Charts

/// Main view for analyzing long-term performance trends
struct TrendAnalysisView: View {

    // MARK: - Properties

    let patientId: UUID

    // MARK: - State

    @StateObject private var viewModel: TrendAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        self._viewModel = StateObject(wrappedValue: TrendAnalysisViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Metric selector
                    metricPicker

                    // Time range picker
                    timeRangePicker

                    if viewModel.isLoading {
                        loadingView
                    } else if let analysis = viewModel.currentAnalysis {
                        // Summary header
                        summaryHeader(analysis)

                        // Main chart
                        trendChart(analysis)

                        // Moving average toggle
                        movingAverageToggle

                        // Best/Worst periods
                        periodHighlights(analysis)

                        // Insights
                        insightsSection(analysis)

                        // Export button
                        exportButton(analysis)
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Trend Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        ComparePeriodView(patientId: patientId, metricType: viewModel.selectedMetric)
                    } label: {
                        Label("Compare", systemImage: "arrow.left.arrow.right")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadAnalysis()
            }
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metric")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TrendMetricType.allCases) { metric in
                        MetricChip(
                            metric: metric,
                            isSelected: viewModel.selectedMetric == metric
                        ) {
                            viewModel.selectedMetric = metric
                            Task {
                                await viewModel.loadAnalysis()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            ForEach(TrendTimeRange.allCases) { range in
                Text(range.shortName).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedTimeRange) { _, _ in
            Task {
                await viewModel.loadAnalysis()
            }
        }
    }

    // MARK: - Summary Header

    private func summaryHeader(_ analysis: TrendAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: analysis.summary.direction.icon)
                            .foregroundColor(analysis.summary.direction.color)
                            .font(.title2)

                        Text(analysis.summary.direction.displayName)
                            .font(.title2.bold())
                            .foregroundColor(analysis.summary.direction.color)
                    }

                    Text(analysis.summary.formattedPercentChange)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f", analysis.summary.endValue))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(analysis.metricType.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Mini stats row
            HStack(spacing: 20) {
                TrendStatItem(
                    label: "Start",
                    value: String(format: "%.1f", analysis.summary.startValue)
                )

                TrendStatItem(
                    label: "Best",
                    value: String(format: "%.1f", analysis.summary.bestValue),
                    color: .green
                )

                TrendStatItem(
                    label: "Worst",
                    value: String(format: "%.1f", analysis.summary.worstValue),
                    color: .red
                )

                TrendStatItem(
                    label: "Volatility",
                    value: String(format: "%.1f", analysis.summary.volatility)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trend summary: \(analysis.summary.direction.displayName), \(analysis.summary.formattedPercentChange) change")
    }

    // MARK: - Trend Chart

    private func trendChart(_ analysis: TrendAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(analysis.metricType.displayName) Over Time")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if analysis.dataPoints.isEmpty {
                chartEmptyState
            } else {
                Chart {
                    // Main data line
                    ForEach(analysis.dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(analysis.metricType.color.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        // Data points
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(analysis.metricType.color)
                        .symbolSize(30)
                    }

                    // Moving average line
                    if viewModel.showMovingAverage {
                        ForEach(analysis.dataPoints.filter { $0.movingAverage != nil }) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Moving Avg", point.movingAverage ?? 0)
                            )
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }

                    // Area fill
                    ForEach(analysis.dataPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    analysis.metricType.color.opacity(0.3),
                                    analysis.metricType.color.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Best value marker
                    RuleMark(y: .value("Best", analysis.summary.bestValue))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Best")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .padding(2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(CornerRadius.xs)
                        }
                }
                .chartYScale(domain: calculateYDomain(for: analysis))
                .chartXAxis {
                    AxisMarks(values: .stride(by: calculateXStride(for: analysis))) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatAxisValue(doubleValue, for: analysis.metricType))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 250)
                .animatedTrim(duration: 0.8, delay: 0.1)
                .accessibilityLabel("Trend chart for \(analysis.metricType.displayName)")
                .accessibilityValue("\(analysis.dataPoints.count) data points from \(analysis.timeRange.displayName)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    private var chartEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No data available")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Moving Average Toggle

    private var movingAverageToggle: some View {
        Toggle(isOn: $viewModel.showMovingAverage) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.orange)
                Text("Show 7-Day Moving Average")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Period Highlights

    private func periodHighlights(_ analysis: TrendAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Periods")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                // Best period
                PeriodCard(
                    title: "Best Performance",
                    value: String(format: "%.1f", analysis.summary.bestValue),
                    unit: analysis.metricType.unit,
                    date: analysis.summary.bestDate,
                    color: .green,
                    icon: "star.fill"
                )

                // Worst period
                PeriodCard(
                    title: "Lowest Point",
                    value: String(format: "%.1f", analysis.summary.worstValue),
                    unit: analysis.metricType.unit,
                    date: analysis.summary.worstDate,
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }

    // MARK: - Insights Section

    private func insightsSection(_ analysis: TrendAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(analysis.summary.insights.indices, id: \.self) { index in
                    InsightRow(insight: analysis.summary.insights[index])
                }
            }
        }
    }

    // MARK: - Export Button

    private func exportButton(_ analysis: TrendAnalysis) -> some View {
        Button {
            viewModel.exportData(analysis)
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.primary)
            .cornerRadius(CornerRadius.md)
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            if let exportData = viewModel.exportData {
                TrendShareSheet(items: [exportData])
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing trends...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Trends")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Trend Data", systemImage: "chart.line.downtrend.xyaxis")
        } description: {
            Text("Complete more sessions to see your performance trends over time")
        } actions: {
            Button {
                dismiss()
            } label: {
                Label("Start Training", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helper Methods

    private func calculateYDomain(for analysis: TrendAnalysis) -> ClosedRange<Double> {
        let values = analysis.dataPoints.map { $0.value }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...100
        }

        let padding = (maxValue - minValue) * 0.1
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding

        return lowerBound...upperBound
    }

    private func calculateXStride(for analysis: TrendAnalysis) -> Calendar.Component {
        switch analysis.timeRange {
        case .thirtyDays:
            return .day
        case .ninetyDays, .oneEightyDays:
            return .weekOfYear
        case .oneYear, .allTime:
            return .month
        }
    }

    private func formatAxisValue(_ value: Double, for metric: TrendMetricType) -> String {
        switch metric {
        case .workloadVolume:
            if value >= 1000 {
                return String(format: "%.0fK", value / 1000)
            }
            return String(format: "%.0f", value)
        case .sleepQuality:
            return String(format: "%.1fh", value)
        default:
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Supporting Views

private struct MetricChip: View {
    let metric: TrendMetricType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                Text(metric.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? metric.color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
        }
        .accessibilityLabel(metric.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TrendStatItem: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct PeriodCard: View {
    let title: String
    let value: String
    let unit: String
    let date: Date
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(date, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit) on \(date.formatted(date: .abbreviated, time: .omitted))")
    }
}

private struct InsightRow: View {
    let insight: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))

            Text(insight)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insight: \(insight)")
    }
}

private struct TrendShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    TrendAnalysisView(patientId: UUID())
}
