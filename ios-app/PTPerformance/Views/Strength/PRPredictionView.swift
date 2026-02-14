//
//  PRPredictionView.swift
//  PTPerformance
//
//  ACP-1027: PR Prediction
//  Predicts future PRs based on recent progression rate.
//  Estimates when user will hit next milestone weights.
//

import SwiftUI
import Charts

// MARK: - PR Prediction View

/// View that predicts when users will hit next PR milestones
/// Based on recent progression rate and historical data
struct PRPredictionView: View {

    // MARK: - Properties

    let predictions: [PRPrediction]
    let exerciseData: [ExerciseOneRMProgress]

    // MARK: - State

    @State private var selectedPrediction: PRPrediction?

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if predictions.isEmpty {
                emptyState
            } else {
                // Predictions header
                predictionsHeader

                // Prediction cards
                ForEach(predictions.prefix(8)) { prediction in
                    predictionCard(prediction)
                }

                // Projection chart for selected prediction
                if let selected = selectedPrediction,
                   let exercise = exerciseData.first(where: { $0.exerciseName == selected.exerciseName }) {
                    projectionChart(prediction: selected, exercise: exercise)
                }

                // Methodology note
                methodologyNote
            }
        }
    }

    // MARK: - Predictions Header

    private var predictionsHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.modusCyan)
                Text("PR Predictions")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }
            .accessibilityAddTraits(.isHeader)

            Text("Based on your recent progression rate, here are estimated timelines for hitting your next milestones.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Prediction Card

    private func predictionCard(_ prediction: PRPrediction) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedPrediction?.id == prediction.id {
                    selectedPrediction = nil
                } else {
                    selectedPrediction = prediction
                }
            }
            HapticFeedback.light()
        } label: {
            VStack(spacing: Spacing.sm) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prediction.exerciseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: prediction.recentTrend.icon)
                                .font(.caption2)
                            Text(prediction.recentTrend.displayText)
                                .font(.caption2)
                        }
                        .foregroundColor(prediction.recentTrend.color)
                    }

                    Spacer()

                    // Confidence badge
                    confidenceBadge(prediction.confidence)
                }

                // Progress bar: current -> milestone
                progressToMilestone(prediction: prediction)

                // Stats row
                HStack(spacing: Spacing.md) {
                    predictionStat(
                        label: "Current",
                        value: String(format: "%.0f", prediction.current1RM),
                        unit: WeightUnit.defaultUnit,
                        color: .modusCyan
                    )

                    predictionStat(
                        label: "Target",
                        value: String(format: "%.0f", prediction.nextMilestone),
                        unit: WeightUnit.defaultUnit,
                        color: .modusTealAccent
                    )

                    predictionStat(
                        label: "ETA",
                        value: formatWeeks(prediction.estimatedWeeksToMilestone),
                        unit: "",
                        color: .orange
                    )

                    predictionStat(
                        label: "Rate",
                        value: String(format: "+%.1f", prediction.weeklyProgressRate),
                        unit: "/wk",
                        color: .purple
                    )
                }

                // Estimated date
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Estimated: ")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(estimatedDate(for: prediction))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)

                    Spacer()

                    if selectedPrediction?.id == prediction.id {
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                            .foregroundColor(.modusCyan)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                selectedPrediction?.id == prediction.id
                    ? Color.modusCyan.opacity(0.05)
                    : Color(.systemBackground)
            )
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        selectedPrediction?.id == prediction.id
                            ? Color.modusCyan.opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prediction.exerciseName): current \(Int(prediction.current1RM)), target \(Int(prediction.nextMilestone)) \(WeightUnit.defaultUnit)")
        .accessibilityValue("Estimated \(prediction.estimatedWeeksToMilestone) weeks, \(Int(prediction.confidence)) percent confidence")
    }

    // MARK: - Progress to Milestone

    private func progressToMilestone(prediction: PRPrediction) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let totalRange = prediction.nextMilestone - max(prediction.current1RM - 50, 0)
                let currentProgress = (prediction.current1RM - max(prediction.current1RM - 50, 0)) / totalRange

                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 8)

                    // Progress
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.modusCyan, .modusTealAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(CGFloat(currentProgress), 1.0), height: 8)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)

            // Labels
            HStack {
                Text(String(format: "%.0f", max(prediction.current1RM - 50, 0)))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.0f %@", prediction.nextMilestone, WeightUnit.defaultUnit))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.modusTealAccent)
            }
        }
    }

    // MARK: - Prediction Stat

    private func predictionStat(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Confidence Badge

    private func confidenceBadge(_ confidence: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor(confidence))
                .frame(width: 6, height: 6)

            Text(String(format: "%.0f%%", confidence))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor(confidence))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor(confidence).opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Projection Chart

    private func projectionChart(prediction: PRPrediction, exercise: ExerciseOneRMProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Projected Progression")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            Chart {
                // Historical data points
                ForEach(exercise.dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("1RM", point.estimated1RM)
                    )
                    .foregroundStyle(Color.modusCyan.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("1RM", point.estimated1RM)
                    )
                    .foregroundStyle(Color.modusCyan)
                    .symbolSize(30)
                }

                // Projected future line
                let projectedPoints = generateProjectedPoints(
                    from: prediction.current1RM,
                    rate: prediction.weeklyProgressRate,
                    weeks: prediction.estimatedWeeksToMilestone
                )

                ForEach(Array(projectedPoints.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Projected", point.value)
                    )
                    .foregroundStyle(Color.modusTealAccent.gradient)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }

                // Milestone line
                RuleMark(y: .value("Milestone", prediction.nextMilestone))
                    .foregroundStyle(Color.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(String(format: "%.0f %@", prediction.nextMilestone, WeightUnit.defaultUnit))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(3)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(CornerRadius.xs)
                    }
            }
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
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                }
            }
            .frame(height: 220)

            // Legend
            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.modusCyan)
                        .frame(width: 16, height: 3)
                    Text("Actual")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.modusTealAccent)
                        .frame(width: 16, height: 3)
                        .overlay(
                            Rectangle()
                                .stroke(Color.modusTealAccent, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                .frame(height: 1)
                        )
                    Text("Projected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 16, height: 3)
                        .overlay(
                            Rectangle()
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                .frame(height: 1)
                        )
                    Text("Milestone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Methodology Note

    private var methodologyNote: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.modusCyan)

            Text("Predictions are based on your recent weekly progression rate using the Epley 1RM formula. Actual results may vary based on training, nutrition, recovery, and other factors.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.modusCyan.opacity(0.05))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan.opacity(0.5))

            Text("No Predictions Available")
                .font(.headline)

            Text("Complete at least 3 sessions on an exercise with consistent progress to see PR predictions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Helpers

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 75 { return .modusTealAccent }
        if confidence >= 50 { return .orange }
        return .secondary
    }

    private func formatWeeks(_ weeks: Int) -> String {
        if weeks <= 0 { return "Soon" }
        if weeks == 1 { return "1 wk" }
        if weeks >= 52 {
            let months = weeks / 4
            return "\(months)mo"
        }
        return "\(weeks) wk"
    }

    private func estimatedDate(for prediction: PRPrediction) -> String {
        let targetDate = Calendar.current.date(
            byAdding: .weekOfYear,
            value: prediction.estimatedWeeksToMilestone,
            to: Date()
        ) ?? Date()
        return targetDate.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private struct ProjectedPoint {
        let date: Date
        let value: Double
    }

    private func generateProjectedPoints(
        from current: Double,
        rate: Double,
        weeks: Int
    ) -> [ProjectedPoint] {
        let cappedWeeks = min(weeks, 26) // Cap projection at 6 months
        return (0...cappedWeeks).map { week in
            ProjectedPoint(
                date: Calendar.current.date(byAdding: .weekOfYear, value: week, to: Date()) ?? Date(),
                value: current + (rate * Double(week))
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PRPredictionView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePredictions: [PRPrediction] = [
            PRPrediction(
                exerciseName: "Bench Press",
                current1RM: 245,
                nextMilestone: 275,
                estimatedWeeksToMilestone: 6,
                weeklyProgressRate: 2.5,
                confidence: 78,
                recentTrend: .improving
            ),
            PRPrediction(
                exerciseName: "Squat",
                current1RM: 345,
                nextMilestone: 365,
                estimatedWeeksToMilestone: 4,
                weeklyProgressRate: 3.0,
                confidence: 85,
                recentTrend: .improving
            ),
            PRPrediction(
                exerciseName: "Deadlift",
                current1RM: 395,
                nextMilestone: 405,
                estimatedWeeksToMilestone: 2,
                weeklyProgressRate: 2.0,
                confidence: 92,
                recentTrend: .improving
            )
        ]

        ScrollView {
            PRPredictionView(
                predictions: samplePredictions,
                exerciseData: []
            )
            .padding()
        }
    }
}
#endif
