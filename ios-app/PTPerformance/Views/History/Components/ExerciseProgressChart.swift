//
//  ExerciseProgressChart.swift
//  PTPerformance
//
//  Reusable chart component for displaying exercise progress over time
//  Extracted from ExerciseProgressView.swift for modularity
//

import SwiftUI
import Charts

// MARK: - Exercise Progress Chart

/// A line chart showing exercise weight progress over time
/// Displays data points with a smooth interpolation line
struct ExerciseProgressChart: View {
    let dataPoints: [ExerciseDataPoint]
    let displayUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Progress Over Time")
                .font(.subheadline)
                .fontWeight(.medium)

            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
            }
            .chartYAxisLabel("Weight (\(displayUnit))")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .padding(.vertical, Spacing.xs)
            .accessibilityLabel(chartAccessibilityLabel)
            .accessibilityHint("Shows weight progress over time")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private var chartAccessibilityLabel: String {
        guard !dataPoints.isEmpty else {
            return "No progress data available"
        }
        let minWeight = dataPoints.map { $0.weight }.min() ?? 0
        let maxWeight = dataPoints.map { $0.weight }.max() ?? 0
        let latest = dataPoints.sorted { $0.date > $1.date }.first
        var label = "Progress chart showing \(dataPoints.count) data points"
        label += ", weight range from \(Int(minWeight)) to \(Int(maxWeight)) \(displayUnit)"
        if let latest = latest {
            label += ", most recent \(Int(latest.weight)) \(displayUnit)"
        }
        return label
    }
}

// MARK: - Chart Loading Placeholder

/// A loading placeholder shown while chart data is being fetched
struct ChartLoadingPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Progress Over Time")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Spacer()
                VStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading chart data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Personal Record Badge

/// A decorative badge displaying a personal record achievement
struct PersonalRecordBadge: View {
    let record: PersonalRecord
    let displayUnit: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Personal Record")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(record.formattedValue)
                    .font(.title3)
                    .bold()

                Text("Achieved \(record.achievedDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let improvement = record.formattedImprovement {
                VStack {
                    Text(improvement)
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("vs previous")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(prAccessibilityLabel)
    }

    private var prAccessibilityLabel: String {
        var label = "Personal Record: \(record.formattedValue), achieved \(record.achievedDate.formatted(date: .abbreviated, time: .omitted))"
        if let improvement = record.formattedImprovement {
            label += ", \(improvement) improvement versus previous record"
        }
        return label
    }
}

// MARK: - Recent History Section

/// Displays a list of recent exercise sessions
struct RecentHistorySection: View {
    let sessions: [ExerciseSessionRecord]
    let displayUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Sessions")
                .font(.subheadline)
                .fontWeight(.medium)
                .accessibilityAddTraits(.isHeader)

            ForEach(sessions.prefix(5)) { session in
                sessionRow(session)

                if session.id != sessions.prefix(5).last?.id {
                    Divider()
                        .accessibilityHidden(true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func sessionRow(_ session: ExerciseSessionRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date, style: .date)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(session.sets) sets x \(session.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let weight = session.weight {
                Text(String(format: "%.1f %@", weight, session.loadUnit ?? displayUnit))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if session.isPersonalRecord {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sessionAccessibilityLabel(session))
    }

    private func sessionAccessibilityLabel(_ session: ExerciseSessionRecord) -> String {
        var label = "\(session.date.formatted(date: .abbreviated, time: .omitted))"
        label += ", \(session.sets) sets of \(session.reps) reps"
        if let weight = session.weight {
            label += " at \(String(format: "%.1f", weight)) \(session.loadUnit ?? displayUnit)"
        }
        if session.isPersonalRecord {
            label += ", personal record"
        }
        return label
    }
}

// MARK: - Preview

#if DEBUG
struct ExerciseProgressChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            ExerciseProgressChart(
                dataPoints: sampleDataPoints,
                displayUnit: "lbs"
            )

            ChartLoadingPlaceholder()

            PersonalRecordBadge(
                record: PersonalRecord.sample,
                displayUnit: "lbs"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }

    static var sampleDataPoints: [ExerciseDataPoint] {
        let calendar = Calendar.current
        var points: [ExerciseDataPoint] = []
        for i in 0..<8 {
            let weight = 175.0 + Double(i) * 2.5
            let date = calendar.date(byAdding: .day, value: -i * 7, to: Date()) ?? Date()
            points.append(ExerciseDataPoint(
                date: date,
                weight: weight,
                reps: 5,
                sets: 3,
                volume: weight * 5.0 * 3.0
            ))
        }
        return points
    }
}
#endif
