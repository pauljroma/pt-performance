//
//  NutritionGoalView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Goal settings view
//  Updated: Enhanced error handling with retry functionality
//

import SwiftUI

/// View for setting and managing nutrition goals
struct NutritionGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NutritionGoalViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else {
                goalFormContent
            }
        }
        .navigationTitle("Nutrition Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if await viewModel.saveGoal() {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isSaving || viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadGoals()
        }
        .errorAlert(
            message: $viewModel.error,
            title: "Unable to Save Goal",
            onRetry: {
                await viewModel.saveGoal()
            },
            showRetry: true
        )
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your nutrition goals...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Goal Form Content

    private var goalFormContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goal Type
                goalTypeSection

                // Presets
                presetsSection

                // Calorie Target
                calorieSection

                // Macro Targets
                macroSection

                // Macro Balance Indicator
                macroBalanceIndicator

                // Additional Targets
                additionalTargetsSection

                // Notes
                notesSection

                // Saving indicator
                if viewModel.isSaving {
                    savingIndicator
                }
            }
            .padding()
        }
    }

    // MARK: - Saving Indicator

    private var savingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Saving your goal...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Goal Type

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Type")
                .font(.headline)

            Picker("Goal Type", selection: $viewModel.goalType) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GoalPreset.presets) { preset in
                        GoalPresetCard(preset: preset, isSelected: viewModel.selectedPreset?.id == preset.id) {
                            viewModel.applyPreset(preset)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Calorie Section

    private var calorieSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Calories")
                .font(.headline)

            HStack {
                Text("\(viewModel.targetCalories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("kcal")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Slider(value: Binding(
                get: { Double(viewModel.targetCalories) },
                set: { viewModel.targetCalories = Int($0) }
            ), in: 1200...4000, step: 50)

            HStack {
                Text("1,200")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("4,000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Macro Section

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Targets")
                .font(.headline)

            // Protein
            MacroSlider(
                title: "Protein",
                value: $viewModel.targetProtein,
                range: 50...300,
                unit: "g",
                color: .red,
                percent: viewModel.proteinPercent
            )

            // Carbs
            MacroSlider(
                title: "Carbs",
                value: $viewModel.targetCarbs,
                range: 50...500,
                unit: "g",
                color: .blue,
                percent: viewModel.carbsPercent
            )

            // Fat
            MacroSlider(
                title: "Fat",
                value: $viewModel.targetFat,
                range: 20...200,
                unit: "g",
                color: .yellow,
                percent: viewModel.fatPercent
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Macro Balance Indicator

    private var macroBalanceIndicator: some View {
        HStack {
            Image(systemName: viewModel.macrosBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(viewModel.macrosBalanced ? .green : .orange)

            VStack(alignment: .leading) {
                Text(viewModel.macrosBalanced ? "Macros are balanced" : "Macros don't match calories")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Macro total: \(viewModel.macroCalories) kcal (Target: \(viewModel.targetCalories))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(viewModel.macrosBalanced ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Additional Targets

    private var additionalTargetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Targets")
                .font(.headline)

            // Fiber
            HStack {
                Text("Fiber")
                Spacer()
                TextField("", value: $viewModel.targetFiber, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("g")
                    .foregroundColor(.secondary)
            }

            // Water
            HStack {
                Text("Water")
                Spacer()
                TextField("", value: $viewModel.targetWater, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("ml")
                    .foregroundColor(.secondary)
            }

            // Protein per kg
            HStack {
                Text("Protein/kg")
                Spacer()
                TextField("", value: $viewModel.proteinPerKg, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("g/kg")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)

            TextField("Optional notes about your goals...", text: $viewModel.notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}

// MARK: - Preset Card

private struct GoalPresetCard: View {
    let preset: GoalPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(preset.calories) kcal")
                    .font(.caption)

                Text(preset.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 140)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Macro Slider

private struct MacroSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    let percent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("(\(percent)%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range, step: 5)
                .tint(color)
        }
    }
}

#Preview {
    NavigationStack {
        NutritionGoalView()
    }
}
