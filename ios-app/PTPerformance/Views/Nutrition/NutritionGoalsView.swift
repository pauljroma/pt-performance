//
//  NutritionGoalsView.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - Set daily nutrition goals
//

import SwiftUI

/// View for setting daily nutrition goals
struct NutritionGoalsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calorieGoal: String = "2000"
    @State private var proteinGoal: String = "150"
    @State private var carbsGoal: String = "200"
    @State private var fatGoal: String = "70"
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var error: String?
    @State private var showError = false

    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            Form {
                // Calorie Goal
                Section {
                    HStack {
                        Text("Daily Calories")
                        Spacer()
                        TextField("2000", text: $calorieGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Calorie Goal")
                } footer: {
                    Text("Recommended: 1500-3000 calories depending on your goals and activity level")
                }

                // Macro Goals
                Section {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("Protein")
                        Spacer()
                        TextField("150", text: $proteinGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Circle()
                            .fill(Color.modusCyan)
                            .frame(width: 12, height: 12)
                        Text("Carbohydrates")
                        Spacer()
                        TextField("200", text: $carbsGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 12, height: 12)
                        Text("Fat")
                        Spacer()
                        TextField("70", text: $fatGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Macro Goals")
                } footer: {
                    let calculatedCals = calculatedCalories
                    if calculatedCals > 0 {
                        Text("Macros total: \(calculatedCals) calories (\(Int(proteinValue))g × 4 + \(Int(carbsValue))g × 4 + \(Int(fatValue))g × 9)")
                    }
                }

                // Presets
                Section("Quick Presets") {
                    Button {
                        applyPreset(.maintenance)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Maintenance")
                                    .foregroundColor(.primary)
                                Text("2000 cal | 150g P | 200g C | 70g F")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Button {
                        applyPreset(.muscleGain)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Muscle Gain")
                                    .foregroundColor(.primary)
                                Text("2500 cal | 180g P | 280g C | 80g F")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Button {
                        applyPreset(.fatLoss)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Fat Loss")
                                    .foregroundColor(.primary)
                                Text("1600 cal | 160g P | 120g C | 55g F")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Button {
                        applyPreset(.highProtein)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("High Protein")
                                    .foregroundColor(.primary)
                                Text("2200 cal | 200g P | 180g C | 70g F")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveGoals()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .task {
                await loadCurrentGoals()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error ?? "An error occurred")
            }
        }
    }

    // MARK: - Computed Properties

    private var proteinValue: Double {
        Double(proteinGoal) ?? 0
    }

    private var carbsValue: Double {
        Double(carbsGoal) ?? 0
    }

    private var fatValue: Double {
        Double(fatGoal) ?? 0
    }

    private var calculatedCalories: Int {
        Int(proteinValue * 4 + carbsValue * 4 + fatValue * 9)
    }

    // MARK: - Presets

    private enum GoalPreset {
        case maintenance
        case muscleGain
        case fatLoss
        case highProtein
    }

    private func applyPreset(_ preset: GoalPreset) {
        switch preset {
        case .maintenance:
            calorieGoal = "2000"
            proteinGoal = "150"
            carbsGoal = "200"
            fatGoal = "70"
        case .muscleGain:
            calorieGoal = "2500"
            proteinGoal = "180"
            carbsGoal = "280"
            fatGoal = "80"
        case .fatLoss:
            calorieGoal = "1600"
            proteinGoal = "160"
            carbsGoal = "120"
            fatGoal = "55"
        case .highProtein:
            calorieGoal = "2200"
            proteinGoal = "200"
            carbsGoal = "180"
            fatGoal = "70"
        }
    }

    // MARK: - Data Loading

    private func loadCurrentGoals() async {
        guard let patientId = supabase.userId else { return }

        do {
            if let goal = try await nutritionService.fetchActiveGoal(patientId: patientId) {
                calorieGoal = "\(goal.targetCalories ?? 2000)"
                proteinGoal = "\(Int(goal.targetProteinG ?? 150))"
                carbsGoal = "\(Int(goal.targetCarbsG ?? 200))"
                fatGoal = "\(Int(goal.targetFatG ?? 70))"
            }
            isLoading = false
        } catch {
            logger.error("GOALS", "Failed to load goals: \(error)")
            isLoading = false
        }
    }

    private func saveGoals() async {
        guard let patientId = supabase.userId else {
            error = "Not logged in"
            showError = true
            return
        }

        logger.info("GOALS", "Saving nutrition goals")
        isSaving = true

        do {
            let goalDTO = CreateNutritionGoalDTO(
                patientId: patientId,
                goalType: "daily",
                targetCalories: Int(calorieGoal) ?? 2000,
                targetProteinG: Double(proteinGoal) ?? 150,
                targetCarbsG: Double(carbsGoal) ?? 200,
                targetFatG: Double(fatGoal) ?? 70,
                targetFiberG: nil,
                targetWaterMl: nil,
                proteinPerKg: nil,
                startDate: Date(),
                notes: nil
            )
            _ = try await nutritionService.createNutritionGoal(goalDTO)

            logger.success("GOALS", "Goals saved successfully")
            isSaving = false
            dismiss()
        } catch {
            logger.error("GOALS", "Failed to save goals: \(error)")
            self.error = "Failed to save goals: \(error.localizedDescription)"
            self.showError = true
            isSaving = false
        }
    }
}
