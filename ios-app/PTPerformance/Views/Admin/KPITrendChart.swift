//
//  KPITrendChart.swift
//  PTPerformance
//
//  Reusable Trend Chart Component for KPI Dashboard
//  M10: KPI dashboard with trend visualization
//
//  Features:
//  - Line chart with gradient fill
//  - Target line indicator
//  - Hover/tap for data point details
//  - Animation on load
//

import SwiftUI
import Charts

// MARK: - KPI Trend Chart

/// Reusable trend chart for displaying KPI metrics over time
/// Uses Swift Charts with gradient fill and target line
struct KPITrendChart: View {
    let title: String
    let data: [KPITrendDataPoint]
    let targetValue: Double?
    let formatValue: (Double) -> String
    let trendColor: Color
    let isInverted: Bool // For metrics where lower is better (e.g., latency)

    @State private var selectedPoint: KPITrendDataPoint?
    @State private var isAnimating = false

    init(
        title: String,
        data: [KPITrendDataPoint],
        targetValue: Double? = nil,
        formatValue: @escaping (Double) -> String = { String(format: "%.1f", $0) },
        trendColor: Color = .blue,
        isInverted: Bool = false
    ) {
        self.title = title
        self.data = data
        self.targetValue = targetValue
        self.formatValue = formatValue
        self.trendColor = trendColor
        self.isInverted = isInverted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            header

            // Chart
            if data.isEmpty {
                emptyState
            } else {
                chartView
            }

            // Selected point detail
            if let selected = selectedPoint {
                selectedPointDetail(selected)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                if let latest = data.last {
                    Text(formatValue(latest.value))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            Spacer()

            // Trend indicator
            trendBadge
        }
    }

    private var trendBadge: some View {
        let trend = data.trendDirection
        let isPositive = isInverted ? trend == .down : trend == .up

        return HStack(spacing: 4) {
            Image(systemName: trend.iconName)
                .font(.caption)

            if let change = data.percentageChange {
                Text(String(format: "%+.1f%%", change))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(trend == .stable ? .gray : (isPositive ? .green : .red))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((trend == .stable ? Color.gray : (isPositive ? Color.green : Color.red)).opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart {
            // Area fill with gradient
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", isAnimating ? point.value : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            trendColor.opacity(0.3),
                            trendColor.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", isAnimating ? point.value : 0)
                )
                .foregroundStyle(trendColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }

            // Data points
            ForEach(data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", isAnimating ? point.value : 0)
                )
                .foregroundStyle(selectedPoint?.id == point.id ? trendColor : Color.clear)
                .symbolSize(selectedPoint?.id == point.id ? 100 : 40)
            }

            // Target line
            if let target = targetValue {
                RuleMark(y: .value("Target", target))
                    .foregroundStyle(Color.green.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target: \(formatValue(target))")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(CornerRadius.xs)
                    }
            }
        }
        .chartYScale(domain: yAxisDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: axisStrideCount)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisDate(date))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatValue(doubleValue))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleChartInteraction(at: value.location, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                // Keep selection for a moment, then clear
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        selectedPoint = nil
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 180)
        .animation(.easeInOut(duration: 0.3), value: selectedPoint?.id)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No data available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: KPITrendDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatFullDate(point.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatValue(point.value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            if let target = targetValue {
                let meetsTarget = isInverted ? point.value <= target : point.value >= target
                Label(
                    meetsTarget ? "On Target" : "Below Target",
                    systemImage: meetsTarget ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.caption)
                .foregroundColor(meetsTarget ? .green : .orange)
            }
        }
        .padding(10)
        .background(trendColor.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Helpers

    private var yAxisDomain: ClosedRange<Double> {
        let values = data.map(\.value)
        let min = (values.min() ?? 0)
        let max = (values.max() ?? 1)

        var lower = min - (max - min) * 0.1
        var upper = max + (max - min) * 0.1

        // Include target in range if provided
        if let target = targetValue {
            lower = Swift.min(lower, target - (max - min) * 0.1)
            upper = Swift.max(upper, target + (max - min) * 0.1)
        }

        // Ensure minimum range
        if upper - lower < 0.01 {
            lower = min - 0.1
            upper = max + 0.1
        }

        return lower...upper
    }

    private var axisStrideCount: Int {
        switch data.count {
        case 0...7: return 1
        case 8...14: return 2
        case 15...30: return 5
        default: return 7
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if data.count <= 7 {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func handleChartInteraction(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let date = proxy.value(atX: location.x, as: Date.self) else { return }

        // Find nearest point
        let nearestPoint = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })

        withAnimation(.easeInOut(duration: 0.15)) {
            selectedPoint = nearestPoint
        }
    }
}

// MARK: - Specialized Chart Variants

/// Percentage-based trend chart (0-100%)
struct PercentageTrendChart: View {
    let title: String
    let data: [KPITrendDataPoint]
    let targetPercentage: Double
    let trendColor: Color

    var body: some View {
        KPITrendChart(
            title: title,
            data: data,
            targetValue: targetPercentage,
            formatValue: { "\(Int($0 * 100))%" },
            trendColor: trendColor
        )
    }
}

/// Latency trend chart (milliseconds)
struct LatencyTrendChart: View {
    let title: String
    let data: [KPITrendDataPoint]
    let targetMs: Int

    var body: some View {
        KPITrendChart(
            title: title,
            data: data,
            targetValue: Double(targetMs),
            formatValue: { ms in
                if ms < 1000 {
                    return "\(Int(ms))ms"
                } else {
                    return String(format: "%.1fs", ms / 1000)
                }
            },
            trendColor: .orange,
            isInverted: true // Lower latency is better
        )
    }
}

// MARK: - Compact Trend Chart

/// Compact trend chart for dashboard cards
struct CompactTrendChart: View {
    let data: [KPITrendDataPoint]
    let trendColor: Color
    let showPoints: Bool

    @State private var isAnimating = false

    init(data: [KPITrendDataPoint], trendColor: Color = .blue, showPoints: Bool = false) {
        self.data = data
        self.trendColor = trendColor
        self.showPoints = showPoints
    }

    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", isAnimating ? point.value : (data.first?.value ?? 0))
                )
                .foregroundStyle(trendColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }

            if showPoints {
                ForEach(data) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", isAnimating ? point.value : (data.first?.value ?? 0))
                    )
                    .foregroundStyle(trendColor)
                    .symbolSize(20)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Multi-Metric Comparison Chart

/// Chart for comparing multiple metrics
struct MultiMetricTrendChart: View {
    let title: String
    let series: [(name: String, data: [KPITrendDataPoint], color: Color)]
    let formatValue: (Double) -> String

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Chart {
                ForEach(series, id: \.name) { item in
                    ForEach(item.data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", isAnimating ? point.value : 0),
                            series: .value("Metric", item.name)
                        )
                        .foregroundStyle(item.color)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 200)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isAnimating = true
                }
            }

            // Legend
            HStack(spacing: 16) {
                ForEach(series, id: \.name) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)

                        Text(item.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct KPITrendChart_Previews: PreviewProvider {
    static var sampleData: [KPITrendDataPoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> KPITrendDataPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return KPITrendDataPoint(date: date, value: Double.random(in: 0.55...0.75))
        }
    }

    static var latencyData: [KPITrendDataPoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> KPITrendDataPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return KPITrendDataPoint(date: date, value: Double.random(in: 2500...4500))
        }
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                PercentageTrendChart(
                    title: "PT Weekly Active Usage",
                    data: sampleData,
                    targetPercentage: 0.65,
                    trendColor: .blue
                )

                LatencyTrendChart(
                    title: "p95 Latency",
                    data: latencyData,
                    targetMs: 5000
                )

                CompactTrendChart(data: sampleData, trendColor: .green, showPoints: true)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
