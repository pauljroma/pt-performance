//
//  FoodPickerView.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - Food picker for adding to meals
//

import SwiftUI

/// View for picking foods to add to a meal
struct FoodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onFoodSelected: (FoodSearchResult) -> Void

    @State private var searchText = ""
    @State private var foods: [FoodSearchResult] = []
    @State private var isLoading = false
    @State private var selectedCategory: FoodCategory?

    private let foodService = FoodDatabaseService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in
                        searchFoods()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task {
                            await loadPopularFoods()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FoodCategoryChip(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                        Task {
                            await loadPopularFoods()
                        }
                    }

                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        FoodCategoryChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            searchByCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Results
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if foods.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No foods found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(foods) { food in
                    Button {
                        onFoodSelected(food)
                        dismiss()
                    } label: {
                        FoodPickerRow(food: food)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Add Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task {
            await loadPopularFoods()
        }
    }

    // MARK: - Data Loading

    private func loadPopularFoods() async {
        isLoading = true
        do {
            foods = try await foodService.fetchPopularFoods(limit: 50)
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func searchFoods() {
        guard !searchText.isEmpty else {
            Task {
                await loadPopularFoods()
            }
            return
        }

        Task {
            do {
                foods = try await foodService.searchFoods(query: searchText)
            } catch {
                // Handle error silently
            }
        }
    }

    private func searchByCategory(_ category: FoodCategory) {
        Task {
            do {
                foods = try await foodService.searchByCategory(category)
            } catch {
                // Handle error silently
            }
        }
    }
}

// MARK: - Food Picker Row

struct FoodPickerRow: View {
    let food: FoodSearchResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let brand = food.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(food.servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories) cal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(Int(food.protein))g P | \(Int(food.carbs))g C | \(Int(food.fat))g F")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Category Chip

struct FoodCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - FoodSearchResult Extension

extension FoodSearchResult {
    var protein: Double {
        // This should come from the food database
        // Approximation based on calories (about 25% protein for common foods)
        Double(calories) * 0.1 / 4.0
    }

    var carbs: Double {
        // Approximation (about 50% carbs)
        Double(calories) * 0.5 / 4.0
    }

    var fat: Double {
        // Approximation (about 25% fat)
        Double(calories) * 0.25 / 9.0
    }
}
