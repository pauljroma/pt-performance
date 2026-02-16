//
//  EnhancedMealCard.swift
//  PTPerformance
//
//  ACP-1018: Visual upgrade - Improved meal card designs with better typography
//

import SwiftUI

// MARK: - Enhanced Meal Card

/// Polished meal card with improved typography, iconography, and animations
struct EnhancedMealCard: View {
    let log: NutritionLog
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Meal type icon with colored background
            mealTypeIcon

            // Meal details
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Header row with meal type and time
                HStack {
                    if let mealType = log.mealType {
                        Text(mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(log.loggedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Macro summary with icons
                HStack(spacing: Spacing.sm) {
                    NutritionMacroBadge(
                        value: log.totalCalories ?? 0,
                        unit: "cal",
                        icon: "flame.fill",
                        color: .orange
                    )

                    NutritionMacroBadge(
                        value: Int(log.totalProteinG ?? 0),
                        unit: "g",
                        icon: "p.circle.fill",
                        color: .red
                    )

                    if let carbs = log.totalCarbsG, carbs > 0 {
                        NutritionMacroBadge(
                            value: Int(carbs),
                            unit: "g",
                            icon: "c.circle.fill",
                            color: .blue
                        )
                    }

                    if let fat = log.totalFatG, fat > 0 {
                        NutritionMacroBadge(
                            value: Int(fat),
                            unit: "g",
                            icon: "f.circle.fill",
                            color: .yellow
                        )
                    }
                }

                // Food items list
                if !log.foodItems.isEmpty {
                    Text(log.foodItems.map { $0.name }.joined(separator: " - "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            // Delete button
            Button {
                HapticFeedback.warning()
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
                    .padding(Spacing.xs)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Delete meal")
            .accessibilityHint("Removes this meal from your log")
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: AnimationDuration.quick), value: isPressed)
        .confirmationDialog(
            "Delete Meal",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this meal?")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var mealTypeIcon: some View {
        let mealType = log.mealType ?? .lunch
        let iconColor = mealTypeColor(mealType)
        return ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(iconColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: mealType.icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
        }
    }

    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        case .preWorkout: return .red
        case .postWorkout: return .teal
        case .unknown: return .gray
        }
    }

    private var accessibilityDescription: String {
        var description = "\(log.mealType?.displayName ?? "Meal")"
        if let calories = log.totalCalories {
            description += ", \(calories) calories"
        }
        if let protein = log.totalProteinG {
            description += ", \(Int(protein)) grams protein"
        }
        return description
    }
}

// MARK: - Enhanced Planned Meal Card

/// Card for displaying planned meals from meal plan with visual distinction
struct EnhancedPlannedMealCard: View {
    let meal: MealPlanItem

    @Environment(\.colorScheme) private var colorScheme

    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        case .preWorkout: return .red
        case .postWorkout: return .teal
        case .unknown: return .gray
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Meal type icon with planned indicator
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(mealTypeColor(meal.mealType).opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: meal.mealType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(mealTypeColor(meal.mealType).opacity(0.7))
                }

                // Planned badge
                Image(systemName: "calendar")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(Color.modusCyan))
                    .offset(x: 4, y: -4)
            }

            // Meal details
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.8))

                    Text("Planned")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.modusCyan.opacity(0.15))
                        )

                    Spacer()

                    if let time = meal.displayTime {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Recipe name if available
                if let recipeName = meal.recipeName {
                    Text(recipeName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                // Macro summary
                HStack(spacing: Spacing.sm) {
                    if let cal = meal.estimatedCalories {
                        NutritionMacroBadge(
                            value: cal,
                            unit: "cal",
                            icon: "flame.fill",
                            color: .orange.opacity(0.7)
                        )
                    }

                    if let protein = meal.estimatedProteinG {
                        NutritionMacroBadge(
                            value: Int(protein),
                            unit: "g P",
                            icon: nil,
                            color: .red.opacity(0.7)
                        )
                    }
                }

                // Food items
                if !meal.foodItems.isEmpty {
                    Text(meal.foodItems.map { $0.name }.joined(separator: " - "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.modusCyan.opacity(0.3), Color.modusCyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var description = "Planned \(meal.mealType.displayName)"
        if let time = meal.mealTime {
            description += " at \(time)"
        }
        if let recipeName = meal.recipeName {
            description += ", \(recipeName)"
        }
        if let cal = meal.estimatedCalories {
            description += ", \(cal) calories"
        }
        return description
    }
}

// MARK: - Nutrition Macro Badge

/// Small inline badge for displaying macro values
struct NutritionMacroBadge: View {
    let value: Int
    let unit: String
    let icon: String?
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color)
            }

            Text("\(value)\(unit)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Enhanced Quick Log Button

/// Polished quick log button with improved visual feedback
struct EnhancedQuickLogButton: View {
    let mealType: MealType
    let action: () -> Void

    @State private var isPressed = false

    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        case .preWorkout: return .red
        case .postWorkout: return .teal
        case .unknown: return .gray
        }
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(mealTypeColor(mealType).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: mealType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(mealTypeColor(mealType))
                }

                Text(mealType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 85)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Log \(mealType.displayName)")
        .accessibilityHint("Opens meal logging form")
    }
}

// MARK: - Preview

#if DEBUG
struct EnhancedMealCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            // Quick log buttons
            HStack(spacing: Spacing.sm) {
                ForEach(MealType.allCases, id: \.self) { type in
                    EnhancedQuickLogButton(mealType: type) {}
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
