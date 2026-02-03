//
//  TemplateFilterTabs.swift
//  PTPerformance
//
//  Reusable filter components: search bar, category chips, and tab buttons
//

import SwiftUI

// MARK: - Template Search Bar

struct TemplateSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search templates...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Template Category Filters

struct TemplateCategoryFilters: View {
    @Binding var selectedCategory: WorkoutTemplateLibraryViewModel.TemplateCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories chip
                TemplateCategoryChip(
                    title: "All",
                    icon: "list.bullet",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }

                ForEach(WorkoutTemplateLibraryViewModel.TemplateCategory.allCases, id: \.self) { category in
                    TemplateCategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Template Category Chip

struct TemplateCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(8)
        }
        .padding(4)
    }
}

// MARK: - Template Tab Picker

struct TemplateTabPicker: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "My Workouts",
                icon: "heart.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation { selectedTab = 0 }
            }

            TabButton(
                title: "PT/Trainer",
                icon: "person.badge.shield.checkmark.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation { selectedTab = 1 }
            }

            TabButton(
                title: "Library",
                icon: "building.2.fill",
                isSelected: selectedTab == 2
            ) {
                withAnimation { selectedTab = 2 }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
