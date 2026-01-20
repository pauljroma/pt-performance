//
//  AddMealSheet.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - Add meal to plan sheet
//

import SwiftUI

/// Sheet for adding a meal to a meal plan
struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss

    let planId: UUID
    let planType: MealPlanType
    let selectedDay: DayOfWeek
    let onMealAdded: (MealPlanItem) -> Void

    @State private var mealType: MealType = .breakfast
    @State private var mealTime = Date()
    @State private var recipeName = ""
    @State private var notes = ""
    @State private var selectedFoods: [FoodSelectionItem] = []
    @State private var showFoodPicker = false
    @State private var isSaving = false
    @State private var error: String?
    @State private var showError = false

    private let mealPlanService = MealPlanService.shared
    private let logger = DebugLogger.shared

    var body: some View {
        Form {
            // Meal Type
            Section("Meal Type") {
                Picker("Type", selection: $mealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)

                DatePicker("Time", selection: $mealTime, displayedComponents: .hourAndMinute)
            }

            // Recipe Name (Optional)
            Section("Recipe (Optional)") {
                TextField("Recipe name", text: $recipeName)
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
                            Text("Add Food Items")
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
                    Text("Total: \(totalCalories) cal | \(Int(totalProtein))g protein | \(Int(totalCarbs))g carbs | \(Int(totalFat))g fat")
                }
            }

            // Notes
            Section("Notes (Optional)") {
                TextField("Add notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Summary
            if !selectedFoods.isEmpty {
                Section("Summary") {
                    HStack {
                        MacroSummaryItem(value: totalCalories, label: "Calories", color: .orange)
                        MacroSummaryItem(value: Int(totalProtein), label: "Protein", unit: "g", color: .red)
                        MacroSummaryItem(value: Int(totalCarbs), label: "Carbs", unit: "g", color: .blue)
                        MacroSummaryItem(value: Int(totalFat), label: "Fat", unit: "g", color: .yellow)
                    }
                }
            }
        }
        .navigationTitle("Add Meal")
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
                        await saveMeal()
                    }
                }
                .disabled(isSaving)
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

    private func saveMeal() async {
        logger.info("ADD MEAL", "Saving meal: \(mealType.rawValue) with \(selectedFoods.count) items")
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

        // Format time as HH:mm
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: mealTime)

        let dto = CreateMealPlanItemDTO(
            mealPlanId: planId.uuidString,
            dayOfWeek: planType == .weekly ? selectedDay.rawValue : nil,
            mealType: mealType.rawValue,
            mealTime: timeString,
            foodItems: foodItems,
            recipeName: recipeName.isEmpty ? nil : recipeName,
            recipeInstructions: nil,
            estimatedCalories: totalCalories,
            estimatedProteinG: totalProtein,
            estimatedCarbsG: totalCarbs,
            estimatedFatG: totalFat,
            notes: notes.isEmpty ? nil : notes,
            sequence: mealType.defaultSequence
        )

        do {
            let newMeal = try await mealPlanService.addMealToPlan(dto)
            logger.success("ADD MEAL", "Created meal: \(newMeal.id)")
            isSaving = false
            onMealAdded(newMeal)
            dismiss()
        } catch {
            logger.error("ADD MEAL", "Failed to save meal: \(error)")
            self.error = "Failed to save meal: \(error.localizedDescription)"
            self.showError = true
            isSaving = false
        }
    }
}

// MARK: - Food Selection Item

struct FoodSelectionItem: Identifiable {
    let id: UUID
    let foodId: UUID?
    let name: String
    let brand: String?
    var servings: Double
    let caloriesPerServing: Int
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let servingSize: String
}

// MARK: - Food Selection Row

struct FoodSelectionRow: View {
    @Binding var food: FoodSelectionItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                if let brand = food.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(Int(Double(food.caloriesPerServing) * food.servings)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if food.servings > 0.5 {
                        food.servings -= 0.5
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)

                Text(String(format: "%.1f", food.servings))
                    .frame(width: 40)

                Button {
                    food.servings += 0.5
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
    }
}

// MARK: - Macro Summary Item

struct MacroSummaryItem: View {
    let value: Int
    let label: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(unit)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MealType Extension

extension MealType {
    var defaultSequence: Int {
        switch self {
        case .breakfast: return 0
        case .snack: return 1
        case .lunch: return 2
        case .dinner: return 4
        case .preWorkout: return 3
        case .postWorkout: return 5
        }
    }
}
