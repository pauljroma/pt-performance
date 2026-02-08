//
//  AthleteTaskListViewModel.swift
//  PTPerformance
//
//  ViewModel for managing athlete's task list, including loading tasks
//  from active plan, filtering by date, and completing/skipping tasks.
//

import Foundation
import SwiftUI

@MainActor
final class AthleteTaskListViewModel: ObservableObject {
    @Published var allTasks: [AssignedTask] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var todayTasks: [AssignedTask] {
        allTasks.filter {
            Calendar.current.isDateInToday($0.dueDate) &&
            $0.status == .pending
        }
    }

    var upcomingTasks: [AssignedTask] {
        allTasks.filter {
            $0.dueDate > Date() &&
            !Calendar.current.isDateInToday($0.dueDate) &&
            $0.status == .pending
        }
        .prefix(10)
        .map { $0 }
    }

    var overdueTasks: [AssignedTask] {
        allTasks.filter {
            $0.dueDate < Calendar.current.startOfDay(for: Date()) &&
            $0.status == .pending
        }
    }

    var completedTasks: [AssignedTask] {
        allTasks.filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // MARK: - Methods

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let athleteId = try await getAthleteId() else {
                DebugLogger.shared.log("[TaskList] No athlete ID found", level: .warning)
                return
            }

            if let plan = try await ProtocolService.shared.getActivePlan(athleteId: athleteId) {
                allTasks = plan.tasks
                DebugLogger.shared.log("[TaskList] Loaded \(plan.tasks.count) tasks", level: .success)
            } else {
                allTasks = []
                DebugLogger.shared.log("[TaskList] No active plan found", level: .info)
            }
        } catch {
            self.error = error
            DebugLogger.shared.log("[TaskList] Load failed: \(error.localizedDescription)", level: .error)
        }
    }

    func completeTask(_ task: AssignedTask, notes: String? = nil) async {
        do {
            try await ProtocolService.shared.updateTask(
                taskId: task.id,
                status: AssignedTask.TaskStatus.completed,
                notes: notes
            )

            // Update local state
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks[index] = AssignedTask(
                    id: task.id,
                    planId: task.planId,
                    title: task.title,
                    taskType: task.taskType,
                    dueDate: task.dueDate,
                    dueTime: task.dueTime,
                    status: .completed,
                    completedAt: Date(),
                    notes: notes
                )
            }

            HapticFeedback.success()
            DebugLogger.shared.log("[TaskList] Task completed: \(task.title)", level: .success)
        } catch {
            self.error = error
            HapticFeedback.error()
            DebugLogger.shared.log("[TaskList] Complete failed: \(error.localizedDescription)", level: .error)
        }
    }

    func skipTask(_ task: AssignedTask) async {
        do {
            try await ProtocolService.shared.updateTask(
                taskId: task.id,
                status: AssignedTask.TaskStatus.skipped
            )

            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks.remove(at: index)
            }

            HapticFeedback.light()
            DebugLogger.shared.log("[TaskList] Task skipped: \(task.title)", level: .info)
        } catch {
            self.error = error
            DebugLogger.shared.log("[TaskList] Skip failed: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Private Methods

    private func getAthleteId() async throws -> UUID? {
        // Get current user's patient ID
        guard let userId = PTSupabaseClient.shared.userId else {
            return nil
        }

        let response = try await PTSupabaseClient.shared.client
            .from("patients")
            .select("id")
            .eq("user_id", value: userId)
            .single()
            .execute()

        struct PatientId: Decodable {
            let id: UUID
        }

        let patient = try JSONDecoder().decode(PatientId.self, from: response.data)
        return patient.id
    }
}
