//
//  BigLiftsScorecard.swift
//  PTPerformance
//
//  Big Lifts Scorecard view displaying compound exercise PRs and estimated totals
//  BUILD 340: Integrated with strength mode dashboard
//

import SwiftUI

/// Big Lifts Scorecard - Displays compound exercise personal records
/// Shows SBD total, individual lift PRs, and progress trends
struct BigLiftsScorecard: View {
    // MARK: - Properties

    let patientId: String?

    // MARK: - State

    @StateObject private var viewModel = BigLiftsViewModel()
    @State private var showExerciseDetail: String?
    @State private var showAllLifts = false

    // MARK: - Initialization

    init(patientId: String? = nil) {
        self.patientId = patientId
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                // SBD Total
                sbdTotalSection

                // Lifts grid
                liftsGridSection

                // Stats row
                statsRow
            }
        }
        .task {
            await loadData()
        }
        .sheetWithHaptic(isPresented: $showAllLifts) {
            AllLiftsSheet(lifts: viewModel.bigLifts, onSelectLift: { lift in
                showExerciseDetail = lift.exerciseName
            })
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Big Lifts")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Spacer()

            if !viewModel.bigLifts.isEmpty {
                Button("See All") {
                    HapticFeedback.light()
                    showAllLifts = true
                }
                .font(.caption)
                .foregroundColor(.modusCyan)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                HapticFeedback.light()
                Task { await viewModel.retryFetch() }
            }
            .font(.caption)
            .foregroundColor(.modusCyan)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "dumbbell.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Big Lifts Yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Log bench press, squat, or deadlift to see your PRs here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - SBD Total Section

    private var sbdTotalSection: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Est. Total (SBD)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", viewModel.estimatedTotal))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("lbs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // PR count badge
            if viewModel.totalPRCount > 0 {
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("\(viewModel.totalPRCount)")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)

                    Text("Total PRs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Lifts Grid Section

    private var liftsGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            ForEach(viewModel.bigLifts.prefix(4)) { lift in
                liftCard(lift)
            }
        }
    }

    private func liftCard(_ lift: BigLiftSummary) -> some View {
        Button(action: {
            HapticFeedback.light()
            showExerciseDetail = lift.exerciseName
        }) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(shortLiftName(lift.exerciseName))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if lift.hasRecentPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }

                Spacer()

                Text(lift.formattedMaxWeight)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .monospacedDigit()

                if let improvement = lift.formattedImprovement {
                    HStack(spacing: 2) {
                        Image(systemName: lift.isImproving ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(improvement)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(lift.isImproving ? .green : .red)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lift.exerciseName), \(lift.formattedMaxWeight)")
        .accessibilityHint("Tap to view exercise history")
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.lg) {
            statItem(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(viewModel.improvingCount)",
                label: "Improving"
            )

            Divider()
                .frame(height: 30)

            statItem(
                icon: "flame.fill",
                value: "\(viewModel.bigLifts.count)",
                label: "Tracked"
            )

            if let avgImprovement = viewModel.averageImprovement {
                Divider()
                    .frame(height: 30)

                statItem(
                    icon: "percent",
                    value: String(format: "%.1f%%", avgImprovement),
                    label: "Avg Gain"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.modusCyan)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func loadData() async {
        guard let patientIdString = patientId ?? PTSupabaseClient.shared.userId,
              let uuid = UUID(uuidString: patientIdString) else {
            return
        }
        await viewModel.fetchData(for: uuid)
    }

    private func shortLiftName(_ name: String) -> String {
        switch name {
        case "Bench Press": return "Bench"
        case "Back Squat", "Squat": return "Squat"
        case "Deadlift": return "Deadlift"
        case "Overhead Press": return "OHP"
        case "Barbell Row": return "Row"
        default: return String(name.prefix(8))
        }
    }
}

// MARK: - All Lifts Sheet

private struct AllLiftsSheet: View {
    let lifts: [BigLiftSummary]
    let onSelectLift: (BigLiftSummary) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(lifts) { lift in
                Button(action: {
                    onSelectLift(lift)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lift.exerciseName)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if lift.hasRecentPR {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }

                            if let days = lift.daysSinceLastPerformed {
                                Text(days == 0 ? "Performed today" : "\(days) days ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(lift.formattedMaxWeight)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if let improvement = lift.formattedImprovement {
                                Text(improvement)
                                    .font(.caption)
                                    .foregroundColor(lift.isImproving ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("All Big Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BigLiftsScorecard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                BigLiftsScorecard()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
