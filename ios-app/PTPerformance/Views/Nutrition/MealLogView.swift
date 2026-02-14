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
            Button("Try Again") {
                Task {
                    if await viewModel.saveMealLog() {
                        onSaved()
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
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
                        HapticFeedback.light()
                        viewModel.mealType = type
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(viewModel.mealType == type ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
                        .foregroundColor(viewModel.mealType == type ? .white : .primary)
                        .cornerRadius(CornerRadius.xl)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.xs)
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
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.searchFoods()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    HapticFeedback.light()
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityHint("Clears the current search text")
            }

            Button {
                viewModel.showAddCustomFoodSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Add custom food")
            .accessibilityHint("Opens the form to add a new custom food item")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
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
                .id(item.id)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
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
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(.secondary)

                    Text("No Foods Found")
                        .font(.headline)

                    Text("Try a different search term or add a custom food using the + button above.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                ForEach(viewModel.searchResults) { food in
                    FoodSearchRow(food: food) {
                        viewModel.addFood(food)
                    }
                    .id(food.id)
                }
            }
        }
    }

    // MARK: - Suggestions Section (ACP-1017: Enhanced)

    private var suggestionsSection: some View {
        VStack(spacing: 20) {
            // Copy Yesterday's Meals (ACP-1017)
            if !viewModel.yesterdaysMeals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Yesterday's Meals")
                            .font(.headline)
                        Spacer()
                        Button {
                            HapticFeedback.medium()
                            viewModel.copyYesterdaysMeals()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copy All")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.modusCyan)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(Color.modusCyan.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                        }
                        .accessibilityLabel("Copy all meals from yesterday")
                    }

                    ForEach(viewModel.yesterdaysMeals.prefix(3)) { log in
                        YesterdayMealCard(log: log) {
                            for item in log.foodItems {
                                viewModel.foodItems.append(item)
                            }
                        }
                    }
                }
            }

            // Favorites (ACP-1017: One-tap favorites)
            if !viewModel.favoriteFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("Favorites")
                            .font(.headline)
                    }

                    ForEach(viewModel.favoriteFoods.prefix(5)) { food in
                        EnhancedFoodSearchRow(food: food, isFavorite: true) {
                            viewModel.addFood(food)
                        } onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(food)
                            }
                        }
                    }
                }
            }

            // Time of Day Suggestions (ACP-1017: Smart suggestions based on time of day)
            if !viewModel.timeOfDayFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: viewModel.mealType.icon)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                        Text("Common for \(viewModel.mealType.displayName)")
                            .font(.headline)
                    }

                    ForEach(viewModel.timeOfDayFoods.prefix(5)) { food in
                        EnhancedFoodSearchRow(food: food, isFavorite: viewModel.isFavorite(food)) {
                            viewModel.addFood(food)
                        } onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(food)
                            }
                        }
                    }
                }
            }

            // Recent Foods
            if !viewModel.recentFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent")
                        .font(.headline)

                    ForEach(viewModel.recentFoods.prefix(5)) { food in
                        EnhancedFoodSearchRow(food: food, isFavorite: viewModel.isFavorite(food)) {
                            viewModel.addFood(food)
                        } onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(food)
                            }
                        }
                    }
                }
            }

            // Popular Foods
            if !viewModel.popularFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular")
                        .font(.headline)

                    ForEach(viewModel.popularFoods.prefix(8)) { food in
                        EnhancedFoodSearchRow(food: food, isFavorite: viewModel.isFavorite(food)) {
                            viewModel.addFood(food)
                        } onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(food)
                            }
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
                            .padding(.vertical, Spacing.sm)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.sm)
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
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .disabled(viewModel.isSaving || !viewModel.canSave)
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.xs)
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
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Edit food")
            .accessibilityHint("Edit serving size for this food item")

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .accessibilityLabel("Remove food")
            .accessibilityHint("Removes this food item from the meal")
        }
        .padding(.vertical, Spacing.xs)
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
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Add food")
            .accessibilityHint("Adds this food to your meal")
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Enhanced Food Search Row (ACP-1017, ACP-1019)

struct EnhancedFoodSearchRow: View {
    let food: FoodSearchResult
    let isFavorite: Bool
    let onAdd: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if food.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }

                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Macro preview inline (ACP-1019: Show macro preview in search results)
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(food.calories)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("P:")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(Int(food.proteinG))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("C:")
                            .font(.caption2)
                            .foregroundColor(.modusCyan)
                        Text("\(Int(food.carbsG))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("F:")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(Int(food.fatG))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }

                Text(food.servingSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                // Favorite button (ACP-1017: One-tap favorites)
                Button {
                    HapticFeedback.light()
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                        .padding(Spacing.xs)
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")

                // Add button (ACP-1019: Quick-add without opening detail)
                Button {
                    HapticFeedback.medium()
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Add food")
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Yesterday Meal Card (ACP-1017)

struct YesterdayMealCard: View {
    let log: NutritionLog
    let onCopy: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let mealType = log.mealType {
                    HStack(spacing: 4) {
                        Image(systemName: mealType.icon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
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

            Spacer()

            Button {
                HapticFeedback.light()
                onCopy()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.modusCyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.modusCyan.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
            .accessibilityLabel("Add this meal")
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        MealLogView(mealType: .lunch) {
            print("Saved")
        }
    }
}
