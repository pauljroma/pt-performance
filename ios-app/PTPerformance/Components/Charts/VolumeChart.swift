//
//  VolumeChart.swift
//  PTPerformance
//
//  Created by Agent 1 - Volume/Strength Trend Charts
//  ACP-1026: Enhanced with tap-to-select data points, annotations, and overlay metrics
//  Line chart showing total volume (sets x reps x weight) over time
//

import SwiftUI
import Charts

/// Reusable volume trend chart component
/// Features tap-to-select data point details, annotation markers,
/// optional overlay metric, and animated line drawing with reduce motion support
struct VolumeChart: View {
    let dataPoints: [VolumeDataPoint]
    var height: CGFloat = 200
    var showAverage: Bool = true
    var annotations: [ChartAnnotation] = []
    var overlayDataPoints: [StrengthDataPoint] = []
    var overlayLabel: String = ""
    var showOverlay: Bool = false

    @State private var isAnimated = false
    @State private var selectedPoint: VolumeDataPoint?
    @State private var selectedAnnotation: ChartAnnotation?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var averageVolume: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.totalVolume }.reduce(0, +) / Double(dataPoints.count)
    }

    private var maxVolume: Double {
        dataPoints.map { $0.totalVolume }.max() ?? 0
    }

    private var accessibilitySummary: String {
        guard !dataPoints.isEmpty else { return "No volume data available" }
        let latestVolume = dataPoints.last?.totalVolume ?? 0
        let avgVolume = averageVolume
        return "Volume trend chart showing \(dataPoints.count) data points. Latest volume: \(formatVolume(latestVolume)). Average: \(formatVolume(avgVolume)) per week"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Volume")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)
                        .accessibilityAddTraits(.isHeader)

                    Text("Total weight lifted per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !dataPoints.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatVolume(averageVolume))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        Text("avg/week")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Selected point tooltip
            if let selected = selectedPoint {
                selectedPointTooltip(selected)
            }

            if dataPoints.isEmpty {
                emptyState
            } else {
                chartView
                    .animatedTrim(duration: 0.8, delay: 0.1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Volume Trend Chart")
        .accessibilityValue(accessibilitySummary)
        .onAppear {
            if reduceMotion {
                isAnimated = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        isAnimated = true
                    }
                }
            }
        }
    }

    // MARK: - Selected Point Tooltip

    private func selectedPointTooltip(_ point: VolumeDataPoint) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatVolume(point.totalVolume))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            Divider()
                .frame(height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(point.sessionCount) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let delta = point.totalVolume - averageVolume
                let sign = delta >= 0 ? "+" : ""
                Text("\(sign)\(formatVolume(delta)) vs avg")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(delta >= 0 ? .modusTealAccent : .red)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedPoint = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.sm)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete workouts to see your volume trends")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                // Line mark
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                // Point marks
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(selectedPoint?.id == point.id ? Color.modusDeepTeal : Color.blue)
                .symbol(.circle)
                .symbolSize(selectedPoint?.id == point.id ? 100 : 50)

                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Overlay metric (e.g., strength data)
            if showOverlay && !overlayDataPoints.isEmpty {
                ForEach(overlayDataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value(overlayLabel, point.estimatedOneRepMax)
                    )
                    .foregroundStyle(Color.modusTealAccent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value(overlayLabel, point.estimatedOneRepMax)
                    )
                    .foregroundStyle(Color.modusTealAccent)
                    .symbol(.diamond)
                    .symbolSize(40)
                }
            }

            // Average line
            if showAverage && averageVolume > 0 {
                RuleMark(y: .value("Average", averageVolume))
                    .foregroundStyle(.gray.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg")
                            .font(.caption2)
                            .padding(Spacing.xxs)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(CornerRadius.xs)
                            .foregroundColor(.gray)
                    }
            }

            // Annotation markers
            ForEach(annotations) { annotation in
                RuleMark(x: .value("Event", annotation.date, unit: .day))
                    .foregroundStyle(annotation.category.color.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Button {
                            selectedAnnotation = annotation
                        } label: {
                            Image(systemName: annotation.category.icon)
                                .font(.caption2)
                                .foregroundColor(annotation.category.color)
                                .padding(Spacing.xxs)
                                .background(annotation.category.color.opacity(0.15))
                                .cornerRadius(CornerRadius.xs)
                        }
                        .buttonStyle(.plain)
                    }
            }

            // Selected point rule mark
            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.date, unit: .day))
                    .foregroundStyle(Color.modusDeepTeal.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartYScale(domain: 0...(maxVolume * 1.1))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(formatAxisVolume(volume))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: calculateDayStride())) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
        .frame(height: height)
        .popover(item: $selectedAnnotation) { annotation in
            annotationPopover(annotation)
        }
    }

    // MARK: - Chart Tap Handler

    private func handleChartTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find the nearest data point
        let closest = dataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })

        withAnimation(.easeOut(duration: 0.2)) {
            if selectedPoint?.id == closest?.id {
                selectedPoint = nil
            } else {
                selectedPoint = closest
                HapticFeedback.light()
            }
        }
    }

    // MARK: - Annotation Popover

    private func annotationPopover(_ annotation: ChartAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: annotation.category.icon)
                    .foregroundColor(annotation.category.color)
                Text(annotation.title)
                    .font(.headline)
            }

            Text(annotation.date, format: .dateTime.month(.wide).day().year())
                .font(.caption)
                .foregroundColor(.secondary)

            if let note = annotation.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(annotation.category.displayName)
                .font(.caption2)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(annotation.category.color.opacity(0.15))
                .foregroundColor(annotation.category.color)
                .cornerRadius(CornerRadius.xs)
        }
        .padding()
        .frame(minWidth: 200)
    }

    // MARK: - Helpers

    private func formatAxisVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func calculateDayStride() -> Int {
        let count = dataPoints.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 7
    }
}

// MARK: - Preview

#if DEBUG
struct VolumeChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = (0..<8).map { week in
            VolumeDataPoint(
                date: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                totalVolume: Double.random(in: 8000...15000),
                sessionCount: Int.random(in: 3...5)
            )
        }

        return VStack(spacing: 20) {
            Text("Volume Chart")
                .font(.headline)

            VolumeChart(
                dataPoints: Array(sampleData.reversed()),
                annotations: [.sampleVacation, .sampleDeload]
            )

            Text("Empty State")
                .font(.headline)

            VolumeChart(dataPoints: [])

            Spacer()
        }
        .padding()
    }
}
#endif
