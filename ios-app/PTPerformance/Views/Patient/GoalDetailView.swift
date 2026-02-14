//
//  GoalDetailView.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//  Enhanced with Goal Progress Visualization components
//

import SwiftUI
import Charts

/// Detail view for a single patient goal with progress tracking and status management
struct GoalDetailView: View {
    let goal: PatientGoal
    @ObservedObject var viewModel: PatientGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var progressSliderValue: Double = 0
    @State private var showingDeleteConfirmation = false
    @State private var showCelebration = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // MARK: - Progress Ring (Enhanced)
                progressRingSection

                // MARK: - Goal Info
                goalInfoSection

                // MARK: - Milestone Progress
                MilestoneProgressView(progress: goal.progress, category: goal.category)
                    .padding(.horizontal, Spacing.md)

                // MARK: - Stats
                statsSection

                // MARK: - Progress Chart
                if goal.targetValue != nil {
                    GoalProgressMiniChart(goal: goal, height: 140)
                        .padding(.horizontal, Spacing.md)
                }

                // MARK: - Deadline Countdown
                DeadlineCountdownView(targetDate: goal.targetDate, isCompleted: goal.isCompleted)
                    .padding(.horizontal, Spacing.md)

                // MARK: - Update Progress
                if goal.targetValue != nil && goal.status == .active {
                    updateProgressSection
                }

                // MARK: - Actions
                actionsSection

