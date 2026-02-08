//
//  ProtocolService.swift
//  PTPerformance
//
//  Service for managing protocol templates and athlete plans
//  Handles CRUD operations for protocol assignment workflow
//

import Foundation

/// Service for protocol template and athlete plan management
actor ProtocolService {
    static let shared = ProtocolService()

    private let supabase = PTSupabaseClient.shared
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.decoder = PTSupabaseClient.flexibleDecoder

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Template Methods

    /// Fetches all protocol templates, optionally filtered by category
    /// - Parameter category: Optional category filter
    /// - Returns: Array of protocol templates
    func getTemplates(category: ProtocolTemplate.ProtocolCategory? = nil) async throws -> [ProtocolTemplate] {
        DebugLogger.shared.log("[ProtocolService] Fetching templates, category: \(category?.rawValue ?? "all")")

        do {
            var query = supabase.client
                .from("protocol_templates")
                .select()
                .eq("is_active", value: true)

            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }

            let templates: [ProtocolTemplate] = try await query.execute().value
            DebugLogger.shared.log("[ProtocolService] Fetched \(templates.count) templates", level: .success)
            return templates
        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to fetch templates: \(error.localizedDescription), using sample data", level: .warning)
            // Fallback to sample templates for development/offline
            return filterTemplates(ProtocolTemplate.sampleTemplates, by: category)
        }
    }

    private func filterTemplates(_ templates: [ProtocolTemplate], by category: ProtocolTemplate.ProtocolCategory?) -> [ProtocolTemplate] {
        guard let category = category else { return templates }
        return templates.filter { $0.category == category }
    }

    // MARK: - Plan Methods

    /// Creates a new athlete plan from a protocol template
    /// - Parameters:
    ///   - athleteId: UUID of the athlete
    ///   - template: The protocol template to use
    ///   - customizations: Custom modifications to the plan
    /// - Returns: The created athlete plan
    func createPlan(
        athleteId: UUID,
        template: ProtocolTemplate,
        customizations: PlanCustomization
    ) async throws -> AthletePlan {
        DebugLogger.shared.log("[ProtocolService] Creating plan for athlete \(athleteId) with template \(template.name)")

        let currentUserId = getCurrentUserId()

        // Prepare plan data for insertion
        let planData = CreatePlanRequest(
            athleteId: athleteId,
            protocolId: template.id,
            startDate: customizations.startDate,
            endDate: customizations.endDate,
            assignedBy: currentUserId,
            status: AthletePlan.PlanStatus.active.rawValue,
            notes: customizations.notes
        )

        do {
            // Insert the athlete plan
            let createdPlan: AthletePlan = try await supabase.client
                .from("athlete_plans")
                .insert(planData)
                .select()
                .single()
                .execute()
                .value

            DebugLogger.shared.log("[ProtocolService] Created plan with ID: \(createdPlan.id)", level: .success)

            // Generate and insert tasks
            let tasks = generateTaskInsertData(
                from: template,
                customizations: customizations,
                planId: createdPlan.id
            )

            if !tasks.isEmpty {
                try await supabase.client
                    .from("assigned_tasks")
                    .insert(tasks)
                    .execute()

                DebugLogger.shared.log("[ProtocolService] Created \(tasks.count) assigned tasks", level: .success)
            }

            // Track KPI event for plan assignment
            try await trackPlanAssignment(athleteId: athleteId, assignedBy: currentUserId)

            // Fetch and return the complete plan with tasks
            if let completePlan = try await getActivePlan(athleteId: athleteId) {
                return completePlan
            }

            // If we can't fetch the complete plan, return what we have
            return createdPlan

        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to create plan: \(error.localizedDescription)", level: .error)

            // For development/offline, create a mock plan
            let planId = UUID()
            let mockTasks = generateAssignedTasks(from: template, customizations: customizations, planId: planId)

            DebugLogger.shared.log("[ProtocolService] Returning mock plan for offline development", level: .warning)

            return AthletePlan(
                id: planId,
                athleteId: athleteId,
                protocolId: template.id,
                startDate: customizations.startDate,
                endDate: customizations.endDate,
                assignedBy: currentUserId,
                tasks: mockTasks,
                status: .active,
                notes: customizations.notes,
                createdAt: Date()
            )
        }
    }

    /// Generates task data formatted for Supabase insertion
    private func generateTaskInsertData(
        from template: ProtocolTemplate,
        customizations: PlanCustomization,
        planId: UUID
    ) -> [CreateTaskRequest] {
        var taskRequests: [CreateTaskRequest] = []

        for templateTask in template.tasks {
            guard let taskCustomization = customizations.taskCustomizations[templateTask.id],
                  taskCustomization.isIncluded else {
                continue
            }

            // Generate dates for this task based on frequency
            let dates = generateTaskDates(
                for: templateTask.frequency,
                from: customizations.startDate,
                to: customizations.endDate
            )

            for date in dates {
                let taskRequest = CreateTaskRequest(
                    planId: planId,
                    title: templateTask.title,
                    taskType: templateTask.taskType.rawValue,
                    dueDate: date,
                    dueTime: taskCustomization.customTime ?? templateTask.defaultTime,
                    status: AssignedTask.TaskStatus.pending.rawValue,
                    notes: taskCustomization.customInstructions
                )
                taskRequests.append(taskRequest)
            }
        }

        return taskRequests
    }

    /// Tracks plan assignment event for KPI reporting
    private func trackPlanAssignment(athleteId: UUID, assignedBy: UUID) async throws {
        let eventData: [String: String] = [
            "event_type": "plan_assigned",
            "user_id": assignedBy.uuidString,
            "athlete_id": athleteId.uuidString
        ]

        do {
            try await supabase.client
                .from("kpi_events")
                .insert(eventData)
                .execute()

            DebugLogger.shared.log("[ProtocolService] Tracked plan assignment KPI event", level: .success)
        } catch {
            // Don't fail the whole operation if KPI tracking fails
            DebugLogger.shared.log("[ProtocolService] Failed to track KPI event: \(error.localizedDescription)", level: .warning)
        }
    }

    private func generateAssignedTasks(
        from template: ProtocolTemplate,
        customizations: PlanCustomization,
        planId: UUID
    ) -> [AssignedTask] {
        var tasks: [AssignedTask] = []

        for templateTask in template.tasks {
            guard let taskCustomization = customizations.taskCustomizations[templateTask.id],
                  taskCustomization.isIncluded else {
                continue
            }

            // Generate tasks based on frequency
            let dates = generateTaskDates(
                for: templateTask.frequency,
                from: customizations.startDate,
                to: customizations.endDate
            )

            for date in dates {
                let task = AssignedTask(
                    id: UUID(),
                    planId: planId,
                    title: templateTask.title,
                    taskType: templateTask.taskType,
                    dueDate: date,
                    dueTime: taskCustomization.customTime ?? templateTask.defaultTime,
                    status: .pending,
                    completedAt: nil,
                    notes: taskCustomization.customInstructions
                )
                tasks.append(task)
            }
        }

        return tasks.sorted { $0.dueDate < $1.dueDate }
    }

    private func generateTaskDates(
        for frequency: ProtocolTask.TaskFrequency,
        from startDate: Date,
        to endDate: Date
    ) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        switch frequency {
        case .daily:
            while currentDate <= endDay {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

        case .twiceDaily:
            while currentDate <= endDay {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            // Note: In real implementation, we'd create two tasks per day with different times

        case .everyOtherDay:
            while currentDate <= endDay {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 2, to: currentDate)!
            }

        case .weekly:
            while currentDate <= endDay {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
            }

        case .asNeeded:
            // For as-needed tasks, create just one placeholder
            dates.append(startDate)
        }

        return dates
    }

    // MARK: - Task Methods

    /// Updates a task's status
    /// - Parameters:
    ///   - taskId: UUID of the task
    ///   - status: New status
    ///   - notes: Optional notes
    func updateTask(taskId: UUID, status: AssignedTask.TaskStatus, notes: String? = nil) async throws {
        DebugLogger.shared.log("[ProtocolService] Updating task \(taskId) to status: \(status.rawValue)")

        var updateData = TaskUpdateRequest(status: status.rawValue)

        if status == .completed {
            updateData.completedAt = Date()
        }

        if let notes = notes {
            updateData.notes = notes
        }

        do {
            try await supabase.client
                .from("assigned_tasks")
                .update(updateData)
                .eq("id", value: taskId.uuidString)
                .execute()

            DebugLogger.shared.log("[ProtocolService] Task updated successfully", level: .success)
        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to update task: \(error.localizedDescription)", level: .error)
            throw ProtocolServiceError.updateFailed
        }
    }

    // MARK: - Plan Status Methods

    /// Updates a plan's status
    /// - Parameters:
    ///   - planId: UUID of the plan
    ///   - status: New status
    func updatePlanStatus(planId: UUID, status: AthletePlan.PlanStatus) async throws {
        DebugLogger.shared.log("[ProtocolService] Updating plan \(planId) to status: \(status.rawValue)")

        do {
            try await supabase.client
                .from("athlete_plans")
                .update(["status": status.rawValue])
                .eq("id", value: planId.uuidString)
                .execute()

            DebugLogger.shared.log("[ProtocolService] Plan status updated successfully", level: .success)
        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to update plan status: \(error.localizedDescription)", level: .error)
            throw ProtocolServiceError.updateFailed
        }
    }

    /// Gets the active plan for an athlete
    /// - Parameter athleteId: UUID of the athlete
    /// - Returns: The active plan if one exists
    func getActivePlan(athleteId: UUID) async throws -> AthletePlan? {
        DebugLogger.shared.log("[ProtocolService] Fetching active plan for athlete \(athleteId)")

        do {
            // Fetch plan with embedded tasks using Supabase relationship
            let plans: [AthletePlan] = try await supabase.client
                .from("athlete_plans")
                .select("*, assigned_tasks(*)")
                .eq("athlete_id", value: athleteId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let plan = plans.first {
                DebugLogger.shared.log("[ProtocolService] Found active plan: \(plan.id)", level: .success)
                return plan
            }

            DebugLogger.shared.log("[ProtocolService] No active plan found for athlete")
            return nil
        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to fetch active plan: \(error.localizedDescription)", level: .warning)
            // For development, return nil
            return nil
        }
    }

    private func getTasksForPlan(planId: UUID) async throws -> [AssignedTask] {
        DebugLogger.shared.log("[ProtocolService] Fetching tasks for plan \(planId)")

        do {
            let tasks: [AssignedTask] = try await supabase.client
                .from("assigned_tasks")
                .select()
                .eq("plan_id", value: planId.uuidString)
                .order("due_date", ascending: true)
                .order("due_time", ascending: true)
                .execute()
                .value

            DebugLogger.shared.log("[ProtocolService] Fetched \(tasks.count) tasks", level: .success)
            return tasks
        } catch {
            DebugLogger.shared.log("[ProtocolService] Failed to fetch tasks: \(error.localizedDescription)", level: .error)
            throw ProtocolServiceError.networkError
        }
    }

    // MARK: - Helper Methods

    private func getCurrentUserId() -> UUID {
        // Get authenticated user ID from PTSupabaseClient
        if let userIdString = supabase.userId,
           let userId = UUID(uuidString: userIdString) {
            return userId
        }
        // Fallback to a new UUID if not authenticated (shouldn't happen in production)
        DebugLogger.shared.log("[ProtocolService] No authenticated user, using placeholder UUID", level: .warning)
        return UUID()
    }
}

// MARK: - Request Models

private struct CreatePlanRequest: Encodable {
    let athleteId: UUID
    let protocolId: UUID
    let startDate: Date
    let endDate: Date
    let assignedBy: UUID
    let status: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case athleteId = "athlete_id"
        case protocolId = "protocol_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case assignedBy = "assigned_by"
        case status
        case notes
    }
}

private struct CreateTaskRequest: Encodable {
    let planId: UUID
    let title: String
    let taskType: String
    let dueDate: Date
    let dueTime: String?
    let status: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case title
        case taskType = "task_type"
        case dueDate = "due_date"
        case dueTime = "due_time"
        case status
        case notes
    }
}

private struct TaskUpdateRequest: Encodable {
    var status: String
    var completedAt: Date?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
        case notes
    }
}

// MARK: - Errors

enum ProtocolServiceError: LocalizedError {
    case networkError
    case createFailed
    case updateFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .createFailed:
            return "Failed to create the protocol plan."
        case .updateFailed:
            return "Failed to update the task or plan."
        case .notFound:
            return "The requested resource was not found."
        }
    }
}
