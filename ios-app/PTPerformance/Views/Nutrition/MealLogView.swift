//
//  MealLogView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal logging view
//

import SwiftUI

/// View for logging a meal with food items
struct MealLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MealLogViewModel
    let onSaved: () -> Void

    init(mealType: MealType = .lunch, onSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: MealLogViewModel(mealType: mealType))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            // Meal Type Picker
            mealTypePicker

            // Search Bar
            searchBar

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Selected Foods
                    if !viewModel.foodItems.isEmpty {
                        selectedFoodsSection
                    }

                    // Search Results or Suggestions
                    if !viewModel.searchText.isEmpty {
                        searchResultsSection
                    } else {
                        suggestionsSection
                    }
                }
                .padding()
            }

            // Bottom Summary & Save
            if !viewModel.foodItems.isEmpty {
                bottomSummaryBar
            }
        }
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .sheet(isPresented: $viewModel.showFoodDetailSheet) {
            if let food = viewModel.selectedFood {
                FoodDetailSheet(food: food) { updatedFood in
                    viewModel.updateServings(for: food, servings: updatedFood.servings)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddCustomFoodSheet) {
            NavigationStack {
                AddCustomFoodView { food in
                    Task {
                        _ = await viewModel.addCustomFood(food)
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

    // MARK: - Meal Type Picker

    private var mealTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Button {
                        viewModel.mealType = type
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(viewModel.mealType == type ? Color.blue : Color(.systemGray5))
                        .foregroundColor(viewModel.mealType == type ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search foods...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchText) {
                    viewModel.searchFoods()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Button {
                viewModel.showAddCustomFoodSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Selected Foods Section

    private var selectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Foods")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.foodItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.foodItems) { item in
                SelectedFoodRow(item: item) {
                    viewModel.editFood(item)
                } onRemove: {
                    viewModel.removeFood(item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                Spacer()
                if viewModel.isSearching {
                    ProgressView()
                }
            }

            if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                Text("No foods found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.searchResults) { food in
                    FoodSearchRow(food: food) {
                        viewModel.addFood(food)
                    }
                }
            }
        }
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(spacing: 20) {
            // Recent Foods
            if !viewModel.recentFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent")
                        .font(.headline)

                    ForEach(viewModel.recentFoods.prefix(5)) { food in
                        FoodSearchRow(food: food) {
                            viewModel.addFood(food)
                        }
                    }
                }
            }

            // Popular Foods
            if !viewModel.popularFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular")
                        .font(.headline)

                    ForEach(viewModel.popularFoods.prefix(10)) { food in
                        FoodSearchRow(food: food) {
                            viewModel.addFood(food)
                        }
                    }
                }
            }

            // Category Buttons
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse by Category")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        Button {
                            Task {
                                await viewModel.searchByCategory(category)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                Text(category.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Summary Bar

    private var bottomSummaryBar: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalCalories) cal")
                        .font(.headline)
                    Text(viewModel.macroSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        if await viewModel.saveMealLog() {
                            onSaved()
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Log Meal")
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSaving || !viewModel.canSave)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Selected Food Row

struct SelectedFoodRow: View {
    let item: LoggedFoodItem
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(item.servings, specifier: "%.1f") serving • \(item.totalCalories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Food Search Row

struct FoodSearchRow: View {
    let food: FoodSearchResult
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if food.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }

                if let brand = food.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(food.servingSize) • \(food.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        MealLogView(mealType: .lunch) {
            print("Saved")
        }
    }
}
