//
//  BodyCompGoalsViewModel.swift
//  PTPerformance
//
//  ViewModel for body composition goals management and progress tracking
//

import SwiftUI

/// ViewModel for managing body composition goals and tracking progress
@MainActor
class BodyCompGoalsViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Published Properties

    @Published var currentGoals: BodyCompGoals?
    @Published var currentProgress: BodyCompGoalProgress?
    @Published var allGoals: [BodyCompGoals] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: AppError?
    @Published var showingSuccessAlert = false
    @Published var showingGoalAchievedAlert = false

    // Latest measurements (populated from progress view or direct fetch)
    @Published var latestWeight: Double?
    @Published var latestBodyFat: Double?
    @Published var latestMuscleMass: Double?

    // MARK: - Private Properties

    private let service = BodyCompGoalsService()
    private let supabase = PTSupabaseClient.shared

    /// Patient ID from the current Supabase session
    var patientId: String? {
        supabase.userId
    }

    // MARK: - Computed Properties

    /// Overall progress status based on current measurements
    var progressStatus: GoalProgressStatus {
        guard let goals = currentGoals else { return .onTrack }
        return goals.progressStatus(currentWeight: latestWeight, currentBodyFat: latestBodyFat)
    }

    /// Weight progress as a percentage (0.0 to 1.0)
    var weightProgress: Double {
        if let progress = currentProgress, let pct = progress.weightProgressPct {
            return min(1.0, max(0, pct / 100.0))
        }
        guard let goals = currentGoals else { return 0 }
        return min(1.0, max(0, goals.weightProgress(current: latestWeight)))
    }

    /// Body fat progress as a percentage (0.0 to 1.0)
    var bodyFatProgress: Double {
        if let progress = currentProgress, let pct = progress.bodyFatProgressPct {
            return min(1.0, max(0, pct / 100.0))
        }
        guard let goals = currentGoals else { return 0 }
        return min(1.0, max(0, goals.bodyFatProgress(current: latestBodyFat)))
    }

    /// Muscle mass progress as a percentage (0.0 to 1.0)
    var muscleMassProgress: Double {
        if let progress = currentProgress, let pct = progress.muscleMassProgressPct {
            return min(1.0, max(0, pct / 100.0))
        }
        guard let goals = currentGoals else { return 0 }
        return min(1.0, max(0, goals.muscleMassProgress(current: latestMuscleMass)))
    }

    /// Weekly weight change needed to reach goal on time
    var weeklyWeightChange: Double? {
        currentGoals?.weeklyWeightChangeNeeded(current: latestWeight)
    }

    /// Weekly body fat change needed to reach goal on time
    var weeklyBodyFatChange: Double? {
        currentGoals?.weeklyBodyFatChangeNeeded(current: latestBodyFat)
    }

    /// Days remaining until target date
    var daysRemaining: Int? {
        currentProgress?.daysRemaining ?? currentGoals?.daysRemaining
    }

    /// Formatted target date
    var targetDateText: String {
        currentGoals?.formattedTargetDate ?? "No target date"
    }

    /// Whether the user has active goals set
    var hasActiveGoals: Bool {
        currentGoals != nil && currentGoals?.status == .active
    }

    /// Whether any goal target has been achieved
    var isAnyGoalAchieved: Bool {
        if let progress = currentProgress {
            return service.isGoalAchieved(progress: progress)
        }
        guard let goals = currentGoals else { return false }
        return service.isGoalAchieved(
            goal: goals,
            currentWeight: latestWeight,
            currentBodyFat: latestBodyFat,
            currentMuscleMass: latestMuscleMass
        )
    }

    // MARK: - Initialization

    init() {
        // Load goals on init if patient ID is available
        Task {
            await loadData()
        }
    }

    // MARK: - Data Loading

    /// Load both goals and latest measurements
    func loadData() async {
        guard let patientIdString = patientId,
              let patientUUID = UUID(uuidString: patientIdString) else {
            return
        }

        isLoading = true
        error = nil

        do {
            // Fetch all data in parallel using async let
            async let progressTask = service.fetchCurrentGoalProgress(patientId: patientUUID)
            async let goalsTask = service.fetchCurrentGoal(patientId: patientUUID)
            async let allGoalsTask = service.fetchGoals(patientId: patientUUID)

            let (progress, goals, fetchedAllGoals) = try await (progressTask, goalsTask, allGoalsTask)

            // Process progress data
            if let progress = progress {
                currentProgress = progress
                latestWeight = progress.currentWeight
                latestBodyFat = progress.currentBodyFat
                latestMuscleMass = progress.currentMuscleMass
                currentGoals = goals
            } else {
                // No progress view data
                currentGoals = goals
                currentProgress = nil

                // Load latest measurements separately
                await loadLatestMeasurements(patientId: patientIdString)
            }

            // Load all goals history
            allGoals = fetchedAllGoals

            // Check if goal was achieved
            if let currentGoal = currentGoals, currentGoal.status == .active {
                let achieved = await checkGoalAchievement(goal: currentGoal)
                if achieved {
                    showingGoalAchievedAlert = true
                }
            }
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Load Body Comp Goals")
        }

        isLoading = false
    }

    /// Load only the latest body composition measurements
    private func loadLatestMeasurements(patientId: String) async {
        do {
            let results: [BodyComposition] = try await supabase.client
                .from("body_compositions")
                .select()
                .eq("patient_id", value: patientId)
                .order("recorded_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let latest = results.first {
                latestWeight = latest.weightLb
                latestBodyFat = latest.bodyFatPercent
                latestMuscleMass = latest.muscleMassLb
            }
        } catch {
            DebugLogger.shared.warning("BodyCompGoalsViewModel", "Error loading latest measurements: \(error.localizedDescription)")
        }
    }

    // MARK: - Save Goals

    /// Save new body composition goals
    /// - Parameters:
    ///   - targetWeight: Target weight in lbs (optional)
    ///   - targetBodyFat: Target body fat percentage (optional)
    ///   - targetMuscleMass: Target muscle mass in lbs (optional)
    ///   - targetDate: Target date to achieve goals
    ///   - notes: Optional notes about the goal
    func saveGoals(
        targetWeight: Double?,
        targetBodyFat: Double?,
        targetMuscleMass: Double?,
        targetDate: Date,
        notes: String? = nil
    ) async {
        guard let patientIdString = patientId,
              let patientUUID = UUID(uuidString: patientIdString) else {
            error = AppError.notAuthenticated
            return
        }

        // Validate that at least one target is set
        guard targetWeight != nil || targetBodyFat != nil || targetMuscleMass != nil else {
            error = AppError.invalidInput("goal target")
            return
        }

        isSaving = true
        error = nil

        do {
            // If there's an existing active goal, pause it first
            if let existingGoal = currentGoals, existingGoal.status == .active {
                try await service.updateGoalStatus(goalId: existingGoal.id, status: .paused)
            }

            // Format target date as YYYY-MM-DD string for PostgreSQL DATE type
            let targetDateString = Self.isoDateFormatter.string(from: targetDate)

            // Create the new goal with current values as starting point
            let input = CreateBodyCompGoalInput(
                patientId: patientUUID,
                targetWeight: targetWeight,
                targetBodyFatPercentage: targetBodyFat,
                targetMuscleMass: targetMuscleMass,
                targetBmi: nil,
                startingWeight: latestWeight,
                startingBodyFatPercentage: latestBodyFat,
                startingMuscleMass: latestMuscleMass,
                targetDate: targetDateString,
                notes: notes
            )

            currentGoals = try await service.createGoal(input)
            showingSuccessAlert = true

            // Haptic feedback
            HapticFeedback.success()

            // Reload all data
            await loadData()

            DebugLogger.shared.log("[BodyCompGoals] Goals saved successfully", level: .success)
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Save Body Comp Goals")
            HapticFeedback.error()
        }

        isSaving = false
    }

    // MARK: - Update Goals

    /// Update existing goals
    func updateGoals(
        targetWeight: Double?,
        targetBodyFat: Double?,
        targetMuscleMass: Double?,
        targetDate: Date?,
        notes: String?
    ) async {
        guard let goal = currentGoals else {
            error = AppError.dataNotFound
            return
        }

        isSaving = true
        error = nil

        do {
            var targetDateString: String? = nil
            if let date = targetDate {
                targetDateString = Self.isoDateFormatter.string(from: date)
            }

            var update = UpdateBodyCompGoalInput()
            update.targetWeight = targetWeight
            update.targetBodyFatPercentage = targetBodyFat
            update.targetMuscleMass = targetMuscleMass
            update.targetDate = targetDateString
            update.notes = notes

            try await service.updateGoal(goalId: goal.id, update: update)

            // Reload goals
            await loadData()

            HapticFeedback.success()
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Update Body Comp Goals")
            HapticFeedback.error()
        }

        isSaving = false
    }

    // MARK: - Goal Status Management

    /// Mark the current goal as achieved
    func markGoalAchieved() async {
        guard let goal = currentGoals else { return }

        isSaving = true

        do {
            try await service.markGoalAchieved(goalId: goal.id)

            // Reload goals
            await loadData()

            HapticFeedback.success()
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Mark Goal Achieved")
        }

        isSaving = false
    }

    /// Pause the current goal
    func pauseGoal() async {
        guard let goal = currentGoals else { return }

        isSaving = true

        do {
            try await service.updateGoalStatus(goalId: goal.id, status: .paused)
            await loadData()
            HapticFeedback.medium()
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Pause Goal")
        }

        isSaving = false
    }

    /// Cancel the current goal
    func cancelGoal() async {
        guard let goal = currentGoals else { return }

        isSaving = true

        do {
            try await service.updateGoalStatus(goalId: goal.id, status: .cancelled)
            await loadData()
            HapticFeedback.medium()
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Cancel Goal")
        }

        isSaving = false
    }

    /// Delete a goal
    func deleteGoal(_ goal: BodyCompGoals) async {
        isSaving = true

        do {
            try await service.deleteGoal(goalId: goal.id)

            // Remove from local array
            allGoals.removeAll { $0.id == goal.id }

            // If it was the current goal, clear it
            if currentGoals?.id == goal.id {
                currentGoals = nil
                currentProgress = nil
            }

            HapticFeedback.success()
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Delete Goal")
        }

        isSaving = false
    }

    // MARK: - Goal Achievement Check

    /// Check if the goal has been achieved and auto-mark if so
    private func checkGoalAchievement(goal: BodyCompGoals) async -> Bool {
        let achieved: Bool
        if let progress = currentProgress {
            achieved = service.isGoalAchieved(progress: progress)
        } else {
            achieved = service.isGoalAchieved(
                goal: goal,
                currentWeight: latestWeight,
                currentBodyFat: latestBodyFat,
                currentMuscleMass: latestMuscleMass
            )
        }

        if achieved {
            // Auto-mark as achieved
            do {
                try await service.markGoalAchieved(goalId: goal.id)

                // Reload to get updated state
                guard let patientIdString = patientId,
                      let patientUUID = UUID(uuidString: patientIdString) else { return achieved }

                currentGoals = try await service.fetchCurrentGoal(patientId: patientUUID)
                currentProgress = try await service.fetchCurrentGoalProgress(patientId: patientUUID)

                DebugLogger.shared.log("[BodyCompGoals] Goal automatically marked as achieved!", level: .success)
            } catch {
                DebugLogger.shared.warning("BodyCompGoalsViewModel", "Error auto-marking goal as achieved: \(error.localizedDescription)")
            }
        }

        return achieved
    }

    // MARK: - Projected Completion

    /// Calculate projected completion date based on current rate of change
    func projectedCompletionDate(for metric: GoalMetric, recentEntries: [BodyComposition]) -> Date? {
        guard let goal = currentGoals else { return nil }

        // Need at least 2 entries to calculate rate
        let sortedEntries = recentEntries.sorted { $0.recordedAt < $1.recordedAt }
        guard sortedEntries.count >= 2,
              let firstEntry = sortedEntries.first,
              let lastEntry = sortedEntries.last else { return nil }

        let daysBetween = Calendar.current.dateComponents(
            [.day],
            from: firstEntry.recordedAt,
            to: lastEntry.recordedAt
        ).day ?? 1

        guard daysBetween > 0 else { return nil }

        // Calculate daily rate of change
        var dailyRate: Double = 0
        var target: Double = 0
        var current: Double = 0

        switch metric {
        case .weight:
            guard let firstWeight = firstEntry.weightLb,
                  let lastWeight = lastEntry.weightLb,
                  let targetWeight = goal.targetWeight else { return nil }

            dailyRate = (lastWeight - firstWeight) / Double(daysBetween)
            target = targetWeight
            current = lastWeight

        case .bodyFat:
            guard let firstBF = firstEntry.bodyFatPercent,
                  let lastBF = lastEntry.bodyFatPercent,
                  let targetBF = goal.targetBodyFatPercentage else { return nil }

            dailyRate = (lastBF - firstBF) / Double(daysBetween)
            target = targetBF
            current = lastBF

        case .muscleMass:
            guard let firstMM = firstEntry.muscleMassLb,
                  let lastMM = lastEntry.muscleMassLb,
                  let targetMM = goal.targetMuscleMass else { return nil }

            dailyRate = (lastMM - firstMM) / Double(daysBetween)
            target = targetMM
            current = lastMM
        }

        // Avoid division by zero and ensure progress is being made in the right direction
        guard dailyRate != 0 else { return nil }

        let remaining = target - current
        let daysToGoal = remaining / dailyRate

        // Only return a valid date if progress is in the right direction
        guard daysToGoal > 0 && daysToGoal < 3650 else { return nil } // Cap at 10 years

        return Calendar.current.date(byAdding: .day, value: Int(daysToGoal), to: Date())
    }

    /// Metrics that can have goals
    enum GoalMetric {
        case weight
        case bodyFat
        case muscleMass
    }
}
