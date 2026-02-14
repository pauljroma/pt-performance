//
//  MealTimeline.swift
//  PTPerformance
//
//  ACP-1018: Meal-by-meal timeline visualization
//

import SwiftUI

// MARK: - Meal Timeline View

/// Displays today's meals in a chronological timeline format with macro breakdown
struct MealTimelineView: View {
    let logs: [NutritionLog]
    let plannedMeals: [MealPlanItem]
    let onDelete: (NutritionLog) -> Void

    @State private var isVisible = false

    private var allMealsChronological: [(type: TimelineItemType, time: Date, item: Any)] {
        var items: [(type: TimelineItemType, time: Date, item: Any)] = []

        // Add logged meals
        for log in logs {
            items.append((.logged, log.loggedAt, log))
        }

        // Add planned meals
        let calendar = Calendar.current
        for planned in plannedMeals {
            if let timeString = planned.mealTime,
               let time = timeFromString(timeString) {
                items.append((.planned, time, planned))
            } else {
                // If no time specified, use default meal times
                let defaultTime = defaultTimeForMealType(planned.mealType)
                items.append((.planned, defaultTime, planned))
            }
        }

        return items.sorted { $0.time < $1.time }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today's Timeline")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Logged")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text("Planned")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if allMealsChronological.isEmpty {
                EmptyTimelineView()
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(allMealsChronological.enumerated()), id: \.offset) { index, item in
                        TimelineItemView(
                            item: item,
                            isLast: index == allMealsChronological.count - 1,
                            onDelete: onDelete
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(x: isVisible ? 0 : -20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05), value: isVisible)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }

    private func timeFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }

        // Combine with today's date
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = components.year
        combined.month = components.month
        combined.day = components.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined)
    }

    private func defaultTimeForMealType(_ mealType: MealType) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)

        switch mealType {
        case .breakfast:
            components.hour = 7
            components.minute = 0
        case .lunch:
            components.hour = 12
            components.minute = 0
        case .dinner:
            components.hour = 18
            components.minute = 0
        case .snack:
            components.hour = 15
            components.minute = 0
        case .preWorkout:
            components.hour = 16
            components.minute = 0
        case .postWorkout:
            components.hour = 19
            components.minute = 0
        }

        return calendar.date(from: components) ?? now
    }
}

// MARK: - Timeline Item Type

enum TimelineItemType {
    case logged
    case planned
}

// MARK: - Timeline Item View

struct TimelineItemView: View {
    let item: (type: TimelineItemType, time: Date, item: Any)
    let isLast: Bool
    let onDelete: (NutritionLog) -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(item.type == .logged ? Color.green : Color.blue.opacity(0.5))
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2, height: 44)
                }
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Time
                Text(item.time, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                if item.type == .logged, let log = item.item as? NutritionLog {
                    LoggedMealTimelineCard(log: log, onDelete: onDelete)
                } else if item.type == .planned, let planned = item.item as? MealPlanItem {
                    PlannedMealTimelineCard(meal: planned)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Logged Meal Timeline Card

struct LoggedMealTimelineCard: View {
    let log: NutritionLog
    let onDelete: (NutritionLog) -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                if let mealType = log.mealType {
                    HStack(spacing: 4) {
                        Image(systemName: mealType.icon)
                            .font(.caption2)
                        Text(mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                }

                // Macro breakdown
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(log.totalCalories ?? 0)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("P:")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(Int(log.totalProteinG ?? 0))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("C:")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("\(Int(log.totalCarbsG ?? 0))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 2) {
                        Text("F:")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(Int(log.totalFatG ?? 0))g")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }

                if !log.foodItems.isEmpty {
                    Text(log.foodItems.map { $0.name }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                HapticFeedback.warning()
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
                    .padding(6)
            }
            .accessibilityLabel("Delete meal")
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
        )
        .confirmationDialog(
            "Delete Meal",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete(log)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Planned Meal Timeline Card

struct PlannedMealTimelineCard: View {
    let meal: MealPlanItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: meal.mealType.icon)
                        .font(.caption2)
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Planned")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
                        )
                }
                .foregroundColor(.primary.opacity(0.8))

                if let recipeName = meal.recipeName {
                    Text(recipeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let cal = meal.estimatedCalories {
                    HStack(spacing: Spacing.xs) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange.opacity(0.7))
                            Text("\(cal)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }

                        if let protein = meal.estimatedProteinG {
                            HStack(spacing: 2) {
                                Text("P:")
                                    .font(.caption2)
                                    .foregroundColor(.red.opacity(0.7))
                                Text("\(Int(protein))g")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Empty Timeline View

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No meals logged yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Track your meals to see your daily timeline")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }
}

// MARK: - Preview

#if DEBUG
struct MealTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        MealTimelineView(
            logs: [],
            plannedMeals: [],
            onDelete: { _ in }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
