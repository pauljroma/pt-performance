//
//  GoalDetailView.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//

import SwiftUI

/// Detail view for a single patient goal with progress tracking and status management
struct GoalDetailView: View {
    let goal: PatientGoal
    @ObservedObject var viewModel: PatientGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var progressSliderValue: Double = 0
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Progress Ring
                progressRingSection

                // MARK: - Goal Info
                goalInfoSection

                // MARK: - Stats
                statsSection

                // MARK: - Update Progress
                if goal.targetValue != nil && goal.status == .active {
                    updateProgressSection
                }

                // MARK: - Actions
                actionsSection

                // MARK: - Delete
                deleteSection
            }
            .padding()
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            progressSliderValue = goal.currentValue ?? 0
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

    // MARK: - Progress Ring Section

    private var progressRingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: goal.progress)

                // Percentage
                VStack(spacing: 2) {
                    Text(goal.progressPercentageText)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)

                    Text("progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
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
            .padding(.horizontal, 12)
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
                    .padding(.vertical, 4)
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
                statItem(
                    title: "Target",
                    value: formatStatValue(goal.targetValue, unit: goal.unit),
                    icon: "target"
                )

                Divider()
                    .frame(height: 50)

                statItem(
                    title: "Current",
                    value: formatStatValue(goal.currentValue, unit: goal.unit),
                    icon: "chart.line.uptrend.xyaxis"
                )
            }

            Divider()

            HStack(spacing: 0) {
                statItem(
                    title: "Progress",
                    value: goal.progressPercentageText,
                    icon: "percent"
                )

                Divider()
                    .frame(height: 50)

                statItem(
                    title: "Days Left",
                    value: daysRemainingText,
                    icon: "calendar"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
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
        VStack(spacing: 12) {
            HStack {
                Text("Update Progress")
                    .font(.headline)
                Spacer()
            }

            if let target = goal.targetValue {
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

                Button {
                    Task {
                        await viewModel.updateProgress(goalId: goal.id, newValue: progressSliderValue)
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
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSaving)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func sliderStep(for target: Double) -> Double {
        if target <= 10 { return 0.5 }
        if target <= 100 { return 1 }
        return 5
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Actions")
                    .font(.headline)
                Spacer()
            }

            if goal.status == .active {
                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .completed)
                        dismiss()
                    }
                } label: {
                    Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
                        .padding(.vertical, 12)
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
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            if goal.status == .completed {
                Button {
                    Task {
                        await viewModel.updateStatus(goalId: goal.id, status: .active)
                        dismiss()
                    }
                } label: {
                    Label("Reopen Goal", systemImage: "arrow.uturn.backward.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }

            // Error message (BUILD 314: Updated to use AppError)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label("Delete Goal", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .padding(.bottom, 16)
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

struct GoalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GoalDetailView(
                goal: PatientGoal(
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
                ),
                viewModel: PatientGoalsViewModel()
            )
        }
    }
}
