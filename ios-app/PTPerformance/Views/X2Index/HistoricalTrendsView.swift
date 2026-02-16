//
//  HistoricalTrendsView.swift
//  PTPerformance
//
//  Phase 3 Integration - Historical Trends View
//  Displays trend analysis for patient metrics over time
//

import SwiftUI
import Charts

// MARK: - Trend Direction

enum HistoricalTrendDirection {
    case improving
    case declining
    case stable

    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .secondary
        }
    }
}

// MARK: - Historical Trends View

struct HistoricalTrendsView: View {

    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: HistoricalTrendsViewModel
    @State private var selectedMetric: TrendMetric = .readiness
    @State private var selectedTimeRange: HistoricalTimeRange = .month
    @State private var animateCharts = false

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: HistoricalTrendsViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Metric selector
                metricSelector
                    .padding(.horizontal)

                // Time range selector
                timeRangeSelector
                    .padding(.horizontal)

                // Main trend chart
                if viewModel.isLoading {
                    loadingChart
                } else if viewModel.hasData {
                    mainTrendChart
                        .opacity(animateCharts ? 1 : 0)
                        .offset(y: animateCharts ? 0 : 20)
                } else {
                    emptyStateView
                }

                // Summary statistics
                if viewModel.hasData {
                    statisticsCard
                        .opacity(animateCharts ? 1 : 0)
                        .offset(y: animateCharts ? 0 : 20)
                }

