//
//  AthletePlanView.swift
//  PTPerformance
//
//  Shows current active plan for an athlete with task list,
//  completion status, progress visualization, and edit/pause/complete actions
//

import SwiftUI

struct AthletePlanView: View {
    let athleteId: UUID
    let athleteName: String

    @StateObject private var viewModel: AthletePlanViewModel
    @State private var showingEditSheet = false
    @State private var showingActionSheet = false
    @State private var selectedTask: AssignedTask?

    init(athleteId: UUID, athleteName: String) {
        self.athleteId = athleteId
        self.athleteName = athleteName
        _viewModel = StateObject(wrappedValue: AthletePlanViewModel(athleteId: athleteId))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let plan = viewModel.activePlan {
                VStack(spacing: 20) {
                    // Progress header
                    progressHeaderView(plan: plan)

                    // Quick stats
                    quickStatsView(plan: plan)

                    // Today's tasks
                    if !plan.todaysTasks.isEmpty {
                        todaysTasksSection(tasks: plan.todaysTasks, plan: plan)
                    }

                    // All tasks by date
                    allTasksSection(plan: plan)

                    // Plan notes
                    if let notes = plan.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                }
                .padding()
            } else {
                noPlanView
            }
        }
        .navigationTitle("\(athleteName)'s Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.activePlan != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Plan", systemImage: "pencil")
                        }

                        Button {
                            Task { await viewModel.pausePlan() }
                        } label: {
                            Label(
                                viewModel.activePlan?.status == .paused ? "Resume Plan" : "Pause Plan",
                                systemImage: viewModel.activePlan?.status == .paused ? "play.fill" : "pause.fill"
                            )
                        }

                        Button {
                            Task { await viewModel.completePlan() }
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            Task { await viewModel.cancelPlan() }
                        } label: {
                            Label("Cancel Plan", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let plan = viewModel.activePlan {
                PlanEditSheet(plan: plan, onSave: { updatedPlan in
                    Task { await viewModel.updatePlan(updatedPlan) }
                })
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskCompletionSheet(task: task) { status, notes in
                Task { await viewModel.updateTaskStatus(task.id, status: status, notes: notes) }
            }
        }
        .refreshable {
            await viewModel.loadActivePlan()
        }
        .task {
            await viewModel.loadActivePlan()
        }
    }

    // MARK: - Progress Header

    private func progressHeaderView(plan: AthletePlan) -> some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: plan.progress)
                    .stroke(
                        progressColor(for: plan.progress),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: plan.progress)

                VStack(spacing: 4) {
                    Text("\(plan.progressPercentage)%")
                        .font(.system(size: 32, weight: .bold))

                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: plan.status.iconName)
                Text(plan.status.displayName)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor(for: plan.status).opacity(0.15))
            .foregroundColor(statusColor(for: plan.status))
            .cornerRadius(20)

            // Date range
            HStack {
                VStack(alignment: .leading) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plan.startDate, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plan.endDate, style: .date)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Quick Stats

    private func quickStatsView(plan: AthletePlan) -> some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Completed",
                value: "\(plan.completedTasks)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                title: "Pending",
                value: "\(plan.pendingTasks)",
                icon: "clock",
                color: .blue
            )

            StatCard(
                title: "Overdue",
                value: "\(plan.overdueTasks)",
                icon: "exclamationmark.circle",
                color: plan.overdueTasks > 0 ? .red : .gray
            )

            StatCard(
                title: "Days Left",
                value: "\(plan.daysRemaining)",
                icon: "calendar",
                color: .purple
            )
        }
    }

    // MARK: - Today's Tasks Section

    private func todaysTasksSection(tasks: [AssignedTask], plan: AthletePlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's Tasks", systemImage: "sun.max.fill")
                    .font(.headline)

                Spacer()

                Text("\(tasks.filter { $0.status == .completed }.count)/\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(tasks) { task in
                TaskRowView(task: task) {
                    selectedTask = task
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - All Tasks Section

    private func allTasksSection(plan: AthletePlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("All Tasks", systemImage: "list.bullet")
                .font(.headline)

            // Group tasks by date
            let groupedTasks = Dictionary(grouping: plan.tasks) { task in
                Calendar.current.startOfDay(for: task.dueDate)
            }

            let sortedDates = groupedTasks.keys.sorted()

            ForEach(sortedDates, id: \.self) { date in
                if let tasks = groupedTasks[date] {
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        HStack {
                            Text(dateHeaderText(for: date))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(tasks.filter { $0.status == .completed }.count)/\(tasks.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                        ForEach(tasks) { task in
                            TaskRowView(task: task) {
                                selectedTask = task
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }

    // MARK: - No Plan View

    private var noPlanView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Active Plan")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(athleteName) doesn't have an active protocol plan.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                ProtocolBuilderView(athleteId: athleteId, athleteName: athleteName)
            } label: {
                Label("Assign Protocol", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Helpers

    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.25: return .red
        case 0.25..<0.50: return .orange
        case 0.50..<0.75: return .yellow
        default: return .green
        }
    }

    private func statusColor(for status: AthletePlan.PlanStatus) -> Color {
        switch status.color {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .gray
        }
    }

    private func dateHeaderText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: AssignedTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status icon
                Image(systemName: task.status.iconName)
                    .font(.title2)
                    .foregroundColor(statusColor)

                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .strikethrough(task.status == .completed)

                    HStack(spacing: 8) {
                        Label(task.taskType.displayName, systemImage: task.taskType.iconName)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let time = task.formattedDueTime {
                            Text("|")
                                .foregroundColor(.secondary)
                            Text(time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch task.status.color {
        case "gray": return .gray
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Task Completion Sheet

struct TaskCompletionSheet: View {
    let task: AssignedTask
    let onComplete: (AssignedTask.TaskStatus, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""
    @State private var selectedStatus: AssignedTask.TaskStatus

    init(task: AssignedTask, onComplete: @escaping (AssignedTask.TaskStatus, String?) -> Void) {
        self.task = task
        self.onComplete = onComplete
        _selectedStatus = State(initialValue: task.status)
        _notes = State(initialValue: task.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Task info
                Section {
                    HStack {
                        Image(systemName: task.taskType.iconName)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.taskType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    LabeledContent("Due Date", value: task.dueDate, format: .dateTime.month().day())

                    if let time = task.formattedDueTime {
                        LabeledContent("Due Time", value: time)
                    }
                }

                // Status selection
                Section("Status") {
                    ForEach(AssignedTask.TaskStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            HStack {
                                Image(systemName: status.iconName)
                                    .foregroundColor(statusColor(for: status))
                                Text(status.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Update Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onComplete(selectedStatus, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func statusColor(for status: AssignedTask.TaskStatus) -> Color {
        switch status.color {
        case "gray": return .gray
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Plan Edit Sheet

struct PlanEditSheet: View {
    let plan: AthletePlan
    let onSave: (AthletePlan) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var endDate: Date
    @State private var notes: String

    init(plan: AthletePlan, onSave: @escaping (AthletePlan) -> Void) {
        self.plan = plan
        self.onSave = onSave
        _endDate = State(initialValue: plan.endDate)
        _notes = State(initialValue: plan.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Duration") {
                    LabeledContent("Start Date", value: plan.startDate, format: .dateTime.month().day().year())

                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: plan.startDate...,
                        displayedComponents: .date
                    )
                }

                Section("Notes") {
                    TextField("Notes for athlete...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedPlan = plan
                        // Note: In a real implementation, you'd create a new AthletePlan
                        // with updated values since the struct has let properties
                        onSave(updatedPlan)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Athlete Plan ViewModel

@MainActor
class AthletePlanViewModel: ObservableObject {
    let athleteId: UUID

    @Published var activePlan: AthletePlan?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let protocolService = ProtocolService.shared

    init(athleteId: UUID) {
        self.athleteId = athleteId
    }

    func loadActivePlan() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activePlan = try await protocolService.getActivePlan(athleteId: athleteId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTaskStatus(_ taskId: UUID, status: AssignedTask.TaskStatus, notes: String?) async {
        do {
            try await protocolService.updateTask(taskId: taskId, status: status, notes: notes)
            await loadActivePlan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pausePlan() async {
        guard var plan = activePlan else { return }

        do {
            let newStatus: AthletePlan.PlanStatus = plan.status == .paused ? .active : .paused
            try await protocolService.updatePlanStatus(planId: plan.id, status: newStatus)
            await loadActivePlan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completePlan() async {
        guard let plan = activePlan else { return }

        do {
            try await protocolService.updatePlanStatus(planId: plan.id, status: .completed)
            await loadActivePlan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelPlan() async {
        guard let plan = activePlan else { return }

        do {
            try await protocolService.updatePlanStatus(planId: plan.id, status: .cancelled)
            await loadActivePlan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePlan(_ plan: AthletePlan) async {
        // In a real implementation, this would update the plan via the service
        await loadActivePlan()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AthletePlanView(
            athleteId: UUID(),
            athleteName: "John Smith"
        )
    }
}
