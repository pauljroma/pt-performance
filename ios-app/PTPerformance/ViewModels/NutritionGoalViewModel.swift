//
//  NutritionGoalViewModel.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Goals ViewModel
//

import Foundation
import SwiftUI

/// ViewModel for setting and managing nutrition goals
@MainActor
class NutritionGoalViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showError = false

    // Current Goal
    @Published var currentGoal: NutritionGoal?
    @Published var allGoals: [NutritionGoal] = []

    // Goal Form Fields
    @Published var goalType: GoalType = .daily
    @Published var targetCalories: Int = 2000
    @Published var targetProtein: Double = 150
    @Published var targetCarbs: Double = 200
    @Published var targetFat: Double = 65
    @Published var targetFiber: Double = 30
    @Published var targetWater: Int = 2500 // ml
    @Published var proteinPerKg: Double = 1.6
    @Published var notes: String = ""

    // Presets
    @Published var selectedPreset: GoalPreset?

    // MARK: - Private Properties

    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties

    var patientId: String? {
        supabase.userId
    }

    var hasActiveGoal: Bool {
        currentGoal?.active == true
    }

    var macroCalories: Int {
        let proteinCals = Int(targetProtein * 4)
        let carbsCals = Int(targetCarbs * 4)
        let fatCals = Int(targetFat * 9)
        return proteinCals + carbsCals + fatCals
    }

    var caloriesDifference: Int {
        targetCalories - macroCalories
    }

    var macrosBalanced: Bool {
        abs(caloriesDifference) < 100
    }

    var proteinPercent: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((targetProtein * 4 / Double(targetCalories)) * 100)
    }

    var carbsPercent: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((targetCarbs * 4 / Double(targetCalories)) * 100)
    }

    var fatPercent: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((targetFat * 9 / Double(targetCalories)) * 100)
    }

    // MARK: - Load Data

    func loadGoals() async {
        guard let patientId = patientId else { return }

        isLoading = true

        do {
            async let currentTask = nutritionService.fetchActiveGoal(patientId: patientId)
            async let allTask = nutritionService.fetchAllGoals(patientId: patientId)

            let (current, all) = try await (currentTask, allTask)

            currentGoal = current
            allGoals = all

            // Populate form with current goal values
            if let goal = current {
                populateForm(from: goal)
            }

            isLoading = false
        } catch {
            self.error = "Unable to load your nutrition goals. Please check your connection and try again."
            self.showError = true
            isLoading = false
        }
    }

    func populateForm(from goal: NutritionGoal) {
        goalType = goal.goalType
        targetCalories = goal.targetCalories ?? 2000
        targetProtein = goal.targetProteinG ?? 150
        targetCarbs = goal.targetCarbsG ?? 200
        targetFat = goal.targetFatG ?? 65
        targetFiber = goal.targetFiberG ?? 30
        targetWater = goal.targetWaterMl ?? 2500
        proteinPerKg = goal.proteinPerKg ?? 1.6
        notes = goal.notes ?? ""
    }

    // MARK: - Presets

    func applyPreset(_ preset: GoalPreset) {
        selectedPreset = preset
        targetCalories = preset.calories
        targetProtein = preset.protein
        targetCarbs = preset.carbs
        targetFat = preset.fat
        targetFiber = preset.fiber
    }

    func calculateFromBodyWeight(_ weightKg: Double) {
        // Calculate protein based on proteinPerKg
        targetProtein = weightKg * proteinPerKg

        // Adjust carbs and fat proportionally
        let proteinCals = targetProtein * 4
        let remainingCals = Double(targetCalories) - proteinCals

        // 55% of remaining to carbs, 45% to fat
        targetCarbs = (remainingCals * 0.55) / 4
        targetFat = (remainingCals * 0.45) / 9
    }

    // MARK: - Save Goal

    func saveGoal() async -> Bool {
        guard let patientId = patientId else {
            error = "Not logged in"
            showError = true
            return false
        }

        isSaving = true

        do {
            let dto = CreateNutritionGoalDTO(
                patientId: patientId,
                goalType: goalType.rawValue,
                targetCalories: targetCalories,
                targetProteinG: targetProtein,
                targetCarbsG: targetCarbs,
                targetFatG: targetFat,
                targetFiberG: targetFiber,
                targetWaterMl: targetWater,
                proteinPerKg: proteinPerKg,
                startDate: Date(),
                notes: notes.isEmpty ? nil : notes
            )

            let newGoal = try await nutritionService.createNutritionGoal(dto)
            currentGoal = newGoal
            allGoals.insert(newGoal, at: 0)

            isSaving = false
            return true
        } catch {
            self.error = "Unable to save your nutrition goal. Please try again."
            self.showError = true
            isSaving = false
            return false
        }
    }

    // MARK: - Update Goal

    func updateCurrentGoal() async -> Bool {
        guard let goalId = currentGoal?.id else {
            return await saveGoal() // Create new if none exists
        }

        isSaving = true

        do {
            let updates = UpdateNutritionGoalDTO(
                targetCalories: targetCalories,
                targetProteinG: targetProtein,
                targetCarbsG: targetCarbs,
                targetFatG: targetFat,
                targetFiberG: targetFiber,
                targetWaterMl: targetWater,
                active: true,
                notes: notes.isEmpty ? nil : notes
            )

            try await nutritionService.updateNutritionGoal(id: goalId, updates: updates)

            // Refresh goals
            await loadGoals()

            isSaving = false
            return true
        } catch {
            self.error = "Unable to update your goal. Please try again."
            self.showError = true
            isSaving = false
            return false
        }
    }

    // MARK: - Deactivate Goal

    func deactivateCurrentGoal() async -> Bool {
        guard let goalId = currentGoal?.id else { return false }

        do {
            let updates = UpdateNutritionGoalDTO(
                targetCalories: nil,
                targetProteinG: nil,
                targetCarbsG: nil,
                targetFatG: nil,
                targetFiberG: nil,
                targetWaterMl: nil,
                active: false,
                notes: nil
            )

            try await nutritionService.updateNutritionGoal(id: goalId, updates: updates)
            currentGoal = nil
            await loadGoals()
            return true
        } catch {
            self.error = "Unable to deactivate this goal. Please try again."
            self.showError = true
            return false
        }
    }
}

// MARK: - Goal Presets

struct GoalPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double

    static let presets: [GoalPreset] = [
        GoalPreset(
            name: "Maintenance",
            description: "Balanced macros for maintaining weight",
            calories: 2000,
            protein: 150,
            carbs: 200,
            fat: 65,
            fiber: 30
        ),
        GoalPreset(
            name: "Muscle Gain",
            description: "High protein for building muscle",
            calories: 2500,
            protein: 200,
            carbs: 250,
            fat: 70,
            fiber: 35
        ),
        GoalPreset(
            name: "Fat Loss",
            description: "Moderate deficit with high protein",
            calories: 1600,
            protein: 160,
            carbs: 120,
            fat: 55,
            fiber: 30
        ),
        GoalPreset(
            name: "Athletic Performance",
            description: "High carbs for endurance athletes",
            calories: 2800,
            protein: 175,
            carbs: 350,
            fat: 75,
            fiber: 40
        ),
        GoalPreset(
            name: "Recovery Focus",
            description: "Anti-inflammatory focus for injury recovery",
            calories: 2200,
            protein: 165,
            carbs: 220,
            fat: 75,
            fiber: 35
        )
    ]
}
