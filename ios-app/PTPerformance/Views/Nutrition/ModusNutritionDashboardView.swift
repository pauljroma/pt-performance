//
//  ModusNutritionDashboardView.swift
//  PTPerformance
//
//  Modus Nutrition Module - Enhanced nutrition dashboard with profile-based calculations
//  Incorporates Modus Nutrition Guidelines for athlete-specific recommendations
//

import SwiftUI

/// Enhanced nutrition dashboard with Modus guidelines integration
struct ModusNutritionDashboardView: View {
    @StateObject private var viewModel = ModusNutritionDashboardViewModel()
    @State private var showProfileSetup = false
    @State private var showPortionGuide = false
    @State private var showMealLogSheet = false
    @State private var showMealTiming = false
    @State private var selectedMealType: MealType = .lunch

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    loadingView
                } else if viewModel.profile == nil {
                    profileSetupPrompt
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showProfileSetup = true
                        } label: {
                            Label("Edit Profile", systemImage: "person.crop.circle")
                        }

                        Button {
                            showPortionGuide = true
                        } label: {
                            Label("Portion Guide", systemImage: "hand.raised")
                        }

                        Button {
                            showMealTiming = true
                        } label: {
                            Label("Meal Timing", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.loadDashboard()
            }
            .refreshable {
                HapticFeedback.light()
                await viewModel.forceRefresh()
            }
            .sheet(isPresented: $showProfileSetup) {
                NutritionProfileSetupView {
                    Task {
                        await viewModel.forceRefresh()
                    }
                }
            }
            .sheet(isPresented: $showPortionGuide) {
                PortionGuideView()
            }
            .sheet(isPresented: $showMealTiming) {
                MealTimingGuideView()
            }
            .sheet(isPresented: $showMealLogSheet) {
                NavigationStack {
                    MealLogView(mealType: selectedMealType) {
                        Task {
                            await viewModel.forceRefresh()
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading nutrition data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Profile Setup Prompt

    private var profileSetupPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Set Up Your Nutrition Profile")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get personalized calorie and macro targets based on your body, activity level, and goals using the Modus nutrition system.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showProfileSetup = true
            } label: {
                Label("Get Started", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Summary Card
                profileSummaryCard

                // Daily Targets Progress
                dailyTargetsCard

                // Athlete-Specific Tips
                athleteTipsCard

                // Quick Log Section
                quickLogSection

                // Portion Guide Quick Access
                portionGuideCard

                // Meal Timing Recommendations
                mealTimingCard
            }
            .padding()
        }
    }

    // MARK: - Profile Summary Card

    private var profileSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let profile = viewModel.profile {
                        HStack {
                            Text(profile.athleteType)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(viewModel.athleteGuidelines?.themeColor.opacity(0.2) ?? Color.blue.opacity(0.2))
                                .foregroundColor(viewModel.athleteGuidelines?.themeColor ?? .blue)
                                .cornerRadius(CornerRadius.sm)

                            Text(profile.goal.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(profile.goal.color.opacity(0.2))
                                .foregroundColor(profile.goal.color)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                    Text("Daily Target: \(viewModel.targetCalories) cal")
                        .font(.headline)
                }

                Spacer()

                Button {
                    showProfileSetup = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Edit nutrition profile")
            }

            // Macro breakdown
            HStack(spacing: 16) {
                MacroTargetPill(
                    name: "Protein",
                    grams: viewModel.macroTargets.proteinGrams,
                    color: .red
                )
                MacroTargetPill(
                    name: "Carbs",
                    grams: viewModel.macroTargets.carbsGrams,
                    color: .blue
                )
                MacroTargetPill(
                    name: "Fat",
                    grams: viewModel.macroTargets.fatGrams,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Daily Targets Card

    private var dailyTargetsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.mealsLoggedToday) meals logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Calorie Progress
            ProgressRow(
                title: "Calories",
                current: viewModel.caloriesToday,
                target: viewModel.targetCalories,
                unit: "cal",
                color: .blue
            )

            // Protein Progress
            ProgressRow(
                title: "Protein",
                current: Int(viewModel.proteinToday),
                target: viewModel.macroTargets.proteinGrams,
                unit: "g",
                color: .red
            )

            // Carbs Progress
            ProgressRow(
                title: "Carbs",
                current: Int(viewModel.carbsToday),
                target: viewModel.macroTargets.carbsGrams,
                unit: "g",
                color: .blue
            )

            // Fat Progress
            ProgressRow(
                title: "Fat",
                current: Int(viewModel.fatToday),
                target: viewModel.macroTargets.fatGrams,
                unit: "g",
                color: .yellow
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Athlete Tips Card

    private var athleteTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Athlete Tips")
                    .font(.headline)
            }

            if let guidelines = viewModel.athleteGuidelines {
                VStack(alignment: .leading, spacing: 8) {
                    TipItem(
                        icon: "fork.knife",
                        title: "Protein Target",
                        description: guidelines.proteinRangeString
                    )

                    TipItem(
                        icon: "flame.fill",
                        title: "Carb Focus",
                        description: guidelines.carbFocus.description
                    )

                    TipItem(
                        icon: "drop.fill",
                        title: "Hydration",
                        description: "Target: \(viewModel.hydrationTarget) oz/day (\(guidelines.hydrationModifier))"
                    )

                    if !guidelines.keyNutrients.isEmpty {
                        TipItem(
                            icon: "star.fill",
                            title: "Key Nutrients",
                            description: guidelines.keyNutrients.joined(separator: ", ")
                        )
                    }

                    TipItem(
                        icon: "clock.fill",
                        title: "Timing",
                        description: guidelines.timingNotes
                    )
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.md)
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

    // MARK: - Portion Guide Card

    private var portionGuideCard: some View {
        Button {
            showPortionGuide = true
        } label: {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hand-Based Portions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Palm, fist, cupped hand, thumb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meal Timing Card

    private var mealTimingCard: some View {
        Button {
            showMealTiming = true
        } label: {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Meal Timing")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Pre/post workout, competition day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

private struct MacroTargetPill: View {
    let name: String
    let grams: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(grams)g")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }
}

private struct ProgressRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var remaining: Int {
        max(0, target - current)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(current) / \(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : color)

            Text("\(remaining) \(unit) remaining")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct TipItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class ModusNutritionDashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var profile: NutritionProfile?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false

    // Nutrition data
    @Published var todaySummary: DailyNutritionSummary?
    @Published var todaysLogs: [NutritionLog] = []

    // MARK: - Private Properties

    private let profileService = NutritionProfileService.shared
    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    private var hasLoadedInitialData = false

    // MARK: - Computed Properties

    var patientId: String? {
        supabase.userId
    }

    var athleteGuidelines: AthleteTypeNutrition? {
        guard let profile = profile else { return nil }
        return profileService.getGuidelinesForAthleteType(code: profile.athleteType)
    }

    var macroTargets: MacroTargets {
        guard let profile = profile else {
            return MacroTargets(calories: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 70)
        }
        return profileService.calculateMacros(profile: profile)
    }

    var targetCalories: Int {
        macroTargets.calories
    }

    var hydrationTarget: Int {
        guard let profile = profile else { return 90 }
        return profileService.calculateHydrationOz(weightLbs: profile.weightLbs, athleteType: profile.athleteType)
    }

    var caloriesToday: Int {
        todaySummary?.totalCalories ?? 0
    }

    var proteinToday: Double {
        todaySummary?.totalProteinG ?? 0
    }

    var carbsToday: Double {
        todaySummary?.totalCarbsG ?? 0
    }

    var fatToday: Double {
        todaySummary?.totalFatG ?? 0
    }

    var mealsLoggedToday: Int {
        todaysLogs.count
    }

    // MARK: - Load Data

    func loadDashboard() async {
        guard !hasLoadedInitialData else { return }

        isLoading = true
        hasLoadedInitialData = true

        // Load profile
        do {
            profile = try await profileService.fetchProfile()
            logger.info("ModusNutritionDashboard", "Profile loaded: \(profile != nil)")
        } catch {
            logger.error("ModusNutritionDashboard", "Error loading profile: \(error.localizedDescription)")
        }

        // Load nutrition data
        guard let patientId = patientId else {
            isLoading = false
            return
        }

        do {
            todaySummary = try await nutritionService.fetchDailySummary(patientId: patientId, date: Date())
        } catch {
            logger.warning("ModusNutritionDashboard", "Daily summary error: \(error.localizedDescription)")
        }

        do {
            todaysLogs = try await nutritionService.fetchTodaysLogs(patientId: patientId)
        } catch {
            logger.warning("ModusNutritionDashboard", "Today's logs error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func forceRefresh() async {
        hasLoadedInitialData = false
        await loadDashboard()
    }
}

// MARK: - Meal Timing Guide View

struct MealTimingGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let mealTimings = NutritionGuidelinesData.mealTimings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)

                        Text("Meal Timing Guide")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Optimize nutrition around your training for best results")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(CornerRadius.lg)

                    // Timing cards
                    ForEach(mealTimings) { timing in
                        MealTimingCard(timing: timing)
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Timing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MealTimingCard: View {
    let timing: MealTiming

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: timing.icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timing.timing)
                        .font(.headline)
                    Text(timing.goal)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(timing.whatToEat)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Examples:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ForEach(timing.examples, id: \.self) { example in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.purple.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text(example)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

#Preview {
    ModusNutritionDashboardView()
}

#Preview("Meal Timing") {
    MealTimingGuideView()
}
