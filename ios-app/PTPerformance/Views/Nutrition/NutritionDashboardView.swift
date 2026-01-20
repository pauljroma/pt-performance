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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Progress Card
                todayProgressCard

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
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showGoalSheet = true
                } label: {
                    Image(systemName: "target")
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .refreshable {
            await viewModel.loadDashboard()
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
    }

    // MARK: - Today's Progress

    private var todayProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
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

                Text("\(viewModel.remainingCalories) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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

                Text("\(Int(viewModel.remainingProtein))g remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Macro Distribution

    private var macroDistributionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Macros")
                    .font(.headline)
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
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
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
                if !viewModel.todaysLogs.isEmpty {
                    Text("\(viewModel.todaysLogs.count) logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.todaysLogs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No meals logged yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(viewModel.todaysLogs) { log in
                    MealLogRow(log: log) {
                        Task {
                            await viewModel.deleteLog(log)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
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
        .shadow(color: .black.opacity(0.05), radius: 5)
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
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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
                            .foregroundColor(.blue)
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

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        NutritionDashboardView()
    }
}
