//
//  NutritionRecommendationView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - AI Recommendation with today's meals context
//

import SwiftUI

/// View for AI nutrition recommendations with today's meals and plan context
struct NutritionRecommendationView: View {
    let patientId: UUID

    @State private var isLoading = false
    @State private var recommendation: String?
    @State private var errorMessage: String?
    @State private var todaysLogs: [NutritionLog] = []
    @State private var activePlan: MealPlan?
    @State private var todaysMeals: [MealPlanItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Nutrition Coach")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Get personalized nutrition recommendations based on what you've eaten and your meal plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Today's Summary Card
                todaySummaryCard

                // Recommendation Section
                if isLoading {
                    loadingCard
                } else if let recommendation = recommendation {
                    recommendationCard(recommendation)
                } else if let error = errorMessage {
                    errorCard(error)
                } else {
                    getRecommendationCard
                }

                // Today's Logged Meals
                if !todaysLogs.isEmpty {
                    todaysLogsSection
                }

                // Today's Planned Meals
                if !todaysMeals.isEmpty {
                    todaysPlannedSection
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Nutrition AI")
        .task {
            await loadTodaysData()
        }
    }

    // MARK: - Today's Summary Card

    private var todaySummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                MacroProgressRing(
                    label: "Calories",
                    consumed: totalConsumedCalories,
                    planned: totalPlannedCalories,
                    color: .orange
                )

                MacroProgressRing(
                    label: "Protein",
                    consumed: Int(totalConsumedProtein),
                    planned: Int(totalPlannedProtein),
                    color: .red,
                    unit: "g"
                )

                MacroProgressRing(
                    label: "Carbs",
                    consumed: Int(totalConsumedCarbs),
                    planned: Int(totalPlannedCarbs),
                    color: .green,
                    unit: "g"
                )

                MacroProgressRing(
                    label: "Fat",
                    consumed: Int(totalConsumedFat),
                    planned: Int(totalPlannedFat),
                    color: .purple,
                    unit: "g"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Recommendation Cards

    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing your nutrition...")
                .font(.headline)

            Text("Looking at your meals and plan to give personalized recommendations")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    private func recommendationCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("AI Recommendation")
                    .font(.headline)
                Spacer()

                Button {
                    Task {
                        await getRecommendation()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }

            Text(text)
                .font(.body)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    private func errorCard(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await getRecommendation()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    private var getRecommendationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Get AI Recommendations")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Based on what you've eaten today and your meal plan, get personalized suggestions for your next meal.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await getRecommendation()
                }
            } label: {
                Label("Get Recommendation", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Today's Logs Section

    private var todaysLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You've Eaten Today")
                .font(.headline)
                .padding(.horizontal)

            ForEach(todaysLogs) { log in
                ConsumedMealRow(log: log)
            }
        }
    }

    // MARK: - Today's Planned Section

    private var todaysPlannedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meal Plan")
                    .font(.headline)
                if let plan = activePlan {
                    Spacer()
                    Text(plan.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            ForEach(todaysMeals) { item in
                ScheduledMealRow(item: item)
            }
        }
    }

    // MARK: - Computed Properties

    private var totalConsumedCalories: Int {
        todaysLogs.compactMap { $0.totalCalories }.reduce(0, +)
    }

    private var totalConsumedProtein: Double {
        todaysLogs.compactMap { $0.totalProteinG }.reduce(0, +)
    }

    private var totalConsumedCarbs: Double {
        todaysLogs.compactMap { $0.totalCarbsG }.reduce(0, +)
    }

    private var totalConsumedFat: Double {
        todaysLogs.compactMap { $0.totalFatG }.reduce(0, +)
    }

    private var totalPlannedCalories: Int {
        todaysMeals.compactMap { $0.estimatedCalories }.reduce(0, +)
    }

    private var totalPlannedProtein: Double {
        todaysMeals.compactMap { $0.estimatedProteinG }.reduce(0, +)
    }

    private var totalPlannedCarbs: Double {
        todaysMeals.compactMap { $0.estimatedCarbsG }.reduce(0, +)
    }

    private var totalPlannedFat: Double {
        todaysMeals.compactMap { $0.estimatedFatG }.reduce(0, +)
    }

    // MARK: - Data Loading

    private func loadTodaysData() async {
        do {
            // Fetch today's logged meals
            todaysLogs = try await NutritionService.shared.fetchTodaysLogs(patientId: patientId.uuidString)

            // Fetch active meal plan and today's scheduled meals
            todaysMeals = try await MealPlanService.shared.fetchTodaysMeals(patientId: patientId.uuidString)

            // Also get the active plan for context
            activePlan = try await MealPlanService.shared.fetchActiveMealPlan(patientId: patientId.uuidString)
        } catch {
            DebugLogger.shared.warning("NutritionRecommendationView", "Failed to load nutrition data: \(error.localizedDescription)")
        }
    }

    // MARK: - AI Recommendation

    private func getRecommendation() async {
        isLoading = true
        errorMessage = nil

        do {
            // Build context message
            let context = buildNutritionContext()

            // Send to AI chat service
            let response = try await AIChatService.shared.sendMessage(context)
            recommendation = response.content

        } catch {
            errorMessage = "Failed to get recommendation: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func buildNutritionContext() -> String {
        var context = """
        I need nutrition recommendations for today. Here's my current status:

        """

        // Add consumed meals
        if !todaysLogs.isEmpty {
            context += "## What I've Eaten Today:\n"
            for log in todaysLogs {
                let mealName = log.mealType?.displayName ?? "Meal"
                context += "- \(mealName): "
                let foods = log.foodItems.map { $0.name }.joined(separator: ", ")
                context += foods.isEmpty ? "logged meal" : foods
                if let cal = log.totalCalories {
                    context += " (\(cal) cal"
                    if let protein = log.totalProteinG {
                        context += ", \(Int(protein))g protein"
                    }
                    context += ")"
                }
                context += "\n"
            }
            context += "\n"
        } else {
            context += "I haven't logged any meals yet today.\n\n"
        }

        // Add totals consumed
        context += "## Today's Totals So Far:\n"
        context += "- Calories: \(totalConsumedCalories)\n"
        context += "- Protein: \(Int(totalConsumedProtein))g\n"
        context += "- Carbs: \(Int(totalConsumedCarbs))g\n"
        context += "- Fat: \(Int(totalConsumedFat))g\n\n"

        // Add meal plan context
        if let plan = activePlan, !todaysMeals.isEmpty {
            context += "## My Meal Plan for Today (\(plan.name)):\n"
            for item in todaysMeals {
                context += "- \(item.mealType.displayName)"
                if let time = item.displayTime {
                    context += " at \(time)"
                }
                context += ": "
                let foods = item.foodItems.map { $0.name }.joined(separator: ", ")
                context += foods.isEmpty ? (item.recipeName ?? "planned meal") : foods
                if let cal = item.estimatedCalories {
                    context += " (\(cal) cal)"
                }
                context += "\n"
            }
            context += "\n"

            context += "## Planned Totals:\n"
            context += "- Calories: \(totalPlannedCalories)\n"
            context += "- Protein: \(Int(totalPlannedProtein))g\n"
            context += "- Carbs: \(Int(totalPlannedCarbs))g\n"
            context += "- Fat: \(Int(totalPlannedFat))g\n\n"

            // Calculate remaining
            let remainingCal = totalPlannedCalories - totalConsumedCalories
            let remainingProtein = totalPlannedProtein - totalConsumedProtein
            context += "## What I Still Need Today:\n"
            context += "- Calories: \(remainingCal)\n"
            context += "- Protein: \(Int(remainingProtein))g\n\n"
        }

        context += """
        Based on this information, please give me:
        1. A brief assessment of my nutrition so far today
        2. Specific recommendations for my next meal to help me meet my goals
        3. Any adjustments I should consider for the rest of the day

        Keep the response concise and actionable.
        """

        return context
    }
}

// MARK: - Supporting Views

private struct MacroProgressRing: View {
    let label: String
    let consumed: Int
    let planned: Int
    let color: Color
    var unit: String = ""

    private var progress: Double {
        guard planned > 0 else { return 0 }
        return min(Double(consumed) / Double(planned), 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(consumed)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(width: 44, height: 44)

            if planned > 0 {
                Text("/\(planned)\(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct ConsumedMealRow: View {
    let log: NutritionLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: log.mealType?.icon ?? "fork.knife")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.mealType?.displayName ?? "Meal")
                    .font(.subheadline)
                    .fontWeight(.medium)

                let foods = log.foodItems.prefix(3).map { $0.name }.joined(separator: ", ")
                if !foods.isEmpty {
                    Text(foods)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let cal = log.totalCalories {
                    Text("\(cal) cal")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Text(log.loggedAt, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct ScheduledMealRow: View {
    let item: MealPlanItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.mealType.icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.mealType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let recipe = item.recipeName {
                    Text(recipe)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    let foods = item.foodItems.prefix(3).map { $0.name }.joined(separator: ", ")
                    if !foods.isEmpty {
                        Text(foods)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if let cal = item.estimatedCalories {
                    Text("\(cal) cal planned")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            if let time = item.displayTime {
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NutritionRecommendationView(patientId: UUID())
    }
}
