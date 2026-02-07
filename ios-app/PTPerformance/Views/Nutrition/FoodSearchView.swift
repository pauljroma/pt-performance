//
//  FoodSearchView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Food search view
//  Updated: Added error handling UI and loading skeleton states
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
    @State private var searchError: String?

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
                searchLoadingState
            } else if let error = searchError {
                searchErrorState(error)
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

    // MARK: - Loading State

    private var searchLoadingState: some View {
        List {
            ForEach(0..<6, id: \.self) { _ in
                FoodSearchSkeletonRow()
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Error State

    private func searchErrorState(_ error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Search Failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                searchError = nil
                if !searchText.isEmpty {
                    performSearch()
                } else if let category = selectedCategory {
                    performCategorySearch(category)
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
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
            searchError = nil
            return
        }

        isSearching = true
        searchError = nil

        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Debounce
                searchResults = try await foodService.searchFoods(query: searchText)
                isSearching = false
            } catch {
                isSearching = false
                searchError = "Unable to search foods. Please check your connection and try again."
            }
        }
    }

    private func performCategorySearch(_ category: FoodCategory) {
        isSearching = true
        searchError = nil

        Task {
            do {
                searchResults = try await foodService.searchByCategory(category)
                isSearching = false
            } catch {
                isSearching = false
                searchError = "Unable to load \(category.displayName) foods. Please try again."
            }
        }
    }
}

// MARK: - Food Search Skeleton Row

struct FoodSearchSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Food name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 14)
                    .shimmer(isAnimating: isAnimating)

                // Brand skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)
                    .shimmer(isAnimating: isAnimating)

                // Serving/calories skeleton
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 10)
                        .shimmer(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 10)
                        .shimmer(isAnimating: isAnimating)
                }
            }

            Spacer()

            // Macro badges skeleton
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .shimmer(isAnimating: isAnimating)
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
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
