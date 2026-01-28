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

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.goals.isEmpty {
                loadingView
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
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading goals...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Goals Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Set your first goal to start tracking your progress toward recovery and performance milestones.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddGoalSheet = true
            } label: {
                Label("Add Your First Goal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
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

            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }

            // Goals
            Section {
                if filteredGoals.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("No \(selectedFilter.rawValue.lowercased()) goals")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(filteredGoals) { goal in
                        NavigationLink {
                            GoalDetailView(goal: goal, viewModel: viewModel)
                        } label: {
                            GoalRowView(goal: goal)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteGoal(goalId: goal.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if goal.status == .active {
                                Button {
                                    Task {
                                        await viewModel.updateStatus(goalId: goal.id, status: .completed)
                                    }
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
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
            guard let uuid = patientUUID else { return }
            await viewModel.loadGoals(patientId: uuid)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Circular Progress Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: viewModel.overallProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.blue, .green, .blue]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: viewModel.overallProgress)

                    // Percentage text
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                }

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.completedGoals.count) of \(viewModel.goals.count) achieved")
                        .font(.headline)

                    HStack(spacing: 16) {
                        Label("\(viewModel.activeGoals.count) active", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Label("\(viewModel.completedGoals.count) done", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Goal Row View

/// A single goal row in the list
struct GoalRowView: View {
    let goal: PatientGoal

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: goal.category.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(goal.category.color)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                if let description = goal.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Progress Bar
                if goal.targetValue != nil {
                    ProgressView(value: goal.progress)
                        .tint(progressColor(for: goal.progress))
                }

                HStack(spacing: 8) {
                    // Target date
                    if let days = goal.daysRemaining {
                        Label(
                            days >= 0 ? "\(days)d left" : "\(abs(days))d overdue",
                            systemImage: "calendar"
                        )
                        .font(.caption2)
                        .foregroundColor(days >= 0 ? .secondary : .red)
                    }

                    Spacer()

                    // Category badge
                    Text(goal.category.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(goal.category.color.opacity(0.15))
                        .foregroundColor(goal.category.color)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func progressColor(for value: Double) -> Color {
        if value >= 1.0 { return .green }
        if value >= 0.5 { return .blue }
        return .orange
    }
}

// MARK: - Preview

struct PatientGoalsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientGoalsView()
    }
}
