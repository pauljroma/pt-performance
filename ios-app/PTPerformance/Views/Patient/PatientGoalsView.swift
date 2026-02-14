//
//  PatientGoalsView.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//

import SwiftUI

/// Main view for displaying and managing patient goals
struct PatientGoalsView: View {
    @StateObject private var viewModel = PatientGoalsViewModel()
    @State private var selectedFilter: GoalFilter = .active
    @State private var showingAddGoalSheet = false

    /// Filter options for the segmented picker
    enum GoalFilter: String, CaseIterable, Identifiable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"

        var id: String { rawValue }
    }

    /// Filtered goals based on the selected segment
    private var filteredGoals: [PatientGoal] {
        switch selectedFilter {
        case .active:
            return viewModel.goals.filter { $0.status == .active || $0.status == .paused }
        case .completed:
            return viewModel.goals.filter { $0.status == .completed }
        case .all:
            return viewModel.goals
        }
    }

    /// Resolved patient UUID from PTSupabaseClient.shared.userId
    private var patientUUID: UUID? {
        guard let idString = PTSupabaseClient.shared.userId else { return nil }
        return UUID(uuidString: idString)
    }

    /// Icon for filtered empty state
    private var filterEmptyStateIcon: String {
        switch selectedFilter {
        case .active:
            return "flame"
        case .completed:
            return "checkmark.seal"
        case .all:
            return "target"
        }
    }

    /// Message for filtered empty state
    private var filterEmptyStateMessage: String {
        switch selectedFilter {
        case .active:
            return "You have no active goals right now. Create a new goal or check your completed goals."
        case .completed:
            return "No goals completed yet. Keep working toward your active goals to see them here."
        case .all:
            return "Tap the + button to create your first goal."
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.goals.isEmpty {
                loadingView
            } else if let error = viewModel.error, viewModel.goals.isEmpty {
                errorStateView(error: error)
            } else if viewModel.goals.isEmpty {
                emptyStateView
            } else {
                goalsListView
            }
        }
        .navigationTitle("My Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddGoalSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddGoalSheet) {
            AddGoalSheet(viewModel: viewModel)
        }
        .alert("Goal Saved", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your goal has been created successfully.")
        }
        .task {
            guard let uuid = patientUUID else { return }
            await viewModel.loadGoals(patientId: uuid)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        GoalsLoadingView()
    }

    // MARK: - Error State View

    private func errorStateView(error: AppError) -> some View {
        ErrorStateView.genericError(
            message: error.recoverySuggestion ?? "Failed to load goals. Please try again.",
            retry: {
                Task { await viewModel.retryLoadGoals() }
            }
        )
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Goals Yet",
            message: "Set your first goal to start tracking your progress toward recovery and performance milestones. Goals help you stay motivated and measure your improvement.",
            icon: "target",
            iconColor: .modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "Add Your First Goal",
                icon: "plus.circle.fill",
                action: { showingAddGoalSheet = true }
            )
        )
        .refreshable {
            HapticFeedback.light()
            guard let uuid = patientUUID else { return }
            await viewModel.loadGoals(patientId: uuid)
        }
    }

    // MARK: - Goals List View

    private var goalsListView: some View {
        List {
            // Summary Card Section
            Section {
                summaryCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Filter Picker
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(GoalFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            // Error Message with Retry
            if let error = viewModel.error {
                Section {
                    CompactErrorView(
                        message: error.recoverySuggestion ?? "An error occurred.",
                        retry: error.shouldRetry ? {
                            Task { await viewModel.retryLoadGoals() }
                        } : nil
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Goals
            Section {
                if filteredGoals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: filterEmptyStateIcon)
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("No \(selectedFilter.rawValue) Goals")
                            .font(.headline)

                        Text(filterEmptyStateMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
                } else {
                    ForEach(filteredGoals) { goal in
                        NavigationLink {
                            GoalProgressView(goal: goal, viewModel: viewModel)
                        } label: {
                            GoalRowView(goal: goal)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HapticFeedback.medium()
                                Task {
                                    await viewModel.deleteGoal(goalId: goal.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                HapticFeedback.light()
                                // Navigate to detail/edit view
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.modusCyan)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if goal.status == .active {
                                Button {
                                    HapticFeedback.success()
                                    Task {
                                        await viewModel.updateStatus(goalId: goal.id, status: .completed)
                                    }
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                        }
                        .contextMenu {
                            Button {
                                // View progress details
                            } label: {
                                Label("View Progress", systemImage: "chart.line.uptrend.xyaxis")
                            }

                            if goal.status == .active {
                                Button {
                                    Task {
                                        await viewModel.updateStatus(goalId: goal.id, status: .completed)
                                    }
                                } label: {
                                    Label("Mark Complete", systemImage: "checkmark.circle.fill")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteGoal(goalId: goal.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("\(filteredGoals.count) \(selectedFilter.rawValue) Goal\(filteredGoals.count == 1 ? "" : "s")")
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            HapticFeedback.light()
            guard let uuid = patientUUID else { return }
            await viewModel.loadGoals(patientId: uuid)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                // Enhanced Progress Ring with milestones
                GoalProgressRing(
                    progress: viewModel.overallProgress,
                    category: .custom, // Use custom for overall progress
                    size: 90,
                    lineWidth: 10,
                    showMilestones: true,
                    showPercentage: true,
                    animated: true
                )

                // Stats
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(viewModel.completedGoals.count) of \(viewModel.goals.count) achieved")
                        .font(.headline)

                    HStack(spacing: Spacing.md) {
                        Label("\(viewModel.activeGoals.count) active", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Label("\(viewModel.completedGoals.count) done", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    // Overall milestone indicator
                    if let milestone = GoalMilestone.highestAchieved(for: viewModel.overallProgress) {
                        HStack(spacing: 4) {
                            Image(systemName: milestone.icon)
                                .font(.caption)
                            Text("Reached \(milestone.displayText)")
                                .font(.caption)
                        }
                        .foregroundColor(milestone.color)
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding()

            // Quick milestone summary
            if !viewModel.activeGoals.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(GoalMilestone.allCases) { milestone in
                        VStack(spacing: 2) {
                            Image(systemName: milestone.icon)
                                .font(.caption2)
                                .foregroundColor(viewModel.overallProgress >= milestone.fraction ? milestone.color : .gray.opacity(0.4))

                            Text(milestone.displayText)
                                .font(.system(size: 9))
                                .foregroundColor(viewModel.overallProgress >= milestone.fraction ? milestone.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.systemBackground))
                .adaptiveShadow(Shadow.medium)
        )
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Goal Row View

/// A single goal row in the list with enhanced visual progress indicators
struct GoalRowView: View {
    let goal: PatientGoal

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Progress Ring (replaces static category icon)
            GoalProgressRing(
                progress: goal.progress,
                category: goal.category,
                size: 56,
                lineWidth: 5,
                showMilestones: false,
                showPercentage: true,
                animated: false
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                if let description = goal.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Enhanced Progress Bar with milestone markers
                if goal.targetValue != nil {
                    GoalRowProgressBar(progress: goal.progress)
                }

                HStack(spacing: Spacing.xs) {
                    // Category badge
                    GoalCategoryBadge(category: goal.category)

                    // Target date badge
                    if let days = goal.daysRemaining {
                        DeadlineBadge(days: days)
                    }

                    Spacer()

                    // Completion indicator
                    if goal.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// Enhanced progress bar with milestone markers for goal rows
struct GoalRowProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(progressGradient)
                    .frame(width: geometry.size.width * min(progress, 1.0), height: 4)

                // Milestone markers
                ForEach(GoalMilestone.allCases) { milestone in
                    Circle()
                        .fill(progress >= milestone.fraction ? milestone.color : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .position(
                            x: geometry.size.width * milestone.fraction,
                            y: 2
                        )
                }
            }
        }
        .frame(height: 6)
    }

    private var progressGradient: LinearGradient {
        let color = progressColor(for: progress)
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func progressColor(for value: Double) -> Color {
        if value >= 1.0 { return .green }
        if value >= 0.75 { return .blue }
        if value >= 0.5 { return .cyan }
        return .orange
    }
}

// MARK: - Preview

struct PatientGoalsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientGoalsView()
    }
}
