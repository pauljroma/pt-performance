//
//  FoodDetailSheet.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Food detail and serving editor
//

import SwiftUI

/// Sheet for viewing food details and adjusting servings
struct FoodDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let food: LoggedFoodItem
    @State private var servings: Double
    let onUpdate: (LoggedFoodItem) -> Void

    init(food: LoggedFoodItem, onUpdate: @escaping (LoggedFoodItem) -> Void) {
        self.food = food
        self._servings = State(initialValue: food.servings)
        self.onUpdate = onUpdate
    }

    // Calculated values based on servings
    private var totalCalories: Int {
        Int(Double(food.calories) * servings)
    }

    private var totalProtein: Double {
        food.proteinG * servings
    }

    private var totalCarbs: Double {
        food.carbsG * servings
    }

    private var totalFat: Double {
        food.fatG * servings
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Food Header
                    headerSection

                    // Serving Adjuster
                    servingSection

                    // Nutrition Summary
                    nutritionSummary

                    // Detailed Nutrition
                    detailedNutrition
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        var updated = food
                        updated.servings = servings
                        onUpdate(updated)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(food.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let servingSize = food.servingSize {
                Text("Serving: \(servingSize)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Serving Adjuster

    private var servingSection: some View {
        VStack(spacing: 16) {
            Text("Number of Servings")
                .font(.headline)

            HStack(spacing: 20) {
                // Decrement
                Button {
                    if servings > 0.25 {
                        servings -= 0.25
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(servings > 0.25 ? .blue : .gray)
                }
                .disabled(servings <= 0.25)

                // Current value
                Text(String(format: "%.2f", servings))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .frame(minWidth: 120)

                // Increment
                Button {
                    servings += 0.25
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }

            // Quick select buttons
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { value in
                    Button {
                        servings = value
                    } label: {
                        Text(value == 1.0 ? "1" : String(format: "%.1f", value))
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(servings == value ? Color.blue : Color(.systemGray5))
                            .foregroundColor(servings == value ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Nutrition Summary

    private var nutritionSummary: some View {
        VStack(spacing: 16) {
            // Calories
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Calories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(totalCalories)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("kcal")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Macros
            HStack(spacing: 20) {
                MacroCircle(
                    title: "Protein",
                    value: totalProtein,
                    color: .red
                )

                MacroCircle(
                    title: "Carbs",
                    value: totalCarbs,
                    color: .blue
                )

                MacroCircle(
                    title: "Fat",
                    value: totalFat,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Detailed Nutrition

    private var detailedNutrition: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition per serving")
                .font(.headline)

            Group {
                NutritionRow(label: "Calories", value: "\(food.calories)", unit: "kcal")
                NutritionRow(label: "Protein", value: String(format: "%.1f", food.proteinG), unit: "g")
                NutritionRow(label: "Carbohydrates", value: String(format: "%.1f", food.carbsG), unit: "g")
                NutritionRow(label: "Fat", value: String(format: "%.1f", food.fatG), unit: "g")

                if let fiber = food.fiberG, fiber > 0 {
                    NutritionRow(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Macro Circle

struct MacroCircle: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Text("\(Int(value))g")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nutrition Row

struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(value) \(unit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FoodDetailSheet(
        food: LoggedFoodItem(
            name: "Chicken Breast",
            servings: 1.0,
            servingSize: "100g",
            calories: 165,
            proteinG: 31,
            carbsG: 0,
            fatG: 3.6
        )
    ) { updated in
        print("Updated servings: \(updated.servings)")
    }
}
