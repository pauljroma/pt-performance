//
//  PortionGuideView.swift
//  PTPerformance
//
//  Modus Nutrition Module - Visual hand-based portion guide
//  Based on Modus Nutrition Guidelines portion system
//

import SwiftUI

/// Visual guide for hand-based portion measurement
struct PortionGuideView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGender: BiologicalGender = .male
    @State private var selectedGoal: NutritionGoalType = .maintain

    private let portionGuides = NutritionGuidelinesData.portionGuides
    private let mealTemplates = NutritionGuidelinesData.mealTemplates

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Hand-based portions
                    portionCardsSection

                    // Meal templates by goal
                    mealTemplateSection

                    // Tips section
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Portion Guide")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Hand-Based Portions")
                .font(.title2)
                .fontWeight(.bold)

            Text("No measuring required - use your hand as a guide for consistent portions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Portion Cards Section

    private var portionCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portion Measurements")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(portionGuides) { portion in
                PortionGuideCard(portion: portion)
            }
        }
    }

    // MARK: - Meal Template Section

    private var mealTemplateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Templates by Goal")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Gender/Goal Pickers
            HStack(spacing: 12) {
                Picker("Gender", selection: $selectedGender) {
                    ForEach(BiologicalGender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Goal", selection: $selectedGoal) {
                    Text("Maintain").tag(NutritionGoalType.maintain)
                    Text("Fat Loss").tag(NutritionGoalType.fatLoss)
                    Text("Muscle").tag(NutritionGoalType.muscleGain)
                }
                .pickerStyle(.segmented)
            }

            // Template Card
            if let template = getSelectedTemplate() {
                MealTemplateCard(template: template)
            }
        }
    }

    private func getSelectedTemplate() -> MealTemplate? {
        let genderString = selectedGender == .male ? "Male" : "Female"
        let goalString: String
        switch selectedGoal {
        case .maintain, .performance:
            goalString = "Maintenance"
        case .fatLoss:
            goalString = "Fat Loss"
        case .muscleGain:
            goalString = "Muscle Gain"
        }
        return mealTemplates.first { $0.gender == genderString && $0.goal == goalString }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips for Success")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                PortionTipRow(
                    icon: "1.circle.fill",
                    title: "Use YOUR Hand",
                    tipDescription: "Your hand size scales with your body, making it a personalized measuring tool"
                )

                PortionTipRow(
                    icon: "2.circle.fill",
                    title: "Be Consistent",
                    tipDescription: "Use the same hand measurements each time for accurate tracking"
                )

                PortionTipRow(
                    icon: "3.circle.fill",
                    title: "Adjust as Needed",
                    tipDescription: "Add extra vegetables freely; adjust protein and carbs based on activity"
                )

                PortionTipRow(
                    icon: "4.circle.fill",
                    title: "Fill Half Your Plate",
                    tipDescription: "Aim for vegetables to fill half your plate at each meal"
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Portion Guide Card

struct PortionGuideCard: View {
    let portion: PortionGuide

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(portion.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: portion.icon)
                    .font(.title2)
                    .foregroundColor(portion.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                // Hand measure
                HStack {
                    Text(portion.handMeasure)
                        .font(.headline)
                        .foregroundColor(portion.color)

                    Text("=")
                        .foregroundColor(.secondary)

                    Text(portion.foodType)
                        .fontWeight(.medium)
                }

                // Amount
                Text(portion.approximateAmount)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Examples
                Text("e.g. \(portion.examples.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(portion.handMeasure) equals \(portion.foodType). \(portion.approximateAmount). Examples: \(portion.examples.joined(separator: ", "))")
    }
}

// MARK: - Meal Template Card

struct MealTemplateCard: View {
    let template: MealTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(template.displayName)
                .font(.headline)

            // Visual representation
            HStack(spacing: 12) {
                PortionVisual(
                    icon: "hand.raised.fill",
                    count: template.proteinPortions,
                    label: "Protein",
                    color: .red
                )

                PortionVisual(
                    icon: "hand.point.up.fill",
                    count: template.vegetablePortions,
                    label: "Veggies",
                    color: .green
                )

                PortionVisual(
                    icon: "hand.wave.fill",
                    count: template.carbPortions,
                    label: "Carbs",
                    color: .blue
                )

                PortionVisual(
                    icon: "hand.thumbsup.fill",
                    count: template.fatPortions,
                    label: "Fats",
                    color: .yellow
                )
            }

            // Text description
            Text(template.formatPortions())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Portion Visual

struct PortionVisual: View {
    let icon: String
    let count: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)

                    Text(formatCount())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formatCount()) \(label)")
    }

    private func formatCount() -> String {
        if count == floor(count) {
            return "\(Int(count))"
        }
        return String(format: "%.1f", count)
    }
}

// MARK: - Tip Row

struct PortionTipRow: View {
    let icon: String
    let title: String
    let tipDescription: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(tipDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(tipDescription)")
    }
}

// MARK: - Standalone Portion Guide (for embedding)

/// Compact version of portion guide for embedding in other views
struct CompactPortionGuide: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(NutritionGuidelinesData.portionGuides) { portion in
                VStack(spacing: 4) {
                    Image(systemName: portion.icon)
                        .font(.title3)
                        .foregroundColor(portion.color)

                    Text(portion.handMeasure)
                        .font(.caption2)
                        .fontWeight(.medium)

                    Text(portion.foodType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    PortionGuideView()
}

#Preview("Compact") {
    CompactPortionGuide()
        .padding()
}
