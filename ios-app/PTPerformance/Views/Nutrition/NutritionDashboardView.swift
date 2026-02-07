//
//  NutritionDashboardView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Main dashboard view
//

import SwiftUI

/// Main nutrition dashboard showing daily progress, goals, and quick actions
struct NutritionDashboardView: View {
    @StateObject private var viewModel = NutritionDashboardViewModel()
    @State private var showMealLogSheet = false
    @State private var selectedMealType: MealType = .lunch
    @State private var showAIRecommendation = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.todaySummary == nil {
                loadingView
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showGoalSheet = true
                } label: {
                    Image(systemName: "target")
                }
                .accessibilityLabel("Nutrition Goals")
                .accessibilityHint("Opens nutrition goal settings")
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .refreshable {
            HapticFeedback.light()
            // BUILD 279: Use forceRefresh for pull-to-refresh
            await viewModel.forceRefresh()
        }
        .sheet(isPresented: $showMealLogSheet) {
            NavigationStack {
                MealLogView(mealType: selectedMealType) {
                    Task {
                        await viewModel.refreshAfterLogAdded()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showGoalSheet) {
            NavigationStack {
                NutritionGoalView()
            }
        }
        .sheet(isPresented: $showAIRecommendation) {
            NavigationStack {
                if let patientId = UUID(uuidString: PTSupabaseClient.shared.userId ?? "") {
                    NutritionRecommendationView(patientId: patientId)
                } else {
                    Text("Please log in to use AI recommendations")
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        NutritionDashboardLoadingView()
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Progress Card
                todayProgressCard

                // AI Meal Suggestion Card
                aiSuggestionCard

                // Macro Distribution
                macroDistributionCard

                // Quick Log Buttons
                quickLogSection

                // Today's Meals
                todaysMealsSection

                // Weekly Trend
                weeklyTrendSection
            }
            .padding()
        }
    }

    // MARK: - Today's Progress

    private var todayProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if viewModel.hasLoggedToday {
                    Text("\(viewModel.mealsLoggedToday) meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Calorie Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Calories")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.caloriesToday) / \(viewModel.calorieGoal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: viewModel.calorieProgress)
                    .tint(viewModel.calorieProgress >= 1.0 ? .green : .blue)
                    .accessibilityLabel("Calorie progress")
                    .accessibilityValue("\(Int(viewModel.calorieProgress * 100)) percent")

                Text("\(viewModel.remainingCalories) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Calories: \(viewModel.caloriesToday) of \(viewModel.calorieGoal), \(viewModel.remainingCalories) remaining")

            // Protein Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Protein")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(viewModel.proteinToday))g / \(Int(viewModel.proteinGoal))g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: viewModel.proteinProgress)
                    .tint(viewModel.proteinProgress >= 1.0 ? .green : .orange)
                    .accessibilityLabel("Protein progress")
                    .accessibilityValue("\(Int(viewModel.proteinProgress * 100)) percent")

                Text("\(Int(viewModel.remainingProtein))g remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Protein: \(Int(viewModel.proteinToday)) grams of \(Int(viewModel.proteinGoal)) grams, \(Int(viewModel.remainingProtein)) grams remaining")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - AI Suggestion Card

    private var aiSuggestionCard: some View {
        Button {
            showAIRecommendation = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Meal Suggestion")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get personalized recommendations based on your goals and today's meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("AI Meal Suggestion")
        .accessibilityHint("Get personalized meal recommendations based on your goals")
    }

    // MARK: - Macro Distribution

    private var macroDistributionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Macros")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            HStack(spacing: 20) {
                ForEach(viewModel.macroChartData) { data in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(macroColor(for: data.macro))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(Int(data.percent))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )

                        Text(data.macro.displayName)
                            .font(.caption)

                        Text("\(Int(data.grams))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(data.macro.displayName): \(Int(data.grams)) grams, \(Int(data.percent)) percent of total")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    private func macroColor(for macro: MacroType) -> Color {
        switch macro {
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .yellow
        }
    }

    // MARK: - Quick Log Section

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        QuickLogButton(mealType: mealType) {
                            selectedMealType = mealType
                            showMealLogSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Meals

    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                Spacer()
                let totalCount = viewModel.todaysLogs.count + viewModel.todaysPlannedMeals.count
                if totalCount > 0 {
                    Text("\(viewModel.todaysLogs.count) logged, \(viewModel.todaysPlannedMeals.count) planned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // BUILD 244: Show planned meals from meal plan
            if !viewModel.todaysPlannedMeals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Planned")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    ForEach(viewModel.todaysPlannedMeals) { meal in
                        PlannedMealRow(meal: meal)
                    }
                }

                if !viewModel.todaysLogs.isEmpty {
                    Divider()
                }
            }

            // Logged meals
            if !viewModel.todaysLogs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !viewModel.todaysPlannedMeals.isEmpty {
                        Text("Logged")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    ForEach(viewModel.todaysLogs) { log in
                        MealLogRow(log: log) {
                            Task {
                                await viewModel.deleteLog(log)
                            }
                        }
                    }
                }
            }

            // Empty state
            if viewModel.todaysLogs.isEmpty && viewModel.todaysPlannedMeals.isEmpty {
                NutritionEmptyMealsView {
                    selectedMealType = .breakfast
                    showMealLogSheet = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Weekly Trend

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.headline)

            if viewModel.weeklyTrends.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.weeklyTrends) { trend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(trend.weekStart, style: .date)
                                .font(.subheadline)
                            Text("\(trend.daysLogged) days logged")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(Int(trend.avgDailyCalories)) cal/day")
                                .font(.subheadline)
                            Text("\(Int(trend.avgDailyProteinG))g protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let mealType: MealType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mealType.icon)
                    .font(.title2)
                Text(mealType.displayName)
                    .font(.caption)
            }
            .frame(width: 80, height: 70)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(mealType.displayName)")
        .accessibilityHint("Opens meal logging form for \(mealType.displayName.lowercased())")
    }
}

// MARK: - Planned Meal Row (BUILD 244)

struct PlannedMealRow: View {
    let meal: MealPlanItem

    private var accessibilityDescription: String {
        var description = "Planned \(meal.mealType.displayName)"
        if let time = meal.mealTime {
            description += " at \(time)"
        }
        if let recipeName = meal.recipeName {
            description += ", \(recipeName)"
        }
        if let cal = meal.estimatedCalories {
            description += ", \(cal) calories"
        }
        if let protein = meal.estimatedProteinG {
            description += ", \(Int(protein)) grams protein"
        }
        return description
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: meal.mealType.icon)
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let time = meal.mealTime {
                        Spacer()
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let recipeName = meal.recipeName {
                    Text(recipeName)
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                HStack(spacing: 8) {
                    if let cal = meal.estimatedCalories {
                        Text("\(cal) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let protein = meal.estimatedProteinG {
                        Text("P: \(Int(protein))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !meal.foodItems.isEmpty {
                    Text(meal.foodItems.map { $0.name }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "calendar")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.5))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Meal Log Row

struct MealLogRow: View {
    let log: NutritionLog
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let mealType = log.mealType {
                        Image(systemName: mealType.icon)
                            .foregroundColor(.green)
                            .accessibilityHidden(true)
                        Text(mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Text(log.loggedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(log.totalCalories ?? 0) cal | P: \(Int(log.totalProteinG ?? 0))g")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !log.foodItems.isEmpty {
                    Text(log.foodItems.map { $0.name }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(log.mealType?.displayName ?? "Meal"), \(log.totalCalories ?? 0) calories, \(Int(log.totalProteinG ?? 0)) grams protein")

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .accessibilityLabel("Delete meal")
            .accessibilityHint("Removes this meal from your log")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State for Meals Section

struct NutritionEmptyMealsView: View {
    let onLogMeal: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Meals Logged Today", systemImage: "fork.knife.circle")
        } description: {
            Text("Track your nutrition by logging meals throughout the day to monitor your calorie and macro intake.")
        } actions: {
            Button {
                onLogMeal()
            } label: {
                Label("Log Your First Meal", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        NutritionDashboardView()
    }
}
