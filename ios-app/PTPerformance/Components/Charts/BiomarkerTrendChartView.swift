//
//  BiomarkerTrendChartView.swift
//  PTPerformance
//
//  Biomarker trend visualization with reference range bands
//  Shows historical biomarker values with color-coded status
//

import SwiftUI
import Charts

/// SwiftUI chart showing biomarker values over time
///
/// Displays historical biomarker data with optimal range bands.
/// Color coding:
/// - Green: Optimal range
/// - Yellow/Teal: Normal range
/// - Red: Outside normal (concerning)
///
/// Features animated line drawing with reduce motion support
struct BiomarkerTrendChartView: View {
    let dataPoints: [BiomarkerTrendPoint]
    let biomarkerName: String
    var height: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accessibilitySummary: String {
        guard !dataPoints.isEmpty else { return "No data available for \(biomarkerName)" }

        let latestValue = dataPoints.last?.value ?? 0
        let latestStatus = dataPoints.last?.status.displayText ?? "Unknown"
        let unit = dataPoints.first?.unit ?? ""

        return "\(biomarkerName) trend chart showing \(dataPoints.count) data points. Latest value: \(String(format: "%.1f", latestValue)) \(unit), status: \(latestStatus)"
    }

    // MARK: - Computed Properties

    private var yAxisDomain: ClosedRange<Double> {
        guard !dataPoints.isEmpty else { return 0...100 }

        let values = dataPoints.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100

        // Include reference ranges in domain calculation
        var domainMin = minValue
        var domainMax = maxValue

        if let normalLow = dataPoints.first?.normalLow {
            domainMin = min(domainMin, normalLow * 0.9)
        }
        if let normalHigh = dataPoints.first?.normalHigh {
            domainMax = max(domainMax, normalHigh * 1.1)
        }

        // Add padding
        let padding = (domainMax - domainMin) * 0.1
        return (domainMin - padding)...(domainMax + padding)
    }

    private var hasReferenceRanges: Bool {
        guard let first = dataPoints.first else { return false }
        return first.normalLow != nil && first.normalHigh != nil
    }

    private var unit: String {
        dataPoints.first?.unit ?? ""
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(biomarkerName)
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if let latest = dataPoints.last {
                    HStack(spacing: 6) {
                        Image(systemName: latest.status.iconName)
                            .foregroundColor(statusColor(for: latest.status))

                        Text("\(String(format: "%.1f", latest.value)) \(unit)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor(for: latest.status))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(for: latest.status).opacity(0.15))
                    .cornerRadius(8)
                }
            }

            if dataPoints.isEmpty {
                emptyState
            } else {
                chart
            }

            // Legend
            if hasReferenceRanges {
                legend
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(biomarkerName) Trend Chart")
        .accessibilityValue(accessibilitySummary)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Optimal range band (if available)
            if let first = dataPoints.first,
               let optLow = first.optimalLow,
               let optHigh = first.optimalHigh {
                RectangleMark(
                    xStart: nil,
                    xEnd: nil,
                    yStart: .value("OptLow", optLow),
                    yEnd: .value("OptHigh", optHigh)
                )
                .foregroundStyle(Color.modusTealAccent.opacity(0.2))
            }

            // Normal range band (if available)
            if let first = dataPoints.first,
               let normLow = first.normalLow,
               let normHigh = first.normalHigh {
                // Lower normal band (below optimal)
                if let optLow = first.optimalLow, normLow < optLow {
                    RectangleMark(
                        xStart: nil,
                        xEnd: nil,
                        yStart: .value("NormLow", normLow),
                        yEnd: .value("OptLow", optLow)
                    )
                    .foregroundStyle(Color.yellow.opacity(0.15))
                }

                // Upper normal band (above optimal)
                if let optHigh = first.optimalHigh, normHigh > optHigh {
                    RectangleMark(
                        xStart: nil,
                        xEnd: nil,
                        yStart: .value("OptHigh", optHigh),
                        yEnd: .value("NormHigh", normHigh)
                    )
                    .foregroundStyle(Color.yellow.opacity(0.15))
                }
            }

            // Data line
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.modusCyan.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                // Data points with status color
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(statusColor(for: point.status))
                .symbol(.circle)
                .symbolSize(80)

                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.modusCyan.opacity(0.3), Color.modusCyan.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: yAxisDomain)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatAxisValue(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
            }
        }
        .frame(height: height)
        .animatedTrim(duration: 0.8, delay: 0.1)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No historical data")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Upload more lab results to see trends over time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: .modusTealAccent, text: "Optimal")
            legendItem(color: .yellow, text: "Normal")
            legendItem(color: .red, text: "Concern")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func statusColor(for status: BiomarkerStatus) -> Color {
        switch status {
        case .optimal:
            return .modusTealAccent
        case .normal:
            return .modusCyan
        case .low, .high:
            return .orange
        case .critical:
            return .red
        }
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fk", value / 1000)
        } else if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BiomarkerTrendChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = (0..<8).map { week in
            BiomarkerTrendPoint(
                date: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                value: Double.random(in: 45...85),
                biomarkerType: "vitamin_d",
                unit: "ng/mL",
                optimalLow: 50,
                optimalHigh: 70,
                normalLow: 30,
                normalHigh: 100
            )
        }

        return ScrollView {
            VStack(spacing: 20) {
                BiomarkerTrendChartView(
                    dataPoints: Array(sampleData.reversed()),
                    biomarkerName: "Vitamin D"
                )

                BiomarkerTrendChartView(
                    dataPoints: [],
                    biomarkerName: "Testosterone"
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
