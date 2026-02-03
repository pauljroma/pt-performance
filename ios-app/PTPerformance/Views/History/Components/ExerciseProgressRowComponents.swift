//
//  ExerciseProgressRowComponents.swift
//  PTPerformance
//
//  Exercise row and detail components for the progress list
//  Extracted from ExerciseProgressView.swift for modularity
//

import SwiftUI

// MARK: - Exercise Progress Row

/// A single row in the exercise progress list
/// Shows exercise name, trend indicator, session count, and improvement badge
/// Expands to show detailed view on tap
struct ExerciseProgressRow: View {
    let exercise: ExerciseProgressItem
    let isExpanded: Bool
    let onTap: () -> Void
    var fallbackUnit: String = "lbs"

    var body: some View {
        VStack(spacing: 0) {
            // Main row (always visible)
            Button(action: onTap) {
                HStack(spacing: Spacing.md) {
                    // Exercise icon
                    Circle()
                        .fill(trendColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: exercise.trend.icon)
                                .foregroundColor(trendColor)
                        )
                        .accessibilityHidden(true)

                    // Exercise info
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if exercise.hasPersonalRecord {
                                Image(systemName: "trophy.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .accessibilityHidden(true)
                            }
                        }

                        HStack(spacing: Spacing.sm) {
                            if let lastDate = exercise.lastPerformed {
                                Text(lastDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(exercise.sessionCount) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Improvement badge
                    if exercise.improvementPercentage != 0 {
                        Text(exercise.formattedImprovement)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(trendColor.opacity(0.2))
                            .foregroundColor(trendColor)
                            .cornerRadius(8)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(rowAccessibilityLabel)
            .accessibilityHint(isExpanded ? "Double tap to collapse details" : "Double tap to expand details")

            // Expanded detail view
            if isExpanded {
                ExerciseProgressDetailView(exercise: exercise, fallbackUnit: fallbackUnit)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var trendColor: Color {
        switch exercise.trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }

    private var rowAccessibilityLabel: String {
        var label = exercise.exerciseName
        if exercise.hasPersonalRecord {
            label += ", has personal record"
        }
        label += ", \(exercise.sessionCount) sessions"
        if let lastDate = exercise.lastPerformed {
            label += ", last performed \(lastDate.formatted(date: .abbreviated, time: .omitted))"
        }
        if exercise.improvementPercentage != 0 {
            label += ", \(exercise.formattedImprovement) improvement"
        }
        return label
    }
}

// MARK: - Exercise Progress Detail View

/// Expanded detail view showing chart, PR badge, recent history, and stats
struct ExerciseProgressDetailView: View {
    let exercise: ExerciseProgressItem
    var fallbackUnit: String = "lbs"

    /// Returns the appropriate unit to display - prefers data unit, falls back to user preference
    private var displayUnit: String {
        exercise.loadUnit ?? fallbackUnit
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Divider()

            // Progress Chart - show loading state if no data points yet
            if !exercise.dataPoints.isEmpty {
                ExerciseProgressChart(
                    dataPoints: exercise.dataPoints,
                    displayUnit: displayUnit
                )
            } else {
                // BUILD 333: Loading state while fetching time-series data
                ChartLoadingPlaceholder()
            }

            // Personal Record Badge
            if let pr = exercise.personalRecord {
                PersonalRecordBadge(record: pr, displayUnit: displayUnit)
            }

            // Recent History
            if !exercise.recentHistory.isEmpty {
                RecentHistorySection(
                    sessions: exercise.recentHistory,
                    displayUnit: displayUnit
                )
            }

            // Summary stats
            SummaryStatsRow(
                averageWeight: exercise.averageWeight,
                totalVolume: exercise.totalVolume,
                sessionCount: exercise.sessionCount,
                displayUnit: displayUnit
            )
        }
        .padding([.horizontal, .bottom])
    }
}

// MARK: - Preview

#if DEBUG
struct ExerciseProgressRowComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ExerciseProgressRow(
                    exercise: sampleExerciseItem,
                    isExpanded: false,
                    onTap: {}
                )

                ExerciseProgressRow(
                    exercise: sampleExerciseItem,
                    isExpanded: true,
                    onTap: {}
                )
            }
            .padding()
        }
        .previewDisplayName("Exercise Progress Rows")
    }

    static var sampleExerciseItem: ExerciseProgressItem {
        ExerciseProgressItem(
            id: "1",
            exerciseId: "ex-1",
            exerciseName: "Barbell Squat",
            dataPoints: sampleDataPoints,
            trend: .increasing,
            averageWeight: 185.0,
            totalVolume: 24500,
            sessionCount: 12,
            lastPerformed: Date(),
            improvementPercentage: 0.15,
            personalRecord: PersonalRecord.sample,
            recentHistory: sampleRecentHistory,
            loadUnit: "lbs"
        )
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

    static var sampleRecentHistory: [ExerciseSessionRecord] {
        let calendar = Calendar.current
        var records: [ExerciseSessionRecord] = []
        for i in 0..<5 {
            let weight = 195.0 - Double(i) * 5.0
            let date = calendar.date(byAdding: .day, value: -i * 3, to: Date()) ?? Date()
            records.append(ExerciseSessionRecord(
                id: "\(i)",
                date: date,
                sets: 3,
                reps: 5,
                weight: weight,
                volume: weight * 5.0 * 3.0,
                isPersonalRecord: i == 0,
                loadUnit: "lbs"
            ))
        }
        return records
    }
}
#endif
