import SwiftUI

// MARK: - Working Weight Calculator View (ACP-514)

/// Calculates working weight ranges, sets/reps, rest periods, and warmup pyramids
/// based on a known or estimated 1RM and a selected training goal.
struct WorkingWeightCalculatorView: View {

    // MARK: - Training Goal

    enum TrainingGoal: String, CaseIterable {
        case strength = "Strength"
        case hypertrophy = "Hypertrophy"
        case endurance = "Endurance"
        case custom = "Custom"

        /// Percentage range of 1RM for the goal.
        var percentageRange: ClosedRange<Double> {
            switch self {
            case .strength:   return 0.85...0.95
            case .hypertrophy: return 0.65...0.80
            case .endurance:  return 0.50...0.65
            case .custom:     return 0.50...1.00  // user-driven
            }
        }

        /// Recommended rep range description.
        var repRange: String {
            switch self {
            case .strength:   return "3-5 reps"
            case .hypertrophy: return "8-12 reps"
            case .endurance:  return "15-20 reps"
            case .custom:     return "Varies"
            }
        }

        /// Recommended set range description.
        var setRange: String {
            switch self {
            case .strength:   return "4-6 sets"
            case .hypertrophy: return "3-4 sets"
            case .endurance:  return "2-3 sets"
            case .custom:     return "Varies"
            }
        }

        /// Recommended rest period description.
        var restTime: String {
            switch self {
            case .strength:   return "3-5 min"
            case .hypertrophy: return "60-90 sec"
            case .endurance:  return "30-60 sec"
            case .custom:     return "Varies"
            }
        }

        /// SF Symbol icon for the goal.
        var icon: String {
            switch self {
            case .strength:   return "bolt.fill"
            case .hypertrophy: return "figure.arms.open"
            case .endurance:  return "heart.fill"
            case .custom:     return "slider.horizontal.3"
            }
        }

        /// Accent color for the goal.
        var color: Color {
            switch self {
            case .strength:   return .red
            case .hypertrophy: return .purple
            case .endurance:  return .green
            case .custom:     return .orange
            }
        }
    }

    // MARK: - State

    @State private var oneRMText: String = ""
    @State private var estimateFromLift: Bool = false
    @State private var liftWeightText: String = ""
    @State private var liftRepsText: String = ""
    @State private var selectedGoal: TrainingGoal = .hypertrophy
    @State private var customPercentage: Double = 75.0

    // MARK: - Computed Properties

    /// The effective 1RM, either entered directly or estimated from a lift.
    private var effectiveOneRM: Double? {
        if estimateFromLift {
            guard let weight = Double(liftWeightText),
                  let reps = Int(liftRepsText),
                  weight > 0, reps >= 1, reps <= 30 else { return nil }
            if reps == 1 { return weight }
            return weight * (1.0 + Double(reps) / 30.0)
        } else {
            guard let value = Double(oneRMText), value > 0 else { return nil }
            return value
        }
    }

    /// Rounds a value to the nearest 2.5 lbs.
    private func roundToPlate(_ value: Double) -> Double {
        (value / 2.5).rounded() * 2.5
    }

    /// Low end of the working weight range.
    private var workingWeightLow: Double? {
        guard let oneRM = effectiveOneRM else { return nil }
        if selectedGoal == .custom {
            return roundToPlate(oneRM * customPercentage / 100.0)
        }
        return roundToPlate(oneRM * selectedGoal.percentageRange.lowerBound)
    }

    /// High end of the working weight range.
    private var workingWeightHigh: Double? {
        guard let oneRM = effectiveOneRM else { return nil }
        if selectedGoal == .custom {
            return roundToPlate(oneRM * customPercentage / 100.0)
        }
        return roundToPlate(oneRM * selectedGoal.percentageRange.upperBound)
    }

    /// Warmup pyramid sets based on the high end of the working weight range.
    private var warmupSets: [(set: Int, percentage: String, weight: Double, reps: Int)] {
        guard let oneRM = effectiveOneRM else { return [] }
        let workingWeight: Double
        if selectedGoal == .custom {
            workingWeight = roundToPlate(oneRM * customPercentage / 100.0)
        } else {
            workingWeight = roundToPlate(oneRM * selectedGoal.percentageRange.upperBound)
        }

        return [
            (1, "50%",  roundToPlate(oneRM * 0.50), 10),
            (2, "65%",  roundToPlate(oneRM * 0.65), 5),
            (3, "80%",  roundToPlate(oneRM * 0.80), 3),
            (4, "Work", workingWeight, 0)  // 0 reps signals "working set"
        ]
    }

    // MARK: - Body

