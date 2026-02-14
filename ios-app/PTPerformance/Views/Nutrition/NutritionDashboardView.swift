//
//  NutritionDashboardView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Main dashboard view
//  ACP-1018: Visual upgrade with circular progress rings, improved cards, and animations
//

import SwiftUI

/// Main nutrition dashboard showing daily progress, goals, and quick actions
struct NutritionDashboardView: View {
    @StateObject private var viewModel = NutritionDashboardViewModel()
    @State private var showMealLogSheet = false
    @State private var selectedMealType: MealType = .lunch
    @State private var showAIRecommendation = false
    @State private var selectedPeriod: NutritionViewPeriod = .daily
    @State private var isContentVisible = false
    @State private var showCalorieGoalCelebration = false
    @State private var showProteinGoalCelebration = false

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
        .overlay {
            if showCalorieGoalCelebration {
                NutritionGoalCelebration(goalType: "Calorie", isShowing: $showCalorieGoalCelebration)
            }
            if showProteinGoalCelebration {
                NutritionGoalCelebration(goalType: "Protein", isShowing: $showProteinGoalCelebration)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.standard).delay(0.1)) {
                isContentVisible = true
            }
        }
        .onChange(of: viewModel.calorieProgress) { oldValue, newValue in
            // Trigger celebration when calorie goal is first met
            if newValue >= 1.0 && oldValue < 1.0 {
                showCalorieGoalCelebration = true
            }
        }
        .onChange(of: viewModel.proteinProgress) { oldValue, newValue in
            // Trigger celebration when protein goal is first met
            if newValue >= 1.0 && oldValue < 1.0 {
                showProteinGoalCelebration = true
            }
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
            VStack(spacing: Spacing.lg) {
                // View period toggle
                NutritionViewPeriodToggle(selectedPeriod: $selectedPeriod)
                    .staggeredAppearance(index: 0, isVisible: isContentVisible)

                NutritionAnimatedContainer(period: selectedPeriod) {
                    switch selectedPeriod {
                    case .daily:
                        dailyContentView
                    case .weekly:
                        weeklyContentView
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Daily Content View

    private var dailyContentView: some View {
        VStack(spacing: Spacing.lg) {
            // Today's Progress Card with circular rings
            enhancedProgressCard
                .staggeredAppearance(index: 1, isVisible: isContentVisible)

            // Calorie Surplus/Deficit Indicator (ACP-1018)
            CalorieSurplusDeficitIndicator(
                currentCalories: viewModel.caloriesToday,
                targetCalories: viewModel.calorieGoal
            )
            .staggeredAppearance(index: 2, isVisible: isContentVisible)

            // AI Meal Suggestion Card
            aiSuggestionCard
                .staggeredAppearance(index: 3, isVisible: isContentVisible)

            // Macro Distribution with rings
            enhancedMacroCard
                .staggeredAppearance(index: 4, isVisible: isContentVisible)

            // Protein Timing Chart (ACP-1018: Protein timing visualization)
            if !viewModel.todaysLogs.isEmpty {
                ProteinTimingChart(
                    logs: viewModel.todaysLogs,
                    proteinGoal: viewModel.proteinGoal
                )
                .staggeredAppearance(index: 5, isVisible: isContentVisible)
            }

            // Meal Timeline (ACP-1018: Meal-by-meal breakdown)
            MealTimelineView(
                logs: viewModel.todaysLogs,
                plannedMeals: viewModel.todaysPlannedMeals,
                onDelete: { log in
                    Task {
                        await viewModel.deleteLog(log)
                    }
                }
            )
            .staggeredAppearance(index: 6, isVisible: isContentVisible)

            // Quick Log Buttons
            quickLogSection
                .staggeredAppearance(index: 7, isVisible: isContentVisible)

            // Today's Meals (Legacy - kept for backwards compatibility)
            todaysMealsSection
                .staggeredAppearance(index: 8, isVisible: isContentVisible)
        }
    }

    // MARK: - Weekly Content View

    private var weeklyContentView: some View {
        VStack(spacing: Spacing.lg) {
            // Weekly Chart
            WeeklyNutritionChart(
                trends: viewModel.weeklyTrends,
                calorieGoal: viewModel.calorieGoal
            )
            .staggeredAppearance(index: 1, isVisible: isContentVisible)

            // Weekly Summary Cards
            weeklyTrendSection
                .staggeredAppearance(index: 2, isVisible: isContentVisible)
        }
    }

    // MARK: - Enhanced Progress Card (ACP-1018)

    private var enhancedProgressCard: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if viewModel.hasLoggedToday {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(viewModel.mealsLoggedToday) meals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Large calorie progress ring
            HStack(spacing: Spacing.lg) {
                CalorieProgressRing(
                    currentCalories: viewModel.caloriesToday,
                    targetCalories: viewModel.calorieGoal,
                    size: 120
                )

                // Quick stats
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    NutritionStatRow(
                        icon: "flame.fill",
                        label: "Calories",
                        value: "\(viewModel.caloriesToday)",
                        target: "\(viewModel.calorieGoal)",
                        color: .orange,
                        progress: viewModel.calorieProgress
                    )

                    NutritionStatRow(
                        icon: "p.circle.fill",
                        label: "Protein",
                        value: "\(Int(viewModel.proteinToday))g",
                        target: "\(Int(viewModel.proteinGoal))g",
                        color: .red,
                        progress: viewModel.proteinProgress
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Legacy Today's Progress (kept for reference)

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
        .cornerRadius(CornerRadius.md)
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
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("AI Meal Suggestion")
        .accessibilityHint("Get personalized meal recommendations based on your goals")
    }

    // MARK: - Enhanced Macro Distribution (ACP-1018)

    private var enhancedMacroCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Macros")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()

                // Goal indicator
                if viewModel.proteinProgress >= 1.0 && viewModel.calorieProgress >= 1.0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("On track!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            // Triple macro progress rings
            TripleMacroRingsView(
                proteinCurrent: viewModel.proteinToday,
                proteinTarget: viewModel.proteinGoal,
                carbsCurrent: viewModel.carbsToday,
                carbsTarget: viewModel.activeGoal?.targetCarbsG ?? 200,
                fatCurrent: viewModel.fatToday,
                fatTarget: viewModel.activeGoal?.targetFatG ?? 65
            )
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Legacy Macro Distribution

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
        .cornerRadius(CornerRadius.md)
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Log")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        EnhancedQuickLogButton(mealType: mealType) {
                            selectedMealType = mealType
                            showMealLogSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Meals (Enhanced - ACP-1018)

    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                let totalCount = viewModel.todaysLogs.count + viewModel.todaysPlannedMeals.count
                if totalCount > 0 {
                    HStack(spacing: Spacing.xs) {
                        if viewModel.todaysLogs.count > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("\(viewModel.todaysLogs.count)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        if viewModel.todaysPlannedMeals.count > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("\(viewModel.todaysPlannedMeals.count)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }

            // Planned meals from meal plan
            if !viewModel.todaysPlannedMeals.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(viewModel.todaysPlannedMeals) { meal in
                        EnhancedPlannedMealCard(meal: meal)
                    }
                }
            }

            // Logged meals with enhanced cards
            if !viewModel.todaysLogs.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(viewModel.todaysLogs) { log in
                        EnhancedMealCard(log: log) {
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
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Weekly Trend (Enhanced - ACP-1018)

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Weekly Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.weeklyTrends.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Log meals to see your weekly trends")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                ForEach(viewModel.weeklyTrends) { trend in
                    WeekTrendCard(trend: trend, calorieGoal: viewModel.calorieGoal)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Nutrition Stat Row Component (ACP-1018)

struct NutritionStatRow: View {
    let icon: String
    let label: String
    let value: String
    let target: String
    let color: Color
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: Spacing.xxs) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(target)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(progress >= 1.0 ? Color.green : color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Week Trend Card (ACP-1018)

struct WeekTrendCard: View {
    let trend: WeeklyNutritionTrend
    let calorieGoal: Int

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return trend.avgDailyCalories / Double(calorieGoal)
    }

    private var isOnTrack: Bool {
        calorieProgress >= 0.85 && calorieProgress <= 1.15
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Week indicator
            VStack(spacing: 2) {
                Text(weekDayAbbrev)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Text("\(trend.daysLogged)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color(.tertiarySystemBackground))
            )

            // Stats
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(formatDateRange(trend.weekStart))
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Text("\(Int(trend.avgDailyCalories))")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("cal/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Text("P:")
                            .font(.caption)
                            .foregroundColor(.red)

                        Text("\(Int(trend.avgDailyProteinG))g")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            Spacer()

            // Status badge
            if isOnTrack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else if calorieProgress < 0.85 {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private static let monthAbbrevFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var weekDayAbbrev: String {
        Self.monthAbbrevFormatter.string(from: trend.weekStart)
    }

    private func formatDateRange(_ startDate: Date) -> String {
        let start = Self.monthDayFormatter.string(from: startDate)

        if let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) {
            let end = Self.monthDayFormatter.string(from: endDate)
            return "\(start) - \(end)"
        }
        return start
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
            .cornerRadius(CornerRadius.md)
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
        EmptyStateView(
            title: "No Meals Logged Today",
            message: "Track your nutrition by logging meals throughout the day to monitor your calorie and macro intake.",
            icon: "fork.knife.circle",
            iconColor: .orange,
            action: EmptyStateView.EmptyStateAction(
                title: "Log Your First Meal",
                icon: "plus.circle.fill",
                action: onLogMeal
            )
        )
        .padding(.vertical, Spacing.md)
    }
}

#Preview {
    NavigationStack {
        NutritionDashboardView()
    }
}
