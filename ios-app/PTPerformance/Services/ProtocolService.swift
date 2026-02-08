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

    private let supabaseURL: URL
    private let supabaseKey: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        // Get Supabase configuration from environment or use defaults
        self.supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://api.ptperformance.app")!
        self.supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Template Methods

    /// Fetches all protocol templates, optionally filtered by category
    /// - Parameter category: Optional category filter
    /// - Returns: Array of protocol templates
    func getTemplates(category: ProtocolTemplate.ProtocolCategory? = nil) async throws -> [ProtocolTemplate] {
        var urlComponents = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/protocol_templates"), resolvingAgainstBaseURL: false)!

        var queryItems = [URLQueryItem(name: "is_active", value: "eq.true")]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: "eq.\(category.rawValue)"))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ProtocolServiceError.networkError
            }

            return try decoder.decode([ProtocolTemplate].self, from: data)
        } catch is DecodingError {
            // For development, return sample templates
            return filterTemplates(ProtocolTemplate.sampleTemplates, by: category)
        } catch {
            // For development, return sample templates
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
        // Generate assigned tasks from template tasks and customizations
        let assignedTasks = generateAssignedTasks(
            from: template,
            customizations: customizations,
            planId: UUID() // Temporary, will be replaced with actual plan ID
        )

        let plan = CreatePlanRequest(
            athleteId: athleteId,
            protocolId: template.id,
            startDate: customizations.startDate,
            endDate: customizations.endDate,
            assignedBy: getCurrentUserId(),
            status: AthletePlan.PlanStatus.active.rawValue,
            notes: customizations.notes
        )

        var request = URLRequest(url: supabaseURL.appendingPathComponent("/rest/v1/athlete_plans"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(plan)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ProtocolServiceError.createFailed
            }

            let createdPlans = try decoder.decode([AthletePlan].self, from: data)
            guard var createdPlan = createdPlans.first else {
                throw ProtocolServiceError.createFailed
            }

            // Create the assigned tasks
            try await createAssignedTasks(assignedTasks, for: createdPlan.id)

            // Return the plan with tasks
            return try await getActivePlan(athleteId: athleteId) ?? createdPlan
        } catch {
            // For development, create a mock plan
            let planId = UUID()
            let mockTasks = generateAssignedTasks(from: template, customizations: customizations, planId: planId)

            return AthletePlan(
                id: planId,
                athleteId: athleteId,
                protocolId: template.id,
                startDate: customizations.startDate,
                endDate: customizations.endDate,
                assignedBy: getCurrentUserId(),
                tasks: mockTasks,
                status: .active,
                notes: customizations.notes,
                createdAt: Date()
            )
        }
    }

    private func generateAssignedTasks(
        from template: ProtocolTemplate,
        customizations: PlanCustomization,
        planId: UUID
    ) -> [AssignedTask] {
        var tasks: [AssignedTask] = []
        let calendar = Calendar.current

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

    private func createAssignedTasks(_ tasks: [AssignedTask], for planId: UUID) async throws {
        guard !tasks.isEmpty else { return }

        let taskRequests = tasks.map { task in
            CreateTaskRequest(
                planId: planId,
                title: task.title,
                taskType: task.taskType.rawValue,
                dueDate: task.dueDate,
                dueTime: task.dueTime,
                status: task.status.rawValue,
                notes: task.notes
            )
        }

        var request = URLRequest(url: supabaseURL.appendingPathComponent("/rest/v1/assigned_tasks"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(taskRequests)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProtocolServiceError.createFailed
        }
    }

    // MARK: - Task Methods

    /// Updates a task's status
    /// - Parameters:
    ///   - taskId: UUID of the task
    ///   - status: New status
    ///   - notes: Optional notes
    func updateTask(taskId: UUID, status: AssignedTask.TaskStatus, notes: String? = nil) async throws {
        var urlComponents = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/assigned_tasks"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: "eq.\(taskId.uuidString)")]

        var updateData: [String: Any] = ["status": status.rawValue]

        if status == .completed {
            let formatter = ISO8601DateFormatter()
            updateData["completed_at"] = formatter.string(from: Date())
        }

        if let notes = notes {
            updateData["notes"] = notes
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: updateData)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProtocolServiceError.updateFailed
        }
    }

    // MARK: - Plan Status Methods

    /// Updates a plan's status
    /// - Parameters:
    ///   - planId: UUID of the plan
    ///   - status: New status
    func updatePlanStatus(planId: UUID, status: AthletePlan.PlanStatus) async throws {
        var urlComponents = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/athlete_plans"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: "eq.\(planId.uuidString)")]

        let updateData = ["status": status.rawValue]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(updateData)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProtocolServiceError.updateFailed
        }
    }

    /// Gets the active plan for an athlete
    /// - Parameter athleteId: UUID of the athlete
    /// - Returns: The active plan if one exists
    func getActivePlan(athleteId: UUID) async throws -> AthletePlan? {
        var urlComponents = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/athlete_plans"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "athlete_id", value: "eq.\(athleteId.uuidString)"),
            URLQueryItem(name: "status", value: "in.(active,paused)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ProtocolServiceError.networkError
            }

            var plans = try decoder.decode([AthletePlan].self, from: data)

            guard var plan = plans.first else {
                return nil
            }

            // Fetch associated tasks
            let tasks = try await getTasksForPlan(planId: plan.id)

            // Return plan with tasks (need to reconstruct since tasks is let)
            return AthletePlan(
                id: plan.id,
                athleteId: plan.athleteId,
                protocolId: plan.protocolId,
                startDate: plan.startDate,
                endDate: plan.endDate,
                assignedBy: plan.assignedBy,
                tasks: tasks,
                status: plan.status,
                notes: plan.notes,
                createdAt: plan.createdAt
            )
        } catch {
            // For development, return nil
            return nil
        }
    }

    private func getTasksForPlan(planId: UUID) async throws -> [AssignedTask] {
        var urlComponents = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/assigned_tasks"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "plan_id", value: "eq.\(planId.uuidString)"),
            URLQueryItem(name: "order", value: "due_date.asc,due_time.asc")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProtocolServiceError.networkError
        }

        return try decoder.decode([AssignedTask].self, from: data)
    }

    // MARK: - Helper Methods

    private func getCurrentUserId() -> UUID {
        // In a real implementation, this would get the authenticated user ID
        // For now, return a placeholder
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
