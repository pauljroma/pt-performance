//
//  AthleteTaskListView.swift
//  PTPerformance
//
//  Main view showing athlete's assigned tasks from their active plan.
//  Athletes can view and complete their assigned tasks organized by due date.
//

import SwiftUI

struct AthleteTaskListView: View {
    @StateObject private var viewModel = AthleteTaskListViewModel()
    @State private var selectedTask: AssignedTask?
    @State private var showingCompletionSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Loading state
                if viewModel.isLoading {
                    ProgressView("Loading tasks...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxl)
                }

                // Error state
                if let error = viewModel.error {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Unable to Load Tasks")
                            .font(.headline)

                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            Task { await viewModel.loadTasks() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
                    .padding(.horizontal, Spacing.lg)
                }

                // Today's Tasks Section
                if !viewModel.todayTasks.isEmpty {
                    TaskSection(
                        title: "Today",
                        tasks: viewModel.todayTasks,
                        onTaskTap: { task in
                            selectedTask = task
                            showingCompletionSheet = true
                        },
                        onComplete: { task in
                            Task { await viewModel.completeTask(task) }
                        }
                    )
                }

                // Upcoming Tasks Section
                if !viewModel.upcomingTasks.isEmpty {
                    TaskSection(
                        title: "Upcoming",
                        tasks: viewModel.upcomingTasks,
                        onTaskTap: { task in
                            selectedTask = task
                        },
                        onComplete: nil // Can't complete future tasks
                    )
                }

                // Overdue Tasks Section (if any)
                if !viewModel.overdueTasks.isEmpty {
                    TaskSection(
                        title: "Overdue",
                        tasks: viewModel.overdueTasks,
                        isOverdue: true,
                        onTaskTap: { task in
                            selectedTask = task
                            showingCompletionSheet = true
                        },
                        onComplete: { task in
                            Task { await viewModel.completeTask(task) }
                        }
                    )
                }

                // Completed Tasks (collapsed)
                if !viewModel.completedTasks.isEmpty {
                    DisclosureGroup("Completed (\(viewModel.completedTasks.count))") {
                        ForEach(viewModel.completedTasks) { task in
                            CompletedTaskRow(task: task)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }

                // Empty state
                if viewModel.allTasks.isEmpty && !viewModel.isLoading {
                    EmptyTasksView()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Tasks")
        .refreshable {
            await viewModel.loadTasks()
        }
        .task {
            await viewModel.loadTasks()
        }
        .sheet(isPresented: $showingCompletionSheet) {
            if let task = selectedTask {
                AthleteTaskCompletionSheet(
                    task: task,
                    onComplete: { notes in
                        Task {
                            await viewModel.completeTask(task, notes: notes)
                            showingCompletionSheet = false
                        }
                    },
                    onSkip: {
                        Task {
                            await viewModel.skipTask(task)
                            showingCompletionSheet = false
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Empty Tasks View

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your assigned tasks will appear here once your PT creates a plan for you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: AssignedTask

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .strikethrough()

                if let completedAt = task.completedAt {
                    Text("Completed \(completedAt, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AthleteTaskListView()
    }
}
