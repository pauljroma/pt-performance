//
//  FoodSearchView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Food search view
//

import SwiftUI

/// Dedicated view for searching and selecting food items
struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var selectedCategory: FoodCategory?
    @State private var showAddCustomFood = false

    private let foodService = FoodDatabaseService.shared
    let onFoodSelected: (FoodSearchResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar

            // Category Filter
            categoryFilter

            // Results
            if isSearching {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .navigationTitle("Search Foods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCustomFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCustomFood) {
            NavigationStack {
                AddCustomFoodView { food in
                    // Convert to search result and select
                    let result = FoodSearchResult(
                        id: UUID(),
                        name: food.name,
                        brand: food.brand,
                        servingSize: food.servingSize,
                        calories: food.calories,
                        proteinG: food.proteinG,
                        carbsG: food.carbsG,
                        fatG: food.fatG,
                        category: food.category,
                        isVerified: false
                    )
                    onFoodSelected(result)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, _ in
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories button
                Button {
                    selectedCategory = nil
                    performSearch()
                } label: {
                    Text("All")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.blue : Color(.tertiarySystemGroupedBackground))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(16)
                }

                ForEach(FoodCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        performCategorySearch(category)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? Color.blue : Color(.tertiarySystemGroupedBackground))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: "No Foods Found",
            message: "No foods match your search. Try a different term or create a custom food entry with your own nutritional values.",
            icon: "takeoutbag.and.cup.and.straw",
            iconColor: .orange,
            action: EmptyStateView.EmptyStateAction(
                title: "Add Custom Food",
                icon: "plus.circle.fill",
                action: { showAddCustomFood = true }
            )
        )
    }

    // MARK: - Results List

    private var resultsList: some View {
        List(searchResults) { food in
            Button {
                onFoodSelected(food)
                dismiss()
            } label: {
                FoodSearchResultRow(food: food)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - Search Functions

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Debounce
                searchResults = try await foodService.searchFoods(query: searchText)
                isSearching = false
            } catch {
                isSearching = false
            }
        }
    }

    private func performCategorySearch(_ category: FoodCategory) {
        isSearching = true

        Task {
            do {
                searchResults = try await foodService.searchByCategory(category)
                isSearching = false
            } catch {
                isSearching = false
            }
        }
    }
}

// MARK: - Food Search Result Row

struct FoodSearchResultRow: View {
    let food: FoodSearchResult

    var body: some View {
        HStack {
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

                HStack(spacing: 8) {
                    Text(food.servingSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(food.calories) cal")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Macro badges
            HStack(spacing: 4) {
                MacroBadge(value: Int(food.proteinG), label: "P", color: .red)
                MacroBadge(value: Int(food.carbsG), label: "C", color: .blue)
                MacroBadge(value: Int(food.fatG), label: "F", color: .yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Macro Badge

struct MacroBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text("\(value)")
                .font(.caption2)
                .fontWeight(.bold)
            Text(label)
                .font(.system(size: 8))
        }
        .frame(width: 28, height: 28)
        .background(color.opacity(0.2))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        FoodSearchView { food in
            print("Selected: \(food.name)")
        }
    }
}
