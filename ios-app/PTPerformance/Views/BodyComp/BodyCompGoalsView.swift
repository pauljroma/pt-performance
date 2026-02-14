//
//  BodyCompGoalsView.swift
//  PTPerformance
//
//  Main view for body composition goals showing progress and goal management
//

import SwiftUI

/// Main goals view showing current vs target comparison cards with progress tracking
struct BodyCompGoalsView: View {
    @StateObject private var viewModel = BodyCompGoalsViewModel()
    @State private var showGoalSetting = false
    @State private var showingActionSheet = false
    @State private var showingCelebration = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.currentGoals == nil {
                loadingView
            } else if viewModel.hasActiveGoals {
                goalsContentView
            } else {
                emptyGoalsView
            }
        }
        .navigationTitle("Body Comp Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.hasActiveGoals {
                    Menu {
                        Button {
                            showGoalSetting = true
                        } label: {
                            Label("Edit Goals", systemImage: "pencil")
                        }

                        Button {
                            Task { await viewModel.pauseGoal() }
                        } label: {
                            Label("Pause Goals", systemImage: "pause.circle")
                        }

                        Button(role: .destructive) {
                            Task { await viewModel.cancelGoal() }
                        } label: {
                            Label("Cancel Goals", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                } else {
                    Button {
                        showGoalSetting = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showGoalSetting) {
            BodyCompGoalSettingSheet(viewModel: viewModel)
        }
        .alert("Goals Saved", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your body composition goals have been saved. Track your progress by logging regular measurements.")
        }
        .alert("Goal Achieved!", isPresented: $viewModel.showingGoalAchievedAlert) {
            Button("Celebrate!") {
                showingCelebration = true
                HapticFeedback.success()
            }
            Button("Set New Goals") {
                showGoalSetting = true
            }
        } message: {
            Text("Congratulations! You've reached your body composition goals. Amazing work!")
        }
        .overlay {
            if showingCelebration {
                celebrationOverlay
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            if viewModel.currentGoals == nil {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading goals...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Goals View

    private var emptyGoalsView: some View {
        EmptyStateView(
            title: "No Goals Set",
            message: "Set body composition goals to track your progress toward your target weight, body fat, or muscle mass.",
            icon: "target",
            iconColor: .modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "Set Goals",
                icon: "plus.circle.fill",
                action: { showGoalSetting = true }
            )
        )
    }

    // MARK: - Goals Content View

    private var goalsContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Status Card
                progressStatusCard

                // Goal Progress Cards
                goalProgressCards

                // Timeline Section
                timelineSection

                // Weekly Rate Section
                weeklyRateSection

                // Goal History Section
                if !viewModel.allGoals.filter({ $0.status != .active }).isEmpty {
                    goalHistorySection
                }
            }
            .padding()
        }
    }

    // MARK: - Progress Status Card

    private var progressStatusCard: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(viewModel.progressStatus.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: viewModel.progressStatus.icon)
                    .font(.title2)
                    .foregroundColor(viewModel.progressStatus.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Status")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(viewModel.progressStatus.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.progressStatus.color)

                if let days = viewModel.daysRemaining {
                    Text("\(days) days remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Goal Progress Cards

    private var goalProgressCards: some View {
        VStack(spacing: 12) {
            if let goals = viewModel.currentGoals {
                // Weight Goal Card
                if goals.targetWeight != nil {
                    BodyCompGoalProgressCard(
                        title: "Weight Goal",
                        current: viewModel.latestWeight,
                        target: goals.targetWeight,
                        starting: goals.startingWeight,
                        unit: "lbs",
                        color: .modusCyan,
                        icon: "scalemass"
                    )
                }

                // Body Fat Goal Card
                if goals.targetBodyFatPercentage != nil {
                    BodyCompGoalProgressCard(
                        title: "Body Fat Goal",
                        current: viewModel.latestBodyFat,
                        target: goals.targetBodyFatPercentage,
                        starting: goals.startingBodyFatPercentage,
                        unit: "%",
                        color: .orange,
                        icon: "percent"
                    )
                }

                // Muscle Mass Goal Card
                if goals.targetMuscleMass != nil {
                    BodyCompGoalProgressCard(
                        title: "Muscle Mass Goal",
                        current: viewModel.latestMuscleMass,
                        target: goals.targetMuscleMass,
                        starting: goals.startingMuscleMass,
                        unit: "lbs",
                        color: .green,
                        icon: "figure.strengthtraining.traditional"
                    )
                }
            }
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            HStack {
                // Start Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.currentGoals?.formattedStartDate ?? "--")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                // Progress indicator
                if let goals = viewModel.currentGoals, let targetDate = goals.targetDate {
                    let totalDays = Calendar.current.dateComponents([.day], from: goals.startedAt, to: targetDate).day ?? 1
                    let elapsedDays = Calendar.current.dateComponents([.day], from: goals.startedAt, to: Date()).day ?? 0
                    let timeProgress = min(1.0, Double(elapsedDays) / Double(max(1, totalDays)))

                    VStack(spacing: 4) {
                        Text("\(Int(timeProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Target Date
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.targetDateText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)
                }
            }

            // Timeline progress bar
            if let goals = viewModel.currentGoals, let targetDate = goals.targetDate {
                let totalDays = Calendar.current.dateComponents([.day], from: goals.startedAt, to: targetDate).day ?? 1
                let elapsedDays = Calendar.current.dateComponents([.day], from: goals.startedAt, to: Date()).day ?? 0
                let timeProgress = min(1.0, Double(elapsedDays) / Double(max(1, totalDays)))

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.modusCyan)
                            .frame(width: geometry.size.width * timeProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Weekly Rate Section

    private var weeklyRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Rates Needed")
                .font(.headline)

            VStack(spacing: 8) {
                if let weightRate = viewModel.weeklyWeightChange {
                    WeeklyRateRow(
                        title: "Weight",
                        rate: weightRate,
                        unit: "lbs/week",
                        isHealthy: abs(weightRate) <= 2.0,
                        color: .blue
                    )
                }

                if let bfRate = viewModel.weeklyBodyFatChange {
                    WeeklyRateRow(
                        title: "Body Fat",
                        rate: bfRate,
                        unit: "%/week",
                        isHealthy: abs(bfRate) <= 1.0,
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Goal History Section

    private var goalHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal History")
                .font(.headline)

            ForEach(viewModel.allGoals.filter { $0.status != .active }) { goal in
                GoalHistoryRow(goal: goal) {
                    Task {
                        await viewModel.deleteGoal(goal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingCelebration = false
                }

            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 20)

                Text("Goal Achieved!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("You've reached your body composition goals. Your dedication and hard work have paid off!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    showingCelebration = false
                    showGoalSetting = true
                } label: {
                    Text("Set New Goals")
                        .font(.headline)
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.systemBackground))
                        .cornerRadius(CornerRadius.xl)
                }
                .padding(.top)
            }
            .padding(Spacing.xl)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: showingCelebration)
    }
}

// MARK: - Supporting Views

/// Row showing weekly rate needed for a metric
private struct WeeklyRateRow: View {
    let title: String
    let rate: Double
    let unit: String
    let isHealthy: Bool
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: rate < 0 ? "arrow.down.right" : "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(isHealthy ? color : .orange)

                Text("\(abs(rate), specifier: "%.2f") \(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isHealthy ? .primary : .orange)

                if !isHealthy {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

/// Row showing a historical goal
private struct GoalHistoryRow: View {
    let goal: BodyCompGoals
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Status icon
            Image(systemName: goal.status.icon)
                .foregroundColor(goal.status.color)

            VStack(alignment: .leading, spacing: 2) {
                // Targets summary
                HStack(spacing: 8) {
                    if let weight = goal.targetWeight {
                        Text("\(weight, specifier: "%.0f") lbs")
                            .font(.caption)
                    }
                    if let bf = goal.targetBodyFatPercentage {
                        Text("\(bf, specifier: "%.0f")% BF")
                            .font(.caption)
                    }
                    if let mm = goal.targetMuscleMass {
                        Text("\(mm, specifier: "%.0f") lbs MM")
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)

                Text(goal.formattedStartDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            Text(goal.status.displayName)
                .font(.caption)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(goal.status.color.opacity(0.2))
                .foregroundColor(goal.status.color)
                .cornerRadius(CornerRadius.sm)

            // Delete button
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Preview

#if DEBUG
struct BodyCompGoalsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BodyCompGoalsView()
        }
    }
}
#endif
