//
//  PatientGoalsViewModel.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//

import Foundation
import SwiftUI

/// ViewModel for managing patient goals and progress tracking
@MainActor
class PatientGoalsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var goals: [PatientGoal] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showingSuccessAlert = false

    // MARK: - Form Fields

    @Published var title: String = ""
    @Published var goalDescription: String = ""
    @Published var category: GoalCategory = .strength
    @Published var targetValueText: String = ""
    @Published var currentValueText: String = ""
    @Published var unit: String = ""
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @Published var hasTargetDate: Bool = false
    @Published var status: GoalStatus = .active

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared

    // MARK: - Update DTOs

    private struct ProgressUpdate: Codable {
        let currentValue: Double
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case currentValue = "current_value"
            case updatedAt = "updated_at"
        }
    }

    private struct StatusUpdate: Codable {
        let status: String
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case status
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Computed Properties

    /// Active goals only
    var activeGoals: [PatientGoal] {
        goals.filter { $0.status == .active }
    }

    /// Completed goals only
    var completedGoals: [PatientGoal] {
        goals.filter { $0.status == .completed }
    }

    /// Average progress across all active goals (0.0 - 1.0)
    var overallProgress: Double {
        let active = activeGoals
        guard !active.isEmpty else { return 0 }
        let totalProgress = active.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(active.count)
    }

    /// Patient ID from the current Supabase session
    var patientId: String? {
        supabase.userId
    }

    // MARK: - Data Loading

    /// Fetch all goals for the given patient, ordered by created_at descending
    func loadGoals(patientId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedGoals: [PatientGoal] = try await supabase.client
                .from("patient_goals")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            goals = fetchedGoals

            #if DEBUG
            print("[PatientGoals] Loaded \(fetchedGoals.count) goals for patient \(patientId)")
            #endif
        } catch {
            errorMessage = "Failed to load goals. Please try again."
            ErrorLogger.shared.logError(error, context: "Load Patient Goals")
            #if DEBUG
            print("[PatientGoals] Error loading goals: \(error.localizedDescription)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Create Goal

    /// Save a new goal from the current form fields
    func saveGoal(patientId: UUID) async {
        // Validate title
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a goal title."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let targetValue = Double(targetValueText)
            let currentValue = Double(currentValueText)
            let goalUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
            let desc = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)

            let insertGoal = PatientGoalInsert(
                patientId: patientId,
                title: trimmedTitle,
                description: desc.isEmpty ? nil : desc,
                category: category,
                targetValue: targetValue,
                currentValue: currentValue,
                unit: goalUnit.isEmpty ? nil : goalUnit,
                targetDate: hasTargetDate ? targetDate : nil,
                status: .active
            )

            try await supabase.client
                .from("patient_goals")
                .insert(insertGoal)
                .execute()

            showingSuccessAlert = true
            resetForm()

            // Reload goals to include the new one
            await loadGoals(patientId: patientId)

            #if DEBUG
            print("[PatientGoals] Goal created: \(trimmedTitle)")
            #endif
        } catch {
            errorMessage = "Failed to save goal. Please try again."
            ErrorLogger.shared.logError(error, context: "Save Patient Goal")
            #if DEBUG
            print("[PatientGoals] Error saving goal: \(error.localizedDescription)")
            #endif
        }

        isSaving = false
    }

    // MARK: - Update Progress

    /// Update the current_value for a specific goal
    func updateProgress(goalId: UUID, newValue: Double) async {
        isSaving = true
        errorMessage = nil

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let update = ProgressUpdate(currentValue: newValue, updatedAt: now)
            try await supabase.client
                .from("patient_goals")
                .update(update)
                .eq("id", value: goalId.uuidString)
                .execute()

            // Update the local model
            if let index = goals.firstIndex(where: { $0.id == goalId }),
               let pid = patientId, let patientUUID = UUID(uuidString: pid) {
                await loadGoals(patientId: patientUUID)
            }

            #if DEBUG
            print("[PatientGoals] Progress updated for goal \(goalId): \(newValue)")
            #endif
        } catch {
            errorMessage = "Failed to update progress."
            ErrorLogger.shared.logError(error, context: "Update Goal Progress")
        }

        isSaving = false
    }

    // MARK: - Update Status

    /// Update the status of a specific goal
    func updateStatus(goalId: UUID, status: GoalStatus) async {
        isSaving = true
        errorMessage = nil

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let update = StatusUpdate(status: status.rawValue, updatedAt: now)
            try await supabase.client
                .from("patient_goals")
                .update(update)
                .eq("id", value: goalId.uuidString)
                .execute()

            // Reload to reflect changes
            if let pid = patientId, let patientUUID = UUID(uuidString: pid) {
                await loadGoals(patientId: patientUUID)
            }

            #if DEBUG
            print("[PatientGoals] Status updated for goal \(goalId): \(status.rawValue)")
            #endif
        } catch {
            errorMessage = "Failed to update goal status."
            ErrorLogger.shared.logError(error, context: "Update Goal Status")
        }

        isSaving = false
    }

    // MARK: - Delete Goal

    /// Delete a goal by its ID
    func deleteGoal(goalId: UUID) async {
        isSaving = true
        errorMessage = nil

        do {
            try await supabase.client
                .from("patient_goals")
                .delete()
                .eq("id", value: goalId.uuidString)
                .execute()

            // Remove from local array
            goals.removeAll { $0.id == goalId }

            #if DEBUG
            print("[PatientGoals] Goal deleted: \(goalId)")
            #endif
        } catch {
            errorMessage = "Failed to delete goal."
            ErrorLogger.shared.logError(error, context: "Delete Patient Goal")
        }

        isSaving = false
    }

    // MARK: - Form Management

    /// Reset all form fields to defaults
    func resetForm() {
        title = ""
        goalDescription = ""
        category = .strength
        targetValueText = ""
        currentValueText = ""
        unit = ""
        targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        hasTargetDate = false
        status = .active
    }
}
