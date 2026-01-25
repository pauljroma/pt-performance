//
//  MealPlanView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal plan view
//

import SwiftUI

/// View for displaying and managing meal plans
struct MealPlanView: View {
    @State private var mealPlans: [MealPlan] = []
    @State private var activePlan: MealPlan?
    @State private var todaysMeals: [MealPlanItem] = []
    @State private var isLoading = false
    @State private var selectedDay: DayOfWeek = .today
    @State private var showCreatePlanSheet = false
    @State private var error: String?
    @State private var showError = false

    // BUILD 279: Prevent duplicate fetches when switching tabs
    @State private var hasLoadedInitialData = false

    private let mealPlanService = MealPlanService.shared
    private let supabase = PTSupabaseClient.shared

    init() {
        DebugLogger.shared.info("MEAL PLAN VIEW", "MealPlanView initialized")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active Plan Header
                if let plan = activePlan {
                    activePlanHeader(plan)
                } else {
                    noPlanView
                }

                // Day Selector (for weekly plans)
                if activePlan?.planType == .weekly {
                    daySelector
                }

                // Today's/Selected Day's Meals
                mealsSection

                // All Plans List
                allPlansSection
            }
            .padding()
        }
        .navigationTitle("Meal Plans")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreatePlanSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadData()
        }
        .refreshable {
            // BUILD 279: Force refresh for pull-to-refresh
            hasLoadedInitialData = false
            await loadData()
        }
        .sheet(isPresented: $showCreatePlanSheet) {
            NavigationStack {
                CreateMealPlanView { newPlan in
                    mealPlans.insert(newPlan, at: 0)
                    if newPlan.isActive {
                        activePlan = newPlan
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error ?? "An error occurred")
        }
    }

    // MARK: - Active Plan Header

    private func activePlanHeader(_ plan: MealPlan) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if let type = plan.planType {
                    Text(type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }

            if let description = plan.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Plan stats
            HStack(spacing: 20) {
                PlanStat(value: "\(plan.items?.count ?? 0)", label: "Meals")
                PlanStat(value: "\(plan.totalCalories)", label: "Total Cal")
                PlanStat(value: "\(Int(plan.totalProtein))g", label: "Protein")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - No Plan View

    private var noPlanView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Active Meal Plan")
                .font(.headline)

            Text("Create a meal plan to organize your nutrition")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreatePlanSheet = true
            } label: {
                Label("Create Plan", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Button {
                        selectedDay = day
                        loadMealsForDay(day)
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.shortName)
                                .font(.caption)
                                .fontWeight(selectedDay == day ? .bold : .regular)

                            Circle()
                                .fill(selectedDay == day ? Color.blue : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 44, height: 50)
                        .background(selectedDay == day ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(activePlan?.planType == .weekly ? selectedDay.displayName : "Today's Meals")
                    .font(.headline)
                Spacer()
            }

            if todaysMeals.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("No meals planned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                ForEach(todaysMeals) { meal in
                    MealPlanItemRow(item: meal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - All Plans Section

    private var allPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Meal Plans")
                .font(.headline)

            if mealPlans.isEmpty {
                Text("No meal plans created yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(mealPlans) { plan in
                    NavigationLink(destination: MealPlanDetailView(plan: plan)) {
                        MealPlanRowWithActivate(
                            plan: plan,
                            isActive: plan.id == activePlan?.id
                        ) {
                            Task {
                                await activatePlan(plan)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        // BUILD 279: Prevent duplicate fetches when switching tabs
        guard !hasLoadedInitialData else {
            DebugLogger.shared.info("MEAL PLAN VIEW", "Skipping reload - data already loaded")
            return
        }

        DebugLogger.shared.info("MEAL PLAN VIEW", "loadData() called")

        guard let patientId = supabase.userId else {
            DebugLogger.shared.error("MEAL PLAN VIEW", "No patient ID - user not logged in")
            return
        }

        DebugLogger.shared.info("MEAL PLAN VIEW", "Loading data for patient: \(patientId)")

        isLoading = true
        hasLoadedInitialData = true  // Mark as loaded to prevent future duplicate calls

        do {
            async let plansTask = mealPlanService.fetchMealPlans(patientId: patientId, includeInactive: true)
            async let activeTask = mealPlanService.fetchActiveMealPlan(patientId: patientId)
            async let todaysTask = mealPlanService.fetchTodaysMeals(patientId: patientId)

            let (plans, active, todays) = try await (plansTask, activeTask, todaysTask)

            mealPlans = plans
            activePlan = active
            todaysMeals = todays

            DebugLogger.shared.success("MEAL PLAN VIEW", "Loaded \(plans.count) plans, active: \(active?.name ?? "none"), today's meals: \(todays.count)")

            isLoading = false
        } catch {
            DebugLogger.shared.error("MEAL PLAN VIEW", "Error loading data: \(error)")
            self.error = "Failed to load meal plans: \(error.localizedDescription)"
            self.showError = true
            isLoading = false
        }
    }

    private func loadMealsForDay(_ day: DayOfWeek) {
        guard let planId = activePlan?.id else { return }

        Task {
            do {
                todaysMeals = try await mealPlanService.fetchMealsForDay(planId: planId, day: day)
            } catch {
                self.error = "Failed to load meals: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }

    private func activatePlan(_ plan: MealPlan) async {
        guard let patientId = supabase.userId else { return }

        do {
            try await mealPlanService.activateMealPlan(id: plan.id, patientId: patientId)
            activePlan = plan
            await loadData()
        } catch {
            self.error = "Failed to activate plan: \(error.localizedDescription)"
            self.showError = true
        }
    }
}

// MARK: - Plan Stat

struct PlanStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Plan Row with Activate

struct MealPlanRowWithActivate: View {
    let plan: MealPlan
    let isActive: Bool
    let onActivate: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isActive {
                        Text("Active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }

                HStack {
                    Text("\(plan.items?.count ?? 0) meals")
                    if plan.totalCalories > 0 {
                        Text("•")
                        Text("\(plan.totalCalories) cal")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !isActive {
                Button("Activate") {
                    onActivate()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Meal Plan Item Row

struct MealPlanItemRow: View {
    let item: MealPlanItem

    var body: some View {
        HStack {
            Image(systemName: item.mealType.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.mealType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let time = item.displayTime {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let recipe = item.recipeName {
                    Text(recipe)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(item.calculatedCalories) cal | \(Int(item.calculatedProtein))g protein")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        MealPlanView()
    }
}
