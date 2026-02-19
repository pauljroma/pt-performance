//
//  ComparePeriodView.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  Side-by-side period comparison view
//

import SwiftUI
import Charts

/// View for comparing two time periods
struct ComparePeriodView: View {

    // MARK: - Properties

    let patientId: UUID
    let metricType: TrendMetricType

    // MARK: - State

    @StateObject private var viewModel: ComparePeriodViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(patientId: UUID, metricType: TrendMetricType) {
        self.patientId = patientId
        self.metricType = metricType
        self._viewModel = StateObject(wrappedValue: ComparePeriodViewModel(
            patientId: patientId,
            metricType: metricType
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period selectors
                    periodSelectors

                    if viewModel.isLoading {
                        loadingView
                    } else if let comparison = viewModel.comparison {
                        // Comparison result
                        comparisonResult(comparison)

                        // Overlay chart
                        overlayChart(comparison)

                        // Difference breakdown
                        differenceBreakdown(comparison)

                        // Insights
                        insightsSection(comparison)
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        instructionView
                    }
                }
                .padding()
            }
            .navigationTitle("Compare Periods")
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

    // MARK: - Period Selectors

    private var periodSelectors: some View {
        VStack(spacing: 16) {
            // Metric indicator
            HStack {
                Image(systemName: metricType.icon)
                    .foregroundColor(metricType.color)
                Text("Comparing \(metricType.displayName)")
                    .font(.headline)
                Spacer()
            }

            // Quick presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Compare")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ComparisonPreset.allCases) { preset in
                            PresetChip(
                                preset: preset,
                                isSelected: viewModel.selectedPreset == preset
                            ) {
                                viewModel.selectPreset(preset)
                            }
                        }
                    }
                }
            }

            // Custom date pickers
            DisclosureGroup("Custom Date Ranges") {
                VStack(spacing: 16) {
                    // Period 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period 1")
                            .font(.subheadline.bold())
                            .foregroundColor(.modusCyan)

                        HStack {
                            DatePicker(
                                "Start",
                                selection: $viewModel.period1Start,
                                displayedComponents: .date
                            )
                            .labelsHidden()

                            Text("to")
                                .foregroundColor(.secondary)

                            DatePicker(
                                "End",
                                selection: $viewModel.period1End,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        }
                    }

                    Divider()

                    // Period 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period 2")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        HStack {
                            DatePicker(
                                "Start",
                                selection: $viewModel.period2Start,
                                displayedComponents: .date
                            )
                            .labelsHidden()

                            Text("to")
                                .foregroundColor(.secondary)

                            DatePicker(
                                "End",
                                selection: $viewModel.period2End,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        }
                    }

                    Button("Compare Custom Periods") {
                        Task {
                            await viewModel.compareCustomPeriods()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
                .padding(.top, Spacing.xs)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Comparison Result

    private func comparisonResult(_ comparison: RangeComparison) -> some View {
        VStack(spacing: 16) {
            // Main improvement indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.significantDifference ? "Significant Change" : "Minor Change")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(comparison.formattedImprovement)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(comparison.improvement >= 0 ? .green : .red)
                }

                Spacer()

                // Direction arrow
                Image(systemName: comparison.improvement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(comparison.improvement >= 0 ? .green : .red)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill((comparison.improvement >= 0 ? Color.green : Color.red).opacity(0.1))
            )

            // Period summaries side by side
            HStack(spacing: 12) {
                PeriodSummaryCard(
                    title: "Period 1",
                    summary: comparison.range1Summary,
                    dateInterval: comparison.range1,
                    color: .modusCyan,
                    metricType: metricType
                )

                PeriodSummaryCard(
                    title: "Period 2",
                    summary: comparison.range2Summary,
                    dateInterval: comparison.range2,
                    color: .orange,
                    metricType: metricType
                )
            }
        }
    }

    // MARK: - Overlay Chart

    private func overlayChart(_ comparison: RangeComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Comparison")
                .font(.headline)

            // Bar chart comparison
            Chart {
                // Period 1 bars
                BarMark(
                    x: .value("Metric", "Average"),
                    y: .value("Value", (comparison.range1Summary.startValue + comparison.range1Summary.endValue) / 2)
                )
                .foregroundStyle(.blue)
                .position(by: .value("Period", "Period 1"))

                BarMark(
                    x: .value("Metric", "Best"),
                    y: .value("Value", comparison.range1Summary.bestValue)
                )
                .foregroundStyle(.blue)
                .position(by: .value("Period", "Period 1"))

                BarMark(
                    x: .value("Metric", "End"),
                    y: .value("Value", comparison.range1Summary.endValue)
                )
                .foregroundStyle(.blue)
                .position(by: .value("Period", "Period 1"))

                // Period 2 bars
                BarMark(
                    x: .value("Metric", "Average"),
                    y: .value("Value", (comparison.range2Summary.startValue + comparison.range2Summary.endValue) / 2)
                )
                .foregroundStyle(.orange)
                .position(by: .value("Period", "Period 2"))

                BarMark(
                    x: .value("Metric", "Best"),
                    y: .value("Value", comparison.range2Summary.bestValue)
                )
                .foregroundStyle(.orange)
                .position(by: .value("Period", "Period 2"))

                BarMark(
                    x: .value("Metric", "End"),
                    y: .value("Value", comparison.range2Summary.endValue)
                )
                .foregroundStyle(.orange)
                .position(by: .value("Period", "Period 2"))
            }
            .chartLegend(position: .bottom)
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.subtle)
        }
    }

    // MARK: - Difference Breakdown

    private func differenceBreakdown(_ comparison: RangeComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Breakdown")
                .font(.headline)

            VStack(spacing: 8) {
                DifferenceRow(
                    label: "Starting Value",
                    value1: comparison.range1Summary.startValue,
                    value2: comparison.range2Summary.startValue,
                    unit: metricType.unit,
                    higherIsBetter: metricType.higherIsBetter
                )

                DifferenceRow(
                    label: "Ending Value",
                    value1: comparison.range1Summary.endValue,
                    value2: comparison.range2Summary.endValue,
                    unit: metricType.unit,
                    higherIsBetter: metricType.higherIsBetter
                )

                DifferenceRow(
                    label: "Best Value",
                    value1: comparison.range1Summary.bestValue,
                    value2: comparison.range2Summary.bestValue,
                    unit: metricType.unit,
                    higherIsBetter: metricType.higherIsBetter
                )

                DifferenceRow(
                    label: "Volatility",
                    value1: comparison.range1Summary.volatility,
                    value2: comparison.range2Summary.volatility,
                    unit: "",
                    higherIsBetter: false  // Lower volatility is better
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Insights Section

    private func insightsSection(_ comparison: RangeComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Changed?")
                .font(.headline)

            VStack(spacing: 8) {
                CompareInsightCard(
                    icon: comparison.significantDifference ? "exclamationmark.circle.fill" : "info.circle.fill",
                    color: comparison.significantDifference ? (comparison.improvement >= 0 ? .green : .orange) : .modusCyan,
                    message: comparison.comparisonInsight
                )

                if comparison.range2Summary.volatility < comparison.range1Summary.volatility {
                    CompareInsightCard(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        message: "Consistency improved - less variation in Period 2"
                    )
                } else if comparison.range2Summary.volatility > comparison.range1Summary.volatility * 1.2 {
                    CompareInsightCard(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        message: "More variation in Period 2 - consider focusing on consistency"
                    )
                }

                if comparison.improvement > 10 {
                    CompareInsightCard(
                        icon: "star.fill",
                        color: .yellow,
                        message: "Strong improvement! Keep up what you've been doing"
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Comparing periods...")
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
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Comparison Failed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                if let preset = viewModel.selectedPreset {
                    viewModel.selectPreset(preset)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Instruction View

    private var instructionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Select Periods to Compare")
                .font(.headline)

            Text("Choose a quick preset or set custom date ranges to compare your performance between two time periods")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

private struct PresetChip: View {
    let preset: ComparisonPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preset.displayName)
                .font(.caption)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.modusCyan : Color(.tertiarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(CornerRadius.xl)
        }
    }
}

private struct PeriodSummaryCard: View {
    let title: String
    let summary: TrendSummary
    let dateInterval: DateInterval
    let color: Color
    let metricType: TrendMetricType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(color)

            Text(String(format: "%.1f", summary.endValue))
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(metricType.unit)
                .font(.caption2)
                .foregroundColor(.secondary)

            Divider()

            Text(dateRangeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var dateRangeString: String {
        let formatter = Self.monthDayFormatter
        return "\(formatter.string(from: dateInterval.start)) - \(formatter.string(from: dateInterval.end))"
    }
}

private struct DifferenceRow: View {
    let label: String
    let value1: Double
    let value2: Double
    let unit: String
    let higherIsBetter: Bool

    private var difference: Double {
        value2 - value1
    }

    private var isImprovement: Bool {
        higherIsBetter ? difference > 0 : difference < 0
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(String(format: "%.1f", value1))
                .font(.subheadline)
                .foregroundColor(.modusCyan)
                .frame(width: 60, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.1f", value2))
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 60, alignment: .trailing)

            // Change indicator
            Text(String(format: "%+.1f", difference))
                .font(.caption.bold())
                .foregroundColor(abs(difference) < 0.5 ? .gray : (isImprovement ? .green : .red))
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

private struct CompareInsightCard: View {
    let icon: String
    let color: Color
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Comparison Presets

enum ComparisonPreset: String, CaseIterable, Identifiable {
    case thisWeekVsLast = "this_week_vs_last"
    case thisMonthVsLast = "this_month_vs_last"
    case last30VsPrevious30 = "last_30_vs_previous"
    case last90VsPrevious90 = "last_90_vs_previous"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thisWeekVsLast:
            return "This Week vs Last"
        case .thisMonthVsLast:
            return "This Month vs Last"
        case .last30VsPrevious30:
            return "Last 30 vs Prior 30"
        case .last90VsPrevious90:
            return "Last 90 vs Prior 90"
        }
    }

    var dateIntervals: (DateInterval, DateInterval) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisWeekVsLast:
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? now
            return (
                DateInterval(start: lastWeekStart, end: thisWeekStart),
                DateInterval(start: thisWeekStart, end: now)
            )

        case .thisMonthVsLast:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
            return (
                DateInterval(start: lastMonthStart, end: thisMonthStart),
                DateInterval(start: thisMonthStart, end: now)
            )

        case .last30VsPrevious30:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: now) ?? now
            return (
                DateInterval(start: sixtyDaysAgo, end: thirtyDaysAgo),
                DateInterval(start: thirtyDaysAgo, end: now)
            )

        case .last90VsPrevious90:
            let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            let oneEightyDaysAgo = calendar.date(byAdding: .day, value: -180, to: now) ?? now
            return (
                DateInterval(start: oneEightyDaysAgo, end: ninetyDaysAgo),
                DateInterval(start: ninetyDaysAgo, end: now)
            )
        }
    }
}

// MARK: - ViewModel

@MainActor
class ComparePeriodViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedPreset: ComparisonPreset?
    @Published var period1Start: Date = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
    @Published var period1End: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var period2Start: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var period2End: Date = Date()
    @Published var comparison: RangeComparison?
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Properties

    let patientId: UUID
    let metricType: TrendMetricType
    private let service = TrendAnalysisService.shared

    // MARK: - Initialization

    init(patientId: UUID, metricType: TrendMetricType) {
        self.patientId = patientId
        self.metricType = metricType
    }

    // MARK: - Methods

    func selectPreset(_ preset: ComparisonPreset) {
        selectedPreset = preset
        let intervals = preset.dateIntervals
        period1Start = intervals.0.start
        period1End = intervals.0.end
        period2Start = intervals.1.start
        period2End = intervals.1.end

        Task {
            await compare(range1: intervals.0, range2: intervals.1)
        }
    }

    func compareCustomPeriods() async {
        selectedPreset = nil
        let range1 = DateInterval(start: period1Start, end: period1End)
        let range2 = DateInterval(start: period2Start, end: period2End)
        await compare(range1: range1, range2: range2)
    }

    private func compare(range1: DateInterval, range2: DateInterval) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            comparison = try await service.compareRanges(
                patientId: patientId,
                metric: metricType,
                range1: range1,
                range2: range2
            )
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    ComparePeriodView(patientId: UUID(), metricType: .sessionAdherence)
}
