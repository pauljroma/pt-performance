//
//  StalledLiftsDetectorView.swift
//  PTPerformance
//
//  ACP-1027: Stalled Lifts Detector
//  Highlights exercises where progress has plateaued (no increase in 3+ weeks)
//  and provides actionable suggestions for breaking through plateaus.
//

import SwiftUI
import Charts

// MARK: - Stalled Lifts Detector View

/// View that identifies and displays exercises where progress has stalled
/// Provides actionable suggestions for breaking through plateaus
struct StalledLiftsDetectorView: View {

    // MARK: - Properties

    let stalledLifts: [StalledLiftInfo]
    let allExercises: [ExerciseOneRMProgress]
    let onSelectLift: (String) -> Void

    // MARK: - Computed

    private var progressingLifts: [ExerciseOneRMProgress] {
        let stalledNames = Set(stalledLifts.map { $0.exerciseName })
        return allExercises.filter { !stalledNames.contains($0.exerciseName) && $0.weeklyProgressRate > 0 }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary header
            summaryHeader

            if stalledLifts.isEmpty {
                noStalledLiftsView
            } else {
                // Stalled lifts list
                stalledLiftsList

                // Healthy lifts for comparison
                if !progressingLifts.isEmpty {
                    progressingLiftsSection
                }
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: Spacing.md) {
            // Stalled count
            VStack(spacing: 4) {
                Text("\(stalledLifts.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(stalledLifts.isEmpty ? .modusTealAccent : DesignTokens.statusWarning)

                Text("Stalled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                (stalledLifts.isEmpty ? Color.modusTealAccent : DesignTokens.statusWarning).opacity(0.1)
            )
            .cornerRadius(CornerRadius.md)

            // Progressing count
            VStack(spacing: 4) {
                Text("\(progressingLifts.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.modusTealAccent)

                Text("Progressing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusTealAccent.opacity(0.1))
            .cornerRadius(CornerRadius.md)

            // Total tracked
            VStack(spacing: 4) {
                Text("\(allExercises.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.modusCyan)

                Text("Tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - No Stalled Lifts

    private var noStalledLiftsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.modusTealAccent)

            Text("All Lifts Progressing!")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.modusDeepTeal)

            Text("None of your tracked exercises have stalled. Keep up the consistent work and progressive overload!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.modusTealAccent.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Stalled Lifts List

    private var stalledLiftsList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignTokens.statusWarning)
                Text("Stalled Exercises")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(stalledLifts) { lift in
                stalledLiftCard(lift)
            }
        }
    }

    private func stalledLiftCard(_ lift: StalledLiftInfo) -> some View {
        Button {
            HapticFeedback.light()
            onSelectLift(lift.exerciseName)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header row
                HStack {
                    Image(systemName: lift.muscleGroup.icon)
                        .foregroundColor(lift.muscleGroup.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lift.exerciseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(lift.muscleGroup.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Stalled badge
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.caption)
                        Text("\(lift.weeksSinceProgress)w stalled")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignTokens.statusWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.statusWarning.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
                }

                // 1RM info
                HStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current 1RM")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(format: "%.0f %@", lift.current1RM, WeightUnit.defaultUnit))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Peak 1RM")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(format: "%.0f %@", lift.peak1RM, WeightUnit.defaultUnit))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.modusTealAccent)
                            .monospacedDigit()
                    }

                    Spacer()
                }

                // Mini plateau chart
                if !lift.recentDataPoints.isEmpty {
                    Chart(lift.recentDataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("1RM", point.estimated1RM)
                        )
                        .foregroundStyle(DesignTokens.statusWarning.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("1RM", point.estimated1RM)
                        )
                        .foregroundStyle(DesignTokens.statusWarning)
                        .symbolSize(20)
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .frame(height: 50)
                }

                // Suggestion
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    Text(lift.suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.xs)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(CornerRadius.sm)

                // View details indicator
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("View Progress")
                            .font(.caption2)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lift.exerciseName), stalled for \(lift.weeksSinceProgress) weeks at \(Int(lift.current1RM)) \(WeightUnit.defaultUnit)")
        .accessibilityHint("Tap to view progress details")
    }

    // MARK: - Progressing Lifts Section

    private var progressingLiftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundColor(.modusTealAccent)
                Text("Still Progressing")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(progressingLifts.prefix(5)) { exercise in
                HStack {
                    Image(systemName: exercise.muscleGroup.icon)
                        .foregroundColor(exercise.muscleGroup.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(String(format: "+%.1f %@/week", exercise.weeklyProgressRate, WeightUnit.defaultUnit))
                            .font(.caption)
                            .foregroundColor(.modusTealAccent)
                    }

                    Spacer()

                    Text(String(format: "%.0f %@", exercise.current1RM, WeightUnit.defaultUnit))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .padding(.vertical, Spacing.xs)

                if exercise.id != progressingLifts.prefix(5).last?.id {
                    Divider()
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
struct StalledLiftsDetectorView_Previews: PreviewProvider {
    static var previews: some View {
        let stalledData: [StalledLiftInfo] = [
            StalledLiftInfo(
                exerciseName: "Bench Press",
                muscleGroup: .chest,
                current1RM: 245,
                peak1RM: 250,
                weeksSinceProgress: 4,
                suggestion: "Try adjusting rep ranges (e.g., switch to 3x3 or 5x5). Increase training frequency for chest if recovery allows.",
                recentDataPoints: (0..<5).map { i in
                    OneRMDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -i * 5, to: Date())!,
                        weight: 215,
                        reps: 5,
                        estimated1RM: 245 + Double.random(in: -3...3),
                        volume: 215 * 5 * 3
                    )
                }
            ),
            StalledLiftInfo(
                exerciseName: "Overhead Press",
                muscleGroup: .shoulders,
                current1RM: 155,
                peak1RM: 158,
                weeksSinceProgress: 6,
                suggestion: "Consider a deload week followed by a variation change. Try paused reps or tempo work for Overhead Press.",
                recentDataPoints: (0..<4).map { i in
                    OneRMDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())!,
                        weight: 135,
                        reps: 5,
                        estimated1RM: 155 + Double.random(in: -2...2),
                        volume: 135 * 5 * 3
                    )
                }
            )
        ]

        ScrollView {
            StalledLiftsDetectorView(
                stalledLifts: stalledData,
                allExercises: [],
                onSelectLift: { _ in }
            )
            .padding()
        }
    }
}
#endif