    var body: some View {
        Form {
            inputSection
            goalSection
            resultsSection
            warmupSection
        }
        .navigationTitle("Working Weight")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        Section {
            Toggle(isOn: $estimateFromLift.animation()) {
                Label("Estimate from lift", systemImage: "function")
            }
            .accessibilityHint("Toggle to calculate 1RM from a recent lift instead of entering it directly")

            if estimateFromLift {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    TextField("Weight lifted (lbs)", text: $liftWeightText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Weight lifted in pounds")
                }

                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    TextField("Reps performed (1-30)", text: $liftRepsText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Repetitions performed")
                }

                if let oneRM = effectiveOneRM {
                    HStack {
                        Text("Estimated 1RM")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(roundToPlate(oneRM), specifier: "%.1f") lbs")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    TextField("Known 1RM (lbs)", text: $oneRMText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("One rep max in pounds")
                }
            }
        } header: {
            Text("Your 1RM")
        } footer: {
            if estimateFromLift {
                Text("Enter a recent lift to estimate your 1RM using the Epley formula.")
            } else {
                Text("Enter your known one-rep max, or toggle above to estimate it.")
            }
        }
    }

    // MARK: - Goal Section

    private var goalSection: some View {
        Section {
            Picker("Training Goal", selection: $selectedGoal.animation()) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Label(goal.rawValue, systemImage: goal.icon)
                        .tag(goal)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Training goal")

            if selectedGoal == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intensity")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(customPercentage))% of 1RM")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }

                    Slider(value: $customPercentage, in: 50...100, step: 5)
                        .accentColor(.orange)
                        .accessibilityLabel("Custom intensity percentage")
                        .accessibilityValue("\(Int(customPercentage)) percent of one rep max")
                }
                .padding(.vertical, 4)
            } else {
                // Show goal parameters as a summary
                VStack(alignment: .leading, spacing: 6) {
                    goalDetailRow(
                        icon: "percent",
                        label: "Intensity",
                        value: "\(Int(selectedGoal.percentageRange.lowerBound * 100))-\(Int(selectedGoal.percentageRange.upperBound * 100))% of 1RM"
                    )
                    goalDetailRow(
                        icon: "repeat",
                        label: "Reps",
                        value: selectedGoal.repRange
                    )
                    goalDetailRow(
                        icon: "square.stack.3d.up",
                        label: "Sets",
                        value: selectedGoal.setRange
                    )
                    goalDetailRow(
                        icon: "timer",
                        label: "Rest",
                        value: selectedGoal.restTime
                    )
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Training Goal")
        }
    }

    /// Helper row for displaying goal parameters.
    private func goalDetailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Results Section

    @ViewBuilder
    private var resultsSection: some View {
        if let low = workingWeightLow, let high = workingWeightHigh {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 32))
                        .foregroundColor(selectedGoal.color)

                    Text("Working Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if selectedGoal == .custom || low == high {
                        Text("\(low, specifier: "%.1f") lbs")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    } else {
                        Text("\(low, specifier: "%.1f") - \(high, specifier: "%.1f") lbs")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }

                    Divider()

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(selectedGoal == .custom ? "Custom" : selectedGoal.setRange)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Sets")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text(selectedGoal == .custom ? "Varies" : selectedGoal.repRange)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Reps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text(selectedGoal == .custom ? "Varies" : selectedGoal.restTime)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Rest")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(workingWeightAccessibilityLabel(low: low, high: high))
            } header: {
                Text("Recommendation")
            }
        }
    }

    /// Accessibility label for the results card.
    private func workingWeightAccessibilityLabel(low: Double, high: Double) -> String {
        if selectedGoal == .custom || low == high {
            return "Working weight: \(String(format: "%.1f", low)) pounds"
        }
        return "Working weight: \(String(format: "%.1f", low)) to \(String(format: "%.1f", high)) pounds. \(selectedGoal.setRange), \(selectedGoal.repRange), rest \(selectedGoal.restTime)"
    }

    // MARK: - Warmup Section

    @ViewBuilder
    private var warmupSection: some View {
        if effectiveOneRM != nil {
            Section {
                ForEach(warmupSets, id: \.set) { warmup in
                    HStack {
                        // Set number badge
                        Text("\(warmup.set)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(warmup.set == 4 ? selectedGoal.color : Color.gray)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            if warmup.set == 4 {
                                Text("Working Set")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedGoal.color)
                            } else {
                                Text("Warmup Set \(warmup.set)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Text(warmup.set == 4 ? warmup.percentage : "\(warmup.percentage) of 1RM")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(warmup.weight, specifier: "%.1f") lbs")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()

                            if warmup.reps > 0 {
                                Text("x \(warmup.reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(selectedGoal == .custom ? "x custom reps" : "x \(selectedGoal.repRange)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(warmupAccessibilityLabel(warmup))
                }
            } header: {
                Text("Warmup Pyramid")
            } footer: {
                Text("Gradually ramp up to your working weight. Rest 60-90 seconds between warmup sets.")
            }
        }
    }

    /// Accessibility label for a single warmup row.
    private func warmupAccessibilityLabel(_ warmup: (set: Int, percentage: String, weight: Double, reps: Int)) -> String {
        if warmup.set == 4 {
            return "Set 4, working set at \(String(format: "%.1f", warmup.weight)) pounds"
        }
        return "Set \(warmup.set), warmup at \(warmup.percentage) of one rep max, \(String(format: "%.1f", warmup.weight)) pounds for \(warmup.reps) reps"
    }
}

// MARK: - Preview

#Preview {
    WorkingWeightCalculatorView()
}