                // Comparison insights
                if !viewModel.insights.isEmpty {
                    insightsCard
                        .opacity(animateCharts ? 1 : 0)
                        .offset(y: animateCharts ? 0 : 20)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticService.light()
            await viewModel.load()
        }
        .task {
            await viewModel.load()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
        .onChange(of: selectedMetric) { _, _ in
            animateCharts = false
            Task {
                await viewModel.loadMetric(selectedMetric, range: selectedTimeRange)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateCharts = true
                }
            }
        }
        .onChange(of: selectedTimeRange) { _, _ in
            animateCharts = false
            Task {
                await viewModel.loadMetric(selectedMetric, range: selectedTimeRange)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateCharts = true
                }
            }
        }
    }

    // MARK: - Metric Selector

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TrendMetric.allCases) { metric in
                    metricButton(metric)
                }
            }
            .padding(.vertical, Spacing.xxs)
        }
    }

    private func metricButton(_ metric: TrendMetric) -> some View {
        let isSelected = selectedMetric == metric

        return Button {
            withAnimation(.spring(response: 0.3)) {
                HapticService.selection()
                selectedMetric = metric
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                Text(metric.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? metric.color : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(metric.displayName) metric")
        .accessibilityHint("Double tap to view \(metric.displayName) trends")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(HistoricalTimeRange.allCases) { range in
                timeRangeButton(range)
            }
        }
    }

    private func timeRangeButton(_ range: HistoricalTimeRange) -> some View {
        let isSelected = selectedTimeRange == range

        return Button {
            withAnimation(.spring(response: 0.3)) {
                HapticService.selection()
                selectedTimeRange = range
            }
        } label: {
            Text(range.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .modusCyan : .secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.modusCyan.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(range.accessibilityName) time range")
        .accessibilityHint("Double tap to view data for \(range.accessibilityName.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Main Trend Chart

    private var mainTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedMetric.displayName)
                    .font(.headline)

                Spacer()

                if let trend = viewModel.overallTrend {
                    HistoricalTrendBadge(trend: trend)
                }
            }

            // Chart
            if #available(iOS 16.0, *) {
                chartContent
                    .frame(height: 220)
            } else {
                legacyChartPlaceholder
            }

            // Period comparison
            if let comparison = viewModel.periodComparison {
                HStack {
                    Text("vs previous period:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(comparison)
                        .font(.caption.weight(.medium))
                        .foregroundColor(viewModel.isImproving ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    @available(iOS 16.0, *)
    private var chartContent: some View {
        Chart {
            ForEach(viewModel.dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(selectedMetric.color.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Average line
            if let avg = viewModel.averageValue {
                RuleMark(y: .value("Average", avg))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("Avg: \(Int(avg))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
            }
        }
        .chartYScale(domain: viewModel.yAxisRange)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }

    private var legacyChartPlaceholder: some View {
        VStack {
            Text("Charts require iOS 16+")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }

    // MARK: - Loading Chart

    private var loadingChart: some View {
        VStack(spacing: 16) {
            // Skeleton chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 220)
                .overlay(
                    ProgressView()
                )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Data Available")
                .font(.headline)

            Text("Start tracking \(selectedMetric.displayName.lowercased()) to see trends over time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TrendStatisticBox(label: "Average", value: viewModel.averageDisplay, color: .modusCyan)
                TrendStatisticBox(label: "High", value: viewModel.highDisplay, color: .green)
                TrendStatisticBox(label: "Low", value: viewModel.lowDisplay, color: .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.headline)
            }

            ForEach(viewModel.insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.modusCyan)
                        .font(.caption)

                    Text(insight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct HistoricalTrendBadge: View {
    let trend: HistoricalTrendDirection

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
            Text(trend.displayName)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(trend.color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

struct TrendStatisticBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Models

enum TrendMetric: String, CaseIterable, Identifiable {
    case readiness = "readiness"
    case pain = "pain"
    case adherence = "adherence"
    case volume = "volume"
    case strength = "strength"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readiness: return "Readiness"
        case .pain: return "Pain Level"
        case .adherence: return "Adherence"
        case .volume: return "Volume"
        case .strength: return "Strength"
        }
    }

    var icon: String {
        switch self {
        case .readiness: return "heart.fill"
        case .pain: return "cross.circle.fill"
        case .adherence: return "checkmark.circle.fill"
        case .volume: return "chart.bar.fill"
        case .strength: return "figure.strengthtraining.traditional"
        }
    }

    var color: Color {
        switch self {
        case .readiness: return .green
        case .pain: return .red
        case .adherence: return .blue
        case .volume: return .orange
        case .strength: return .purple
        }
    }
}

enum HistoricalTimeRange: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case threeMonths = "3months"
    case year = "year"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .year: return "1Y"
        }
    }

    var accessibilityName: String {
        switch self {
        case .week: return "One week"
        case .month: return "One month"
        case .threeMonths: return "Three months"
        case .year: return "One year"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    /// Maps to the service-layer TrendTimeRange
    var serviceTimeRange: TrendTimeRange {
        switch self {
        case .week: return .thirtyDays
        case .month: return .thirtyDays
        case .threeMonths: return .ninetyDays
        case .year: return .oneYear
        }
    }
}

// MARK: - TrendMetric to TrendMetricType Mapping

extension TrendMetric {
    /// Maps to the service-layer TrendMetricType
    var serviceMetricType: TrendMetricType {
        switch self {
        case .readiness: return .recoveryScore
        case .pain: return .painLevel
        case .adherence: return .sessionAdherence
        case .volume: return .workloadVolume
        case .strength: return .strengthProgress
        }
    }
}

// MARK: - Data Point

struct HistoricalTrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - ViewModel

@MainActor
final class HistoricalTrendsViewModel: ObservableObject {

    // MARK: - Properties

    let patientId: UUID
    private let trendService = TrendAnalysisService.shared

    @Published private(set) var dataPoints: [HistoricalTrendDataPoint] = []
    @Published private(set) var isLoading = false
    @Published private(set) var overallTrend: HistoricalTrendDirection?
    @Published private(set) var periodComparison: String?
    @Published private(set) var isImproving = false
    @Published private(set) var insights: [String] = []

    var hasData: Bool { !dataPoints.isEmpty }

    var averageValue: Double? {
        guard !dataPoints.isEmpty else { return nil }
        return dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)
    }

    var averageDisplay: String {
        guard let avg = averageValue else { return "-" }
        return String(format: "%.0f", avg)
    }

    var highDisplay: String {
        guard let high = dataPoints.map(\.value).max() else { return "-" }
        return String(format: "%.0f", high)
    }

    var lowDisplay: String {
        guard let low = dataPoints.map(\.value).min() else { return "-" }
        return String(format: "%.0f", low)
    }

    var yAxisRange: ClosedRange<Double> {
        guard let min = dataPoints.map(\.value).min(),
              let max = dataPoints.map(\.value).max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
    }

    // MARK: - Methods

    func load() async {
        await loadMetric(.readiness, range: .month)
    }

    func loadMetric(_ metric: TrendMetric, range: HistoricalTimeRange) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let analysis = try await trendService.analyzeTrend(
                patientId: patientId,
                metric: metric.serviceMetricType,
                range: range.serviceTimeRange
            )

            // Convert AnalyticsTrendDataPoints to HistoricalTrendDataPoints
            dataPoints = analysis.dataPoints.map { point in
                HistoricalTrendDataPoint(date: point.date, value: point.value)
            }

            // Map TrendDirection to HistoricalTrendDirection
            switch analysis.summary.direction {
            case .improving:
                overallTrend = .improving
                isImproving = true
            case .declining:
                overallTrend = .declining
                isImproving = false
            case .stable, .fluctuating:
                overallTrend = .stable
                isImproving = false
            }

            // Build period comparison string from summary
            let percentChange = analysis.summary.percentChange
            if abs(percentChange) > 0.1 {
                periodComparison = String(format: "%.1f%%", abs(percentChange)) + (percentChange > 0 ? " increase" : " decrease")
            } else {
                periodComparison = nil
            }

            // Use real insights from analysis
            insights = analysis.summary.insights
        } catch {
            // On error, return empty data instead of mock data
            dataPoints = []
            overallTrend = nil
            periodComparison = nil
            isImproving = false
            insights = []
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HistoricalTrendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoricalTrendsView(patientId: UUID())
        }
    }
}
#endif
