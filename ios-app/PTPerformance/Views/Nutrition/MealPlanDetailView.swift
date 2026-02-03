//
//  MealPlanDetailView.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - Meal plan detail and editing view
//

import SwiftUI

/// Detail view for viewing and editing a meal plan's meals
struct MealPlanDetailView: View {
    let plan: MealPlan
    @State private var meals: [MealPlanItem] = []
    @State private var isLoading = false
    @State private var showAddMeal = false
    @State private var selectedDay: DayOfWeek = .today
    @State private var error: String?
    @State private var showError = false

    private let mealPlanService = MealPlanService.shared
    private let logger = DebugLogger.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plan Summary Card
                planSummaryCard

                // Day Selector (for all plans to filter by day)
                daySelector

                // Meals List
                mealsSection
            }
            .padding()
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddMeal = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadMeals()
        }
        .refreshable {
            await loadMeals()
        }
        .sheet(isPresented: $showAddMeal) {
            NavigationStack {
                AddMealSheet(
                    planId: plan.id,
                    planType: plan.planType ?? .daily,
                    selectedDay: selectedDay
                ) { newMeal in
                    meals.append(newMeal)
                    meals.sort { $0.sequence < $1.sequence }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error ?? "An error occurred")
        }
    }

    // MARK: - Plan Summary Card

    private var planSummaryCard: some View {
        VStack(spacing: 16) {
            // Macros Summary
            HStack(spacing: 0) {
                MacroCircle(
                    value: totalCalories,
                    label: "Calories",
                    color: .orange
                )

                MacroCircle(
                    value: Int(totalProtein),
                    label: "Protein",
                    unit: "g",
                    color: .red
                )

                MacroCircle(
                    value: Int(totalCarbs),
                    label: "Carbs",
                    unit: "g",
                    color: .blue
                )

                MacroCircle(
                    value: Int(totalFat),
                    label: "Fat",
                    unit: "g",
                    color: .yellow
                )
            }

            // Plan Info
            if let description = plan.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Label("\(filteredMeals.count) meals", systemImage: "fork.knife")
                Spacer()
                if let type = plan.planType {
                    Label(type.displayName, systemImage: type == .daily ? "repeat" : "calendar")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    DaySelectorButton(
                        day: day,
                        isSelected: selectedDay == day,
                        mealCount: mealsForDay(day).count
                    ) {
                        selectedDay = day
                    }
                }
            }
        }
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDay.displayName)
                    .font(.headline)
                Spacer()
                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if filteredMeals.isEmpty {
                emptyMealsView
            } else {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    let mealsOfType = filteredMeals.filter { $0.mealType == mealType }
                    if !mealsOfType.isEmpty {
                        MealTypeSection(
                            mealType: mealType,
                            meals: mealsOfType,
                            onDelete: deleteMeal
                        )
                    }
                }
            }
        }
    }

    private var emptyMealsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No meals added yet")
                .font(.headline)

            Text("Tap + to add your first meal")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                showAddMeal = true
            } label: {
                Label("Add Meal", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Computed Properties

    private var filteredMeals: [MealPlanItem] {
        // Filter by selected day, but also include meals with nil dayOfWeek
        // (legacy meals created before day tracking was added)
        let today = DayOfWeek.today
        return meals.filter { meal in
            if let mealDay = meal.dayOfWeek {
                // Meal has a specific day assigned
                return mealDay == selectedDay
            } else {
                // Legacy meal with no day - show on today only
                return selectedDay == today
            }
        }
    }

    private var totalCalories: Int {
        filteredMeals.reduce(0) { $0 + $1.calculatedCalories }
    }

    private var totalProtein: Double {
        filteredMeals.reduce(0) { $0 + $1.calculatedProtein }
    }

    private var totalCarbs: Double {
        filteredMeals.reduce(0) { $0 + ($1.estimatedCarbsG ?? 0) }
    }

    private var totalFat: Double {
        filteredMeals.reduce(0) { $0 + ($1.estimatedFatG ?? 0) }
    }

    private func mealsForDay(_ day: DayOfWeek) -> [MealPlanItem] {
        let today = DayOfWeek.today
        return meals.filter { meal in
            if let mealDay = meal.dayOfWeek {
                return mealDay == day
            } else {
                // Legacy meals with no day - count them for today only
                return day == today
            }
        }
    }

    // MARK: - Data Loading

    private func loadMeals() async {
        logger.info("MEAL DETAIL", "Loading meals for plan: \(plan.id)")
        isLoading = true

        do {
            if let refreshedPlan = try await mealPlanService.fetchMealPlan(id: plan.id) {
                meals = refreshedPlan.items ?? []
                logger.success("MEAL DETAIL", "Loaded \(meals.count) meals")
            }
            isLoading = false
        } catch {
            logger.error("MEAL DETAIL", "Failed to load meals: \(error)")
            self.error = "Failed to load meals: \(error.localizedDescription)"
            self.showError = true
            isLoading = false
        }
    }

    private func deleteMeal(_ meal: MealPlanItem) {
        Task {
            do {
                try await mealPlanService.deleteMealPlanItem(id: meal.id)
                meals.removeAll { $0.id == meal.id }
                logger.success("MEAL DETAIL", "Deleted meal: \(meal.id)")
            } catch {
                logger.error("MEAL DETAIL", "Failed to delete meal: \(error)")
                self.error = "Failed to delete meal"
                self.showError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct MacroCircle: View {
    let value: Int
    let label: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                VStack(spacing: 0) {
                    Text("\(value)")
                        .font(.system(size: 16, weight: .bold))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DaySelectorButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let mealCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)

                if mealCount > 0 {
                    Text("\(mealCount)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.blue : Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
            }
            .frame(width: 50, height: 55)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct MealTypeSection: View {
    let mealType: MealType
    let meals: [MealPlanItem]
    let onDelete: (MealPlanItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(.blue)
                Text(mealType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(sectionCalories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(meals) { meal in
                MealItemCard(meal: meal, onDelete: { onDelete(meal) })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    private var sectionCalories: Int {
        meals.reduce(0) { $0 + $1.calculatedCalories }
    }
}

struct MealItemCard: View {
    let meal: MealPlanItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let recipe = meal.recipeName {
                    Text(recipe)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else if !meal.foodItems.isEmpty {
                    Text(meal.foodItems.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .lineLimit(2)
                } else {
                    Text("No items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let time = meal.displayTime {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Text("\(meal.calculatedCalories) cal")
                    Text("\(Int(meal.calculatedProtein))g protein")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}
