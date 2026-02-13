//
//  StrengthModeDashboardView.swift
//  PTPerformance
//
//  Full dashboard view for Strength Mode
//  ACP-MODE: Comprehensive strength-focused dashboard with big lifts tracking,
//  PRs, volume analytics, and progression suggestions
//

import SwiftUI

/// Strength Mode Dashboard View - Comprehensive strength training monitoring
/// Displays big lifts scorecard, personal records, volume trends, and AI suggestions
struct StrengthModeDashboardView: View {
    // MARK: - Properties

    let patientId: UUID

    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel = StrengthModeDashboardViewModel()
    @State private var showExerciseDetail: String?
    @State private var showAllPRs = false
    @State private var selectedTimeRange: StrengthTimeRange = .month

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header section
                headerSection

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.showError, let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    // SBD Total Card
                    sbdTotalCard

                    // Big Lifts Grid
                    bigLiftsSection

                    // Recent PRs section
                    if !viewModel.recentPRs.isEmpty {
                        recentPRsSection
                    }

                    // Weekly Volume section
                    weeklyVolumeSection

                    // Progression Suggestions
                    if viewModel.hasSuggestions {
                        progressionSuggestionsSection
                    }

                    // Streak indicator
                    if viewModel.currentStreak > 0 {
                        streakSection
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Strength Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.forceRefresh()
        }
        .task {
            await viewModel.loadDashboardData()
        }
        .sheetWithHaptic(isPresented: $showAllPRs) {
            AllPRsSheet(prs: viewModel.recentPRs)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strength Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusDeepTeal)

                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Streak badge
                if viewModel.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.currentStreak)")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(CornerRadius.md)
                }
            }

            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(StrengthTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading strength data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load data")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                HapticFeedback.light()
                Task { await viewModel.retryLoad() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xl)
        }
        .padding()
    }

    // MARK: - SBD Total Card

    private var sbdTotalCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Powerlifting Total")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            HStack(spacing: Spacing.lg) {
                // Total
                VStack(spacing: 4) {
                    Text("Est. Total")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.formattedSBDTotal)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }

                Spacer()

                // Individual lifts summary
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(viewModel.coreLifts.prefix(3)) { lift in
                        HStack(spacing: Spacing.xs) {
                            Text(shortLiftName(lift.exerciseName))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(lift.formattedEstimated1rm)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .monospacedDigit()
                        }
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
    }

    // MARK: - Big Lifts Section

    private var bigLiftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.orange)
                Text("Big Lifts")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text("\(viewModel.bigLifts.count) lifts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.bigLifts.isEmpty {
                emptyBigLiftsCard
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ], spacing: Spacing.sm) {
                    ForEach(viewModel.bigLifts.prefix(6)) { lift in
                        bigLiftCard(lift)
                    }
                }
            }
        }
    }

    private var emptyBigLiftsCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "dumbbell.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No big lifts tracked yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

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

    private func bigLiftCard(_ lift: BigLiftSummary) -> some View {
        Button(action: {
            HapticFeedback.light()
            showExerciseDetail = lift.exerciseName
        }) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(shortLiftName(lift.exerciseName))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Spacer()

                    if lift.hasRecentPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Spacer()

                Text(lift.formattedMaxWeight)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .monospacedDigit()

                HStack(spacing: 4) {
                    Text("Est 1RM:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(lift.formattedEstimated1rm)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }

                if let improvement = lift.formattedImprovement {
                    HStack(spacing: 2) {
                        Image(systemName: lift.isImproving ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(improvement)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(lift.isImproving ? .green : .red)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Recent PRs Section

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Recent PRs")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Button("See All") {
                    HapticFeedback.light()
                    showAllPRs = true
                }
                .font(.caption)
                .foregroundColor(.modusCyan)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.recentPRs.prefix(5)) { pr in
                        prCard(pr)
                    }
                }
            }
        }
    }

    private func prCard(_ pr: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(shortLiftName(pr.exerciseName))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.0f", pr.value))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()

            if let prev = pr.previousRecord {
                let improvement = pr.value - prev
                Text(String(format: "+%.0f", improvement))
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Text(pr.achievedDate.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.sm)
        .frame(width: 100)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Weekly Volume Section

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.modusCyan)
                Text("Weekly Volume")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            HStack(spacing: Spacing.lg) {
                VStack(spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.weeklyVolume.formattedTotal)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.weeklyVolume.sessionCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Avg/Session")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.weeklyVolume.formattedAverage)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Progression Suggestions Section

    private var progressionSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Suggestions")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            ForEach(viewModel.progressionSuggestions.prefix(3)) { suggestion in
                suggestionCard(suggestion)
            }
        }
    }

    private func suggestionCard(_ suggestion: ProgressionSuggestion) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.subheadline)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Next Session")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(String(format: "Try %.0f lbs x %d reps", suggestion.nextLoad, suggestion.nextReps))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "%.0f%% confidence", suggestion.confidence))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.sm)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.currentStreak) Day Streak")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(viewModel.isStreakAtRisk ? "Log activity to maintain!" : "Keep up the great work!")
                    .font(.caption)
                    .foregroundColor(viewModel.isStreakAtRisk ? .orange : .secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.red.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Helpers

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

// MARK: - Time Range Enum

private enum StrengthTimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3 Months"
        }
    }
}

// MARK: - All PRs Sheet

private struct AllPRsSheet: View {
    let prs: [PersonalRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(prs) { pr in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pr.exerciseName)
                            .font(.headline)

                        Text(pr.achievedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.0f lbs", pr.value))
                            .font(.headline)
                            .fontWeight(.bold)

                        if let prev = pr.previousRecord {
                            Text(String(format: "+%.0f", pr.value - prev))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .navigationTitle("All Personal Records")
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
struct StrengthModeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StrengthModeDashboardView(patientId: UUID())
                .environmentObject(AppState())
        }
    }
}
#endif
