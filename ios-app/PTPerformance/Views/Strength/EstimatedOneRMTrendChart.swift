//
//  EstimatedOneRMTrendChart.swift
//  PTPerformance
//
//  ACP-1027: Estimated 1RM Trend Charts
//  Displays estimated one-rep max trends using Epley formula
//  with Swift Charts for data visualization.
//

import SwiftUI
import Charts

// MARK: - Estimated 1RM Trend Chart

/// Chart view showing estimated 1RM trends over time for selected exercises
/// Uses Epley formula: 1RM = weight * (1 + reps/30)
struct EstimatedOneRMTrendChart: View {

    // MARK: - Properties

    let exercises: [ExerciseOneRMProgress]
    @Binding var selectedExercise: String?

    // MARK: - State

    @State private var selectedDataPoint: OneRMDataPoint?
    @State private var showExercisePicker = false

    // MARK: - Computed

    private var currentExercise: ExerciseOneRMProgress? {
        exercises.first { $0.exerciseName == selectedExercise } ?? exercises.first
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Exercise selector
            exerciseSelector

            if let exercise = currentExercise {
                // 1RM summary card
                oneRMSummaryCard(exercise: exercise)

                // Main chart
                oneRMChart(exercise: exercise)

                // Detailed lift history
                liftDetailSection(exercise: exercise)
            } else {
                emptyState
            }
        }
    }

    // MARK: - Exercise Selector

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Select Exercise")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(exercises.prefix(10)) { exercise in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExercise = exercise.exerciseName
                            }
                            HapticFeedback.selectionChanged()
                        } label: {
                            VStack(spacing: 4) {
                                Text(exercise.exerciseName.shortLiftName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Text(String(format: "%.0f", exercise.current1RM))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                selectedExercise == exercise.exerciseName
                                    ? Color.modusCyan
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(
                                selectedExercise == exercise.exerciseName ? .white : .primary
                            )
                            .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 1RM Summary Card

    private func oneRMSummaryCard(exercise: ExerciseOneRMProgress) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text(exercise.muscleGroup.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", exercise.current1RM))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()

                        Text(WeightUnit.defaultUnit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Est. 1RM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: Spacing.lg) {
                oneRMStatItem(
                    label: "Peak",
                    value: String(format: "%.0f", exercise.peak1RM),
                    color: .modusTealAccent
                )

                Divider().frame(height: 30)

                oneRMStatItem(
                    label: "Weekly Gain",
                    value: String(format: "%+.1f", exercise.weeklyProgressRate),
                    color: exercise.weeklyProgressRate > 0 ? .modusTealAccent : .red
                )

                Divider().frame(height: 30)

                oneRMStatItem(
                    label: "Sessions",
                    value: "\(exercise.dataPoints.count)",
                    color: .modusCyan
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func oneRMStatItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .monospacedDigit()

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 1RM Chart

    private func oneRMChart(exercise: ExerciseOneRMProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Estimated 1RM Over Time")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text("Epley Formula")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.xs)
            }

            if exercise.dataPoints.isEmpty {
                chartEmptyState
            } else {
                Chart {
                    // 1RM line
                    ForEach(exercise.dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Est. 1RM", point.estimated1RM)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Est. 1RM", point.estimated1RM)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(40)
                    }

                    // Area fill
                    ForEach(exercise.dataPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Est. 1RM", point.estimated1RM)
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

                    // Peak marker
                    RuleMark(y: .value("Peak", exercise.peak1RM))
                        .foregroundStyle(Color.modusTealAccent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Peak")
                                .font(.caption2)
                                .foregroundColor(.modusTealAccent)
                                .padding(2)
                                .background(Color.modusTealAccent.opacity(0.1))
                                .cornerRadius(CornerRadius.xs)
                        }
                }
                .chartYScale(domain: calculateYDomain(for: exercise))
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
                    AxisMarks(values: .stride(by: .day, count: calculateDayStride(for: exercise))) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                }
                .frame(height: 250)
                .animatedTrim(duration: 0.8, delay: 0.1)
                .accessibilityLabel("Estimated 1RM chart for \(exercise.exerciseName)")
                .accessibilityValue("\(exercise.dataPoints.count) data points, current 1RM: \(Int(exercise.current1RM)) \(WeightUnit.defaultUnit)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Lift Detail Section

    private func liftDetailSection(exercise: ExerciseOneRMProgress) -> some View {
        let sortedPoints = exercise.dataPoints.sorted(by: { $0.date > $1.date })
        let recentPoints = Array(sortedPoints.prefix(8))

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Session History")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            ForEach(recentPoints) { point in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("\(Int(point.weight)) \(WeightUnit.defaultUnit) x \(point.reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f", point.estimated1RM))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.modusCyan)
                            .monospacedDigit()

                        Text("Est. 1RM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xs)

                if point.id != recentPoints.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan.opacity(0.5))

            Text("No Exercise Data")
                .font(.headline)

            Text("Complete strength exercises to see your estimated 1RM trends here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }

    private var chartEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.3))

            Text("Not enough data to chart")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func calculateYDomain(for exercise: ExerciseOneRMProgress) -> ClosedRange<Double> {
        let values = exercise.dataPoints.map { $0.estimated1RM }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...300
        }

        let padding = max((maxValue - minValue) * 0.15, 10)
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding

        guard lowerBound < upperBound else { return 0...(maxValue * 1.2) }
        return lowerBound...upperBound
    }

    private func calculateDayStride(for exercise: ExerciseOneRMProgress) -> Int {
        let count = exercise.dataPoints.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 7
    }
}

// MARK: - Preview

#if DEBUG
struct EstimatedOneRMTrendChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExercise = ExerciseOneRMProgress(
            id: "bench",
            exerciseName: "Bench Press",
            dataPoints: (0..<12).map { i in
                OneRMDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -i * 5, to: Date())!,
                    weight: 185 + Double(12 - i) * 2.5,
                    reps: 5,
                    estimated1RM: RMCalculator.epley(weight: 185 + Double(12 - i) * 2.5, reps: 5),
                    volume: (185 + Double(12 - i) * 2.5) * 5 * 3
                )
            },
            current1RM: RMCalculator.epley(weight: 215, reps: 5),
            peak1RM: RMCalculator.epley(weight: 215, reps: 5),
            muscleGroup: .chest,
            lastPerformedDate: Date(),
            weeklyProgressRate: 2.5
        )

        ScrollView {
            EstimatedOneRMTrendChart(
                exercises: [sampleExercise],
                selectedExercise: .constant("Bench Press")
            )
            .padding()
        }
    }
}
#endif
