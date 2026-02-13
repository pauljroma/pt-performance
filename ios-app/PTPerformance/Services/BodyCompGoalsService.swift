//
//  BodyCompGoalsService.swift
//  PTPerformance
//
//  Service for body composition goals CRUD operations with Supabase
//

import Foundation

/// Service for managing body composition goals in Supabase
actor BodyCompGoalsService {

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let tableName = "body_comp_goals"
    private let progressViewName = "vw_body_comp_goal_progress"

    // MARK: - Fetch Goals

    /// Fetch all body composition goals for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of BodyCompGoals ordered by created_at descending
    func fetchGoals(patientId: UUID) async throws -> [BodyCompGoals] {
        let goals: [BodyCompGoals] = try await supabase.client
            .from(tableName)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        DebugLogger.shared.log("[BodyCompGoals] Fetched \(goals.count) goals for patient \(patientId)", level: .diagnostic)

        return goals
    }

    /// Fetch only active goals for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of active BodyCompGoals
    func fetchActiveGoals(patientId: UUID) async throws -> [BodyCompGoals] {
        let goals: [BodyCompGoals] = try await supabase.client
            .from(tableName)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: BodyCompGoalStatus.active.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value

        return goals
    }

    /// Fetch the most recent active goal for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: The most recent active BodyCompGoals, or nil if none exists
    func fetchCurrentGoal(patientId: UUID) async throws -> BodyCompGoals? {
        let goals: [BodyCompGoals] = try await supabase.client
            .from(tableName)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: BodyCompGoalStatus.active.rawValue)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return goals.first
    }

    /// Fetch goal progress from the database view (includes current measurements)
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of BodyCompGoalProgress with current measurements and calculated progress
    func fetchGoalProgress(patientId: UUID) async throws -> [BodyCompGoalProgress] {
        let progress: [BodyCompGoalProgress] = try await supabase.client
            .from(progressViewName)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: BodyCompGoalStatus.active.rawValue)
            .execute()
            .value

        DebugLogger.shared.log("[BodyCompGoals] Fetched progress for \(progress.count) active goals", level: .diagnostic)

        return progress
    }

    /// Fetch current goal progress (single active goal with measurements)
    func fetchCurrentGoalProgress(patientId: UUID) async throws -> BodyCompGoalProgress? {
        let progress: [BodyCompGoalProgress] = try await supabase.client
            .from(progressViewName)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: BodyCompGoalStatus.active.rawValue)
            .limit(1)
            .execute()
            .value

        return progress.first
    }

    // MARK: - Create Goal

    /// Create a new body composition goal
    /// - Parameter goal: The goal data to insert
    /// - Returns: The created BodyCompGoals with server-generated fields
    func createGoal(_ input: CreateBodyCompGoalInput) async throws -> BodyCompGoals {
        let results: [BodyCompGoals] = try await supabase.client
            .from(tableName)
            .insert(input)
            .select()
            .execute()
            .value

        guard let createdGoal = results.first else {
            throw AppError.saveFailed
        }

        DebugLogger.shared.log("[BodyCompGoals] Created goal: \(createdGoal.id)", level: .success)

        return createdGoal
    }

    // MARK: - Update Goal

    /// Update an existing body composition goal
    /// - Parameters:
    ///   - goalId: The goal's UUID
    ///   - update: The fields to update
    func updateGoal(goalId: UUID, update: UpdateBodyCompGoalInput) async throws {
        try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: goalId.uuidString)
            .execute()

        DebugLogger.shared.log("[BodyCompGoals] Updated goal: \(goalId)", level: .success)
    }

    /// Update the status of a goal
    /// - Parameters:
    ///   - goalId: The goal's UUID
    ///   - status: The new status
    func updateBodyCompGoalStatus(goalId: UUID, status: BodyCompGoalStatus) async throws {
        var update = UpdateBodyCompGoalInput()
        update.status = status.rawValue

        try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: goalId.uuidString)
            .execute()

        DebugLogger.shared.log("[BodyCompGoals] Updated goal \(goalId) status to \(status.rawValue)", level: .success)
    }

    /// Mark a goal as achieved
    /// - Parameter goalId: The goal's UUID
    func markGoalAchieved(goalId: UUID) async throws {
        try await updateBodyCompGoalStatus(goalId: goalId, status: .achieved)
    }

    /// Alias for updateBodyCompGoalStatus for compatibility
    func updateGoalStatus(goalId: UUID, status: BodyCompGoalStatus) async throws {
        try await updateBodyCompGoalStatus(goalId: goalId, status: status)
    }

    // MARK: - Delete Goal

    /// Delete a body composition goal
    /// - Parameter goalId: The goal's UUID
    func deleteGoal(goalId: UUID) async throws {
        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: goalId.uuidString)
            .execute()

        DebugLogger.shared.log("[BodyCompGoals] Deleted goal: \(goalId)", level: .success)
    }

    // MARK: - Goal Achievement Check

    /// Check if a goal has been achieved based on current measurements
    /// - Parameters:
    ///   - goal: The goal to check
    ///   - currentWeight: Current weight measurement
    ///   - currentBodyFat: Current body fat percentage
    ///   - currentMuscleMass: Current muscle mass
    /// - Returns: True if all set targets have been reached
    nonisolated func isGoalAchieved(
        goal: BodyCompGoals,
        currentWeight: Double?,
        currentBodyFat: Double?,
        currentMuscleMass: Double?
    ) -> Bool {
        var achievedCount = 0
        var totalTargets = 0

        // Check weight goal
        if let target = goal.targetWeight, let current = currentWeight {
            totalTargets += 1
            let start = goal.startingWeight ?? current
            let isLossGoal = start > target

            if isLossGoal && current <= target {
                achievedCount += 1
            } else if !isLossGoal && current >= target {
                achievedCount += 1
            }
        }

        // Check body fat goal
        if let target = goal.targetBodyFatPercentage, let current = currentBodyFat {
            totalTargets += 1
            let start = goal.startingBodyFatPercentage ?? current
            let isLossGoal = start > target

            if isLossGoal && current <= target {
                achievedCount += 1
            } else if !isLossGoal && current >= target {
                achievedCount += 1
            }
        }

        // Check muscle mass goal
        if let target = goal.targetMuscleMass, let current = currentMuscleMass {
            totalTargets += 1
            let start = goal.startingMuscleMass ?? current
            let isGainGoal = start < target

            if isGainGoal && current >= target {
                achievedCount += 1
            } else if !isGainGoal && current <= target {
                achievedCount += 1
            }
        }

        // All targets must be achieved
        return totalTargets > 0 && achievedCount == totalTargets
    }

    /// Check if a goal is achieved using progress data from the view
    nonisolated func isGoalAchieved(progress: BodyCompGoalProgress) -> Bool {
        var achievedCount = 0
        var totalTargets = 0

        if progress.targetWeight != nil {
            totalTargets += 1
            if let pct = progress.weightProgressPct, pct >= 100 {
                achievedCount += 1
            }
        }

        if progress.targetBodyFatPercentage != nil {
            totalTargets += 1
            if let pct = progress.bodyFatProgressPct, pct >= 100 {
                achievedCount += 1
            }
        }

        if progress.targetMuscleMass != nil {
            totalTargets += 1
            if let pct = progress.muscleMassProgressPct, pct >= 100 {
                achievedCount += 1
            }
        }

        return totalTargets > 0 && achievedCount == totalTargets
    }

    // MARK: - Convenience Methods (String-based patient IDs)

    /// Get the active goal for a patient (String version)
    /// - Parameter patientId: The patient's ID as string
    /// - Returns: The active goal, or nil if none exists
    func getActiveGoal(patientId: String) async throws -> BodyCompGoals? {
        guard let uuid = UUID(uuidString: patientId) else {
            throw AppError.invalidInput("Invalid patient ID format")
        }
        return try await fetchCurrentGoal(patientId: uuid)
    }

    /// Get goal progress from the database view (String version)
    /// - Parameter patientId: The patient's ID as string
    /// - Returns: Progress data for the active goal, or nil if none exists
    func getGoalProgress(patientId: String) async throws -> BodyCompGoalProgress? {
        guard let uuid = UUID(uuidString: patientId) else {
            throw AppError.invalidInput("Invalid patient ID format")
        }
        return try await fetchCurrentGoalProgress(patientId: uuid)
    }

    /// Create a new goal with convenience parameters
    /// - Parameters:
    ///   - patientId: The patient's ID as string
    ///   - targetWeight: Target weight in lbs (optional)
    ///   - targetBodyFat: Target body fat percentage (optional)
    ///   - targetMuscleMass: Target muscle mass in lbs (optional)
    ///   - targetDate: Target date to achieve goal (optional)
    ///   - currentWeight: Current weight (for starting value)
    ///   - currentBodyFat: Current body fat (for starting value)
    /// - Returns: The created goal
    func createGoal(
        patientId: String,
        targetWeight: Double?,
        targetBodyFat: Double?,
        targetMuscleMass: Double?,
        targetDate: Date?,
        currentWeight: Double?,
        currentBodyFat: Double?
    ) async throws -> BodyCompGoals {
        guard let uuid = UUID(uuidString: patientId) else {
            throw AppError.invalidInput("Invalid patient ID format")
        }

        // Format target date if provided
        var targetDateString: String?
        if let date = targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            targetDateString = formatter.string(from: date)
        }

        // First, deactivate any existing active goals
        let existingGoals = try await fetchActiveGoals(patientId: uuid)
        for goal in existingGoals {
            try await updateBodyCompGoalStatus(goalId: goal.id, status: .cancelled)
        }

        let input = CreateBodyCompGoalInput(
            patientId: uuid,
            targetWeight: targetWeight,
            targetBodyFatPercentage: targetBodyFat,
            targetMuscleMass: targetMuscleMass,
            targetBmi: nil,
            startingWeight: currentWeight,
            startingBodyFatPercentage: currentBodyFat,
            startingMuscleMass: nil,
            targetDate: targetDateString,
            notes: nil
        )

        return try await createGoal(input)
    }

    /// Get goal history (String version)
    /// - Parameter patientId: The patient's ID as string
    /// - Returns: Array of all goals for the patient
    func getGoalHistory(patientId: String) async throws -> [BodyCompGoals] {
        guard let uuid = UUID(uuidString: patientId) else {
            throw AppError.invalidInput("Invalid patient ID format")
        }
        return try await fetchGoals(patientId: uuid)
    }
}
