//
//  BodyCompGoalSettingSheet.swift
//  PTPerformance
//
//  Sheet for setting body composition goals with targets and timeline
//

import SwiftUI

/// Sheet for setting or editing body composition goals
struct BodyCompGoalSettingSheet: View {
    @ObservedObject var viewModel: BodyCompGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var targetWeight: String = ""
    @State private var targetBodyFat: String = ""
    @State private var targetMuscleMass: String = ""
    @State private var targetDate = Date().addingTimeInterval(90 * 24 * 60 * 60) // 90 days default
    @State private var notes: String = ""

    @State private var hasWeightGoal = false
    @State private var hasBodyFatGoal = false
    @State private var hasMuscleMassGoal = false

    @State private var showingValidationError = false
    @State private var validationMessage = ""

    // MARK: - Computed Properties

    /// Weekly weight change needed to reach goal
    private var weeklyWeightChange: Double? {
        guard hasWeightGoal,
              let target = Double(targetWeight),
              let current = viewModel.latestWeight else { return nil }

        let weeks = weeksUntilTarget
        guard weeks > 0 else { return nil }

        return (target - current) / Double(weeks)
    }

    /// Weekly body fat change needed
    private var weeklyBodyFatChange: Double? {
        guard hasBodyFatGoal,
              let target = Double(targetBodyFat),
              let current = viewModel.latestBodyFat else { return nil }

        let weeks = weeksUntilTarget
        guard weeks > 0 else { return nil }

        return (target - current) / Double(weeks)
    }

