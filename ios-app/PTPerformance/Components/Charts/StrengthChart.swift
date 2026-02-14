//
//  StrengthChart.swift
//  PTPerformance
//
//  Created by Agent 1 - Volume/Strength Trend Charts
//  Line chart showing estimated 1RM progression over time
//

import SwiftUI
import Charts

/// Reusable strength progression chart component
/// Features animated line drawing with reduce motion support
struct StrengthChart: View {
    @Environment(\.colorScheme) private var colorScheme
    let dataPoints: [StrengthDataPoint]
    let exerciseName: String
    var height: CGFloat = 200
    var showImprovement: Bool = true

    private var startingMax: Double {
        dataPoints.first?.estimatedOneRepMax ?? 0
    }

    private var currentMax: Double {
        dataPoints.last?.estimatedOneRepMax ?? 0
    }

    private var improvement: Double {
        guard startingMax > 0 else { return 0 }
        return ((currentMax - startingMax) / startingMax) * 100
    }

    private var peakMax: Double {
        dataPoints.map { $0.estimatedOneRepMax }.max() ?? 0
    }

    private var accessibilitySummary: String {
        guard !dataPoints.isEmpty else { return "No strength data available" }
        let improvementText = improvement >= 0 ? "up" : "down"
        return "Strength progression chart for \(exerciseName) showing \(dataPoints.count) data points. Current estimated 1RM: \(String(format: "%.1f", currentMax)) \(WeightUnit.defaultUnit), \(improvementText) \(String(format: "%.1f", abs(improvement))) percent from start"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strength Progress")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text(exerciseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !dataPoints.isEmpty && showImprovement {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(improvement >= 0 ? .green : .red)

                            Text(String(format: "%+.1f%%", improvement))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(improvement >= 0 ? .green : .red)
                        }

                        Text("Est. 1RM: \(String(format: "%.0f", currentMax)) \(WeightUnit.defaultUnit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
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
        .accessibilityLabel("Strength Progression Chart")
        .accessibilityValue(accessibilitySummary)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete strength exercises to track your 1RM progression")
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
                // Line mark for estimated 1RM
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Est. 1RM", point.estimatedOneRepMax)
                )
                .foregroundStyle(.green.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                // Point marks
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Est. 1RM", point.estimatedOneRepMax)
                )
                .foregroundStyle(.green)
                .symbol(.circle)
                .symbolSize(50)

                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Est. 1RM", point.estimatedOneRepMax)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.3), .green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Starting baseline
            if startingMax > 0 {
                RuleMark(y: .value("Starting", startingMax))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .bottom, alignment: .leading) {
                        Text("Start")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(CornerRadius.xs)
                            .foregroundColor(.orange)
                    }
            }
        }
        .chartYScale(domain: calculateYDomain())
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(Int(weight))")
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

    private func calculateYDomain() -> ClosedRange<Double> {
        let minValue = dataPoints.map { $0.estimatedOneRepMax }.min() ?? 0
        let maxValue = peakMax

        // Add some padding to the domain
        let padding = (maxValue - minValue) * 0.1
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding

        // Ensure we have a valid range
        if lowerBound >= upperBound {
            return 0...(maxValue * 1.2)
        }

        return lowerBound...upperBound
    }

    private func calculateDayStride() -> Int {
        let count = dataPoints.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 7
    }
}

// MARK: - Strength Chart with Data Loading

/// Wrapper view that handles data display with loading state
struct StrengthChartSection: View {
    let data: StrengthChartData?
    let isLoading: Bool
    let error: String?
    let onRetry: () -> Void

    var body: some View {
        if let data = data {
            StrengthChart(
                dataPoints: data.dataPoints,
                exerciseName: data.exerciseName
            )
        } else if isLoading {
            loadingView
        } else if let error = error {
            errorView(error)
        } else {
            emptySelectionView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading strength data...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)

            Text("Unable to Load Strength Data")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptySelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("Select an Exercise")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Choose an exercise to view strength progression")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

#if DEBUG
struct StrengthChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = (0..<12).map { day in
            StrengthDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -day * 3, to: Date())!,
                exerciseName: "Squat",
                weight: 185 + Double(12 - day) * 2.5,
                reps: Int.random(in: 3...8),
                estimatedOneRepMax: 200 + Double(12 - day) * 3
            )
        }

        return ScrollView {
            VStack(spacing: 20) {
                Text("Strength Chart - With Data")
                    .font(.headline)

                StrengthChart(
                    dataPoints: Array(sampleData.reversed()),
                    exerciseName: "Squat"
                )

                Text("Strength Chart - Empty State")
                    .font(.headline)

                StrengthChart(
                    dataPoints: [],
                    exerciseName: "Bench Press"
                )

                Text("Strength Chart Section - Loading")
                    .font(.headline)

                StrengthChartSection(
                    data: nil,
                    isLoading: true,
                    error: nil,
                    onRetry: {}
                )

                Spacer()
            }
            .padding()
        }
    }
}
#endif
