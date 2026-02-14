//
//  FoodLoggingInputView.swift
//  PTPerformance
//
//  ACP-1018: Visual upgrade - Polished food logging input UI
//

import SwiftUI

// MARK: - Enhanced Search Bar

/// Polished search bar for food logging with improved visual feedback
struct EnhancedFoodSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onAddCustomFood: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showClearButton = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Search icon with animation
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .modusCyan : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            // Text field
            TextField("Search foods...", text: $searchText)
                .font(.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()

            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        searchText = ""
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Loading indicator
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
                    .transition(.scale.combined(with: .opacity))
            }

            // Divider
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 24)

            // Add custom food button
            Button {
                onAddCustomFood()
                HapticFeedback.medium()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Add custom food")
            .accessibilityHint("Opens form to add a new custom food")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(isFocused ? Color.modusCyan.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
    }
}

// MARK: - EnhancedFoodSearchRow defined in MealLogView.swift (ACP-1017/1019)

// MARK: - Selected Food Item Row

/// Enhanced row for displaying selected food items with serving adjustment
struct EnhancedSelectedFoodRow: View {
    let item: LoggedFoodItem
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Food info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    // Servings pill
                    Text("\(item.servings, specifier: "%.1f") serving")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.modusCyan.opacity(0.15))
                        )

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("\(item.totalCalories) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Edit button
            Button {
                onEdit()
                HapticFeedback.light()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundColor(.modusCyan)
                    .padding(Spacing.xs)
                    .background(
                        Circle()
                            .fill(Color.modusCyan.opacity(0.1))
                    )
            }
            .accessibilityLabel("Edit serving size")

            // Remove button
            Button {
                onRemove()
                HapticFeedback.warning()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .padding(Spacing.xs)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .accessibilityLabel("Remove food")
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Meal Summary Bar

/// Bottom bar showing meal summary and save action
struct EnhancedMealSummaryBar: View {
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let isSaving: Bool
    let canSave: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(.separator).opacity(0), Color(.separator), Color(.separator).opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: Spacing.md) {
                // Macro summary
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(totalCalories) calories")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.sm) {
                        MacroSummaryPill(value: Int(totalProtein), label: "P", color: .red)
                        MacroSummaryPill(value: Int(totalCarbs), label: "C", color: .modusCyan)
                        MacroSummaryPill(value: Int(totalFat), label: "F", color: .yellow)
                    }
                }

                Spacer()

                // Save button
                Button {
                    onSave()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                        }

                        Text("Log Meal")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(canSave ? Color.modusCyan : Color.gray)
                    )
                }
                .disabled(isSaving || !canSave)
                .accessibilityLabel("Log meal")
                .accessibilityHint(canSave ? "Saves the meal to your food log" : "Add foods to enable logging")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Macro Summary Pill

struct MacroSummaryPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text("\(value)g")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Food Category Quick Filter

/// Quick filter chips for food categories
struct EnhancedFoodCategoryFilter: View {
    @Binding var selectedCategory: FoodCategory?
    let onCategorySelected: (FoodCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All category
                EnhancedCategoryChip(
                    label: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(FoodCategory.allCases, id: \.self) { category in
                    EnhancedCategoryChip(
                        label: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        onCategorySelected(category)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Enhanced Category Chip

struct EnhancedCategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct FoodLoggingInputView_Previews: PreviewProvider {
    struct PreviewContainer: View {
        @State private var searchText = ""
        @State private var isSearching = false

        var body: some View {
            VStack(spacing: Spacing.md) {
                EnhancedFoodSearchBar(
                    searchText: $searchText,
                    isSearching: $isSearching,
                    onAddCustomFood: {}
                )

                EnhancedFoodSearchRow(
                    food: FoodSearchResult(
                        name: "Grilled Chicken Breast",
                        brand: "Generic",
                        servingSize: "4 oz (113g)",
                        calories: 187,
                        proteinG: 35,
                        carbsG: 0,
                        fatG: 4,
                        category: "protein",
                        isVerified: true
                    ),
                    isFavorite: false,
                    onAdd: {},
                    onToggleFavorite: {}
                )

                EnhancedMealSummaryBar(
                    totalCalories: 650,
                    totalProtein: 45,
                    totalCarbs: 55,
                    totalFat: 22,
                    isSaving: false,
                    canSave: true,
                    onSave: {}
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }

    static var previews: some View {
        PreviewContainer()
    }
}
#endif