    /// Weeks until target date
    private var weeksUntilTarget: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        return max(1, days / 7)
    }

    /// Whether the weekly weight change rate is healthy (recommended: 0.5-2 lbs/week)
    private var isWeightRateHealthy: Bool {
        guard let rate = weeklyWeightChange else { return true }
        return abs(rate) <= 2.0
    }

    /// Whether the weekly body fat change rate is reasonable
    private var isBodyFatRateHealthy: Bool {
        guard let rate = weeklyBodyFatChange else { return true }
        return abs(rate) <= 1.0
    }

    /// Whether the form has at least one valid goal
    private var hasValidGoal: Bool {
        (hasWeightGoal && Double(targetWeight) != nil) ||
        (hasBodyFatGoal && Double(targetBodyFat) != nil) ||
        (hasMuscleMassGoal && Double(targetMuscleMass) != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Current Stats Section
                currentStatsSection

                // MARK: - Weight Goal Section
                weightGoalSection

                // MARK: - Body Fat Goal Section
                bodyFatGoalSection

                // MARK: - Muscle Mass Goal Section
                muscleMassGoalSection

                // MARK: - Timeline Section
                timelineSection

                // MARK: - Notes Section
                notesSection

                // MARK: - Tips Section
                tipsSection
            }
            .navigationTitle(viewModel.currentGoals != nil ? "Edit Goals" : "Set Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveGoals()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!hasValidGoal || viewModel.isSaving)
                    .fontWeight(.semibold)
                }
            }
            .alert("Invalid Goal", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .onAppear {
                populateExistingGoals()
            }
        }
    }

    // MARK: - Section Views

    private var currentStatsSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let weight = viewModel.latestWeight {
                        Text("\(weight, specifier: "%.1f") lbs")
                            .font(.headline)
                    } else {
                        Text("No data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Body Fat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let bf = viewModel.latestBodyFat {
                        Text("\(bf, specifier: "%.1f")%")
                            .font(.headline)
                    } else {
                        Text("No data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Muscle Mass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let mm = viewModel.latestMuscleMass {
                        Text("\(mm, specifier: "%.1f") lbs")
                            .font(.headline)
                    } else {
                        Text("No data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Current Stats")
        } footer: {
            Text("Your starting point for goal tracking")
        }
    }

    private var weightGoalSection: some View {
        Section {
            Toggle("Set Weight Goal", isOn: $hasWeightGoal.animation())

            if hasWeightGoal {
                HStack {
                    Text("Target Weight")
                    Spacer()
                    TextField("lbs", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lbs")
                        .foregroundColor(.secondary)
                }

                // Show weekly rate needed
                if let rate = weeklyWeightChange, viewModel.latestWeight != nil {
                    HStack {
                        Image(systemName: rate < 0 ? "arrow.down.right" : "arrow.up.right")
                            .foregroundColor(isWeightRateHealthy ? .blue : .orange)

                        let direction = rate < 0 ? "lose" : "gain"
                        Text("\(abs(rate), specifier: "%.1f") lbs/week to \(direction)")
                            .font(.caption)
                            .foregroundColor(isWeightRateHealthy ? .secondary : .orange)

                        Spacer()

                        if !isWeightRateHealthy {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    if !isWeightRateHealthy {
                        Text("Recommended: 0.5-2 lbs/week for healthy, sustainable change")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        } header: {
            Label("Weight Goal", systemImage: "scalemass")
        }
    }

    private var bodyFatGoalSection: some View {
        Section {
            Toggle("Set Body Fat Goal", isOn: $hasBodyFatGoal.animation())

            if hasBodyFatGoal {
                HStack {
                    Text("Target Body Fat")
                    Spacer()
                    TextField("%", text: $targetBodyFat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("%")
                        .foregroundColor(.secondary)
                }

                // Show weekly rate needed
                if let rate = weeklyBodyFatChange {
                    HStack {
                        Image(systemName: rate < 0 ? "arrow.down.right" : "arrow.up.right")
                            .foregroundColor(isBodyFatRateHealthy ? .orange : .red)

                        let direction = rate < 0 ? "decrease" : "increase"
                        Text("\(abs(rate), specifier: "%.2f")%/week \(direction)")
                            .font(.caption)
                            .foregroundColor(isBodyFatRateHealthy ? .secondary : .orange)

                        Spacer()

                        if !isBodyFatRateHealthy {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    if !isBodyFatRateHealthy {
                        Text("Consider extending your timeline for sustainable results")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        } header: {
            Label("Body Fat Goal", systemImage: "percent")
        }
    }

    private var muscleMassGoalSection: some View {
        Section {
            Toggle("Set Muscle Mass Goal", isOn: $hasMuscleMassGoal.animation())

            if hasMuscleMassGoal {
                HStack {
                    Text("Target Muscle Mass")
                    Spacer()
                    TextField("lbs", text: $targetMuscleMass)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lbs")
                        .foregroundColor(.secondary)
                }

                if let current = viewModel.latestMuscleMass,
                   let target = Double(targetMuscleMass) {
                    let gain = target - current
                    let weeks = weeksUntilTarget
                    let weeklyGain = gain / Double(weeks)

                    HStack {
                        Image(systemName: gain > 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(.green)

                        Text("\(abs(weeklyGain), specifier: "%.2f") lbs/week \(gain > 0 ? "gain" : "change")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("Muscle Mass Goal", systemImage: "figure.strengthtraining.traditional")
        } footer: {
            if hasMuscleMassGoal {
                Text("Natural muscle gain is typically 0.25-0.5 lbs/week for beginners")
            }
        }
    }

    private var timelineSection: some View {
        Section {
            DatePicker(
                "Target Date",
                selection: $targetDate,
                in: Date()...,
                displayedComponents: .date
            )

            // Quick timeline buttons
            HStack(spacing: 12) {
                TimelineButton(title: "30 days", weeks: 4) { targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60) }
                TimelineButton(title: "60 days", weeks: 8) { targetDate = Date().addingTimeInterval(60 * 24 * 60 * 60) }
                TimelineButton(title: "90 days", weeks: 12) { targetDate = Date().addingTimeInterval(90 * 24 * 60 * 60) }
                TimelineButton(title: "6 months", weeks: 26) { targetDate = Date().addingTimeInterval(180 * 24 * 60 * 60) }
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("\(weeksUntilTarget) weeks until target date")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("Timeline", systemImage: "calendar")
        }
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 60)
        } header: {
            Label("Notes (Optional)", systemImage: "note.text")
        } footer: {
            Text("Add any notes about your goals or motivation")
        }
    }

    private var tipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "checkmark.circle", text: "Set realistic, achievable targets")
                TipRow(icon: "clock", text: "Allow enough time for sustainable progress")
                TipRow(icon: "chart.line.uptrend.xyaxis", text: "Track regularly to monitor progress")
                TipRow(icon: "figure.run", text: "Combine with consistent exercise and nutrition")
            }
            .padding(.vertical, 4)
        } header: {
            Label("Tips for Success", systemImage: "lightbulb")
        }
    }

    // MARK: - Helper Views

    private struct TimelineButton: View {
        let title: String
        let weeks: Int
        let action: () -> Void

        var body: some View {
            Button(action: {
                HapticFeedback.selectionChanged()
                action()
            }) {
                Text(title)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
    }

    private struct TipRow: View {
        let icon: String
        let text: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .font(.caption)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func populateExistingGoals() {
        guard let goals = viewModel.currentGoals else { return }

        if let weight = goals.targetWeight {
            hasWeightGoal = true
            targetWeight = String(format: "%.1f", weight)
        }

        if let bf = goals.targetBodyFatPercentage {
            hasBodyFatGoal = true
            targetBodyFat = String(format: "%.1f", bf)
        }

        if let mm = goals.targetMuscleMass {
            hasMuscleMassGoal = true
            targetMuscleMass = String(format: "%.1f", mm)
        }

        if let date = goals.targetDate {
            targetDate = date
        }

        notes = goals.notes ?? ""
    }

    private func saveGoals() {
        // Validate inputs
        var weight: Double? = nil
        var bodyFat: Double? = nil
        var muscleMass: Double? = nil

        if hasWeightGoal {
            guard let w = Double(targetWeight) else {
                validationMessage = "Please enter a valid weight target."
                showingValidationError = true
                return
            }
            if w <= 0 || w > 1000 {
                validationMessage = "Please enter a reasonable weight target (1-1000 lbs)."
                showingValidationError = true
                return
            }
            weight = w
        }

        if hasBodyFatGoal {
            guard let bf = Double(targetBodyFat) else {
                validationMessage = "Please enter a valid body fat percentage target."
                showingValidationError = true
                return
            }
            if bf < 3 || bf > 60 {
                validationMessage = "Please enter a reasonable body fat target (3-60%)."
                showingValidationError = true
                return
            }
            bodyFat = bf
        }

        if hasMuscleMassGoal {
            guard let mm = Double(targetMuscleMass) else {
                validationMessage = "Please enter a valid muscle mass target."
                showingValidationError = true
                return
            }
            if mm <= 0 || mm > 500 {
                validationMessage = "Please enter a reasonable muscle mass target (1-500 lbs)."
                showingValidationError = true
                return
            }
            muscleMass = mm
        }

        // Save goals
        Task {
            await viewModel.saveGoals(
                targetWeight: weight,
                targetBodyFat: bodyFat,
                targetMuscleMass: muscleMass,
                targetDate: targetDate,
                notes: notes.isEmpty ? nil : notes
            )

            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BodyCompGoalSettingSheet_Previews: PreviewProvider {
    static var previews: some View {
        BodyCompGoalSettingSheet(viewModel: BodyCompGoalsViewModel())
    }
}
#endif
