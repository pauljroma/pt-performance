//
//  BigLiftsGrid.swift
//  PTPerformance
//
//  Big Lifts grid component for displaying compound exercise PRs
//  Extracted from ExerciseProgressView.swift for modularity
//  BUILD 340: Big Lifts Scorecard integration
//

import SwiftUI

// MARK: - Inline Big Lifts Grid

/// Displays a grid of "big lift" compound exercises with their PRs prominently
/// Uses ExerciseProgressItem data from the parent view
/// Tapping a card navigates to detailed history for that exercise
struct InlineBigLiftsGrid: View {
    let exercises: [ExerciseProgressItem]
    let preferredUnit: String
    let onExerciseTap: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        if exercises.isEmpty {
            emptyBigLiftsState
        } else {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(exercises.prefix(6)) { exercise in
                    InlineBigLiftCard(
                        exercise: exercise,
                        preferredUnit: preferredUnit,
                        onTap: { onExerciseTap(exercise.exerciseName) }
                    )
                }
            }
        }
    }

    private var emptyBigLiftsState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dumbbell.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No Big Lifts Yet")
                .font(.headline)
            Text("Log bench press, squat, deadlift, or overhead press to see your PRs here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Inline Big Lift Card

/// Individual card for a big lift exercise showing weight, estimated 1RM, and improvement
struct InlineBigLiftCard: View {
    let exercise: ExerciseProgressItem
    let preferredUnit: String
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var displayUnit: String {
        exercise.loadUnit ?? preferredUnit
    }

    private var cardBackgroundColor: Color {
        Color(.secondarySystemGroupedBackground)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Exercise name with trophy if PR
                HStack {
                    Text(shortExerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Spacer()

                    if exercise.hasPersonalRecord {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Spacer()

                // Max weight prominently displayed
                if let pr = exercise.personalRecord {
                    Text(formatWeight(pr.value))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    // Estimated 1RM (if different from max weight)
                    if let estimated1RM = estimated1RMValue, estimated1RM > pr.value {
                        HStack(spacing: 2) {
                            Text("Est 1RM:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatWeight(estimated1RM))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                } else {
                    Text(formatWeight(exercise.averageWeight))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("Avg Weight")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Improvement badge
                if exercise.improvementPercentage != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: exercise.improvementPercentage > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(exercise.formattedImprovement)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(exercise.improvementPercentage > 0 ? .green : .red)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(cardBackgroundColor)
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.exerciseName), \(exercise.personalRecord.map { formatWeight($0.value) } ?? formatWeight(exercise.averageWeight))")
        .accessibilityHint("Double tap to view exercise history")
    }

    /// Shortened exercise name for compact display
    private var shortExerciseName: String {
        let name = exercise.exerciseName
        // Remove common prefixes for compact display
        let shortened = name
            .replacingOccurrences(of: "Barbell ", with: "")
            .replacingOccurrences(of: "Dumbbell ", with: "DB ")
        return shortened
    }

    /// Estimates 1RM using Epley formula if we have rep data
    /// This is a simplified calculation - the full RMCalculator is used in ExerciseHistorySheet
    private var estimated1RMValue: Double? {
        guard exercise.personalRecord != nil else { return nil }
        // Simple Epley formula estimate: weight * (1 + reps/30)
        // Since we don't have rep count in ExerciseProgressItem, return nil
        // The actual 1RM is calculated in ExerciseHistorySheet with full session data
        return nil
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight)) \(displayUnit)"
        }
        return String(format: "%.1f %@", weight, displayUnit)
    }
}

// MARK: - Big Lifts Section Header

/// Header view for the Big Lifts section
struct BigLiftsSectionHeader: View {
    let liftCount: Int

    var body: some View {
        HStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundColor(.orange)
            Text("Big Lifts")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            if liftCount > 4 {
                Text("\(liftCount) lifts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Big Lifts Section, \(liftCount) compound lifts tracked")
    }
}

// MARK: - Preview

#if DEBUG
struct BigLiftsGrid_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                BigLiftsSectionHeader(liftCount: 4)

                InlineBigLiftsGrid(
                    exercises: sampleBigLifts,
                    preferredUnit: "lbs",
                    onExerciseTap: { _ in }
                )
            }
            .padding()
        }
        .previewDisplayName("Big Lifts Grid")
    }

    static var sampleBigLifts: [ExerciseProgressItem] {
        [
            ExerciseProgressItem(
                id: "bench",
                exerciseId: "ex-bench",
                exerciseName: "Bench Press",
                dataPoints: [],
                trend: .improving,
                averageWeight: 185.0,
                totalVolume: 18500,
                sessionCount: 15,
                lastPerformed: Date(),
                improvementPercentage: 0.08,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-bench",
                    exerciseName: "Bench Press",
                    recordType: .maxWeight,
                    value: 225.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 3),
                    previousRecord: 215.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            ),
            ExerciseProgressItem(
                id: "squat",
                exerciseId: "ex-squat",
                exerciseName: "Back Squat",
                dataPoints: [],
                trend: .improving,
                averageWeight: 275.0,
                totalVolume: 32000,
                sessionCount: 18,
                lastPerformed: Date().addingTimeInterval(-86400),
                improvementPercentage: 0.12,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-squat",
                    exerciseName: "Back Squat",
                    recordType: .maxWeight,
                    value: 315.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 7),
                    previousRecord: 295.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            )
        ]
    }
}
#endif