                // MARK: - Delete
                deleteSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    GoalProgressView(goal: goal, viewModel: viewModel)
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
            }
        }
        .onAppear {
            progressSliderValue = goal.currentValue ?? 0
            // Trigger celebration if goal is already complete
            if goal.progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCelebration = true
                }
            }
        }
        .alert("Delete Goal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteGoal(goalId: goal.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
    }

    // MARK: - Progress Ring Section (Enhanced with GoalProgressRing)

    private var progressRingSection: some View {
        VStack(spacing: Spacing.sm) {
            GoalProgressRing(
                progress: goal.progress,
                category: goal.category,
                size: 160,
                lineWidth: 14,
                showMilestones: true,
                showPercentage: true,
                animated: true
            )

            // Current milestone badge
            if let milestone = GoalMilestone.highestAchieved(for: goal.progress) {
                HStack(spacing: 4) {
                    Image(systemName: milestone.icon)
                        .font(.caption)
                    Text("Reached \(milestone.displayText) milestone!")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(milestone.color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(milestone.color.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.top, Spacing.xs)
    }

    private var progressGradient: AngularGradient {
        let color = progressColor(for: goal.progress)
        return AngularGradient(
            gradient: Gradient(colors: [color.opacity(0.6), color]),
            center: .center
        )
    }

    // MARK: - Goal Info Section

    private var goalInfoSection: some View {
        VStack(spacing: 12) {
            // Title
            Text(goal.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            if let description = goal.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Category Badge
            HStack(spacing: 6) {
                Image(systemName: goal.category.icon)
                    .font(.caption)
                Text(goal.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(goal.category.color.opacity(0.15))
            .foregroundColor(goal.category.color)
            .clipShape(Capsule())

            // Status badge if not active
            if goal.status != .active {
                Text(goal.status.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, Spacing.xxs)
                    .background(statusColor(for: goal.status).opacity(0.15))
                    .foregroundColor(statusColor(for: goal.status))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatBox(
                    title: "Target",
                    value: formatStatValue(goal.targetValue, unit: goal.unit),
                    icon: "target",
                    color: .green
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    title: "Current",
                    value: formatStatValue(goal.currentValue, unit: goal.unit),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }

            Divider()

            HStack(spacing: 0) {
                StatBox(
                    title: "Remaining",
                    value: formatRemaining(),
                    icon: "arrow.up.right",
                    color: .orange
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    title: "Days Left",
                    value: daysRemainingText,
                    icon: "calendar",
                    color: daysRemainingColor
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    private func formatRemaining() -> String {
        guard let target = goal.targetValue else { return "--" }
        let current = goal.currentValue ?? 0
        let remaining = max(0, target - current)
        let formatted = remaining == remaining.rounded() ? String(format: "%.0f", remaining) : String(format: "%.1f", remaining)
        if let unit = goal.unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }

    private var daysRemainingColor: Color {
        guard let days = goal.daysRemaining else { return .secondary }
        if days < 0 { return .red }
        if days <= 7 { return .orange }
        return .blue
    }

    private var daysRemainingText: String {
        guard let days = goal.daysRemaining else { return "No date" }
        if days < 0 { return "\(abs(days))d overdue" }
        if days == 0 { return "Today" }
        return "\(days)d"
    }

    private func formatStatValue(_ value: Double?, unit: String?) -> String {
        guard let value = value else { return "--" }
        let formatted: String
        if value == value.rounded() {
            formatted = String(format: "%.0f", value)
        } else {
            formatted = String(format: "%.1f", value)
        }
        if let unit = unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }

    // MARK: - Update Progress Section

    private var updateProgressSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Update Progress")
                    .font(.headline)
                Spacer()

                // Quick progress preview
                Text("\(Int((progressSliderValue / (goal.targetValue ?? 1)) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor(for: progressSliderValue / (goal.targetValue ?? 1)))
            }

            if let target = goal.targetValue {
                // Progress slider with visual feedback
                VStack(spacing: Spacing.xs) {
                    HStack {
                        Text(String(format: "%.0f", progressSliderValue))
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .frame(width: 60, alignment: .leading)

                        Slider(
                            value: $progressSliderValue,
                            in: 0...max(target, 1),
                            step: sliderStep(for: target)
                        )
                        .tint(progressColor(for: progressSliderValue / target))

                        if let unit = goal.unit {
                            Text(unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Mini milestone markers under slider
                    HStack {
                        ForEach(GoalMilestone.allCases) { milestone in
                            let milestoneValue = target * milestone.fraction
                            Spacer()
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(progressSliderValue >= milestoneValue ? milestone.color : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(milestone.displayText)
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            if milestone != .complete {
                                Spacer()
                            }
                        }
                    }
                }

                Button {
                    Task {
                        let previousProgress = goal.progress
                        await viewModel.updateProgress(goalId: goal.id, newValue: progressSliderValue)

                        // Trigger celebration if just reached 100%
                        if progressSliderValue >= target && previousProgress < 1.0 {
                            showCelebration = true
                            HapticFeedback.success()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                        }
                        Text("Save Progress")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSaving)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    private func sliderStep(for target: Double) -> Double {
        if target <= 10 { return 0.5 }
        if target <= 100 { return 1 }
        return 5
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Actions")
                    .font(.headline)
                Spacer()
            }

            if goal.status == .active {
                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .completed)
                        HapticFeedback.success()
                        showCelebration = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                } label: {
                    Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .paused)
                        dismiss()
                    }
                } label: {
                    Label("Pause Goal", systemImage: "pause.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.bordered)
            }

            if goal.status == .paused {
                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .active)
                        dismiss()
                    }
                } label: {
                    Label("Resume Goal", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.modusCyan)
            }

            if goal.status == .completed {
                // Celebration message
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "party.popper.fill")
                        .foregroundColor(.green)
                    Text("Goal achieved! Great work!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, Spacing.xs)

                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .active)
                        dismiss()
                    }
                } label: {
                    Label("Reopen Goal", systemImage: "arrow.uturn.backward.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.bordered)
            }

            // Error message
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Button(role: .destructive) {
            HapticFeedback.warning()
            showingDeleteConfirmation = true
        } label: {
            Label("Delete Goal", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Helpers

    private func progressColor(for value: Double) -> Color {
        if value >= 1.0 { return .green }
        if value >= 0.5 { return .blue }
        return .orange
    }

    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GoalDetailView_Previews: PreviewProvider {
    static let activeGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "Bench Press 225 lbs",
        description: "Work up to a 225 lb bench press for a clean single rep.",
        category: .strength,
        targetValue: 225,
        currentValue: 185,
        unit: "lbs",
        targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
        status: .active,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let completedGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "5K Under 25 Minutes",
        description: "Improve cardio endurance to run 5K in under 25 minutes.",
        category: .endurance,
        targetValue: 25,
        currentValue: 25,
        unit: "min",
        targetDate: Date(),
        status: .completed,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let painReductionGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "Reduce Lower Back Pain",
        description: "Decrease pain level from 7 to 2 on the pain scale.",
        category: .painReduction,
        targetValue: 2,
        currentValue: 4,
        unit: "pain scale",
        targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 6, to: Date()),
        status: .active,
        createdAt: Date(),
        updatedAt: Date()
    )

    static var previews: some View {
        Group {
            NavigationStack {
                GoalDetailView(
                    goal: activeGoal,
                    viewModel: PatientGoalsViewModel()
                )
            }
            .previewDisplayName("Active Goal")

            NavigationStack {
                GoalDetailView(
                    goal: completedGoal,
                    viewModel: PatientGoalsViewModel()
                )
            }
            .previewDisplayName("Completed Goal")

            NavigationStack {
                GoalDetailView(
                    goal: painReductionGoal,
                    viewModel: PatientGoalsViewModel()
                )
            }
            .previewDisplayName("Pain Reduction Goal")
        }
    }
}
#endif
