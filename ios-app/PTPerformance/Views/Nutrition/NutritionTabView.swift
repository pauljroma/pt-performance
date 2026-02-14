//
//  NutritionTabView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Main tab view for nutrition features
//

import SwiftUI

/// Main entry point for the Nutrition tab
struct NutritionTabView: View {
    @State private var selectedSection: NutritionSection = .dashboard
    @State private var showLogMeal = false
    @State private var showSetGoals = false
    @State private var showHistory = false

    init() {
        DebugLogger.shared.info("NUTRITION TAB", "NutritionTabView initialized")
    }

    var body: some View {
        let _ = DebugLogger.shared.info("NUTRITION TAB", "Rendering body, section: \(selectedSection.title)")
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                sectionPicker

                // Content based on selection
                Group {
                    switch selectedSection {
                    case .dashboard:
                        NutritionDashboardView()
                    case .mealPlans:
                        MealPlanView()
                    case .foods:
                        FoodLibraryView()
                    }
                }
            }
            .navigationTitle(selectedSection.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showLogMeal = true
                        } label: {
                            Label("Log Meal", systemImage: "plus.circle")
                        }

                        Button {
                            showSetGoals = true
                        } label: {
                            Label("Set Goals", systemImage: "target")
                        }

                        Button {
                            showHistory = true
                        } label: {
                            Label("View History", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showLogMeal) {
                QuickLogMealSheet()
            }
            .sheet(isPresented: $showSetGoals) {
                NutritionGoalsView()
            }
            .sheet(isPresented: $showHistory) {
                NutritionHistoryView()
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(NutritionSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.title3)
                        Text(section.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedSection == section ? Color.modusCyan.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedSection == section ? .modusCyan : .secondary)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
}

// MARK: - Nutrition Section Enum

enum NutritionSection: String, CaseIterable {
    case dashboard
    case mealPlans
    case foods

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .mealPlans: return "Meal Plans"
        case .foods: return "Foods"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie"
        case .mealPlans: return "calendar"
        case .foods: return "leaf"
        }
    }
}

// MARK: - Food Library View

struct FoodLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var foods: [FoodSearchResult] = []
    @State private var userFoods: [FoodItem] = []
    @State private var isLoading = false
    @State private var showAddCustomFood = false

    // BUILD 279: Prevent duplicate fetches when switching tabs
    @State private var hasLoadedInitialData = false

    private let foodService = FoodDatabaseService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, _ in
                        searchFoods()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        foods = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Text("All")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            .cornerRadius(CornerRadius.lg)
                    }

                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            searchByCategory(category)
                        } label: {
                            Text(category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(CornerRadius.lg)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Results
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List {
                    // User's custom foods section
                    if !userFoods.isEmpty && searchText.isEmpty && selectedCategory == nil {
                        Section("My Foods") {
                            ForEach(userFoods) { food in
                                FoodLibraryRow(name: food.name, brand: food.brand, calories: food.calories, servingSize: food.servingSize)
                            }
                        }
                    }

                    // Search results or popular foods
                    Section(searchText.isEmpty ? "Popular Foods" : "Results") {
                        ForEach(foods) { food in
                            FoodLibraryRow(name: food.name, brand: food.brand, calories: food.calories, servingSize: food.servingSize)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCustomFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showAddCustomFood) {
            NavigationStack {
                AddCustomFoodView { _ in
                    // Refresh user foods
                    Task {
                        await loadUserFoods()
                    }
                }
            }
        }
    }

    private func loadInitialData() async {
        // BUILD 279: Prevent duplicate fetches when switching tabs
        guard !hasLoadedInitialData else { return }

        isLoading = true
        hasLoadedInitialData = true

        do {
            async let popularTask = foodService.fetchPopularFoods(limit: 50)
            async let userTask = foodService.fetchUserFoods()

            let (popular, user) = try await (popularTask, userTask)

            foods = popular
            userFoods = user
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func loadUserFoods() async {
        do {
            userFoods = try await foodService.fetchUserFoods()
        } catch {
            // Handle error silently
        }
    }

    private func searchFoods() {
        guard !searchText.isEmpty else {
            Task {
                foods = try await foodService.fetchPopularFoods(limit: 50)
            }
            return
        }

        Task {
            do {
                foods = try await foodService.searchFoods(query: searchText)
            } catch {
                // Handle error
            }
        }
    }

    private func searchByCategory(_ category: FoodCategory) {
        Task {
            do {
                foods = try await foodService.searchByCategory(category)
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Food Library Row

struct FoodLibraryRow: View {
    let name: String
    let brand: String?
    let calories: Int
    let servingSize: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let brand = brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(calories) cal")
                    .font(.subheadline)
                Text(servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NutritionTabView()
}
