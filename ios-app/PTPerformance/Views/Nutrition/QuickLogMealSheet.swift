//
//  QuickLogMealSheet.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - Quick meal logging without a plan
//

import SwiftUI

/// Sheet for quickly logging a meal without a meal plan
struct QuickLogMealSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mealType: MealType = .lunch
    @State private var selectedFoods: [FoodSelectionItem] = []
    @State private var showFoodPicker = false
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var showError = false

    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            Form {
                // Meal Type
                Section("What are you logging?") {
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Food Items
                Section {
                    if selectedFoods.isEmpty {
                        Button {
                            showFoodPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Add Food")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        ForEach($selectedFoods) { $food in
                            FoodSelectionRow(food: $food) {
                                selectedFoods.removeAll { $0.id == food.id }
                            }
                        }

                        Button {
                            showFoodPicker = true
                        } label: {
                            Label("Add More", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Food Items")
                } footer: {
                    if !selectedFoods.isEmpty {
                        Text("Total: \(totalCalories) cal | \(Int(totalProtein))g protein")
                    }
                }

                // Notes
                Section("Notes (Optional)") {
                    TextField("How did you feel?", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Summary
                if !selectedFoods.isEmpty {
                    Section("Totals") {
                        HStack {
                            MacroSummaryItem(value: totalCalories, label: "Calories", color: .orange)
                            MacroSummaryItem(value: Int(totalProtein), label: "Protein", unit: "g", color: .red)
                            MacroSummaryItem(value: Int(totalCarbs), label: "Carbs", unit: "g", color: .blue)
                            MacroSummaryItem(value: Int(totalFat), label: "Fat", unit: "g", color: .yellow)
                        }
                    }
                }
            }
            .navigationTitle("Log Meal")
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
                            await saveMealLog()
                        }
                    }
                    .disabled(selectedFoods.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showFoodPicker) {
                NavigationStack {
                    FoodPickerView { food in
                        selectedFoods.append(FoodSelectionItem(
                            id: UUID(),
                            foodId: food.id,
                            name: food.name,
                            brand: food.brand,
                            servings: 1.0,
                            caloriesPerServing: food.calories,
                            proteinPerServing: food.protein,
                            carbsPerServing: food.carbs,
                            fatPerServing: food.fat,
                            servingSize: food.servingSize
                        ))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error ?? "An error occurred")
            }
        }
    }

    // MARK: - Computed Properties

    private var totalCalories: Int {
        selectedFoods.reduce(0) { $0 + Int(Double($1.caloriesPerServing) * $1.servings) }
    }

    private var totalProtein: Double {
        selectedFoods.reduce(0) { $0 + ($1.proteinPerServing * $1.servings) }
    }

    private var totalCarbs: Double {
        selectedFoods.reduce(0) { $0 + ($1.carbsPerServing * $1.servings) }
    }

    private var totalFat: Double {
        selectedFoods.reduce(0) { $0 + ($1.fatPerServing * $1.servings) }
    }

    // MARK: - Save

    private func saveMealLog() async {
        guard let patientId = supabase.userId else {
            error = "Not logged in"
            showError = true
            return
        }

        logger.info("QUICK LOG", "Saving meal log: \(mealType.rawValue) with \(selectedFoods.count) items")
        isSaving = true

        // Convert to LoggedFoodItems
        let foodItems = selectedFoods.map { food in
            LoggedFoodItem(
                foodItemId: food.foodId,
                name: food.name,
                servings: food.servings,
                servingSize: food.servingSize,
                calories: food.caloriesPerServing,
                proteinG: food.proteinPerServing,
                carbsG: food.carbsPerServing,
                fatG: food.fatPerServing
            )
        }

        do {
            let logDTO = CreateNutritionLogDTO(
                patientId: patientId,
                loggedAt: Date(),
                mealType: mealType.rawValue,
                foodItems: foodItems,
                totalCalories: totalCalories,
                totalProteinG: totalProtein,
                totalCarbsG: totalCarbs,
                totalFatG: totalFat,
                totalFiberG: nil,
                notes: notes.isEmpty ? nil : notes,
                photoUrl: nil
            )
            _ = try await nutritionService.createNutritionLog(logDTO)

            logger.success("QUICK LOG", "Meal logged successfully")
            isSaving = false
            dismiss()
        } catch {
            logger.error("QUICK LOG", "Failed to log meal: \(error)")
            self.error = "Failed to log meal: \(error.localizedDescription)"
            self.showError = true
            isSaving = false
        }
    }
}
