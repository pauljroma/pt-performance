//
//  VolumeChart.swift
//  PTPerformance
//
//  Created by Agent 1 - Volume/Strength Trend Charts
//  Line chart showing total volume (sets x reps x weight) over time
//

import SwiftUI
import Charts

/// Reusable volume trend chart component
struct VolumeChart: View {
    let dataPoints: [VolumeDataPoint]
    var height: CGFloat = 200
    var showAverage: Bool = true

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

            if dataPoints.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Volume Trend Chart")
        .accessibilityValue(accessibilitySummary)
    }

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

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                // Line mark
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(.blue.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                // Point marks
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
                .symbolSize(50)

                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Average line
            if showAverage && averageVolume > 0 {
                RuleMark(y: .value("Average", averageVolume))
                    .foregroundStyle(.gray.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.gray)
                    }
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
        .frame(height: height)
    }

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

            VolumeChart(dataPoints: Array(sampleData.reversed()))

            Text("Empty State")
                .font(.headline)

            VolumeChart(dataPoints: [])

            Spacer()
        }
        .padding()
    }
}
#endif
