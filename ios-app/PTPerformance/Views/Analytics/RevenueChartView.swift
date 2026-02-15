//
//  RevenueChartView.swift
//  PTPerformance
//
//  ACP-989: Subscription Analytics Dashboard
//  Reusable revenue chart with Swift Charts AreaMark, gradient fill,
//  date range selection, and tap-to-inspect tooltip.
//

import SwiftUI
import Charts

/// Reusable revenue chart showing revenue over time with gradient fill and date range selector
///
/// Uses Swift Charts AreaMark with a .modusCyan gradient. Supports interactive
/// tap/hover to display a tooltip with exact revenue and subscriber values.
///
/// ## Usage Example
/// ```swift
/// RevenueChartView(
///     dataPoints: revenueHistory,
///     selectedRange: $selectedRange,
///     onRangeChanged: { range in
///         await loadData(days: range.days)
///     }
/// )
/// ```
struct RevenueChartView: View {

    // MARK: - Properties

    let dataPoints: [RevenueDataPoint]
    @Binding var selectedRange: AnalyticsDateRange
    var onRangeChanged: ((AnalyticsDateRange) async -> Void)?

    // MARK: - State

    @State private var selectedDataPoint: RevenueDataPoint?
    @State private var plotWidth: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with range selector
            headerSection

            if dataPoints.isEmpty {
                emptyState
            } else {
                // Chart
                chartSection

                // Summary footer
                summaryFooter
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Revenue chart")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label("Revenue", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Date range selector
                Picker("Range", selection: $selectedRange) {
                    ForEach(AnalyticsDateRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                .onChange(of: selectedRange) { _, newRange in
                    selectedDataPoint = nil
                    if let onRangeChanged = onRangeChanged {
                        Task {
                            await onRangeChanged(newRange)
                        }
                    }
                }
            }

            // Tooltip display when a point is selected
            if let selected = selectedDataPoint {
                tooltipView(for: selected)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Tooltip

    private func tooltipView(for point: RevenueDataPoint) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(point.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(point.formattedRevenue)
                    .font(.title3.bold())
                    .foregroundColor(.modusCyan)
            }

            Divider()
                .frame(height: 32)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Subscribers")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(point.subscribers)")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedDataPoint = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
            .accessibilityLabel("Dismiss tooltip")
        }
        .padding(Spacing.sm)
        .background(Color.modusCyan.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Selected: \(point.formattedDate), revenue \(point.formattedRevenue), \(point.subscribers) subscribers")
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        Chart {
            ForEach(dataPoints) { point in
                // Area fill with gradient
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.modusCyan.opacity(colorScheme == .dark ? 0.35 : 0.25),
                            Color.modusCyan.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Line on top of area
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(Color.modusCyan)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }

            // Selected point indicator
            if let selected = selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date, unit: .day))
                    .foregroundStyle(Color.modusCyan.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date, unit: .day),
                    y: .value("Revenue", selected.revenue)
                )
                .foregroundStyle(Color.modusCyan)
                .symbolSize(80)
                .annotation(position: .top) {
                    Text(selected.formattedRevenue)
                        .font(.caption2.bold())
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.modusCyan.opacity(0.12))
                        )
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStride, count: xAxisStrideCount)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel(format: xAxisLabelFormat)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatYAxisValue(doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisDomain)
        .frame(height: 220)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, proxy: proxy, geometry: geometry)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleChartTap(at: value.location, proxy: proxy, geometry: geometry)
                            }
                    )
            }
        }
        .accessibilityLabel("Revenue over time chart, \(dataPoints.count) data points")
        .accessibilityValue("Range: \(selectedRange.displayName)")
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        HStack(spacing: Spacing.lg) {
            if let first = dataPoints.first, let last = dataPoints.last {
                let change = last.revenue - first.revenue
                let percentChange = first.revenue > 0 ? (change / first.revenue) * 100 : 0
                let isPositive = change >= 0

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Period Total")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(dataPoints.reduce(0) { $0 + $1.revenue }))
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Daily Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(dataPoints.reduce(0) { $0 + $1.revenue } / max(Double(dataPoints.count), 1)))
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(String(format: "%@%.1f%%", isPositive ? "+" : "", percentChange))
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(isPositive ? DesignTokens.statusSuccess : DesignTokens.statusError)
                }
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No revenue data available")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Revenue data will appear once subscriptions are active")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No revenue data available")
    }

    // MARK: - Chart Interaction

    private func handleChartTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = location.x - plotFrame.origin.x

        guard xPosition >= 0, xPosition <= plotFrame.width else {
            return
        }

        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }

        // Find the closest data point to the tapped date
        let closest = dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })

        withAnimation(.easeOut(duration: 0.15)) {
            selectedDataPoint = closest
        }

        HapticFeedback.selectionChanged()
    }

    // MARK: - Axis Configuration

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .sevenDays: return .day
        case .thirtyDays: return .day
        case .ninetyDays: return .weekOfYear
        }
    }

    private var xAxisStrideCount: Int {
        switch selectedRange {
        case .sevenDays: return 1
        case .thirtyDays: return 5
        case .ninetyDays: return 2
        }
    }

    private var xAxisLabelFormat: Date.FormatStyle {
        switch selectedRange {
        case .sevenDays:
            return .dateTime.weekday(.abbreviated)
        case .thirtyDays:
            return .dateTime.month(.abbreviated).day()
        case .ninetyDays:
            return .dateTime.month(.abbreviated).day()
        }
    }

    private var yAxisDomain: ClosedRange<Double> {
        let revenues = dataPoints.map { $0.revenue }
        guard let minVal = revenues.min(), let maxVal = revenues.max() else {
            return 0...1000
        }
        let padding = (maxVal - minVal) * 0.15
        return max(0, minVal - padding)...(maxVal + padding)
    }

    // MARK: - Formatting Helpers

    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }

    private static let wholeCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatCurrency(_ value: Double) -> String {
        Self.wholeCurrencyFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Revenue Chart - With Data") {
    RevenueChartView(
        dataPoints: RevenueDataPoint.sampleHistory,
        selectedRange: .constant(.thirtyDays)
    )
    .padding()
}

#Preview("Revenue Chart - Empty") {
    RevenueChartView(
        dataPoints: [],
        selectedRange: .constant(.thirtyDays)
    )
    .padding()
}
#endif
