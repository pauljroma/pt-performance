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
                .foregroundColor(isFocused ? .blue : .secondary)
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
                    .foregroundColor(.blue)
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
                        .strokeBorder(isFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
    }
}

// MARK: - Enhanced Food Search Result Row

/// Polished food search result row with improved visual hierarchy
struct EnhancedFoodSearchRow: View {
    let food: FoodSearchResult
    let onAdd: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Food icon/category indicator
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(categoryColor)
            }

            // Food details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

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
                        .lineLimit(1)
                }

                // Serving and calorie info
                HStack(spacing: Spacing.xs) {
                    Text(food.servingSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))

                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)

                        Text("\(food.calories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if food.proteinG > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("\(Int(food.proteinG))g P")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }

            Spacer()

            // Add button
            Button {
                onAdd()
                HapticFeedback.light()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.systemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(food.name), \(food.servingSize), \(food.calories) calories")
        .accessibilityHint("Double tap to add to meal")
    }

    private var categoryColor: Color {
        guard let categoryString = food.category,
              let category = FoodCategory(rawValue: categoryString) else {
            return .gray
        }
        switch category {
        case .protein: return .red
        case .grain: return .brown
        case .vegetable: return .green
        case .fruit: return .orange
        case .dairy: return .blue
        case .fat: return .yellow
        case .beverage: return .cyan
        case .snack: return .pink
        case .supplement: return .purple
        case .condiment: return .gray
        }
    }

    private var categoryIcon: String {
        guard let categoryString = food.category,
              let category = FoodCategory(rawValue: categoryString) else {
            return "fork.knife"
        }
        return category.icon
    }
}

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
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
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
                    .foregroundColor(.blue)
                    .padding(Spacing.xs)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
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
                        MacroSummaryPill(value: Int(totalCarbs), label: "C", color: .blue)
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
                            .fill(canSave ? Color.blue : Color.gray)
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
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemGroupedBackground))
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
                    onAdd: {}
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
