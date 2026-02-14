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
                    HapticFeedback.light()
                    if servings > 0.25 {
                        servings -= 0.25
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(servings > 0.25 ? .blue : .gray)
                }
                .disabled(servings <= 0.25)
                .accessibilityLabel("Decrease servings")

                // Current value
                Text(String(format: "%.2f", servings))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .frame(minWidth: 120)

                // Increment
                Button {
                    HapticFeedback.light()
                    servings += 0.25
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Increase servings")
            }

            // Quick select buttons
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { value in
                    Button {
                        HapticFeedback.light()
                        servings = value
                    } label: {
                        Text("\(value, specifier: "%.1f")")
                            .font(.subheadline)
                            .fontWeight(servings == value ? .bold : .medium)
                            .foregroundColor(servings == value ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(servings == value ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                    }
                }
            }

            // Portion size presets (ACP-1019)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Common Portions")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.xs)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        PortionPresetButton(
                            label: "1 cup",
                            servings: 1.0,
                            currentServings: $servings
                        )
                        PortionPresetButton(
                            label: "1/2 cup",
                            servings: 0.5,
                            currentServings: $servings
                        )
                        PortionPresetButton(
                            label: "1 tbsp",
                            servings: 0.25,
                            currentServings: $servings
                        )
                        PortionPresetButton(
                            label: "100g",
                            servings: 1.0,
                            currentServings: $servings
                        )
                        PortionPresetButton(
                            label: "1 oz",
                            servings: 0.35,
                            currentServings: $servings
                        )
                    }
                }
            }

        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
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
                FoodMacroCircle(
                    title: "Protein",
                    value: totalProtein,
                    color: .red
                )

                FoodMacroCircle(
                    title: "Carbs",
                    value: totalCarbs,
                    color: .blue
                )

                FoodMacroCircle(
                    title: "Fat",
                    value: totalFat,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
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
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Food Macro Circle

struct FoodMacroCircle: View {
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

// MARK: - Portion Preset Button (ACP-1019)

/// Button for quick portion size selection
struct PortionPresetButton: View {
    let label: String
    let servings: Double
    @Binding var currentServings: Double

    var body: some View {
        Button {
            HapticFeedback.light()
            currentServings = servings
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(currentServings == servings ? .white : .blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(currentServings == servings ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel("\(label) portion")
    }
}
